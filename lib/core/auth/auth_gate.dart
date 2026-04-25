import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';

import 'package:hisabet/features/sync/presentation/screens/onboarding_screen.dart';
import 'package:hisabet/features/home/presentation/screens/main_scaffold.dart';

const bool kDevBypassProfileCheck = bool.fromEnvironment(
  'DEV_BYPASS_PROFILE_CHECK',
);

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('[AuthGate] Waiting for auth state...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          debugPrint('[AuthGate] User is logged in: ${snapshot.data!.uid}. Routing to ProfileCheckGate.');
          if (kDevBypassProfileCheck) {
            debugPrint('[AuthGate] Dev bypass active -> MainScaffold');
            return const MainScaffold();
          }
          return const ProfileCheckGate();
        }

        debugPrint('[AuthGate] No user logged in -> Login page.');
        return const OnboardingScreen();
      },
    );
  }
}

class ProfileCheckGate extends ConsumerStatefulWidget {
  const ProfileCheckGate({super.key});

  @override
  ConsumerState<ProfileCheckGate> createState() => _ProfileCheckGateState();
}

class _ProfileCheckGateState extends ConsumerState<ProfileCheckGate> {
  bool _isProfileComplete(Map<String, dynamic>? data, User user) {
    if (data == null) return false;
    final hasName = data['name']?.toString().trim().isNotEmpty == true;
    final hasRoles = data['roles'] != null && (data['roles'] as List).isNotEmpty;
    // Check Firestore-stored contact info first, then fall back to Firebase Auth directly
    final firestorePhone = data['phone']?.toString().trim().isNotEmpty == true;
    final firestoreEmail = data['email']?.toString().trim().isNotEmpty == true;
    final authPhone = user.phoneNumber?.isNotEmpty == true;
    final authEmail = user.email?.isNotEmpty == true;
    final hasContact = firestorePhone || firestoreEmail || authPhone || authEmail;
    debugPrint('[ProfileCheckGate] hasName=$hasName, hasRoles=$hasRoles, firestorePhone=$firestorePhone, firestoreEmail=$firestoreEmail, authPhone=$authPhone, authEmail=$authEmail');
    return hasName && hasContact && hasRoles;
  }

  Future<void> _signOutAndWipe() async {
    debugPrint('[ProfileCheckGate] Signing out user due to incomplete profile or deleted account.');
    try {
      await ref.read(appDatabaseProvider).clearAllData();
      debugPrint('[ProfileCheckGate] Local database wiped.');
    } catch (e) {
      debugPrint('[ProfileCheckGate] Error wiping database: $e');
    }
    
    await FirebaseAuth.instance.signOut();
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[ProfileCheckGate] currentUser is null -> Login page.');
      return const OnboardingScreen();
    }
    if (kDevBypassProfileCheck) {
      debugPrint('[ProfileCheckGate] Dev bypass -> MainScaffold');
      return const MainScaffold();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('[ProfileCheckGate] Waiting for Firestore profile (uid=${user.uid})...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint('[ProfileCheckGate] Firestore error: ${snapshot.error}');
          return Scaffold(
            body: Center(child: Text('Connection error: ${snapshot.error}')),
          );
        }

        final docExists = snapshot.data?.exists == true;
        final data = snapshot.data?.data() as Map<String, dynamic>?;

        debugPrint('[ProfileCheckGate] Firestore snapshot received. docExists=$docExists, data keys=${data?.keys.toList()}');

        if (_isProfileComplete(data, user)) {
          debugPrint('[ProfileCheckGate] Profile is COMPLETE -> MainScaffold ✓');

          // Silently backfill email/phone into Firestore if missing.
          // This fixes existing Google OAuth users whose email was never saved.
          final firestoreEmail = data?['email']?.toString().trim() ?? '';
          final firestorePhone = data?['phone']?.toString().trim() ?? '';
          final authEmail = user.email ?? '';
          final authPhone = user.phoneNumber ?? '';
          final needsUpdate = (firestoreEmail.isEmpty && authEmail.isNotEmpty) ||
              (firestorePhone.isEmpty && authPhone.isNotEmpty);
          if (needsUpdate) {
            final updates = <String, dynamic>{};
            if (firestoreEmail.isEmpty && authEmail.isNotEmpty) updates['email'] = authEmail;
            if (firestorePhone.isEmpty && authPhone.isNotEmpty) updates['phone'] = authPhone;
            debugPrint('[ProfileCheckGate] Backfilling missing fields: $updates');
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update(updates)
                .catchError((e) => debugPrint('[ProfileCheckGate] Backfill error: $e'));
          }

          return const MainScaffold();
        }

        if (!docExists) {
          // Verify if the Firebase Auth user actually still exists on the backend
          user.reload().then((_) {
            // User still exists in Auth, but Firestore doc is missing.
          }).catchError((e) {
            if (e is FirebaseAuthException) {
              if (e.code == 'user-not-found' || e.code == 'user-disabled') {
                debugPrint('[ProfileCheckGate] Account deleted/disabled on backend. Wiping data and signing out.');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _signOutAndWipe();
                });
              } else {
                debugPrint('[ProfileCheckGate] user.reload() failed with code: ${e.code}. Ignoring due to possible network error.');
              }
            }
          });

          // Brand new user who just authenticated — show profile setup
          debugPrint('[ProfileCheckGate] New user (no Firestore doc) -> Profile setup page.');
          return const OnboardingScreen(startAtProfile: true);
        }

        // Doc exists but profile is still incomplete (e.g. missing roles, name, or contact).
        // Show Profile page so the user can complete it.
        final existingRoles = (data?['roles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        debugPrint('[ProfileCheckGate] Doc exists but profile INCOMPLETE -> Profile setup page. existingRoles=$existingRoles');
        return OnboardingScreen(startAtProfile: true, initialRoles: existingRoles);
      },
    );
  }
}
