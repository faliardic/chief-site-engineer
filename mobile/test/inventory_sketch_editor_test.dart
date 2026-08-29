import 'dart:async';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/inventory/inventory_sketch_canvas.dart';
import 'package:chief_site_engineer/features/inventory/inventory_sketch_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _sketchId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _draftId = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const _activeId = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';
final _time = DateTime.utc(2026, 8, 28, 6);

void main() {
  group('pure editor DRAW and history', () {
    test('start, add, open-end, close and one-point removal are exact', () {
      var editor = InventorySketchEditorSnapshot.recover(
        InventoryGeometry.emptyDraft(),
      );
      editor = editor.drawPoint(_point(0, 0))!;
      expect(editor.hasWorkingPolyline, isTrue);
      expect(editor.geometry.polylines.single.points, [_point(0, 0)]);

      editor = editor.drawPoint(_point(64, 0))!;
      final beforeEndJson = editor.geometry.canonicalJson;
      editor = editor.finishWorkingPolyline()!;
      expect(editor.hasWorkingPolyline, isFalse);
      expect(editor.geometry.canonicalJson, beforeEndJson);
      expect(editor.undo().hasWorkingPolyline, isTrue);
      expect(editor.undo().redo().hasWorkingPolyline, isFalse);

      var onePoint = InventorySketchEditorSnapshot.recover(
        InventoryGeometry.emptyDraft(),
      ).drawPoint(_point(0, 0))!;
      onePoint = onePoint.finishWorkingPolyline()!;
      expect(onePoint.geometry.polylines, isEmpty);
      expect(onePoint.undo().geometry.polylines.single.points, [_point(0, 0)]);

      var closed = InventorySketchEditorSnapshot.recover(
        InventoryGeometry.emptyDraft(),
      );
      for (final point in [_point(0, 0), _point(64, 0), _point(64, 64)]) {
        closed = closed.drawPoint(point)!;
      }
      closed = closed.drawPoint(_point(0, 0))!;
      expect(closed.geometry.polylines.single.closed, isTrue);
      expect(closed.geometry.polylines.single.points, hasLength(3));
      expect(closed.hasWorkingPolyline, isFalse);
    });

    test('duplicate, outside and limit commands leave state unchanged', () {
      var editor = InventorySketchEditorSnapshot.recover(
        InventoryGeometry.emptyDraft(),
      ).drawPoint(_point(0, 0))!;
      final before = editor.geometry.canonicalJson;
      expect(editor.drawPoint(_point(0, 0)), isNull);
      expect(editor.geometry.canonicalJson, before);

      final viewport = InventoryViewport.fit(const Size(4096, 3072));
      expect(viewport.snapViewPoint(const Offset(-0.01, 0)), isNull);
      expect(viewport.snapViewPoint(const Offset(4096.01, 0)), isNull);

      final line = InventoryPolyline(
        closed: false,
        points: [_point(0, 0), _point(64, 0)],
      );
      final maximum = InventorySketchEditorSnapshot.recover(
        InventoryGeometry(polylines: List.filled(64, line)),
      );
      expect(maximum.drawPoint(_point(128, 0)), isNull);
      expect(maximum.geometry.polylines, hasLength(64));
      expect(maximum.undoDepth, 0);
    });

    test('mode changes preserve working polyline and history caps at 100', () {
      var editor = InventorySketchEditorSnapshot.recover(
        InventoryGeometry.emptyDraft(),
      ).drawPoint(_point(0, 0))!;
      editor = editor.withMode(InventorySketchEditorMode.select);
      expect(editor.hasWorkingPolyline, isTrue);
      editor = editor.withMode(InventorySketchEditorMode.draw);
      editor = editor.finishWorkingPolyline()!;
      for (var index = 0; index < 51; index += 1) {
        editor = editor.drawPoint(_point(0, 0))!;
        editor = editor.finishWorkingPolyline()!;
      }
      expect(editor.undoDepth, InventorySketchEditorSnapshot.maximumHistory);
      editor = editor.undo();
      expect(editor.canRedo, isTrue);
      editor = editor.drawPoint(_point(64, 0))!;
      expect(editor.canRedo, isFalse);
    });

    test('recovery keeps durable geometry and starts with empty history', () {
      final geometry = _openGeometry();
      final editor = InventorySketchEditorSnapshot.recover(geometry);

      expect(editor.geometry.canonicalJson, geometry.canonicalJson);
      expect(editor.undoDepth, 0);
      expect(editor.redoDepth, 0);
      expect(editor.hasWorkingPolyline, isFalse);
    });
  });

  group('stable block spatial contract', () {
    test(
      'self-intersection, overlap, touching and containment fail closed',
      () {
        final bowTie = InventoryPolyline(
          closed: true,
          points: [
            _point(0, 0),
            _point(256, 192),
            _point(0, 256),
            _point(192, 0),
          ],
        );
        expect(
          () => InventorySpatialContract.validateBlockPolygon(bowTie),
          throwsA(
            isA<InventoryFailure>().having(
              (error) => error.code,
              'code',
              'inventory_block_polygon_self_intersects',
            ),
          ),
        );

        final first = _closedBlockGeometry().polylines.single;
        final touching = InventoryPolyline(
          closed: true,
          points: [_point(192, 64), _point(320, 64), _point(256, 192)],
        );
        final contained = InventoryPolyline(
          closed: true,
          points: [_point(64, 64), _point(128, 64), _point(64, 128)],
        );
        for (final candidate in [touching, contained]) {
          expect(
            () => InventorySpatialContract.validateNonOverlappingPolygons([
              first,
              candidate,
            ]),
            throwsA(
              isA<InventoryFailure>().having(
                (error) => error.code,
                'code',
                'inventory_block_polygon_ambiguous',
              ),
            ),
          );
        }
      },
    );

    test(
      'multiple non-overlapping blocks keep stable ordered floor metadata',
      () async {
        final fake = _FakeInventoryApplication.withDraft(
          InventoryGeometry.emptyDraft(),
        );
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();

        for (final point in [_point(0, 0), _point(192, 64), _point(128, 192)]) {
          controller.drawPoint(point);
        }
        expect(
          controller.closeWorkingBlock(
            controller.createBlockDraft(displayName: 'A Blok', floorCount: 2),
          ),
          isTrue,
        );
        for (final point in [
          _point(512, 0),
          _point(704, 64),
          _point(640, 192),
        ]) {
          controller.drawPoint(point);
        }
        expect(
          controller.closeWorkingBlock(
            controller.createBlockDraft(displayName: 'B Blok', floorCount: 3),
          ),
          isTrue,
        );
        expect(controller.newBlocks.map((block) => block.polygonIndex), [0, 1]);
        expect(
          controller.newBlocks.first.floors.map((floor) => floor.ordinal),
          [1, 2],
        );
        expect(controller.newBlocks.last.floors.map((floor) => floor.ordinal), [
          1,
          2,
          3,
        ]);

        for (final point in [
          _point(64, 64),
          _point(256, 64),
          _point(128, 256),
        ]) {
          controller.drawPoint(point);
        }
        expect(
          controller.closeWorkingBlock(
            controller.createBlockDraft(
              displayName: 'Çakışan Alan',
              floorCount: 1,
            ),
          ),
          isFalse,
        );
        expect(controller.lastErrorCode, 'inventory_block_polygon_ambiguous');
        expect(controller.newBlocks, hasLength(2));
      },
    );
  });

  group('SELECT and deterministic delete', () {
    final viewport = InventoryViewport.fit(const Size(4096, 3072));

    test('nearest segment escalates to whole polyline on repeated tap', () {
      var editor = InventorySketchEditorSnapshot.recover(
        _fourPointOpenGeometry(),
        mode: InventorySketchEditorMode.select,
      );
      editor = editor.selectAt(const Offset(96, 0), viewport);
      expect(editor.selection?.segmentIndex, 1);
      expect(editor.selection?.wholePolyline, isFalse);
      editor = editor.selectAt(const Offset(96, 0), viewport);
      expect(editor.selection?.wholePolyline, isTrue);
      expect(editor.selection?.semanticLabel, contains('çizgi seçili'));
      editor = editor.deleteSelection()!;
      expect(editor.geometry.polylines, isEmpty);
    });

    test('open interior delete keeps only ordered valid fragments', () {
      final editor =
          InventorySketchEditorSnapshot.recover(
            _fourPointOpenGeometry(),
            mode: InventorySketchEditorMode.select,
          ).withSelection(
            const InventorySketchSelection.segment(
              polylineIndex: 0,
              segmentIndex: 1,
            ),
          );

      final deleted = editor.deleteSelection()!;
      expect(deleted.geometry.polylines, hasLength(2));
      expect(deleted.geometry.polylines[0].points, [
        _point(0, 0),
        _point(64, 0),
      ]);
      expect(deleted.geometry.polylines[1].points, [
        _point(128, 0),
        _point(192, 0),
      ]);
    });

    test('closed closing delete opens same order; other delete rotates', () {
      final geometry = InventoryGeometry(
        polylines: [
          InventoryPolyline(
            closed: true,
            points: [
              _point(0, 0),
              _point(64, 0),
              _point(64, 64),
              _point(0, 64),
            ],
          ),
        ],
      );
      final base = InventorySketchEditorSnapshot.recover(
        geometry,
        mode: InventorySketchEditorMode.select,
      );
      final opened = base
          .withSelection(
            const InventorySketchSelection.segment(
              polylineIndex: 0,
              segmentIndex: 3,
            ),
          )
          .deleteSelection()!;
      expect(opened.geometry.polylines.single.closed, isFalse);
      expect(
        opened.geometry.polylines.single.points,
        geometry.polylines.single.points,
      );

      final rotated = base
          .withSelection(
            const InventorySketchSelection.segment(
              polylineIndex: 0,
              segmentIndex: 1,
            ),
          )
          .deleteSelection()!;
      expect(rotated.geometry.polylines.single.closed, isFalse);
      expect(rotated.geometry.polylines.single.points, [
        _point(64, 64),
        _point(0, 64),
        _point(0, 0),
        _point(64, 0),
      ]);
    });
  });

  group('viewport and gesture separation', () {
    test('inverse transform, snap ties, zoom clamp, fit and pan bounds', () {
      final viewport = InventoryViewport.fit(const Size(800, 600));
      expect(viewport.scale, closeTo(800 / 4096, 1e-12));
      final viewPoint = viewport.virtualToView(_point(64, 64));
      expect(viewport.snapViewPoint(viewPoint), _point(64, 64));

      final exactSize = InventoryViewport.fit(const Size(4096, 3072));
      expect(exactSize.snapViewPoint(const Offset(32, 32)), _point(0, 0));
      expect(exactSize.snapViewPoint(const Offset(96, 96)), _point(64, 64));

      final maximum = viewport.zoomAt(20, const Offset(400, 300));
      final minimum = viewport.zoomAt(0.01, const Offset(400, 300));
      expect(maximum.zoom, InventoryViewport.maximumZoom);
      expect(minimum.zoom, InventoryViewport.minimumZoom);
      expect(maximum.reset().zoom, 1);

      final panned = maximum.panBy(const Offset(100000, 100000));
      expect(
        panned.origin.dx,
        lessThanOrEqualTo(
          panned.viewSize.width -
              panned.canvasViewSize.width *
                  InventoryViewport.minimumVisibleFraction,
        ),
      );
      expect(
        panned.origin.dy,
        lessThanOrEqualTo(
          panned.viewSize.height -
              panned.canvasViewSize.height *
                  InventoryViewport.minimumVisibleFraction,
        ),
      );
    });

    testWidgets('two-finger navigation never draws and PAN drag only pans', (
      tester,
    ) async {
      var snapshot = InventorySketchEditorSnapshot.recover(
        InventoryGeometry.emptyDraft(),
      );
      var drawCount = 0;
      final canvasKey = GlobalKey<InventorySketchCanvasState>();

      Future<void> pumpCanvas() => tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: InventorySketchCanvas(
              key: canvasKey,
              snapshot: snapshot,
              onDrawPoint: (_) => drawCount += 1,
              onSelect: (_, _) {},
            ),
          ),
        ),
      );

      await pumpCanvas();
      final first = await tester.startGesture(
        const Offset(300, 300),
        pointer: 1,
      );
      final second = await tester.startGesture(
        const Offset(500, 300),
        pointer: 2,
      );
      await first.moveTo(const Offset(250, 300));
      await second.moveTo(const Offset(550, 300));
      await first.up();
      await second.up();
      await tester.pump();
      expect(drawCount, 0);

      await tester.tap(
        find.byKey(const Key('inventory-sketch-canvas-gesture')),
      );
      await tester.pump();
      expect(drawCount, 1);

      final drawPanBefore = canvasKey.currentState!.viewport!.pan;
      await tester.drag(
        find.byKey(const Key('inventory-sketch-canvas-gesture')),
        const Offset(80, 0),
      );
      expect(canvasKey.currentState!.viewport!.pan, drawPanBefore);

      snapshot = snapshot.withMode(InventorySketchEditorMode.pan);
      await pumpCanvas();
      final panBefore = canvasKey.currentState!.viewport!.pan;
      await tester.drag(
        find.byKey(const Key('inventory-sketch-canvas-gesture')),
        const Offset(80, 0),
      );
      expect(canvasKey.currentState!.viewport!.pan, isNot(panBefore));
      await tester.tap(
        find.byKey(const Key('inventory-sketch-canvas-gesture')),
      );
      expect(drawCount, 1);
    });
  });

  group('acknowledged autosave controller', () {
    testWidgets('debounces exactly 500 ms and saves status follows ack', (
      tester,
    ) async {
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      );
      final controller = _controller(fake);
      addTearDown(controller.dispose);
      await controller.initialize();

      expect(controller.drawPoint(_point(0, 0)), isTrue);
      expect(controller.saveLabel, 'Kaydediliyor…');
      await tester.pump(const Duration(milliseconds: 499));
      expect(fake.saveCalls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(fake.saveCalls, hasLength(1));
      expect(controller.saveLabel, 'Kaydedildi');
      expect(
        controller.acknowledgedGeometry!.canonicalJson,
        controller.editor!.geometry.canonicalJson,
      );
    });

    test(
      'failure preserves ack; retry reuses operation and discard is local',
      () async {
        final fake = _FakeInventoryApplication.withDraft(
          InventoryGeometry.emptyDraft(),
        )..failSaveCount = 1;
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();
        final acknowledged = controller.acknowledgedGeometry!.canonicalJson;
        controller.drawPoint(_point(0, 0));

        expect(await controller.forceSave(), isFalse);
        expect(controller.saveLabel, 'Kaydedilemedi');
        expect(controller.acknowledgedGeometry!.canonicalJson, acknowledged);
        expect(controller.editor!.geometry.canonicalJson, isNot(acknowledged));
        final failedOperation = fake.saveCalls.single.operationId;

        expect(await controller.forceSave(), isTrue);
        expect(fake.saveCalls, hasLength(2));
        expect(fake.saveCalls.last.operationId, failedOperation);
        expect(fake.saveMutationCount, 1);

        fake.failSaveCount = 1;
        controller.drawPoint(_point(64, 0));
        expect(await controller.forceSave(), isFalse);
        final durable = controller.acknowledgedGeometry!.canonicalJson;
        controller.discardUnsaved();
        expect(controller.editor!.geometry.canonicalJson, durable);
        expect(controller.editor!.undoDepth, 0);
        expect(controller.hasUnacknowledgedGeometry, isFalse);
        expect(fake.abandonCalls, 0);
      },
    );

    test(
      'delayed older save is serialized and cannot replace newer candidate',
      () async {
        final gate = Completer<void>();
        final fake = _FakeInventoryApplication.withDraft(
          InventoryGeometry.emptyDraft(),
        )..saveGates.add(gate);
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.drawPoint(_point(0, 0));
        final saving = controller.forceSave();
        await Future<void>.delayed(Duration.zero);
        expect(fake.saveCalls, hasLength(1));

        controller.drawPoint(_point(64, 0));
        expect(fake.saveCalls, hasLength(1));
        gate.complete();
        expect(await saving, isTrue);
        expect(fake.saveCalls, hasLength(2));
        expect(fake.maximumConcurrentSaves, 1);
        expect(
          controller.acknowledgedGeometry!.canonicalJson,
          controller.editor!.geometry.canonicalJson,
        );
        expect(
          controller.editor!.geometry.polylines.single.points,
          hasLength(2),
        );
      },
    );

    testWidgets('normal in-flight save preserves the newer 500 ms debounce', (
      tester,
    ) async {
      final gate = Completer<void>();
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      )..saveGates.add(gate);
      final controller = _controller(fake);
      addTearDown(controller.dispose);
      await controller.initialize();

      controller.drawPoint(_point(0, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(fake.saveCalls, hasLength(1));

      controller.drawPoint(_point(64, 0));
      gate.complete();
      await tester.pump();
      expect(fake.saveCalls, hasLength(1));
      await tester.pump(const Duration(milliseconds: 499));
      expect(fake.saveCalls, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(fake.saveCalls, hasLength(2));
      expect(fake.maximumConcurrentSaves, 1);
      expect(
        controller.acknowledgedGeometry!.canonicalJson,
        controller.editor!.geometry.canonicalJson,
      );
    });

    testWidgets(
      'explicit force during an in-flight save drains latest immediately',
      (tester) async {
        final gate = Completer<void>();
        final fake = _FakeInventoryApplication.withDraft(
          InventoryGeometry.emptyDraft(),
        )..saveGates.add(gate);
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();

        controller.drawPoint(_point(0, 0));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        expect(fake.saveCalls, hasLength(1));

        controller.drawPoint(_point(64, 0));
        final forced = controller.forceSave();
        gate.complete();
        await tester.pump();
        await tester.pump();

        expect(await forced, isTrue);
        expect(fake.saveCalls, hasLength(2));
        expect(fake.maximumConcurrentSaves, 1);
        expect(
          controller.acknowledgedGeometry!.canonicalJson,
          controller.editor!.geometry.canonicalJson,
        );
      },
    );
  });

  group('launch, finalize and durable recovery', () {
    test(
      'finalize enablement requires finalizable acknowledged geometry',
      () async {
        final emptyFake = _FakeInventoryApplication.withDraft(
          InventoryGeometry.emptyDraft(),
        );
        final emptyController = _controller(emptyFake);
        addTearDown(emptyController.dispose);
        await emptyController.initialize();
        expect(emptyController.isFinalizeEnabled, isFalse);
        emptyController.drawPoint(_point(0, 0));
        expect(emptyController.isFinalizeEnabled, isFalse);

        final readyFake = _FakeInventoryApplication.withDraft(
          _closedBlockGeometry(),
          draftNewBlocks: _blockDrafts(),
        );
        final readyController = _controller(readyFake);
        addTearDown(readyController.dispose);
        await readyController.initialize();
        expect(readyController.isFinalizeEnabled, isTrue);
        readyController.drawPoint(_point(512, 512));
        expect(readyController.isFinalizeEnabled, isFalse);
      },
    );

    test(
      'create/recover and edit-active use exact existing draft behavior',
      () async {
        final createFake = _FakeInventoryApplication.empty();
        final createController = _controller(createFake);
        addTearDown(createController.dispose);
        await createController.initialize();
        expect(createFake.createCalls, 1);
        expect(createController.editor!.geometry.polylines, isEmpty);

        final activeFake = _FakeInventoryApplication.withActive(
          _openGeometry(),
        );
        final editController = _controller(
          activeFake,
          intent: InventorySketchLaunchIntent.editActive,
        );
        addTearDown(editController.dispose);
        await editController.initialize();
        expect(activeFake.editCalls, 1);
        expect(
          editController.editor!.geometry.canonicalJson,
          _openGeometry().canonicalJson,
        );
        expect(editController.editor!.undoDepth, 0);

        final existingDraftFake = _FakeInventoryApplication.withEditDraft(
          _openGeometry(),
        );
        final recoveryController = _controller(
          existingDraftFake,
          intent: InventorySketchLaunchIntent.editActive,
        );
        addTearDown(recoveryController.dispose);
        await recoveryController.initialize();
        expect(existingDraftFake.editCalls, 0);
        expect(recoveryController.editor!.undoDepth, 0);
      },
    );

    test(
      'migrated schema20 first draft keeps legacy geometry without metadata rewrite',
      () async {
        final fake = _FakeInventoryApplication.withDraft(
          _openGeometry(),
          legacyPolygonCount: 1,
        );
        final controller = _controller(fake);
        addTearDown(controller.dispose);

        await controller.initialize();
        expect(controller.newBlocks, isEmpty);
        expect(controller.isFinalizeEnabled, isTrue);
        expect(await controller.finalizeDraft(), isTrue);
        expect(fake.saveCalls, isEmpty);
        expect(
          fake.projection!.activeRevision!.geometry.canonicalJson,
          _openGeometry().canonicalJson,
        );
      },
    );

    test(
      'finalize forces latest save, verifies it, and failure stays draft',
      () async {
        final fake = _FakeInventoryApplication.withDraft(
          InventoryGeometry.emptyDraft(),
        );
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.drawPoint(_point(0, 0));
        controller.drawPoint(_point(192, 64));
        controller.drawPoint(_point(128, 192));
        final definition = controller.createBlockDraft(
          displayName: 'A Blok',
          floorCount: 2,
        );
        expect(controller.closeWorkingBlock(definition), isTrue);

        expect(await controller.finalizeDraft(), isTrue);
        expect(fake.operationOrder, ['save', 'finalize']);
        expect(controller.finalizePersisted, isTrue);
        expect(fake.projection!.draftRevision, isNull);
        expect(
          fake.projection!.activeRevision!.geometry.polylines,
          hasLength(1),
        );
        expect(fake.saveCalls.single.newBlocks.single.displayName, 'A Blok');
        expect(fake.saveCalls.single.newBlocks.single.floors, hasLength(2));

        final failingFake = _FakeInventoryApplication.withDraft(
          _closedBlockGeometry(),
          draftNewBlocks: _blockDrafts(),
        )..failFinalizeCount = 1;
        final failingController = _controller(failingFake);
        addTearDown(failingController.dispose);
        await failingController.initialize();
        expect(await failingController.finalizeDraft(), isFalse);
        expect(failingFake.projection!.draftRevision, isNotNull);
        expect(failingController.finalizePersisted, isFalse);
        expect(failingController.isFinalizeEnabled, isTrue);

        final recovered = _controller(failingFake);
        addTearDown(recovered.dispose);
        await recovered.initialize();
        expect(recovered.editor!.undoDepth, 0);
        expect(await recovered.finalizeDraft(), isTrue);
      },
    );

    test('finalize rejects externally advanced sketch revision', () async {
      final fake = _FakeInventoryApplication.withDraft(
        _closedBlockGeometry(),
        draftNewBlocks: _blockDrafts(),
      );
      final controller = _controller(fake);
      addTearDown(controller.dispose);
      await controller.initialize();
      final before = fake.projection!;

      fake.projection = _projection(
        sketchId: before.sketch.id,
        sketchRevision: before.sketch.revision + 1,
        active: before.activeRevision,
        draft: before.draftRevision,
        draftNewBlocks: before.draftNewBlocks,
      );

      expect(await controller.finalizeDraft(), isFalse);
      expect(controller.lastErrorCode, 'inventory_stale_revision');
      expect(controller.expectedSketchRevision, before.sketch.revision);
      expect(controller.finalizePersisted, isFalse);
      expect(controller.editor, isNotNull);
      expect(controller.isFinalizeEnabled, isFalse);
      expect(fake.finalizeCalls, 0);
    });

    test('finalize rejects externally advanced content revision', () async {
      final fake = _FakeInventoryApplication.withDraft(
        _closedBlockGeometry(),
        draftNewBlocks: _blockDrafts(),
      );
      final controller = _controller(fake);
      addTearDown(controller.dispose);
      await controller.initialize();
      final before = fake.projection!;
      final draft = before.draftRevision!;

      fake.projection = _projection(
        sketchId: before.sketch.id,
        sketchRevision: before.sketch.revision,
        active: before.activeRevision,
        draft: _revision(
          id: draft.id,
          sketchId: draft.sketchId,
          state: draft.state,
          geometry: draft.geometry,
          contentRevision: draft.contentRevision + 1,
          baseRevisionId: draft.baseRevisionId,
        ),
        draftNewBlocks: before.draftNewBlocks,
      );

      expect(await controller.finalizeDraft(), isFalse);
      expect(controller.lastErrorCode, 'inventory_stale_content_revision');
      expect(controller.expectedContentRevision, draft.contentRevision);
      expect(controller.finalizePersisted, isFalse);
      expect(controller.editor, isNotNull);
      expect(controller.isFinalizeEnabled, isFalse);
      expect(fake.finalizeCalls, 0);
    });
  });

  testWidgets(
    'explicit close dialog persists arbitrary-angle block metadata and recovers',
    (tester) async {
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      );
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, pageKey);
      final controller = pageKey.currentState!.controller;

      for (final point in [_point(0, 0), _point(192, 64), _point(128, 192)]) {
        controller.drawPoint(point);
      }
      await tester.pump();
      expect(
        find.byKey(const Key('inventory-editor-edge-preview')),
        findsOneWidget,
      );
      final closeBlock = find.byKey(const Key('inventory-editor-close-block'));
      await tester.ensureVisible(closeBlock);
      await tester.pump();
      await tester.tap(closeBlock);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-block-metadata-dialog')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('inventory-block-name')),
        'A Blok',
      );
      await tester.enterText(
        find.byKey(const Key('inventory-block-floor-count')),
        '2',
      );
      await tester.tap(find.byKey(const Key('inventory-block-metadata-save')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(controller.editor!.geometry.polylines.single.closed, isTrue);
      expect(controller.newBlocks.single.displayName, 'A Blok');
      expect(controller.newBlocks.single.floors, hasLength(2));
      expect(
        fake.saveCalls.last.newBlocks.single.id,
        controller.newBlocks.single.id,
      );
      expect(tester.takeException(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final recoveredKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, recoveredKey);
      expect(
        recoveredKey.currentState!.controller.newBlocks.single.displayName,
        'A Blok',
      );
      expect(
        recoveredKey.currentState!.controller.newBlocks.single.floors.map(
          (floor) => floor.ordinal,
        ),
        [1, 2],
      );
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );

  group('page back, lifecycle and orientation boundary', () {
    testWidgets('create/recover final action copy is Oluştur', (tester) async {
      final fake = _FakeInventoryApplication.withDraft(_openGeometry());
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, pageKey);

      expect(find.widgetWithText(FilledButton, 'Oluştur'), findsOneWidget);
      expect(find.text('Güncelle'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(InventorySketchEditorPage), findsNothing);
    });

    testWidgets(
      'edit-active loads existing base, finalizes successor, and returns true',
      (tester) async {
        final fake = _FakeInventoryApplication.withActive(_openGeometry());
        final orientations = _OrientationRecorder();
        final pageKey = GlobalKey<InventorySketchEditorPageState>();
        bool? result;
        await _openEditor(
          tester,
          fake,
          orientations,
          pageKey,
          intent: InventorySketchLaunchIntent.editActive,
          onResult: (value) => result = value,
        );

        expect(fake.createCalls, 0);
        expect(fake.editCalls, 1);
        expect(
          pageKey.currentState!.controller.editor!.geometry.canonicalJson,
          _openGeometry().canonicalJson,
        );
        expect(find.widgetWithText(FilledButton, 'Güncelle'), findsOneWidget);
        expect(find.text('Oluştur'), findsNothing);

        await tester.tap(find.byKey(const Key('inventory-editor-finalize')));
        await tester.pumpAndSettle();

        expect(result, isTrue);
        expect(fake.finalizeCalls, 1);
        expect(fake.projection!.sketch.id, _sketchId);
        expect(fake.projection!.activeRevision!.id, isNot(_activeId));
        expect(fake.projection!.activeRevision!.baseRevisionId, _activeId);
        expect(
          fake.projection!.activeRevision!.geometry.canonicalJson,
          _openGeometry().canonicalJson,
        );
        expect(fake.projection!.draftRevision, isNull);
        expect(find.byType(InventorySketchEditorPage), findsNothing);
      },
    );

    testWidgets('save label is hidden during loading and shown after ack', (
      tester,
    ) async {
      final loadGate = Completer<void>();
      final loadingFake = _FakeInventoryApplication.withDraft(_openGeometry())
        ..loadGates.add(loadGate);
      final loadingOrientations = _OrientationRecorder();
      final loadingPageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(
        tester,
        loadingFake,
        loadingOrientations,
        loadingPageKey,
        settle: false,
      );
      await tester.pump();
      expect(
        find.byKey(const Key('inventory-editor-save-status')),
        findsNothing,
      );
      expect(find.text('Kaydedildi'), findsNothing);

      loadGate.complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-editor-save-status')),
        findsOneWidget,
      );
      expect(find.text('Kaydedildi'), findsOneWidget);
    });

    testWidgets('save label stays hidden after load failure', (tester) async {
      final failingFake = _FakeInventoryApplication.withDraft(_openGeometry())
        ..failLoadCount = 1;
      final failingOrientations = _OrientationRecorder();
      final failingPageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(
        tester,
        failingFake,
        failingOrientations,
        failingPageKey,
      );
      expect(
        find.byKey(const Key('inventory-editor-save-status')),
        findsNothing,
      );
      expect(find.text('Kaydedildi'), findsNothing);
    });

    testWidgets('back awaits save, blocks failure, and retry exits', (
      tester,
    ) async {
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      )..failSaveCount = 1;
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, pageKey);
      pageKey.currentState!.controller.drawPoint(_point(0, 0));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(InventorySketchEditorPage), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.text('Kaydedilmemiş değişiklikleri bırak'), findsOneWidget);
      expect(
        orientations.calls.last,
        InventorySketchEditorPage.landscapeOrientations,
      );

      await tester.tap(find.byKey(const Key('inventory-editor-retry-save')));
      await tester.pumpAndSettle();
      expect(find.byType(InventorySketchEditorPage), findsNothing);
      expect(
        orientations.calls.last,
        InventorySketchEditorPage.standardOrientations,
      );
    });

    testWidgets('lifecycle interruption saves/restores and resume reasserts', (
      tester,
    ) async {
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      );
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, pageKey);
      pageKey.currentState!.controller.drawPoint(_point(0, 0));

      pageKey.currentState!.didChangeAppLifecycleState(
        AppLifecycleState.paused,
      );
      await pageKey.currentState!.waitForLifecycleForTest();
      await tester.pump();
      expect(fake.saveCalls, hasLength(1));
      expect(
        orientations.calls.last,
        InventorySketchEditorPage.standardOrientations,
      );

      pageKey.currentState!.didChangeAppLifecycleState(
        AppLifecycleState.resumed,
      );
      await pageKey.currentState!.waitForLifecycleForTest();
      await tester.pump();
      expect(
        orientations.calls.last,
        InventorySketchEditorPage.landscapeOrientations,
      );
    });

    testWidgets(
      'finalize restores before exit and orientation retry never refinalizes',
      (tester) async {
        final fake = _FakeInventoryApplication.withDraft(
          _closedBlockGeometry(),
          draftNewBlocks: _blockDrafts(),
        );
        final orientations = _OrientationRecorder()..failStandardCount = 1;
        final pageKey = GlobalKey<InventorySketchEditorPageState>();
        await _openEditor(tester, fake, orientations, pageKey);
        expect(
          orientations.calls.first,
          InventorySketchEditorPage.landscapeOrientations,
        );

        await tester.tap(find.byKey(const Key('inventory-editor-finalize')));
        await tester.pumpAndSettle();
        expect(fake.finalizeCalls, 1);
        expect(find.byType(InventorySketchEditorPage), findsOneWidget);
        expect(
          find.byKey(const Key('inventory-editor-retry-orientation')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('inventory-editor-retry-orientation')),
        );
        await tester.pumpAndSettle();
        expect(fake.finalizeCalls, 1);
        expect(find.byType(InventorySketchEditorPage), findsNothing);
        expect(
          orientations.calls.last,
          InventorySketchEditorPage.standardOrientations,
        );
      },
    );

    testWidgets('handled load error exits through standard restoration', (
      tester,
    ) async {
      final fake = _FakeInventoryApplication.withDraft(_openGeometry())
        ..failLoadCount = 1;
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, pageKey, settle: false);
      await tester.pumpAndSettle();
      expect(find.text('Şematik kroki güvenle açılamadı.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('inventory-editor-load-back')));
      await tester.pumpAndSettle();
      expect(find.byType(InventorySketchEditorPage), findsNothing);
      expect(fake.saveCalls, isEmpty);
      expect(
        orientations.calls.last,
        InventorySketchEditorPage.standardOrientations,
      );
    });
  });
}

