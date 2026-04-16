import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final initialLanguageCodeProvider = Provider<String?>((ref) => null);

// Simple provider to manage locale state
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final initialLanguageCode = ref.watch(initialLanguageCodeProvider);
  return LanguageNotifier(initialLanguageCode: initialLanguageCode);
});

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier({String? initialLanguageCode})
    : super(Locale((initialLanguageCode == 'am') ? 'am' : 'en'));

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
