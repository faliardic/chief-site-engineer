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
const _projectArchived = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3';
const _t0 = '2026-08-27T04:00:00Z';

void main() {
  setUpAll(sqfliteFfiInit);

  test('receipt replay, conflict, corruption, no-op, and rollback', () async {
    final fixture = await _Fixture.create('receipt');
    addTearDown(fixture.close);
    final sketch = await _createFinalizedSketch(fixture, seed: 100);
    final create = CreateInventoryAssetCommand(
      operationId: _uuid(110),
      projectId: _projectA,
      assetId: _uuid(111),
      placementId: _uuid(112),
      placementKey: _uuid(113),
      sketchId: sketch.sketchId,
      activeRevisionId: sketch.activeRevisionId,
      displayName: 'Vibratör',
      category: InventoryCategory.equipment,
      totalQuantity: 2,
      x: 17,
      y: 21,
    );
    final first = await fixture.app.createAsset(create);
    final before = await _counts(fixture.db.database);
    final replay = await fixture.app.createAsset(create);
    expect(_resultValues(replay), _resultValues(first));
    expect(await _counts(fixture.db.database), before);

    await expectLater(
      fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: create.operationId,
          projectId: _projectA,
          assetId: create.assetId,
          placementId: create.placementId,
          placementKey: create.placementKey,
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          displayName: 'Farklı',
          category: InventoryCategory.equipment,
          totalQuantity: 2,
          x: 17,
          y: 21,
        ),
      ),
      _fails('inventory_operation_id_conflict'),
    );
    expect(await _counts(fixture.db.database), before);

    final noOp = UpdateInventoryAssetCommand(
      operationId: _uuid(114),
      projectId: _projectA,
      assetId: create.assetId,
      expectedAssetRevision: 1,
      displayName: 'Vibratör',
      category: InventoryCategory.equipment,
    );
    final noOpResult = await fixture.app.updateAsset(noOp);
    expect(noOpResult.isNoOp, isTrue);
    expect(noOpResult.eventCount, 0);
    expect(
      (await fixture.db.database.query(
        'inventory_command_receipts',
        where: 'id = ?',
        whereArgs: [noOp.operationId],
      )).single,
      containsPair('is_no_op', 1),
    );
    expect(
      await fixture.db.database.query(
        'inventory_events',
        where: 'operation_id = ?',
        whereArgs: [noOp.operationId],
      ),
      isEmpty,
    );

    await fixture.db.database.insert('inventory_command_receipts', {
      'id': _uuid(115),
      'project_id': _projectA,
      'command_type': InventoryCommandType.assetUpdate.storageValue,
      'primary_aggregate_type': InventoryAggregateType.asset.storageValue,
      'primary_aggregate_id': create.assetId,
      'intent_sha256': 'a'.padRight(64, 'a'),
      'result_json': '{}',
      'result_sha256': 'b'.padRight(64, 'b'),
      'is_no_op': 1,
      'event_count': 0,
      'created_at': _t0,
    });
    await expectLater(
      fixture.app.updateAsset(
        UpdateInventoryAssetCommand(
          operationId: _uuid(115),
          projectId: _projectA,
          assetId: create.assetId,
          expectedAssetRevision: 1,
          displayName: 'Vibratör',
          category: InventoryCategory.equipment,
        ),
      ),
      _fails('inventory_receipt_corrupt'),
    );

    final failing = InventoryApplication(
      database: fixture.db,
      clock: fixture.clock.call,
      idFactory: fixture.ids.call,
      afterSourceWritesBeforeHistory: () async {
        throw StateError('injected write-boundary failure');
      },
    );
    final countsBeforeFailure = await _counts(fixture.db.database);
    await expectLater(
      failing.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(116),
          projectId: _projectA,
          assetId: _uuid(117),
          placementId: _uuid(118),
          placementKey: _uuid(119),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          displayName: 'Rollback aracı',
          category: InventoryCategory.handTool,
          totalQuantity: 1,
          x: 64,
          y: 64,
        ),
      ),
      _fails('inventory_persistence_failed'),
    );
    expect(await _counts(fixture.db.database), countsBeforeFailure);
    expect(
      await fixture.db.database.query(
        'inventory_assets',
        where: 'id = ?',
        whereArgs: [_uuid(117)],
      ),
      isEmpty,
    );
  });

  test(
    'sketch lifecycle preserves revisions, geometry, and constraints',
    () async {
      final fixture = await _Fixture.create('sketch');
      addTearDown(fixture.close);
      final sketchId = _uuid(200);
      final firstDraft = _uuid(201);
      final created = await fixture.app.createSketch(
        CreateInventorySketchCommand(
          operationId: _uuid(202),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: firstDraft,
        ),
      );
      expect(created.sourceRevision, 1);
      var projection = await fixture.app.loadPrimarySketch(_projectA);
      expect(projection, isNotNull);
      expect(projection!.activeRevision, isNull);
      expect(projection.draftRevision!.geometry.polylines, isEmpty);
      final initialSketchBefore = (await fixture.db.database.query(
        'inventory_sketches',
        where: 'id = ?',
        whereArgs: [sketchId],
      )).single;
      final initialDraftBefore = (await fixture.db.database.query(
        'inventory_sketch_revisions',
        where: 'id = ?',
        whereArgs: [firstDraft],
      )).single;
      final initialCountsBefore = await _counts(fixture.db.database);
      await expectLater(
        fixture.app.abandonSketchDraft(
          AbandonInventorySketchDraftCommand(
            operationId: _uuid(221),
            projectId: _projectA,
            sketchId: sketchId,
            draftRevisionId: firstDraft,
            expectedSketchRevision: 1,
          ),
        ),
        _fails('inventory_sketch_edit_lifecycle_invalid'),
      );
      expect(await _counts(fixture.db.database), initialCountsBefore);
      expect(
        (await fixture.db.database.query(
          'inventory_sketches',
          where: 'id = ?',
          whereArgs: [sketchId],
        )).single,
        initialSketchBefore,
      );
      expect(
        (await fixture.db.database.query(
          'inventory_sketch_revisions',
          where: 'id = ?',
          whereArgs: [firstDraft],
        )).single,
        initialDraftBefore,
      );
      expect(
        await fixture.db.database.query(
          'inventory_command_receipts',
          where: 'id = ?',
          whereArgs: [_uuid(221)],
        ),
        isEmpty,
      );

      final changed = await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(203),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: firstDraft,
          expectedSketchRevision: 1,
          expectedContentRevision: 1,
          geometry: _geometry(),
        ),
      );
      expect(changed.sourceRevision, 2);
      expect(changed.supportingRevision, 2);
      final identical = await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(204),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: firstDraft,
          expectedSketchRevision: 2,
          expectedContentRevision: 2,
          geometry: _geometry(),
        ),
      );
      expect(identical.isNoOp, isTrue);
      expect(identical.eventCount, 0);
      await expectLater(
        fixture.app.autosaveSketchDraft(
          AutosaveInventorySketchDraftCommand(
            operationId: _uuid(205),
            projectId: _projectA,
            sketchId: sketchId,
            draftRevisionId: firstDraft,
            expectedSketchRevision: 1,
            expectedContentRevision: 2,
            geometry: _geometry(64),
          ),
        ),
        _fails('inventory_stale_revision'),
      );
      expect(
        await fixture.db.database.query(
          'inventory_command_receipts',
          where: 'id = ?',
          whereArgs: [_uuid(205)],
        ),
        isEmpty,
      );

      await fixture.app.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _uuid(206),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: firstDraft,
          expectedSketchRevision: 2,
          expectedContentRevision: 2,
        ),
      );
      projection = await fixture.app.loadPrimarySketch(_projectA);
      expect(projection!.activeRevision!.id, firstDraft);
      expect(projection.draftRevision, isNull);

      final secondDraft = _uuid(207);
      await fixture.app.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(208),
          projectId: _projectA,
          sketchId: sketchId,
          activeRevisionId: firstDraft,
          newDraftRevisionId: secondDraft,
          expectedSketchRevision: 3,
        ),
      );
      projection = await fixture.app.loadPrimarySketch(_projectA);
      expect(
        projection!.draftRevision!.geometry.canonicalJson,
        projection.activeRevision!.geometry.canonicalJson,
      );
      expect(projection.draftRevision!.baseRevisionId, firstDraft);
      await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(209),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: secondDraft,
          expectedSketchRevision: 4,
          expectedContentRevision: 1,
          geometry: _geometry(64),
        ),
      );
      await fixture.app.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _uuid(210),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: secondDraft,
          expectedSketchRevision: 5,
          expectedContentRevision: 2,
        ),
      );
      final oldActive = await fixture.db.database.query(
        'inventory_sketch_revisions',
        where: 'id = ?',
        whereArgs: [firstDraft],
      );
      expect(
        oldActive.single['state'],
        InventorySketchRevisionState.superseded.storageValue,
      );

      final abandonedDraft = _uuid(211);
      await fixture.app.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(212),
          projectId: _projectA,
          sketchId: sketchId,
          activeRevisionId: secondDraft,
          newDraftRevisionId: abandonedDraft,
          expectedSketchRevision: 6,
        ),
      );
      projection = await fixture.app.loadPrimarySketch(_projectA);
      expect(projection!.activeRevision!.id, secondDraft);
      expect(projection.draftRevision!.baseRevisionId, secondDraft);
      await fixture.app.abandonSketchDraft(
        AbandonInventorySketchDraftCommand(
          operationId: _uuid(213),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: abandonedDraft,
          expectedSketchRevision: 7,
        ),
      );
      projection = await fixture.app.loadPrimarySketch(_projectA);
      expect(projection!.activeRevision!.id, secondDraft);
      expect(projection.draftRevision, isNull);
      expect(
        (await fixture.db.database.query(
          'inventory_sketch_revisions',
          where: 'id = ?',
          whereArgs: [abandonedDraft],
        )).single['state'],
        InventorySketchRevisionState.abandoned.storageValue,
      );

      await fixture.app.archiveSketch(
        ArchiveInventorySketchCommand(
          operationId: _uuid(214),
          projectId: _projectA,
          sketchId: sketchId,
          expectedSketchRevision: 8,
        ),
      );
      expect(await fixture.app.loadPrimarySketch(_projectA), isNull);
      await fixture.app.unarchiveSketch(
        UnarchiveInventorySketchCommand(
          operationId: _uuid(215),
          projectId: _projectA,
          sketchId: sketchId,
          expectedSketchRevision: 9,
        ),
      );
      expect(
        (await fixture.app.loadPrimarySketch(_projectA))!.sketch.revision,
        10,
      );

      final mismatchedDraft = _uuid(222);
      final mismatchGeometry = _geometry(128);
      final currentSketchRow = (await fixture.db.database.query(
        'inventory_sketches',
        where: 'id = ?',
        whereArgs: [sketchId],
      )).single;
      final mismatchTimestamp = currentSketchRow['updated_at'];
      await fixture.db.database.insert('inventory_sketch_revisions', {
        'id': mismatchedDraft,
        'sketch_id': sketchId,
        'project_id': _projectA,
        'revision_number': 4,
        'base_revision_id': firstDraft,
        'state': InventorySketchRevisionState.draft.storageValue,
        'geometry_version': InventoryGeometryContract.geometryVersion,
        'canvas_width': InventoryGeometryContract.canvasWidth,
        'canvas_height': InventoryGeometryContract.canvasHeight,
        'geometry_json': mismatchGeometry.canonicalJson,
        'geometry_sha256': mismatchGeometry.sha256,
        'content_revision': 1,
        'created_at': mismatchTimestamp,
        'updated_at': mismatchTimestamp,
        'finalized_at': null,
        'superseded_at': null,
        'abandoned_at': null,
      });
      await fixture.db.database.update(
        'inventory_sketches',
        {
          'draft_revision_id': mismatchedDraft,
          'revision': 11,
          'updated_at': mismatchTimestamp,
        },
        where: 'id = ? AND revision = 10',
        whereArgs: [sketchId],
      );
      final mismatchCountsBefore = await _counts(fixture.db.database);
      final mismatchSketchBefore = (await fixture.db.database.query(
        'inventory_sketches',
        where: 'id = ?',
        whereArgs: [sketchId],
      )).single;
      final mismatchDraftBefore = (await fixture.db.database.query(
        'inventory_sketch_revisions',
        where: 'id = ?',
        whereArgs: [mismatchedDraft],
      )).single;
      await expectLater(
        fixture.app.abandonSketchDraft(
          AbandonInventorySketchDraftCommand(
            operationId: _uuid(223),
            projectId: _projectA,
            sketchId: sketchId,
            draftRevisionId: mismatchedDraft,
            expectedSketchRevision: 11,
          ),
        ),
        _fails('inventory_sketch_edit_lifecycle_invalid'),
      );
      expect(await _counts(fixture.db.database), mismatchCountsBefore);
      expect(
        (await fixture.db.database.query(
          'inventory_sketches',
          where: 'id = ?',
          whereArgs: [sketchId],
        )).single,
        mismatchSketchBefore,
      );
      expect(
        (await fixture.db.database.query(
          'inventory_sketch_revisions',
          where: 'id = ?',
          whereArgs: [mismatchedDraft],
        )).single,
        mismatchDraftBefore,
      );
      expect(
        await fixture.db.database.query(
          'inventory_command_receipts',
          where: 'id = ?',
          whereArgs: [_uuid(223)],
        ),
        isEmpty,
      );

      await expectLater(
        fixture.app.startSketchEdit(
          StartInventorySketchEditCommand(
            operationId: _uuid(216),
            projectId: _projectB,
            sketchId: sketchId,
            activeRevisionId: secondDraft,
            newDraftRevisionId: _uuid(217),
            expectedSketchRevision: 10,
          ),
        ),
        _fails('inventory_sketch_unavailable'),
      );
      await expectLater(
        fixture.app.createSketch(
          CreateInventorySketchCommand(
            operationId: _uuid(218),
            projectId: _projectArchived,
            sketchId: _uuid(219),
            draftRevisionId: _uuid(220),
          ),
        ),
        _fails('inventory_project_unavailable'),
      );
    },
  );

  test(
    'asset and placement lifecycle is atomic, versioned, and readable',
    () async {
      final fixture = await _Fixture.create('asset');
      addTearDown(fixture.close);
      final sketch = await _createFinalizedSketch(fixture, seed: 300);
      final assetId = _uuid(310);
      final placementKey = _uuid(311);
      final placement1 = _uuid(312);
      await fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(313),
          projectId: _projectA,
          assetId: assetId,
          placementId: placement1,
          placementKey: placementKey,
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          displayName: '  ISKELE   İĞNE  ',
          category: InventoryCategory.equipment,
          totalQuantity: 2,
          status: InventoryAssetStatus.available,
          x: 17,
          y: 21,
        ),
      );
      final firstProjection = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: assetId,
      );
      expect(firstProjection.asset.displayName, 'ISKELE   İĞNE');
      expect(firstProjection.asset.normalizedName, 'ıskele iğne');
      expect(firstProjection.activePlacement!.x, 16);
      expect(firstProjection.activePlacement!.y, 20);
      expect(firstProjection.activePlacement!.quantity, 2);

      final secondAssetId = _uuid(314);
      await fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(315),
          projectId: _projectA,
          assetId: secondAssetId,
          placementId: _uuid(316),
          placementKey: _uuid(317),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          displayName: 'Akülü Matkap',
          category: InventoryCategory.powerTool,
          totalQuantity: 1,
          x: 128,
          y: 128,
        ),
      );
      expect(
        (await fixture.app.listAssets(
          projectId: _projectA,
        )).map((item) => item.asset.id),
        [secondAssetId, assetId],
      );
      await expectLater(
        fixture.app.archiveSketch(
          ArchiveInventorySketchCommand(
            operationId: _uuid(318),
            projectId: _projectA,
            sketchId: sketch.sketchId,
            expectedSketchRevision: sketch.sketchRevision,
          ),
        ),
        _fails('inventory_sketch_has_active_placements'),
      );

      final metadata = await fixture.app.updateAsset(
        UpdateInventoryAssetCommand(
          operationId: _uuid(319),
          projectId: _projectA,
          assetId: assetId,
          expectedAssetRevision: 1,
          displayName: 'Zincir',
          category: InventoryCategory.other,
          otherCategoryLabel: 'Kaldırma',
          note: 'Kontrol edildi',
        ),
      );
      expect(metadata.sourceRevision, 2);
      final metadataNoOp = await fixture.app.updateAsset(
        UpdateInventoryAssetCommand(
          operationId: _uuid(320),
          projectId: _projectA,
          assetId: assetId,
          expectedAssetRevision: 2,
          displayName: 'Zincir',
          category: InventoryCategory.other,
          otherCategoryLabel: 'Kaldırma',
          note: 'Kontrol edildi',
        ),
      );
      expect(metadataNoOp.isNoOp, isTrue);

      final status = await fixture.app.changeAssetStatus(
        ChangeInventoryAssetStatusCommand(
          operationId: _uuid(321),
          projectId: _projectA,
          assetId: assetId,
          expectedAssetRevision: 2,
          status: InventoryAssetStatus.inUse,
        ),
      );
      expect(status.sourceRevision, 3);
      final statusNoOp = await fixture.app.changeAssetStatus(
        ChangeInventoryAssetStatusCommand(
          operationId: _uuid(322),
          projectId: _projectA,
          assetId: assetId,
          expectedAssetRevision: 3,
          status: InventoryAssetStatus.inUse,
        ),
      );
      expect(statusNoOp.isNoOp, isTrue);

      final placement2 = _uuid(323);
      final quantity = await fixture.app.changeAssetQuantity(
        ChangeInventoryAssetQuantityCommand(
          operationId: _uuid(324),
          projectId: _projectA,
          assetId: assetId,
          placementKey: placementKey,
          successorPlacementId: placement2,
          expectedAssetRevision: 3,
          expectedPlacementSequence: 1,
          totalQuantity: 3,
        ),
      );
      expect(quantity.sourceRevision, 4);
      expect(quantity.supportingRevision, 2);
      final placement3 = _uuid(325);
      final moved = await fixture.app.movePlacement(
        MoveInventoryPlacementCommand(
          operationId: _uuid(326),
          projectId: _projectA,
          assetId: assetId,
          placementKey: placementKey,
          successorPlacementId: placement3,
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          expectedPlacementSequence: 2,
          x: 33,
          y: 41,
        ),
      );
      expect(moved.sourceRevision, 4);
      expect(moved.supportingRevision, 3);
      final sameCoordinate = await fixture.app.movePlacement(
        MoveInventoryPlacementCommand(
          operationId: _uuid(327),
          projectId: _projectA,
          assetId: assetId,
          placementKey: placementKey,
          successorPlacementId: _uuid(328),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          expectedPlacementSequence: 3,
          x: 32,
          y: 40,
        ),
      );
      expect(sameCoordinate.isNoOp, isTrue);
      expect(
        await fixture.db.database.query(
          'inventory_asset_placements',
          where: 'id = ?',
          whereArgs: [_uuid(328)],
        ),
        isEmpty,
      );
      await expectLater(
        fixture.app.movePlacement(
          MoveInventoryPlacementCommand(
            operationId: _uuid(329),
            projectId: _projectA,
            assetId: assetId,
            placementKey: placementKey,
            successorPlacementId: _uuid(330),
            sketchId: sketch.sketchId,
            activeRevisionId: sketch.activeRevisionId,
            expectedPlacementSequence: 2,
            x: 64,
            y: 64,
          ),
        ),
        _fails('inventory_stale_placement_sequence'),
      );

      final archived = await fixture.app.archiveAsset(
        ArchiveInventoryAssetCommand(
          operationId: _uuid(331),
          projectId: _projectA,
          assetId: assetId,
          expectedAssetRevision: 4,
        ),
      );
      expect(archived.sourceRevision, 5);
      expect(
        (await fixture.app.listAssets(
          projectId: _projectA,
        )).map((item) => item.asset.id),
        [secondAssetId],
      );
      final archivedProjection = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: assetId,
      );
      expect(archivedProjection.asset.archivedAt, isNotNull);
      expect(archivedProjection.activePlacement, isNull);
      final archivedEventCount = (await fixture.db.database.query(
        'inventory_events',
      )).length;
      final archivedNoOp = await fixture.app.archiveAsset(
        ArchiveInventoryAssetCommand(
          operationId: _uuid(334),
          projectId: _projectA,
          assetId: assetId,
          expectedAssetRevision: 5,
        ),
      );
      expect(archivedNoOp.isNoOp, isTrue);
      expect(archivedNoOp.sourceRevision, 5);
      expect(
        (await fixture.db.database.query('inventory_events')).length,
        archivedEventCount,
      );

      final placement4 = _uuid(332);
      final unarchived = await fixture.app.unarchiveAsset(
        UnarchiveInventoryAssetCommand(
          operationId: _uuid(333),
          projectId: _projectA,
          assetId: assetId,
          placementKey: placementKey,
          successorPlacementId: placement4,
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          expectedAssetRevision: 5,
          expectedPreviousPlacementSequence: 3,
          x: 80,
          y: 84,
        ),
      );
      expect(unarchived.sourceRevision, 6);
      expect(unarchived.supportingRevision, 4);
      final versions = await fixture.app.listPlacementVersions(
        projectId: _projectA,
        assetId: assetId,
        placementKey: placementKey,
      );
      expect(versions.map((item) => item.sequence), [1, 2, 3, 4]);
      expect(versions.map((item) => item.id), [
        placement1,
        placement2,
        placement3,
        placement4,
      ]);
      expect(versions.last.isActive, isTrue);
      expect(versions.last.x, 80);
      expect(versions.last.y, 84);

      final history = await fixture.app.listAssetHistory(
        projectId: _projectA,
        assetId: assetId,
      );
      expect(history, hasLength(11));
      expect(
        history.every(
          (event) =>
              event.aggregateId == assetId || event.aggregateId == placementKey,
        ),
        isTrue,
      );
      for (var index = 1; index < history.length; index += 1) {
        final previous = history[index - 1];
        final current = history[index];
        expect(
          previous.occurredAt.isAfter(current.occurredAt) ||
              (previous.occurredAt == current.occurredAt &&
                  previous.id.compareTo(current.id) < 0),
          isTrue,
        );
      }
      await expectLater(
        fixture.app.loadAsset(projectId: _projectB, assetId: assetId),
        _fails('inventory_asset_unavailable'),
      );
      expect(
        await fixture.db.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      expect(
        (await fixture.db.database.rawQuery(
          'PRAGMA integrity_check',
        )).single['integrity_check'],
        'ok',
      );
    },
  );

  test(
    'validation and corrupt geometry fail before persistent mutation',
    () async {
      final fixture = await _Fixture.create('validation');
      addTearDown(fixture.close);
      final sketch = await _createFinalizedSketch(fixture, seed: 400);
      final initialCounts = await _counts(fixture.db.database);

      Future<void> expectInvalid(
        CreateInventoryAssetCommand command,
        String code,
      ) async {
        await expectLater(
          Future.sync(() => fixture.app.createAsset(command)),
          _fails(code),
        );
        expect(await _counts(fixture.db.database), initialCounts);
      }

      CreateInventoryAssetCommand assetCommand({
        required int seed,
        String displayName = 'Pompa',
        InventoryCategory category = InventoryCategory.equipment,
        String? otherCategoryLabel,
        int quantity = 1,
        int x = 64,
        int y = 64,
        String projectId = _projectA,
      }) => CreateInventoryAssetCommand(
        operationId: _uuid(seed),
        projectId: projectId,
        assetId: _uuid(seed + 1),
        placementId: _uuid(seed + 2),
        placementKey: _uuid(seed + 3),
        sketchId: sketch.sketchId,
        activeRevisionId: sketch.activeRevisionId,
        displayName: displayName,
        category: category,
        otherCategoryLabel: otherCategoryLabel,
        totalQuantity: quantity,
        x: x,
        y: y,
      );

      await expectInvalid(
        assetCommand(seed: 410, displayName: '   '),
        'inventory_invalid_asset_name',
      );
      await expectInvalid(
        assetCommand(seed: 420, category: InventoryCategory.other),
        'inventory_invalid_other_category_label',
      );
      await expectInvalid(
        assetCommand(seed: 430, otherCategoryLabel: 'Yersiz'),
        'inventory_invalid_other_category_label',
      );
      await expectInvalid(
        assetCommand(seed: 440, quantity: 0),
        'inventory_invalid_quantity',
      );
      await expectInvalid(
        assetCommand(seed: 450, x: 4097),
        'inventory_invalid_placement_coordinate',
      );
      await expectInvalid(
        assetCommand(seed: 460, projectId: _projectB),
        'inventory_sketch_unavailable',
      );

      final emptySketch = _uuid(470);
      final emptyDraft = _uuid(471);
      await fixture.app.archiveSketch(
        ArchiveInventorySketchCommand(
          operationId: _uuid(472),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          expectedSketchRevision: 3,
        ),
      );
      await fixture.app.createSketch(
        CreateInventorySketchCommand(
          operationId: _uuid(473),
          projectId: _projectA,
          sketchId: emptySketch,
          draftRevisionId: emptyDraft,
        ),
      );
      await expectLater(
        fixture.app.finalizeSketch(
          FinalizeInventorySketchCommand(
            operationId: _uuid(474),
            projectId: _projectA,
            sketchId: emptySketch,
            draftRevisionId: emptyDraft,
            expectedSketchRevision: 1,
            expectedContentRevision: 1,
          ),
        ),
        _fails(InventoryGeometryFailure.safeCode),
      );
      expect(
        await fixture.db.database.query(
          'inventory_command_receipts',
          where: 'id = ?',
          whereArgs: [_uuid(474)],
        ),
        isEmpty,
      );

      await fixture.app.archiveSketch(
        ArchiveInventorySketchCommand(
          operationId: _uuid(475),
          projectId: _projectA,
          sketchId: emptySketch,
          expectedSketchRevision: 1,
        ),
      );
      await fixture.app.unarchiveSketch(
        UnarchiveInventorySketchCommand(
          operationId: _uuid(476),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          expectedSketchRevision: 4,
        ),
      );
      final corruptDraft = _uuid(477);
      await fixture.app.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(478),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          newDraftRevisionId: corruptDraft,
          expectedSketchRevision: 5,
        ),
      );
      await fixture.db.database.update(
        'inventory_sketch_revisions',
        {
          'geometry_sha256': 'a'.padRight(64, 'a'),
          'content_revision': 2,
          'updated_at': (await fixture.db.database.query(
            'inventory_sketch_revisions',
            columns: const ['updated_at'],
            where: 'id = ?',
            whereArgs: [corruptDraft],
          )).single['updated_at'],
        },
        where: 'id = ?',
        whereArgs: [corruptDraft],
      );
      await expectLater(
        fixture.app.loadPrimarySketch(_projectA),
        _fails(InventoryGeometryFailure.safeCode),
      );
    },
  );

  test(
    'archive rejects an unarchived asset with zero active placements',
    () async {
      final fixture = await _Fixture.create('zero_placement_archive');
      addTearDown(fixture.close);
      final sketch = await _createFinalizedSketch(fixture, seed: 600);
      final assetId = _uuid(610);
      final placementId = _uuid(611);
      await fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(612),
          projectId: _projectA,
          assetId: assetId,
          placementId: placementId,
          placementKey: _uuid(613),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          displayName: 'Bozuk yerleşim fixture',
          category: InventoryCategory.equipment,
          totalQuantity: 1,
          x: 64,
          y: 64,
        ),
      );
      final placementBefore = (await fixture.db.database.query(
        'inventory_asset_placements',
        where: 'id = ?',
        whereArgs: [placementId],
      )).single;
      await fixture.db.database.update(
        'inventory_asset_placements',
        {
          'ended_at': placementBefore['created_at'],
          'end_reason': InventoryPlacementEndReason.moved.storageValue,
        },
        where: 'id = ? AND ended_at IS NULL',
        whereArgs: [placementId],
      );
      await expectLater(
        fixture.app.loadAsset(projectId: _projectA, assetId: assetId),
        _fails('inventory_projection_integrity_failed'),
      );
      final assetBefore = (await fixture.db.database.query(
        'inventory_assets',
        where: 'id = ?',
        whereArgs: [assetId],
      )).single;
      final countsBefore = await _counts(fixture.db.database);
      await expectLater(
        fixture.app.archiveAsset(
          ArchiveInventoryAssetCommand(
            operationId: _uuid(614),
            projectId: _projectA,
            assetId: assetId,
            expectedAssetRevision: 1,
          ),
        ),
        _fails('inventory_projection_integrity_failed'),
      );
      expect(await _counts(fixture.db.database), countsBefore);
      expect(
        (await fixture.db.database.query(
          'inventory_assets',
          where: 'id = ?',
          whereArgs: [assetId],
        )).single,
        assetBefore,
      );
      expect(
        await fixture.db.database.query(
          'inventory_command_receipts',
          where: 'id = ?',
          whereArgs: [_uuid(614)],
        ),
        isEmpty,
      );
    },
  );

  test(
    'unsupported multiple active placements fails typed and never selects',
    () async {
      final fixture = await _Fixture.create('multiple');
      addTearDown(fixture.close);
      final sketch = await _createFinalizedSketch(fixture, seed: 500);
      final assetId = _uuid(510);
      await fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(511),
          projectId: _projectA,
          assetId: assetId,
          placementId: _uuid(512),
          placementKey: _uuid(513),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          displayName: 'Çoklu yerleşim fixture',
          category: InventoryCategory.temporaryWorks,
          totalQuantity: 2,
          x: 64,
          y: 64,
        ),
      );
      final timestamp = (await fixture.db.database.query(
        'inventory_assets',
        columns: const ['updated_at'],
        where: 'id = ?',
        whereArgs: [assetId],
      )).single['updated_at'];
      await fixture.db.database.update(
        'inventory_assets',
        {'total_quantity': 4, 'revision': 2, 'updated_at': timestamp},
        where: 'id = ?',
        whereArgs: [assetId],
      );
      await fixture.db.database.insert('inventory_asset_placements', {
        'id': _uuid(514),
        'placement_key': _uuid(515),
        'project_id': _projectA,
        'asset_id': assetId,
        'sketch_id': sketch.sketchId,
        'provenance_revision_id': sketch.activeRevisionId,
        'sequence': 1,
        'x': 128,
        'y': 128,
        'quantity': 2,
        'created_at': timestamp,
        'ended_at': null,
        'end_reason': null,
        'supersedes_placement_id': null,
      });
      await expectLater(
        fixture.app.loadAsset(projectId: _projectA, assetId: assetId),
        _fails('inventory_multiple_placements_not_supported_in_v1'),
      );
      await expectLater(
        fixture.app.archiveAsset(
          ArchiveInventoryAssetCommand(
            operationId: _uuid(516),
            projectId: _projectA,
            assetId: assetId,
            expectedAssetRevision: 2,
          ),
        ),
        _fails('inventory_multiple_placements_not_supported_in_v1'),
      );
      expect(
        await fixture.db.database.query(
          'inventory_command_receipts',
          where: 'id = ?',
          whereArgs: [_uuid(516)],
        ),
        isEmpty,
      );
      expect(
        await fixture.db.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
    },
  );
}

