import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';
import '../../models/project_milestone.dart';
import '../project_shared.dart';

/// Single row of the project timeline. Renders the vertical rail dot on the
/// left and a milestone card on the right.
///
/// Tap → toggle expand. Long press (user milestones only) → context menu
/// with Edit / Toggle complete / Delete.
class TimelineMilestoneCard extends StatelessWidget {
  final ProjectMilestone milestone;
  final bool isFirst;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;

  const TimelineMilestoneCard({
    super.key,
    required this.milestone,
    required this.isFirst,
    required this.isLast,
    required this.isExpanded,
    required this.onToggleExpand,
    this.onEdit,
    this.onDelete,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final status = milestone.status;
    final accent = status.color;
    final isSystem = !milestone.isEditable;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(
            accent: accent,
            isCompleted: milestone.isCompleted,
            isFirst: isFirst,
            isLast: isLast,
            faded: isSystem,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: _MilestoneBody(
                milestone: milestone,
                accent: accent,
                isExpanded: isExpanded,
                isSystem: isSystem,
                onToggleExpand: onToggleExpand,
                onEdit: onEdit,
                onDelete: onDelete,
                onToggleComplete: onToggleComplete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  final Color accent;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;
  final bool faded;

  const _Rail({
    required this.accent,
    required this.isCompleted,
    required this.isFirst,
    required this.isLast,
    required this.faded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.18);
    final dotColor = faded ? accent.withValues(alpha: 0.5) : accent;

    return SizedBox(
      width: 28,
      child: Column(
        children: [
          if (!isFirst)
            Container(width: 2, height: 14, color: lineColor),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isCompleted ? dotColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: dotColor, width: 2),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 8, color: Colors.white)
                : null,
          ),
          if (!isLast)
            Expanded(child: Container(width: 2, color: lineColor)),
        ],
      ),
    );
  }
}

class _MilestoneBody extends StatelessWidget {
  final ProjectMilestone milestone;
  final Color accent;
  final bool isExpanded;
  final bool isSystem;
  final VoidCallback onToggleExpand;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;

  const _MilestoneBody({
    required this.milestone,
    required this.accent,
    required this.isExpanded,
    required this.isSystem,
    required this.onToggleExpand,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  bool get _showExpandable =>
      milestone.description?.trim().isNotEmpty == true || !isSystem;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final status = milestone.status;

    return ProjectDetailCard(
      padding: EdgeInsets.zero,
      borderColor: accent.withValues(alpha: isSystem ? 0.18 : 0.32),
      child: InkWell(
        onTap: onToggleExpand,
        onLongPress: isSystem ? null : () => _showActions(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusM + 2),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      milestone.title,
                      style: TextStyle(
                        color: textColor.withValues(alpha: isSystem ? 0.75 : 1),
                        fontSize: AppSizes.fontM,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!isSystem)
                    IconButton(
                      tooltip: 'More',
                      splashRadius: 18,
                      onPressed: () => _showActions(context),
                      icon: Icon(Icons.more_vert_rounded,
                          size: 18, color: captionColor),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 2),
                      child: Icon(Icons.lock_outline_rounded,
                          size: 14, color: captionColor),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _MetaRow(
                milestone: milestone,
                status: status,
                accent: accent,
                captionColor: captionColor,
              ),
              if (isExpanded && _showExpandable) ...[
                if ((milestone.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    milestone.description!,
                    style: TextStyle(
                      color: captionColor,
                      fontSize: AppSizes.fontS + 1,
                      height: 1.4,
                    ),
                  ),
                ],
                if (!isSystem) ...[
                  const SizedBox(height: 10),
                  _ExpandedActions(
                    completed: milestone.isCompleted,
                    onToggle: onToggleComplete,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    accent: accent,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    if (isSystem) return;
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (box == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(box.size.topRight(Offset.zero), ancestor: overlay),
        box.localToGlobal(
            box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'toggle',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(milestone.isCompleted
                ? Icons.radio_button_unchecked_rounded
                : Icons.check_circle_outline_rounded),
            title: Text(milestone.isCompleted
                ? 'Mark as incomplete'
                : 'Mark as completed'),
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444)),
            title: Text('Delete',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ),
      ],
    );

    switch (choice) {
      case 'toggle':
        onToggleComplete?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}

class _MetaRow extends StatelessWidget {
  final ProjectMilestone milestone;
  final MilestoneStatus status;
  final Color accent;
  final Color captionColor;

  const _MetaRow({
    required this.milestone,
    required this.status,
    required this.accent,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    final date = milestone.targetDate;
    final dateText = date == null
        ? 'No target date'
        : DateFormat('MMM d, yyyy').format(date);
    final countdown = milestone.countdownLabel;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatusChip(label: status.label, color: accent),
        Text(
          dateText,
          style: TextStyle(
            color: captionColor,
            fontSize: AppSizes.fontS + 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (countdown.isNotEmpty)
          Text(
            '· $countdown',
            style: TextStyle(
              color: status == MilestoneStatus.overdue
                  ? const Color(0xFFEF4444)
                  : captionColor,
              fontSize: AppSizes.fontS + 1,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

class _ExpandedActions extends StatelessWidget {
  final bool completed;
  final Color accent;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ExpandedActions({
    required this.completed,
    required this.accent,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onToggle,
          icon: Icon(
            completed
                ? Icons.radio_button_unchecked_rounded
                : Icons.check_rounded,
            size: 16,
          ),
          label: Text(completed ? 'Reopen' : 'Mark done'),
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withValues(alpha: 0.45)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Edit',
          splashRadius: 18,
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: 'Delete',
          splashRadius: 18,
          icon: const Icon(Icons.delete_outline_rounded,
              size: 18, color: Color(0xFFEF4444)),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
