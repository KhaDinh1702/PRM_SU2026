import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/focus/models/focus_session.dart';
import 'package:prm_app/features/focus/providers/focus_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FocusProvider state machine', () {
    test('bind on empty prefs leaves engine idle with default focus duration',
        () async {
      final provider = FocusProvider();
      await provider.bind(userId: 'u1');
      expect(provider.state, FocusEngineState.idle);
      expect(provider.mode, FocusSessionMode.focus);
      expect(provider.totalSeconds, FocusDurations.focusSeconds);
      expect(provider.secondsElapsed, 0);
      expect(provider.history, isEmpty);
    });

    test('selectTask and setMode update fields when idle', () async {
      final provider = FocusProvider();
      await provider.bind(userId: 'u1');

      provider.selectTask(id: 'task-1', title: 'Capstone');
      expect(provider.taskId, 'task-1');
      expect(provider.taskTitle, 'Capstone');

      provider.setMode(FocusSessionMode.custom, customMinutes: 50);
      expect(provider.mode, FocusSessionMode.custom);
      expect(provider.totalSeconds, 50 * 60);
    });

    test('setMode is ignored mid-session', () async {
      final provider = FocusProvider();
      await provider.bind(userId: 'u1');
      await provider.start();

      provider.setMode(FocusSessionMode.custom, customMinutes: 5);
      expect(provider.mode, FocusSessionMode.focus);
      expect(provider.totalSeconds, FocusDurations.focusSeconds);
    });

    test('start → pause → resume keeps elapsed time', () async {
      final provider = FocusProvider();
      await provider.bind(userId: 'u1');
      provider.setMode(FocusSessionMode.custom, customMinutes: 1);

      await provider.start();
      for (var i = 0; i < 10; i++) {
        await provider.tick();
      }
      expect(provider.secondsElapsed, 10);

      await provider.pause();
      expect(provider.state, FocusEngineState.paused);
      // Ticks while paused are no-ops.
      await provider.tick();
      expect(provider.secondsElapsed, 10);

      await provider.resume();
      await provider.tick();
      expect(provider.state, FocusEngineState.running);
      expect(provider.secondsElapsed, 11);
    });
  });

  group('FocusProvider completion + history', () {
    test('completing a focus session saves it and queues a short break',
        () async {
      final provider = FocusProvider();
      await provider.bind(userId: 'u1');
      provider.selectTask(id: 'task-A', title: 'Alpha');
      provider.setMode(FocusSessionMode.custom, customMinutes: 1);
      await provider.start();

      bool finished = false;
      for (var i = 0; i < 60; i++) {
        finished = await provider.tick();
      }
      expect(finished, isTrue);
      expect(provider.state, FocusEngineState.breakReady);
      expect(provider.mode, FocusSessionMode.shortBreak);
      expect(provider.history.length, 1);
      expect(provider.history.first.taskId, 'task-A');
      expect(provider.history.first.completed, isTrue);
      expect(provider.history.first.durationSeconds, 60);
      expect(provider.stats.todayFocusSeconds, 60);
    });

    test('cancel logs partial session as completed=false', () async {
      final provider = FocusProvider();
      await provider.bind(userId: 'u1');
      provider.setMode(FocusSessionMode.custom, customMinutes: 1);
      await provider.start();
      for (var i = 0; i < 7; i++) {
        await provider.tick();
      }
      await provider.cancel();

      expect(provider.state, FocusEngineState.idle);
      expect(provider.history.length, 1);
      expect(provider.history.first.completed, isFalse);
      expect(provider.history.first.durationSeconds, 7);
      // Cancelled sessions don't count toward today total.
      expect(provider.stats.todayFocusSeconds, 0);
    });

    test('every 4th completed focus queues a long break', () async {
      final provider = FocusProvider();
      await provider.bind(userId: 'u1');

      Future<void> runOne() async {
        provider.setMode(FocusSessionMode.custom, customMinutes: 1);
        await provider.start();
        for (var i = 0; i < 60; i++) {
          await provider.tick();
        }
        await provider.skipBreak();
      }

      await runOne();
      await runOne();
      await runOne();
      // The 4th completion should queue a long break instead of skipping.
      provider.setMode(FocusSessionMode.custom, customMinutes: 1);
      await provider.start();
      for (var i = 0; i < 60; i++) {
        await provider.tick();
      }
      expect(provider.mode, FocusSessionMode.longBreak);
      expect(provider.totalSeconds, FocusDurations.longBreakSeconds);
    });
  });

  group('FocusProvider persistence', () {
    test('restores in-progress session as paused on bind', () async {
      final first = FocusProvider();
      await first.bind(userId: 'u-restore');
      first.selectTask(id: 't-1', title: 'Persisted');
      first.setMode(FocusSessionMode.custom, customMinutes: 1);
      await first.start();
      // Tick enough times to cross a 5s snapshot boundary.
      for (var i = 0; i < 10; i++) {
        await first.tick();
      }
      // Simulate app kill mid-session — no explicit pause, just drop the
      // instance.

      final second = FocusProvider();
      await second.bind(userId: 'u-restore');
      expect(second.state, FocusEngineState.paused);
      expect(second.taskId, 't-1');
      expect(second.secondsElapsed, 10);
      expect(second.totalSeconds, 60);
    });
  });
}
