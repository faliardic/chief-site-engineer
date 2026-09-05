import 'dart:io';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _projectB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _sketchA = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _revisionA = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const _legacyDraft = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2';
const _assetA = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';
const _placementA = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1';
const _placementKeyA = 'ffffffff-ffff-4fff-8fff-fffffffffff1';
const _attachmentA = '11111111-1111-4111-8111-111111111111';
const _photoLinkA = '22222222-2222-4222-8222-222222222222';
const _receiptA = '33333333-3333-4333-8333-333333333333';
const _eventA = '44444444-4444-4444-8444-444444444444';
const _blockA = '55555555-5555-4555-8555-555555555555';
const _floorA = '66666666-6666-4666-8666-666666666666';
const _supersededFloorTwo = '77777777-7777-4777-8777-777777777772';
const _supersededProjectBFloor = '77777777-7777-4777-8777-777777777773';
const _successorPlacement = '88888888-8888-4888-8888-888888888882';
const _t0 = '2026-08-27T04:00:00Z';
const _t1 = '2026-08-27T05:00:00Z';
const _t2 = '2026-08-27T06:00:00Z';
const _digest =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

const _inventoryTables = <String>{
  'inventory_sketches',
  'inventory_sketch_revisions',
  'inventory_blocks',
  'inventory_floors',
  'inventory_sketch_revision_block_polygons',
  'inventory_sketch_revision_spatial_drafts',
  'inventory_assets',
  'inventory_asset_placements',
  'inventory_command_receipts',
  'inventory_events',
  'inventory_asset_attachment_links',
};

const _plannedIndexes = <String>{
  'uq_inventory_sketches_primary',
  'ix_inventory_sketches_project',
  'uq_inventory_sketch_revisions_draft',
  'uq_inventory_sketch_revisions_active',
  'ix_inventory_sketch_revisions_history',
  'ix_inventory_assets_project_name',
  'ix_inventory_assets_project_filter',
  'uq_inventory_asset_placements_active_key',
  'ix_inventory_asset_placements_map',
  'ix_inventory_asset_placements_asset',
  'ix_inventory_command_receipts_aggregate',
  'ix_inventory_events_history',
  'ix_inventory_events_operation',
  'uq_inventory_asset_attachment_links_active',
  'ix_inventory_asset_attachment_links_asset',
  'ix_inventory_asset_attachment_links_attachment',
  'inventory_blocks_project_state',
  'uq_inventory_blocks_active_name',
  'inventory_floors_project_block',
  'inventory_revision_block_polygons_revision',
  'inventory_spatial_drafts_revision',
  'inventory_placements_floor_history',
};

