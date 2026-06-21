import 'package:flutter/material.dart';

import '../../calendar/models/calendar_item.dart';
import '../../tasks/models/task_model.dart';

/// Kind of entry shown on the unified "Today" timeline.
enum TodayItemKind { task, event, deadline }

/// Single row on the Today timeline. Wraps either a [TaskModel] or a
/// [CalendarItem] under a common shape so the timeline widget can stay
/// dumb about origin.
class TodayItem {
  final TodayItemKind kind;
  final String id;
  final String title;
  final String subtitle;
  final DateTime time;
  final bool isAllDay;
  final bool isCompleted;
  final Color accentColor;

  /// Original source — caller can downcast to wire deep-link / open
  /// actions without the timeline knowing the concrete type.
  final Object source;

  const TodayItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isAllDay,
    required this.isCompleted,
    required this.accentColor,
    required this.source,
  });

  factory TodayItem.fromTask(TaskModel task) {
    final due = task.effectiveDueDateTime ?? DateTime.now();
    final hasTime = task.dueTime != null && task.dueTime!.isNotEmpty;
    return TodayItem(
      kind: TodayItemKind.task,
      id: 'task:${task.id}',
      title: task.title.isEmpty ? 'Untitled task' : task.title,
      subtitle: task.projectName.isNotEmpty
          ? task.projectName
          : task.priorityLabel,
      time: due,
      isAllDay: !hasTime,
      isCompleted: task.status == TaskStatus.completed,
      accentColor: task.priorityColor,
      source: task,
    );
  }

  factory TodayItem.fromCalendarItem(CalendarItem item) {
    return TodayItem(
      kind: item.kind == CalendarItemKind.deadline
          ? TodayItemKind.deadline
          : TodayItemKind.event,
      id: 'cal:${item.id}',
      title: item.title.isEmpty ? 'Untitled event' : item.title,
      subtitle: item.projectName ?? item.typeLabel,
      time: item.start,
      isAllDay: item.isAllDay,
      isCompleted: item.isCompleted,
      accentColor: item.accentColor,
      source: item,
    );
  }
}
