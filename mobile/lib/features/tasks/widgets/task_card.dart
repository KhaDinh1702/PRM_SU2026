import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_widgets.dart';

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
  final Map<String, dynamic> task;
  final Color textColor;
  final Color subTextColor;
  final Color captionColor;
  final String source;
  final Color sourceColor;
  final String projectName;
  final String assigneeName;
  final String dueText;
  final String reminderLabel;
  final Color priorityColor;
  final Color statusColor;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const TaskInboxCard({
    super.key,
    required this.task,
    required this.textColor,
    required this.subTextColor,
    required this.captionColor,
    required this.source,
    required this.sourceColor,
    required this.projectName,
    required this.assigneeName,
    required this.dueText,
    required this.reminderLabel,
    required this.priorityColor,
    required this.statusColor,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = task['title']?.toString() ?? 'Untitled task';
    final description = task['description']?.toString() ?? '';
    final status = task['status']?.toString() ?? 'Pending';
    final priority = task['priority']?.toString() ?? 'Medium';
    final completed = status == 'Completed';
    final metaParts = [
      dueText,
      if (projectName.isNotEmpty) projectName else source,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 22,
        padding: EdgeInsets.zero,
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
                              ? Icon(
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
                                TaskBadge(label: source, color: sourceColor),
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
                                    label: priority, color: priorityColor),
                                if (assigneeName.isNotEmpty &&
                                    source == 'Project')
                                  TaskBadge(
                                    label: 'Assigned to $assigneeName',
                                    color: captionColor,
                                  ),
                                if (reminderLabel.isNotEmpty)
                                  TaskBadge(
                                    label: reminderLabel,
                                    color: AppColors.timerFocus,
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
    );
  }
}
