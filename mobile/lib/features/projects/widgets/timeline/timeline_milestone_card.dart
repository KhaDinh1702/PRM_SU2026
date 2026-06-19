import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../services/theme_service.dart';
import '../../models/project_milestone.dart';
import '../project_shared.dart';

class TimelineMilestoneCard extends StatelessWidget {
  final ProjectMilestone milestone;
  final bool isFirst;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onToggle;

  const TimelineMilestoneCard({
    super.key,
    required this.milestone,
    required this.isFirst,
    required this.isLast,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final color = milestone.isCompleted
        ? const Color(0xFF10B981)
        : const Color(0xFF06B6D4);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 12,
                    color: captionColor.withValues(alpha: 0.25),
                  ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: milestone.isCompleted ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: milestone.isCompleted
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: captionColor.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: ProjectDetailCard(
                padding: EdgeInsets.zero,
                borderColor: color.withValues(alpha: 0.25),
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                milestone.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: captionColor,
                              size: 20,
                            ),
                          ],
                        ),
                        if (milestone.targetDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy')
                                .format(milestone.targetDate!),
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (isExpanded) ...[
                          const SizedBox(height: 10),
                          Text(
                            milestone.description?.isNotEmpty == true
                                ? milestone.description!
                                : milestone.isCompleted
                                    ? 'This milestone has been reached.'
                                    : 'This milestone is still in progress.',
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              milestone.isCompleted ? 'Completed' : 'Upcoming',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
