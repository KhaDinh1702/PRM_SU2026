import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/task_tag.dart';
import 'task_section_title.dart';

/// Tags block inside the task detail sheet: header + "New tag" button,
/// and a wrapping list of [_TagChip]s that toggle attachment to the task.
class TaskTagsSection extends StatelessWidget {
  final bool loading;
  final List<TaskTag> catalog;
  final Set<String> attachedIds;
  final Future<void> Function(TaskTag) onToggle;
  final Future<void> Function() onCreate;

  const TaskTagsSection({
    super.key,
    required this.loading,
    required this.catalog,
    required this.attachedIds,
    required this.onToggle,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TaskSectionTitle(label: LocaleService.tr('NHÃN', en: 'TAGS')),
            const Spacer(),
            TextButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(LocaleService.tr('Tạo nhãn', en: 'New tag')),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF06B6D4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (loading)
          const SizedBox(height: 28)
        else if (catalog.isEmpty)
          Text(
            LocaleService.tr(
              'Bạn chưa có nhãn nào. Tạo nhãn đầu tiên để phân loại task.',
              en: "You haven't created any tags yet. Create one to start categorising tasks.",
            ),
            style: TextStyle(
              color: captionColor,
              fontSize: 12,
              height: 1.4,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in catalog)
                _TagChip(
                  tag: tag,
                  selected: attachedIds.contains(tag.id),
                  onTap: () => onToggle(tag),
                ),
            ],
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final TaskTag tag;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : tag.color;
    final bg = selected
        ? tag.color
        : tag.color.withValues(alpha: 0.14);
    final border = selected
        ? tag.color
        : tag.color.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
              ] else ...[
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: tag.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Text(
                tag.name,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
