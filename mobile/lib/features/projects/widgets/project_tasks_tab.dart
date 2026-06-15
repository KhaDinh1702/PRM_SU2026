import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import 'project_shared.dart';
import 'project_card.dart';

// --- Utility functions (top-level, dùng bởi TasksTab) ---

Color taskStatusColor(String status) {
  if (status == 'Completed') return const Color(0xFF10B981);
  if (status == 'In Progress') return const Color(0xFF06B6D4);
  return Colors.blueGrey;
}

Color taskPriorityColor(String priority) {
  if (priority == 'Urgent') return const Color(0xFFDC2626);
  if (priority == 'High') return const Color(0xFFF43F5E);
  if (priority == 'Medium') return const Color(0xFFF59E0B);
  return const Color(0xFF10B981);
}

DateTime? _taskDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

TimeOfDay? _taskTime(dynamic value) {
  final raw = value?.toString() ?? '';
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _taskTimeText(TimeOfDay? time) {
  if (time == null) return 'End of day';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String taskDueText(dynamic task) {
  if (task is! Map) return 'No due date';
  final due = _taskDate(task['dueDate'] ?? task['deadline']);
  if (due == null) return 'No due date';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(due.year, due.month, due.day);
  final diff = dueDay.difference(today).inDays;
  final dateText = diff == 0
      ? 'Today'
      : diff == 1
          ? 'Tomorrow'
          : diff == -1
              ? 'Yesterday'
              : '${due.day}/${due.month}/${due.year}';
  return '$dateText · ${_taskTimeText(_taskTime(task['dueTime']))}';
}

bool taskIsVisuallyOverdue(dynamic task) {
  if (task is! Map) return false;
  if ((task['status'] ?? '').toString() == 'Completed') return false;
  final due = _taskDate(task['dueDate'] ?? task['deadline']);
  if (due == null) return false;
  final time = _taskTime(task['dueTime']);
  final dueAt = DateTime(
    due.year,
    due.month,
    due.day,
    time?.hour ?? 23,
    time?.minute ?? 59,
  );
  return dueAt.isBefore(DateTime.now());
}

String taskReminderLabel(dynamic task) {
  if (task is! Map || task['notificationEnabled'] != true) return '';
  switch ((task['reminderType'] ?? 'none').toString()) {
    case 'at_time':
      return 'Reminder: due time';
    case '15_min_before':
      return 'Reminder: 15 min';
    case '30_min_before':
      return 'Reminder: 30 min';
    case '1_hour_before':
      return 'Reminder: 1 hour';
    case '1_day_before':
      return 'Reminder: 1 day';
    case 'custom':
      return 'Reminder: custom';
    default:
      return '';
  }
}

// --- Widget ---

/// Tab danh sách task của project với filter và popup action.
class TasksTab extends StatelessWidget {
  final List<dynamic> tasks;
  final String selectedFilter;
  final bool isLoading;
  final bool tasksLoaded;
  final bool canManage;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onAddTask;
  final VoidCallback onLoadTasks;
  final String Function(dynamic assignee) assigneeName;
  final bool Function(dynamic task) canUpdateTask;
  final void Function(dynamic task) onEditTask;
  final void Function(dynamic task, String status) onUpdateStatus;

  const TasksTab({
    super.key,
    required this.tasks,
    required this.selectedFilter,
    required this.isLoading,
    required this.tasksLoaded,
    required this.canManage,
    required this.onFilterChanged,
    required this.onAddTask,
    required this.onLoadTasks,
    required this.assigneeName,
    required this.canUpdateTask,
    required this.onEditTask,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final filteredTasks = tasks.where((task) {
      final status = (task['status'] ?? 'Pending').toString();
      if (selectedFilter == 'To Do') return status == 'Pending';
      if (selectedFilter == 'Done') return status == 'Completed';
      if (selectedFilter == 'In Progress') return status == 'In Progress';
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final filter =
                          ['All', 'To Do', 'In Progress', 'Done'][index];
                      final selected = filter == selectedFilter;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(filter),
                        selectedColor: const Color(0xFF06B6D4),
                        labelStyle: TextStyle(
                            color: selected ? Colors.white : captionColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                        onSelected: (_) => onFilterChanged(filter),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: 4,
                  ),
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.add_task_rounded),
                  color: const Color(0xFF06B6D4),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
                  ? ProjectEmptyState(
                      icon: Icons.task_alt_rounded,
                      title: 'No tasks yet',
                      text:
                          'Create tasks to break this project into manageable work.',
                      cta: canManage ? 'Add task' : null,
                      onPressed: canManage ? onAddTask : null,
                    )
                  : filteredTasks.isEmpty
                      ? const ProjectEmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          title: 'No tasks in this filter',
                          text: 'Try a different task status.',
                          cta: null,
                          onPressed: null,
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final status =
                                (task['status'] ?? 'Pending').toString();
                            final priority =
                                (task['priority'] ?? 'Medium').toString();
                            final assignee = task['assignedTo'] ?? task['user'];
                            final overdue = taskIsVisuallyOverdue(task);
                            final color = overdue
                                ? const Color(0xFFF43F5E)
                                : taskStatusColor(status);
                            final reminderLabel = taskReminderLabel(task);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ProjectDetailCard(
                                padding: const EdgeInsets.all(14),
                                borderColor: color.withOpacity(0.24),
                                child: Row(
                                  children: [
                                    Icon(
                                      status == 'Completed'
                                          ? Icons.check_circle_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded,
                                      color: color,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task['title'] ?? 'Untitled task',
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${taskDueText(task)} · ${assigneeName(assignee)}',
                                            style: TextStyle(
                                                color: captionColor,
                                                fontSize: 11),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 7,
                                            runSpacing: 6,
                                            children: [
                                              ProjectStatusPill(
                                                label: overdue
                                                    ? 'Overdue'
                                                    : status,
                                                color: color,
                                              ),
                                              ProjectStatusPill(
                                                label: priority,
                                                color: taskPriorityColor(
                                                    priority),
                                              ),
                                              if (reminderLabel.isNotEmpty)
                                                ProjectStatusPill(
                                                  label: reminderLabel,
                                                  color:
                                                      const Color(0xFF8B5CF6),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (canUpdateTask(task))
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert_rounded,
                                            color: captionColor),
                                        onSelected: (value) {
                                          if (value == '__edit') {
                                            onEditTask(task);
                                          } else {
                                            onUpdateStatus(task, value);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (canManage)
                                            const PopupMenuItem(
                                              value: '__edit',
                                              child: Text('Edit'),
                                            ),
                                          if (canManage)
                                            const PopupMenuDivider(),
                                          ...[
                                            'Pending',
                                            'In Progress',
                                            'Completed',
                                          ].map((value) => PopupMenuItem(
                                                value: value,
                                                child: Text(value),
                                              )),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
