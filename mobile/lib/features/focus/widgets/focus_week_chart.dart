import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

/// Compact bar chart of the user's focus minutes over the last 7 days.
/// Today is the rightmost bar; days with zero focus draw as a thin
/// placeholder so the axis still reads correctly.
class FocusWeekChart extends StatelessWidget {
  /// Oldest day first (index 0 = 6 days ago, index 6 = today).
  final List<int> weekBuckets;

  static const Color _accent = Color(0xFF06B6D4);

  const FocusWeekChart({super.key, required this.weekBuckets});

  static const List<String> _dayLabelsEn = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _dayLabelsVi = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  /// Build a list of [_dayLabel + bucket] pairs aligned so the rightmost
  /// entry is today. The label comes from today's weekday (1=Mon ... 7=Sun)
  /// walked backwards.
  List<MapEntry<String, int>> _buildEntries() {
    final useVi = LocaleService.languageCode.value == 'vi';
    final labels = useVi ? _dayLabelsVi : _dayLabelsEn;
    final now = DateTime.now();
    final todayIndex = (now.weekday - 1) % 7; // 0=Mon
    final values = weekBuckets.length == 7
        ? weekBuckets
        : List<int>.filled(7, 0);
    return [
      for (var offset = 6; offset >= 0; offset--)
        MapEntry(
          labels[(todayIndex - offset + 7) % 7],
          values[6 - offset],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    final entries = _buildEntries();
    final peak = entries.fold<int>(0, (max, e) => e.value > max ? e.value : max);
    final hasAny = peak > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                LocaleService.tr('7 ngày qua', en: 'Last 7 days'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                hasAny
                    ? '${(peak / 60).round()}m peak'
                    : LocaleService.tr('Chưa có dữ liệu', en: 'No data yet'),
                style: TextStyle(
                  color: captionColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in entries)
                  Expanded(
                    child: _Bar(
                      value: entry.value,
                      peak: peak,
                      label: entry.key,
                      labelColor: captionColor,
                      accent: _accent,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final int peak;
  final String label;
  final Color labelColor;
  final Color accent;

  const _Bar({
    required this.value,
    required this.peak,
    required this.label,
    required this.labelColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = peak > 0 && value > 0;
    final ratio = hasData ? (value / peak).clamp(0.05, 1.0) : 0.0;
    final color = hasData ? accent : accent.withValues(alpha: 0.18);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: ratio == 0 ? 0.05 : ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
