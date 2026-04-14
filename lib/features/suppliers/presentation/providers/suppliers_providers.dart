import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart'
    show appDatabaseProvider;
import 'package:hisabet/features/suppliers/data/models/supplier_model.dart';
import 'package:hisabet/features/suppliers/data/repositories/suppliers_repository.dart';

final suppliersRepositoryProvider = Provider<SuppliersRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SuppliersRepositoryImpl(db);
});

final allSuppliersProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final repo = ref.watch(suppliersRepositoryProvider);
  return repo.getAllSuppliers();
});

final supplierProvider = FutureProvider.family<SupplierModel?, String>((ref, id) async {
  final repo = ref.watch(suppliersRepositoryProvider);
  return repo.getSupplierById(id);
});