import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../models/checklist_item.dart';
import '../models/task_model.dart';
import '../models/task_tag.dart';

/// Badge màu hiển thị nhãn nhỏ gọn (status, priority, source, reminder).
class TaskBadge extends StatelessWidget {
  final String label;
  final Color color;

  const TaskBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
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

/// Card hiển thị thông tin task trong danh sách Unified Inbox.
class TaskInboxCard extends StatelessWidget {
  final TaskModel task;
  final Color textColor;
  final Color subTextColor;
  final Color captionColor;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onOpen;

  /// When `true`, shows a small "Repeat" badge so the user knows this task
  /// auto-creates the next instance on completion.
  final bool isRecurring;

  /// Checklist progress for this task. When non-empty, a small "3/5" badge
  /// renders alongside the other meta badges.
  final ChecklistProgress checklistProgress;

  /// Tags currently attached to this task. Rendered as a colored chip row.
  final List<TaskTag> tags;

  /// Minutes the user has spent focusing on this task today. When > 0
  /// a small badge renders so the user can see at-a-glance which tasks
  /// have already had time invested today.
  final int focusMinutesToday;

  const TaskInboxCard({
    super.key,
    required this.task,
    required this.textColor,
    required this.subTextColor,
    required this.captionColor,
    required this.onToggle,
    required this.onDelete,
    this.onOpen,
    this.isRecurring = false,
    this.checklistProgress = ChecklistProgress.empty,
    this.tags = const [],
    this.focusMinutesToday = 0,
  });

  @override
  Widget build(BuildContext context) {
    final title = task.title.isEmpty ? 'Untitled task' : task.title;
    final description = task.description;
    final status = task.statusLabel;
    final priority = task.priorityLabel;
    final completed = task.status == TaskStatus.completed;

    final dueTextStr = task.dueText;
    final projectNameStr = task.projectName;
    final sourceLabelStr = task.sourceLabel;
    final sourceColorStr = task.sourceColor;
    final assigneeNameStr = task.assigneeName;
    final reminderLabelStr = task.reminderLabel;
    final priorityColorStr = task.priorityColor;

    final statusColor = task.isOverdue
        ? AppColors.error
        : (task.status == TaskStatus.completed
            ? AppColors.success
            : (task.status == TaskStatus.inProgress
                ? AppColors.taskAccent
                : const Color(0xFF94A3B8)));

    final metaParts = [
      dueTextStr,
      if (projectNameStr.isNotEmpty) projectNameStr else sourceLabelStr,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 22,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(22),
          child: IntrinsicHeight(
          child: Row(
            children: [
              // Thanh màu trạng thái bên trái
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(22),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle complete button
                      GestureDetector(
                        onTap: onToggle,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: completed
                                ? AppColors.success.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border.all(
                              color: completed
                                  ? AppColors.success
                                  : captionColor.withValues(alpha: 0.45),
                              width: 2,
                            ),
                          ),
                          child: completed
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.success,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      decoration: completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TaskBadge(
                                  label: sourceLabelStr,
                                  color: sourceColorStr,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              metaParts.join(' · '),
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: captionColor, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                TaskBadge(label: status, color: statusColor),
                                TaskBadge(
                                  label: priority,
                                  color: priorityColorStr,
                                ),
                                if (assigneeNameStr.isNotEmpty &&
                                    sourceLabelStr == 'Project')
                                  TaskBadge(
                                    label: LocaleService.tr(
                                        'Giao cho $assigneeNameStr',
                                        en: 'Assigned to $assigneeNameStr'),
                                    color: captionColor,
                                  ),
                                if (reminderLabelStr.isNotEmpty)
                                  TaskBadge(
                                    label: reminderLabelStr,
                                    color: AppColors.timerFocus,
                                  ),
                                if (isRecurring)
                                  TaskBadge(
                                    label:
                                        LocaleService.tr('Lặp', en: 'Repeat'),
                                    color: const Color(0xFF06B6D4),
                                  ),
                                if (checklistProgress.hasItems)
                                  TaskBadge(
                                    label: '◰ ${checklistProgress.label}',
                                    color: checklistProgress.isComplete
                                        ? AppColors.success
                                        : AppColors.taskAccent,
                                  ),
                                if (focusMinutesToday > 0)
                                  TaskBadge(
                                    label: '◉ ${focusMinutesToday}m',
                                    color: const Color(0xFF06B6D4),
                                  ),
                                for (final tag in tags)
                                  TaskBadge(
                                    label: '#${tag.name}',
                                    color: tag.color,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Delete task',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent.withValues(alpha: 0.85),
                            size: 21,
                          ),
                          onPressed: onDelete,
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
  }
}

