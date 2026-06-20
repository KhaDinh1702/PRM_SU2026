import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_scaffold_background.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../utils/notification_deep_link.dart';
import '../widgets/notification_day_header.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_filter_chips.dart';
import '../widgets/notification_invitation_card.dart';
import '../widgets/notification_list_tile.dart';

/// Notifications screen.
///
/// Provides a back button, SafeArea, filter chips, day-grouped list and
/// swipe-to-mark-read for unread notifications. Invitations always render
/// with their dedicated Accept/Reject card.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().loadNotifications();
      }
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await context.read<NotificationProvider>().loadNotifications();
  }

  Future<void> _markAllAsRead(List<NotificationModel> notifications) async {
    final provider = context.read<NotificationProvider>();
    final unread = notifications
        .where((n) => !n.isRead && n.type != NotificationType.invitation)
        .toList();
    for (final n in unread) {
      await provider.markAsRead(n.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleService.tr(
            'Đã đánh dấu tất cả là đã đọc.',
            en: 'Marked everything as read.',
          )),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _respondToInvitation(
    NotificationModel invite,
    String action,
  ) async {
    final provider = context.read<NotificationProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await provider.respondToInvitation(
      projectId: invite.invitationProjectId,
      notificationId: invite.id,
      action: action,
    );
    if (!mounted) return;
    if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(action == 'accept'
              ? LocaleService.tr('Đã chấp nhận lời mời!',
                  en: 'Invitation accepted!')
              : LocaleService.tr('Đã từ chối lời mời.',
                  en: 'Invitation declined.')),
          backgroundColor:
              action == 'accept' ? const Color(0xFF10B981) : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              LocaleService.tr('Có lỗi xảy ra', en: 'Something went wrong')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<NotificationModel> _applyFilter(List<NotificationModel> source) {
    switch (_filter) {
      case NotificationFilter.all:
        return source;
      case NotificationFilter.unread:
        return source.where((n) => !n.isRead).toList();
      case NotificationFilter.invitations:
        return source.where((n) => n.isPendingInvitation).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [ThemeService.isDarkMode, LocaleService.languageCode]),
      builder: (context, _) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final primary = ThemeService.getPrimaryColor(isDark);

        return Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            final all = provider.notifications;
            final filtered = _applyFilter(all);
            final unreadCount = provider.unreadCount;
            final invitationsCount = provider.pendingInvitations.length;

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: AppScaffoldBackground(
                child: SafeArea(
                  child: Column(
                    children: [
                      _Header(
                        title:
                            LocaleService.tr('Thông báo', en: 'Notifications'),
                        textColor: textColor,
                        primary: primary,
                        showMarkAll: unreadCount > 0,
                        onMarkAll: () => _markAllAsRead(all),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 4, bottom: 10),
                        child: NotificationFilterChips(
                          selected: _filter,
                          onChanged: (next) => setState(() => _filter = next),
                          unreadCount: unreadCount,
                          invitationsCount: invitationsCount,
                        ),
                      ),
                      Expanded(
                        child: _buildBody(
                          provider: provider,
                          filtered: filtered,
                          primary: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody({
    required NotificationProvider provider,
    required List<NotificationModel> filtered,
    required Color primary,
  }) {
    if (provider.isLoading && filtered.isEmpty) {
      return Center(child: CircularProgressIndicator(color: primary));
    }
    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          children: [
            const SizedBox(height: 40),
            NotificationEmptyState(filter: _filter),
          ],
        ),
      );
    }

    final groups = _groupByDay(filtered);
    return RefreshIndicator(
      onRefresh: _refresh,
      color: primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationDayHeader(label: group.label),
              for (final notification in group.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: notification.isPendingInvitation
                      ? NotificationInvitationCard(
                          invite: notification,
                          onRespond: (action) =>
                              _respondToInvitation(notification, action),
                        )
                      : NotificationListTile(
                          notification: notification,
                          onTap: () => NotificationDeepLink.open(
                              context, notification),
                          onMarkRead: () => context
                              .read<NotificationProvider>()
                              .markAsRead(notification.id),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Groups notifications into Today / Yesterday / Earlier this week / Older.
  List<_DayGroup> _groupByDay(List<NotificationModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <String, List<NotificationModel>>{
      _GroupKey.today: [],
      _GroupKey.yesterday: [],
      _GroupKey.thisWeek: [],
      _GroupKey.older: [],
    };

    for (final n in items) {
      final created = n.createdAt;
      if (created == null) {
        groups[_GroupKey.older]!.add(n);
        continue;
      }
      final createdDay =
          DateTime(created.year, created.month, created.day);
      final diff = today.difference(createdDay).inDays;
      if (diff <= 0) {
        groups[_GroupKey.today]!.add(n);
      } else if (diff == 1) {
        groups[_GroupKey.yesterday]!.add(n);
      } else if (diff < 7) {
        groups[_GroupKey.thisWeek]!.add(n);
      } else {
        groups[_GroupKey.older]!.add(n);
      }
    }

    return [
      if (groups[_GroupKey.today]!.isNotEmpty)
        _DayGroup(
          label: LocaleService.tr('HÔM NAY', en: 'TODAY'),
          items: groups[_GroupKey.today]!,
        ),
      if (groups[_GroupKey.yesterday]!.isNotEmpty)
        _DayGroup(
          label: LocaleService.tr('HÔM QUA', en: 'YESTERDAY'),
          items: groups[_GroupKey.yesterday]!,
        ),
      if (groups[_GroupKey.thisWeek]!.isNotEmpty)
        _DayGroup(
          label: LocaleService.tr('TUẦN NÀY', en: 'EARLIER THIS WEEK'),
          items: groups[_GroupKey.thisWeek]!,
        ),
      if (groups[_GroupKey.older]!.isNotEmpty)
        _DayGroup(
          label: LocaleService.tr('CŨ HƠN', en: 'OLDER'),
          items: groups[_GroupKey.older]!,
        ),
    ];
  }
}

class _DayGroup {
  final String label;
  final List<NotificationModel> items;
  const _DayGroup({required this.label, required this.items});
}

/// Custom header row used in place of Scaffold.appBar so the gradient
/// background (from [AppScaffoldBackground]) extends all the way to the top
/// of the screen instead of leaving a transparent AppBar area that exposes
/// the device's default black background.
class _Header extends StatelessWidget {
  final String title;
  final Color textColor;
  final Color primary;
  final bool showMarkAll;
  final VoidCallback onMarkAll;

  const _Header({
    required this.title,
    required this.textColor,
    required this.primary,
    required this.showMarkAll,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (showMarkAll)
            TextButton.icon(
              onPressed: onMarkAll,
              icon: Icon(Icons.done_all_rounded, size: 18, color: primary),
              label: Text(
                LocaleService.tr('Đọc hết', en: 'Mark all'),
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupKey {
  static const today = 'today';
  static const yesterday = 'yesterday';
  static const thisWeek = 'this_week';
  static const older = 'older';
}