class _Fixture {
  _Fixture({
    required this.root,
    required this.db,
    required this.clock,
    required this.ids,
    required this.app,
  });

  final Directory root;
  final AppDatabase db;
  final _TickingClock clock;
  final _SequentialIds ids;
  final InventoryApplication app;

  static Future<_Fixture> create(String label) async {
    final root = await Directory.systemTemp.createTemp('cse_inv_app_$label');
    final clock = _TickingClock(DateTime.parse(_t0));
    final ids = _SequentialIds(800000);
    final db = AppDatabase(
      path: path.join(root.path, 'mobile.sqlite3'),
      factory: databaseFactoryFfi,
      clock: clock.call,
    );
    await db.open();
    for (final project in const [
      (_projectA, 'Project A', false),
      (_projectB, 'Project B', false),
      (_projectArchived, 'Archived', true),
    ]) {
      await db.database.insert('projects', {
        'id': project.$1,
        'name': project.$2,
        'created_at': _t0,
        'updated_at': _t0,
        'revision': 1,
        'archived_at': project.$3 ? _t0 : null,
      });
    }
    final app = InventoryApplication(
      database: db,
      clock: clock.call,
      idFactory: ids.call,
    );
    return _Fixture(root: root, db: db, clock: clock, ids: ids, app: app);
  }

