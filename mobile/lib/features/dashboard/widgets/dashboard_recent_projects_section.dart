import 'package:flutter/material.dart';

import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../projects/models/project_model.dart';
import '../../projects/widgets/project_card_v2.dart';

class DashboardRecentProjectsSection extends StatelessWidget {
  final List<ProjectModel> projects;
  final ValueChanged<ProjectModel>? onProjectTap;
  final VoidCallback? onViewAll;

  const DashboardRecentProjectsSection({
    super.key,
    required this.projects,
    this.onProjectTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocaleService.tr('Dự án đang hoạt động', en: 'Recent Projects'),
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  LocaleService.tr('Xem tất cả', en: 'View all'),
                  style: TextStyle(
                    color: ThemeService.getPrimaryColor(isDark),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Text(
              LocaleService.tr(
                'Chưa có dự án nào đang hoạt động.',
                en: 'No active projects yet.',
              ),
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          )
        else
          ...projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ProjectCardV2(
                project: project,
                compact: true,
                onTap: () => onProjectTap?.call(project),
              ),
            ),
          ),
      ],
    );
  }
}
