import 'dart:ui';
import 'dart:async' as async_timer;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/theme_service.dart';
import 'package:sketchy_design_lang/sketchy_design_lang.dart' as sketchy;

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
    final isSketchy = ThemeService.isSketchyMode.value;
    if (isSketchy) {
      if (_isLoginMode) {
        if (_emailOrPhoneController.text.trim().isEmpty) {
          _showSnackBar(
              LocaleService.tr('Vui lòng nhập Email, SĐT hoặc Username',
                  en: 'Please enter Email, Phone or Username'),
              Colors.redAccent);
          return;
        }
      } else {
        if (_emailController.text.trim().isEmpty) {
          _showSnackBar(
              LocaleService.tr('Vui lòng nhập Email', en: 'Please enter Email'),
              Colors.redAccent);
          return;
        }
        if (_otpController.text.trim().isEmpty) {
          _showSnackBar(
              LocaleService.tr('Vui lòng nhập mã OTP', en: 'Please enter OTP code'),
              Colors.redAccent);
          return;
        }
        if (_passwordController.text.length < 6) {
          _showSnackBar(
              LocaleService.tr('Mật khẩu phải chứa ít nhất 6 ký tự',
                  en: 'Password must be at least 6 characters'),
              Colors.redAccent);
          return;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          _showSnackBar(
              LocaleService.tr('Mật khẩu xác nhận không trùng khớp!',
                  en: 'Passwords do not match!'),
              Colors.redAccent);
          return;
        }
      }
    } else {
      if (!_formKey.currentState!.validate()) return;
    }

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
            Navigator.pushReplacementNamed(context, '/home');
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
            Navigator.pushReplacementNamed(context, '/home');
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
    // Dynamic themes & colors
    const themeColor = Color(0xFF8B5CF6); // Premium Cyber Violet
    const accentColor = Color(0xFFF43F5E); // Cyber Pink

    return ListenableBuilder(
      listenable: Listenable.merge(
          [LocaleService.languageCode, ThemeService.isSketchyMode]),
      builder: (context, child) {
        final isSketchy = ThemeService.isSketchyMode.value;
        if (isSketchy) {
          return _buildSketchyLayout();
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF070B19),
                  Color(0xFF0F172A),
                  Color(0xFF020617),
                ],
                stops: [0.0, 0.5, 1.0],
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
                            // LOGO Space Timer & Glowing Title
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
                                        color: themeColor.withOpacity(0.2),
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
                                    color: Colors.white.withOpacity(0.03),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: const Icon(
                                    Icons.blur_on_rounded,
                                    size: 48,
                                    color: themeColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'SPACE TIMER',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
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
                                      'ĐĂNG KÝ THÀNH VIÊN VŨ TRỤ',
                                      en: 'REGISTER SPACE MEMBER'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white38,
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
                                    color: const Color(0xFF0F1524)
                                        .withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                      width: 1,
                                    ),
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
                                                      backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                                                      foregroundColor: const Color(0xFF8B5CF6),
                                                      side: BorderSide(
                                                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                    ),
                                                    child: _isSendingOtp
                                                        ? const SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Color(0xFF8B5CF6),
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
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons
                                                        .visibility_off_rounded
                                                    : Icons.visibility_rounded,
                                                color: Colors.white38,
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
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    themeColor,
                                                    accentColor
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: themeColor
                                                        .withOpacity(0.3),
                                                    blurRadius: 16,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
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
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: _toggleMode,
                                  child: Text(
                                    _isLoginMode
                                        ? LocaleService.tr('Đăng ký ngay',
                                            en: 'Register now')
                                        : LocaleService.tr('Đăng nhập',
                                            en: 'Login'),
                                    style: const TextStyle(
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
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.language,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              LocaleService.languageCode.value.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
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

  Widget _buildSketchyLayout() {
    return sketchy.SketchyScaffold(
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo vẽ tay
                sketchy.SketchyCard(
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(
                      Icons.blur_on_rounded,
                      size: 48,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                sketchy.SketchyText(
                  'SPACE TIMER',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                sketchy.SketchyText(
                  _isLoginMode
                      ? LocaleService.tr('ĐĂNG NHẬP ĐỂ ĐỒNG BỘ TIẾN TRÌNH',
                          en: 'LOGIN TO SYNC PROGRESS')
                      : LocaleService.tr('ĐĂNG KÝ THÀNH VIÊN VŨ TRỤ',
                          en: 'REGISTER SPACE MEMBER'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 30),

                // Form Card vẽ tay
                sketchy.SketchyCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isLoginMode) ...[
                          sketchy.SketchyTextField(
                            controller: _emailOrPhoneController,
                            decoration: InputDecoration(
                              hintText: LocaleService.tr(
                                  'Email, SĐT hoặc Username',
                                  en: 'Email, Phone or Username'),
                            ),
                          ),
                        ] else ...[
                          sketchy.SketchyTextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: LocaleService.tr('Địa chỉ Email',
                                  en: 'Email Address'),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: sketchy.SketchyTextField(
                                  controller: _otpController,
                                  decoration: InputDecoration(
                                    hintText: LocaleService.tr('Mã xác thực OTP',
                                        en: 'OTP Verification Code'),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              sketchy.SketchyButton(
                                onPressed: (_otpCountdown > 0 || _isSendingOtp)
                                    ? null
                                    : _sendOtpCode,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: _isSendingOtp
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                        )
                                      : sketchy.SketchyText(
                                          _otpCountdown > 0
                                              ? '${_otpCountdown}s'
                                              : (_otpSent
                                                  ? LocaleService.tr('Gửi lại', en: 'Resend')
                                                  : LocaleService.tr('Gửi mã', en: 'Send')),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          sketchy.SketchyTextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              hintText: LocaleService.tr(
                                  'Số điện thoại (Tùy chọn)',
                                  en: 'Phone number (Optional)'),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          sketchy.SketchyTextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: LocaleService.tr('Username (Tùy chọn)',
                                  en: 'Username (Optional)'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        sketchy.SketchyTextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText:
                                LocaleService.tr('Mật khẩu', en: 'Password'),
                          ),
                          obscureText: _obscurePassword,
                        ),
                        if (!_isLoginMode) ...[
                          const SizedBox(height: 16),
                          sketchy.SketchyTextField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              hintText: LocaleService.tr('Xác nhận Mật khẩu',
                                  en: 'Confirm Password'),
                            ),
                            obscureText: _obscurePassword,
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Submit Button vẽ tay
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF8B5CF6)))
                            : sketchy.SketchyButton(
                                onPressed: _submitForm,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  child: Center(
                                    child: sketchy.SketchyText(
                                      _isLoginMode
                                          ? LocaleService.tr('Đăng Nhập',
                                              en: 'Login')
                                          : LocaleService.tr('Tạo Tài Khoản',
                                              en: 'Create Account'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Switch mode footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    sketchy.SketchyText(
                      _isLoginMode
                          ? LocaleService.tr('Chưa có tài khoản? ',
                              en: 'Don\'t have an account? ')
                          : LocaleService.tr('Đã có tài khoản? ',
                              en: 'Already have an account? '),
                    ),
                    GestureDetector(
                      onTap: _toggleMode,
                      child: sketchy.SketchyText(
                        _isLoginMode
                            ? LocaleService.tr('Đăng ký ngay',
                                en: 'Register now')
                            : LocaleService.tr('Đăng nhập', en: 'Login'),
                        style: const TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
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