  Future<void> close() async {
    await db.close();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

class _TickingClock {
  _TickingClock(this.value);
  DateTime value;

  DateTime call() {
    final result = value;
    value = value.add(const Duration(seconds: 1));
    return result;
  }
}

class _SequentialIds {
  _SequentialIds(this.value);
  int value;
  String call() => _uuid(value++);
}

class _FinalizedSketch {
  const _FinalizedSketch({
    required this.sketchId,
    required this.activeRevisionId,
    required this.sketchRevision,
  });
  final String sketchId;
  final String activeRevisionId;
  final int sketchRevision;
}

Future<_FinalizedSketch> _createFinalizedSketch(
  _Fixture fixture, {
  required int seed,
  String projectId = _projectA,
}) async {
  final sketchId = _uuid(seed);
  final draftId = _uuid(seed + 1);
  await fixture.app.createSketch(
    CreateInventorySketchCommand(
      operationId: _uuid(seed + 2),
      projectId: projectId,
      sketchId: sketchId,
      draftRevisionId: draftId,
    ),
  );
  await fixture.app.autosaveSketchDraft(
    AutosaveInventorySketchDraftCommand(
      operationId: _uuid(seed + 3),
      projectId: projectId,
      sketchId: sketchId,
      draftRevisionId: draftId,
      expectedSketchRevision: 1,
      expectedContentRevision: 1,
      geometry: _geometry(),
    ),
  );
  await fixture.app.finalizeSketch(
    FinalizeInventorySketchCommand(
      operationId: _uuid(seed + 4),
      projectId: projectId,
      sketchId: sketchId,
      draftRevisionId: draftId,
      expectedSketchRevision: 2,
      expectedContentRevision: 2,
    ),
  );
  return _FinalizedSketch(
    sketchId: sketchId,
    activeRevisionId: draftId,
    sketchRevision: 3,
  );
}

InventoryGeometry _geometry([int offset = 0]) => InventoryGeometry(
  polylines: [
    InventoryPolyline(
      closed: false,
      points: [
        InventorySketchPoint(x: offset, y: 0),
        InventorySketchPoint(x: offset + 64, y: 64),
      ],
    ),
  ],
);

String _uuid(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';

Matcher _fails(String code) => throwsA(
  isA<InventoryFailure>().having((failure) => failure.code, 'code', code),
);

Map<String, Object?> _resultValues(InventoryMutationResult value) => {
  'operation': value.operationId,
  'command': value.commandType,
  'project': value.projectId,
  'aggregate_type': value.primaryAggregateType,
  'aggregate_id': value.primaryAggregateId,
  'source': value.sourceId,
  'source_revision': value.sourceRevision,
  'supporting': value.supportingId,
  'supporting_revision': value.supportingRevision,
  'no_op': value.isNoOp,
  'event_count': value.eventCount,
  'at': value.resultAt,
};

Future<Map<String, int>> _counts(sqflite.Database db) async => {
  for (final table in const [
    'inventory_sketches',
    'inventory_sketch_revisions',
    'inventory_assets',
    'inventory_asset_placements',
    'inventory_command_receipts',
    'inventory_events',
  ])
    table: sqflite.Sqflite.firstIntValue(
      await db.rawQuery('SELECT count(*) FROM $table'),
    )!,
};
