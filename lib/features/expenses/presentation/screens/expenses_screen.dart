import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/core/theme/app_colors.dart';
import 'package:hisabet/features/expenses/data/models/expense_category_model.dart';
import 'package:hisabet/features/expenses/data/models/expense_model.dart';
import 'package:hisabet/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:hisabet/features/expenses/presentation/screens/expense_category_upsert_screen.dart';
import 'package:hisabet/features/expenses/presentation/screens/expense_upsert_screen.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesProvider);
    final categoriesAsync = ref.watch(allExpenseCategoriesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Expenses'),
          backgroundColor: AppColors.background,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Categories'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Add category',
              icon: const Icon(Icons.category_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ExpenseCategoryUpsertScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _ExpensesTab(expensesAsync: expensesAsync, categoriesAsync: categoriesAsync),
            _CategoriesTab(categoriesAsync: categoriesAsync),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ExpenseUpsertScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  final AsyncValue<List<ExpenseModel>> expensesAsync;
  final AsyncValue<List<ExpenseCategoryModel>> categoriesAsync;

  const _ExpensesTab({required this.expensesAsync, required this.categoriesAsync});

  @override
  Widget build(BuildContext context) {
    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (expenses) {
        return categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (categories) {
            final categoryById = {for (final category in categories) category.id: category};

            return RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _ExpenseSummaryCard(expenses: expenses),
                  const SizedBox(height: 12),
                  if (expenses.isEmpty)
                    const _EmptyExpensesState()
                  else
                    ...expenses.map(
                      (expense) => _ExpenseTile(
                        expense: expense,
                        category: categoryById[expense.categoryId],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final AsyncValue<List<ExpenseCategoryModel>> categoriesAsync;

  const _CategoriesTab({required this.categoriesAsync});

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (categories) {
        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _CategorySummaryCard(categories: categories),
              const SizedBox(height: 12),
              if (categories.isEmpty)
                const _EmptyCategoriesState()
              else
                ...categories.map(
                  (category) => _CategoryTile(category: category),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpenseSummaryCard extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const _ExpenseSummaryCard({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<Decimal>(Decimal.zero, (sum, expense) => sum + expense.amount);
    final recurringCount = expenses.where((expense) => expense.isRecurring).length;

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
          const Text('Expense Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Text('Total expenses: ${expenses.length}'),
          Text('Recurring expenses: $recurringCount'),
          Text('Total spent: ETB $total'),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final ExpenseCategoryModel? category;

  const _ExpenseTile({required this.expense, required this.category});

  @override
  Widget build(BuildContext context) {
    final color = category == null
        ? AppColors.primary
        : Color(int.parse('0xFF${category!.colorHex}'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpenseUpsertScreen(expenseToEdit: expense),
              ),
            );
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.receipt_long, color: color),
            ),
            title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (category != null) category!.name,
                    if (expense.vendor != null && expense.vendor!.isNotEmpty) expense.vendor!,
                    expense.paymentMethod.toUpperCase(),
                  ].join(' • '),
                ),
                Text(DateFormat('MMM d, yyyy').format(expense.spentAt)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('ETB ${expense.amount}', style: const TextStyle(fontWeight: FontWeight.w700)),
                if (expense.isRecurring)
                  const Text('Recurring', style: TextStyle(fontSize: 11, color: Colors.orange)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  final List<ExpenseCategoryModel> categories;

  const _CategorySummaryCard({required this.categories});

  @override
  Widget build(BuildContext context) {
    final activeCount = categories.where((category) => category.isActive).length;

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
          const Text('Category Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Text('Total categories: ${categories.length}'),
          Text('Active categories: $activeCount'),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ExpenseCategoryModel category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xFF${category.colorHex}'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpenseCategoryUpsertScreen(categoryToEdit: category),
              ),
            );
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.label, color: color),
            ),
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(category.notes ?? 'No notes'),
            trailing: category.isActive
                ? const Text('Active', style: TextStyle(color: Colors.green))
                : const Text('Inactive', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ),
    );
  }
}

class _EmptyExpensesState extends StatelessWidget {
  const _EmptyExpensesState();

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
          Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No expenses yet.', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Record business costs, recurring charges, and receipts here.'),
        ],
      ),
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
  const _EmptyCategoriesState();

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
          Icon(Icons.category_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No expense categories yet.', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Create categories for rent, fuel, delivery, and more.'),
        ],
      ),
    );
  }
}