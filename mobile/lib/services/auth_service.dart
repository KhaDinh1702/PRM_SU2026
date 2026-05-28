import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Thay đổi IP cho phù hợp (10.0.2.2 đối với Android Emulator)
  static const String baseUrl = 'https://prm-tan.vercel.app/api/auth';
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_info';

  // Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register(
      String email, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'phone': phone.trim().isEmpty ? null : phone.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 5));

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
      ).timeout(const Duration(seconds: 5));

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
}
