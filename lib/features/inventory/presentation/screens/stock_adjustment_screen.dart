import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const StockAdjustmentScreen({super.key, required this.product});

  @override
  ConsumerState<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isIncrease = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveAdjustment() async {
    final allowed = await _ensureManageInventoryPermission(
      context,
      ref,
      attemptedAction: 'adjust_stock',
      entityId: widget.product.id,
    );
    if (!allowed) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
      final delta = _isIncrease ? quantity : -quantity;
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      final repo = ref.read(productsRepositoryProvider);
      await repo.recordStockMovement(
        productId: widget.product.id,
        quantityChange: delta,
        movementType: _isIncrease ? 'increase' : 'decrease',
        note: note,
      );

      final actorRole = ref.read(currentRoleProvider);
      await ref.read(auditRepositoryProvider).logAction(
        actorRole: actorRole,
        action: 'stock_adjusted',
        entityType: 'product',
        entityId: widget.product.id,
        message: 'Stock ${_isIncrease ? 'increased' : 'decreased'} by $quantity for ${widget.product.name}.',
      );

      ref.invalidate(allProductsProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(productStockMovementsProvider(widget.product.id));
      ref.invalidate(recentAuditLogsProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adjustment failed: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _ensureManageInventoryPermission(
    BuildContext context,
    WidgetRef ref, {
    required String attemptedAction,
    String? entityId,
  }) async {
    final allowed = ref.read(hasPermissionProvider(TeamPermission.manageInventory));
    if (allowed) return true;

    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
      actorRole: actorRole,
      action: 'permission_denied',
      entityType: 'product',
      entityId: entityId,
      message: 'Denied $attemptedAction for role ${actorRole.name}.',
    );
    ref.invalidate(recentAuditLogsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to adjust stock.'),
          backgroundColor: AppColors.negative,
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final movementsAsync = ref.watch(
      productStockMovementsProvider(widget.product.id),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Adjust Stock - ${widget.product.name}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────────────────────────
              // Active Product Status Card
              // ─────────────────────────────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.xl),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AppDimensions.avatarMd / 2,
                      backgroundColor: AppColors.primaryLight.withOpacity(0.15),
                      child: const Icon(Icons.inventory_2, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppDimensions.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.name, style: AppTextStyles.cardTitle),
                          const SizedBox(height: 4),
                          Text(
                            'Current Stock: ${widget.product.stockQuantity} ${widget.product.unit}',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: widget.product.isLowStock
                                    ? AppColors.negative
                                    : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xxxl),

              // ─────────────────────────────────────────────────────────
              // Adjustment Form
              // ─────────────────────────────────────────────────────────
              AppFormSection(
                title: 'Record Adjustment',
                icon: Icons.sync_alt,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.md),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Increase Stock'),
                          icon: Icon(Icons.add),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Reduce Stock'),
                          icon: Icon(Icons.remove),
                        ),
                      ],
                      selected: {_isIncrease},
                      onSelectionChanged: (selection) {
                        setState(() => _isIncrease = selection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: _isIncrease ? AppColors.positiveLight : AppColors.negativeLight,
                        foregroundColor: AppColors.textPrimary,
                        selectedForegroundColor: _isIncrease ? AppColors.positive : AppColors.negative,
                        selectedBackgroundColor: (_isIncrease ? AppColors.positive : AppColors.negative).withOpacity(0.2),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: AppTextStyles.headlineSmall,
                            decoration: const InputDecoration(
                              labelText: 'Adjustment Quantity',
                              hintText: '0',
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              final quantity = int.tryParse(value ?? '');
                              if (quantity == null || quantity <= 0) {
                                return 'Enter a valid quantity';
                              }
                              return null;
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                          child: TextFormField(
                            controller: _noteController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Note or Reason (optional)',
                              hintText: 'e.g. Damaged during shipping',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xxl),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveAdjustment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isIncrease ? AppColors.positive : AppColors.negative,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isIncrease ? 'CONFIRM INCREASE' : 'CONFIRM REDUCTION',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppDimensions.xxxl),

              // ─────────────────────────────────────────────────────────
              // Audit Log (Recent Movements)
              // ─────────────────────────────────────────────────────────
              const AppSectionHeader(
                title: 'Audit Log (Movements)',
                uppercase: true,
              ),
              movementsAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(AppDimensions.xxl),
                  child: CircularProgressIndicator(),
                )),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  child: Text('Error loading movements: $error'),
                ),
                data: (movements) {
                  if (movements.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.history,
                      title: 'No stock movements recorded yet.',
                      compact: true,
                    );
                  }

                  return Column(
                    children: movements.map((movement) {
                      final isPositive = movement.quantityChange >= 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                        child: AppListTile(
                          leadingIcon: isPositive ? Icons.add : Icons.remove,
                          leadingColor: isPositive ? AppColors.positive : AppColors.negative,
                          title: movement.movementLabel,
                          subtitle: movement.note ?? 'No note provided',
                          trailing: Text(
                            '${isPositive ? '+' : ''}${movement.quantityChange}',
                            style: AppTextStyles.badgeLabel.copyWith(
                              fontSize: 16,
                              color: isPositive ? AppColors.positive : AppColors.negative,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}