import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/task_tag.dart';

/// Modal for entering a new tag — name field + colour swatches from the
/// fixed palette. Returns a partial [TaskTag] with an empty id; the caller
/// is responsible for persisting it through [TagService.createTag].
class CreateTagDialog extends StatefulWidget {
  const CreateTagDialog({super.key});

  static Future<TaskTag?> show(BuildContext context) {
    return showDialog<TaskTag>(
      context: context,
      builder: (_) => const CreateTagDialog(),
    );
  }

  @override
  State<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<CreateTagDialog> {
  final TextEditingController _controller = TextEditingController();
  int _selectedColor = TaskTag.paletteColors.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    return AlertDialog(
      title: Text(LocaleService.tr('Tạo nhãn mới', en: 'New tag')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: LocaleService.tr('VD: urgent, research...',
                  en: 'e.g. urgent, research...'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.none,
            maxLength: 24,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in TaskTag.paletteColors)
                _ColorSwatch(
                  color: Color(c),
                  selected: _selectedColor == c,
                  onTap: () => setState(() => _selectedColor = c),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleService.tr('Huỷ', en: 'Cancel')),
        ),
        FilledButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(TaskTag(
              id: '',
              name: name,
              colorValue: _selectedColor,
            ));
          },
          child: Text(LocaleService.tr('Tạo', en: 'Create')),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check_rounded,
                color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}
