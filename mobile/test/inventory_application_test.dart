import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/inventory/inventory_sketch_editor_page.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:crypto/crypto.dart' as hashes;
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

  for (final editActive in [false, true]) {
    test(
      'AT-602 rejects multiple or nonterminal open drafts without writes ($editActive)',
      () async {
        final fixture = await _Fixture.create('single_open_suffix_$editActive');
        addTearDown(fixture.close);
        if (editActive) await _createFinalizedSketch(fixture, seed: 29000);
        final controller = InventorySketchEditorController(
          application: fixture.app,
          projectId: _projectA,
          launchIntent: editActive
              ? InventorySketchLaunchIntent.editActive
              : InventorySketchLaunchIntent.createOrRecover,
          idFactory: _SequentialIds(29100).call,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        final before = (await fixture.app.loadPrimarySketch(_projectA))!;
        final prefix = before.draftRevision!.geometry.polylines;
        final open = InventoryPolyline(
          closed: false,
          points: [
            InventorySketchPoint(x: 2560, y: 512),
            InventorySketchPoint(x: 3072, y: 512),
            InventorySketchPoint(x: 3072, y: 1024),
          ],
        );
        final countsBefore = await _counts(fixture.db.database);
        for (final openCount in [2, 3]) {
          await expectLater(
            fixture.app.autosaveSketchDraft(
              AutosaveInventorySketchDraftCommand(
                operationId: _uuid(29200 + openCount),
                projectId: _projectA,
                sketchId: before.sketch.id,
                draftRevisionId: before.draftRevision!.id,
                expectedSketchRevision: before.sketch.revision,
                expectedContentRevision: before.draftRevision!.contentRevision,
                geometry: InventoryGeometry(
                  polylines: [...prefix, ...List.filled(openCount, open)],
                ),
                existingBlockMappings: controller.existingBlockMappings,
              ),
            ),
            _fails('inventory_block_metadata_incomplete'),
          );
          expect(await _counts(fixture.db.database), countsBefore);
        }
        if (editActive) {
          await expectLater(
            fixture.app.autosaveSketchDraft(
              AutosaveInventorySketchDraftCommand(
                operationId: _uuid(29210),
                projectId: _projectA,
                sketchId: before.sketch.id,
                draftRevisionId: before.draftRevision!.id,
                expectedSketchRevision: before.sketch.revision,
                expectedContentRevision: before.draftRevision!.contentRevision,
                geometry: InventoryGeometry(polylines: [open, ...prefix]),
                existingBlockMappings: [
                  for (final mapping in controller.existingBlockMappings)
                    InventoryExistingBlockMappingDraft(
                      blockId: mapping.blockId,
                      polygonIndex: mapping.polygonIndex + 1,
                    ),
                ],
              ),
            ),
            _fails('inventory_block_metadata_incomplete'),
          );
          expect(await _counts(fixture.db.database), countsBefore);
        }
        final unchanged = (await fixture.app.loadPrimarySketch(_projectA))!;
        expect(
          unchanged.draftRevision!.geometry.canonicalJson,
          before.draftRevision!.geometry.canonicalJson,
        );
        expect(
          unchanged.draftRevision!.contentRevision,
          before.draftRevision!.contentRevision,
        );
        expect(unchanged.sketch.revision, before.sketch.revision);

        // Exercise both count formats on read: first-draft legacy count and the
        // historical edit-draft prefix count that includes mapped active blocks.
        final legacyCount = editActive
            ? before.activeRevision!.geometry.polylines.length
            : 0;
        await _seedDraftGeometry(
          fixture,
          geometry: InventoryGeometry(polylines: [...prefix, open]),
          legacyPolygonCount: legacyCount,
        );
        final single = (await fixture.app.loadPrimarySketch(_projectA))!;
        expect(
          single.draftRevision!.geometry.polylines.last.points,
          open.points,
        );
        await _seedDraftGeometry(
          fixture,
          geometry: InventoryGeometry(polylines: [...prefix, open, open]),
          legacyPolygonCount: legacyCount,
        );
        final malformedCounts = await _counts(fixture.db.database);
        await expectLater(
          fixture.app.loadPrimarySketch(_projectA),
          _fails('inventory_projection_integrity_failed'),
        );
        await expectLater(
          fixture.app.autosaveSketchDraft(
            AutosaveInventorySketchDraftCommand(
              operationId: _uuid(29220),
              projectId: _projectA,
              sketchId: single.sketch.id,
              draftRevisionId: single.draftRevision!.id,
              expectedSketchRevision: single.sketch.revision,
              expectedContentRevision:
                  single.draftRevision!.contentRevision + 1,
              geometry: InventoryGeometry(polylines: [...prefix, open, open]),
              existingBlockMappings: controller.existingBlockMappings,
            ),
          ),
          _fails('inventory_projection_integrity_failed'),
        );
        expect(await _counts(fixture.db.database), malformedCounts);
      },
    );
  }

  for (final finalizedLegacy in [false, true]) {
    test(
      'AT-602 identical legacy and new open lines recover by durable index ($finalizedLegacy)',
      () async {
        final fixture = await _Fixture.create(
          'identical_open_suffix_$finalizedLegacy',
        );
        addTearDown(fixture.close);
        final sketchId = _uuid(29300);
        final legacyId = _uuid(29301);
        final legacy = InventoryGeometry(
          polylines: [
            InventoryPolyline(
              closed: false,
              points: [
                InventorySketchPoint(x: 0, y: 0),
                InventorySketchPoint(x: 64, y: 0),
              ],
            ),
          ],
        );
        await fixture.app.createSketch(
          CreateInventorySketchCommand(
            operationId: _uuid(29302),
            projectId: _projectA,
            sketchId: sketchId,
            draftRevisionId: legacyId,
          ),
        );
        await _seedDraftGeometry(
          fixture,
          geometry: legacy,
          legacyPolygonCount: 1,
        );
        if (finalizedLegacy) {
          await fixture.app.finalizeSketch(
            FinalizeInventorySketchCommand(
              operationId: _uuid(29303),
              projectId: _projectA,
              sketchId: sketchId,
              draftRevisionId: legacyId,
              expectedSketchRevision: 1,
              expectedContentRevision: 2,
            ),
          );
          await fixture.app.startSketchEdit(
            StartInventorySketchEditCommand(
              operationId: _uuid(29304),
              projectId: _projectA,
              sketchId: sketchId,
              activeRevisionId: legacyId,
              newDraftRevisionId: _uuid(29305),
              expectedSketchRevision: 2,
            ),
          );
        }
        final before = (await fixture.app.loadPrimarySketch(_projectA))!;
        final identical = InventoryGeometry(
          polylines: [
            legacy.polylines.single,
            InventoryGeometry.decode(legacy.canonicalJson).polylines.single,
          ],
        );
        await fixture.app.autosaveSketchDraft(
          AutosaveInventorySketchDraftCommand(
            operationId: _uuid(29306),
            projectId: _projectA,
            sketchId: sketchId,
            draftRevisionId: before.draftRevision!.id,
            expectedSketchRevision: before.sketch.revision,
            expectedContentRevision: before.draftRevision!.contentRevision,
            geometry: identical,
            existingBlockMappings: const [],
          ),
        );
        final saved = (await fixture.app.loadPrimarySketch(_projectA))!;
        expect(saved.draftLegacyPolygonCount, 1);
        final savedCounts = await _counts(fixture.db.database);
        await fixture.db.close();
        await fixture.db.open();
        final relaunchedApp = InventoryApplication(
          database: fixture.db,
          clock: fixture.clock.call,
          idFactory: fixture.ids.call,
        );
        final recovered = InventorySketchEditorController(
          application: relaunchedApp,
          projectId: _projectA,
          launchIntent: InventorySketchLaunchIntent.createOrRecover,
          idFactory: _SequentialIds(29400).call,
          autosaveDelay: const Duration(days: 1),
        );
        addTearDown(recovered.dispose);
        await recovered.initialize();
        expect(recovered.loadStatus, InventorySketchLoadStatus.ready);
        expect(recovered.draftRevisionId, saved.draftRevision!.id);
        expect(
          recovered.editor!.geometry.canonicalJson,
          identical.canonicalJson,
        );
        expect(recovered.editor!.workingPolylineIndex, 1);
        expect(recovered.newBlocks, isEmpty);
        expect(await recovered.finalizeDraft(), isFalse);
        expect(await _counts(fixture.db.database), savedCounts);
        final nextPoint = InventorySketchPoint(x: 64, y: 64);
        expect(recovered.drawPoint(nextPoint), isTrue);
        recovered.discardUnsaved();
        expect(
          recovered.editor!.geometry.canonicalJson,
          identical.canonicalJson,
        );
        expect(recovered.editor!.workingPolylineIndex, 1);
        expect(recovered.drawPoint(nextPoint), isTrue);
        expect(await recovered.forceSave(), isTrue);
        final continued = (await relaunchedApp.loadPrimarySketch(_projectA))!;
        expect(
          continued.draftRevision!.geometry.polylines.first.points,
          legacy.polylines.single.points,
        );
        expect(continued.draftRevision!.geometry.polylines.last.points, [
          ...legacy.polylines.single.points,
          nextPoint,
        ]);
        expect(
          continued.draftRevision!.geometry.polylines.last.closed,
          isFalse,
        );
        expect(
          continued.draftRevision!.contentRevision,
          saved.draftRevision!.contentRevision + 1,
        );
        expect(continued.blocks, isEmpty);
        expect(continued.floors, isEmpty);
        expect(continued.draftNewBlocks, isEmpty);
        if (finalizedLegacy) {
          expect(continued.activeRevision!.id, legacyId);
          expect(
            continued.activeRevision!.geometry.canonicalJson,
            legacy.canonicalJson,
          );
        }
        final continuedCounts = await _counts(fixture.db.database);
        await expectLater(
          relaunchedApp.autosaveSketchDraft(
            AutosaveInventorySketchDraftCommand(
              operationId: _uuid(29500),
              projectId: _projectA,
              sketchId: sketchId,
              draftRevisionId: continued.draftRevision!.id,
              expectedSketchRevision: continued.sketch.revision,
              expectedContentRevision: continued.draftRevision!.contentRevision,
              geometry: InventoryGeometry(
                polylines: [
                  InventoryPolyline(
                    closed: false,
                    points: [
                      InventorySketchPoint(x: 0, y: 0),
                      InventorySketchPoint(x: 128, y: 0),
                    ],
                  ),
                  continued.draftRevision!.geometry.polylines.last,
                ],
              ),
              existingBlockMappings: const [],
            ),
          ),
          _fails('inventory_legacy_geometry_immutable'),
        );
        expect(await _counts(fixture.db.database), continuedCounts);
      },
    );
  }

  for (final typedLifecycle in [false, true]) {
    test(
      'AT-602 migrated open legacy draft stays immutable and finalizable ($typedLifecycle)',
      () async {
        final fixture = await _Fixture.create(
          'migrated_open_legacy_$typedLifecycle',
        );
        addTearDown(fixture.close);
        final sketchId = _uuid(28000);
        final draftId = _uuid(28001);
        final legacy = InventoryGeometry(
          polylines: [
            InventoryPolyline(
              closed: false,
              points: [
                InventorySketchPoint(x: 0, y: 0),
                InventorySketchPoint(x: 64, y: 0),
              ],
            ),
          ],
        );
        await fixture.app.createSketch(
          CreateInventorySketchCommand(
            operationId: _uuid(28002),
            projectId: _projectA,
            sketchId: sketchId,
            draftRevisionId: draftId,
          ),
        );
        // Exact post-migration representation: the existing open line is counted
        // as legacy, unlike a newly autosaved open drawing (legacy count zero).
        await fixture.db.database.transaction((transaction) async {
          await transaction.update(
            'inventory_sketch_revisions',
            {
              'geometry_json': legacy.canonicalJson,
              'geometry_sha256': legacy.sha256,
              'content_revision': 2,
            },
            where: 'id = ?',
            whereArgs: [draftId],
          );
          final rows = await transaction.query(
            'inventory_sketch_revision_spatial_drafts',
            where: 'revision_id = ?',
            whereArgs: [draftId],
          );
          await transaction.insert('inventory_sketch_revision_spatial_drafts', {
            ...rows.single,
            'content_revision': 2,
            'legacy_polygon_count': 1,
          });
        });
        final controller = InventorySketchEditorController(
          application: fixture.app,
          projectId: _projectA,
          launchIntent: InventorySketchLaunchIntent.createOrRecover,
          idFactory: _SequentialIds(28100).call,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        expect(controller.loadStatus, InventorySketchLoadStatus.ready);
        expect(controller.workingPolyline, isNull);
        expect(controller.isFinalizeEnabled, isTrue);
        final countsBefore = await _counts(fixture.db.database);
        await expectLater(
          fixture.app.autosaveSketchDraft(
            AutosaveInventorySketchDraftCommand(
              operationId: _uuid(28003),
              projectId: _projectA,
              sketchId: sketchId,
              draftRevisionId: draftId,
              expectedSketchRevision: 1,
              expectedContentRevision: 2,
              geometry: InventoryGeometry(
                polylines: [
                  InventoryPolyline(
                    closed: false,
                    points: [
                      InventorySketchPoint(x: 0, y: 0),
                      InventorySketchPoint(x: 128, y: 0),
                    ],
                  ),
                ],
              ),
              existingBlockMappings: const [],
            ),
          ),
          _fails('inventory_legacy_geometry_immutable'),
        );
        expect(await _counts(fixture.db.database), countsBefore);
        await fixture.app.finalizeSketch(
          FinalizeInventorySketchCommand(
            operationId: _uuid(28004),
            projectId: _projectA,
            sketchId: sketchId,
            draftRevisionId: draftId,
            expectedSketchRevision: 1,
            expectedContentRevision: 2,
            existingBlockIntents: typedLifecycle ? const [] : null,
          ),
        );
        final finalized = (await fixture.app.loadPrimarySketch(_projectA))!;
        expect(finalized.draftRevision, isNull);
        expect(
          finalized.activeRevision!.geometry.canonicalJson,
          legacy.canonicalJson,
        );
        expect(finalized.activeRevision!.contentRevision, 2);
        expect(finalized.blocks, isEmpty);
        expect(finalized.floors, isEmpty);
      },
    );
  }

  for (final editActive in [false, true]) {
    test(
      'AT-602 open draft survives database restart and continues ($editActive)',
      () async {
        final fixture = await _Fixture.create('open_draft_$editActive');
        addTearDown(fixture.close);
        if (editActive) await _createFinalizedSketch(fixture, seed: 21000);
        final first = InventorySketchEditorController(
          application: fixture.app,
          projectId: _projectA,
          launchIntent: editActive
              ? InventorySketchLaunchIntent.editActive
              : InventorySketchLaunchIntent.createOrRecover,
          idFactory: _SequentialIds(22000).call,
          autosaveDelay: const Duration(days: 1),
        );
        var firstDisposed = false;
        addTearDown(() {
          if (!firstDisposed) first.dispose();
        });
        await first.initialize();
        expect(first.loadStatus, InventorySketchLoadStatus.ready);
        final before = (await fixture.app.loadPrimarySketch(_projectA))!;
        final countsBefore = await _counts(fixture.db.database);
        final points = [
          InventorySketchPoint(x: 2560, y: 512),
          InventorySketchPoint(x: 3072, y: 512),
          InventorySketchPoint(x: 3072, y: 1024),
        ];
        for (final point in points) {
          expect(first.drawPoint(point), isTrue);
        }
        final geometry = first.editor!.geometry;
        final saving = first.forceSave();
        expect(identical(first.forceSave(), saving), isTrue);
        expect(await saving, isTrue);
        expect(first.isFinalizeEnabled, isFalse);
        final saved = (await fixture.app.loadPrimarySketch(_projectA))!;
        expect(
          saved.draftRevision!.geometry.canonicalJson,
          geometry.canonicalJson,
        );
        expect(saved.draftRevision!.id, before.draftRevision!.id);
        expect(
          saved.draftRevision!.contentRevision,
          before.draftRevision!.contentRevision + 1,
        );
        expect(saved.sketch.revision, before.sketch.revision + 1);
        expect(saved.draftNewBlocks, isEmpty);
        expect(saved.draftLegacyPolygonCount, 0);
        final countsSaved = await _counts(fixture.db.database);
        for (final table in [
          'inventory_sketches',
          'inventory_sketch_revisions',
          'inventory_blocks',
          'inventory_floors',
        ]) {
          expect(countsSaved[table], countsBefore[table], reason: table);
        }
        expect(await first.forceSave(), isTrue);
        expect(await _counts(fixture.db.database), countsSaved);
        final receipts = await fixture.db.database.query(
          'inventory_command_receipts',
          where: 'command_type = ?',
          whereArgs: [InventoryCommandType.sketchDraftAutosave.storageValue],
          orderBy: 'created_at DESC',
          limit: 1,
        );
        await fixture.app.autosaveSketchDraft(
          AutosaveInventorySketchDraftCommand(
            operationId: receipts.single['id']! as String,
            projectId: _projectA,
            sketchId: before.sketch.id,
            draftRevisionId: before.draftRevision!.id,
            expectedSketchRevision: before.sketch.revision,
            expectedContentRevision: before.draftRevision!.contentRevision,
            geometry: geometry,
            existingBlockMappings: first.existingBlockMappings,
          ),
        );
        expect(await _counts(fixture.db.database), countsSaved);
        first.dispose();
        firstDisposed = true;
        await fixture.db.close();
        await fixture.db.open();
        final relaunchedApp = InventoryApplication(
          database: fixture.db,
          clock: fixture.clock.call,
          idFactory: fixture.ids.call,
        );
        final recovered = InventorySketchEditorController(
          application: relaunchedApp,
          projectId: _projectA,
          launchIntent: InventorySketchLaunchIntent.createOrRecover,
          idFactory: _SequentialIds(23000).call,
          autosaveDelay: const Duration(days: 1),
        );
        addTearDown(recovered.dispose);
        await recovered.initialize();
        expect(recovered.loadStatus, InventorySketchLoadStatus.ready);
        expect(recovered.sketchId, saved.sketch.id);
        expect(recovered.draftRevisionId, saved.draftRevision!.id);
        expect(
          recovered.editor!.geometry.canonicalJson,
          geometry.canonicalJson,
        );
        expect(
          recovered.editor!.workingPolylineIndex,
          geometry.polylines.length - 1,
        );
        expect(recovered.editor!.undoDepth, 0);
        expect(recovered.newBlocks, isEmpty);
        expect(await recovered.finalizeDraft(), isFalse);
        for (final typedLifecycle in [false, true]) {
          await expectLater(
            relaunchedApp.finalizeSketch(
              FinalizeInventorySketchCommand(
                operationId: _uuid(24000 + (typedLifecycle ? 1 : 0)),
                projectId: _projectA,
                sketchId: saved.sketch.id,
                draftRevisionId: saved.draftRevision!.id,
                expectedSketchRevision: saved.sketch.revision,
                expectedContentRevision: saved.draftRevision!.contentRevision,
                existingBlockIntents: typedLifecycle
                    ? [
                        for (final mapping in saved.draftBlockPolygons)
                          InventoryExistingBlockFinalizeIntent(
                            blockId: mapping.blockId,
                            action: InventoryExistingBlockAction.retainMapped,
                            expectedBlockRevision: saved.blocks
                                .singleWhere(
                                  (block) => block.id == mapping.blockId,
                                )
                                .revision,
                            targetPolygonIndex: mapping.polygonIndex,
                          ),
                      ]
                    : null,
              ),
            ),
            _fails(
              editActive && typedLifecycle
                  ? 'inventory_legacy_geometry_immutable'
                  : 'inventory_block_metadata_incomplete',
            ),
          );
        }
        expect(await _counts(fixture.db.database), countsSaved);
        final nextPoint = InventorySketchPoint(x: 2560, y: 1024);
        expect(recovered.drawPoint(nextPoint), isTrue);
        expect(recovered.workingPolyline!.points, [...points, nextPoint]);
        expect(
          recovered.editor!.geometry.polylines.length,
          geometry.polylines.length,
        );
        final block = recovered.createBlockDraft(
          displayName: 'Devam edilen blok',
          floorCount: 1,
        );
        expect(recovered.closeWorkingBlock(block), isTrue);
        expect(await recovered.finalizeDraft(), isTrue);
        final finalized = (await relaunchedApp.loadPrimarySketch(_projectA))!;
        expect(finalized.draftRevision, isNull);
        expect(finalized.blocks.length, before.blocks.length + 1);
        expect(finalized.blocks.last.id, block.id);
        expect(
          finalized.activeRevision!.geometry.polylines.last.closed,
          isTrue,
        );
        expect(finalized.activeRevision!.geometry.polylines.last.points, [
          ...points,
          nextPoint,
        ]);
        if (editActive) {
          expect(finalized.blocks.first.id, before.blocks.first.id);
          for (final existingBlock in before.blocks) {
            expect(
              finalized.floors
                  .where((floor) => floor.blockId == existingBlock.id)
                  .map((floor) => (floor.id, floor.ordinal, floor.revision)),
              before.floors
                  .where((floor) => floor.blockId == existingBlock.id)
                  .map((floor) => (floor.id, floor.ordinal, floor.revision)),
            );
          }
          expect(
            finalized.activeRevision!.geometry.polylines.first.points,
            before.activeRevision!.geometry.polylines.first.points,
          );
        }
      },
    );
  }

  test(
    'AT-602 open draft allowance retains exact finalized legacy geometry',
    () async {
      final fixture = await _Fixture.create('open_draft_legacy');
      addTearDown(fixture.close);
      final sketchId = _uuid(25000);
      final activeId = _uuid(25001);
      final legacy = _geometry();
      await fixture.app.createSketch(
        CreateInventorySketchCommand(
          operationId: _uuid(25002),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: activeId,
        ),
      );
      // An existing unclassified closed polygon represents pre-spatial legacy data.
      await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(25003),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: activeId,
          expectedSketchRevision: 1,
          expectedContentRevision: 1,
          geometry: legacy,
        ),
      );
      await fixture.app.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _uuid(25004),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: activeId,
          expectedSketchRevision: 2,
          expectedContentRevision: 2,
        ),
      );
      await fixture.app.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(25005),
          projectId: _projectA,
          sketchId: sketchId,
          activeRevisionId: activeId,
          newDraftRevisionId: _uuid(25006),
          expectedSketchRevision: 3,
        ),
      );
      final open = InventoryPolyline(
        closed: false,
        points: [
          InventorySketchPoint(x: 2560, y: 512),
          InventorySketchPoint(x: 3072, y: 512),
          InventorySketchPoint(x: 3072, y: 1024),
        ],
      );
      await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(25007),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: _uuid(25006),
          expectedSketchRevision: 4,
          expectedContentRevision: 1,
          geometry: InventoryGeometry(polylines: [...legacy.polylines, open]),
          existingBlockMappings: const [],
        ),
      );
      final before = await _counts(fixture.db.database);
      final invalidCandidates = [
        InventoryGeometry(polylines: [open]),
        InventoryGeometry(polylines: [_rectangle(64, 0, 2112, 1536), open]),
        InventoryGeometry(
          polylines: [
            InventoryPolyline(
              closed: false,
              points: legacy.polylines.single.points,
            ),
            open,
          ],
        ),
        InventoryGeometry(
          polylines: [...legacy.polylines, _rectangle(2560, 512, 3072, 1024)],
        ),
      ];
      for (var index = 0; index < invalidCandidates.length; index += 1) {
        await expectLater(
          fixture.app.autosaveSketchDraft(
            AutosaveInventorySketchDraftCommand(
              operationId: _uuid(25100 + index),
              projectId: _projectA,
              sketchId: sketchId,
              draftRevisionId: _uuid(25006),
              expectedSketchRevision: 5,
              expectedContentRevision: 2,
              geometry: invalidCandidates[index],
              existingBlockMappings: const [],
            ),
          ),
          _fails('inventory_legacy_geometry_immutable'),
        );
        expect(await _counts(fixture.db.database), before);
      }
      final durable = (await fixture.app.loadPrimarySketch(_projectA))!;
      expect(
        durable.activeRevision!.geometry.canonicalJson,
        legacy.canonicalJson,
      );
      expect(
        durable.draftRevision!.geometry.polylines.last.points,
        open.points,
      );
      final controller = InventorySketchEditorController(
        application: fixture.app,
        projectId: _projectA,
        launchIntent: InventorySketchLaunchIntent.createOrRecover,
        idFactory: _SequentialIds(25200).call,
        autosaveDelay: const Duration(days: 1),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.loadStatus, InventorySketchLoadStatus.ready);
      expect(controller.workingPolyline!.points, open.points);
      expect(
        controller.drawPoint(InventorySketchPoint(x: 2560, y: 1024)),
        isTrue,
      );
      expect(await controller.forceSave(), isTrue);
      expect(
        (await fixture.app.loadPrimarySketch(
          _projectA,
        ))!.activeRevision!.geometry.canonicalJson,
        legacy.canonicalJson,
      );
    },
  );

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
    expect(create.floorId, isNull);
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
    'AT-531-007/010 exact floor persists and wrong-block or project writes nothing',
    () async {
      final fixture = await _Fixture.create('exact_floor');
      addTearDown(fixture.close);
      final sketchA = await _createFinalizedSketch(
        fixture,
        seed: 12000,
        geometry: _geometry(64),
      );
      final projectionA = (await fixture.app.loadPrimarySketch(_projectA))!;
      final firstMapping = projectionA.activeBlockPolygons.singleWhere(
        (mapping) => mapping.polygonIndex == 0,
      );
      final secondMapping = projectionA.activeBlockPolygons.singleWhere(
        (mapping) => mapping.polygonIndex == 1,
      );
      final exactFloor = projectionA.floors.singleWhere(
        (floor) => floor.blockId == firstMapping.blockId && floor.ordinal == 2,
      );
      final otherBlockFloor = projectionA.floors.singleWhere(
        (floor) => floor.blockId == secondMapping.blockId && floor.ordinal == 2,
      );
      final exact = CreateInventoryAssetCommand(
        operationId: _uuid(12010),
        projectId: _projectA,
        assetId: _uuid(12011),
        placementId: _uuid(12012),
        placementKey: _uuid(12013),
        sketchId: sketchA.sketchId,
        activeRevisionId: sketchA.activeRevisionId,
        floorId: exactFloor.id,
        displayName: 'İkinci kat aracı',
        category: InventoryCategory.equipment,
        totalQuantity: 1,
        x: 256,
        y: 256,
      );
      final result = await fixture.app.createAsset(exact);
      expect(result.isNoOp, isFalse);
      expect(
        (await fixture.app.loadAsset(
          projectId: _projectA,
          assetId: exact.assetId,
        )).activePlacement!.floorId,
        exactFloor.id,
      );
      expect(
        (await fixture.db.database.query(
          'inventory_asset_placements',
          columns: const ['floor_id'],
          where: 'id = ?',
          whereArgs: [exact.placementId],
        )).single['floor_id'],
        exactFloor.id,
      );
      final placementEvent =
          (await fixture.app.listAssetHistory(
            projectId: _projectA,
            assetId: exact.assetId,
          )).singleWhere(
            (event) => event.eventType == InventoryEventType.placementCreated,
          );
      expect(placementEvent.payload['floor_id'], exactFloor.id);

      final afterExact = await _counts(fixture.db.database);
      final replay = await fixture.app.createAsset(exact);
      expect(_resultValues(replay), _resultValues(result));
      expect(await _counts(fixture.db.database), afterExact);
      await expectLater(
        fixture.app.createAsset(
          CreateInventoryAssetCommand(
            operationId: exact.operationId,
            projectId: exact.projectId,
            assetId: exact.assetId,
            placementId: exact.placementId,
            placementKey: exact.placementKey,
            sketchId: exact.sketchId,
            activeRevisionId: exact.activeRevisionId,
            floorId: projectionA.floors
                .singleWhere(
                  (floor) =>
                      floor.blockId == firstMapping.blockId &&
                      floor.ordinal == 1,
                )
                .id,
            displayName: exact.displayName,
            category: exact.category,
            totalQuantity: exact.totalQuantity,
            x: exact.x,
            y: exact.y,
          ),
        ),
        _fails('inventory_operation_id_conflict'),
      );
      expect(await _counts(fixture.db.database), afterExact);

      await expectLater(
        fixture.app.createAsset(
          CreateInventoryAssetCommand(
            operationId: _uuid(12020),
            projectId: _projectA,
            assetId: _uuid(12021),
            placementId: _uuid(12022),
            placementKey: _uuid(12023),
            sketchId: sketchA.sketchId,
            activeRevisionId: sketchA.activeRevisionId,
            floorId: otherBlockFloor.id,
            displayName: 'Yanlış blok',
            category: InventoryCategory.handTool,
            totalQuantity: 1,
            x: 256,
            y: 256,
          ),
        ),
        _fails('inventory_floor_unavailable'),
      );
      expect(await _counts(fixture.db.database), afterExact);

      await expectLater(
        fixture.app.createAsset(
          CreateInventoryAssetCommand(
            operationId: _uuid(12030),
            projectId: _projectA,
            assetId: _uuid(12031),
            placementId: _uuid(12032),
            placementKey: _uuid(12033),
            sketchId: sketchA.sketchId,
            activeRevisionId: sketchA.activeRevisionId,
            floorId: exactFloor.id,
            displayName: 'Sınır noktası',
            category: InventoryCategory.handTool,
            totalQuantity: 1,
            x: 0,
            y: 256,
          ),
        ),
        _fails('inventory_floor_unavailable'),
      );
      expect(await _counts(fixture.db.database), afterExact);

      await _createFinalizedSketch(fixture, seed: 12100, projectId: _projectB);
      final projectionB = (await fixture.app.loadPrimarySketch(_projectB))!;
      final projectBFloor = projectionB.floors.first;
      final beforeCrossProject = await _counts(fixture.db.database);
      await expectLater(
        fixture.app.createAsset(
          CreateInventoryAssetCommand(
            operationId: _uuid(12110),
            projectId: _projectA,
            assetId: _uuid(12111),
            placementId: _uuid(12112),
            placementKey: _uuid(12113),
            sketchId: sketchA.sketchId,
            activeRevisionId: sketchA.activeRevisionId,
            floorId: projectBFloor.id,
            displayName: 'Yanlış proje katı',
            category: InventoryCategory.handTool,
            totalQuantity: 1,
            x: 256,
            y: 256,
          ),
        ),
        _fails('inventory_floor_unavailable'),
      );
      expect(await _counts(fixture.db.database), beforeCrossProject);
    },
  );

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
          newBlocks: _blockDrafts(sketchId, _geometry()),
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
          newBlocks: _blockDrafts(sketchId, _geometry()),
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
            newBlocks: _blockDrafts(sketchId, _geometry(64)),
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
          newBlocks: _blockDrafts(sketchId, _geometry()),
        ),
      );
      projection = await fixture.app.loadPrimarySketch(_projectA);
      expect(projection!.activeRevision!.id, firstDraft);
      expect(projection.draftRevision, isNull);
      expect(projection.blocks, hasLength(1));
      expect(projection.blocks.single.state, InventoryBlockState.active);
      expect(projection.blocks.single.ordinal, 1);
      expect(projection.blocks.single.normalizedName, 'alan 1');
      expect(projection.floors, hasLength(2));
      expect(projection.floors.map((floor) => floor.ordinal), [1, 2]);
      expect(
        projection.floors.every(
          (floor) => floor.blockId == projection!.blocks.single.id,
        ),
        isTrue,
      );
      expect(projection.activeBlockPolygons, hasLength(1));
      expect(
        projection.activeBlockPolygons.single.blockId,
        projection.blocks.single.id,
      );
      expect(projection.activeBlockPolygons.single.polygonIndex, 0);
      final firstBlockId = projection.blocks.single.id;
      final firstFloorId = projection.floors.first.id;

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
      final rewrittenBase = InventoryGeometry(
        polylines: [
          _rectangle(0, 0, 1984, 1536),
          _rectangle(2560, 0, 2944, 512),
        ],
      );
      final beforeRejectedAutosaves = await _counts(fixture.db.database);
      await expectLater(
        fixture.app.autosaveSketchDraft(
          AutosaveInventorySketchDraftCommand(
            operationId: _uuid(224),
            projectId: _projectA,
            sketchId: sketchId,
            draftRevisionId: secondDraft,
            expectedSketchRevision: 4,
            expectedContentRevision: 1,
            geometry: rewrittenBase,
            newBlocks: _blockDrafts(
              sketchId,
              rewrittenBase,
              firstPolygonIndex: 1,
            ),
          ),
        ),
        _fails('inventory_block_geometry_immutable'),
      );
      final overlapping = InventoryGeometry(
        polylines: [
          _rectangle(0, 0, 2048, 1536),
          _rectangle(512, 512, 1024, 1024),
        ],
      );
      await expectLater(
        fixture.app.autosaveSketchDraft(
          AutosaveInventorySketchDraftCommand(
            operationId: _uuid(225),
            projectId: _projectA,
            sketchId: sketchId,
            draftRevisionId: secondDraft,
            expectedSketchRevision: 4,
            expectedContentRevision: 1,
            geometry: overlapping,
            newBlocks: _blockDrafts(
              sketchId,
              overlapping,
              firstPolygonIndex: 1,
            ),
          ),
        ),
        _fails('inventory_block_polygon_ambiguous'),
      );
      expect(await _counts(fixture.db.database), beforeRejectedAutosaves);
      await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(209),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: secondDraft,
          expectedSketchRevision: 4,
          expectedContentRevision: 1,
          geometry: _geometry(64),
          newBlocks: _blockDrafts(
            sketchId,
            _geometry(64),
            firstPolygonIndex: 1,
          ),
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
          newBlocks: _blockDrafts(
            sketchId,
            _geometry(64),
            firstPolygonIndex: 1,
          ),
        ),
      );
      projection = await fixture.app.loadPrimarySketch(_projectA);
      expect(projection!.blocks, hasLength(2));
      expect(projection.blocks.map((block) => block.ordinal), [1, 2]);
      expect(projection.floors, hasLength(4));
      expect(projection.activeBlockPolygons, hasLength(2));
      expect(
        projection.blocks.firstWhere((block) => block.id == firstBlockId).state,
        InventoryBlockState.active,
      );
      expect(
        projection.floors
            .singleWhere((floor) => floor.id == firstFloorId)
            .blockId,
        firstBlockId,
      );
      expect(
        projection.activeBlockPolygons
            .singleWhere((mapping) => mapping.blockId == firstBlockId)
            .polygonIndex,
        0,
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
      expect(
        (await fixture.db.database.query(
          'inventory_blocks',
        )).map((row) => row['state']).toSet(),
        {InventoryBlockState.archived.storageValue},
      );
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
      expect(
        (await fixture.db.database.query(
          'inventory_blocks',
        )).map((row) => row['state']).toSet(),
        {InventoryBlockState.active.storageValue},
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
      final stableFloorId = firstProjection.activePlacement!.floorId;
      final spatialAfterCreate = (await fixture.app.loadPrimarySketch(
        _projectA,
      ))!;
      expect(
        spatialAfterCreate.floors.map((floor) => floor.id),
        contains(stableFloorId),
      );
      final stableFloor = spatialAfterCreate.floors.singleWhere(
        (floor) => floor.id == stableFloorId,
      );
      final owningBlock = spatialAfterCreate.blocks.singleWhere(
        (block) => block.id == stableFloor.blockId,
      );
      final owningMapping = spatialAfterCreate.activeBlockPolygons.singleWhere(
        (mapping) => mapping.blockId == owningBlock.id,
      );
      expect(owningBlock.state, InventoryBlockState.active);
      expect(stableFloor.ordinal, 1);
      expect(
        InventorySpatialContract.containsPlacement(
          spatialAfterCreate.activeRevision!.geometry.polylines[owningMapping
              .polygonIndex],
          x: firstProjection.activePlacement!.x,
          y: firstProjection.activePlacement!.y,
        ),
        isTrue,
      );

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
      expect(
        versions.every((placement) => placement.floorId == stableFloorId),
        isTrue,
      );

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
    'MT-527-006 normalized duplicate block name fails before mutation',
    () async {
      final fixture = await _Fixture.create('mt_527_006_duplicate');
      addTearDown(fixture.close);
      final sketchId = _uuid(850);
      final draftId = _uuid(851);
      await fixture.app.createSketch(
        CreateInventorySketchCommand(
          operationId: _uuid(852),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: draftId,
        ),
      );
      final geometry = _geometry(64);
      final sourceBlocks = _blockDrafts(sketchId, geometry);
      final duplicateBlocks = [
        InventoryBlockDraft(
          id: sourceBlocks[0].id,
          displayName: 'Alan',
          polygonIndex: sourceBlocks[0].polygonIndex,
          floors: sourceBlocks[0].floors,
        ),
        InventoryBlockDraft(
          id: sourceBlocks[1].id,
          displayName: 'alan',
          polygonIndex: sourceBlocks[1].polygonIndex,
          floors: sourceBlocks[1].floors,
        ),
      ];
      final countsBefore = await _counts(fixture.db.database);
      final sketchBefore = (await fixture.db.database.query(
        'inventory_sketches',
        where: 'id = ?',
        whereArgs: [sketchId],
      )).single;
      final revisionBefore = (await fixture.db.database.query(
        'inventory_sketch_revisions',
        where: 'id = ?',
        whereArgs: [draftId],
      )).single;
      final spatialBefore = (await fixture.db.database.query(
        'inventory_sketch_revision_spatial_drafts',
        where: 'revision_id = ?',
        whereArgs: [draftId],
      )).single;

      await expectLater(
        Future<InventoryMutationResult>.sync(
          () => fixture.app.finalizeSketch(
            FinalizeInventorySketchCommand(
              operationId: _uuid(853),
              projectId: _projectA,
              sketchId: sketchId,
              draftRevisionId: draftId,
              expectedSketchRevision: 1,
              expectedContentRevision: 1,
              newBlocks: duplicateBlocks,
            ),
          ),
        ),
        _fails('inventory_block_name_conflict'),
      );

      expect(await _counts(fixture.db.database), countsBefore);
      expect(
        (await fixture.db.database.query(
          'inventory_sketches',
          where: 'id = ?',
          whereArgs: [sketchId],
        )).single,
        sketchBefore,
      );
      expect(
        (await fixture.db.database.query(
          'inventory_sketch_revisions',
          where: 'id = ?',
          whereArgs: [draftId],
        )).single,
        revisionBefore,
      );
      expect(
        (await fixture.db.database.query(
          'inventory_sketch_revision_spatial_drafts',
          where: 'revision_id = ?',
          whereArgs: [draftId],
        )).single,
        spatialBefore,
      );
      expect(
        await fixture.db.database.query(
          'inventory_command_receipts',
          where: 'id = ?',
          whereArgs: [_uuid(853)],
        ),
        isEmpty,
      );
    },
  );

  test(
    'MT-527-008 cross-block move preserves placement and event truth',
    () async {
      final fixture = await _Fixture.create('mt_527_008_cross_block');
      addTearDown(fixture.close);
      final geometry = _geometry(64);
      final sketch = await _createFinalizedSketch(
        fixture,
        seed: 860,
        geometry: geometry,
      );
      final spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      InventoryFloorRecord firstFloorForPolygon(int polygonIndex) {
        final mapping = spatial.activeBlockPolygons.singleWhere(
          (item) => item.polygonIndex == polygonIndex,
        );
        return spatial.floors.singleWhere(
          (floor) => floor.blockId == mapping.blockId && floor.ordinal == 1,
        );
      }

      final firstFloor = firstFloorForPolygon(0);
      final secondFloor = firstFloorForPolygon(1);
      expect(secondFloor.id, isNot(firstFloor.id));
      final assetId = _uuid(870);
      final placementKey = _uuid(871);
      final firstPlacementId = _uuid(872);
      await fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(873),
          projectId: _projectA,
          assetId: assetId,
          placementId: firstPlacementId,
          placementKey: placementKey,
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          displayName: 'Taşınan kayıt',
          category: InventoryCategory.equipment,
          totalQuantity: 1,
          x: 128,
          y: 128,
        ),
      );
      expect(
        (await fixture.app.loadAsset(
          projectId: _projectA,
          assetId: assetId,
        )).activePlacement!.floorId,
        firstFloor.id,
      );

      final sameBlockPlacementId = _uuid(874);
      await fixture.app.movePlacement(
        MoveInventoryPlacementCommand(
          operationId: _uuid(875),
          projectId: _projectA,
          assetId: assetId,
          placementKey: placementKey,
          successorPlacementId: sameBlockPlacementId,
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          expectedPlacementSequence: 1,
          x: 512,
          y: 512,
        ),
      );
      expect(
        (await fixture.app.loadAsset(
          projectId: _projectA,
          assetId: assetId,
        )).activePlacement!.floorId,
        firstFloor.id,
      );

      final crossBlockPlacementId = _uuid(876);
      await fixture.app.movePlacement(
        MoveInventoryPlacementCommand(
          operationId: _uuid(877),
          projectId: _projectA,
          assetId: assetId,
          placementKey: placementKey,
          successorPlacementId: crossBlockPlacementId,
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          expectedPlacementSequence: 2,
          x: 2704,
          y: 128,
        ),
      );
      final active = (await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: assetId,
      )).activePlacement!;
      expect(active.id, crossBlockPlacementId);
      expect(active.floorId, secondFloor.id);
      expect(active.x, 2704);
      expect(active.y, 128);

      final versions = await fixture.app.listPlacementVersions(
        projectId: _projectA,
        assetId: assetId,
        placementKey: placementKey,
      );
      expect(versions.map((item) => item.id), [
        firstPlacementId,
        sameBlockPlacementId,
        crossBlockPlacementId,
      ]);
      expect(versions.map((item) => item.sequence), [1, 2, 3]);
      expect(versions.map((item) => item.floorId), [
        firstFloor.id,
        firstFloor.id,
        secondFloor.id,
      ]);
      expect(versions.map((item) => item.supersedesPlacementId), [
        null,
        firstPlacementId,
        sameBlockPlacementId,
      ]);
      expect(versions.map((item) => item.endReason), [
        InventoryPlacementEndReason.moved,
        InventoryPlacementEndReason.moved,
        null,
      ]);
      expect(versions.map((item) => item.isActive), [false, false, true]);
      expect(
        versions.every((item) => item.placementKey == placementKey),
        isTrue,
      );

      final moves = (await fixture.app.listAssetHistory(
        projectId: _projectA,
        assetId: assetId,
      )).where((event) => event.eventType == InventoryEventType.placementMoved);
      expect(moves, hasLength(2));
      final sameBlockEvent = moves.singleWhere(
        (event) => event.payload['sequence'] == 2,
      );
      expect(sameBlockEvent.payload['before_floor_id'], firstFloor.id);
      expect(sameBlockEvent.payload['after_floor_id'], firstFloor.id);
      final crossBlockEvent = moves.singleWhere(
        (event) => event.payload['sequence'] == 3,
      );
      expect(crossBlockEvent.payload['before_floor_id'], firstFloor.id);
      expect(crossBlockEvent.payload['after_floor_id'], secondFloor.id);
      expect(crossBlockEvent.payload['before_x'], 512);
      expect(crossBlockEvent.payload['before_y'], 512);
      expect(crossBlockEvent.payload['after_x'], 2704);
      expect(crossBlockEvent.payload['after_y'], 128);
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
      final floorId =
          (await fixture.db.database.query(
                'inventory_asset_placements',
                columns: const ['floor_id'],
                where: 'asset_id = ? AND ended_at IS NULL',
                whereArgs: [assetId],
              )).single['floor_id']!
              as String;
      await fixture.db.database.insert('inventory_asset_placements', {
        'id': _uuid(514),
        'placement_key': _uuid(515),
        'project_id': _projectA,
        'asset_id': assetId,
        'sketch_id': sketch.sketchId,
        'provenance_revision_id': sketch.activeRevisionId,
        'floor_id': floorId,
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

  test(
    'inventory photo add replace remove replay and relaunch preserve history',
    () async {
      final fixture = await _Fixture.create('photo_lifecycle');
      addTearDown(fixture.close);
      final sketch = await _createFinalizedSketch(fixture, seed: 600);
      final assetId = _uuid(610);
      await _createAsset(fixture, sketch: sketch, assetId: assetId, seed: 611);
      final gateway = _MemoryInventoryAttachmentGateway();
      final app = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
        attachmentGateway: gateway,
      );
      final first = AddOrReplaceInventoryAssetPhotoCommand(
        operationId: _uuid(620),
        projectId: _projectA,
        assetId: assetId,
        linkId: _uuid(621),
        attachmentId: _uuid(622),
        expectedAssetRevision: 1,
        selection: InventoryPhotoSelection(
          originalFileName: 'first.jpg',
          bytes: _jpeg(1),
          source: InventoryPhotoSource.camera,
        ),
      );

      final added = await app.addOrReplaceAssetPhoto(first);
      final replay = await app.addOrReplaceAssetPhoto(first);
      expect(_resultValues(replay), _resultValues(added));
      expect(gateway.stageCalls, 1);
      var active = await app.loadActiveAssetPhoto(
        projectId: _projectA,
        assetId: assetId,
      );
      expect(active?.linkId, first.linkId);
      expect(active?.integrity, InventoryPhotoIntegrity.healthy);
      expect(
        (await app.readAssetPhoto(
          projectId: _projectA,
          assetId: assetId,
          linkId: first.linkId,
        )).bytes,
        _jpeg(1),
      );

      final replacement = AddOrReplaceInventoryAssetPhotoCommand(
        operationId: _uuid(623),
        projectId: _projectA,
        assetId: assetId,
        linkId: _uuid(624),
        attachmentId: _uuid(625),
        expectedAssetRevision: 1,
        selection: InventoryPhotoSelection(
          originalFileName: 'replacement.png',
          bytes: _png(2),
          source: InventoryPhotoSource.photoLibrary,
        ),
      );
      await app.addOrReplaceAssetPhoto(replacement);
      active = await app.loadActiveAssetPhoto(
        projectId: _projectA,
        assetId: assetId,
      );
      expect(active?.linkId, replacement.linkId);
      final links = await fixture.db.database.query(
        'inventory_asset_attachment_links',
        where: 'asset_id = ?',
        whereArgs: [assetId],
        orderBy: 'created_at ASC, id ASC',
      );
      expect(links, hasLength(2));
      expect(links.first['archived_at'], isNotNull);
      expect(links.last['archived_at'], isNull);
      expect(gateway.files, hasLength(2));

      final activeRelaunch = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
        attachmentGateway: gateway,
      );
      expect(
        (await activeRelaunch.loadActiveAssetPhoto(
          projectId: _projectA,
          assetId: assetId,
        ))?.linkId,
        replacement.linkId,
      );
      expect(
        (await activeRelaunch.readAssetPhoto(
          projectId: _projectA,
          assetId: assetId,
          linkId: replacement.linkId,
        )).bytes,
        _png(2),
      );

      await app.removeAssetPhoto(
        RemoveInventoryAssetPhotoCommand(
          operationId: _uuid(626),
          projectId: _projectA,
          assetId: assetId,
          linkId: replacement.linkId,
          expectedAssetRevision: 1,
          expectedLinkRevision: 1,
        ),
      );
      expect(
        await app.loadActiveAssetPhoto(projectId: _projectA, assetId: assetId),
        isNull,
      );
      expect(gateway.files, hasLength(2));
      expect(gateway.cleanedPaths, isEmpty);
      final history = await app.listAssetHistory(
        projectId: _projectA,
        assetId: assetId,
      );
      expect(
        history.map((event) => event.eventType),
        containsAll(<InventoryEventType>[
          InventoryEventType.photoLinked,
          InventoryEventType.photoArchived,
        ]),
      );

      final relaunched = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
        attachmentGateway: gateway,
      );
      expect(
        (await relaunched.loadAsset(
          projectId: _projectA,
          assetId: assetId,
        )).activePlacement,
        isNotNull,
      );
      expect(
        await relaunched.loadActiveAssetPhoto(
          projectId: _projectA,
          assetId: assetId,
        ),
        isNull,
      );
      expect(
        await fixture.db.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
    },
  );

  test(
    'inventory photo failures clean only new bytes and reject unsafe identity',
    () async {
      final fixture = await _Fixture.create('photo_failure');
      addTearDown(fixture.close);
      final sketch = await _createFinalizedSketch(fixture, seed: 650);
      final assetId = _uuid(660);
      await _createAsset(fixture, sketch: sketch, assetId: assetId, seed: 661);
      final gateway = _MemoryInventoryAttachmentGateway();
      final healthy = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
        attachmentGateway: gateway,
      );
      await healthy.addOrReplaceAssetPhoto(
        AddOrReplaceInventoryAssetPhotoCommand(
          operationId: _uuid(670),
          projectId: _projectA,
          assetId: assetId,
          linkId: _uuid(671),
          attachmentId: _uuid(672),
          expectedAssetRevision: 1,
          selection: InventoryPhotoSelection(
            originalFileName: 'retained.jpg',
            bytes: _jpeg(3),
            source: InventoryPhotoSource.camera,
          ),
        ),
      );
      final retainedPath = gateway.files.keys.single;
      final stageCallsBeforeGuards = gateway.stageCalls;
      await expectLater(
        healthy.addOrReplaceAssetPhoto(
          AddOrReplaceInventoryAssetPhotoCommand(
            operationId: _uuid(673),
            projectId: _projectB,
            assetId: assetId,
            linkId: _uuid(674),
            attachmentId: _uuid(675),
            expectedAssetRevision: 1,
            selection: InventoryPhotoSelection(
              originalFileName: 'wrong-project.jpg',
              bytes: _jpeg(4),
              source: InventoryPhotoSource.camera,
            ),
          ),
        ),
        _fails('inventory_asset_unavailable'),
      );
      await expectLater(
        healthy.addOrReplaceAssetPhoto(
          AddOrReplaceInventoryAssetPhotoCommand(
            operationId: _uuid(676),
            projectId: _projectA,
            assetId: assetId,
            linkId: _uuid(677),
            attachmentId: _uuid(678),
            expectedAssetRevision: 2,
            selection: InventoryPhotoSelection(
              originalFileName: 'stale.jpg',
              bytes: _jpeg(5),
              source: InventoryPhotoSource.camera,
            ),
          ),
        ),
        _fails('inventory_stale_revision'),
      );
      expect(gateway.stageCalls, stageCallsBeforeGuards);

      final failing = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
        attachmentGateway: gateway,
        afterSourceWritesBeforeHistory: () async {
          throw StateError('injected photo DB failure');
        },
      );
      await expectLater(
        failing.addOrReplaceAssetPhoto(
          AddOrReplaceInventoryAssetPhotoCommand(
            operationId: _uuid(679),
            projectId: _projectA,
            assetId: assetId,
            linkId: _uuid(680),
            attachmentId: _uuid(681),
            expectedAssetRevision: 1,
            selection: InventoryPhotoSelection(
              originalFileName: 'rollback.png',
              bytes: _png(6),
              source: InventoryPhotoSource.photoLibrary,
            ),
          ),
        ),
        _fails('inventory_persistence_failed'),
      );
      expect(gateway.cleanedPaths, hasLength(1));
      expect(gateway.files.keys, [retainedPath]);
      expect(
        (await healthy.loadActiveAssetPhoto(
          projectId: _projectA,
          assetId: assetId,
        ))?.originalFileName,
        'retained.jpg',
      );

      await fixture.app.archiveAsset(
        ArchiveInventoryAssetCommand(
          operationId: _uuid(682),
          projectId: _projectA,
          assetId: assetId,
          expectedAssetRevision: 1,
        ),
      );
      expect(
        await healthy.readAssetPhoto(
          projectId: _projectA,
          assetId: assetId,
          linkId: _uuid(671),
        ),
        isA<InventoryPhotoContent>(),
      );
      final callsBeforeArchived = gateway.stageCalls;
      await expectLater(
        healthy.addOrReplaceAssetPhoto(
          AddOrReplaceInventoryAssetPhotoCommand(
            operationId: _uuid(683),
            projectId: _projectA,
            assetId: assetId,
            linkId: _uuid(684),
            attachmentId: _uuid(685),
            expectedAssetRevision: 2,
            selection: InventoryPhotoSelection(
              originalFileName: 'archived.jpg',
              bytes: _jpeg(7),
              source: InventoryPhotoSource.camera,
            ),
          ),
        ),
        _fails('inventory_asset_archived'),
      );
      expect(gateway.stageCalls, callsBeforeArchived);
    },
  );

  test(
    'first and edit-active drafts recover exact durable identity after recreation',
    () async {
      final fixture = await _Fixture.create('draft_relaunch');
      addTearDown(fixture.close);
      final sketchId = _uuid(700);
      final firstDraftId = _uuid(701);
      await fixture.app.createSketch(
        CreateInventorySketchCommand(
          operationId: _uuid(702),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: firstDraftId,
        ),
      );
      await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(703),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: firstDraftId,
          expectedSketchRevision: 1,
          expectedContentRevision: 1,
          geometry: _geometry(64),
          newBlocks: _blockDrafts(sketchId, _geometry(64)),
        ),
      );
      final firstRelaunch = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
      );
      var recovered = await firstRelaunch.loadPrimarySketch(_projectA);
      expect(recovered?.activeRevision, isNull);
      expect(recovered?.draftRevision?.id, firstDraftId);
      expect(
        recovered?.draftRevision?.geometry.canonicalJson,
        _geometry(64).canonicalJson,
      );

      await firstRelaunch.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _uuid(704),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: firstDraftId,
          expectedSketchRevision: 2,
          expectedContentRevision: 2,
          newBlocks: _blockDrafts(sketchId, _geometry(64)),
        ),
      );
      final editDraftId = _uuid(705);
      await firstRelaunch.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(706),
          projectId: _projectA,
          sketchId: sketchId,
          activeRevisionId: firstDraftId,
          newDraftRevisionId: editDraftId,
          expectedSketchRevision: 3,
        ),
      );
      await firstRelaunch.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(707),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: editDraftId,
          expectedSketchRevision: 4,
          expectedContentRevision: 1,
          geometry: _geometry(128),
          newBlocks: _blockDrafts(
            sketchId,
            _geometry(128),
            firstPolygonIndex: 2,
          ),
        ),
      );

      final editRelaunch = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
      );
      recovered = await editRelaunch.loadPrimarySketch(_projectA);
      expect(recovered?.activeRevision?.id, firstDraftId);
      expect(recovered?.draftRevision?.id, editDraftId);
      expect(recovered?.draftRevision?.baseRevisionId, firstDraftId);
      expect(
        recovered?.draftRevision?.geometry.canonicalJson,
        _geometry(128).canonicalJson,
      );
      expect(recovered?.draftNewBlocks, hasLength(1));
      expect(recovered?.draftNewBlocks.single.polygonIndex, 2);
      expect(
        InventoryGeometry(
          polylines: recovered!.draftRevision!.geometry.polylines
              .take(2)
              .toList(),
        ).canonicalJson,
        _geometry(64).canonicalJson,
      );

      await editRelaunch.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _uuid(708),
          projectId: _projectA,
          sketchId: sketchId,
          draftRevisionId: editDraftId,
          expectedSketchRevision: recovered.sketch.revision,
          expectedContentRevision: recovered.draftRevision!.contentRevision,
          newBlocks: recovered.draftNewBlocks,
        ),
      );
      final finalized = await editRelaunch.loadPrimarySketch(_projectA);
      expect(finalized?.draftRevision, isNull);
      expect(finalized?.activeRevision?.id, editDraftId);
      expect(finalized?.activeRevision?.baseRevisionId, firstDraftId);
      expect(
        finalized?.activeRevision?.geometry.canonicalJson,
        _geometry(128).canonicalJson,
      );
      expect(
        InventoryGeometry(
          polylines: finalized!.activeRevision!.geometry.polylines
              .take(2)
              .toList(),
        ).canonicalJson,
        _geometry(64).canonicalJson,
      );
      expect(
        (await fixture.db.database.query(
          'inventory_sketch_revision_block_polygons',
          columns: const ['polygon_index'],
          where: 'revision_id = ?',
          whereArgs: [editDraftId],
          orderBy: 'polygon_index ASC',
        )).map((row) => row['polygon_index']),
        [0, 1, 2],
      );
      expect(
        (await fixture.db.database.query(
          'inventory_sketch_revisions',
          where: 'sketch_id = ?',
          whereArgs: [sketchId],
          orderBy: 'revision_number ASC',
        )).map((row) => row['state']),
        [
          InventorySketchRevisionState.superseded.storageValue,
          InventorySketchRevisionState.active.storageValue,
        ],
      );
      List<Object?> blockTruth(InventoryBlockRecord block) => [
        block.id,
        block.projectId,
        block.displayName,
        block.normalizedName,
        block.ordinal,
        block.state,
        block.revision,
        block.createdAt,
        block.updatedAt,
        block.archivedAt,
      ];
      List<Object?> floorTruth(InventoryFloorRecord floor) => [
        floor.id,
        floor.blockId,
        floor.projectId,
        floor.displayName,
        floor.ordinal,
        floor.revision,
        floor.createdAt,
        floor.updatedAt,
        floor.archivedAt,
      ];
      List<Object?> mappingTruth(InventoryRevisionBlockPolygonRecord mapping) =>
          [
            mapping.revisionId,
            mapping.blockId,
            mapping.projectId,
            mapping.sketchId,
            mapping.polygonIndex,
            mapping.createdAt,
          ];

      final blockSnapshot = finalized.blocks.map(blockTruth).toList();
      final floorSnapshot = finalized.floors.map(floorTruth).toList();
      final mappingSnapshot = finalized.activeBlockPolygons
          .map(mappingTruth)
          .toList();
      await fixture.db.close();
      await fixture.db.open();
      final finalizedRelaunch = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
      );
      final durable = (await finalizedRelaunch.loadPrimarySketch(_projectA))!;
      expect(durable.draftRevision, isNull);
      expect(durable.activeRevision!.id, editDraftId);
      expect(
        durable.activeRevision!.geometry.canonicalJson,
        finalized.activeRevision!.geometry.canonicalJson,
      );
      expect(
        durable.activeRevision!.geometrySha256,
        finalized.activeRevision!.geometrySha256,
      );
      expect(durable.blocks.map(blockTruth).toList(), blockSnapshot);
      expect(durable.floors.map(floorTruth).toList(), floorSnapshot);
      expect(
        durable.activeBlockPolygons.map(mappingTruth).toList(),
        mappingSnapshot,
      );
    },
  );

  test(
    'AT-533-002/003/004/005 rigid and non-rigid reconciliation is deterministic, historical, and idempotent',
    () async {
      final fixture = await _Fixture.create('at_533_reconciliation');
      addTearDown(fixture.close);
      final sketch = await _createFinalizedSketch(fixture, seed: 16000);
      var spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      final block = spatial.blocks.single;
      final floor = spatial.floors.firstWhere(
        (item) => item.blockId == block.id && item.ordinal == 1,
      );
      final stableAssetId = _uuid(16010);
      await fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(16011),
          projectId: _projectA,
          assetId: stableAssetId,
          placementId: _uuid(16012),
          placementKey: _uuid(16013),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          floorId: floor.id,
          displayName: 'Stable interior',
          category: InventoryCategory.equipment,
          totalQuantity: 1,
          x: 128,
          y: 128,
        ),
      );
      final rigidPeerAssetId = _uuid(16014);
      await fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(16015),
          projectId: _projectA,
          assetId: rigidPeerAssetId,
          placementId: _uuid(16016),
          placementKey: _uuid(16017),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          floorId: floor.id,
          displayName: 'Rigid peer',
          category: InventoryCategory.handTool,
          totalQuantity: 1,
          x: 384,
          y: 256,
        ),
      );
      final beforeRigid = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: stableAssetId,
      );
      final peerBeforeRigid = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: rigidPeerAssetId,
      );
      final rigidDraftId = _uuid(16020);
      await _seedLegacyPrefixEditDraft(
        fixture,
        draftId: rigidDraftId,
        legacyPolygonCount: spatial.activeRevision!.geometry.polylines.length,
      );
      spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      expect(
        spatial.draftLegacyPolygonCount,
        spatial.activeRevision!.geometry.polylines.length,
      );
      final rigidGeometry = InventoryGeometry(
        polylines: [_rectangle(64, 0, 2112, 1536)],
      );
      await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(16022),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: rigidDraftId,
          expectedSketchRevision: spatial.sketch.revision,
          expectedContentRevision: spatial.draftRevision!.contentRevision,
          geometry: rigidGeometry,
          existingBlockMappings: [
            InventoryExistingBlockMappingDraft(
              blockId: block.id,
              polygonIndex: 0,
            ),
          ],
        ),
      );
      spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      expect(spatial.draftLegacyPolygonCount, 0);
      final rigidCommand = FinalizeInventorySketchCommand(
        operationId: _uuid(16023),
        projectId: _projectA,
        sketchId: sketch.sketchId,
        draftRevisionId: rigidDraftId,
        expectedSketchRevision: spatial.sketch.revision,
        expectedContentRevision: spatial.draftRevision!.contentRevision,
        existingBlockIntents: [
          InventoryExistingBlockFinalizeIntent(
            blockId: block.id,
            action: InventoryExistingBlockAction.retainMapped,
            expectedBlockRevision: block.revision,
            targetPolygonIndex: 0,
          ),
        ],
        placementExpectations: await _placementExpectations(fixture.app),
      );
      final rigidResult = await fixture.app.finalizeSketch(rigidCommand);
      expect(rigidResult.eventCount, 3);
      final afterRigid = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: stableAssetId,
      );
      final peerAfterRigid = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: rigidPeerAssetId,
      );
      expect(
        afterRigid.activePlacement!.x,
        beforeRigid.activePlacement!.x + 64,
      );
      expect(afterRigid.activePlacement!.y, beforeRigid.activePlacement!.y);
      expect(
        afterRigid.activePlacement!.sequence,
        beforeRigid.activePlacement!.sequence + 1,
      );
      expect(
        peerAfterRigid.activePlacement!.x,
        peerBeforeRigid.activePlacement!.x + 64,
      );
      expect(
        peerAfterRigid.activePlacement!.y,
        peerBeforeRigid.activePlacement!.y,
      );
      expect(
        peerAfterRigid.activePlacement!.sequence,
        peerBeforeRigid.activePlacement!.sequence + 1,
      );
      expect(
        peerAfterRigid.activePlacement!.x - afterRigid.activePlacement!.x,
        peerBeforeRigid.activePlacement!.x - beforeRigid.activePlacement!.x,
      );
      expect(
        peerAfterRigid.activePlacement!.y - afterRigid.activePlacement!.y,
        peerBeforeRigid.activePlacement!.y - beforeRigid.activePlacement!.y,
      );
      final rigidEvents = await fixture.db.database.query(
        'inventory_events',
        where: 'operation_id = ?',
        whereArgs: [rigidCommand.operationId],
        orderBy: 'aggregate_type ASC',
      );
      expect(rigidEvents, hasLength(3));
      final rigidMoveRows = rigidEvents
          .where(
            (row) =>
                row['event_type'] ==
                InventoryEventType.placementMoved.storageValue,
          )
          .toList(growable: false);
      expect(rigidMoveRows, hasLength(2));
      final rigidMovePayload =
          jsonDecode(
                rigidMoveRows.singleWhere(
                      (row) =>
                          row['aggregate_id'] ==
                          beforeRigid.activePlacement!.placementKey,
                    )['payload_json']!
                    as String,
              )
              as Map<String, dynamic>;
      expect(rigidMovePayload['reason'], 'geometry_reconciliation');
      expect(rigidMovePayload['source_revision_id'], sketch.activeRevisionId);
      expect(rigidMovePayload['target_revision_id'], rigidDraftId);
      expect(rigidMovePayload['before_floor_id'], floor.id);
      expect(rigidMovePayload['after_floor_id'], floor.id);
      expect(rigidMovePayload['before_x'], beforeRigid.activePlacement!.x);
      expect(rigidMovePayload['before_y'], beforeRigid.activePlacement!.y);
      expect(rigidMovePayload['after_x'], afterRigid.activePlacement!.x);
      expect(rigidMovePayload['after_y'], afterRigid.activePlacement!.y);
      expect(
        rigidMovePayload['predecessor_placement_id'],
        beforeRigid.activePlacement!.id,
      );
      expect(rigidMovePayload['placement_id'], afterRigid.activePlacement!.id);
      final peerRigidMovePayload =
          jsonDecode(
                rigidMoveRows.singleWhere(
                      (row) =>
                          row['aggregate_id'] ==
                          peerBeforeRigid.activePlacement!.placementKey,
                    )['payload_json']!
                    as String,
              )
              as Map<String, dynamic>;
      expect(peerRigidMovePayload['reason'], 'geometry_reconciliation');
      expect(
        peerRigidMovePayload['before_x'],
        peerBeforeRigid.activePlacement!.x,
      );
      expect(
        peerRigidMovePayload['before_y'],
        peerBeforeRigid.activePlacement!.y,
      );
      expect(
        peerRigidMovePayload['after_x'],
        peerAfterRigid.activePlacement!.x,
      );
      expect(
        peerRigidMovePayload['after_y'],
        peerAfterRigid.activePlacement!.y,
      );
      expect(
        peerRigidMovePayload['predecessor_placement_id'],
        peerBeforeRigid.activePlacement!.id,
      );
      expect(
        peerRigidMovePayload['placement_id'],
        peerAfterRigid.activePlacement!.id,
      );
      final countsBeforeReplay = await _counts(fixture.db.database);
      final rigidReplay = await fixture.app.finalizeSketch(rigidCommand);
      expect(_resultValues(rigidReplay), _resultValues(rigidResult));
      expect(await _counts(fixture.db.database), countsBeforeReplay);

      spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      final outsideAssetId = _uuid(16030);
      await fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(16031),
          projectId: _projectA,
          assetId: outsideAssetId,
          placementId: _uuid(16032),
          placementKey: _uuid(16033),
          sketchId: sketch.sketchId,
          activeRevisionId: spatial.activeRevision!.id,
          floorId: floor.id,
          displayName: 'Outside after reshape',
          category: InventoryCategory.handTool,
          totalQuantity: 1,
          x: 2048,
          y: 128,
        ),
      );
      final stableBeforeReshape = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: stableAssetId,
      );
      final outsideBeforeReshape = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: outsideAssetId,
      );
      final nonRigidDraftId = _uuid(16040);
      await fixture.app.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(16041),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          activeRevisionId: spatial.activeRevision!.id,
          newDraftRevisionId: nonRigidDraftId,
          expectedSketchRevision: spatial.sketch.revision,
        ),
      );
      spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      final nonRigidGeometry = InventoryGeometry(
        polylines: [_rectangle(64, 0, 1024, 1536)],
      );
      await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(16042),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: nonRigidDraftId,
          expectedSketchRevision: spatial.sketch.revision,
          expectedContentRevision: spatial.draftRevision!.contentRevision,
          geometry: nonRigidGeometry,
          existingBlockMappings: [
            InventoryExistingBlockMappingDraft(
              blockId: block.id,
              polygonIndex: 0,
            ),
          ],
        ),
      );
      spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      final currentBlock = spatial.blocks.singleWhere(
        (item) => item.id == block.id,
      );
      final nonRigidCommand = FinalizeInventorySketchCommand(
        operationId: _uuid(16043),
        projectId: _projectA,
        sketchId: sketch.sketchId,
        draftRevisionId: nonRigidDraftId,
        expectedSketchRevision: spatial.sketch.revision,
        expectedContentRevision: spatial.draftRevision!.contentRevision,
        existingBlockIntents: [
          InventoryExistingBlockFinalizeIntent(
            blockId: block.id,
            action: InventoryExistingBlockAction.retainMapped,
            expectedBlockRevision: currentBlock.revision,
            targetPolygonIndex: 0,
          ),
        ],
        placementExpectations: await _placementExpectations(fixture.app),
      );
      final nonRigidResult = await fixture.app.finalizeSketch(nonRigidCommand);
      expect(nonRigidResult.eventCount, 2);
      final stableAfterReshape = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: stableAssetId,
      );
      final outsideAfterReshape = await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: outsideAssetId,
      );
      expect(
        stableAfterReshape.activePlacement!.id,
        stableBeforeReshape.activePlacement!.id,
      );
      expect(
        stableAfterReshape.activePlacement!.sequence,
        stableBeforeReshape.activePlacement!.sequence,
      );
      expect(
        outsideAfterReshape.activePlacement!.sequence,
        outsideBeforeReshape.activePlacement!.sequence + 1,
      );
      expect(
        InventorySpatialContract.safelyContainsPlacement(
          nonRigidGeometry.polylines.single,
          x: outsideAfterReshape.activePlacement!.x,
          y: outsideAfterReshape.activePlacement!.y,
        ),
        isTrue,
      );
      expect(
        await fixture.db.database.query(
          'inventory_events',
          where: 'operation_id = ? AND event_type = ?',
          whereArgs: [
            nonRigidCommand.operationId,
            InventoryEventType.placementMoved.storageValue,
          ],
        ),
        hasLength(1),
      );
    },
  );

  test(
    'AT-533-008/010/012/013 detach, reattach, archive, and name ambiguity preserve invariants',
    () async {
      final fixture = await _Fixture.create('at_533_lifecycle');
      addTearDown(fixture.close);
      final geometry = _geometry(64);
      final sketch = await _createFinalizedSketch(
        fixture,
        seed: 17000,
        geometry: geometry,
      );
      final gateway = _MemoryInventoryAttachmentGateway();
      final app = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
        attachmentGateway: gateway,
      );
      var spatial = (await app.loadPrimarySketch(_projectA))!;
      final firstMapping = spatial.activeBlockPolygons.singleWhere(
        (mapping) => mapping.polygonIndex == 0,
      );
      final secondMapping = spatial.activeBlockPolygons.singleWhere(
        (mapping) => mapping.polygonIndex == 1,
      );
      final firstBlockId = firstMapping.blockId;
      final secondBlockId = secondMapping.blockId;
      final firstFloor = spatial.floors.firstWhere(
        (floor) => floor.blockId == firstBlockId && floor.ordinal == 1,
      );
      final firstFloorIds = spatial.floors
          .where((floor) => floor.blockId == firstBlockId)
          .map((floor) => floor.id)
          .toList(growable: false);
      final firstPolygon =
          spatial.activeRevision!.geometry.polylines[firstMapping.polygonIndex];
      final secondPolygon = spatial
          .activeRevision!
          .geometry
          .polylines[secondMapping.polygonIndex];
      final assetId = _uuid(17010);
      await app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(17011),
          projectId: _projectA,
          assetId: assetId,
          placementId: _uuid(17012),
          placementKey: _uuid(17013),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          floorId: firstFloor.id,
          displayName: 'Lifecycle asset',
          category: InventoryCategory.equipment,
          totalQuantity: 1,
          x: 128,
          y: 128,
        ),
      );
      final secondAssetId = _uuid(17050);
      await app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(17051),
          projectId: _projectA,
          assetId: secondAssetId,
          placementId: _uuid(17052),
          placementKey: _uuid(17053),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          floorId: firstFloor.id,
          displayName: 'Lifecycle peer',
          category: InventoryCategory.handTool,
          totalQuantity: 1,
          x: 384,
          y: 256,
        ),
      );
      final photoLinkId = _uuid(17014);
      await app.addOrReplaceAssetPhoto(
        AddOrReplaceInventoryAssetPhotoCommand(
          operationId: _uuid(17015),
          projectId: _projectA,
          assetId: assetId,
          linkId: photoLinkId,
          attachmentId: _uuid(17016),
          expectedAssetRevision: 1,
          selection: InventoryPhotoSelection(
            originalFileName: 'lifecycle.jpg',
            bytes: _jpeg(17),
            source: InventoryPhotoSource.camera,
          ),
        ),
      );
      final photoPath = gateway.files.keys.single;
      final placementBeforeDetach = (await app.loadAsset(
        projectId: _projectA,
        assetId: assetId,
      )).activePlacement!;
      final secondPlacementBeforeDetach = (await app.loadAsset(
        projectId: _projectA,
        assetId: secondAssetId,
      )).activePlacement!;

      final detachDraftId = _uuid(17020);
      await app.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(17021),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          activeRevisionId: spatial.activeRevision!.id,
          newDraftRevisionId: detachDraftId,
          expectedSketchRevision: spatial.sketch.revision,
        ),
      );
      spatial = (await app.loadPrimarySketch(_projectA))!;
      final detachedGeometry = InventoryGeometry(polylines: [secondPolygon]);
      final detachAutosaveCommand = AutosaveInventorySketchDraftCommand(
        operationId: _uuid(17022),
        projectId: _projectA,
        sketchId: sketch.sketchId,
        draftRevisionId: detachDraftId,
        expectedSketchRevision: spatial.sketch.revision,
        expectedContentRevision: spatial.draftRevision!.contentRevision,
        geometry: detachedGeometry,
        existingBlockMappings: [
          InventoryExistingBlockMappingDraft(
            blockId: secondBlockId,
            polygonIndex: 0,
          ),
        ],
      );
      final detachAutosaveResult = await app.autosaveSketchDraft(
        detachAutosaveCommand,
      );
      spatial = (await app.loadPrimarySketch(_projectA))!;
      final detachReplacementDraftId = spatial.draftRevision!.id;
      expect(detachReplacementDraftId, isNot(detachDraftId));
      expect(spatial.draftRevision!.contentRevision, 1);
      expect(
        (await fixture.db.database.query(
          'inventory_sketch_revisions',
          columns: const ['state'],
          where: 'id = ?',
          whereArgs: [detachDraftId],
        )).single['state'],
        InventorySketchRevisionState.abandoned.storageValue,
      );
      expect(
        await fixture.db.database.query(
          'inventory_sketch_revision_block_polygons',
          where: 'revision_id = ?',
          whereArgs: [detachDraftId],
        ),
        hasLength(2),
      );
      expect(spatial.draftBlockPolygons.map((mapping) => mapping.blockId), [
        secondBlockId,
      ]);
      final detachAutosaveCounts = await _counts(fixture.db.database);
      expect(
        _resultValues(await app.autosaveSketchDraft(detachAutosaveCommand)),
        _resultValues(detachAutosaveResult),
      );
      expect(await _counts(fixture.db.database), detachAutosaveCounts);
      final detachAutosaveEvent = (await fixture.db.database.query(
        'inventory_events',
        where: 'operation_id = ?',
        whereArgs: [detachAutosaveCommand.operationId],
      )).single;
      final detachAutosavePayload =
          jsonDecode(detachAutosaveEvent['payload_json']! as String)
              as Map<String, dynamic>;
      expect(detachAutosavePayload['mapping_revision_replaced'], isTrue);
      expect(
        detachAutosavePayload['replaced_draft_revision_id'],
        detachDraftId,
      );
      expect(
        detachAutosavePayload['draft_revision_id'],
        detachReplacementDraftId,
      );
      final countsBeforeMissingIntent = await _counts(fixture.db.database);
      await expectLater(
        app.finalizeSketch(
          FinalizeInventorySketchCommand(
            operationId: _uuid(17023),
            projectId: _projectA,
            sketchId: sketch.sketchId,
            draftRevisionId: detachReplacementDraftId,
            expectedSketchRevision: spatial.sketch.revision,
            expectedContentRevision: spatial.draftRevision!.contentRevision,
          ),
        ),
        _fails('inventory_block_lifecycle_intent_required'),
      );
      expect(await _counts(fixture.db.database), countsBeforeMissingIntent);
      final detachResult = await app.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _uuid(17024),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: detachReplacementDraftId,
          expectedSketchRevision: spatial.sketch.revision,
          expectedContentRevision: spatial.draftRevision!.contentRevision,
          existingBlockIntents: [
            InventoryExistingBlockFinalizeIntent(
              blockId: firstBlockId,
              action: InventoryExistingBlockAction.detach,
              expectedBlockRevision: 1,
            ),
            InventoryExistingBlockFinalizeIntent(
              blockId: secondBlockId,
              action: InventoryExistingBlockAction.retainMapped,
              expectedBlockRevision: 1,
              targetPolygonIndex: 0,
            ),
          ],
          placementExpectations: await _placementExpectations(app),
        ),
      );
      expect(detachResult.eventCount, 1);
      spatial = (await app.loadPrimarySketch(_projectA))!;
      expect(
        spatial.blocks.singleWhere((block) => block.id == firstBlockId).state,
        InventoryBlockState.detached,
      );
      expect(spatial.activeBlockPolygons.map((mapping) => mapping.blockId), [
        secondBlockId,
      ]);
      final placementAfterDetach = (await app.loadAsset(
        projectId: _projectA,
        assetId: assetId,
      )).activePlacement!;
      final secondPlacementAfterDetach = (await app.loadAsset(
        projectId: _projectA,
        assetId: secondAssetId,
      )).activePlacement!;
      expect(placementAfterDetach.id, placementBeforeDetach.id);
      expect(placementAfterDetach.sequence, placementBeforeDetach.sequence);
      expect(secondPlacementAfterDetach.id, secondPlacementBeforeDetach.id);
      expect(
        secondPlacementAfterDetach.sequence,
        secondPlacementBeforeDetach.sequence,
      );
      expect(
        spatial.floors
            .where((floor) => firstFloorIds.contains(floor.id))
            .every((floor) => floor.archivedAt == null),
        isTrue,
      );

      final reattachDraftId = _uuid(17030);
      await app.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(17031),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          activeRevisionId: spatial.activeRevision!.id,
          newDraftRevisionId: reattachDraftId,
          expectedSketchRevision: spatial.sketch.revision,
        ),
      );
      spatial = (await app.loadPrimarySketch(_projectA))!;
      final reattachedGeometry = InventoryGeometry(
        polylines: [secondPolygon, firstPolygon],
      );
      await app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(17032),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: reattachDraftId,
          expectedSketchRevision: spatial.sketch.revision,
          expectedContentRevision: spatial.draftRevision!.contentRevision,
          geometry: reattachedGeometry,
          existingBlockMappings: [
            InventoryExistingBlockMappingDraft(
              blockId: secondBlockId,
              polygonIndex: 0,
            ),
            InventoryExistingBlockMappingDraft(
              blockId: firstBlockId,
              polygonIndex: 1,
            ),
          ],
        ),
      );
      spatial = (await app.loadPrimarySketch(_projectA))!;
      final reattachReplacementDraftId = spatial.draftRevision!.id;
      expect(reattachReplacementDraftId, isNot(reattachDraftId));
      expect(spatial.draftRevision!.contentRevision, 1);
      final detachedBlock = spatial.blocks.singleWhere(
        (block) => block.id == firstBlockId,
      );
      final conflictingBlockId = _uuid(17034);
      final conflictingFloorId = _uuid(17035);
      await fixture.db.database.insert('inventory_blocks', {
        'id': conflictingBlockId,
        'project_id': _projectA,
        'display_name': detachedBlock.displayName,
        'normalized_name': detachedBlock.normalizedName,
        'ordinal': 999,
        'state': InventoryBlockState.active.storageValue,
        'revision': 1,
        'created_at': _t0,
        'updated_at': _t0,
        'archived_at': null,
      });
      await fixture.db.database.insert('inventory_floors', {
        'id': conflictingFloorId,
        'block_id': conflictingBlockId,
        'project_id': _projectA,
        'display_name': '1. Kat',
        'ordinal': 1,
        'revision': 1,
        'created_at': _t0,
        'updated_at': _t0,
        'archived_at': null,
      });
      final countsBeforeNameConflict = await _counts(fixture.db.database);
      await expectLater(
        app.finalizeSketch(
          FinalizeInventorySketchCommand(
            operationId: _uuid(17036),
            projectId: _projectA,
            sketchId: sketch.sketchId,
            draftRevisionId: reattachReplacementDraftId,
            expectedSketchRevision: spatial.sketch.revision,
            expectedContentRevision: spatial.draftRevision!.contentRevision,
            existingBlockIntents: [
              InventoryExistingBlockFinalizeIntent(
                blockId: firstBlockId,
                action: InventoryExistingBlockAction.reattach,
                expectedBlockRevision: 2,
                targetPolygonIndex: 1,
              ),
              InventoryExistingBlockFinalizeIntent(
                blockId: secondBlockId,
                action: InventoryExistingBlockAction.retainMapped,
                expectedBlockRevision: 1,
                targetPolygonIndex: 0,
              ),
            ],
            placementExpectations: await _placementExpectations(app),
          ),
        ),
        _fails('inventory_block_name_conflict'),
      );
      expect(await _counts(fixture.db.database), countsBeforeNameConflict);
      await fixture.db.database.update(
        'inventory_floors',
        {'revision': 2, 'updated_at': _t0, 'archived_at': _t0},
        where: 'id = ? AND revision = 1',
        whereArgs: [conflictingFloorId],
      );
      await fixture.db.database.update(
        'inventory_blocks',
        {
          'state': InventoryBlockState.archived.storageValue,
          'revision': 2,
          'updated_at': _t0,
          'archived_at': _t0,
        },
        where: 'id = ? AND revision = 1',
        whereArgs: [conflictingBlockId],
      );
      final reattachResult = await app.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _uuid(17033),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: reattachReplacementDraftId,
          expectedSketchRevision: spatial.sketch.revision,
          expectedContentRevision: spatial.draftRevision!.contentRevision,
          existingBlockIntents: [
            InventoryExistingBlockFinalizeIntent(
              blockId: firstBlockId,
              action: InventoryExistingBlockAction.reattach,
              expectedBlockRevision: 2,
              targetPolygonIndex: 1,
            ),
            InventoryExistingBlockFinalizeIntent(
              blockId: secondBlockId,
              action: InventoryExistingBlockAction.retainMapped,
              expectedBlockRevision: 1,
              targetPolygonIndex: 0,
            ),
          ],
          placementExpectations: await _placementExpectations(app),
        ),
      );
      expect(reattachResult.eventCount, 3);
      spatial = (await app.loadPrimarySketch(_projectA))!;
      final reattachedBlock = spatial.blocks.singleWhere(
        (block) => block.id == firstBlockId,
      );
      expect(reattachedBlock.state, InventoryBlockState.active);
      expect(reattachedBlock.revision, 3);
      expect(
        spatial.floors
            .where((floor) => firstFloorIds.contains(floor.id))
            .map((floor) => floor.id),
        firstFloorIds,
      );
      final placementAfterReattach = (await app.loadAsset(
        projectId: _projectA,
        assetId: assetId,
      )).activePlacement!;
      final secondPlacementAfterReattach = (await app.loadAsset(
        projectId: _projectA,
        assetId: secondAssetId,
      )).activePlacement!;
      expect(
        placementAfterReattach.sequence,
        placementBeforeDetach.sequence + 1,
      );
      expect(placementAfterReattach.floorId, placementBeforeDetach.floorId);
      expect(
        secondPlacementAfterReattach.sequence,
        secondPlacementBeforeDetach.sequence + 1,
      );
      expect(
        secondPlacementAfterReattach.floorId,
        secondPlacementBeforeDetach.floorId,
      );
      final expectedReattachTarget =
          InventorySpatialContract.safeInteriorPlacement(
            firstPolygon,
            spreadIndex: 0,
            clearance: InventoryGeometryContract.placementStep,
          );
      final expectedSecondReattachTarget =
          InventorySpatialContract.safeInteriorPlacement(
            firstPolygon,
            spreadIndex: 1,
            occupied: <InventoryPlacementCoordinates>{expectedReattachTarget},
            clearance: InventoryGeometryContract.placementStep,
          );
      expect(placementAfterReattach.x, expectedReattachTarget.x);
      expect(placementAfterReattach.y, expectedReattachTarget.y);
      expect(secondPlacementAfterReattach.x, expectedSecondReattachTarget.x);
      expect(secondPlacementAfterReattach.y, expectedSecondReattachTarget.y);
      expect(
        placementAfterReattach.x == secondPlacementAfterReattach.x &&
            placementAfterReattach.y == secondPlacementAfterReattach.y,
        isFalse,
      );
      final reattachMoveEvents = await fixture.db.database.query(
        'inventory_events',
        where: 'operation_id = ? AND event_type = ?',
        whereArgs: [
          _uuid(17033),
          InventoryEventType.placementMoved.storageValue,
        ],
      );
      expect(reattachMoveEvents, hasLength(2));
      final reattachMovePayload =
          jsonDecode(
                reattachMoveEvents.singleWhere(
                      (row) =>
                          row['aggregate_id'] ==
                          placementBeforeDetach.placementKey,
                    )['payload_json']!
                    as String,
              )
              as Map<String, dynamic>;
      expect(reattachMovePayload['reason'], 'geometry_reconciliation');
      expect(reattachMovePayload['before_floor_id'], firstFloor.id);
      expect(reattachMovePayload['after_floor_id'], firstFloor.id);
      expect(reattachMovePayload['before_x'], placementBeforeDetach.x);
      expect(reattachMovePayload['before_y'], placementBeforeDetach.y);
      expect(reattachMovePayload['after_x'], placementAfterReattach.x);
      expect(reattachMovePayload['after_y'], placementAfterReattach.y);
      expect(
        reattachMovePayload['predecessor_placement_id'],
        placementBeforeDetach.id,
      );
      expect(reattachMovePayload['placement_id'], placementAfterReattach.id);
      final secondReattachMovePayload =
          jsonDecode(
                reattachMoveEvents.singleWhere(
                      (row) =>
                          row['aggregate_id'] ==
                          secondPlacementBeforeDetach.placementKey,
                    )['payload_json']!
                    as String,
              )
              as Map<String, dynamic>;
      expect(secondReattachMovePayload['reason'], 'geometry_reconciliation');
      expect(secondReattachMovePayload['before_floor_id'], firstFloor.id);
      expect(secondReattachMovePayload['after_floor_id'], firstFloor.id);
      expect(
        secondReattachMovePayload['before_x'],
        secondPlacementBeforeDetach.x,
      );
      expect(
        secondReattachMovePayload['before_y'],
        secondPlacementBeforeDetach.y,
      );
      expect(
        secondReattachMovePayload['after_x'],
        secondPlacementAfterReattach.x,
      );
      expect(
        secondReattachMovePayload['after_y'],
        secondPlacementAfterReattach.y,
      );
      expect(
        secondReattachMovePayload['predecessor_placement_id'],
        secondPlacementBeforeDetach.id,
      );
      expect(
        secondReattachMovePayload['placement_id'],
        secondPlacementAfterReattach.id,
      );
      final firstReattachVersions = await app.listPlacementVersions(
        projectId: _projectA,
        assetId: assetId,
        placementKey: placementBeforeDetach.placementKey,
      );
      expect(firstReattachVersions.map((item) => item.id), [
        placementBeforeDetach.id,
        placementAfterReattach.id,
      ]);
      expect(firstReattachVersions.map((item) => item.sequence), [1, 2]);
      expect(firstReattachVersions.map((item) => item.supersedesPlacementId), [
        null,
        placementBeforeDetach.id,
      ]);
      final secondReattachVersions = await app.listPlacementVersions(
        projectId: _projectA,
        assetId: secondAssetId,
        placementKey: secondPlacementBeforeDetach.placementKey,
      );
      expect(secondReattachVersions.map((item) => item.id), [
        secondPlacementBeforeDetach.id,
        secondPlacementAfterReattach.id,
      ]);
      expect(secondReattachVersions.map((item) => item.sequence), [1, 2]);
      expect(secondReattachVersions.map((item) => item.supersedesPlacementId), [
        null,
        secondPlacementBeforeDetach.id,
      ]);
      expect(
        [
          placementBeforeDetach.placementKey,
          secondPlacementBeforeDetach.placementKey,
        ]..sort(),
        [
          placementBeforeDetach.placementKey,
          secondPlacementBeforeDetach.placementKey,
        ],
      );

      final archiveDraftId = _uuid(17040);
      await app.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(17041),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          activeRevisionId: spatial.activeRevision!.id,
          newDraftRevisionId: archiveDraftId,
          expectedSketchRevision: spatial.sketch.revision,
        ),
      );
      spatial = (await app.loadPrimarySketch(_projectA))!;
      await app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(17042),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: archiveDraftId,
          expectedSketchRevision: spatial.sketch.revision,
          expectedContentRevision: spatial.draftRevision!.contentRevision,
          geometry: detachedGeometry,
          existingBlockMappings: [
            InventoryExistingBlockMappingDraft(
              blockId: secondBlockId,
              polygonIndex: 0,
            ),
          ],
        ),
      );
      spatial = (await app.loadPrimarySketch(_projectA))!;
      final archiveReplacementDraftId = spatial.draftRevision!.id;
      expect(archiveReplacementDraftId, isNot(archiveDraftId));
      expect(spatial.draftRevision!.contentRevision, 1);
      final archiveResult = await app.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _uuid(17043),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: archiveReplacementDraftId,
          expectedSketchRevision: spatial.sketch.revision,
          expectedContentRevision: spatial.draftRevision!.contentRevision,
          existingBlockIntents: [
            InventoryExistingBlockFinalizeIntent(
              blockId: firstBlockId,
              action: InventoryExistingBlockAction.archive,
              expectedBlockRevision: 3,
            ),
            InventoryExistingBlockFinalizeIntent(
              blockId: secondBlockId,
              action: InventoryExistingBlockAction.retainMapped,
              expectedBlockRevision: 1,
              targetPolygonIndex: 0,
            ),
          ],
          placementExpectations: await _placementExpectations(app),
        ),
      );
      expect(archiveResult.eventCount, 5);
      final archivedAsset = await app.loadAsset(
        projectId: _projectA,
        assetId: assetId,
      );
      final archivedSecondAsset = await app.loadAsset(
        projectId: _projectA,
        assetId: secondAssetId,
      );
      expect(archivedAsset.asset.archivedAt, isNotNull);
      expect(archivedAsset.activePlacement, isNull);
      expect(archivedSecondAsset.asset.archivedAt, isNotNull);
      expect(archivedSecondAsset.activePlacement, isNull);
      spatial = (await app.loadPrimarySketch(_projectA))!;
      final archivedBlock = spatial.blocks.singleWhere(
        (block) => block.id == firstBlockId,
      );
      expect(archivedBlock.state, InventoryBlockState.archived);
      expect(archivedBlock.revision, 4);
      expect(
        spatial.floors
            .where((floor) => firstFloorIds.contains(floor.id))
            .every((floor) => floor.archivedAt != null),
        isTrue,
      );
      expect(spatial.activeBlockPolygons.map((mapping) => mapping.blockId), [
        secondBlockId,
      ]);
      expect(
        await app.readAssetPhoto(
          projectId: _projectA,
          assetId: assetId,
          linkId: photoLinkId,
        ),
        isA<InventoryPhotoContent>(),
      );
      expect(gateway.files.keys, [photoPath]);
      final placementRows = await fixture.db.database.query(
        'inventory_asset_placements',
        where: 'asset_id = ?',
        whereArgs: [assetId],
        orderBy: 'sequence ASC',
      );
      expect(placementRows, hasLength(2));
      expect(
        placementRows.last['end_reason'],
        InventoryPlacementEndReason.assetArchived.storageValue,
      );
      final secondPlacementRows = await fixture.db.database.query(
        'inventory_asset_placements',
        where: 'asset_id = ?',
        whereArgs: [secondAssetId],
        orderBy: 'sequence ASC',
      );
      expect(secondPlacementRows, hasLength(2));
      expect(secondPlacementRows.map((row) => row['id']), [
        secondPlacementBeforeDetach.id,
        secondPlacementAfterReattach.id,
      ]);
      expect(
        secondPlacementRows.last['end_reason'],
        InventoryPlacementEndReason.assetArchived.storageValue,
      );
    },
  );

  test(
    'AT-533-006/007 mixed draft metadata and ambiguous intent fail closed; injected finalize rolls back',
    () async {
      final fixture = await _Fixture.create('at_533_rollback');
      addTearDown(fixture.close);
      final sketch = await _createFinalizedSketch(
        fixture,
        seed: 18000,
        geometry: _geometry(64),
      );
      var spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      final firstMapping = spatial.activeBlockPolygons.singleWhere(
        (mapping) => mapping.polygonIndex == 0,
      );
      final secondMapping = spatial.activeBlockPolygons.singleWhere(
        (mapping) => mapping.polygonIndex == 1,
      );
      final firstFloor = spatial.floors.firstWhere(
        (floor) => floor.blockId == firstMapping.blockId && floor.ordinal == 1,
      );
      final assetId = _uuid(18010);
      await fixture.app.createAsset(
        CreateInventoryAssetCommand(
          operationId: _uuid(18011),
          projectId: _projectA,
          assetId: assetId,
          placementId: _uuid(18012),
          placementKey: _uuid(18013),
          sketchId: sketch.sketchId,
          activeRevisionId: sketch.activeRevisionId,
          floorId: firstFloor.id,
          displayName: 'Rollback asset',
          category: InventoryCategory.equipment,
          totalQuantity: 1,
          x: 128,
          y: 128,
        ),
      );
      final placementBefore = (await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: assetId,
      )).activePlacement!;
      final corruptDraftId = _uuid(18020);
      final sketchRevisionBeforeCorruptDraft = spatial.sketch.revision;
      await _seedLegacyPrefixEditDraft(
        fixture,
        draftId: corruptDraftId,
        legacyPolygonCount: 1,
      );
      await expectLater(
        fixture.app.loadPrimarySketch(_projectA),
        _fails('inventory_projection_integrity_failed'),
      );
      await fixture.app.abandonSketchDraft(
        AbandonInventorySketchDraftCommand(
          operationId: _uuid(18021),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: corruptDraftId,
          expectedSketchRevision: sketchRevisionBeforeCorruptDraft + 1,
        ),
      );
      spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      final draftId = _uuid(18060);
      await fixture.app.startSketchEdit(
        StartInventorySketchEditCommand(
          operationId: _uuid(18061),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          activeRevisionId: spatial.activeRevision!.id,
          newDraftRevisionId: draftId,
          expectedSketchRevision: spatial.sketch.revision,
        ),
      );
      spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      expect(spatial.draftLegacyPolygonCount, 0);
      final rigidGeometry = InventoryGeometry(
        polylines: [_rectangle(64, 0, 2112, 1536)],
      );
      await fixture.app.autosaveSketchDraft(
        AutosaveInventorySketchDraftCommand(
          operationId: _uuid(18022),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: draftId,
          expectedSketchRevision: spatial.sketch.revision,
          expectedContentRevision: spatial.draftRevision!.contentRevision,
          geometry: rigidGeometry,
          existingBlockMappings: [
            InventoryExistingBlockMappingDraft(
              blockId: firstMapping.blockId,
              polygonIndex: 0,
            ),
          ],
        ),
      );
      spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      final replacementDraftId = spatial.draftRevision!.id;
      expect(replacementDraftId, isNot(draftId));
      expect(spatial.draftRevision!.contentRevision, 1);
      expect(spatial.draftBlockPolygons.map((mapping) => mapping.blockId), [
        firstMapping.blockId,
      ]);
      final countsBeforeAmbiguity = await _counts(fixture.db.database);
      await expectLater(
        () => fixture.app.finalizeSketch(
          FinalizeInventorySketchCommand(
            operationId: _uuid(18023),
            projectId: _projectA,
            sketchId: sketch.sketchId,
            draftRevisionId: replacementDraftId,
            expectedSketchRevision: spatial.sketch.revision,
            expectedContentRevision: spatial.draftRevision!.contentRevision,
            existingBlockIntents: [
              InventoryExistingBlockFinalizeIntent(
                blockId: firstMapping.blockId,
                action: InventoryExistingBlockAction.retainMapped,
                expectedBlockRevision: 1,
                targetPolygonIndex: 0,
              ),
              InventoryExistingBlockFinalizeIntent(
                blockId: firstMapping.blockId,
                action: InventoryExistingBlockAction.detach,
                expectedBlockRevision: 1,
              ),
            ],
          ),
        ),
        _fails('inventory_block_identity_ambiguous'),
      );
      expect(await _counts(fixture.db.database), countsBeforeAmbiguity);
      final validIntents = [
        InventoryExistingBlockFinalizeIntent(
          blockId: firstMapping.blockId,
          action: InventoryExistingBlockAction.retainMapped,
          expectedBlockRevision: 1,
          targetPolygonIndex: 0,
        ),
        InventoryExistingBlockFinalizeIntent(
          blockId: secondMapping.blockId,
          action: InventoryExistingBlockAction.detach,
          expectedBlockRevision: 1,
        ),
      ];
      await expectLater(
        fixture.app.finalizeSketch(
          FinalizeInventorySketchCommand(
            operationId: _uuid(18024),
            projectId: _projectA,
            sketchId: sketch.sketchId,
            draftRevisionId: replacementDraftId,
            expectedSketchRevision: spatial.sketch.revision,
            expectedContentRevision: spatial.draftRevision!.contentRevision,
            existingBlockIntents: validIntents,
          ),
        ),
        _fails('inventory_placement_expectation_required'),
      );
      expect(await _counts(fixture.db.database), countsBeforeAmbiguity);
      final finalizeCommand = FinalizeInventorySketchCommand(
        operationId: _uuid(18025),
        projectId: _projectA,
        sketchId: sketch.sketchId,
        draftRevisionId: replacementDraftId,
        expectedSketchRevision: spatial.sketch.revision,
        expectedContentRevision: spatial.draftRevision!.contentRevision,
        existingBlockIntents: validIntents,
        placementExpectations: await _placementExpectations(fixture.app),
      );
      final failing = InventoryApplication(
        database: fixture.db,
        clock: fixture.clock.call,
        idFactory: fixture.ids.call,
        afterSourceWritesBeforeHistory: () async {
          throw StateError('injected lifecycle write-boundary failure');
        },
      );
      final countsBeforeFailure = await _counts(fixture.db.database);
      await expectLater(
        failing.finalizeSketch(finalizeCommand),
        _fails('inventory_persistence_failed'),
      );
      expect(await _counts(fixture.db.database), countsBeforeFailure);
      final afterFailureSpatial = (await fixture.app.loadPrimarySketch(
        _projectA,
      ))!;
      expect(afterFailureSpatial.activeRevision!.id, sketch.activeRevisionId);
      expect(afterFailureSpatial.draftRevision!.id, replacementDraftId);
      expect(afterFailureSpatial.blocks.map((block) => block.revision), [1, 1]);
      final placementAfterFailure = (await fixture.app.loadAsset(
        projectId: _projectA,
        assetId: assetId,
      )).activePlacement!;
      expect(placementAfterFailure.id, placementBefore.id);
      expect(placementAfterFailure.sequence, placementBefore.sequence);
      expect(
        await fixture.db.database.query(
          'inventory_command_receipts',
          where: 'id = ?',
          whereArgs: [finalizeCommand.operationId],
        ),
        isEmpty,
      );
      final recovered = await fixture.app.finalizeSketch(finalizeCommand);
      expect(recovered.eventCount, 2);
      final recoveredSpatial = (await fixture.app.loadPrimarySketch(
        _projectA,
      ))!;
      expect(
        recoveredSpatial.blocks
            .singleWhere((block) => block.id == secondMapping.blockId)
            .state,
        InventoryBlockState.detached,
      );
      expect(
        recoveredSpatial.activeBlockPolygons.map((mapping) => mapping.blockId),
        [firstMapping.blockId],
      );
      expect(
        (await fixture.app.loadAsset(
          projectId: _projectA,
          assetId: assetId,
        )).activePlacement!.sequence,
        placementBefore.sequence + 1,
      );
    },
  );

  test(
    'AT-533-016 exact legacy-prefix edit draft finalizes unchanged through typed lifecycle path',
    () async {
      final fixture = await _Fixture.create('at_533_legacy_finalize');
      addTearDown(fixture.close);
      final sketch = await _createFinalizedSketch(fixture, seed: 19000);
      var spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      final block = spatial.blocks.single;
      final mapping = spatial.activeBlockPolygons.single;
      final draftId = _uuid(19010);
      await _seedLegacyPrefixEditDraft(
        fixture,
        draftId: draftId,
        legacyPolygonCount: spatial.activeRevision!.geometry.polylines.length,
      );
      spatial = (await fixture.app.loadPrimarySketch(_projectA))!;
      expect(
        spatial.draftLegacyPolygonCount,
        spatial.activeRevision!.geometry.polylines.length,
      );
      final result = await fixture.app.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _uuid(19012),
          projectId: _projectA,
          sketchId: sketch.sketchId,
          draftRevisionId: draftId,
          expectedSketchRevision: spatial.sketch.revision,
          expectedContentRevision: spatial.draftRevision!.contentRevision,
          existingBlockIntents: [
            InventoryExistingBlockFinalizeIntent(
              blockId: block.id,
              action: InventoryExistingBlockAction.retainMapped,
              expectedBlockRevision: block.revision,
              targetPolygonIndex: mapping.polygonIndex,
            ),
          ],
        ),
      );
      expect(result.eventCount, 1);
      final finalized = (await fixture.app.loadPrimarySketch(_projectA))!;
      expect(finalized.draftRevision, isNull);
      expect(finalized.activeRevision!.id, draftId);
      expect(
        finalized.activeRevision!.geometry.canonicalJson,
        spatial.activeRevision!.geometry.canonicalJson,
      );
      expect(
        finalized.blocks.singleWhere((item) => item.id == block.id).revision,
        block.revision,
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
  InventoryGeometry? geometry,
}) async {
  final sketchId = _uuid(seed);
  final draftId = _uuid(seed + 1);
  final finalizedGeometry = geometry ?? _geometry();
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
      geometry: finalizedGeometry,
      newBlocks: _blockDrafts(sketchId, finalizedGeometry),
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
      newBlocks: _blockDrafts(sketchId, finalizedGeometry),
    ),
  );
  return _FinalizedSketch(
    sketchId: sketchId,
    activeRevisionId: draftId,
    sketchRevision: 3,
  );
}

