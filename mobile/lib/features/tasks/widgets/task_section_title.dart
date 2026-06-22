import 'package:flutter/material.dart';

import '../../../services/theme_service.dart';

/// Reusable section header used inside [TaskDetailSheet]'s body —
/// renders a bold uppercase label with an optional trailing counter
/// (e.g. `"3/5"` for partial-progress sections).
class TaskSectionTitle extends StatelessWidget {
  final String label;
  final String? counter;

  const TaskSectionTitle({super.key, required this.label, this.counter});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        if (counter != null) ...[
          const SizedBox(width: 6),
          Text(
            counter!,
            style: TextStyle(
              color: captionColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
