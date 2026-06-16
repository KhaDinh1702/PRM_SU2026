import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';

class TimeAdjuster extends StatelessWidget {
  final bool isRunning;
  final int totalSeconds;
  final Color themeColor;
  final Function(int deltaMinutes) onAdjust;
  final VoidCallback onTimeTap;

  const TimeAdjuster({
    super.key,
    required this.isRunning,
    required this.totalSeconds,
    required this.themeColor,
    required this.onAdjust,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return AnimatedOpacity(
      opacity: isRunning ? 0.3 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: isRunning,
        child: Column(
          children: [
            Text(
              LocaleService.tr('ĐIỀU CHỈNH THỜI GIAN', en: 'ADJUST TIME'),
              style: TextStyle(
                color: captionColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAdjustButton(
                  icon: Icons.remove,
                  onPressed: () => onAdjust(-1),
                  themeColor: themeColor,
                  isDark: isDark,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    textBaseline: TextBaseline.alphabetic,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    children: [
                      GestureDetector(
                        onTap: onTimeTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05)),
                          ),
                          child: Text(
                            '${totalSeconds ~/ 60}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'phút',
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAdjustButton(
                  icon: Icons.add,
                  onPressed: () => onAdjust(1),
                  themeColor: themeColor,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color themeColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black87,
          size: 18,
        ),
      ),
    );
  }
}
