import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';

/// Service xử lý API calls liên quan đến Timer/Session (Pomodoro).
class TimerService {
  const TimerService();

  /// Đồng bộ phiên làm việc đã hoàn thành lên backend
  Future<void> syncSession({
    required String mode,
    required int durationSeconds,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/sessions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'mode': mode,
            'durationSeconds': durationSeconds,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception('Không thể đồng bộ phiên làm việc');
    }
  }
}
