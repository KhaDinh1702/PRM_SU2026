import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

/// One-line summary that introduces the Today timeline:
/// "3 tasks · 2 meetings · 45m focus".
class DashboardTodaySummary extends StatelessWidget {
  final int taskCount;
  final int meetingCount;
  final int focusMinutes;

  const DashboardTodaySummary({
    super.key,
    required this.taskCount,
    required this.meetingCount,
    required this.focusMinutes,
  });

  String _tasksLabel() => taskCount == 1
      ? LocaleService.tr('1 nhiệm vụ', en: '1 task')
      : LocaleService.tr('$taskCount nhiệm vụ', en: '$taskCount tasks');

  String _meetingsLabel() => meetingCount == 1
      ? LocaleService.tr('1 cuộc họp', en: '1 meeting')
      : LocaleService.tr('$meetingCount cuộc họp', en: '$meetingCount meetings');

  String _focusLabel() {
    if (focusMinutes <= 0) {
      return LocaleService.tr('chưa focus', en: 'no focus yet');
    }
    if (focusMinutes < 60) {
      return LocaleService.tr('${focusMinutes}p focus', en: '${focusMinutes}m focus');
    }
    final hours = focusMinutes ~/ 60;
    final minutes = focusMinutes % 60;
    if (minutes == 0) {
      return LocaleService.tr('${hours}h focus', en: '${hours}h focus');
    }
    return LocaleService.tr('${hours}h ${minutes}p focus',
        en: '${hours}h ${minutes}m focus');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Stat(value: '$taskCount', label: _tasksLabel().split(' ').sublist(1).join(' ')),
        _Dot(color: captionColor),
        _Stat(value: '$meetingCount', label: _meetingsLabel().split(' ').sublist(1).join(' ')),
        _Dot(color: captionColor),
        Text(
          _focusLabel(),
          style: TextStyle(
            color: textColor.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: TextStyle(
              color: captionColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      '·',
      style: TextStyle(
        color: color.withValues(alpha: 0.5),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
