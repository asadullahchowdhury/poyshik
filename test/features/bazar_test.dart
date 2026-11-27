import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/features/bazar/bazar_repository.dart';

void main() {
  test('parses a trailing quantity in English and Bangla', () {
    expect(parseBazarEntry('Rice 5 kg'), ('Rice', '5 kg'));
    expect(parseBazarEntry('  Eggs   2 dozen '), ('Eggs', '2 dozen'));
    expect(parseBazarEntry('Milk 1.5L'), ('Milk', '1.5L'));
    expect(parseBazarEntry('চাল ৫ কেজি'), ('চাল', '৫ কেজি'));
    expect(parseBazarEntry('ডিম ২ হালি'), ('ডিম', '২ হালি'));
    expect(parseBazarEntry('Soap 3'), ('Soap', '3'));
    expect(parseBazarEntry('Dettol'), ('Dettol', null));
    // A number that is part of the name with no space stays in the name.
    expect(parseBazarEntry('7up'), ('7up', null));
  });

  test('a spoken list becomes separate items, with prices', () {
    List<(String, String?, int?)> parse(String s) => [
      for (final e in parseBazarItems(s)) (e.name, e.quantity, e.price?.minor),
    ];
    expect(parse('chal 5 kg dal 2 kg and tel 1 litre'), [
      ('chal', '5 kg', null),
      ('dal', '2 kg', null),
      ('tel', '1 litre', null),
    ]);
    expect(parse('চাল ৫ কেজি ৪৫০ টাকা আর ডিম ২ হালি'), [
      ('চাল', '৫ কেজি', 45000),
      ('ডিম', '২ হালি', null),
    ]);
    expect(parse('onion 2kg 120 taka, salt, soap 3 ৳150'), [
      ('onion', '2kg', 12000),
      ('salt', null, null),
      ('soap', '3', 15000),
    ]);
    expect(parse('milk and eggs and 7up'), [
      ('milk', null, null),
      ('eggs', null, null),
      ('7up', null, null),
    ]);
    expect(parse('rice 5 kg 450'), [('rice', '5 kg', 45000)]);
  });

  test('picks the guess that reads as the most items', () {
    expect(
      bestBazarText(['chalk 5 kg dial', 'chal 5 kg dal 2 kg', 'shall 5']),
      'chal 5 kg dal 2 kg',
    );
  });

  group('repository', () {
    late AppDatabase db;
    late BazarRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = BazarRepository(db);
    });
    tearDown(() => db.close());

    test('a pasted list becomes one item per line, in order', () async {
      await repo.addFromText('Rice 5 kg\nOil 1 L, Onion 2 kg\n\n');
      final items = await repo.watchAll().first;
      expect(items.map((i) => i.name), ['Rice', 'Oil', 'Onion']);
      expect(items.map((i) => i.quantity), ['5 kg', '1 L', '2 kg']);
    });

    test('tick, clear bought with undo, untick all for next time', () async {
      await repo.addFromText('Rice\nOil\nSalt');
      var items = await repo.watchAll().first;
      await repo.setDone(items[0].id, done: true);
      await repo.setDone(items[1].id, done: true);
      items = await repo.watchAll().first;
      // Items to buy come first.
      expect(items.map((i) => i.name), ['Salt', 'Rice', 'Oil']);

      final cleared = await repo.clearDone();
      expect(cleared, hasLength(2));
      expect(await repo.watchAll().first, hasLength(1));
      await repo.restoreAll(cleared);
      expect(await repo.watchAll().first, hasLength(3));

      await repo.untickAll();
      items = await repo.watchAll().first;
      expect(items.every((i) => !i.isDone), isTrue);
    });

    test('edit sets quantity and price; delete and restore', () async {
      await repo.addFromText('Fish');
      final fish = (await repo.watchAll().first).single;
      await repo.update(
        fish.id,
        name: 'Hilsa',
        quantity: '1 kg',
        estimate: const Money.taka(1200),
      );
      final edited = (await repo.watchAll().first).single;
      expect(edited.name, 'Hilsa');
      expect(edited.estimate, 120000);
      final row = await repo.delete(fish.id);
      expect(await repo.watchAll().first, isEmpty);
      await repo.restore(row!);
      expect((await repo.watchAll().first).single.quantity, '1 kg');
      // Clearing the price removes it.
      await repo.update(fish.id, name: 'Hilsa');
      expect((await repo.watchAll().first).single.estimate, isNull);
    });
  });
}
