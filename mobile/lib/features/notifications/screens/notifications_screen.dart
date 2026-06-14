import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../features/notifications/models/notification_model.dart';
import '../../../features/notifications/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  static final ValueNotifier<int> refreshTrigger = ValueNotifier(0);
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final _notificationService = const NotificationService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    NotificationsScreen.refreshTrigger.addListener(_onGlobalRefresh);
    _loadNotifications();
  }

  void _onGlobalRefresh() {
    if (mounted) {
      _loadNotifications();
    }
  }

  @override
  void dispose() {
    NotificationsScreen.refreshTrigger.removeListener(_onGlobalRefresh);
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Gọi qua NotificationService — không http trực tiếp trong widget
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    // Gọi service, cập nhật local state ngay không cần reload
    await _notificationService.markAsRead(notificationId);
    if (mounted) {
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notificationId);
        if (idx != -1) {
          _notifications[idx] = _notifications[idx].copyWithRead();
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    // Mark all unread (except invitations) as read
    final unread = _notifications
        .where((n) => !n.isRead && n.type != NotificationType.invitation)
        .toList();
    for (final n in unread) {
      await _markAsRead(n.id);
    }
  }

  Future<void> _respondToInvitation(
      String projectId, String notificationId, String action) async {
    try {
      // Gọi qua NotificationService — không http trực tiếp trong widget
      final updatedNotification =
          await _notificationService.respondToInvitation(
        projectId: projectId,
        notificationId: notificationId,
        action: action,
      );
      if (mounted) {
        setState(() {
          final idx =
              _notifications.indexWhere((n) => n.id == notificationId);
          if (idx != -1) {
            _notifications[idx] = updatedNotification;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept'
                ? LocaleService.tr('Đã chấp nhận lời mời!',
                    en: 'Invitation accepted!')
                : LocaleService.tr('Đã từ chối lời mời.',
                    en: 'Invitation rejected.')),
            backgroundColor:
                action == 'accept' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  LocaleService.tr('Có lỗi xảy ra', en: 'An error occurred'))),
        );
      }
    }
  }

  // --- UI Helpers --- (giờ dùng model getters thay vì switch thô)

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) {
      return LocaleService.tr('Vừa xong', en: 'Just now');
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${LocaleService.tr('phút trước', en: 'mins ago')}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ${LocaleService.tr('giờ trước', en: 'hours ago')}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ${LocaleService.tr('ngày trước', en: 'days ago')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFF59E0B); // Amber for Notifications

    return ListenableBuilder(
      listenable: Listenable.merge(
          [ThemeService.isDarkMode, LocaleService.languageCode]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);

        final unreadCount =
            _notifications.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: _loadNotifications,
            color: themeColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // --- Header ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: FadeInSlide(
                      delayMs: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                              LocaleService.tr('THÔNG BÁO',
                                    en: 'NOTIFICATIONS'),
                                style: TextStyle(
                                  color: captionColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Notifications',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (unreadCount > 0) ...[
                                    const SizedBox(width: 10),
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: themeColor.withOpacity(0.12 +
                                                _pulseController.value * 0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  themeColor.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
        '${unreadCount} ${LocaleService.tr('mới', en: 'new')}',
                                            style: TextStyle(
                                              color: themeColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (unreadCount > 0)
                            GestureDetector(
                              onTap: _markAllAsRead,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: themeColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.done_all_rounded,
                                        color: themeColor, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      LocaleService.tr('Đọc tất cả',
                                          en: 'Mark all as read'),
                                      style: TextStyle(
                                        color: themeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  if (_notifications.any((n) => n.isPendingInvitation))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleService.tr('Lời mời dự án',
                                en: 'Project Invitations'),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._notifications
                              .where((n) => n.isPendingInvitation)
                              .map((invite) =>
                                  _buildInvitationCard(invite, isDark)),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                // --- Content ---
                if (_isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: List.generate(
                            5,
                            (i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ShimmerLoading(
                                      width: double.infinity,
                                      height: 100,
                                      borderRadius: 20),
                                )),
                      ),
                    ),
                  )
                else if (_notifications.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: FadeInSlide(
                        delayMs: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_off_rounded,
                                color: themeColor.withOpacity(0.5),
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              LocaleService.tr('You are all caught up!',
                                  en: 'You are all caught up!'),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              LocaleService.tr(
                                  'Không có thông báo nào. Hãy quay lại sau!',
                                  en: 'No notifications. Check back later!'),
                              style: TextStyle(
                                color: captionColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notification = _notifications
                              .where((n) => !n.isPendingInvitation)
                              .toList()[index];
                          return FadeInSlide(
                            delayMs: 80 * index,
                            child: _buildNotificationCard(notification, isDark),
                          );
                        },
                        childCount: _notifications
                            .where((n) => !n.isPendingInvitation)
                            .length,
                      ),
                    ),
                  ),

                // Bottom padding for navbar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(
      NotificationModel notification, bool isDark) {
    final isRead = notification.isRead;
    // Dùng getter từ model thay vì switch thủ công
    final color = notification.typeColor;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          if (!isRead) _markAsRead(notification.id);
        },
        child: GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          boxShadow: isRead
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(isDark ? 0.08 : 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isRead ? 0.06 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withOpacity(isRead ? 0.08 : 0.2),
                  ),
                ),
                child: Icon(
                  notification.typeIcon,
                  color: color.withOpacity(isRead ? 0.5 : 1.0),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notification.typeLabel,
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.title.isNotEmpty
                          ? notification.title
                          : LocaleService.tr('Thông báo', en: 'Notification'),
                      style: TextStyle(
                        color: isRead ? subTextColor : textColor,
                        fontSize: 14,
                        fontWeight:
                            isRead ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: isRead ? captionColor : subTextColor,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(
    NotificationModel invite,
    bool isDark,
  ) {
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    // Dùng getter từ model thay vì map['field'] thủ công
    final projectName = invite.invitationProjectName;
    final senderName = invite.senderName;
    final projectId = invite.invitationProjectId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectName,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocaleService.tr(
                          '$senderName đã mời bạn tham gia dự án',
                          en: '$senderName invited you to join the project',
                        ),
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PremiumButton.icon(
                    onPressed: projectId.isEmpty
                        ? null
                        : () => _respondToInvitation(
                            projectId, invite.id, 'accept'),
                    icon: Icons.check,
                    label: LocaleService.tr('Chấp nhận', en: 'Accept'),
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PremiumButton.icon(
                    onPressed: projectId.isEmpty
                        ? null
                        : () => _respondToInvitation(
                            projectId, invite.id, 'reject'),
                    icon: Icons.close,
                    label: LocaleService.tr('Từ chối', en: 'Reject'),
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
