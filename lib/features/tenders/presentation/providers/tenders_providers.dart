import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenderModel {
  final String id;
  final String importerUid;
  final String importerName;
  final String itemNumber;
  final String? photoUrl;
  final int cartons;
  final int seriesSize;
  final String? colorDistribution;
  final double price;
  final String status; // 'open', 'won', 'lost'
  final String? winnerUid;
  final DateTime createdAt;

  TenderModel({
    required this.id,
    required this.importerUid,
    required this.importerName,
    required this.itemNumber,
    this.photoUrl,
    required this.cartons,
    required this.seriesSize,
    this.colorDistribution,
    required this.price,
    required this.status,
    this.winnerUid,
    required this.createdAt,
  });

  factory TenderModel.fromJson(Map<String, dynamic> json, String id) {
    return TenderModel(
      id: id,
      importerUid: json['importerUid'] ?? '',
      importerName: json['importerName'] ?? 'Unknown Importer',
      itemNumber: json['itemNumber'] ?? '',
      photoUrl: json['photoUrl'],
      cartons: json['cartons'] ?? 0,
      seriesSize: json['seriesSize'] ?? 6,
      colorDistribution: json['colorDistribution'],
      price: (json['price'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'open',
      winnerUid: json['winnerUid'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

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
