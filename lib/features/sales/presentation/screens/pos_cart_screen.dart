import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/promotions/presentation/providers/promotions_providers.dart';
import 'package:hisabet/features/promotions/data/models/promotion_model.dart';
import 'package:hisabet/features/sales/presentation/providers/pos_cart_provider.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';
import 'package:hisabet/features/sales/presentation/screens/sales_history_screen.dart';
import 'package:hisabet/features/contacts/data/models/contact_model.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:hisabet/features/sales/presentation/screens/invoice_preview_screen.dart';
import 'package:hisabet/features/settings/presentation/providers/settings_providers.dart';

class PosCartScreen extends ConsumerStatefulWidget {
  const PosCartScreen({super.key});

  @override
  ConsumerState<PosCartScreen> createState() => _PosCartScreenState();
}

class _PosCartScreenState extends ConsumerState<PosCartScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isGridView = false; // Grid vs List toggle

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final cart = ref.watch(posCartProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final defaultTaxPercent = settingsAsync.valueOrNull?.defaultTaxPercent ?? 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          IconButton(
            tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            tooltip: 'Recent sales',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: AppDimensions.sm),
        ],
      ),
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search products by name or SKU...',
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading products: $error')),
              data: (products) {
                final filtered = products
                    .where((product) {
                      if (_query.trim().isEmpty) return true;
                      final q = _query.toLowerCase();
                      return product.name.toLowerCase().contains(q) ||
                          (product.sku?.toLowerCase().contains(q) ?? false);
                    })
                    .where((product) => product.stockQuantity > 0)
                    .toList();

                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No products found',
                    subtitle: 'Try a different search query.',
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimensions.pagePaddingH, AppDimensions.sm, AppDimensions.pagePaddingH, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppDimensions.md,
                      crossAxisSpacing: AppDimensions.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _ProductGridCard(
                      product: filtered[index],
                      onAdd: () => _handleAddToCart(filtered[index]),
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimensions.pagePaddingH, AppDimensions.sm, AppDimensions.pagePaddingH, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: _ProductListCard(
                        product: filtered[index],
                        onAdd: () => _handleAddToCart(filtered[index]),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _FloatingCartBar(cart: cart),
    );
  }

  Future<void> _handleAddToCart(ProductModel product) async {
    final allowed = await _ensureProcessSalesPermission(
      context,
      ref,
      attemptedAction: 'add_product_to_cart',
      entityType: 'product',
      entityId: product.id,
    );
    if (!allowed) return;
    ref.read(posCartProvider.notifier).addProduct(product);
  }
}

