import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/sales/presentation/providers/pos_cart_provider.dart';
import 'package:hisabet/features/sales/presentation/providers/sales_providers.dart';
import 'package:hisabet/features/sales/presentation/screens/sales_history_screen.dart';

class PosCartScreen extends ConsumerStatefulWidget {
  const PosCartScreen({super.key});

  @override
  ConsumerState<PosCartScreen> createState() => _PosCartScreenState();
}

class _PosCartScreenState extends ConsumerState<PosCartScreen> {
  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final cart = ref.watch(posCartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('POS Checkout'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Recent sales',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading products: $error')),
        data: (products) {
          final filtered = products.where((product) {
            if (_query.trim().isEmpty) return true;
            final q = _query.toLowerCase();
            return product.name.toLowerCase().contains(q) ||
                (product.sku?.toLowerCase().contains(q) ?? false);
          }).where((product) => product.stockQuantity > 0).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search product by name or SKU',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final isBundle =
                        product.unit.toLowerCase() == 'carton' ||
                        (product.itemsPerCarton ?? 0) > 0;
                    final pricePerCarton = isBundle
                        ? product.sellingPrice * Decimal.fromInt(product.itemsPerCarton ?? 1)
                        : Decimal.zero;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          isBundle
                              ? 'Stock: ${product.stockQuantity} cartons • ${product.itemsPerCarton ?? 1} items/carton • ETB ${pricePerCarton} per carton'
                              : 'Stock: ${product.stockQuantity} ${product.unit} • ETB ${product.sellingPrice}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(posCartProvider.notifier)
                                .addProduct(product);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _CartSummaryPanel(
                discountController: _discountController,
                taxController: _taxController,
                cart: cart,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _CheckoutBar(cart: cart),
    );
  }
}

class _CartSummaryPanel extends ConsumerWidget {
  final TextEditingController discountController;
  final TextEditingController taxController;
  final PosCartState cart;

  const _CartSummaryPanel({
    required this.discountController,
    required this.taxController,
    required this.cart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Cart',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              TextButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () => ref.read(posCartProvider.notifier).clear(),
                child: const Text('Clear'),
              ),
            ],
          ),
          if (cart.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No items in cart yet.'),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.builder(
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return ListTile(
                    dense: true,
                    title: Text(item.product.name),
                    subtitle: Text(
                      item.isBundle
                          ? '${item.quantity} carton(s) x ETB ${item.pricePerCarton} /carton'
                          : 'ETB ${item.product.sellingPrice} x ${item.quantity}',
                    ),
                    trailing: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              ref
                                  .read(posCartProvider.notifier)
                                  .decreaseQty(item.product.id);
                            },
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              ref
                                  .read(posCartProvider.notifier)
                                  .increaseQty(item.product.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: discountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Discount',
                    prefixText: 'ETB ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final amount = Decimal.tryParse(value) ?? Decimal.zero;
                    ref.read(posCartProvider.notifier).setDiscount(amount);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: taxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Tax',
                    prefixText: 'ETB ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final amount = Decimal.tryParse(value) ?? Decimal.zero;
                    ref.read(posCartProvider.notifier).setTax(amount);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _labelValue('Subtotal', 'ETB ${cart.subtotal}'),
              _labelValue('Total', 'ETB ${cart.total}', isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value, {bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends ConsumerWidget {
  final PosCartState cart;

  const _CheckoutBar({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: cart.items.isEmpty
                ? null
                : () async {
                    await _showCheckoutDialog(context, ref, cart);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.point_of_sale),
            label: Text('Checkout • ETB ${cart.total}'),
          ),
        ),
      ),
    );
  }

  Future<void> _showCheckoutDialog(
    BuildContext context,
    WidgetRef ref,
    PosCartState cart,
  ) async {
    final customerNameCtrl = TextEditingController();
    final paidCtrl = TextEditingController(text: cart.total.toString());
    final noteCtrl = TextEditingController();
    String paymentMethod = 'cash';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete Checkout',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customerNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer name (optional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank')),
                        DropdownMenuItem(
                          value: 'mobile',
                          child: Text('Mobile Money'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => paymentMethod = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: paidCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Paid Amount',
                        prefixText: 'ETB ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            child: const Text('Confirm'),
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

    if (result != true) {
      return;
    }

    try {
      await ref.read(salesRepositoryProvider).checkoutSale(
            cartItems: cart.items,
            customerName: customerNameCtrl.text.trim().isEmpty
                ? null
                : customerNameCtrl.text.trim(),
            discount: cart.discount,
            tax: cart.tax,
            paidAmount: Decimal.tryParse(paidCtrl.text.trim()) ?? Decimal.zero,
            paymentMethod: paymentMethod,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          );

      ref.read(posCartProvider.notifier).clear();
      ref.invalidate(allProductsProvider);
      ref.invalidate(lowStockProductsProvider);
      ref.invalidate(recentSalesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale completed and saved. Open Receipts for history.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    }
  }
}
