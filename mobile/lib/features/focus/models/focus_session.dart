import 'package:flutter/foundation.dart';

/// The kind of timer block a session belongs to. `focus` is the productive
/// chunk; the breaks complement it inside a Pomodoro-style cycle. `custom`
/// is used when the user picks an arbitrary duration outside the presets.
enum FocusSessionMode { focus, shortBreak, longBreak, custom }

extension FocusSessionModeX on FocusSessionMode {
  /// Wire format kept in JSON / backend payload so storage is stable even
  /// if we reorder the enum.
  String get wireValue {
    switch (this) {
      case FocusSessionMode.focus:
        return 'focus';
      case FocusSessionMode.shortBreak:
        return 'short_break';
      case FocusSessionMode.longBreak:
        return 'long_break';
      case FocusSessionMode.custom:
        return 'custom';
    }
  }

  static FocusSessionMode fromWire(String? value) {
    switch (value) {
      case 'focus':
        return FocusSessionMode.focus;
      case 'short_break':
        return FocusSessionMode.shortBreak;
      case 'long_break':
        return FocusSessionMode.longBreak;
      case 'custom':
        return FocusSessionMode.custom;
      default:
        return FocusSessionMode.focus;
    }
  }

  bool get isBreak =>
      this == FocusSessionMode.shortBreak ||
      this == FocusSessionMode.longBreak;
}

/// One focus or break interval the user has spent inside the app.
/// [durationSeconds] is the actual time spent (after pauses) — it may be
/// less than `endedAt - startedAt` when the user paused. [completed] is
/// true when the session finished naturally and false when cancelled.
/// [taskTitle] is denormalised so history rows still render the task name
/// after the task itself has been deleted.
@immutable
class FocusSession {
  final String id;
  final String? taskId;
  final String? taskTitle;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final FocusSessionMode mode;
  final bool completed;

  const FocusSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.mode,
    required this.completed,
    this.taskId,
    this.taskTitle,
  });

  /// Convenience: the calendar day this session belongs to. Used by stats
  /// to bucket by day.
  DateTime get day =>
      DateTime(startedAt.year, startedAt.month, startedAt.day);

  int get minutes => (durationSeconds / 60).round();

  FocusSession copyWith({
    String? id,
    String? taskId,
    String? taskTitle,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    FocusSessionMode? mode,
    bool? completed,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      mode: mode ?? this.mode,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'mode': mode.wireValue,
        'completed': completed,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is String) {
        return DateTime.tryParse(value)?.toLocal() ?? fallback;
      }
      return fallback;
    }

    final started = parseDate(json['startedAt'], DateTime.now());
    return FocusSession(
      id: (json['id'] ?? '').toString(),
      taskId: (json['taskId'] as String?)?.isEmpty == true
          ? null
          : json['taskId'] as String?,
      taskTitle: (json['taskTitle'] as String?)?.isEmpty == true
          ? null
          : json['taskTitle'] as String?,
      startedAt: started,
      endedAt: parseDate(json['endedAt'], started),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      mode: FocusSessionModeX.fromWire(json['mode']?.toString()),
      completed: json['completed'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSession &&
          other.id == id &&
          other.taskId == taskId &&
          other.taskTitle == taskTitle &&
          other.startedAt == startedAt &&
          other.endedAt == endedAt &&
          other.durationSeconds == durationSeconds &&
          other.mode == mode &&
          other.completed == completed);

  @override
  int get hashCode => Object.hash(
        id,
        taskId,
        taskTitle,
        startedAt,
        endedAt,
        durationSeconds,
        mode,
        completed,
      );
}
