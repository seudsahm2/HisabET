import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
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
    required String contactPhone,
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
        'date': transaction.date.toIso8601String(),
        'description': transaction.description,
        'metadata': transaction.metadata,
        'creator_phone': creatorPhone,
        'contact_phone': contactPhone,
        'reference_id': transaction.referenceId,
        'last_updated': FieldValue.serverTimestamp(),
      };

      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      // Log error or rethrow, for now silent fail is okay as offline-first implies retry later
      print('Sync Error: $e');
    }
  }

  /// Fetches transactions created by the contact that involve me (Remote Version)
  /// Fetches transactions created by the contact that involve me (Remote Version)
  /// If [contactUid] is provided, it queries the specific user's subcollection (Better performance, less indexing).
  /// If not, it falls back to Collection Group query (Requires Index).
  Stream<List<TransactionModel>> streamRemoteTransactions({
    required String myPhone,
    required String contactPhone,
    String? contactUid,
  }) {
    // Normalize phones to ensure matching
    final myPhoneSanitized = PhoneUtil.normalize(myPhone);
    final contactPhoneSanitized = PhoneUtil.normalize(contactPhone);

    Query<Map<String, dynamic>> query;

    if (contactUid != null && contactUid.isNotEmpty) {
      query = _firestore
          .collection('users')
          .doc(contactUid)
          .collection('transactions')
          .where('contact_phone', isEqualTo: myPhoneSanitized);
    } else {
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
          amount: Decimal.parse(data['amount'] as String),
          date: DateTime.parse(data['date'] as String),
          description: data['description'],
          metadata: data['metadata'],
          referenceId: data['reference_id'],
        );
      }).toList();
    });
  }
}
