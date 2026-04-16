import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hisabet/core/presentation/widgets/widgets.dart';
import 'package:hisabet/core/theme/theme.dart';

import 'package:hisabet/features/expenses/data/models/expense_category_model.dart';
import 'package:hisabet/features/expenses/data/models/expense_model.dart';
import 'package:hisabet/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:hisabet/features/expenses/presentation/screens/expense_category_upsert_screen.dart';
import 'package:hisabet/features/expenses/presentation/screens/expense_upsert_screen.dart';
import 'package:hisabet/features/team/data/models/team_member_model.dart';
import 'package:hisabet/features/team/presentation/providers/team_providers.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesProvider);
    final categoriesAsync = ref.watch(allExpenseCategoriesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Expenses'),
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
              onPressed: () async {
                final allowed = await _ensureExpensesPermission(
                  context,
                  ref,
                  attemptedAction: 'open_add_expense_category',
                  entityType: 'expense_category',
                );
                if (!allowed) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExpenseCategoryUpsertScreen()),
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
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
          onPressed: () async {
            final allowed = await _ensureExpensesPermission(
              context,
              ref,
              attemptedAction: 'open_add_expense',
              entityType: 'expense',
            );
            if (!allowed) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseUpsertScreen()),
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
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
                children: [
                  _ExpenseSummaryCard(expenses: expenses),
                  const SizedBox(height: AppDimensions.xl),
                  if (expenses.isEmpty)
                    const AppEmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No expenses tracked',
                      subtitle: 'Record business costs, recurring charges, and bills here.',
                    )
                  else
                    ...expenses.map(
                      (expense) => _ExpenseTile(
                        expense: expense,
                        category: categoryById[expense.categoryId],
                      ),
                    ),
                  const SizedBox(height: 80),
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
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pagePaddingH, vertical: AppDimensions.lg),
            children: [
              _CategorySummaryCard(categories: categories),
              const SizedBox(height: AppDimensions.xl),
              if (categories.isEmpty)
                const AppEmptyState(
                  icon: Icons.category_rounded,
                  title: 'No categories',
                  subtitle: 'Create categories to easily sort your company spending.',
                )
              else
                ...categories.map((category) => _CategoryTile(category: category)),
              const SizedBox(height: 80),
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

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.negativeLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.outbound_rounded, color: AppColors.negative),
              ),
              const SizedBox(width: AppDimensions.md),
              Text('Expense Summary', style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              Expanded(child: _buildStatItem('Records', expenses.length.toString(), Colors.blue)),
              Expanded(child: _buildStatItem('Recurring', recurringCount.toString(), AppColors.warning)),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Spending', style: AppTextStyles.cardSubtitle),
                Text('ETB $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.negative)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.headlineSmall.copyWith(color: color)),
        Text(label, style: AppTextStyles.badgeLabel.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final ExpenseCategoryModel? category;

  const _ExpenseTile({required this.expense, required this.category});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final color = category == null ? AppColors.primary : Color(int.parse('0xFF${category!.colorHex}'));

        return AppListTile(
          leadingIcon: Icons.receipt_long_rounded,
          leadingColor: color,
          title: expense.title,
          subtitle: [
            if (expense.vendor != null && expense.vendor!.isNotEmpty) expense.vendor!,
            expense.paymentMethod.toUpperCase(),
            DateFormat('MMM d, yyyy').format(expense.spentAt),
          ].join(' • '),
          onTap: () async {
            final allowed = await _ensureExpensesPermission(context, ref, attemptedAction: 'open_edit_expense', entityType: 'expense', entityId: expense.id);
            if (!allowed) return;
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExpenseUpsertScreen(expenseToEdit: expense)));
          },
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ETB ${expense.amount}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (expense.isRecurring) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.repeat_rounded, size: 14, color: AppColors.warning)),
                  AppStatusBadge(label: category?.name ?? 'General', color: color, small: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  final List<ExpenseCategoryModel> categories;

  const _CategorySummaryCard({required this.categories});

  @override
  Widget build(BuildContext context) {
    final activeCount = categories.where((category) => category.isActive).length;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.category_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.md),
              Text('Categories Overview', style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categories.length.toString(), style: AppTextStyles.headlineSmall.copyWith(color: Colors.blue)),
                    Text('Total Tags', style: AppTextStyles.badgeLabel.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activeCount.toString(), style: AppTextStyles.headlineSmall.copyWith(color: AppColors.positive)),
                    Text('Active', style: AppTextStyles.badgeLabel.copyWith(color: AppColors.textSecondary)),
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

class _CategoryTile extends StatelessWidget {
  final ExpenseCategoryModel category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final color = Color(int.parse('0xFF${category.colorHex}'));

        return AppListTile(
          leadingIcon: Icons.label_important_rounded,
          leadingColor: color,
          title: category.name,
          subtitle: category.notes ?? 'No notes provided',
          onTap: () async {
            final allowed = await _ensureExpensesPermission(context, ref, attemptedAction: 'open_edit_expense_category', entityType: 'expense_category', entityId: category.id);
            if (!allowed) return;
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExpenseCategoryUpsertScreen(categoryToEdit: category)));
          },
          trailing: category.isActive ? AppStatusBadge.success(label: 'ACTIVE', small: true) : AppStatusBadge.neutral(label: 'INACTIVE', small: true),
        );
      },
    );
  }
}

Future<bool> _ensureExpensesPermission(
  BuildContext context,
  WidgetRef ref, {
  required String attemptedAction,
  required String entityType,
  String? entityId,
}) async {
  final allowed = ref.read(hasPermissionProvider(TeamPermission.manageExpenses));
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
  }
  return false;
}