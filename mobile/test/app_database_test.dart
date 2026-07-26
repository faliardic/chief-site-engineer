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
      {'version': 6, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 7, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 8, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 9, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 10, 'applied_at': '2026-07-19T08:00:00Z'},
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
        'project_concrete_classes',
        'project_concrete_class_events',
        'concrete_pour_context_links',
        'concrete_check_items',
        'concrete_trucks',
        'concrete_sample_sets',
        'concrete_follow_up_items',
        'concrete_attachments',
        'agenda_log_attachments',
        'concrete_pour_events',
        'subcontractors',
        'workforce_teams',
        'workforce_events',
        'workforce_compliance_records',
        'workforce_ppe_assignments',
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

  test(
    'schema 5 to 6 maps legacy teams atomically and preserves exact history',
    () async {
      final versionFive = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(5).toList(),
      );
      await versionFive.open();
      final database = versionFive.database;
      await database.insert('projects', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Korunan proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      for (final value in const [
        ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1', ' Kalıp '),
        ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 'kalıp'),
        ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3', ''),
      ]) {
        await database.insert('workforce_members', {
          'id': value.$1,
          'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'full_name': 'Korunan ${value.$1.substring(value.$1.length - 1)}',
          'team_name': value.$2,
          'role_name': 'Usta',
          'is_active': 1,
          'revision': 1,
          'created_at': '2026-07-19T08:00:00Z',
          'updated_at': '2026-07-19T08:00:00Z',
        });
      }
      await database.insert('attendance_days', {
        'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'local_date': '2026-07-18',
        'status': 'draft',
        'revision': 1,
        'created_at': '2026-07-18T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_entries', {
        'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'attendance_day_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'workforce_member_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
        'result': 'full_day',
        'overtime_minutes': 60,
        'created_at': '2026-07-18T08:00:00Z',
        'updated_at': '2026-07-18T08:00:00Z',
      });
      await database.update(
        'attendance_days',
        {
          'status': 'completed',
          'revision': 2,
          'updated_at': '2026-07-19T08:00:00Z',
          'completed_at': '2026-07-19T08:00:00Z',
        },
        where: 'id = ?',
        whereArgs: ['cccccccc-cccc-4ccc-8ccc-cccccccccccc'],
      );
      await database.insert('attendance_events', {
        'id': 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        'attendance_day_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'sequence': 1,
        'event_type': 'attendance_day.created',
        'occurred_at': '2026-07-18T08:00:00Z',
        'payload_json': '{}',
      });
      await versionFive.close();

      final failing = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
        migrations: [
          ...AppDatabase.foundationMigrations.take(5),
          DatabaseMigration(
            version: 6,
            apply: (transaction) async {
              await AppDatabase.foundationMigrations[5].apply(transaction);
              throw StateError('intentional schema 6 failure');
            },
          ),
        ],
      );
      await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
      final afterFailure = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await afterFailure.rawQuery('PRAGMA user_version'),
        ),
        5,
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await afterFailure.rawQuery(
            "SELECT count(*) FROM sqlite_master WHERE name = 'subcontractors'",
          ),
        ),
        0,
      );
      expect(await afterFailure.query('workforce_members'), hasLength(3));
      await afterFailure.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      final subcontractors = await upgraded.database.query(
        'subcontractors',
        orderBy: 'name_normalized ASC',
      );
      final teams = await upgraded.database.query(
        'workforce_teams',
        orderBy: 'name_normalized ASC',
      );
      final members = await upgraded.database.query(
        'workforce_members',
        orderBy: 'id ASC',
      );
      final entry = (await upgraded.database.query(
        'attendance_entries',
      )).single;
      final attendanceEvent = (await upgraded.database.query(
        'attendance_events',
      )).single;
      final workforceEvents = await upgraded.database.query('workforce_events');

      expect(subcontractors, hasLength(2));
      expect(teams, hasLength(2));
      expect(
        subcontractors.map((row) => row['name']),
        containsAll(['Kalıp', 'Tanımsız ekip']),
      );
      expect(members.map((row) => row['id']), [
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3',
      ]);
      expect(members.every((row) => row['team_id'] != null), isTrue);
      expect(members[0]['team_id'], members[1]['team_id']);
      expect(entry['workforce_member_id'], members.first['id']);
      expect(entry['overtime_minutes'], 60);
      expect(attendanceEvent['id'], 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee');
      expect(workforceEvents, hasLength(7));

      await expectLater(
        upgraded.database.update(
          'workforce_events',
          {'payload_json': '{"changed":true}'},
          where: 'id = ?',
          whereArgs: [workforceEvents.first['id']],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        upgraded.database.delete(
          'subcontractors',
          where: 'id = ?',
          whereArgs: [subcontractors.first['id']],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        upgraded.database.insert('subcontractors', {
          'id': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
          'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'name': 'KALIP',
          'name_normalized': 'kalıp',
          'status': 'active',
          'revision': 1,
          'created_at': '2026-07-19T09:00:00Z',
          'updated_at': '2026-07-19T09:00:00Z',
        }),
        throwsA(isA<DatabaseException>()),
      );
      await upgraded.close();
    },
  );

  test(
    'schema 6 to 7 preserves agenda concrete truck child graph and nullable notes',
    () async {
      final versionSix = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(6).toList(),
      );
      await versionSix.open();
      final db = versionSix.database;
      const project = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      const observation = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
      const pour = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
      const truck = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
      const sample = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
      const attachment = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
      const timestamp = '2026-07-19T08:00:00Z';
      await db.insert('projects', {
        'id': project,
        'name': 'Schema 6 Projesi',
        'created_at': timestamp,
        'updated_at': timestamp,
        'revision': 1,
      });
      await db.insert('field_observations', {
        'id': observation,
        'project_id': project,
        'observed_at': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
        'category': 'concrete',
        'description': 'Korunacak log',
        'revision': 1,
      });
      await db.insert('concrete_pours', {
        'id': pour,
        'project_id': project,
        'pour_code': 'BT-V6',
        'element_location': 'A Blok',
        'planned_at': timestamp,
        'concrete_class': 'C30/37',
        'planned_volume_m3': 12.5,
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_trucks', {
        'id': truck,
        'concrete_pour_id': pour,
        'sequence_no': 1,
        'vehicle_plate': '34 TEST 1',
        'delivery_note_number': 'IRS-V6',
        'volume_m3': 7.5,
        'result': 'received',
        'revision': 2,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_sample_sets', {
        'id': sample,
        'concrete_pour_id': pour,
        'source_truck_id': truck,
        'sample_code': 'N-V6',
        'sample_count': 0,
        'sample_labels_json': '[]',
        'expected_result_dates_json': '[]',
        'status': 'planned',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_attachments', {
        'id': attachment,
        'concrete_pour_id': pour,
        'truck_id': truck,
        'evidence_type': 'delivery_receipt_scan',
        'original_file_name': 'irsaliye.jpg',
        'mime_type': 'image/jpeg',
        'byte_size': 4,
        'sha256': 'a'.padLeft(64, 'a'),
        'relative_path': 'concrete/$pour/$attachment.jpg',
        'captured_at': timestamp,
        'created_at': timestamp,
      });
      await versionSix.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      expect(
        sqflite.Sqflite.firstIntValue(
          await upgraded.database.rawQuery('PRAGMA user_version'),
        ),
        AppDatabase.schemaVersion,
      );
      expect(
        (await upgraded.database.query(
          'field_observations',
        )).single['description'],
        'Korunacak log',
      );
      final preservedTruck = (await upgraded.database.query(
        'concrete_trucks',
        where: 'id = ?',
        whereArgs: [truck],
      )).single;
      expect(preservedTruck['delivery_note_number'], 'IRS-V6');
      expect(preservedTruck['revision'], 2);
      expect(preservedTruck['note'], isNull);
      expect(
        (await upgraded.database.query(
          'concrete_sample_sets',
        )).single['source_truck_id'],
        truck,
      );
      expect(
        (await upgraded.database.query(
          'concrete_attachments',
        )).single['truck_id'],
        truck,
      );
      final truckColumns = await upgraded.database.rawQuery(
        'PRAGMA table_info(concrete_trucks)',
      );
      expect(
        truckColumns.singleWhere(
          (row) => row['name'] == 'delivery_note_number',
        )['notnull'],
        0,
      );
      for (final (id, sequence) in [
        ('11111111-1111-4111-8111-111111111111', 2),
        ('22222222-2222-4222-8222-222222222222', 3),
      ]) {
        await upgraded.database.insert('concrete_trucks', {
          'id': id,
          'concrete_pour_id': pour,
          'sequence_no': sequence,
          'vehicle_plate': '34 NULL $sequence',
          'delivery_note_number': null,
          'volume_m3': 1.0,
          'result': 'received',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
      }
      await expectLater(
        upgraded.database.insert('concrete_trucks', {
          'id': '33333333-3333-4333-8333-333333333333',
          'concrete_pour_id': pour,
          'sequence_no': 4,
          'vehicle_plate': '34 DUP',
          'delivery_note_number': 'IRS-V6',
          'volume_m3': 1.0,
          'result': 'received',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        upgraded.database.delete(
          'concrete_trucks',
          where: 'id = ?',
          whereArgs: ['11111111-1111-4111-8111-111111111111'],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        upgraded.database.rawInsert(
          '''
          INSERT INTO agenda_log_attachments (
            id, observation_id, project_id, attachment_type,
            original_file_name, mime_type, byte_size, sha256, relative_path,
            revision, created_at, updated_at
          ) VALUES (?, ?, ?, 'site_photo', 'saha.jpg', 'image/jpeg', 4, ?, ?,
            1, ?, ?)
        ''',
          [
            '44444444-4444-4444-8444-444444444444',
            observation,
            project,
            'b'.padLeft(64, 'b'),
            'agenda/$observation/photo.jpg',
            timestamp,
            timestamp,
          ],
        ),
        completes,
      );
      await expectLater(
        upgraded.database.delete('agenda_log_attachments'),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      await upgraded.close();
    },
  );

  test(
    'schema 7 to 8 normalizes waiting and preserves schedules sources and audit',
    () async {
      final versionSeven = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(7).toList(),
      );
      await versionSeven.open();
      final db = versionSeven.database;
      const project = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      const observation = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
      const attendance = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
      const pour = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
      const timestamp = '2026-07-19T08:00:00Z';
      const due = '2026-07-20T06:00:00Z';
      await db.insert('projects', {
        'id': project,
        'name': 'Schema 8 Projesi',
        'created_at': timestamp,
        'updated_at': timestamp,
        'revision': 1,
      });
      await db.insert('field_observations', {
        'id': observation,
        'project_id': project,
        'observed_at': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
        'category': 'inspection',
        'description': 'Korunan Ajanda kaynağı',
        'revision': 1,
      });
      await db.insert('attendance_days', {
        'id': attendance,
        'project_id': project,
        'local_date': '2026-07-19',
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_pours', {
        'id': pour,
        'project_id': project,
        'pour_code': 'BT-V8',
        'element_location': 'A Blok',
        'planned_at': due,
        'concrete_class': 'C30/37',
        'planned_volume_m3': 8.0,
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      Future<void> insertReminder({
        required String id,
        required int platformId,
        required String itemType,
        required String status,
        String? sourceObservation,
        String? sourceAttendance,
        String? sourceConcrete,
        int revision = 1,
      }) async {
        await db.insert('follow_up_items', {
          'id': id,
          'capture_text': 'Legacy $id',
          'title': 'Legacy $id',
          'item_type': itemType,
          'status': status,
          'project_id':
              sourceObservation != null ||
                  sourceAttendance != null ||
                  sourceConcrete != null
              ? project
              : null,
          'observation_id': sourceObservation,
          'attendance_day_id': sourceAttendance,
          'concrete_pour_id': sourceConcrete,
          'is_important': 1,
          'next_attention_at': status == 'inbox' ? null : due,
          'outcome_type': status == 'completed'
              ? 'completed'
              : status == 'cancelled'
              ? 'no_longer_needed'
              : null,
          'revision': revision,
          'created_at': timestamp,
          'updated_at': timestamp,
          'completed_at': status == 'completed' ? timestamp : null,
          'cancelled_at': status == 'cancelled' ? timestamp : null,
        });
        await db.insert('follow_up_events', {
          'id':
              'eeeeeeee-eeee-4eee-8eee-'
              '${platformId.toString().padLeft(12, '0')}',
          'follow_up_id': id,
          'sequence': 1,
          'project_id':
              sourceObservation != null ||
                  sourceAttendance != null ||
                  sourceConcrete != null
              ? project
              : null,
          'source_observation_id': sourceObservation,
          'source_attendance_day_id': sourceAttendance,
          'source_concrete_pour_id': sourceConcrete,
          'event_type': 'created',
          'occurred_at': timestamp,
          'payload_json': '{}',
        });
        await db.insert('reminder_notification_bindings', {
          'reminder_id': id,
          'platform_notification_id': platformId,
          'scheduled_for': status == 'inbox' ? null : due,
          'sync_state': status == 'inbox' ? 'cancelled' : 'scheduled',
          'last_synced_at': timestamp,
          'repeat_interval_minutes': platformId == 101 ? 60 : null,
        });
      }

      const bothWaiting = '11111111-1111-4111-8111-111111111111';
      const kindWaiting = '22222222-2222-4222-8222-222222222222';
      const statusWaiting = '33333333-3333-4333-8333-333333333333';
      await insertReminder(
        id: bothWaiting,
        platformId: 101,
        itemType: 'waiting',
        status: 'waiting',
        sourceObservation: observation,
        revision: 7,
      );
      await db.insert('follow_up_events', {
        'id': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        'follow_up_id': bothWaiting,
        'sequence': 2,
        'project_id': project,
        'source_observation_id': observation,
        'event_type': 'waiting_started',
        'occurred_at': timestamp,
        'payload_json': '{"legacy":true}',
      });
      await insertReminder(
        id: kindWaiting,
        platformId: 102,
        itemType: 'waiting',
        status: 'active',
        sourceAttendance: attendance,
        revision: 5,
      );
      await insertReminder(
        id: statusWaiting,
        platformId: 103,
        itemType: 'action',
        status: 'waiting',
        sourceConcrete: pour,
        revision: 4,
      );
      await insertReminder(
        id: '44444444-4444-4444-8444-444444444444',
        platformId: 104,
        itemType: 'action',
        status: 'active',
      );
      await insertReminder(
        id: '55555555-5555-4555-8555-555555555555',
        platformId: 105,
        itemType: 'action',
        status: 'inbox',
      );
      await insertReminder(
        id: '66666666-6666-4666-8666-666666666666',
        platformId: 106,
        itemType: 'recheck',
        status: 'completed',
      );
      await insertReminder(
        id: '77777777-7777-4777-8777-777777777777',
        platformId: 107,
        itemType: 'action',
        status: 'cancelled',
      );
      await versionSeven.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      expect(
        sqflite.Sqflite.firstIntValue(
          await upgraded.database.rawQuery('PRAGMA user_version'),
        ),
        AppDatabase.schemaVersion,
      );
      final rows = await upgraded.database.query(
        'follow_up_items',
        orderBy: 'id ASC',
      );
      expect(rows, hasLength(7));
      final normalizedBoth = rows.singleWhere(
        (row) => row['id'] == bothWaiting,
      );
      expect(normalizedBoth['item_type'], 'action');
      expect(normalizedBoth['status'], 'active');
      expect(normalizedBoth['next_attention_at'], due);
      expect(normalizedBoth['revision'], 7);
      expect(normalizedBoth['observation_id'], observation);
      expect(normalizedBoth['all_day_local_date'], isNull);
      expect(
        rows.singleWhere((row) => row['id'] == kindWaiting)['item_type'],
        'action',
      );
      expect(
        rows.singleWhere(
          (row) => row['id'] == kindWaiting,
        )['attendance_day_id'],
        attendance,
      );
      expect(
        rows.singleWhere((row) => row['id'] == statusWaiting)['status'],
        'active',
      );
      expect(
        rows.singleWhere(
          (row) => row['id'] == statusWaiting,
        )['concrete_pour_id'],
        pour,
      );
      final binding = (await upgraded.database.query(
        'reminder_notification_bindings',
        where: 'reminder_id = ?',
        whereArgs: [bothWaiting],
      )).single;
      expect(binding['platform_notification_id'], 101);
      expect(binding['scheduled_for'], due);
      expect(binding['sync_state'], 'scheduled');
      expect(binding['repeat_interval_minutes'], 60);
      final normalizationEvents = await upgraded.database.query(
        'follow_up_events',
        where: "event_type = 'legacy_waiting_normalized'",
        orderBy: 'follow_up_id ASC',
      );
      expect(normalizationEvents, hasLength(3));
      expect(
        (await upgraded.database.query(
          'follow_up_events',
          where: 'follow_up_id = ?',
          whereArgs: [bothWaiting],
          orderBy: 'sequence ASC',
        )).map((row) => row['sequence']),
        [1, 2, 3],
      );
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      await expectLater(
        upgraded.database.insert('follow_up_items', {
          'id': '88888888-8888-4888-8888-888888888888',
          'capture_text': 'Yasak waiting',
          'title': 'Yasak waiting',
          'item_type': 'waiting',
          'status': 'active',
          'next_attention_at': due,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        upgraded.database.insert('follow_up_items', {
          'id': '99999999-9999-4999-8999-999999999999',
          'capture_text': 'Çift schedule',
          'title': 'Çift schedule',
          'item_type': 'action',
          'status': 'active',
          'next_attention_at': due,
          'all_day_local_date': '2026-07-20',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await upgraded.close();

      final restarted = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 10),
      );
      await restarted.open();
      expect(
        await restarted.database.query(
          'follow_up_events',
          where: "event_type = 'legacy_waiting_normalized'",
        ),
        hasLength(3),
      );
      await restarted.close();
    },
  );

  test('empty schema 8 migrates atomically through schema 10', () async {
    final versionEight = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(8).toList(),
    );
    await versionEight.open();
    await versionEight.close();

    final upgraded = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 20, 9),
    );
    await upgraded.open();
    expect(
      sqflite.Sqflite.firstIntValue(
        await upgraded.database.rawQuery('PRAGMA user_version'),
      ),
      AppDatabase.schemaVersion,
    );
    expect(
      (await upgraded.database.rawQuery(
        'PRAGMA table_info(follow_up_items)',
      )).map((row) => row['name']),
      contains('trashed_at'),
    );
    expect(
      await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
      isEmpty,
    );
    expect(
      await upgraded.database.query('project_concrete_classes'),
      isEmpty,
    );
    await upgraded.close();
  });

  test(
    'schema 8 to 9 preserves reminder variants sources bindings and history',
    () async {
      final versionEight = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(8).toList(),
      );
      await versionEight.open();
      final db = versionEight.database;
      const project = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      const observation = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
      const attendance = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
      const pour = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
      const timestamp = '2026-07-20T08:00:00Z';
      const due = '2026-07-21T06:00:00Z';
      await db.insert('projects', {
        'id': project,
        'name': 'Schema 9 Projesi',
        'created_at': timestamp,
        'updated_at': timestamp,
        'revision': 1,
      });
      await db.insert('field_observations', {
        'id': observation,
        'project_id': project,
        'observed_at': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
        'category': 'inspection',
        'description': 'Korunan Ajanda kaynağı',
        'revision': 1,
      });
      await db.insert('attendance_days', {
        'id': attendance,
        'project_id': project,
        'local_date': '2026-07-20',
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_pours', {
        'id': pour,
        'project_id': project,
        'pour_code': 'BT-V9',
        'element_location': 'A Blok',
        'planned_at': due,
        'concrete_class': 'C30/37',
        'planned_volume_m3': 8.0,
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      Future<void> insertReminder({
        required String id,
        required int platformId,
        required String status,
        String? nextAttentionAt,
        String? allDayLocalDate,
        String? sourceObservation,
        String? sourceAttendance,
        String? sourceConcrete,
      }) async {
        final terminal = status == 'completed' || status == 'cancelled';
        await db.insert('follow_up_items', {
          'id': id,
          'capture_text': 'Schema 9 $id',
          'title': 'Schema 9 $id',
          'item_type': 'action',
          'status': status,
          'project_id':
              sourceObservation != null ||
                  sourceAttendance != null ||
                  sourceConcrete != null
              ? project
              : null,
          'observation_id': sourceObservation,
          'attendance_day_id': sourceAttendance,
          'concrete_pour_id': sourceConcrete,
          'is_important': 0,
          'next_attention_at': nextAttentionAt,
          'all_day_local_date': allDayLocalDate,
          'outcome_type': status == 'completed'
              ? 'completed'
              : status == 'cancelled'
              ? 'no_longer_needed'
              : null,
          'revision': 3,
          'created_at': timestamp,
          'updated_at': timestamp,
          'completed_at': status == 'completed' ? timestamp : null,
          'cancelled_at': status == 'cancelled' ? timestamp : null,
        });
        await db.insert('follow_up_events', {
          'id':
              'eeeeeeee-eeee-4eee-8eee-'
              '${platformId.toString().padLeft(12, '0')}',
          'follow_up_id': id,
          'sequence': 1,
          'project_id':
              sourceObservation != null ||
                  sourceAttendance != null ||
                  sourceConcrete != null
              ? project
              : null,
          'source_observation_id': sourceObservation,
          'source_attendance_day_id': sourceAttendance,
          'source_concrete_pour_id': sourceConcrete,
          'event_type': 'created',
          'occurred_at': timestamp,
          'payload_json': '{}',
        });
        await db.insert('reminder_notification_bindings', {
          'reminder_id': id,
          'platform_notification_id': platformId,
          'scheduled_for': terminal ? null : nextAttentionAt,
          'sync_state': nextAttentionAt == null || terminal
              ? 'cancelled'
              : 'scheduled',
          'last_synced_at': timestamp,
        });
      }

      await insertReminder(
        id: '11111111-1111-4111-8111-111111111111',
        platformId: 201,
        status: 'active',
        nextAttentionAt: due,
        sourceObservation: observation,
      );
      await insertReminder(
        id: '22222222-2222-4222-8222-222222222222',
        platformId: 202,
        status: 'active',
        allDayLocalDate: '2026-07-21',
        sourceAttendance: attendance,
      );
      await insertReminder(
        id: '33333333-3333-4333-8333-333333333333',
        platformId: 203,
        status: 'inbox',
        sourceConcrete: pour,
      );
      await insertReminder(
        id: '44444444-4444-4444-8444-444444444444',
        platformId: 204,
        status: 'completed',
      );
      await insertReminder(
        id: '55555555-5555-4555-8555-555555555555',
        platformId: 205,
        status: 'cancelled',
      );
      await versionEight.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 20, 9),
      );
      await upgraded.open();
      final rows = await upgraded.database.query(
        'follow_up_items',
        orderBy: 'id ASC',
      );
      expect(rows, hasLength(5));
      expect(rows.every((row) => row['trashed_at'] == null), isTrue);
      expect(rows.map((row) => row['status']), [
        'active',
        'active',
        'inbox',
        'completed',
        'cancelled',
      ]);
      expect(rows[0]['observation_id'], observation);
      expect(rows[1]['attendance_day_id'], attendance);
      expect(rows[2]['concrete_pour_id'], pour);
      expect(
        (await upgraded.database.query(
          'reminder_notification_bindings',
          orderBy: 'platform_notification_id ASC',
        )).map((row) => row['platform_notification_id']),
        [201, 202, 203, 204, 205],
      );
      expect(await upgraded.database.query('follow_up_events'), hasLength(5));
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      await upgraded.database.update(
        'follow_up_items',
        {'trashed_at': '2026-07-20T09:00:00Z'},
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
      await expectLater(
        upgraded.database.update(
          'follow_up_items',
          {'trashed_at': '2026-07-20 09:00:00'},
          where: 'id = ?',
          whereArgs: [rows[1]['id']],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await upgraded.database.insert('follow_up_events', {
        'id': 'ffffffff-ffff-4fff-8fff-fffffffffff1',
        'follow_up_id': rows.first['id'],
        'sequence': 2,
        'project_id': project,
        'source_observation_id': observation,
        'event_type': 'trashed',
        'occurred_at': '2026-07-20T09:00:00Z',
        'payload_json': '{}',
      });
      await upgraded.database.insert('follow_up_events', {
        'id': 'ffffffff-ffff-4fff-8fff-fffffffffff2',
        'follow_up_id': rows.first['id'],
        'sequence': 3,
        'project_id': project,
        'source_observation_id': observation,
        'event_type': 'restored_from_trash',
        'occurred_at': '2026-07-20T09:01:00Z',
        'payload_json': '{}',
      });
      await expectLater(
        upgraded.database.delete(
          'follow_up_items',
          where: 'id = ?',
          whereArgs: [rows.first['id']],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await upgraded.close();
    },
  );

  test(
    'schema 9 to 10 seeds project concrete classes and links legacy snapshots',
    () async {
      final versionNine = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(9).toList(),
      );
      await versionNine.open();
      final db = versionNine.database;
      const projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
      const projectB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
      const pourA1 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
      const pourA2 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
      const pourB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3';
      const timestamp = '2026-07-20T08:00:00Z';
      for (final value in const [(projectA, 'Proje A'), (projectB, 'Proje B')]) {
        await db.insert('projects', {
          'id': value.$1,
          'name': value.$2,
          'created_at': timestamp,
          'updated_at': timestamp,
          'revision': 1,
        });
      }
      for (final value in const [
        (pourA1, projectA, 'BT-A1', ' C30/37 ', null, null),
        (
          pourA2,
          projectA,
          'BT-A2',
          'c30/37',
          '2026-07-20T08:10:00Z',
          '2026-07-20T08:40:00Z',
        ),
        (pourB, projectB, 'BT-B1', 'C30/37', null, null),
      ]) {
        await db.insert('concrete_pours', {
          'id': value.$1,
          'project_id': value.$2,
          'pour_code': value.$3,
          'element_location': 'Temel',
          'planned_at': '2026-07-20T09:00:00Z',
          'actual_started_at': value.$5,
          'actual_ended_at': value.$6,
          'concrete_class': value.$4,
          'target_slump': value.$1 == pourA1 ? 'S3' : null,
          'planned_volume_m3': 20.0,
          'status': value.$6 != null
              ? 'poured'
              : value.$5 != null
              ? 'pouring'
              : 'draft',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
      }
      await db.insert('concrete_trucks', {
        'id': 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
        'concrete_pour_id': pourA2,
        'sequence_no': 1,
        'vehicle_plate': '34 CSE 234',
        'volume_m3': 8.0,
        'result': 'received',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_pour_events', {
        'id': 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1',
        'concrete_pour_id': pourA2,
        'sequence': 1,
        'event_type': 'pour.started',
        'occurred_at': '2026-07-20T08:10:00Z',
        'payload_json': '{}',
      });
      await versionNine.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 20, 10),
      );
      await upgraded.open();
      final classes = await upgraded.database.query(
        'project_concrete_classes',
        orderBy: 'project_id ASC',
      );
      final links = await upgraded.database.query(
        'concrete_pour_context_links',
        orderBy: 'concrete_pour_id ASC',
      );
      final pours = await upgraded.database.query(
        'concrete_pours',
        orderBy: 'id ASC',
      );
      expect(classes, hasLength(2));
      expect(classes.map((row) => row['normalized_name']), [
        'c30/37',
        'c30/37',
      ]);
      expect(classes.first['default_target_slump'], 'S3');
      expect(links, hasLength(3));
      expect(links[0]['concrete_class_id'], links[1]['concrete_class_id']);
      expect(links[2]['concrete_class_id'], isNot(links[0]['concrete_class_id']));
      expect(pours.map((row) => row['concrete_class']), [
        ' C30/37 ',
        'c30/37',
        'C30/37',
      ]);
      expect(pours[1]['actual_started_at'], '2026-07-20T08:10:00Z');
      expect(pours[1]['actual_ended_at'], '2026-07-20T08:40:00Z');
      expect(await upgraded.database.query('concrete_trucks'), hasLength(1));
      expect(
        (await upgraded.database.query('concrete_pour_events')).single['id'],
        'dddddddd-dddd-4ddd-8ddd-ddddddddddd1',
      );
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      const managedAgendaId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1';
      await upgraded.database.insert('field_observations', {
        'id': managedAgendaId,
        'project_id': projectA,
        'observed_at': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
        'category': 'concrete',
        'description': 'Managed legacy concrete projection',
        'revision': 1,
      });
      await upgraded.database.update(
        'concrete_pour_context_links',
        {'agenda_log_id': managedAgendaId},
        where: 'concrete_pour_id = ?',
        whereArgs: [pourA1],
      );
      await expectLater(
        upgraded.database.update(
          'concrete_pour_context_links',
          {'agenda_log_id': managedAgendaId},
          where: 'concrete_pour_id = ?',
          whereArgs: [pourA2],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        upgraded.database.update(
          'concrete_pour_context_links',
          {'concrete_class_id': classes.last['id']},
          where: 'concrete_pour_id = ?',
          whereArgs: [pourA1],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        upgraded.database.delete(
          'project_concrete_classes',
          where: 'id = ?',
          whereArgs: [classes.first['id']],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        upgraded.database.update(
          'project_concrete_class_events',
          {'payload_json': '{"changed":true}'},
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await upgraded.close();
    },
  );

  test('schema 10 migration rolls back on an invalid legacy class', () async {
    final versionNine = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(9).toList(),
    );
    await versionNine.open();
    await versionNine.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Rollback V10',
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T08:00:00Z',
      'revision': 1,
    });
    await versionNine.database.insert('concrete_pours', {
      'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'pour_code': 'BT-BAD',
      'element_location': 'Temel',
      'planned_at': '2026-07-20T09:00:00Z',
      'concrete_class': '   ',
      'planned_volume_m3': 5.0,
      'status': 'draft',
      'revision': 1,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T08:00:00Z',
    });
    await versionNine.close();

    final upgraded = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 20, 10),
    );
    await expectLater(upgraded.open(), throwsA(isA<DatabaseOpenFailure>()));
    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: sqflite.OpenDatabaseOptions(singleInstance: false),
    );
    expect(
      sqflite.Sqflite.firstIntValue(await raw.rawQuery('PRAGMA user_version')),
      9,
    );
    expect(
      await raw.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE name = 'project_concrete_classes'",
      ),
      isEmpty,
    );
    expect((await raw.query('concrete_pours')).single['concrete_class'], '   ');
    await raw.close();
  });

  test('failed schema 9 migration rolls back intact schema 8 data', () async {
    final versionEight = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(8).toList(),
    );
    await versionEight.open();
    await versionEight.database.insert('follow_up_items', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'capture_text': 'Rollback schema 9',
      'title': 'Rollback schema 9',
      'item_type': 'action',
      'status': 'inbox',
      'is_important': 0,
      'revision': 1,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T08:00:00Z',
    });
    await versionEight.close();

    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 20, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(8),
        DatabaseMigration(
          version: 9,
          apply: (transaction) async {
            await AppDatabase.foundationMigrations[8].apply(transaction);
            throw StateError('forced schema 9 failure');
          },
        ),
      ],
    );
    await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: sqflite.OpenDatabaseOptions(singleInstance: false),
    );
    expect(
      sqflite.Sqflite.firstIntValue(await raw.rawQuery('PRAGMA user_version')),
      8,
    );
    expect(
      (await raw.query('follow_up_items')).single['title'],
      'Rollback schema 9',
    );
    expect(
      (await raw.rawQuery(
        'PRAGMA table_info(follow_up_items)',
      )).where((row) => row['name'] == 'trashed_at'),
      isEmpty,
    );
    expect(
      await raw.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'follow_up_events_v8'",
      ),
      isEmpty,
    );
    await raw.close();
  });

  test('failed schema 7 migration rolls back intact schema 6 data', () async {
    final versionSix = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(6).toList(),
    );
    await versionSix.open();
    await versionSix.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Rollback V6',
      'created_at': '2026-07-19T08:00:00Z',
      'updated_at': '2026-07-19T08:00:00Z',
      'revision': 1,
    });
    await versionSix.close();
    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(6),
        DatabaseMigration(
          version: 7,
          apply: (transaction) async {
            await transaction.execute('CREATE TABLE partial_v7 (id TEXT)');
            throw StateError('forced schema 7 failure');
          },
        ),
      ],
    );
    await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: sqflite.OpenDatabaseOptions(singleInstance: false),
    );
    expect(
      sqflite.Sqflite.firstIntValue(await raw.rawQuery('PRAGMA user_version')),
      6,
    );
    expect((await raw.query('projects')).single['name'], 'Rollback V6');
    expect(
      await raw.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'partial_v7'",
      ),
      isEmpty,
    );
    await raw.close();
  });

  test(
    'failed schema 8 migration rolls back intact schema 7 waiting data',
    () async {
      final versionSeven = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(7).toList(),
      );
      await versionSeven.open();
      await versionSeven.database.insert('follow_up_items', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'capture_text': 'Rollback waiting',
        'title': 'Rollback waiting',
        'item_type': 'waiting',
        'status': 'waiting',
        'is_important': 0,
        'next_attention_at': '2026-07-20T06:00:00Z',
        'revision': 3,
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await versionSeven.database.insert('follow_up_events', {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'follow_up_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'sequence': 1,
        'event_type': 'created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await versionSeven.database.insert('reminder_notification_bindings', {
        'reminder_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'platform_notification_id': 501,
        'scheduled_for': '2026-07-20T06:00:00Z',
        'sync_state': 'scheduled',
        'last_synced_at': '2026-07-19T08:00:00Z',
      });
      await versionSeven.close();

      final failing = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
        migrations: [
          ...AppDatabase.foundationMigrations.take(7),
          DatabaseMigration(
            version: 8,
            apply: (transaction) async {
              await AppDatabase.foundationMigrations[7].apply(transaction);
              throw StateError('forced schema 8 failure');
            },
          ),
        ],
      );
      await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: sqflite.OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await raw.rawQuery('PRAGMA user_version'),
        ),
        7,
      );
      final waiting = (await raw.query('follow_up_items')).single;
      expect(waiting['item_type'], 'waiting');
      expect(waiting['status'], 'waiting');
      expect(
        (await raw.rawQuery(
          'PRAGMA table_info(follow_up_items)',
        )).where((row) => row['name'] == 'all_day_local_date'),
        isEmpty,
      );
      expect(
        await raw.rawQuery(
          "SELECT name FROM sqlite_master WHERE name LIKE '%_v7'",
        ),
        isEmpty,
      );
      await raw.close();
    },
  );
}
