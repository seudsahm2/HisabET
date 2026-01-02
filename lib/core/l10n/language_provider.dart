import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple provider to manage locale state
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  // Default to English, but could load from SharedPreferences/Hive
  LanguageNotifier() : super(const Locale('en'));

  void toggleLanguage() {
    if (state.languageCode == 'en') {
      state = const Locale('am');
    } else {
      state = const Locale('en');
    }
  }

  void setLanguage(Locale locale) {
    state = locale;
  }
}
