import '../models/calendar_item.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime calendarGridStart(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  return first.subtract(Duration(days: first.weekday % 7));
}

DateTime calendarGridEnd(DateTime month) {
  final last = DateTime(month.year, month.month + 1, 0);
  return last.add(Duration(days: 6 - (last.weekday % 7)));
}

List<DateTime> visibleCalendarDays(DateTime month) {
  final start = calendarGridStart(month);
  return List.generate(42, (index) => start.add(Duration(days: index)));
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

CalendarItem? mapCalendarPayload(Map<String, dynamic> payload) {
  final start = parseDate(payload['start']);
  if (start == null) return null;

  final source = payload['source']?.toString() ?? 'event';
  final sourceType = payload['sourceType']?.toString() ??
      (source == 'task' ? 'personal' : 'schedule');
  final isTask = source == 'task';
  final isProjectTask = isTask && sourceType == 'project';
  final cleanTitle = (payload['title']?.toString() ?? 'Untitled').replaceFirst(
    RegExp(r'^\[TASK DEADLINE\]\s*'),
    '',
  );

  CalendarItemKind kind;
  if (!isTask) {
    kind = CalendarItemKind.event;
  } else if (isProjectTask) {
    kind = CalendarItemKind.projectTask;
  } else {
    kind = CalendarItemKind.personalTask;
  }

  final item = CalendarItem(
    id: payload['id']?.toString() ?? '',
    title: cleanTitle,
    description: payload['description']?.toString() ?? '',
    start: start.toLocal(),
    end: parseDate(payload['end'])?.toLocal(),
    kind: kind,
    source: source,
    sourceType: sourceType,
    projectName: payload['projectName']?.toString(),
    status: payload['status']?.toString(),
    priority: payload['priority']?.toString(),
    hasReminder: payload['notificationEnabled'] == true ||
        (payload['reminderType'] != null &&
            payload['reminderType'].toString() != 'none'),
  );

  if (!item.isOverdue) return item;

  return CalendarItem(
    id: item.id,
    title: item.title,
    description: item.description,
    start: item.start,
    end: item.end,
    kind: CalendarItemKind.deadline,
    source: item.source,
    sourceType: item.sourceType,
    projectName: item.projectName,
    status: item.status,
    priority: item.priority,
    hasReminder: item.hasReminder,
  );
}

List<CalendarItem> getCalendarItemsForDate(
  DateTime date,
  List<CalendarItem> items,
) {
  return sortCalendarItemsByTime(
    items.where((item) => isSameDay(item.start, date)).toList(),
  );
}

List<CalendarItem> mapTasksToCalendarItems(List<dynamic> tasks) {
  return tasks
      .whereType<Map<String, dynamic>>()
      .map((task) {
        final start = parseDate(task['deadline'] ?? task['dueDate']);
        if (start == null) return null;
        final sourceType = task['sourceType']?.toString() ?? 'personal';
        return CalendarItem(
          id: task['_id']?.toString() ?? task['id']?.toString() ?? '',
          title: task['title']?.toString() ?? 'Untitled task',
          description: task['description']?.toString() ?? '',
          start: start.toLocal(),
          kind: sourceType == 'project'
              ? CalendarItemKind.projectTask
              : CalendarItemKind.personalTask,
          source: 'task',
          sourceType: sourceType,
          projectName: task['projectName']?.toString(),
          status: task['status']?.toString(),
          priority: task['priority']?.toString(),
          hasReminder: task['notificationEnabled'] == true,
        );
      })
      .whereType<CalendarItem>()
      .toList();
}

List<CalendarItem> mapEventsToCalendarItems(List<dynamic> events) {
  return events
      .whereType<Map<String, dynamic>>()
      .map((event) {
        final start = parseDate(event['start'] ?? event['startTime']);
        if (start == null) return null;
        return CalendarItem(
          id: event['id']?.toString() ?? event['_id']?.toString() ?? '',
          title: event['title']?.toString() ?? 'Untitled event',
          description: event['description']?.toString() ?? '',
          start: start.toLocal(),
          end: parseDate(event['end'] ?? event['endTime'])?.toLocal(),
          kind: CalendarItemKind.event,
          source: 'event',
          sourceType: 'schedule',
          hasReminder: event['type']?.toString() == 'reminder',
        );
      })
      .whereType<CalendarItem>()
      .toList();
}

Map<String, List<CalendarItem>> groupCalendarItemsByTime(
  List<CalendarItem> items,
) {
  final grouped = <String, List<CalendarItem>>{};
  for (final item in items) {
    final key = item.isAllDay ? 'All-day' : formatTime(item.start);
    grouped.putIfAbsent(key, () => []).add(item);
  }
  return grouped;
}

DateIndicatorCounts getDateIndicatorCounts(
  DateTime date,
  List<CalendarItem> items,
) {
  int events = 0;
  int personalTasks = 0;
  int projectTasks = 0;
  int deadlines = 0;

  for (final item in items) {
    if (!isSameDay(item.start, date)) continue;
    if (item.isOverdue || item.kind == CalendarItemKind.deadline) {
      deadlines++;
    } else if (item.kind == CalendarItemKind.event) {
      events++;
    } else if (item.kind == CalendarItemKind.projectTask) {
      projectTasks++;
    } else {
      personalTasks++;
    }
  }

  return DateIndicatorCounts(
    events: events,
    personalTasks: personalTasks,
    projectTasks: projectTasks,
    deadlines: deadlines,
  );
}

List<CalendarItem> filterCalendarItems(
  List<CalendarItem> items,
  CalendarFilter filter,
) {
  switch (filter) {
    case CalendarFilter.all:
      return items;
    case CalendarFilter.events:
      return items
          .where((item) => item.kind == CalendarItemKind.event)
          .toList();
    case CalendarFilter.tasks:
      return items.where((item) => item.isTask).toList();
    case CalendarFilter.project:
      return items
          .where((item) => item.kind == CalendarItemKind.projectTask)
          .toList();
    case CalendarFilter.overdue:
      return items.where((item) => item.isOverdue).toList();
  }
}

List<CalendarItem> sortCalendarItemsByTime(List<CalendarItem> items) {
  final sorted = [...items];
  sorted.sort((a, b) {
    if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
    return a.start.compareTo(b.start);
  });
  return sorted;
}

String formatMonthTitle(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String agendaTitle(DateTime date) {
  final today = dateOnly(DateTime.now());
  final tomorrow = today.add(const Duration(days: 1));
  if (isSameDay(date, today)) return 'Today, ${formatShortDate(date)}';
  if (isSameDay(date, tomorrow)) return 'Tomorrow, ${formatShortDate(date)}';
  return formatShortDate(date);
}

String formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String formatDateTime(DateTime date) =>
    '${formatShortDate(date)}, ${formatTime(date)}';

String formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String agendaItemSecondaryLine(CalendarItem item) {
  if (item.isOverdue) {
    final days =
        dateOnly(DateTime.now()).difference(dateOnly(item.start)).inDays;
    return 'Overdue by $days ${days == 1 ? 'day' : 'days'}';
  }
  if (item.projectName?.isNotEmpty == true) {
    return '${item.projectName} - ${formatTime(item.start)}';
  }
  if (item.kind == CalendarItemKind.event && item.end != null) {
    return '${formatTime(item.start)} - ${formatTime(item.end!)}';
  }
  return item.isAllDay
      ? 'No specific time'
      : 'Due at ${formatTime(item.start)}';
}

String reminderLabel(String value) {
  switch (value) {
    case 'at_time':
      return 'At due time';
    case '15_min_before':
      return '15 min before';
    case '30_min_before':
      return '30 min before';
    case '1_hour_before':
      return '1 hour before';
    case '1_day_before':
      return '1 day before';
    default:
      return 'No reminder';
  }
}