class _ProductListCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const _ProductListCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isBundle = product.unit.toLowerCase() == 'carton' || (product.itemsPerCarton ?? 0) > 0;
    final pricePerCarton = isBundle
        ? product.sellingPrice * Decimal.fromInt(product.itemsPerCarton ?? 1)
        : Decimal.zero;

    return AppListTile(
      leadingIcon: isBundle ? Icons.inventory_rounded : Icons.inventory_2_outlined,
      leadingColor: AppColors.primary,
      title: product.name,
      subtitle: isBundle
          ? 'Stock: ${product.stockQuantity} CTN • ETB $pricePerCarton / CTN'
          : 'Stock: ${product.stockQuantity} ${product.unit}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isBundle) ...[
            Text('ETB ${product.sellingPrice}', style: AppTextStyles.cardTitle),
            const SizedBox(width: AppDimensions.md),
          ],
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
          ),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const _ProductGridCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isBundle = product.unit.toLowerCase() == 'carton' || (product.itemsPerCarton ?? 0) > 0;
    final pricePerCarton = isBundle
        ? product.sellingPrice * Decimal.fromInt(product.itemsPerCarton ?? 1)
        : Decimal.zero;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Icon(
                isBundle ? Icons.inventory_rounded : Icons.inventory_2_outlined,
                size: 40,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          Text(product.name, style: AppTextStyles.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          if (isBundle) ...[
            Text('Stock: ${product.stockQuantity} CTN', style: AppTextStyles.cardSubtitle),
            Text('ETB $pricePerCarton /CTN', style: AppTextStyles.amountNeutral),
          ] else ...[
            Text('Stock: ${product.stockQuantity} ${product.unit}', style: AppTextStyles.cardSubtitle),
            Text('ETB ${product.sellingPrice}', style: AppTextStyles.amountNeutral),
          ],
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight.withOpacity(0.15),
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              ),
              child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCartBar extends ConsumerWidget {
  final PosCartState cart;

  const _FloatingCartBar({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cart.items.isEmpty) return const SizedBox.shrink();

    final totalItems = cart.items.fold(0, (sum, item) => sum + item.quantity);

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
      child: Material(
        color: AppColors.surface,
        elevation: 8,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: () => _showCartBottomSheet(context, ref, cart),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$totalItems Item${totalItems > 1 ? 's' : ''} in cart', style: AppTextStyles.cardSubtitle),
                      Text('ETB ${cart.total}', style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showCartBottomSheet(context, ref, cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                  ),
                  child: const Text('Review Cart', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context, WidgetRef ref, PosCartState cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CartBottomSheet(cart: cart),
    );
  }
}

class _CartBottomSheet extends ConsumerStatefulWidget {
  final PosCartState cart;
  const _CartBottomSheet({required this.cart});

  @override
  ConsumerState<_CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends ConsumerState<_CartBottomSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    final cart = ref.watch(posCartProvider); // Realtime updates inside sheet
    final settingsAsync = ref.watch(appSettingsProvider);
    final defaultTaxPercent = settingsAsync.valueOrNull?.defaultTaxPercent ?? 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH),
            child: Row(
              children: [
                const Text('Cart Contents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: cart.items.isEmpty
                      ? null
                      : () async {
                          final allowed = await _ensureProcessSalesPermission(
                            context,
                            ref,
                            attemptedAction: 'clear_pos_cart',
                          );
                          if (!allowed) return;
                          ref.read(posCartProvider.notifier).clear();
                          if (mounted) Navigator.pop(context);
                        },
                  child: const Text('Clear All', style: TextStyle(color: AppColors.negative)),
                ),
              ],
            ),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? const AppEmptyState(icon: Icons.shopping_basket_outlined, title: 'Your cart is empty', subtitle: 'Add products to start checkout')
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
                        child: ListTile(
                          title: Text(item.product.name, style: AppTextStyles.cardTitle),
                          subtitle: Text(
                            item.isBundle
                                ? 'ETB ${item.pricePerCarton} / CTN'
                                : 'ETB ${item.product.sellingPrice} / ${item.product.unit}',
                            style: AppTextStyles.cardSubtitle,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.negative),
                                onPressed: () {
                                  ref.read(posCartProvider.notifier).decreaseQty(item.product.id);
                                  if (cart.items.length == 1 && item.quantity == 1) Navigator.pop(context); // Close if last item removed
                                },
                              ),
                              SizedBox(
                                width: 30,
                                child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.positive),
                                onPressed: () => ref.read(posCartProvider.notifier).increaseQty(item.product.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, AppDimensions.lg, AppDimensions.pagePaddingH, MediaQuery.of(context).viewInsets.bottom + AppDimensions.xxl),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
              boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: Offset(0, -4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Removed tax and discount fields from here
                const SizedBox(height: AppDimensions.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    Text('ETB ${cart.subtotal}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total to Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('ETB ${cart.total}', style: AppTextStyles.heroAmount.copyWith(color: AppColors.primary, fontSize: 24)),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () {
                            final taxAmount = cart.subtotal * Decimal.parse((defaultTaxPercent / 100).toStringAsFixed(4));
                            ref.read(posCartProvider.notifier).setTax(taxAmount);
                            _showCheckoutDialog(context, ref, ref.read(posCartProvider), defaultTaxPercent);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
                    ),
                    child: const Text('PROCEED TO CHECKOUT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCheckoutDialog(BuildContext context, WidgetRef ref, PosCartState cart, double taxPercent) async {
  final customerNameCtrl = TextEditingController();
  final paidCtrl = TextEditingController(text: cart.total.toString());
  final noteCtrl = TextEditingController();
  String paymentMethod = 'cash';
  String? appliedPromotionId;
  String? appliedPromotionCode;
  String? promoMessage;
  bool promoApplied = false;
  bool isPartialPayment = false;
  ContactModel? selectedContact;
  PromotionModel? selectedPromotion;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(AppDimensions.pagePaddingH, AppDimensions.sm, AppDimensions.pagePaddingH, MediaQuery.of(context).viewInsets.bottom + AppDimensions.xxxl),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Finalize Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  const SizedBox(height: AppDimensions.xl),
                  AppFormSection(
                    title: 'Payment Details',
                    icon: Icons.payments_outlined,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                        child: DropdownButtonFormField<String>(
                          value: paymentMethod,
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash Payment')),
                            DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                            DropdownMenuItem(value: 'mobile', child: Text('Mobile Money')),
                          ],
                          onChanged: (v) => setState(() => paymentMethod = v ?? 'cash'),
                          decoration: const InputDecoration(labelText: 'Method', border: InputBorder.none),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tax ($taxPercent%)', style: const TextStyle(fontSize: 16)),
                            Text('ETB ${cart.tax}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        title: const Text('Partial Payment (Credit Sale)', style: TextStyle(fontSize: 16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
                        value: isPartialPayment,
                        onChanged: (val) {
                          setState(() {
                            isPartialPayment = val ?? false;
                            if (!isPartialPayment) {
                              paidCtrl.text = ref.read(posCartProvider).total.toString();
                            } else {
                              paidCtrl.clear();
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                        child: TextField(
                          controller: paidCtrl,
                          enabled: isPartialPayment,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: InputDecoration(
                            labelText: isPartialPayment ? 'Amount Tendered (ETB)' : 'Full Amount Tendered (Auto)',
                            border: InputBorder.none,
                            labelStyle: TextStyle(color: isPartialPayment ? AppColors.textPrimary : AppColors.textSecondary),
                          ),
                          style: TextStyle(
                            color: isPartialPayment ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: isPartialPayment ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  Consumer(
                    builder: (context, ref, child) {
                      final contactsAsync = ref.watch(allContactsProvider);
                      final contacts = contactsAsync.valueOrNull ?? [];
                      final promotionsAsync = ref.watch(allPromotionsProvider);
                      final activePromotions = promotionsAsync.valueOrNull?.where((p) => p.isActive).toList() ?? [];

                      return AppFormSection(
                        title: 'Customer & Promotions',
                        icon: Icons.person_outline,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                            child: DropdownButtonFormField<ContactModel>(
                              value: selectedContact,
                              decoration: const InputDecoration(
                                labelText: 'Select Customer (Optional)',
                                border: InputBorder.none,
                              ),
                              items: [
                                const DropdownMenuItem<ContactModel>(
                                  value: null,
                                  child: Text('Walk-in Customer'),
                                ),
                                ...contacts.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                )),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedContact = val;
                                  if (val != null) {
                                    customerNameCtrl.text = val.name;
                                  } else {
                                    customerNameCtrl.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          if (selectedContact != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(AppDimensions.xl, 0, AppDimensions.xl, AppDimensions.sm),
                              child: Text(
                                'Credit Limit: ETB ${selectedContact!.creditLimit} | Balance: ETB ${selectedContact!.netBalance}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                            child: TextField(
                              controller: customerNameCtrl,
                              decoration: const InputDecoration(labelText: 'Customer Name (Override)', border: InputBorder.none),
                            ),
                          ),
                          if (activePromotions.isNotEmpty) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.md),
                              child: DropdownButtonFormField<PromotionModel>(
                                value: selectedPromotion,
                                decoration: const InputDecoration(
                                  labelText: 'Apply Promotion',
                                  border: InputBorder.none,
                                ),
                                items: [
                                  const DropdownMenuItem<PromotionModel>(
                                    value: null,
                                    child: Text('No Promotion'),
                                  ),
                                  ...activePromotions.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text('${p.code} - ${p.title}'),
                                  )),
                                ],
                                onChanged: (val) async {
                                  if (val == null) {
                                    setState(() {
                                      selectedPromotion = null;
                                      promoApplied = false;
                                      promoMessage = null;
                                      appliedPromotionId = null;
                                      appliedPromotionCode = null;
                                      ref.read(posCartProvider.notifier).setDiscount(Decimal.zero);
                                      if (!isPartialPayment) {
                                        paidCtrl.text = ref.read(posCartProvider).total.toString();
                                      }
                                    });
                                    return;
                                  }

                                  final res = await ref.read(promotionsRepositoryProvider).evaluatePromotion(code: val.code, subtotal: cart.subtotal);
                                  setState(() {
                                    selectedPromotion = val;
                                    if (!res.isValid || res.promotion == null) {
                                      promoApplied = false;
                                      promoMessage = res.message ?? 'Invalid code.';
                                      appliedPromotionId = null;
                                      appliedPromotionCode = null;
                                      ref.read(posCartProvider.notifier).setDiscount(Decimal.zero);
                                    } else {
                                      promoApplied = true;
                                      appliedPromotionId = res.promotion!.id;
                                      appliedPromotionCode = res.promotion!.code;
                                      promoMessage = 'Applied ${res.promotion!.code} (- ETB ${res.discountAmount})';
                                      ref.read(posCartProvider.notifier).setDiscount(res.discountAmount);
                                    }
                                    if (!isPartialPayment) {
                                      paidCtrl.text = ref.read(posCartProvider).total.toString();
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                          if (promoMessage != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppDimensions.xl, 0, AppDimensions.xl, AppDimensions.sm),
                          child: Text(
                            promoMessage!,
                            style: TextStyle(color: promoApplied ? AppColors.positive : AppColors.negative, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppDimensions.lg),
                  AppFormSection(
                    title: 'Additional Info',
                    icon: Icons.note_alt_outlined,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl, vertical: AppDimensions.sm),
                        child: TextField(
                          controller: noteCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Order Notes', border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.xxxl),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: const Text('CANCEL'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
                            ),
                            child: const Text('CONFIRM SALE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (result != true || !context.mounted) {
    debugPrint('CHECKOUT TRACE: Dialog returned $result or context not mounted. Aborting.');
    return;
  }

  try {
    debugPrint('CHECKOUT TRACE: Starting checkoutSale repository call...');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing checkout... Please wait.'), duration: Duration(seconds: 2)));
    }
    
    final latestCart = ref.read(posCartProvider);
    final saleId = await ref.read(salesRepositoryProvider).checkoutSale(
          cartItems: latestCart.items,
          contactId: selectedContact?.id,
          customerName: customerNameCtrl.text.trim().isEmpty ? null : customerNameCtrl.text.trim(),
          discount: latestCart.discount,
          tax: latestCart.tax,
          paidAmount: Decimal.tryParse(paidCtrl.text.trim()) ?? Decimal.zero,
          paymentMethod: paymentMethod,
          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          promotionId: appliedPromotionId,
          promotionCode: appliedPromotionCode,
        );
    final actorRole = ref.read(currentRoleProvider);
    await ref.read(auditRepositoryProvider).logAction(
          actorRole: actorRole,
          action: 'sale_completed',
          entityType: 'sale',
          message: 'POS checkout completed. Total ETB ${cart.total}.',
        );

    ref.read(posCartProvider.notifier).clear();
    ref.invalidate(allProductsProvider);
    ref.invalidate(lowStockProductsProvider);
    ref.invalidate(recentSalesProvider);
    ref.invalidate(recentAuditLogsProvider);
    if (selectedContact != null) {
      ref.invalidate(contactProvider(selectedContact!.id));
      ref.invalidate(contactTransactionsProvider(selectedContact!.id));
      ref.invalidate(allContactsProvider);
    }
    debugPrint('CHECKOUT TRACE: checkoutSale completed successfully. Sale ID: $saleId');
    
    debugPrint('CHECKOUT TRACE: Navigating to InvoicePreviewScreen...');
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => InvoicePreviewScreen(saleId: saleId)),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed successfully! 🎉'), backgroundColor: AppColors.positive));
    }
  } catch (e, stackTrace) {
    debugPrint('CHECKOUT ERROR: $e');
    debugPrint('STACKTRACE: $stackTrace');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e\nCheck console for details.'),
          backgroundColor: AppColors.negative,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }
}

Future<bool> _ensureProcessSalesPermission(
  BuildContext context,
  WidgetRef ref, {
  required String attemptedAction,
  String entityType = 'sale',
  String? entityId,
}) async {
  final allowed = ref.read(hasPermissionProvider(TeamPermission.processSales));
  if (allowed) return true;

  final actorRole = ref.read(currentRoleProvider);
  await ref.read(auditRepositoryProvider).logAction(
        actorRole: actorRole,
        action: 'permission_denied',
        entityType: entityType,
        entityId: entityId,
        message: 'Denied $attemptedAction for role ${actorRole.name}.',
      );
  ref.invalidate(recentAuditLogsProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.'), backgroundColor: AppColors.negative));
  }
  return false;
}
