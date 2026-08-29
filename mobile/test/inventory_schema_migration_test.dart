import 'dart:io';

import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _projectB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _sketchA = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _floorA = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
const _revisionA = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const _assetA = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';
const _placementA = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1';
const _placementKeyA = 'ffffffff-ffff-4fff-8fff-fffffffffff1';
const _attachmentA = '11111111-1111-4111-8111-111111111111';
const _photoLinkA = '22222222-2222-4222-8222-222222222222';
const _receiptA = '33333333-3333-4333-8333-333333333333';
const _eventA = '44444444-4444-4444-8444-444444444444';
const _t0 = '2026-08-27T04:00:00Z';
const _t1 = '2026-08-27T05:00:00Z';
const _t2 = '2026-08-27T06:00:00Z';
const _digest =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

const _inventoryTables = <String>{
  'inventory_floors',
  'inventory_sketches',
  'inventory_sketch_revisions',
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
  'ix_inventory_asset_placements_floor_map',
  'ix_inventory_floors_project',
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
    'fresh database creates exact schema 21 Inventory tables and indices',
    () async {
      final database = _database(databasePath);
      await database.open();
      final db = database.database;

      expect(
        sqflite.Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')),
        21,
      );
      expect(
        (await db.query(
          'schema_versions',
          columns: ['version'],
          orderBy: 'version ASC',
        )).map((row) => row['version']),
        List.generate(21, (index) => index + 1),
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
      final afterObjects = await _existingObjects(db);
      final afterRows = await _representativeRows(db);

      expect(afterObjects, beforeObjects);
      expect(afterRows, beforeRows);
      expect(
        sqflite.Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')),
        21,
      );
      for (final table in _inventoryTables) {
        expect(await db.query(table), isEmpty, reason: table);
      }
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await upgraded.close();

      final rollbackPath = path.join(temporaryRoot.path, 'rollback.sqlite3');
      final rollbackSchema = await _openSeededSchemaNineteen(rollbackPath);
      final rollbackRows = await _representativeRows(rollbackSchema.database);
      await rollbackSchema.close();
      final failing = _database(
        rollbackPath,
        migrations: [
          ...AppDatabase.foundationMigrations.take(19),
          DatabaseMigration(
            version: 20,
            apply: (transaction) async {
              await AppDatabase.foundationMigrations[19].apply(transaction);
              throw StateError('forced inventory schema 20 failure');
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
        19,
      );
      expect(
        await _objectNames(afterFailure, type: 'table', prefix: 'inventory_'),
        isEmpty,
      );
      expect(
        await afterFailure.query('schema_versions', where: 'version = 20'),
        isEmpty,
      );
      expect(await _representativeRows(afterFailure), rollbackRows);
      expect(
        (await afterFailure.query(
          'projects',
          where: 'id = ?',
          whereArgs: [_projectA],
        )).single['name'],
        'Inventory migration project',
      );
      await afterFailure.close();
    },
  );

  test(
    'schema 20 to 21 backfill is deterministic and preserves Inventory graph',
    () async {
      final upgradePath = path.join(temporaryRoot.path, 'schema20.sqlite3');
      final schemaTwenty = _database(
        upgradePath,
        migrations: AppDatabase.foundationMigrations.take(20).toList(),
      );
      await schemaTwenty.open();
      final source = schemaTwenty.database;
      await _seedProjects(source);
      await _seedValidInventoryGraph(source, schemaTwenty: true);
      await source.update(
        'inventory_asset_placements',
        {'ended_at': _t2, 'end_reason': 'MOVED'},
        where: 'id = ?',
        whereArgs: [_placementA],
      );
      await source.insert(
        'inventory_asset_placements',
        _placementRow(
          id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee2',
          sequence: 2,
          x: 4,
          y: 4,
          supersedesPlacementId: _placementA,
          createdAt: _t2,
          includeFloor: false,
        ),
      );
      final before = await _inventoryPreservationRows(source);
      await schemaTwenty.close();

      final upgraded = _database(upgradePath);
      await upgraded.open();
      final db = upgraded.database;
      final after = await _inventoryPreservationRows(db, stripFloorId: true);
      expect(after, before);
      final floors = await db.query('inventory_floors');
      expect(floors, hasLength(1));
      expect(floors.single, {
        'id': _stableUuid('inventory-floor-v1:$_projectA'),
        'project_id': _projectA,
        'ordinal': 1,
        'display_name': '1. Kat',
        'revision': 1,
        'created_at': _t0,
        'updated_at': _t0,
      });
      final placements = await db.query(
        'inventory_asset_placements',
        orderBy: 'sequence ASC',
      );
      expect(placements, hasLength(2));
      expect(placements.map((row) => row['floor_id']).toSet(), {
        _stableUuid('inventory-floor-v1:$_projectA'),
      });
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await upgraded.close();

      final rollbackPath = path.join(
        temporaryRoot.path,
        'schema21-rollback.sqlite3',
      );
      final rollbackSource = _database(
        rollbackPath,
        migrations: AppDatabase.foundationMigrations.take(20).toList(),
      );
      await rollbackSource.open();
      await _seedProjects(rollbackSource.database);
      await _seedValidInventoryGraph(
        rollbackSource.database,
        schemaTwenty: true,
      );
      final rollbackBefore = await _inventoryPreservationRows(
        rollbackSource.database,
      );
      await rollbackSource.close();
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
        await _objectNames(
          afterFailure,
          type: 'table',
          prefix: 'inventory_floors',
        ),
        isEmpty,
      );
      expect(await _inventoryPreservationRows(afterFailure), rollbackBefore);
      await afterFailure.close();
    },
  );

  test(
    'schema 21 fails closed and retains one valid populated graph',
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
      expect(await db.query('inventory_floors'), hasLength(1));
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
  bool schemaTwenty = false,
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
  if (!schemaTwenty) {
    await database.insert('inventory_floors', _floorRow());
  }
  await database.insert('inventory_assets', _assetRow());
  await database.insert(
    'inventory_asset_placements',
    _placementRow(includeFloor: !schemaTwenty),
  );
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

Map<String, Object?> _placementRow({
  String id = _placementA,
  String placementKey = _placementKeyA,
  String projectId = _projectA,
  String assetId = _assetA,
  String sketchId = _sketchA,
  String provenanceRevisionId = _revisionA,
  int sequence = 1,
  int x = 0,
  int y = 0,
  int quantity = 5,
  String createdAt = _t1,
  String? supersedesPlacementId,
  bool includeFloor = true,
}) => {
  'id': id,
  'placement_key': placementKey,
  'project_id': projectId,
  'asset_id': assetId,
  'sketch_id': sketchId,
  if (includeFloor) 'floor_id': _floorA,
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

Map<String, Object?> _floorRow({
  String id = _floorA,
  String projectId = _projectA,
  int ordinal = 1,
  String displayName = '1. Kat',
}) => {
  'id': id,
  'project_id': projectId,
  'ordinal': ordinal,
  'display_name': displayName,
  'revision': 1,
  'created_at': _t0,
  'updated_at': _t0,
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

Future<void> _fails(Future<Object?> operation) =>
    expectLater(operation, throwsA(isA<sqflite.DatabaseException>()));

Future<Map<String, List<Map<String, Object?>>>> _inventoryPreservationRows(
  sqflite.Database database, {
  bool stripFloorId = false,
}) async {
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
    result[table] = rows
        .map((row) {
          final copy = Map<String, Object?>.from(row);
          if (stripFloorId && table == 'inventory_asset_placements') {
            copy.remove('floor_id');
          }
          return copy;
        })
        .toList(growable: false);
  }
  return result;
}

String _stableUuid(String seed) {
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
