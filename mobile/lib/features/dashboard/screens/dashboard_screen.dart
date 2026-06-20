import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_focus_stats_section.dart';
import '../widgets/dashboard_greeting_header.dart';
import '../widgets/dashboard_productivity_card.dart';
import '../widgets/dashboard_recent_projects_section.dart';
import '../widgets/dashboard_today_tasks_section.dart';
import '../widgets/dashboard_upcoming_events_section.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onTabSelect;

  const DashboardScreen({super.key, this.onTabSelect});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().loadDashboard();
        context.read<AuthProvider>().fetchCurrentUser();
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<DashboardProvider>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        [ThemeService.isDarkMode, LocaleService.languageCode],
      ),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final primary = ThemeService.getPrimaryColor(isDark);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Consumer2<DashboardProvider, AuthProvider>(
            builder: (context, dashboardProvider, authProvider, child) {
              final isLoading = dashboardProvider.isLoading &&
                  dashboardProvider.status !=
                      DashboardLoadStatus.loaded;
              final data = dashboardProvider.data;
              final userName = authProvider.currentUser?['name']
                      ?.toString()
                      .trim()
                      .isNotEmpty ==
                  true
                  ? authProvider.currentUser!['name'].toString()
                  : authProvider.username.isNotEmpty
                      ? authProvider.username
                      : 'FlowMate';

              return RefreshIndicator(
                onRefresh: _refresh,
                color: primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          FadeInSlide(
                            delayMs: 0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DashboardGreetingHeader(
                                    userName: userName,
                                    productivityScore: data.productivityScore,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: NotificationBell(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (isLoading)
                            const Column(
                              children: [
                                ShimmerLoading(
                                  width: double.infinity,
                                  height: 130,
                                  borderRadius: 24,
                                ),
                                SizedBox(height: 16),
                                ShimmerLoading(
                                  width: double.infinity,
                                  height: 100,
                                  borderRadius: 20,
                                ),
                              ],
                            )
                          else ...[
                            FadeInSlide(
                              delayMs: 80,
                              child: DashboardProductivityCard(
                                score: data.productivityScore,
                                weeklyTrendPercent:
                                    data.weeklyTrendPercent,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeInSlide(
                              delayMs: 140,
                              child: DashboardTodayTasksSection(
                                dueToday: data.dueTodayCount,
                                overdue: data.overdueCount,
                                completed: data.completedTodayCount,
                                onTap: () => widget.onTabSelect?.call(1),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeInSlide(
                              delayMs: 200,
                              child: DashboardFocusStatsSection(
                                todayMinutes: data.focusTodayMinutes,
                                weeklyMinutes: data.focusWeeklyMinutes,
                                onTap: () => widget.onTabSelect?.call(3),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeInSlide(
                              delayMs: 260,
                              child: DashboardUpcomingEventsSection(
                                events: data.upcomingEvents,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeInSlide(
                              delayMs: 320,
                              child: DashboardRecentProjectsSection(
                                projects: data.recentProjects,
                                onViewAll: () =>
                                    widget.onTabSelect?.call(2),
                              ),
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
