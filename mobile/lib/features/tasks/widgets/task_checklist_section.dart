import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/checklist_item.dart';
import 'task_section_title.dart';

/// Subtasks block inside the task detail sheet: header with `done/total`
/// counter, list of [_ChecklistRow]s, and a quick-add field at the bottom.
class TaskChecklistSection extends StatelessWidget {
  final bool loading;
  final List<ChecklistItem> items;
  final TextEditingController controller;
  final Future<void> Function() onAdd;
  final Future<void> Function(ChecklistItem) onToggle;
  final Future<void> Function(ChecklistItem) onRemove;

  const TaskChecklistSection({
    super.key,
    required this.loading,
    required this.items,
    required this.controller,
    required this.onAdd,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final done = items.where((i) => i.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskSectionTitle(
          label: LocaleService.tr('CÁC BƯỚC', en: 'SUBTASKS'),
          counter: items.isEmpty ? null : '$done/${items.length}',
        ),
        const SizedBox(height: 8),
        if (loading)
          const SizedBox(
            height: 28,
            child: Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else
          for (final item in items)
            _ChecklistRow(
              item: item,
              onToggle: () => onToggle(item),
              onRemove: () => onRemove(item),
            ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onAdd(),
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      LocaleService.tr('Thêm bước...', en: 'Add a step...'),
                  hintStyle: TextStyle(color: captionColor),
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _ChecklistRow({
    required this.item,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggle,
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              item.isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: item.isDone
                  ? const Color(0xFF10B981)
                  : captionColor,
              size: 22,
            ),
          ),
          Expanded(
            child: Text(
              item.text,
              style: TextStyle(
                color: item.isDone ? captionColor : textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration:
                    item.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.close_rounded, color: captionColor, size: 18),
          ),
        ],
      ),
    );
  }
}
