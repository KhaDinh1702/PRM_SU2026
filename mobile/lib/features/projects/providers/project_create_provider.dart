import 'package:flutter/foundation.dart';

import '../models/project_create_draft.dart';
import '../models/project_template.dart';
import '../models/project_type.dart';
import '../services/project_milestone_service.dart';
import 'project_provider.dart';

/// Result returned by [ProjectCreateProvider.submit].
class ProjectCreateResult {
  final bool success;
  final String? projectId;
  final String? errorMessage;

  /// Emails that the project was created with but that could not be invited
  /// (server rejected them — e.g. user not found). The UI surfaces this so
  /// the user knows the project still exists.
  final List<String> failedInvites;

  const ProjectCreateResult._({
    required this.success,
    this.projectId,
    this.errorMessage,
    this.failedInvites = const [],
  });

  const ProjectCreateResult.success({
    required String projectId,
    List<String> failedInvites = const [],
  }) : this._(
          success: true,
          projectId: projectId,
          failedInvites: failedInvites,
        );

  const ProjectCreateResult.failure(String message)
      : this._(success: false, errorMessage: message);
}

/// Owns the in-progress draft for the "Create New Project" sheet.
///
/// Only the sheet talks to this provider. The actual REST calls go through
/// [ProjectProvider] / `ProjectService`, so this class never touches `http`
/// directly — it just orchestrates the multi-step submit flow.
class ProjectCreateProvider extends ChangeNotifier {
  final ProjectMilestoneService _milestoneService;

  ProjectCreateProvider({ProjectMilestoneService? milestoneService})
      : _milestoneService =
            milestoneService ?? const ProjectMilestoneService();

  ProjectCreateDraft _draft = const ProjectCreateDraft();
  bool _isSubmitting = false;
  String? _submitError;

  ProjectCreateDraft get draft => _draft;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  ProjectCreateValidation get validation => _draft.validate();
  bool get canSubmit => !_isSubmitting && validation.isValid;

  void setName(String value) => _update(_draft.copyWith(name: value));
  void setDescription(String value) =>
      _update(_draft.copyWith(description: value));

  void setType(ProjectType type) {
    final meta = ProjectTypeMeta.of(type);
    // Drop invitations + tasks-by-members flag when switching to a
    // single-user project to avoid stale state from the previous selection.
    final emails = meta.collaborative ? _draft.inviteEmails : const <String>[];
    _update(_draft.copyWith(type: type, inviteEmails: emails));
  }

  void setDeadline(DateTime? value) {
    _update(
      value == null
          ? _draft.copyWith(clearDeadline: true)
          : _draft.copyWith(deadline: value),
    );
  }

  void setAllowMembersToCreateTasks(bool value) =>
      _update(_draft.copyWith(allowMembersToCreateTasks: value));

  void addInviteEmail(String email) {
    final cleaned = email.trim().toLowerCase();
    if (cleaned.isEmpty) return;
    if (_draft.inviteEmails.contains(cleaned)) return;
    _update(_draft.copyWith(
      inviteEmails: [..._draft.inviteEmails, cleaned],
    ));
  }

  void removeInviteEmail(String email) {
    if (!_draft.inviteEmails.contains(email)) return;
    _update(_draft.copyWith(
      inviteEmails: _draft.inviteEmails.where((e) => e != email).toList(),
    ));
  }

  /// Apply a project template — pre-fills name, description, type and the
  /// suggested deadline. The user can still edit anything before submit.
  /// Pass `null` to clear the template selection.
  void applyTemplate(ProjectTemplate? template) {
    if (template == null) {
      _update(_draft.copyWith(clearTemplate: true));
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _update(_draft.copyWith(
      template: template,
      name: template.projectName,
      description: template.projectDescription,
      type: template.projectType,
      deadline: template.defaultDeadlineOffset == null
          ? _draft.deadline
          : today.add(template.defaultDeadlineOffset!),
    ));
  }

  void reset() {
    _draft = const ProjectCreateDraft();
    _submitError = null;
    _isSubmitting = false;
    notifyListeners();
  }

  /// Executes the create flow: POST project → (optionally) PUT settings →
  /// invite members one by one. Failures during the optional steps don't
  /// roll back the project — the result surfaces them instead.
  Future<ProjectCreateResult> submit(ProjectProvider projects) async {
    if (_isSubmitting) {
      return const ProjectCreateResult.failure('Already submitting');
    }
    final v = validation;
    if (!v.isValid) {
      return ProjectCreateResult.failure(
        v.nameError ?? v.deadlineError ?? v.inviteError ?? 'Invalid form',
      );
    }

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final projectId =
          await projects.createProject(payload: _draft.toCreatePayload());

      if (projectId.isEmpty) {
        return const ProjectCreateResult.failure(
          'Project created but server did not return an id',
        );
      }

      // Apply the "members can create tasks" flag only when it differs from
      // the backend default (true) — saves a round-trip in the common case.
      if (!_draft.allowMembersToCreateTasks &&
          ProjectTypeMeta.of(_draft.type).collaborative) {
        await projects.updateProject(
          projectId: projectId,
          payload: const {'allowMembersToCreateTasks': false},
        );
      }

      final failedInvites = <String>[];
      if (_draft.hasInvitations) {
        for (final email in _draft.inviteEmails) {
          final result =
              await projects.addMember(projectId: projectId, email: email);
          if (result['success'] != true) {
            failedInvites.add(email);
          }
        }
      }

      // Materialise template milestones (if any) into the local milestone
      // store. Failures here don't roll back the project — log and move on.
      final template = _draft.template;
      if (template != null) {
        final milestones = template.materializeMilestones(DateTime.now());
        var current = await _milestoneService.loadMilestones(
          projectId: projectId,
          projectData: projects.projects.firstWhere(
            (p) => p.project.id == projectId,
            orElse: () => projects.projects.isNotEmpty
                ? projects.projects.first
                : (throw StateError('no project available')),
          ),
        );
        for (final m in milestones) {
          final created = await _milestoneService.addMilestone(
            projectId: projectId,
            current: current,
            title: m.title,
            description: m.description,
            targetDate: m.targetDate,
          );
          current = [...current, created];
        }
      }

      return ProjectCreateResult.success(
        projectId: projectId,
        failedInvites: failedInvites,
      );
    } catch (e) {
      _submitError = _humanizeError(e);
      return ProjectCreateResult.failure(_submitError!);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _update(ProjectCreateDraft next) {
    if (identical(next, _draft)) return;
    _draft = next;
    notifyListeners();
  }

  String _humanizeError(Object e) {
    final raw = e.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }
}
