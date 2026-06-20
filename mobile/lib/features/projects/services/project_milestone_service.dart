import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../models/project_milestone.dart';
import '../models/project_model.dart';

/// Local-only milestone storage scoped to `(userId, projectId)`. Two users
/// sharing the same device no longer see each other's milestones.
///
/// Backend persistence is out of scope for now — the service exposes a clean
/// async API so the move to a real endpoint is a single file change later.
class ProjectMilestoneService {
  const ProjectMilestoneService();

  Future<String> _key(String projectId) async {
    final user = await AuthService.getUserInfo();
    final userId = (user?['_id'] ?? user?['id'] ?? 'anon').toString();
    return 'project_milestones_${userId}_$projectId';
  }

  Future<List<ProjectMilestone>> loadMilestones({
    required String projectId,
    required ProjectModel projectData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key(projectId);

    final List<ProjectMilestone> userMilestones;
    final raw = prefs.getString(key);
    if (raw == null) {
      userMilestones = const [];
    } else {
      final list = jsonDecode(raw) as List<dynamic>;
      userMilestones = list
          .whereType<Map<String, dynamic>>()
          .map(ProjectMilestone.fromJson)
          // Filter out any persisted system milestones — we regenerate them
          // from project metadata so they always stay in sync.
          .where((m) => m.kind != MilestoneKind.system)
          .toList();
    }

    final system = _systemMilestones(projectData);
    return _merge(system, userMilestones);
  }

  Future<void> _persist(
    String projectId,
    List<ProjectMilestone> milestones,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key(projectId);
    final userOnly =
        milestones.where((m) => m.kind == MilestoneKind.user).toList();
    final encoded = jsonEncode(userOnly.map((m) => m.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  Future<ProjectMilestone> addMilestone({
    required String projectId,
    required List<ProjectMilestone> current,
    required String title,
    String? description,
    DateTime? targetDate,
  }) async {
    final milestone = ProjectMilestone(
      id: 'user:${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      targetDate: targetDate,
      kind: MilestoneKind.user,
    );
    final updated = [...current, milestone];
    await _persist(projectId, updated);
    return milestone;
  }

  Future<void> updateMilestone({
    required String projectId,
    required List<ProjectMilestone> current,
    required String milestoneId,
    String? title,
    String? description,
    DateTime? targetDate,
    bool clearTargetDate = false,
  }) async {
    final updated = current.map((m) {
      if (m.id != milestoneId || !m.isEditable) return m;
      return m.copyWith(
        title: title,
        description: description,
        targetDate: targetDate,
        clearTargetDate: clearTargetDate,
      );
    }).toList();
    await _persist(projectId, updated);
  }

  Future<void> toggleCompleted({
    required String projectId,
    required List<ProjectMilestone> current,
    required String milestoneId,
  }) async {
    final updated = current.map((m) {
      if (m.id != milestoneId || !m.isEditable) return m;
      return m.copyWith(isCompleted: !m.isCompleted);
    }).toList();
    await _persist(projectId, updated);
  }

  Future<void> deleteMilestone({
    required String projectId,
    required List<ProjectMilestone> current,
    required String milestoneId,
  }) async {
    final updated = current
        .where((m) => m.id != milestoneId || !m.isEditable)
        .toList();
    await _persist(projectId, updated);
  }

  // --- Internals ---

  List<ProjectMilestone> _systemMilestones(ProjectModel projectData) {
    final project = projectData.project;
    final created = project.createdAt;
    final deadline = project.deadline;
    final progress = projectData.progress;

    return [
      ProjectMilestone(
        id: ProjectMilestone.systemCreatedId,
        title: 'Project Created',
        targetDate: created,
        isCompleted: true,
        kind: MilestoneKind.system,
      ),
      if (deadline != null)
        ProjectMilestone(
          id: ProjectMilestone.systemDeadlineId,
          title: 'Project Deadline',
          targetDate: deadline,
          isCompleted: progress >= 100,
          kind: MilestoneKind.system,
        ),
    ];
  }

  /// Merges system + user milestones sorted by target date (nulls last).
  /// Created marker always stays first, Deadline marker always stays last.
  List<ProjectMilestone> _merge(
    List<ProjectMilestone> system,
    List<ProjectMilestone> user,
  ) {
    final created = system.firstWhere(
      (m) => m.id == ProjectMilestone.systemCreatedId,
      orElse: () => const ProjectMilestone(
        id: ProjectMilestone.systemCreatedId,
        title: 'Project Created',
        kind: MilestoneKind.system,
      ),
    );
    final deadline = system
        .where((m) => m.id == ProjectMilestone.systemDeadlineId)
        .toList();

    final sortedUser = [...user];
    sortedUser.sort((a, b) {
      final ad = a.targetDate;
      final bd = b.targetDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });

    return [created, ...sortedUser, ...deadline];
  }
}
