import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';
import '../../providers/project_create_provider.dart';
import 'section_header.dart';

/// Optional deadline picker. Clearing falls back to "no deadline".
class CreateProjectScheduleSection extends StatelessWidget {
  const CreateProjectScheduleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectCreateProvider>();
    final deadline = provider.draft.deadline;
    final error = provider.validation.deadlineError;
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreateProjectSectionHeader(
          icon: Icons.event_rounded,
          title: 'Schedule',
          subtitle: 'Optional deadline to keep things on track.',
        ),
        InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          onTap: () => _pickDate(context, provider, deadline),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM - 4,
              vertical: AppSizes.paddingS + 6,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(
                color: error != null
                    ? const Color(0xFFEF4444)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: captionColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    deadline == null
                        ? 'No deadline'
                        : _formatDate(deadline),
                    style: TextStyle(
                      color: deadline == null ? captionColor : textColor,
                      fontSize: AppSizes.fontM,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (deadline != null)
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: captionColor),
                    splashRadius: 18,
                    onPressed: () => provider.setDeadline(null),
                  ),
                Icon(Icons.edit_calendar_rounded,
                    size: 18, color: captionColor),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: AppSizes.fontS + 1,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    ProjectCreateProvider provider,
    DateTime? current,
  ) async {
    final now = DateTime.now();
    final initial = current ?? now.add(const Duration(days: 7));
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      helpText: 'Project deadline',
    );
    if (picked != null) {
      provider.setDeadline(picked);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
