import 'package:drift/drift.dart' as drift;
import 'package:hisabet/core/database/app_database.dart';

enum TeamRole {
  owner,
  manager,
  cashier,
  viewer,
}

enum TeamPermission {
  manageInventory,
  processSales,
  managePurchases,
  manageExpenses,
  viewReports,
  manageTeam,
}

class TeamMemberModel {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final TeamRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamMemberModel({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamMemberModel.fromDb(TeamMember row) {
    return TeamMemberModel(
      id: row.id,
      fullName: row.fullName,
      phoneNumber: row.phoneNumber,
      role: TeamRole.values[row.role],
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TeamMemberModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    TeamRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamMemberModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  TeamMembersCompanion toDbCompanion() {
    return TeamMembersCompanion.insert(
      id: id,
      fullName: fullName,
      phoneNumber: drift.Value(phoneNumber),
      role: drift.Value(role.index),
      isActive: drift.Value(isActive),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

const Map<TeamRole, Set<TeamPermission>> _rolePermissions = {
  TeamRole.owner: {
    TeamPermission.manageInventory,
    TeamPermission.processSales,
    TeamPermission.managePurchases,
    TeamPermission.manageExpenses,
    TeamPermission.viewReports,
    TeamPermission.manageTeam,
  },
  TeamRole.manager: {
    TeamPermission.manageInventory,
    TeamPermission.processSales,
    TeamPermission.managePurchases,
    TeamPermission.manageExpenses,
    TeamPermission.viewReports,
  },
  TeamRole.cashier: {
    TeamPermission.processSales,
  },
  TeamRole.viewer: {
    TeamPermission.viewReports,
  },
};

bool roleHasPermission(TeamRole role, TeamPermission permission) {
  return _rolePermissions[role]?.contains(permission) ?? false;
}