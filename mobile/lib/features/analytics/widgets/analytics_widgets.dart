import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/analytics_report.dart';

/// Range selector pills for selecting day, week, month
class AnalyticsRangeSelector extends StatelessWidget {
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;
  final Color activeColor;

  const AnalyticsRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final options = [
      {'key': 'day', 'label': LocaleService.tr('Hôm nay', en: 'Today')},
      {'key': 'week', 'label': LocaleService.tr('7 ngày', en: '7 days')},
      {'key': 'month', 'label': LocaleService.tr('30 ngày', en: '30 days')},
    ];

    return Row(
      children: options.map((opt) {
        final isActive = selectedRange == opt['key'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onRangeChanged(opt['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.12)
                    : ThemeService.getCardColor(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? activeColor.withValues(alpha: 0.3)
                      : ThemeService.getBorderColor(isDark),
                ),
              ),
              child: Center(
                child: Text(
                  opt['label']!,
                  style: TextStyle(
                    color: isActive
                        ? activeColor
                        : ThemeService.getCaptionColor(isDark),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Shimmer placeholder loading for summary section
class AnalyticsShimmerSummary extends StatelessWidget {
  const AnalyticsShimmerSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: const [
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
      ],
    );
  }
}

/// Stat card widget
class AnalyticsStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;

  const AnalyticsStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(AppSizes.paddingM - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 14),
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    height: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: AppSizes.fontS,
                    color: captionColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontS + 1,
              color: subTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section containing the 4 summary stat cards
class AnalyticsSummarySection extends StatelessWidget {
  final AnalyticsReport report;
  final Color themeColor;

  const AnalyticsSummarySection({
    super.key,
    required this.report,
    required this.themeColor,
  });

  String _formatFocusTime(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final pendingTasks = report.totalTasks - report.completedTasks;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: [
        FadeInSlide(
          delayMs: 100,
          child: AnalyticsStatCard(
            icon: Icons.task_alt_rounded,
            label: LocaleService.tr('Hoàn thành', en: 'Completed'),
            value: '${report.completedTasks}',
            unit: LocaleService.tr('tasks', en: 'tasks'),
            color: AppColors.success,
            isDark: isDark,
          ),
        ),
        FadeInSlide(
          delayMs: 150,
          child: AnalyticsStatCard(
            icon: Icons.pending_actions_rounded,
            label: LocaleService.tr('Đang chờ', en: 'Pending'),
            value: '$pendingTasks',
            unit: LocaleService.tr('tasks', en: 'tasks'),
            color: AppColors.warning,
            isDark: isDark,
          ),
        ),
        FadeInSlide(
          delayMs: 200,
          child: AnalyticsStatCard(
            icon: Icons.bolt_rounded,
            label: LocaleService.tr('Thời gian Focus', en: 'Focus time'),
            value: _formatFocusTime(report.totalFocusMinutes),
            unit: '',
            color: themeColor,
            isDark: isDark,
          ),
        ),
        FadeInSlide(
          delayMs: 250,
          child: AnalyticsStatCard(
            icon: Icons.hourglass_full_rounded,
            label: LocaleService.tr('Phiên Pomodoro', en: 'Pomodoro sessions'),
            value: '${report.totalFocusSessions}',
            unit: LocaleService.tr('phiên', en: 'sessions'),
            color: AppColors.dashboardAccent,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

/// Completion rate card with a circular progress indicator
class CompletionRingCard extends StatelessWidget {
  final AnalyticsReport report;
  final Color accentColor;

  const CompletionRingCard({
    super.key,
    required this.report,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final pendingTasks = report.totalTasks - report.completedTasks;

    return GlassCard(
      borderRadius: AppSizes.radiusL,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: CompletionRingPainter(
                percentage: report.completionRate / 100,
                color: accentColor,
                bgColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${report.completionRate}%',
                      style: TextStyle(
                        color: textColor,
                        fontSize: AppSizes.fontTitle,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      LocaleService.tr('hoàn thành', en: 'completed'),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleService.tr('Tỷ Lệ Hoàn Thành', en: 'Completion Rate'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppSizes.fontL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _ProgressRow(
                  label: LocaleService.tr('Hoàn thành', en: 'Completed'),
                  count: report.completedTasks,
                  color: AppColors.success,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _ProgressRow(
                  label: LocaleService.tr('Đang chờ', en: 'Pending'),
                  count: pendingTasks,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _ProgressRow(
                  label: LocaleService.tr('Tổng cộng', en: 'Total'),
                  count: report.totalTasks,
                  color: accentColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _ProgressRow({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: captionColor, fontSize: 12),
        ),
        const Spacer(),
        Text(
          '$count',
          style: TextStyle(
            color: textColor,
            fontSize: AppSizes.fontM,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Custom Painter for Completion Ring
class CompletionRingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color bgColor;

  CompletionRingPainter({
    required this.percentage,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [color.withValues(alpha: 0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow dot
    if (percentage > 0) {
      final endAngle = -pi / 2 + sweepAngle;
      final dotX = center.dx + radius * cos(endAngle);
      final dotY = center.dy + radius * sin(endAngle);

      final dotPaint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
      canvas.drawCircle(Offset(dotX, dotY), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CompletionRingPainter old) {
    return old.percentage != percentage;
  }
}

/// Bar chart for focus time or completed tasks
class AnalyticsBarChart extends StatelessWidget {
  final List<DailyStat> dailyStats;
  final Color barColor;
  final String dataKey; // 'focusMinutes' or 'completedTasks'
  final String unit;
  final String Function(String?) formatDayLabel;

  const AnalyticsBarChart({
    super.key,
    required this.dailyStats,
    required this.barColor,
    required this.dataKey,
    required this.unit,
    required this.formatDayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);

    final allZero = dailyStats.every((day) {
      final val = dataKey == 'focusMinutes' ? day.focusMinutes : day.completedTasks;
      return val == 0;
    });

    if (dailyStats.isEmpty || allZero) {
      return GlassCard(
        borderRadius: AppSizes.radiusL,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppSizes.paddingL),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📊', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(
                LocaleService.tr('Chưa có dữ liệu thống kê',
                    en: 'No stats yet'),
                style: TextStyle(
                  color: textColor,
                  fontSize: AppSizes.fontM,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  LocaleService.tr(
                    'Hãy bắt đầu hoàn thành task hoặc chạy Focus session để ghi nhận dữ liệu.',
                    en: 'Complete a task or run a Focus session to start tracking.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: captionColor,
                    fontSize: AppSizes.fontS + 1,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Find max value
    double maxVal = 0;
    for (final day in dailyStats) {
      final val = (dataKey == 'focusMinutes' ? day.focusMinutes : day.completedTasks).toDouble();
      if (val > maxVal) maxVal = val;
    }
    if (maxVal == 0) maxVal = 1;

    return GlassCard(
      borderRadius: AppSizes.radiusL,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyStats.map((day) {
                final val = (dataKey == 'focusMinutes' ? day.focusMinutes : day.completedTasks).toDouble();
                final heightFraction = val / maxVal;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${val.toInt()}',
                              style: TextStyle(
                                color: barColor,
                                fontSize: AppSizes.fontXS,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          height: max(4.0, 130.0 * heightFraction),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                barColor,
                                barColor.withValues(alpha: 0.5),
                              ],
                            ),
                            boxShadow: val > 0
                                ? [
                                    BoxShadow(
                                      color: barColor.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: dailyStats.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    formatDayLabel(day.date),
                    style: TextStyle(
                      color: captionColor,
                      fontSize: AppSizes.fontXS,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Performance summary card (averages, best day)
class PerformanceSummaryCard extends StatelessWidget {
  final AnalyticsReport report;
  final Color themeColor;
  final String Function(String?) formatDayLabel;

  const PerformanceSummaryCard({
    super.key,
    required this.report,
    required this.themeColor,
    required this.formatDayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final dailyStats = report.dailyStats;
    final totalDays = dailyStats.length;

    final avgTasks =
        totalDays > 0 ? (report.completedTasks / totalDays).toStringAsFixed(1) : '0';
    final avgFocus = totalDays > 0
        ? (report.totalFocusMinutes / totalDays).toStringAsFixed(0)
        : '0';

    String bestDay = '—';
    int bestCount = 0;
    for (final day in dailyStats) {
      final count = day.completedTasks;
      if (count > bestCount) {
        bestCount = count;
        bestDay = formatDayLabel(day.date).replaceAll('\n', ' ');
      }
    }

    return GlassCard(
      borderRadius: AppSizes.radiusL,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: themeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weekly Performance',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            icon: Icons.speed_rounded,
            label: LocaleService.tr('TB Tasks/ngày', en: 'Avg Tasks/day'),
            value: avgTasks,
            color: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.timer_rounded,
            label: LocaleService.tr('TB Focus/ngày', en: 'Avg Focus/day'),
            value: '${avgFocus}m',
            color: AppColors.dashboardAccent,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.star_rounded,
            label: LocaleService.tr('Ngày làm tốt nhất', en: 'Best Day'),
            value: bestDay,
            color: AppColors.warning,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.whatshot_rounded,
            label: LocaleService.tr('Tổng phiên Focus', en: 'Total Focus Sessions'),
            value: '${report.totalFocusSessions} ${LocaleService.tr('phiên', en: 'sessions')}',
            color: themeColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: captionColor, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: AppSizes.fontM,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
