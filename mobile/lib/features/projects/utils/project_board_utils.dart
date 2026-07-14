import '../../../services/locale_service.dart';
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

  /// Localized label for [column], used by the board UI. The English keys
  /// above remain stable identifiers for tests / persistence.
  static String labelFor(BoardColumn column) {
    switch (column) {
      case BoardColumn.todo:
        return LocaleService.tr('Cần làm', en: todoLabel);
      case BoardColumn.inProgress:
        return LocaleService.tr('Đang làm', en: inProgressLabel);
      case BoardColumn.review:
        return LocaleService.tr('Kiểm tra', en: reviewLabel);
      case BoardColumn.completed:
        return LocaleService.tr('Hoàn tất', en: completedLabel);
    }
  }

  static BoardColumn columnForTask(TaskModel task) {
    switch (task.status) {
      case TaskStatus.pending:
        return BoardColumn.todo;
      case TaskStatus.inProgress:
        return BoardColumn.inProgress;
      case TaskStatus.review:
        return BoardColumn.review;
      case TaskStatus.completed:
        return BoardColumn.completed;
    }
  }

  static String apiStatusForColumn(BoardColumn column) {
    switch (column) {
      case BoardColumn.todo:
        return 'Pending';
      case BoardColumn.inProgress:
        return 'In Progress';
      case BoardColumn.review:
        return 'Review';
      case BoardColumn.completed:
        return 'Completed';
    }
  }

  static BoardColumn? nextColumn(BoardColumn column) {
    final index = columnOrder.indexOf(column);
    if (index < 0 || index >= columnOrder.length - 1) return null;
    return columnOrder[index + 1];
  }

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
    final open =
        tasks.where((task) => task.status != TaskStatus.completed).toList();
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
