import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/promotions/data/models/promotion_model.dart';
import 'package:hisabet/features/promotions/presentation/providers/promotions_providers.dart';
import 'package:hisabet/features/promotions/presentation/screens/promotion_upsert_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promotionsAsync = ref.watch(allPromotionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Promotions & Promo Codes')),
      body: promotionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (promotions) {
          final active = promotions.where((p) => p.isActive).length;
          final totalRedemptions = promotions.fold<int>(0, (sum, p) => sum + p.usedCount);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allPromotionsProvider),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
                vertical: AppDimensions.lg,
              ),
              children: [
                _SummaryCard(
                  total: promotions.length,
                  active: active,
                  redemptions: totalRedemptions,
                ),
                const SizedBox(height: AppDimensions.xl),
                const AppSectionHeader(title: 'Active Campaigns', uppercase: true),
                if (promotions.isEmpty)
                  const _EmptyState()
                else
                  ...promotions.map((item) => _PromotionTile(item: item)),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.campaign_rounded, color: Colors.white),
        label: const Text('New Campaign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final allowed = await _ensurePromotionPermission(context, ref, attemptedAction: 'open_create_promotion');
          if (!allowed) return;
          if (!context.mounted) return;
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PromotionUpsertScreen()));
          ref.invalidate(allPromotionsProvider);
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int active;
  final int redemptions;

  const _SummaryCard({
    required this.total,
    required this.active,
    required this.redemptions,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Campaign Snapshot', style: AppTextStyles.cardTitle),
              if (active > 0)
                AppStatusBadge.success(label: '$active Running', small: true)
              else
                AppStatusBadge.neutral(label: 'All Stopped', small: true),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Campaigns', style: AppTextStyles.cardSubtitle),
                    Text('$total Records', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total Redemptions', style: AppTextStyles.cardSubtitle),
                    Text('$redemptions Triggers', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionTile extends ConsumerWidget {
  final PromotionModel item;

  const _PromotionTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPercent = item.discountType.name == 'percent';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: AppListTile(
        onTap: () async {
          final allowed = await _ensurePromotionPermission(
            context, ref,
            attemptedAction: 'open_edit_promotion',
            entityId: item.id,
          );
          if (!allowed) return;
          if (!context.mounted) return;
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PromotionUpsertScreen(promotionToEdit: item)));
          ref.invalidate(allPromotionsProvider);
        },
        leadingIcon: Icons.local_offer_rounded,
        leadingColor: item.isActive ? AppColors.moduleSales : AppColors.divider, // Dim when disabled
        title: item.title,
        subtitle: '${item.code}\nUsed ${item.usedCount}${item.usageLimit == null ? ' times' : '/${item.usageLimit}'}',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isPercent)
                  Text('${item.discountValue}% OFF', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary))
                else
                  Text(
                    'ETB ${item.discountValue} OFF',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
                  ),
                const SizedBox(height: 4),
                item.isActive
                    ? AppStatusBadge.success(label: 'Active', small: true)
                    : AppStatusBadge.danger(label: 'Disabled', small: true),
              ],
            ),
            const SizedBox(width: AppDimensions.md),
            Switch(
              value: item.isActive,
              activeColor: AppColors.positive,
              onChanged: (value) async {
                final allowed = await _ensurePromotionPermission(context, ref, attemptedAction: 'toggle_promotion_active', entityId: item.id);
                if (!allowed) return;

                await ref.read(promotionsRepositoryProvider).setPromotionActive(item.id, value);
                final actorRole = ref.read(currentRoleProvider);
                await ref.read(auditRepositoryProvider).logAction(
                  actorRole: actorRole,
                  action: value ? 'promotion_activated' : 'promotion_deactivated',
                  entityType: 'promotion',
                  entityId: item.id,
                  message: 'Promotion ${item.code} was ${value ? 'activated' : 'deactivated'}.',
                );
                ref.invalidate(allPromotionsProvider);
                ref.invalidate(recentAuditLogsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.campaign_rounded,
      title: 'No promotions active',
      subtitle: 'Create campaigns and promo codes to strategically drive volume.',
    );
  }
}

Future<bool> _ensurePromotionPermission(
  BuildContext context,
  WidgetRef ref, {
  required String attemptedAction,
  String? entityId,
}) async {
  final allowed = ref.read(hasPermissionProvider(TeamPermission.processSales));
  if (allowed) return true;

  final actorRole = ref.read(currentRoleProvider);
  await ref.read(auditRepositoryProvider).logAction(
    actorRole: actorRole,
    action: 'permission_denied',
    entityType: 'promotion',
    entityId: entityId,
    message: 'Denied $attemptedAction for role ${actorRole.name}.',
  );
  ref.invalidate(recentAuditLogsProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You do not have permission to manage promotions.')));
  }
  return false;
}
