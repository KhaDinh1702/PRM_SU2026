import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../tasks/models/task_model.dart';

/// Display-layer helpers for project tasks.
///
/// These now consume [TaskModel] rather than raw `Map<String, dynamic>`.
/// The board cards, the project tasks tab and the overview "next task"
/// card all share these helpers — keeping them off the UI files makes the
/// status / priority / due-date conventions consistent.
Color taskStatusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.completed:
      return AppColors.success;
    case TaskStatus.inProgress:
      return AppColors.taskAccent;
    case TaskStatus.pending:
      return Colors.blueGrey;
  }
}

Color taskPriorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.urgent:
      return AppColors.priorityUrgent;
    case TaskPriority.high:
      return AppColors.priorityHigh;
    case TaskPriority.medium:
      return AppColors.priorityMedium;
    case TaskPriority.low:
      return AppColors.priorityLow;
  }
}

/// Friendly due-date text — falls back to `No due date` when neither
/// deadline nor `dueDate` is set.
String taskDueText(TaskModel task) {
  final due = task.effectiveDueDateTime;
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
  return '$dateText · ${_timeText(due)}';
}

bool taskIsVisuallyOverdue(TaskModel task) {
  return task.isOverdue;
}

String taskReminderLabel(TaskModel task) {
  if (!task.notificationEnabled) return '';
  switch (task.reminderType) {
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

String _timeText(DateTime due) {
  final hourOfPeriod = due.hour % 12 == 0 ? 12 : due.hour % 12;
  final minute = due.minute.toString().padLeft(2, '0');
  final period = due.hour >= 12 ? 'PM' : 'AM';
  return '$hourOfPeriod:$minute $period';
}
