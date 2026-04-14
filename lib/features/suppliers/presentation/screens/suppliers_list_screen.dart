import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/suppliers/data/models/supplier_model.dart';
import 'package:hisabet/features/suppliers/presentation/providers/suppliers_providers.dart';
import 'package:hisabet/features/suppliers/presentation/screens/supplier_detail_screen.dart';
import 'package:hisabet/features/suppliers/presentation/screens/supplier_upsert_screen.dart';

class SuppliersListScreen extends ConsumerWidget {
  const SuppliersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(allSuppliersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Suppliers'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: suppliersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (suppliers) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allSuppliersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _SupplierSummary(suppliers: suppliers),
                const SizedBox(height: 12),
                if (suppliers.isEmpty)
                  const _EmptySuppliersState()
                else
                  ...suppliers.map(
                    (supplier) => _SupplierTile(
                      supplier: supplier,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SupplierDetailScreen(supplierId: supplier.id),
                          ),
                        );
                      },
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SupplierUpsertScreen(
                              supplierToEdit: supplier,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SupplierUpsertScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Supplier', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _SupplierSummary extends StatelessWidget {
  final List<SupplierModel> suppliers;

  const _SupplierSummary({required this.suppliers});

  @override
  Widget build(BuildContext context) {
    final activeCount = suppliers.where((supplier) => supplier.isActive).length;
    final payableCount = suppliers.where((supplier) => supplier.isPayable).length;
    final totalBalance = suppliers.fold<Decimal>(
      Decimal.zero,
      (sum, supplier) => sum + supplier.currentBalance,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supplier Summary',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text('Total suppliers: ${suppliers.length}'),
          Text('Active suppliers: $activeCount'),
          Text('Payable suppliers: $payableCount'),
          Text('Net supplier balance: ETB $totalBalance'),
        ],
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _SupplierTile({required this.supplier, required this.onTap, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isPayable = supplier.isPayable;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: isPayable
                  ? Colors.redAccent.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.12),
              child: Icon(
                Icons.local_shipping_outlined,
                color: isPayable ? Colors.redAccent : AppColors.primary,
              ),
            ),
            title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              [
                if (supplier.phone != null && supplier.phone!.isNotEmpty) 'Phone: ${supplier.phone}',
                if (supplier.email != null && supplier.email!.isNotEmpty) 'Email: ${supplier.email}',
                if (supplier.termsDays > 0) 'Terms: ${supplier.termsDays} days',
                'Balance: ETB ${supplier.currentBalance}',
              ].join(' • '),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySuppliersState extends StatelessWidget {
  const _EmptySuppliersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.local_shipping_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No suppliers yet.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Add your first supplier to start the purchase flow.'),
        ],
      ),
    );
  }
}