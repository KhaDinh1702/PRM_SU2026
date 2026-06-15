import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_widgets.dart';

/// Widget empty state khi không có task nào trong danh sách.
class TaskEmptyState extends StatelessWidget {
  final Color textColor;
  final Color captionColor;
  final VoidCallback onAddTask;

  const TaskEmptyState({
    super.key,
    required this.textColor,
    required this.captionColor,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 58,
            color: captionColor.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          Text(
            'No tasks for now',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Personal tasks, scheduled tasks, and project tasks assigned to you will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: captionColor, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 42,
            child: PremiumButton.icon(
              onPressed: onAddTask,
              icon: Icons.add_rounded,
              label: 'New personal task',
              backgroundColor: AppColors.taskAccent,
            ),
          ),
        ],
      ),
    );
  }
}
