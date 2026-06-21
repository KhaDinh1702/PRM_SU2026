import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/locale_service.dart';
import '../../../../services/theme_service.dart';
import '../../../tasks/models/task_model.dart';
import '../../utils/project_board_utils.dart';
import '../../utils/task_display.dart';
import 'board_palette.dart';

/// Card rendered for each task inside a Kanban column.
///
/// - Tap fires [onTap] (the parent typically pushes the Task Detail screen).
/// - Long press fires [onLongPress] (the parent typically shows the detail
///   bottom sheet). Falls back to [onTap] when not provided.
/// - Swipe right marks the task complete via [onSwipeComplete].
/// - Swipe left advances the task to the next column via [onSwipeAdvance].
class BoardTaskCard extends StatelessWidget {
  final TaskModel task;
  final BoardColumn column;
  final String assigneeName;
  final bool canSwipe;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeComplete;
  final VoidCallback? onSwipeAdvance;

  const BoardTaskCard({
    super.key,
    required this.task,
    required this.assigneeName,
    required this.canSwipe,
    required this.onTap,
    this.column = BoardColumn.todo,
    this.onLongPress,
    this.onSwipeComplete,
    this.onSwipeAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    final title = task.title.isEmpty ? 'Untitled' : task.title;
    final priority = task.priorityLabel;
    final priorityColor = BoardPalette.priorityColorFromString(priority);
    final statusColor = BoardPalette.statusColor(column);
    final dueText = taskDueText(task);
    final overdue = taskIsVisuallyOverdue(task);

    final card = Semantics(
      button: true,
      label: 'Task $title, priority $priority',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress ?? onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppSizes.radiusM - 2),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppSizes.radiusM - 2),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: AppSizes.fontM,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.paddingS),
                            _PriorityBadge(
                              label: priority,
                              color: priorityColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingS + 2),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: overdue
                                  ? BoardPalette.high
                                  : captionColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dueText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: overdue
                                      ? BoardPalette.high
                                      : captionColor,
                                  fontSize: AppSizes.fontS,
                                  fontWeight: overdue
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _AssigneeAvatar(
                              name: assigneeName,
                              color: statusColor,
                              textColor: subTextColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!canSwipe || onSwipeComplete == null || onSwipeAdvance == null) {
      return card;
    }

    return Dismissible(
      key: ValueKey(task.id.isEmpty ? title : task.id),
      direction: DismissDirection.horizontal,
      movementDuration: const Duration(milliseconds: 200),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onSwipeComplete!();
        } else {
          onSwipeAdvance!();
        }
        return false;
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: BoardPalette.statusColor(BoardColumn.completed),
        icon: Icons.check_rounded,
        label: LocaleService.tr('Hoàn tất', en: 'Complete'),
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: const Color(0xFF06B6D4),
        icon: Icons.arrow_forward_rounded,
        label: LocaleService.tr('Tiếp', en: 'Next'),
      ),
      child: card,
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppSizes.fontXS + 1,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _AssigneeAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final Color textColor;

  const _AssigneeAvatar({
    required this.name,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return Tooltip(
      message: name.isEmpty ? 'Unassigned' : name,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: initials.isEmpty
            ? Icon(Icons.person_outline_rounded, size: 14, color: textColor)
            : Text(
                initials,
                style: TextStyle(
                  color: color,
                  fontSize: AppSizes.fontS,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }

  static String _initials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isStart = alignment == Alignment.centerLeft;
    final children = <Widget>[
      Icon(icon, color: color),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    ];

    return Container(
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: isStart ? 20 : 0)
          .add(EdgeInsets.only(right: isStart ? 0 : 20)),
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSizes.radiusM - 2),
      ),
      child: Row(
        mainAxisAlignment:
            isStart ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: isStart ? children : children.reversed.toList(),
      ),
    );
  }
}
