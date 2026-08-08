import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/features/auth/data/services/otp_service.dart';

/// The active phone-verification provider.
///
/// To move off Firebase phone auth — e.g. onto Telegram Gateway or a local
/// Ethiopian SMS aggregator — write a new [OtpService] implementation and
/// return it here. Nothing in the UI layer needs to change.
final otpServiceProvider = Provider<OtpService>((ref) {
  return FirebaseOtpService(FirebaseAuth.instance);
});
