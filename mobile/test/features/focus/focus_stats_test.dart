import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/focus/models/focus_session.dart';
import 'package:prm_app/features/focus/models/focus_stats.dart';
import 'package:prm_app/features/focus/services/focus_stats_service.dart';

FocusSession _session({
  required String id,
  required DateTime startedAt,
  int durationSeconds = 25 * 60,
  String? taskId,
  String? taskTitle,
  FocusSessionMode mode = FocusSessionMode.focus,
  bool completed = true,
}) {
  return FocusSession(
    id: id,
    taskId: taskId,
    taskTitle: taskTitle,
    startedAt: startedAt,
    endedAt: startedAt.add(Duration(seconds: durationSeconds)),
    durationSeconds: durationSeconds,
    mode: mode,
    completed: completed,
  );
}

void main() {
  const service = FocusStatsService();
  final fixedNow = DateTime(2026, 4, 15, 14);

  test('returns FocusStats.empty when there are no sessions', () {
    final stats = service.compute(const [], now: fixedNow);
    expect(stats, FocusStats.empty);
  });

  test('today totals only count completed focus sessions on today', () {
    final stats = service.compute(
      [
        _session(id: '1', startedAt: DateTime(2026, 4, 15, 9), durationSeconds: 1500),
        _session(id: '2', startedAt: DateTime(2026, 4, 15, 10), durationSeconds: 900),
        // Excluded: short break
        _session(
          id: 'br',
          startedAt: DateTime(2026, 4, 15, 11),
          durationSeconds: 300,
          mode: FocusSessionMode.shortBreak,
        ),
        // Excluded: cancelled
        _session(
          id: 'cx',
          startedAt: DateTime(2026, 4, 15, 12),
          durationSeconds: 600,
          completed: false,
        ),
        // Excluded: yesterday
        _session(id: '3', startedAt: DateTime(2026, 4, 14, 22), durationSeconds: 1500),
      ],
      now: fixedNow,
    );
    expect(stats.todayFocusSeconds, 2400);
    expect(stats.sessionsCompletedToday, 2);
  });

  test('week bucket index 6 maps to today, 0 to 6 days ago', () {
    final stats = service.compute(
      [
        _session(id: 'today', startedAt: DateTime(2026, 4, 15, 9), durationSeconds: 600),
        _session(id: 'd-6', startedAt: DateTime(2026, 4, 9, 10), durationSeconds: 1200),
        // outside the 7-day window
        _session(id: 'old', startedAt: DateTime(2026, 4, 1, 10), durationSeconds: 900),
      ],
      now: fixedNow,
    );
    expect(stats.weekBuckets.length, 7);
    expect(stats.weekBuckets.first, 1200);
    expect(stats.weekBuckets.last, 600);
    expect(stats.weekFocusSeconds, 1800);
  });

  test('current streak counts consecutive days back from today', () {
    final stats = service.compute(
      [
        _session(id: 't', startedAt: DateTime(2026, 4, 15, 9), durationSeconds: 600),
        _session(id: 'y', startedAt: DateTime(2026, 4, 14, 9), durationSeconds: 600),
        _session(id: 'd2', startedAt: DateTime(2026, 4, 13, 9), durationSeconds: 600),
        // Gap on Apr 12
        _session(id: 'd4', startedAt: DateTime(2026, 4, 11, 9), durationSeconds: 600),
      ],
      now: fixedNow,
    );
    expect(stats.currentStreakDays, 3);
    expect(stats.longestStreakDays, 3);
  });

  test('streak is preserved when today has no session yet', () {
    final stats = service.compute(
      [
        _session(id: 'y', startedAt: DateTime(2026, 4, 14, 9), durationSeconds: 600),
        _session(id: 'd2', startedAt: DateTime(2026, 4, 13, 9), durationSeconds: 600),
      ],
      now: fixedNow,
    );
    expect(stats.currentStreakDays, 2);
  });

  test('top tasks are ranked by total seconds and capped at 3', () {
    final stats = service.compute(
      [
        _session(
          id: 'a1',
          startedAt: DateTime(2026, 4, 15, 9),
          durationSeconds: 1500,
          taskId: 'A',
          taskTitle: 'Alpha',
        ),
        _session(
          id: 'b1',
          startedAt: DateTime(2026, 4, 14, 9),
          durationSeconds: 600,
          taskId: 'B',
          taskTitle: 'Beta',
        ),
        _session(
          id: 'c1',
          startedAt: DateTime(2026, 4, 14, 10),
          durationSeconds: 1800,
          taskId: 'C',
          taskTitle: 'Gamma',
        ),
        _session(
          id: 'd1',
          startedAt: DateTime(2026, 4, 13, 9),
          durationSeconds: 900,
          taskId: 'D',
          taskTitle: 'Delta',
        ),
      ],
      now: fixedNow,
    );
    expect(stats.topTasks.length, 3);
    expect(stats.topTasks.first.taskId, 'C');
    expect(stats.topTasks[1].taskId, 'A');
    expect(stats.topTasks[2].taskId, 'D');
  });

  test('sessions with no taskId fold into the unassigned bucket', () {
    final stats = service.compute(
      [
        _session(id: 'a', startedAt: DateTime(2026, 4, 15, 9), durationSeconds: 1500),
        _session(id: 'b', startedAt: DateTime(2026, 4, 15, 10), durationSeconds: 600),
      ],
      now: fixedNow,
    );
    expect(stats.topTasks, hasLength(1));
    expect(stats.topTasks.first.taskId, FocusTaskAggregate.unassignedTaskId);
    expect(stats.topTasks.first.totalSeconds, 2100);
  });
}
