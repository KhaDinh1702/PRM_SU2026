import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/projects/models/project_milestone.dart';

ProjectMilestone milestone({
  bool isCompleted = false,
  DateTime? targetDate,
  MilestoneKind kind = MilestoneKind.user,
}) {
  return ProjectMilestone(
    id: 'm',
    title: 'x',
    targetDate: targetDate,
    isCompleted: isCompleted,
    kind: kind,
  );
}

void main() {
  group('ProjectMilestone.status', () {
    test('completed when isCompleted is true', () {
      expect(milestone(isCompleted: true).status, MilestoneStatus.completed);
    });

    test('overdue when target is in the past and not completed', () {
      final m = milestone(
        targetDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(m.status, MilestoneStatus.overdue);
    });

    test('dueSoon when target is within 3 days', () {
      final m = milestone(
        targetDate: DateTime.now().add(const Duration(days: 2)),
      );
      expect(m.status, MilestoneStatus.dueSoon);
    });

    test('inProgress when target is 4-14 days away', () {
      final m = milestone(
        targetDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(m.status, MilestoneStatus.inProgress);
    });

    test('upcoming when target is far in the future', () {
      final m = milestone(
        targetDate: DateTime.now().add(const Duration(days: 60)),
      );
      expect(m.status, MilestoneStatus.upcoming);
    });

    test('upcoming when target is null', () {
      expect(milestone().status, MilestoneStatus.upcoming);
    });
  });

  group('ProjectMilestone.countdownLabel', () {
    test('empty when completed', () {
      final m = milestone(
        isCompleted: true,
        targetDate: DateTime.now().add(const Duration(days: 3)),
      );
      expect(m.countdownLabel, '');
    });

    test('"Today" when target is today', () {
      final now = DateTime.now();
      final m = milestone(targetDate: DateTime(now.year, now.month, now.day));
      expect(m.countdownLabel, 'Today');
    });

    test('"Tomorrow" when target is tomorrow', () {
      final m = milestone(
        targetDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(m.countdownLabel, 'Tomorrow');
    });

    test('"Due in Nd" for future targets', () {
      final m = milestone(
        targetDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(m.countdownLabel, 'Due in 5d');
    });

    test('"Nd overdue" for past targets', () {
      final m = milestone(
        targetDate: DateTime.now().subtract(const Duration(days: 4)),
      );
      expect(m.countdownLabel, '4d overdue');
    });
  });

  group('ProjectMilestone.isEditable', () {
    test('true for user milestones', () {
      expect(milestone(kind: MilestoneKind.user).isEditable, isTrue);
    });

    test('false for system milestones', () {
      expect(milestone(kind: MilestoneKind.system).isEditable, isFalse);
    });
  });

  group('ProjectMilestone.copyWith', () {
    test('clearTargetDate removes the date', () {
      final m = milestone(
        targetDate: DateTime.now().add(const Duration(days: 1)),
      );
      final cleared = m.copyWith(clearTargetDate: true);
      expect(cleared.targetDate, isNull);
    });
  });
}
