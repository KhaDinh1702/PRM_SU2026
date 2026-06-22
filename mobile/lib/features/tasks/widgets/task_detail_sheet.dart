import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/checklist_item.dart';
import '../models/task_model.dart';
import '../models/task_tag.dart';
import '../services/checklist_service.dart';
import '../services/tag_service.dart';

/// Result emitted when the [TaskDetailSheet] closes.
class TaskDetailResult {
  /// Whether the user made any change that the caller should reload to
  /// reflect on the task card (checklist or tag mutation).
  final bool dirty;

  /// `true` when the sheet closed with every checklist item ticked off.
  /// The caller may auto-complete the parent task in that case.
  final bool allSubtasksDone;

  const TaskDetailResult({
    required this.dirty,
    required this.allSubtasksDone,
  });
}

/// Bottom sheet that opens on tap of a task card. Houses:
///  - core task fields (read-only summary)
///  - checklist editor (add / tick / remove items)
///  - tag picker (toggle attached tags from the user's catalog)
class TaskDetailSheet extends StatefulWidget {
  final TaskModel task;
  final ChecklistService checklistService;
  final TagService tagService;

  const TaskDetailSheet({
    super.key,
    required this.task,
    this.checklistService = const ChecklistService(),
    this.tagService = const TagService(),
  });

  static Future<TaskDetailResult?> show(
    BuildContext context, {
    required TaskModel task,
  }) {
    return showModalBottomSheet<TaskDetailResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(task: task),
    );
  }

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  bool _loading = true;
  bool _dirty = false;
  List<ChecklistItem> _items = const [];
  List<TaskTag> _catalog = const [];
  Set<String> _attachedTagIds = const {};
  final TextEditingController _addItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      widget.checklistService.loadItems(widget.task.id),
      widget.tagService.loadCatalog(),
      widget.tagService.loadAssignedIds(widget.task.id),
    ]);
    if (!mounted) return;
    setState(() {
      _items = results[0] as List<ChecklistItem>;
      _catalog = results[1] as List<TaskTag>;
      _attachedTagIds = (results[2] as List<String>).toSet();
      _loading = false;
    });
  }

  // --- Checklist mutations ---

  Future<void> _addItem() async {
    final text = _addItemController.text.trim();
    if (text.isEmpty) return;
    final next = [
      ..._items,
      ChecklistItem(
        id: 'c:${DateTime.now().millisecondsSinceEpoch}',
        text: text,
      ),
    ];
    await widget.checklistService.saveItems(widget.task.id, next);
    if (!mounted) return;
    setState(() {
      _items = next;
      _dirty = true;
    });
    _addItemController.clear();
  }

  Future<void> _toggleItem(ChecklistItem item) async {
    final next = _items
        .map((i) => i.id == item.id ? i.copyWith(isDone: !i.isDone) : i)
        .toList(growable: false);
    await widget.checklistService.saveItems(widget.task.id, next);
    if (!mounted) return;
    setState(() {
      _items = next;
      _dirty = true;
    });
    // If the user just ticked off the last unfinished subtask, close the
    // sheet immediately — the screen will auto-complete the parent task.
    final allDone = next.isNotEmpty && next.every((i) => i.isDone);
    if (allDone && !item.isDone) {
      // small delay so the user sees the checkbox flip before the sheet
      // animates away.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      Navigator.of(context).pop(
        const TaskDetailResult(dirty: true, allSubtasksDone: true),
      );
    }
  }

  Future<void> _removeItem(ChecklistItem item) async {
    final next = _items.where((i) => i.id != item.id).toList(growable: false);
    await widget.checklistService.saveItems(widget.task.id, next);
    if (!mounted) return;
    setState(() {
      _items = next;
      _dirty = true;
    });
  }

  // --- Tag mutations ---

  Future<void> _toggleTag(TaskTag tag) async {
    final next = {..._attachedTagIds};
    if (next.contains(tag.id)) {
      next.remove(tag.id);
    } else {
      next.add(tag.id);
    }
    await widget.tagService.saveAssignedIds(widget.task.id, next.toList());
    if (!mounted) return;
    setState(() {
      _attachedTagIds = next;
      _dirty = true;
    });
  }

  Future<void> _createTagFlow() async {
    final tag = await _CreateTagDialog.show(context);
    if (tag == null) return;
    final created = await widget.tagService.createTag(
      name: tag.name,
      colorValue: tag.colorValue,
    );
    if (!mounted) return;
    setState(() {
      _catalog = [..._catalog, created];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Handle(color: captionColor),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Title(task: widget.task, textColor: textColor),
                          const SizedBox(height: 14),
                          _ChecklistSection(
                            loading: _loading,
                            items: _items,
                            controller: _addItemController,
                            onAdd: _addItem,
                            onToggle: _toggleItem,
                            onRemove: _removeItem,
                          ),
                          const SizedBox(height: 22),
                          _TagsSection(
                            loading: _loading,
                            catalog: _catalog,
                            attachedIds: _attachedTagIds,
                            onToggle: _toggleTag,
                            onCreate: _createTagFlow,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _CloseBar(onClose: () {
                    final allDone =
                        _items.isNotEmpty && _items.every((i) => i.isDone);
                    Navigator.of(context).pop(
                      TaskDetailResult(
                        dirty: _dirty,
                        allSubtasksDone: allDone,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  final Color color;
  const _Handle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final TaskModel task;
  final Color textColor;

  const _Title({required this.task, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title.isEmpty
              ? LocaleService.tr('Task chưa đặt tên', en: 'Untitled task')
              : task.title,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.description,
            style: TextStyle(
              color: captionColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 14, color: captionColor),
            const SizedBox(width: 4),
            Text(
              task.dueText,
              style: TextStyle(
                color: captionColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.flag_outlined, size: 14, color: task.priorityColor),
            const SizedBox(width: 4),
            Text(
              task.priorityLabel,
              style: TextStyle(
                color: task.priorityColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final String? counter;

  const _SectionTitle({required this.label, this.counter});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        if (counter != null) ...[
          const SizedBox(width: 6),
          Text(
            counter!,
            style: TextStyle(
              color: captionColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  final bool loading;
  final List<ChecklistItem> items;
  final TextEditingController controller;
  final Future<void> Function() onAdd;
  final Future<void> Function(ChecklistItem) onToggle;
  final Future<void> Function(ChecklistItem) onRemove;

  const _ChecklistSection({
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
        _SectionTitle(
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
                  hintText: LocaleService.tr('Thêm bước...', en: 'Add a step...'),
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

class _TagsSection extends StatelessWidget {
  final bool loading;
  final List<TaskTag> catalog;
  final Set<String> attachedIds;
  final Future<void> Function(TaskTag) onToggle;
  final Future<void> Function() onCreate;

  const _TagsSection({
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
            _SectionTitle(label: LocaleService.tr('NHÃN', en: 'TAGS')),
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

class _CloseBar extends StatelessWidget {
  final VoidCallback onClose;
  const _CloseBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Row(
        children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(LocaleService.tr('Xong', en: 'Done')),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Create tag dialog ---

class _CreateTagDialog extends StatefulWidget {
  static Future<TaskTag?> show(BuildContext context) {
    return showDialog<TaskTag>(
      context: context,
      builder: (_) => const _CreateTagDialog(),
    );
  }

  const _CreateTagDialog();

  @override
  State<_CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<_CreateTagDialog> {
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
