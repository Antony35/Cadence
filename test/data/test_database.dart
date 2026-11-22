import 'package:cadence/data/drift/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A real SQLite database, in memory: created empty for each test, with the
/// same tables, constraints and catalog as on the phone.
AppDatabase openTestDatabase() {
  // Each test opens its own database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// The database itself said no (a constraint), not the Dart code.
final Matcher throwsSqliteError = throwsA(isA<SqliteException>());
