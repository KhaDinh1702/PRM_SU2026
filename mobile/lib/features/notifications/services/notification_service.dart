import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';
import '../models/notification_model.dart';

/// Service xử lý tất cả API calls liên quan đến Notifications.
class NotificationService {
  const NotificationService();

  /// Lấy danh sách thông báo
  Future<List<NotificationModel>> getNotifications() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${AuthService.apiBaseUrl}/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Không thể tải thông báo');
    }

    final List<dynamic> rawList = jsonDecode(response.body);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  /// Đánh dấu một thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    final token = await AuthService.getToken();
    await http.put(
      Uri.parse('${AuthService.apiBaseUrl}/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));
    // Âm thầm fail — thử lại ở lần refresh tiếp theo
  }

  /// Tạo thông báo mới (từ event reminder)
  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    required String token,
  }) async {
    await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/notifications'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'title': title,
            'message': message,
            'type': type == 'meeting' ? 'meeting' : 'task',
          }),
        )
        .timeout(const Duration(seconds: 10));
  }

  /// Phản hồi lời mời tham gia project
  Future<NotificationModel> respondToInvitation({
    required String projectId,
    required String notificationId,
    required String action, // 'accept' hoặc 'reject'
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse(
              '${AuthService.apiBaseUrl}/projects/$projectId/invitations/$notificationId/respond'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'action': action}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Không thể phản hồi lời mời');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return NotificationModel.fromJson(
        data['notification'] as Map<String, dynamic>);
  }
}
