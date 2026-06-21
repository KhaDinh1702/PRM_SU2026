import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/locale_service.dart';
import '../../../../services/theme_service.dart';
import '../../providers/project_create_provider.dart';
import '../../providers/project_provider.dart';
import 'create_project_basics.dart';
import 'create_project_members.dart';
import 'create_project_schedule.dart';
import 'create_project_settings.dart';
import 'create_project_template_picker.dart';
import 'create_project_type_picker.dart';

/// Glassmorphic bottom sheet that hosts the multi-section "Create New Project"
/// form. Public entry point is [show] — callers don't construct it directly.
class CreateProjectSheet extends StatelessWidget {
  const CreateProjectSheet({super.key});

  /// Shows the sheet and resolves to the new project's id on success, or
  /// `null` if the user cancelled / submission failed.
  static Future<String?> show(BuildContext context) {
    final projectProvider = context.read<ProjectProvider>();
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<ProjectCreateProvider>(
        create: (_) => ProjectCreateProvider(),
        child: _CreateProjectSheetScaffold(projectProvider: projectProvider),
      ),
    );
  }

  // The widget itself is only an entry point; the real UI lives in the
  // _CreateProjectSheetScaffold child below.
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _CreateProjectSheetScaffold extends StatelessWidget {
  final ProjectProvider projectProvider;

  const _CreateProjectSheetScaffold({required this.projectProvider});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final mediaInsets = MediaQuery.of(context).viewInsets;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaInsets.bottom),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: dialogBg.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusXL),
              ),
              border: Border.all(color: borderColor),
            ),
            child: const SafeArea(
              top: false,
              child: _SheetBody(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM,
            vertical: 6,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  LocaleService.tr('Tạo dự án mới', en: 'Create new project'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppSizes.fontL,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              IconButton(
                tooltip: LocaleService.tr('Đóng', en: 'Close'),
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(null),
              ),
            ],
          ),
        ),
        const Flexible(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSizes.paddingM,
              AppSizes.paddingS,
              AppSizes.paddingM,
              AppSizes.paddingM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CreateProjectTemplatePicker(),
                SizedBox(height: AppSizes.paddingL - 4),
                CreateProjectBasicsSection(),
                SizedBox(height: AppSizes.paddingL - 4),
                CreateProjectTypePicker(),
                SizedBox(height: AppSizes.paddingL - 4),
                CreateProjectScheduleSection(),
                SizedBox(height: AppSizes.paddingL - 4),
                CreateProjectMembersSection(),
                SizedBox(height: AppSizes.paddingL - 4),
                CreateProjectSettingsSection(),
              ],
            ),
          ),
        ),
        const _SubmitBar(),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final color = ThemeService.getCaptionColor(isDark).withValues(alpha: 0.35);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectCreateProvider>();
    final isDark = ThemeService.isDarkMode.value;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingM,
        AppSizes.paddingS + 4,
        AppSizes.paddingM,
        AppSizes.paddingM - 2,
      ),
      child: Row(
        children: [
          if (provider.submitError != null)
            Expanded(
              child: Text(
                provider.submitError!,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: AppSizes.fontS + 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const Spacer(),
          TextButton(
            onPressed:
                provider.isSubmitting ? null : () => Navigator.of(context).pop(),
            child: Text(
              LocaleService.tr('Huỷ', en: 'Cancel'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: provider.canSubmit
                  ? () => _handleSubmit(context, provider)
                  : null,
              icon: provider.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(provider.isSubmitting
                  ? LocaleService.tr('Đang tạo…', en: 'Creating…')
                  : LocaleService.tr('Tạo', en: 'Create')),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    ProjectCreateProvider provider,
  ) async {
    final projects = context.read<ProjectProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await provider.submit(projects);
    if (!context.mounted) return;

    if (result.success) {
      final failed = result.failedInvites;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failed.isEmpty
                ? 'Project created'
                : 'Project created — could not invite ${failed.length} email(s)',
          ),
          backgroundColor: failed.isEmpty
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      navigator.pop(result.projectId);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Could not create project'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
