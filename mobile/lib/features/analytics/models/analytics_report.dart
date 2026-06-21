/// Lenient int parsing — accepts `int`, `double`, numeric `String` or
/// `null`. The backend sometimes returns counts as doubles (e.g. `45.0`)
/// which made the previous `as int?` cast throw a runtime TypeError.
int _safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}

class DailyStat {
  final String date;
  final int focusMinutes;
  final int completedTasks;

  const DailyStat({
    required this.date,
    required this.focusMinutes,
    required this.completedTasks,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      date: json['date']?.toString() ?? '',
      focusMinutes: _safeInt(json['focusMinutes']),
      completedTasks: _safeInt(json['completedTasks']),
    );
  }
}

class AnalyticsReport {
  final int totalTasks;
  final int completedTasks;
  final int completionRate;
  final int totalFocusMinutes;
  final int totalFocusSessions;
  final List<DailyStat> dailyStats;

  const AnalyticsReport({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.totalFocusMinutes,
    required this.totalFocusSessions,
    required this.dailyStats,
  });

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final daily = json['dailyStats'] as List<dynamic>? ?? [];

    return AnalyticsReport(
      totalTasks: _safeInt(summary['totalTasksCreated']),
      completedTasks: _safeInt(summary['completedTasksCount']),
      completionRate: _safeInt(summary['completionRatePercentage']),
      totalFocusMinutes: _safeInt(summary['totalFocusTimeMinutes']),
      totalFocusSessions: _safeInt(summary['totalFocusSessionsCount']),
      dailyStats: daily
          .whereType<Map<String, dynamic>>()
          .map(DailyStat.fromJson)
          .toList(),
    );
  }
}
