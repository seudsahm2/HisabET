import 'package:flutter/material.dart';

/// The canonical business-role taxonomy for HisabET.
///
/// This is the single source of truth. Before this existed the app carried
/// three competing vocabularies — user profile roles, contact boolean flags,
/// and `products.businessRole` — which is why the Tenders module gated on an
/// `Importer` role that onboarding never offered.
///
/// The roles mirror the real Ethiopian shoe-import chain, top to bottom:
///
/// ```
/// Supplier ──▶ Broker ──▶ Wholesaler ──▶ Retailer
/// (imports)   (bulk,      (Merkato       (sells
///              no shop)    shop owner)    pairs)
/// ```
///
/// "Supplier" is what earlier revisions called "Importer" — the party who
/// brings containers in. The two are the same concept and `importer` is now
/// only accepted as a legacy alias when reading old data.
enum BusinessRole {
  supplier,
  broker,
  wholesaler,
  retailer;

  /// Stable lowercase key persisted to Firestore (`users/{uid}.roles`) and to
  /// `products.business_role`. Never change these — old rows depend on them.
  String get storageKey => name;

  /// Human-readable label for UI.
  String get label => switch (this) {
        BusinessRole.supplier => 'Supplier',
        BusinessRole.broker => 'Broker',
        BusinessRole.wholesaler => 'Wholesaler',
        BusinessRole.retailer => 'Retailer',
      };

  /// One-line explanation shown under the label in the role picker, phrased
  /// the way someone in the trade would describe themselves.
  String get description => switch (this) {
        BusinessRole.supplier =>
          'I import containers and sell cartons in bulk',
        BusinessRole.broker =>
          'I buy many cartons from importers and resell them',
        BusinessRole.wholesaler =>
          'I own a shop and buy cartons from brokers',
        BusinessRole.retailer => 'I sell individual pairs to customers',
      };

  IconData get icon => switch (this) {
        BusinessRole.supplier => Icons.directions_boat_rounded,
        BusinessRole.broker => Icons.handshake_rounded,
        BusinessRole.wholesaler => Icons.storefront_rounded,
        BusinessRole.retailer => Icons.shopping_bag_rounded,
      };

  /// The role directly above this one in the trade chain — i.e. who this role
  /// normally buys from. `null` for [BusinessRole.supplier], who imports.
  ///
  /// Drives the "Bought From" contact filter on the product form.
  BusinessRole? get buysFrom => switch (this) {
        BusinessRole.supplier => null,
        BusinessRole.broker => BusinessRole.supplier,
        BusinessRole.wholesaler => BusinessRole.broker,
        BusinessRole.retailer => BusinessRole.wholesaler,
      };

  /// True when this role represents a vendor you buy from on credit terms,
  /// and therefore gets an address / payment-terms / opening-balance profile.
  bool get keepsVendorLedger => this == BusinessRole.supplier;

  /// Parses a stored or displayed role string. Case-insensitive, and maps the
  /// legacy `importer` value onto [BusinessRole.supplier].
  ///
  /// Returns `null` for anything unrecognised so callers can decide whether to
  /// drop the value or fail loudly.
  static BusinessRole? tryParse(String? raw) {
    if (raw == null) return null;
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (key == 'importer') return BusinessRole.supplier;
    for (final role in BusinessRole.values) {
      if (role.storageKey == key) return role;
    }
    return null;
  }

  /// Parses a list of stored role strings, dropping unknown entries and
  /// collapsing duplicates (legacy data may contain both `importer` and
  /// `supplier`, which now mean the same thing).
  static List<BusinessRole> parseAll(Iterable<dynamic>? raw) {
    if (raw == null) return const [];
    final seen = <BusinessRole>{};
    for (final entry in raw) {
      final role = tryParse(entry?.toString());
      if (role != null) seen.add(role);
    }
    // Preserve canonical chain order rather than insertion order.
    return BusinessRole.values.where(seen.contains).toList();
  }

  static List<String> toStorageKeys(Iterable<BusinessRole> roles) =>
      roles.map((r) => r.storageKey).toList();
}
