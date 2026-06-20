import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import 'notification_filter_chips.dart';

/// Empty state shown when the filtered notification list is empty.
class NotificationEmptyState extends StatelessWidget {
  final NotificationFilter filter;

  const NotificationEmptyState({super.key, required this.filter});

  ({String emoji, String title, String subtitle}) _content() {
    switch (filter) {
      case NotificationFilter.all:
        return (
          emoji: '🎉',
          title: LocaleService.tr(
            'Tất cả đã đọc',
            en: 'All caught up',
          ),
          subtitle: LocaleService.tr(
            'Chưa có thông báo nào. Tận hưởng sự tập trung.',
            en: 'No notifications yet. Enjoy the focus.',
          ),
        );
      case NotificationFilter.unread:
        return (
          emoji: '✅',
          title: LocaleService.tr(
            'Không còn gì chưa đọc',
            en: 'Nothing unread',
          ),
          subtitle: LocaleService.tr(
            'Bạn đã đọc xong mọi thông báo.',
            en: 'You\'re fully up to date.',
          ),
        );
      case NotificationFilter.invitations:
        return (
          emoji: '💌',
          title: LocaleService.tr(
            'Không có lời mời',
            en: 'No invitations',
          ),
          subtitle: LocaleService.tr(
            'Lời mời tham gia dự án sẽ xuất hiện ở đây.',
            en: 'Project invites will show up here.',
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final content = _content();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(content.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
