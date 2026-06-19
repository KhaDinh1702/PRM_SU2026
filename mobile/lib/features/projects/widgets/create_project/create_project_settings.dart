import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';
import '../../models/project_type.dart';
import '../../providers/project_create_provider.dart';
import 'section_header.dart';

/// Per-project toggles. Currently only "allow members to create tasks" —
/// the section is hidden for single-user (Personal) projects since the
/// toggle has no effect there.
class CreateProjectSettingsSection extends StatelessWidget {
  const CreateProjectSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectCreateProvider>();
    final meta = ProjectTypeMeta.of(provider.draft.type);
    if (!meta.collaborative) return const SizedBox.shrink();

    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreateProjectSectionHeader(
          icon: Icons.tune_rounded,
          title: 'Settings',
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM - 4,
            vertical: 4,
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
          child: SwitchListTile(
            value: provider.draft.allowMembersToCreateTasks,
            onChanged: provider.setAllowMembersToCreateTasks,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: meta.color,
            title: Text(
              'Members can add tasks',
              style: TextStyle(
                color: textColor,
                fontSize: AppSizes.fontM - 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Otherwise only owners and managers can create tasks.',
              style:
                  TextStyle(color: captionColor, fontSize: AppSizes.fontS + 1),
            ),
          ),
        ),
      ],
    );
  }
}
