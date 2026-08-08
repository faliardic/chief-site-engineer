import 'dart:io';

import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _projectB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _observation = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _reminder = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _pour = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _timestamp = '2026-08-08T08:00:00Z';

void main() {
  late Directory temporaryRoot;
  late String databasePath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_project_location_schema_',
    );
    databasePath = path.join(temporaryRoot.path, 'cse.sqlite3');
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test(
    'fresh install creates the complete contiguous schema 11 contract',
    () async {
      final database = _database(databasePath);
      await database.open();

      final version = sqflite.Sqflite.firstIntValue(
        await database.database.rawQuery('PRAGMA user_version'),
      );
      final history = await database.database.query(
        'schema_versions',
        columns: ['version'],
        orderBy: 'version ASC',
      );
      final tables = await database.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
      );

      expect(version, 11);
      expect(
        history.map((row) => row['version']),
        List.generate(11, (i) => i + 1),
      );
      expect(
        tables.map((row) => row['name']),
        containsAll([
          'project_locations',
          'project_events',
          'project_location_events',
        ]),
      );
      for (final table in [
        'field_observations',
        'follow_up_items',
        'concrete_pours',
      ]) {
        final columns = await database.database.rawQuery(
          'PRAGMA table_info($table)',
        );
        expect(
          columns.map((row) => row['name']),
          contains('location_id'),
          reason: table,
        );
      }
      expect(await database.database.query('project_locations'), isEmpty);
      expect(await database.database.query('project_events'), isEmpty);
      expect(await database.database.query('project_location_events'), isEmpty);
      expect(
        await database.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );

      await database.close();
    },
  );

  test(
    'schema 10 upgrade preserves legacy ids texts revisions events and attachments',
    () async {
      final versionTen = _database(
        databasePath,
        migrations: AppDatabase.foundationMigrations.take(10).toList(),
      );
      await versionTen.open();
      await _seedLegacyFixture(versionTen.database);
      final before = await _legacySnapshots(versionTen.database);
      await versionTen.close();

      final upgraded = _database(databasePath);
      await upgraded.open();
      final after = await _legacySnapshots(
        upgraded.database,
        removeLocationLinks: true,
      );

      expect(after, before);
      for (final table in [
        'field_observations',
        'follow_up_items',
        'concrete_pours',
      ]) {
        final rows = await upgraded.database.query(
          table,
          columns: ['location_id'],
        );
        expect(rows, isNotEmpty, reason: table);
        expect(rows.every((row) => row['location_id'] == null), isTrue);
      }
      expect(await upgraded.database.query('project_locations'), isEmpty);
      expect(await upgraded.database.query('project_events'), isEmpty);
      expect(await upgraded.database.query('project_location_events'), isEmpty);
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );

      await upgraded.close();
    },
  );

  test(
    'location hierarchy links and immutable histories fail closed',
    () async {
      final database = _database(databasePath);
      await database.open();
      await _seedProjectsAndRecords(database.database);

      await _insertLocation(
        database.database,
        id: 'location-a-root',
        projectId: _projectA,
        displayName: 'A Blok',
        normalizedName: 'a blok',
      );
      await _insertLocation(
        database.database,
        id: 'location-a-parent-1',
        projectId: _projectA,
        displayName: '1. Kat',
        normalizedName: '1. kat',
      );
      await _insertLocation(
        database.database,
        id: 'location-a-parent-2',
        projectId: _projectA,
        displayName: '2. Kat',
        normalizedName: '2. kat',
      );
      await _insertLocation(
        database.database,
        id: 'location-a-child-1',
        projectId: _projectA,
        displayName: 'Daire 1',
        normalizedName: 'daire 1',
        parentLocationId: 'location-a-parent-1',
      );
      await _insertLocation(
        database.database,
        id: 'location-a-child-2',
        projectId: _projectA,
        displayName: 'Daire 1',
        normalizedName: 'daire 1',
        parentLocationId: 'location-a-parent-2',
      );
      await _insertLocation(
        database.database,
        id: 'location-b-root',
        projectId: _projectB,
        displayName: 'B Blok',
        normalizedName: 'b blok',
      );

      await expectLater(
        _insertLocation(
          database.database,
          id: 'location-a-root-duplicate',
          projectId: _projectA,
          displayName: 'A BLOK',
          normalizedName: 'a blok',
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        _insertLocation(
          database.database,
          id: 'location-a-child-duplicate',
          projectId: _projectA,
          displayName: 'DAİRE 1',
          normalizedName: 'daire 1',
          parentLocationId: 'location-a-parent-1',
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await _insertLocation(
        database.database,
        id: 'location-a-root-archived',
        projectId: _projectA,
        displayName: 'Eski A Blok',
        normalizedName: 'a blok',
        archivedAt: _timestamp,
      );
      await expectLater(
        _insertLocation(
          database.database,
          id: 'location-cross-project-child',
          projectId: _projectB,
          displayName: 'Yanlış çocuk',
          normalizedName: 'yanlış çocuk',
          parentLocationId: 'location-a-root',
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        _insertLocation(
          database.database,
          id: 'location-self-parent',
          projectId: _projectA,
          displayName: 'Kendi üstü',
          normalizedName: 'kendi üstü',
          parentLocationId: 'location-self-parent',
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );

      for (final tableAndId in const [
        ('field_observations', _observation),
        ('follow_up_items', _reminder),
        ('concrete_pours', _pour),
      ]) {
        await database.database.update(
          tableAndId.$1,
          {'location_id': 'location-a-root'},
          where: 'id = ?',
          whereArgs: [tableAndId.$2],
        );
        await expectLater(
          database.database.update(
            tableAndId.$1,
            {'location_id': 'location-b-root'},
            where: 'id = ?',
            whereArgs: [tableAndId.$2],
          ),
          throwsA(isA<sqflite.DatabaseException>()),
          reason: tableAndId.$1,
        );
        expect(
          (await database.database.query(
            tableAndId.$1,
            columns: ['location_id'],
            where: 'id = ?',
            whereArgs: [tableAndId.$2],
          )).single['location_id'],
          'location-a-root',
        );
      }
      await expectLater(
        database.database.update(
          'project_locations',
          {'project_id': _projectB},
          where: 'id = ?',
          whereArgs: ['location-a-root'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      expect(
        (await database.database.query(
          'project_locations',
          columns: ['project_id'],
          where: 'id = ?',
          whereArgs: ['location-a-root'],
        )).single['project_id'],
        _projectA,
      );
      for (final tableAndId in const [
        ('field_observations', _observation),
        ('follow_up_items', _reminder),
        ('concrete_pours', _pour),
      ]) {
        expect(
          await database.database.query(
            tableAndId.$1,
            columns: ['project_id', 'location_id'],
            where: 'id = ?',
            whereArgs: [tableAndId.$2],
          ),
          [
            {'project_id': _projectA, 'location_id': 'location-a-root'},
          ],
          reason: tableAndId.$1,
        );
      }
      expect(
        await database.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );

      for (final event in const [
        'project.renamed',
        'project.archived',
        'project.restored',
      ].indexed) {
        await database.database.insert('project_events', {
          'id': 'project-event-${event.$1}',
          'project_id': _projectA,
          'sequence': event.$1 + 1,
          'event_type': event.$2,
          'occurred_at': _timestamp,
          'payload_json': '{}',
        });
      }
      for (final event in const [
        'location.created',
        'location.renamed',
        'location.reparented',
        'location.archived',
        'location.restored',
      ].indexed) {
        await database.database.insert('project_location_events', {
          'id': 'location-event-${event.$1}',
          'location_id': 'location-a-root',
          'sequence': event.$1 + 1,
          'event_type': event.$2,
          'occurred_at': _timestamp,
          'payload_json': '{}',
        });
      }
      await expectLater(
        database.database.insert('project_events', {
          'id': 'project-event-invalid',
          'project_id': _projectA,
          'sequence': 4,
          'event_type': 'project.deleted',
          'occurred_at': _timestamp,
          'payload_json': '{}',
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        database.database.insert('project_location_events', {
          'id': 'location-event-invalid',
          'location_id': 'location-a-root',
          'sequence': 6,
          'event_type': 'location.deleted',
          'occurred_at': _timestamp,
          'payload_json': '{}',
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      for (final table in ['project_events', 'project_location_events']) {
        await expectLater(
          database.database.update(table, {'payload_json': '{"changed":true}'}),
          throwsA(isA<sqflite.DatabaseException>()),
          reason: table,
        );
        await expectLater(
          database.database.delete(table),
          throwsA(isA<sqflite.DatabaseException>()),
          reason: table,
        );
      }
      await expectLater(
        database.database.delete(
          'project_locations',
          where: 'id = ?',
          whereArgs: ['location-a-child-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        database.database.delete(
          'projects',
          where: 'id = ?',
          whereArgs: [_projectA],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      expect(
        await database.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );

      await database.close();
    },
  );

  test('failed schema 11 migration rolls back every additive change', () async {
    final versionTen = _database(
      databasePath,
      migrations: AppDatabase.foundationMigrations.take(10).toList(),
    );
    await versionTen.open();
    await versionTen.database.insert('projects', {
      'id': _projectA,
      'name': 'Rollback projesi',
      'created_at': _timestamp,
      'updated_at': _timestamp,
      'revision': 3,
    });
    await versionTen.close();

    final failing = _database(
      databasePath,
      migrations: [
        ...AppDatabase.foundationMigrations.take(10),
        DatabaseMigration(
          version: 11,
          apply: (transaction) async {
            await AppDatabase.foundationMigrations[10].apply(transaction);
            throw StateError('forced schema 11 failure');
          },
        ),
      ],
    );
    await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));

    final raw = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: sqflite.OpenDatabaseOptions(singleInstance: false),
    );
    expect(
      sqflite.Sqflite.firstIntValue(await raw.rawQuery('PRAGMA user_version')),
      10,
    );
    expect((await raw.query('projects')).single['revision'], 3);
    expect(
      await raw.rawQuery(
        "SELECT name FROM sqlite_master WHERE name IN ("
        "'project_locations', 'project_events', 'project_location_events')",
      ),
      isEmpty,
    );
    for (final table in [
      'field_observations',
      'follow_up_items',
      'concrete_pours',
    ]) {
      final columns = await raw.rawQuery('PRAGMA table_info($table)');
      expect(
        columns.where((row) => row['name'] == 'location_id'),
        isEmpty,
        reason: table,
      );
    }
    expect(await raw.query('schema_versions', where: 'version = 11'), isEmpty);
    await raw.close();
  });
}

AppDatabase _database(
  String databasePath, {
  List<DatabaseMigration>? migrations,
}) => AppDatabase(
  path: databasePath,
  factory: databaseFactoryFfi,
  clock: () => DateTime.parse(_timestamp),
  migrations: migrations,
);

Future<void> _seedProjectsAndRecords(sqflite.Database database) async {
  for (final project in const [
    (_projectA, 'Proje A'),
    (_projectB, 'Proje B'),
  ]) {
    await database.insert('projects', {
      'id': project.$1,
      'name': project.$2,
      'created_at': _timestamp,
      'updated_at': _timestamp,
      'revision': 1,
    });
  }
  await database.insert('field_observations', {
    'id': _observation,
    'project_id': _projectA,
    'observed_at': _timestamp,
    'created_at': _timestamp,
    'updated_at': _timestamp,
    'category': 'inspection',
    'description': 'Konum bağlantısı gözlemi',
    'location': 'A Blok / 1. Kat',
    'revision': 1,
  });
  await database.insert('follow_up_items', {
    'id': _reminder,
    'capture_text': 'Konumu tekrar kontrol et',
    'title': 'Konumu tekrar kontrol et',
    'item_type': 'action',
    'status': 'inbox',
    'project_id': _projectA,
    'observation_id': _observation,
    'location': 'A Blok / 1. Kat',
    'is_important': 0,
    'revision': 1,
    'created_at': _timestamp,
    'updated_at': _timestamp,
  });
  await database.insert('concrete_pours', {
    'id': _pour,
    'project_id': _projectA,
    'pour_code': 'BT-392',
    'element_location': 'A Blok temel',
    'block_name': 'A Blok',
    'floor_name': 'Temel',
    'axis_name': 'A/1',
    'planned_at': _timestamp,
    'concrete_class': 'C30/37',
    'planned_volume_m3': 10.0,
    'status': 'draft',
    'revision': 1,
    'created_at': _timestamp,
    'updated_at': _timestamp,
  });
}

Future<void> _seedLegacyFixture(sqflite.Database database) async {
  await _seedProjectsAndRecords(database);
  await database.insert('observation_events', {
    'id': 'observation-event-392',
    'observation_id': _observation,
    'project_id': _projectA,
    'event_type': 'observation.created',
    'occurred_at': _timestamp,
    'payload_json': '{"location":"A Blok / 1. Kat"}',
  });
  await database.insert('follow_up_events', {
    'id': 'reminder-event-392',
    'follow_up_id': _reminder,
    'sequence': 1,
    'project_id': _projectA,
    'source_observation_id': _observation,
    'event_type': 'created',
    'occurred_at': _timestamp,
    'payload_json': '{}',
  });
  await database.insert('concrete_pour_events', {
    'id': 'pour-event-392',
    'concrete_pour_id': _pour,
    'sequence': 1,
    'event_type': 'pour.created',
    'occurred_at': _timestamp,
    'payload_json': '{}',
  });
  await database.insert('agenda_log_attachments', {
    'id': 'agenda-attachment-392',
    'observation_id': _observation,
    'project_id': _projectA,
    'attachment_type': 'site_photo',
    'original_file_name': 'legacy.jpg',
    'mime_type': 'image/jpeg',
    'byte_size': 4,
    'sha256': List.filled(64, 'a').join(),
    'relative_path': 'agenda/legacy.jpg',
    'revision': 2,
    'created_at': _timestamp,
    'updated_at': _timestamp,
  });
  await database.insert('concrete_attachments', {
    'id': 'concrete-attachment-392',
    'concrete_pour_id': _pour,
    'evidence_type': 'site_photo',
    'original_file_name': 'legacy.bin',
    'mime_type': 'application/octet-stream',
    'byte_size': 3,
    'sha256': List.filled(64, 'b').join(),
    'relative_path': 'concrete/legacy.bin',
    'captured_at': _timestamp,
    'created_at': _timestamp,
  });
}

Future<Map<String, List<Map<String, Object?>>>> _legacySnapshots(
  sqflite.Database database, {
  bool removeLocationLinks = false,
}) async {
  final result = <String, List<Map<String, Object?>>>{};
  for (final table in [
    'projects',
    'field_observations',
    'observation_events',
    'follow_up_items',
    'follow_up_events',
    'concrete_pours',
    'concrete_pour_events',
    'agenda_log_attachments',
    'concrete_attachments',
  ]) {
    final rows = await database.query(table, orderBy: 'id ASC');
    result[table] = rows.map((row) {
      final copy = Map<String, Object?>.from(row);
      if (removeLocationLinks &&
          {
            'field_observations',
            'follow_up_items',
            'concrete_pours',
          }.contains(table)) {
        copy.remove('location_id');
      }
      return copy;
    }).toList();
  }
  return result;
}

Future<void> _insertLocation(
  sqflite.Database database, {
  required String id,
  required String projectId,
  required String displayName,
  required String normalizedName,
  String? parentLocationId,
  String? archivedAt,
}) => database.insert('project_locations', {
  'id': id,
  'project_id': projectId,
  'display_name': displayName,
  'normalized_name': normalizedName,
  'parent_location_id': parentLocationId,
  'revision': 1,
  'created_at': _timestamp,
  'updated_at': _timestamp,
  'archived_at': archivedAt,
});
