import '../models/focus_session.dart';
import '../models/focus_stats.dart';

/// Pure aggregation over a list of [FocusSession]s. No I/O, no clock
/// access — the caller passes [now] so tests are deterministic and the
/// UI can pass the user's local time.
class FocusStatsService {
  const FocusStatsService();

  /// Computes today / week / streak / top-tasks from [sessions]. Breaks
  /// and cancelled sessions are excluded from the totals — they're logged
  /// for history but they don't count as productive time.
  FocusStats compute(List<FocusSession> sessions, {DateTime? now}) {
    if (sessions.isEmpty) return FocusStats.empty;
    final referenceTime = now ?? DateTime.now();
    final today = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final weekStart = today.subtract(const Duration(days: 6));

    final focused = sessions
        .where((s) =>
            s.mode == FocusSessionMode.focus ||
            s.mode == FocusSessionMode.custom)
        .where((s) => s.completed)
        .toList();

    int todaySec = 0;
    int weekSec = 0;
    int sessionsToday = 0;
    final dayBuckets = List<int>.filled(7, 0);
    final perTask = <String, _TaskBucket>{};

    for (final s in focused) {
      final day = s.day;
      if (!day.isBefore(today)) {
        todaySec += s.durationSeconds;
        sessionsToday += 1;
      }
      if (!day.isBefore(weekStart)) {
        weekSec += s.durationSeconds;
        final index = day.difference(weekStart).inDays;
        if (index >= 0 && index < 7) {
          dayBuckets[index] += s.durationSeconds;
        }
      }
      // Top-tasks window: same 7-day window as week stat.
      if (!day.isBefore(weekStart)) {
        final key = s.taskId == null || s.taskId!.isEmpty
            ? FocusTaskAggregate.unassignedTaskId
            : s.taskId!;
        final bucket = perTask.putIfAbsent(
          key,
          () => _TaskBucket(title: s.taskTitle ?? ''),
        );
        bucket.totalSeconds += s.durationSeconds;
        bucket.sessionCount += 1;
        // Pick whichever title is non-empty in case some sessions had it
        // wiped at write time.
        if (bucket.title.isEmpty &&
            s.taskTitle != null &&
            s.taskTitle!.isNotEmpty) {
          bucket.title = s.taskTitle!;
        }
      }
    }

    final topTasks = perTask.entries
        .map((entry) => FocusTaskAggregate(
              taskId: entry.key,
              taskTitle: entry.value.title,
              totalSeconds: entry.value.totalSeconds,
              sessionCount: entry.value.sessionCount,
            ))
        .toList()
      ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

    final streakDays = _computeStreak(focused, today);

    return FocusStats(
      todayFocusSeconds: todaySec,
      weekFocusSeconds: weekSec,
      currentStreakDays: streakDays.current,
      longestStreakDays: streakDays.longest,
      sessionsCompletedToday: sessionsToday,
      weekBuckets: dayBuckets,
      topTasks: topTasks.take(3).toList(),
    );
  }

  /// A streak is a run of consecutive calendar days each containing at
  /// least one completed focus session. Current streak is computed from
  /// today backwards; a day with no session anywhere ends the streak.
  /// If today has no session yet, the streak from yesterday still counts
  /// — that lets the badge stay green until midnight rolls over without
  /// punishing the user for not having started a session yet.
  _StreakResult _computeStreak(
    List<FocusSession> focused,
    DateTime today,
  ) {
    if (focused.isEmpty) return const _StreakResult(0, 0);
    final daySet = <DateTime>{
      for (final s in focused) s.day,
    };
    int current = 0;
    var cursor = today;
    if (!daySet.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (daySet.contains(cursor)) {
      current += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int longest = 0;
    int running = 0;
    DateTime? last;
    final sortedDays = daySet.toList()..sort();
    for (final day in sortedDays) {
      if (last != null && day.difference(last).inDays == 1) {
        running += 1;
      } else {
        running = 1;
      }
      if (running > longest) longest = running;
      last = day;
    }

    return _StreakResult(current, longest);
  }
}

class _TaskBucket {
  String title;
  int totalSeconds = 0;
  int sessionCount = 0;
  _TaskBucket({required this.title});
}

class _StreakResult {
  final int current;
  final int longest;
  const _StreakResult(this.current, this.longest);
}
