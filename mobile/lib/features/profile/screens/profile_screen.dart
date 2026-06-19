import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/providers/notification_provider.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    await authProvider.fetchCurrentUser();
    if (mounted) {
      _usernameController.text = authProvider.username;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;
    
    final authProvider = context.read<AuthProvider>();
    if (newUsername == authProvider.username) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Username không thay đổi!'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);
    final result = await authProvider.changeUsername(newUsername);
    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        final remaining = result['changesRemaining'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${result['message']} (còn $remaining lượt đổi tháng này)'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['message']}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeService.isDarkMode,
        LocaleService.languageCode,
      ]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);
        final cardBg = ThemeService.getCardColor(isDark);
        final borderColor = ThemeService.getBorderColor(isDark);
        final activeThemeColor = ThemeService.getPrimaryColor(isDark);

        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.currentUser;
            final remaining = authProvider.usernameChangesRemaining;
            final used = 2 - remaining;

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: activeThemeColor))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            LocaleService.tr('HỒ SƠ CÁ NHÂN', en: 'MY PROFILE'),
                            style: TextStyle(
                                color: captionColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2),
                          ),
                          Text(
                            LocaleService.tr('Tài khoản', en: 'Account'),
                            style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 28),

                          // Avatar + Name Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  children: [
                                    // Avatar circle
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            activeThemeColor,
                                            activeThemeColor.withValues(alpha: 0.7)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: activeThemeColor.withValues(alpha: 0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          )
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          authProvider.avatarLetter,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      authProvider.username.isNotEmpty
                                          ? '@${authProvider.username}'
                                          : LocaleService.tr('Chưa đặt username',
                                              en: 'No username set'),
                                      style: TextStyle(
                                        color: activeThemeColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authProvider.email,
                                      style: TextStyle(
                                          color: subTextColor, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Info cards
                          _infoRow(
                              Icons.person_outline_rounded,
                              LocaleService.tr('Họ tên', en: 'Name'),
                              user?['name']?.toString().isNotEmpty == true
                                  ? user!['name']
                                  : LocaleService.tr('Chưa cập nhật',
                                      en: 'Not set'),
                              textColor,
                              subTextColor,
                              cardBg,
                              borderColor,
                              activeThemeColor),
                          const SizedBox(height: 10),
                          _infoRow(
                              Icons.email_outlined,
                              'Email',
                              authProvider.email,
                              textColor,
                              subTextColor,
                              cardBg,
                              borderColor,
                              activeThemeColor),
                          const SizedBox(height: 28),

                          // Username change section
                          Text(
                            LocaleService.tr('ĐỔI USERNAME', en: 'CHANGE USERNAME'),
                            style: TextStyle(
                                color: captionColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2),
                          ),
                          const SizedBox(height: 12),

                          // Remaining changes indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: remaining == 0
                                  ? Colors.redAccent.withValues(alpha: 0.1)
                                  : activeThemeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: remaining == 0
                                    ? Colors.redAccent.withValues(alpha: 0.3)
                                    : activeThemeColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  remaining == 0
                                      ? Icons.block_rounded
                                      : Icons.swap_horiz_rounded,
                                  color: remaining == 0
                                      ? Colors.redAccent
                                      : activeThemeColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    remaining == 0
                                        ? LocaleService.tr(
                                            'Đã dùng hết 2 lượt đổi tháng này',
                                            en: 'Used all 2 changes this month')
                                        : LocaleService.tr(
                                            'Đã đổi $used/2 lần tháng này · Còn $remaining lượt',
                                            en: 'Changed $used/2 times this month · $remaining left'),
                                    style: TextStyle(
                                      color: remaining == 0
                                          ? Colors.redAccent
                                          : activeThemeColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Username text field
                          Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                            ),
                            child: TextField(
                              controller: _usernameController,
                              enabled: remaining > 0,
                              style: TextStyle(color: textColor, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: LocaleService.tr('Nhập username mới...',
                                    en: 'Enter new username...'),
                                hintStyle: TextStyle(color: subTextColor),
                                prefixIcon: Icon(Icons.alternate_email_rounded,
                                    color: activeThemeColor, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                helperText: LocaleService.tr(
                                    '3-20 ký tự: a-z, 0-9, dấu gạch dưới',
                                    en: '3-20 chars: a-z, 0-9, underscore'),
                                helperStyle:
                                    TextStyle(color: captionColor, fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Save button
                          Builder(builder: (_) {
                            final canChange = remaining > 0 && !_isSaving;
                            return GestureDetector(
                              onTap: canChange ? _changeUsername : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: canChange
                                      ? LinearGradient(
                                          colors: [
                                            activeThemeColor,
                                            activeThemeColor.withValues(alpha: 0.7)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.grey.withValues(alpha: 0.3),
                                            Colors.grey.withValues(alpha: 0.3)
                                          ],
                                        ),
                                  boxShadow: canChange
                                      ? [
                                          BoxShadow(
                                              color: activeThemeColor.withValues(alpha: 0.3),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4))
                                        ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : Text(
                                        LocaleService.tr('Lưu Username',
                                            en: 'Save Username'),
                                        style: TextStyle(
                                          color: canChange
                                              ? Colors.white
                                              : subTextColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            );
                          }),
                          const SizedBox(height: 32),

                          Text(
                            LocaleService.tr('CÔNG CỤ', en: 'TOOLS'),
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _hubTile(
                            icon: Icons.calendar_month_rounded,
                            title: LocaleService.tr('Lịch', en: 'Calendar'),
                            subtitle: LocaleService.tr(
                              'Sự kiện và lịch trình',
                              en: 'Events and schedule',
                            ),
                            color: const Color(0xFF10B981),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CalendarScreen(),
                              ),
                            ),
                            textColor: textColor,
                            subTextColor: subTextColor,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 10),
                          _hubTile(
                            icon: Icons.insights_rounded,
                            title: LocaleService.tr('Thống kê', en: 'Analytics'),
                            subtitle: LocaleService.tr(
                              'Báo cáo năng suất',
                              en: 'Productivity reports',
                            ),
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnalyticsScreen(),
                              ),
                            ),
                            textColor: textColor,
                            subTextColor: subTextColor,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 10),
                          Consumer<NotificationProvider>(
                            builder: (context, notifProvider, _) {
                              return _hubTile(
                                icon: Icons.notifications_outlined,
                                title: LocaleService.tr(
                                  'Thông báo',
                                  en: 'Notifications',
                                ),
                                subtitle: LocaleService.tr(
                                  'Lời mời và cập nhật',
                                  en: 'Invites and updates',
                                ),
                                color: const Color(0xFFF59E0B),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationsScreen(),
                                  ),
                                ),
                                textColor: textColor,
                                subTextColor: subTextColor,
                                cardBg: cardBg,
                                borderColor: borderColor,
                              );
                            },
                          ),
                          const SizedBox(height: 28),

                          Text(
                            LocaleService.tr('CÀI ĐẶT', en: 'SETTINGS'),
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _hubTile(
                            icon: isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            title: LocaleService.tr(
                              isDark ? 'Chế độ sáng' : 'Chế độ tối',
                              en: isDark ? 'Light Mode' : 'Dark Mode',
                            ),
                            subtitle: LocaleService.tr(
                              'Thay đổi giao diện',
                              en: 'Change appearance',
                            ),
                            color: activeThemeColor,
                            onTap: ThemeService.toggleTheme,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 10),
                          ValueListenableBuilder<String>(
                            valueListenable: LocaleService.languageCode,
                            builder: (context, lang, _) {
                              final isEn = lang == 'en';
                              return _hubTile(
                                icon: Icons.language_rounded,
                                title: LocaleService.tr('Ngôn ngữ', en: 'Language'),
                                subtitle: isEn ? 'English' : 'Tiếng Việt',
                                color: const Color(0xFF06B6D4),
                                onTap: LocaleService.toggleLanguage,
                                textColor: textColor,
                                subTextColor: subTextColor,
                                cardBg: cardBg,
                                borderColor: borderColor,
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          GestureDetector(
                            onTap: widget.onLogout,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: 0.25),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.logout_rounded,
                                      color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    LocaleService.tr('Đăng xuất', en: 'Logout'),
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color textColor,
      Color subTextColor, Color cardBg, Color borderColor, Color activeThemeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: activeThemeColor, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: subTextColor,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hubTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Color textColor,
    required Color subTextColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subTextColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
