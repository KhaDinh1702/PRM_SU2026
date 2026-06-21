/// How often a recurring task repeats.
enum RecurrencePattern { daily, weekly, monthly }

extension RecurrencePatternX on RecurrencePattern {
  String get label {
    switch (this) {
      case RecurrencePattern.daily:
        return 'Daily';
      case RecurrencePattern.weekly:
        return 'Weekly';
      case RecurrencePattern.monthly:
        return 'Monthly';
    }
  }

  static RecurrencePattern? fromName(String? value) {
    switch (value) {
      case 'daily':
        return RecurrencePattern.daily;
      case 'weekly':
        return RecurrencePattern.weekly;
      case 'monthly':
        return RecurrencePattern.monthly;
      default:
        return null;
    }
  }
}

/// Recurrence configuration attached to a task.
///
/// - `daily` with `interval: 1` → every day
/// - `daily` with `interval: 2` → every other day
/// - `weekly` with `weekdays: {1, 3, 5}` → every Mon/Wed/Fri
///   (`interval` here is "every N weeks" of that pattern)
/// - `monthly` with `interval: 1` → same day-of-month next month
///
/// `endDate` optionally caps the series — after this date no new occurrences
/// are spawned.
class RecurrenceRule {
  final RecurrencePattern pattern;
  final int interval;

  /// Only meaningful for [RecurrencePattern.weekly].
  /// Uses Dart's `DateTime.weekday` convention: Mon = 1 … Sun = 7.
  final Set<int> weekdays;

  final DateTime? endDate;

  const RecurrenceRule({
    required this.pattern,
    this.interval = 1,
    this.weekdays = const {},
    this.endDate,
  });

  /// Given the [current] occurrence date, returns the next date that
  /// matches the rule, or `null` once the series has ended.
  DateTime? nextOccurrence(DateTime current) {
    final step = interval < 1 ? 1 : interval;
    DateTime candidate;

    switch (pattern) {
      case RecurrencePattern.daily:
        candidate = _addDays(current, step);
        break;

      case RecurrencePattern.weekly:
        candidate = _nextWeeklyOccurrence(current, step);
        break;

      case RecurrencePattern.monthly:
        candidate = _addMonths(current, step);
        break;
    }

    final end = endDate;
    if (end != null && candidate.isAfter(end)) return null;
    return candidate;
  }

  /// Pure data round-trip used by the persistence layer.
  Map<String, dynamic> toJson() => {
        'pattern': pattern.name,
        'interval': interval,
        if (weekdays.isNotEmpty) 'weekdays': weekdays.toList()..sort(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
      };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    final pattern = RecurrencePatternX.fromName(json['pattern']?.toString()) ??
        RecurrencePattern.daily;
    final interval = (json['interval'] is num)
        ? (json['interval'] as num).toInt()
        : int.tryParse(json['interval']?.toString() ?? '') ?? 1;
    final weekdays = <int>{};
    final rawDays = json['weekdays'];
    if (rawDays is List) {
      for (final d in rawDays) {
        final v = d is num
            ? d.toInt()
            : int.tryParse(d?.toString() ?? '');
        if (v != null && v >= 1 && v <= 7) weekdays.add(v);
      }
    }
    final endDate = json['endDate'] != null
        ? DateTime.tryParse(json['endDate'].toString())
        : null;
    return RecurrenceRule(
      pattern: pattern,
      interval: interval < 1 ? 1 : interval,
      weekdays: weekdays,
      endDate: endDate,
    );
  }

  String describe() {
    switch (pattern) {
      case RecurrencePattern.daily:
        return interval == 1 ? 'Every day' : 'Every $interval days';
      case RecurrencePattern.weekly:
        if (weekdays.isEmpty) {
          return interval == 1 ? 'Every week' : 'Every $interval weeks';
        }
        final names = weekdays.toList()..sort();
        final labels = names.map(_weekdayLabel).join(', ');
        return interval == 1 ? labels : 'Every $interval weeks · $labels';
      case RecurrencePattern.monthly:
        return interval == 1 ? 'Every month' : 'Every $interval months';
    }
  }

  // --- Internal helpers ---

  DateTime _addDays(DateTime base, int days) {
    return DateTime(
      base.year,
      base.month,
      base.day + days,
      base.hour,
      base.minute,
    );
  }

  DateTime _addMonths(DateTime base, int months) {
    final targetMonth = base.month + months;
    final year = base.year + (targetMonth - 1) ~/ 12;
    final month = ((targetMonth - 1) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = base.day > lastDay ? lastDay : base.day;
    return DateTime(year, month, day, base.hour, base.minute);
  }

  DateTime _nextWeeklyOccurrence(DateTime current, int interval) {
    // No specific weekdays — repeat on the same weekday, [interval] weeks
    // later.
    if (weekdays.isEmpty) {
      return _addDays(current, 7 * interval);
    }
    // Otherwise, find the next listed weekday after `current`. If we've
    // exhausted this week's options, jump to the next [interval]-th week.
    for (var offset = 1; offset <= 7; offset++) {
      final candidate = _addDays(current, offset);
      if (weekdays.contains(candidate.weekday)) return candidate;
    }
    // Should not reach — but if it does, fall back to weeks-later same day.
    return _addDays(current, 7 * interval);
  }

  static String _weekdayLabel(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return '?';
    return names[weekday - 1];
  }
}
