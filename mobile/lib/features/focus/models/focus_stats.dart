import 'package:flutter/foundation.dart';

/// Total time and session count attributable to a single task. Used by
/// the "Top tasks this week" widget — sessions without a [taskId] are
/// folded into the special bucket [unassignedTaskId].
@immutable
class FocusTaskAggregate {
  static const String unassignedTaskId = '__unassigned__';

  final String taskId;
  final String taskTitle;
  final int totalSeconds;
  final int sessionCount;

  const FocusTaskAggregate({
    required this.taskId,
    required this.taskTitle,
    required this.totalSeconds,
    required this.sessionCount,
  });

  int get minutes => (totalSeconds / 60).round();

  bool get isUnassigned => taskId == unassignedTaskId;
}

/// Snapshot of focus stats over the user's history. All durations are in
/// seconds for precision — UI rounds to minutes. [weekBuckets] holds 7
/// entries, oldest day first, so it can be plotted directly.
@immutable
class FocusStats {
  final int todayFocusSeconds;
  final int weekFocusSeconds;
  final int currentStreakDays;
  final int longestStreakDays;
  final int sessionsCompletedToday;
  final List<int> weekBuckets;
  final List<FocusTaskAggregate> topTasks;

  const FocusStats({
    required this.todayFocusSeconds,
    required this.weekFocusSeconds,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.sessionsCompletedToday,
    required this.weekBuckets,
    required this.topTasks,
  });

  /// Empty value used when no sessions exist yet — keeps UI code from
  /// branching on null.
  static const FocusStats empty = FocusStats(
    todayFocusSeconds: 0,
    weekFocusSeconds: 0,
    currentStreakDays: 0,
    longestStreakDays: 0,
    sessionsCompletedToday: 0,
    weekBuckets: [0, 0, 0, 0, 0, 0, 0],
    topTasks: [],
  );

  int get todayMinutes => (todayFocusSeconds / 60).round();
  int get weekMinutes => (weekFocusSeconds / 60).round();

  /// Highest bucket value in [weekBuckets] — UI uses this to scale the
  /// bar chart so the tallest bar reaches the top of the chart.
  int get peakDailySeconds {
    if (weekBuckets.isEmpty) return 0;
    return weekBuckets.reduce((a, b) => a > b ? a : b);
  }
}
