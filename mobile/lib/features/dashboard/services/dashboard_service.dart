import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';
import '../models/dashboard_summary.dart';

/// Service xử lý tất cả API calls liên quan đến Dashboard.
class DashboardService {
  const DashboardService();

  /// Lấy dữ liệu tổng quan dashboard
  Future<DashboardSummary> getSummary() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      // Dùng AuthService.apiBaseUrl thay vì hardcode
      Uri.parse('${AuthService.apiBaseUrl}/dashboard/summary'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Không thể tải dữ liệu dashboard');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return DashboardSummary.fromJson(data);
  }
}
