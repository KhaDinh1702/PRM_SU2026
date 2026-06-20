import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_scaffold_background.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/analytics_report.dart';
import '../services/analytics_service.dart';
import '../widgets/analytics_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String _selectedRange = 'week'; // 'day', 'week', 'month'
  final AnalyticsService _analyticsService = const AnalyticsService();
  AnalyticsReport? _report;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final report = await _analyticsService.getAnalyticsReport(_selectedRange);
      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onRangeChanged(String range) {
    if (range != _selectedRange) {
      setState(() => _selectedRange = range);
      _loadReports();
    }
  }

  String _formatDayLabel(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final days = [
        LocaleService.tr('CN', en: 'Sun'),
        LocaleService.tr('T2', en: 'Mon'),
        LocaleService.tr('T3', en: 'Tue'),
        LocaleService.tr('T4', en: 'Wed'),
        LocaleService.tr('T5', en: 'Thu'),
        LocaleService.tr('T6', en: 'Fri'),
        LocaleService.tr('T7', en: 'Sat')
      ];
      return '${days[date.weekday % 7]}\n${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = AppColors.analyticsAccent;
    const accentColor = AppColors.dashboardAccent;

    return ListenableBuilder(
      listenable: Listenable.merge(
          [ThemeService.isDarkMode, LocaleService.languageCode]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);

        final totalTasks = _report?.totalTasks ?? 0;
        final totalFocusSessions = _report?.totalFocusSessions ?? 0;
        final dailyStats = _report?.dailyStats ?? [];

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: AppScaffoldBackground(
            child: RefreshIndicator(
            onRefresh: _loadReports,
            color: themeColor,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  FadeInSlide(
                    delayMs: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleService.tr('THỐNG KÊ NĂNG SUẤT',
                              en: 'PRODUCTIVITY STATS'),
                          style: TextStyle(
                            color: captionColor,
                            fontSize: AppSizes.fontS,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Analytics & Reports',
                          style: TextStyle(
                            color: textColor,
                            fontSize: AppSizes.fontXXL,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Range selector pills ---
                  FadeInSlide(
                    delayMs: 80,
                    child: AnalyticsRangeSelector(
                      selectedRange: _selectedRange,
                      onRangeChanged: _onRangeChanged,
                      activeColor: themeColor,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingL),

                  // --- Summary Cards ---
                  _isLoading
                      ? const AnalyticsShimmerSummary()
                      : _report == null
                          ? const SizedBox.shrink()
                          : AnalyticsSummarySection(
                              report: _report!,
                              themeColor: themeColor,
                            ),
                  const SizedBox(height: 28),

                  // --- Completion Rate Ring ---
                  _isLoading
                      ? const ShimmerLoading(
                          width: double.infinity,
                          height: 200,
                          borderRadius: AppSizes.radiusL)
                      : _report == null
                          ? const SizedBox.shrink()
                          : FadeInSlide(
                              delayMs: 350,
                              child: CompletionRingCard(
                                report: _report!,
                                accentColor: accentColor,
                              ),
                            ),
                  const SizedBox(height: 28),

                  // --- Focus Time Chart ---
                  FadeInSlide(
                    delayMs: 400,
                    child: Text(
                      LocaleService.tr('BIỂU ĐỒ THỜI GIAN TẬP TRUNG',
                          en: 'FOCUS TIME CHART'),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: AppSizes.fontS,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const ShimmerLoading(
                          width: double.infinity,
                          height: 220,
                          borderRadius: AppSizes.radiusL)
                      : FadeInSlide(
                          delayMs: 450,
                          child: AnalyticsBarChart(
                            dailyStats: dailyStats,
                            barColor: accentColor,
                            dataKey: 'focusMinutes',
                            unit: LocaleService.tr('phút', en: 'mins'),
                            formatDayLabel: _formatDayLabel,
                          ),
                        ),
                  const SizedBox(height: 28),

                  // --- Completed Tasks Chart ---
                  FadeInSlide(
                    delayMs: 500,
                    child: Text(
                      LocaleService.tr('BIỂU ĐỒ TASK HOÀN THÀNH',
                          en: 'COMPLETED TASKS CHART'),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: AppSizes.fontS,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const ShimmerLoading(
                          width: double.infinity,
                          height: 220,
                          borderRadius: AppSizes.radiusL)
                      : FadeInSlide(
                          delayMs: 550,
                          child: AnalyticsBarChart(
                            dailyStats: dailyStats,
                            barColor: AppColors.success,
                            dataKey: 'completedTasks',
                            unit: 'tasks',
                            formatDayLabel: _formatDayLabel,
                          ),
                        ),

                  // --- Performance Summary ---
                  if (!_isLoading && _report != null && dailyStats.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    FadeInSlide(
                      delayMs: 600,
                      child: Text(
                        LocaleService.tr('TỔNG QUAN HIỆU SUẤT',
                            en: 'PERFORMANCE SUMMARY'),
                        style: TextStyle(
                          color: captionColor,
                          fontSize: AppSizes.fontS,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      delayMs: 650,
                      child: PerformanceSummaryCard(
                        report: _report!,
                        themeColor: themeColor,
                        formatDayLabel: _formatDayLabel,
                      ),
                    ),
                  ],

                  // Empty state
                  if (!_isLoading && totalTasks == 0 && totalFocusSessions == 0) ...[
                    const SizedBox(height: 28),
                    FadeInSlide(
                      delayMs: 400,
                      child: GlassCard(
                        borderRadius: AppSizes.radiusL,
                        padding: const EdgeInsets.all(AppSizes.paddingXL),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.insights_rounded,
                                  color: themeColor.withValues(alpha: 0.5),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                LocaleService.tr('Chưa có dữ liệu năng suất',
                                    en: 'No productivity data yet'),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: AppSizes.fontL,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                LocaleService.tr(
                                    'Bắt đầu hoàn thành công việc để xem báo cáo!',
                                    en: 'Start completing tasks to see your report!'),
                                style: TextStyle(
                                  color: captionColor,
                                  fontSize: AppSizes.fontM,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Bottom padding for navbar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}
