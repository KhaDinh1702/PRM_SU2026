import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/checklist_item.dart';
import '../models/recurrence_rule.dart';
import '../models/task_model.dart';
import '../models/task_tag.dart';
import '../providers/task_provider.dart';
import '../services/checklist_service.dart';
import '../services/recurrence_service.dart';
import '../services/tag_service.dart';
import '../widgets/due_date_picker.dart';
import '../widgets/priority_picker.dart';
import '../widgets/recurrence_picker.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_sheet.dart';
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

  /// Maps tab key → localized label for display only. Keys stay English
  /// because filter logic compares against them.
  String _tabLabel(String key) {
    switch (key) {
      case 'Today':
        return LocaleService.tr('Hôm nay', en: 'Today');
      case 'Upcoming':
        return LocaleService.tr('Sắp tới', en: 'Upcoming');
      case 'Overdue':
        return LocaleService.tr('Quá hạn', en: 'Overdue');
      case 'Project':
        return LocaleService.tr('Dự án', en: 'Project');
      case 'Personal':
        return LocaleService.tr('Cá nhân', en: 'Personal');
      case 'Completed':
        return LocaleService.tr('Hoàn tất', en: 'Completed');
      default:
        return key;
    }
  }

  /// Localized label for `_groupTasks` keys.
  String _groupLabel(String key) {
    switch (key) {
      case 'Overdue':
        return LocaleService.tr('QUÁ HẠN', en: 'OVERDUE');
      case 'Today':
        return LocaleService.tr('HÔM NAY', en: 'TODAY');
      case 'Tomorrow':
        return LocaleService.tr('NGÀY MAI', en: 'TOMORROW');
      case 'This Week':
        return LocaleService.tr('TUẦN NÀY', en: 'THIS WEEK');
      case 'Later':
        return LocaleService.tr('SAU NÀY', en: 'LATER');
      case 'No Due Date':
        return LocaleService.tr('CHƯA CÓ HẠN', en: 'NO DUE DATE');
      default:
        return key.toUpperCase();
    }
  }

  bool _isLoading = true;
  List<TaskModel> _tasks = [];
  String _selectedTab = 'Today';
  String _sourceFilter = 'All';
  String _statusFilter = 'All';
  String _priorityFilter = 'All';
  String _sortBy = 'recent';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _taskPriority = 'Medium';

  /// In-progress recurrence rule for the Create Task dialog. Cleared after
  /// each successful submit.
  RecurrenceRule? _draftRecurrence;

  /// In-progress due date/time for the Create Task dialog. Defaults are
  /// computed at submit time based on the active tab when the user leaves
  /// this `null`.
  DateTime? _draftDueDate;

  /// Cache of task IDs that have an attached recurrence rule. Populated
  /// after each `loadTasks`, drives the small "Repeat" badge on task cards.
  Set<String> _recurringTaskIds = const {};

  /// Per-task checklist progress (done/total). Drives the subtask badge.
  Map<String, ChecklistProgress> _checklistProgress = const {};

  /// Per-task assigned tags. Drives the tag chip strip on each card.
  Map<String, List<TaskTag>> _taskTags = const {};

  final RecurrenceService _recurrenceService = const RecurrenceService();
  final ChecklistService _checklistService = const ChecklistService();
  final TagService _tagService = const TagService();

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

  Future<void> _loadTasks() async {
    if (!mounted) return;
    await context.read<TaskProvider>().applyFilters(
      tab: _selectedTab,
      sortBy: _sortBy,
      sourceFilter: _sourceFilter,
      statusFilter: _statusFilter,
      priorityFilter: _priorityFilter,
      searchQuery: _searchController.text.trim(),
    );
    await _refreshSideState();
  }

  /// Refreshes everything the screen caches alongside the task list:
  /// recurrence flag, checklist progress, attached tags.
  Future<void> _refreshSideState() async {
    if (!mounted) return;
    final tasks = context.read<TaskProvider>().tasks
        .where((t) => t.id.isNotEmpty)
        .toList(growable: false);

    final results = await Future.wait(
      tasks.map((t) async {
        final rule = await _recurrenceService.loadRule(t.id);
        final progress = await _checklistService.loadProgress(t.id);
        final tags = await _tagService.loadAssignedTags(t.id);
        return (id: t.id, rule: rule, progress: progress, tags: tags);
      }),
    );

    if (!mounted) return;
    setState(() {
      _recurringTaskIds = {
        for (final entry in results)
          if (entry.rule != null) entry.id,
      };
      _checklistProgress = {
        for (final entry in results)
          if (entry.progress.hasItems) entry.id: entry.progress,
      };
      _taskTags = {
        for (final entry in results)
          if (entry.tags.isNotEmpty) entry.id: entry.tags,
      };
    });
  }

  Future<void> _createTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    try {
      final dueDate = _draftDueDate ??
          (_selectedTab == 'Upcoming'
              ? DateTime.now().add(const Duration(days: 1))
              : DateTime.now());
      final newId = await context.read<TaskProvider>().createTask(
            title: title,
            description: _descController.text.trim(),
            priority: _taskPriority,
            dueDate: dueDate,
          );
      if (_draftRecurrence != null && newId.isNotEmpty) {
        await _recurrenceService.saveRule(newId, _draftRecurrence!);
      }
      _titleController.clear();
      _descController.clear();
      _taskPriority = 'Medium';
      _draftRecurrence = null;
      _draftDueDate = null;
      if (mounted) {
        Navigator.pop(context);
        _showSnack(
          LocaleService.tr('Đã tạo task', en: 'Task added successfully'),
          _accent,
        );
        await _refreshSideState();
      }
    } catch (_) {
      if (mounted) {
        _showSnack(
          LocaleService.tr('Không thể tạo task', en: 'Could not create task'),
          Colors.redAccent,
        );
      }
    }
  }

  Future<void> _toggleTaskComplete(TaskModel task) async {
    final taskId = task.id;
    if (taskId.isEmpty) return;

    final wasCompleted = task.status == TaskStatus.completed;
    final newStatus =
        wasCompleted ? TaskStatus.pending : TaskStatus.completed;

    try {
      await context.read<TaskProvider>().updateTaskStatus(
            taskId: taskId,
            newStatus: newStatus,
          );

      // When a recurring task transitions to completed, spawn the next
      // instance with the next-occurrence date and transfer the rule onto it.
      if (!wasCompleted) {
        await _spawnNextRecurringInstance(task);
      }

      if (!mounted) return;
      _showSnack(
        newStatus == TaskStatus.completed
            ? LocaleService.tr('Đã hoàn thành task', en: 'Task completed')
            : LocaleService.tr('Đã mở lại task', en: 'Task reopened'),
        newStatus == TaskStatus.completed ? AppColors.success : Colors.amber,
      );
    } catch (_) {
      if (mounted) {
        _showSnack(
          LocaleService.tr('Không thể cập nhật task',
              en: 'Could not update task'),
          Colors.redAccent,
        );
      }
    }
  }

  /// If [completedTask] had a recurrence rule, create a fresh task at the
  /// next-occurrence date and move the rule onto the new task id. Series
  /// auto-ends when the rule's endDate is passed.
  Future<void> _spawnNextRecurringInstance(TaskModel completedTask) async {
    final rule = await _recurrenceService.loadRule(completedTask.id);
    if (rule == null) return;
    final currentDue = completedTask.effectiveDueDateTime ?? DateTime.now();
    final nextDue = rule.nextOccurrence(currentDue);
    if (nextDue == null) {
      await _recurrenceService.deleteRule(completedTask.id);
      return;
    }
    if (!mounted) return;
    final newId = await context.read<TaskProvider>().createTask(
          title: completedTask.title,
          description: completedTask.description,
          priority: completedTask.priorityLabel,
          dueDate: nextDue,
        );
    if (newId.isNotEmpty) {
      await _recurrenceService.transferRule(
        oldTaskId: completedTask.id,
        newTaskId: newId,
      );
    }
    if (mounted) await _refreshSideState();
  }

  Future<void> _openTaskDetail(TaskModel task) async {
    final result = await TaskDetailSheet.show(context, task: task);
    if (!mounted) return;
    // Always refresh side state — the sheet may be dismissed by swipe
    // (returns null) but still have mutated checklist/tags through saves.
    await _refreshSideState();
    if (result?.allSubtasksDone == true &&
        task.status != TaskStatus.completed) {
      await _toggleTaskComplete(task);
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final taskId = task.id;
    if (taskId.isEmpty) return;

    try {
      await context.read<TaskProvider>().deleteTask(taskId);
      _showSnack(
        LocaleService.tr('Đã xoá task', en: 'Task deleted successfully'),
        Colors.redAccent,
      );
    } catch (_) {
      if (mounted) {
        _showSnack(
          LocaleService.tr('Không thể xoá task', en: 'Could not delete task'),
          Colors.redAccent,
        );
      }
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
    // Start each dialog from a clean draft so leftover values from a
    // cancelled previous open don't surprise the user.
    _draftDueDate = null;
    _draftRecurrence = null;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
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
                  LocaleService.tr('TẠO TASK CÁ NHÂN',
                      en: 'CREATE PERSONAL TASK'),
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
                      label: LocaleService.tr('Tên task *', en: 'Task title *'),
                      hintText: LocaleService.tr('Nhập tên task...',
                          en: 'Enter title...'),
                      prefixIcon: Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    PremiumInputField(
                      controller: _descController,
                      label: LocaleService.tr('Mô tả ngắn',
                          en: 'Short description'),
                      hintText: LocaleService.tr('Chi tiết...',
                          en: 'Enter details...'),
                      prefixIcon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 14),
                    DueDatePickerTile(
                      value: _draftDueDate,
                      onChanged: (value) =>
                          setDialogState(() => _draftDueDate = value),
                    ),
                    const SizedBox(height: 10),
                    PriorityPickerTile(
                      value: _taskPriority,
                      onChanged: (value) =>
                          setDialogState(() => _taskPriority = value),
                    ),
                    const SizedBox(height: 10),
                    RecurrencePickerTile(
                      rule: _draftRecurrence,
                      onChanged: (next) =>
                          setDialogState(() => _draftRecurrence = next),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      LocaleService.tr(
                        'Task dự án được giao trong màn Chi tiết dự án và tự động hiện ở đây.',
                        en: 'Project tasks are assigned inside Project Detail and appear here automatically.',
                      ),
                      style: TextStyle(color: captionColor, fontSize: 11),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      LocaleService.tr('Huỷ', en: 'Cancel'),
                      style: TextStyle(
                          color: captionColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PremiumButton(
                    onPressed: _createTask,
                    backgroundColor: _accent,
                    child: Text(
                      LocaleService.tr('Tạo', en: 'Create'),
                      style: const TextStyle(
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

  Map<String, List<TaskModel>> _groupTasks() {
    final groups = <String, List<TaskModel>>{
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

    for (final task in _tasks) {
      final status = task.status;
      final due = task.effectiveDueDateTime;

      if (due == null) {
        groups['No Due Date']!.add(task);
        continue;
      }

      final dueDay = DateTime(due.year, due.month, due.day);
      if (due.isBefore(now) && status != TaskStatus.completed) {
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

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        _tasks = provider.tasks;
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
                .where((task) => task.source == TaskSource.project)
                .length;
            final overdueCount = _tasks.where((task) => task.isOverdue).length;

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
                                LocaleService.tr('HỘP THƯ THỐNG NHẤT',
                                    en: 'UNIFIED INBOX'),
                                style: TextStyle(
                                  color: captionColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                LocaleService.tr('Nhiệm vụ', en: 'Tasks'),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const NotificationBell(),
                        IconButton(
                          tooltip: LocaleService.tr('Bộ lọc', en: 'Filters'),
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
                          hintText: LocaleService.tr('Tìm task...',
                              en: 'Search tasks...'),
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
                            label: Text(_tabLabel(tab)),
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
                                            _groupLabel(entry.key),
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
                                            isRecurring:
                                                _recurringTaskIds.contains(task.id),
                                            checklistProgress:
                                                _checklistProgress[task.id] ??
                                                    ChecklistProgress.empty,
                                            tags: _taskTags[task.id] ??
                                                const [],
                                            onOpen: () =>
                                                _openTaskDetail(task),
                                            onToggle: () =>
                                                _toggleTaskComplete(task),
                                            onDelete: task.source == TaskSource.personal
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
