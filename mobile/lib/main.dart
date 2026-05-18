import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Premium Timer App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6), // Premium Violet
          brightness: Brightness.dark,
          background: const Color(0xFF080C14),
        ),
      ),
      home: const TimerHomePage(),
    );
  }
}

class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key});

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

class _TimerHomePageState extends State<TimerHomePage> with TickerProviderStateMixin {
  // Backend API URL (Android Emulator uses 10.0.2.2 to connect to host localhost)
  static const String _baseUrl = 'http://10.0.2.2:5000/api/sessions';

  // Timer settings
  int _totalSeconds = 25 * 60;
  int _secondsRemaining = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  
  // App mode: 'Focus' (25m), 'Short Break' (5m), 'Long Break' (15m), 'Custom'
  String _currentMode = 'Focus';
  int _customMinutes = 25;

  // Completion animation
  late AnimationController _completionController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup pulsing animation for completion state
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeInOut),
    );
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
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mode': mode,
          'durationSeconds': durationSeconds,
        }),
      ).timeout(const Duration(seconds: 4));

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

  Future<List<dynamic>> _fetchHistory() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/stats')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'totalSessions': 0,
      'totalFocusMinutes': 0,
      'totalBreakMinutes': 0,
    };
  }

  void _showHistoryStatsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1524).withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([_fetchHistory(), _fetchStats()]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  );
                }

                final history = snapshot.data?[0] as List<dynamic>? ?? [];
                final stats = snapshot.data?[1] as Map<String, dynamic>? ?? {};

                final totalSessions = stats['totalSessions'] ?? 0;
                final totalFocusMin = stats['totalFocusMinutes'] ?? 0;
                final totalBreakMin = stats['totalBreakMinutes'] ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'THỐNG KÊ & LỊCH SỬ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Tổng phiên',
                            '$totalSessions',
                            Icons.emoji_events_outlined,
                            const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Tập trung',
                            '$totalFocusMin phút',
                            Icons.wb_sunny_outlined,
                            const Color(0xFFF43F5E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Nghỉ ngơi',
                            '$totalBreakMin phút',
                            Icons.nature_people_outlined,
                            const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'LỊCH SỬ GẦN ĐÂY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: history.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Chưa có dữ liệu phiên nào được đồng bộ.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: history.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final session = history[index];
                                final mode = session['mode'] ?? 'Focus';
                                final duration = session['durationSeconds'] ?? 0;
                                final dateStr = session['completedAt'] ?? '';
                                
                                String formattedDate = 'Vừa xong';
                                try {
                                  final completedAt = DateTime.parse(dateStr).toLocal();
                                  formattedDate = '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')} - ${completedAt.day}/${completedAt.month}';
                                } catch (_) {}

                                Color modeColor;
                                if (mode == 'Focus') {
                                  modeColor = const Color(0xFF8B5CF6);
                                } else if (mode == 'Short Break') {
                                  modeColor = const Color(0xFF10B981);
                                } else if (mode == 'Long Break') {
                                  modeColor = const Color(0xFF06B6D4);
                                } else {
                                  modeColor = const Color(0xFFF43F5E);
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.04),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: modeColor.withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          mode == 'Focus' || mode == 'Custom'
                                              ? Icons.center_focus_strong
                                              : Icons.coffee,
                                          color: modeColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mode == 'Focus' ? 'Phiên Tập Trung' : (mode == 'Short Break' ? 'Nghỉ Ngắn' : (mode == 'Long Break' ? 'Nghỉ Dài' : 'Tùy Chỉnh')),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white38,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${duration ~/ 60}m',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: modeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
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
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xFF131A2C).withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFF43F5E), width: 1.5),
            ),
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                SizedBox(width: 10),
                Text(
                  'HOÀN THÀNH!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
              style: const TextStyle(color: Colors.white70, fontSize: 16),
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
      // Show caution alert if changing preset while timer is running
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
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  // Premium App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                            Text(
                              'Space Timer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 28),
                              onPressed: _showHistoryStatsSheet,
                              tooltip: 'Thống kê & Lịch sử',
                            ),
                            const SizedBox(width: 8),
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
                                  Icon(Icons.bolt, color: themeColor, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _currentMode.toUpperCase(),
                                    style: TextStyle(
                                      color: themeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                  ),

                  const SizedBox(height: 24),

                  // Preset Selector Tab Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPresetTab('Focus', '25M', _currentMode == 'Focus', () => _setPreset('Focus', 25)),
                          ),
                          Expanded(
                            child: _buildPresetTab('Short Break', '5M', _currentMode == 'Short Break', () => _setPreset('Short Break', 5)),
                          ),
                          Expanded(
                            child: _buildPresetTab('Long Break', '15M', _currentMode == 'Long Break', () => _setPreset('Long Break', 15)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Timer Display Circle
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Inner Glow Accent
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.08),
                                  blurRadius: 50,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),

                          // Outer Interactive Canvas Painter
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: CustomPaint(
                              painter: TimerPainter(
                                progress: progress,
                                baseColor: Colors.white.withOpacity(0.05),
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
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor.withOpacity(0.9),
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Custom Time Adjustment Controls (Active in Custom Mode or when paused)
                  AnimatedOpacity(
                    opacity: _isRunning ? 0.3 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: _isRunning,
                      child: Column(
                        children: [
                          const Text(
                            'ĐIỀU CHỈNH THỜI GIAN',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAdjustButton(Icons.remove, () => _adjustTime(-1), themeColor),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  textBaseline: TextBaseline.alphabetic,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  children: [
                                    Text(
                                      '${_totalSeconds ~/ 60}',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'phút',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildAdjustButton(Icons.add, () => _adjustTime(1), themeColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Main Control Actions
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset Button
                        _buildSecondaryButton(
                          Icons.replay,
                          _resetTimer,
                          Colors.white.withOpacity(0.08),
                        ),

                        const SizedBox(width: 32),

                        // Play / Pause Button with Premium Gradient Glow
                        GestureDetector(
                          onTap: _isRunning ? _pauseTimer : _startTimer,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isRunning
                                    ? [const Color(0xFFF43F5E), const Color(0xFFBE123C)] // Cyber Pink Gradient
                                    : [themeColor, themeColor.withOpacity(0.7)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRunning ? const Color(0xFFF43F5E) : themeColor).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),

                        const SizedBox(width: 32),

                        // Custom preset setup button to reset quickly to default
                        _buildSecondaryButton(
                          Icons.settings_backup_restore,
                          () => _setPreset('Focus', 25),
                          Colors.white.withOpacity(0.08),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom Preset Tab builder
  Widget _buildPresetTab(String title, String subtitle, bool isSelected, VoidCallback onTap) {
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white30,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Adjust Control Button
  Widget _buildAdjustButton(IconData icon, VoidCallback onPressed, Color themeColor) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }

  // Secondary Control Button
  Widget _buildSecondaryButton(IconData icon, VoidCallback onTap, Color bgColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 24,
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
    const strokeWidth = 14.0;

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
        ..strokeWidth = strokeWidth + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

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
