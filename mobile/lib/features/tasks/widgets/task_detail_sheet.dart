import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/checklist_item.dart';
import '../models/task_model.dart';
import '../models/task_tag.dart';
import '../services/checklist_service.dart';
import '../services/tag_service.dart';
import 'create_tag_dialog.dart';
import 'task_checklist_section.dart';
import 'task_tags_section.dart';

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

  /// When the user taps the Edit button. The caller is expected to open the
  /// edit dialog and refresh the task list — the sheet just pops first so
  /// the dialog can take focus.
  final VoidCallback? onEdit;

  /// When the user taps "Start focus". The caller should pop the sheet
  /// and push the Focus screen with this task pre-selected.
  final VoidCallback? onStartFocus;

  const TaskDetailSheet({
    super.key,
    required this.task,
    this.onEdit,
    this.onStartFocus,
    this.checklistService = const ChecklistService(),
    this.tagService = const TagService(),
  });

  static Future<TaskDetailResult?> show(
    BuildContext context, {
    required TaskModel task,
    VoidCallback? onEdit,
    VoidCallback? onStartFocus,
  }) {
    return showModalBottomSheet<TaskDetailResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(
        task: task,
        onEdit: onEdit,
        onStartFocus: onStartFocus,
      ),
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
    final tag = await CreateTagDialog.show(context);
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Title(
                                  task: widget.task,
                                  textColor: textColor,
                                ),
                              ),
                              if (widget.onEdit != null)
                                IconButton(
                                  tooltip: LocaleService.tr('Sửa task',
                                      en: 'Edit task'),
                                  splashRadius: 22,
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: textColor,
                                    size: 20,
                                  ),
                                  onPressed: widget.onEdit,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (widget.onStartFocus != null) ...[
                            _StartFocusButton(onTap: widget.onStartFocus!),
                            const SizedBox(height: 16),
                          ],
                          TaskChecklistSection(
                            loading: _loading,
                            items: _items,
                            controller: _addItemController,
                            onAdd: _addItem,
                            onToggle: _toggleItem,
                            onRemove: _removeItem,
                          ),
                          const SizedBox(height: 22),
                          TaskTagsSection(
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

/// Prominent "Start focus" CTA shown in the task detail sheet. Tapping
/// pops the sheet via the supplied callback so the host screen can push
/// the Focus screen with this task pre-selected.
class _StartFocusButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartFocusButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF06B6D4);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
        label: Text(
          LocaleService.tr('Bắt đầu focus', en: 'Start focus'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
