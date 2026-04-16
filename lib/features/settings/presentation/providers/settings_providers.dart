import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/features/settings/data/models/app_settings_model.dart';
import 'package:hisabet/features/settings/data/repositories/app_settings_repository.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository();
});

final appSettingsProvider = FutureProvider<AppSettingsModel>((ref) async {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return repo.loadSettings();
});
