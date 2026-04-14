import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/expenses/data/models/expense_category_model.dart';
import 'package:hisabet/features/expenses/data/models/expense_model.dart';
import 'package:uuid/uuid.dart';

abstract class ExpensesRepository {
  Future<List<ExpenseModel>> getAllExpenses();
  Future<ExpenseModel?> getExpenseById(String id);
  Future<List<ExpenseCategoryModel>> getAllCategories();
  Future<ExpenseCategoryModel?> getCategoryById(String id);
  Future<void> addExpense({
    required String categoryId,
    required String title,
    String? vendor,
    required Decimal amount,
    required DateTime spentAt,
    String paymentMethod = 'cash',
    String? description,
    String? receiptPath,
    bool isRecurring = false,
    int? recurrenceDays,
  });
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  Future<void> addCategory({
    required String name,
    String colorHex = 'FF8A3D',
    String? notes,
    bool isActive = true,
  });
  Future<void> updateCategory(ExpenseCategoryModel category);
  Future<void> deleteCategory(String id);
  Future<void> ensureSeedCategories();
}

class ExpensesRepositoryImpl implements ExpensesRepository {
  final AppDatabase _db;

  ExpensesRepositoryImpl(this._db);

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    await ensureSeedCategories();
    final rows = await (
      _db.select(_db.expenses)
        ..orderBy([(t) => OrderingTerm.desc(t.spentAt)])
    ).get();
    return rows.map(ExpenseModel.fromDb).toList();
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    final row = await (_db.select(_db.expenses)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : ExpenseModel.fromDb(row);
  }

  @override
  Future<List<ExpenseCategoryModel>> getAllCategories() async {
    await ensureSeedCategories();
    final rows = await (
      _db.select(_db.expenseCategories)
        ..orderBy([(t) => OrderingTerm.asc(t.name)])
    ).get();
    return rows.map(ExpenseCategoryModel.fromDb).toList();
  }

  @override
  Future<ExpenseCategoryModel?> getCategoryById(String id) async {
    final row = await (_db.select(_db.expenseCategories)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : ExpenseCategoryModel.fromDb(row);
  }

  @override
  Future<void> addExpense({
    required String categoryId,
    required String title,
    String? vendor,
    required Decimal amount,
    required DateTime spentAt,
    String paymentMethod = 'cash',
    String? description,
    String? receiptPath,
    bool isRecurring = false,
    int? recurrenceDays,
  }) async {
    final now = DateTime.now();
    final expense = ExpenseModel(
      id: const Uuid().v4(),
      categoryId: categoryId,
      title: title,
      vendor: vendor,
      amount: amount,
      spentAt: spentAt,
      paymentMethod: paymentMethod,
      description: description,
      receiptPath: receiptPath,
      isRecurring: isRecurring,
      recurrenceDays: recurrenceDays,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.expenses).insert(expense.toDbCompanion());
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    final updated = expense.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.expenses)..where((tbl) => tbl.id.equals(expense.id)))
        .write(updated.toDbCompanion());
  }

  @override
  Future<void> deleteExpense(String id) async {
    await (_db.delete(_db.expenses)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> addCategory({
    required String name,
    String colorHex = 'FF8A3D',
    String? notes,
    bool isActive = true,
  }) async {
    final now = DateTime.now();
    final category = ExpenseCategoryModel(
      id: const Uuid().v4(),
      name: name,
      colorHex: colorHex,
      notes: notes,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.expenseCategories).insert(category.toDbCompanion());
  }

  @override
  Future<void> updateCategory(ExpenseCategoryModel category) async {
    final updated = category.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.expenseCategories)..where((tbl) => tbl.id.equals(category.id)))
        .write(updated.toDbCompanion());
  }

  @override
  Future<void> deleteCategory(String id) async {
    await (_db.delete(_db.expenseCategories)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> ensureSeedCategories() async {
    final count = await _db.select(_db.expenseCategories).get().then((rows) => rows.length);
    if (count > 0) return;

    final now = DateTime.now();
    final seed = <String>[
      'Rent',
      'Fuel',
      'Transport',
      'Packaging',
      'Utilities',
      'Salary',
      'Repairs',
      'Internet',
      'Office Supplies',
      'Miscellaneous',
    ].map((name) {
      return ExpenseCategoriesCompanion.insert(
        id: const Uuid().v4(),
        name: name,
        colorHex: const Value('FF8A3D'),
        notes: const Value.absent(),
        isActive: const Value(true),
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    for (final category in seed) {
      await _db.into(_db.expenseCategories).insert(category);
    }
  }
}