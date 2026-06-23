import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/focus_session.dart';
import '../models/focus_stats.dart';
import '../services/focus_session_service.dart';
import '../services/focus_stats_service.dart';

/// High-level state of the focus engine. Mid-session pauses keep state in
/// [paused] so the screen can render "Resume". After a focus session
/// completes naturally the engine sits in [breakReady] so the user can
/// choose to start the break (Pomodoro recovery) or skip it.
enum FocusEngineState { idle, running, paused, breakReady }

/// Default durations per mode (in seconds). Kept here so the screen and
/// the provider agree without the screen owning state.
class FocusDurations {
  static const int focusSeconds = 25 * 60;
  static const int shortBreakSeconds = 5 * 60;
  static const int longBreakSeconds = 15 * 60;
  static const int longBreakEveryNFocus = 4;

  static int defaultFor(FocusSessionMode mode) {
    switch (mode) {
      case FocusSessionMode.focus:
        return focusSeconds;
      case FocusSessionMode.shortBreak:
        return shortBreakSeconds;
      case FocusSessionMode.longBreak:
        return longBreakSeconds;
      case FocusSessionMode.custom:
        return focusSeconds;
    }
  }
}

/// Drives the focus countdown, persists in-progress state across restarts,
/// and exposes the rolling history + computed stats to the UI.
///
/// The provider does NOT own a `Timer.periodic` — the screen drives ticks
/// by calling [tick] every second. That keeps the provider deterministic
/// in tests (we can call `tick()` 1500 times to simulate a session) and
/// keeps lifecycle ownership of the timer at the widget where pause/resume
/// integrate naturally with the UI.
class FocusProvider extends ChangeNotifier {
  static const String _activePrefsPrefix = 'focus_active_v1::';

  final FocusSessionService _sessionService;
  final FocusStatsService _statsService;

  FocusProvider({
    FocusSessionService? sessionService,
    FocusStatsService? statsService,
  })  : _sessionService = sessionService ?? const FocusSessionService(),
        _statsService = statsService ?? const FocusStatsService();

  // --- Identity ---------------------------------------------------------
  String _userId = '';

  // --- Engine state -----------------------------------------------------
  FocusEngineState _state = FocusEngineState.idle;
  FocusSessionMode _mode = FocusSessionMode.focus;
  String? _taskId;
  String? _taskTitle;
  int _totalSeconds = FocusDurations.focusSeconds;
  int _secondsElapsed = 0;
  DateTime? _startedAt;
  int _completedFocusInCycle = 0;

  // --- Cached read models -----------------------------------------------
  List<FocusSession> _history = const [];
  FocusStats _stats = FocusStats.empty;

  // --- Getters ----------------------------------------------------------
  FocusEngineState get state => _state;
  FocusSessionMode get mode => _mode;
  String? get taskId => _taskId;
  String? get taskTitle => _taskTitle;
  int get totalSeconds => _totalSeconds;
  int get secondsElapsed => _secondsElapsed;
  int get secondsRemaining =>
      (_totalSeconds - _secondsElapsed).clamp(0, _totalSeconds);
  double get progress => _totalSeconds == 0
      ? 0
      : (_secondsElapsed / _totalSeconds).clamp(0.0, 1.0);
  bool get isRunning => _state == FocusEngineState.running;
  bool get isPaused => _state == FocusEngineState.paused;
  bool get isIdle => _state == FocusEngineState.idle;
  bool get isBreakReady => _state == FocusEngineState.breakReady;
  bool get hasActiveSession => !isIdle;
  int get completedFocusInCycle => _completedFocusInCycle;
  List<FocusSession> get history => _history;
  FocusStats get stats => _stats;

  /// Hook the provider to the current user — loads history, recomputes
  /// stats, and restores any in-progress session as paused so the user
  /// decides whether to keep going.
  Future<void> bind({required String userId}) async {
    _userId = userId;
    await _restoreActiveSession();
    await reloadHistory();
  }

  /// Reload the history list + recompute stats. Cheap — operations are
  /// fully in-memory after the initial prefs read.
  Future<void> reloadHistory() async {
    _history = await _sessionService.loadAll(_userId);
    _stats = _statsService.compute(_history);
    notifyListeners();
  }

  // --- Task selection ---------------------------------------------------

  void selectTask({required String id, required String title}) {
    _taskId = id;
    _taskTitle = title;
    notifyListeners();
  }

  void clearTask() {
    _taskId = null;
    _taskTitle = null;
    notifyListeners();
  }

  // --- Mode setup -------------------------------------------------------

  /// Switches the planned mode. Ignored while a session is mid-flight —
  /// the user must cancel first. [customMinutes] is only honoured for
  /// [FocusSessionMode.custom].
  void setMode(FocusSessionMode mode, {int? customMinutes}) {
    if (isRunning || isPaused) return;
    _mode = mode;
    _totalSeconds = mode == FocusSessionMode.custom
        ? ((customMinutes ?? 25).clamp(1, 180)) * 60
        : FocusDurations.defaultFor(mode);
    _secondsElapsed = 0;
    notifyListeners();
  }

  // --- Lifecycle --------------------------------------------------------

  /// Begin counting down. From [breakReady] this starts the queued break;
  /// from [idle] it starts a fresh session in the currently selected mode.
  Future<void> start() async {
    if (isRunning) return;
    _state = FocusEngineState.running;
    _startedAt ??= DateTime.now();
    notifyListeners();
    await _persistActive();
  }

