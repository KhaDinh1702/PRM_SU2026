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
      focusMinutes: json['focusMinutes'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
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
      totalTasks: summary['totalTasksCreated'] as int? ?? 0,
      completedTasks: summary['completedTasksCount'] as int? ?? 0,
      completionRate: summary['completionRatePercentage'] as int? ?? 0,
      totalFocusMinutes: summary['totalFocusTimeMinutes'] as int? ?? 0,
      totalFocusSessions: summary['totalFocusSessionsCount'] as int? ?? 0,
      dailyStats: daily
          .whereType<Map<String, dynamic>>()
          .map(DailyStat.fromJson)
          .toList(),
    );
  }
}
