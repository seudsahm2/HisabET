import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:uuid/uuid.dart';

abstract class TeamRepository {
  Future<List<TeamMemberModel>> getAllMembers();
  Future<void> addMember({
    required String fullName,
    String? phoneNumber,
    TeamRole role = TeamRole.viewer,
    bool isActive = true,
  });
  Future<void> updateMember(TeamMemberModel member);
  Future<void> deleteMember(String id);
  Future<void> ensureSeedOwner();
}

class TeamRepositoryImpl implements TeamRepository {
  final AppDatabase _db;

  TeamRepositoryImpl(this._db);

  @override
  Future<List<TeamMemberModel>> getAllMembers() async {
    await ensureSeedOwner();
    final rows = await (_db.select(_db.teamMembers)
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();
    return rows.map(TeamMemberModel.fromDb).toList();
  }

  @override
  Future<void> addMember({
    required String fullName,
    String? phoneNumber,
    TeamRole role = TeamRole.viewer,
    bool isActive = true,
  }) async {
    final now = DateTime.now();
    final member = TeamMemberModel(
      id: const Uuid().v4(),
      fullName: fullName,
      phoneNumber: phoneNumber,
      role: role,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.teamMembers).insert(member.toDbCompanion());
  }

  @override
  Future<void> updateMember(TeamMemberModel member) async {
    final updated = member.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.teamMembers)..where((tbl) => tbl.id.equals(member.id)))
        .write(updated.toDbCompanion());
  }

  @override
  Future<void> deleteMember(String id) async {
    await (_db.delete(_db.teamMembers)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> ensureSeedOwner() async {
    final rows = await _db.select(_db.teamMembers).get();
    if (rows.isNotEmpty) return;

    final now = DateTime.now();
    await _db.into(_db.teamMembers).insert(
          TeamMembersCompanion.insert(
            id: const Uuid().v4(),
            fullName: 'Owner',
            phoneNumber: const Value.absent(),
            role: Value(TeamRole.owner.index),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }
}