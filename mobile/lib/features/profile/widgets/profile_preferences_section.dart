import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import 'profile_section_header.dart';
import 'profile_toggle_tile.dart';

/// Theme + language toggles.
///
/// Subscribes directly to [ThemeService.isDarkMode] and
/// [LocaleService.languageCode] so a parent caller can mark this widget
/// `const` without breaking reactivity — the inner [ListenableBuilder]
/// always triggers a rebuild when either value changes.
class ProfilePreferencesSection extends StatelessWidget {
  const ProfilePreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeService.isDarkMode,
        LocaleService.languageCode,
      ]),
      builder: (context, _) {
        final isDark = ThemeService.isDarkMode.value;
        final accent = ThemeService.getPrimaryColor(isDark);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileSectionHeader(
              label: LocaleService.tr('CÀI ĐẶT', en: 'PREFERENCES'),
            ),
            ProfileToggleTile(
              icon:
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: accent,
              title: LocaleService.tr('Chế độ tối', en: 'Dark mode'),
              subtitle: LocaleService.tr(
                isDark ? 'Đang bật' : 'Đang tắt',
                en: isDark ? 'On' : 'Off',
              ),
              value: isDark,
              onChanged: (_) => ThemeService.toggleTheme(),
              onThumbIcon: Icons.dark_mode_rounded,
              offThumbIcon: Icons.light_mode_rounded,
            ),
            const SizedBox(height: 10),
            ProfileToggleTile(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF06B6D4),
              title: LocaleService.tr('Ngôn ngữ', en: 'Language'),
              subtitle: LocaleService.languageCode.value == 'en'
                  ? 'English'
                  : 'Tiếng Việt',
              value: LocaleService.languageCode.value == 'en',
              onChanged: (_) => LocaleService.toggleLanguage(),
              onThumbIcon: Icons.public_rounded,
              offThumbIcon: Icons.public_rounded,
            ),
          ],
        );
      },
    );
  }
}
