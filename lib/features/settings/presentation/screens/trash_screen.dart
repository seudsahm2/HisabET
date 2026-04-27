import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:hisabet/features/inventory/presentation/providers/products_providers.dart';
import 'package:hisabet/features/transactions/presentation/providers/transactions_providers.dart';
import 'package:intl/intl.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash & Recovery'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Contacts'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DeletedTransactionsTab(),
          _DeletedContactsTab(),
          _DeletedProductsTab(),
        ],
      ),
    );
  }
}

class _DeletedTransactionsTab extends ConsumerWidget {
  const _DeletedTransactionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(transactionsRepositoryProvider);

    return FutureBuilder(
      future: repo.getDeletedTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No deleted transactions'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final tx = items[index];
            return ListTile(
              title: Text('Tx: ${tx.amount.toStringAsFixed(2)}'),
              subtitle: Text('Deleted: ${DateFormat.yMMMd().format(tx.deletedAt ?? DateTime.now())}'),
              trailing: TextButton(
                onPressed: () async {
                  await repo.restoreTransaction(tx.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction Restored')),
                  );
                  // Quick reload trick: call setState in parent or just use riverpod correctly
                  // Since we're using FutureBuilder, we can just pop or re-trigger build
                  (context as Element).markNeedsBuild();
                },
                child: const Text('RESTORE'),
              ),
            );
          },
        );
      },
    );
  }
}

class _DeletedContactsTab extends ConsumerWidget {
  const _DeletedContactsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(contactsRepositoryProvider);

    return FutureBuilder(
      future: repo.getDeletedContacts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No deleted contacts'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final contact = items[index];
            return ListTile(
              title: Text(contact.name),
              subtitle: Text('Deleted: ${DateFormat.yMMMd().format(contact.deletedAt ?? DateTime.now())}'),
              trailing: TextButton(
                onPressed: () async {
                  await repo.restoreContact(contact.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact Restored')),
                  );
                  (context as Element).markNeedsBuild();
                },
                child: const Text('RESTORE'),
              ),
            );
          },
        );
      },
    );
  }
}

class _DeletedProductsTab extends ConsumerWidget {
  const _DeletedProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(productsRepositoryProvider);

    return FutureBuilder(
      future: repo.getDeletedProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No deleted products'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final product = items[index];
            return ListTile(
              title: Text(product.name),
              subtitle: Text('Deleted: ${DateFormat.yMMMd().format(product.deletedAt ?? DateTime.now())}'),
              trailing: TextButton(
                onPressed: () async {
                  await repo.restoreProduct(product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product Restored')),
                  );
                  (context as Element).markNeedsBuild();
                },
                child: const Text('RESTORE'),
              ),
            );
          },
        );
      },
    );
  }
}