void main() {
  late Directory temporaryRoot;
  late String databasePath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_inventory_schema_',
    );
    databasePath = path.join(temporaryRoot.path, 'mobile.sqlite3');
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test(
    'fresh database creates exact schema 23 Inventory tables and indices',
    () async {
      final database = _database(databasePath);
      await database.open();
      final db = database.database;

      expect(
        sqflite.Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')),
        23,
      );
      expect(
        (await db.query(
          'schema_versions',
          columns: ['version'],
          orderBy: 'version ASC',
        )).map((row) => row['version']),
        List.generate(23, (index) => index + 1),
      );
      expect(
        await _objectNames(db, type: 'table', prefix: 'inventory_'),
        _inventoryTables,
      );
      expect(
        await _objectNames(
          db,
          type: 'index',
          prefix: 'inventory_',
          names: true,
        ),
        containsAll(_plannedIndexes),
      );
      for (final table in _inventoryTables) {
        expect(await db.query(table), isEmpty, reason: table);
      }
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect(
        (await db.rawQuery('PRAGMA integrity_check')).single['integrity_check'],
        'ok',
      );
      await database.close();
    },
  );

  test(
    'schema 19 upgrade is additive, preserves rows, and rolls back on failure',
    () async {
      final upgradePath = path.join(temporaryRoot.path, 'upgrade.sqlite3');
      final schemaNineteen = await _openSeededSchemaNineteen(upgradePath);
      final beforeObjects = await _existingObjects(schemaNineteen.database);
      final beforeRows = await _representativeRows(schemaNineteen.database);
      await schemaNineteen.close();

      final upgraded = _database(upgradePath);
      await upgraded.open();
      final db = upgraded.database;
      final currentObjects = await _existingObjects(db);
      const profileTables = {
        'project_profile_fields',
        'project_profile_events',
      };
      final profileObjects = currentObjects
          .where((object) => profileTables.contains(object['tbl_name']))
          .toList();
      final afterObjects = currentObjects
          .where((object) => !profileTables.contains(object['tbl_name']))
          .toList();
      final afterRows = await _representativeRows(db);

      // Schema 23 adds only these profile objects outside Inventory. Every
      // pre-existing object's SQL and every representative row stay exact.
      expect(
        profileObjects.map((object) => object['name']),
        unorderedEquals(const [
          'project_profile_fields',
          'project_profile_events',
          'ix_project_profile_fields_project_order',
          'ix_project_profile_events_project',
          'project_profile_fields_project_immutable',
          'project_profile_fields_identity_immutable',
          'project_profile_fields_no_physical_delete',
          'project_profile_events_append_only_update',
          'project_profile_events_append_only_delete',
        ]),
      );
      expect(afterObjects, beforeObjects);
      expect(afterRows, beforeRows);
      expect(
        sqflite.Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')),
        23,
      );
      for (final table in _inventoryTables) {
        expect(await db.query(table), isEmpty, reason: table);
      }
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await upgraded.close();

      final rollbackPath = path.join(temporaryRoot.path, 'rollback.sqlite3');
      final rollbackSchema = await _openSeededSchemaTwenty(rollbackPath);
      final rollbackRows = await _inventoryV20Snapshot(rollbackSchema.database);
      await rollbackSchema.close();
      final failing = _database(
        rollbackPath,
        migrations: [
          ...AppDatabase.foundationMigrations.take(20),
          DatabaseMigration(
            version: 21,
            apply: (transaction) async {
              await AppDatabase.foundationMigrations[20].apply(transaction);
              throw StateError('forced inventory schema 21 failure');
            },
          ),
        ],
      );

      await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
      final afterFailure = await databaseFactoryFfi.openDatabase(
        rollbackPath,
        options: sqflite.OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await afterFailure.rawQuery('PRAGMA user_version'),
        ),
        20,
      );
      expect(
        await _objectNames(afterFailure, type: 'table', prefix: 'inventory_'),
        _inventoryTables.difference(const {
          'inventory_blocks',
          'inventory_floors',
          'inventory_sketch_revision_block_polygons',
          'inventory_sketch_revision_spatial_drafts',
        }),
      );
      expect(
        await afterFailure.query('schema_versions', where: 'version = 21'),
        isEmpty,
      );
      expect(await _inventoryV20Snapshot(afterFailure), rollbackRows);
      await afterFailure.close();
    },
  );

  test(
    'schema 20 through revised 21 to 23 preserves the exact Inventory graph',
    () async {
      final legacy = await _openSeededSchemaTwenty(databasePath);
      final before = await _inventoryV20Snapshot(legacy.database);
      await legacy.close();

      final upgraded = _database(databasePath);
      await upgraded.open();
      final db = upgraded.database;

      expect(await _inventoryV20Snapshot(db), before);
      expect(
        sqflite.Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')),
        23,
      );
      final blocks = await db.query('inventory_blocks');
      final floors = await db.query('inventory_floors');
      expect(blocks, hasLength(1));
      expect(floors, hasLength(1));
      expect(
        blocks.single['id'],
        _stableMigrationUuid('inventory-spatial-v21:block:$_projectA'),
      );
      expect(blocks.single['project_id'], _projectA);
      expect(blocks.single['display_name'], 'Varsayılan Alan');
      expect(blocks.single['normalized_name'], 'varsayılan alan');
      expect(blocks.single['ordinal'], 1);
      expect(blocks.single['state'], 'DETACHED');
      expect(
        floors.single['id'],
        _stableMigrationUuid('inventory-spatial-v21:floor:$_projectA'),
      );
      expect(floors.single['project_id'], _projectA);
      expect(floors.single['block_id'], blocks.single['id']);
      expect(floors.single['display_name'], '1. Kat');
      expect(floors.single['ordinal'], 1);
      expect(
        (await db.query('inventory_asset_placements')).single['floor_id'],
        floors.single['id'],
      );
      expect(
        await db.query('inventory_sketch_revision_block_polygons'),
        isEmpty,
      );
      expect(
        (await db.query(
          'inventory_sketch_revision_spatial_drafts',
        )).single['legacy_polygon_count'],
        1,
      );
      final application = InventoryApplication(
        database: upgraded,
        clock: () => DateTime.parse(_t2),
        idFactory: () => '77777777-7777-4777-8777-777777777777',
      );
      final projection = await application.loadPrimarySketch(_projectA);
      expect(projection!.activeRevision!.id, _revisionA);
      expect(projection.draftRevision!.id, _legacyDraft);
      expect(projection.draftLegacyPolygonCount, 1);
      expect(projection.draftNewBlocks, isEmpty);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect(
        (await db.rawQuery('PRAGMA integrity_check')).single['integrity_check'],
        'ok',
      );
      await upgraded.close();
    },
  );

  test(
    'revised schema 21 to 23 preserves Inventory structure with integrity validation',
    () async {
      final schemaTwenty = await _openSeededSchemaTwenty(databasePath);
      await schemaTwenty.close();
      final revisedTwentyOne = _database(
        databasePath,
        migrations: AppDatabase.foundationMigrations.take(21).toList(),
      );
      await revisedTwentyOne.open();
      final rowsBefore = await _finalInventorySnapshot(
        revisedTwentyOne.database,
      );
      final objectsBefore = await _inventorySchemaObjects(
        revisedTwentyOne.database,
      );
      await revisedTwentyOne.close();

      final upgraded = _database(databasePath);
      await upgraded.open();
      expect(
        sqflite.Sqflite.firstIntValue(
          await upgraded.database.rawQuery('PRAGMA user_version'),
        ),
        23,
      );
      expect(await _finalInventorySnapshot(upgraded.database), rowsBefore);
      expect(await _inventorySchemaObjects(upgraded.database), objectsBefore);
      expect(
        await upgraded.database.query('schema_versions', where: 'version = 22'),
        hasLength(1),
      );
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      expect(
        (await upgraded.database.rawQuery(
          'PRAGMA integrity_check',
        )).single['integrity_check'],
        'ok',
      );
      await upgraded.close();
    },
  );

  test(
    'superseded schema 21 to 23 preserves floors placement history and evidence',
    () async {
      final superseded = await _openSeededSupersededSchemaTwentyOne(
        databasePath,
      );
      final preservedBefore = await _supersededPreservedSnapshot(
        superseded.database,
      );
      final oldFloors = await superseded.database.query(
        'inventory_floors',
        orderBy: 'id ASC',
      );
      final oldPlacements = await superseded.database.query(
        'inventory_asset_placements',
        orderBy: 'id ASC',
      );
      await superseded.close();

      final upgraded = _database(databasePath);
      await upgraded.open();
      final db = upgraded.database;
      expect(
        sqflite.Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')),
        23,
      );
      expect(await _supersededPreservedSnapshot(db), preservedBefore);
      expect(
        await db.query('inventory_asset_placements', orderBy: 'id ASC'),
        oldPlacements,
      );

      final expectedBlockId = _stableMigrationUuid(
        'inventory-spatial-v21:block:$_projectA',
      );
      final blocks = await db.query('inventory_blocks', orderBy: 'id ASC');
      expect(blocks, hasLength(1));
      expect(blocks.single['id'], expectedBlockId);
      expect(blocks.single['project_id'], _projectA);
      expect(blocks.single['state'], 'DETACHED');
      final floors = await db.query('inventory_floors', orderBy: 'id ASC');
      expect(floors, hasLength(oldFloors.length));
      for (var index = 0; index < oldFloors.length; index += 1) {
        final oldFloor = oldFloors[index];
        final floor = floors[index];
        for (final column in const [
          'id',
          'project_id',
          'ordinal',
          'display_name',
          'revision',
          'created_at',
          'updated_at',
        ]) {
          expect(floor[column], oldFloor[column], reason: '$column at $index');
        }
        expect(floor['block_id'], expectedBlockId);
        expect(floor['archived_at'], isNull);
      }
      expect(
        await db.query('inventory_sketch_revision_block_polygons'),
        isEmpty,
      );
      final draftMetadata = await db.query(
        'inventory_sketch_revision_spatial_drafts',
        where: 'revision_id = ?',
        whereArgs: [_legacyDraft],
      );
      expect(draftMetadata, hasLength(1));
      expect(draftMetadata.single['legacy_polygon_count'], 1);
      expect(draftMetadata.single['definitions_json'], '[]');

      const secondBlock = '99999999-9999-4999-8999-999999999992';
      const secondBlockFloor = '99999999-9999-4999-8999-999999999993';
      await db.insert('inventory_blocks', {
        'id': secondBlock,
        'project_id': _projectA,
        'display_name': 'İkinci Alan',
        'normalized_name': 'ikinci alan',
        'ordinal': 2,
        'state': 'DETACHED',
        'revision': 1,
        'created_at': _t2,
        'updated_at': _t2,
      });
      await db.insert('inventory_floors', {
        'id': secondBlockFloor,
        'block_id': secondBlock,
        'project_id': _projectA,
        'display_name': '1. Kat',
        'ordinal': 1,
        'revision': 1,
        'created_at': _t2,
        'updated_at': _t2,
      });
      expect(
        await db.query(
          'inventory_floors',
          where: 'ordinal = 1',
          orderBy: 'block_id ASC',
        ),
        hasLength(2),
      );
      final projection = await InventoryApplication(
        database: upgraded,
        clock: () => DateTime.parse(_t2),
        idFactory: () => '77777777-7777-4777-8777-777777777777',
      ).loadPrimarySketch(_projectA);
      expect(projection!.draftRevision!.id, _legacyDraft);
      expect(projection.draftLegacyPolygonCount, 1);
      expect(projection.draftNewBlocks, isEmpty);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect(
        (await db.rawQuery('PRAGMA integrity_check')).single['integrity_check'],
        'ok',
      );
      await upgraded.close();
    },
  );

  test(
    'mixed schema 21 signature fails closed without partial conversion',
    () async {
      final superseded = await _openSeededSupersededSchemaTwentyOne(
        databasePath,
      );
      await superseded.database.execute(
        'CREATE TABLE inventory_blocks (id TEXT)',
      );
      await superseded.close();

      final upgraded = _database(databasePath);
      await expectLater(upgraded.open(), throwsA(isA<DatabaseOpenFailure>()));
      final afterFailure = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: sqflite.OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await afterFailure.rawQuery('PRAGMA user_version'),
        ),
        21,
      );
      expect(await afterFailure.query('inventory_blocks'), isEmpty);
      expect(
        await afterFailure.query('schema_versions', where: 'version = 22'),
        isEmpty,
      );
      expect(
        (await _tableColumnsForTest(afterFailure, 'inventory_floors')),
        isNot(contains('block_id')),
      );
      await afterFailure.close();
    },
  );

  test(
    'superseded schema 21 corrupt placement floor relationship rolls back',
    () async {
      final superseded = await _openSeededSupersededSchemaTwentyOne(
        databasePath,
      );
      final db = superseded.database;
      await db.insert('inventory_floors', {
        'id': _supersededProjectBFloor,
        'project_id': _projectB,
        'ordinal': 1,
        'display_name': 'Project B floor',
        'revision': 3,
        'created_at': _t1,
        'updated_at': _t2,
      });
      await db.execute(
        'DROP TRIGGER inventory_asset_placements_terminal_update',
      );
      await db.update(
        'inventory_asset_placements',
        {'floor_id': _supersededProjectBFloor},
        where: 'id = ?',
        whereArgs: [_successorPlacement],
      );
      await _createSupersededPlacementTerminalTrigger(db);
      await superseded.close();

      final upgraded = _database(databasePath);
      await expectLater(upgraded.open(), throwsA(isA<DatabaseOpenFailure>()));
      final afterFailure = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: sqflite.OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await afterFailure.rawQuery('PRAGMA user_version'),
        ),
        21,
      );
      expect(
        (await afterFailure.query(
          'inventory_asset_placements',
          columns: ['floor_id'],
          where: 'id = ?',
          whereArgs: [_successorPlacement],
        )).single['floor_id'],
        _supersededProjectBFloor,
      );
      expect(
        await _objectNames(afterFailure, type: 'table', prefix: 'inventory_'),
        isNot(contains('inventory_blocks')),
      );
      expect(
        await afterFailure.query('schema_versions', where: 'version = 22'),
        isEmpty,
      );
      await afterFailure.close();
    },
  );

  test(
    'schema 21 corrupt cross-project source rolls back before any DDL',
    () async {
      final legacy = await _openSeededSchemaTwenty(databasePath);
      await legacy.close();
      final corrupt = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: sqflite.OpenDatabaseOptions(
          singleInstance: false,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = OFF');
          },
        ),
      );
      await corrupt.execute(
        'DROP TRIGGER inventory_asset_placements_source_insert',
      );
      final corruptPlacement =
          _placementRow(
              id: 'cross-project-corrupt-placement',
              placementKey: 'cross-project-corrupt-key',
              projectId: _projectB,
              quantity: 1,
              createdAt: _t2,
            )
            ..remove('floor_id')
            ..['ended_at'] = _t2
            ..['end_reason'] = 'MOVED';
      await corrupt.insert('inventory_asset_placements', corruptPlacement);
      final before = await _inventoryV20Snapshot(corrupt);
      await corrupt.close();

      final upgraded = _database(databasePath);
      await expectLater(upgraded.open(), throwsA(isA<DatabaseOpenFailure>()));
      final afterFailure = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: sqflite.OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await afterFailure.rawQuery('PRAGMA user_version'),
        ),
        20,
      );
      expect(
        await _objectNames(afterFailure, type: 'table', prefix: 'inventory_'),
        _inventoryTables.difference(const {
          'inventory_blocks',
          'inventory_floors',
          'inventory_sketch_revision_block_polygons',
          'inventory_sketch_revision_spatial_drafts',
        }),
      );
      expect(await _inventoryV20Snapshot(afterFailure), before);
      await afterFailure.close();
    },
  );

  test(
    'schema 23 fails closed and retains one valid populated graph',
    () async {
      final database = _database(databasePath);
      await database.open();
      final db = database.database;
      await _seedProjects(db);
      final graph = await _seedValidInventoryGraph(db);

      await _expectCrossProjectFailures(db, graph);
      await _expectPartialUniquenessFailures(db, graph);
      await _expectVocabularyAndCheckFailures(db, graph);
      await _expectImmutabilityAndAppendOnlyFailures(db, graph);
      await _expectPlacementHistoryAndQuantityFailures(db, graph);

      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect(
        (await db.rawQuery('PRAGMA integrity_check')).single['integrity_check'],
        'ok',
      );
      expect(await db.query('inventory_sketches'), isNotEmpty);
      expect(await db.query('inventory_sketch_revisions'), isNotEmpty);
      expect(await db.query('inventory_assets'), hasLength(1));
      expect(await db.query('inventory_asset_placements'), hasLength(2));
      expect(await db.query('inventory_command_receipts'), hasLength(1));
      expect(await db.query('inventory_events'), hasLength(1));
      expect(await db.query('inventory_asset_attachment_links'), hasLength(1));
      await database.close();
    },
  );
}

