import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/auth/providers/auth_providers.dart';
import 'package:hisabet/features/phone_identity/data/phone_claim_repository.dart';
import 'package:hisabet/features/phone_identity/data/phone_identity_config.dart';
import 'package:hisabet/features/phone_identity/data/telegram_launcher.dart';
import 'package:hisabet/features/phone_identity/data/telegram_phone_verifier.dart';
import 'package:hisabet/features/phone_identity/data/telegram_sign_in_service.dart';
import 'package:hisabet/features/phone_identity/domain/telegram_verification.dart';
import 'package:hisabet/features/phone_identity/domain/verified_phone.dart';

/// Telegram verification, or null when no bot is configured for this build
/// (`--dart-define=TELEGRAM_BOT_USERNAME=...`). The UI hides the option then.
final telegramPhoneVerifierProvider = Provider<TelegramPhoneVerifier?>((ref) {
  final bot = PhoneIdentityConfig.telegramBotUsername;
  if (bot == null) return null;
  return FirestoreTelegramPhoneVerifier(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    botUsername: bot,
  );
});

/// "Continue with Telegram", or null unless both the bot name and the
/// backend URL are configured for this build.
final telegramSignInServiceProvider = Provider<TelegramSignInService?>((ref) {
  final verifier = ref.watch(telegramPhoneVerifierProvider);
  final exchangeUrl = PhoneIdentityConfig.telegramSignInUrl;
  if (verifier == null || exchangeUrl == null) return null;
  return TelegramSignInService(
    auth: FirebaseAuth.instance,
    verifier: verifier,
    exchangeUrl: exchangeUrl,
  );
});

final telegramLauncherProvider =
    Provider<TelegramLauncher>((ref) => const TelegramLauncher());

final phoneClaimRepositoryProvider = Provider<PhoneClaimRepository>((ref) {
  return PhoneClaimRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Live state of one Telegram verification session.
final telegramSessionProvider = StreamProvider.autoDispose
    .family<TelegramVerificationSession, String>((ref, sessionId) {
  final verifier = ref.watch(telegramPhoneVerifierProvider);
  if (verifier == null) return const Stream.empty();
  return verifier.watch(sessionId);
});

/// The signed-in account's proven, unique phone number — or null.
///
/// This is the single answer to "is this account phone-verified?". It reads
/// `users/{uid}` so it reflects every path equally: Telegram (written by the
/// backend), SMS code and phone sign-in (written by [PhoneClaimRepository]).
final verifiedPhoneProvider = StreamProvider<VerifiedPhone?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => VerifiedPhone.fromProfile(snap.data()));
});
