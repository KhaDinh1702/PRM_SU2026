import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';
import '../models/task_model.dart';

/// Service xử lý tất cả API calls liên quan đến Task.
/// Các widget KHÔNG gọi http trực tiếp — chỉ gọi qua TaskService.
class TaskService {
  const TaskService();

  /// Lấy danh sách task theo bộ lọc
  Future<List<TaskModel>> getTasks({
    required String tab,
    String sortBy = 'recent',
    String? sourceFilter,
    String? statusFilter,
    String? priorityFilter,
    String? search,
  }) async {
    final token = await AuthService.getToken();
    final query = <String, String>{
      'tab': tab,
      'sort': sortBy,
      if (sourceFilter != null && sourceFilter != 'All')
        'source': sourceFilter.toLowerCase(),
      if (statusFilter != null && statusFilter != 'All')
        'status': statusFilter,
      if (priorityFilter != null && priorityFilter != 'All')
        'priority': priorityFilter,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final uri = Uri.parse('${AuthService.apiBaseUrl}/tasks')
        .replace(queryParameters: query);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách task: ${response.statusCode}');
    }

    final List<dynamic> rawList = jsonDecode(response.body);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .toList();
  }

  /// Tạo task cá nhân mới
  Future<void> createTask({
    required String title,
    String description = '',
    String priority = 'Medium',
    DateTime? dueDate,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/tasks'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'title': title,
            'description': description,
            'priority': priority,
            'status': 'Pending',
            if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception('Không thể tạo task');
    }
  }

  /// Cập nhật trạng thái task (toggle hoàn thành / mở lại)
  Future<void> updateTaskStatus({
    required String taskId,
    required String newStatus,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .put(
          Uri.parse('${AuthService.apiBaseUrl}/tasks/$taskId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'status': newStatus}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Không thể cập nhật trạng thái task');
    }
  }

  /// Xóa task cá nhân
  Future<void> deleteTask(String taskId) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${AuthService.apiBaseUrl}/tasks/$taskId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Không thể xóa task');
    }
  }
}
