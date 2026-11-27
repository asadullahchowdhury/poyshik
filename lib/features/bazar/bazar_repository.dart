import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

/// One parsed list entry: "Rice 5 kg ৳450" → ("Rice", "5 kg", ৳450).
typedef BazarEntry = ({String name, String? quantity, Money? price});

const _units = {
  'kg', 'kilo', 'kilos', 'g', 'gm', 'gram', 'grams', 'l', 'ltr', 'litre', //
  'litres', 'liter', 'liters', 'ml', 'pcs', 'pc', 'piece', 'pieces',
  'dozen', 'pack', 'packs', 'packet', 'packets', 'box', 'boxes', 'bottle',
  'bottles', 'কেজি', 'কিলো', 'গ্রাম', 'লিটার', 'মিলি', 'টি', 'টা', 'পিস',
  'ডজন', 'প্যাকেট', 'হালি', 'বোতল',
};
const _currency = {'taka', 'tk', 'টাকা'};
const _separators = {'and', 'then', 'also', 'আর', 'এবং', 'ও', 'তারপর'};
const _bnDigits = '০১২৩৪৫৬৭৮৯';

final _numberUnit = RegExp(
  r'^([0-9০-৯]+(?:[.,][0-9০-৯]+)?)(\p{L}*)$',
  unicode: true,
);

String _latinDigits(String s) => String.fromCharCodes(
  s.runes.map((r) {
    final d = _bnDigits.indexOf(String.fromCharCode(r));
    return d >= 0 ? 0x30 + d : r;
  }),
);

/// Splits typed or spoken text into list items.
///
/// "Rice 5 kg, dal 2 kg and oil 1 litre 180 taka" gives three items: a
/// quantity ends an item, as do commas, new lines and "and / আর / এবং".
/// A number followed by "taka" / "টাকা" (or written "৳450") is the price.
/// Bangla digits are fine; quantities keep the wording that was used.
List<BazarEntry> parseBazarItems(String input) {
  final items = <BazarEntry>[];
  for (final chunk in input.split(RegExp(r'[\n,;।]'))) {
    final tokens = chunk
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final name = <String>[];
    String? quantity;
    Money? price;

    void close() {
      if (name.isNotEmpty) {
        items.add((name: name.join(' '), quantity: quantity, price: price));
      }
      name.clear();
      quantity = null;
      price = null;
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final lower = token.toLowerCase();
      if (_separators.contains(lower)) {
        close();
        continue;
      }
      if (_currency.contains(lower)) continue; // stray "taka"
      final taka = lower.startsWith('৳') ? lower.substring(1) : null;
      final match = _numberUnit.firstMatch(taka ?? lower);
      if (match == null) {
        // A word after a finished quantity or price starts the next item.
        if (quantity != null || price != null) close();
        name.add(token);
        continue;
      }
      final number = match.group(1)!;
      var unit = match.group(2)!;
      var unitToken = unit.isEmpty
          ? null
          : token.substring(token.length - unit.length);
      final next = i + 1 < tokens.length ? tokens[i + 1].toLowerCase() : null;
      final isPrice =
          taka != null ||
          _currency.contains(unit) ||
          (unit.isEmpty && next != null && _currency.contains(next)) ||
          // A second bare number after the quantity: its price.
          (unit.isEmpty && quantity != null && price == null);
      if (isPrice) {
        if (unit.isEmpty && next != null && _currency.contains(next)) i++;
        final value = double.tryParse(
          _latinDigits(number).replaceAll(',', '.'),
        );
        if (value != null && value > 0) price = Money((value * 100).round());
        continue;
      }
      if (unit.isEmpty && next != null && _units.contains(next)) {
        unit = next;
        unitToken = tokens[i + 1];
        i++;
      }
      if (unit.isNotEmpty && !_units.contains(unit)) {
        // "7up", "5star": part of a name, not a quantity.
        if (quantity != null || price != null) close();
        name.add(token);
        continue;
      }
      if (quantity != null) close();
      final digits = taka == null ? token.substring(0, number.length) : number;
      quantity = unitToken == null
          ? digits
          : (token.length > number.length ? token : '$digits $unitToken');
    }
    close();
  }
  return items;
}

/// From the recognizer's guesses (best first), the one that reads as the
/// most items with quantities. Ties keep the recognizer's order.
String bestBazarText(List<String> heard) {
  var best = heard.first;
  var bestScore = -1;
  for (final text in heard) {
    final items = parseBazarItems(text);
    final score =
        items.length * 2 + items.where((i) => i.quantity != null).length;
    if (score > bestScore) {
      best = text;
      bestScore = score;
    }
  }
  return best;
}

