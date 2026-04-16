import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/team/data/models/audit_log_model.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:uuid/uuid.dart';

abstract class AuditRepository {
  Future<void> logAction({
    required TeamRole actorRole,
    required String action,
    String? entityType,
    String? entityId,
    String? message,
  });
  Future<List<AuditLogModel>> getRecentLogs({int limit = 100});
}

class AuditRepositoryImpl implements AuditRepository {
  final AppDatabase _db;

  AuditRepositoryImpl(this._db);

  @override
  Future<void> logAction({
    required TeamRole actorRole,
    required String action,
    String? entityType,
    String? entityId,
    String? message,
  }) async {
    final item = AuditLogModel(
      id: const Uuid().v4(),
      actorRole: actorRole,
      action: action,
      entityType: entityType,
      entityId: entityId,
      message: message,
      createdAt: DateTime.now(),
    );

    await _db.into(_db.auditLogs).insert(item.toDbCompanion());
  }

  @override
  Future<List<AuditLogModel>> getRecentLogs({int limit = 100}) async {
    final rows = await (_db.select(_db.auditLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(AuditLogModel.fromDb).toList();
  }
}