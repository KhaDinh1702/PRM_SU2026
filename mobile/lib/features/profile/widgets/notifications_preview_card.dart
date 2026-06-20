import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/utils/notification_deep_link.dart';

/// Preview card surfacing the 3 latest unread notifications inline.
///
/// Each row is tappable and routes to the right destination via
/// [NotificationDeepLink]. The card itself (and the "View all" footer) push
/// the full inbox.
class NotificationsPreviewCard extends StatelessWidget {
  static const int maxItems = 3;

  const NotificationsPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final cardBg = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    const accent = Color(0xFFF59E0B);

    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final unread =
            provider.notifications.where((n) => !n.isRead).toList(growable: false);
        final preview = unread.take(maxItems).toList();
        final remaining = unread.length - preview.length;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openInbox(context),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    accent: accent,
                    unreadCount: unread.length,
                  ),
                  const SizedBox(height: 10),
                  if (provider.isLoading && unread.isEmpty)
                    const _Skeleton()
                  else if (unread.isEmpty)
                    const _EmptyState()
                  else ...[
                    for (final item in preview)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _NotificationRow(notification: item),
                      ),
                    if (remaining > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 4),
                        child: Text(
                          LocaleService.tr(
                            '+ $remaining thông báo chưa đọc',
                            en: '+$remaining more unread',
                          ),
                          style: const TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openInbox(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (context.mounted) {
      // Refresh badge after returning.
      context.read<NotificationProvider>().loadNotifications(silent: true);
    }
  }
}

class _Header extends StatelessWidget {
  final Color accent;
  final int unreadCount;

  const _Header({required this.accent, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.notifications_active_outlined,
              color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleService.tr('Thông báo', en: 'Notifications'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                unreadCount == 0
                    ? LocaleService.tr('Tất cả đã đọc', en: 'All caught up')
                    : LocaleService.tr(
                        '$unreadCount chưa đọc',
                        en: '$unreadCount unread',
                      ),
                style: TextStyle(color: captionColor, fontSize: 11),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: captionColor, size: 20),
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationRow({required this.notification});

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return InkWell(
      onTap: () => NotificationDeepLink.open(context, notification),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: notification.typeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification.typeIcon,
                size: 14,
                color: notification.typeColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title.isEmpty
                        ? notification.typeLabel
                        : notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (notification.message.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      notification.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: captionColor, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _timeAgo(notification.createdAt),
              style: TextStyle(
                color: captionColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final subTextColor = ThemeService.getSubTextColor(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            LocaleService.tr('Bạn đã đọc hết!', en: 'All caught up.'),
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final shimmer = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
