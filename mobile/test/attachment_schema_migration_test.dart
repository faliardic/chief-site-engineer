import 'dart:io';

import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _projectB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _observationA = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _observationB = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _pourA = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _pourB = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
const _truckA = '11111111-1111-4111-8111-111111111111';
const _truckB = '22222222-2222-4222-8222-222222222222';
const _sampleA = '33333333-3333-4333-8333-333333333333';
const _checkA = '44444444-4444-4444-8444-444444444444';
const _timestamp = '2026-08-09T08:00:00Z';

void main() {
  late Directory root;
  late String databasePath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cse_attachment_schema_');
    databasePath = '${root.path}${Platform.pathSeparator}mobile.sqlite3';
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('fresh schema exposes canonical attachment invariants only', () async {
    final database = _database(databasePath);
    await database.open();
    final tables = (await database.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    )).map((row) => row['name']).toSet();

    expect(
      tables,
      containsAll(<String>{
        'managed_attachments',
        'attachment_links',
        'attachment_link_events',
      }),
    );
    expect(tables, isNot(contains('agenda_log_attachments')));
    expect(tables, isNot(contains('concrete_attachments')));

    await expectLater(
      database.database.insert('managed_attachments', {
        'id': '55555555-5555-4555-8555-555555555555',
        'relative_path': '../outside.jpg',
        'mime_type': 'image/jpeg',
        'byte_size': 1,
        'sha256': 'a'.padLeft(64, 'a'),
        'created_at': _timestamp,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await database.close();
  });

  test(
    'schema 12 migrates Agenda and Concrete metadata losslessly without SHA merge',
    () async {
      final schemaTwelve = await _openSeededSchemaTwelve(databasePath);
      await schemaTwelve.database.insert('agenda_log_attachments', {
        'id': '55555555-5555-4555-8555-555555555555',
        'observation_id': _observationA,
        'project_id': _projectA,
        'attachment_type': 'site_photo',
        'original_file_name': 'agenda.jpg',
        'mime_type': 'image/jpeg',
        'byte_size': 11,
        'sha256': 'a'.padLeft(64, 'a'),
        'relative_path': 'agenda/active.jpg',
        'description': 'Agenda açıklaması',
        'captured_at': null,
        'revision': 3,
        'created_at': _timestamp,
        'updated_at': '2026-08-09T09:00:00Z',
        'archived_at': '2026-08-09T10:00:00Z',
      });
      await _insertConcreteAttachment(
        schemaTwelve.database,
        id: '66666666-6666-4666-8666-666666666666',
        contextColumn: 'truck_id',
        contextId: _truckA,
        evidenceType: 'delivery_receipt_scan',
        relativePath: 'concrete/truck.jpg',
        digest: 'a'.padLeft(64, 'a'),
        archivedAt: '2026-08-09T11:00:00Z',
      );
      await _insertConcreteAttachment(
        schemaTwelve.database,
        id: '77777777-7777-4777-8777-777777777777',
        contextColumn: 'sample_set_id',
        contextId: _sampleA,
        evidenceType: 'sample_photo',
        relativePath: 'concrete/sample.jpg',
        digest: 'b'.padLeft(64, 'b'),
      );
      await _insertConcreteAttachment(
        schemaTwelve.database,
        id: '88888888-8888-4888-8888-888888888888',
        contextColumn: 'check_item_id',
        contextId: _checkA,
        evidenceType: 'other',
        relativePath: 'concrete/check.jpg',
        digest: 'c'.padLeft(64, 'c'),
      );
      await schemaTwelve.close();

      final upgraded = _database(databasePath);
      await upgraded.open();
      expect(
        sqflite.Sqflite.firstIntValue(
          await upgraded.database.rawQuery('PRAGMA user_version'),
        ),
        AppDatabase.schemaVersion,
      );
      final managed = await upgraded.database.query(
        'managed_attachments',
        orderBy: 'relative_path ASC',
      );
      final links = await upgraded.database.query(
        'attachment_links',
        orderBy: 'legacy_id ASC',
      );
      expect(managed, hasLength(4));
      expect(
        managed.where((row) => row['sha256'] == 'a'.padLeft(64, 'a')),
        hasLength(2),
      );
      expect(links, hasLength(4));

      final agenda = links.singleWhere(
        (row) => row['legacy_id'] == '55555555-5555-4555-8555-555555555555',
      );
      expect(agenda, containsPair('legacy_source', 'agenda_log_attachments'));
      expect(agenda, containsPair('source_type', 'agenda_observation'));
      expect(agenda, containsPair('source_id', _observationA));
      expect(agenda, containsPair('project_id', _projectA));
      expect(agenda, containsPair('role', 'site_photo'));
      expect(agenda['captured_at'], isNull);
      expect(agenda, containsPair('revision', 3));
      expect(agenda, containsPair('archived_at', '2026-08-09T10:00:00Z'));

      final truck = links.singleWhere(
        (row) => row['legacy_id'] == '66666666-6666-4666-8666-666666666666',
      );
      expect(truck, containsPair('source_type', 'concrete_pour'));
      expect(truck, containsPair('source_id', _pourA));
      expect(truck, containsPair('project_id', _projectA));
      expect(truck, containsPair('context_type', 'concrete_truck'));
      expect(truck, containsPair('context_id', _truckA));
      expect(truck, containsPair('archived_at', '2026-08-09T11:00:00Z'));
      expect(
        links.singleWhere(
          (row) => row['legacy_id'] == '77777777-7777-4777-8777-777777777777',
        ),
        containsPair('context_type', 'concrete_sample_set'),
      );
      expect(
        links.singleWhere(
          (row) => row['legacy_id'] == '88888888-8888-4888-8888-888888888888',
        ),
        containsPair('context_type', 'concrete_check_item'),
      );
      expect(
        await upgraded.database.query('attachment_link_events'),
        hasLength(4),
      );
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      await upgraded.close();
    },
  );

  for (final fixture in <String, Future<void> Function(Database)>{
    'duplicate path': (database) async {
      await _insertAgendaAttachment(
        database,
        id: '55555555-5555-4555-8555-555555555555',
        relativePath: 'shared/collision.jpg',
      );
      await _insertConcreteAttachment(
        database,
        id: '66666666-6666-4666-8666-666666666666',
        contextColumn: 'truck_id',
        contextId: _truckA,
        evidenceType: 'mixer_photo',
        relativePath: 'shared/collision.jpg',
        digest: 'b'.padLeft(64, 'b'),
      );
    },
    'missing target': (database) async {
      await _insertAgendaAttachment(
        database,
        id: '55555555-5555-4555-8555-555555555555',
        relativePath: 'agenda/missing.jpg',
        observationId: '99999999-9999-4999-8999-999999999999',
      );
    },
    'cross-project source': (database) async {
      await _insertAgendaAttachment(
        database,
        id: '55555555-5555-4555-8555-555555555555',
        relativePath: 'agenda/cross-project.jpg',
        projectId: _projectB,
      );
    },
    'invalid Concrete context': (database) async {
      await _insertConcreteAttachment(
        database,
        id: '66666666-6666-4666-8666-666666666666',
        contextColumn: 'truck_id',
        contextId: _truckB,
        evidenceType: 'mixer_photo',
        relativePath: 'concrete/invalid-context.jpg',
        digest: 'b'.padLeft(64, 'b'),
      );
    },
  }.entries) {
    test(
      '${fixture.key} migration fails closed and rolls schema 13 back',
      () async {
        final schemaTwelve = await _openSeededSchemaTwelve(databasePath);
        await schemaTwelve.close();
        final fixtureDatabase = await databaseFactoryFfi.openDatabase(
          databasePath,
          options: sqflite.OpenDatabaseOptions(singleInstance: false),
        );
        await fixtureDatabase.execute('PRAGMA foreign_keys = OFF');
        await fixture.value(fixtureDatabase);
        await fixtureDatabase.close();

        final upgrade = _database(databasePath);
        await expectLater(upgrade.open(), throwsA(isA<DatabaseOpenFailure>()));

        final afterFailure = await databaseFactoryFfi.openDatabase(
          databasePath,
          options: sqflite.OpenDatabaseOptions(singleInstance: false),
        );
        expect(
          sqflite.Sqflite.firstIntValue(
            await afterFailure.rawQuery('PRAGMA user_version'),
          ),
          12,
        );
        expect(
          await afterFailure.rawQuery(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'managed_attachments'",
          ),
          isEmpty,
        );
        expect(
          await afterFailure.query('schema_versions', where: 'version = 13'),
          isEmpty,
        );
        await afterFailure.close();
      },
    );
  }
}

AppDatabase _database(String path) => AppDatabase(
  path: path,
  factory: databaseFactoryFfi,
  clock: () => DateTime.utc(2026, 8, 9, 8),
);

Future<AppDatabase> _openSeededSchemaTwelve(String path) async {
  final database = AppDatabase(
    path: path,
    factory: databaseFactoryFfi,
    clock: () => DateTime.utc(2026, 8, 9, 8),
    migrations: AppDatabase.foundationMigrations.take(12).toList(),
  );
  await database.open();
  for (final (id, name) in [(_projectA, 'Proje A'), (_projectB, 'Proje B')]) {
    await database.database.insert('projects', {
      'id': id,
      'name': name,
      'revision': 1,
      'created_at': _timestamp,
      'updated_at': _timestamp,
    });
  }
  for (final (id, projectId) in [
    (_observationA, _projectA),
    (_observationB, _projectB),
  ]) {
    await database.database.insert('field_observations', {
      'id': id,
      'project_id': projectId,
      'observed_at': _timestamp,
      'created_at': _timestamp,
      'updated_at': _timestamp,
      'category': 'general_note',
      'description': 'Gözlem',
      'revision': 1,
    });
  }
  for (final (id, projectId, code) in [
    (_pourA, _projectA, 'POUR-A'),
    (_pourB, _projectB, 'POUR-B'),
  ]) {
    await database.database.insert('concrete_pours', {
      'id': id,
      'project_id': projectId,
      'pour_code': code,
      'element_location': 'Temel',
      'planned_at': _timestamp,
      'concrete_class': 'C30/37',
      'planned_volume_m3': 10.0,
      'status': 'draft',
      'revision': 1,
      'created_at': _timestamp,
      'updated_at': _timestamp,
    });
  }
  for (final (id, pourId, sequence) in [
    (_truckA, _pourA, 1),
    (_truckB, _pourB, 1),
  ]) {
    await database.database.insert('concrete_trucks', {
      'id': id,
      'concrete_pour_id': pourId,
      'sequence_no': sequence,
      'vehicle_plate': '34 TEST $sequence',
      'delivery_note_number': 'IRS-$pourId',
      'volume_m3': 5.0,
      'result': 'received',
      'revision': 1,
      'created_at': _timestamp,
      'updated_at': _timestamp,
    });
  }
  await database.database.insert('concrete_sample_sets', {
    'id': _sampleA,
    'concrete_pour_id': _pourA,
    'source_truck_id': _truckA,
    'sample_code': 'NUM-A',
    'sample_count': 0,
    'sample_labels_json': '[]',
    'expected_result_dates_json': '[]',
    'status': 'planned',
    'revision': 1,
    'created_at': _timestamp,
    'updated_at': _timestamp,
  });
  await database.database.insert('concrete_check_items', {
    'id': _checkA,
    'concrete_pour_id': _pourA,
    'item_key': 'check-a',
    'label': 'Kontrol A',
    'sort_order': 1,
    'is_required': 1,
    'status': 'pending',
    'revision': 1,
    'created_at': _timestamp,
    'updated_at': _timestamp,
  });
  return database;
}

Future<void> _insertAgendaAttachment(
  Database database, {
  required String id,
  required String relativePath,
  String observationId = _observationA,
  String projectId = _projectA,
}) => database.insert('agenda_log_attachments', {
  'id': id,
  'observation_id': observationId,
  'project_id': projectId,
  'attachment_type': 'site_photo',
  'original_file_name': 'agenda.jpg',
  'mime_type': 'image/jpeg',
  'byte_size': 10,
  'sha256': 'a'.padLeft(64, 'a'),
  'relative_path': relativePath,
  'revision': 1,
  'created_at': _timestamp,
  'updated_at': _timestamp,
});

Future<void> _insertConcreteAttachment(
  Database database, {
  required String id,
  required String contextColumn,
  required String contextId,
  required String evidenceType,
  required String relativePath,
  required String digest,
  String? archivedAt,
}) => database.insert('concrete_attachments', {
  'id': id,
  'concrete_pour_id': _pourA,
  contextColumn: contextId,
  'evidence_type': evidenceType,
  'original_file_name': 'concrete.jpg',
  'mime_type': 'image/jpeg',
  'byte_size': 12,
  'sha256': digest,
  'relative_path': relativePath,
  'captured_at': _timestamp,
  'description': 'Beton açıklaması',
  'created_at': _timestamp,
  'archived_at': archivedAt,
});
