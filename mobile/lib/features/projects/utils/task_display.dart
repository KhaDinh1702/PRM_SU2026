import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Display-layer helpers for project tasks (Map-shaped backend payloads).
///
/// These were previously top-level functions inside `widgets/project_tasks_tab.dart`,
/// which made that UI file double as a utility module. Moving them here lets
/// other UI files (board card, overview, etc.) depend on a `utils/` symbol
/// instead of importing a tab widget.
Color taskStatusColor(String status) {
  if (status == 'Completed') return AppColors.success;
  if (status == 'In Progress') return AppColors.taskAccent;
  return Colors.blueGrey;
}

Color taskPriorityColor(String priority) {
  if (priority == 'Urgent') return AppColors.priorityUrgent;
  if (priority == 'High') return AppColors.priorityHigh;
  if (priority == 'Medium') return AppColors.priorityMedium;
  return AppColors.priorityLow;
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

// --- Private helpers ---

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
