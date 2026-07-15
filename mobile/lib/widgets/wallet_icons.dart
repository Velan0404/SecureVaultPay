import 'package:flutter/material.dart';

/// Curated icon set for Purpose Wallets. Stored on the backend as the string
/// key (e.g. "shopping_cart"), resolved to an [IconData] here for display —
/// keeps [PurposeWalletModel] free of any Flutter dependency.
class WalletIcons {
  WalletIcons._();

  static const Map<String, IconData> byName = {
    'shopping_cart': Icons.shopping_cart_outlined,
    'restaurant': Icons.restaurant_outlined,
    'flight': Icons.flight_outlined,
    'movie': Icons.movie_outlined,
    'savings': Icons.savings_outlined,
    'bolt': Icons.bolt_outlined,
    'home': Icons.home_outlined,
    'school': Icons.school_outlined,
    'favorite': Icons.favorite_outline,
    'fitness_center': Icons.fitness_center_outlined,
    'pets': Icons.pets_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,
    'directions_car': Icons.directions_car_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'wallet': Icons.account_balance_wallet_outlined,
  };

  static IconData resolve(String name) => byName[name] ?? Icons.account_balance_wallet_outlined;
}

/// Curated color set for Purpose Wallets — vivid accents chosen to read
/// clearly as tinted icon circles against the app's dark surfaces (a
/// near-black swatch would disappear on the dark theme, so every color here
/// stays well above the background's luminance).
class WalletColors {
  WalletColors._();

  static const List<String> palette = [
    '#E53935', // red
    '#2DD9A8', // teal
    '#F5A623', // orange
    '#9B6BFF', // purple
    '#3E8BFF', // blue
    '#EC4899', // pink
    '#F4C430', // gold
    '#34C759', // green
  ];

  static Color fromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.parse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return Color(value);
  }
}
