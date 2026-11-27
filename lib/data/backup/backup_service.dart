import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../db/app_database.dart';
import '../db/database_provider.dart';

/// Thrown when a file is not a Poyshik backup or can't be read.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message, {this.isNewer = false});
  final String message;

  /// The file was written by a newer Poyshik than this one.
  final bool isNewer;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Summary of a backup, shown before restoring.
typedef BackupInfo = ({
  DateTime createdAt,
  int accounts,
  int categories,
  int transactions,
});

/// Whole-database backup as versioned JSON, and CSV export.
///
/// JSON (not a copy of the SQLite file) keeps backups readable, independent
/// of the on-disk schema, and safe to validate before anything is replaced.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const format = 'poyshik-backup';
  static const formatVersion = 1;

  Future<String> exportJson({DateTime? now}) async {
    final data = {
      'accounts': [
        for (final r in await _db.select(_db.accounts).get()) r.toJson(),
      ],
      'categories': [
        for (final r in await _db.select(_db.categories).get()) r.toJson(),
      ],
      'transactions': [
        for (final r in await _db.select(_db.transactions).get()) r.toJson(),
      ],
      'budgets': [
        for (final r in await _db.select(_db.budgets).get()) r.toJson(),
      ],
      'settings': [
        for (final r in await _db.select(_db.appSettings).get()) r.toJson(),
      ],
      // Schema v2. Older backups simply lack these sections.
      'recurring': [
        for (final r in await _db.select(_db.recurringRules).get()) r.toJson(),
      ],
      'favourites': [
        for (final r in await _db.select(_db.quickTemplates).get()) r.toJson(),
      ],
      'bazar': [
        for (final r in await _db.select(_db.bazarItems).get()) r.toJson(),
      ],
    };
    return const JsonEncoder.withIndent(' ').convert({
      'format': format,
      'version': formatVersion,
      'schemaVersion': _db.schemaVersion,
      'createdAt': (now ?? DateTime.now()).toIso8601String(),
      'data': data,
    });
  }

  /// Parses and validates a backup without touching the database.
  ({BackupInfo info, _Parsed parsed}) inspect(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const BackupFormatException('Not a valid backup file');
    }
    if (decoded is! Map<String, Object?> || decoded['format'] != format) {
      throw const BackupFormatException('Not a Poyshik backup');
    }
    final version = decoded['version'];
    if (version is! int || version > formatVersion) {
      throw const BackupFormatException(
        'This backup is from a newer version of Poyshik',
        isNewer: true,
      );
    }
    // Rows are read with this build's table definitions, so a backup from a
    // newer database schema could carry columns this build doesn't know.
    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion != null &&
        (schemaVersion is! int || schemaVersion > _db.schemaVersion)) {
      throw const BackupFormatException(
        'This backup is from a newer version of Poyshik',
        isNewer: true,
      );
    }
    final data = decoded['data'];
    if (data is! Map<String, Object?>) {
      throw const BackupFormatException('Backup has no data');
    }

    List<T> rows<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = data[key];
      if (list == null) return const [];
      if (list is! List) throw BackupFormatException('Bad "$key" section');
      try {
        return [for (final e in list) fromJson(e as Map<String, dynamic>)];
      } on Object {
        throw BackupFormatException('Damaged "$key" section');
      }
    }

    final parsed = (
      accounts: rows('accounts', Account.fromJson),
      categories: rows('categories', Category.fromJson),
      transactions: rows('transactions', TransactionRecord.fromJson),
      budgets: rows('budgets', Budget.fromJson),
      settings: rows('settings', AppSetting.fromJson),
      recurring: rows('recurring', RecurringRule.fromJson),
      favourites: rows('favourites', QuickTemplate.fromJson),
      bazar: rows('bazar', BazarItem.fromJson),
    );
    _checkReferences(parsed);
    final createdAt =
        DateTime.tryParse('${decoded['createdAt']}') ?? DateTime(1970);
    return (
      info: (
        createdAt: createdAt,
        accounts: parsed.accounts.length,
        categories: parsed.categories.length,
        transactions: parsed.transactions.length,
      ),
      parsed: parsed,
    );
  }

  /// Every reference must point at a row in the same backup, so a damaged
  /// file is refused up front instead of failing halfway through a restore.
  static void _checkReferences(_Parsed p) {
    final accountIds = {for (final a in p.accounts) a.id};
    final categoryIds = {for (final c in p.categories) c.id};
    bool unique(Iterable<String> ids) => ids.length == ids.toSet().length;
    if (accountIds.length != p.accounts.length ||
        categoryIds.length != p.categories.length ||
        !unique(p.transactions.map((t) => t.id)) ||
        !unique(p.budgets.map((b) => b.id)) ||
        !unique(p.recurring.map((r) => r.id)) ||
        !unique(p.favourites.map((f) => f.id)) ||
        !unique(p.bazar.map((b) => b.id))) {
      throw const BackupFormatException('Duplicate rows');
    }
    final ruleIds = {for (final r in p.recurring) r.id};
    for (final r in p.recurring) {
      final ok =
          accountIds.contains(r.accountId) &&
          (r.toAccountId == null || accountIds.contains(r.toAccountId)) &&
          (r.categoryId == null || categoryIds.contains(r.categoryId));
      if (!ok) throw const BackupFormatException('Broken recurring link');
    }
    for (final f in p.favourites) {
      final ok =
          categoryIds.contains(f.categoryId) &&
          (f.accountId == null || accountIds.contains(f.accountId));
      if (!ok) throw const BackupFormatException('Broken favourite link');
    }
    for (final t in p.transactions) {
      final ok =
          accountIds.contains(t.accountId) &&
          (t.toAccountId == null || accountIds.contains(t.toAccountId)) &&
          (t.categoryId == null || categoryIds.contains(t.categoryId)) &&
          (t.recurringId == null || ruleIds.contains(t.recurringId));
      if (!ok) throw const BackupFormatException('Broken transaction link');
    }
    for (final b in p.budgets) {
      if (b.categoryId != null && !categoryIds.contains(b.categoryId)) {
        throw const BackupFormatException('Broken budget link');
      }
    }
  }

  /// Replaces ALL data with the backup, in one transaction: if anything
  /// fails, the current data is left untouched.
  Future<BackupInfo> restore(String json) async {
    final (:info, :parsed) = inspect(json);
    await _db.transaction(() async {
      // Children before parents (foreign keys).
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.recurringRules).go();
      await _db.delete(_db.quickTemplates).go();
      await _db.delete(_db.bazarItems).go();
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.appSettings).go();
      await _db.batch((b) {
        b
          ..insertAll(_db.accounts, parsed.accounts)
          ..insertAll(_db.categories, parsed.categories)
          ..insertAll(_db.recurringRules, parsed.recurring)
          ..insertAll(_db.quickTemplates, parsed.favourites)
          ..insertAll(_db.bazarItems, parsed.bazar)
          ..insertAll(_db.transactions, parsed.transactions)
          ..insertAll(_db.budgets, parsed.budgets)
          ..insertAll(_db.appSettings, parsed.settings);
      });
    });
    return info;
  }

  /// All transactions as CSV, newest first. UTF-8 with BOM so Excel shows
  /// ৳ and Bangla correctly. Amounts are plain decimals (no grouping).
  Future<String> exportCsv() async {
    final accounts = {
      for (final a in await _db.select(_db.accounts).get()) a.id: a.name,
    };
    final categories = {
      for (final c in await _db.select(_db.categories).get()) c.id: c.name,
    };
    final txs =
        await (_db.select(_db.transactions)..orderBy([
              (t) => OrderingTerm.desc(t.occurredAt),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
            .get();

    final date = DateFormat('yyyy-MM-dd');
    final time = DateFormat('HH:mm');
    final lines = <List<String>>[
      [
        'Date',
        'Time',
        'Type',
        'Amount',
        'Account',
        'To account',
        'Category',
        'Note',
      ],
      for (final t in txs)
        [
          date.format(t.occurredAt),
          time.format(t.occurredAt),
          t.type.name,
          MoneyFormat.format(
            Money(t.amount),
            withSymbol: false,
            alwaysDecimals: true,
          ).replaceAll(',', ''),
          accounts[t.accountId] ?? '',
          t.toAccountId == null ? '' : accounts[t.toAccountId] ?? '',
          t.categoryId == null ? '' : categories[t.categoryId] ?? '',
          t.note ?? '',
        ],
    ];
    return '﻿${lines.map((l) => l.map(csvField).join(',')).join('\r\n')}\r\n';
  }

  /// Quotes a CSV field when it contains a comma, quote or line break.
  static String csvField(String value) {
    if (!value.contains(RegExp('[",\r\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}

typedef _Parsed = ({
  List<Account> accounts,
  List<Category> categories,
  List<TransactionRecord> transactions,
  List<Budget> budgets,
  List<AppSetting> settings,
  List<RecurringRule> recurring,
  List<QuickTemplate> favourites,
  List<BazarItem> bazar,
});

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);
