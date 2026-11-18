import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisabet/core/database/app_database.dart';
import 'package:hisabet/features/inventory/data/models/product_model.dart';
import 'package:hisabet/features/sales/data/models/pos_cart_item.dart';
import 'package:hisabet/features/sales/data/repositories/sales_repository.dart';

void main() {
  late AppDatabase db;
  late SalesRepositoryImpl repo;
  final now = DateTime(2026, 1, 1);

  Future<ProductModel> addProduct(String id, {required int stock}) async {
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: id,
            name: 'Style $id',
            sellingPrice: const Value('1200'),
            stockQuantity: Value(stock),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final row = await (db.select(db.products)..where((t) => t.id.equals(id)))
        .getSingle();
    return ProductModel.fromDb(row);
  }

  Future<int> stockOf(String id) async {
    final row = await (db.select(db.products)..where((t) => t.id.equals(id)))
        .getSingle();
    return row.stockQuantity;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SalesRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('a failing item rolls back every write of the checkout', () async {
    final ok = await addProduct('a', stock: 10);
    final short = await addProduct('b', stock: 1);

    await expectLater(
      repo.checkoutSale(
        cartItems: [
          PosCartItem(product: ok, quantity: 3),
          PosCartItem(product: short, quantity: 5), // more than in stock
        ],
        paymentMethod: 'cash',
      ),
      throwsException,
    );

    expect(await stockOf('a'), 10);
    expect(await stockOf('b'), 1);
    expect(await db.select(db.sales).get(), isEmpty);
    expect(await db.select(db.stockMovements).get(), isEmpty);
  });

  test('stock is deducted from the current row, not the cart snapshot',
      () async {
    final snapshot = await addProduct('a', stock: 10);

    // Stock changes after the item was put in the cart.
    await (db.update(db.products)..where((t) => t.id.equals('a')))
        .write(const ProductsCompanion(stockQuantity: Value(4)));

    await repo.checkoutSale(
      cartItems: [PosCartItem(product: snapshot, quantity: 3)],
      paymentMethod: 'cash',
    );

    expect(await stockOf('a'), 1);
  });

  test('a credit sale sets the contact balance from the full ledger', () async {
    final product = await addProduct('a', stock: 10);
    await db.into(db.contacts).insert(
          ContactsCompanion.insert(
            id: 'c1',
            name: 'Buyer',
            // Deliberately wrong cached value: a full recalculation fixes it,
            // an incremental update would carry the error forward.
            netBalance: const Value('999'),
            lastTransactionDate: now,
          ),
        );

    await repo.checkoutSale(
      cartItems: [PosCartItem(product: product, quantity: 2)],
      contactId: 'c1',
      paidAmount: Decimal.parse('400'),
      paymentMethod: 'credit',
    );

    final contact = await (db.select(db.contacts)
          ..where((t) => t.id.equals('c1')))
        .getSingle();
    expect(Decimal.parse(contact.netBalance), Decimal.parse('2000'));
  });
}
