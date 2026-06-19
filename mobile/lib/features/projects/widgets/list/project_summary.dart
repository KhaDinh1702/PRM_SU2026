import 'package:flutter/material.dart';

import '../../../../services/theme_service.dart';

/// Inline summary: "3 projects · 3 active · 1 needs attention".
/// Replaces the previous 3-tile layout to save ~80px of vertical space.
class ProjectSummary extends StatelessWidget {
  final int totalProjects;
  final int activeProjects;
  final int attentionProjects;

  const ProjectSummary({
    super.key,
    required this.totalProjects,
    required this.activeProjects,
    required this.attentionProjects,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);

    final parts = <_Stat>[
      _Stat(value: totalProjects, label: 'projects', color: textColor),
      _Stat(
        value: activeProjects,
        label: 'active',
        color: const Color(0xFF06B6D4),
      ),
      if (attentionProjects > 0)
        _Stat(
          value: attentionProjects,
          label: attentionProjects == 1 ? 'needs attention' : 'need attention',
          color: const Color(0xFFEF4444),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            _StatChip(stat: parts[i], captionColor: captionColor),
            if (i < parts.length - 1)
              Text(
                '·',
                style: TextStyle(
                  color: captionColor.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Stat {
  final int value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});
}

class _StatChip extends StatelessWidget {
  final _Stat stat;
  final Color captionColor;

  const _StatChip({required this.stat, required this.captionColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${stat.value}',
          style: TextStyle(
            color: stat.color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          stat.label,
          style: TextStyle(
            color: captionColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
