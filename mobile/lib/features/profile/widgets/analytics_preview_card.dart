import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../analytics/models/analytics_report.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../analytics/services/analytics_service.dart';

/// Compact analytics card shown inside the Profile screen's INSIGHTS section.
///
/// Pulls two weeks of dailyStats (current + previous) in parallel and renders
/// a big "completed tasks" number, a delta vs last week and a 7-day sparkline.
class AnalyticsPreviewCard extends StatefulWidget {
  final AnalyticsService service;

  const AnalyticsPreviewCard({
    super.key,
    this.service = const AnalyticsService(),
  });

  @override
  State<AnalyticsPreviewCard> createState() => AnalyticsPreviewCardState();
}

class AnalyticsPreviewCardState extends State<AnalyticsPreviewCard> {
  bool _loading = true;
  String? _error;
  _WeeklySummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // The backend currently exposes `week` and `month` ranges. We pull
      // both: the week range powers the headline + sparkline; month gives
      // the trailing window we sample for the previous-week comparison.
      final week = await widget.service.getAnalyticsReport('week');
      AnalyticsReport? month;
      try {
        month = await widget.service.getAnalyticsReport('month');
      } catch (_) {
        // Previous-week comparison is optional — degrade silently.
        month = null;
      }
      if (!mounted) return;
      setState(() {
        _summary = _WeeklySummary.compute(week: week, month: month);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final cardBg = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    const accent = Color(0xFF8B5CF6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openAnalytics,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(accent: accent),
              const SizedBox(height: 12),
              _Body(
                loading: _loading,
                error: _error,
                summary: _summary,
                accent: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Color accent;

  const _Header({required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.insights_rounded, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleService.tr('Năng suất', en: 'Productivity'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                LocaleService.tr('Tuần này', en: 'This week'),
                style: TextStyle(color: captionColor, fontSize: 11),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: captionColor, size: 20),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final bool loading;
  final String? error;
  final _WeeklySummary? summary;
  final Color accent;

  const _Body({
    required this.loading,
    required this.error,
    required this.summary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return _Skeleton(accent: accent);
    if (error != null) {
      return _StatusMessage(
        text: LocaleService.tr(
          'Không tải được báo cáo.',
          en: 'Could not load report.',
        ),
      );
    }
    if (summary == null || summary!.completedThisWeek == 0) {
      return _StatusMessage(
        text: LocaleService.tr(
          'Chưa đủ dữ liệu. Hoàn thành vài task để xem báo cáo tuần.',
          en: 'Not enough data yet. Complete tasks to unlock a weekly report.',
        ),
      );
    }

    final s = summary!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _HeadlineNumber(value: s.completedThisWeek),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DeltaPill(delta: s.deltaPercent),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: _Sparkline(values: s.dailySeries, color: accent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeadlineNumber extends StatelessWidget {
  final int value;

  const _HeadlineNumber({required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: textColor,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          LocaleService.tr('Task xong', en: 'Tasks done'),
          style: TextStyle(
            color: captionColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final double? delta;

  const _DeltaPill({required this.delta});

  @override
  Widget build(BuildContext context) {
    final value = delta;
    if (value == null) {
      return _Chip(
        label: LocaleService.tr('Tuần đầu tiên', en: 'First week'),
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF06B6D4),
      );
    }
    final positive = value >= 0;
    final color = positive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final sign = positive ? '+' : '';
    final label = LocaleService.tr(
      '$sign${value.toStringAsFixed(0)}% so với tuần trước',
      en: '$sign${value.toStringAsFixed(0)}% vs last week',
    );
    return _Chip(
      label: label,
      icon: positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      color: color,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Chip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<int> values;
  final Color color;

  const _Sparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final ratio = maxVal == 0 ? 0.0 : values[i] / maxVal;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              height: 4 + (ratio * 26),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3 + ratio * 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final Color accent;

  const _Skeleton({required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final shimmer = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    return Row(
      children: [
        Container(
          width: 56,
          height: 36,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String text;

  const _StatusMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          color: ThemeService.getSubTextColor(isDark),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Aggregated view-model for the card.
class _WeeklySummary {
  final int completedThisWeek;
  final double? deltaPercent;
  final List<int> dailySeries;

  const _WeeklySummary({
    required this.completedThisWeek,
    required this.deltaPercent,
    required this.dailySeries,
  });

  static _WeeklySummary compute({
    required AnalyticsReport week,
    AnalyticsReport? month,
  }) {
    final lastSeven = _lastN(week.dailyStats, 7);
    final completedThisWeek =
        lastSeven.fold<int>(0, (sum, s) => sum + s.completedTasks);
    final dailySeries =
        lastSeven.map((s) => s.completedTasks).toList(growable: false);

    double? delta;
    if (month != null && month.dailyStats.length >= 14) {
      // Take the 7 days right before the current 7 as the comparison window.
      final monthly = month.dailyStats;
      final end = monthly.length - 7;
      final start = end - 7;
      if (start >= 0 && end > start) {
        final prev = monthly
            .sublist(start, end)
            .fold<int>(0, (sum, s) => sum + s.completedTasks);
        if (prev > 0) {
          delta = ((completedThisWeek - prev) / prev) * 100.0;
        } else if (completedThisWeek > 0) {
          delta = 100.0;
        }
      }
    }

    return _WeeklySummary(
      completedThisWeek: completedThisWeek,
      deltaPercent: delta,
      dailySeries: dailySeries,
    );
  }

  static List<DailyStat> _lastN(List<DailyStat> stats, int n) {
    if (stats.length <= n) return stats;
    return stats.sublist(stats.length - n);
  }
}
