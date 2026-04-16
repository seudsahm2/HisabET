import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';
import 'package:hisabet/features/team/data/models/audit_log_model.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class TeamManagementScreen extends ConsumerWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allTeamMembersProvider);
    final previewRole = ref.watch(rolePreviewProvider);
    final logsAsync = ref.watch(recentAuditLogsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Team Workspace & Roles'),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Team Registry'),
              Tab(text: 'Permission Matrix'),
              Tab(text: 'Audit Timeline'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (members) => _TeamTab(members: members),
            ),
            _PermissionsTab(previewRole: previewRole),
            logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (logs) => _AuditTab(logs: logs),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () async {
            final allowed = await _ensureTeamPermission(context, ref, attemptedAction: 'open_add_staff_dialog');
            if (!allowed) return;
            if (!context.mounted) return;
            await _openMemberDialog(context, ref);
          },
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Add Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _TeamTab extends ConsumerWidget {
  final List<TeamMemberModel> members;

  const _TeamTab({required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (members.isEmpty) {
      return const AppEmptyState(
        icon: Icons.groups_rounded,
        title: 'Empty Team Registry',
        subtitle: 'Add staff members and assign roles to delegate control workflows.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(allTeamMembersProvider),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
        children: [
          const AppSectionHeader(title: 'Active Personnel', uppercase: true),
          ...members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.md),
              child: AppListTile(
                leadingIcon: Icons.person_rounded,
                leadingColor: member.isActive ? AppColors.primary : AppColors.divider,
                title: member.fullName,
                subtitle: '${_capitalize(member.role.name)} Role\n${member.phoneNumber ?? 'No direct line'}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    member.isActive
                        ? AppStatusBadge.success(label: 'Active', small: true)
                        : AppStatusBadge.danger(label: 'Disabled', small: true),
                    const SizedBox(width: AppDimensions.sm),
                    PopupMenuButton<String>(
                      tooltip: 'Manage staff',
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                      onSelected: (value) async {
                        final repo = ref.read(teamRepositoryProvider);
                        final actorRole = ref.read(currentRoleProvider);
                        if (value == 'edit') {
                          final allowed = await _ensureTeamPermission(context, ref, attemptedAction: 'edit_team_member', entityId: member.id);
                          if (!allowed) return;
                          if (!context.mounted) return;
                          await _openMemberDialog(context, ref, memberToEdit: member);
                        }
                        if (value == 'toggle') {
                          final allowed = await _ensureTeamPermission(context, ref, attemptedAction: 'toggle_team_member_active', entityId: member.id);
                          if (!allowed) return;
                          await repo.updateMember(member.copyWith(isActive: !member.isActive));
                          await ref.read(auditRepositoryProvider).logAction(
                            actorRole: actorRole,
                            action: member.isActive ? 'team_member_deactivated' : 'team_member_activated',
                            entityType: 'team_member',
                            entityId: member.id,
                            message: '${member.fullName} was ${member.isActive ? 'deactivated' : 'activated'}.',
                          );
                          ref.invalidate(allTeamMembersProvider);
                          ref.invalidate(recentAuditLogsProvider);
                        }
                        if (value == 'delete') {
                          final allowed = await _ensureTeamPermission(context, ref, attemptedAction: 'delete_team_member', entityId: member.id);
                          if (!allowed) return;
                          await repo.deleteMember(member.id);
                          await ref.read(auditRepositoryProvider).logAction(
                            actorRole: actorRole,
                            action: 'team_member_deleted',
                            entityType: 'team_member',
                            entityId: member.id,
                            message: '${member.fullName} was removed from team.',
                          );
                          ref.invalidate(allTeamMembersProvider);
                          ref.invalidate(recentAuditLogsProvider);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                        PopupMenuItem(value: 'toggle', child: Text(member.isActive ? 'Suspend Access' : 'Restore Access')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'delete', child: Text('Delete Member', style: TextStyle(color: AppColors.negative))),
                      ],
                    ),
                  ],
                ),
                onTap: () {},
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _PermissionsTab extends ConsumerWidget {
  final TeamRole previewRole;

  const _PermissionsTab({required this.previewRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentRoleProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security Matrix', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppDimensions.md),
              const Text('Select a role to preview their feature access level across the HisabET platform.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: AppDimensions.lg),
              AppFilterChips<TeamRole>(
                options: TeamRole.values,
                selected: previewRole,
                labelBuilder: (role) => _capitalize(role.name),
                onSelected: (role) => ref.read(rolePreviewProvider.notifier).state = role,
              ),
              const SizedBox(height: AppDimensions.xl),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Global Session Context', style: AppTextStyles.cardSubtitle),
                    const SizedBox(height: AppDimensions.sm),
                    DropdownButtonFormField<TeamRole>(
                      initialValue: currentRole,
                      decoration: const InputDecoration(
                        labelText: 'Switch your active session role',
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: TeamRole.values.map((role) => DropdownMenuItem(value: role, child: Text(_capitalize(role.name)))).toList(),
                      onChanged: (value) {
                        if (value != null) ref.read(currentRoleProvider.notifier).state = value;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        const AppSectionHeader(title: 'Granted Capabilities', uppercase: true),
        ...TeamPermission.values.map(
          (permission) {
            final allowed = roleHasPermission(previewRole, permission);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: AppListTile(
                leadingIcon: allowed ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                leadingColor: allowed ? AppColors.positive : AppColors.textSecondary,
                title: _label(permission),
                subtitle: allowed ? 'Permitted explicitly' : 'Strictly restricted',
                trailing: AppStatusBadge(
                  label: allowed ? 'Granted' : 'Blocked',
                  color: allowed ? AppColors.positive : AppColors.textSecondary,
                  small: true,
                ),
                onTap: () {},
              ),
            );
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _label(TeamPermission permission) {
    switch (permission) {
      case TeamPermission.manageInventory: return 'Inventory Management';
      case TeamPermission.processSales: return 'Sales Operations';
      case TeamPermission.managePurchases: return 'Supply Chain Control';
      case TeamPermission.manageExpenses: return 'Expense Tracking';
      case TeamPermission.viewReports: return 'Financial Analytics';
      case TeamPermission.manageTeam: return 'Administrative Action';
    }
  }
}

class _AuditTab extends ConsumerWidget {
  final List<AuditLogModel> logs;

  const _AuditTab({required this.logs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (logs.isEmpty) {
      return const AppEmptyState(
        icon: Icons.history_rounded,
        title: 'Timeline cleared',
        subtitle: 'No historical actions traced in the immediate audit ledger.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(recentAuditLogsProvider),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
        children: [
          const AppSectionHeader(title: 'Tracing Log Timeline', uppercase: true),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: logs.map((item) {
                return Column(
                  children: [
                    AppListTile(
                      leadingIcon: Icons.admin_panel_settings_rounded,
                      leadingColor: AppColors.primary,
                      title: item.message ?? item.action,
                      subtitle: DateFormat('MMM dd, yyyy • hh:mm a').format(item.createdAt),
                      trailing: AppStatusBadge.neutral(label: item.actorRole.name.toUpperCase(), small: true),
                      onTap: () {},
                    ),
                    if (item != logs.last) const Divider(height: 1, indent: 64),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

Future<void> _openMemberDialog(BuildContext context, WidgetRef ref, {TeamMemberModel? memberToEdit}) async {
  final nameController = TextEditingController(text: memberToEdit?.fullName ?? '');
  final phoneController = TextEditingController(text: memberToEdit?.phoneNumber ?? '');
  var role = memberToEdit?.role ?? TeamRole.viewer;
  var isActive = memberToEdit?.isActive ?? true;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(memberToEdit == null ? 'Register Staff' : 'Modify Access', style: AppTextStyles.cardTitle),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: AppDimensions.md),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Direct Line (optional)'), keyboardType: TextInputType.phone),
                  const SizedBox(height: AppDimensions.md),
                  DropdownButtonFormField<TeamRole>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Delegated Role'),
                    items: TeamRole.values.map((item) {
                      final name = item.name;
                      return DropdownMenuItem(value: item, child: Text(name[0].toUpperCase() + name.substring(1)));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => role = value);
                    },
                  ),
                  const SizedBox(height: AppDimensions.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    activeColor: AppColors.positive,
                    onChanged: (value) => setState(() => isActive = value),
                    title: const Text('Access Granted', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSm))),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();
                  if (name.isEmpty) return;

                  final allowed = await _ensureTeamPermission(context, ref, attemptedAction: memberToEdit == null ? 'create_team_member' : 'update_team_member', entityId: memberToEdit?.id);
                  if (!allowed) return;

                  final repo = ref.read(teamRepositoryProvider);
                  final actorRole = ref.read(currentRoleProvider);
                  if (memberToEdit == null) {
                    await repo.addMember(fullName: name, phoneNumber: phone.isEmpty ? null : phone, role: role, isActive: isActive);
                    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'team_member_created', entityType: 'team_member', message: '$name was onboarded as ${role.name}.');
                  } else {
                    await repo.updateMember(memberToEdit.copyWith(fullName: name, phoneNumber: phone.isEmpty ? null : phone, role: role, isActive: isActive));
                    await ref.read(auditRepositoryProvider).logAction(actorRole: actorRole, action: 'team_member_updated', entityType: 'team_member', entityId: memberToEdit.id, message: '${memberToEdit.fullName} privileges were modified.');
                  }

                  if (context.mounted) Navigator.of(context).pop();
                  ref.invalidate(allTeamMembersProvider);
                  ref.invalidate(recentAuditLogsProvider);
                },
                child: Text(memberToEdit == null ? 'Onboard Member' : 'Save Changes'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool> _ensureTeamPermission(
  BuildContext context,
  WidgetRef ref, {
  required String attemptedAction,
  String? entityId,
}) async {
  final canManageTeam = ref.read(hasPermissionProvider(TeamPermission.manageTeam));
  if (canManageTeam) return true;

  final actorRole = ref.read(currentRoleProvider);
  await ref.read(auditRepositoryProvider).logAction(
    actorRole: actorRole,
    action: 'permission_denied',
    entityType: 'team_member',
    entityId: entityId,
    message: 'Denied $attemptedAction for executing role ${actorRole.name}.',
  );
  ref.invalidate(recentAuditLogsProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unauthorized access. Elevated credentials required.')));
  }
  return false;
}