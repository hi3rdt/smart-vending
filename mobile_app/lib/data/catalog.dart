// Product catalog for cabinet A-03 (2 shelves × 2 zones).
//
// This mirrors the seed data the backend/Raspberry Pi use. Keep `sku`,
// `aiLabel` and the weight fields identical to the vision model labels and the
// load-cell calibration; the app only DISPLAYS them (the server decides the cart).

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../widgets/cart.dart';

@immutable
class Product {
  const Product({
    required this.sku,
    required this.aiLabel,
    required this.name,
    required this.shortName,
    required this.unit,
    required this.priceVnd,
    required this.unitWeightG,
    required this.toleranceG,
    required this.shelf,
    required this.zone,
    required this.initialStock,
  })  : assert(priceVnd >= 0),
        assert(unitWeightG > 0),
        assert(toleranceG >= 0 && toleranceG < unitWeightG / 2,
            'Tolerance must stay below half a unit, or 1 vs 2 items become ambiguous'),
        assert(initialStock >= 0);

  final String sku; // e.g. "milo_180ml"
  final String aiLabel; // class name emitted by the camera model, e.g. "milo"
  final String name; // customer-facing, Vietnamese
  final String shortName; // fits a shelf slot / toast
  final String unit; // "hộp", "lon", "gói"
  final int priceVnd; // integer dong, never double
  final int unitWeightG; // calibrated mean weight of ONE item
  final int toleranceG; // accepted deviation per item
  final int shelf; // 1-based
  final String zone; // "A".."D"
  final int initialStock;

  /// Converts a measured weight change on this product's zone into an item
  /// count. Returns null when the change matches no whole number of items
  /// (noise, a foreign object, or a misplaced product) - the caller should then
  /// fall back to the camera or flag the event instead of guessing.
  ///
  /// [deltaG] < 0 means weight left the shelf (items taken).
  int? itemsFromWeightDelta(double deltaG) {
    final double magnitude = deltaG.abs();
    final int n = (magnitude / unitWeightG).round();
    if (n == 0) return null;
    // Tolerance grows with the item count (independent per-item variance ≈ √n),
    // but never below one item's tolerance.
    final double allowed = toleranceG * math.sqrt(n);
    if ((magnitude - n * unitWeightG).abs() > allowed) return null;
    return deltaG < 0 ? -n : n;
  }

  /// Builds a cart line for this product.
  CartLine toCartLine(int quantity, {CartChange? change}) => CartLine(
        sku: sku,
        name: name,
        quantity: quantity,
        unitPrice: priceVnd,
        change: change,
      );
}

/// Cabinet A-03 as currently stocked: 4 products, 6 items in total.
const List<Product> kCabinetA03 = <Product>[
  Product(
    sku: 'milo_180ml',
    aiLabel: 'milo',
    name: 'Milo 180 ml',
    shortName: 'Milo',
    unit: 'hộp',
    priceVnd: 12000,
    unitWeightG: 190,
    toleranceG: 12,
    shelf: 1,
    zone: 'A',
    initialStock: 2,
  ),
  Product(
    sku: 'pepsi_can_330ml',
    aiLabel: 'pepsi',
    name: 'Pepsi lon 330 ml',
    shortName: 'Pepsi',
    unit: 'lon',
    priceVnd: 12000,
    unitWeightG: 335,
    toleranceG: 20,
    shelf: 1,
    zone: 'B',
    initialStock: 2,
  ),
  Product(
    sku: 'nabati_cheese_50g',
    aiLabel: 'nabati',
    name: 'Nabati Wafer phô mai 50 g',
    shortName: 'Nabati',
    unit: 'gói',
    priceVnd: 12000,
    unitWeightG: 52,
    toleranceG: 7,
    shelf: 2,
    zone: 'C',
    initialStock: 1,
  ),
  Product(
    sku: 'pocky_strawberry_38g',
    aiLabel: 'pocky',
    name: 'Pocky dâu 38 g',
    shortName: 'Pocky dâu',
    unit: 'hộp',
    priceVnd: 12000,
    unitWeightG: 48,
    toleranceG: 7,
    shelf: 2,
    zone: 'D',
    initialStock: 1,
  ),
];

/// Lookup by SKU (server events carry the SKU).
Product? productBySku(String sku) {
  for (final Product p in kCabinetA03) {
    if (p.sku == sku) return p;
  }
  return null;
}

/// Lookup by camera label.
Product? productByAiLabel(String label) {
  for (final Product p in kCabinetA03) {
    if (p.aiLabel == label) return p;
  }
  return null;
}