AppDatabase _database(
  String databasePath, {
  List<DatabaseMigration>? migrations,
}) => AppDatabase(
  path: databasePath,
  factory: databaseFactoryFfi,
  clock: () => DateTime.parse(_t0),
  migrations: migrations,
);

Future<AppDatabase> _openSeededSchemaNineteen(String databasePath) async {
  final database = _database(
    databasePath,
    migrations: AppDatabase.foundationMigrations.take(19).toList(),
  );
  await database.open();
  await database.database.insert('projects', {
    'id': _projectA,
    'name': 'Inventory migration project',
    'created_at': _t0,
    'updated_at': _t0,
    'revision': 1,
  });
  await database.database.insert('field_observations', {
    'id': 'legacy-observation',
    'project_id': _projectA,
    'observed_at': _t0,
    'created_at': _t0,
    'updated_at': _t0,
    'category': 'general_note',
    'description': 'Preserved legacy row',
    'notes': 'Byte-equivalent text',
    'revision': 1,
  });
  await database.database.insert('managed_attachments', {
    'id': _attachmentA,
    'relative_path': 'managed/inventory-fixture.jpg',
    'mime_type': 'image/jpeg',
    'byte_size': 17,
    'sha256': _digest,
    'created_at': _t0,
  });
  return database;
}

