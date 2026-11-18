import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/phone_identity/presentation/widgets/phone_verification_panel.dart';

/// Shown by `AuthGate` to an account whose profile is otherwise complete but
/// which has no verified phone number — typically an account created before
/// a phone number became mandatory.
///
/// It never navigates: once verification succeeds, `users/{uid}` changes and
/// the gate's profile stream routes on to the app.
class PhoneRequiredScreen extends StatelessWidget {
  const PhoneRequiredScreen({super.key});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      final google = GoogleSignIn();
      if (await google.isSignedIn()) await google.signOut();
    } catch (_) {
      // No Google session (phone sign-in) — nothing to clear.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your phone'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, size: AppDimensions.iconSm),
            label: const Text('Sign out'),
          ),
          const SizedBox(width: AppDimensions.sm),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePaddingH,
            AppDimensions.lg,
            AppDimensions.pagePaddingH,
            AppDimensions.xxxl,
          ),
          children: const [
            AppMissionHeader(
              eyebrow: 'ONE LAST STEP',
              title: 'Add your phone number',
              subtitle:
                  'Partners find you by your number, and it is how your ledger is matched with theirs. '
                  'Each number can belong to only one HisabET account.',
              padding: EdgeInsets.zero,
            ),
            SizedBox(height: AppDimensions.xl),
            AppFormSection(
              title: 'Phone number',
              icon: Icons.verified_user_outlined,
              children: [PhoneVerificationPanel()],
            ),
          ],
        ),
      ),
    );
  }
}
