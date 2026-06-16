import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../features/timer/services/timer_service.dart';
import '../models/forest_tree.dart';
import '../widgets/forest_dialog_content.dart';
import '../widgets/timer_header.dart';
import '../widgets/preset_tab_bar.dart';
import '../widgets/timer_display.dart';
import '../widgets/time_adjuster.dart';
import '../widgets/timer_action_buttons.dart';

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
  List<ForestTree> _forestTrees = [];

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
      _loadForest();
    }
  }

  Future<void> _loadForest() async {
    if (_userEmail.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('forest_trees_$_userEmail');
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          setState(() {
            _forestTrees = decoded
                .map((item) => ForestTree.fromJson(Map<String, dynamic>.from(item as Map)))
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveForest() async {
    if (_userEmail.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_forestTrees.map((t) => t.toJson()).toList());
      await prefs.setString('forest_trees_$_userEmail', encoded);
    } catch (_) {}
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
    if (_isRunning && (_currentMode == 'Focus' || _currentMode == 'Custom')) {
      _showAbandonWarningDialog();
      return;
    }
    _performReset();
  }

  void _performReset() {
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

  void _showAbandonWarningDialog() {
    final bool willWither = _totalSeconds >= 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = ThemeService.isDarkMode.value;
        final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: dialogBg.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                const SizedBox(width: 10),
                Text(
                  willWither
                      ? LocaleService.tr('Bạn muốn bỏ cuộc sao?', en: 'Are you sure to give up?')
                      : LocaleService.tr('Hủy phiên tập trung?', en: 'Cancel focus session?'),
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              willWither
                  ? LocaleService.tr(
                      'Nếu dừng lại ở đây, mầm cây đang trồng của bạn sẽ bị héo úa và chết!',
                      en: 'If you stop now, your growing tree will wither and die!',
                    )
                  : LocaleService.tr(
                      'Bạn có muốn dừng phiên tập trung này không? (Phiên dưới 10 phút không tính vào Khu rừng).',
                      en: 'Do you want to stop this focus session? (Sessions under 10 minutes do not affect the Forest).',
                    ),
              style: TextStyle(color: subTextColor, fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  LocaleService.tr('Tiếp tục tập trung', en: 'Keep Focusing'),
                  style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (willWither) {
                    _recordFailedTree();
                  }
                  _performReset();
                },
                child: Text(
                  LocaleService.tr('Chấp nhận', en: 'Confirm'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _recordFailedTree() {
    if (_totalSeconds < 600) return;
    setState(() {
      _forestTrees.add(ForestTree(
        timestamp: DateTime.now(),
        mode: _currentMode,
        durationSeconds: _totalSeconds,
        isSuccess: false,
      ));
    });
    _saveForest();
  }

  void _showForestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = ThemeService.isDarkMode.value;
        final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AlertDialog(
            backgroundColor: dialogBg.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
            title: Row(
              children: [
                const Icon(Icons.forest_rounded, color: Color(0xFF10B981), size: 26),
                const SizedBox(width: 10),
                Text(
                  LocaleService.tr('KHU RỪNG NĂNG SUẤT', en: 'PRODUCTIVITY FOREST'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                      letterSpacing: 1.2),
                ),
              ],
            ),
            content: ForestDialogContent(trees: _forestTrees),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  LocaleService.tr('Đóng', en: 'Close'),
                  style: TextStyle(
                      color: captionColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _timerFinished() {
    _countdownController.stop();
    setState(() {
      _isRunning = false;
      _secondsRemaining = 0;
    });

    final bool isFocusMode = _currentMode == 'Focus' || _currentMode == 'Custom';
    final bool qualifiesForForest = _totalSeconds >= 600;

    // Record successful tree if mode is Focus or Custom and is at least 10 minutes
    if (isFocusMode && qualifiesForForest) {
      _forestTrees.add(ForestTree(
        timestamp: DateTime.now(),
        mode: _currentMode,
        durationSeconds: _totalSeconds,
        isSuccess: true,
      ));
      _saveForest();
    }

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

        String contentText;
        if (isFocusMode) {
          if (qualifiesForForest) {
            contentText = LocaleService.tr(
              'Tuyệt vời ông chủ! Bạn đã hoàn thành tập trung cao độ. Một cây xanh mới đã được trồng vào Khu rừng! Hãy nghỉ ngơi một chút nhé!',
              en: 'Awesome! You completed deep focus. A new tree has been planted in the Forest! Take a break!',
            );
          } else {
            contentText = LocaleService.tr(
              'Hoàn thành tập trung! Bạn đã hoàn thành phiên tập trung ngắn. Lưu ý: cần tập trung tối thiểu 10 phút để được trồng cây vào Khu rừng nhé!',
              en: 'Focus completed! You completed a short focus session. Note: at least 10 minutes of focus is required to plant a tree in the Forest!',
            );
          }
        } else {
          contentText = LocaleService.tr(
            'Thời gian nghỉ ngơi đã hết! Ông chủ đã sẵn sàng bắt đầu phiên làm việc mới chưa?',
            en: 'Break time is over! Ready for a new session?',
          );
        }

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: dialogBg.withValues(alpha: 0.9),
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
              contentText,
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
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TimerHeader(
                    userEmail: _userEmail,
                    currentMode: _currentMode,
                    themeColor: themeColor,
                    onForestPressed: _showForestDialog,
                  ),

                  const SizedBox(height: 20),

                  PresetTabBar(
                    currentMode: _currentMode,
                    onPresetSelected: (mode, minutes) => _setPreset(mode, minutes),
                  ),

                  const SizedBox(height: 24),

                  TimerDisplay(
                    pulseAnimation: _pulseAnimation,
                    countdownController: _countdownController,
                    themeColor: themeColor,
                    treeEmoji: _getTreeEmoji(_getProgress()),
                    timeStr: timeStr,
                    isRunning: _isRunning,
                    onTimeTap: _showTimeInputDialog,
                  ),

                  const SizedBox(height: 24),

                  TimeAdjuster(
                    isRunning: _isRunning,
                    totalSeconds: _totalSeconds,
                    themeColor: themeColor,
                    onAdjust: _adjustTime,
                    onTimeTap: _showTimeInputDialog,
                  ),

                  const SizedBox(height: 24),

                  TimerActionButtons(
                    isRunning: _isRunning,
                    themeColor: themeColor,
                    onPlayPause: _isRunning ? _pauseTimer : _startTimer,
                    onReset: _resetTimer,
                    onRestore: () => _setPreset('Focus', 25),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTreeEmoji(double progress) {
    if (_currentMode != 'Focus' && _currentMode != 'Custom') {
      return '☕';
    }
    if (!_isRunning && _secondsRemaining == _totalSeconds) {
      return '🌰';
    }
    if (progress > 0.8) {
      return '🌱';
    }
    if (progress > 0.5) {
      return '🌿';
    }
    if (progress > 0.2) {
      return '🌲';
    }
    if (progress > 0.0) {
      return '🌳';
    }
    return '🌸';
  }
}
