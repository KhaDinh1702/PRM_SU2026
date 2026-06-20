import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../widgets/analytics_preview_card.dart';
import '../widgets/calendar_preview_card.dart';
import '../widgets/profile_hero_card.dart';
import '../widgets/profile_inbox_section.dart';
import '../widgets/profile_insights_section.dart';
import '../widgets/profile_logout_button.dart';
import '../widgets/profile_preferences_section.dart';
import '../widgets/profile_username_sheet.dart';

/// Profile screen — slim orchestrator. UI is composed of the section
/// widgets under `profile/widgets/`; this file owns only the page chrome
/// (header, loading state, scroll) and the entry point to the username
/// change sheet.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  /// Keys allow the screen-level pull-to-refresh to trigger reload() on each
  /// preview card without lifting their loading state into the parent.
  final _calendarKey = GlobalKey<CalendarPreviewCardState>();
  final _analyticsKey = GlobalKey<AnalyticsPreviewCardState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    await context.read<AuthProvider>().fetchCurrentUser();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refreshAll() async {
    await Future.wait<void>([
      context.read<AuthProvider>().fetchCurrentUser(),
      context.read<NotificationProvider>().loadNotifications(silent: true),
      _calendarKey.currentState?.reload() ?? Future.value(),
      _analyticsKey.currentState?.reload() ?? Future.value(),
    ]);
  }

  Future<void> _openUsernameSheet() async {
    final changed = await ProfileUsernameSheet.show(context);
    if (changed == true && mounted) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeService.isDarkMode,
        LocaleService.languageCode,
      ]),
      builder: (context, _) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);
        final activeColor = ThemeService.getPrimaryColor(isDark);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: activeColor))
              : RefreshIndicator(
                  onRefresh: _refreshAll,
                  color: activeColor,
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Header(
                              textColor: textColor,
                              captionColor: captionColor,
                            ),
                            const SizedBox(height: 24),
                            ProfileHeroCard(
                              username: auth.username,
                              email: auth.email,
                              fullName: auth.currentUser?['name']?.toString(),
                              avatarLetter: auth.avatarLetter,
                              usernameChangesRemaining:
                                  auth.usernameChangesRemaining,
                              onEditUsername: _openUsernameSheet,
                            ),
                            const SizedBox(height: 28),
                            ProfileInsightsSection(
                              calendarKey: _calendarKey,
                              analyticsKey: _analyticsKey,
                            ),
                            const SizedBox(height: 24),
                            const ProfileInboxSection(),
                            const SizedBox(height: 24),
                            const ProfilePreferencesSection(),
                            const SizedBox(height: 28),
                            ProfileLogoutButton(onLogout: widget.onLogout),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Color textColor;
  final Color captionColor;

  const _Header({required this.textColor, required this.captionColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleService.tr('HỒ SƠ CÁ NHÂN', en: 'MY PROFILE'),
          style: TextStyle(
            color: captionColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          LocaleService.tr('Tài khoản', en: 'Account'),
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
