import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';
import 'timer_painter.dart';

class TimerDisplay extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final AnimationController countdownController;
  final Color themeColor;
  final String treeEmoji;
  final String timeStr;
  final bool isRunning;
  final VoidCallback? onTimeTap;

  const TimerDisplay({
    super.key,
    required this.pulseAnimation,
    required this.countdownController,
    required this.themeColor,
    required this.treeEmoji,
    required this.timeStr,
    required this.isRunning,
    this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);

    return ScaleTransition(
      scale: pulseAnimation,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner Glow Accent
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.08),
                    blurRadius: 40,
                    spreadRadius: 15,
                  ),
                ],
              ),
            ),

            SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: countdownController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: TimerPainter(
                      progress: countdownController.value,
                      baseColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      progressColor: themeColor,
                    ),
                  );
                },
              ),
            ),

            // Inside text content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  treeEmoji,
                  style: const TextStyle(fontSize: 42),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: isRunning ? null : onTimeTap,
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 1.5,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isRunning
                      ? LocaleService.tr('TIẾN TRÌNH', en: 'IN PROGRESS')
                      : LocaleService.tr('TẠM DỪNG', en: 'PAUSED'),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: themeColor.withValues(alpha: 0.9),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
