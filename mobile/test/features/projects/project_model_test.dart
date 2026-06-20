import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/projects/models/project_model.dart';

/// Builds a [ProjectModel] from a minimal payload so each test only spells
/// out the fields it cares about.
ProjectModel buildProject({
  String id = 'p1',
  String name = 'Test',
  String description = '',
  String status = 'Active',
  String type = 'Team',
  DateTime? deadline,
  DateTime? createdAt,
  String? currentUserRole = 'Owner',
  int totalTasks = 0,
  int completedTasks = 0,
  int progressPercentage = 0,
  bool allowMembersToCreateTasks = false,
}) {
  return ProjectModel(
    project: ProjectDetails(
      id: id,
      name: name,
      description: description,
      members: const [],
      memberRoles: const [],
      status: status,
      type: type,
      deadline: deadline,
      createdAt: createdAt,
      allowMembersToCreateTasks: allowMembersToCreateTasks,
    ),
    currentUserRole: currentUserRole,
    pendingInvitationUserIds: const [],
    stats: ProjectStats(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      progressPercentage: progressPercentage,
    ),
  );
}

void main() {
  group('ProjectModel.priority', () {
    test('returns High when there are many open tasks', () {
      final p = buildProject(totalTasks: 10, completedTasks: 2);
      expect(p.priority, 'High');
    });

    test('returns Medium with a few open tasks', () {
      final p = buildProject(totalTasks: 3, completedTasks: 1);
      expect(p.priority, 'Medium');
    });

    test('returns Normal with no open tasks', () {
      final p = buildProject(totalTasks: 0, completedTasks: 0);
      expect(p.priority, 'Normal');
    });

    test('returns High when overdue', () {
      final p = buildProject(
        totalTasks: 1,
        deadline: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(p.priority, 'High');
    });
  });

  group('ProjectModel.isOverdue', () {
    test('true when deadline is in the past and progress < 100', () {
      final p = buildProject(
        totalTasks: 1,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(p.isOverdue, isTrue);
    });

    test('false when project is completed', () {
      final p = buildProject(
        totalTasks: 1,
        completedTasks: 1,
        progressPercentage: 100,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(p.isOverdue, isFalse);
    });

    test('false when no deadline set', () {
      expect(buildProject().isOverdue, isFalse);
    });
  });

  group('ProjectModel.needsAttention + attentionScore', () {
    test('overdue project scores higher than a quiet one', () {
      final overdue = buildProject(
        totalTasks: 1,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      final quiet = buildProject(totalTasks: 1);
      expect(overdue.attentionScore, greaterThan(quiet.attentionScore));
    });

    test('completed project does not need attention', () {
      final completed = buildProject(
        totalTasks: 1,
        completedTasks: 1,
        progressPercentage: 100,
      );
      expect(completed.needsAttention, isFalse);
    });

    test('attentionReason "Overdue tasks" wins when project is past due', () {
      final p = buildProject(
        totalTasks: 1,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(p.attentionReason, 'Overdue tasks');
    });
  });

  group('ProjectModel.openTasks + progress', () {
    test('openTasks = total - completed', () {
      final p = buildProject(totalTasks: 7, completedTasks: 3);
      expect(p.openTasks, 4);
    });

    test('openTasks clamps to 0', () {
      final p = buildProject(totalTasks: 2, completedTasks: 5);
      expect(p.openTasks, 0);
    });
  });
}
