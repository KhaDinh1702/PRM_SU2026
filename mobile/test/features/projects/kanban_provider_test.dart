import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/projects/providers/kanban_provider.dart';
import 'package:prm_app/features/projects/utils/project_board_utils.dart';
import 'package:prm_app/features/tasks/models/task_model.dart';

TaskModel task({
  String id = 't',
  String title = 'Task',
  String description = '',
  TaskStatus status = TaskStatus.pending,
  TaskPriority priority = TaskPriority.medium,
  Map<String, dynamic>? assignee,
  DateTime? deadline,
}) {
  return TaskModel(
    id: id,
    title: title,
    description: description,
    status: status,
    priority: priority,
    source: TaskSource.project,
    deadline: deadline,
    assignedTo: assignee,
  );
}

void main() {
  group('KanbanProvider.groupTasks', () {
    test('groups tasks into the right columns based on status', () {
      final provider = KanbanProvider();
      final grouped = provider.groupTasks(
        [
          task(id: '1', status: TaskStatus.pending),
          task(id: '2', status: TaskStatus.inProgress),
          task(id: '3', status: TaskStatus.completed),
        ],
        {},
      );

      expect(grouped[BoardColumn.todo]!.length, 1);
      expect(grouped[BoardColumn.inProgress]!.length, 1);
      expect(grouped[BoardColumn.completed]!.length, 1);
      expect(grouped[BoardColumn.review]!.length, 0);
    });

    test('moves task to Review when reviewTaskIds contains its id', () {
      final provider = KanbanProvider();
      final grouped = provider.groupTasks(
        [task(id: '1', status: TaskStatus.inProgress)],
        {'1'},
      );
      expect(grouped[BoardColumn.review]!.length, 1);
      expect(grouped[BoardColumn.inProgress]!.length, 0);
    });

    test('search filter narrows by title / description', () {
      final provider = KanbanProvider()..setQuery('alpha');
      final grouped = provider.groupTasks(
        [
          task(id: '1', title: 'Alpha launch'),
          task(id: '2', title: 'Beta launch'),
          task(id: '3', title: 'Other', description: 'Touches the alpha plan'),
        ],
        {},
      );
      final all =
          grouped.values.expand((list) => list).toList(growable: false);
      expect(all.length, 2);
    });

    test('priority filter keeps only matching tasks', () {
      final provider = KanbanProvider()
        ..setPriorityFilter(KanbanPriority.high);
      final grouped = provider.groupTasks(
        [
          task(id: '1', priority: TaskPriority.high),
          task(id: '2', priority: TaskPriority.medium),
          task(id: '3', priority: TaskPriority.urgent), // also bucketed
        ],
        {},
      );
      final all =
          grouped.values.expand((list) => list).toList(growable: false);
      expect(all.length, 2);
    });

    test('assignee filter keeps only matching tasks', () {
      final provider = KanbanProvider()..setAssigneeFilter('u1');
      final grouped = provider.groupTasks(
        [
          task(id: '1', assignee: {'_id': 'u1', 'name': 'Alice'}),
          task(id: '2', assignee: {'_id': 'u2', 'name': 'Bob'}),
          task(id: '3'), // no assignee
        ],
        {},
      );
      final all =
          grouped.values.expand((list) => list).toList(growable: false);
      expect(all.length, 1);
    });

    test('priority sort orders Urgent > High > Medium > Low within a column',
        () {
      final provider = KanbanProvider()..setSort(KanbanSort.priority);
      final grouped = provider.groupTasks(
        [
          task(id: '1', priority: TaskPriority.low),
          task(id: '2', priority: TaskPriority.urgent),
          task(id: '3', priority: TaskPriority.medium),
          task(id: '4', priority: TaskPriority.high),
        ],
        {},
      );
      final todo = grouped[BoardColumn.todo]!;
      expect(todo.map((t) => t.priority), [
        TaskPriority.urgent,
        TaskPriority.high,
        TaskPriority.medium,
        TaskPriority.low,
      ]);
    });

    test('due-date sort puts soonest deadline first', () {
      final provider = KanbanProvider()..setSort(KanbanSort.dueDate);
      final now = DateTime.now();
      final grouped = provider.groupTasks(
        [
          task(id: '1', deadline: now.add(const Duration(days: 5))),
          task(id: '2', deadline: now.add(const Duration(days: 1))),
          task(id: '3', deadline: now.add(const Duration(days: 3))),
        ],
        {},
      );
      final todo = grouped[BoardColumn.todo]!;
      expect(todo.first.id, '2');
      expect(todo.last.id, '1');
    });
  });

  group('KanbanProvider state', () {
    test('toggleExpanded flips per-column boolean', () {
      final provider = KanbanProvider();
      expect(provider.isExpanded(BoardColumn.todo), isTrue);
      provider.toggleExpanded(BoardColumn.todo);
      expect(provider.isExpanded(BoardColumn.todo), isFalse);
    });

    test('clearFilters resets every filter and the query', () {
      final provider = KanbanProvider()
        ..setQuery('x')
        ..setStatusFilter(BoardColumn.review)
        ..setPriorityFilter(KanbanPriority.high)
        ..setAssigneeFilter('u1');
      provider.clearFilters();
      expect(provider.query, '');
      expect(provider.statusFilter, isNull);
      expect(provider.priorityFilter, isNull);
      expect(provider.assigneeFilter, isNull);
      expect(provider.activeFilterCount, 0);
    });
  });
}