// Seed a persisted draft snapshot for migration/corruption recovery checks.
// Keep revision triggers and append-only spatial metadata intact.
Future<void> _seedDraftGeometry(
  _Fixture fixture, {
  required InventoryGeometry geometry,
  required int legacyPolygonCount,
}) async {
  final projection = (await fixture.app.loadPrimarySketch(_projectA))!;
  final draft = projection.draftRevision!;
  await fixture.db.database.transaction((transaction) async {
    final rows = await transaction.query(
      'inventory_sketch_revision_spatial_drafts',
      where: 'revision_id = ? AND content_revision = ?',
      whereArgs: [draft.id, draft.contentRevision],
    );
    await transaction.update(
      'inventory_sketch_revisions',
      {
        'geometry_json': geometry.canonicalJson,
        'geometry_sha256': geometry.sha256,
        'content_revision': draft.contentRevision + 1,
      },
      where: 'id = ?',
      whereArgs: [draft.id],
    );
    await transaction.insert('inventory_sketch_revision_spatial_drafts', {
      ...rows.single,
      'content_revision': draft.contentRevision + 1,
      'legacy_polygon_count': legacyPolygonCount,
    });
  });
}

Future<void> _seedLegacyPrefixEditDraft(
  _Fixture fixture, {
  required String draftId,
  required int legacyPolygonCount,
}) async {
  final projection = (await fixture.app.loadPrimarySketch(_projectA))!;
  final active = projection.activeRevision!;
  if (projection.draftRevision != null ||
      projection.sketch.activeRevisionId != active.id) {
    throw StateError('legacy-prefix fixture requires one active revision');
  }
  final timestamp = CseTimeCodec.encodeUtc(fixture.clock.call());
  await fixture.db.database.transaction((transaction) async {
    final nextRevisionNumber =
        (sqflite.Sqflite.firstIntValue(
              await transaction.rawQuery(
                'SELECT max(revision_number) FROM inventory_sketch_revisions '
                'WHERE project_id = ? AND sketch_id = ?',
                [_projectA, projection.sketch.id],
              ),
            ) ??
            0) +
        1;
    await transaction.insert('inventory_sketch_revisions', {
      'id': draftId,
      'sketch_id': projection.sketch.id,
      'project_id': _projectA,
      'revision_number': nextRevisionNumber,
      'base_revision_id': active.id,
      'state': InventorySketchRevisionState.draft.storageValue,
      'geometry_version': InventoryGeometryContract.geometryVersion,
      'canvas_width': InventoryGeometryContract.canvasWidth,
      'canvas_height': InventoryGeometryContract.canvasHeight,
      'geometry_json': active.geometry.canonicalJson,
      'geometry_sha256': active.geometrySha256,
      'content_revision': 1,
      'created_at': timestamp,
      'updated_at': timestamp,
      'finalized_at': null,
      'superseded_at': null,
      'abandoned_at': null,
    });
    for (final mapping in projection.activeBlockPolygons) {
      await transaction.insert('inventory_sketch_revision_block_polygons', {
        'revision_id': draftId,
        'block_id': mapping.blockId,
        'project_id': _projectA,
        'sketch_id': projection.sketch.id,
        'polygon_index': mapping.polygonIndex,
        'created_at': timestamp,
      });
    }
    await transaction.insert('inventory_sketch_revision_spatial_drafts', {
      'revision_id': draftId,
      'project_id': _projectA,
      'sketch_id': projection.sketch.id,
      'content_revision': 1,
      'legacy_polygon_count': legacyPolygonCount,
      'definitions_json': '[]',
      'created_at': timestamp,
    });
    final updated = await transaction.update(
      'inventory_sketches',
      {
        'draft_revision_id': draftId,
        'revision': projection.sketch.revision + 1,
        'updated_at': timestamp,
      },
      where: 'id = ? AND project_id = ? AND revision = ?',
      whereArgs: [projection.sketch.id, _projectA, projection.sketch.revision],
    );
    if (updated != 1) {
      throw StateError('legacy-prefix fixture sketch update failed');
    }
  });
}

