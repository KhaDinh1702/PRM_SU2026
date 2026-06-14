import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../features/timer/services/timer_service.dart';

class TimerScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const TimerScreen({super.key, required this.onLogout});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  final _timerService = const TimerService();

  // Timer settings
  int _totalSeconds = 25 * 60;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  late AnimationController _countdownController;

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

    // Setup smooth countdown controller
    _countdownController = AnimationController(
      vsync: this,
      value: 1.0,
    );
    _countdownController.addListener(() {
      setState(() {
        _secondsRemaining = (_countdownController.value * _totalSeconds).ceil();
      });
    });
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _isRunning) {
        _timerFinished();
      }
    });
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
    _countdownController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  // --- Backend API Integrations ---

  Future<void> _syncSessionToBackend(String mode, int durationSeconds) async {
    try {
      // Gọi qua TimerService — không http trực tiếp trong widget
      await _timerService.syncSession(
        mode: mode,
        durationSeconds: durationSeconds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr(
                'Đã đồng bộ phiên làm việc thành công!',
                en: 'Session synced successfully!')),
            backgroundColor: Colors.indigo,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr(
                'Đã lưu phiên offline (Không thể kết nối server).',
                en: 'Session saved offline (Cannot connect to server).')),
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

    setState(() {
      _isRunning = true;
    });

    _countdownController.duration = Duration(seconds: _totalSeconds);
    _countdownController.reverse(
        from: _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0);
  }

  void _pauseTimer() {
    if (!_isRunning) return;

    _countdownController.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _countdownController.stop();
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
      _countdownController.value = 1.0;
    });
  }

  void _timerFinished() {
    _countdownController.stop();
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
                  LocaleService.tr('HOÀN THÀNH!', en: 'COMPLETED!'),
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
                  ? LocaleService.tr(
                      'Tuyệt vời ông chủ! Bạn đã hoàn thành tập trung cao độ. Hãy nghỉ ngơi một chút!',
                      en: 'Awesome! You completed deep focus. Take a break!')
                  : LocaleService.tr(
                      'Thời gian nghỉ ngơi đã hết! Ông chủ đã sẵn sàng bắt đầu phiên làm việc mới chưa?',
                      en: 'Break time is over! Ready for a new session?'),
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextColor, fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              PremiumButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetTimer();
                },
                backgroundColor: const Color(0xFFF43F5E),
                child: Text(
                  LocaleService.tr('Tuyệt vời', en: 'Awesome'),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
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
          content: Text(LocaleService.tr(
              'Vui lòng tạm dừng timer trước khi đổi chế độ!',
              en: 'Please pause the timer before changing mode!')),
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
      _countdownController.value = 1.0;
    });
  }

  void _adjustTime(int deltaMinutes) {
    if (_isRunning) return;

    setState(() {
      _currentMode = 'Custom';
      _customMinutes = (_customMinutes + deltaMinutes).clamp(1, 999);
      _totalSeconds = _customMinutes * 60;
      _secondsRemaining = _totalSeconds;
      _countdownController.value = 1.0;
    });
  }

  Future<void> _showTimeInputDialog() async {
    if (_isRunning) return;

    final TextEditingController controller =
        TextEditingController(text: (_totalSeconds ~/ 60).toString());

    await showDialog(
      context: context,
      builder: (context) {
        final isDark = ThemeService.isDarkMode.value;
        final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);

        return AlertDialog(
          backgroundColor: dialogBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            LocaleService.tr('Nhập thời gian (phút)',
                en: 'Enter time (minutes)'),
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
                color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '25',
              hintStyle: TextStyle(color: ThemeService.getSubTextColor(isDark)),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: ThemeService.getBorderColor(isDark)),
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xFFF43F5E), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            autofocus: true,
            onSubmitted: (val) => Navigator.pop(context, val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleService.tr('Hủy', en: 'Cancel'),
                  style:
                      TextStyle(color: ThemeService.getSubTextColor(isDark))),
            ),
            PremiumButton(
              onPressed: () => Navigator.pop(context, controller.text),
              backgroundColor: const Color(0xFFF43F5E),
              child: Text(LocaleService.tr('Xác nhận', en: 'Confirm'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null && value is String && value.isNotEmpty) {
        final int? minutes = int.tryParse(value);
        if (minutes != null && minutes > 0) {
          setState(() {
            _currentMode = 'Custom';
            _customMinutes = minutes.clamp(1, 999);
            _totalSeconds = _customMinutes * 60;
            _secondsRemaining = _totalSeconds;
            _countdownController.value = 1.0;
          });
        }
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    return _countdownController.value;
  }

  @override
  Widget build(BuildContext context) {
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

    return ListenableBuilder(
      listenable: Listenable.merge(
          [ThemeService.isDarkMode, LocaleService.languageCode]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
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
                                  ? '${LocaleService.tr('CHÀO ÔNG CHỦ: ', en: 'HELLO BOSS: ')}${_userEmail.split('@')[0].toUpperCase()}'
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
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
                          child: _buildPresetTab(
                              'Focus',
                              '25M',
                              _currentMode == 'Focus',
                              () => _setPreset('Focus', 25),
                              isDark),
                        ),
                        Expanded(
                          child: _buildPresetTab(
                              'Short Break',
                              '5M',
                              _currentMode == 'Short Break',
                              () => _setPreset('Short Break', 5),
                              isDark),
                        ),
                        Expanded(
                          child: _buildPresetTab(
                              'Long Break',
                              '15M',
                              _currentMode == 'Long Break',
                              () => _setPreset('Long Break', 15),
                              isDark),
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

                          SizedBox(
                            width: 220,
                            height: 220,
                            child: AnimatedBuilder(
                              animation: _countdownController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: TimerPainter(
                                    progress: _getProgress(),
                                    baseColor: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.05),
                                    progressColor: themeColor,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Inside text content
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _isRunning ? null : _showTimeInputDialog,
                                child: Text(
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
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isRunning
                                    ? LocaleService.tr('TIẾN TRÌNH',
                                        en: 'IN PROGRESS')
                                    : LocaleService.tr('TẠM DỪNG',
                                        en: 'PAUSED'),
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
                            LocaleService.tr('ĐIỀU CHỈNH THỜI GIAN',
                                en: 'ADJUST TIME'),
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
                              _buildAdjustButton(Icons.remove,
                                  () => _adjustTime(-1), themeColor, isDark),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  textBaseline: TextBaseline.alphabetic,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  children: [
                                    GestureDetector(
                                      onTap: _showTimeInputDialog,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.black.withOpacity(0.03),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.1)
                                                  : Colors.black
                                                      .withOpacity(0.05)),
                                        ),
                                        child: Text(
                                          '${_totalSeconds ~/ 60}',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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
                              _buildAdjustButton(Icons.add,
                                  () => _adjustTime(1), themeColor, isDark),
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
                        isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
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
                                  ? [
                                      const Color(0xFFF43F5E),
                                      const Color(0xFFBE123C)
                                    ]
                                  : [themeColor, themeColor.withOpacity(0.7)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRunning
                                        ? const Color(0xFFF43F5E)
                                        : themeColor)
                                    .withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
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
                        isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
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
  Widget _buildPresetTab(String title, String subtitle, bool isSelected,
      VoidCallback onTap, bool isDark) {
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
          color:
              isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          border: Border.all(
            color:
                isSelected ? activeColor.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white54 : Colors.black54),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.white30 : Colors.black38),
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
  Widget _buildAdjustButton(
      IconData icon, VoidCallback onPressed, Color themeColor, bool isDark) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.03),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06)),
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
  Widget _buildSecondaryButton(
      IconData icon, VoidCallback onTap, Color bgColor, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04)),
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
