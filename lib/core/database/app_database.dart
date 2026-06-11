import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:hisabet/core/database/tables/audit_logs.dart';
import 'package:hisabet/core/database/tables/contacts.dart';
import 'package:hisabet/core/database/tables/expense_categories.dart';
import 'package:hisabet/core/database/tables/expenses.dart';
import 'package:hisabet/core/database/tables/products.dart';
import 'package:hisabet/core/database/tables/promotion_redemptions.dart';
import 'package:hisabet/core/database/tables/promotions.dart';
import 'package:hisabet/core/database/tables/purchase_order_line_items.dart';
import 'package:hisabet/core/database/tables/purchase_orders.dart';
import 'package:hisabet/core/database/tables/suppliers.dart';
import 'package:hisabet/core/database/tables/sale_line_items.dart';
import 'package:hisabet/core/database/tables/sales.dart';
import 'package:hisabet/core/database/tables/stock_movements.dart';
import 'package:hisabet/core/database/tables/team_members.dart';
import 'package:hisabet/core/database/tables/transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AuditLogs,
    Contacts,
    ExpenseCategories,
    Expenses,
    Products,
    Promotions,
    PromotionRedemptions,
    PurchaseOrderLineItems,
    PurchaseOrders,
    Suppliers,
    Sales,
    SaleLineItems,
    StockMovements,
    TeamMembers,
    Transactions,
  ],
)
class AppDatabase extends _$AppDatabase {
  final String uid;
  
  AppDatabase(this.uid) : super(_openConnection(uid));