Future<AppDatabase> _openSeededSchemaTwenty(String databasePath) async {
  final database = _database(
    databasePath,
    migrations: AppDatabase.foundationMigrations.take(20).toList(),
  );
  await database.open();
  await _seedProjects(database.database);
  final graph = await _seedValidInventoryGraph(
    database.database,
    spatial: false,
  );
  await database.database.insert(
    'inventory_sketch_revisions',
    _revisionRow(
      id: _legacyDraft,
      revisionNumber: 2,
      baseRevisionId: _revisionA,
      geometryJson: graph['geometry_json']! as String,
      geometrySha256: graph['geometry_sha256']! as String,
      createdAt: _t2,
      updatedAt: _t2,
    ),
  );
  await database.database.update(
    'inventory_sketches',
    {'draft_revision_id': _legacyDraft, 'revision': 3, 'updated_at': _t2},
    where: 'id = ? AND revision = 2',
    whereArgs: [_sketchA],
  );
  return database;
}

Future<AppDatabase> _openSeededSupersededSchemaTwentyOne(
  String databasePath,
) async {
  final schemaTwenty = await _openSeededSchemaTwenty(databasePath);
  await schemaTwenty.close();
  final database = _database(
    databasePath,
    migrations: [
      ...AppDatabase.foundationMigrations.take(20),
      const DatabaseMigration(
        version: 21,
        apply: _applySupersededSchemaTwentyOneFixture,
      ),
    ],
  );
  await database.open();
  final db = database.database;
  await db.insert('inventory_floors', {
    'id': _supersededFloorTwo,
    'project_id': _projectA,
    'ordinal': 2,
    'display_name': 'Bodrum Kat',
    'revision': 4,
    'created_at': _t1,
    'updated_at': _t2,
  });
  await db.update(
    'inventory_asset_placements',
    {'ended_at': _t2, 'end_reason': 'MOVED'},
    where: 'id = ?',
    whereArgs: [_placementA],
  );
  await db.insert(
    'inventory_asset_placements',
    _placementRow(
      id: _successorPlacement,
      floorId: _supersededFloorTwo,
      sequence: 2,
      x: 8,
      y: 12,
      createdAt: _t2,
      supersedesPlacementId: _placementA,
    ),
  );
  return database;
}

Future<void> _applySupersededSchemaTwentyOneFixture(
  sqflite.Transaction transaction,
) async {
  await transaction.execute('''
    CREATE TABLE inventory_floors (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      project_id TEXT NOT NULL REFERENCES projects(id),
      ordinal INTEGER NOT NULL CHECK (ordinal BETWEEN 1 AND 100),
      display_name TEXT NOT NULL CHECK (
        length(display_name) BETWEEN 1 AND 80
        AND display_name = trim(display_name)
      ),
      revision INTEGER NOT NULL CHECK (revision >= 1),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      UNIQUE (id, project_id),
      UNIQUE (project_id, ordinal),
      CHECK (updated_at >= created_at)
    )
  ''');
  await transaction.execute('''
    ALTER TABLE inventory_asset_placements
    ADD COLUMN floor_id TEXT REFERENCES inventory_floors(id)
  ''');
  await transaction.execute(
    'DROP TRIGGER inventory_asset_placements_terminal_update',
  );
  final projects = await transaction.rawQuery('''
    SELECT project.id, project.created_at
    FROM projects project
    WHERE project.id IN (
      SELECT project_id FROM inventory_sketches
      UNION
      SELECT project_id FROM inventory_asset_placements
    )
    ORDER BY project.id ASC
  ''');
  for (final project in projects) {
    final projectId = project['id']! as String;
    final floorId = _stableMigrationUuid('inventory-floor-v1:$projectId');
    await transaction.insert('inventory_floors', {
      'id': floorId,
      'project_id': projectId,
      'ordinal': 1,
      'display_name': '1. Kat',
      'revision': 1,
      'created_at': project['created_at'],
      'updated_at': project['created_at'],
    });
    await transaction.update(
      'inventory_asset_placements',
      {'floor_id': floorId},
      where: 'project_id = ? AND floor_id IS NULL',
      whereArgs: [projectId],
    );
  }
  await transaction.execute('''
    CREATE INDEX ix_inventory_asset_placements_floor_map
    ON inventory_asset_placements(
      project_id, floor_id, sketch_id, ended_at, y, x, id
    )
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_floors_project
    ON inventory_floors(project_id, ordinal, id)
  ''');
  await _addSupersededFloorTimestampGuards(transaction);
  await transaction.execute('''
    CREATE TRIGGER inventory_floors_project_available_insert
    BEFORE INSERT ON inventory_floors
    WHEN NOT EXISTS (
      SELECT 1 FROM projects project
      WHERE project.id = NEW.project_id AND project.archived_at IS NULL
    )
    BEGIN
      SELECT RAISE(ABORT, 'inventory project is unavailable');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_floors_project_available_update
    BEFORE UPDATE ON inventory_floors
    WHEN NOT EXISTS (
      SELECT 1 FROM projects project
      WHERE project.id = NEW.project_id AND project.archived_at IS NULL
    )
    BEGIN
      SELECT RAISE(ABORT, 'inventory project is unavailable');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_floors_contiguous_insert
    BEFORE INSERT ON inventory_floors
    WHEN NEW.ordinal != (
      SELECT COALESCE(MAX(floor.ordinal), 0) + 1
      FROM inventory_floors floor
      WHERE floor.project_id = NEW.project_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'inventory floor ordinal is not contiguous');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_floors_guarded_update
    BEFORE UPDATE ON inventory_floors
    BEGIN
      SELECT CASE
        WHEN NEW.id != OLD.id
          OR NEW.project_id != OLD.project_id
          OR NEW.ordinal != OLD.ordinal
          OR NEW.created_at != OLD.created_at
        THEN RAISE(ABORT, 'inventory floor identity is immutable')
      END;
      SELECT CASE
        WHEN NEW.revision != OLD.revision + 1
        THEN RAISE(ABORT, 'inventory floor revision mismatch')
      END;
      SELECT CASE
        WHEN NEW.updated_at < OLD.updated_at
        THEN RAISE(ABORT, 'inventory floor timestamp regression')
      END;
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_floors_no_physical_delete
    BEFORE DELETE ON inventory_floors
    BEGIN
      SELECT RAISE(ABORT, 'inventory source cannot be physically deleted');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_asset_placements_floor_insert
    BEFORE INSERT ON inventory_asset_placements
    WHEN NEW.floor_id IS NULL OR NOT EXISTS (
      SELECT 1 FROM inventory_floors floor
      WHERE floor.id = NEW.floor_id AND floor.project_id = NEW.project_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'inventory placement floor is invalid');
    END
  ''');
  await _createSupersededPlacementTerminalTrigger(transaction);
}

