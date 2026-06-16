import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';

class TimerActionButtons extends StatelessWidget {
  final bool isRunning;
  final Color themeColor;
  final VoidCallback onPlayPause;
  final VoidCallback onReset;
  final VoidCallback onRestore;

  const TimerActionButtons({
    super.key,
    required this.isRunning,
    required this.themeColor,
    required this.onPlayPause,
    required this.onReset,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button
        _buildSecondaryButton(
          icon: Icons.replay,
          onTap: onReset,
          bgColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          isDark: isDark,
        ),

        const SizedBox(width: 24),

        // Play / Pause Button with Premium Gradient Glow
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isRunning
                    ? [const Color(0xFFF43F5E), const Color(0xFFBE123C)]
                    : [themeColor, themeColor.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isRunning ? const Color(0xFFF43F5E) : themeColor)
                      .withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Preset restore
        _buildSecondaryButton(
          icon: Icons.settings_backup_restore,
          onTap: onRestore,
          bgColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color bgColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black87,
          size: 20,
        ),
      ),
    );
  }
}
