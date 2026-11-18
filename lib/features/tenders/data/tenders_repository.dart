import 'package:cloud_firestore/cloud_firestore.dart';

/// Why a tender action was refused, phrased for end users.
class TenderException implements Exception {
  const TenderException(this.message);
  final String message;

  @override
  String toString() => 'TenderException: $message';
}

/// Cloud side of the B2B tender board (`tenders/{id}`).
///
/// Tenders are the one place two *different* accounts compete for the same
/// record, so it lives in Firestore rather than the local database. The rules
/// in `firestore.rules` → TENDERS enforce the same invariants server-side;
/// the checks here exist to give a clear message instead of a bare
/// permission-denied.
class TendersRepository {
  TendersRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _tenders =>
      _db.collection('tenders');

  Future<void> postTender({
    required String importerUid,
    required String importerName,
    required String itemNumber,
    required int cartons,
    required int seriesSize,
    required double price,
  }) async {
    if (itemNumber.trim().isEmpty) {
      throw const TenderException('Enter the item / style number.');
    }
    if (cartons <= 0 || seriesSize <= 0 || price <= 0) {
      throw const TenderException('Cartons, series size and price must be above zero.');
    }
    try {
      await _tenders.add({
        'importerUid': importerUid,
        'importerName': importerName,
        'itemNumber': itemNumber.trim(),
        'cartons': cartons,
        'seriesSize': seriesSize,
        'price': price,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw TenderException(e.code == 'permission-denied'
          ? 'Only suppliers with a verified phone number can post tenders.'
          : 'Could not post the tender (${e.code}).');
    }
  }

  /// Claims an open tender for [winnerUid].
  ///
  /// Runs as a transaction so that when two brokers tap "Win" at the same
  /// moment exactly one succeeds and the other gets a clear message — the
  /// old plain `update` let the second write silently overwrite the first.
  Future<void> claimWin({
    required String tenderId,
    required String winnerUid,
  }) async {
    final ref = _tenders.doc(tenderId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) {
          throw const TenderException('This tender no longer exists.');
        }
        if (data['importerUid'] == winnerUid) {
          throw const TenderException('You cannot win your own tender.');
        }
        if (data['status'] != 'open') {
          throw const TenderException('Someone else already won this tender.');
        }
        tx.update(ref, {
          'status': 'won',
          'winnerUid': winnerUid,
          'wonAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw TenderException(e.code == 'permission-denied'
          ? 'This tender is no longer open.'
          : 'Could not claim the tender (${e.code}). Check your connection.');
    }
  }
}
