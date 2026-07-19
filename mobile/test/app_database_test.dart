import 'dart:io';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:chief_site_engineer/storage/smoke_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;
  final firstClock = DateTime.utc(2026, 7, 19, 8);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_mobile_db_');
    directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    await directories.ensureCreated();
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('migration history and smoke record survive database restart', () async {
    final first = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
    );
    await first.open();
    final firstRecord = await SmokeRecordRepository(
      database: first,
      clock: () => firstClock,
    ).ensureFoundationRecord();
    await first.close();

    final restarted = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
    );
    await restarted.open();
    final restartedRecord = await SmokeRecordRepository(
      database: restarted,
      clock: () => DateTime.utc(2026, 7, 19, 9),
    ).ensureFoundationRecord();
    final history = await restarted.database.query('schema_versions');
    await restarted.close();

    expect(firstRecord.id, SmokeRecordRepository.foundationRecordId);
    expect(restartedRecord.createdAt, firstRecord.createdAt);
    expect(history, [
      {'version': 1, 'applied_at': '2026-07-19T08:00:00Z'},
    ]);
  });

  test('a failed migration rolls back every partial schema write', () async {
    final database = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: [
        AppDatabase.foundationMigrations.single,
        DatabaseMigration(
          version: 2,
          apply: (transaction) async {
            await transaction.execute(
              'CREATE TABLE partial_write (id INTEGER)',
            );
            throw StateError('intentional migration failure');
          },
        ),
      ],
    );

    await expectLater(database.open(), throwsA(isA<DatabaseOpenFailure>()));

    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    final tables = await raw.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    final version = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('PRAGMA user_version'),
    );
    await raw.close();

    expect(version, 0);
    expect(tables, isEmpty);
  });
}
