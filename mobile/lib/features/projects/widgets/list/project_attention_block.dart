import 'package:flutter/material.dart';

import '../../../../services/locale_service.dart';
import '../../../../services/theme_service.dart';
import '../../models/project_model.dart';
import '../project_card_v2.dart';

/// "Needs attention" block pinned to the top of the project list. Surfaces
/// projects with `needsAttention == true`, ordered by `attentionScore`,
/// capped at [maxItems]. Hidden entirely when nothing needs attention.
class ProjectAttentionBlock extends StatelessWidget {
  final List<ProjectModel> projects;
  final void Function(ProjectModel project) onProjectTap;
  final int maxItems;

  static const Color _accent = Color(0xFFF59E0B);

  const ProjectAttentionBlock({
    super.key,
    required this.projects,
    required this.onProjectTap,
    this.maxItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    final items = projects.take(maxItems).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accent.withValues(alpha: 0.36)),
                ),
                child: const Icon(Icons.bolt_rounded,
                    size: 16, color: _accent),
              ),
              const SizedBox(width: 10),
              Text(
                LocaleService.tr('Cần chú ý', en: 'Needs attention'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  items.length.toString(),
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                LocaleService.tr('Quá hạn / sắp tới', en: 'Overdue / soon'),
                style: TextStyle(
                  color: captionColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final project in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProjectCardV2(
                project: project,
                onTap: () => onProjectTap(project),
              ),
            ),
        ],
      ),
    );
  }
}
