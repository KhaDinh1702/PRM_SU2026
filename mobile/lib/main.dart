import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/locale_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/task_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/project_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/analytics_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init(); // Initialize global dark/light theme state
  await LocaleService.init(); // Initialize language preference
  final bool loggedIn = await AuthService.isLoggedIn();
  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.languageCode,
      builder: (context, langCode, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: ThemeService.isDarkMode,
          builder: (context, isDark, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'FlowMate Productivity System',
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF8B5CF6), // Premium Violet
                  brightness: Brightness.light,
                  background: const Color(0xFFF8FAFC),
                ),
                scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF8B5CF6), // Cyber Violet
                  brightness: Brightness.dark,
                  background: const Color(0xFF070B19),
                ),
                scaffoldBackgroundColor: const Color(0xFF070B19),
              ),
              initialRoute: isLoggedIn ? '/home' : '/login',
              routes: {
                '/login': (context) => const LoginScreen(),
                '/home': (context) => const MainNavigationScreen(),
              },
            );
          },
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 3; // Default to Timer tab (center of 7)

  late final List<Widget> _screens;
  Timer? _eventCheckTimer;
  final Set<String> _notifiedEventIds = {};

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(), // 0: Home
      const TaskScreen(), // 1: Tasks
      TimerScreen(onLogout: _handleLogout), // 2: Timer
      const ProjectScreen(), // 3: Projects
      const CalendarScreen(), // 4: Calendar
      const AnalyticsScreen(), // 5: Analytics
      const NotificationsScreen(), // 6: Notifications
    ];
    _startEventCheckTimer();
  }

  @override
  void dispose() {
    _eventCheckTimer?.cancel();
    super.dispose();
  }

  void _startEventCheckTimer() {
    _eventCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) return;

      try {
        final token = await AuthService.getToken();
        final response = await http.get(
          Uri.parse('https://prm-tan.vercel.app/api/calendar/events'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> events = jsonDecode(response.body);
          final now = DateTime.now();

          for (final event in events) {
            final eventId = event['id'];
            final source = event['source'] ?? 'event';
            // Chỉ thông báo các sự kiện từ calendar (source là 'event'), bỏ qua task deadline
            if (source != 'event') continue;

            final startStr = event['start'];
            if (startStr == null || eventId == null) continue;

            final eventTime = DateTime.parse(startStr).toLocal();
            final title = event['title'] ?? LocaleService.tr('Sự kiện', en: 'Event');
            final message = event['description'] ?? LocaleService.tr('Đã đến thời gian diễn ra sự kiện.', en: 'It is time for your event.');
            final type = event['type'] ?? 'reminder';

            // Nếu thời gian hiện tại đã vượt qua hoặc bằng thời gian sự kiện 
            // và sự kiện chưa được thông báo trong phiên làm việc này
            if (now.isAfter(eventTime) && !_notifiedEventIds.contains(eventId)) {
              // Đảm bảo không thông báo các sự kiện quá cũ (quá 2 giờ trước) khi ứng dụng vừa khởi động
              if (now.difference(eventTime).inHours < 2) {
                _notifiedEventIds.add(eventId);
                _triggerEventNotification(eventId, title, message, type, token!);
              } else {
                // Đánh dấu đã qua nhưng không thông báo vì quá cũ
                _notifiedEventIds.add(eventId);
              }
            }
          }
        }
      } catch (_) {
        // Lỗi kết nối âm thầm bỏ qua để tránh ảnh hưởng trải nghiệm người dùng
      }
    });
  }

  Future<void> _triggerEventNotification(
    String eventId,
    String title,
    String message,
    String type,
    String token,
  ) async {
    // 1. Gửi thông báo lên backend để lưu vào cơ sở dữ liệu
    try {
      await http.post(
        Uri.parse('https://prm-tan.vercel.app/api/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': '${LocaleService.tr('Sự kiện diễn ra:', en: 'Event starting:')} $title ⏰',
          'message': message.isNotEmpty ? message : LocaleService.tr('Đã đến thời gian diễn ra sự kiện.', en: 'It is time for your event.'),
          'type': type == 'meeting' ? 'meeting' : 'task',
        }),
      ).timeout(const Duration(seconds: 10));
      NotificationsScreen.refreshTrigger.value++; // <--- trigger refresh globally
    } catch (_) {}

    // 2. Hiển thị popup thông báo trực quan trên màn hình và phát âm thanh
    if (!mounted) return;
    
    // Play sound and vibrate
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc người dùng nhấn xác nhận
      builder: (context) {
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
              side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    LocaleService.tr('ĐẾN GIỜ HẸN! ⏰', en: 'EVENT TIME! ⏰'),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message.isNotEmpty ? message : LocaleService.tr('Đã đến thời gian diễn ra sự kiện.', en: 'It is time for your event.'),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  LocaleService.tr('Đã hiểu', en: 'Got it'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã đăng xuất tài khoản thành công! 👋'),
          backgroundColor: Colors.amber[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic theme color matching current tab
    Color activeColor;
    switch (_currentIndex) {
      case 0:
        activeColor = const Color(0xFF8B5CF6); // Violet for Dashboard
        break;
      case 1:
        activeColor = const Color(0xFF10B981); // Emerald for Tasks
        break;
      case 2:
        activeColor = const Color(0xFF8B5CF6); // Cyber Violet for Timer
        break;
      case 3:
        activeColor = const Color(0xFF06B6D4); // Cyan for Projects
        break;
      case 4:
        activeColor = const Color(0xFFF43F5E); // Rose for Calendar
        break;
      case 5:
        activeColor = const Color(0xFFEC4899); // Pink for Analytics
        break;
      case 6:
        activeColor = const Color(0xFFF59E0B); // Amber for Notifications
        break;
      default:
        activeColor = const Color(0xFF8B5CF6);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(isDark),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ThemeService.getGradientColors(isDark),
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
          bottomNavigationBar: _buildGlassmorphicNavBar(activeColor, isDark),
        );
      },
    );
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor: ThemeService.getBackgroundColor(isDark),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: const Color(0xFF8B5CF6), size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'FlowMate',
                    style: TextStyle(
                      color: ThemeService.getTextColor(isDark),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.withOpacity(0.2)),
            ListTile(
              leading: Icon(Icons.calendar_month_rounded, color: ThemeService.getTextColor(isDark)),
              title: Text(LocaleService.tr('Lịch (Calendar)', en: 'Calendar'), style: TextStyle(color: ThemeService.getTextColor(isDark))),
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.insights_rounded, color: ThemeService.getTextColor(isDark)),
              title: Text(LocaleService.tr('Thống kê (Analytics)', en: 'Analytics'), style: TextStyle(color: ThemeService.getTextColor(isDark))),
              onTap: () {
                setState(() => _currentIndex = 5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_outlined, color: ThemeService.getTextColor(isDark)),
              title: Text(LocaleService.tr('Thông báo (Alerts)', en: 'Alerts'), style: TextStyle(color: ThemeService.getTextColor(isDark))),
              onTap: () {
                setState(() => _currentIndex = 6);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: ThemeService.getTextColor(isDark),
              ),
              title: Text(
                LocaleService.tr(
                  isDark ? 'Chế độ sáng' : 'Chế độ tối',
                  en: isDark ? 'Light Mode' : 'Dark Mode',
                ),
                style: TextStyle(color: ThemeService.getTextColor(isDark)),
              ),
              onTap: () {
                ThemeService.toggleTheme();
              },
            ),
            const Spacer(),
            Divider(color: Colors.grey.withOpacity(0.2)),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(
                LocaleService.tr('Đăng xuất', en: 'Logout'),
                style: const TextStyle(color: Colors.redAccent),
              ),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Premium Custom Glassmorphic Navigation Bar
  Widget _buildGlassmorphicNavBar(Color activeColor, bool isDark) {
    final navBg = isDark
        ? const Color(0xFF0A0F24).withOpacity(0.85)
        : const Color(0xFFFFFFFF).withOpacity(0.85);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return Container(
      decoration: BoxDecoration(
        color: ThemeService.getBackgroundColor(isDark),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: navBg,
              border: Border(
                top: BorderSide(
                  color: borderColor,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(isDark ? 0.03 : 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.space_dashboard_outlined, Icons.space_dashboard, 'Home', activeColor, isDark),
                  _buildNavItem(1, Icons.playlist_add_check_rounded, Icons.playlist_add_check_rounded, 'Tasks', activeColor, isDark),
                  _buildNavItem(2, Icons.hourglass_empty_rounded, Icons.hourglass_full_rounded, 'Timer', activeColor, isDark),
                  _buildNavItem(3, Icons.dns_outlined, Icons.dns_rounded, 'Projects', activeColor, isDark),
                  // Nút mở Menu (Drawer) được thêm vào đây
                  _buildMenuButton(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(bool isDark) {
    final themeColor = isDark ? Colors.white38 : Colors.black38;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _scaffoldKey.currentState?.openDrawer(); // Mở Drawer
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(
                Icons.menu_rounded,
                color: themeColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Menu',
              style: TextStyle(
                color: themeColor,
                fontSize: 9,
                fontWeight: FontWeight.normal,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label, Color activeColor, bool isDark) {
    final isSelected = _currentIndex == index;
    final themeColor = isSelected
        ? activeColor
        : (isDark ? Colors.white38 : Colors.black38);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: isSelected ? 6 : 4),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                isSelected ? solidIcon : outlineIcon,
                color: themeColor,
                size: isSelected ? 20 : 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: themeColor,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
