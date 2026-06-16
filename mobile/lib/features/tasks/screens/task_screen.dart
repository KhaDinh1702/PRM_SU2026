import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_empty_state.dart';
import '../widgets/task_filter_sheet.dart';
import '../widgets/task_summary_bar.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  static const Color _accent = AppColors.taskAccent;
  static const List<String> _tabs = [
    'Today',
    'Upcoming',
    'Overdue',
    'Project',
    'Personal',
    'Completed',
  ];

  bool _isLoading = true;
  List<dynamic> _tasks = [];
  String _selectedTab = 'Today';
  String _sourceFilter = 'All';
  String _statusFilter = 'All';
  String _priorityFilter = 'All';
  String _sortBy = 'recent';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _taskPriority = 'Medium';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- API Methods ---

  Map<String, dynamic> _taskModelToMap(TaskModel task) {
    final statusString = task.status == TaskStatus.completed
        ? 'Completed'
        : task.status == TaskStatus.inProgress
            ? 'In Progress'
            : 'Pending';

    final priorityString = task.priority == TaskPriority.urgent
        ? 'Urgent'
        : task.priority == TaskPriority.high
            ? 'High'
            : task.priority == TaskPriority.medium
                ? 'Medium'
                : 'Low';

    final sourceString = task.source == TaskSource.project
        ? 'project'
        : task.source == TaskSource.schedule
            ? 'schedule'
            : 'personal';

    return {
      '_id': task.id,
      'title': task.title,
      'description': task.description,
      'status': statusString,
      'priority': priorityString,
      'sourceType': sourceString,
      'deadline': task.deadline?.toIso8601String(),
      'dueDate': task.dueDate?.toIso8601String(),
      'dueTime': task.dueTime,
      'notificationEnabled': task.notificationEnabled,
      'reminderType': task.reminderType,
      'project': task.project,
      'assignedTo': task.assignedTo,
    };
  }

  Future<void> _loadTasks() async {
    if (mounted) {
      await context.read<TaskProvider>().applyFilters(
        tab: _selectedTab,
        sortBy: _sortBy,
        sourceFilter: _sourceFilter,
        statusFilter: _statusFilter,
        priorityFilter: _priorityFilter,
        searchQuery: _searchController.text.trim(),
      );
    }
  }

  Future<void> _createTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    try {
      await context.read<TaskProvider>().createTask(
        title: title,
        description: _descController.text.trim(),
        priority: _taskPriority,
      );
      _titleController.clear();
      _descController.clear();
      _taskPriority = 'Medium';
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Task added successfully', _accent);
      }
    } catch (_) {
      if (mounted) _showSnack('Could not create task', Colors.redAccent);
    }
  }

  Future<void> _toggleTaskComplete(Map<String, dynamic> task) async {
    final taskId = task['_id']?.toString();
    if (taskId == null || taskId.isEmpty) return;

    final currentStatus = task['status']?.toString() ?? 'Pending';
    final newStatus = currentStatus == 'Completed' ? TaskStatus.pending : TaskStatus.completed;

    try {
      await context.read<TaskProvider>().updateTaskStatus(
        taskId: taskId,
        newStatus: newStatus,
      );
      _showSnack(
        newStatus == TaskStatus.completed ? 'Task completed' : 'Task reopened',
        newStatus == TaskStatus.completed ? AppColors.success : Colors.amber,
      );
    } catch (_) {
      if (mounted) _showSnack('Could not update task', Colors.redAccent);
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final taskId = task['_id']?.toString();
    if (taskId == null || taskId.isEmpty) return;

    try {
      await context.read<TaskProvider>().deleteTask(taskId);
      _showSnack('Task deleted successfully', Colors.redAccent);
    } catch (_) {
      if (mounted) _showSnack('Could not delete task', Colors.redAccent);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- Dialogs ---

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final subTextColor = ThemeService.getSubTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AlertDialog(
                backgroundColor: dialogBg.withValues(alpha: 0.94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                title: Text(
                  'CREATE PERSONAL TASK',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumInputField(
                      controller: _titleController,
                      label: 'Task title *',
                      hintText: 'Enter title...',
                      prefixIcon: Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    PremiumInputField(
                      controller: _descController,
                      label: 'Short description',
                      hintText: 'Enter details...',
                      prefixIcon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Priority',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _taskPriority,
                              dropdownColor: dialogBg,
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: subTextColor),
                              items: ['Low', 'Medium', 'High', 'Urgent']
                                  .map(
                                    (value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() => _taskPriority = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Project tasks are assigned inside Project Detail and appear here automatically.',
                      style: TextStyle(color: captionColor, fontSize: 11),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                          color: captionColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PremiumButton(
                    onPressed: _createTask,
                    backgroundColor: _accent,
                    child: const Text(
                      'Create',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showFilterSheet() async {
    final result = await showTaskFilterSheet(
      context,
      sourceFilter: _sourceFilter,
      statusFilter: _statusFilter,
      priorityFilter: _priorityFilter,
      sortBy: _sortBy,
    );
    if (result != null && mounted) {
      setState(() {
        _sourceFilter = result.source;
        _statusFilter = result.status;
        _priorityFilter = result.priority;
        _sortBy = result.sort;
      });
      _loadTasks();
    }
  }

  // --- Data helpers ---

  Map<String, List<Map<String, dynamic>>> _groupTasks() {
    final groups = <String, List<Map<String, dynamic>>>{
      'Overdue': [],
      'Today': [],
      'Tomorrow': [],
      'This Week': [],
      'Later': [],
      'No Due Date': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    for (final rawTask in _tasks) {
      final task = Map<String, dynamic>.from(rawTask as Map);
      final status = task['status']?.toString() ?? 'Pending';
      final due = _taskDueDate(task);

      if (due == null) {
        groups['No Due Date']!.add(task);
        continue;
      }

      final dueDay = DateTime(due.year, due.month, due.day);
      if (due.isBefore(now) && status != 'Completed') {
        groups['Overdue']!.add(task);
      } else if (dueDay == today) {
        groups['Today']!.add(task);
      } else if (dueDay == tomorrow) {
        groups['Tomorrow']!.add(task);
      } else if (dueDay.isBefore(weekEnd)) {
        groups['This Week']!.add(task);
      } else {
        groups['Later']!.add(task);
      }
    }

    groups.removeWhere((_, value) => value.isEmpty);
    return groups;
  }

  DateTime? _taskDueDate(Map<String, dynamic> task) {
    final value = task['deadline'] ?? task['dueDate'];
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString())?.toLocal();
    if (parsed == null) return null;
    final dueTime = _parseTaskTime(task['dueTime']);
    if (dueTime == null) return parsed;
    return DateTime(
        parsed.year, parsed.month, parsed.day, dueTime.hour, dueTime.minute);
  }

  TimeOfDay? _parseTaskTime(dynamic value) {
    final raw = value?.toString() ?? '';
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _sourceLabel(Map<String, dynamic> task) {
    final source = task['sourceType']?.toString();
    if (source == 'project' || task['project'] != null) return 'Project';
    if (source == 'schedule' || task['scheduleId'] != null) return 'Schedule';
    return 'Personal';
  }

  String _projectName(Map<String, dynamic> task) {
    final project = task['project'];
    if (project is Map && project['name'] != null) {
      return project['name'].toString();
    }
    return '';
  }

  String _assigneeName(Map<String, dynamic> task) {
    final assignee = task['assignedTo'];
    if (assignee is Map) {
      return assignee['name']?.toString().isNotEmpty == true
          ? assignee['name'].toString()
          : assignee['email']?.toString() ?? '';
    }
    return '';
  }

  String _dueText(Map<String, dynamic> task) {
    final due = _taskDueDate(task);
    if (due == null) return 'No due date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final days = dueDay.difference(today).inDays;
    final time =
        '${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}';

    if (days == 0) return 'Due today · $time';
    if (days == 1) return 'Tomorrow · $time';
    if (days == -1) return 'Yesterday · $time';
    if (days < -1) return '${days.abs()} days overdue';
    return '${due.day}/${due.month}/${due.year} · $time';
  }

  String _reminderLabel(Map<String, dynamic> task) {
    if (task['notificationEnabled'] != true) return '';
    switch ((task['reminderType'] ?? 'none').toString()) {
      case 'at_time':
        return 'Reminder: due time';
      case '15_min_before':
        return 'Reminder: 15 min before';
      case '30_min_before':
        return 'Reminder: 30 min before';
      case '1_hour_before':
        return 'Reminder: 1 hour before';
      case '1_day_before':
        return 'Reminder: 1 day before';
      case 'custom':
        return 'Reminder: custom';
      default:
        return '';
    }
  }

  Color _priorityColor(String priority) {
    if (priority == 'Urgent') return AppColors.priorityUrgent;
    if (priority == 'High') return AppColors.priorityHigh;
    if (priority == 'Medium') return AppColors.priorityMedium;
    return AppColors.priorityLow;
  }

  Color _sourceColor(String source) {
    if (source == 'Project') return _accent;
    if (source == 'Schedule') return AppColors.timerFocus;
    return AppColors.success;
  }

  Color _statusColor(String status, bool overdue) {
    if (overdue) return AppColors.error;
    if (status == 'Completed') return AppColors.success;
    if (status == 'In Progress') return _accent;
    return const Color(0xFF94A3B8);
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        _tasks = provider.tasks.map(_taskModelToMap).toList();
        _isLoading = provider.isLoading;

        return ListenableBuilder(
          listenable: Listenable.merge(
              [ThemeService.isDarkMode, LocaleService.languageCode]),
          builder: (context, child) {
            final isDark = ThemeService.isDarkMode.value;
            final textColor = ThemeService.getTextColor(isDark);
            final subTextColor = ThemeService.getSubTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);
            final cardColor = ThemeService.getCardColor(isDark);
            final borderColor = ThemeService.getBorderColor(isDark);
            final groupedTasks = _groupTasks();

        final projectCount = _tasks
            .where((task) =>
                _sourceLabel(Map<String, dynamic>.from(task as Map)) ==
                'Project')
            .length;
        final overdueCount = _tasks.where((task) {
          final map = Map<String, dynamic>.from(task as Map);
          final due = _taskDueDate(map);
          return due != null &&
              due.isBefore(DateTime.now()) &&
              map['status'] != 'Completed';
        }).length;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UNIFIED INBOX',
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tasks',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Filters',
                      onPressed: _showFilterSheet,
                      icon: Icon(Icons.tune_rounded, color: subTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Summary bar + New button
                TaskSummaryBar(
                  totalCount: _tasks.length,
                  projectCount: projectCount,
                  overdueCount: overdueCount,
                  onAddTask: _showCreateTaskDialog,
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadTasks(),
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle:
                          TextStyle(color: captionColor, fontSize: 14),
                      prefixIcon:
                          Icon(Icons.search_rounded, color: captionColor),
                      suffixIcon: _searchController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _loadTasks();
                              },
                              icon: Icon(Icons.close_rounded,
                                  color: captionColor, size: 18),
                            ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Tab chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      final selected = _selectedTab == tab;
                      return ChoiceChip(
                        label: Text(tab),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: _accent.withValues(alpha: 0.18),
                        backgroundColor: cardColor,
                        side: BorderSide(
                          color: selected ? _accent : borderColor,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? _accent : subTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedTab = tab);
                          _loadTasks();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                // Task list
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          itemCount: 6,
                          itemBuilder: (_, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: ShimmerLoading(
                              width: double.infinity,
                              height: 112,
                              borderRadius: 22,
                            ),
                          ),
                        )
                      : groupedTasks.isEmpty
                          ? TaskEmptyState(
                              textColor: textColor,
                              captionColor: captionColor,
                              onAddTask: _showCreateTaskDialog,
                            )
                          : RefreshIndicator(
                              color: _accent,
                              onRefresh: _loadTasks,
                              child: ListView(
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  for (final entry
                                      in groupedTasks.entries) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 10),
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(
                                          color: captionColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ),
                                    for (final task in entry.value)
                                      TaskInboxCard(
                                        task: task,
                                        textColor: textColor,
                                        subTextColor: subTextColor,
                                        captionColor: captionColor,
                                        source: _sourceLabel(task),
                                        sourceColor:
                                            _sourceColor(_sourceLabel(task)),
                                        projectName: _projectName(task),
                                        assigneeName: _assigneeName(task),
                                        dueText: _dueText(task),
                                        reminderLabel: _reminderLabel(task),
                                        priorityColor: _priorityColor(
                                          task['priority']?.toString() ??
                                              'Medium',
                                        ),
                                        statusColor: _statusColor(
                                          task['status']?.toString() ??
                                              'Pending',
                                          entry.key == 'Overdue',
                                        ),
                                        onToggle: () =>
                                            _toggleTaskComplete(task),
                                        onDelete: _sourceLabel(task) ==
                                                'Personal'
                                            ? () => _deleteTask(task)
                                            : null,
                                      ),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }
}
