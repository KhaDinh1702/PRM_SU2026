import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/recurrence_rule.dart';
import '../models/task_model.dart';
import 'due_date_picker.dart';
import 'priority_picker.dart';
import 'recurrence_picker.dart';

/// Data the form emits when the user taps Create / Save.
class TaskFormResult {
  final String title;
  final String description;
  final String priority;
  final DateTime? dueDate;
  final RecurrenceRule? recurrence;

  const TaskFormResult({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.recurrence,
  });
}

/// Stateful dialog used for both creating and editing a task. The caller
/// pre-loads the recurrence rule (for edit) and supplies an [onSubmit]
/// callback — the dialog only closes when [onSubmit] returns `true`, so
/// the caller can show a SnackBar and abort the close on failure.
class TaskFormDialog extends StatefulWidget {
  final TaskModel? initial;
  final RecurrenceRule? initialRecurrence;
  final Color accent;
  final Future<bool> Function(TaskFormResult result) onSubmit;

  const TaskFormDialog({
    super.key,
    required this.accent,
    required this.onSubmit,
    this.initial,
    this.initialRecurrence,
  });

  static Future<void> show(
    BuildContext context, {
    required Color accent,
    required Future<bool> Function(TaskFormResult result) onSubmit,
    TaskModel? initial,
    RecurrenceRule? initialRecurrence,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => TaskFormDialog(
        accent: accent,
        onSubmit: onSubmit,
        initial: initial,
        initialRecurrence: initialRecurrence,
      ),
    );
  }

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _priority;
  DateTime? _dueDate;
  RecurrenceRule? _recurrence;
  bool _submitting = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descController = TextEditingController(text: initial?.description ?? '');
    _priority = initial?.priorityLabel ?? 'Medium';
    _dueDate = initial?.effectiveDueDateTime;
    _recurrence = widget.initialRecurrence;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final ok = await widget.onSubmit(TaskFormResult(
      title: title,
      description: _descController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      recurrence: _recurrence,
    ));
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: AlertDialog(
        backgroundColor: dialogBg.withValues(alpha: 0.94),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        title: Text(
          _isEditing
              ? LocaleService.tr('SỬA TASK', en: 'EDIT TASK')
              : LocaleService.tr('TẠO TASK CÁ NHÂN',
                  en: 'CREATE PERSONAL TASK'),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumInputField(
              controller: _titleController,
              label: LocaleService.tr('Tên task *', en: 'Task title *'),
              hintText:
                  LocaleService.tr('Nhập tên task...', en: 'Enter title...'),
              prefixIcon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 14),
            PremiumInputField(
              controller: _descController,
              label:
                  LocaleService.tr('Mô tả ngắn', en: 'Short description'),
              hintText:
                  LocaleService.tr('Chi tiết...', en: 'Enter details...'),
              prefixIcon: Icons.notes_rounded,
            ),
            const SizedBox(height: 14),
            DueDatePickerTile(
              value: _dueDate,
              onChanged: (value) => setState(() => _dueDate = value),
            ),
            const SizedBox(height: 10),
            PriorityPickerTile(
              value: _priority,
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: 10),
            RecurrencePickerTile(
              rule: _recurrence,
              onChanged: (next) => setState(() => _recurrence = next),
            ),
            const SizedBox(height: 10),
            if (!_isEditing)
              Text(
                LocaleService.tr(
                  'Task dự án được giao trong màn Chi tiết dự án và tự động hiện ở đây.',
                  en: 'Project tasks are assigned inside Project Detail and appear here automatically.',
                ),
                style: TextStyle(color: captionColor, fontSize: 11),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            child: Text(
              LocaleService.tr('Huỷ', en: 'Cancel'),
              style: TextStyle(
                  color: captionColor, fontWeight: FontWeight.bold),
            ),
          ),
          PremiumButton(
            onPressed: _submitting ? null : _handleSubmit,
            backgroundColor: widget.accent,
            child: Text(
              _isEditing
                  ? LocaleService.tr('Lưu', en: 'Save')
                  : LocaleService.tr('Tạo', en: 'Create'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
