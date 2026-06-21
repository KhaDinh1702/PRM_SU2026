import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_greeting_header.dart';
import '../widgets/dashboard_recent_projects_section.dart';
import '../widgets/dashboard_today_summary.dart';
import '../widgets/dashboard_today_timeline.dart';

/// Home screen.
///
/// Redesigned as a "Today view" — the greeting, today summary and the unified
/// task + event timeline are the dominant content. The scattered cards
/// (productivity ring, separate "today tasks", focus stats, upcoming events)
/// have been folded into the timeline and the summary chip so the user can
/// see the whole day at a glance.
class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onTabSelect;

  const DashboardScreen({super.key, this.onTabSelect});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _tabTasks = 1;
  static const int _tabProjects = 2;

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
      builder: (context, _) {
        final isDark = ThemeService.isDarkMode.value;
        final primary = ThemeService.getPrimaryColor(isDark);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Consumer2<DashboardProvider, AuthProvider>(
            builder: (context, dashboard, auth, _) {
              final data = dashboard.data;
              final isLoading = dashboard.isLoading &&
                  dashboard.status != DashboardLoadStatus.loaded;
              final userName = _displayName(auth);

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
                          _Header(userName: userName, score: data.productivityScore),
                          const SizedBox(height: 14),
                          DashboardTodaySummary(
                            taskCount: data.dueTodayCount +
                                data.overdueCount +
                                data.completedTodayCount,
                            meetingCount: data.meetingsTodayCount,
                            focusMinutes: data.focusTodayMinutes,
                          ),
                          const SizedBox(height: 22),
                          _SectionTitle(
                            text: LocaleService.tr('LỊCH HÔM NAY',
                                en: 'TODAY'),
                          ),
                          const SizedBox(height: 10),
                          if (isLoading)
                            const ShimmerLoading(
                              width: double.infinity,
                              height: 240,
                              borderRadius: 18,
                            )
                          else
                            DashboardTodayTimeline(
                              items: data.todayTimeline,
                              onTapTask: (_) =>
                                  widget.onTabSelect?.call(_tabTasks),
                              onTapEvent: (_) =>
                                  widget.onTabSelect?.call(_tabTasks),
                            ),
                          const SizedBox(height: 24),
                          _SectionTitle(
                            text: LocaleService.tr('DỰ ÁN GẦN ĐÂY',
                                en: 'RECENT PROJECTS'),
                          ),
                          const SizedBox(height: 10),
                          if (isLoading)
                            const ShimmerLoading(
                              width: double.infinity,
                              height: 130,
                              borderRadius: 18,
                            )
                          else
                            DashboardRecentProjectsSection(
                              projects: data.recentProjects,
                              onViewAll: () =>
                                  widget.onTabSelect?.call(_tabProjects),
                            ),
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

  String _displayName(AuthProvider auth) {
    final fullName = auth.currentUser?['name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    if (auth.username.isNotEmpty) return auth.username;
    return 'FlowMate';
  }
}

class _Header extends StatelessWidget {
  final String userName;
  final int score;

  const _Header({required this.userName, required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DashboardGreetingHeader(
            userName: userName,
            productivityScore: score,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: NotificationBell(),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: TextStyle(
          color: captionColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}
