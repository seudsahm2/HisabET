import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/tenders/data/tender_model.dart';
import 'package:hisabet/features/tenders/data/tender_win_service.dart';
import 'package:hisabet/features/tenders/data/tenders_repository.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';

export 'package:hisabet/features/tenders/data/tender_model.dart';

final tendersRepositoryProvider = Provider<TendersRepository>(
  (ref) => TendersRepository(FirebaseFirestore.instance),
);

final tenderWinServiceProvider = Provider<TenderWinService>((ref) {
  return TenderWinService(
    tenders: ref.watch(tendersRepositoryProvider),
    contacts: ref.watch(contactsRepositoryProvider),
    products: ref.watch(productsRepositoryProvider),
    transactions: ref.watch(transactionsRepositoryProvider),
    firestore: FirebaseFirestore.instance,
  );
});

final activeTendersProvider = StreamProvider<List<TenderModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('tenders')
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TenderModel.fromJson(doc.data(), doc.id))
          .toList());
});

final myTenderActivityProvider = StreamProvider.family<List<TenderModel>, String>((ref, myUid) {
  return FirebaseFirestore.instance
      .collection('tenders')
      .where('winnerUid', isEqualTo: myUid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TenderModel.fromJson(doc.data(), doc.id))
          .toList());
});
