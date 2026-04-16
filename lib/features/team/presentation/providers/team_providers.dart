import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart'
    show appDatabaseProvider;
import 'package:hisabet/features/team/data/models/audit_log_model.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/data/repositories/audit_repository.dart';
import 'package:hisabet/features/team/data/repositories/team_repository.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TeamRepositoryImpl(db);
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AuditRepositoryImpl(db);
});

final allTeamMembersProvider = FutureProvider<List<TeamMemberModel>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getAllMembers();
});

final recentAuditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.getRecentLogs();
});

final rolePreviewProvider = StateProvider<TeamRole>((ref) => TeamRole.owner);

final currentRoleProvider = StateProvider<TeamRole>((ref) => TeamRole.owner);

final hasPermissionProvider = Provider.family<bool, TeamPermission>((ref, permission) {
  final role = ref.watch(currentRoleProvider);
  return roleHasPermission(role, permission);
});