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
import '../models/today_item.dart';
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

      // Each source loads in parallel but degrades gracefully if its
      // endpoint blows up — a single bad payload should not blank the
      // whole home screen.
      final results = await Future.wait<dynamic>([
        _dashboardService
            .getSummary()
            .catchError((_) => DashboardSummary.empty),
        _taskService
            .getTasks(tab: 'all', sortBy: 'recent')
            .catchError((_) => const <TaskModel>[]),
        _calendarService
            .fetchCalendarItems(start: todayStart, end: calendarEnd)
            .catchError((_) => const <CalendarItem>[]),
        _analyticsService.getAnalyticsReport('week').catchError(
              (_) => const AnalyticsReport(
                totalTasks: 0,
                completedTasks: 0,
                completionRate: 0,
                totalFocusMinutes: 0,
                totalFocusSessions: 0,
                dailyStats: [],
              ),
            ),
        _projectService.getProjects().catchError((_) => const <dynamic>[]),
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

      final todayTimeline = _buildTodayTimeline(
        tasks: tasks,
        calendarItems: calendarItems,
        todayStart: todayStart,
      );
      final meetingsTodayCount = todayTimeline
          .where((item) => item.kind == TodayItemKind.event)
          .length;

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
        todayTimeline: todayTimeline,
        meetingsTodayCount: meetingsTodayCount,
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

  /// Combines today's tasks and today's calendar items into one time-sorted
  /// list. All-day items are pushed to the top of the day.
  List<TodayItem> _buildTodayTimeline({
    required List<TaskModel> tasks,
    required List<CalendarItem> calendarItems,
    required DateTime todayStart,
  }) {
    final todayEnd = todayStart.add(const Duration(days: 1));
    final items = <TodayItem>[];

    for (final task in tasks) {
      final due = task.effectiveDueDateTime;
      if (due == null) continue;
      if (due.isBefore(todayStart) || !due.isBefore(todayEnd)) continue;
      items.add(TodayItem.fromTask(task));
    }

    for (final cal in calendarItems) {
      final start = cal.start;
      if (start.isBefore(todayStart) || !start.isBefore(todayEnd)) continue;
      items.add(TodayItem.fromCalendarItem(cal));
    }

    items.sort((a, b) {
      // All-day entries float to the top, otherwise compare by time.
      if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
      return a.time.compareTo(b.time);
    });

    return items;
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
