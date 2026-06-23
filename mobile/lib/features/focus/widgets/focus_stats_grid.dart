import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/focus_stats.dart';

/// Four headline stat tiles arranged in a 2×2 grid: today's focus time,
/// week total, current streak, and sessions completed today.
class FocusStatsGrid extends StatelessWidget {
  final FocusStats stats;

  static const Color _focus = Color(0xFF06B6D4);
  static const Color _week = Color(0xFF8B5CF6);
  static const Color _streak = Color(0xFFF59E0B);
  static const Color _sessions = Color(0xFF10B981);

  const FocusStatsGrid({super.key, required this.stats});

  String _fmtHours(int seconds) {
    if (seconds < 60) return '0m';
    final mins = seconds ~/ 60;
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: LocaleService.tr('Hôm nay', en: 'Today'),
            value: _fmtHours(stats.todayFocusSeconds),
            icon: Icons.center_focus_strong_rounded,
            tint: _focus,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: LocaleService.tr('Tuần này', en: 'This week'),
            value: _fmtHours(stats.weekFocusSeconds),
            icon: Icons.bar_chart_rounded,
            tint: _week,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: LocaleService.tr('Streak', en: 'Streak'),
            value: '${stats.currentStreakDays}',
            unit: LocaleService.tr(
                stats.currentStreakDays == 1 ? 'ngày' : 'ngày',
                en: stats.currentStreakDays == 1 ? 'day' : 'days'),
            icon: Icons.local_fire_department_rounded,
            tint: _streak,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: LocaleService.tr('Phiên', en: 'Sessions'),
            value: '${stats.sessionsCompletedToday}',
            icon: Icons.check_circle_outline_rounded,
            tint: _sessions,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color tint;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(
                  unit!,
                  style: TextStyle(
                    color: captionColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: captionColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
