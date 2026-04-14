import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, authorize them
        if (snapshot.hasData) {
          if (kDevBypassProfileCheck) {
            return const MainScaffold();
          }
          return const ProfileCheckGate();
        }

        // Otherwise, show login/onboarding
        return const OnboardingScreen();
      },
    );
  }
}

class ProfileCheckGate extends StatefulWidget {
  const ProfileCheckGate({super.key});

  @override
  State<ProfileCheckGate> createState() => _ProfileCheckGateState();
}

class _ProfileCheckGateState extends State<ProfileCheckGate> {
  bool _isProfileComplete(Map<String, dynamic>? data) {
    if (data == null) return false;
    final hasName = data['name']?.toString().trim().isNotEmpty == true;
    final hasPhone = data['phone']?.toString().trim().isNotEmpty == true;
    final hasAccountType = data['accountType']?.toString().trim().isNotEmpty == true;
    return hasName && hasPhone && hasAccountType;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const OnboardingScreen();
    if (kDevBypassProfileCheck) return const MainScaffold();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        if (_isProfileComplete(data)) {
          return const MainScaffold();
        }

        return const OnboardingScreen(startAtProfile: true);
      },
    );
  }
}