Future<void> _addSupersededFloorTimestampGuards(
  sqflite.DatabaseExecutor database,
) async {
  for (final column in const ['created_at', 'updated_at']) {
    for (final operation in const ['insert', 'update']) {
      final action = operation == 'insert' ? 'INSERT' : 'UPDATE OF $column';
      await database.execute('''
        CREATE TRIGGER inventory_floors_${column}_canonical_$operation
        BEFORE $action ON inventory_floors
        WHEN NEW.$column IS NOT NULL AND (
          length(NEW.$column) != 20
          OR NEW.$column NOT GLOB
            '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
          OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.$column, '+0 seconds')
            IS NULL
          OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.$column, '+0 seconds')
            != NEW.$column
        )
        BEGIN
          SELECT RAISE(ABORT, 'inventory timestamp must be canonical UTC');
        END
      ''');
    }
  }
}

Future<void> _createSupersededPlacementTerminalTrigger(
  sqflite.DatabaseExecutor database,
) => database.execute('''
  CREATE TRIGGER inventory_asset_placements_terminal_update
  BEFORE UPDATE ON inventory_asset_placements
  BEGIN
    SELECT CASE
      WHEN NEW.id != OLD.id
        OR NEW.placement_key != OLD.placement_key
        OR NEW.project_id != OLD.project_id
        OR NEW.asset_id != OLD.asset_id
        OR NEW.sketch_id != OLD.sketch_id
        OR NEW.floor_id IS NOT OLD.floor_id
        OR NEW.provenance_revision_id != OLD.provenance_revision_id
        OR NEW.sequence != OLD.sequence
        OR NEW.x != OLD.x
        OR NEW.y != OLD.y
        OR NEW.quantity != OLD.quantity
        OR NEW.created_at != OLD.created_at
        OR NEW.supersedes_placement_id IS NOT OLD.supersedes_placement_id
      THEN RAISE(ABORT, 'inventory placement source is immutable')
    END;
    SELECT CASE
      WHEN OLD.ended_at IS NOT NULL
        OR OLD.end_reason IS NOT NULL
        OR NEW.ended_at IS NULL
        OR NEW.end_reason IS NULL
      THEN RAISE(ABORT, 'inventory placement terminal transition is invalid')
    END;
  END
''');

Future<void> _seedProjects(sqflite.Database database) async {
  for (final item in const [
    (_projectA, 'Project A'),
    (_projectB, 'Project B'),
  ]) {
    await database.insert('projects', {
      'id': item.$1,
      'name': item.$2,
      'created_at': _t0,
      'updated_at': _t0,
      'revision': 1,
    });
  }
}

Future<Map<String, Object>> _seedValidInventoryGraph(
  sqflite.Database database, {
  bool spatial = true,
}) async {
  final geometry = InventoryGeometry(
    polylines: [
      InventoryPolyline(
        closed: false,
        points: [
          InventorySketchPoint(x: 0, y: 0),
          InventorySketchPoint(x: 64, y: 64),
        ],
      ),
    ],
  );
  await database.insert('inventory_sketches', _sketchRow());
  await database.insert(
    'inventory_sketch_revisions',
    _revisionRow(
      geometryJson: geometry.canonicalJson,
      geometrySha256: geometry.sha256,
    ),
  );
  await database.update(
    'inventory_sketch_revisions',
    {'state': 'ACTIVE', 'updated_at': _t1, 'finalized_at': _t1},
    where: 'id = ?',
    whereArgs: [_revisionA],
  );
  await database.update(
    'inventory_sketches',
    {'active_revision_id': _revisionA, 'revision': 2, 'updated_at': _t1},
    where: 'id = ?',
    whereArgs: [_sketchA],
  );
  if (spatial) {
    await database.insert('inventory_blocks', _blockRow());
    await database.insert('inventory_floors', _floorRow());
  }
  await database.insert('inventory_assets', _assetRow());
  final placement = _placementRow();
  if (!spatial) placement.remove('floor_id');
  await database.insert('inventory_asset_placements', placement);
  await database.insert('managed_attachments', {
    'id': _attachmentA,
    'relative_path': 'managed/inventory-photo.jpg',
    'mime_type': 'image/jpeg',
    'byte_size': 11,
    'sha256': _digest,
    'created_at': _t0,
  });
  await database.insert('inventory_asset_attachment_links', _photoLinkRow());
  await database.insert('inventory_command_receipts', _receiptRow());
  await database.insert('inventory_events', _eventRow());
  return {
    'geometry_json': geometry.canonicalJson,
    'geometry_sha256': geometry.sha256,
  };
}

