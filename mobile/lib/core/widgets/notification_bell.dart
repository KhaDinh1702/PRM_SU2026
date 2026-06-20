import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/notifications/providers/notification_provider.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../services/theme_service.dart';

/// Bell icon with unread-count badge, shared across the Dashboard, Tasks
/// and Projects top headers so the inbox is always one tap away.
///
/// Pulls live unread count from [NotificationProvider] (no extra network
/// call — the provider's existing state drives the badge). Tapping pushes
/// the full [NotificationsScreen].
class NotificationBell extends StatelessWidget {
  /// Tint of the bell icon. Each main screen passes its accent so the bell
  /// blends with the surrounding header.
  final Color? iconColor;

  /// Optional override. When null we just push [NotificationsScreen].
  final VoidCallback? onTap;

  const NotificationBell({super.key, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final defaultColor = ThemeService.getSubTextColor(isDark);

    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final unread = provider.unreadCount;
        return Tooltip(
          message: unread == 0 ? 'Notifications' : '$unread unread',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () => _openNotifications(context),
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: iconColor ?? defaultColor,
                      size: 24,
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 6,
                        top: 8,
                        child: _Badge(count: unread),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _openNotifications(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    // Returning silently refreshes the badge in case the user marked items
    // as read inside the inbox screen.
    if (context.mounted) {
      context.read<NotificationProvider>().loadNotifications(silent: true);
    }
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final ringColor =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
    final label = count > 9 ? '9+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ringColor, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    );
  }
}
