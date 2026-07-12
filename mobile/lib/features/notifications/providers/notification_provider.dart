import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../services/auth_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Enum trạng thái load
enum NotificationLoadStatus { initial, loading, loaded, error }

/// NotificationProvider thay thế:
/// - static ValueNotifier<int> refreshTrigger trong NotificationsScreen
/// - _isLoading, _notifications, _error setState() trong notifications_screen
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  io.Socket? _socket;
  Timer? _pollTimer;

  NotificationProvider({NotificationService? service})
      : _service = service ?? const NotificationService() {
    _initSocket();
    _startRefreshPolling();
    loadNotifications(silent: true);
  }

  List<NotificationModel> _notifications = [];
  NotificationLoadStatus _status = NotificationLoadStatus.initial;
  String? _errorMessage;

  // --- Getters ---
  List<NotificationModel> get notifications => _notifications;
  NotificationLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == NotificationLoadStatus.loading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get pendingInvitations =>
      _notifications.where((n) => n.isPendingInvitation).toList();

  // --- Load danh sách thông báo ---
  Future<void> loadNotifications({bool silent = false}) async {
    if (!silent) {
      _status = NotificationLoadStatus.loading;
      notifyListeners();
    }
    try {
      final list = await _service.getNotifications();
      _notifications = list;
      _status = NotificationLoadStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = NotificationLoadStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> _initSocket() async {
    try {
      final userData = await AuthService.getUserInfo();
      final userId = (userData?['id'] ?? userData?['_id'] ?? '').toString();
      if (userId.isEmpty) return;

      // Build backend base URL (strip trailing /api if present)
      String apiBase = AuthService.apiBaseUrl;
      String baseUrl = apiBase.endsWith('/api') ? apiBase.substring(0, apiBase.length - 4) : apiBase;
      if (baseUrl.contains('vercel.app')) return; // skip sockets on Vercel

      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .build(),
      );

      _socket!.connect();
      _socket!.onConnect((_) {
        _socket!.emit('joinUser', userId);
      });

      _socket!.on('userNotification', (_) {
        triggerRefresh();
      });
      _socket!.on('userNotificationPlain', (_) {
        triggerRefresh();
      });
    } catch (_) {
      // ignore socket setup failures
    }
  }

  void _startRefreshPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadNotifications(silent: true);
    });
  }

  /// Kích hoạt refresh im lặng (thay thế refreshTrigger.value++)
  /// Dùng sau khi EventCheckService phát hiện event mới.
  Future<void> triggerRefresh() => loadNotifications(silent: true);

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  /// Đánh dấu đọc một thông báo, cập nhật local state ngay lập tức
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    // Optimistic update
    _notifications[index] = _notifications[index].copyWithRead();
    notifyListeners();
    // Gửi lên server (fire-and-forget)
    _service.markAsRead(notificationId).catchError((_) {});
  }

  /// Phản hồi lời mời tham gia project
  Future<NotificationModel?> respondToInvitation({
    required String projectId,
    required String notificationId,
    required String action, // 'accept' | 'reject'
  }) async {
    try {
      final updated = await _service.respondToInvitation(
        projectId: projectId,
        notificationId: notificationId,
        action: action,
      );
      // Cập nhật local notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
