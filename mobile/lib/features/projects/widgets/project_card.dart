import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/project_model.dart';

/// Card hiển thị thông tin tóm tắt của một project.
class ProjectCard extends StatelessWidget {
  final ProjectModel project;
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
        ? AppColors.cardDark.withValues(alpha: 0.86)
        : AppColors.backgroundLight.withValues(alpha: 0.92);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: project.accentColor.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: AppSizes.radiusM + 2.0,
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
                  topLeft: Radius.circular(AppSizes.radiusM),
                  bottomLeft: Radius.circular(AppSizes.radiusM),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.paddingM - 2.0,
                  compact ? AppSizes.paddingS + 4.0 : AppSizes.paddingM - 1.0,
                  AppSizes.paddingM - 2.0,
                  AppSizes.paddingM - 2.0,
                ),
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
                              fontSize: compact ? AppSizes.fontM + 1.0 : AppSizes.fontL,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingS),
                        ProjectStatusPill(
                          label: project.stateLabel,
                          color: project.accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingS - 1.0),
                    Text(
                      project.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: project.needsAttention
                            ? project.accentColor
                            : subTextColor,
                        fontSize: AppSizes.fontS + 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingS - 3.0),
                    Text(
                      'Next: ${project.nextAction}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: captionColor,
                        fontSize: AppSizes.fontS,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingM - 4.0),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSizes.radiusS),
                            child: LinearProgressIndicator(
                              value: project.progress / 100,
                              minHeight: 7,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                project.accentColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingS + 2.0),
                        Text(
                          '${project.progress}%',
                          style: TextStyle(
                            color: textColor,
                            fontSize: AppSizes.fontS + 1.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: AppSizes.paddingM - 4.0),
                      Wrap(
                        spacing: AppSizes.paddingM - 4.0,
                        runSpacing: AppSizes.paddingS,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingS,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizes.radiusS + 2.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppSizes.fontXS + 1.0,
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
        Icon(icon, size: AppSizes.fontM, color: color),
        const SizedBox(width: AppSizes.paddingS - 3.0),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: AppSizes.fontS,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
