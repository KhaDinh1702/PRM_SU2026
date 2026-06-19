import 'package:flutter/foundation.dart';

import '../../analytics/models/analytics_report.dart';
import '../../analytics/services/analytics_service.dart';
import '../../calendar/models/calendar_item.dart';
import '../../calendar/services/calendar_service.dart';
import '../../projects/models/project_model.dart';
import '../../projects/services/project_service.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/services/task_service.dart';
import '../models/dashboard_summary.dart';
import '../models/dashboard_view_data.dart';
import '../services/dashboard_service.dart';

enum DashboardLoadStatus { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService;
  final TaskService _taskService;
  final CalendarService _calendarService;
  final AnalyticsService _analyticsService;
  final ProjectService _projectService;

  DashboardProvider({
    DashboardService? dashboardService,
    TaskService? taskService,
    CalendarService? calendarService,
    AnalyticsService? analyticsService,
    ProjectService? projectService,
  })  : _dashboardService = dashboardService ?? const DashboardService(),
        _taskService = taskService ?? const TaskService(),
        _calendarService = calendarService ?? const CalendarService(),
        _analyticsService = analyticsService ?? const AnalyticsService(),
        _projectService = projectService ?? const ProjectService();

  DashboardLoadStatus _status = DashboardLoadStatus.initial;
  DashboardViewData _data = DashboardViewData.empty;
  String? _errorMessage;

  DashboardLoadStatus get status => _status;
  DashboardViewData get data => _data;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == DashboardLoadStatus.loading;

  Future<void> loadDashboard({bool silent = false}) async {
    if (!silent) {
      _status = DashboardLoadStatus.loading;
      notifyListeners();
    }

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final calendarEnd = todayStart.add(const Duration(days: 14));

      final results = await Future.wait([
        _dashboardService.getSummary(),
        _taskService.getTasks(tab: 'all', sortBy: 'recent'),
        _calendarService.fetchCalendarItems(start: todayStart, end: calendarEnd),
        _analyticsService.getAnalyticsReport('week'),
        _projectService.getProjects(),
      ]);

      final summary = results[0] as DashboardSummary;
      final tasks = results[1] as List<TaskModel>;
      final calendarItems = results[2] as List<CalendarItem>;
      final analytics = results[3] as AnalyticsReport;
      final projectsRaw = results[4];

      final projects = _normalizeProjects(projectsRaw);
      final taskStats = _computeTaskStats(tasks, todayStart);
      final focusWeeklyMinutes = analytics.totalFocusMinutes;
      final focusTodayMinutes = _focusTodayMinutes(analytics.dailyStats, todayStart);
      final weeklyTrend = _computeWeeklyTrend(analytics.dailyStats);
      final productivityScore = _computeProductivityScore(
        completedToday: taskStats.completedToday,
        dueToday: taskStats.dueToday,
        overdue: taskStats.overdue,
        focusTodayMinutes: focusTodayMinutes > 0
            ? focusTodayMinutes
            : summary.totalFocusTimeTodayMinutes,
        completionRate: analytics.completionRate,
      );

      final upcomingEvents = calendarItems
          .where((item) => !item.start.isBefore(now))
          .take(3)
          .toList();

      final recentProjects = projects
          .where((p) => p.stateLabel != 'Completed')
          .toList()
        ..sort((a, b) => b.attentionScore.compareTo(a.attentionScore));

      _data = DashboardViewData(
        summary: summary,
        productivityScore: productivityScore,
        weeklyTrendPercent: weeklyTrend,
        dueTodayCount: taskStats.dueToday,
        overdueCount: taskStats.overdue,
        completedTodayCount: taskStats.completedToday,
        focusTodayMinutes: focusTodayMinutes > 0
            ? focusTodayMinutes
            : summary.totalFocusTimeTodayMinutes,
        focusWeeklyMinutes: focusWeeklyMinutes,
        upcomingEvents: upcomingEvents,
        recentProjects: recentProjects.take(4).toList(),
      );
      _status = DashboardLoadStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = DashboardLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  List<ProjectModel> _normalizeProjects(dynamic decoded) {
    final List<dynamic> rawProjects;
    if (decoded is List) {
      rawProjects = decoded;
    } else if (decoded is Map && decoded['projects'] is List) {
      rawProjects = decoded['projects'] as List;
    } else {
      rawProjects = const [];
    }

    return rawProjects
        .map((item) {
          if (item is Map<String, dynamic>) {
            return ProjectModel.fromJson(item);
          }
          if (item is Map) {
            return ProjectModel.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        })
        .whereType<ProjectModel>()
        .toList();
  }

  ({int dueToday, int overdue, int completedToday}) _computeTaskStats(
    List<TaskModel> tasks,
    DateTime todayStart,
  ) {
    var dueToday = 0;
    var overdue = 0;
    var completedToday = 0;

    for (final task in tasks) {
      final due = task.effectiveDueDateTime;
      if (task.status == TaskStatus.completed) {
        if (due != null) {
          final dueDay = DateTime(due.year, due.month, due.day);
          if (dueDay == todayStart) completedToday++;
        }
        continue;
      }

      if (task.isOverdue) {
        overdue++;
        continue;
      }

      if (due != null) {
        final dueDay = DateTime(due.year, due.month, due.day);
        if (dueDay == todayStart) dueToday++;
      }
    }

    return (dueToday: dueToday, overdue: overdue, completedToday: completedToday);
  }

  int _focusTodayMinutes(List<DailyStat> dailyStats, DateTime todayStart) {
    final todayKey =
        '${todayStart.year}-${todayStart.month.toString().padLeft(2, '0')}-${todayStart.day.toString().padLeft(2, '0')}';
    for (final stat in dailyStats) {
      if (stat.date.startsWith(todayKey) ||
          stat.date == todayKey.split('-').reversed.join('-')) {
        return stat.focusMinutes;
      }
    }
    return 0;
  }

  double _computeWeeklyTrend(List<DailyStat> dailyStats) {
    if (dailyStats.length < 2) return 0;

    final sorted = [...dailyStats];
    final midpoint = sorted.length ~/ 2;
    final firstHalf =
        sorted.take(midpoint).fold<int>(0, (sum, s) => sum + s.focusMinutes);
    final secondHalf = sorted
        .skip(midpoint)
        .fold<int>(0, (sum, s) => sum + s.focusMinutes);

    if (firstHalf == 0) return secondHalf > 0 ? 100 : 0;
    return ((secondHalf - firstHalf) / firstHalf * 100).clamp(-100, 100);
  }

  int _computeProductivityScore({
    required int completedToday,
    required int dueToday,
    required int overdue,
    required int focusTodayMinutes,
    required int completionRate,
  }) {
    final totalToday = dueToday + overdue + completedToday;
    final taskScore = totalToday > 0
        ? (completedToday / totalToday * 40).round()
        : (completionRate > 0 ? 20 : 10);
    final focusScore = (focusTodayMinutes / 120 * 30).clamp(0, 30).round();
    final overallScore = (completionRate / 100 * 30).clamp(0, 30).round();
    return (taskScore + focusScore + overallScore).clamp(0, 100);
  }
}