Future<void> _expectCrossProjectFailures(
  sqflite.Database database,
  Map<String, Object> graph,
) async {
  await _fails(
    database.insert(
      'inventory_sketch_revisions',
      _revisionRow(
        id: 'cross-project-revision',
        projectId: _projectB,
        revisionNumber: 2,
        geometryJson: graph['geometry_json']! as String,
        geometrySha256: graph['geometry_sha256']! as String,
      ),
    ),
  );
  await _fails(
    database.insert(
      'inventory_asset_placements',
      _placementRow(
        id: 'cross-project-placement',
        placementKey: 'cross-project-placement-key',
        projectId: _projectB,
      ),
    ),
  );
  await _fails(
    database.insert(
      'inventory_asset_attachment_links',
      _photoLinkRow(id: 'cross-project-photo-link', projectId: _projectB),
    ),
  );
  await _fails(
    database.update(
      'inventory_sketches',
      {
        'active_revision_id': 'missing-other-project-revision',
        'revision': 3,
        'updated_at': _t2,
      },
      where: 'id = ?',
      whereArgs: [_sketchA],
    ),
  );
}

Future<void> _expectPartialUniquenessFailures(
  sqflite.Database database,
  Map<String, Object> graph,
) async {
  await _fails(
    database.insert(
      'inventory_sketches',
      _sketchRow(id: 'second-primary-sketch'),
    ),
  );
  await database.insert(
    'inventory_sketch_revisions',
    _revisionRow(
      id: 'draft-revision-2',
      revisionNumber: 2,
      baseRevisionId: _revisionA,
      createdAt: _t2,
      updatedAt: _t2,
      geometryJson: graph['geometry_json']! as String,
      geometrySha256: graph['geometry_sha256']! as String,
    ),
  );
  await _fails(
    database.insert(
      'inventory_sketch_revisions',
      _revisionRow(
        id: 'second-draft-revision',
        revisionNumber: 3,
        baseRevisionId: _revisionA,
        createdAt: _t2,
        updatedAt: _t2,
        geometryJson: graph['geometry_json']! as String,
        geometrySha256: graph['geometry_sha256']! as String,
      ),
    ),
  );
  await _fails(
    database.update(
      'inventory_sketch_revisions',
      {'state': 'ACTIVE', 'updated_at': _t2, 'finalized_at': _t2},
      where: 'id = ?',
      whereArgs: ['draft-revision-2'],
    ),
  );
  await _fails(
    database.insert(
      'inventory_asset_placements',
      _placementRow(id: 'duplicate-active-placement'),
    ),
  );
  await _fails(
    database.insert(
      'inventory_asset_attachment_links',
      _photoLinkRow(id: 'duplicate-active-photo-link'),
    ),
  );
}

Future<void> _expectVocabularyAndCheckFailures(
  sqflite.Database database,
  Map<String, Object> graph,
) async {
  final invalidCategory = _assetRow(id: 'invalid-category')
    ..['category_code'] = 'STOCK';
  await _fails(database.insert('inventory_assets', invalidCategory));

  final invalidStatus = _assetRow(id: 'invalid-status')
    ..['status'] = 'ARCHIVED';
  await _fails(database.insert('inventory_assets', invalidStatus));

  final invalidTimestamp = _assetRow(id: 'invalid-timestamp')
    ..['created_at'] = '2026-08-27 04:00:00';
  await _fails(database.insert('inventory_assets', invalidTimestamp));

  final invalidReceipt = _receiptRow(id: 'invalid-command-receipt')
    ..['command_type'] = 'inventory_unknown';
  await _fails(database.insert('inventory_command_receipts', invalidReceipt));

  final invalidHash = _receiptRow(id: 'invalid-hash-receipt')
    ..['intent_sha256'] = 'A' * 64;
  await _fails(database.insert('inventory_command_receipts', invalidHash));

  final invalidEvent = _eventRow(
    id: 'invalid-event',
    operationId: 'missing-invalid-event-receipt',
  )..['event_type'] = 'inventory.asset_deleted';
  await _fails(database.insert('inventory_events', invalidEvent));

  final invalidState = _revisionRow(
    id: 'invalid-state-revision',
    revisionNumber: 3,
    baseRevisionId: _revisionA,
    state: 'ACTIVE',
    createdAt: _t2,
    updatedAt: _t2,
    geometryJson: graph['geometry_json']! as String,
    geometrySha256: graph['geometry_sha256']! as String,
  )..['finalized_at'] = _t2;
  await _fails(database.insert('inventory_sketch_revisions', invalidState));

  final invalidCoordinate = _placementRow(
    id: 'invalid-coordinate-placement',
    placementKey: 'invalid-coordinate-key',
  )..['x'] = 2;
  await _fails(
    database.insert('inventory_asset_placements', invalidCoordinate),
  );

  final invalidQuantity = _placementRow(
    id: 'invalid-quantity-placement',
    placementKey: 'invalid-quantity-key',
  )..['quantity'] = 0;
  await _fails(database.insert('inventory_asset_placements', invalidQuantity));

  final invalidEndReason =
      _placementRow(
          id: 'invalid-end-reason-placement',
          placementKey: 'invalid-end-reason-key',
        )
        ..['ended_at'] = _t2
        ..['end_reason'] = 'DELETED';
  await _fails(database.insert('inventory_asset_placements', invalidEndReason));
}

