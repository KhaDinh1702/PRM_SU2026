import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';

class TimerHeader extends StatelessWidget {
  final String userEmail;
  final String currentMode;
  final Color themeColor;
  final VoidCallback onForestPressed;

  const TimerHeader({
    super.key,
    required this.userEmail,
    required this.currentMode,
    required this.themeColor,
    required this.onForestPressed,
  });

  String _localizedModeLabel(String mode) {
    switch (mode) {
      case 'Focus':
        return LocaleService.tr('Tập trung', en: 'Focus');
      case 'Short Break':
        return LocaleService.tr('Nghỉ ngắn', en: 'Short Break');
      case 'Long Break':
        return LocaleService.tr('Nghỉ dài', en: 'Long Break');
      case 'Custom':
        return LocaleService.tr('Tuỳ chỉnh', en: 'Custom');
      default:
        return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userEmail.isNotEmpty
                    ? '${LocaleService.tr('CHÀO ÔNG CHỦ: ', en: 'HELLO BOSS: ')}${userEmail.split('@')[0].toUpperCase()}'
                    : 'PREMIUM',
                style: TextStyle(
                  color: captionColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'FlowMate',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.forest_rounded,
                  color: Color(0xFF10B981), size: 24),
              onPressed: onForestPressed,
              tooltip: LocaleService.tr('Khu rừng của tôi', en: 'My Forest'),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: themeColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _localizedModeLabel(currentMode).toUpperCase(),
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
