import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/recurrence_rule.dart';

/// Compact "Repeat" row used inside the Create Task dialog. Shows the
/// current rule (or "Never") and opens [RecurrencePickerSheet] on tap.
class RecurrencePickerTile extends StatelessWidget {
  final RecurrenceRule? rule;
  final ValueChanged<RecurrenceRule?> onChanged;

  const RecurrencePickerTile({
    super.key,
    required this.rule,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final label = rule == null
        ? LocaleService.tr('Không', en: 'Never')
        : rule!.describe();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final next = await RecurrencePickerSheet.show(context, initial: rule);
          if (next != _SentinelUnchanged.value) {
            onChanged(next as RecurrenceRule?);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Icon(Icons.repeat_rounded, color: subTextColor, size: 18),
              const SizedBox(width: 10),
              Text(
                LocaleService.tr('Lặp lại', en: 'Repeat'),
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: rule == null ? captionColor : textColor,
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
    );
  }
}

/// Bottom sheet that lets the user pick a [RecurrenceRule].
/// Returns the picked rule, `null` to clear, or [_SentinelUnchanged.value]
/// if the sheet was dismissed.
class RecurrencePickerSheet extends StatefulWidget {
  final RecurrenceRule? initial;

  const RecurrencePickerSheet({super.key, required this.initial});

  static Future<Object?> show(
    BuildContext context, {
    RecurrenceRule? initial,
  }) {
    return showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecurrencePickerSheet(initial: initial),
    );
  }

  @override
  State<RecurrencePickerSheet> createState() => _RecurrencePickerSheetState();
}

class _RecurrencePickerSheetState extends State<RecurrencePickerSheet> {
  late RecurrencePattern? _pattern;
  late int _interval;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();
    _pattern = widget.initial?.pattern;
    _interval = widget.initial?.interval ?? 1;
    _weekdays = {...(widget.initial?.weekdays ?? const <int>{})};
  }

  RecurrenceRule? _buildRule() {
    if (_pattern == null) return null;
    return RecurrenceRule(
      pattern: _pattern!,
      interval: _interval,
      weekdays: _pattern == RecurrencePattern.weekly
          ? Set<int>.from(_weekdays)
          : const <int>{},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: dialogBg.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(color: borderColor),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: captionColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    LocaleService.tr('Lặp lại', en: 'Repeat'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _PatternChips(
                    selected: _pattern,
                    onChanged: (next) => setState(() {
                      _pattern = next;
                      if (next != RecurrencePattern.weekly) {
                        _weekdays.clear();
                      }
                    }),
                  ),
                  if (_pattern != null) ...[
                    const SizedBox(height: 18),
                    _IntervalRow(
                      pattern: _pattern!,
                      interval: _interval,
                      onChanged: (value) => setState(() => _interval = value),
                    ),
                  ],
                  if (_pattern == RecurrencePattern.weekly) ...[
                    const SizedBox(height: 16),
                    Text(
                      LocaleService.tr('VÀO', en: 'ON'),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _WeekdayChips(
                      selected: _weekdays,
                      onToggle: (day) => setState(() {
                        if (_weekdays.contains(day)) {
                          _weekdays.remove(day);
                        } else {
                          _weekdays.add(day);
                        }
                      }),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        child: Text(
                          LocaleService.tr('Không lặp', en: "Don't repeat"),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_SentinelUnchanged.value),
                        child: Text(
                          LocaleService.tr('Huỷ', en: 'Cancel'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        onPressed: _pattern == null
                            ? null
                            : () => Navigator.of(context).pop(_buildRule()),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          LocaleService.tr('Lưu', en: 'Save'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternChips extends StatelessWidget {
  final RecurrencePattern? selected;
  final ValueChanged<RecurrencePattern> onChanged;

  const _PatternChips({required this.selected, required this.onChanged});

  String _labelFor(RecurrencePattern pattern) {
    switch (pattern) {
      case RecurrencePattern.daily:
        return LocaleService.tr('Hàng ngày', en: 'Daily');
      case RecurrencePattern.weekly:
        return LocaleService.tr('Hàng tuần', en: 'Weekly');
      case RecurrencePattern.monthly:
        return LocaleService.tr('Hàng tháng', en: 'Monthly');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final pattern in RecurrencePattern.values)
          _Chip(
            label: _labelFor(pattern),
            selected: selected == pattern,
            onTap: () => onChanged(pattern),
          ),
      ],
    );
  }
}

class _IntervalRow extends StatelessWidget {
  final RecurrencePattern pattern;
  final int interval;
  final ValueChanged<int> onChanged;

  const _IntervalRow({
    required this.pattern,
    required this.interval,
    required this.onChanged,
  });

  String _unit() {
    switch (pattern) {
      case RecurrencePattern.daily:
        return LocaleService.tr('ngày', en: interval == 1 ? 'day' : 'days');
      case RecurrencePattern.weekly:
        return LocaleService.tr('tuần', en: interval == 1 ? 'week' : 'weeks');
      case RecurrencePattern.monthly:
        return LocaleService.tr('tháng',
            en: interval == 1 ? 'month' : 'months');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);

    return Row(
      children: [
        Text(
          LocaleService.tr('Mỗi', en: 'Every'),
          style: TextStyle(
            color: captionColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: interval > 1 ? () => onChanged(interval - 1) : null,
          icon: const Icon(Icons.remove_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: textColor.withValues(alpha: 0.06),
            padding: const EdgeInsets.all(4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            width: 24,
            child: Text(
              '$interval',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: interval < 30 ? () => onChanged(interval + 1) : null,
          icon: const Icon(Icons.add_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: textColor.withValues(alpha: 0.06),
            padding: const EdgeInsets.all(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _unit(),
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WeekdayChips extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _WeekdayChips({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: [
        for (var i = 1; i <= 7; i++) ...[
          _DayChip(
            label: labels[i - 1],
            selected: selected.contains(i),
            onTap: () => onToggle(i),
          ),
          if (i < 7) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    const accent = Color(0xFF06B6D4);
    final bg = selected
        ? accent.withValues(alpha: 0.16)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04));
    final border = selected
        ? accent
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08));
    final fg = selected ? accent : ThemeService.getTextColor(isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    const accent = Color(0xFF06B6D4);
    final bg = selected
        ? accent
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04));
    final fg = selected ? Colors.white : ThemeService.getTextColor(isDark);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sentinel used to distinguish "user dismissed the sheet" from "user
/// explicitly chose to remove recurrence" (which returns `null`).
class _SentinelUnchanged {
  static const Object value = _SentinelUnchanged._();
  const _SentinelUnchanged._();
}
