import 'package:flutter/material.dart';
import '../../../../services/locale_service.dart';
import '../../../../services/theme_service.dart';

/// Bottom sheet lọc project theo status, loại dự án và sắp xếp.
/// Vai trò (Owner/Manager/Member) đã được phủ bởi quick chips
/// Mine/Shared ở header màn Projects nên không xuất hiện ở đây nữa.
class ProjectFilterBottomSheet extends StatelessWidget {
  final String typeFilter;
  final String statusFilter;
  final String sortBy;
  final List<String> typeOptions;
  final List<String> statusOptions;
  final List<String> sortOptions;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onClear;

  const ProjectFilterBottomSheet({
    super.key,
    required this.typeFilter,
    required this.statusFilter,
    required this.sortBy,
    required this.typeOptions,
    required this.statusOptions,
    required this.sortOptions,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: captionColor.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocaleService.tr('Bộ lọc dự án', en: 'Project filters'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: Text(LocaleService.tr('Xoá', en: 'Clear')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FilterGroup(
              title: LocaleService.tr('Trạng thái', en: 'Status'),
              options: statusOptions,
              selected: statusFilter,
              onChanged: onStatusChanged,
            ),
            const SizedBox(height: 16),
            _FilterGroup(
              title: LocaleService.tr('Loại dự án', en: 'Project type'),
              options: typeOptions,
              selected: typeFilter,
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 16),
            _FilterGroup(
              title: LocaleService.tr('Sắp xếp', en: 'Sort by'),
              options: sortOptions,
              selected: sortBy,
              onChanged: onSortChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final active = option == selected;
            return ChoiceChip(
              selected: active,
              label: Text(
                option,
                style: TextStyle(
                  color: active ? Colors.white : captionColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              selectedColor: const Color(0xFF06B6D4),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              side: BorderSide(
                color: active
                    ? const Color(0xFF06B6D4)
                    : captionColor.withValues(alpha: 0.14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (_) => onChanged(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}