  Future<bool> _hasColumn(String tableName, String columnName) async {
    final rows = await customSelect('PRAGMA table_info("$tableName")').get();
    for (final row in rows) {
      final name = row.data['name']?.toString();
      if (name != null && name.toLowerCase() == columnName.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  @override
  int get schemaVersion => 27;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          if (!await _hasColumn('contacts', 'linked_user_uid')) {
            await m.addColumn(contacts, contacts.linkedUserUid);
          }
        }
        if (from < 3) {
          if (!await _hasColumn('transactions', 'reference_id')) {
            await m.addColumn(transactions, transactions.referenceId);
          }
        }
        if (from < 4) {
          await m.createTable(products);
        }
        if (from < 5) {
          await m.createTable(stockMovements);
        }
        if (from < 6) {
          await m.createTable(sales);
          await m.createTable(saleLineItems);
        }
        if (from < 7) {
          if (!await _hasColumn('transactions', 'cartons')) {
            await m.addColumn(transactions, transactions.cartons);
          }
          if (!await _hasColumn('transactions', 'qty_per_carton')) {
            await m.addColumn(transactions, transactions.qtyPerCarton);
          }
          if (!await _hasColumn('transactions', 'unit_price')) {
            await m.addColumn(transactions, transactions.unitPrice);
          }
        }
        if (from < 8) {
          if (!await _hasColumn('products', 'items_per_carton')) {
            await m.addColumn(products, products.itemsPerCarton);
          }
        }
        if (from < 9) {
          if (!await _hasColumn('transactions', 'status')) {
            await m.addColumn(transactions, transactions.status);
          }
        }
        if (from < 10) {
          await m.createTable(suppliers);
        }
        if (from < 11) {
          await m.createTable(purchaseOrders);
        }
        if (from < 12) {
          if (!await _hasColumn('contacts', 'role')) {
            await m.addColumn(contacts, contacts.role);
          }
        }
        if (from < 13) {
          if (!await _hasColumn('sale_line_items', 'unit')) {
            await m.addColumn(saleLineItems, saleLineItems.unit);
          }
          if (!await _hasColumn('sale_line_items', 'items_per_carton')) {
            await m.addColumn(saleLineItems, saleLineItems.itemsPerCarton);
          }
        }
        if (from < 14) {
          if (!await _hasColumn('contacts', 'verification_status')) {
            await m.addColumn(contacts, contacts.verificationStatus);
          }
          if (!await _hasColumn('contacts', 'verification_requested_at')) {
            await m.addColumn(contacts, contacts.verificationRequestedAt);
          }
          if (!await _hasColumn('contacts', 'verification_deadline_at')) {
            await m.addColumn(contacts, contacts.verificationDeadlineAt);
          }
          if (!await _hasColumn('contacts', 'verification_timeout_policy')) {
            await m.addColumn(contacts, contacts.verificationTimeoutPolicy);
          }
        }
        if (from < 15) {
          await m.createTable(purchaseOrderLineItems);
        }
        if (from < 16) {
          await m.createTable(expenseCategories);
          await m.createTable(expenses);
        }
        if (from < 17) {
          await m.createTable(teamMembers);
        }
        if (from < 18) {
          await m.createTable(auditLogs);
        }
        if (from < 19) {
          if (!await _hasColumn('contacts', 'credit_limit')) {
            await m.addColumn(contacts, contacts.creditLimit);
          }
          if (!await _hasColumn('contacts', 'loyalty_points')) {
            await m.addColumn(contacts, contacts.loyaltyPoints);
          }
        }
        if (from < 20) {
          await m.createTable(promotions);
          await m.createTable(promotionRedemptions);
        }
        if (from < 21) {
          if (!await _hasColumn('contacts', 'verification_method')) {
            await m.addColumn(contacts, contacts.verificationMethod);
          }
        }
        if (from < 22) {
          if (!await _hasColumn('contacts', 'is_retailer')) {
            await m.addColumn(contacts, contacts.isRetailer);
          }
          if (!await _hasColumn('contacts', 'is_wholesaler')) {
            await m.addColumn(contacts, contacts.isWholesaler);
          }
          if (!await _hasColumn('contacts', 'is_broker')) {
            await m.addColumn(contacts, contacts.isBroker);
          }
          if (!await _hasColumn('contacts', 'is_supplier')) {
            await m.addColumn(contacts, contacts.isSupplier);
          }
        }
        if (from < 23) {
          if (!await _hasColumn('sales', 'contact_id')) {
            await m.addColumn(sales, sales.contactId);
          }
          if (!await _hasColumn('transactions', 'sale_id')) {
            await m.addColumn(transactions, transactions.saleId);
          }
        }
        if (from < 24) {
          if (!await _hasColumn('transactions', 'is_synced')) {
            await m.addColumn(transactions, transactions.isSynced);
          }
        }
        if (from < 25) {
          if (!await _hasColumn('transactions', 'is_deleted')) {
            await m.addColumn(transactions, transactions.isDeleted);
          }
          if (!await _hasColumn('transactions', 'deleted_at')) {
            await m.addColumn(transactions, transactions.deletedAt);
          }
          if (!await _hasColumn('contacts', 'is_deleted')) {
            await m.addColumn(contacts, contacts.isDeleted);
          }
          if (!await _hasColumn('contacts', 'deleted_at')) {
            await m.addColumn(contacts, contacts.deletedAt);
          }
          if (!await _hasColumn('products', 'is_deleted')) {
            await m.addColumn(products, products.isDeleted);
          }
          if (!await _hasColumn('products', 'deleted_at')) {
            await m.addColumn(products, products.deletedAt);
          }
        }
        if (from < 26) {
          if (!await _hasColumn('products', 'item_number')) {
            await m.addColumn(products, products.itemNumber);
          }
          if (!await _hasColumn('products', 'size_from')) {
            await m.addColumn(products, products.sizeFrom);
          }
          if (!await _hasColumn('products', 'size_to')) {
            await m.addColumn(products, products.sizeTo);
          }
          if (!await _hasColumn('products', 'series_size')) {
            await m.addColumn(products, products.seriesSize);
          }
          if (!await _hasColumn('products', 'color_distribution')) {
            await m.addColumn(products, products.colorDistribution);
          }
          if (!await _hasColumn('products', 'container_ref')) {
            await m.addColumn(products, products.containerRef);
          }
          // Note: importer_contact_id was renamed to supplier_contact_id in v27.
          // We keep this here only for users upgrading from before v26.
          if (!await _hasColumn('products', 'importer_contact_id')) {
            // Old column name — this DB will be migrated via v27 below.
          }
          if (!await _hasColumn('contacts', 'is_importer')) {
            await m.addColumn(contacts, contacts.isImporter);
          }
        }
        if (from < 27) {
          // Replace importer_contact_id with supplier_contact_id
          if (!await _hasColumn('products', 'supplier_contact_id')) {
            await m.addColumn(products, products.supplierContactId);
          }
          if (!await _hasColumn('products', 'business_role')) {
            await m.addColumn(products, products.businessRole);
          }
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Wipes all data from the database. Use with caution (e.g., when a user deletes their account).
  Future<void> clearAllData() async {
    await customStatement('PRAGMA foreign_keys = OFF');
    try {
      await transaction(() async {
        for (final table in allTables) {
          await delete(table).go();
        }
      });
    } finally {
      await customStatement('PRAGMA foreign_keys = ON');
    }
  }
}

LazyDatabase _openConnection(String uid) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hisabet_$uid.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
