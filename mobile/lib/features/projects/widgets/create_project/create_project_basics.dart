import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';
import '../../../../services/locale_service.dart';
import '../../models/project_create_draft.dart';
import '../../providers/project_create_provider.dart';
import 'section_header.dart';

/// Name + description inputs. Name is required and shows an inline error
/// once the user starts typing.
class CreateProjectBasicsSection extends StatefulWidget {
  const CreateProjectBasicsSection({super.key});

  @override
  State<CreateProjectBasicsSection> createState() =>
      _CreateProjectBasicsSectionState();
}

class _CreateProjectBasicsSectionState
    extends State<CreateProjectBasicsSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  bool _nameTouched = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<ProjectCreateProvider>().draft;
    _nameController = TextEditingController(text: draft.name);
    _descController = TextEditingController(text: draft.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Push [draftValue] into [controller] only when it differs from what's
  /// currently in the field. Keeps the cursor where the user put it as long
  /// as the user is the source of the change.
  void _syncFromDraft(TextEditingController controller, String draftValue) {
    if (controller.text == draftValue) return;
    controller.value = TextEditingValue(
      text: draftValue,
      selection: TextSelection.collapsed(offset: draftValue.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectCreateProvider>();
    final validation = provider.validation;
    final nameError = _nameTouched ? validation.nameError : null;

    // Sync controllers when the draft changes from outside (e.g. user picks
    // a template) — but don't clobber what they're actively typing.
    _syncFromDraft(_nameController, provider.draft.name);
    _syncFromDraft(_descController, provider.draft.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateProjectSectionHeader(
          icon: Icons.edit_note_rounded,
          title: LocaleService.tr('Thông tin chung', en: 'Basics'),
          subtitle: LocaleService.tr(
            'Đặt tên và mô tả ngắn cho dự án.',
            en: 'Give your project a name and short description.',
          ),
        ),
        _LabelledField(
          controller: _nameController,
          label: LocaleService.tr('Tên dự án', en: 'Project name'),
          hint: LocaleService.tr('VD: Sprint 1 đồ án tốt nghiệp',
              en: 'e.g. Capstone Sprint 1'),
          icon: Icons.folder_rounded,
          maxLength: ProjectCreateDraft.nameMaxLength,
          errorText: nameError,
          autofocus: true,
          onChanged: (value) {
            if (!_nameTouched) setState(() => _nameTouched = true);
            provider.setName(value);
          },
        ),
        const SizedBox(height: AppSizes.paddingM - 4),
        _LabelledField(
          controller: _descController,
          label: LocaleService.tr('Mô tả', en: 'Description'),
          hint: LocaleService.tr(
            'Tuỳ chọn — dự án này về cái gì?',
            en: 'Optional — what is this project about?',
          ),
          icon: Icons.description_outlined,
          maxLength: ProjectCreateDraft.descriptionMaxLength,
          maxLines: 3,
          onChanged: provider.setDescription,
        ),
      ],
    );
  }
}

/// Small wrapper around [TextField] that keeps label, helper, counter and
/// error styling consistent across the sheet. Local to this folder — there
/// is already a `PremiumInputField` but it lacks error/counter support, so
/// we use the framework field directly here.
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
