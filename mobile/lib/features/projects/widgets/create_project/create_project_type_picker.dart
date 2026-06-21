import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';
import '../../../../services/locale_service.dart';
import '../../models/project_type.dart';
import '../../providers/project_create_provider.dart';
import 'section_header.dart';

/// Visual chip picker for the project type. Replaces the original dropdown
/// so the icon, colour and short description of each type are visible
/// without an extra tap.
class CreateProjectTypePicker extends StatelessWidget {
  const CreateProjectTypePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectCreateProvider>();
    final selected = provider.draft.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateProjectSectionHeader(
          icon: Icons.category_rounded,
          title: LocaleService.tr('Loại', en: 'Type'),
          subtitle: LocaleService.tr(
            'Bạn sẽ dùng dự án này thế nào?',
            en: 'How will you use this project?',
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSizes.paddingS;
            final tileWidth =
                (constraints.maxWidth - spacing) / 2; // 2 cột mobile
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final meta in ProjectTypeMeta.all)
                  SizedBox(
                    width: tileWidth,
                    child: _ProjectTypeTile(
                      meta: meta,
                      selected: meta.type == selected,
                      onTap: () => provider.setType(meta.type),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProjectTypeTile extends StatelessWidget {
  final ProjectTypeMeta meta;
  final bool selected;
  final VoidCallback onTap;

  const _ProjectTypeTile({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    final background = selected
        ? meta.color.withValues(alpha: 0.14)
        : (isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03));
    final borderColor = selected
        ? meta.color.withValues(alpha: 0.55)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08));

    return Semantics(
      button: true,
      selected: selected,
      label: '${meta.localizedLabel} · ${meta.localizedDescription}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM - 4,
              vertical: AppSizes.paddingS + 4,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(meta.icon, color: meta.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.localizedLabel,
                        style: TextStyle(
                          color: selected ? meta.color : textColor,
                          fontSize: AppSizes.fontM,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta.localizedDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: captionColor,
                          fontSize: AppSizes.fontXS + 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
