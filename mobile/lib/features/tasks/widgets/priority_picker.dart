import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

/// Row identical in layout to [RecurrencePickerTile] but for picking a task
/// priority. Opens a popup menu anchored to the row when tapped.
class PriorityPickerTile extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  static const List<String> options = ['Low', 'Medium', 'High', 'Urgent'];

  const PriorityPickerTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String _localizedValue(String key) {
    switch (key) {
      case 'Urgent':
        return LocaleService.tr('Khẩn', en: 'Urgent');
      case 'High':
        return LocaleService.tr('Cao', en: 'High');
      case 'Medium':
        return LocaleService.tr('Vừa', en: 'Medium');
      case 'Low':
        return LocaleService.tr('Thấp', en: 'Low');
      default:
        return key;
    }
  }

  Color _colorFor(String priority) {
    switch (priority) {
      case 'Urgent':
        return AppColors.priorityUrgent;
      case 'High':
        return AppColors.priorityHigh;
      case 'Medium':
        return AppColors.priorityMedium;
      case 'Low':
        return AppColors.priorityLow;
      default:
        return AppColors.priorityMedium;
    }
  }

  Future<void> _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (box == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final picked = await showMenu<String>(
      context: context,
      position: position,
      items: [
        for (final option in options)
          PopupMenuItem<String>(
            value: option,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _colorFor(option),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _localizedValue(option),
                  style: TextStyle(
                    fontWeight: option == value
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (picked != null && picked != value) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final accent = _colorFor(value);

    return Builder(
      builder: (rowContext) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openMenu(rowContext),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, color: subTextColor, size: 18),
                const SizedBox(width: 10),
                Text(
                  LocaleService.tr('Ưu tiên', en: 'Priority'),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 90,
                  child: Text(
                    _localizedValue(value),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
