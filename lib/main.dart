import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/core/l10n/generated/app_localizations.dart';
import 'package:hisabet/core/l10n/language_provider.dart';
import 'package:hisabet/core/auth/auth_gate.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/settings/data/repositories/app_settings_repository.dart';
import 'package:hisabet/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  _configurePhoneAuthTesting();

  final prefs = await SharedPreferences.getInstance();
  final initialLanguageCode = await AppSettingsRepository.readInitialLanguageCode();

  final container = ProviderContainer(
    overrides: [
      initialLanguageCodeProvider.overrideWithValue(initialLanguageCode),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  // Pre-load saved threshold from SharedPreferences
  await container.read(lowStockThresholdProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

void _configurePhoneAuthTesting() {
  const testingEnabled = bool.fromEnvironment('PHONE_AUTH_TESTING');
  if (!testingEnabled || !kDebugMode) return;

  const testPhone = String.fromEnvironment('PHONE_AUTH_TEST_NUMBER');
  const testCode = String.fromEnvironment('PHONE_AUTH_TEST_CODE');

  // Apply all testing config in one call.
  // This avoids settings being accidentally overridden by a second call.
  if (testPhone.isNotEmpty && testCode.isNotEmpty) {
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
      phoneNumber: testPhone,
      smsCode: testCode,
    );
    return;
  }

  // Fallback: disable app verification only.
  FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HisabET',

      // Theme Configuration
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // Localization Configuration
      locale: language, // Reactive Locale
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('am')],

      // Home: Auth Gate (Checks Login)
      home: const AuthGate(),
    );
  }
}
