import 'package:flutter/material.dart';

import '../../../services/theme_service.dart';

/// Subtle uppercase label used between day-grouped notification clusters.
class NotificationDayHeader extends StatelessWidget {
  final String label;

  const NotificationDayHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Text(
        label,
        style: TextStyle(
          color: captionColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}
