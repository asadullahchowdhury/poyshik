import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/settings_repository.dart';
import 'package:poyshik/features/recurring/recurrence.dart';
import 'package:poyshik/features/recurring/recurring_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

const _monthly = RecurrenceFrequency.monthly;

void main() {
  group('schedule math', () {
    test('monthly on the 31st clamps, then returns to the 31st', () {
      final start = DateTime(2026, 1, 31, 9);
      expect(occurrence(start, _monthly, 1, 1), DateTime(2026, 2, 28, 9));
      expect(occurrence(start, _monthly, 1, 3), DateTime(2026, 4, 30, 9));
      expect(occurrence(start, _monthly, 1, 4), DateTime(2026, 5, 31, 9));
    });

    test('yearly on 29 Feb, weekly and every-3-months', () {
      final leap = DateTime(2028, 2, 29);
      expect(
        occurrence(leap, RecurrenceFrequency.yearly, 1, 1),
        DateTime(2029, 2, 28),
      );
      expect(
        occurrence(DateTime(2026, 11, 28), RecurrenceFrequency.weekly, 1, 1),
        DateTime(2026, 12, 5),
      );
      expect(
        occurrence(DateTime(2026, 11, 15), _monthly, 3, 1),
        DateTime(2027, 2, 15),
      );
    });

    test('next occurrence after a moment', () {
      final start = DateTime(2026, 1, 31, 9);
      expect(
        nextOccurrenceAfter(start, _monthly, 1, DateTime(2026, 2, 28, 9)),
        DateTime(2026, 3, 31, 9),
      );
      expect(
        nextOccurrenceAfter(
          DateTime(2026, 1, 1),
          RecurrenceFrequency.daily,
          1,
          DateTime(2026, 3, 1, 12),
        ),
        DateTime(2026, 3, 2),
      );
    });
  });

  group('repository', () {
    late AppDatabase db;
    late TransactionsRepository tx;
    late RecurringRepository repo;
    late String cash;
    late String food;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      tx = TransactionsRepository(db, SettingsRepository(db));
      repo = RecurringRepository(db, tx);
      cash = (await db.select(db.accounts).get()).first.id;
      food = (await (db.select(
        db.categories,
      )..where((c) => c.systemKey.equals('food'))).getSingle()).id;
    });
    tearDown(() => db.close());

    Future<String> create({required bool autoLog}) async {
      final draft = (
        type: TransactionType.expense,
        amount: const Money.taka(1200),
        accountId: cash,
        categoryId: food,
        toAccountId: null,
        occurredAt: DateTime(2026, 9, 5, 10),
        note: 'Internet',
      );
      final first = await tx.add(draft);
      return repo.createFrom(draft, (
        frequency: _monthly,
        interval: 1,
        autoLog: autoLog,
      ), firstId: first);
    }

    Future<List<TransactionRecord>> linked(String ruleId) => (db.select(
      db.transactions,
    )..where((t) => t.recurringId.equals(ruleId))).get();

    test('catch-up logs every missed auto occurrence once', () async {
      final id = await create(autoLog: true);
      expect(await repo.catchUp(DateTime(2026, 11, 20)), 2); // Oct 5, Nov 5
      expect(await repo.catchUp(DateTime(2026, 11, 20)), 0); // idempotent
      final rows = await linked(id);
      expect(rows.map((r) => r.occurredAt.month), unorderedEquals([9, 10, 11]));
      final rule = await (db.select(
        db.recurringRules,
      )..where((r) => r.id.equals(id))).getSingle();
      expect(rule.nextDue, DateTime(2026, 12, 5, 10));
    });

    test(
      'bills wait: mark paid logs and advances, skip only advances',
      () async {
        final id = await create(autoLog: false);
        expect(await repo.catchUp(DateTime(2026, 11, 20)), 0);
        var rule = await (db.select(
          db.recurringRules,
        )..where((r) => r.id.equals(id))).getSingle();
        await repo.markPaid(rule, now: DateTime(2026, 10, 6, 18));
        expect(await linked(id), hasLength(2));
        rule = await (db.select(
          db.recurringRules,
        )..where((r) => r.id.equals(id))).getSingle();
        expect(rule.nextDue, DateTime(2026, 11, 5, 10));
        await repo.skip(rule);
        rule = await (db.select(
          db.recurringRules,
        )..where((r) => r.id.equals(id))).getSingle();
        expect(rule.nextDue, DateTime(2026, 12, 5, 10));
        expect(await linked(id), hasLength(2));
      },
    );

    test('paused rules are not caught up; delete keeps past entries', () async {
      final id = await create(autoLog: true);
      await repo.setPaused(id, paused: true);
      expect(await repo.catchUp(DateTime(2026, 11, 20)), 0);
      await repo.delete(id);
      expect(await db.select(db.recurringRules).get(), isEmpty);
      final all = await db.select(db.transactions).get();
      expect(all, hasLength(1));
      expect(all.single.recurringId, isNull);
    });
  });
}
