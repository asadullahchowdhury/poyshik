import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/features/voice/voice_parser.dart';

void main() {
  late List<Category> categories;
  late Map<String, String> keyOf; // id → systemKey

  setUpAll(() async {
    final db = AppDatabase(NativeDatabase.memory());
    categories = await db.select(db.categories).get();
    keyOf = {for (final c in categories) c.id: c.systemKey ?? c.name};
    await db.close();
  });

  VoiceEntry parse(String s) =>
      parseVoiceEntry(s, categories: categories, names: (c) => c.name);

  void check(
    String spoken, {
    Money? amount,
    String? category,
    TransactionType? type,
    String? note,
  }) {
    final e = parse(spoken);
    expect(e.amount, amount, reason: 'amount of "$spoken"');
    expect(
      e.categoryId == null ? null : keyOf[e.categoryId],
      category,
      reason: 'category of "$spoken"',
    );
    expect(e.type, type, reason: 'type of "$spoken"');
    if (note != null) expect(e.note, note, reason: 'note of "$spoken"');
  }

  test('English phrases', () {
    check(
      'Rickshaw 50 taka',
      amount: const Money.taka(50),
      category: 'transport',
      note: 'Rickshaw',
    );
    check(
      'spent 1,250 on groceries',
      amount: const Money.taka(1250),
      category: 'groceries',
    );
    check(
      'lunch two hundred fifty',
      amount: const Money.taka(250),
      category: 'food',
    );
    check(
      'salary 45 thousand',
      amount: const Money.taka(45000),
      category: 'salary',
      type: TransactionType.income,
    );
    check(
      'internet bill 1.5k',
      amount: const Money.taka(1500),
      // "internet" is more specific than "bill".
      category: 'mobile',
    );
    check('tea twenty five', amount: const Money.taka(25), category: 'food');
    check('৳80 bus', amount: const Money.taka(80), category: 'transport');
  });

  test('Bangla phrases, digits and number words', () {
    check(
      'চা বিশ টাকা',
      amount: const Money.taka(20),
      category: 'food',
      note: 'চা',
    );
    check(
      'রিকশা ভাড়া ৬০ টাকা',
      amount: const Money.taka(60),
      category: 'transport',
    );
    check(
      'বাজার দুই হাজার পাঁচ শ',
      amount: const Money.taka(2500),
      category: 'groceries',
    );
    check(
      'বেতন পেলাম ৫০০০০',
      amount: const Money.taka(50000),
      category: 'salary',
      type: TransactionType.income,
    );
    check(
      'ওষুধ দেড় হাজার',
      amount: const Money.taka(1500),
      category: 'health',
    );
  });

  test('a custom category name beats keywords', () {
    final custom = categories.first.copyWith(
      id: 'custom',
      name: 'Office lunch',
      systemKey: const Value(null),
    );
    final e = parseVoiceEntry(
      'office lunch 300',
      categories: [...categories, custom],
      names: (c) => c.name,
    );
    expect(e.categoryId, 'custom');
    expect(e.amount, const Money.taka(300));
  });

  test('nothing understood leaves fields empty', () {
    final e = parse('hmm');
    expect(e.amount, isNull);
    expect(e.categoryId, isNull);
    expect(e.note, 'Hmm');
    expect(parse('   ').note, isNull);
  });
}
