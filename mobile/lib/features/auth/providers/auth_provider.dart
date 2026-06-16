import 'package:flutter/foundation.dart';
import '../../../services/auth_service.dart';

/// AuthProvider quản lý toàn bộ trạng thái xác thực và thông tin người dùng.
/// Thay thế việc gọi AuthService.getUserInfo() rải rác ở từng màn hình.
class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // --- Getters ---
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  String get displayName =>
      _currentUser?['username']?.toString().isNotEmpty == true
          ? '@${_currentUser!['username']}'
          : _currentUser?['name']?.toString() ??
              _currentUser?['email']?.toString() ??
              '';

  String get email => _currentUser?['email']?.toString() ?? '';

  String get username => _currentUser?['username']?.toString() ?? '';

  String get avatarLetter {
    final name = _currentUser?['username'] ??
        _currentUser?['name'] ??
        _currentUser?['email'] ??
        'U';
    final s = name.toString();
    return s.isNotEmpty ? s[0].toUpperCase() : 'U';
  }

  int get usernameChangesRemaining =>
      (_currentUser?['usernameChangesRemaining'] as int?) ?? 2;

  // --- Khởi tạo: nạp user từ cache local ---
  Future<void> loadFromCache() async {
    final user = await AuthService.getUserInfo();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  // --- Lấy thông tin mới nhất từ server ---
  Future<void> fetchCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user =
          await AuthService.fetchMe() ?? await AuthService.getUserInfo();
      _currentUser = user;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Đổi username và cập nhật state cục bộ ngay lập tức ---
  Future<Map<String, dynamic>> changeUsername(String newUsername) async {
    final result = await AuthService.changeUsername(newUsername);
    if (result['success'] == true) {
      if (_currentUser != null) {
        _currentUser!['username'] = newUsername;
        _currentUser!['usernameChangesRemaining'] =
            result['changesRemaining'] ?? 0;
        notifyListeners();
      }
    }
    return result;
  }

  // --- Đăng nhập: lưu session và load user ---
  Future<Map<String, dynamic>> login(
      String emailOrPhone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await AuthService.login(emailOrPhone, password);
      if (result['success'] == true) {
        await fetchCurrentUser();
      } else {
        _errorMessage = result['message'];
      }
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Đăng xuất: xóa toàn bộ state ---
  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
