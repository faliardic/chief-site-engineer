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
      {'version': 3, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 4, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 5, 'applied_at': '2026-07-19T08:00:00Z'},
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
        'workforce_members',
        'attendance_days',
        'attendance_entries',
        'attendance_events',
        'attendance_reminder_settings',
        'attendance_day_reminder_links',
        'concrete_pours',
        'concrete_check_items',
        'concrete_trucks',
        'concrete_sample_sets',
        'concrete_follow_up_items',
        'concrete_attachments',
        'concrete_pour_events',
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

  test(
    'schema 2 to 3 upgrade preserves agenda linked reminder and events',
    () async {
      final versionTwo = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(2).toList(),
      );
      await versionTwo.open();
      final database = versionTwo.database;
      await database.insert('projects', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Korunan proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('field_observations', {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'observed_at': '2026-07-19T07:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
        'category': 'general_note',
        'description': 'Korunan Ajanda kaydı',
      });
      await database.insert('follow_up_items', {
        'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'observation_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'title': 'Korunan hatırlatıcı',
        'item_type': 'action',
        'status': 'active',
        'next_attention_at': '2026-07-20T06:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('follow_up_events', {
        'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'follow_up_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'source_observation_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'event_type': 'created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await versionTwo.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      final reminder = (await upgraded.database.query(
        'follow_up_items',
      )).single;
      final event = (await upgraded.database.query('follow_up_events')).single;
      final binding = (await upgraded.database.query(
        'reminder_notification_bindings',
      )).single;
      final observationCount = sqflite.Sqflite.firstIntValue(
        await upgraded.database.rawQuery(
          'SELECT COUNT(*) FROM field_observations',
        ),
      );
      await upgraded.close();

      expect(observationCount, 1);
      expect(reminder['capture_text'], 'Korunan hatırlatıcı');
      expect(
        reminder['observation_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(event['sequence'], 1);
      expect(binding['scheduled_for'], '2026-07-20T06:00:00Z');
      expect(binding['sync_state'], 'unavailable');
      expect(binding['safe_error_code'], 'reconciliation_required');
    },
  );

  test('failed schema 3 upgrade rolls back intact schema 2 data', () async {
    final versionTwo = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(2).toList(),
    );
    await versionTwo.open();
    await versionTwo.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Korunan proje',
      'created_at': '2026-07-19T08:00:00Z',
      'updated_at': '2026-07-19T08:00:00Z',
    });
    await versionTwo.close();

    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(2),
        DatabaseMigration(
          version: 3,
          apply: (transaction) async {
            await transaction.execute('CREATE TABLE partial_v3 (id TEXT)');
            throw StateError('intentional v3 failure');
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
    final projectCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('SELECT COUNT(*) FROM projects'),
    );
    final partialCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery(
        "SELECT COUNT(*) FROM sqlite_master WHERE name = 'partial_v3'",
      ),
    );
    await raw.close();

    expect(version, 2);
    expect(projectCount, 1);
    expect(partialCount, 0);
  });

  test(
    'schema 3 to 4 preserves agenda reminder notification and events',
    () async {
      final versionThree = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(3).toList(),
      );
      await versionThree.open();
      final database = versionThree.database;
      await database.insert('projects', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Korunan proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('field_observations', {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'observed_at': '2026-07-19T07:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
        'category': 'general_note',
        'description': 'Korunan Ajanda kaydı',
      });
      await database.insert('follow_up_items', {
        'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'capture_text': 'Korunan reminder',
        'title': 'Korunan reminder',
        'item_type': 'action',
        'status': 'active',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'observation_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'next_attention_at': '2026-07-20T06:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('follow_up_events', {
        'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'follow_up_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'sequence': 1,
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'source_observation_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'event_type': 'created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await database.insert('reminder_notification_bindings', {
        'reminder_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'platform_notification_id': 42,
        'scheduled_for': '2026-07-20T06:00:00Z',
        'sync_state': 'scheduled',
        'last_synced_at': '2026-07-19T08:00:00Z',
      });
      await versionThree.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      final reminder = (await upgraded.database.query(
        'follow_up_items',
      )).single;
      final event = (await upgraded.database.query('follow_up_events')).single;
      final binding = (await upgraded.database.query(
        'reminder_notification_bindings',
      )).single;
      final tables = await upgraded.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
      );
      await upgraded.close();

      expect(
        reminder['observation_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(reminder['attendance_day_id'], isNull);
      expect(
        event['source_observation_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(event['source_attendance_day_id'], isNull);
      expect(binding['platform_notification_id'], 42);
      expect(
        tables.map((row) => row['name']),
        containsAll([
          'workforce_members',
          'attendance_days',
          'attendance_entries',
          'attendance_events',
          'attendance_reminder_settings',
          'attendance_day_reminder_links',
        ]),
      );
    },
  );

  test('failed schema 4 upgrade rolls back intact schema 3 data', () async {
    final versionThree = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(3).toList(),
    );
    await versionThree.open();
    await versionThree.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Korunan proje',
      'created_at': '2026-07-19T08:00:00Z',
      'updated_at': '2026-07-19T08:00:00Z',
    });
    await versionThree.close();

    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(3),
        DatabaseMigration(
          version: 4,
          apply: (transaction) async {
            await transaction.execute('CREATE TABLE partial_v4 (id TEXT)');
            throw StateError('intentional v4 failure');
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
    final projectCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('SELECT COUNT(*) FROM projects'),
    );
    final partialCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery(
        "SELECT COUNT(*) FROM sqlite_master WHERE name = 'partial_v4'",
      ),
    );
    await raw.close();

    expect(version, 3);
    expect(projectCount, 1);
    expect(partialCount, 0);
  });

  test(
    'schema 4 to 5 preserves agenda attendance reminders notifications and events',
    () async {
      final versionFour = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(4).toList(),
      );
      await versionFour.open();
      final database = versionFour.database;
      await database.insert('projects', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Korunan proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_days', {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'local_date': '2026-07-19',
        'status': 'draft',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_events', {
        'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'attendance_day_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'sequence': 1,
        'event_type': 'attendance_day.created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await database.insert('follow_up_items', {
        'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'capture_text': 'Korunan Puantaj reminder',
        'title': 'Korunan Puantaj reminder',
        'item_type': 'action',
        'status': 'active',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'attendance_day_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'next_attention_at': '2026-07-19T14:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('follow_up_events', {
        'id': 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        'follow_up_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'sequence': 1,
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'source_attendance_day_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'event_type': 'created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await database.insert('reminder_notification_bindings', {
        'reminder_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'platform_notification_id': 187,
        'scheduled_for': '2026-07-19T14:00:00Z',
        'sync_state': 'scheduled',
        'last_synced_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_day_reminder_links', {
        'attendance_day_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'reminder_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'due_at': '2026-07-19T14:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
      });
      await versionFour.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      final reminder = (await upgraded.database.query(
        'follow_up_items',
      )).single;
      final event = (await upgraded.database.query('follow_up_events')).single;
      final binding = (await upgraded.database.query(
        'reminder_notification_bindings',
      )).single;
      final link = (await upgraded.database.query(
        'attendance_day_reminder_links',
      )).single;
      final foreignKeys = await upgraded.database.rawQuery(
        "PRAGMA foreign_key_list('concrete_follow_up_items')",
      );
      await upgraded.close();

      expect(
        reminder['attendance_day_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(reminder['concrete_pour_id'], isNull);
      expect(
        event['source_attendance_day_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(event['source_concrete_pour_id'], isNull);
      expect(binding['platform_notification_id'], 187);
      expect(link['reminder_id'], 'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
      expect(
        foreignKeys.map((row) => row['table']),
        contains('follow_up_items'),
      );
    },
  );

  test('failed schema 5 upgrade rolls back intact schema 4 data', () async {
    final versionFour = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(4).toList(),
    );
    await versionFour.open();
    await versionFour.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Korunan proje',
      'created_at': '2026-07-19T08:00:00Z',
      'updated_at': '2026-07-19T08:00:00Z',
    });
    await versionFour.close();

    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(4),
        DatabaseMigration(
          version: 5,
          apply: (transaction) async {
            await transaction.execute('CREATE TABLE partial_v5 (id TEXT)');
            throw StateError('intentional v5 failure');
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
    final projectCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('SELECT count(*) FROM projects'),
    );
    final partialCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery(
        "SELECT count(*) FROM sqlite_master WHERE name = 'partial_v5'",
      ),
    );
    await raw.close();
    expect(version, 4);
    expect(projectCount, 1);
    expect(partialCount, 0);
  });
}
