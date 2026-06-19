import 'package:flutter/material.dart';

import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

class DashboardTodayTasksSection extends StatelessWidget {
  final int dueToday;
  final int overdue;
  final int completed;
  final VoidCallback? onTap;

  const DashboardTodayTasksSection({
    super.key,
    required this.dueToday,
    required this.overdue,
    required this.completed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocaleService.tr('Công việc hôm nay', en: "Today's Tasks"),
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
                  LocaleService.tr('Xem tất cả', en: 'View all'),
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
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _TaskStatTile(
                  label: LocaleService.tr('Hôm nay', en: 'Due today'),
                  count: dueToday,
                  color: const Color(0xFF06B6D4),
                  icon: Icons.today_rounded,
                  captionColor: captionColor,
                  textColor: textColor,
                ),
              ),
              Container(
                width: 1,
                height: 52,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _TaskStatTile(
                  label: LocaleService.tr('Quá hạn', en: 'Overdue'),
                  count: overdue,
                  color: const Color(0xFFEF4444),
                  icon: Icons.warning_amber_rounded,
                  captionColor: captionColor,
                  textColor: textColor,
                ),
              ),
              Container(
                width: 1,
                height: 52,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              Expanded(
                child: _TaskStatTile(
                  label: LocaleService.tr('Hoàn thành', en: 'Completed'),
                  count: completed,
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_outline_rounded,
                  captionColor: captionColor,
                  textColor: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskStatTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final Color captionColor;
  final Color textColor;

  const _TaskStatTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.captionColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: captionColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
