import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/sync/domain/entities/user_profile.dart';

/// Provides the current authenticated user's Firebase [User] stream.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provides the current user's profile data from Firestore as a stream.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return null;
        }
        return UserProfile.fromJson(snapshot.data()!);
      });
});

/// A convenience provider that exposes just the current user's roles.
/// Returns an empty list if the user is not logged in or has no roles.
final userRolesProvider = Provider<List<String>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.roles ?? [];
});
