import 'package:flutter/material.dart';

import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

class DashboardFocusStatsSection extends StatelessWidget {
  final int todayMinutes;
  final int weeklyMinutes;
  final VoidCallback? onTap;

  const DashboardFocusStatsSection({
    super.key,
    required this.todayMinutes,
    required this.weeklyMinutes,
    this.onTap,
  });

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '${hours}h';
      return '${hours}h ${mins}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    const accent = Color(0xFF8B5CF6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocaleService.tr('Thống kê tập trung', en: 'Focus Statistics'),
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (onTap != null)
              TextButton(
                onPressed: onTap,
                child: Text(
                  LocaleService.tr('Mở Focus', en: 'Open Focus'),
                  style: TextStyle(
                    color: ThemeService.getPrimaryColor(isDark),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(18),
                child: _FocusTile(
                  label: LocaleService.tr('Hôm nay', en: 'Today'),
                  value: _formatDuration(todayMinutes),
                  icon: Icons.timer_outlined,
                  color: accent,
                  textColor: textColor,
                  captionColor: captionColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(18),
                child: _FocusTile(
                  label: LocaleService.tr('Tuần này', en: 'This week'),
                  value: _formatDuration(weeklyMinutes),
                  icon: Icons.calendar_view_week_rounded,
                  color: const Color(0xFF06B6D4),
                  textColor: textColor,
                  captionColor: captionColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FocusTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color captionColor;

  const _FocusTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: captionColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
