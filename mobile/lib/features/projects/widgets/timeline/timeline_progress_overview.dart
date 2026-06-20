import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';
import '../../models/project_milestone.dart';

/// Header strip rendered above the milestone list. Shows
/// "Project Timeline" + a progress bar + small badges for done / overdue
/// counts so the user can scan timeline health in one glance.
class TimelineProgressOverview extends StatelessWidget {
  final List<ProjectMilestone> milestones;

  const TimelineProgressOverview({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    // Count only user milestones for progress — system markers (Created,
    // Deadline) would skew the ratio.
    final user = milestones.where((m) => m.isEditable).toList();
    final total = user.length;
    final done = user.where((m) => m.isCompleted).length;
    final overdue = user
        .where((m) => m.status == MilestoneStatus.overdue)
        .length;
    final ratio = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Timeline',
            style: TextStyle(
              color: textColor,
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track milestones from kickoff to delivery.',
            style: TextStyle(color: captionColor, fontSize: AppSizes.fontS + 1),
          ),
          if (total > 0) ...[
            const SizedBox(height: AppSizes.paddingS + 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MetricChip(
                  label: '$done/$total done',
                  color: const Color(0xFF10B981),
                ),
                if (overdue > 0)
                  _MetricChip(
                    label:
                        '$overdue overdue',
                    color: const Color(0xFFEF4444),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetricChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppSizes.fontS + 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
