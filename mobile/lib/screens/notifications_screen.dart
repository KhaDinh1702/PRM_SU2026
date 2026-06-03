import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../widgets/premium_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  static final ValueNotifier<int> refreshTrigger = ValueNotifier(0);
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'https://prm-tan.vercel.app/api';
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
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
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _notifications = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            final idx = _notifications.indexWhere((n) => n['_id'] == notificationId);
            if (idx != -1) {
              _notifications[idx]['isRead'] = true;
            }
          });
        }
      }
    } catch (_) {
      // Silently fail — we can retry on next refresh
    }
  }

  Future<void> _markAllAsRead() async {
    final unread = _notifications.where((n) => n['isRead'] != true && n['type'] != 'invitation').toList();
    for (final n in unread) {
      await _markAsRead(n['_id']);
    }
  }

  Future<void> _respondToInvitation(String projectId, String notificationId, String action) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/projects/$projectId/invitations/$notificationId/respond'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            final idx = _notifications.indexWhere((n) => n['_id'] == notificationId);
            if (idx != -1) {
              _notifications[idx] = data['notification'];
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(action == 'accept'
                  ? LocaleService.tr('Đã chấp nhận lời mời! 🎉', en: 'Invitation accepted! 🎉')
                  : LocaleService.tr('Đã từ chối lời mời.', en: 'Invitation rejected.')),
              backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleService.tr('Có lỗi xảy ra', en: 'An error occurred'))),
        );
      }
    }
  }

  // --- UI Helpers ---

  IconData _iconForType(String? type) {
    switch (type) {
      case 'task':
        return Icons.task_alt_rounded;
      case 'meeting':
        return Icons.videocam_rounded;
      case 'project':
        return Icons.dns_rounded;
      case 'invitation':
        return Icons.group_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'task':
        return const Color(0xFF10B981); // Emerald
      case 'meeting':
        return const Color(0xFFF43F5E); // Rose
      case 'project':
        return const Color(0xFF06B6D4); // Cyan
      case 'invitation':
        return Colors.blue;
      default:
        return const Color(0xFF8B5CF6); // Violet
    }
  }

  String _labelForType(String? type) {
    switch (type) {
      case 'task':
        return LocaleService.tr('Công việc', en: 'Task');
      case 'meeting':
        return LocaleService.tr('Cuộc họp', en: 'Meeting');
      case 'project':
        return LocaleService.tr('Dự án', en: 'Project');
      case 'invitation':
        return LocaleService.tr('Lời mời', en: 'Invite');
      default:
        return LocaleService.tr('Hệ thống', en: 'System');
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return LocaleService.tr('Vừa xong', en: 'Just now');
      if (diff.inMinutes < 60) return '${diff.inMinutes} ${LocaleService.tr('phút trước', en: 'mins ago')}';
      if (diff.inHours < 24) return '${diff.inHours} ${LocaleService.tr('giờ trước', en: 'hours ago')}';
      if (diff.inDays < 7) return '${diff.inDays} ${LocaleService.tr('ngày trước', en: 'days ago')}';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFF59E0B); // Amber for Notifications

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
        final textColor = ThemeService.getTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);

        final unreadCount = _notifications.where((n) => n['isRead'] != true).length;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: _loadNotifications,
            color: themeColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                                LocaleService.tr('THÔNG BÁO', en: 'NOTIFICATIONS'),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: themeColor.withOpacity(0.12 + _pulseController.value * 0.08),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: themeColor.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            '$unreadCount ${LocaleService.tr('mới', en: 'new')}',
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                    Icon(Icons.done_all_rounded, color: themeColor, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      LocaleService.tr('Đọc tất cả', en: 'Mark all as read'),
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

                if (_notifications.any((n) => n['type'] == 'invitation' && n['invitationStatus'] == 'pending'))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleService.tr('Lời mời dự án', en: 'Project Invitations'),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._notifications
                              .where((n) => n['type'] == 'invitation' && n['invitationStatus'] == 'pending')
                              .map((invite) => _buildInvitationCard(invite, isDark)),
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
                        children: List.generate(5, (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ShimmerLoading(width: double.infinity, height: 100, borderRadius: 20),
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
                              LocaleService.tr('You are all caught up! 🎉', en: 'You are all caught up! 🎉'),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              LocaleService.tr('Không có thông báo nào. Hãy quay lại sau!', en: 'No notifications. Check back later!'),
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
                          final notification = _notifications.where((n) => n['type'] != 'invitation' || n['invitationStatus'] != 'pending').toList()[index];
                          return FadeInSlide(
                            delayMs: 80 * index,
                            child: _buildNotificationCard(notification, isDark),
                          );
                        },
                        childCount: _notifications.where((n) => n['type'] != 'invitation' || n['invitationStatus'] != 'pending').length,
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

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isDark) {
    final isRead = notification['isRead'] == true;
    final type = notification['type'] as String?;
    final color = _colorForType(type);
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['_id']);
          }
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
              // Icon container
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
                  _iconForType(type),
                  color: color.withOpacity(isRead ? 0.5 : 1.0),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Type label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _labelForType(type),
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Unread dot indicator
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
                      notification['title'] ?? LocaleService.tr('Thông báo', en: 'Notification'),
                      style: TextStyle(
                        color: isRead ? subTextColor : textColor,
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'] ?? '',
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
                      _timeAgo(notification['createdAt']),
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
    Map<String, dynamic> invite,
    bool isDark,
  ) {
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final projectName = invite['relatedId'] != null ? invite['relatedId']['name'] : 'Unknown Project';
    final senderName = invite['sender'] != null ? (invite['sender']['name'] ?? invite['sender']['email']) : 'Someone';
    final projectId = invite['relatedId'] != null ? invite['relatedId']['_id'] : '';

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
                  child: ElevatedButton.icon(
                    onPressed: projectId.isEmpty ? null : () => _respondToInvitation(projectId, invite['_id'], 'accept'),
                    icon: const Icon(Icons.check),
                    label: Text(LocaleService.tr('Chấp nhận', en: 'Accept')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: projectId.isEmpty ? null : () => _respondToInvitation(projectId, invite['_id'], 'reject'),
                    icon: const Icon(Icons.close),
                    label: Text(LocaleService.tr('Từ chối', en: 'Reject')),
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
