import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

class DashboardGreetingHeader extends StatelessWidget {
  final String userName;
  final int productivityScore;

  const DashboardGreetingHeader({
    super.key,
    required this.userName,
    this.productivityScore = 0,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return LocaleService.tr('Chào buổi sáng', en: 'Good Morning');
    }
    if (hour < 17) {
      return LocaleService.tr('Chào buổi chiều', en: 'Good Afternoon');
    }
    return LocaleService.tr('Chào buổi tối', en: 'Good Evening');
  }

  String _subtitle(int score) {
    if (score >= 80) {
      return LocaleService.tr(
        'Bạn đang làm rất tốt — giữ vững nhịp độ nhé!',
        en: 'You are on fire — keep the momentum going!',
      );
    }
    if (score >= 50) {
      return LocaleService.tr(
        'Tiến bộ ổn định. Hoàn thành thêm vài việc nhé.',
        en: 'Steady progress. Knock out a few more tasks.',
      );
    }
    return LocaleService.tr(
      'Một ngày mới, một cơ hội mới để tập trung.',
      en: 'Fresh day, fresh focus — start with one win.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final primary = ThemeService.getPrimaryColor(isDark);
    final now = DateTime.now();
    final dateText = DateFormat(
      LocaleService.languageCode.value == 'en'
          ? 'EEEE, MMMM d'
          : 'EEEE, d MMMM',
      LocaleService.languageCode.value,
    ).format(now);

    final displayName = userName.isNotEmpty ? userName : 'FlowMate';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateText,
          style: TextStyle(
            color: captionColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
            children: [
              TextSpan(text: '${_greeting()},\n'),
              TextSpan(
                text: displayName,
                style: TextStyle(color: primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _subtitle(productivityScore),
          style: TextStyle(
            color: subTextColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
