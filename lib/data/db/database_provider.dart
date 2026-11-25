import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The single app database. Tests override this with an in-memory database:
/// `appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory()))`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => unawaited(db.close()));
  return db;
});
