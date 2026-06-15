import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../core/constants/app_durations.dart';

/// Data class chứa thông tin notification cần hiển thị.
class EventNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String token;

  const EventNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.token,
  });
}

/// Service kiểm tra sự kiện lịch sắp diễn ra và kích hoạt thông báo.
///
/// Tách hoàn toàn khỏi UI — caller (main.dart) chịu trách nhiệm hiển thị dialog.
/// Service chỉ lo: gọi API, filter event, format message, lưu backend notification.
class EventCheckService {
  /// Tập hợp các event ID đã được thông báo trong phiên hiện tại.
  /// Tránh thông báo trùng khi timer chạy định kỳ.
  final Set<String> _notifiedEventIds = {};

  /// Kiểm tra các sự kiện sắp diễn ra từ calendar API.
  ///
  /// Trả về danh sách [EventNotification] cần hiển thị cho người dùng.
  /// Caller quyết định cách hiển thị (dialog, push notification...).
  Future<List<EventNotification>> checkEvents() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) return [];

    try {
      final token = await AuthService.getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${AuthService.apiBaseUrl}/calendar/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode != 200) return [];

      final List<dynamic> events = jsonDecode(response.body);
      final now = DateTime.now();
      final List<EventNotification> toNotify = [];

      for (final event in events) {
        final eventId = event['id'];
        final source = event['source'] ?? 'event';
        final startStr = event['start'];
        if (startStr == null || eventId == null) continue;

        // Xây dựng notification ID duy nhất theo source
        final notificationId = source == 'task'
            ? 'task:$eventId:${event['reminderType'] ?? 'reminder'}'
            : eventId.toString();

        // Tính thời gian sự kiện
        final eventTime = source == 'task'
            ? DateTime.tryParse(
                    (event['reminderAt'] ?? event['start']).toString())
                ?.toLocal()
            : DateTime.tryParse(startStr)?.toLocal();
        if (eventTime == null) continue;

        // Bỏ qua task đã hoàn thành hoặc tắt notification
        if (source == 'task') {
          if (event['notificationEnabled'] != true ||
              event['status'] == 'Completed') {
            continue;
          }
        }

        // Bỏ qua nếu đã thông báo rồi
        if (_notifiedEventIds.contains(notificationId)) continue;

        // Chỉ thông báo nếu đã đến giờ
        if (!now.isAfter(eventTime)) continue;

        // Bỏ qua nếu sự kiện quá cũ (> 2 tiếng)
        if (now.difference(eventTime).inHours >= 2) {
          _notifiedEventIds.add(notificationId);
          continue;
        }

        // Build notification content
        final rawTitle =
            event['title'] ?? LocaleService.tr('Sự kiện', en: 'Event');
        final rawMessage = event['description'] ??
            LocaleService.tr('Đã đến thời gian diễn ra sự kiện.',
                en: 'It is time for your event.');
        final type =
            source == 'task' ? 'task' : (event['type'] ?? 'reminder');
        final notifTitle =
            source == 'task' ? 'Task Reminder' : rawTitle.toString();
        final notifMessage = source == 'task'
            ? _buildTaskReminderMessage(event)
            : rawMessage.toString();

        _notifiedEventIds.add(notificationId);
        toNotify.add(EventNotification(
          id: notificationId,
          title: notifTitle,
          message: notifMessage,
          type: type.toString(),
          token: token,
        ));
      }

      return toNotify;
    } catch (_) {
      // Lỗi kết nối âm thầm bỏ qua để tránh ảnh hưởng trải nghiệm người dùng
      return [];
    }
  }

  /// Lưu notification lên backend (fire-and-forget).
  Future<void> saveNotificationToBackend(EventNotification notif) async {
    try {
      await http
          .post(
            Uri.parse('${AuthService.apiBaseUrl}/notifications'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${notif.token}',
            },
            body: jsonEncode({
              'title':
                  '${LocaleService.tr('Sự kiện diễn ra:', en: 'Event starting:')} ${notif.title}',
              'message': notif.message.isNotEmpty
                  ? notif.message
                  : LocaleService.tr('Đã đến thời gian diễn ra sự kiện.',
                      en: 'It is time for your event.'),
              'type': notif.type == 'meeting' ? 'meeting' : 'task',
            }),
          )
          .timeout(AppDurations.apiTimeout);
    } catch (_) {
      // fire-and-forget — lỗi bỏ qua
    }
  }

  /// Đặt lại tất cả trạng thái đã thông báo (dùng khi logout).
  void reset() => _notifiedEventIds.clear();

  // --- Private helpers ---

  String _buildTaskReminderMessage(Map<String, dynamic> task) {
    final rawTitle = (task['title'] ?? 'Task').toString();
    final title = rawTitle.replaceFirst('[TASK DEADLINE] ', '');
    final reminderType = (task['reminderType'] ?? '').toString();
    switch (reminderType) {
      case 'at_time':
        return '$title is due now.';
      case '15_min_before':
        return '$title is due in 15 minutes.';
      case '30_min_before':
        return '$title is due in 30 minutes.';
      case '1_hour_before':
        return '$title is due in 1 hour.';
      case '1_day_before':
        return '$title is due tomorrow.';
      default:
        return '$title is due soon.';
    }
  }
}
