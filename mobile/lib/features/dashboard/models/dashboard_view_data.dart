import '../../calendar/models/calendar_item.dart';
import '../../projects/models/project_model.dart';
import 'dashboard_summary.dart';
import 'today_item.dart';

/// Aggregated dashboard state for the redesigned home screen.
class DashboardViewData {
  final DashboardSummary summary;
  final int productivityScore;
  final double weeklyTrendPercent;
  final int dueTodayCount;
  final int overdueCount;
  final int completedTodayCount;
  final int focusTodayMinutes;
  final int focusWeeklyMinutes;
  final List<CalendarItem> upcomingEvents;
  final List<ProjectModel> recentProjects;

  /// Tasks + events for today, time-sorted. Drives the unified Today
  /// timeline on the home screen.
  final List<TodayItem> todayTimeline;

  /// Number of meetings/events scheduled for today (subset of [todayTimeline]).
  final int meetingsTodayCount;

  const DashboardViewData({
    required this.summary,
    required this.productivityScore,
    required this.weeklyTrendPercent,
    required this.dueTodayCount,
    required this.overdueCount,
    required this.completedTodayCount,
    required this.focusTodayMinutes,
    required this.focusWeeklyMinutes,
    required this.upcomingEvents,
    required this.recentProjects,
    required this.todayTimeline,
    required this.meetingsTodayCount,
  });

  static const DashboardViewData empty = DashboardViewData(
    summary: DashboardSummary.empty,
    productivityScore: 0,
    weeklyTrendPercent: 0,
    dueTodayCount: 0,
    overdueCount: 0,
    completedTodayCount: 0,
    focusTodayMinutes: 0,
    focusWeeklyMinutes: 0,
    upcomingEvents: [],
    recentProjects: [],
    todayTimeline: [],
    meetingsTodayCount: 0,
  );
}
