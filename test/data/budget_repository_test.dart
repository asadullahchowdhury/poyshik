import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/features/budgets/budget_repository.dart';

void main() {
  group('BudgetRepository', () {
    late AppDatabase db;
    late BudgetRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = BudgetRepository(db);
    });
    tearDown(() => db.close());

    test('no budget by default; set replaces; clear removes', () async {
      expect(await repo.watchOverall().first, isNull);

      await repo.setOverall(const Money.taka(20000));
      await repo.setOverall(const Money.taka(25000));
      expect(await repo.watchOverall().first, const Money.taka(25000));
      expect(await db.select(db.budgets).get(), hasLength(1));

      await repo.clearOverall();
      expect(await repo.watchOverall().first, isNull);
    });
  });

  group('budgetStatus', () {
    // 25 Nov: 6 days left including today.
    final now = DateTime(2026, 11, 25, 10);

    test('safe to spend per day splits the remainder over days left', () {
      final s = budgetStatus(
        budget: const Money.taka(20000),
        spent: const Money.taka(12500),
        now: now,
      );
      expect(s.remaining, const Money.taka(7500));
      expect(s.daysLeft, 6);
      expect(s.perDay, const Money.taka(1250));
      expect(s.progress, closeTo(0.625, 1e-9));
      expect(s.isOver, isFalse);
    });

    test('over budget', () {
      final s = budgetStatus(
        budget: const Money.taka(10000),
        spent: const Money.taka(11000),
        now: now,
      );
      expect(s.isOver, isTrue);
      expect(s.remaining, const Money.taka(-1000));
      expect(s.perDay, Money.zero);
      expect(s.progress, closeTo(1.1, 1e-9));
    });

    test('last day of month gets the whole remainder', () {
      final s = budgetStatus(
        budget: const Money.taka(1000),
        spent: const Money.taka(400),
        now: DateTime(2026, 11, 30, 21),
      );
      expect(s.daysLeft, 1);
      expect(s.perDay, const Money.taka(600));
    });
  });
}
