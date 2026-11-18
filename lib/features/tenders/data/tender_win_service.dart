import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import 'package:hisabet/features/contacts/data/repositories/contacts_repository.dart';
import 'package:hisabet/features/inventory/data/repositories/products_repository.dart';
import 'package:hisabet/features/tenders/data/tender_model.dart';
import 'package:hisabet/features/tenders/data/tenders_repository.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';
import 'package:hisabet/features/transactions/data/repositories/transactions_repository.dart';

/// Winning a tender, end to end: claim it in the cloud, then record it in
/// the broker's own books.
///
/// Order matters. The claim is the only contested step, so it goes first;
/// nothing is written locally unless it succeeded. The local steps then use
/// a **local contact id** for the importer — the old code passed the
/// importer's Firestore UID as `contactId`, which the transactions table's
/// foreign key rejected, so every win failed after already being claimed.
class TenderWinService {
  TenderWinService({
    required TendersRepository tenders,
    required ContactsRepository contacts,
    required ProductsRepository products,
    required TransactionsRepository transactions,
    required FirebaseFirestore firestore,
  })  : _tenders = tenders,
        _contacts = contacts,
        _products = products,
        _transactions = transactions,
        _db = firestore;

  final TendersRepository _tenders;
  final ContactsRepository _contacts;
  final ProductsRepository _products;
  final TransactionsRepository _transactions;
  final FirebaseFirestore _db;

  Future<void> win({
    required TenderModel tender,
    required String winnerUid,
    required String productName,
    required Decimal pricePerCarton,
  }) async {
    await _tenders.claimWin(tenderId: tender.id, winnerUid: winnerUid);

    try {
      final contactId = await _contacts.ensureLinkedContact(
        linkedUserUid: tender.importerUid,
        name: tender.importerName,
        phone: await _importerPhone(tender.importerUid),
        isSupplier: true,
      );

      await _products.addProduct(
        name: productName,
        itemNumber: tender.itemNumber,
        photoUrl: tender.photoUrl,
        colorDistribution: tender.colorDistribution,
        unit: 'carton',
        itemsPerCarton: tender.seriesSize,
        seriesSize: tender.seriesSize,
        stockQuantity: tender.cartons,
        supplierContactId: contactId,
        costPrice: pricePerCarton,
        sellingPrice: pricePerCarton,
        businessRole: 'broker',
      );

      await _transactions.addTransaction(
        contactId: contactId,
        type: TransactionType.goodsTaken,
        amount: pricePerCarton * Decimal.fromInt(tender.cartons),
        date: DateTime.now(),
        description: 'Won Tender: ${tender.itemNumber} — $productName',
        metadata: {
          'source': 'tender',
          'tenderId': tender.id,
          'importerUid': tender.importerUid,
          'product_snapshot': {
            'name': productName,
            'itemNumber': tender.itemNumber,
            'photoUrl': tender.photoUrl,
            'cartons': tender.cartons,
            'seriesSize': tender.seriesSize,
            'colorDistribution': tender.colorDistribution,
            'costPrice': pricePerCarton.toString(),
          },
        },
      );
    } catch (e) {
      // The tender is already ours in the cloud; say so plainly rather than
      // letting the user think the win failed and try again.
      throw TenderException(
        'You won this tender, but it could not be added to your books: $e',
      );
    }
  }

  /// The importer's verified number, so the contact matches their ledger.
  /// Optional: a win must still go through offline or for older profiles.
  Future<String?> _importerPhone(String uid) async {
    try {
      final phone = (await _db.collection('users').doc(uid).get()).data()?['phone'];
      return phone is String && phone.isNotEmpty ? phone : null;
    } catch (e) {
      debugPrint('[TenderWinService] importer phone lookup failed: $e');
      return null;
    }
  }
}
