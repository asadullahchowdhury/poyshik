import 'package:material_ui/material_ui.dart';

import 'phosphor.dart';

/// Maps stored icon keys (database) to icons. Keys are stable; the icon a key
/// shows can change freely. Unknown keys fall back to a neutral icon.
///
/// Phosphor duotone icons (MIT): an outline plus a soft fill in the same
/// colour. [of] returns the outline; CategoryIcon adds the fill from
/// [secondaryOf]. A plain Icon shows the outline only, which also reads well.
abstract final class AppIcons {
  static const _accounts = <String, Duotone>{
    'cash': PhDuotone.money,
    'bank': PhDuotone.bank,
    'wallet': PhDuotone.wallet,
    'card': PhDuotone.creditCard,
  };

  /// Icons offered when creating or editing a category, in picker order.
  static const _categories = <String, Duotone>{
    'restaurant': PhDuotone.forkKnife,
    'snacks': PhDuotone.hamburger,
    'coffee': PhDuotone.coffee,
    'grocery': PhDuotone.shoppingCart,
    'bus': PhDuotone.bus,
    'rickshaw': PhDuotone.scooter,
    'taxi': PhDuotone.taxi,
    'bike': PhDuotone.motorcycle,
    'fuel': PhDuotone.gasPump,
    'shopping_bag': PhDuotone.shoppingBag,
    'clothes': PhDuotone.tShirt,
    'receipt': PhDuotone.receipt,
    'electricity': PhDuotone.lightning,
    'water': PhDuotone.drop,
    'gas': PhDuotone.flame,
    'internet': PhDuotone.wifiHigh,
    'phone': PhDuotone.deviceMobile,
    'home': PhDuotone.house,
    'repair': PhDuotone.wrench,
    'laundry': PhDuotone.washingMachine,
    'health': PhDuotone.firstAidKit,
    'medicine': PhDuotone.pill,
    'fitness': PhDuotone.barbell,
    'beauty': PhDuotone.flowerLotus,
    'school': PhDuotone.graduationCap,
    'books': PhDuotone.bookOpen,
    'movie': PhDuotone.filmSlate,
    'games': PhDuotone.gameController,
    'travel': PhDuotone.airplaneTilt,
    'family': PhDuotone.usersThree,
    'baby': PhDuotone.baby,
    'pets': PhDuotone.pawPrint,
    'gift': PhDuotone.gift,
    'charity': PhDuotone.handHeart,
    'work': PhDuotone.briefcase,
    'store': PhDuotone.storefront,
    'payments': PhDuotone.money,
    'savings': PhDuotone.piggyBank,
    'investment': PhDuotone.trendUp,
    'more': PhDuotone.dotsThree,
  };

  static IconData of(String key) =>
      (_categories[key] ?? _accounts[key] ?? PhDuotone.tag).primary;

  /// The soft fill layer that goes under [primary], if it is one of ours.
  static IconData? secondaryOf(IconData primary) => _secondary[primary];

  static final Map<IconData, IconData> _secondary = {
    for (final d in [..._categories.values, ..._accounts.values, PhDuotone.tag])
      d.primary: d.secondary,
  };

  static Iterable<String> get categoryKeys => _categories.keys;
}
