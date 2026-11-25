import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Now", injectable so tests can freeze time. Read it instead of calling
/// `DateTime.now()` in logic that depends on the current date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
