import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

/// Filter buckets on the Notifications screen.
enum NotificationFilter { all, unread, invitations }

extension NotificationFilterX on NotificationFilter {
  String get label {
    switch (this) {
      case NotificationFilter.all:
        return LocaleService.tr('Tất cả', en: 'All');
      case NotificationFilter.unread:
        return LocaleService.tr('Chưa đọc', en: 'Unread');
      case NotificationFilter.invitations:
        return LocaleService.tr('Lời mời', en: 'Invites');
    }
  }
}

/// Horizontal row of filter chips with optional badge counters.
class NotificationFilterChips extends StatelessWidget {
  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onChanged;
  final int unreadCount;
  final int invitationsCount;

  const NotificationFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.unreadCount,
    required this.invitationsCount,
  });

  int _badgeFor(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.all:
        return 0;
      case NotificationFilter.unread:
        return unreadCount;
      case NotificationFilter.invitations:
        return invitationsCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (var i = 0; i < NotificationFilter.values.length; i++) ...[
            _Chip(
              filter: NotificationFilter.values[i],
              isSelected: NotificationFilter.values[i] == selected,
              badge: _badgeFor(NotificationFilter.values[i]),
              onTap: () => onChanged(NotificationFilter.values[i]),
            ),
            if (i < NotificationFilter.values.length - 1)
              const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final NotificationFilter filter;
  final bool isSelected;
  final int badge;
  final VoidCallback onTap;

  const _Chip({
    required this.filter,
    required this.isSelected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    const accent = Color(0xFFF59E0B);
    final captionColor = ThemeService.getCaptionColor(isDark);

    final fg = isSelected ? Colors.white : captionColor;
    final bg = isSelected
        ? accent
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04));
    final border = isSelected
        ? accent
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filter.label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: TextStyle(
                      color: isSelected ? Colors.white : accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
