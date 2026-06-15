import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_widgets.dart';

/// Pill hiển thị tóm tắt số liệu nhanh (tổng task, project, overdue).
class TaskSummaryPill extends StatelessWidget {
  final String label;
  final Color color;

  const TaskSummaryPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Thanh tóm tắt hiển thị 3 pill: tổng task, project task, overdue.
class TaskSummaryBar extends StatelessWidget {
  final int totalCount;
  final int projectCount;
  final int overdueCount;
  final VoidCallback onAddTask;

  static const Color _accent = AppColors.taskAccent;

  const TaskSummaryBar({
    super.key,
    required this.totalCount,
    required this.projectCount,
    required this.overdueCount,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TaskSummaryPill(label: '$totalCount Tasks', color: _accent),
        const SizedBox(width: 8),
        TaskSummaryPill(
          label: '$projectCount Project',
          color: AppColors.timerFocus,
        ),
        const SizedBox(width: 8),
        TaskSummaryPill(
          label: '$overdueCount Overdue',
          color: AppColors.error,
        ),
        const Spacer(),
        SizedBox(
          height: 36,
          child: PremiumButton.icon(
            onPressed: onAddTask,
            icon: Icons.add_rounded,
            label: 'New',
            backgroundColor: _accent,
          ),
        ),
      ],
    );
  }
}
