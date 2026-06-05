import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isSketchyMode = ValueNotifier<bool>(false);
  static const String _themeKey = 'is_dark_mode';
  static const String _sketchyKey = 'is_sketchy_mode';

  // Initialize theme state from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_themeKey) ?? true;
    isSketchyMode.value = prefs.getBool(_sketchyKey) ?? false;
  }

  // Toggle between dark and light themes
  static Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode.value);
  }

  // Toggle between sketchy and standard themes
  static Future<void> toggleSketchyMode() async {
    isSketchyMode.value = !isSketchyMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sketchyKey, isSketchyMode.value);
  }

  // --- Dynamic Color Palettes adapting to Dark/Light Mode ---

  static Color getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF070B19) : const Color(0xFFF8FAFC);
  }

  static List<Color> getGradientColors(bool isDark) {
    return isDark
        ? [const Color(0xFF070B19), const Color(0xFF0F172A), const Color(0xFF020617)]
        : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)];
  }

  static Color getCardColor(bool isDark) {
    return isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03);
  }

  static Color getBorderColor(bool isDark) {
    return isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05);
  }

  static Color getTextColor(bool isDark) {
    return isDark ? Colors.white : const Color(0xFF0F172A);
  }

  static Color getSubTextColor(bool isDark) {
    return isDark ? Colors.white60 : const Color(0xFF475569);
  }

  static Color getCaptionColor(bool isDark) {
    return isDark ? Colors.white38 : const Color(0xFF64748B);
  }

  static Color getDialogBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF0F1524) : Colors.white;
  }
}
