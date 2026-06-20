import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/notification_model.dart';

/// Compact tile for non-invitation notifications.
///
/// - Tap fires [onTap] (typically deep-link routing).
/// - Swipe left → mark read via [onMarkRead].
/// - Unread state shows a dot + bolder typography.
class NotificationListTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  const NotificationListTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.onMarkRead,
  });

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return LocaleService.tr('Vừa xong', en: 'now');
    }
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final isRead = notification.isRead;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardBg = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final accent = notification.typeColor;

    final tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? borderColor : accent.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(notification.typeIcon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypePill(
                        label: notification.typeLabel,
                        color: accent,
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(notification.createdAt),
                        style: TextStyle(
                          color: captionColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.title.isEmpty
                        ? notification.typeLabel
                        : notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight:
                          isRead ? FontWeight.w600 : FontWeight.w900,
                    ),
                  ),
                  if (notification.message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isRead || onMarkRead == null) return tile;

    return Dismissible(
      key: ValueKey('notif-${notification.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onMarkRead!();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleService.tr('Đã đọc', en: 'Mark read'),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.done_rounded, color: accent, size: 18),
          ],
        ),
      ),
      child: tile,
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final Color color;

  const _TypePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
