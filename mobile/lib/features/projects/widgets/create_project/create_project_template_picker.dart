import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/locale_service.dart';
import '../../../../services/theme_service.dart';
import '../../models/project_template.dart';
import '../../providers/project_create_provider.dart';
import 'section_header.dart';

/// Horizontal carousel of pre-built [ProjectTemplate] cards shown at the top
/// of the Create Project sheet. Selecting a template fills the form below.
class CreateProjectTemplatePicker extends StatelessWidget {
  const CreateProjectTemplatePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectCreateProvider>();
    final selectedId = provider.draft.template?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateProjectSectionHeader(
          icon: Icons.dashboard_customize_rounded,
          title: LocaleService.tr('Mẫu dự án', en: 'Templates'),
          subtitle: LocaleService.tr(
            'Bắt đầu từ mẫu sẵn — kèm milestone.',
            en: 'Start from a blueprint — milestones included.',
          ),
        ),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ProjectTemplate.catalog.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _BlankCard(
                  selected: selectedId == null,
                  onTap: () => provider.applyTemplate(null),
                );
              }
              final template = ProjectTemplate.catalog[index - 1];
              return _TemplateCard(
                template: template,
                selected: selectedId == template.id,
                onTap: () => provider.applyTemplate(template),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BlankCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _BlankCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardBg = ThemeService.getCardColor(isDark);
    final borderColor = selected
        ? const Color(0xFF06B6D4)
        : ThemeService.getBorderColor(isDark);

    return SizedBox(
      width: 150,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: captionColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add_rounded,
                      color: captionColor, size: 18),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleService.tr('Trống', en: 'Blank'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: AppSizes.fontM,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.tr('Bắt đầu từ đầu',
                          en: 'Start from scratch'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: captionColor,
                        fontSize: AppSizes.fontS,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ProjectTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardBg = ThemeService.getCardColor(isDark);
    final borderColor = selected
        ? template.color
        : ThemeService.getBorderColor(isDark);

    return SizedBox(
      width: 200,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: template.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(template.icon,
                          color: template.color, size: 18),
                    ),
                    const Spacer(),
                    Text(
                      LocaleService.tr(
                          '${template.milestones.length} milestone',
                          en: '${template.milestones.length} milestones'),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: AppSizes.fontXS + 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: AppSizes.fontM,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: captionColor,
                        fontSize: AppSizes.fontS,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
