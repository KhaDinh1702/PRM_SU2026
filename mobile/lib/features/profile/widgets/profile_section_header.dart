import 'package:flutter/material.dart';

import '../../../services/theme_service.dart';

/// Tiny uppercase label used to introduce each profile section
/// (TOOLS, PREFERENCES, ACCOUNT...). Kept in its own widget so spacing and
/// typography stay consistent without each section re-declaring it.
class ProfileSectionHeader extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;

  const ProfileSectionHeader({
    super.key,
    required this.label,
    this.padding = const EdgeInsets.only(left: 4, bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    return Padding(
      padding: padding,
      child: Text(
        label,
        style: TextStyle(
          color: captionColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
