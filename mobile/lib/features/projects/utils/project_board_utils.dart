import '../../tasks/models/task_model.dart';

/// Mobile Kanban columns mapped to backend task statuses.
enum BoardColumn { todo, inProgress, review, completed }

class ProjectBoardUtils {
  static const todoLabel = 'To Do';
  static const inProgressLabel = 'In Progress';
  static const reviewLabel = 'Review';
  static const completedLabel = 'Completed';

  static const columnOrder = [
    BoardColumn.todo,
    BoardColumn.inProgress,
    BoardColumn.review,
    BoardColumn.completed,
  ];

  static String labelFor(BoardColumn column) {
    switch (column) {
      case BoardColumn.todo:
        return todoLabel;
      case BoardColumn.inProgress:
        return inProgressLabel;
      case BoardColumn.review:
        return reviewLabel;
      case BoardColumn.completed:
        return completedLabel;
    }
  }

  static BoardColumn columnForTask(
    TaskModel task,
    Set<String> reviewTaskIds,
  ) {
    if (task.status == TaskStatus.completed) return BoardColumn.completed;
    if (task.status == TaskStatus.inProgress) {
      return reviewTaskIds.contains(task.id)
          ? BoardColumn.review
          : BoardColumn.inProgress;
    }
    return BoardColumn.todo;
  }

  static String apiStatusForColumn(BoardColumn column) {
    switch (column) {
      case BoardColumn.todo:
        return 'Pending';
      case BoardColumn.inProgress:
      case BoardColumn.review:
        return 'In Progress';
      case BoardColumn.completed:
        return 'Completed';
    }
  }

  static BoardColumn? nextColumn(BoardColumn column) {
    final index = columnOrder.indexOf(column);
    if (index < 0 || index >= columnOrder.length - 1) return null;
    return columnOrder[index + 1];
  }

  static bool shouldMarkReview(BoardColumn column) =>
      column == BoardColumn.review;

  static int priorityWeight(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return 4;
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }

  /// Picks the most important still-open task — used by the project overview
  /// "next task" surface.
  static TaskModel? pickNextTask(List<TaskModel> tasks) {
    final open = tasks
        .where((task) => task.status != TaskStatus.completed)
        .toList();
    if (open.isEmpty) return null;

    open.sort((a, b) {
      final pa = priorityWeight(a.priority);
      final pb = priorityWeight(b.priority);
      if (pa != pb) return pb.compareTo(pa);

      final da = a.effectiveDueDateTime?.millisecondsSinceEpoch;
      final db = b.effectiveDueDateTime?.millisecondsSinceEpoch;
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1;
      if (db != null) return 1;
      return 0;
    });

    return open.first;
  }
}
