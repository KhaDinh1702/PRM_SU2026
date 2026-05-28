import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class TimerScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const TimerScreen({super.key, required this.onLogout});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  // Backend API URL (Vercel deployment)
  static const String _baseUrl = 'https://prm-tan.vercel.app/api/sessions';

  // Timer settings
  int _totalSeconds = 25 * 60;
  int _secondsRemaining = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  
  // App mode: 'Focus' (25m), 'Short Break' (5m), 'Long Break' (15m), 'Custom'
  String _currentMode = 'Focus';
  int _customMinutes = 25;
  String _userEmail = '';

  // Completion animation
  late AnimationController _completionController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    
    // Setup pulsing animation for completion state
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await AuthService.getUserInfo();
    if (userInfo != null && mounted) {
      setState(() {
        _userEmail = userInfo['email'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _completionController.dispose();
    super.dispose();
  }

  // --- Backend API Integrations ---
  
  Future<void> _syncSessionToBackend(String mode, int durationSeconds) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mode': mode,
          'durationSeconds': durationSeconds,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã đồng bộ phiên làm việc thành công! 🚀'),
              backgroundColor: Colors.indigo,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu phiên offline (Không thể kết nối server).'),
            backgroundColor: Colors.amber[900],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startTimer() {
    if (_isRunning) return;
    
    _timer?.cancel();
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timerFinished();
      }
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;

    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _completionController.stop();
    _completionController.reset();
    setState(() {
      _isRunning = false;
      if (_currentMode == 'Focus') {
        _totalSeconds = 25 * 60;
      } else if (_currentMode == 'Short Break') {
        _totalSeconds = 5 * 60;
      } else if (_currentMode == 'Long Break') {
        _totalSeconds = 15 * 60;
      } else {
        _totalSeconds = _customMinutes * 60;
      }
      _secondsRemaining = _totalSeconds;
    });
  }

  void _timerFinished() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = 0;
    });
    
    // Start pulsing visual effect to alert the user
    _completionController.repeat(reverse: true);

    // Sync session to backend
    _syncSessionToBackend(_currentMode, _totalSeconds);

    // Show a beautiful completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = ThemeService.isDarkMode.value;
        final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: dialogBg.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFF43F5E), width: 1.5),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Text(
                  'HOÀN THÀNH!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            content: Text(
              _currentMode == 'Focus'
                  ? 'Tuyệt vời ông chủ! Bạn đã hoàn thành 25 phút tập trung cao độ. Hãy nghỉ ngơi một chút!'
                  : 'Thời gian nghỉ ngơi đã hết! Ông chủ đã sẵn sàng bắt đầu phiên làm việc mới chưa?',
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextColor, fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetTimer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Tuyệt vời',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setPreset(String mode, int minutes) {
    if (_isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng tạm dừng timer trước khi đổi chế độ!'),
          backgroundColor: Colors.amber[800],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _completionController.stop();
    _completionController.reset();

    setState(() {
      _currentMode = mode;
      _totalSeconds = minutes * 60;
      _secondsRemaining = _totalSeconds;
    });
  }

  void _adjustTime(int deltaMinutes) {
    if (_isRunning) return;

    setState(() {
      _currentMode = 'Custom';
      _customMinutes = (_customMinutes + deltaMinutes).clamp(1, 180);
      _totalSeconds = _customMinutes * 60;
      _secondsRemaining = _totalSeconds;
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    if (_totalSeconds == 0) return 0;
    return _secondsRemaining / _totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getProgress();
    final timeStr = _formatTime(_secondsRemaining);

    // Dynamic colors depending on the mode
    Color themeColor;
    if (_currentMode == 'Focus') {
      themeColor = const Color(0xFF8B5CF6); // Cyber Violet
    } else if (_currentMode == 'Short Break') {
      themeColor = const Color(0xFF10B981); // Emerald Green
    } else if (_currentMode == 'Long Break') {
      themeColor = const Color(0xFF06B6D4); // Cyan Blue
    } else {
      themeColor = const Color(0xFFF43F5E); // Cyber Pink (Custom)
    }

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);
        final cardBgColor = ThemeService.getCardColor(isDark);
        final borderColor = ThemeService.getBorderColor(isDark);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Premium Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userEmail.isNotEmpty 
                                  ? 'CHÀO ÔNG CHỦ: ${_userEmail.split('@')[0].toUpperCase()}'
                                  : 'PREMIUM',
                              style: TextStyle(
                                color: captionColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Space Timer',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: themeColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.bolt, color: themeColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _currentMode.toUpperCase(),
                                  style: TextStyle(
                                    color: themeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Premium Light/Dark Mode Toggle Switch
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: isDark ? Colors.amber[400] : const Color(0xFF475569),
                              size: 20,
                            ),
                            onPressed: () => ThemeService.toggleTheme(),
                            tooltip: 'Chuyển chủ đề',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 14),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                            onPressed: widget.onLogout,
                            tooltip: 'Đăng xuất',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Preset Selector Tab Bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPresetTab('Focus', '25M', _currentMode == 'Focus', () => _setPreset('Focus', 25), isDark),
                        ),
                        Expanded(
                          child: _buildPresetTab('Short Break', '5M', _currentMode == 'Short Break', () => _setPreset('Short Break', 5), isDark),
                        ),
                        Expanded(
                          child: _buildPresetTab('Long Break', '15M', _currentMode == 'Long Break', () => _setPreset('Long Break', 15), isDark),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Timer Display Circle
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Inner Glow Accent
                          Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.08),
                                  blurRadius: 40,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                          ),

                          // Outer Interactive Canvas Painter
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: CustomPaint(
                              painter: TimerPainter(
                                progress: progress,
                                baseColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                progressColor: themeColor,
                              ),
                            ),
                          ),

                          // Inside text content
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: 1.5,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isRunning ? 'TIẾN TRÌNH' : 'TẠM DỪNG',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor.withOpacity(0.9),
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Custom Time Adjustment Controls
                  AnimatedOpacity(
                    opacity: _isRunning ? 0.3 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: _isRunning,
                      child: Column(
                        children: [
                          Text(
                            'ĐIỀU CHỈNH THỜI GIAN',
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAdjustButton(Icons.remove, () => _adjustTime(-1), themeColor, isDark),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  textBaseline: TextBaseline.alphabetic,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  children: [
                                    Text(
                                      '${_totalSeconds ~/ 60}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'phút',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildAdjustButton(Icons.add, () => _adjustTime(1), themeColor, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Control Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset Button
                      _buildSecondaryButton(
                        Icons.replay,
                        _resetTimer,
                        isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                        isDark,
                      ),

                      const SizedBox(width: 24),

                      // Play / Pause Button with Premium Gradient Glow
                      GestureDetector(
                        onTap: _isRunning ? _pauseTimer : _startTimer,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isRunning
                                  ? [const Color(0xFFF43F5E), const Color(0xFFBE123C)]
                                  : [themeColor, themeColor.withOpacity(0.7)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRunning ? const Color(0xFFF43F5E) : themeColor).withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Preset restore
                      _buildSecondaryButton(
                        Icons.settings_backup_restore,
                        () => _setPreset('Focus', 25),
                        isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Custom Preset Tab builder
  Widget _buildPresetTab(String title, String subtitle, bool isSelected, VoidCallback onTap, bool isDark) {
    Color activeColor;
    if (title == 'Focus') {
      activeColor = const Color(0xFF8B5CF6);
    } else if (title == 'Short Break') {
      activeColor = const Color(0xFF10B981);
    } else {
      activeColor = const Color(0xFF06B6D4);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? Colors.white54 : Colors.black54),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? activeColor : (isDark ? Colors.white30 : Colors.black38),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Adjust Control Button
  Widget _buildAdjustButton(IconData icon, VoidCallback onPressed, Color themeColor, bool isDark) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black87,
          size: 18,
        ),
      ),
    );
  }

  // Secondary Control Button
  Widget _buildSecondaryButton(IconData icon, VoidCallback onTap, Color bgColor, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black87,
          size: 20,
        ),
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  final Color progressColor;

  TimerPainter({
    required this.progress,
    required this.baseColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 12.0;

    // Draw background track
    final paintBase = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth - 2;
    canvas.drawCircle(center, radius - strokeWidth / 2, paintBase);

    // Draw glowing progress arc
    if (progress > 0) {
      final paintProgress = Paint()
        ..shader = SweepGradient(
          colors: [
            progressColor.withOpacity(0.6),
            progressColor,
            progressColor.withOpacity(0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      // Subtle shadow/glow effect
      final paintGlow = Paint()
        ..color = progressColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -math.pi / 2,
        sweepAngle,
        false,
        paintGlow,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -math.pi / 2,
        sweepAngle,
        false,
        paintProgress,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.progressColor != progressColor;
  }
}
