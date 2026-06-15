/// Tất cả các Duration dùng chung trong app.
/// Không hardcode magic number như Duration(seconds: 60) rải rác ở màn hình.
class AppDurations {
  AppDurations._();

  // --- Background Polling ---
  /// Chu kỳ kiểm tra sự kiện lịch để hiển thị notification.
  static const Duration eventCheckInterval = Duration(seconds: 60);

  // --- API Timeout ---
  /// Timeout mặc định cho tất cả HTTP request.
  static const Duration apiTimeout = Duration(seconds: 10);

  // --- UI Animations ---
  /// Micro-animation nhanh (button press, chip select).
  static const Duration animationFast = Duration(milliseconds: 160);

  /// Animation thông thường (dialog, panel slide).
  static const Duration animationNormal = Duration(milliseconds: 300);

  /// Animation chậm (page transition, hero animation).
  static const Duration animationSlow = Duration(milliseconds: 500);

  // --- Haptic Delay ---
  /// Delay giữa 2 lần rung liên tiếp.
  static const Duration hapticDelay = Duration(milliseconds: 300);

  // --- Snackbar ---
  /// Thời gian snackbar thông báo lỗi hiển thị.
  static const Duration snackbarError = Duration(seconds: 3);

  /// Thời gian snackbar thành công hiển thị.
  static const Duration snackbarSuccess = Duration(seconds: 2);
}