InventorySketchEditorController _controller(
  _FakeInventoryApplication fake, {
  InventorySketchLaunchIntent intent =
      InventorySketchLaunchIntent.createOrRecover,
}) => InventorySketchEditorController(
  application: fake,
  projectId: _projectId,
  launchIntent: intent,
  idFactory: _SequentialIds(1000).call,
);

Future<void> _openEditor(
  WidgetTester tester,
  _FakeInventoryApplication fake,
  _OrientationRecorder orientations,
  GlobalKey<InventorySketchEditorPageState> pageKey, {
  bool settle = true,
  InventorySketchLaunchIntent intent =
      InventorySketchLaunchIntent.createOrRecover,
  ValueChanged<bool?>? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const Key('open-editor-test-host'),
              onPressed: () => unawaited(
                Navigator.of(context)
                    .push<bool>(
                      MaterialPageRoute(
                        builder: (_) => InventorySketchEditorPage(
                          key: pageKey,
                          application: fake,
                          projectId: _projectId,
                          launchIntent: intent,
                          idFactory: _SequentialIds(5000).call,
                          orientationSetter: orientations.call,
                        ),
                      ),
                    )
                    .then((value) => onResult?.call(value)),
              ),
              child: const Text('Editor aç'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-editor-test-host')));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

InventorySketchPoint _point(int x, int y) => InventorySketchPoint(x: x, y: y);

InventoryGeometry _openGeometry() => InventoryGeometry(
  polylines: [
    InventoryPolyline(closed: false, points: [_point(0, 0), _point(64, 0)]),
  ],
);

InventoryGeometry _fourPointOpenGeometry() => InventoryGeometry(
  polylines: [
    InventoryPolyline(
      closed: false,
      points: [_point(0, 0), _point(64, 0), _point(128, 0), _point(192, 0)],
    ),
  ],
);

InventoryGeometry _closedBlockGeometry() => InventoryGeometry(
  polylines: [
    InventoryPolyline(
      closed: true,
      points: [_point(0, 0), _point(192, 64), _point(128, 192), _point(0, 128)],
    ),
  ],
);

List<InventoryBlockDraft> _blockDrafts() => [
  InventoryBlockDraft(
    id: _uuid(8000),
    displayName: 'A Blok',
    polygonIndex: 0,
    floors: [
      InventoryFloorDraft(id: _uuid(8001), displayName: '1. Kat', ordinal: 1),
      InventoryFloorDraft(id: _uuid(8002), displayName: '2. Kat', ordinal: 2),
    ],
  ),
];

class _OrientationRecorder {
  final calls = <List<DeviceOrientation>>[];
  int failStandardCount = 0;

  Future<void> call(List<DeviceOrientation> value) async {
    calls.add(List<DeviceOrientation>.unmodifiable(value));
    if (_sameOrientations(
          value,
          InventorySketchEditorPage.standardOrientations,
        ) &&
        failStandardCount > 0) {
      failStandardCount -= 1;
      throw StateError('injected orientation failure');
    }
  }
}

bool _sameOrientations(
  List<DeviceOrientation> left,
  List<DeviceOrientation> right,
) =>
    left.length == right.length &&
    List.generate(
      left.length,
      (index) => left[index] == right[index],
    ).every((value) => value);

class _SequentialIds {
  _SequentialIds(this.value);
  int value;
  String call() => _uuid(value++);
}

String _uuid(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';

class _FakeInventoryApplication implements InventoryApplicationPort {
  _FakeInventoryApplication._(this.projection);

  factory _FakeInventoryApplication.empty() =>
      _FakeInventoryApplication._(null);

  factory _FakeInventoryApplication.withDraft(
    InventoryGeometry geometry, {
    List<InventoryBlockDraft> draftNewBlocks = const [],
    int legacyPolygonCount = 0,
  }) => _FakeInventoryApplication._(
    _projection(
      sketchRevision: 1,
      draft: _revision(
        id: _draftId,
        state: InventorySketchRevisionState.draft,
        geometry: geometry,
        contentRevision: 1,
      ),
      draftNewBlocks: draftNewBlocks,
      draftLegacyPolygonCount: legacyPolygonCount,
    ),
  );

  factory _FakeInventoryApplication.withActive(InventoryGeometry geometry) =>
      _FakeInventoryApplication._(
        _projection(
          sketchRevision: 3,
          active: _revision(
            id: _activeId,
            state: InventorySketchRevisionState.active,
            geometry: geometry,
            contentRevision: 2,
          ),
        ),
      );

  factory _FakeInventoryApplication.withEditDraft(InventoryGeometry geometry) =>
      _FakeInventoryApplication._(
        _projection(
          sketchRevision: 4,
          active: _revision(
            id: _activeId,
            state: InventorySketchRevisionState.active,
            geometry: geometry,
            contentRevision: 2,
          ),
          draft: _revision(
            id: _draftId,
            state: InventorySketchRevisionState.draft,
            geometry: geometry,
            contentRevision: 1,
            baseRevisionId: _activeId,
          ),
        ),
      );

  InventoryPrimarySketchProjection? projection;
  int createCalls = 0;
  int editCalls = 0;
  int finalizeCalls = 0;
  int abandonCalls = 0;
  int failSaveCount = 0;
  int failFinalizeCount = 0;
  int failLoadCount = 0;
  int saveMutationCount = 0;
  int concurrentSaves = 0;
  int maximumConcurrentSaves = 0;
  final saveCalls = <AutosaveInventorySketchDraftCommand>[];
  final saveGates = <Completer<void>>[];
  final loadGates = <Completer<void>>[];
  final operationOrder = <String>[];
  final _receipts = <String, InventoryMutationResult>{};

  @override
  Future<InventoryPrimarySketchProjection?> loadPrimarySketch(
    String projectId,
  ) async {
    if (loadGates.isNotEmpty) await loadGates.removeAt(0).future;
    if (failLoadCount > 0) {
      failLoadCount -= 1;
      throw const InventoryFailure('inventory_persistence_failed');
    }
    return projection;
  }

  @override
  Future<InventoryMutationResult> createSketch(
    CreateInventorySketchCommand command,
  ) async {
    createCalls += 1;
    if (projection != null) {
      throw const InventoryFailure('inventory_primary_sketch_exists');
    }
    final draft = _revision(
      id: command.draftRevisionId,
      sketchId: command.sketchId,
      state: InventorySketchRevisionState.draft,
      geometry: InventoryGeometry.emptyDraft(),
      contentRevision: 1,
    );
    projection = _projection(
      sketchId: command.sketchId,
      sketchRevision: 1,
      draft: draft,
    );
    return _result(
      command: InventoryCommandType.sketchCreate,
      operationId: command.operationId,
      sourceId: command.sketchId,
      sourceRevision: 1,
      supportingId: command.draftRevisionId,
      supportingRevision: 1,
    );
  }

  @override
  Future<InventoryMutationResult> startSketchEdit(
    StartInventorySketchEditCommand command,
  ) async {
    editCalls += 1;
    final current = projection!;
    final active = current.activeRevision!;
    final draft = _revision(
      id: command.newDraftRevisionId,
      sketchId: current.sketch.id,
      state: InventorySketchRevisionState.draft,
      geometry: active.geometry,
      contentRevision: 1,
      baseRevisionId: active.id,
    );
    projection = _projection(
      sketchId: current.sketch.id,
      sketchRevision: current.sketch.revision + 1,
      active: active,
      draft: draft,
    );
    return _result(
      command: InventoryCommandType.sketchEditStart,
      operationId: command.operationId,
      sourceId: current.sketch.id,
      sourceRevision: current.sketch.revision + 1,
      supportingId: draft.id,
      supportingRevision: 1,
    );
  }

  @override
  Future<InventoryMutationResult> autosaveSketchDraft(
    AutosaveInventorySketchDraftCommand command,
  ) async {
    saveCalls.add(command);
    operationOrder.add('save');
    concurrentSaves += 1;
    maximumConcurrentSaves = maximumConcurrentSaves < concurrentSaves
        ? concurrentSaves
        : maximumConcurrentSaves;
    try {
      if (saveGates.isNotEmpty) await saveGates.removeAt(0).future;
      if (failSaveCount > 0) {
        failSaveCount -= 1;
        throw const InventoryFailure('inventory_persistence_failed');
      }
      final replay = _receipts[command.operationId];
      if (replay != null) return replay;
      final current = projection!;
      final draft = current.draftRevision!;
      if (current.sketch.revision != command.expectedSketchRevision) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      if (draft.contentRevision != command.expectedContentRevision) {
        throw const InventoryFailure('inventory_stale_content_revision');
      }
      final changed =
          draft.geometry.canonicalJson != command.geometry.canonicalJson ||
          !_sameBlockDrafts(current.draftNewBlocks, command.newBlocks);
      final nextSketchRevision = current.sketch.revision + (changed ? 1 : 0);
      final nextContentRevision = draft.contentRevision + (changed ? 1 : 0);
      final nextDraft = _revision(
        id: draft.id,
        sketchId: current.sketch.id,
        state: InventorySketchRevisionState.draft,
        geometry: command.geometry,
        contentRevision: nextContentRevision,
        baseRevisionId: draft.baseRevisionId,
      );
      projection = _projection(
        sketchId: current.sketch.id,
        sketchRevision: nextSketchRevision,
        active: current.activeRevision,
        draft: nextDraft,
        draftNewBlocks: command.newBlocks,
        draftLegacyPolygonCount: current.draftLegacyPolygonCount,
      );
      if (changed) saveMutationCount += 1;
      final result = _result(
        command: InventoryCommandType.sketchDraftAutosave,
        operationId: command.operationId,
        sourceId: current.sketch.id,
        sourceRevision: nextSketchRevision,
        supportingId: draft.id,
        supportingRevision: nextContentRevision,
        isNoOp: !changed,
      );
      _receipts[command.operationId] = result;
      return result;
    } finally {
      concurrentSaves -= 1;
    }
  }

  @override
  Future<InventoryMutationResult> finalizeSketch(
    FinalizeInventorySketchCommand command,
  ) async {
    finalizeCalls += 1;
    operationOrder.add('finalize');
    if (failFinalizeCount > 0) {
      failFinalizeCount -= 1;
      throw const InventoryFailure('inventory_persistence_failed');
    }
    final current = projection!;
    final draft = current.draftRevision!;
    draft.geometry.validateFinalizable();
    if (!_sameBlockDrafts(current.draftNewBlocks, command.newBlocks)) {
      throw const InventoryFailure('inventory_block_metadata_mismatch');
    }
    final active = _revision(
      id: draft.id,
      sketchId: current.sketch.id,
      state: InventorySketchRevisionState.active,
      geometry: draft.geometry,
      contentRevision: draft.contentRevision,
      baseRevisionId: draft.baseRevisionId,
    );
    final nextRevision = current.sketch.revision + 1;
    projection = _projection(
      sketchId: current.sketch.id,
      sketchRevision: nextRevision,
      active: active,
    );
    return _result(
      command: InventoryCommandType.sketchFinalize,
      operationId: command.operationId,
      sourceId: current.sketch.id,
      sourceRevision: nextRevision,
      supportingId: draft.id,
      supportingRevision: draft.contentRevision,
    );
  }

  @override
  Future<InventoryMutationResult> abandonSketchDraft(
    AbandonInventorySketchDraftCommand command,
  ) async {
    abandonCalls += 1;
    throw UnsupportedError('not used');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

InventoryPrimarySketchProjection _projection({
  String sketchId = _sketchId,
  required int sketchRevision,
  InventorySketchRevisionRecord? active,
  InventorySketchRevisionRecord? draft,
  List<InventoryBlockDraft> draftNewBlocks = const [],
  int draftLegacyPolygonCount = 0,
}) => InventoryPrimarySketchProjection(
  sketch: InventorySketchRecord(
    id: sketchId,
    projectId: _projectId,
    displayName: 'Saha krokisi',
    isPrimary: true,
    activeRevisionId: active?.id,
    draftRevisionId: draft?.id,
    revision: sketchRevision,
    createdAt: _time,
    updatedAt: _time,
    archivedAt: null,
  ),
  activeRevision: active,
  draftRevision: draft,
  draftNewBlocks: draftNewBlocks,
  draftLegacyPolygonCount: draftLegacyPolygonCount,
);

bool _sameBlockDrafts(
  List<InventoryBlockDraft> first,
  List<InventoryBlockDraft> second,
) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index += 1) {
    final left = first[index];
    final right = second[index];
    if (left.id != right.id ||
        left.displayName != right.displayName ||
        left.polygonIndex != right.polygonIndex ||
        left.floors.length != right.floors.length) {
      return false;
    }
    for (var floor = 0; floor < left.floors.length; floor += 1) {
      if (left.floors[floor].id != right.floors[floor].id ||
          left.floors[floor].displayName != right.floors[floor].displayName ||
          left.floors[floor].ordinal != right.floors[floor].ordinal) {
        return false;
      }
    }
  }
  return true;
}

InventorySketchRevisionRecord _revision({
  required String id,
  String sketchId = _sketchId,
  required InventorySketchRevisionState state,
  required InventoryGeometry geometry,
  required int contentRevision,
  String? baseRevisionId,
}) => InventorySketchRevisionRecord(
  id: id,
  sketchId: sketchId,
  projectId: _projectId,
  revisionNumber: id == _activeId ? 1 : 2,
  baseRevisionId: baseRevisionId,
  state: state,
  geometry: geometry,
  geometrySha256: geometry.sha256,
  contentRevision: contentRevision,
  createdAt: _time,
  updatedAt: _time,
  finalizedAt: state == InventorySketchRevisionState.active ? _time : null,
  supersededAt: null,
  abandonedAt: null,
);

InventoryMutationResult _result({
  required InventoryCommandType command,
  required String operationId,
  required String sourceId,
  required int sourceRevision,
  required String supportingId,
  required int supportingRevision,
  bool isNoOp = false,
}) => InventoryMutationResult(
  operationId: operationId,
  commandType: command,
  projectId: _projectId,
  primaryAggregateType: InventoryAggregateType.sketch,
  primaryAggregateId: sourceId,
  sourceId: sourceId,
  sourceRevision: sourceRevision,
  supportingId: supportingId,
  supportingRevision: supportingRevision,
  isNoOp: isNoOp,
  eventCount: isNoOp ? 0 : 1,
  resultAt: _time,
);
