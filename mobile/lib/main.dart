import 'dart:ui';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/task_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/project_screen.dart';
import 'screens/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init(); // Initialize global dark/light theme state
  final bool loggedIn = await AuthService.isLoggedIn();
  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
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
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Default to Timer tab

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const TaskScreen(),
      TimerScreen(onLogout: _handleLogout),
      const ProjectScreen(),
      const CalendarScreen(),
    ];
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
        activeColor = const Color(0xFFF43F5E); // Pink for Calendar
        break;
      default:
        activeColor = const Color(0xFF8B5CF6);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.analytics_outlined, Icons.analytics, 'Dashboard', activeColor, isDark),
                  _buildNavItem(1, Icons.playlist_add_check_rounded, Icons.playlist_add_check_rounded, 'Tasks', activeColor, isDark),
                  _buildNavItem(2, Icons.hourglass_empty_rounded, Icons.hourglass_full_rounded, 'Timer', activeColor, isDark),
                  _buildNavItem(3, Icons.dns_outlined, Icons.dns, 'Projects', activeColor, isDark),
                  _buildNavItem(4, Icons.calendar_today_rounded, Icons.calendar_month_rounded, 'Calendar', activeColor, isDark),
                ],
              ),
            ),
          ),
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: isSelected ? 8 : 4),
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
                size: isSelected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: themeColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