  Future<void> pause() async {
    if (!isRunning) return;
    _state = FocusEngineState.paused;
    notifyListeners();
    await _persistActive();
  }

  Future<void> resume() async {
    if (!isPaused) return;
    _state = FocusEngineState.running;
    notifyListeners();
    await _persistActive();
  }

  /// Advance the engine by one second. Returns true when the call landed
  /// on the natural end of the session — callers may use that to fire a
  /// completion sound or animation.
  Future<bool> tick() async {
    if (!isRunning) return false;
    _secondsElapsed = (_secondsElapsed + 1).clamp(0, _totalSeconds);
    if (_secondsElapsed >= _totalSeconds) {
      await _finish(completed: true);
      return true;
    }
    // Throttle disk writes — once every 5s is enough for crash recovery.
    if (_secondsElapsed % 5 == 0) {
      await _persistActive();
    }
    notifyListeners();
    return false;
  }

  /// Cancel an in-flight session. Time clocked so far still lands in the
  /// history with `completed: false` so the user keeps credit for effort.
  Future<void> cancel() async {
    if (isIdle) return;
    await _finish(completed: false);
  }

  /// Skip the queued break entirely — used when the engine sits in
  /// [FocusEngineState.breakReady] but the user wants to start another
  /// focus block right away.
  Future<void> skipBreak() async {
    if (!isBreakReady) return;
    _resetToIdle(nextMode: FocusSessionMode.focus);
    notifyListeners();
    await _clearActiveSnapshot();
  }

  // --- Internals --------------------------------------------------------

  Future<void> _finish({required bool completed}) async {
    final started = _startedAt ?? DateTime.now();
    final ended = DateTime.now();
    final wasFocus = _mode == FocusSessionMode.focus ||
        _mode == FocusSessionMode.custom;

    // Only persist sessions that actually counted at least one second —
    // otherwise we'd litter history with empty rows from accidental taps.
    if (_secondsElapsed > 0) {
      final session = FocusSession(
        id: _newSessionId(),
        taskId: _taskId,
        taskTitle: _taskTitle,
        startedAt: started,
        endedAt: ended,
        durationSeconds: _secondsElapsed,
        mode: _mode,
        completed: completed,
      );
      _history =
          await _sessionService.save(userId: _userId, session: session);
      _stats = _statsService.compute(_history);
    }

    if (completed && wasFocus) {
      _completedFocusInCycle += 1;
      final dueLongBreak = _completedFocusInCycle %
              FocusDurations.longBreakEveryNFocus ==
          0;
      _mode = dueLongBreak
          ? FocusSessionMode.longBreak
          : FocusSessionMode.shortBreak;
      _totalSeconds = FocusDurations.defaultFor(_mode);
      _secondsElapsed = 0;
      _startedAt = null;
      _state = FocusEngineState.breakReady;
    } else {
      _resetToIdle(nextMode: FocusSessionMode.focus);
    }

    await _clearActiveSnapshot();
    notifyListeners();
  }

  void _resetToIdle({required FocusSessionMode nextMode}) {
    _state = FocusEngineState.idle;
    _mode = nextMode;
    _totalSeconds = FocusDurations.defaultFor(nextMode);
    _secondsElapsed = 0;
    _startedAt = null;
  }

  String _newSessionId() => 'fs_${DateTime.now().microsecondsSinceEpoch}';

  String _activeKey() =>
      '$_activePrefsPrefix${_userId.isEmpty ? 'anon' : _userId}';

  Future<void> _persistActive() async {
    if (_userId.isEmpty) return;
    if (isIdle) {
      await _clearActiveSnapshot();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final snapshot = <String, dynamic>{
      'state': _state.name,
      'mode': _mode.wireValue,
      'taskId': _taskId,
      'taskTitle': _taskTitle,
      'totalSeconds': _totalSeconds,
      'secondsElapsed': _secondsElapsed,
      'startedAt': _startedAt?.toIso8601String(),
      'cycle': _completedFocusInCycle,
    };
    await prefs.setString(_activeKey(), jsonEncode(snapshot));
  }

  Future<void> _clearActiveSnapshot() async {
    if (_userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey());
  }

  /// On restart we never auto-resume — we restore as paused so the user
  /// explicitly opts back in. Closing the app for an hour shouldn't bank
  /// an hour of focus time.
  Future<void> _restoreActiveSession() async {
    if (_userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeKey());
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return;
      _mode = FocusSessionModeX.fromWire(data['mode']?.toString());
      _taskId = (data['taskId'] as String?)?.isEmpty == true
          ? null
          : data['taskId'] as String?;
      _taskTitle = (data['taskTitle'] as String?)?.isEmpty == true
          ? null
          : data['taskTitle'] as String?;
      _totalSeconds = (data['totalSeconds'] as num?)?.toInt() ??
          FocusDurations.defaultFor(_mode);
      _secondsElapsed = (data['secondsElapsed'] as num?)?.toInt() ?? 0;
      _startedAt = data['startedAt'] is String
          ? DateTime.tryParse(data['startedAt'] as String)
          : null;
      _completedFocusInCycle = (data['cycle'] as num?)?.toInt() ?? 0;
      // Always restore paused so user controls whether to keep counting.
      _state = _secondsElapsed >= _totalSeconds
          ? FocusEngineState.idle
          : FocusEngineState.paused;
    } catch (_) {
      await _clearActiveSnapshot();
    }
  }
}
