import 'package:material_ui/material_ui.dart';

/// Maps stored icon keys (database) to icons. Keys are stable; the icon a key
/// shows can change freely. Unknown keys fall back to a neutral icon.
abstract final class AppIcons {
  static const _accounts = <String, IconData>{
    'cash': Icons.payments_rounded,
    'bank': Icons.account_balance_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'card': Icons.credit_card_rounded,
  };

  /// Icons offered when creating or editing a category, in picker order.
  static const _categories = <String, IconData>{
    'restaurant': Icons.restaurant_rounded,
    'snacks': Icons.fastfood_rounded,
    'coffee': Icons.coffee_rounded,
    'grocery': Icons.local_grocery_store_rounded,
    'bus': Icons.directions_bus_rounded,
    'rickshaw': Icons.electric_rickshaw_rounded,
    'taxi': Icons.local_taxi_rounded,
    'bike': Icons.two_wheeler_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'clothes': Icons.checkroom_rounded,
    'receipt': Icons.receipt_long_rounded,
    'electricity': Icons.bolt_rounded,
    'water': Icons.water_drop_rounded,
    'gas': Icons.local_fire_department_rounded,
    'internet': Icons.wifi_rounded,
    'phone': Icons.phone_android_rounded,
    'home': Icons.home_rounded,
    'repair': Icons.build_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'health': Icons.local_hospital_rounded,
    'medicine': Icons.medication_rounded,
    'fitness': Icons.fitness_center_rounded,
    'beauty': Icons.spa_rounded,
    'school': Icons.school_rounded,
    'books': Icons.menu_book_rounded,
    'movie': Icons.movie_rounded,
    'games': Icons.sports_esports_rounded,
    'travel': Icons.flight_rounded,
    'family': Icons.family_restroom_rounded,
    'baby': Icons.child_care_rounded,
    'pets': Icons.pets_rounded,
    'gift': Icons.card_giftcard_rounded,
    'charity': Icons.volunteer_activism_rounded,
    'work': Icons.work_rounded,
    'store': Icons.storefront_rounded,
    'payments': Icons.payments_rounded,
    'savings': Icons.savings_rounded,
    'investment': Icons.trending_up_rounded,
    'more': Icons.more_horiz_rounded,
  };

  static IconData of(String key) =>
      _categories[key] ?? _accounts[key] ?? Icons.category_rounded;

  static Iterable<String> get categoryKeys => _categories.keys;
}
