import 'package:flutter/material.dart';

import '../../../../services/theme_service.dart';
import '../project_shared.dart';

class ProjectInsightsGrid extends StatelessWidget {
  final int totalTasks;
  final int memberCount;
  final int activeDays;
  final String status;
  final Color statusColor;

  const ProjectInsightsGrid({
    super.key,
    required this.totalTasks,
    required this.memberCount,
    required this.activeDays,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Insights',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _InsightTile(
              icon: Icons.checklist_rounded,
              label: 'Tasks',
              value: '$totalTasks',
              color: const Color(0xFF06B6D4),
            ),
            _InsightTile(
              icon: Icons.groups_rounded,
              label: 'Members',
              value: '$memberCount',
              color: const Color(0xFF8B5CF6),
            ),
            _InsightTile(
              icon: Icons.calendar_today_rounded,
              label: 'Active Days',
              value: '$activeDays',
              color: const Color(0xFFF59E0B),
            ),
            _InsightTile(
              icon: Icons.flag_rounded,
              label: 'Status',
              value: status,
              color: statusColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return ProjectDetailCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: captionColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
