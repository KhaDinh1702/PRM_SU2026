import 'project_type.dart';

/// Validation feedback returned by [ProjectCreateDraft.validate]. Keeps
/// field-specific messages so the UI can highlight individual inputs instead
/// of showing one global error.
class ProjectCreateValidation {
  final String? nameError;
  final String? deadlineError;
  final String? inviteError;

  const ProjectCreateValidation({
    this.nameError,
    this.deadlineError,
    this.inviteError,
  });

  bool get isValid =>
      nameError == null && deadlineError == null && inviteError == null;
}

/// Immutable form state of the "Create New Project" sheet.
///
/// Held by [ProjectCreateProvider]; serialised to the API payload via
/// [toCreatePayload]. Keeping the draft a plain immutable model (rather than
/// scattered `setState` fields) makes validation, testing and copy-on-change
/// updates straightforward.
class ProjectCreateDraft {
  static const int nameMinLength = 3;
  static const int nameMaxLength = 80;
  static const int descriptionMaxLength = 280;

  final String name;
  final String description;
  final ProjectType type;
  final DateTime? deadline;
  final List<String> inviteEmails;
  final bool allowMembersToCreateTasks;

  const ProjectCreateDraft({
    this.name = '',
    this.description = '',
    this.type = ProjectType.personal,
    this.deadline,
    this.inviteEmails = const [],
    this.allowMembersToCreateTasks = true,
  });

  ProjectCreateDraft copyWith({
    String? name,
    String? description,
    ProjectType? type,
    DateTime? deadline,
    bool clearDeadline = false,
    List<String>? inviteEmails,
    bool? allowMembersToCreateTasks,
  }) {
    return ProjectCreateDraft(
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      inviteEmails: inviteEmails ?? this.inviteEmails,
      allowMembersToCreateTasks:
          allowMembersToCreateTasks ?? this.allowMembersToCreateTasks,
    );
  }

  /// `true` when the type is collaborative and at least one email is queued
  /// for invitation. Used by the sheet to decide whether to call the
  /// invite-member endpoint after creation.
  bool get hasInvitations =>
      ProjectTypeMeta.of(type).collaborative && inviteEmails.isNotEmpty;

  /// Field-by-field validation. The button is only enabled when this
  /// returns [ProjectCreateValidation.isValid].
  ProjectCreateValidation validate() {
    final trimmedName = name.trim();
    String? nameError;
    if (trimmedName.isEmpty) {
      nameError = 'Project name is required';
    } else if (trimmedName.length < nameMinLength) {
      nameError = 'Name must be at least $nameMinLength characters';
    } else if (trimmedName.length > nameMaxLength) {
      nameError = 'Name must be at most $nameMaxLength characters';
    }

    String? deadlineError;
    if (deadline != null) {
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      if (deadline!.isBefore(startOfToday)) {
        deadlineError = 'Deadline cannot be in the past';
      }
    }

    String? inviteError;
    for (final email in inviteEmails) {
      if (!_emailRegex.hasMatch(email)) {
        inviteError = '"$email" is not a valid email';
        break;
      }
    }

    return ProjectCreateValidation(
      nameError: nameError,
      deadlineError: deadlineError,
      inviteError: inviteError,
    );
  }

  /// Payload accepted by `POST /api/projects`. Optional fields are dropped
  /// when empty so the backend keeps its defaults.
  Map<String, dynamic> toCreatePayload() {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'type': ProjectTypeMeta.of(type).apiValue,
    };
    if (deadline != null) {
      payload['deadline'] = deadline!.toUtc().toIso8601String();
    }
    return payload;
  }

  static final RegExp _emailRegex =
      RegExp(r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$');
}
