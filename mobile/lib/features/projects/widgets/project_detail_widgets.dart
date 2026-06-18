import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';

/// Header panel hiển thị trên detail sheet của project.
class ProjectDetailHeader extends StatelessWidget {
  final String name;
  final String description;
  final String role;
  final String workStatus;
  final int memberCount;
  final int progress;
  final int completedTasks;
  final int totalTasks;
  final Color statusColor;
  final bool canShowMenu;
  final bool canLeave;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLeave;

  const ProjectDetailHeader({
    super.key,
    required this.name,
    required this.description,
    required this.role,
    required this.workStatus,
    required this.memberCount,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.statusColor,
    required this.canShowMenu,
    required this.canLeave,
    required this.onEdit,
    required this.onDelete,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    final progressText = totalTasks == 0
        ? 'No tasks yet'
        : '$progress% complete · $completedTasks of $totalTasks tasks done';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: captionColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '$role · $workStatus · $memberCount members',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: captionColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (canShowMenu || canLeave)
              ProjectActionMenu(
                canShowMenu: canShowMenu,
                canLeave: canLeave,
                onEdit: onEdit,
                onDelete: onDelete,
                onLeave: onLeave,
              ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 7,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progressText,
          style: TextStyle(
            color: totalTasks == 0 ? captionColor : statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Popup menu edit/delete/leave trên header project.
class ProjectActionMenu extends StatelessWidget {
  final bool canShowMenu;
  final bool canLeave;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLeave;

  const ProjectActionMenu({
    super.key,
    required this.canShowMenu,
    required this.canLeave,
    required this.onEdit,
    required this.onDelete,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
        if (value == 'leave') onLeave();
      },
      itemBuilder: (context) => [
        if (canShowMenu) ...[
          const PopupMenuItem(value: 'edit', child: Text('Edit project')),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete project', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
        if (canShowMenu && canLeave)
          const PopupMenuDivider(),
        if (canLeave)
          const PopupMenuItem(
            value: 'leave',
            child: Text('Leave project', style: TextStyle(color: Colors.orangeAccent)),
          ),
      ],
    );
  }
}
