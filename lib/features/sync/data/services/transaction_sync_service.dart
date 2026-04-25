import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:hisabet/core/utils/phone_util.dart';
import 'package:hisabet/features/transactions/data/models/transaction_model.dart';

class TransactionSyncService {
  final FirebaseFirestore _firestore;

  TransactionSyncService(this._firestore);

  /// Pushes a local transaction to the cloud (user's private collection)
  Future<void> saveTransactionToCloud({
    required TransactionModel transaction,
    required String creatorUid,
    required String creatorPhone,
    String? contactPhone,
    String? contactUid,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(creatorUid)
          .collection('transactions')
          .doc(transaction.id);

      final data = {
        'id': transaction.id,
        'amount': transaction.amount.toString(),
        'type': transaction.type.index, // Store as Int index
        'status': transaction.status.index,
        'date': transaction.date.toIso8601String(),
        'description': transaction.description,
        'cartons': transaction.cartons,
        'qty_per_carton': transaction.qtyPerCarton,
        'unit_price': transaction.unitPrice?.toString(),
        'metadata': transaction.metadata,
        'creator_phone': creatorPhone,
        'contact_phone': contactPhone,
        'contact_uid': contactUid,
        'reference_id': transaction.referenceId,
        'last_updated': FieldValue.serverTimestamp(),
      };

      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      // Log error or rethrow, for now silent fail is okay as offline-first implies retry later
      debugPrint('Sync Error: $e');
    }
  }

  /// Fetches transactions created by the contact that involve me (Remote Version)
  /// Fetches transactions created by the contact that involve me (Remote Version)
  /// If [contactUid] is provided, it queries the specific user's subcollection (Better performance, less indexing).
  /// If not, it falls back to Collection Group query (Requires Index).
  Stream<List<TransactionModel>> streamRemoteTransactions({
    required String myPhone,
    String? contactPhone,
    String? contactUid,
  }) {
    // Normalize phones to ensure matching
    final myPhoneSanitized = PhoneUtil.normalize(myPhone);
    final contactPhoneSanitized = contactPhone != null ? PhoneUtil.normalize(contactPhone) : null;

    Query<Map<String, dynamic>> query;

    if (contactUid != null && contactUid.isNotEmpty) {
      query = _firestore
          .collection('users')
          .doc(contactUid)
          .collection('transactions')
          .where('contact_phone', isEqualTo: myPhoneSanitized);
    } else {
      if (contactPhoneSanitized == null) {
        throw ArgumentError('Either contactUid or contactPhone must be provided.');
      }
      query = _firestore
          .collectionGroup('transactions')
          .where('creator_phone', isEqualTo: contactPhoneSanitized)
          .where('contact_phone', isEqualTo: myPhoneSanitized);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionModel(
          id: data['id'] ?? doc.id,
          contactId: 'REMOTE',
          type: TransactionType.values[data['type'] as int],
            status: data['status'] == null
              ? TransactionStatus.pending
              : TransactionStatus.values[int.tryParse(data['status'].toString()) ?? 0],
          amount: Decimal.parse(data['amount'] as String),
          date: DateTime.parse(data['date'] as String),
          description: data['description'],
          cartons: data['cartons'] == null ? null : int.tryParse(data['cartons'].toString()),
          qtyPerCarton: data['qty_per_carton'] == null
            ? null
            : int.tryParse(data['qty_per_carton'].toString()),
          unitPrice: data['unit_price'] != null
              ? Decimal.tryParse(data['unit_price'].toString())
              : null,
          metadata: data['metadata'],
          referenceId: data['reference_id'],
        );
      }).toList();
    });
  }
}
