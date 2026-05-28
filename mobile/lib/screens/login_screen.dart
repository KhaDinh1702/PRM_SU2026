import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
    if (_isLoginMode) {
      _fadeController.forward(from: 0.0);
    } else {
      _fadeController.forward(from: 0.0);
    }
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
            _showSnackBar(result['message'] ?? 'Chào mừng ông chủ trở lại! 🚀', Colors.indigo);
            // Quay lại trang chính (TimerHomePage) và làm mới trạng thái đăng nhập
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            _showSnackBar(result['message'] ?? 'Đăng nhập thất bại.', Colors.redAccent);
          }
        }
      } else {
        // Đăng ký
        if (_passwordController.text != _confirmPasswordController.text) {
          _showSnackBar('Mật khẩu xác nhận không trùng khớp!', Colors.redAccent);
          setState(() => _isLoading = false);
          return;
        }

        final result = await AuthService.register(
          _emailController.text,
          _phoneController.text,
          _passwordController.text,
        );

        if (mounted) {
          if (result['success']) {
            _showSnackBar(result['message'] ?? 'Tạo tài khoản thành công! 🌟', Colors.teal);
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            _showSnackBar(result['message'] ?? 'Đăng ký thất bại.', Colors.redAccent);
          }
        }
      }
    } catch (e) {
      _showSnackBar('Đã xảy ra lỗi kết nối: $e', Colors.redAccent);
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
          child: Center(
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
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                          ? 'ĐĂNG NHẬP ĐỂ ĐỒNG BỘ TIẾN TRÌNH'
                          : 'ĐĂNG KÝ THÀNH VIÊN VŨ TRỤ',
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
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(28.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1524).withOpacity(0.6),
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_isLoginMode) ...[
                                    // LOGIN MODE FIELDS
                                    _buildTextField(
                                      controller: _emailOrPhoneController,
                                      labelText: 'Email hoặc Số điện thoại',
                                      icon: Icons.alternate_email_rounded,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Vui lòng nhập Email hoặc SĐT';
                                        }
                                        return null;
                                      },
                                    ),
                                  ] else ...[
                                    // REGISTER MODE FIELDS
                                    _buildTextField(
                                      controller: _emailController,
                                      labelText: 'Địa chỉ Email',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Vui lòng nhập Email';
                                        }
                                        final emailRegex = RegExp(
                                            r'^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$');
                                        if (!emailRegex.hasMatch(value.trim())) {
                                          return 'Định dạng email không hợp lệ';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _phoneController,
                                      labelText: 'Số điện thoại (Tùy chọn)',
                                      icon: Icons.phone_android_rounded,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value != null && value.trim().isNotEmpty) {
                                          final phoneRegex = RegExp(r'^[0-9]{10,11}$');
                                          if (!phoneRegex.hasMatch(value.trim())) {
                                            return 'SĐT không hợp lệ (10-11 chữ số)';
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
                                    labelText: 'Mật khẩu',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.white38,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập mật khẩu';
                                      }
                                      if (value.length < 6) {
                                        return 'Mật khẩu phải chứa ít nhất 6 ký tự';
                                      }
                                      return null;
                                    },
                                  ),

                                  // CONFIRM PASSWORD FIELD (REGISTER ONLY)
                                  if (!_isLoginMode) ...[
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _confirmPasswordController,
                                      labelText: 'Xác nhận Mật khẩu',
                                      icon: Icons.lock_reset_rounded,
                                      obscureText: _obscurePassword,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Vui lòng xác nhận mật khẩu';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Mật khẩu xác nhận không trùng khớp';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],

                                  const SizedBox(height: 32),

                                  // MAIN SUBMIT BUTTON WITH GRADIENT & GLOW
                                  GestureDetector(
                                    onTap: _isLoading ? null : _submitForm,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          colors: [themeColor, accentColor],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: themeColor.withOpacity(0.3),
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
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              _isLoginMode ? 'Đăng Nhập' : 'Tạo Tài Khoản',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
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
                              ? 'Chưa có tài khoản? '
                              : 'Đã có tài khoản? ',
                          style: const TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: _toggleMode,
                          child: Text(
                            _isLoginMode ? 'Đăng ký ngay' : 'Đăng nhập',
                            style: const TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}
