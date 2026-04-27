import 'dart:async';
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
      debugPrint('🚀 [SYNC SAVE] Saving Tx: ${transaction.id} to /users/$creatorUid/transactions');
      debugPrint('🚀 [SYNC SAVE] -> contactUid: $contactUid, contactPhone: $contactPhone');

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
      debugPrint('🚀 [SYNC SAVE] ✅ Success!');
    } catch (e) {
      debugPrint('❌ [SYNC SAVE] ERROR: $e');
    }
  }

  /// Fetches transactions created by the contact that involve me (Remote Version)
  Stream<List<TransactionModel>> streamRemoteTransactions({
    required String myUid,
    String? myPhone,
    String? contactPhone,
    String? contactUid,
  }) {
    debugPrint('📡 [STREAM INIT] Starting remote stream.');
    debugPrint('📡 [STREAM INIT] myUid: $myUid, myPhone: $myPhone');
    debugPrint('📡 [STREAM INIT] contactUid: $contactUid, contactPhone: $contactPhone');

    final myPhoneSanitized = myPhone != null ? PhoneUtil.normalize(myPhone) : null;
    final contactPhoneSanitized = contactPhone != null ? PhoneUtil.normalize(contactPhone) : null;

    final controller = StreamController<List<TransactionModel>>.broadcast();

    List<TransactionModel> uidList = [];
    List<TransactionModel> phoneList = [];

    void emitCombined() {
      final map = <String, TransactionModel>{};
      for (final t in uidList) map[t.id] = t;
      for (final t in phoneList) map[t.id] = t;
      final combined = map.values.toList();
      combined.sort((a, b) => b.date.compareTo(a.date));
      debugPrint('🔄 [STREAM EMIT] Emitting combined list of length: ${combined.length} (UID list: ${uidList.length}, Phone list: ${phoneList.length})');
      controller.add(combined);
    }

    StreamSubscription? uidSub;
    StreamSubscription? phoneSub;

    List<TransactionModel> mapDocs(QuerySnapshot<Map<String, dynamic>> snapshot, String source) {
      debugPrint('📦 [STREAM DATA - $source] Received snapshot with ${snapshot.docs.length} docs.');
      final list = <TransactionModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          list.add(TransactionModel(
            id: data['id'] ?? doc.id,
            contactId: 'REMOTE',
            type: TransactionType.values[int.tryParse(data['type']?.toString() ?? '0') ?? 0],
            status: data['status'] == null
                ? TransactionStatus.pending
                : TransactionStatus.values[int.tryParse(data['status'].toString()) ?? 0],
            amount: Decimal.tryParse(data['amount']?.toString() ?? '0') ?? Decimal.zero,
            date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
            description: data['description']?.toString(),
            cartons: data['cartons'] == null ? null : int.tryParse(data['cartons'].toString()),
            qtyPerCarton: data['qty_per_carton'] == null
                ? null
                : int.tryParse(data['qty_per_carton'].toString()),
            unitPrice: data['unit_price'] != null
                ? Decimal.tryParse(data['unit_price'].toString())
                : null,
            metadata: data['metadata'] as Map<String, dynamic>?,
            referenceId: data['reference_id']?.toString(),
          ));
        } catch (e) {
          debugPrint('❌ [STREAM MAP ERROR] Error mapping remote doc ${doc.id}: $e');
        }
      }
      return list;
    }

    controller.onListen = () {
      debugPrint('🎧 [STREAM LISTEN] UI has subscribed to the stream.');
      if (contactUid != null && contactUid.isNotEmpty) {
        debugPrint('🔍 [STREAM QUERY] Using Subcollection Query because contactUid is known: /users/$contactUid/transactions');
        uidSub = _firestore
            .collection('users')
            .doc(contactUid)
            .collection('transactions')
            .where('contact_uid', isEqualTo: myUid)
            .snapshots()
            .listen((snapshot) {
              uidList = mapDocs(snapshot, 'UID-SUB');
              emitCombined();
            }, onError: (e) {
              debugPrint('🛑 [STREAM UID ERROR] Subcollection UID query failed: $e');
              emitCombined();
            });

        if (myPhoneSanitized != null) {
          phoneSub = _firestore
              .collection('users')
              .doc(contactUid)
              .collection('transactions')
              .where('contact_phone', isEqualTo: myPhoneSanitized)
              .snapshots()
              .listen((snapshot) {
                phoneList = mapDocs(snapshot, 'PHONE-SUB');
                emitCombined();
              }, onError: (e) {
                debugPrint('🛑 [STREAM PHONE ERROR] Subcollection Phone query failed: $e');
                emitCombined();
              });
        }
      } else {
        debugPrint('🔍 [STREAM QUERY] contactUid is NULL! Falling back to CollectionGroup query.');
        if (contactPhoneSanitized == null) {
          debugPrint('🛑 [STREAM FATAL] Both contactUid and contactPhone are missing. Cannot query.');
          controller.addError(ArgumentError('Either contactUid or contactPhone must be provided.'));
          return;
        }
        
        uidSub = _firestore
            .collectionGroup('transactions')
            .where('creator_phone', isEqualTo: contactPhoneSanitized)
            .where('contact_uid', isEqualTo: myUid)
            .snapshots()
            .listen((snapshot) {
              uidList = mapDocs(snapshot, 'UID-GROUP');
              emitCombined();
            }, onError: (e) {
              debugPrint('🛑 [STREAM UID ERROR] CollectionGroup UID query failed. DOES INDEX EXIST? Error: $e');
              emitCombined();
            });

        if (myPhoneSanitized != null) {
          phoneSub = _firestore
              .collectionGroup('transactions')
              .where('creator_phone', isEqualTo: contactPhoneSanitized)
              .where('contact_phone', isEqualTo: myPhoneSanitized)
              .snapshots()
              .listen((snapshot) {
                phoneList = mapDocs(snapshot, 'PHONE-GROUP');
                emitCombined();
              }, onError: (e) {
                debugPrint('🛑 [STREAM PHONE ERROR] CollectionGroup Phone query failed. DOES INDEX EXIST? Error: $e');
                emitCombined();
              });
        }
      }
    };

    controller.onCancel = () {
      debugPrint('🚫 [STREAM CANCEL] UI unsubscribed from stream.');
      uidSub?.cancel();
      phoneSub?.cancel();
    };

    return controller.stream;
  }
}
