import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/focus/models/focus_session.dart';

void main() {
  group('FocusSessionMode wire mapping', () {
    test('round-trips every mode through wireValue / fromWire', () {
      for (final mode in FocusSessionMode.values) {
        expect(FocusSessionModeX.fromWire(mode.wireValue), mode);
      }
    });

    test('fromWire falls back to focus on unknown / null input', () {
      expect(FocusSessionModeX.fromWire(null), FocusSessionMode.focus);
      expect(FocusSessionModeX.fromWire('nonsense'), FocusSessionMode.focus);
    });

    test('isBreak true only for short_break / long_break', () {
      expect(FocusSessionMode.focus.isBreak, isFalse);
      expect(FocusSessionMode.custom.isBreak, isFalse);
      expect(FocusSessionMode.shortBreak.isBreak, isTrue);
      expect(FocusSessionMode.longBreak.isBreak, isTrue);
    });
  });

  group('FocusSession serialization', () {
    test('round-trips through JSON', () {
      final session = FocusSession(
        id: 'abc',
        taskId: 'task-7',
        taskTitle: 'Capstone',
        startedAt: DateTime(2026, 4, 1, 9, 0),
        endedAt: DateTime(2026, 4, 1, 9, 25),
        durationSeconds: 25 * 60,
        mode: FocusSessionMode.focus,
        completed: true,
      );
      final round = FocusSession.fromJson(session.toJson());
      expect(round, session);
    });

    test('handles missing optional fields gracefully', () {
      final round = FocusSession.fromJson(const {
        'id': 'x',
        'startedAt': '2026-04-01T09:00:00.000',
        'endedAt': '2026-04-01T09:25:00.000',
        'durationSeconds': 60,
        'mode': 'short_break',
        'completed': false,
      });
      expect(round.taskId, isNull);
      expect(round.taskTitle, isNull);
      expect(round.mode, FocusSessionMode.shortBreak);
      expect(round.completed, isFalse);
    });

    test('treats empty taskId / taskTitle strings as null', () {
      final round = FocusSession.fromJson(const {
        'id': 'y',
        'taskId': '',
        'taskTitle': '',
        'startedAt': '2026-04-01T09:00:00.000',
        'endedAt': '2026-04-01T09:25:00.000',
        'durationSeconds': 60,
        'mode': 'focus',
        'completed': true,
      });
      expect(round.taskId, isNull);
      expect(round.taskTitle, isNull);
    });
  });

  group('FocusSession derived getters', () {
    test('day strips out time-of-day', () {
      final s = FocusSession(
        id: '1',
        startedAt: DateTime(2026, 4, 1, 14, 35),
        endedAt: DateTime(2026, 4, 1, 15, 0),
        durationSeconds: 1500,
        mode: FocusSessionMode.focus,
        completed: true,
      );
      expect(s.day, DateTime(2026, 4, 1));
    });

    test('minutes rounds to nearest whole minute', () {
      final s = FocusSession(
        id: '1',
        startedAt: DateTime(2026, 4, 1),
        endedAt: DateTime(2026, 4, 1),
        durationSeconds: 89,
        mode: FocusSessionMode.focus,
        completed: true,
      );
      expect(s.minutes, 1);
    });

    test('copyWith replaces only the requested fields', () {
      final base = FocusSession(
        id: '1',
        taskId: 't',
        taskTitle: 'Title',
        startedAt: DateTime(2026, 4, 1, 9),
        endedAt: DateTime(2026, 4, 1, 9, 25),
        durationSeconds: 1500,
        mode: FocusSessionMode.focus,
        completed: true,
      );
      final updated = base.copyWith(completed: false);
      expect(updated.completed, isFalse);
      expect(updated.id, base.id);
      expect(updated.taskTitle, base.taskTitle);
      expect(updated.mode, base.mode);
    });
  });
}
