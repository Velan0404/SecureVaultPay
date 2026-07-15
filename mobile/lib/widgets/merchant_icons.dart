import 'package:flutter/material.dart';

/// Icon set for demo Merchants. Stored on the backend as the string key
/// (e.g. "shopping_cart"), resolved to an [IconData] here for display —
/// keeps [MerchantModel] free of any Flutter dependency, matching
/// [WalletIcons]'s convention for Purpose Wallets.
class MerchantIcons {
  MerchantIcons._();

  static const Map<String, IconData> byName = {
    'shopping_cart': Icons.shopping_cart_outlined,
    'local_grocery_store': Icons.local_grocery_store_outlined,
    'store': Icons.store_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'delivery_dining': Icons.delivery_dining_outlined,
    'restaurant': Icons.restaurant_outlined,
    'local_gas_station': Icons.local_gas_station_outlined,
    'local_pharmacy': Icons.local_pharmacy_outlined,
    'train': Icons.train_outlined,
  };

  static IconData resolve(String? name) => byName[name] ?? Icons.storefront_outlined;
}

/// Display labels for the backend's MerchantCategory enum values — kept
/// separate from the raw string so new categories the backend adds still
/// render (falls back to the raw value) instead of throwing.
class MerchantCategories {
  MerchantCategories._();

  static const List<String> all = [
    'GROCERY',
    'FOOD',
    'FUEL',
    'SHOPPING',
    'ENTERTAINMENT',
    'HEALTHCARE',
    'EDUCATION',
    'UTILITY',
    'TRAVEL',
    'OTHER',
  ];

  static const Map<String, String> _labels = {
    'GROCERY': 'Grocery',
    'FOOD': 'Food',
    'FUEL': 'Fuel',
    'SHOPPING': 'Shopping',
    'ENTERTAINMENT': 'Entertainment',
    'HEALTHCARE': 'Healthcare',
    'EDUCATION': 'Education',
    'UTILITY': 'Utility',
    'TRAVEL': 'Travel',
    'OTHER': 'Other',
  };

  static String label(String category) => _labels[category] ?? category;
}
