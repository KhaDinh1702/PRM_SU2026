import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/locale_service.dart';
import '../../../../services/theme_service.dart';
import '../project_shared.dart';

/// Accordion column shown on the mobile Kanban board.
class BoardSection extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final Widget? emptyState;

  const BoardSection({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final body = children.isEmpty
        ? (emptyState ??
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Text(
                LocaleService.tr('Cột này chưa có task.',
                    en: 'No tasks in this column.'),
                style: TextStyle(
                  color: captionColor,
                  fontSize: AppSizes.fontS + 1,
                ),
              ),
            ))
        : Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(children: children),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ProjectDetailCard(
        padding: EdgeInsets.zero,
        borderColor: color.withValues(alpha: 0.25),
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingM - 2,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: AppSizes.fontM,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: color,
                          fontSize: AppSizes.fontS + 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: captionColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Column(
                      children: [
                        Divider(height: 1, color: dividerColor),
                        body,
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
