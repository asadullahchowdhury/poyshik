import 'package:material_ui/material_ui.dart';

/// Maps stored icon keys (database) to icons. Keys are stable; the icon a key
/// shows can change freely. Unknown keys fall back to a neutral icon.
abstract final class AppIcons {
  static const _map = <String, IconData>{
    // Accounts
    'cash': Icons.payments_rounded,
    'bank': Icons.account_balance_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'card': Icons.credit_card_rounded,
    // Categories
    'restaurant': Icons.restaurant_rounded,
    'grocery': Icons.local_grocery_store_rounded,
    'bus': Icons.directions_bus_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'receipt': Icons.receipt_long_rounded,
    'home': Icons.home_rounded,
    'health': Icons.local_hospital_rounded,
    'school': Icons.school_rounded,
    'movie': Icons.movie_rounded,
    'phone': Icons.phone_android_rounded,
    'gift': Icons.card_giftcard_rounded,
    'more': Icons.more_horiz_rounded,
    'work': Icons.work_rounded,
    'store': Icons.storefront_rounded,
    'payments': Icons.payments_rounded,
    'coffee': Icons.coffee_rounded,
  };

  static IconData of(String key) => _map[key] ?? Icons.category_rounded;

  static Iterable<String> get keys => _map.keys;
}
