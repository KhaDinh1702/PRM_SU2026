import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_durations.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/locale_service.dart';
import 'services/event_check_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/tasks/screens/task_screen.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/timer/screens/timer_screen.dart';
import 'features/projects/screens/project_screen.dart';
import 'features/projects/providers/project_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/profile/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init();
  await LocaleService.init();
  final bool loggedIn = await AuthService.isLoggedIn();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MyApp(isLoggedIn: loggedIn),
    ),
  );
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
                  seedColor: AppColors.primary,
                  brightness: Brightness.light,
                  surface: AppColors.backgroundLight,
                ),
                scaffoldBackgroundColor: AppColors.backgroundLight,
                cardColor: AppColors.cardLight,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primaryDark,
                  brightness: Brightness.dark,
                  surface: AppColors.backgroundDark,
                ),
                scaffoldBackgroundColor: AppColors.backgroundDark,
                cardColor: AppColors.cardDark,
              ),
              initialRoute: isLoggedIn ? AppRoutes.home : AppRoutes.login,
              routes: {
                AppRoutes.login: (context) => const LoginScreen(),
                AppRoutes.home: (context) => const MainNavigationScreen(),
              },
            );
          },
        );
      },
    );
  }
}

/// Primary app shell with 5-tab bottom navigation.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _eventCheckTimer;
  final _eventService = EventCheckService();

  static const int _tabDashboard = 0;
  static const int _tabTasks = 1;
  static const int _tabProjects = 2;
  static const int _tabFocus = 3;
  static const int _tabProfile = 4;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      DashboardScreen(onTabSelect: (index) {
        if (mounted) setState(() => _currentIndex = index);
      }),
      const TaskScreen(),
      const ProjectScreen(),
      TimerScreen(onLogout: _handleLogout),
      ProfileScreen(onLogout: _handleLogout),
    ];
    _startEventCheckTimer();
    _checkEventsOnce();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _eventCheckTimer?.cancel();
      _eventCheckTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _startEventCheckTimer();
      _checkEventsOnce();
    }
  }

  void _startEventCheckTimer() {
    _eventCheckTimer?.cancel();
    _eventCheckTimer =
        Timer.periodic(AppDurations.eventCheckInterval, (timer) async {
      await _checkEventsOnce();
    });
  }

  Future<void> _checkEventsOnce() async {
    final notifications = await _eventService.checkEvents();
    for (final notif in notifications) {
      await _eventService.saveNotificationToBackend(notif);

      if (mounted) {
        context.read<NotificationProvider>().triggerRefresh();
      }

      if (!mounted) return;
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      Future.delayed(
        AppDurations.hapticDelay,
        () => HapticFeedback.heavyImpact(),
      );
      _showEventNotificationDialog(notif.title, notif.message);
    }
  }

  void _showEventNotificationDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.notifAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: AppColors.notifAccent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    LocaleService.tr('ĐẾN GIỜ HẸN!', en: 'EVENT TIME!'),
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
                  message.isNotEmpty
                      ? message
                      : LocaleService.tr('Đã đến thời gian diễn ra sự kiện.',
                          en: 'It is time for your event.'),
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
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    _eventService.reset();
    await AuthService.logout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleService.tr(
            'Đã đăng xuất tài khoản thành công!',
            en: 'Logged out successfully!',
          )),
          backgroundColor: Colors.amber[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
        final activeColor = ThemeService.getPrimaryColor(isDark);

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

  Widget _buildGlassmorphicNavBar(Color activeColor, bool isDark) {
    final navBg = isDark
        ? const Color(0xFF0A0F24).withValues(alpha: 0.85)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.85);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

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
              border: Border(top: BorderSide(color: borderColor, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: isDark ? 0.03 : 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    _tabDashboard,
                    Icons.space_dashboard_outlined,
                    Icons.space_dashboard,
                    LocaleService.tr('Tổng quan', en: 'Dashboard'),
                    activeColor,
                    isDark,
                  ),
                  _buildNavItem(
                    _tabTasks,
                    Icons.playlist_add_check_outlined,
                    Icons.playlist_add_check_rounded,
                    LocaleService.tr('Nhiệm vụ', en: 'Tasks'),
                    activeColor,
                    isDark,
                  ),
                  _buildNavItem(
                    _tabProjects,
                    Icons.dns_outlined,
                    Icons.dns_rounded,
                    LocaleService.tr('Dự án', en: 'Projects'),
                    activeColor,
                    isDark,
                  ),
                  _buildNavItem(
                    _tabFocus,
                    Icons.center_focus_strong_outlined,
                    Icons.center_focus_strong_rounded,
                    LocaleService.tr('Tập trung', en: 'Focus'),
                    activeColor,
                    isDark,
                  ),
                  _buildNavItem(
                    _tabProfile,
                    Icons.person_outline_rounded,
                    Icons.person_rounded,
                    LocaleService.tr('Hồ sơ', en: 'Profile'),
                    activeColor,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;
    final themeColor =
        isSelected ? activeColor : (isDark ? Colors.white38 : Colors.black38);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppDurations.animationSlow,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: isSelected ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.2)
                      : Colors.transparent,
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
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
