import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:hisabet/features/settings/data/models/app_settings_model.dart';

class AppSettingsRepository {
  static const String _settingsFileName = 'app_settings.json';
  static const String _databaseFileName = 'hisabet_v1.sqlite';

  Future<AppSettingsModel> loadSettings() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      final defaults = AppSettingsModel.defaults();
      await saveSettings(defaults);
      return defaults;
    }

    try {
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return AppSettingsModel.fromJson(map);
    } catch (_) {
      final defaults = AppSettingsModel.defaults();
      await saveSettings(defaults);
      return defaults;
    }
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(settings.toJson()));
  }

  Future<String> createDatabaseBackup() async {
    final documents = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documents.path, _databaseFileName);
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Database file not found for backup.');
    }

    final backupsDir = Directory(p.join(documents.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(backupsDir.path, 'hisabet_backup_$stamp.sqlite');
    await dbFile.copy(backupPath);
    return backupPath;
  }

  Future<String> exportSettingsSnapshot() async {
    final settings = await loadSettings();
    final documents = await getApplicationDocumentsDirectory();
    final backupsDir = Directory(p.join(documents.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = p.join(backupsDir.path, 'settings_export_$stamp.json');
    await File(path).writeAsString(jsonEncode(settings.toJson()));
    return path;
  }

  static Future<String?> readInitialLanguageCode() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final file = File(p.join(docs.path, _settingsFileName));
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final lang = map['languageCode'] as String?;
      if (lang == null || lang.trim().isEmpty) return null;
      return lang.trim();
    } catch (_) {
      return null;
    }
  }

  Future<File> _settingsFile() async {
    final documents = await getApplicationDocumentsDirectory();
    return File(p.join(documents.path, _settingsFileName));
  }
}
