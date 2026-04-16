import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart'
    show appDatabaseProvider, allContactsProvider;
import 'package:hisabet/features/suppliers/data/models/supplier_model.dart';
import 'package:hisabet/features/suppliers/data/repositories/suppliers_repository.dart';

final suppliersRepositoryProvider = Provider<SuppliersRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SuppliersRepositoryImpl(db);
});

/// Reads suppliers from the unified contacts table (role = supplier/both).
/// This is the correct source for the B2B Tenders listing.
final supplierContactsProvider = FutureProvider<List<ContactModel>>((ref) async {
  final contacts = await ref.watch(allContactsProvider.future);
  return contacts
      .where((c) => c.role == ContactRole.supplier || c.role == ContactRole.both)
      .toList();
});

final allSuppliersProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final repo = ref.watch(suppliersRepositoryProvider);
  return repo.getAllSuppliers();
});

final supplierProvider = FutureProvider.family<SupplierModel?, String>((ref, id) async {
  final repo = ref.watch(suppliersRepositoryProvider);
  return repo.getSupplierById(id);
});