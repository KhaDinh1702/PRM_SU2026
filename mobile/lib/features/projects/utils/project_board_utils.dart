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
    dynamic task,
    Set<String> reviewTaskIds,
  ) {
    if (task is! Map) return BoardColumn.todo;
    final status = task['status']?.toString() ?? 'Pending';
    final id = task['_id']?.toString() ?? '';

    if (status == 'Completed') return BoardColumn.completed;
    if (status == 'In Progress') {
      return reviewTaskIds.contains(id)
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

  static int priorityWeight(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  static dynamic pickNextTask(List<dynamic> tasks) {
    final open = tasks.where((task) {
      if (task is! Map) return false;
      return (task['status'] ?? '') != 'Completed';
    }).toList();

    if (open.isEmpty) return null;

    open.sort((a, b) {
      final pa = priorityWeight(a['priority']?.toString());
      final pb = priorityWeight(b['priority']?.toString());
      if (pa != pb) return pb.compareTo(pa);

      final da = _dueMillis(a);
      final db = _dueMillis(b);
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1;
      if (db != null) return 1;
      return 0;
    });

    return open.first;
  }

  static int? _dueMillis(dynamic task) {
    if (task is! Map) return null;
    final raw = task['deadline'] ?? task['dueDate'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.millisecondsSinceEpoch;
  }
}