Future<void> _expectImmutabilityAndAppendOnlyFailures(
  sqflite.Database database,
  Map<String, Object> graph,
) async {
  await _fails(
    database.update(
      'inventory_sketch_revisions',
      {
        'geometry_json':
            '{"canvas_height":3072,"canvas_width":4096,'
            '"geometry_version":1,"polylines":[]}',
        'geometry_sha256':
            'bd23cac9d6ab5b9c8aafff69496a31ed'
            '588cffd2761edf7a27208432c81a121a',
        'content_revision': 2,
        'updated_at': _t2,
        'finalized_at': _t2,
      },
      where: 'id = ?',
      whereArgs: [_revisionA],
    ),
  );
  await _fails(
    database.update(
      'inventory_asset_placements',
      {'x': 4},
      where: 'id = ?',
      whereArgs: [_placementA],
    ),
  );
  await _fails(
    database.update(
      'inventory_assets',
      {'project_id': _projectB, 'revision': 2, 'updated_at': _t2},
      where: 'id = ?',
      whereArgs: [_assetA],
    ),
  );
  await _fails(
    database.update(
      'inventory_asset_attachment_links',
      {'attachment_id': 'other-attachment', 'revision': 2, 'updated_at': _t2},
      where: 'id = ?',
      whereArgs: [_photoLinkA],
    ),
  );
  await _fails(
    database.update(
      'inventory_command_receipts',
      {'result_json': '{"changed":true}'},
      where: 'id = ?',
      whereArgs: [_receiptA],
    ),
  );
  await _fails(
    database.update(
      'inventory_events',
      {'payload_json': '{"changed":true}'},
      where: 'id = ?',
      whereArgs: [_eventA],
    ),
  );
  await _fails(
    database.transaction((transaction) async {
      await transaction.insert(
        'inventory_command_receipts',
        _receiptRow(id: 'gap-sequence-receipt'),
      );
      await transaction.insert(
        'inventory_events',
        _eventRow(
          id: 'gap-sequence-event',
          operationId: 'gap-sequence-receipt',
          sequence: 3,
        ),
      );
      return null;
    }),
  );
  for (final target in const [
    ('inventory_events', _eventA),
    ('inventory_command_receipts', _receiptA),
    ('inventory_asset_attachment_links', _photoLinkA),
    ('inventory_asset_placements', _placementA),
    ('inventory_assets', _assetA),
    ('inventory_sketch_revisions', _revisionA),
    ('inventory_sketches', _sketchA),
  ]) {
    await _fails(
      database.delete(target.$1, where: 'id = ?', whereArgs: [target.$2]),
    );
  }
}

Future<void> _expectPlacementHistoryAndQuantityFailures(
  sqflite.Database database,
  Map<String, Object> graph,
) async {
  await database.update(
    'inventory_asset_placements',
    {'ended_at': _t2, 'end_reason': 'MOVED'},
    where: 'id = ?',
    whereArgs: [_placementA],
  );
  await database.insert(
    'inventory_asset_placements',
    _placementRow(
      id: 'successor-placement',
      sequence: 2,
      x: 4,
      y: 4,
      supersedesPlacementId: _placementA,
      createdAt: _t2,
    ),
  );
  await _fails(
    database.insert(
      'inventory_asset_placements',
      _placementRow(
        id: 'branch-placement',
        sequence: 2,
        x: 8,
        y: 8,
        supersedesPlacementId: _placementA,
        createdAt: _t2,
      ),
    ),
  );
  await _fails(
    database.insert(
      'inventory_asset_placements',
      _placementRow(
        id: 'quantity-overflow-placement',
        placementKey: 'quantity-overflow-key',
        quantity: 1,
        createdAt: _t2,
      ),
    ),
  );
  await _fails(
    database.update(
      'inventory_assets',
      {'total_quantity': 4, 'revision': 2, 'updated_at': _t2},
      where: 'id = ?',
      whereArgs: [_assetA],
    ),
  );
}

Map<String, Object?> _sketchRow({
  String id = _sketchA,
  String projectId = _projectA,
  int isPrimary = 1,
}) => {
  'id': id,
  'project_id': projectId,
  'display_name': 'Site sketch',
  'is_primary': isPrimary,
  'active_revision_id': null,
  'draft_revision_id': null,
  'revision': 1,
  'created_at': _t0,
  'updated_at': _t0,
  'archived_at': null,
};

Map<String, Object?> _revisionRow({
  String id = _revisionA,
  String sketchId = _sketchA,
  String projectId = _projectA,
  int revisionNumber = 1,
  String? baseRevisionId,
  String state = 'DRAFT',
  String? geometryJson,
  String? geometrySha256,
  String createdAt = _t0,
  String updatedAt = _t0,
}) => {
  'id': id,
  'sketch_id': sketchId,
  'project_id': projectId,
  'revision_number': revisionNumber,
  'base_revision_id': baseRevisionId,
  'state': state,
  'geometry_version': 1,
  'canvas_width': 4096,
  'canvas_height': 3072,
  'geometry_json':
      geometryJson ??
      '{"canvas_height":3072,"canvas_width":4096,'
          '"geometry_version":1,"polylines":[]}',
  'geometry_sha256':
      geometrySha256 ??
      'bd23cac9d6ab5b9c8aafff69496a31ed'
          '588cffd2761edf7a27208432c81a121a',
  'content_revision': 1,
  'created_at': createdAt,
  'updated_at': updatedAt,
  'finalized_at': null,
  'superseded_at': null,
  'abandoned_at': null,
};

Map<String, Object?> _assetRow({
  String id = _assetA,
  String projectId = _projectA,
}) => {
  'id': id,
  'project_id': projectId,
  'display_name': 'Tower crane',
  'normalized_name': 'tower crane',
  'category_code': 'EQUIPMENT',
  'other_category_label': null,
  'total_quantity': 5,
  'status': 'AVAILABLE',
  'note': 'Synthetic fixture',
  'revision': 1,
  'created_at': _t0,
  'updated_at': _t0,
  'status_changed_at': _t0,
  'archived_at': null,
};

Map<String, Object?> _blockRow({
  String id = _blockA,
  String projectId = _projectA,
}) => {
  'id': id,
  'project_id': projectId,
  'display_name': 'Varsayılan Alan',
  'normalized_name': 'varsayılan alan',
  'ordinal': 1,
  'state': 'DETACHED',
  'revision': 1,
  'created_at': _t0,
  'updated_at': _t0,
  'archived_at': null,
};

Map<String, Object?> _floorRow({
  String id = _floorA,
  String blockId = _blockA,
  String projectId = _projectA,
}) => {
  'id': id,
  'block_id': blockId,
  'project_id': projectId,
  'display_name': '1. Kat',
  'ordinal': 1,
  'revision': 1,
  'created_at': _t0,
  'updated_at': _t0,
  'archived_at': null,
};

Map<String, Object?> _placementRow({
  String id = _placementA,
  String placementKey = _placementKeyA,
  String projectId = _projectA,
  String assetId = _assetA,
  String sketchId = _sketchA,
  String floorId = _floorA,
  String provenanceRevisionId = _revisionA,
  int sequence = 1,
  int x = 0,
  int y = 0,
  int quantity = 5,
  String createdAt = _t1,
  String? supersedesPlacementId,
}) => {
  'id': id,
  'placement_key': placementKey,
  'project_id': projectId,
  'asset_id': assetId,
  'sketch_id': sketchId,
  'floor_id': floorId,
  'provenance_revision_id': provenanceRevisionId,
  'sequence': sequence,
  'x': x,
  'y': y,
  'quantity': quantity,
  'created_at': createdAt,
  'ended_at': null,
  'end_reason': null,
  'supersedes_placement_id': supersedesPlacementId,
};

