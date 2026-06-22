import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

/// Row identical in layout to PriorityPickerTile / RecurrencePickerTile but
/// for picking a task due date + optional time. Tap → date picker, then
/// time picker. Returns `null` if either step is cancelled (keeps existing).
class DueDatePickerTile extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const DueDatePickerTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String _label() {
    final v = value;
    if (v == null) return LocaleService.tr('Không', en: 'None');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(v.year, v.month, v.day);
    final diff = due.difference(today).inDays;

    final time =
        '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';

    if (diff == 0) {
      return LocaleService.tr('Hôm nay · $time', en: 'Today · $time');
    }
    if (diff == 1) {
      return LocaleService.tr('Ngày mai · $time', en: 'Tomorrow · $time');
    }
    if (diff == -1) {
      return LocaleService.tr('Hôm qua · $time', en: 'Yesterday · $time');
    }
    final dateText = DateFormat('MMM d').format(v);
    return '$dateText · $time';
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = value ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: LocaleService.tr('Hạn task', en: 'Task due date'),
    );
    if (pickedDate == null) return;
    if (!context.mounted) return;

    final initialTime = TimeOfDay.fromDateTime(value ?? now);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: LocaleService.tr('Giờ hạn', en: 'Due time'),
    );
    if (pickedTime == null) return;

    onChanged(DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final subTextColor = ThemeService.getSubTextColor(isDark);
    const accent = Color(0xFF06B6D4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _pick(context),
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
              Icon(Icons.event_rounded, color: subTextColor, size: 18),
              const SizedBox(width: 10),
              Text(
                LocaleService.tr('Hạn', en: 'Due'),
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 130,
                child: Text(
                  _label(),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: value == null ? subTextColor : accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (value != null)
                IconButton(
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                  icon: Icon(Icons.close_rounded,
                      color: subTextColor, size: 18),
                  onPressed: () => onChanged(null),
                )
              else
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: subTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
