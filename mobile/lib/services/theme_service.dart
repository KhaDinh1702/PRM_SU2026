import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isSketchyMode = ValueNotifier<bool>(false);
  static const String _themeKey = 'is_dark_mode';

  // Initialize theme state from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_themeKey) ?? false;
  }

  // Toggle between dark and light themes
  static Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode.value);
  }

  // Sketchy Mode has been deprecated
  static Future<void> toggleSketchyMode() async {
    // Deprecated: Do nothing
  }

  // --- Dynamic Color Palettes adapting to Dark/Light Mode ---

  static Color getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
  }

  static List<Color> getGradientColors(bool isDark) {
    return isDark
        ? [const Color(0xFF0D1117), const Color(0xFF161B22), const Color(0xFF0D1117)]
        : [const Color(0xFFFFFFFF), const Color(0xFFF6F8FA), const Color(0xFFFFFFFF)];
  }

  static Color getCardColor(bool isDark) {
    return isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA);
  }

  static Color getBorderColor(bool isDark) {
    return isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
  }

  static Color getTextColor(bool isDark) {
    return isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
  }

  static Color getSubTextColor(bool isDark) {
    return isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);
  }

  static Color getCaptionColor(bool isDark) {
    // Dark value was #484F58 — contrast vs #0D1117 background was ~2.5:1
    // (fails WCAG AA). Move to #6E7681 which gives ~5.5:1 while still
    // staying one tier dimmer than `getSubTextColor` (#8B949E) so we keep
    // the 3-step text hierarchy.
    return isDark ? const Color(0xFF6E7681) : const Color(0xFF8C959F);
  }

  static Color getDialogBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF);
  }

  // GitHub Theme Accent & Primary colors
  static Color getPrimaryColor(bool isDark) {
    return isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
  }

  static Color getButtonColor(bool isDark) {
    return isDark ? const Color(0xFF238636) : const Color(0xFF1F883D);
  }

  static Color getButtonHoverColor(bool isDark) {
    return isDark ? const Color(0xFF2EA44F) : const Color(0xFF1A7F37);
  }
}
