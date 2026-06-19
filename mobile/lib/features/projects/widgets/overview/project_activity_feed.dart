import 'package:flutter/material.dart';

import '../../../../services/theme_service.dart';
import '../../models/project_activity.dart';
import '../../utils/project_activity_builder.dart';
import '../project_shared.dart';

class ProjectActivityFeed extends StatelessWidget {
  final List<ProjectActivity> activities;

  const ProjectActivityFeed({
    super.key,
    required this.activities,
  });

  IconData _iconFor(ProjectActivityType type) {
    switch (type) {
      case ProjectActivityType.taskCompleted:
        return Icons.check_circle_rounded;
      case ProjectActivityType.taskCreated:
        return Icons.add_task_rounded;
      case ProjectActivityType.memberJoined:
        return Icons.person_add_rounded;
      case ProjectActivityType.milestoneAdded:
        return Icons.flag_rounded;
      case ProjectActivityType.projectUpdated:
        return Icons.update_rounded;
    }
  }

  Color _colorFor(ProjectActivityType type) {
    switch (type) {
      case ProjectActivityType.taskCompleted:
        return const Color(0xFF10B981);
      case ProjectActivityType.taskCreated:
        return const Color(0xFF06B6D4);
      case ProjectActivityType.memberJoined:
        return const Color(0xFF8B5CF6);
      case ProjectActivityType.milestoneAdded:
        return const Color(0xFFF59E0B);
      case ProjectActivityType.projectUpdated:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          ProjectDetailCard(
            child: Text(
              'No recent activity yet.',
              style: TextStyle(color: captionColor, fontSize: 12),
            ),
          )
        else
          ProjectDetailCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                final color = _colorFor(activity.type);
                final isLast = index == activities.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_iconFor(activity.type),
                                size: 15, color: color),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: captionColor.withValues(alpha: 0.2),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.message,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ProjectActivityBuilder.relativeTime(
                                    activity.timestamp),
                                style: TextStyle(
                                  color: captionColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
