import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/premium_widgets.dart';
import '../../../../services/theme_service.dart';
import '../project_shared.dart';

class ProjectHeroCard extends StatelessWidget {
  final String name;
  final String statusLabel;
  final Color statusColor;
  final int progress;
  final int completedTasks;
  final int totalTasks;
  final DateTime? dueDate;
  final int memberCount;

  const ProjectHeroCard({
    super.key,
    required this.name,
    required this.statusLabel,
    required this.statusColor,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    this.dueDate,
    required this.memberCount,
  });

  String _progressBar() {
    const segments = 10;
    final filled = (progress / 100 * segments).round().clamp(0, segments);
    return '${'█' * filled}${'░' * (segments - filled)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              ProjectStatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$progress%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const Spacer(),
              Text(
                '$completedTasks / $totalTasks Tasks',
                style: TextStyle(
                  color: captionColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _progressBar(),
            style: TextStyle(
              color: statusColor.withValues(alpha: 0.9),
              fontSize: 12,
              letterSpacing: 0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.event_rounded, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text(
                dueDate != null
                    ? DateFormat('MMM d').format(dueDate!)
                    : 'No due date',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Icon(Icons.people_outline_rounded,
                  size: 16, color: captionColor),
              const SizedBox(width: 4),
              Text(
                '$memberCount Members',
                style: TextStyle(
                  color: captionColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
