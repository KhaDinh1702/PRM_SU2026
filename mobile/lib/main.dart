import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_durations.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/locale_service.dart';
import 'services/event_check_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/tasks/screens/task_screen.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/timer/screens/timer_screen.dart';
import 'features/projects/screens/project_screen.dart';
import 'features/projects/providers/project_provider.dart';
import 'features/calendar/screens/calendar_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/analytics/screens/analytics_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init(); // Initialize global dark/light theme state
  await LocaleService.init(); // Initialize language preference
  final bool loggedIn = await AuthService.isLoggedIn();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
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

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0; // Default to Home tab

  late final List<Widget> _screens;
  Timer? _eventCheckTimer;
  final _eventService = EventCheckService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      DashboardScreen(onTabSelect: (index) {
        if (mounted) {
          setState(() => _currentIndex = index);
        }
      }), // 0: Home
      const TaskScreen(), // 1: Tasks
      TimerScreen(onLogout: _handleLogout), // 2: Timer
      const ProjectScreen(), // 3: Projects
      const CalendarScreen(), // 4: Calendar
      const AnalyticsScreen(), // 5: Analytics
      const NotificationsScreen(), // 6: Notifications
      const ProfileScreen(), // 7: Profile
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
      // Lưu notification lên backend (fire-and-forget)
      await _eventService.saveNotificationToBackend(notif);

      // Cập nhật NotificationProvider thay vì gọi static refreshTrigger
      if (mounted) {
        context
            .read<NotificationProvider>()
            .triggerRefresh();
      }

      // Hiển thị popup trực quan
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
                      : Colors.black.withValues(alpha: 0.08)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.notifAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_active_rounded,
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
          content: const Text('Đã đăng xuất tài khoản thành công!'),
          backgroundColor: Colors.amber[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
        final activeColor = ThemeService.getPrimaryColor(isDark);

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
                  Icon(Icons.bolt,
                      color: ThemeService.getPrimaryColor(isDark), size: 32),
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
            Divider(color: Colors.grey.withValues(alpha: 0.2)),
            ListTile(
              leading: Icon(Icons.calendar_month_rounded,
                  color: ThemeService.getTextColor(isDark)),
              title: Text(LocaleService.tr('Lịch', en: 'Calendar'),
                  style: TextStyle(color: ThemeService.getTextColor(isDark))),
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.insights_rounded,
                  color: ThemeService.getTextColor(isDark)),
              title: Text(LocaleService.tr('Thống kê', en: 'Analytics'),
                  style: TextStyle(color: ThemeService.getTextColor(isDark))),
              onTap: () {
                setState(() => _currentIndex = 5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_outlined,
                  color: ThemeService.getTextColor(isDark)),
              title: Text(LocaleService.tr('Thông báo', en: 'Notifications'),
                  style: TextStyle(color: ThemeService.getTextColor(isDark))),
              onTap: () {
                setState(() => _currentIndex = 6);
                Navigator.pop(context);
              },
            ),
            // Theme toggle
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
              onTap: () => ThemeService.toggleTheme(),
            ),
            // Language toggle
            ValueListenableBuilder<String>(
              valueListenable: LocaleService.languageCode,
              builder: (context, lang, _) {
                final isEn = lang == 'en';
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await LocaleService.toggleLanguage();
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            isEn ? '🇬🇧' : '🇻🇳',
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocaleService.tr('Ngôn ngữ', en: 'Language'),
                                  style: TextStyle(
                                    color:
                                        ThemeService.getCaptionColor(isDark),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  isEn ? 'English' : 'Tiếng Việt',
                                  style: TextStyle(
                                    color: ThemeService.getTextColor(isDark),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ThemeService.getPrimaryColor(isDark)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              LocaleService.tr('Chuyển sang EN',
                                  en: 'Switch to VI'),
                              style: TextStyle(
                                color: ThemeService.getPrimaryColor(isDark),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            Divider(color: Colors.grey.withValues(alpha: 0.2)),
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: Colors.redAccent),
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
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: isDark ? 0.03 : 0.06),
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
                  _buildNavItem(
                      0,
                      Icons.space_dashboard_outlined,
                      Icons.space_dashboard,
                      LocaleService.tr('Trang chủ', en: 'Home'),
                      activeColor,
                      isDark),
                  _buildNavItem(
                      1,
                      Icons.playlist_add_check_rounded,
                      Icons.playlist_add_check_rounded,
                      LocaleService.tr('Nhiệm vụ', en: 'Tasks'),
                      activeColor,
                      isDark),
                  _buildNavItem(
                      2,
                      Icons.hourglass_empty_rounded,
                      Icons.hourglass_full_rounded,
                      LocaleService.tr('Bấm giờ', en: 'Timer'),
                      activeColor,
                      isDark),
                  _buildNavItem(
                      3,
                      Icons.dns_outlined,
                      Icons.dns_rounded,
                      LocaleService.tr('Dự án', en: 'Projects'),
                      activeColor,
                      isDark),
                  _buildNavItem(
                      7,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      LocaleService.tr('Hồ sơ', en: 'Profile'),
                      activeColor,
                      isDark),
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
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(Icons.menu_rounded, color: themeColor, size: 18),
            ),
            const SizedBox(height: 2),
            Text(
              LocaleService.tr('Danh mục', en: 'Menu'),
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

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon,
      String label, Color activeColor, bool isDark) {
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
                  horizontal: 10, vertical: isSelected ? 6 : 4),
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
