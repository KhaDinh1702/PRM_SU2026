import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

enum TaskLoadStatus { initial, loading, loaded, error }

/// TaskProvider quản lý danh sách task, bộ lọc và trạng thái load.
/// Thay thế setState rải rác trong task_screen.dart.
class TaskProvider extends ChangeNotifier {
  final TaskService _service;

  TaskProvider({TaskService? service})
      : _service = service ?? const TaskService();

  // --- State ---
  List<TaskModel> _tasks = [];
  TaskLoadStatus _status = TaskLoadStatus.initial;
  String? _errorMessage;

  // Bộ lọc hiện tại
  String _currentTab = 'all';
  String _sortBy = 'recent';
  String? _sourceFilter;
  String? _statusFilter;
  String? _priorityFilter;
  String? _searchQuery;

  // --- Getters ---
  List<TaskModel> get tasks => _tasks;
  TaskLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == TaskLoadStatus.loading;

  String get currentTab => _currentTab;
  String get sortBy => _sortBy;
  String? get sourceFilter => _sourceFilter;
  String? get statusFilter => _statusFilter;
  String? get priorityFilter => _priorityFilter;
  String? get searchQuery => _searchQuery;

  int get pendingCount =>
      _tasks.where((t) => t.status == TaskStatus.pending).length;
  int get doneCount =>
      _tasks.where((t) => t.status == TaskStatus.completed).length;

  // --- Load với bộ lọc hiện tại ---
  Future<void> loadTasks({bool silent = false}) async {
    if (!silent) {
      _status = TaskLoadStatus.loading;
      notifyListeners();
    }
    try {
      final list = await _service.getTasks(
        tab: _currentTab,
        sortBy: _sortBy,
        sourceFilter: _sourceFilter,
        statusFilter: _statusFilter,
        priorityFilter: _priorityFilter,
        search: _searchQuery,
      );
      _tasks = list;
      _status = TaskLoadStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = TaskLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // --- Cập nhật bộ lọc rồi reload ---
  Future<void> applyFilters({
    String? tab,
    String? sortBy,
    String? sourceFilter,
    String? statusFilter,
    String? priorityFilter,
    String? searchQuery,
    bool clearFilters = false,
  }) async {
    if (clearFilters) {
      _sourceFilter = null;
      _statusFilter = null;
      _priorityFilter = null;
      _searchQuery = null;
    } else {
      if (tab != null) _currentTab = tab;
      if (sortBy != null) _sortBy = sortBy;
      if (sourceFilter != null) {
        _sourceFilter = sourceFilter == 'All' ? null : sourceFilter;
      }
      if (statusFilter != null) {
        _statusFilter = statusFilter == 'All' ? null : statusFilter;
      }
      if (priorityFilter != null) {
        _priorityFilter = priorityFilter == 'All' ? null : priorityFilter;
      }
      if (searchQuery != null) _searchQuery = searchQuery;
    }
    await loadTasks();
  }

  // --- Tạo task mới — returns new task id so the caller can attach
  // side-state (recurrence rule, ...).
  Future<String> createTask({
    required String title,
    String description = '',
    String priority = 'Medium',
    DateTime? dueDate,
  }) async {
    final id = await _service.createTask(
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
    );
    await loadTasks(silent: true);
    return id;
  }

  // --- Edit full task (title / description / priority / dueDate) ---
  Future<void> updateTask({
    required String taskId,
    required String title,
    String description = '',
    String priority = 'Medium',
    DateTime? dueDate,
  }) async {
    await _service.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
    );
    await loadTasks(silent: true);
  }

  // --- Cập nhật trạng thái task với optimistic update ---
  Future<void> updateTaskStatus({
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    // Optimistic update
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: newStatus);
      notifyListeners();
    }
    // Map enum về string cho API
    final statusString = newStatus == TaskStatus.completed
        ? 'Completed'
        : newStatus == TaskStatus.inProgress
            ? 'In Progress'
            : 'Pending';
    try {
      await _service.updateTaskStatus(taskId: taskId, newStatus: statusString);
    } catch (e) {
      // Revert nếu fail
      await loadTasks(silent: true);
      rethrow;
    }
  }

  // --- Xóa task ---
  Future<void> deleteTask(String taskId) async {
    await _service.deleteTask(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }
}
