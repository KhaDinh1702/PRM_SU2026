import 'package:flutter/foundation.dart';

import '../../../services/locale_service.dart';
import '../../tasks/models/task_model.dart';
import '../utils/project_board_utils.dart';

/// Sort criteria for the mobile Kanban board.
enum KanbanSort { dueDate, priority, recentlyUpdated }

/// Priority filter values aligned with the board task card.
/// `null` means "all priorities".
enum KanbanPriority { low, medium, high }

extension KanbanPriorityX on KanbanPriority {
  String get label {
    switch (this) {
      case KanbanPriority.low:
        return LocaleService.tr('Thấp', en: 'Low');
      case KanbanPriority.medium:
        return LocaleService.tr('Vừa', en: 'Medium');
      case KanbanPriority.high:
        return LocaleService.tr('Cao', en: 'High');
    }
  }
}

extension KanbanSortX on KanbanSort {
  String get label {
    switch (this) {
      case KanbanSort.dueDate:
        return LocaleService.tr('Hạn', en: 'Due Date');
      case KanbanSort.priority:
        return LocaleService.tr('Ưu tiên', en: 'Priority');
      case KanbanSort.recentlyUpdated:
        return LocaleService.tr('Mới cập nhật', en: 'Recently Updated');
    }
  }
}

/// Holds the transient UI state of the Kanban board (search, filter, sort,
/// accordion expansion). Persistence of tasks themselves still lives in the
/// existing [ProjectProvider] / parent screen — this provider only models the
/// presentation layer for the board.
class KanbanProvider extends ChangeNotifier {
  String _query = '';
  BoardColumn? _statusFilter;
  KanbanPriority? _priorityFilter;
  String? _assigneeFilter;
  KanbanSort _sort = KanbanSort.dueDate;

  final Map<BoardColumn, bool> _expanded = {
    for (final column in ProjectBoardUtils.columnOrder) column: true,
  };

  String get query => _query;
  BoardColumn? get statusFilter => _statusFilter;
  KanbanPriority? get priorityFilter => _priorityFilter;
  String? get assigneeFilter => _assigneeFilter;
  KanbanSort get sort => _sort;

  bool isExpanded(BoardColumn column) => _expanded[column] ?? true;

  bool get hasActiveFilter =>
      _statusFilter != null ||
      _priorityFilter != null ||
      _assigneeFilter != null;

  int get activeFilterCount =>
      (_statusFilter != null ? 1 : 0) +
      (_priorityFilter != null ? 1 : 0) +
      (_assigneeFilter != null ? 1 : 0);

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void setStatusFilter(BoardColumn? column) {
    if (_statusFilter == column) return;
    _statusFilter = column;
    notifyListeners();
  }

  void setPriorityFilter(KanbanPriority? priority) {
    if (_priorityFilter == priority) return;
    _priorityFilter = priority;
    notifyListeners();
  }

  void setAssigneeFilter(String? assigneeId) {
    if (_assigneeFilter == assigneeId) return;
    _assigneeFilter = assigneeId;
    notifyListeners();
  }

  void setSort(KanbanSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  void toggleExpanded(BoardColumn column) {
    _expanded[column] = !(_expanded[column] ?? true);
    notifyListeners();
  }

  void clearFilters() {
    if (!hasActiveFilter && _query.isEmpty) return;
    _statusFilter = null;
    _priorityFilter = null;
    _assigneeFilter = null;
    _query = '';
    notifyListeners();
  }

  /// Group the given task list into board columns after applying search,
  /// filter and sort. Tasks that don't match the active query / filters are
  /// dropped before grouping.
  Map<BoardColumn, List<TaskModel>> groupTasks(
    List<TaskModel> tasks,
  ) {
    final grouped = <BoardColumn, List<TaskModel>>{
      for (final column in ProjectBoardUtils.columnOrder) column: [],
    };

    final query = _query.trim().toLowerCase();

    for (final task in tasks) {
      final column = ProjectBoardUtils.columnForTask(task);

      if (_statusFilter != null && _statusFilter != column) continue;
      if (!_matchesQuery(task, query)) continue;
      if (!_matchesPriority(task)) continue;
      if (!_matchesAssignee(task)) continue;

      grouped[column]!.add(task);
    }

    for (final entry in grouped.entries) {
      entry.value.sort(_compareTasks);
    }
    return grouped;
  }

  /// Build a deduplicated list of `(id, name)` pairs for the assignee filter
  /// popup, derived from the supplied tasks. Tasks without an assignee are
  /// ignored.
  List<({String id, String name})> assigneeOptions(
    List<TaskModel> tasks,
    String Function(Map<String, dynamic>? assignee) resolveName,
  ) {
    final seen = <String>{};
    final result = <({String id, String name})>[];
    for (final task in tasks) {
      final assignee = task.assignedTo;
      final id = _assigneeId(assignee);
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      result.add((id: id, name: resolveName(assignee)));
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  // --- Internal helpers ---

  bool _matchesQuery(TaskModel task, String query) {
    if (query.isEmpty) return true;
    final title = task.title.toLowerCase();
    final description = task.description.toLowerCase();
    return title.contains(query) || description.contains(query);
  }

  bool _matchesPriority(TaskModel task) {
    if (_priorityFilter == null) return true;
    switch (_priorityFilter!) {
      case KanbanPriority.low:
        return task.priority == TaskPriority.low;
      case KanbanPriority.medium:
        return task.priority == TaskPriority.medium;
      case KanbanPriority.high:
        // Urgent is treated as a stronger flavour of High.
        return task.priority == TaskPriority.high ||
            task.priority == TaskPriority.urgent;
    }
  }

  bool _matchesAssignee(TaskModel task) {
    if (_assigneeFilter == null) return true;
    return _assigneeId(task.assignedTo) == _assigneeFilter;
  }

  int _compareTasks(TaskModel a, TaskModel b) {
    switch (_sort) {
      case KanbanSort.priority:
        final pa = ProjectBoardUtils.priorityWeight(a.priority);
        final pb = ProjectBoardUtils.priorityWeight(b.priority);
        if (pa != pb) return pb.compareTo(pa);
        return _compareByDue(a, b);
      case KanbanSort.recentlyUpdated:
        // TaskModel does not carry updatedAt explicitly — fall back to
        // due-date ordering which is the next-most-meaningful signal.
        return _compareByDue(a, b);
      case KanbanSort.dueDate:
        return _compareByDue(a, b);
    }
  }

  int _compareByDue(TaskModel a, TaskModel b) {
    final da = a.effectiveDueDateTime?.millisecondsSinceEpoch;
    final db = b.effectiveDueDateTime?.millisecondsSinceEpoch;
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return 0;
  }

  static String _assigneeId(Map<String, dynamic>? assignee) {
    if (assignee == null) return '';
    return (assignee['_id'] ?? assignee['id'] ?? '').toString();
  }
}
