import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

/// Bottom sheet that lets the user pick a custom focus duration in
/// minutes. Surfaces a row of common presets (15/25/45/60/90) and a free
/// numeric input so the user can dial in any value from 1 to 180.
/// Returns the picked minute count, or `null` if the user dismisses.
class FocusDurationPickerSheet extends StatefulWidget {
  final int initialMinutes;

  const FocusDurationPickerSheet({
    super.key,
    required this.initialMinutes,
  });

  static Future<int?> show(
    BuildContext context, {
    required int initialMinutes,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FocusDurationPickerSheet(
        initialMinutes: initialMinutes,
      ),
    );
  }

  @override
  State<FocusDurationPickerSheet> createState() =>
      _FocusDurationPickerSheetState();
}

class _FocusDurationPickerSheetState extends State<FocusDurationPickerSheet> {
  static const List<int> _presets = [15, 25, 45, 60, 90];
  static const int _minMinutes = 1;
  static const int _maxMinutes = 180;
  static const Color _accent = Color(0xFF06B6D4);

  late int _selected;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMinutes.clamp(_minMinutes, _maxMinutes);
    _controller = TextEditingController(text: _selected.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyInput(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return;
    final clamped = parsed.clamp(_minMinutes, _maxMinutes);
    setState(() => _selected = clamped);
  }

  void _confirm() {
    final final_ = _selected.clamp(_minMinutes, _maxMinutes);
    Navigator.pop(context, final_);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final bg = ThemeService.getDialogBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          MediaQuery.of(context).padding.bottom + 22,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: captionColor.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleService.tr('Thời lượng focus', en: 'Focus duration'),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              LocaleService.tr(
                'Chọn nhanh hoặc nhập số phút (1 – 180).',
                en: 'Pick a preset or type any value (1 – 180 min).',
              ),
              style: TextStyle(
                color: captionColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _presets)
                  _PresetChip(
                    label: '${preset}m',
                    selected: preset == _selected,
                    onTap: () {
                      setState(() => _selected = preset);
                      _controller.text = preset.toString();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onChanged: _applyInput,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      hintText:
                          LocaleService.tr('Phút', en: 'Minutes'),
                      hintStyle: TextStyle(color: captionColor),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '= ${_selected}m',
                  style: TextStyle(
                    color: captionColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      LocaleService.tr('Huỷ', en: 'Cancel'),
                      style: TextStyle(
                        color: captionColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      LocaleService.tr('Áp dụng', en: 'Apply'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    const accent = Color(0xFF06B6D4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? accent
                : accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? accent
                  : accent.withValues(alpha: 0.32),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : textColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
