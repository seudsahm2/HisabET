import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/auth/providers/auth_providers.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/data/repositories/contacts_repository.dart';

/// Provider for the database instance
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final user = ref.watch(authStateProvider).value;
  final uid = user?.uid ?? 'unauthenticated';
  final db = AppDatabase(uid);
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for the ContactsRepository
final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ContactsRepositoryImpl(db);
});

/// Provider for the list of all contacts
final allContactsProvider = FutureProvider<List<ContactModel>>((ref) async {
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.getAllContacts();
});

/// Provider for a single contact (reactive to balance updates)
final contactProvider = StreamProvider.family<ContactModel?, String>((
  ref,
  id,
) {
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.watchContact(id);
});

/// Provider for incoming connection requests
final connectionRequestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('connection_requests')
      .where('toUid', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
});
