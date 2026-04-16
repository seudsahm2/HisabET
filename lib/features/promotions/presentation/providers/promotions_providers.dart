import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/promotions/data/models/promotion_model.dart';
import 'package:hisabet/features/promotions/data/repositories/promotions_repository.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PromotionsRepositoryImpl(db);
});

final allPromotionsProvider = FutureProvider<List<PromotionModel>>((ref) async {
  final repo = ref.watch(promotionsRepositoryProvider);
  return repo.getAllPromotions();
});
