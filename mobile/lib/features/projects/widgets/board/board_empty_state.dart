import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';

/// Empty-state shown inside a Kanban column when no tasks match the current
/// filter and inside the board itself when no tasks exist at all.
class BoardEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final EdgeInsetsGeometry padding;

  const BoardEmptyState({
    super.key,
    this.title = 'No tasks in this column',
    this.subtitle = 'Create your first task',
    this.emoji = '📋',
    this.ctaLabel,
    this.onCta,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSizes.paddingL,
      vertical: AppSizes.paddingL,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: AppSizes.paddingS),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: AppSizes.fontM,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontSize: AppSizes.fontS + 1,
                height: 1.3,
              ),
            ),
          ],
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: AppSizes.paddingM),
            ElevatedButton.icon(
              onPressed: onCta,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                ctaLabel!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingS + 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
