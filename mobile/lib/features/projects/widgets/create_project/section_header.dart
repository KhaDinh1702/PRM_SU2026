import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';

/// Visual header reused by every section inside [CreateProjectSheet]. Keeping
/// it in its own widget avoids copy/paste of the title-and-icon row.
class CreateProjectSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const CreateProjectSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: captionColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppSizes.fontM,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: captionColor,
                        fontSize: AppSizes.fontS + 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
