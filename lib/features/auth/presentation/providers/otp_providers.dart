import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/features/auth/data/services/otp_service.dart';
import 'package:hisabet/features/auth/data/services/pnv_service.dart';

/// The SMS-code phone-verification provider (the fallback path).
///
/// Telegram verification — the primary path — lives in
/// `lib/features/phone_identity/`; it needs no [OtpService] because the
/// backend proves the number and writes it.
///
/// To move off Firebase phone auth — e.g. onto Telegram Gateway or a local
/// Ethiopian SMS aggregator — write a new [OtpService] implementation and
/// return it here. Nothing in the UI layer needs to change.
final otpServiceProvider = Provider<OtpService>((ref) {
  return FirebaseOtpService(FirebaseAuth.instance);
});

/// Carrier-side verification: no SMS, no code to type.
///
/// It sits alongside [otpServiceProvider] rather than replacing it, because it
/// only works on carriers Firebase has integrated with — see [PnvService].
final pnvServiceProvider = Provider<PnvService>((ref) => const PnvService());

/// Whether this device could attempt PNV. Resolves once at startup.
final pnvAvailableProvider = FutureProvider<bool>((ref) {
  return ref.watch(pnvServiceProvider).isAvailable();
});
