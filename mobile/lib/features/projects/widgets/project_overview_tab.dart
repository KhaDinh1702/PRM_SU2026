import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import 'project_shared.dart';

/// Tab tổng quan: mô tả, card next action, tiến độ, grid thông tin.
class OverviewTab extends StatelessWidget {
  final String description;
  final String actionTitle;
  final String actionText;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;
  final int progress;
  final int completedTasks;
  final int totalTasks;
  final int memberCount;
  final String role;
  final String workStatus;
  final Color workStatusColor;

  const OverviewTab({
    super.key,
    required this.description,
    required this.actionTitle,
    required this.actionText,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.memberCount,
    required this.role,
    required this.workStatus,
    required this.workStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        ProjectDetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                description.isEmpty ? 'No detailed description.' : description,
                style:
                    TextStyle(color: subTextColor, fontSize: 13, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NextActionCard(
          title: actionTitle,
          text: actionText,
          ctaLabel: actionLabel,
          color: actionColor,
          onPressed: onAction,
        ),
        const SizedBox(height: 12),
        ProgressSummaryCard(
          progress: progress,
          completedTasks: completedTasks,
          totalTasks: totalTasks,
          color: workStatusColor,
        ),
        const SizedBox(height: 12),
        ProjectInfoGrid(
          completedTasks: completedTasks,
          totalTasks: totalTasks,
          memberCount: memberCount,
          role: role,
          workStatus: workStatus,
          workStatusColor: workStatusColor,
        ),
        const SizedBox(height: 12),
        RecentActivityCard(
          text: totalTasks == 0
              ? 'Project created. No tasks have been added yet.'
              : 'Progress is based on the latest task updates.',
        ),
      ],
    );
  }
}

/// Card gợi ý hành động tiếp theo.
class NextActionCard extends StatelessWidget {
  final String title;
  final String text;
  final String ctaLabel;
  final Color color;
  final VoidCallback onPressed;

  const NextActionCard({
    super.key,
    required this.title,
    required this.text,
    required this.ctaLabel,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return ProjectDetailCard(
      borderColor: color.withValues(alpha: 0.32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.bolt_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(text,
                    style: TextStyle(
                        color: subTextColor, fontSize: 12, height: 1.3)),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(ctaLabel,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card tiến độ tổng thể: progress bar + số task.
class ProgressSummaryCard extends StatelessWidget {
  final int progress;
  final int completedTasks;
  final int totalTasks;
  final Color color;

  const ProgressSummaryCard({
    super.key,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return ProjectDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress summary',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900)),
              Text('$progress%',
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalTasks == 0
                ? 'No tasks yet'
                : '$completedTasks of $totalTasks tasks completed',
            style: TextStyle(color: captionColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Grid 2 cột: tasks, members, role, status.
class ProjectInfoGrid extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;
  final int memberCount;
  final String role;
  final String workStatus;
  final Color workStatusColor;

  const ProjectInfoGrid({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
    required this.memberCount,
    required this.role,
    required this.workStatus,
    required this.workStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.45,
      children: [
        _InfoTile(label: 'Tasks', value: '$completedTasks/$totalTasks'),
        _InfoTile(label: 'Members', value: '$memberCount'),
        _InfoTile(label: 'Role', value: role),
        _InfoTile(
            label: 'Project Status', value: workStatus, color: workStatusColor),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoTile({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return ProjectDetailCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: captionColor, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color ?? textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// Card ghi chú hoạt động gần đây.
class RecentActivityCard extends StatelessWidget {
  final String text;

  const RecentActivityCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    return ProjectDetailCard(
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: captionColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child:
                Text(text, style: TextStyle(color: captionColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
