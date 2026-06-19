import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static final ValueNotifier<String> languageCode = ValueNotifier<String>('en');
  static const String _langKey = 'app_language_code';

  /// Initialize language state and intl date symbols for supported locales.
  static Future<void> init() async {
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('vi', null);

    final prefs = await SharedPreferences.getInstance();
    languageCode.value = prefs.getString(_langKey) ?? 'en';
  }

  // Toggle between vi and en
  static Future<void> toggleLanguage() async {
    languageCode.value = languageCode.value == 'vi' ? 'en' : 'vi';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, languageCode.value);
  }

  // Helper function for inline translation
  static String tr(String viText, {String? en}) {
    if (languageCode.value == 'en' && en != null) {
      return en;
    }
    return viText; // default to Vietnamese
  }
}
