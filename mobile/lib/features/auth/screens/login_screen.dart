import 'dart:ui';
import 'dart:async' as async_timer;
import 'package:flutter/material.dart';
import '../../../core/constants/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;
  int _otpCountdown = 0;
  async_timer.Timer? _timer;

  // Animation controller for switching modes smoothly
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startOtpCountdown() {
    _timer?.cancel();
    setState(() {
      _otpCountdown = 60;
    });
    _timer = async_timer.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_otpCountdown > 0) {
          _otpCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOtpCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar(
          LocaleService.tr('Vui lòng nhập Email trước', en: 'Please enter Email first'),
          Colors.redAccent);
      return;
    }
    final emailRegex = RegExp(r'^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar(
          LocaleService.tr('Định dạng email không hợp lệ', en: 'Invalid email format'),
          Colors.redAccent);
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      final result = await AuthService.sendOtp(email);
      if (mounted) {
        if (result['success']) {
          _showSnackBar(result['message'], Colors.teal);
          setState(() => _otpSent = true);
          _startOtpCountdown();
        } else {
          _showSnackBar(result['message'], Colors.redAccent);
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi gửi OTP: $e', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _otpController.clear();
      _otpSent = false;
      _otpCountdown = 0;
      _timer?.cancel();
    });
    _fadeController.forward(from: 0.0);
  }

  // Xử lý submit Form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // Đăng nhập
        final result = await AuthService.login(
          _emailOrPhoneController.text,
          _passwordController.text,
        );

        if (mounted) {
          if (result['success']) {
            _showSnackBar(
                result['message'] ??
                    LocaleService.tr('Chào mừng ông chủ trở lại!',
                        en: 'Welcome back, boss!'),
                Colors.indigo);
            // Quay lại trang chính (TimerHomePage) và làm mới trạng thái đăng nhập
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else {
            _showSnackBar(
                result['message'] ??
                    LocaleService.tr('Đăng nhập thất bại.',
                        en: 'Login failed.'),
                Colors.redAccent);
          }
        }
      } else {
        // Đăng ký
        if (_passwordController.text != _confirmPasswordController.text) {
          _showSnackBar(
              LocaleService.tr('Mật khẩu xác nhận không trùng khớp!',
                  en: 'Passwords do not match!'),
              Colors.redAccent);
          setState(() => _isLoading = false);
          return;
        }

        final result = await AuthService.register(
          _emailController.text,
          _phoneController.text,
          _passwordController.text,
          _otpController.text,
          username: _usernameController.text,
        );

        if (mounted) {
          if (result['success']) {
            _showSnackBar(
                result['message'] ??
                    LocaleService.tr('Tạo tài khoản thành công!',
                        en: 'Account created successfully!'),
                Colors.teal);
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else {
            _showSnackBar(
                result['message'] ??
                    LocaleService.tr('Đăng ký thất bại.',
                        en: 'Registration failed.'),
                Colors.redAccent);
          }
        }
      }
    } catch (e) {
      _showSnackBar(
          '${LocaleService.tr('Đã xảy ra lỗi kết nối:', en: 'Connection error:')} $e',
          Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [LocaleService.languageCode, ThemeService.isDarkMode]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final bgGradient = ThemeService.getGradientColors(isDark);
        
        // GitHub Theme Colors
        final themeColor = ThemeService.getPrimaryColor(isDark); // GitHub Blue accent
        final buttonColor = themeColor; // Main Brand Blue
        final buttonHoverColor = isDark ? const Color(0xFF1F6FEB) : const Color(0xFF0C63E4); // Main Brand Blue hover

        final cardColor = isDark 
            ? const Color(0xFF161B22).withValues(alpha: 0.9) 
            : const Color(0xFFFFFFFF).withValues(alpha: 0.9);
        final borderColor = isDark 
            ? const Color(0xFF30363D)
            : const Color(0xFFD0D7DE);
        final titleTextColor = isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
        final subTextColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);
        final footerTextColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgGradient,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // LOGO GitHub & Glowing Title
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColor.withValues(alpha: 0.15),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                                    border: Border.all(
                                        color: borderColor),
                                  ),
                                  child: Image.asset(
                                    'assets/github_logo.png',
                                    width: 48,
                                    height: 48,
                                    color: titleTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'FLOWMATE',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: titleTextColor,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isLoginMode
                                  ? LocaleService.tr(
                                      'ĐĂNG NHẬP ĐỂ ĐỒNG BỘ TIẾN TRÌNH',
                                      en: 'LOGIN TO SYNC PROGRESS')
                                  : LocaleService.tr(
                                      'ĐĂNG KÝ TÀI KHOẢN MỚI',
                                      en: 'REGISTER NEW ACCOUNT'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: subTextColor,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // GLASSMORPHIC CARD WITH FORM
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(28.0),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                    boxShadow: isDark ? [] : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      )
                                    ],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (_isLoginMode) ...[
                                            // LOGIN MODE FIELDS
                                            _buildTextField(
                                              controller:
                                                  _emailOrPhoneController,
                                              labelText: LocaleService.tr(
                                                  'Email, SĐT hoặc Username',
                                                  en: 'Email, Phone or Username'),
                                              icon:
                                                  Icons.person_outline_rounded,
                                              isDark: isDark,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return LocaleService.tr(
                                                      'Vui lòng nhập Email, SĐT hoặc Username',
                                                      en: 'Please enter Email, Phone or Username');
                                                }
                                                return null;
                                              },
                                            ),
                                          ] else ...[
                                            // REGISTER MODE FIELDS
                                            _buildTextField(
                                              controller: _emailController,
                                              labelText: LocaleService.tr(
                                                  'Địa chỉ Email',
                                                  en: 'Email Address'),
                                              icon: Icons.email_outlined,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              isDark: isDark,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return LocaleService.tr(
                                                      'Vui lòng nhập Email',
                                                      en: 'Please enter Email');
                                                }
                                                final emailRegex = RegExp(
                                                    r'^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$');
                                                if (!emailRegex
                                                    .hasMatch(value.trim())) {
                                                  return LocaleService.tr(
                                                      'Định dạng email không hợp lệ',
                                                      en: 'Invalid email format');
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildTextField(
                                                    controller: _otpController,
                                                    labelText: LocaleService.tr(
                                                        'Mã xác thực OTP',
                                                        en: 'OTP Verification Code'),
                                                    icon: Icons.domain_verification_rounded,
                                                    keyboardType: TextInputType.number,
                                                    isDark: isDark,
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.trim().isEmpty) {
                                                        return LocaleService.tr(
                                                            'Vui lòng nhập OTP',
                                                            en: 'Please enter OTP');
                                                      }
                                                      if (value.trim().length != 6) {
                                                        return LocaleService.tr(
                                                            'OTP gồm 6 chữ số',
                                                            en: 'OTP must be 6 digits');
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                SizedBox(
                                                  height: 56,
                                                  child: ElevatedButton(
                                                    onPressed: (_otpCountdown > 0 || _isSendingOtp)
                                                        ? null
                                                        : _sendOtpCode,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: themeColor.withValues(alpha: 0.1),
                                                      foregroundColor: themeColor,
                                                      side: BorderSide(
                                                        color: themeColor.withValues(alpha: 0.3),
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                    ),
                                                    child: _isSendingOtp
                                                        ? SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: themeColor,
                                                            ),
                                                          )
                                                        : Text(
                                                            _otpCountdown > 0
                                                                ? '${_otpCountdown}s'
                                                                : (_otpSent
                                                                    ? LocaleService.tr('Gửi lại', en: 'Resend')
                                                                    : LocaleService.tr('Gửi mã', en: 'Send OTP')),
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            _buildTextField(
                                              controller: _phoneController,
                                              labelText: LocaleService.tr(
                                                  'Số điện thoại (Tùy chọn)',
                                                  en: 'Phone number (Optional)'),
                                              icon: Icons.phone_android_rounded,
                                              keyboardType: TextInputType.phone,
                                              isDark: isDark,
                                              validator: (value) {
                                                if (value != null &&
                                                    value.trim().isNotEmpty) {
                                                  final phoneRegex =
                                                      RegExp(r'^[0-9]{10,11}$');
                                                  if (!phoneRegex
                                                      .hasMatch(value.trim())) {
                                                    return LocaleService.tr(
                                                        'SĐT không hợp lệ (10-11 chữ số)',
                                                        en: 'Invalid phone number (10-11 digits)');
                                                  }
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            _buildTextField(
                                              controller: _usernameController,
                                              labelText: LocaleService.tr(
                                                  'Username (Tùy chọn)',
                                                  en: 'Username (Optional)'),
                                              icon:
                                                  Icons.alternate_email_rounded,
                                              isDark: isDark,
                                              validator: (value) {
                                                if (value != null &&
                                                    value.trim().isNotEmpty) {
                                                  final usernameRegex = RegExp(
                                                      r'^[a-zA-Z0-9_]{3,20}$');
                                                  if (!usernameRegex
                                                      .hasMatch(value.trim())) {
                                                    return LocaleService.tr(
                                                        '3-20 ký tự: chữ, số, dấu gạch',
                                                        en: '3-20 chars: letters, numbers, underscore');
                                                  }
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                          const SizedBox(height: 16),

                                          // PASSWORD FIELD
                                          _buildTextField(
                                            controller: _passwordController,
                                            labelText: LocaleService.tr(
                                                'Mật khẩu',
                                                en: 'Password'),
                                            icon: Icons.lock_outline_rounded,
                                            obscureText: _obscurePassword,
                                            isDark: isDark,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                        .visibility_off_rounded
                                                    : Icons.visibility_rounded,
                                                color: isDark ? Colors.white38 : Colors.black38,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() =>
                                                    _obscurePassword =
                                                        !_obscurePassword);
                                              },
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return LocaleService.tr(
                                                    'Vui lòng nhập mật khẩu',
                                                    en: 'Please enter password');
                                              }
                                              if (value.length < 6) {
                                                return LocaleService.tr(
                                                    'Mật khẩu phải chứa ít nhất 6 ký tự',
                                                    en: 'Password must be at least 6 characters');
                                              }
                                              // Không kiểm tra độ mạnh nếu đang ở màn hình Đăng Nhập
                                              if (!_isLoginMode) {
                                                final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
                                                final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
                                                if (!hasUppercase) {
                                                  return LocaleService.tr(
                                                      'Yêu cầu ít nhất 1 chữ cái in hoa',
                                                      en: 'Requires at least 1 uppercase letter');
                                                }
                                                if (!hasSpecialChar) {
                                                  return LocaleService.tr(
                                                      'Yêu cầu ít nhất 1 ký tự đặc biệt',
                                                      en: 'Requires at least 1 special character');
                                                }
                                              }
                                              return null;
                                            },
                                          ),

                                          // CONFIRM PASSWORD FIELD (REGISTER ONLY)
                                          if (!_isLoginMode) ...[
                                            const SizedBox(height: 16),
                                            _buildTextField(
                                              controller:
                                                  _confirmPasswordController,
                                              labelText: LocaleService.tr(
                                                  'Xác nhận Mật khẩu',
                                                  en: 'Confirm Password'),
                                              icon: Icons.lock_reset_rounded,
                                              obscureText: _obscurePassword,
                                              isDark: isDark,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return LocaleService.tr(
                                                      'Vui lòng xác nhận mật khẩu',
                                                      en: 'Please confirm password');
                                                }
                                                if (value !=
                                                    _passwordController.text) {
                                                  return LocaleService.tr(
                                                      'Mật khẩu xác nhận không trùng khớp',
                                                      en: 'Passwords do not match');
                                                }
                                                return null;
                                              },
                                            ),
                                          ],

                                          const SizedBox(height: 32),

                                          // MAIN SUBMIT BUTTON WITH GRADIENT & GLOW
                                          GestureDetector(
                                            onTap:
                                                _isLoading ? null : _submitForm,
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              height: 56,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    buttonColor,
                                                    buttonHoverColor,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: buttonColor
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 16,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF2EA44F).withValues(alpha: 0.5) : const Color(0xFF1A7F37).withValues(alpha: 0.5),
                                                  width: 1,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                    )
                                                  : Text(
                                                      _isLoginMode
                                                          ? LocaleService.tr(
                                                              'Đăng Nhập',
                                                              en: 'Login')
                                                          : LocaleService.tr(
                                                              'Tạo Tài Khoản',
                                                              en: 'Create Account'),
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // SWITCH REGISTER/LOGIN FOOTER
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLoginMode
                                      ? LocaleService.tr('Chưa có tài khoản? ',
                                          en: 'Don\'t have an account? ')
                                      : LocaleService.tr('Đã có tài khoản? ',
                                          en: 'Already have an account? '),
                                  style: TextStyle(
                                      color: footerTextColor, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: _toggleMode,
                                  child: Text(
                                    _isLoginMode
                                        ? LocaleService.tr('Đăng ký ngay',
                                            en: 'Register now')
                                        : LocaleService.tr('Đăng nhập',
                                            en: 'Login'),
                                    style: TextStyle(
                                      color: themeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ), // closes Row
                          ], // closes children of Column
                        ), // closes Column
                      ), // closes Padding
                    ), // closes SingleChildScrollView
                  ), // closes Center
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: LocaleService.toggleLanguage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.language,
                                color: isDark ? Colors.white70 : Colors.black87, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              LocaleService.languageCode.value.toUpperCase(),
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Reusable Premium TextField Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? Colors.white38 : const Color(0xFF64748B);
    final iconColor = isDark ? Colors.white30 : const Color(0xFF94A3B8);
    final fillColor = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: labelColor, fontSize: 14),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: isDark ? const Color(0xFF58A6FF) : const Color(0xFF0969DA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(
            color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}
