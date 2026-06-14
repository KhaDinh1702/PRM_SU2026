import 'package:flutter/material.dart';

enum CalendarFilter { all, events, tasks, project, overdue }

enum CalendarItemKind { event, personalTask, projectTask, deadline }

class CalendarItem {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime? end;
  final CalendarItemKind kind;
  final String source;
  final String sourceType;
  final String? projectName;
  final String? status;
  final String? priority;
  final bool hasReminder;

  const CalendarItem({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.kind,
    required this.source,
    required this.sourceType,
    this.end,
    this.projectName,
    this.status,
    this.priority,
    this.hasReminder = false,
  });

  bool get isTask => source == 'task';

  bool get isCompleted => status?.toLowerCase() == 'completed';

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(start.year, start.month, start.day);
    return isTask && !isCompleted && itemDate.isBefore(today);
  }

  bool get isAllDay => start.hour == 0 && start.minute == 0;

  Color get accentColor {
    if (isOverdue || kind == CalendarItemKind.deadline) {
      return const Color(0xFFEF4444);
    }
    switch (kind) {
      case CalendarItemKind.event:
        return const Color(0xFF10B981);
      case CalendarItemKind.personalTask:
        return const Color(0xFF06B6D4);
      case CalendarItemKind.projectTask:
        return const Color(0xFF8B5CF6);
      case CalendarItemKind.deadline:
        return const Color(0xFFEF4444);
    }
  }

  String get typeLabel {
    if (isOverdue) return 'Overdue';
    switch (kind) {
      case CalendarItemKind.event:
        return 'Event';
      case CalendarItemKind.personalTask:
        return 'Personal Task';
      case CalendarItemKind.projectTask:
        return 'Project Task';
      case CalendarItemKind.deadline:
        return 'Deadline';
    }
  }
}

class DateIndicatorCounts {
  final int events;
  final int personalTasks;
  final int projectTasks;
  final int deadlines;

  const DateIndicatorCounts({
    this.events = 0,
    this.personalTasks = 0,
    this.projectTasks = 0,
    this.deadlines = 0,
  });

  bool get hasAny =>
      events > 0 || personalTasks > 0 || projectTasks > 0 || deadlines > 0;
}
