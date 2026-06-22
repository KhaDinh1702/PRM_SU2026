import 'package:flutter/material.dart';

import '../../../../services/locale_service.dart';
import '../../../../services/theme_service.dart';
import '../../models/project_model.dart';
import '../project_card_v2.dart';

/// One group of projects under a labelled header. The header carries an
/// icon, the localized group name, and a count badge so users can see at
/// a glance how big each bucket is.
class ProjectGroupSection {
  final String key;
  final String label;
  final IconData icon;
  final Color tint;
  final List<ProjectModel> items;

  const ProjectGroupSection({
    required this.key,
    required this.label,
    required this.icon,
    required this.tint,
    required this.items,
  });
}

/// Sectioned list — replaces the flat ListView when [groupBy] != 'None'.
/// Empty groups are skipped (no "0 projects" rows). Each section has a
/// sticky-feeling pinned header that uses the group's tint colour.
class ProjectSectionList extends StatelessWidget {
  final List<ProjectGroupSection> sections;
  final void Function(ProjectModel project) onProjectTap;

  const ProjectSectionList({
    super.key,
    required this.sections,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          _SectionHeader(
            label: section.label,
            count: section.items.length,
            icon: section.icon,
            tint: section.tint,
          ),
          const SizedBox(height: 10),
          for (final project in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProjectCardV2(
                project: project,
                onTap: () => onProjectTap(project),
              ),
            ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color tint;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tint.withValues(alpha: 0.32)),
          ),
          child: Icon(icon, size: 16, color: tint),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: tint,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Spacer(),
        Text(
          _trailingCaption(count),
          style: TextStyle(
            color: captionColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _trailingCaption(int n) {
    final word = LocaleService.tr('dự án', en: n == 1 ? 'project' : 'projects');
    return '$n $word';
  }
}
