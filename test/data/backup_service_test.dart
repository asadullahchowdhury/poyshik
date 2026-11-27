import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/backup/backup_service.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/data/db/balance_queries.dart';
import 'package:poyshik/data/settings_repository.dart';
import 'package:poyshik/features/accounts/accounts_repository.dart';
import 'package:poyshik/features/budgets/budget_repository.dart';
import 'package:poyshik/features/transactions/transactions_repository.dart';

Future<AppDatabase> _seeded() async {
  final db = AppDatabase(NativeDatabase.memory());
  final cash = (await db.select(db.accounts).getSingle()).id;
  final bkash = await AccountsRepository(db).create(
    name: 'bKash',
    type: AccountType.mobileWallet,
    colorIndex: 6,
    openingBalance: const Money.taka(500),
  );
  final food = (await (db.select(
    db.categories,
  )..where((c) => c.systemKey.equals('food'))).getSingle()).id;
  final tx = TransactionsRepository(db, SettingsRepository(db));
  await tx.add((
    type: TransactionType.expense,
    amount: const Money(32050),
    accountId: cash,
    categoryId: food,
    toAccountId: null,
    occurredAt: DateTime(2026, 11, 26, 13, 5),
    note: 'Lunch, with "Rafi"',
  ));
  await tx.add((
    type: TransactionType.transfer,
    amount: const Money.taka(200),
    accountId: cash,
    categoryId: null,
    toAccountId: bkash.id,
    occurredAt: DateTime(2026, 11, 26, 18),
    note: null,
  ));
  await BudgetRepository(db).setOverall(const Money.taka(20000));
  await SettingsRepository(db).set(SettingKeys.themeMode, 'dark');
  return db;
}

/// A real backup of [db] with its accounts removed, so every transaction
/// references a missing account.
Future<String> _withoutAccounts(AppDatabase db) async {
  final map =
      jsonDecode(await BackupService(db).exportJson()) as Map<String, dynamic>;
  (map['data'] as Map<String, dynamic>)['accounts'] = <Object>[];
  return jsonEncode(map);
}

void main() {
  test(
    'backup → restore into a fresh database reproduces everything',
    () async {
      final source = await _seeded();
      final json = await BackupService(source).exportJson();
      final sourceBalances = await source.accountBalances();

      final target = AppDatabase(NativeDatabase.memory()); // has its own seed
      final info = await BackupService(target).restore(json);

      expect(info.accounts, 2);
      expect(info.transactions, 2);
      expect(await target.accountBalances(), sourceBalances);
      expect(
        (await target.select(target.transactions).get()).map((t) => t.note),
        containsAll(['Lunch, with "Rafi"', null]),
      );
      expect(
        await BudgetRepository(target).watchOverall().first,
        const Money.taka(20000),
      );
      expect(
        await SettingsRepository(target).get(SettingKeys.themeMode),
        'dark',
      );
      // Seeded categories were replaced, not duplicated.
      expect(
        await target.select(target.categories).get(),
        hasLength(
          await source.select(source.categories).get().then((l) => l.length),
        ),
      );
      await source.close();
      await target.close();
    },
  );

  test('invalid files are rejected and current data is untouched', () async {
    final db = await _seeded();
    final service = BackupService(db);
    final before = await db.select(db.transactions).get();

    for (final bad in [
      'not json',
      jsonEncode({'format': 'something-else'}),
      jsonEncode({
        'format': 'poyshik-backup',
        'version': 99,
        'data': <String, Object>{},
      }),
      jsonEncode({
        'format': 'poyshik-backup',
        'version': 1,
        'data': {
          'accounts': [
            {'id': 'x'}, // missing required fields
          ],
        },
      }),
      // Written by a newer database schema.
      jsonEncode({
        'format': 'poyshik-backup',
        'version': 1,
        'schemaVersion': db.schemaVersion + 1,
        'data': <String, Object>{},
      }),
      // A transaction pointing at an account that isn't in the file.
      await _withoutAccounts(db),
    ]) {
      await expectLater(
        service.restore(bad),
        throwsA(isA<BackupFormatException>()),
      );
    }
    expect(await db.select(db.transactions).get(), hasLength(before.length));
    await db.close();
  });

  test('CSV has a header, escapes fields and uses plain amounts', () async {
    final db = await _seeded();
    final csv = await BackupService(db).exportCsv();
    expect(csv.startsWith('﻿Date,Time,Type,Amount'), isTrue);
    final lines = csv.trim().split('\r\n');
    expect(lines, hasLength(3));
    expect(lines[1], '2026-11-26,18:00,transfer,200.00,Cash,bKash,,');
    expect(
      lines[2],
      '2026-11-26,13:05,expense,320.50,Cash,,Food,"Lunch, with ""Rafi"""',
    );
    await db.close();
  });

  test('csvField', () {
    expect(BackupService.csvField('plain'), 'plain');
    expect(BackupService.csvField('a,b'), '"a,b"');
    expect(BackupService.csvField('say "hi"'), '"say ""hi"""');
    expect(BackupService.csvField('two\nlines'), '"two\nlines"');
  });
}
