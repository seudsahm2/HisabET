import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabet/features/contacts/presentation/providers/contacts_providers.dart'
    show appDatabaseProvider;
import 'package:hisabet/features/expenses/data/models/expense_category_model.dart';
import 'package:hisabet/features/expenses/data/models/expense_model.dart';
import 'package:hisabet/features/expenses/data/repositories/expenses_repository.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExpensesRepositoryImpl(db);
});

final allExpensesProvider = FutureProvider<List<ExpenseModel>>((ref) async {
  final repo = ref.watch(expensesRepositoryProvider);
  return repo.getAllExpenses();
});

final expenseProvider = FutureProvider.family<ExpenseModel?, String>((ref, id) async {
  final repo = ref.watch(expensesRepositoryProvider);
  return repo.getExpenseById(id);
});

final allExpenseCategoriesProvider = FutureProvider<List<ExpenseCategoryModel>>((ref) async {
  final repo = ref.watch(expensesRepositoryProvider);
  return repo.getAllCategories();
});

final expenseCategoryProvider = FutureProvider.family<ExpenseCategoryModel?, String>((ref, id) async {
  final repo = ref.watch(expensesRepositoryProvider);
  return repo.getCategoryById(id);
});