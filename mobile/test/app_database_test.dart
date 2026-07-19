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
      {'version': 2, 'applied_at': '2026-07-19T08:00:00Z'},
    ]);
  });

  test('schema 1 upgrades atomically and preserves its smoke record', () async {
    final versionOne = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: [AppDatabase.foundationMigrations.first],
    );
    await versionOne.open();
    final original = await SmokeRecordRepository(
      database: versionOne,
      clock: () => firstClock,
    ).ensureFoundationRecord();
    await versionOne.close();

    final upgraded = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
    );
    await upgraded.open();
    final persisted = await SmokeRecordRepository(
      database: upgraded,
      clock: () => DateTime.utc(2026, 7, 19, 9),
    ).ensureFoundationRecord();
    final version = sqflite.Sqflite.firstIntValue(
      await upgraded.database.rawQuery('PRAGMA user_version'),
    );
    final tables = await upgraded.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    await upgraded.close();

    expect(version, AppDatabase.schemaVersion);
    expect(persisted.createdAt, original.createdAt);
    expect(
      tables.map((row) => row['name']),
      containsAll([
        'projects',
        'field_observations',
        'observation_events',
        'follow_up_items',
        'follow_up_events',
      ]),
    );
  });

  test(
    'failed schema 2 upgrade rolls back and preserves schema 1 data',
    () async {
      final versionOne = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: [AppDatabase.foundationMigrations.first],
      );
      await versionOne.open();
      await SmokeRecordRepository(
        database: versionOne,
        clock: () => firstClock,
      ).ensureFoundationRecord();
      await versionOne.close();

      final failing = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
        migrations: [
          AppDatabase.foundationMigrations.first,
          DatabaseMigration(
            version: 2,
            apply: (transaction) async {
              await transaction.execute('CREATE TABLE partial_v2 (id TEXT)');
              throw StateError('intentional v2 failure');
            },
          ),
        ],
      );
      await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final version = sqflite.Sqflite.firstIntValue(
        await raw.rawQuery('PRAGMA user_version'),
      );
      final smokeCount = sqflite.Sqflite.firstIntValue(
        await raw.rawQuery('SELECT COUNT(*) FROM smoke_records'),
      );
      final partialCount = sqflite.Sqflite.firstIntValue(
        await raw.rawQuery(
          "SELECT COUNT(*) FROM sqlite_master WHERE name = 'partial_v2'",
        ),
      );
      await raw.close();

      expect(version, 1);
      expect(smokeCount, 1);
      expect(partialCount, 0);
    },
  );

  test('a failed migration rolls back every partial schema write', () async {
    final database = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: [
        AppDatabase.foundationMigrations.first,
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
