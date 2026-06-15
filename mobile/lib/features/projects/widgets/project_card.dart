import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';

/// Model chứa dữ liệu đã được xử lý cho một ProjectCard.
class ProjectCardModel {
  final dynamic raw;
  final String name;
  final String status;
  final String subtitle;
  final String nextAction;
  final int progress;
  final int completedTasks;
  final int totalTasks;
  final int memberCount;
  final String role;
  final String type;
  final String dueText;
  final String attentionReason;
  final Color accentColor;
  final bool needsAttention;

  const ProjectCardModel({
    required this.raw,
    required this.name,
    required this.status,
    required this.subtitle,
    required this.nextAction,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.memberCount,
    required this.role,
    required this.type,
    required this.dueText,
    required this.attentionReason,
    required this.accentColor,
    required this.needsAttention,
  });
}

/// Card hiển thị thông tin tóm tắt của một project.
class ProjectCard extends StatelessWidget {
  final ProjectCardModel project;
  final bool compact;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final bgColor = isDark
        ? const Color(0xFF101827).withOpacity(0.86)
        : Colors.white.withOpacity(0.92);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: project.accentColor.withOpacity(0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: project.accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, compact ? 12 : 15, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: compact ? 15 : 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ProjectStatusPill(
                          label: project.status,
                          color: project.accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      project.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: project.needsAttention
                            ? project.accentColor
                            : subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Next: ${project.nextAction}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: project.progress / 100,
                              minHeight: 7,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                project.accentColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${project.progress}%',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _MetaItem(
                            icon: Icons.check_circle_outline_rounded,
                            label:
                                '${project.completedTasks}/${project.totalTasks} tasks',
                            color: captionColor,
                          ),
                          _MetaItem(
                            icon: Icons.people_outline_rounded,
                            label: '${project.memberCount} members',
                            color: captionColor,
                          ),
                          _MetaItem(
                            icon: Icons.verified_user_outlined,
                            label: project.role,
                            color: captionColor,
                          ),
                          if (project.dueText.isNotEmpty)
                            _MetaItem(
                              icon: Icons.event_rounded,
                              label: project.dueText,
                              color: project.accentColor,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge nhỏ hiển thị trạng thái project.
class ProjectStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const ProjectStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Row icon + label nhỏ cho metadata của card.
class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
