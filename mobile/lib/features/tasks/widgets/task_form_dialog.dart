import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../navigation/screens/location_picker_screen.dart';
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
  final TaskLocation? location;

  const TaskFormResult({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.recurrence,
    this.location,
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
  late final TextEditingController _placeController;
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late String _priority;
  DateTime? _dueDate;
  RecurrenceRule? _recurrence;
  bool _locationEnabled = false;
  String? _locationError;
  bool _submitting = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descController = TextEditingController(text: initial?.description ?? '');
    _placeController =
        TextEditingController(text: initial?.location?.placeName ?? '');
    _addressController =
        TextEditingController(text: initial?.location?.address ?? '');
    _latController = TextEditingController(
      text: initial?.location == null
          ? ''
          : initial!.location!.latitude.toStringAsFixed(6),
    );
    _lngController = TextEditingController(
      text: initial?.location == null
          ? ''
          : initial!.location!.longitude.toStringAsFixed(6),
    );
    _priority = initial?.priorityLabel ?? 'Medium';
    _dueDate = initial?.effectiveDueDateTime;
    _recurrence = widget.initialRecurrence;
    _locationEnabled = initial?.hasLocation == true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _placeController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _submitting) return;
    final location = _buildLocation();
    if (_locationError != null) {
      setState(() {});
      return;
    }
    setState(() => _submitting = true);
    final ok = await widget.onSubmit(TaskFormResult(
      title: title,
      description: _descController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      recurrence: _recurrence,
      location: location,
    ));
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
    }
  }

  TaskLocation? _buildLocation() {
    _locationError = null;
    if (!_locationEnabled) return null;

    final latitude = double.tryParse(_latController.text.trim());
    final longitude = double.tryParse(_lngController.text.trim());
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      _locationError = LocaleService.tr(
        'Toa do khong hop le',
        en: 'Invalid coordinates',
      );
      return null;
    }

    return TaskLocation(
      placeName: _placeController.text.trim(),
      address: _addressController.text.trim(),
      latitude: latitude,
      longitude: longitude,
      reminderRadiusMeters: 100,
    );
  }

  Future<void> _pickLocationOnMap() async {
    final currentDraft = _draftLocationOrNull();
    final picked = await Navigator.of(context).push<TaskLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: currentDraft),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _locationEnabled = true;
      _locationError = null;
      _placeController.text = picked.placeName;
      _addressController.text = picked.address;
      _latController.text = picked.latitude.toStringAsFixed(6);
      _lngController.text = picked.longitude.toStringAsFixed(6);
    });
  }

  TaskLocation? _draftLocationOrNull() {
    final latitude = double.tryParse(_latController.text.trim());
    final longitude = double.tryParse(_lngController.text.trim());
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return TaskLocation(
      placeName: _placeController.text.trim(),
      address: _addressController.text.trim(),
      latitude: latitude,
      longitude: longitude,
    );
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
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumInputField(
                  controller: _titleController,
                  label: LocaleService.tr('Tên task *', en: 'Task title *'),
                  hintText: LocaleService.tr('Nhập tên task...',
                      en: 'Enter title...'),
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
                _LocationFields(
                  enabled: _locationEnabled,
                  placeController: _placeController,
                  addressController: _addressController,
                  errorText: _locationError,
                  onPickMap: _pickLocationOnMap,
                  onEnabledChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                      _locationError = null;
                    });
                  },
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            child: Text(
              LocaleService.tr('Huỷ', en: 'Cancel'),
              style:
                  TextStyle(color: captionColor, fontWeight: FontWeight.bold),
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

class _LocationFields extends StatelessWidget {
  final bool enabled;
  final TextEditingController placeController;
  final TextEditingController addressController;
  final String? errorText;
  final VoidCallback onPickMap;
  final ValueChanged<bool> onEnabledChanged;

  const _LocationFields({
    required this.enabled,
    required this.placeController,
    required this.addressController,
    required this.errorText,
    required this.onPickMap,
    required this.onEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.025 : 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: enabled,
            onChanged: onEnabledChanged,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            activeThumbColor: const Color(0xFF06B6D4),
            secondary: Icon(
              Icons.location_on_outlined,
              color: enabled ? const Color(0xFF06B6D4) : captionColor,
            ),
            title: Text(
              LocaleService.tr('Gan dia diem', en: 'Attach location'),
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (enabled) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onPickMap,
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: Text(
                        LocaleService.tr('Chon tren ban do', en: 'Pick on map'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PremiumInputField(
                    controller: placeController,
                    label: LocaleService.tr('Ten dia diem', en: 'Place name'),
                    hintText: 'WinMart Nguyen Trai',
                    prefixIcon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 10),
                  PremiumInputField(
                    controller: addressController,
                    label: LocaleService.tr('Dia chi', en: 'Address'),
                    hintText: 'Nguyen Trai, Thanh Xuan',
                    prefixIcon: Icons.map_outlined,
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
