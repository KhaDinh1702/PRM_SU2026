import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/tasks/models/task_model.dart';

void main() {
  group('TaskModel.fromJson', () {
    test('parses status, priority and source enums', () {
      final task = TaskModel.fromJson({
        '_id': 't1',
        'title': 'Test',
        'description': 'desc',
        'status': 'In Progress',
        'priority': 'High',
        'project': {'_id': 'p1', 'name': 'Project A'},
      });

      expect(task.id, 't1');
      expect(task.status, TaskStatus.inProgress);
      expect(task.priority, TaskPriority.high);
      expect(task.source, TaskSource.project);
      expect(task.projectName, 'Project A');
    });

    test('defaults to pending + low + personal when fields are missing', () {
      final task = TaskModel.fromJson({});
      expect(task.status, TaskStatus.pending);
      expect(task.priority, TaskPriority.low);
      expect(task.source, TaskSource.personal);
    });

    test('parses and serializes the persisted Review status', () {
      final task = TaskModel.fromJson({
        '_id': 't-review',
        'status': 'Review',
      });

      expect(task.status, TaskStatus.review);
      expect(task.statusLabel, 'Review');
      expect(task.toMap()['status'], 'Review');
    });
  });

  group('TaskModel.isOverdue', () {
    test('true when deadline is in the past and not completed', () {
      final task = TaskModel(
        id: 't1',
        title: 'x',
        description: '',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        source: TaskSource.personal,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(task.isOverdue, isTrue);
    });

    test('false when task is completed', () {
      final task = TaskModel(
        id: 't1',
        title: 'x',
        description: '',
        status: TaskStatus.completed,
        priority: TaskPriority.medium,
        source: TaskSource.personal,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(task.isOverdue, isFalse);
    });

    test('false when no deadline set', () {
      const task = TaskModel(
        id: 't1',
        title: 'x',
        description: '',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        source: TaskSource.personal,
      );
      expect(task.isOverdue, isFalse);
    });
  });

  group('TaskModel.effectiveDueDateTime', () {
    test('combines deadline date with dueTime when provided', () {
      final task = TaskModel(
        id: 't1',
        title: 'x',
        description: '',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        source: TaskSource.personal,
        deadline: DateTime(2026, 6, 20),
        dueTime: '15:30',
      );
      final due = task.effectiveDueDateTime!;
      expect(due.hour, 15);
      expect(due.minute, 30);
      expect(due.day, 20);
    });

    test('falls back to date midnight when dueTime is invalid', () {
      final task = TaskModel(
        id: 't1',
        title: 'x',
        description: '',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        source: TaskSource.personal,
        deadline: DateTime(2026, 6, 20),
        dueTime: 'bad',
      );
      expect(task.effectiveDueDateTime!.day, 20);
    });
  });

  group('TaskModel.dueText', () {
    test('"Due today" when deadline is today', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 't1',
        title: 'x',
        description: '',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        source: TaskSource.personal,
        deadline: DateTime(now.year, now.month, now.day, 18),
      );
      expect(task.dueText, startsWith('Due today'));
    });

    test('returns "No due date" when neither deadline nor dueDate set', () {
      const task = TaskModel(
        id: 't1',
        title: 'x',
        description: '',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        source: TaskSource.personal,
      );
      expect(task.dueText, 'No due date');
    });
  });

  group('TaskModel.copyWith', () {
    test('replaces status without touching unchanged fields', () {
      const original = TaskModel(
        id: 't1',
        title: 'Original',
        description: '',
        status: TaskStatus.pending,
        priority: TaskPriority.medium,
        source: TaskSource.personal,
      );
      final updated = original.copyWith(status: TaskStatus.completed);
      expect(updated.status, TaskStatus.completed);
      expect(updated.title, 'Original');
      expect(updated.id, 't1');
    });
  });
}