Future<void> _createAsset(
  _Fixture fixture, {
  required _FinalizedSketch sketch,
  required String assetId,
  required int seed,
}) => fixture.app
    .createAsset(
      CreateInventoryAssetCommand(
        operationId: _uuid(seed),
        projectId: _projectA,
        assetId: assetId,
        placementId: _uuid(seed + 1),
        placementKey: _uuid(seed + 2),
        sketchId: sketch.sketchId,
        activeRevisionId: sketch.activeRevisionId,
        displayName: 'Photo asset',
        category: InventoryCategory.equipment,
        totalQuantity: 1,
        x: 128,
        y: 128,
      ),
    )
    .then((_) {});

Future<List<InventoryPlacementReconciliationExpectation>>
_placementExpectations(InventoryApplication app) async {
  final projections = await app.listAssets(projectId: _projectA);
  final result = <InventoryPlacementReconciliationExpectation>[
    for (final projection in projections)
      if (projection.activePlacement != null)
        InventoryPlacementReconciliationExpectation(
          assetId: projection.asset.id,
          expectedAssetRevision: projection.asset.revision,
          placementId: projection.activePlacement!.id,
          placementKey: projection.activePlacement!.placementKey,
          expectedPlacementSequence: projection.activePlacement!.sequence,
        ),
  ]..sort((first, second) => first.assetId.compareTo(second.assetId));
  return result;
}

