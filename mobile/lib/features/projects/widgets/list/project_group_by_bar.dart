import 'package:flutter/material.dart';

import '../../../../services/locale_service.dart';
import '../../../../services/theme_service.dart';

/// Compact pill above the project list that lets the user switch how the
/// list is grouped — `Type`, `Status`, or flat (`None`). Tap opens a
/// popup menu so the bar stays a single row even at narrow widths.
class ProjectGroupByBar extends StatelessWidget {
  static const List<String> options = ['Type', 'Status', 'None'];

  final String groupBy;
  final int totalVisible;
  final int totalProjects;
  final ValueChanged<String> onChanged;

  const ProjectGroupByBar({
    super.key,
    required this.groupBy,
    required this.totalVisible,
    required this.totalProjects,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return Row(
      children: [
        Text(
          '$totalVisible/$totalProjects',
          style: TextStyle(
            color: captionColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          LocaleService.tr('Nhóm theo', en: 'Group by'),
          style: TextStyle(
            color: captionColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: PopupMenuButton<String>(
            tooltip: LocaleService.tr('Đổi cách nhóm', en: 'Change grouping'),
            initialValue: groupBy,
            onSelected: onChanged,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            itemBuilder: (context) => [
              for (final option in options)
                PopupMenuItem(
                  value: option,
                  child: Text(_labelFor(option)),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: captionColor.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _labelFor(groupBy),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: captionColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _labelFor(String value) {
    switch (value) {
      case 'Type':
        return LocaleService.tr('Loại', en: 'Type');
      case 'Status':
        return LocaleService.tr('Trạng thái', en: 'Status');
      case 'None':
        return LocaleService.tr('Không nhóm', en: 'None');
    }
    return value;
  }
}
