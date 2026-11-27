import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/app/app_info.dart';

void main() {
  test('kAppVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([^\s+]+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml has no version line');
    expect(kAppVersion, match![1]);
  });
}
