import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';
import '../../models/project_milestone.dart';

/// Payload returned by [MilestoneCreateSheet.show]. `null` means the user
/// cancelled — caller should not mutate anything.
class MilestoneSheetResult {
  final String title;
  final String description;
  final DateTime? targetDate;

  const MilestoneSheetResult({
    required this.title,
    required this.description,
    required this.targetDate,
  });
}

/// Bottom sheet for creating or editing a user milestone.
///
/// Pass [initial] to switch into edit mode — the sheet pre-fills the form
/// and changes its title. Returns [MilestoneSheetResult] on save, `null`
/// on cancel.
class MilestoneCreateSheet extends StatefulWidget {
  final ProjectMilestone? initial;

  const MilestoneCreateSheet({super.key, this.initial});

  static Future<MilestoneSheetResult?> show(
    BuildContext context, {
    ProjectMilestone? initial,
  }) {
    return showModalBottomSheet<MilestoneSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MilestoneCreateSheet(initial: initial),
    );
  }

  @override
  State<MilestoneCreateSheet> createState() => _MilestoneCreateSheetState();
}

class _MilestoneCreateSheetState extends State<MilestoneCreateSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  DateTime? _targetDate;
  bool _titleTouched = false;

  static const int _titleMaxLength = 60;
  static const int _descMaxLength = 240;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descController =
        TextEditingController(text: widget.initial?.description ?? '');
    _targetDate = widget.initial?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String? get _titleError {
    if (!_titleTouched) return null;
    final trimmed = _titleController.text.trim();
    if (trimmed.isEmpty) return 'Title is required';
    if (trimmed.length < 2) return 'Title is too short';
    return null;
  }

  bool get _canSubmit {
    final trimmed = _titleController.text.trim();
    return trimmed.length >= 2;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
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
              top: Radius.circular(AppSizes.radiusXL),
            ),
            border: Border.all(color: borderColor),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingM,
                AppSizes.paddingS,
                AppSizes.paddingM,
                AppSizes.paddingM,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Handle(color: captionColor),
                  const SizedBox(height: 6),
                  Text(
                    _isEditing ? 'Edit milestone' : 'New milestone',
                    style: TextStyle(
                      color: textColor,
                      fontSize: AppSizes.fontL,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  _LabelledField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'e.g. Beta launch',
                    icon: Icons.flag_rounded,
                    maxLength: _titleMaxLength,
                    errorText: _titleError,
                    autofocus: !_isEditing,
                    onChanged: (_) => setState(() => _titleTouched = true),
                  ),
                  const SizedBox(height: AppSizes.paddingS + 4),
                  _LabelledField(
                    controller: _descController,
                    label: 'Description',
                    hint: 'Optional — what does done look like?',
                    icon: Icons.description_outlined,
                    maxLength: _descMaxLength,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSizes.paddingS + 4),
                  _DatePickerRow(
                    value: _targetDate,
                    onPicked: (value) => setState(() => _targetDate = value),
                    onCleared: () => setState(() => _targetDate = null),
                    textColor: textColor,
                    captionColor: captionColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSizes.paddingL - 4),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        onPressed: _canSubmit ? _submit : null,
                        icon: Icon(
                          _isEditing
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          size: 18,
                        ),
                        label: Text(_isEditing ? 'Save' : 'Create'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusM),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingM,
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

  void _submit() {
    Navigator.of(context).pop(
      MilestoneSheetResult(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        targetDate: _targetDate,
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  final Color color;
  const _Handle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
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

class _LabelledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLength;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _LabelledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.maxLength,
    required this.onChanged,
    this.maxLines = 1,
    this.errorText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: maxLength,
      maxLines: maxLines,
      autofocus: autofocus,
      style: TextStyle(color: textColor, fontSize: AppSizes.fontM),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Icon(icon, color: captionColor, size: 20),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        labelStyle: TextStyle(
          color: captionColor,
          fontSize: AppSizes.fontS + 2,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: captionColor, fontSize: AppSizes.fontM),
        filled: true,
        fillColor: fillColor,
        counterStyle:
            TextStyle(color: captionColor, fontSize: AppSizes.fontXS + 1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM - 4,
          vertical: AppSizes.paddingS + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback onCleared;
  final Color textColor;
  final Color captionColor;
  final bool isDark;

  const _DatePickerRow({
    required this.value,
    required this.onPicked,
    required this.onCleared,
    required this.textColor,
    required this.captionColor,
    required this.isDark,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? now.add(const Duration(days: 7));
    final firstDate = DateTime(now.year - 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      helpText: 'Target date',
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM - 4,
          vertical: AppSizes.paddingS + 6,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 18, color: captionColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value == null
                    ? 'No target date'
                    : DateFormat('MMM d, yyyy').format(value!),
                style: TextStyle(
                  color: value == null ? captionColor : textColor,
                  fontSize: AppSizes.fontM,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (value != null)
              IconButton(
                splashRadius: 18,
                icon: Icon(Icons.close_rounded,
                    size: 18, color: captionColor),
                onPressed: onCleared,
              ),
            Icon(Icons.edit_calendar_rounded, size: 18, color: captionColor),
          ],
        ),
      ),
    );
  }
}
