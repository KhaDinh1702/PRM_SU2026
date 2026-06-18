import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';
import '../models/analytics_report.dart';

/// Service để tương tác với các API của Analytics
class AnalyticsService {
  const AnalyticsService();

  /// Tải báo cáo năng suất dựa trên range ('day', 'week', 'month')
  Future<AnalyticsReport> getAnalyticsReport(String range) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập');
    }

    final response = await http.get(
      Uri.parse('${AuthService.apiBaseUrl}/analytics/reports?range=$range'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Không thể lấy báo cáo phân tích: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AnalyticsReport.fromJson(data);
  }
}
