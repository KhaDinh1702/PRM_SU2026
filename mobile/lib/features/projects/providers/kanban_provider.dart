import 'package:flutter/foundation.dart';

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
        return 'Low';
      case KanbanPriority.medium:
        return 'Medium';
      case KanbanPriority.high:
        return 'High';
    }
  }
}

extension KanbanSortX on KanbanSort {
  String get label {
    switch (this) {
      case KanbanSort.dueDate:
        return 'Due Date';
      case KanbanSort.priority:
        return 'Priority';
      case KanbanSort.recentlyUpdated:
        return 'Recently Updated';
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
  Map<BoardColumn, List<dynamic>> groupTasks(
    List<dynamic> tasks,
    Set<String> reviewTaskIds,
  ) {
    final grouped = <BoardColumn, List<dynamic>>{
      for (final column in ProjectBoardUtils.columnOrder) column: [],
    };

    final query = _query.trim().toLowerCase();

    for (final task in tasks) {
      if (task is! Map) continue;
      final column = ProjectBoardUtils.columnForTask(task, reviewTaskIds);

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
    List<dynamic> tasks,
    String Function(dynamic assignee) resolveName,
  ) {
    final seen = <String>{};
    final result = <({String id, String name})>[];
    for (final task in tasks) {
      if (task is! Map) continue;
      final assignee = task['assignedTo'] ?? task['user'];
      final id = _assigneeId(assignee);
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      result.add((id: id, name: resolveName(assignee)));
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  // --- Internal helpers ---

  bool _matchesQuery(Map task, String query) {
    if (query.isEmpty) return true;
    final title = (task['title'] ?? '').toString().toLowerCase();
    final description = (task['description'] ?? '').toString().toLowerCase();
    return title.contains(query) || description.contains(query);
  }

  bool _matchesPriority(Map task) {
    if (_priorityFilter == null) return true;
    final raw = (task['priority'] ?? '').toString().toLowerCase();
    switch (_priorityFilter!) {
      case KanbanPriority.low:
        return raw == 'low';
      case KanbanPriority.medium:
        return raw == 'medium';
      case KanbanPriority.high:
        // Urgent is treated as a stronger flavour of High.
        return raw == 'high' || raw == 'urgent';
    }
  }

  bool _matchesAssignee(Map task) {
    if (_assigneeFilter == null) return true;
    final id = _assigneeId(task['assignedTo'] ?? task['user']);
    return id == _assigneeFilter;
  }

  int _compareTasks(dynamic a, dynamic b) {
    switch (_sort) {
      case KanbanSort.priority:
        final pa = ProjectBoardUtils.priorityWeight(a['priority']?.toString());
        final pb = ProjectBoardUtils.priorityWeight(b['priority']?.toString());
        if (pa != pb) return pb.compareTo(pa);
        return _compareByDue(a, b);
      case KanbanSort.recentlyUpdated:
        final ua = _millis(a, 'updatedAt') ?? _millis(a, 'createdAt');
        final ub = _millis(b, 'updatedAt') ?? _millis(b, 'createdAt');
        if (ua != null && ub != null) return ub.compareTo(ua);
        if (ua != null) return -1;
        if (ub != null) return 1;
        return 0;
      case KanbanSort.dueDate:
        return _compareByDue(a, b);
    }
  }

  int _compareByDue(dynamic a, dynamic b) {
    final da = _dueMillis(a);
    final db = _dueMillis(b);
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return 0;
  }

  static String _assigneeId(dynamic assignee) {
    if (assignee is Map) {
      return (assignee['_id'] ?? assignee['id'] ?? '').toString();
    }
    if (assignee == null) return '';
    return assignee.toString();
  }

  static int? _dueMillis(dynamic task) {
    if (task is! Map) return null;
    final raw = task['deadline'] ?? task['dueDate'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.millisecondsSinceEpoch;
  }

  static int? _millis(dynamic task, String key) {
    if (task is! Map) return null;
    final raw = task[key];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.millisecondsSinceEpoch;
  }
}