Map<String, Object?> _photoLinkRow({
  String id = _photoLinkA,
  String projectId = _projectA,
}) => {
  'id': id,
  'attachment_id': _attachmentA,
  'asset_id': _assetA,
  'project_id': projectId,
  'role': 'inventory_photo',
  'original_file_name': 'inventory-photo.jpg',
  'description': 'Synthetic photo relation',
  'revision': 1,
  'created_at': _t1,
  'updated_at': _t1,
  'archived_at': null,
};

Map<String, Object?> _receiptRow({String id = _receiptA}) => {
  'id': id,
  'project_id': _projectA,
  'command_type': 'sketch_create',
  'primary_aggregate_type': 'sketch',
  'primary_aggregate_id': _sketchA,
  'intent_sha256': _digest,
  'result_json': '{"sketch_id":"$_sketchA"}',
  'result_sha256': _digest,
  'is_no_op': 0,
  'event_count': 1,
  'created_at': _t1,
};

Map<String, Object?> _eventRow({
  String id = _eventA,
  String operationId = _receiptA,
  int sequence = 1,
}) => {
  'id': id,
  'operation_id': operationId,
  'project_id': _projectA,
  'aggregate_type': 'sketch',
  'aggregate_id': _sketchA,
  'sequence': sequence,
  'event_type': 'inventory.sketch_created',
  'occurred_at': _t1,
  'payload_json': '{"sketch_id":"$_sketchA"}',
  'payload_sha256': _digest,
};

Future<Set<String>> _objectNames(
  sqflite.Database database, {
  required String type,
  required String prefix,
  bool names = false,
}) async {
  final filterColumn = names ? 'tbl_name' : 'name';
  final rows = await database.rawQuery(
    'SELECT name FROM sqlite_master '
    'WHERE type = ? AND $filterColumn LIKE ?',
    [type, '$prefix%'],
  );
  return rows.map((row) => row['name']! as String).toSet();
}

Future<List<Map<String, Object?>>> _existingObjects(
  sqflite.Database database,
) => database.rawQuery('''
      SELECT type, name, tbl_name, sql
      FROM sqlite_master
      WHERE sql IS NOT NULL
        AND tbl_name NOT LIKE 'inventory_%'
      ORDER BY type, name
    ''');

Future<Map<String, List<Map<String, Object?>>>> _representativeRows(
  sqflite.Database database,
) async {
  final result = <String, List<Map<String, Object?>>>{};
  for (final table in const [
    'projects',
    'field_observations',
    'managed_attachments',
  ]) {
    result[table] = await database.query(table, orderBy: 'id ASC');
  }
  return result;
}

Future<Map<String, List<Map<String, Object?>>>> _inventoryV20Snapshot(
  sqflite.Database database,
) async {
  final result = <String, List<Map<String, Object?>>>{};
  for (final table in const [
    'inventory_sketches',
    'inventory_sketch_revisions',
    'inventory_assets',
    'inventory_asset_placements',
    'inventory_command_receipts',
    'inventory_events',
    'inventory_asset_attachment_links',
  ]) {
    final rows = await database.query(table, orderBy: 'id ASC');
    result[table] = [
      for (final row in rows)
        {
          for (final entry in row.entries)
            if (entry.key != 'floor_id') entry.key: entry.value,
        },
    ];
  }
  return result;
}

Future<Map<String, List<Map<String, Object?>>>> _finalInventorySnapshot(
  sqflite.Database database,
) async {
  const ordering = <String, String>{
    'inventory_sketches': 'id ASC',
    'inventory_sketch_revisions': 'id ASC',
    'inventory_blocks': 'id ASC',
    'inventory_floors': 'id ASC',
    'inventory_sketch_revision_block_polygons': 'revision_id ASC, block_id ASC',
    'inventory_sketch_revision_spatial_drafts':
        'revision_id ASC, content_revision ASC',
    'inventory_assets': 'id ASC',
    'inventory_asset_placements': 'id ASC',
    'inventory_command_receipts': 'id ASC',
    'inventory_events': 'id ASC',
    'inventory_asset_attachment_links': 'id ASC',
    'managed_attachments': 'id ASC',
  };
  return {
    for (final entry in ordering.entries)
      entry.key: await database.query(entry.key, orderBy: entry.value),
  };
}

Future<Map<String, List<Map<String, Object?>>>> _supersededPreservedSnapshot(
  sqflite.Database database,
) async {
  const tables = <String, String>{
    'inventory_sketches': 'id ASC',
    'inventory_sketch_revisions': 'id ASC',
    'inventory_assets': 'id ASC',
    'inventory_asset_placements': 'id ASC',
    'inventory_command_receipts': 'id ASC',
    'inventory_events': 'id ASC',
    'inventory_asset_attachment_links': 'id ASC',
    'managed_attachments': 'id ASC',
  };
  return {
    'inventory_floors': await database.query(
      'inventory_floors',
      columns: const [
        'id',
        'project_id',
        'ordinal',
        'display_name',
        'revision',
        'created_at',
        'updated_at',
      ],
      orderBy: 'id ASC',
    ),
    for (final entry in tables.entries)
      entry.key: await database.query(entry.key, orderBy: entry.value),
  };
}

Future<List<Map<String, Object?>>> _inventorySchemaObjects(
  sqflite.Database database,
) => database.rawQuery('''
  SELECT type, name, tbl_name, sql
  FROM sqlite_master
  WHERE sql IS NOT NULL
    AND (name LIKE 'inventory_%' OR tbl_name LIKE 'inventory_%')
  ORDER BY type ASC, name ASC
''');

Future<Set<String>> _tableColumnsForTest(
  sqflite.Database database,
  String table,
) async => (await database.rawQuery(
  'PRAGMA table_info($table)',
)).map((row) => row['name']! as String).toSet();

String _stableMigrationUuid(String seed) {
  int hash(String value, int salt) {
    var result = (2166136261 ^ salt) & 0xffffffff;
    for (final unit in value.codeUnits) {
      result ^= unit;
      result = (result * 16777619) & 0xffffffff;
    }
    return result;
  }

  final raw = List.generate(
    4,
    (index) =>
        hash(seed, 0x9e3779b9 * (index + 1)).toRadixString(16).padLeft(8, '0'),
  ).join();
  final chars = raw.split('');
  chars[12] = '4';
  chars[16] = '8';
  final value = chars.join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

Future<void> _fails(Future<Object?> operation) =>
    expectLater(operation, throwsA(isA<sqflite.DatabaseException>()));
