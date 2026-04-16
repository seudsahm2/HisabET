import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';

class AuditLogModel {
  final String id;
  final TeamRole actorRole;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? message;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.actorRole,
    required this.action,
    this.entityType,
    this.entityId,
    this.message,
    required this.createdAt,
  });

  factory AuditLogModel.fromDb(AuditLog row) {
    return AuditLogModel(
      id: row.id,
      actorRole: TeamRole.values[row.actorRole],
      action: row.action,
      entityType: row.entityType,
      entityId: row.entityId,
      message: row.message,
      createdAt: row.createdAt,
    );
  }

  AuditLogsCompanion toDbCompanion() {
    return AuditLogsCompanion.insert(
      id: id,
      actorRole: drift.Value(actorRole.index),
      action: action,
      entityType: drift.Value(entityType),
      entityId: drift.Value(entityId),
      message: drift.Value(message),
      createdAt: createdAt,
    );
  }
}