/// Splits "Rice 5 kg" into ("Rice", "5 kg"): the first item of
/// [parseBazarItems], without its price.
(String name, String? quantity) parseBazarEntry(String input) {
  final items = parseBazarItems(input);
  if (items.isEmpty) return (input.trim(), null);
  return (items.first.name, items.first.quantity);
}

/// The shopping list, a notepad with tick boxes.
class BazarRepository {
  BazarRepository(this._db);

  final AppDatabase _db;

  /// Items to buy first (in the order added), then the ticked ones.
  Stream<List<BazarItem>> watchAll() =>
      (_db.select(_db.bazarItems)..orderBy([
            (b) => OrderingTerm.asc(b.isDone),
            (b) => OrderingTerm.asc(b.sortOrder),
            (b) => OrderingTerm.asc(b.createdAt),
          ]))
          .watch();

  /// Adds what was typed or said: one item per line, comma, "and", or
  /// quantity ("Rice 5 kg dal 2 kg" is two items). Returns how many.
  Future<int> addFromText(String text) async {
    final entries = parseBazarItems(text);
    if (entries.isEmpty) return 0;
    await _db.transaction(() async {
      final last = await (_db.selectOnly(
        _db.bazarItems,
      )..addColumns([_db.bazarItems.sortOrder.max()])).getSingle();
      var order = (last.read(_db.bazarItems.sortOrder.max()) ?? -1) + 1;
      for (final e in entries) {
        await _db
            .into(_db.bazarItems)
            .insert(
              BazarItemsCompanion.insert(
                name: _clip(e.name, 80),
                quantity: Value(
                  e.quantity == null ? null : _clip(e.quantity!, 30),
                ),
                estimate: Value(e.price?.minor),
                sortOrder: Value(order++),
              ),
            );
      }
    });
    return entries.length;
  }

  /// Sets or clears an item's price (expected before buying, paid after).
  Future<void> setPrice(String id, Money? price) =>
      (_db.update(_db.bazarItems)..where((b) => b.id.equals(id))).write(
        BazarItemsCompanion(
          estimate: Value(
            price == null || !price.isPositive ? null : price.minor,
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> update(
    String id, {
    required String name,
    String? quantity,
    Money? estimate,
  }) {
    final q = quantity?.trim();
    return (_db.update(_db.bazarItems)..where((b) => b.id.equals(id))).write(
      BazarItemsCompanion(
        name: Value(_clip(name.trim(), 80)),
        quantity: Value(q == null || q.isEmpty ? null : _clip(q, 30)),
        estimate: Value(
          estimate == null || !estimate.isPositive ? null : estimate.minor,
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setDone(String id, {required bool done}) =>
      (_db.update(_db.bazarItems)..where((b) => b.id.equals(id))).write(
        BazarItemsCompanion(
          isDone: Value(done),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes and returns the row, for Undo.
  Future<BazarItem?> delete(String id) async {
    final row = await (_db.select(
      _db.bazarItems,
    )..where((b) => b.id.equals(id))).getSingleOrNull();
    await (_db.delete(_db.bazarItems)..where((b) => b.id.equals(id))).go();
    return row;
  }

  Future<void> restore(BazarItem row) =>
      _db.into(_db.bazarItems).insertOnConflictUpdate(row);

  /// Removes everything already bought. Returns the rows, for Undo.
  Future<List<BazarItem>> clearDone() => _db.transaction(() async {
    final rows = await (_db.select(
      _db.bazarItems,
    )..where((b) => b.isDone.equals(true))).get();
    await (_db.delete(
      _db.bazarItems,
    )..where((b) => b.isDone.equals(true))).go();
    return rows;
  });

  Future<void> restoreAll(List<BazarItem> rows) =>
      _db.batch((b) => b.insertAllOnConflictUpdate(_db.bazarItems, rows));

  /// Unticks everything: the same list again for next month's shopping.
  Future<void> untickAll() =>
      (_db.update(_db.bazarItems)..where((b) => b.isDone.equals(true))).write(
        BazarItemsCompanion(
          isDone: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );

  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}

final bazarRepositoryProvider = Provider<BazarRepository>(
  (ref) => BazarRepository(ref.watch(appDatabaseProvider)),
);

final bazarItemsProvider = StreamProvider<List<BazarItem>>(
  (ref) => ref.watch(bazarRepositoryProvider).watchAll(),
);
