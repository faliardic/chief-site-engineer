import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

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
  test(
    'AT-602 identical open suffix uses legacy and block indexes on recovery and discard',
    () async {
      final legacy = _openGeometry().polylines.single;
      final firstBlock = _blockDrafts().single;
      final geometry = InventoryGeometry(
        polylines: [
          ..._closedBlockGeometry().polylines,
          legacy,
          _openGeometry().polylines.single,
        ],
      );
      final fake = _FakeInventoryApplication.withDraft(
        geometry,
        draftNewBlocks: [firstBlock],
        legacyPolygonCount: 1,
      );
      final controller = _controller(fake);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.loadStatus, InventorySketchLoadStatus.ready);
      expect(controller.editor!.workingPolylineIndex, 2);
      expect(controller.isFinalizeEnabled, isFalse);
      expect(controller.drawPoint(_point(64, 64)), isTrue);
      expect(controller.editor!.geometry.polylines[1].points, legacy.points);
      controller.discardUnsaved();
      expect(controller.editor!.geometry.canonicalJson, geometry.canonicalJson);
      expect(controller.editor!.workingPolylineIndex, 2);

      // Remove the classified prefix through selection, then discard. Recovery
      // must use the acknowledged block indexes, not the unsaved shorter list.
      controller.setMode(InventorySketchEditorMode.select);
      final viewport = InventoryViewport.fit(const Size(4096, 3072));
      final edge =
          (viewport.virtualToView(_point(192, 64)) +
              viewport.virtualToView(_point(128, 192))) /
          2;
      controller.selectAt(edge, viewport);
      controller.selectAt(edge, viewport);
      expect(controller.editor!.selection?.wholePolyline, isTrue);
      expect(controller.editor!.selection?.polylineIndex, 0);
      expect(controller.deleteSelection(), isTrue);
      expect(controller.newBlocks, isEmpty);
      expect(controller.editor!.workingPolylineIndex, 1);
      controller.discardUnsaved();
      expect(controller.editor!.workingPolylineIndex, 2);
      expect(controller.editor!.geometry.canonicalJson, geometry.canonicalJson);
      _expectSameBlockIdentity(
        controller.newBlocks.single,
        firstBlock,
        polygonIndex: 0,
      );
      controller.setMode(InventorySketchEditorMode.draw);
      expect(controller.drawPoint(_point(64, 64)), isTrue);
      expect(controller.workingPolyline!.points, [
        ...legacy.points,
        _point(64, 64),
      ]);
      expect(await controller.forceSave(), isTrue);
      expect(fake.saveMutationCount, 1);
      expect(fake.maximumConcurrentSaves, 1);
      expect(
        fake.projection!.draftRevision!.geometry.polylines[1].points,
        legacy.points,
      );
      expect(fake.projection!.draftNewBlocks.map((block) => block.id), [
        firstBlock.id,
      ]);
      expect(fake.finalizeCalls, 0);
    },
  );

  test(
    'AT-602 one-point recovery respects explicit durable legacy classification',
    () async {
      final geometry = InventoryGeometry(
        polylines: [
          InventoryPolyline(closed: false, points: [_point(64, 64)]),
        ],
      );
      for (final legacyCount in [0, 1]) {
        final fake = _FakeInventoryApplication.withDraft(
          geometry,
          legacyPolygonCount: legacyCount,
        );
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();
        expect(controller.loadStatus, InventorySketchLoadStatus.ready);
        expect(
          controller.editor!.workingPolylineIndex,
          legacyCount == 0 ? 0 : null,
        );
        expect(controller.isFinalizeEnabled, isFalse);
        expect(fake.saveCalls, isEmpty);
        expect(fake.finalizeCalls, 0);
      }
    },
  );

  test(
    'AT-602 recovery separates closed draft block metadata from open drawing',
    () async {
      final firstBlock = _blockDrafts().single;
      final geometry = InventoryGeometry(
        polylines: [
          ..._closedBlockGeometry().polylines,
          InventoryPolyline(
            closed: false,
            points: [_point(512, 512), _point(1024, 512), _point(1024, 1024)],
          ),
        ],
      );
      final fake = _FakeInventoryApplication.withDraft(
        geometry,
        draftNewBlocks: [firstBlock],
        legacyPolygonCount: 0,
      );
      final controller = _controller(fake);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.loadStatus, InventorySketchLoadStatus.ready);
      expect(controller.editor!.geometry.canonicalJson, geometry.canonicalJson);
      expect(controller.editor!.workingPolylineIndex, 1);
      expect(controller.isFinalizeEnabled, isFalse);
      expect(controller.drawPoint(_point(512, 1024)), isTrue);
      final secondBlock = controller.createBlockDraft(
        displayName: 'B Blok',
        floorCount: 1,
      );
      expect(controller.closeWorkingBlock(secondBlock), isTrue);
      expect(controller.isFinalizeEnabled, isTrue);
      _expectSameBlockIdentity(
        controller.newBlocks.first,
        firstBlock,
        polygonIndex: 0,
      );
      expect(await controller.forceSave(), isTrue);
      expect(fake.saveMutationCount, 1);
      expect(fake.projection!.draftNewBlocks.map((block) => block.id), [
        firstBlock.id,
        secondBlock.id,
      ]);
      expect(fake.finalizeCalls, 0);
    },
  );

  testWidgets(
    'AT-602 touch selects, nudges whole block and returns to edge reshape',
    (tester) async {
      final blockId = _uuid(26000);
      final geometry = InventoryGeometry(
        polylines: [
          InventoryPolyline(
            closed: true,
            points: [
              _point(640, 512),
              _point(2688, 512),
              _point(2688, 2048),
              _point(640, 2048),
            ],
          ),
        ],
      );
      final fake = _FakeInventoryApplication.withMappedActive(
        geometry: geometry,
        blocks: [_blockRecord(id: blockId)],
        floors: [_floorRecord(id: _uuid(26001), blockId: blockId)],
        activeBlockPolygons: [
          _blockPolygon(
            revisionId: _activeId,
            blockId: blockId,
            polygonIndex: 0,
          ),
        ],
      );
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(
        tester,
        fake,
        _OrientationRecorder(),
        pageKey,
        intent: InventorySketchLaunchIntent.editActive,
      );
      final controller = pageKey.currentState!.controller;
      final canvas = find.byKey(const Key('inventory-sketch-canvas-gesture'));
      Future<void> tapPoint(InventorySketchPoint point) async {
        final state = tester.state<InventorySketchCanvasState>(
          find.byType(InventorySketchCanvas),
        );
        await tester.tapAt(
          tester.getTopLeft(canvas) + state.viewport!.virtualToView(point),
        );
        await tester.pump();
      }

      Future<void> tapControl(String key) async {
        final control = find.byKey(Key(key));
        await tester.ensureVisible(control);
        await tester.pump();
        expect(control.hitTestable(), findsOneWidget);
        await tester.tap(control);
        await tester.pump();
      }

      await tapControl('inventory-editor-mode-select');
      await tapPoint(_point(1664, 512));
      expect(controller.editor!.selection?.segmentIndex, 0);
      await tapControl('inventory-editor-nudge-up');
      expect(controller.editor!.geometry.polylines.single.points, [
        _point(640, 448),
        _point(2688, 448),
        _point(2688, 2048),
        _point(640, 2048),
      ]);
      await tapPoint(_point(1664, 448));
      expect(controller.editor!.selection?.wholePolyline, isTrue);
      await tapControl('inventory-editor-nudge-right');
      expect(controller.editor!.geometry.polylines.single.points, [
        _point(704, 448),
        _point(2752, 448),
        _point(2752, 2048),
        _point(704, 2048),
      ]);
      await tapPoint(_point(2752, 1280));
      expect(controller.editor!.selection?.wholePolyline, isFalse);
      expect(controller.editor!.selection?.segmentIndex, 1);
      await tapControl('inventory-editor-nudge-left');
      final reshaped = controller.editor!.geometry.polylines.single;
      expect(reshaped.points, [
        _point(704, 448),
        _point(2688, 448),
        _point(2688, 2048),
        _point(704, 2048),
      ]);
      expect(
        () => InventorySpatialContract.validateBlockPolygon(reshaped),
        returnsNormally,
      );
      expect(controller.existingBlockMappings.single.blockId, blockId);
      expect(controller.lastErrorCode, isNull);
      await tapControl('inventory-editor-back');
      await tester.pumpAndSettle();
      expect(
        fake.projection!.draftRevision!.geometry.canonicalJson,
        InventoryGeometry(polylines: [reshaped]).canonicalJson,
      );
      expect(fake.maximumConcurrentSaves, 1);
      expect(
        fake.projection!.activeRevision!.geometry.canonicalJson,
        geometry.canonicalJson,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AT-602 touch drawing autosaves, leaves and resumes exact open polygon',
    (tester) async {
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      );
      final orientations = _OrientationRecorder();
      final firstKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, firstKey);
      Future<void> tapPoint(InventorySketchPoint point) async {
        final canvas = find.byKey(const Key('inventory-sketch-canvas-gesture'));
        final state = tester.state<InventorySketchCanvasState>(
          find.byType(InventorySketchCanvas),
        );
        await tester.tapAt(
          tester.getTopLeft(canvas) + state.viewport!.virtualToView(point),
        );
        await tester.pump();
      }

      final points = [_point(640, 512), _point(1664, 512), _point(1664, 1536)];
      for (final point in points) {
        await tapPoint(point);
      }
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      final first = firstKey.currentState!.controller;
      final geometry = first.editor!.geometry.canonicalJson;
      expect(first.editor!.geometry.polylines.single.points, points);
      expect(first.saveStatus, InventorySketchSaveStatus.saved);
      expect(first.isFinalizeEnabled, isFalse);
      expect(first.newBlocks, isEmpty);
      expect(fake.saveCalls, hasLength(1));
      expect(fake.saveMutationCount, 1);
      await tester.tap(find.byKey(const Key('inventory-editor-back')));
      await tester.pumpAndSettle();
      expect(fake.saveCalls, hasLength(1));
      expect(fake.projection!.draftRevision!.geometry.canonicalJson, geometry);
      final recoveredKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(
        tester,
        fake,
        orientations,
        recoveredKey,
        idFactory: _SequentialIds(27000).call,
      );
      final recovered = recoveredKey.currentState!.controller;
      expect(recovered.editor!.geometry.canonicalJson, geometry);
      expect(recovered.editor!.workingPolylineIndex, 0);
      expect(recovered.editor!.undoDepth, 0);
      expect(recovered.newBlocks, isEmpty);
      expect(recovered.isFinalizeEnabled, isFalse);
      await tapPoint(_point(640, 1536));
      expect(recovered.workingPolyline!.points, [...points, _point(640, 1536)]);
      expect(recovered.editor!.geometry.polylines, hasLength(1));
      await tester.tap(find.byKey(const Key('inventory-editor-back')));
      await tester.pumpAndSettle();
      expect(fake.saveCalls, hasLength(2));
      expect(
        fake.saveCalls.map((command) => command.operationId).toSet(),
        hasLength(2),
      );
      expect(fake.saveMutationCount, 2);
      expect(fake.maximumConcurrentSaves, 1);
      expect(fake.finalizeCalls, 0);
      expect(fake.createCalls, 0);
      expect(fake.projection!.draftNewBlocks, isEmpty);
      expect(
        fake.projection!.draftRevision!.geometry.polylines.single.closed,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
      for (final point in [
        _point(0, 0),
        _point(64, 0),
        _point(64, 64),
        _point(0, 64),
      ]) {
        closed = closed.drawPoint(point)!;
      }
      closed = closed.drawPoint(_point(0, 0))!;
      expect(closed.geometry.polylines.single.closed, isTrue);
      expect(closed.geometry.polylines.single.points, hasLength(4));
      expect(closed.hasWorkingPolyline, isFalse);
    });

    test(
      'normal drawing locks dominant axis, alternates 90 degrees and aligns rectangle',
      () {
        var editor = InventorySketchEditorSnapshot.recover(
          InventoryGeometry.emptyDraft(),
        ).drawPoint(_point(0, 0))!;

        final firstEdge = editor.proposeDrawPoint(_point(256, 64))!;
        expect(firstEdge.axis, InventorySketchAxis.horizontal);
        expect(firstEdge.end, _point(256, 0));
        expect(firstEdge.alignmentGuide, isNull);
        editor = editor.drawPoint(_point(256, 64))!;

        final secondEdge = editor.proposeDrawPoint(_point(320, 256))!;
        expect(secondEdge.axis, InventorySketchAxis.vertical);
        expect(secondEdge.end, _point(256, 256));
        editor = editor.drawPoint(_point(320, 256))!;

        final thirdEdge = editor.proposeDrawPoint(_point(128, 320))!;
        expect(thirdEdge.axis, InventorySketchAxis.horizontal);
        expect(thirdEdge.end, _point(0, 256));
        expect(
          thirdEdge.alignmentGuide,
          const InventorySketchAlignmentGuide(
            axis: InventorySketchAxis.vertical,
            coordinate: 0,
          ),
        );
        editor = editor.drawPoint(_point(128, 320))!;
        expect(editor.geometry.polylines.single.points, [
          _point(0, 0),
          _point(256, 0),
          _point(256, 256),
          _point(0, 256),
        ]);

        var vertical = InventorySketchEditorSnapshot.recover(
          InventoryGeometry.emptyDraft(),
        ).drawPoint(_point(64, 64))!;
        final verticalFirst = vertical.proposeDrawPoint(_point(128, 256))!;
        expect(verticalFirst.axis, InventorySketchAxis.vertical);
        expect(verticalFirst.end, _point(64, 256));
        vertical = vertical.drawPoint(_point(128, 256))!;
        expect(
          vertical.proposeDrawPoint(_point(320, 320))!.end,
          _point(320, 256),
        );
      },
    );

    test('legacy diagonal persisted geometry recovers unchanged', () {
      final legacy = InventoryGeometry(
        polylines: [
          InventoryPolyline(
            closed: true,
            points: [_point(0, 0), _point(192, 64), _point(128, 192)],
          ),
        ],
      );

      final recovered = InventorySketchEditorSnapshot.recover(legacy);

      expect(recovered.geometry.canonicalJson, legacy.canonicalJson);
      expect(recovered.geometry.polylines.single.points[1], _point(192, 64));
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

  test(
    'Serbest uzunluk bypasses one vertex alignment, stays orthogonal and resets',
    () async {
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      );
      final controller = _controller(fake);
      addTearDown(controller.dispose);
      await controller.initialize();

      expect(controller.drawPoint(_point(0, 0)), isTrue);
      expect(controller.drawPoint(_point(256, 64)), isTrue);
      expect(controller.drawPoint(_point(320, 256)), isTrue);
      controller.setFreeLengthNextSegment(true);
      expect(controller.freeLengthNextSegment, isTrue);

      final freeProposal = controller.proposeDrawPoint(_point(128, 320))!;
      expect(freeProposal.axis, InventorySketchAxis.horizontal);
      expect(freeProposal.end, _point(128, 256));
      expect(freeProposal.alignmentGuide, isNull);
      expect(controller.drawPoint(_point(128, 320)), isTrue);
      expect(controller.freeLengthNextSegment, isFalse);
      expect(
        controller.editor!.geometry.polylines.single.points.last,
        _point(128, 256),
      );

      final restoredSmart = controller.proposeDrawPoint(_point(192, 64))!;
      expect(restoredSmart.axis, InventorySketchAxis.vertical);
      expect(restoredSmart.end, _point(128, 0));
      expect(
        restoredSmart.alignmentGuide,
        const InventorySketchAlignmentGuide(
          axis: InventorySketchAxis.horizontal,
          coordinate: 0,
        ),
      );
    },
  );

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

        for (final point in [
          _point(0, 0),
          _point(192, 0),
          _point(192, 192),
          _point(0, 192),
        ]) {
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
          _point(704, 0),
          _point(704, 192),
          _point(512, 192),
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
          _point(256, 256),
          _point(64, 256),
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

    test(
      'MT-527-006 metadata boundaries fail closed and limits succeed',
      () async {
        final fake = _FakeInventoryApplication.withDraft(
          InventoryGeometry.emptyDraft(),
        );
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();
        for (final point in [
          _point(0, 0),
          _point(192, 0),
          _point(192, 192),
          _point(0, 192),
        ]) {
          controller.drawPoint(point);
        }
        final beforeGeometry = controller.editor!.geometry.canonicalJson;

        Matcher failsWith(String code) => throwsA(
          isA<InventoryFailure>().having(
            (failure) => failure.code,
            'code',
            code,
          ),
        );

        expect(
          () => controller.createBlockDraft(displayName: ' ', floorCount: 1),
          failsWith('inventory_block_name_invalid'),
        );
        expect(
          () => controller.createBlockDraft(
            displayName: ''.padRight(81, 'A'),
            floorCount: 1,
          ),
          failsWith('inventory_block_name_invalid'),
        );
        expect(
          () => controller.createBlockDraft(displayName: 'Alan', floorCount: 0),
          failsWith('inventory_floor_count_invalid'),
        );
        expect(
          () =>
              controller.createBlockDraft(displayName: 'Alan', floorCount: 101),
          failsWith('inventory_floor_count_invalid'),
        );

        final minimum = controller.createBlockDraft(
          displayName: 'A',
          floorCount: 1,
        );
        expect(minimum.displayName, 'A');
        expect(minimum.floors.single.ordinal, 1);
        final maximum = controller.createBlockDraft(
          displayName: ''.padRight(80, 'B'),
          floorCount: 100,
        );
        expect(maximum.displayName.length, 80);
        expect(maximum.floors, hasLength(100));
        expect(
          maximum.floors.map((floor) => floor.ordinal),
          List.generate(100, (index) => index + 1),
        );
        expect(maximum.floors.map((floor) => floor.id).toSet(), hasLength(100));
        expect(controller.editor!.geometry.canonicalJson, beforeGeometry);
        expect(controller.newBlocks, isEmpty);
        expect(fake.saveCalls, isEmpty);
        expect(fake.finalizeCalls, 0);
      },
    );

    test(
      'whole polygon delete remaps surviving identity through history and persistence',
      () async {
        final fake = _FakeInventoryApplication.withDraft(
          InventoryGeometry.emptyDraft(),
        );
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();

        for (final point in [
          _point(0, 0),
          _point(192, 0),
          _point(192, 192),
          _point(0, 192),
        ]) {
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
          _point(704, 0),
          _point(704, 192),
          _point(512, 192),
        ]) {
          controller.drawPoint(point);
        }
        expect(
          controller.closeWorkingBlock(
            controller.createBlockDraft(displayName: 'B Blok', floorCount: 3),
          ),
          isTrue,
        );
        final blockA = controller.newBlocks.first;
        final blockB = controller.newBlocks.last;
        final blockBGeometry = controller.editor!.geometry.polylines[1];

        controller.editor = controller.editor!.withSelection(
          const InventorySketchSelection.polyline(polylineIndex: 0),
        );
        expect(controller.deleteSelection(), isTrue);
        expect(controller.editor!.geometry.polylines, [blockBGeometry]);
        _expectSameBlockIdentity(
          controller.newBlocks.single,
          blockB,
          polygonIndex: 0,
        );
        expect(controller.newBlocks.single.id, isNot(blockA.id));

        expect(controller.undo(), isTrue);
        expect(controller.newBlocks.map((block) => block.id), [
          blockA.id,
          blockB.id,
        ]);
        _expectSameBlockIdentity(
          controller.newBlocks.last,
          blockB,
          polygonIndex: 1,
        );
        expect(controller.redo(), isTrue);
        _expectSameBlockIdentity(
          controller.newBlocks.single,
          blockB,
          polygonIndex: 0,
        );
        expect(controller.undo(), isTrue);
        expect(controller.newBlocks.map((block) => block.id), [
          blockA.id,
          blockB.id,
        ]);
        expect(controller.redo(), isTrue);
        _expectSameBlockIdentity(
          controller.newBlocks.single,
          blockB,
          polygonIndex: 0,
        );

        expect(await controller.forceSave(), isTrue);
        _expectSameBlockIdentity(
          fake.projection!.draftNewBlocks.single,
          blockB,
          polygonIndex: 0,
        );
        final recovered = _controller(fake);
        addTearDown(recovered.dispose);
        await recovered.initialize();
        expect(recovered.editor!.geometry.polylines, [blockBGeometry]);
        _expectSameBlockIdentity(
          recovered.newBlocks.single,
          blockB,
          polygonIndex: 0,
        );

        expect(await recovered.finalizeDraft(), isTrue);
        final finalized = fake.finalizeCommands.single.newBlocks.single;
        _expectSameBlockIdentity(finalized, blockB, polygonIndex: 0);
        expect(finalized.id, isNot(blockA.id));
      },
    );

    test(
      'AT-533-001/014 mapped whole nudge preserves identity, history, and idempotent save',
      () async {
        final blockId = _uuid(8100);
        final geometry = _rectangleGeometry();
        final fake = _FakeInventoryApplication.withMappedActive(
          geometry: geometry,
          blocks: [_blockRecord(id: blockId, revision: 7)],
          floors: [_floorRecord(id: _uuid(8101), blockId: blockId)],
          activeBlockPolygons: [
            _blockPolygon(
              revisionId: _activeId,
              blockId: blockId,
              polygonIndex: 0,
            ),
          ],
        );
        final controller = _controller(
          fake,
          intent: InventorySketchLaunchIntent.editActive,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.setMode(InventorySketchEditorMode.select);
        controller.editor = controller.editor!.withSelection(
          const InventorySketchSelection.polyline(polylineIndex: 0),
        );

        final before = controller.editor!.geometry.polylines.single;
        expect(
          controller.nudgeSelection(InventorySketchNudgeDirection.right),
          isTrue,
        );
        final translated = controller.editor!.geometry.polylines.single;
        expect(
          () => InventorySpatialContract.validateBlockPolygon(translated),
          returnsNormally,
        );
        expect(translated.points, [
          for (final point in before.points)
            InventorySketchPoint(
              x: point.x + InventoryGeometryContract.sketchGridStep,
              y: point.y,
            ),
        ]);
        expect(
          controller.existingBlockMappings.map(
            (mapping) => (mapping.blockId, mapping.polygonIndex),
          ),
          [(blockId, 0)],
        );

        expect(controller.undo(), isTrue);
        expect(
          controller.editor!.geometry.canonicalJson,
          geometry.canonicalJson,
        );
        expect(controller.existingBlockMappings.single.blockId, blockId);
        expect(controller.redo(), isTrue);
        expect(
          controller.editor!.geometry.canonicalJson,
          InventoryGeometry(polylines: [translated]).canonicalJson,
        );
        expect(controller.existingBlockMappings.single.blockId, blockId);

        expect(await controller.forceSave(), isTrue);
        expect(fake.saveCalls, hasLength(1));
        final mapping = fake.saveCalls.single.existingBlockMappings!.single;
        expect((mapping.blockId, mapping.polygonIndex), (blockId, 0));
        expect(fake.projection!.draftBlockPolygons.single.blockId, blockId);

        final recovered = _controller(
          fake,
          intent: InventorySketchLaunchIntent.editActive,
        );
        addTearDown(recovered.dispose);
        await recovered.initialize();
        expect(
          recovered.editor!.geometry.canonicalJson,
          controller.editor!.geometry.canonicalJson,
        );
        expect(recovered.existingBlockMappings.single.blockId, blockId);
        final saveCount = fake.saveCalls.length;
        expect(await recovered.forceSave(), isTrue);
        expect(fake.saveCalls, hasLength(saveCount));

        expect(await recovered.finalizeDraft(), isTrue);
        final intent =
            fake.finalizeCommands.single.existingBlockIntents!.single;
        expect(intent.blockId, blockId);
        expect(intent.action, InventoryExistingBlockAction.retainMapped);
        expect(intent.expectedBlockRevision, 7);
        expect(intent.targetPolygonIndex, 0);
        expect(fake.projection!.activeBlockPolygons.single.blockId, blockId);
      },
    );

    test(
      'AT-533-006 orthogonal edge nudge validates before history and autosave',
      () async {
        final validBlockId = _uuid(8200);
        final validFake = _FakeInventoryApplication.withMappedActive(
          geometry: _rectangleGeometry(),
          blocks: [_blockRecord(id: validBlockId)],
          floors: [_floorRecord(id: _uuid(8201), blockId: validBlockId)],
          activeBlockPolygons: [
            _blockPolygon(
              revisionId: _activeId,
              blockId: validBlockId,
              polygonIndex: 0,
            ),
          ],
        );
        final validController = _controller(
          validFake,
          intent: InventorySketchLaunchIntent.editActive,
        );
        addTearDown(validController.dispose);
        await validController.initialize();
        validController.setMode(InventorySketchEditorMode.select);
        validController.editor = validController.editor!.withSelection(
          const InventorySketchSelection.segment(
            polylineIndex: 0,
            segmentIndex: 0,
          ),
        );

        expect(
          validController.nudgeSelection(InventorySketchNudgeDirection.right),
          isFalse,
        );
        expect(
          validController.lastErrorCode,
          'inventory_block_edge_nudge_direction_invalid',
        );
        expect(validController.editor!.undoDepth, 0);
        expect(validFake.saveCalls, isEmpty);
        expect(
          validController.nudgeSelection(InventorySketchNudgeDirection.down),
          isTrue,
        );
        expect(validController.lastErrorCode, isNull);
        expect(validController.editor!.geometry.polylines.single.points, [
          _point(64, 128),
          _point(256, 128),
          _point(256, 256),
          _point(64, 256),
        ]);
        expect(
          validController.existingBlockMappings.single.blockId,
          validBlockId,
        );

        Future<void> expectRejected({
          required InventoryGeometry geometry,
          required InventorySketchSelection selection,
          required InventorySketchNudgeDirection direction,
          required String errorCode,
        }) async {
          final blockIds = [
            for (var index = 0; index < geometry.polylines.length; index += 1)
              _uuid(8300 + index),
          ];
          final fake = _FakeInventoryApplication.withMappedActive(
            geometry: geometry,
            blocks: [
              for (var index = 0; index < blockIds.length; index += 1)
                _blockRecord(
                  id: blockIds[index],
                  displayName: '${index + 1}. Blok',
                  normalizedName: '${index + 1}. blok',
                  ordinal: index + 1,
                ),
            ],
            floors: [
              for (var index = 0; index < blockIds.length; index += 1)
                _floorRecord(id: _uuid(8350 + index), blockId: blockIds[index]),
            ],
            activeBlockPolygons: [
              for (var index = 0; index < blockIds.length; index += 1)
                _blockPolygon(
                  revisionId: _activeId,
                  blockId: blockIds[index],
                  polygonIndex: index,
                ),
            ],
          );
          final controller = _controller(
            fake,
            intent: InventorySketchLaunchIntent.editActive,
          );
          addTearDown(controller.dispose);
          await controller.initialize();
          controller.setMode(InventorySketchEditorMode.select);
          controller.editor = controller.editor!.withSelection(selection);
          final beforeGeometry = controller.editor!.geometry.canonicalJson;
          final beforeUndoDepth = controller.editor!.undoDepth;
          final beforeProjection = fake.projection;
          final beforeMappings = [
            for (final mapping in controller.existingBlockMappings)
              (mapping.blockId, mapping.polygonIndex),
          ];

          expect(controller.nudgeSelection(direction), isFalse);
          expect(controller.lastErrorCode, errorCode);
          expect(controller.editor!.geometry.canonicalJson, beforeGeometry);
          expect(controller.editor!.undoDepth, beforeUndoDepth);
          expect(
            controller.existingBlockMappings.map(
              (mapping) => (mapping.blockId, mapping.polygonIndex),
            ),
            beforeMappings,
          );
          expect(fake.saveCalls, isEmpty);
          expect(fake.operationOrder, isEmpty);
          expect(identical(fake.projection, beforeProjection), isTrue);
        }

        await expectRejected(
          geometry: _edgeSelfIntersectionGeometry(),
          selection: const InventorySketchSelection.segment(
            polylineIndex: 0,
            segmentIndex: 4,
          ),
          direction: InventorySketchNudgeDirection.up,
          errorCode: 'inventory_block_polygon_self_intersects',
        );
        await expectRejected(
          geometry: _rectangleGeometry(left: 0, right: 192),
          selection: const InventorySketchSelection.polyline(polylineIndex: 0),
          direction: InventorySketchNudgeDirection.left,
          errorCode: 'inventory_block_nudge_out_of_bounds',
        );
        await expectRejected(
          geometry: InventoryGeometry(
            polylines: [
              _rectangleGeometry(left: 0, right: 192).polylines.single,
              _rectangleGeometry(left: 256, right: 448).polylines.single,
            ],
          ),
          selection: const InventorySketchSelection.polyline(polylineIndex: 0),
          direction: InventorySketchNudgeDirection.right,
          errorCode: 'inventory_block_polygon_ambiguous',
        );
        await expectRejected(
          geometry: _closedBlockGeometry(),
          selection: const InventorySketchSelection.segment(
            polylineIndex: 0,
            segmentIndex: 0,
          ),
          direction: InventorySketchNudgeDirection.right,
          errorCode: 'inventory_block_diagonal_edge_reshape_not_supported',
        );
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

    testWidgets(
      'failed intermediate generation saves fresh exact detached-block reattach',
      (tester) async {
        final activeBlockId = _uuid(8800);
        final detachedBlockId = _uuid(8810);
        final floorIds = [_uuid(8811), _uuid(8812)];
        final baseGeometry = _rectangleGeometry();
        final fake =
            _FakeInventoryApplication.withSpatialEditDraft(
                activeGeometry: baseGeometry,
                draftGeometry: baseGeometry,
                blocks: [
                  _blockRecord(id: activeBlockId, revision: 4),
                  _blockRecord(
                    id: detachedBlockId,
                    displayName: 'B Blok',
                    normalizedName: 'b blok',
                    ordinal: 2,
                    state: InventoryBlockState.detached,
                    revision: 3,
                  ),
                ],
                floors: [
                  _floorRecord(id: _uuid(8801), blockId: activeBlockId),
                  _floorRecord(id: floorIds[0], blockId: detachedBlockId),
                  _floorRecord(
                    id: floorIds[1],
                    blockId: detachedBlockId,
                    displayName: '2. Kat',
                    ordinal: 2,
                  ),
                ],
                activeBlockPolygons: [
                  _blockPolygon(
                    revisionId: _activeId,
                    blockId: activeBlockId,
                    polygonIndex: 0,
                  ),
                ],
                draftBlockPolygons: [
                  _blockPolygon(
                    revisionId: _draftId,
                    blockId: activeBlockId,
                    polygonIndex: 0,
                  ),
                ],
              )
              ..failSaveCount = 1
              ..saveFailureCode = 'inventory_legacy_geometry_immutable';
        final controller = _controller(
          fake,
          intent: InventorySketchLaunchIntent.editActive,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        final before = fake.projection!;
        final acknowledged = controller.acknowledgedGeometry!.canonicalJson;

        expect(controller.drawPoint(_point(512, 64)), isTrue);
        expect(await controller.forceSave(), isFalse);
        final failed = fake.saveCalls.single;
        final failedGeometry = failed.geometry.canonicalJson;
        expect(failed.geometry.polylines.last.closed, isFalse);
        expect(failed.geometry.polylines.last.points, [_point(512, 64)]);
        expect(
          failed.existingBlockMappings!.map((m) => (m.blockId, m.polygonIndex)),
          [(activeBlockId, 0)],
        );
        expect(failed.newBlocks, isEmpty);
        expect(controller.lastErrorCode, 'inventory_legacy_geometry_immutable');
        expect(controller.saveLabel, 'Kaydedilemedi');
        expect(controller.acknowledgedGeometry!.canonicalJson, acknowledged);
        expect(fake.projection, same(before));
        expect(fake.saveMutationCount, 0);
        expect(controller.isFinalizeEnabled, isFalse);
        expect(await controller.finalizeDraft(), isFalse);
        expect(fake.finalizeCalls, 0);

        for (final point in [
          _point(704, 64),
          _point(704, 256),
          _point(512, 256),
        ]) {
          expect(controller.drawPoint(point), isTrue);
        }
        expect(controller.closeWorkingBlockAsReattach(detachedBlockId), isTrue);
        final currentGeometry = controller.editor!.geometry.canonicalJson;
        expect(currentGeometry, isNot(failedGeometry));
        expect(controller.isFinalizeEnabled, isTrue);
        expect(await controller.forceSave(), isTrue);

        expect(fake.saveCalls, hasLength(2));
        final saved = fake.saveCalls.last;
        expect(saved.operationId, isNot(failed.operationId));
        expect(saved.geometry.canonicalJson, currentGeometry);
        expect(saved.geometry.polylines.first, baseGeometry.polylines.first);
        expect(saved.geometry.polylines.last.closed, isTrue);
        expect(saved.newBlocks, isEmpty);
        expect(controller.newBlocks, isEmpty);
        final expectedMappings = [(activeBlockId, 0), (detachedBlockId, 1)];
        expect(
          saved.existingBlockMappings!.map((m) => (m.blockId, m.polygonIndex)),
          expectedMappings,
        );
        expect(
          controller.existingBlockMappings.map(
            (m) => (m.blockId, m.polygonIndex),
          ),
          expectedMappings,
        );
        expect(
          fake.projection!.draftBlockPolygons.map(
            (m) => (m.blockId, m.polygonIndex),
          ),
          expectedMappings,
        );
        expect(fake.projection!.draftNewBlocks, isEmpty);
        expect(fake.projection!.blocks.map((block) => block.id), [
          activeBlockId,
          detachedBlockId,
        ]);
        expect(
          fake.projection!.blocks.map((block) => block.id).toSet(),
          hasLength(2),
        );
        expect(fake.projection!.floors, before.floors);
        expect(
          controller
              .floorsForExistingBlock(detachedBlockId)
              .map((floor) => floor.id),
          floorIds,
        );
        expect(controller.acknowledgedGeometry!.canonicalJson, currentGeometry);
        expect(
          fake.projection!.draftRevision!.geometry.canonicalJson,
          currentGeometry,
        );
        expect(controller.hasUnacknowledgedGeometry, isFalse);
        expect(controller.saveStatus, InventorySketchSaveStatus.saved);
        expect(controller.saveLabel, 'Kaydedildi');
        expect(controller.lastErrorCode, isNull);
        expect(fake.saveMutationCount, 1);
        expect(fake.maximumConcurrentSaves, 1);

        expect(await controller.finalizeDraft(), isTrue);
        expect(controller.finalizePersisted, isTrue);
        final intents = fake.finalizeCommands.single.existingBlockIntents!;
        expect(intents, hasLength(2));
        expect(
          intents.map(
            (intent) => (
              intent.blockId,
              intent.action,
              intent.expectedBlockRevision,
              intent.targetPolygonIndex,
            ),
          ),
          [
            (activeBlockId, InventoryExistingBlockAction.retainMapped, 4, 0),
            (detachedBlockId, InventoryExistingBlockAction.reattach, 3, 1),
          ],
        );
        expect(fake.finalizeCommands.single.newBlocks, isEmpty);
        expect(
          fake.projection!.activeRevision!.geometry.canonicalJson,
          currentGeometry,
        );
        expect(
          fake.projection!.activeRevision!.geometry.canonicalJson,
          isNot(failedGeometry),
        );
        expect(fake.projection!.floors, before.floors);
        expect(fake.projection!.blocks.map((block) => block.id), [
          activeBlockId,
          detachedBlockId,
        ]);
        await tester.pump(const Duration(milliseconds: 501));
        expect(fake.saveCalls, hasLength(2));
        expect(fake.saveMutationCount, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'expired newer debounce survives an in-flight stale failure without another edit',
      (tester) async {
        final gate = Completer<void>();
        final fake =
            _FakeInventoryApplication.withDraft(InventoryGeometry.emptyDraft())
              ..failSaveCount = 1
              ..saveGates.add(gate);
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();
        final acknowledged = controller.acknowledgedGeometry!.canonicalJson;

        expect(controller.drawPoint(_point(0, 0)), isTrue);
        await tester.pump(const Duration(milliseconds: 500));
        expect(fake.saveCalls, hasLength(1));
        expect(fake.concurrentSaves, 1);
        final older = fake.saveCalls.single;

        expect(controller.drawPoint(_point(64, 0)), isTrue);
        final current = controller.editor!.geometry.canonicalJson;
        await tester.pump(const Duration(milliseconds: 499));
        expect(fake.saveCalls, hasLength(1));
        await tester.pump(const Duration(milliseconds: 1));
        expect(fake.saveCalls, hasLength(1));
        expect(fake.concurrentSaves, 1);
        expect(fake.saveMutationCount, 0);
        expect(controller.acknowledgedGeometry!.canonicalJson, acknowledged);

        gate.complete();
        await tester.pump();
        expect(fake.saveCalls, hasLength(2));
        final newer = fake.saveCalls.last;
        expect(newer.operationId, isNot(older.operationId));
        expect(newer.geometry.canonicalJson, current);
        expect(
          newer.geometry.canonicalJson,
          isNot(older.geometry.canonicalJson),
        );
        expect(controller.acknowledgedGeometry!.canonicalJson, current);
        expect(controller.hasUnacknowledgedGeometry, isFalse);
        expect(controller.saveStatus, InventorySketchSaveStatus.saved);
        expect(controller.saveLabel, 'Kaydedildi');
        expect(controller.lastErrorCode, isNull);
        expect(fake.concurrentSaves, 0);
        expect(fake.maximumConcurrentSaves, 1);
        expect(fake.saveMutationCount, 1);
        await tester.pump(const Duration(milliseconds: 501));
        expect(fake.saveCalls, hasLength(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'durable older result survives transient verification load failure before fresh current save',
      (tester) async {
        final olderSaveGate = Completer<void>();
        final replayReadGate = Completer<void>();
        final currentSaveGate = Completer<void>();
        final fake = _FakeInventoryApplication.withDraft(
          InventoryGeometry.emptyDraft(),
        )..saveGates.add(olderSaveGate);
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();
        final initial = fake.projection!;
        final acknowledged = controller.acknowledgedGeometry!.canonicalJson;

        expect(controller.drawPoint(_point(0, 0)), isTrue);
        await tester.pump(const Duration(milliseconds: 500));
        expect(fake.saveCalls, hasLength(1));
        expect(fake.concurrentSaves, 1);
        final older = fake.saveCalls.single;
        expect(controller.drawPoint(_point(64, 0)), isTrue);
        final currentGeometry = controller.editor!.geometry.canonicalJson;
        await tester.pump(const Duration(milliseconds: 500));
        expect(fake.saveCalls, hasLength(1));
        expect(fake.concurrentSaves, 1);
        expect(fake.saveMutationCount, 0);

        fake.failLoadCount = 1;
        olderSaveGate.complete();
        await tester.pump();

        expect(fake.saveCalls, hasLength(1));
        expect(fake.saveMutationCount, 1);
        final durableOlder = fake.projection!;
        expect(durableOlder.sketch.revision, initial.sketch.revision + 1);
        expect(
          durableOlder.draftRevision!.contentRevision,
          initial.draftRevision!.contentRevision + 1,
        );
        expect(
          durableOlder.draftRevision!.geometry.canonicalJson,
          older.geometry.canonicalJson,
        );
        expect(
          durableOlder.draftRevision!.geometry.canonicalJson,
          isNot(currentGeometry),
        );
        expect(controller.acknowledgedGeometry!.canonicalJson, acknowledged);
        expect(controller.expectedSketchRevision, initial.sketch.revision);
        expect(
          controller.expectedContentRevision,
          initial.draftRevision!.contentRevision,
        );
        expect(controller.hasUnacknowledgedGeometry, isTrue);
        expect(controller.saveStatus, InventorySketchSaveStatus.failed);
        expect(controller.saveLabel, 'Kaydedilemedi');
        expect(controller.lastErrorCode, 'inventory_persistence_failed');
        expect(controller.isFinalizeEnabled, isFalse);
        expect(controller.finalizePersisted, isFalse);
        expect(fake.finalizeCalls, 0);
        expect(fake.concurrentSaves, 0);
        expect(fake.maximumConcurrentSaves, 1);

        fake.loadGates.add(replayReadGate);
        var forceCompleted = false;
        final forced = controller.forceSave().then((result) {
          forceCompleted = true;
          return result;
        });
        await tester.pump();

        expect(fake.saveCalls, hasLength(2));
        final replay = fake.saveCalls.last;
        expect(replay, same(older));
        expect(replay.operationId, older.operationId);
        expect(replay.geometry.canonicalJson, older.geometry.canonicalJson);
        expect(replay.expectedSketchRevision, older.expectedSketchRevision);
        expect(replay.expectedContentRevision, older.expectedContentRevision);
        expect(replay.draftRevisionId, older.draftRevisionId);
        expect(replay.existingBlockMappings, older.existingBlockMappings);
        expect(replay.newBlocks, older.newBlocks);
        expect(fake.saveMutationCount, 1);
        expect(fake.projection, same(durableOlder));
        expect(controller.acknowledgedGeometry!.canonicalJson, acknowledged);
        expect(forceCompleted, isFalse);

        fake.saveGates.add(currentSaveGate);
        replayReadGate.complete();
        await tester.pump();

        expect(fake.saveCalls, hasLength(3));
        final current = fake.saveCalls.last;
        expect(current.operationId, isNot(older.operationId));
        expect(current.geometry.canonicalJson, currentGeometry);
        expect(
          current.geometry.canonicalJson,
          isNot(older.geometry.canonicalJson),
        );
        expect(current.sketchId, durableOlder.sketch.id);
        expect(current.draftRevisionId, durableOlder.draftRevision!.id);
        expect(current.expectedSketchRevision, durableOlder.sketch.revision);
        expect(
          current.expectedContentRevision,
          durableOlder.draftRevision!.contentRevision,
        );
        expect(controller.draftRevisionId, durableOlder.draftRevision!.id);
        expect(controller.expectedSketchRevision, durableOlder.sketch.revision);
        expect(
          controller.expectedContentRevision,
          durableOlder.draftRevision!.contentRevision,
        );
        expect(
          controller.acknowledgedGeometry!.canonicalJson,
          older.geometry.canonicalJson,
        );
        expect(controller.editor!.geometry.canonicalJson, currentGeometry);
        expect(controller.hasUnacknowledgedGeometry, isTrue);
        expect(controller.saveStatus, InventorySketchSaveStatus.saving);
        expect(fake.saveMutationCount, 1);
        expect(fake.concurrentSaves, 1);
        expect(fake.maximumConcurrentSaves, 1);
        expect(forceCompleted, isFalse);

        currentSaveGate.complete();
        await tester.pump();
        expect(await forced, isTrue);
        expect(forceCompleted, isTrue);
        expect(fake.saveMutationCount, 2);
        expect(
          fake.projection!.draftRevision!.geometry.canonicalJson,
          currentGeometry,
        );
        expect(controller.acknowledgedGeometry!.canonicalJson, currentGeometry);
        expect(controller.hasUnacknowledgedGeometry, isFalse);
        expect(controller.saveStatus, InventorySketchSaveStatus.saved);
        expect(controller.saveLabel, 'Kaydedildi');
        expect(controller.lastErrorCode, isNull);
        expect(fake.concurrentSaves, 0);
        expect(fake.maximumConcurrentSaves, 1);
        await tester.pump(const Duration(milliseconds: 501));
        expect(fake.saveCalls, hasLength(3));
        expect(fake.saveMutationCount, 2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'stale failure preserves a newer debounce that is not yet eligible',
      (tester) async {
        final gate = Completer<void>();
        final fake =
            _FakeInventoryApplication.withDraft(InventoryGeometry.emptyDraft())
              ..failSaveCount = 1
              ..saveGates.add(gate);
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();

        expect(controller.drawPoint(_point(0, 0)), isTrue);
        await tester.pump(const Duration(milliseconds: 500));
        expect(fake.saveCalls, hasLength(1));
        expect(fake.concurrentSaves, 1);
        expect(controller.drawPoint(_point(64, 0)), isTrue);
        gate.complete();
        await tester.pump();
        expect(fake.saveCalls, hasLength(1));
        expect(fake.concurrentSaves, 0);
        expect(controller.saveStatus, InventorySketchSaveStatus.saving);
        expect(controller.lastErrorCode, isNull);
        expect(controller.hasUnacknowledgedGeometry, isTrue);
        await tester.pump(const Duration(milliseconds: 499));
        expect(fake.saveCalls, hasLength(1));
        await tester.pump(const Duration(milliseconds: 1));
        expect(fake.saveCalls, hasLength(2));
        expect(
          fake.saveCalls.last.operationId,
          isNot(fake.saveCalls.first.operationId),
        );
        expect(
          fake.saveCalls.last.geometry.canonicalJson,
          controller.editor!.geometry.canonicalJson,
        );
        expect(
          controller.acknowledgedGeometry!.canonicalJson,
          controller.editor!.geometry.canonicalJson,
        );
        expect(controller.hasUnacknowledgedGeometry, isFalse);
        expect(controller.saveLabel, 'Kaydedildi');
        expect(controller.lastErrorCode, isNull);
        expect(fake.maximumConcurrentSaves, 1);
        expect(fake.saveMutationCount, 1);
        await tester.pump(const Duration(milliseconds: 501));
        expect(fake.saveCalls, hasLength(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'force during an in-flight stale failure waits for the current serialized save',
      (tester) async {
        final olderGate = Completer<void>();
        final currentGate = Completer<void>();
        final fake =
            _FakeInventoryApplication.withDraft(InventoryGeometry.emptyDraft())
              ..failSaveCount = 1
              ..saveGates.addAll([olderGate, currentGate]);
        final controller = _controller(fake);
        addTearDown(controller.dispose);
        await controller.initialize();
        final acknowledged = controller.acknowledgedGeometry!.canonicalJson;

        expect(controller.drawPoint(_point(0, 0)), isTrue);
        await tester.pump(const Duration(milliseconds: 500));
        expect(fake.saveCalls, hasLength(1));
        expect(fake.concurrentSaves, 1);
        expect(controller.drawPoint(_point(64, 0)), isTrue);
        var forceCompleted = false;
        final forced = controller.forceSave().then((result) {
          forceCompleted = true;
          return result;
        });
        olderGate.complete();
        await tester.pump();

        expect(fake.saveCalls, hasLength(2));
        expect(fake.concurrentSaves, 1);
        expect(fake.maximumConcurrentSaves, 1);
        expect(forceCompleted, isFalse);
        expect(controller.acknowledgedGeometry!.canonicalJson, acknowledged);
        expect(controller.saveStatus, InventorySketchSaveStatus.saving);
        expect(controller.lastErrorCode, isNull);
        expect(
          fake.saveCalls.last.operationId,
          isNot(fake.saveCalls.first.operationId),
        );
        expect(
          fake.saveCalls.last.geometry.canonicalJson,
          controller.editor!.geometry.canonicalJson,
        );
        currentGate.complete();
        await tester.pump();

        expect(await forced, isTrue);
        expect(forceCompleted, isTrue);
        expect(
          controller.acknowledgedGeometry!.canonicalJson,
          controller.editor!.geometry.canonicalJson,
        );
        expect(controller.hasUnacknowledgedGeometry, isFalse);
        expect(controller.saveLabel, 'Kaydedildi');
        expect(controller.lastErrorCode, isNull);
        expect(fake.concurrentSaves, 0);
        expect(fake.maximumConcurrentSaves, 1);
        expect(fake.saveMutationCount, 1);
        await tester.pump(const Duration(milliseconds: 501));
        expect(fake.saveCalls, hasLength(2));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'recovered lifecycle change refreshes pending state but unchanged retry keeps identity',
      (tester) async {
        final blockId = _uuid(8820);
        final fake = _FakeInventoryApplication.withSpatialEditDraft(
          activeGeometry: _rectangleGeometry(),
          draftGeometry: InventoryGeometry.emptyDraft(),
          blocks: [_blockRecord(id: blockId)],
          floors: [_floorRecord(id: _uuid(8821), blockId: blockId)],
          activeBlockPolygons: [
            _blockPolygon(
              revisionId: _activeId,
              blockId: blockId,
              polygonIndex: 0,
            ),
          ],
        )..failSaveCount = 2;
        final controller = _controller(
          fake,
          intent: InventorySketchLaunchIntent.editActive,
        );
        addTearDown(controller.dispose);
        await controller.initialize();
        expect(
          controller.recordRecoveredLifecycleChoice(
            blockId,
            InventoryExistingBlockAction.detach,
          ),
          isTrue,
        );
        expect(controller.hasUnacknowledgedGeometry, isFalse);
        expect(fake.saveCalls, isEmpty);

        final added = _appendClosedBlock(
          controller,
          left: 512,
          top: 64,
          right: 704,
          bottom: 256,
          displayName: 'Yeni Blok',
        );
        expect(await controller.forceSave(), isFalse);
        final failed = fake.saveCalls.single;
        controller.setMode(InventorySketchEditorMode.select);
        controller.selectAt(
          const Offset(512, 64),
          InventoryViewport.fit(const Size(4096, 3072)),
        );
        expect(
          controller.recordRecoveredLifecycleChoice(
            blockId,
            InventoryExistingBlockAction.detach,
          ),
          isTrue,
        );
        expect(await controller.finalizeDraft(), isFalse);
        expect(fake.finalizeCalls, 0);
        expect(controller.finalizePersisted, isFalse);
        expect(fake.saveCalls, hasLength(2));
        expect(fake.saveCalls.last.operationId, failed.operationId);
        expect(fake.saveMutationCount, 0);
        expect(controller.saveLabel, 'Kaydedilemedi');

        expect(
          controller.recordRecoveredLifecycleChoice(
            blockId,
            InventoryExistingBlockAction.archive,
          ),
          isTrue,
        );
        expect(
          controller.editor!.geometry.canonicalJson,
          failed.geometry.canonicalJson,
        );
        expect(await controller.forceSave(), isTrue);
        expect(fake.saveCalls, hasLength(3));
        final current = fake.saveCalls.last;
        expect(current.operationId, isNot(failed.operationId));
        expect(current.geometry.canonicalJson, failed.geometry.canonicalJson);
        expect(current.existingBlockMappings, isEmpty);
        _expectSameBlockIdentity(
          current.newBlocks.single,
          added,
          polygonIndex: 0,
        );
        expect(fake.saveMutationCount, 1);
        expect(fake.maximumConcurrentSaves, 1);
        expect(controller.hasUnacknowledgedGeometry, isFalse);
        expect(controller.saveLabel, 'Kaydedildi');
        controller.discardUnsaved();
        expect(await controller.finalizeDraft(), isTrue);
        final intent =
            fake.finalizeCommands.single.existingBlockIntents!.single;
        expect(intent.blockId, blockId);
        expect(intent.action, InventoryExistingBlockAction.archive);
        expect(intent.targetPolygonIndex, isNull);
        _expectSameBlockIdentity(
          fake.finalizeCommands.single.newBlocks.single,
          added,
          polygonIndex: 0,
        );
        expect(fake.abandonCalls, 0);
        await tester.pump(const Duration(milliseconds: 501));
        expect(fake.saveCalls, hasLength(3));
        expect(tester.takeException(), isNull);
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
      'finalize enablement requires complete geometry but accepts pending save',
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
        emptyController.drawPoint(_point(192, 0));
        emptyController.drawPoint(_point(192, 192));
        emptyController.drawPoint(_point(0, 192));
        final pendingBlock = emptyController.createBlockDraft(
          displayName: 'A Blok',
          floorCount: 1,
        );
        expect(emptyController.closeWorkingBlock(pendingBlock), isTrue);
        expect(emptyController.saveStatus, InventorySketchSaveStatus.saving);
        expect(emptyController.hasUnacknowledgedGeometry, isTrue);
        expect(emptyController.isFinalizeEnabled, isTrue);

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
      'edit-active keeps base untouched while appended block saves reloads and finalizes',
      () async {
        final base = _closedBlockGeometry();
        final fake = _FakeInventoryApplication.withActive(base);
        final controller = _controller(
          fake,
          intent: InventorySketchLaunchIntent.editActive,
        );
        addTearDown(controller.dispose);
        await controller.initialize();

        for (final point in [
          _point(512, 0),
          _point(768, 64),
          _point(704, 256),
          _point(512, 192),
        ]) {
          expect(controller.drawPoint(point), isTrue);
        }
        final appended = controller.createBlockDraft(
          displayName: 'Yeni Alan',
          floorCount: 2,
        );
        expect(controller.closeWorkingBlock(appended), isTrue);
        expect(await controller.forceSave(), isTrue);
        expect(fake.saveMutationCount, 1);
        expect(
          fake.projection!.draftRevision!.geometry.polylines.first,
          base.polylines.first,
        );
        expect(
          fake.projection!.draftRevision!.geometry.polylines,
          hasLength(2),
        );

        final recovered = _controller(
          fake,
          intent: InventorySketchLaunchIntent.editActive,
        );
        addTearDown(recovered.dispose);
        await recovered.initialize();
        expect(fake.editCalls, 1);
        expect(
          recovered.editor!.geometry.polylines.first,
          base.polylines.first,
        );
        _expectSameBlockIdentity(
          recovered.newBlocks.single,
          appended,
          polygonIndex: 1,
        );

        expect(await recovered.finalizeDraft(), isTrue);
        expect(fake.projection!.draftRevision, isNull);
        expect(
          fake.projection!.activeRevision!.geometry.polylines.first,
          base.polylines.first,
        );
        expect(fake.finalizeCommands.single.newBlocks.single.id, appended.id);
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
        controller.drawPoint(_point(192, 0));
        controller.drawPoint(_point(192, 192));
        controller.drawPoint(_point(0, 192));
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
    'explicit close dialog persists orthogonal block metadata and recovers',
    (tester) async {
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      );
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, pageKey);
      final controller = pageKey.currentState!.controller;

      for (final point in [
        _point(0, 0),
        _point(192, 0),
        _point(192, 192),
        _point(0, 192),
      ]) {
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
      expect(find.text('Alanı ekle'), findsOneWidget);
      expect(find.text('Alanı oluştur'), findsNothing);
      expect(find.text('Kaydet'), findsNothing);

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
      expect(fake.finalizeCalls, 0);
      expect(
        fake.saveCalls.last.newBlocks.single.id,
        controller.newBlocks.single.id,
      );
      expect(tester.takeException(), isNull);

      for (final point in [
        _point(512, 0),
        _point(704, 0),
        _point(704, 192),
        _point(512, 192),
      ]) {
        controller.drawPoint(point);
      }
      await tester.pump();
      await tester.ensureVisible(closeBlock);
      await tester.tap(closeBlock);
      await tester.pumpAndSettle();
      expect(find.text('Alanı ekle'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('inventory-block-name')),
        'B Blok',
      );
      await tester.tap(find.byKey(const Key('inventory-block-metadata-save')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(controller.editor!.geometry.polylines, hasLength(2));
      expect(controller.newBlocks.map((block) => block.displayName), [
        'A Blok',
        'B Blok',
      ]);
      expect(fake.finalizeCalls, 0);
      expect(fake.saveCalls.last.newBlocks, hasLength(2));
      final expectedGeometry = controller.editor!.geometry.canonicalJson;
      final expectedBlocks = List<InventoryBlockDraft>.of(controller.newBlocks);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final recoveredKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, recoveredKey);
      final recoveredController = recoveredKey.currentState!.controller;
      expect(recoveredController.newBlocks.map((block) => block.displayName), [
        'A Blok',
        'B Blok',
      ]);
      expect(
        recoveredController.newBlocks.first.floors.map(
          (floor) => floor.ordinal,
        ),
        [1, 2],
      );
      expect(
        recoveredController.editor!.geometry.canonicalJson,
        expectedGeometry,
      );
      expect(recoveredController.newBlocks, hasLength(expectedBlocks.length));
      for (var index = 0; index < expectedBlocks.length; index += 1) {
        _expectSameBlockIdentity(
          recoveredController.newBlocks[index],
          expectedBlocks[index],
          polygonIndex: index,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'MT-527-004 invalid closure rejects before metadata without mutation',
    (tester) async {
      final cases =
          <
            ({
              String label,
              List<InventorySketchPoint> points,
              String errorCode,
            })
          >[
            (
              label: 'intersecting',
              points: [
                _point(64, 64),
                _point(256, 64),
                _point(256, 256),
                _point(64, 256),
              ],
              errorCode: 'inventory_block_polygon_ambiguous',
            ),
            (
              label: 'touching',
              points: [
                _point(192, 64),
                _point(320, 64),
                _point(320, 128),
                _point(192, 128),
              ],
              errorCode: 'inventory_block_polygon_ambiguous',
            ),
            (
              label: 'contained',
              points: [
                _point(64, 64),
                _point(128, 64),
                _point(128, 128),
                _point(64, 128),
              ],
              errorCode: 'inventory_block_polygon_ambiguous',
            ),
            (
              label: 'self-intersecting',
              points: [
                _point(512, 128),
                _point(704, 128),
                _point(704, 320),
                _point(576, 320),
                _point(576, 64),
                _point(768, 64),
                _point(768, 256),
                _point(512, 256),
              ],
              errorCode: 'inventory_block_polygon_self_intersects',
            ),
          ];

      for (final testCase in cases) {
        final firstBlock = _blockDrafts().single;
        final fake = _FakeInventoryApplication.withDraft(
          _draftWithWorkingSecondBlock(testCase.points.first),
          draftNewBlocks: [firstBlock],
        );
        final orientations = _OrientationRecorder();
        final pageKey = GlobalKey<InventorySketchEditorPageState>();
        await _openEditor(tester, fake, orientations, pageKey);
        final controller = pageKey.currentState!.controller;
        for (final point in testCase.points.skip(1)) {
          controller.setFreeLengthNextSegment(true);
          expect(
            controller.drawPoint(point),
            isTrue,
            reason: '${testCase.label} setup point',
          );
        }
        expect(await controller.forceSave(), isTrue);
        await tester.pumpAndSettle();
        expect(fake.saveCalls, hasLength(1), reason: testCase.label);
        expect(fake.saveMutationCount, 1, reason: testCase.label);
        expect(controller.hasUnacknowledgedGeometry, isFalse);

        final originalProjection = fake.projection!;
        final geometry = controller.editor!.geometry;
        final beforeGeometry = controller.editor!.geometry.canonicalJson;
        final saveCallsBeforeClose =
            List<AutosaveInventorySketchDraftCommand>.of(fake.saveCalls);
        final saveMutationCountBeforeClose = fake.saveMutationCount;
        final operationOrderBeforeClose = List<String>.of(fake.operationOrder);
        expect(
          () => controller.validateWorkingBlockClosure(),
          throwsA(
            isA<InventoryFailure>().having(
              (error) => error.code,
              'code',
              testCase.errorCode,
            ),
          ),
          reason: testCase.label,
        );
        expect(controller.lastErrorCode, isNull);

        final closeBlock = find.byKey(
          const Key('inventory-editor-close-block'),
        );
        await tester.ensureVisible(closeBlock);
        final closeIconButton = tester.widget<IconButton>(
          find.descendant(of: closeBlock, matching: find.byType(IconButton)),
        );
        expect(closeIconButton.onPressed, isNotNull, reason: testCase.label);
        await tester.tap(closeBlock);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        expect(
          find.byKey(const Key('inventory-block-metadata-dialog')),
          findsNothing,
          reason: testCase.label,
        );
        expect(controller.lastErrorCode, testCase.errorCode);
        expect(controller.editor!.geometry.canonicalJson, beforeGeometry);
        expect(controller.editor!.workingPolylineIndex, 1);
        expect(controller.newBlocks, hasLength(1));
        _expectSameBlockIdentity(
          controller.newBlocks.single,
          firstBlock,
          polygonIndex: 0,
        );
        expect(identical(fake.projection, originalProjection), isTrue);
        expect(
          fake.projection!.draftRevision!.geometry.canonicalJson,
          geometry.canonicalJson,
        );
        expect(fake.saveCalls, orderedEquals(saveCallsBeforeClose));
        expect(fake.saveMutationCount, saveMutationCountBeforeClose);
        expect(fake.operationOrder, orderedEquals(operationOrderBeforeClose));
        expect(fake.finalizeCalls, 0);
        expect(tester.takeException(), isNull);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'smart alignment guide is visible and Serbest uzunluk resets after one edge',
    (tester) async {
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      );
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, pageKey);
      final controller = pageKey.currentState!.controller;
      controller.drawPoint(_point(0, 0));
      controller.drawPoint(_point(256, 64));
      controller.drawPoint(_point(320, 256));
      await tester.pump();

      final canvas = find.byKey(const Key('inventory-sketch-canvas-gesture'));
      final canvasRect = tester.getRect(canvas);
      final viewport = InventoryViewport.fit(canvasRect.size);
      final target =
          canvasRect.topLeft + viewport.virtualToView(_point(128, 320));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: canvasRect.center);
      await mouse.moveTo(target);
      await tester.pump();

      expect(
        find.byKey(const Key('inventory-editor-smart-alignment-guide')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const Key('inventory-editor-smart-alignment-guide')),
            )
            .properties
            .label,
        'Akıllı hizalama kılavuzu',
      );

      final freeLength = find.byKey(const Key('inventory-editor-free-length'));
      await tester.ensureVisible(freeLength);
      await tester.tap(freeLength);
      await tester.pump();
      expect(controller.freeLengthNextSegment, isTrue);
      expect(
        find.byKey(const Key('inventory-editor-free-length-selected')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory-editor-smart-alignment-guide')),
        findsNothing,
      );

      await mouse.moveTo(target + const Offset(1, 0));
      await tester.pump();
      expect(
        find.byKey(const Key('inventory-editor-smart-alignment-guide')),
        findsNothing,
      );
      expect(controller.drawPoint(_point(128, 320)), isTrue);
      await tester.pump();
      expect(controller.freeLengthNextSegment, isFalse);
      expect(
        find.byKey(const Key('inventory-editor-free-length-selected')),
        findsNothing,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'AT-533-014 mapped delete requires exact choice and history keeps mapping',
    (tester) async {
      final blockId = _uuid(8400);
      final geometry = _rectangleGeometry();
      final fake = _FakeInventoryApplication.withMappedActive(
        geometry: geometry,
        blocks: [_blockRecord(id: blockId)],
        floors: [_floorRecord(id: _uuid(8401), blockId: blockId)],
        activeBlockPolygons: [
          _blockPolygon(
            revisionId: _activeId,
            blockId: blockId,
            polygonIndex: 0,
          ),
        ],
      );
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(
        tester,
        fake,
        orientations,
        pageKey,
        intent: InventorySketchLaunchIntent.editActive,
      );
      final controller = pageKey.currentState!.controller;
      final originalDraftRevisionId = controller.draftRevisionId;
      controller.editor = controller.editor!.withSelection(
        const InventorySketchSelection.polyline(polylineIndex: 0),
      );
      controller.setMode(InventorySketchEditorMode.select);
      await tester.pump();
      final beforeGeometry = controller.editor!.geometry.canonicalJson;
      final beforeMappings = controller.existingBlockMappings;

      final delete = find.byKey(const Key('inventory-editor-delete'));
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inventory-block-lifecycle-dialog')),
        findsOneWidget,
      );
      expect(find.text('Bloğu ve envanter kayıtlarını sil'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory-block-lifecycle-archive')),
        findsOneWidget,
      );
      expect(
        find.text('Bloğu krokiden kaldır, kayıtları koru'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory-block-lifecycle-detach')),
        findsOneWidget,
      );
      expect(controller.editor!.geometry.canonicalJson, beforeGeometry);
      expect(controller.existingBlockMappings.single.blockId, blockId);
      expect(fake.saveCalls, isEmpty);

      await tester.tap(
        find.byKey(const Key('inventory-block-lifecycle-detach')),
      );
      await tester.pumpAndSettle();
      expect(controller.editor!.geometry.polylines, isEmpty);
      expect(controller.existingBlockMappings, isEmpty);
      expect(controller.hasUnresolvedLifecycleChoices, isFalse);
      expect(controller.isFinalizeEnabled, isTrue);

      expect(controller.undo(), isTrue);
      expect(controller.editor!.geometry.canonicalJson, beforeGeometry);
      expect(
        controller.existingBlockMappings.map(
          (mapping) => (mapping.blockId, mapping.polygonIndex),
        ),
        beforeMappings.map(
          (mapping) => (mapping.blockId, mapping.polygonIndex),
        ),
      );
      expect(controller.redo(), isTrue);
      expect(controller.editor!.geometry.polylines, isEmpty);
      expect(controller.existingBlockMappings, isEmpty);
      expect(controller.hasUnresolvedLifecycleChoices, isFalse);

      expect(await controller.finalizeDraft(), isTrue);
      expect(
        controller.draftRevisionId,
        allOf(isNotNull, isNot(originalDraftRevisionId)),
      );
      final intent = fake.finalizeCommands.single.existingBlockIntents!.single;
      expect(intent.blockId, blockId);
      expect(intent.action, InventoryExistingBlockAction.detach);
      expect(intent.targetPolygonIndex, isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'AT-533-014 recovered missing mapping requires a fresh session choice',
    (tester) async {
      final blockId = _uuid(8500);
      final activeGeometry = _rectangleGeometry();
      final fake = _FakeInventoryApplication.withSpatialEditDraft(
        activeGeometry: activeGeometry,
        draftGeometry: InventoryGeometry.emptyDraft(),
        blocks: [_blockRecord(id: blockId)],
        floors: [_floorRecord(id: _uuid(8501), blockId: blockId)],
        activeBlockPolygons: [
          _blockPolygon(
            revisionId: _activeId,
            blockId: blockId,
            polygonIndex: 0,
          ),
        ],
      );
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(
        tester,
        fake,
        orientations,
        pageKey,
        intent: InventorySketchLaunchIntent.editActive,
      );
      final controller = pageKey.currentState!.controller;

      expect(
        find.byKey(const Key('inventory-block-lifecycle-dialog')),
        findsOneWidget,
      );
      expect(controller.hasUnresolvedLifecycleChoices, isTrue);
      expect(controller.isFinalizeEnabled, isFalse);
      expect(fake.saveCalls, isEmpty);

      await tester.tap(
        find.byKey(const Key('inventory-block-lifecycle-detach')),
      );
      await tester.pumpAndSettle();
      expect(controller.hasUnresolvedLifecycleChoices, isFalse);
      expect(controller.isFinalizeEnabled, isTrue);
      expect(controller.hasUnacknowledgedGeometry, isFalse);
      expect(fake.saveCalls, isEmpty);

      final freshSession = _controller(
        fake,
        intent: InventorySketchLaunchIntent.editActive,
      );
      addTearDown(freshSession.dispose);
      await freshSession.initialize();
      expect(freshSession.hasUnresolvedLifecycleChoices, isTrue);
      expect(freshSession.isFinalizeEnabled, isFalse);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'AT-533-011 Turkish-normalized reattach reuses exact block and floor IDs',
    (tester) async {
      final blockId = _uuid(8600);
      final floorIds = [_uuid(8601), _uuid(8602)];
      final fake = _FakeInventoryApplication.withSpatialEditDraft(
        activeGeometry: InventoryGeometry.emptyDraft(),
        draftGeometry: InventoryGeometry.emptyDraft(),
        blocks: [
          _blockRecord(
            id: blockId,
            displayName: 'I Blok',
            normalizedName: 'ı blok',
            state: InventoryBlockState.detached,
            revision: 3,
          ),
        ],
        floors: [
          _floorRecord(id: floorIds[0], blockId: blockId),
          _floorRecord(
            id: floorIds[1],
            blockId: blockId,
            displayName: '2. Kat',
            ordinal: 2,
          ),
        ],
      );
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(
        tester,
        fake,
        orientations,
        pageKey,
        intent: InventorySketchLaunchIntent.editActive,
      );
      final controller = pageKey.currentState!.controller;
      final originalDraftRevisionId = controller.draftRevisionId;
      for (final point in [
        _point(64, 64),
        _point(256, 64),
        _point(256, 256),
        _point(64, 256),
      ]) {
        expect(controller.drawPoint(point), isTrue);
      }
      await tester.pump();

      final close = find.byKey(const Key('inventory-editor-close-block'));
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('inventory-block-name')),
        'I   BLOK',
      );
      await tester.tap(find.byKey(const Key('inventory-block-metadata-save')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inventory-block-reattach-dialog')),
        findsOneWidget,
      );
      expect(controller.existingBlockMappings, isEmpty);
      expect(controller.newBlocks, isEmpty);
      expect(controller.editor!.workingPolylineIndex, 0);
      expect(find.textContaining('I Blok'), findsOneWidget);
      expect(find.textContaining('2 kat'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('inventory-block-reattach-confirm')),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(controller.newBlocks, isEmpty);
      expect(
        controller.draftRevisionId,
        allOf(isNotNull, isNot(originalDraftRevisionId)),
      );
      expect(fake.projection!.draftRevision!.id, controller.draftRevisionId);
      expect(controller.existingBlockMappings, hasLength(1));
      expect(controller.existingBlockMappings.single.blockId, blockId);
      expect(controller.existingBlockMappings.single.polygonIndex, 0);
      expect(
        controller.floorsForExistingBlock(blockId).map((floor) => floor.id),
        floorIds,
      );
      expect(fake.saveCalls, isNotEmpty);
      expect(
        fake.saveCalls.last.existingBlockMappings!.single.blockId,
        blockId,
      );
      expect(fake.saveCalls.last.newBlocks, isEmpty);

      expect(await controller.finalizeDraft(), isTrue);
      final intent = fake.finalizeCommands.single.existingBlockIntents!.single;
      expect(intent.blockId, blockId);
      expect(intent.action, InventoryExistingBlockAction.reattach);
      expect(intent.expectedBlockRevision, 3);
      expect(intent.targetPolygonIndex, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('full-screen editor uses accessible icon-only right toolbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fake = _FakeInventoryApplication.withDraft(
      _closedBlockGeometry(),
      draftNewBlocks: _blockDrafts(),
    );
    final orientations = _OrientationRecorder();
    final pageKey = GlobalKey<InventorySketchEditorPageState>();
    await _openEditor(tester, fake, orientations, pageKey, textScale: 1.6);
    expect(orientations.calls.single, [DeviceOrientation.portraitUp]);

    expect(find.byType(AppBar), findsNothing);
    final workspace = find.byKey(
      const Key('inventory-editor-fullscreen-workspace'),
    );
    final canvas = find.byKey(const Key('inventory-sketch-canvas-gesture'));
    final toolbar = find.byKey(const Key('inventory-editor-right-toolbar'));
    expect(workspace, findsOneWidget);
    expect(canvas, findsOneWidget);
    expect(toolbar, findsOneWidget);
    expect(tester.getRect(canvas).size, tester.getRect(workspace).size);
    expect(
      tester.getRect(toolbar).right,
      closeTo(tester.getRect(workspace).right - 8, 0.1),
    );
    expect(
      find.descendant(of: toolbar, matching: find.byType(Text)),
      findsNothing,
    );

    final controls = <Key, String>{
      Key('inventory-editor-back'): 'Geri',
      Key('inventory-editor-mode-draw'): 'Çiz',
      Key('inventory-editor-mode-select'): 'Seç',
      Key('inventory-editor-mode-pan'): 'Taşı',
      Key('inventory-editor-undo'): 'Geri al',
      Key('inventory-editor-redo'): 'İleri al',
      Key('inventory-editor-finish-line'): 'Çizgiyi bitir',
      Key('inventory-editor-close-block'): 'Alanı kapat',
      Key('inventory-editor-free-length'): 'Serbest uzunluk',
      Key('inventory-editor-delete'): 'Seçileni sil',
      Key('inventory-editor-nudge-up'): 'Yukarı taşı',
      Key('inventory-editor-nudge-right'): 'Sağa taşı',
      Key('inventory-editor-nudge-down'): 'Aşağı taşı',
      Key('inventory-editor-nudge-left'): 'Sola taşı',
      Key('inventory-editor-zoom-out'): 'Uzaklaştır',
      Key('inventory-editor-zoom-in'): 'Yakınlaştır',
      Key('inventory-editor-fit'): 'Tamamını göster',
      Key('inventory-editor-finalize'): 'Krokiyi yayınla',
    };
    for (final entry in controls.entries) {
      final control = find.byKey(entry.key);
      expect(control, findsOneWidget);
      await tester.ensureVisible(control);
      await tester.pump();
      expect(control.hitTestable(), findsOneWidget);
      expect(tester.getSize(control).width, greaterThanOrEqualTo(40));
      expect(tester.getSize(control).height, greaterThanOrEqualTo(40));
      expect(
        tester
            .widgetList<Tooltip>(
              find.descendant(of: control, matching: find.byType(Tooltip)),
            )
            .map((tooltip) => tooltip.message),
        contains(entry.value),
      );
      expect(
        tester
            .widgetList<Semantics>(
              find.descendant(of: control, matching: find.byType(Semantics)),
            )
            .map((semantics) => semantics.properties.label),
        contains(entry.value),
      );
    }

    expect(
      find.byKey(const Key('inventory-editor-mode-selected-draw')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('inventory-editor-mode-select')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('inventory-editor-mode-select')));
    await tester.pump();
    expect(
      find.byKey(const Key('inventory-editor-mode-selected-draw')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('inventory-editor-mode-selected-select')),
      findsOneWidget,
    );
    final canvasState = tester.state<InventorySketchCanvasState>(
      find.byType(InventorySketchCanvas),
    );
    final zoomBefore = canvasState.viewport!.zoom;
    final zoomIn = find.byKey(const Key('inventory-editor-zoom-in'));
    await tester.ensureVisible(zoomIn);
    await tester.pump();
    expect(zoomIn.hitTestable(), findsOneWidget);
    await tester.tap(zoomIn);
    await tester.pump();
    expect(canvasState.viewport!.zoom, greaterThan(zoomBefore));
    final fit = find.byKey(const Key('inventory-editor-fit'));
    await tester.ensureVisible(fit);
    await tester.pump();
    await tester.tap(fit);
    await tester.pump();
    expect(canvasState.viewport!.zoom, zoomBefore);
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'closed block final icon drains pending autosave before create finalize',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = _FakeInventoryApplication.withDraft(
        InventoryGeometry.emptyDraft(),
      );
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      bool? result;
      await _openEditor(
        tester,
        fake,
        orientations,
        pageKey,
        onResult: (value) => result = value,
        textScale: 1.6,
      );
      final controller = pageKey.currentState!.controller;
      _appendClosedBlock(
        controller,
        left: 0,
        top: 0,
        right: 192,
        bottom: 192,
        displayName: 'A Blok',
      );
      await tester.pump();

      expect(fake.saveCalls, isEmpty);
      expect(controller.saveStatus, InventorySketchSaveStatus.saving);
      expect(controller.hasUnacknowledgedGeometry, isTrue);
      expect(controller.isFinalizeEnabled, isTrue);

      expect(
        find.byKey(const Key('inventory-editor-finalize')).hitTestable(),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('inventory-editor-finalize')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(fake.operationOrder, ['save', 'finalize']);
      expect(fake.projection!.draftRevision, isNull);
      expect(fake.projection!.activeRevision!.geometry.polylines, hasLength(1));
      expect(find.byType(InventorySketchEditorPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'edit-active appended block immediately drains and finalizes with base',
    (tester) async {
      final base = _closedBlockGeometry();
      final fake = _FakeInventoryApplication.withActive(base);
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
      final controller = pageKey.currentState!.controller;
      final appended = _appendClosedBlock(
        controller,
        left: 512,
        top: 0,
        right: 704,
        bottom: 192,
        displayName: 'Yeni Alan',
      );
      await tester.pump();

      expect(fake.saveCalls, isEmpty);
      expect(controller.isFinalizeEnabled, isTrue);
      await tester.tap(find.byKey(const Key('inventory-editor-finalize')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(fake.operationOrder, ['save', 'finalize']);
      expect(fake.projection!.draftRevision, isNull);
      expect(
        fake.projection!.activeRevision!.geometry.polylines.first,
        base.polylines.first,
      );
      expect(fake.projection!.activeRevision!.geometry.polylines, hasLength(2));
      _expectSameBlockIdentity(
        fake.finalizeCommands.single.newBlocks.single,
        appended,
        polygonIndex: 1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('finalize failure preserves draft and exposes retry feedback', (
    tester,
  ) async {
    final fake = _FakeInventoryApplication.withDraft(
      _closedBlockGeometry(),
      draftNewBlocks: _blockDrafts(),
    )..failFinalizeCount = 1;
    final orientations = _OrientationRecorder();
    final pageKey = GlobalKey<InventorySketchEditorPageState>();
    bool? result;
    await _openEditor(
      tester,
      fake,
      orientations,
      pageKey,
      onResult: (value) => result = value,
    );

    await tester.tap(find.byKey(const Key('inventory-editor-finalize')));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byType(InventorySketchEditorPage), findsOneWidget);
    expect(fake.projection!.draftRevision, isNotNull);
    expect(fake.projection!.activeRevision, isNull);
    expect(
      find.byKey(const Key('inventory-editor-finalize-failure')),
      findsOneWidget,
    );
    expect(find.textContaining('Dayanıklı taslak korundu'), findsOneWidget);
    final retry = find.byKey(const Key('inventory-editor-retry-finalize'));
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(fake.finalizeCalls, 2);
    expect(fake.projection!.draftRevision, isNull);
    expect(find.byType(InventorySketchEditorPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('page back, lifecycle and orientation boundary', () {
    testWidgets('create/recover final action is accessible publish icon', (
      tester,
    ) async {
      final fake = _FakeInventoryApplication.withDraft(_openGeometry());
      final orientations = _OrientationRecorder();
      final pageKey = GlobalKey<InventorySketchEditorPageState>();
      await _openEditor(tester, fake, orientations, pageKey);

      final finalize = find.byKey(const Key('inventory-editor-finalize'));
      expect(
        find.descendant(of: finalize, matching: find.byType(Tooltip)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Tooltip>(
              find.descendant(of: finalize, matching: find.byType(Tooltip)),
            )
            .message,
        'Krokiyi yayınla',
      );
      expect(
        find.descendant(
          of: finalize,
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
      expect(find.text('Oluştur'), findsNothing);
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
        final finalize = find.byKey(const Key('inventory-editor-finalize'));
        expect(
          tester
              .widget<Tooltip>(
                find.descendant(of: finalize, matching: find.byType(Tooltip)),
              )
              .message,
          'Krokiyi yayınla ve güncelle',
        );
        expect(find.text('Oluştur'), findsNothing);
        expect(find.text('Güncelle'), findsNothing);

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

    testWidgets(
      'edit-active base mutation rejects before autosave with explicit safe message',
      (tester) async {
        final base = _closedBlockGeometry();
        final fake = _FakeInventoryApplication.withActive(base);
        final orientations = _OrientationRecorder();
        final pageKey = GlobalKey<InventorySketchEditorPageState>();
        await _openEditor(
          tester,
          fake,
          orientations,
          pageKey,
          intent: InventorySketchLaunchIntent.editActive,
        );
        final controller = pageKey.currentState!.controller;
        controller.setMode(InventorySketchEditorMode.select);
        controller.editor = controller.editor!.withSelection(
          const InventorySketchSelection.polyline(polylineIndex: 0),
        );

        expect(controller.deleteSelection(), isFalse);
        await tester.pump(const Duration(milliseconds: 600));
        expect(fake.saveCalls, isEmpty);
        expect(controller.hasUnacknowledgedGeometry, isFalse);
        expect(controller.saveStatus, InventorySketchSaveStatus.saved);
        expect(controller.editor!.geometry.canonicalJson, base.canonicalJson);
        expect(
          controller.lastErrorCode,
          InventorySketchEditorController.lockedBaseGeometryCode,
        );
        expect(
          find.byKey(const Key('inventory-editor-locked-geometry-message')),
          findsOneWidget,
        );
        expect(
          find.textContaining('Mevcut alanın şekli henüz değiştirilemez.'),
          findsOneWidget,
        );
        expect(
          find.text('Taslak kaydedilemedi. Şematik kroki açık bırakıldı.'),
          findsNothing,
        );

        await tester.tap(
          find.byKey(const Key('inventory-editor-locked-geometry-dismiss')),
        );
        await tester.pump();
        expect(
          find.byKey(const Key('inventory-editor-locked-geometry-message')),
          findsNothing,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(fake.saveCalls, isEmpty);
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

      final originalController = pageKey.currentState!.controller;
      final draftId = originalController.draftRevisionId;

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(InventorySketchEditorPage), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.text('Kaydedilmemiş değişiklikleri bırak'), findsOneWidget);
      expect(
        orientations.calls.last,
        InventorySketchEditorPage.portraitOrientations,
      );
      expect(orientations.calls.last, [DeviceOrientation.portraitUp]);
      expect(pageKey.currentState!.controller, same(originalController));
      expect(originalController.draftRevisionId, draftId);
      expect(fake.saveCalls, hasLength(1));

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
      final originalController = pageKey.currentState!.controller;
      final draftId = originalController.draftRevisionId;

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
        InventorySketchEditorPage.portraitOrientations,
      );
      expect(orientations.calls.last, [DeviceOrientation.portraitUp]);
      expect(pageKey.currentState!.controller, same(originalController));
      expect(originalController.draftRevisionId, draftId);
      expect(fake.saveCalls, hasLength(1));
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
          InventorySketchEditorPage.portraitOrientations,
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
  double textScale = 1,
  InventorySketchLaunchIntent intent =
      InventorySketchLaunchIntent.createOrRecover,
  ValueChanged<bool?>? onResult,
  String Function()? idFactory,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
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
                          idFactory: idFactory ?? _SequentialIds(5000).call,
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

InventoryBlockDraft _appendClosedBlock(
  InventorySketchEditorController controller, {
  required int left,
  required int top,
  required int right,
  required int bottom,
  required String displayName,
}) {
  for (final point in [
    _point(left, top),
    _point(right, top),
    _point(right, bottom),
    _point(left, bottom),
  ]) {
    expect(controller.drawPoint(point), isTrue);
  }
  final block = controller.createBlockDraft(
    displayName: displayName,
    floorCount: 1,
  );
  expect(controller.closeWorkingBlock(block), isTrue);
  return block;
}

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

InventoryGeometry _draftWithWorkingSecondBlock(InventorySketchPoint start) =>
    InventoryGeometry(
      polylines: [
        InventoryPolyline(
          closed: true,
          points: [
            _point(0, 0),
            _point(192, 0),
            _point(192, 192),
            _point(0, 192),
          ],
        ),
        InventoryPolyline(closed: false, points: [start]),
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

InventoryBlockRecord _blockRecord({
  required String id,
  String displayName = 'A Blok',
  String normalizedName = 'a blok',
  int ordinal = 1,
  InventoryBlockState state = InventoryBlockState.active,
  int revision = 1,
}) => InventoryBlockRecord(
  id: id,
  projectId: _projectId,
  displayName: displayName,
  normalizedName: normalizedName,
  ordinal: ordinal,
  state: state,
  revision: revision,
  createdAt: _time,
  updatedAt: _time,
  archivedAt: null,
);

InventoryFloorRecord _floorRecord({
  required String id,
  required String blockId,
  String displayName = '1. Kat',
  int ordinal = 1,
  int revision = 1,
}) => InventoryFloorRecord(
  id: id,
  blockId: blockId,
  projectId: _projectId,
  displayName: displayName,
  ordinal: ordinal,
  revision: revision,
  createdAt: _time,
  updatedAt: _time,
  archivedAt: null,
);

InventoryRevisionBlockPolygonRecord _blockPolygon({
  required String revisionId,
  required String blockId,
  required int polygonIndex,
}) => InventoryRevisionBlockPolygonRecord(
  revisionId: revisionId,
  blockId: blockId,
  projectId: _projectId,
  sketchId: _sketchId,
  polygonIndex: polygonIndex,
  createdAt: _time,
);

InventoryGeometry _rectangleGeometry({
  int left = 64,
  int top = 64,
  int right = 256,
  int bottom = 256,
}) => InventoryGeometry(
  polylines: [
    InventoryPolyline(
      closed: true,
      points: [
        _point(left, top),
        _point(right, top),
        _point(right, bottom),
        _point(left, bottom),
      ],
    ),
  ],
);

InventoryGeometry _edgeSelfIntersectionGeometry() => InventoryGeometry(
  polylines: [
    InventoryPolyline(
      closed: true,
      points: [
        _point(0, 0),
        _point(256, 0),
        _point(256, 256),
        _point(192, 256),
        _point(192, 64),
        _point(64, 64),
        _point(64, 256),
        _point(0, 256),
      ],
    ),
  ],
);

void _expectSameBlockIdentity(
  InventoryBlockDraft actual,
  InventoryBlockDraft expected, {
  required int polygonIndex,
}) {
  expect(actual.id, expected.id);
  expect(actual.displayName, expected.displayName);
  expect(actual.polygonIndex, polygonIndex);
  expect(
    actual.floors.map((floor) => floor.id),
    expected.floors.map((floor) => floor.id),
  );
  expect(
    actual.floors.map((floor) => floor.displayName),
    expected.floors.map((floor) => floor.displayName),
  );
  expect(
    actual.floors.map((floor) => floor.ordinal),
    expected.floors.map((floor) => floor.ordinal),
  );
}

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

  factory _FakeInventoryApplication.withMappedActive({
    required InventoryGeometry geometry,
    required List<InventoryBlockRecord> blocks,
    required List<InventoryFloorRecord> floors,
    required List<InventoryRevisionBlockPolygonRecord> activeBlockPolygons,
  }) => _FakeInventoryApplication._(
    _projection(
      sketchRevision: 3,
      active: _revision(
        id: _activeId,
        state: InventorySketchRevisionState.active,
        geometry: geometry,
        contentRevision: 2,
      ),
      blocks: blocks,
      floors: floors,
      activeBlockPolygons: activeBlockPolygons,
    ),
  );

  factory _FakeInventoryApplication.withSpatialEditDraft({
    required InventoryGeometry activeGeometry,
    required InventoryGeometry draftGeometry,
    List<InventoryBlockRecord> blocks = const [],
    List<InventoryFloorRecord> floors = const [],
    List<InventoryRevisionBlockPolygonRecord> activeBlockPolygons = const [],
    List<InventoryRevisionBlockPolygonRecord> draftBlockPolygons = const [],
  }) => _FakeInventoryApplication._(
    _projection(
      sketchRevision: 4,
      active: _revision(
        id: _activeId,
        state: InventorySketchRevisionState.active,
        geometry: activeGeometry,
        contentRevision: 2,
      ),
      draft: _revision(
        id: _draftId,
        state: InventorySketchRevisionState.draft,
        geometry: draftGeometry,
        contentRevision: 1,
        baseRevisionId: _activeId,
      ),
      blocks: blocks,
      floors: floors,
      activeBlockPolygons: activeBlockPolygons,
      draftBlockPolygons: draftBlockPolygons,
    ),
  );

  InventoryPrimarySketchProjection? projection;
  int createCalls = 0;
  int editCalls = 0;
  int finalizeCalls = 0;
  int abandonCalls = 0;
  int failSaveCount = 0;
  String saveFailureCode = 'inventory_persistence_failed';
  int failFinalizeCount = 0;
  int failLoadCount = 0;
  int saveMutationCount = 0;
  int replacementDraftCount = 0;
  int concurrentSaves = 0;
  int maximumConcurrentSaves = 0;
  final saveCalls = <AutosaveInventorySketchDraftCommand>[];
  final finalizeCommands = <FinalizeInventorySketchCommand>[];
  final assetProjections = <InventoryAssetProjection>[];
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
      blocks: current.blocks,
      floors: current.floors,
      activeBlockPolygons: current.activeBlockPolygons,
      draftBlockPolygons: [
        for (final mapping in current.activeBlockPolygons)
          _blockPolygon(
            revisionId: draft.id,
            blockId: mapping.blockId,
            polygonIndex: mapping.polygonIndex,
          ),
      ],
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
        throw InventoryFailure(saveFailureCode);
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
      final requestedMappings =
          command.existingBlockMappings ??
          [
            for (final mapping in current.draftBlockPolygons)
              InventoryExistingBlockMappingDraft(
                blockId: mapping.blockId,
                polygonIndex: mapping.polygonIndex,
              ),
          ];
      final mappingsChanged = !_sameExistingBlockMappings(
        current.draftBlockPolygons,
        requestedMappings,
      );
      final changed =
          draft.geometry.canonicalJson != command.geometry.canonicalJson ||
          mappingsChanged ||
          !_sameBlockDrafts(current.draftNewBlocks, command.newBlocks);
      final nextSketchRevision = current.sketch.revision + (changed ? 1 : 0);
      final nextDraftId = mappingsChanged
          ? _uuid(900000 + replacementDraftCount++)
          : draft.id;
      final nextContentRevision = mappingsChanged
          ? 1
          : draft.contentRevision + (changed ? 1 : 0);
      final nextDraft = _revision(
        id: nextDraftId,
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
        blocks: current.blocks,
        floors: current.floors,
        activeBlockPolygons: current.activeBlockPolygons,
        draftBlockPolygons: [
          for (final mapping in requestedMappings)
            _blockPolygon(
              revisionId: nextDraftId,
              blockId: mapping.blockId,
              polygonIndex: mapping.polygonIndex,
            ),
        ],
        draftNewBlocks: command.newBlocks,
        draftLegacyPolygonCount: current.draftLegacyPolygonCount,
      );
      if (changed) saveMutationCount += 1;
      final result = _result(
        command: InventoryCommandType.sketchDraftAutosave,
        operationId: command.operationId,
        sourceId: current.sketch.id,
        sourceRevision: nextSketchRevision,
        supportingId: nextDraftId,
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
    finalizeCommands.add(command);
    operationOrder.add('finalize');
    if (failFinalizeCount > 0) {
      failFinalizeCount -= 1;
      throw const InventoryFailure('inventory_persistence_failed');
    }
    final current = projection!;
    final draft = current.draftRevision!;
    final intents = command.existingBlockIntents;
    final allowEmpty =
        intents != null &&
        intents.isNotEmpty &&
        intents.every(
          (intent) =>
              intent.action == InventoryExistingBlockAction.detach ||
              intent.action == InventoryExistingBlockAction.archive,
        );
    draft.geometry.validateFinalizable(allowEmpty: allowEmpty);
    if (!_sameBlockDrafts(current.draftNewBlocks, command.newBlocks)) {
      throw const InventoryFailure('inventory_block_metadata_mismatch');
    }
    if (intents != null) {
      final mappedByBlock = {
        for (final mapping in current.draftBlockPolygons)
          mapping.blockId: mapping.polygonIndex,
      };
      for (final intent in intents) {
        final target = mappedByBlock[intent.blockId];
        if (intent.action == InventoryExistingBlockAction.retainMapped ||
            intent.action == InventoryExistingBlockAction.reattach) {
          if (target == null || target != intent.targetPolygonIndex) {
            throw const InventoryFailure('inventory_spatial_draft_mismatch');
          }
        } else if (target != null) {
          throw const InventoryFailure('inventory_spatial_draft_mismatch');
        }
      }
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
      blocks: current.blocks,
      floors: current.floors,
      activeBlockPolygons: [
        for (final mapping in current.draftBlockPolygons)
          _blockPolygon(
            revisionId: draft.id,
            blockId: mapping.blockId,
            polygonIndex: mapping.polygonIndex,
          ),
      ],
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
  Future<List<InventoryAssetProjection>> listAssets({
    required String projectId,
    bool includeArchived = false,
  }) async => List<InventoryAssetProjection>.unmodifiable(
    assetProjections.where(
      (projection) =>
          projection.asset.projectId == projectId &&
          (includeArchived || projection.asset.archivedAt == null),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

InventoryPrimarySketchProjection _projection({
  String sketchId = _sketchId,
  required int sketchRevision,
  InventorySketchRevisionRecord? active,
  InventorySketchRevisionRecord? draft,
  List<InventoryBlockRecord> blocks = const [],
  List<InventoryFloorRecord> floors = const [],
  List<InventoryRevisionBlockPolygonRecord> activeBlockPolygons = const [],
  List<InventoryRevisionBlockPolygonRecord> draftBlockPolygons = const [],
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
  blocks: blocks,
  floors: floors,
  activeBlockPolygons: activeBlockPolygons,
  draftBlockPolygons: draftBlockPolygons,
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

bool _sameExistingBlockMappings(
  List<InventoryRevisionBlockPolygonRecord> records,
  List<InventoryExistingBlockMappingDraft> drafts,
) {
  if (records.length != drafts.length) return false;
  final recordIndexes = <String, int>{};
  for (final record in records) {
    if (recordIndexes.containsKey(record.blockId)) return false;
    recordIndexes[record.blockId] = record.polygonIndex;
  }
  for (final draft in drafts) {
    if (recordIndexes[draft.blockId] != draft.polygonIndex) return false;
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