List<int> _jpeg(int suffix) => <int>[0xff, 0xd8, 0xff, suffix];

List<int> _png(int suffix) => <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  suffix,
];

class _MemoryInventoryAttachmentGateway implements InventoryAttachmentGateway {
  final Map<String, List<int>> files = <String, List<int>>{};
  final List<String> cleanedPaths = <String>[];
  int stageCalls = 0;

  @override
  Future<InventoryPhotoPickResult> pick(InventoryPhotoSource source) async =>
      const InventoryPhotoPickResult(
        outcome: InventoryPhotoPickOutcome.cancelled,
      );

  @override
  Future<StagedInventoryPhoto> stage({
    required String assetId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) async {
    stageCalls += 1;
    final mimeType = bytes.length >= 8 && bytes[0] == 0x89
        ? 'image/png'
        : 'image/jpeg';
    final extension = mimeType == 'image/png' ? 'png' : 'jpg';
    final relativePath = 'managed/$attachmentId.$extension';
    files[relativePath] = List<int>.of(bytes);
    return StagedInventoryPhoto(
      relativePath: relativePath,
      mimeType: mimeType,
      byteSize: bytes.length,
      sha256Value: hashes.sha256.convert(bytes).toString(),
    );
  }

  @override
  Future<InventoryPhotoIntegrity> inspect({
    required String relativePath,
    required String expectedSha256,
    required String expectedMimeType,
    required int expectedByteSize,
  }) async {
    final bytes = files[relativePath];
    if (bytes == null) return InventoryPhotoIntegrity.missingFile;
    if (bytes.length != expectedByteSize) {
      return InventoryPhotoIntegrity.sizeMismatch;
    }
    if (hashes.sha256.convert(bytes).toString() != expectedSha256) {
      return InventoryPhotoIntegrity.hashMismatch;
    }
    return InventoryPhotoIntegrity.healthy;
  }

  @override
  Future<InventoryPhotoContent> read({
    required String relativePath,
    required String originalFileName,
    required String expectedSha256,
    required String expectedMimeType,
    required int expectedByteSize,
  }) async {
    if (await inspect(
          relativePath: relativePath,
          expectedSha256: expectedSha256,
          expectedMimeType: expectedMimeType,
          expectedByteSize: expectedByteSize,
        ) !=
        InventoryPhotoIntegrity.healthy) {
      throw const InventoryFailure('inventory_photo_integrity_failed');
    }
    return InventoryPhotoContent(
      fileName: originalFileName,
      mimeType: expectedMimeType,
      bytes: files[relativePath]!,
    );
  }

  @override
  Future<void> cleanup(String relativePath) async {
    cleanedPaths.add(relativePath);
    files.remove(relativePath);
  }
}

InventoryGeometry _geometry([int stage = 0]) => InventoryGeometry(
  polylines: [
    _rectangle(0, 0, 2048, 1536),
    if (stage >= 64) _rectangle(2560, 0, 2944, 512),
    if (stage >= 128) _rectangle(3200, 0, 3584, 512),
  ],
);

InventoryPolyline _rectangle(int left, int top, int right, int bottom) =>
    InventoryPolyline(
      closed: true,
      points: [
        InventorySketchPoint(x: left, y: top),
        InventorySketchPoint(x: right, y: top),
        InventorySketchPoint(x: right, y: bottom),
        InventorySketchPoint(x: left, y: bottom),
      ],
    );

List<InventoryBlockDraft> _blockDrafts(
  String sketchId,
  InventoryGeometry geometry, {
  int firstPolygonIndex = 0,
}) {
  final sketchSeed = int.parse(sketchId.substring(sketchId.length - 12));
  final base = 700000000000 + sketchSeed * 100;
  return [
    for (
      var index = firstPolygonIndex;
      index < geometry.polylines.length;
      index += 1
    )
      InventoryBlockDraft(
        id: _uuid(base + index * 10),
        displayName: 'Alan ${index + 1}',
        polygonIndex: index,
        floors: [
          InventoryFloorDraft(
            id: _uuid(base + index * 10 + 1),
            displayName: '1. Kat',
            ordinal: 1,
          ),
          InventoryFloorDraft(
            id: _uuid(base + index * 10 + 2),
            displayName: '2. Kat',
            ordinal: 2,
          ),
        ],
      ),
  ];
}

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
    'inventory_blocks',
    'inventory_floors',
    'inventory_sketch_revision_block_polygons',
    'inventory_sketch_revision_spatial_drafts',
    'inventory_assets',
    'inventory_asset_placements',
    'inventory_command_receipts',
    'inventory_events',
  ])
    table: sqflite.Sqflite.firstIntValue(
      await db.rawQuery('SELECT count(*) FROM $table'),
    )!,
};
