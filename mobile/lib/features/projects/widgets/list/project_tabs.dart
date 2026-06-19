import 'package:flutter/material.dart';
import '../../../../services/theme_service.dart';

/// Tab bar lọc danh sách project (All / Owned / Member / Invited...).
class ProjectTabs extends StatelessWidget {
  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onChanged;

  const ProjectTabs({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab == selectedTab;
          return ChoiceChip(
            selected: selected,
            label: Text(
              tab,
              style: TextStyle(
                color: selected ? Colors.white : captionColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            selectedColor: const Color(0xFF06B6D4),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF06B6D4)
                  : captionColor.withValues(alpha: 0.16),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: (_) => onChanged(tab),
          );
        },
      ),
    );
  }
}
