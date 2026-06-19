import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/premium_widgets.dart';
import '../../../../services/theme_service.dart';
import '../../utils/task_display.dart';

class ProjectNextTaskCard extends StatelessWidget {
  final dynamic task;
  final String assigneeName;
  final VoidCallback? onOpenTask;
  final VoidCallback? onMarkInProgress;
  final VoidCallback? onCreateTask;

  const ProjectNextTaskCard({
    super.key,
    required this.task,
    required this.assigneeName,
    this.onOpenTask,
    this.onMarkInProgress,
    this.onCreateTask,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final primary = ThemeService.getPrimaryColor(isDark);

    if (task == null) {
      return GlassCard(
        borderRadius: 22,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Task',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All caught up — no open tasks right now.',
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
            if (onCreateTask != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onCreateTask,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Task'),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final title = task['title']?.toString() ?? 'Untitled task';
    final priority = task['priority']?.toString() ?? 'Medium';
    final status = task['status']?.toString() ?? 'Pending';
    final priorityColor = taskPriorityColor(priority);
    final dueText = taskDueText(task);

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'NEXT TASK',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.bolt_rounded, color: primary, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: priority,
                color: priorityColor,
              ),
              _Chip(
                label: dueText,
                color: taskIsVisuallyOverdue(task)
                    ? AppColors.priorityUrgent
                    : subTextColor,
              ),
              _Chip(
                label: assigneeName,
                color: primary,
                icon: Icons.person_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenTask,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Open Task',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              if (status != 'In Progress' && onMarkInProgress != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onMarkInProgress,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Start',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
