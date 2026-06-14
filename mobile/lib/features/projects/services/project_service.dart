import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';

/// Service xử lý tất cả API calls liên quan đến Projects.
/// Thay thế các lời gọi http trực tiếp rải rác trong ProjectScreen.
class ProjectService {
  const ProjectService();

  /// Lấy danh sách project của user hiện tại
  Future<List<dynamic>> getProjects() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập');
    }

    final response = await http.get(
      Uri.parse('${AuthService.apiBaseUrl}/projects'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = _tryDecode(response.body);
      throw Exception(
          data?['error'] ?? 'HTTP ${response.statusCode}: Không thể tải dự án');
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  /// Lấy danh sách users (để mời vào project)
  Future<List<dynamic>> getUsers() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${AuthService.apiBaseUrl}/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return [];
    return jsonDecode(response.body) as List<dynamic>;
  }

  /// Tạo project mới
  Future<void> createProject({
    required String name,
    required String description,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/projects'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception('Không thể tạo dự án');
    }
  }

  /// Cập nhật thông tin project
  Future<void> updateProject({
    required String projectId,
    required Map<String, dynamic> payload,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .put(
          Uri.parse('${AuthService.apiBaseUrl}/projects/$projectId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = _tryDecode(response.body);
      throw Exception(data?['error'] ?? 'Không thể cập nhật dự án');
    }
  }

  /// Xóa project
  Future<void> deleteProject(String projectId) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${AuthService.apiBaseUrl}/projects/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = _tryDecode(response.body);
      throw Exception(data?['error'] ?? 'Không thể xóa dự án');
    }
  }

  /// Thêm thành viên vào project (gửi lời mời)
  Future<Map<String, dynamic>> addMember({
    required String projectId,
    required String email,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/projects/$projectId/members'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 15));

    final data = _tryDecode(response.body) ?? {};

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Có lỗi xảy ra'};
    }
  }

  /// Lấy danh sách task của project
  Future<List<dynamic>> getProjectTasks(String projectId) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${AuthService.apiBaseUrl}/projects/$projectId/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return [];
    return jsonDecode(response.body) as List<dynamic>;
  }

  /// Tạo task trong project
  Future<Map<String, dynamic>> createProjectTask({
    required String projectId,
    required Map<String, dynamic> payload,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${AuthService.apiBaseUrl}/projects/$projectId/tasks'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      return {'success': true, 'data': _tryDecode(response.body) ?? {}};
    }
    final data = _tryDecode(response.body) ?? {};
    return {'success': false, 'error': data['error'] ?? 'Không thể tạo task'};
  }

  /// Cập nhật task trong project
  Future<Map<String, dynamic>> updateProjectTask({
    required String projectId,
    required String taskId,
    required Map<String, dynamic> payload,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .put(
          Uri.parse(
              '${AuthService.apiBaseUrl}/projects/$projectId/tasks/$taskId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return {'success': true};
    }
    final data = _tryDecode(response.body) ?? {};
    return {
      'success': false,
      'error': data['error'] ?? 'Không thể cập nhật task',
      'statusCode': response.statusCode,
    };
  }

  /// Cập nhật role thành viên trong project
  Future<Map<String, dynamic>> updateMemberRole({
    required String projectId,
    required String userId,
    required String role,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .put(
          Uri.parse(
              '${AuthService.apiBaseUrl}/projects/$projectId/members/$userId/role'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'role': role}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return {'success': true, 'data': _tryDecode(response.body) ?? {}};
    }
    final data = _tryDecode(response.body) ?? {};
    return {
      'success': false,
      'error': data['error'] ?? 'Không thể cập nhật role',
    };
  }

  // --- Private helper ---
  Map<String, dynamic>? _tryDecode(String body) {
    try {
      if (body.isEmpty) return null;
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
}
