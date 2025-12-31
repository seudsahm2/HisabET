import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/data/repositories/contacts_repository.dart';

/// Provider for the database instance
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
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
