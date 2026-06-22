import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/task_tag.dart';

/// Group chip filter cho một nhóm options (Source, Status, Priority, Sort).
class TaskFilterGroup extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  static const Color _accent = AppColors.taskAccent;

  const TaskFilterGroup({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: subTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(_labelFor(option)),
                  selected: value == option,
                  showCheckmark: false,
                  selectedColor: _accent.withValues(alpha: 0.18),
                  backgroundColor: cardColor,
                  side: BorderSide(
                    color: value == option ? _accent : borderColor,
                  ),
                  labelStyle: TextStyle(
                    color: value == option ? _accent : textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (_) => onChanged(option),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelFor(String option) {
    if (option == 'recent') return 'Recent';
    if (option == 'deadline') return 'Due date';
    if (option == 'priority') return 'Priority';
    return option;
  }
}

/// Bottom sheet filter cho task screen.
/// Dùng showTaskFilterSheet() thay vì tạo instance trực tiếp.
Future<TaskFilterResult?> showTaskFilterSheet(
  BuildContext context, {
  required String sourceFilter,
  required String statusFilter,
  required String priorityFilter,
  required String sortBy,
  required Set<String> selectedTagIds,
  required List<TaskTag> availableTags,
}) {
  return showModalBottomSheet<TaskFilterResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _TaskFilterSheet(
      initialSource: sourceFilter,
      initialStatus: statusFilter,
      initialPriority: priorityFilter,
      initialSort: sortBy,
      initialTagIds: selectedTagIds,
      availableTags: availableTags,
    ),
  );
}

/// Kết quả filter trả về sau khi user Apply.
class TaskFilterResult {
  final String source;
  final String status;
  final String priority;
  final String sort;
  final Set<String> tagIds;

  const TaskFilterResult({
    required this.source,
    required this.status,
    required this.priority,
    required this.sort,
    this.tagIds = const {},
  });
}

class _TaskFilterSheet extends StatefulWidget {
  final String initialSource;
  final String initialStatus;
  final String initialPriority;
  final String initialSort;
  final Set<String> initialTagIds;
  final List<TaskTag> availableTags;

  const _TaskFilterSheet({
    required this.initialSource,
    required this.initialStatus,
    required this.initialPriority,
    required this.initialSort,
    required this.initialTagIds,
    required this.availableTags,
  });

  @override
  State<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<_TaskFilterSheet> {
  late String _source;
  late String _status;
  late String _priority;
  late String _sort;
  late Set<String> _tagIds;

  static const Color _accent = AppColors.taskAccent;

  @override
  void initState() {
    super.initState();
    _source = widget.initialSource;
    _status = widget.initialStatus;
    _priority = widget.initialPriority;
    _sort = widget.initialSort;
    _tagIds = {...widget.initialTagIds};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final bg = ThemeService.getDialogBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).padding.bottom + 22,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
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
                color: subTextColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            LocaleService.tr('Lọc task', en: 'Filter tasks'),
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          TaskFilterGroup(
            title: LocaleService.tr('Nguồn', en: 'Source'),
            value: _source,
            options: const ['All', 'Personal', 'Project', 'Schedule'],
            onChanged: (v) => setState(() => _source = v),
          ),
          TaskFilterGroup(
            title: LocaleService.tr('Trạng thái', en: 'Status'),
            value: _status,
            options: const ['All', 'Pending', 'In Progress', 'Completed'],
            onChanged: (v) => setState(() => _status = v),
          ),
          TaskFilterGroup(
            title: LocaleService.tr('Ưu tiên', en: 'Priority'),
            value: _priority,
            options: const ['All', 'Low', 'Medium', 'High', 'Urgent'],
            onChanged: (v) => setState(() => _priority = v),
          ),
          TaskFilterGroup(
            title: LocaleService.tr('Sắp xếp', en: 'Sort by'),
            value: _sort,
            options: const ['recent', 'deadline', 'priority'],
            onChanged: (v) => setState(() => _sort = v),
          ),
          if (widget.availableTags.isNotEmpty)
            _TagMultiSelectGroup(
              title: LocaleService.tr('Nhãn', en: 'Tags'),
              tags: widget.availableTags,
              selectedIds: _tagIds,
              onToggle: (id) => setState(() {
                if (_tagIds.contains(id)) {
                  _tagIds.remove(id);
                } else {
                  _tagIds = {..._tagIds, id};
                }
              }),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    const TaskFilterResult(
                      source: 'All',
                      status: 'All',
                      priority: 'All',
                      sort: 'recent',
                      tagIds: {},
                    ),
                  ),
                  child: Text(
                    LocaleService.tr('Đặt lại', en: 'Reset'),
                    style: TextStyle(
                      color: subTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumButton(
                  onPressed: () => Navigator.pop(
                    context,
                    TaskFilterResult(
                      source: _source,
                      status: _status,
                      priority: _priority,
                      sort: _sort,
                      tagIds: _tagIds,
                    ),
                  ),
                  backgroundColor: _accent,
                  child: Text(
                    LocaleService.tr('Áp dụng', en: 'Apply'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Multi-select chip group for tags. Each chip toggles in/out of the
/// selected set independently — unlike [TaskFilterGroup] which picks one.
class _TagMultiSelectGroup extends StatelessWidget {
  final String title;
  final List<TaskTag> tags;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _TagMultiSelectGroup({
    required this.title,
    required this.tags,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: subTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                _TagFilterChip(
                  tag: tag,
                  selected: selectedIds.contains(tag.id),
                  onTap: () => onToggle(tag.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagFilterChip extends StatelessWidget {
  final TaskTag tag;
  final bool selected;
  final VoidCallback onTap;

  const _TagFilterChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : tag.color;
    final bg =
        selected ? tag.color : tag.color.withValues(alpha: 0.14);
    final border =
        selected ? tag.color : tag.color.withValues(alpha: 0.45);

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
              ],
              Text(
                '#${tag.name}',
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
