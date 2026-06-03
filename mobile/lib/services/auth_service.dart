import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Trỏ về local server để có các bản cập nhật mới nhất (username, etc)
  static const String baseUrl = 'http://10.0.2.2:5000/api/auth';
  static const String localBaseUrl = 'http://10.0.2.2:5000/api';
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_info';

  // Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register(
      String email, String phone, String password, {String username = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'phone': phone.trim().isEmpty ? null : phone.trim(),
          'password': password,
          if (username.trim().isNotEmpty) 'username': username.trim(),
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final token = data['token'];
        final user = data['user'];
        await _saveSession(token, user);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Đăng ký thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến server: $e'};
    }
  }

  // Đăng nhập
  static Future<Map<String, dynamic>> login(
      String emailOrPhone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhone': emailOrPhone.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final user = data['user'];
        await _saveSession(token, user);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến server: $e'};
    }
  }

  // Lưu Session (Token và User Info) vào SharedPreferences
  static Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, jsonEncode(user));
  }

  // Lấy Token hiện tại
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Lấy Thông tin User hiện tại
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(userKey);
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  // Kiểm tra đã đăng nhập chưa
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  // Lấy thông tin user mới nhất từ server (kèm username và số lượt đổi còn lại)
  static Future<Map<String, dynamic>?> fetchMe() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      final response = await http.get(
        Uri.parse('$localBaseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Cập nhật lại cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(userKey, jsonEncode(data));
        return data;
      }
    } catch (_) {}
    return null;
  }

  // Đổi username (giới hạn 2 lần/tháng)
  static Future<Map<String, dynamic>> changeUsername(String newUsername) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$localBaseUrl/users/username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'username': newUsername.trim()}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Cập nhật cache
        final userInfo = await getUserInfo();
        if (userInfo != null) {
          userInfo['username'] = data['username'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(userKey, jsonEncode(userInfo));
        }
        return {'success': true, 'message': data['message'], 'changesRemaining': data['changesRemaining']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
