import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/auth/providers/auth_providers.dart';
import 'package:hisabet/features/phone_identity/data/phone_claim_repository.dart';
import 'package:hisabet/features/phone_identity/data/phone_identity_config.dart';
import 'package:hisabet/features/phone_identity/data/telegram_login_service.dart';
import 'package:hisabet/features/phone_identity/domain/verified_phone.dart';

/// "Log In with Telegram", or null when this build has no Telegram client id
/// or backend URL configured (see AppConfig). The UI hides Telegram then.
final telegramLoginServiceProvider = Provider<TelegramLoginService?>((ref) {
  final config = PhoneIdentityConfig.telegramLogin;
  if (config == null) return null;
  return TelegramLoginService(auth: FirebaseAuth.instance, config: config);
});

final phoneClaimRepositoryProvider = Provider<PhoneClaimRepository>((ref) {
  return PhoneClaimRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
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
