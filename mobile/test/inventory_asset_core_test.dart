import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/inventory/inventory_asset_detail_sheet.dart';
import 'package:chief_site_engineer/features/inventory/inventory_asset_quick_form.dart';
import 'package:chief_site_engineer/features/inventory/inventory_map_view.dart';
import 'package:chief_site_engineer/features/inventory/inventory_sketch_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _otherProjectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _assetId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _sketchId = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const _activeRevisionId = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';
const _placementId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1';
const _placementKey = 'ffffffff-ffff-4fff-8fff-fffffffffff1';
const _floorId = '99999999-9999-4999-8999-999999999991';
const _blockId = '88888888-8888-4888-8888-888888888881';
final _t0 = DateTime.parse('2026-08-28T06:00:00Z');
final _pixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8'
  '/x8AAusB9Wl2nWQAAAAASUVORK5CYII=',
);

void main() {
  test('01 inverse transform captures placement on step 4', () {
    final viewport = InventoryViewport.fit(
      const Size(800, 600),
    ).zoomAt(2, const Offset(400, 300)).panBy(const Offset(21, -17));
    final point =
        viewport.origin +
        Offset(100.9 * viewport.scale, 204.8 * viewport.scale);

    expect(
      captureInventoryPlacementTarget(point, viewport),
      const InventoryPlacementTarget(x: 100, y: 204),
    );
  });

  test('02 exact half ties snap to the lower placement coordinate', () {
    final viewport = InventoryViewport.fit(const Size(4096, 3072));
    final point = viewport.origin + const Offset(102, 206);

    expect(
      captureInventoryPlacementTarget(point, viewport),
      const InventoryPlacementTarget(x: 100, y: 204),
    );
  });

  test('03 inclusive canvas edges remain valid placement coordinates', () {
    final viewport = InventoryViewport.fit(const Size(4096, 3072));

    expect(
      captureInventoryPlacementTarget(viewport.origin, viewport),
      const InventoryPlacementTarget(x: 0, y: 0),
    );
    expect(
      captureInventoryPlacementTarget(
        viewport.origin +
            const Offset(
              1.0 * InventoryGeometryContract.canvasWidth,
              1.0 * InventoryGeometryContract.canvasHeight,
            ),
        viewport,
      ),
      const InventoryPlacementTarget(
        x: InventoryGeometryContract.canvasWidth,
        y: InventoryGeometryContract.canvasHeight,
      ),
    );
  });

  test('04 out-of-bounds map input is rejected without clamping', () {
    final viewport = InventoryViewport.fit(const Size(4096, 3072));

    expect(
      captureInventoryPlacementTarget(
        viewport.origin - const Offset(0.01, 0),
        viewport,
      ),
      isNull,
    );
    expect(
      captureInventoryPlacementTarget(
        viewport.origin +
            const Offset(
              InventoryGeometryContract.canvasWidth + 0.01,
              1.0 * InventoryGeometryContract.canvasHeight,
            ),
        viewport,
      ),
      isNull,
    );
  });

  test(
    'AT-531-008 safe interior sequence is strict deterministic and compact',
    () {
      final rectangle = InventoryPolyline(
        closed: true,
        points: [
          InventorySketchPoint(x: 0, y: 0),
          InventorySketchPoint(x: 128, y: 0),
          InventorySketchPoint(x: 128, y: 128),
          InventorySketchPoint(x: 0, y: 128),
        ],
      );

      List<InventoryPlacementCoordinates> sequence() {
        final result = <InventoryPlacementCoordinates>[];
        for (var index = 0; index < 8; index += 1) {
          result.add(
            InventorySpatialContract.safeInteriorPlacement(
              rectangle,
              spreadIndex: result.length,
              occupied: result,
            ),
          );
        }
        return result;
      }

      final first = sequence();
      final second = sequence();
      expect(second, first);
      expect(first.toSet(), hasLength(first.length));
      for (final target in first) {
        expect(target.x % InventoryGeometryContract.placementStep, 0);
        expect(target.y % InventoryGeometryContract.placementStep, 0);
        expect(
          InventorySpatialContract.strictlyContainsPlacement(
            rectangle,
            x: target.x,
            y: target.y,
          ),
          isTrue,
        );
        expect((target.x - 64).abs(), lessThanOrEqualTo(8));
        expect((target.y - 64).abs(), lessThanOrEqualTo(8));
      }
      final wrapPolygon = InventoryPolyline(
        closed: true,
        points: [
          InventorySketchPoint(x: 0, y: 0),
          InventorySketchPoint(x: 64, y: 0),
          InventorySketchPoint(x: 64, y: 64),
          InventorySketchPoint(x: 0, y: 64),
        ],
      );
      final wrapFirst = InventorySpatialContract.safeInteriorPlacement(
        wrapPolygon,
        spreadIndex: 0,
      );
      final allOtherWrapTargets = [
        for (
          var x = InventoryGeometryContract.placementStep;
          x < 64;
          x += InventoryGeometryContract.placementStep
        )
          for (
            var y = InventoryGeometryContract.placementStep;
            y < 64;
            y += InventoryGeometryContract.placementStep
          )
            if (x != wrapFirst.x || y != wrapFirst.y)
              InventoryPlacementCoordinates(x: x, y: y),
      ];
      expect(
        InventorySpatialContract.safeInteriorPlacement(
          wrapPolygon,
          spreadIndex: 2,
          occupied: allOtherWrapTargets,
        ),
        wrapFirst,
      );
      expect(
        InventorySpatialContract.containsPlacement(rectangle, x: 0, y: 64),
        isTrue,
      );
      expect(
        InventorySpatialContract.strictlyContainsPlacement(
          rectangle,
          x: 0,
          y: 64,
        ),
        isFalse,
      );

      final concave = InventoryPolyline(
        closed: true,
        points: [
          InventorySketchPoint(x: 0, y: 0),
          InventorySketchPoint(x: 192, y: 0),
          InventorySketchPoint(x: 192, y: 64),
          InventorySketchPoint(x: 64, y: 64),
          InventorySketchPoint(x: 64, y: 192),
          InventorySketchPoint(x: 0, y: 192),
        ],
      );
      final concaveTarget = InventorySpatialContract.safeInteriorPlacement(
        concave,
        spreadIndex: 0,
      );
      expect(
        InventorySpatialContract.strictlyContainsPlacement(
          concave,
          x: concaveTarget.x,
          y: concaveTarget.y,
        ),
        isTrue,
      );
    },
  );

  testWidgets('05 marker tap opens detail and never starts create', (
    tester,
  ) async {
    final fake = _FakeInventoryApplication.standard();
    final controller = InventoryMapController(
      application: fake,
      projectId: _projectId,
    );
    addTearDown(controller.dispose);
    expect(await controller.reload(), isTrue);
    final opened = <String>[];
    final creates = <InventoryPlacementTarget>[];

    await _pumpMap(
      tester,
      controller,
      onOpenAsset: opened.add,
      onCreateTarget: creates.add,
    );
    await tester.tap(find.byKey(const Key('inventory-marker-$_assetId')));
    await tester.pump();

    expect(opened, [_assetId]);
    expect(creates, isEmpty);
    expect(controller.pendingCreateTarget, isNull);
  });

  test(
    '06 quick create requires name, category, quantity, and valid target',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final controller = _quickController(fake);

      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 100, y: 100),
          displayName: ' ',
          category: InventoryCategory.equipment,
          quantityText: '1',
        ),
        isFalse,
      );
      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 100, y: 100),
          displayName: 'Vinç',
          category: null,
          quantityText: '1',
        ),
        isFalse,
      );
      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 100, y: 100),
          displayName: 'Vinç',
          category: InventoryCategory.equipment,
          quantityText: '0',
        ),
        isFalse,
      );
      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 101, y: 100),
          displayName: 'Vinç',
          category: InventoryCategory.equipment,
          quantityText: '1',
        ),
        isFalse,
      );
      expect(fake.createCalls, 0);
    },
  );

  test(
    '07 OTHER requires its label and non-OTHER clears stale label',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final controller = _quickController(fake);

      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 100, y: 100),
          displayName: 'Özel araç',
          category: InventoryCategory.other,
          quantityText: '1',
          otherCategoryLabel: ' ',
        ),
        isFalse,
      );
      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 100, y: 100),
          displayName: 'El arabası',
          category: InventoryCategory.handTool,
          quantityText: '1',
          otherCategoryLabel: 'Bayat değer',
        ),
        isTrue,
      );
      expect(fake.lastCreate!.otherCategoryLabel, isNull);
    },
  );

  test('08 quick create defaults status to AVAILABLE', () async {
    final fake = _FakeInventoryApplication.standard();

    expect(
      await _quickController(fake).submit(
        target: const InventoryPlacementTarget(x: 100, y: 100),
        displayName: 'Jeneratör',
        category: InventoryCategory.equipment,
        quantityText: '2',
      ),
      isTrue,
    );
    expect(fake.lastCreate!.status, InventoryAssetStatus.available);
  });

  test(
    '09 quick create injects exact ids and current sketch revision',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final controller = _quickController(fake, ids: _SequentialIds(1000));

      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 124, y: 208),
          displayName: ' Jeneratör ',
          category: InventoryCategory.equipment,
          quantityText: '3',
        ),
        isTrue,
      );
      final command = fake.lastCreate!;
      expect(command.operationId, _uuid(1000));
      expect(command.assetId, _uuid(1001));
      expect(command.placementId, _uuid(1002));
      expect(command.placementKey, _uuid(1003));
      expect(command.projectId, _projectId);
      expect(command.sketchId, _sketchId);
      expect(command.activeRevisionId, _activeRevisionId);
      expect(command.x, 124);
      expect(command.y, 208);
      expect(command.totalQuantity, 3);
      expect(command.floorId, isNull);
    },
  );

  test(
    'AT-531-007 exact floor quick-create intent is forwarded unchanged',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final controller = _quickController(
        fake,
        ids: _SequentialIds(1050),
        floorId: _floorId,
      );

      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 124, y: 208),
          displayName: 'Kat aracı',
          category: InventoryCategory.equipment,
          quantityText: '1',
        ),
        isTrue,
      );
      expect(fake.lastCreate!.floorId, _floorId);
      expect(fake.projections[_uuid(1051)]!.activePlacement!.floorId, _floorId);
    },
  );

  test('10 successful create reloads the canonical map projection', () async {
    final fake = _FakeInventoryApplication.standard();
    var reloads = 0;
    final controller = InventoryAssetQuickCreateController(
      application: fake,
      projectId: _projectId,
      reloadCanonical: () async {
        reloads += 1;
      },
      idFactory: _SequentialIds(1100).call,
    );

    expect(
      await controller.submit(
        target: const InventoryPlacementTarget(x: 100, y: 100),
        displayName: 'Yeni varlık',
        category: InventoryCategory.handTool,
        quantityText: '1',
      ),
      isTrue,
    );
    expect(reloads, 1);
    expect(controller.lastCreatedAssetId, _uuid(1101));
    expect(fake.projections, contains(_uuid(1101)));
  });

  test(
    '11 create failure exposes no fake success or canonical mutation',
    () async {
      final fake = _FakeInventoryApplication.standard()
        ..nextFailure = const InventoryFailure('inventory_persistence_failed');
      var reloads = 0;
      final controller = InventoryAssetQuickCreateController(
        application: fake,
        projectId: _projectId,
        reloadCanonical: () async {
          reloads += 1;
        },
        idFactory: _SequentialIds(1200).call,
      );
      final before = Map<String, InventoryAssetProjection>.of(fake.projections);

      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 100, y: 100),
          displayName: 'Başarısız',
          category: InventoryCategory.handTool,
          quantityText: '1',
        ),
        isFalse,
      );
      expect(controller.status, InventoryQuickCreateStatus.failed);
      expect(controller.lastCreatedAssetId, isNull);
      expect(controller.lastErrorCode, 'inventory_persistence_failed');
      expect(fake.createCalls, 1);
      expect(reloads, 0);
      expect(fake.projections, before);
    },
  );

  test(
    '11a committed create retries canonical refresh without duplicate mutation',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final generatedIds = <String>[];
      var nextIdValue = 1250;
      String nextId() {
        final id = _uuid(nextIdValue++);
        generatedIds.add(id);
        return id;
      }

      var reloads = 0;
      final controller = InventoryAssetQuickCreateController(
        application: fake,
        projectId: _projectId,
        reloadCanonical: () async {
          reloads += 1;
          if (reloads == 1) {
            throw const InventoryFailure('inventory_canonical_reload_failed');
          }
        },
        idFactory: nextId,
      );

      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 100, y: 100),
          displayName: 'Committed varlık',
          category: InventoryCategory.handTool,
          quantityText: '1',
        ),
        isFalse,
      );
      final committedCommand = fake.lastCreate!;
      expect(fake.createCalls, 1);
      expect(reloads, 1);
      expect(
        controller.status,
        InventoryQuickCreateStatus.committedRefreshFailed,
      );
      expect(controller.hasCommittedAssetAwaitingRefresh, isTrue);
      expect(controller.lastCreatedAssetId, committedCommand.assetId);
      expect(controller.lastErrorCode, 'inventory_canonical_reload_failed');
      expect(fake.projections, contains(committedCommand.assetId));
      expect(generatedIds, [
        _uuid(1250),
        _uuid(1251),
        _uuid(1252),
        _uuid(1253),
      ]);

      expect(
        await controller.submit(
          target: const InventoryPlacementTarget(x: 200, y: 200),
          displayName: 'Farklı yeni intent',
          category: InventoryCategory.equipment,
          quantityText: '2',
        ),
        isFalse,
      );
      expect(fake.createCalls, 1);
      expect(reloads, 1);
      expect(fake.lastCreate, same(committedCommand));
      expect(generatedIds, hasLength(4));

      expect(await controller.retryCommittedRefresh(), isTrue);
      expect(fake.createCalls, 1);
      expect(reloads, 2);
      expect(controller.status, InventoryQuickCreateStatus.succeeded);
      expect(controller.hasCommittedAssetAwaitingRefresh, isFalse);
      expect(controller.lastCreatedAssetId, committedCommand.assetId);
      expect(controller.lastErrorCode, isNull);
      expect(fake.lastCreate, same(committedCommand));
      expect(generatedIds, hasLength(4));
    },
  );

  testWidgets(
    '12 markers expose name quantity and non-color status semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final fake = _FakeInventoryApplication.standard();
        final controller = InventoryMapController(
          application: fake,
          projectId: _projectId,
        );
        addTearDown(controller.dispose);
        expect(await controller.reload(), isTrue);

        await _pumpMap(tester, controller);

        expect(
          find.bySemanticsLabel('Kule vinç, 2 adet, Mevcut'),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('13 marker hit target is at least 48 by 48 logical pixels', (
    tester,
  ) async {
    final fake = _FakeInventoryApplication.standard();
    final controller = InventoryMapController(
      application: fake,
      projectId: _projectId,
    );
    addTearDown(controller.dispose);
    expect(await controller.reload(), isTrue);

    await _pumpMap(tester, controller);

    expect(
      tester.getSize(find.byKey(const Key('inventory-marker-$_assetId'))),
      const Size(48, 48),
    );
  });

  testWidgets('14 each marker opens its exact project asset identity', (
    tester,
  ) async {
    final fake = _FakeInventoryApplication.standard()
      ..addAsset(assetId: _uuid(1300), x: 800, y: 800);
    final controller = InventoryMapController(
      application: fake,
      projectId: _projectId,
    );
    addTearDown(controller.dispose);
    expect(await controller.reload(), isTrue);
    final opened = <String>[];

    await _pumpMap(tester, controller, onOpenAsset: opened.add);
    await tester.tap(find.byKey(Key('inventory-marker-${_uuid(1300)}')));
    await tester.pump();

    expect(opened, [_uuid(1300)]);
  });

  test('14a overlap groups are deterministic and dissolve at higher zoom', () {
    final first = _projection(
      assetId: _uuid(1310),
      displayName: 'Beta',
      x: 20,
      y: 20,
    );
    final second = _projection(
      assetId: _uuid(1311),
      displayName: 'Alfa',
      x: 120,
      y: 120,
    );
    final third = _projection(
      assetId: _uuid(1312),
      displayName: 'Alfa',
      x: 220,
      y: 220,
    );
    final fitted = InventoryViewport.fit(const Size(800, 600));
    final grouped = buildInventoryMarkerGroups([first, third, second], fitted);

    expect(grouped, hasLength(1));
    expect(grouped.single.isCluster, isTrue);
    expect(grouped.single.projections.map((item) => item.asset.id), [
      _uuid(1311),
      _uuid(1312),
      _uuid(1310),
    ]);
    final zoomed = fitted.zoomAt(4, const Offset(400, 300));
    expect(
      buildInventoryMarkerGroups([first, second, third], zoomed).length,
      greaterThan(1),
    );
    expect(
      buildInventoryMarkerGroups([second], fitted).single.isCluster,
      isFalse,
    );
    final boundaryLeft = _projection(
      assetId: _uuid(1313),
      displayName: 'Sinir A',
      x: 245,
      y: 100,
    );
    final boundaryRight = _projection(
      assetId: _uuid(1314),
      displayName: 'Sinir B',
      x: 251,
      y: 100,
    );
    final acrossBoundary = buildInventoryMarkerGroups([
      boundaryLeft,
      boundaryRight,
    ], fitted);
    expect(acrossBoundary, hasLength(1));
    expect(acrossBoundary.single.isCluster, isTrue);
  });

  testWidgets(
    '14b cluster chooser has exact identities and target mode bypasses it',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final fake = _FakeInventoryApplication.standard()
          ..addAsset(assetId: _uuid(1320), x: 220, y: 220)
          ..addAsset(assetId: _uuid(1321), x: 240, y: 240);
        final controller = InventoryMapController(
          application: fake,
          projectId: _projectId,
        );
        addTearDown(controller.dispose);
        expect(await controller.reload(), isTrue);
        final opened = <String>[];

        await _pumpMap(tester, controller, onOpenAsset: opened.add);
        final mapState = tester.state<InventoryMapViewState>(
          find.byType(InventoryMapView),
        );
        var cluster = find.bySemanticsLabel('3 envanter kaydı içeren küme');
        expect(cluster, findsOneWidget);
        expect(tester.getSize(cluster), const Size(48, 48));
        final initialViewport = mapState.viewport!;
        await tester.tap(cluster);
        await tester.pump();
        final zoomedViewport = mapState.viewport!;
        expect(zoomedViewport.zoom, initialViewport.zoom * 1.25);
        expect(
          find.byKey(const Key('inventory-cluster-chooser')),
          findsNothing,
        );
        final centeredGroup = buildInventoryMarkerGroups(
          controller.projections,
          zoomedViewport,
        ).singleWhere((group) => group.projections.length == 3);
        expect(
          centeredGroup.center.dx,
          closeTo(zoomedViewport.viewSize.width / 2, 0.01),
        );
        expect(
          centeredGroup.center.dy,
          closeTo(zoomedViewport.viewSize.height / 2, 0.01),
        );

        while (mapState.viewport!.zoom < InventoryViewport.maximumZoom) {
          mapState.zoomIn();
          await tester.pump();
        }
        expect(mapState.viewport!.zoom, InventoryViewport.maximumZoom);
        cluster = find.bySemanticsLabel('3 envanter kaydı içeren küme');
        expect(cluster, findsOneWidget);
        await tester.tap(cluster);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('inventory-cluster-chooser')),
          findsOneWidget,
        );
        for (final assetId in [_assetId, _uuid(1320), _uuid(1321)]) {
          expect(
            find.byKey(Key('inventory-cluster-item-$assetId')),
            findsOneWidget,
          );
        }
        await tester.tap(
          find.byKey(Key('inventory-cluster-item-${_uuid(1321)}')),
        );
        await tester.pumpAndSettle();
        expect(opened, [_uuid(1321)]);

        final selectedTargets = <InventoryPlacementTarget>[];
        final quickCreates = <InventoryPlacementTarget>[];
        await _pumpMap(
          tester,
          controller,
          onOpenAsset: opened.add,
          onCreateTarget: quickCreates.add,
          onSelectTarget: selectedTargets.add,
        );
        await tester.tap(find.bySemanticsLabel('3 envanter kaydı içeren küme'));
        await tester.pump();
        expect(
          find.byKey(const Key('inventory-cluster-chooser')),
          findsNothing,
        );
        expect(selectedTargets, hasLength(1));
        expect(quickCreates, isEmpty);
        expect(opened, [_uuid(1321)]);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    '14c clustered list focus centers exact placement with a two-second cue',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final focusedAssetId = _uuid(1321);
        final fake = _FakeInventoryApplication.standard()
          ..addAsset(assetId: _uuid(1320), x: 220, y: 220)
          ..addAsset(assetId: focusedAssetId, x: 240, y: 240);
        final controller = InventoryMapController(
          application: fake,
          projectId: _projectId,
        );
        addTearDown(controller.dispose);
        expect(await controller.reload(), isTrue);

        await _pumpMap(tester, controller);
        final mapState = tester.state<InventoryMapViewState>(
          find.byType(InventoryMapView),
        );
        expect(mapState.focusAsset(focusedAssetId), isTrue);
        await tester.pump();

        final cue = find.byKey(Key('inventory-cluster-focus-$focusedAssetId'));
        expect(cue, findsOneWidget);
        expect(
          find.bySemanticsLabel('Ek varlık, kesin konumda odaklandı'),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cue,
            matching: find.byIcon(Icons.center_focus_strong),
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('3 envanter kaydı içeren küme'),
          findsOneWidget,
        );
        final viewport = mapState.viewport!;
        final projection = controller.projections.firstWhere(
          (item) => item.asset.id == focusedAssetId,
        );
        final placement = projection.activePlacement!;
        final exactCenter =
            viewport.origin +
            Offset(placement.x * viewport.scale, placement.y * viewport.scale);
        final cueCenter = tester.getCenter(cue);
        final viewCenter = viewport.viewSize.center(Offset.zero);
        expect(cueCenter.dx, closeTo(exactCenter.dx, 0.01));
        expect(cueCenter.dy, closeTo(exactCenter.dy, 0.01));
        expect(exactCenter.dx, closeTo(viewCenter.dx, 0.01));
        expect(exactCenter.dy, closeTo(viewCenter.dy, 0.01));

        await tester.pump(const Duration(milliseconds: 1999));
        expect(cue, findsOneWidget);
        await tester.pump(const Duration(milliseconds: 2));
        expect(cue, findsNothing);
        expect(mapState.highlightedAssetId, isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  test('15 archived assets are absent from canonical map markers', () async {
    final fake = _FakeInventoryApplication.standard(archived: true);
    final controller = InventoryMapController(
      application: fake,
      projectId: _projectId,
    );
    addTearDown(controller.dispose);

    expect(await controller.reload(), isTrue);
    expect(controller.projections, isEmpty);
    expect(fake.lastIncludeArchived, isFalse);
  });

  test(
    '16 multiple placement projections fail closed with typed reason',
    () async {
      final fake = _FakeInventoryApplication.standard()
        ..duplicateAssetInList = true;
      final controller = InventoryMapController(
        application: fake,
        projectId: _projectId,
      );
      addTearDown(controller.dispose);

      expect(await controller.reload(), isFalse);
      expect(
        controller.lastErrorCode,
        'inventory_multiple_placements_not_supported_in_v1',
      );
      expect(controller.projections, isEmpty);
    },
  );

  test(
    '17 metadata no-op stays stable and real update advances revision',
    () async {
      final fake = _FakeInventoryApplication.standard();
      var mapReloads = 0;
      final controller = await _loadedDetail(
        fake,
        mapReload: () async {
          mapReloads += 1;
        },
        ids: _SequentialIds(1400),
      );
      addTearDown(controller.dispose);

      expect(
        await controller.updateMetadata(
          displayName: 'Kule vinç',
          category: InventoryCategory.equipment,
        ),
        isTrue,
      );
      expect(controller.asset!.revision, 1);
      expect(fake.lastUpdate!.expectedAssetRevision, 1);
      expect(
        await controller.updateMetadata(
          displayName: 'Kule vinç A',
          category: InventoryCategory.equipment,
          note: 'Kuzey cephe',
        ),
        isTrue,
      );
      expect(controller.asset!.revision, 2);
      expect(controller.asset!.displayName, 'Kule vinç A');
      expect(controller.asset!.note, 'Kuzey cephe');
      expect(mapReloads, 2);
    },
  );

  test(
    '18 status no-op stays stable and real change advances revision',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final controller = await _loadedDetail(fake, ids: _SequentialIds(1500));
      addTearDown(controller.dispose);

      expect(
        await controller.changeStatus(InventoryAssetStatus.available),
        isTrue,
      );
      expect(controller.asset!.revision, 1);
      expect(await controller.changeStatus(InventoryAssetStatus.inUse), isTrue);
      expect(controller.asset!.revision, 2);
      expect(controller.asset!.status, InventoryAssetStatus.inUse);
      expect(fake.lastStatus!.expectedAssetRevision, 1);
    },
  );

  test(
    '19 quantity command carries asset revision and placement sequence',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final controller = await _loadedDetail(fake, ids: _SequentialIds(1600));
      addTearDown(controller.dispose);

      expect(await controller.changeQuantity(5), isTrue);
      final command = fake.lastQuantity!;
      expect(command.operationId, _uuid(1600));
      expect(command.successorPlacementId, _uuid(1601));
      expect(command.projectId, _projectId);
      expect(command.assetId, _assetId);
      expect(command.placementKey, _placementKey);
      expect(command.expectedAssetRevision, 1);
      expect(command.expectedPlacementSequence, 1);
      expect(command.totalQuantity, 5);
    },
  );

  test(
    '20 quantity successor preserves coordinate and placement key',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final controller = await _loadedDetail(fake, ids: _SequentialIds(1700));
      addTearDown(controller.dispose);
      final before = controller.activePlacement!;

      expect(await controller.changeQuantity(7), isTrue);
      final after = controller.activePlacement!;
      expect(after.id, _uuid(1701));
      expect(after.placementKey, before.placementKey);
      expect(after.sequence, before.sequence + 1);
      expect(after.x, before.x);
      expect(after.y, before.y);
      expect(after.quantity, 7);
      expect(controller.asset!.totalQuantity, 7);
      expect(
        controller.placementVersions.first.endReason,
        InventoryPlacementEndReason.quantityChanged,
      );
    },
  );

  testWidgets(
    '20a quantity dialog survives dismissal and reloads one successor',
    (tester) async {
      final fake = _FakeInventoryApplication.standard();
      final controller = await _loadedDetail(fake, ids: _SequentialIds(1750));
      addTearDown(controller.dispose);
      final before = controller.activePlacement!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryAssetDetailSheet(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-detail-quantity')));
      await tester.pumpAndSettle();
      expect(find.text('Adedi değiştir'), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), '7');
      await tester.tap(find.text('Kaydet'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final after = controller.activePlacement!;
      expect(find.byType(InventoryAssetDetailSheet), findsOneWidget);
      expect(find.text('7 adet'), findsOneWidget);
      expect(controller.asset!.totalQuantity, 7);
      expect(controller.asset!.revision, 2);
      expect(after.id, _uuid(1751));
      expect(after.quantity, controller.asset!.totalQuantity);
      expect(after.placementKey, before.placementKey);
      expect(after.sequence, before.sequence + 1);
      expect(after.x, before.x);
      expect(after.y, before.y);
      expect(after.supersedesPlacementId, before.id);
      expect(fake.quantityCalls, 1);
      final predecessor = controller.placementVersions.singleWhere(
        (placement) => placement.id == before.id,
      );
      expect(
        predecessor.endReason,
        InventoryPlacementEndReason.quantityChanged,
      );

      await tester.tap(find.byKey(const Key('inventory-detail-quantity')));
      await tester.pumpAndSettle();
      expect(find.text('Adedi değiştir'), findsNWidgets(2));
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('7 adet'), findsOneWidget);
      expect(fake.quantityCalls, 1);
    },
  );

  testWidgets(
    '20b metadata dialog survives dismissal, reload, reopen, and cancel',
    (tester) async {
      final fake = _FakeInventoryApplication.standard();
      final controller = await _loadedDetail(fake, ids: _SequentialIds(1775));
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryAssetDetailSheet(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-detail-edit-metadata')));
      await tester.pumpAndSettle();
      expect(find.text('Envanter bilgileri'), findsWidgets);
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).first, 'Kule vinç B');
      await tester.enterText(find.byType(TextField).last, 'Kuzey cephe');
      await tester.tap(find.text('Kaydet'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.byType(InventoryAssetDetailSheet), findsOneWidget);
      expect(controller.asset!.displayName, 'Kule vinç B');
      expect(controller.asset!.category, InventoryCategory.equipment);
      expect(controller.asset!.otherCategoryLabel, isNull);
      expect(controller.asset!.note, 'Kuzey cephe');
      expect(controller.asset!.revision, 2);
      expect(fake.projections[_assetId]!.asset.displayName, 'Kule vinç B');
      expect(fake.projections[_assetId]!.asset.note, 'Kuzey cephe');
      expect(fake.updateCalls, 1);
      expect(fake.lastUpdate!.displayName, 'Kule vinç B');
      expect(fake.lastUpdate!.category, InventoryCategory.equipment);
      expect(fake.lastUpdate!.otherCategoryLabel, isNull);
      expect(fake.lastUpdate!.note, 'Kuzey cephe');

      await tester.tap(find.byKey(const Key('inventory-detail-edit-metadata')));
      await tester.pumpAndSettle();
      expect(find.text('Envanter bilgileri'), findsWidgets);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Kule vinç B'), findsOneWidget);
      expect(find.text('Kuzey cephe'), findsOneWidget);
      expect(fake.updateCalls, 1);
    },
  );

  testWidgets(
    '20c photo add replace cancel remove and safe preview use real detail flow',
    (tester) async {
      final fake = _FakeInventoryApplication.standard();
      var mapReloads = 0;
      final photoController = InventoryAssetDetailController(
        application: fake,
        projectId: _projectId,
        assetId: _assetId,
        reloadMapCanonical: () async {
          mapReloads += 1;
        },
        idFactory: _SequentialIds(1790).call,
      );
      addTearDown(photoController.dispose);
      expect(await photoController.reload(), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryAssetDetailSheet(
              controller: photoController,
              autoLoad: false,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('inventory-photo-add')), findsOneWidget);

      fake.nextPhotoPick = InventoryPhotoPickResult(
        outcome: InventoryPhotoPickOutcome.selected,
        selection: InventoryPhotoSelection(
          originalFileName: 'library.png',
          bytes: _pixelPng,
          source: InventoryPhotoSource.photoLibrary,
        ),
      );
      await tester.tap(find.byKey(const Key('inventory-photo-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-photo-library')));
      await tester.pumpAndSettle();
      expect(fake.photoAddCalls, 1);
      expect(fake.photo?.originalFileName, 'library.png');
      expect(find.byKey(const Key('inventory-photo-preview')), findsOneWidget);
      expect(mapReloads, 1);
      expect(tester.takeException(), isNull);

      fake.nextPhotoPick = InventoryPhotoPickResult(
        outcome: InventoryPhotoPickOutcome.selected,
        selection: InventoryPhotoSelection(
          originalFileName: 'camera.png',
          bytes: _pixelPng,
          source: InventoryPhotoSource.camera,
        ),
      );
      await tester.tap(find.byKey(const Key('inventory-photo-replace')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-photo-camera')));
      await tester.pumpAndSettle();
      expect(fake.photoAddCalls, 2);
      expect(fake.photo?.originalFileName, 'camera.png');
      expect(mapReloads, 2);

      fake.nextPhotoPick = const InventoryPhotoPickResult(
        outcome: InventoryPhotoPickOutcome.cancelled,
      );
      await tester.tap(find.byKey(const Key('inventory-photo-replace')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-photo-library')));
      await tester.pumpAndSettle();
      expect(fake.photoAddCalls, 2);
      expect(fake.photo?.originalFileName, 'camera.png');
      expect(mapReloads, 2);

      await tester.tap(find.byKey(const Key('inventory-photo-remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-photo-remove-confirm')));
      await tester.pumpAndSettle();
      expect(fake.photoRemoveCalls, 1);
      expect(fake.photo, isNull);
      expect(find.byKey(const Key('inventory-photo-add')), findsOneWidget);
      expect(mapReloads, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('20d archived and corrupt photo states stay safe at large text', (
    tester,
  ) async {
    final archived = _FakeInventoryApplication.standard(archived: true)
      ..setPhoto();
    final archivedController = await _loadedDetail(
      archived,
      ids: _SequentialIds(1795),
    );
    addTearDown(archivedController.dispose);
    await _pumpDetailWithTextScale(tester, archivedController, textScale: 2.5);
    expect(find.byKey(const Key('inventory-photo-card')), findsOneWidget);
    expect(find.byKey(const Key('inventory-photo-preview')), findsOneWidget);
    expect(find.byKey(const Key('inventory-photo-replace')), findsNothing);
    expect(find.byKey(const Key('inventory-photo-remove')), findsNothing);
    expect(find.byKey(const Key('inventory-photo-add')), findsNothing);
    expect(tester.takeException(), isNull);

    final corrupt = _FakeInventoryApplication.standard()
      ..setPhoto(integrity: InventoryPhotoIntegrity.hashMismatch);
    final corruptController = await _loadedDetail(
      corrupt,
      ids: _SequentialIds(1798),
    );
    addTearDown(corruptController.dispose);
    await _pumpDetailWithTextScale(tester, corruptController, textScale: 2.5);
    expect(find.byKey(const Key('inventory-photo-failure')), findsOneWidget);
    expect(
      corruptController.photoDiagnosticCode,
      'inventory_photo_hash_mismatch',
    );
    expect(tester.takeException(), isNull);
  });

  test(
    '20e project context change during picker performs zero photo mutation',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final pending = Completer<InventoryPhotoPickResult>();
      fake.pendingPhotoPick = pending;
      var contextCurrent = true;
      final controller = InventoryAssetDetailController(
        application: fake,
        projectId: _projectId,
        assetId: _assetId,
        reloadMapCanonical: _noReload,
        isProjectContextCurrent: () => contextCurrent,
        idFactory: _SequentialIds(1799).call,
      );
      addTearDown(controller.dispose);
      expect(await controller.reload(), isTrue);

      final result = controller.addOrReplacePhoto(
        InventoryPhotoSource.photoLibrary,
      );
      await Future<void>.delayed(Duration.zero);
      expect(fake.photoPickCalls, 1);
      contextCurrent = false;
      pending.complete(
        InventoryPhotoPickResult(
          outcome: InventoryPhotoPickOutcome.selected,
          selection: InventoryPhotoSelection(
            originalFileName: 'late.png',
            bytes: _pixelPng,
            source: InventoryPhotoSource.photoLibrary,
          ),
        ),
      );

      expect(await result, isFalse);
      expect(fake.photoAddCalls, 0);
      expect(controller.lastErrorCode, 'inventory_project_context_changed');
    },
  );

  test(
    '21 stale overflow and multiple placement failures never patch state',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final controller = await _loadedDetail(fake, ids: _SequentialIds(1800));
      addTearDown(controller.dispose);
      final original = controller.activePlacement!;
      fake.nextFailure = const InventoryFailure('inventory_stale_revision');

      expect(await controller.changeQuantity(4), isFalse);
      expect(controller.activePlacement!.id, original.id);
      expect(controller.asset!.totalQuantity, 2);
      expect(controller.lastErrorCode, 'inventory_stale_revision');
      expect(await controller.changeQuantity(1000001), isFalse);
      expect(controller.activePlacement!.id, original.id);
      expect(controller.asset!.totalQuantity, 2);

      final multiple = _FakeInventoryApplication.standard()
        ..replaceProjection(_projection(quantity: 2, placementQuantity: 1));
      final multipleController = InventoryAssetDetailController(
        application: multiple,
        projectId: _projectId,
        assetId: _assetId,
        reloadMapCanonical: _noReload,
        idFactory: _SequentialIds(1810).call,
      );
      addTearDown(multipleController.dispose);
      expect(await multipleController.reload(), isFalse);
      expect(
        multipleController.lastErrorCode,
        'inventory_multiple_placements_not_supported_in_v1',
      );
      expect(multiple.quantityCalls, 0);
    },
  );

  test('22 move selection stores preview only and does not mutate', () async {
    final fake = _FakeInventoryApplication.standard();
    final controller = await _loadedDetail(fake, ids: _SequentialIds(1900));
    addTearDown(controller.dispose);
    final original = controller.activePlacement!;

    expect(controller.beginMove(), isTrue);
    expect(
      controller.previewMove(const InventoryPlacementTarget(x: 400, y: 404)),
      isTrue,
    );
    expect(
      controller.pendingMoveTarget,
      const InventoryPlacementTarget(x: 400, y: 404),
    );
    expect(controller.activePlacement!.id, original.id);
    expect(fake.moveCalls, 0);
  });

  test('23 move cancel clears preview without persistence', () async {
    final fake = _FakeInventoryApplication.standard();
    final controller = await _loadedDetail(fake, ids: _SequentialIds(2000));
    addTearDown(controller.dispose);

    expect(controller.beginMove(), isTrue);
    expect(
      controller.previewMove(const InventoryPlacementTarget(x: 400, y: 404)),
      isTrue,
    );
    controller.cancelMove();

    expect(controller.selectingMoveTarget, isFalse);
    expect(controller.pendingMoveTarget, isNull);
    expect(fake.moveCalls, 0);
  });

  test('24 same-coordinate move is a canonical no-op', () async {
    final fake = _FakeInventoryApplication.standard();
    final controller = await _loadedDetail(fake, ids: _SequentialIds(2100));
    addTearDown(controller.dispose);
    final original = controller.activePlacement!;

    expect(controller.beginMove(), isTrue);
    expect(
      controller.previewMove(
        InventoryPlacementTarget(x: original.x, y: original.y),
      ),
      isTrue,
    );
    expect(await controller.confirmMove(), isTrue);

    expect(controller.activePlacement!.id, original.id);
    expect(controller.activePlacement!.sequence, original.sequence);
    expect(fake.lastResult!.isNoOp, isTrue);
  });

  test(
    '25 move confirmation uses explicit path and current active revision',
    () async {
      final fake = _FakeInventoryApplication.standard();
      final controller = await _loadedDetail(fake, ids: _SequentialIds(2200));
      addTearDown(controller.dispose);

      expect(controller.beginMove(), isTrue);
      expect(
        controller.previewMove(const InventoryPlacementTarget(x: 500, y: 504)),
        isTrue,
      );
      expect(await controller.confirmMove(), isTrue);
      final command = fake.lastMove!;

      expect(command.operationId, _uuid(2200));
      expect(command.successorPlacementId, _uuid(2201));
      expect(command.projectId, _projectId);
      expect(command.assetId, _assetId);
      expect(command.placementKey, _placementKey);
      expect(command.sketchId, _sketchId);
      expect(command.activeRevisionId, _activeRevisionId);
      expect(command.expectedPlacementSequence, 1);
      expect(command.x, 500);
      expect(command.y, 504);
      expect(controller.selectingMoveTarget, isFalse);
    },
  );

  test('26 move creates successor with stable key and next sequence', () async {
    final fake = _FakeInventoryApplication.standard();
    final controller = await _loadedDetail(fake, ids: _SequentialIds(2300));
    addTearDown(controller.dispose);
    final original = controller.activePlacement!;

    controller.beginMove();
    controller.previewMove(const InventoryPlacementTarget(x: 600, y: 604));
    expect(await controller.confirmMove(), isTrue);
    final successor = controller.activePlacement!;

    expect(successor.id, _uuid(2301));
    expect(successor.placementKey, original.placementKey);
    expect(successor.sequence, original.sequence + 1);
    expect(successor.supersedesPlacementId, original.id);
    expect(
      controller.placementVersions.first.endReason,
      InventoryPlacementEndReason.moved,
    );
  });

  test('27 stale cross-project and invalid move paths fail safely', () async {
    final stale = _FakeInventoryApplication.standard();
    final staleController = await _loadedDetail(
      stale,
      ids: _SequentialIds(2400),
    );
    addTearDown(staleController.dispose);
    final original = staleController.activePlacement!;
    staleController.beginMove();
    staleController.previewMove(const InventoryPlacementTarget(x: 700, y: 704));
    stale.nextFailure = const InventoryFailure('inventory_stale_revision');

    expect(await staleController.confirmMove(), isFalse);
    expect(staleController.activePlacement!.id, original.id);
    expect(staleController.lastErrorCode, 'inventory_stale_revision');

    final invalid = _FakeInventoryApplication.standard();
    final invalidController = await _loadedDetail(
      invalid,
      ids: _SequentialIds(2410),
    );
    addTearDown(invalidController.dispose);
    invalidController.beginMove();
    expect(
      invalidController.previewMove(
        const InventoryPlacementTarget(x: 701, y: 704),
      ),
      isFalse,
    );
    expect(invalid.moveCalls, 0);

    final cross = _FakeInventoryApplication.standard();
    final crossController = await _loadedDetail(
      cross,
      ids: _SequentialIds(2420),
    );
    addTearDown(crossController.dispose);
    crossController.beginMove();
    crossController.previewMove(const InventoryPlacementTarget(x: 800, y: 804));
    cross.primarySketch = _primarySketch(projectId: _otherProjectId);
    expect(await crossController.confirmMove(), isFalse);
    expect(cross.moveCalls, 0);
    expect(
      crossController.lastErrorCode,
      'inventory_active_revision_unavailable',
    );
  });

  test('28 archive removes marker only through canonical reload', () async {
    final fake = _FakeInventoryApplication.standard();
    final map = InventoryMapController(
      application: fake,
      projectId: _projectId,
    );
    addTearDown(map.dispose);
    expect(await map.reload(), isTrue);
    expect(map.projections, hasLength(1));
    final detail = await _loadedDetail(
      fake,
      mapReload: () async {
        if (!await map.reload()) {
          throw const InventoryFailure('inventory_map_reload_failed');
        }
      },
      ids: _SequentialIds(2500),
    );
    addTearDown(detail.dispose);

    expect(await detail.archive(), isTrue);
    expect(detail.isArchived, isTrue);
    expect(detail.activePlacement, isNull);
    expect(map.projections, isEmpty);
    expect(
      detail.placementVersions.last.endReason,
      InventoryPlacementEndReason.assetArchived,
    );
  });

  testWidgets('29 detail surface has no hard delete action', (tester) async {
    final fake = _FakeInventoryApplication.standard();
    final controller = await _loadedDetail(fake, ids: _SequentialIds(2600));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventoryAssetDetailSheet(
            controller: controller,
            autoLoad: false,
          ),
        ),
      ),
    );

    expect(controller.hasHardDeleteAction, isFalse);
    expect(find.text('Sil'), findsNothing);
    expect(find.text('Kalıcı olarak sil'), findsNothing);
  });

  test(
    '30 unarchive preserves key and targets current active revision',
    () async {
      final fake = _FakeInventoryApplication.standard(archived: true);
      final controller = await _loadedDetail(fake, ids: _SequentialIds(2700));
      addTearDown(controller.dispose);

      expect(controller.beginUnarchive(), isTrue);
      expect(
        controller.previewUnarchive(
          const InventoryPlacementTarget(x: 900, y: 904),
        ),
        isTrue,
      );
      expect(await controller.confirmUnarchive(), isTrue);
      final command = fake.lastUnarchive!;

      expect(command.operationId, _uuid(2700));
      expect(command.successorPlacementId, _uuid(2701));
      expect(command.placementKey, _placementKey);
      expect(command.sketchId, _sketchId);
      expect(command.activeRevisionId, _activeRevisionId);
      expect(command.expectedPreviousPlacementSequence, 1);
      expect(command.x, 900);
      expect(command.y, 904);
      expect(controller.isArchived, isFalse);
      expect(controller.activePlacement!.placementKey, _placementKey);
      expect(controller.activePlacement!.sequence, 2);
    },
  );

  test('31 history is rendered in occurred DESC then id ASC order', () async {
    final fake = _FakeInventoryApplication.standard();
    final later = _t0.add(const Duration(minutes: 2));
    final earlier = _t0.add(const Duration(minutes: 1));
    fake.histories[_assetId] = [
      _event(id: _uuid(2800), occurredAt: later),
      _event(id: _uuid(2801), occurredAt: later),
      _event(id: _uuid(2802), occurredAt: earlier),
    ];
    final controller = await _loadedDetail(fake, ids: _SequentialIds(2810));
    addTearDown(controller.dispose);

    expect(controller.history.map((event) => event.id), [
      _uuid(2800),
      _uuid(2801),
      _uuid(2802),
    ]);
  });

  test('32 history view adds no synthetic records', () async {
    final fake = _FakeInventoryApplication.standard();
    final canonical = List<InventoryEventRecord>.of(fake.histories[_assetId]!);
    final controller = await _loadedDetail(fake, ids: _SequentialIds(2900));
    addTearDown(controller.dispose);

    expect(controller.history, canonical);
    expect(controller.history.length, fake.histories[_assetId]!.length);
    expect(inventoryEventSummary(controller.history.single), isNotEmpty);
    expect(fake.histories[_assetId], canonical);
  });

  test('33 reload and relaunch always source canonical projections', () async {
    final fake = _FakeInventoryApplication.standard();
    final first = InventoryMapController(
      application: fake,
      projectId: _projectId,
    );
    addTearDown(first.dispose);
    expect(await first.reload(), isTrue);
    expect(first.projections.single.asset.displayName, 'Kule vinç');

    fake.replaceProjection(
      _projection(displayName: 'Canonical harici değişim'),
    );
    expect(await first.reload(), isTrue);
    expect(
      first.projections.single.asset.displayName,
      'Canonical harici değişim',
    );

    final relaunched = InventoryMapController(
      application: fake,
      projectId: _projectId,
    );
    addTearDown(relaunched.dispose);
    expect(await relaunched.reload(), isTrue);
    expect(
      relaunched.projections.single.asset.displayName,
      'Canonical harici değişim',
    );
    expect(fake.listAssetsCalls, 3);
  });
}

Future<void> _pumpMap(
  WidgetTester tester,
  InventoryMapController controller, {
  ValueChanged<InventoryPlacementTarget>? onCreateTarget,
  ValueChanged<String>? onOpenAsset,
  ValueChanged<InventoryPlacementTarget>? onSelectTarget,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: InventoryMapView(
            controller: controller,
            autoLoad: false,
            onCreateTarget: onCreateTarget ?? (_) {},
            onOpenAsset: onOpenAsset ?? (_) {},
            onSelectTarget: onSelectTarget,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpDetailWithTextScale(
  WidgetTester tester,
  InventoryAssetDetailController controller, {
  required double textScale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: InventoryAssetDetailSheet(
          controller: controller,
          autoLoad: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

InventoryAssetQuickCreateController _quickController(
  _FakeInventoryApplication fake, {
  _SequentialIds? ids,
  String? floorId,
}) => InventoryAssetQuickCreateController(
  application: fake,
  projectId: _projectId,
  reloadCanonical: _noReload,
  floorId: floorId,
  idFactory: (ids ?? _SequentialIds(900)).call,
);

Future<InventoryAssetDetailController> _loadedDetail(
  _FakeInventoryApplication fake, {
  Future<void> Function()? mapReload,
  _SequentialIds? ids,
}) async {
  final controller = InventoryAssetDetailController(
    application: fake,
    projectId: _projectId,
    assetId: _assetId,
    reloadMapCanonical: mapReload ?? _noReload,
    idFactory: (ids ?? _SequentialIds(800)).call,
  );
  if (!await controller.reload()) {
    throw StateError(
      'detail fixture failed: ${controller.lastErrorCode ?? 'unknown'}',
    );
  }
  return controller;
}

Future<void> _noReload() async {}

InventoryPrimarySketchProjection _primarySketch({
  String projectId = _projectId,
}) {
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
  return InventoryPrimarySketchProjection(
    sketch: InventorySketchRecord(
      id: _sketchId,
      projectId: projectId,
      displayName: 'Ana kroki',
      isPrimary: true,
      activeRevisionId: _activeRevisionId,
      draftRevisionId: null,
      revision: 3,
      createdAt: _t0,
      updatedAt: _t0,
      archivedAt: null,
    ),
    activeRevision: InventorySketchRevisionRecord(
      id: _activeRevisionId,
      sketchId: _sketchId,
      projectId: projectId,
      revisionNumber: 2,
      baseRevisionId: null,
      state: InventorySketchRevisionState.active,
      geometry: geometry,
      geometrySha256: geometry.sha256,
      contentRevision: 1,
      createdAt: _t0,
      updatedAt: _t0,
      finalizedAt: _t0,
      supersededAt: null,
      abandonedAt: null,
    ),
    draftRevision: null,
    blocks: [
      InventoryBlockRecord(
        id: _blockId,
        projectId: projectId,
        displayName: 'Eski alan',
        normalizedName: 'eski alan',
        ordinal: 1,
        state: InventoryBlockState.detached,
        revision: 1,
        createdAt: _t0,
        updatedAt: _t0,
        archivedAt: null,
      ),
    ],
    floors: [
      InventoryFloorRecord(
        id: _floorId,
        blockId: _blockId,
        projectId: projectId,
        displayName: '1. Kat',
        ordinal: 1,
        revision: 1,
        createdAt: _t0,
        updatedAt: _t0,
        archivedAt: null,
      ),
    ],
  );
}

InventoryAssetProjection _projection({
  String assetId = _assetId,
  String projectId = _projectId,
  String displayName = 'Kule vinç',
  InventoryCategory category = InventoryCategory.equipment,
  String? otherCategoryLabel,
  int quantity = 2,
  int? placementQuantity,
  InventoryAssetStatus status = InventoryAssetStatus.available,
  String? note,
  int revision = 1,
  bool archived = false,
  String placementId = _placementId,
  String placementKey = _placementKey,
  int sequence = 1,
  int x = 200,
  int y = 204,
  String floorId = _floorId,
}) {
  final asset = InventoryAssetRecord(
    id: assetId,
    projectId: projectId,
    displayName: displayName,
    normalizedName: displayName.toLowerCase(),
    category: category,
    otherCategoryLabel: otherCategoryLabel,
    totalQuantity: quantity,
    status: status,
    note: note,
    revision: revision,
    createdAt: _t0,
    updatedAt: _t0,
    statusChangedAt: _t0,
    archivedAt: archived ? _t0 : null,
  );
  return InventoryAssetProjection(
    asset: asset,
    activePlacement: archived
        ? null
        : _placement(
            id: placementId,
            placementKey: placementKey,
            assetId: assetId,
            projectId: projectId,
            sequence: sequence,
            x: x,
            y: y,
            floorId: floorId,
            quantity: placementQuantity ?? quantity,
          ),
  );
}

InventoryPlacementRecord _placement({
  String id = _placementId,
  String placementKey = _placementKey,
  String assetId = _assetId,
  String projectId = _projectId,
  String sketchId = _sketchId,
  String provenanceRevisionId = _activeRevisionId,
  int sequence = 1,
  int x = 200,
  int y = 204,
  int quantity = 2,
  String floorId = _floorId,
  InventoryPlacementEndReason? endReason,
  String? supersedesPlacementId,
}) => InventoryPlacementRecord(
  id: id,
  placementKey: placementKey,
  projectId: projectId,
  assetId: assetId,
  sketchId: sketchId,
  floorId: floorId,
  provenanceRevisionId: provenanceRevisionId,
  sequence: sequence,
  x: x,
  y: y,
  quantity: quantity,
  createdAt: _t0,
  endedAt: endReason == null ? null : _t0.add(const Duration(minutes: 1)),
  endReason: endReason,
  supersedesPlacementId: supersedesPlacementId,
);

InventoryEventRecord _event({
  String id = '11111111-1111-4111-8111-111111111111',
  String assetId = _assetId,
  String projectId = _projectId,
  String placementKey = _placementKey,
  DateTime? occurredAt,
}) => InventoryEventRecord(
  id: id,
  operationId: '22222222-2222-4222-8222-222222222222',
  projectId: projectId,
  aggregateType: InventoryAggregateType.placement,
  aggregateId: placementKey,
  sequence: 1,
  eventType: InventoryEventType.placementCreated,
  occurredAt: occurredAt ?? _t0,
  payload: <String, Object?>{'asset_id': assetId},
  payloadJson: '{"asset_id":"$assetId"}',
  payloadSha256: 'a'.padRight(64, 'a'),
);

String _uuid(int value) {
  final suffix = value.toRadixString(16).padLeft(12, '0');
  return '00000000-0000-4000-8000-$suffix';
}

class _SequentialIds {
  _SequentialIds(this._next);

  int _next;

  String call() => _uuid(_next++);
}

class _FakeInventoryApplication
    implements InventoryApplicationPort, InventoryPhotoApplicationPort {
  _FakeInventoryApplication({
    required this.primarySketch,
    required this.projections,
    required this.versions,
    required this.histories,
  });

  factory _FakeInventoryApplication.standard({bool archived = false}) {
    final projection = _projection(archived: archived);
    final placement = archived
        ? _placement(endReason: InventoryPlacementEndReason.assetArchived)
        : projection.activePlacement!;
    return _FakeInventoryApplication(
      primarySketch: _primarySketch(),
      projections: <String, InventoryAssetProjection>{_assetId: projection},
      versions: <String, List<InventoryPlacementRecord>>{
        _assetId: <InventoryPlacementRecord>[placement],
      },
      histories: <String, List<InventoryEventRecord>>{
        _assetId: <InventoryEventRecord>[_event()],
      },
    );
  }

  InventoryPrimarySketchProjection? primarySketch;
  final Map<String, InventoryAssetProjection> projections;
  final Map<String, List<InventoryPlacementRecord>> versions;
  final Map<String, List<InventoryEventRecord>> histories;

  Object? nextFailure;
  bool duplicateAssetInList = false;
  bool? lastIncludeArchived;
  int createCalls = 0;
  int updateCalls = 0;
  int statusCalls = 0;
  int quantityCalls = 0;
  int archiveCalls = 0;
  int unarchiveCalls = 0;
  int moveCalls = 0;
  int listAssetsCalls = 0;
  int loadAssetCalls = 0;
  int historyCalls = 0;
  int placementVersionCalls = 0;
  int photoPickCalls = 0;
  int photoAddCalls = 0;
  int photoRemoveCalls = 0;
  InventoryPhotoPickResult nextPhotoPick = const InventoryPhotoPickResult(
    outcome: InventoryPhotoPickOutcome.cancelled,
  );
  Completer<InventoryPhotoPickResult>? pendingPhotoPick;
  InventoryAssetPhotoRecord? photo;
  InventoryPhotoContent? photoContent;
  CreateInventoryAssetCommand? lastCreate;
  UpdateInventoryAssetCommand? lastUpdate;
  ChangeInventoryAssetStatusCommand? lastStatus;
  ChangeInventoryAssetQuantityCommand? lastQuantity;
  ArchiveInventoryAssetCommand? lastArchive;
  UnarchiveInventoryAssetCommand? lastUnarchive;
  MoveInventoryPlacementCommand? lastMove;
  InventoryMutationResult? lastResult;

  void setPhoto({
    InventoryPhotoIntegrity integrity = InventoryPhotoIntegrity.healthy,
    String fileName = 'asset.png',
    List<int>? bytes,
  }) {
    final contentBytes = bytes ?? _pixelPng;
    photo = InventoryAssetPhotoRecord(
      linkId: _uuid(3900),
      attachmentId: _uuid(3901),
      assetId: _assetId,
      projectId: _projectId,
      originalFileName: fileName,
      revision: 1,
      createdAt: _t0,
      updatedAt: _t0,
      archivedAt: null,
      relativePath: 'managed/${_uuid(3901)}.png',
      mimeType: 'image/png',
      byteSize: contentBytes.length,
      sha256Value: 'a'.padRight(64, 'a'),
      integrity: integrity,
    );
    photoContent = InventoryPhotoContent(
      fileName: fileName,
      mimeType: 'image/png',
      bytes: contentBytes,
    );
  }

  void addAsset({required String assetId, required int x, required int y}) {
    final index = projections.length;
    final key = _uuid(3000 + index * 2);
    final placementId = _uuid(3001 + index * 2);
    final projection = _projection(
      assetId: assetId,
      displayName: 'Ek varlık',
      placementId: placementId,
      placementKey: key,
      x: x,
      y: y,
    );
    projections[assetId] = projection;
    versions[assetId] = [projection.activePlacement!];
    histories[assetId] = [_event(assetId: assetId, placementKey: key)];
  }

  void replaceProjection(InventoryAssetProjection projection) {
    projections[projection.asset.id] = projection;
  }

  @override
  Future<InventoryPrimarySketchProjection?> loadPrimarySketch(
    String projectId,
  ) async => primarySketch;

  @override
  Future<List<InventoryAssetProjection>> listAssets({
    required String projectId,
    bool includeArchived = false,
  }) async {
    listAssetsCalls += 1;
    lastIncludeArchived = includeArchived;
    final result = projections.values
        .where(
          (projection) =>
              projection.asset.projectId == projectId &&
              (includeArchived || projection.asset.archivedAt == null),
        )
        .toList();
    if (duplicateAssetInList && result.isNotEmpty) {
      result.add(result.first);
    }
    return result;
  }

  @override
  Future<InventoryAssetProjection> loadAsset({
    required String projectId,
    required String assetId,
  }) async {
    loadAssetCalls += 1;
    final projection = projections[assetId];
    if (projection == null || projection.asset.projectId != projectId) {
      throw const InventoryFailure('inventory_asset_not_found');
    }
    return projection;
  }

  @override
  Future<List<InventoryPlacementRecord>> listPlacementVersions({
    required String projectId,
    required String assetId,
    required String placementKey,
  }) async {
    placementVersionCalls += 1;
    final result = versions[assetId];
    if (result == null ||
        result.isEmpty ||
        result.any(
          (placement) =>
              placement.projectId != projectId ||
              placement.placementKey != placementKey,
        )) {
      throw const InventoryFailure('inventory_placement_not_found');
    }
    return List<InventoryPlacementRecord>.of(result);
  }

  @override
  Future<List<InventoryEventRecord>> listAssetHistory({
    required String projectId,
    required String assetId,
  }) async {
    historyCalls += 1;
    final result = histories[assetId];
    if (result == null || result.any((event) => event.projectId != projectId)) {
      throw const InventoryFailure('inventory_asset_not_found');
    }
    return List<InventoryEventRecord>.of(result);
  }

  @override
  Future<InventoryPhotoPickResult> pickAssetPhoto(
    InventoryPhotoSource source,
  ) async {
    photoPickCalls += 1;
    return pendingPhotoPick?.future ?? nextPhotoPick;
  }

  @override
  Future<InventoryAssetPhotoRecord?> loadActiveAssetPhoto({
    required String projectId,
    required String assetId,
  }) async {
    _current(projectId, assetId);
    return photo;
  }

  @override
  Future<InventoryPhotoContent> readAssetPhoto({
    required String projectId,
    required String assetId,
    required String linkId,
  }) async {
    _current(projectId, assetId);
    final current = photo;
    if (current == null || current.linkId != linkId || photoContent == null) {
      throw const InventoryFailure('inventory_photo_unavailable');
    }
    if (current.integrity != InventoryPhotoIntegrity.healthy) {
      throw const InventoryFailure('inventory_photo_integrity_failed');
    }
    return photoContent!;
  }

  @override
  Future<InventoryMutationResult> addOrReplaceAssetPhoto(
    AddOrReplaceInventoryAssetPhotoCommand command,
  ) async {
    photoAddCalls += 1;
    _throwIfNeeded();
    final current = _current(command.projectId, command.assetId);
    _expectAssetRevision(current, command.expectedAssetRevision);
    setPhoto(
      fileName: command.selection.originalFileName,
      bytes: command.selection.bytes,
    );
    photo = InventoryAssetPhotoRecord(
      linkId: command.linkId,
      attachmentId: command.attachmentId,
      assetId: command.assetId,
      projectId: command.projectId,
      originalFileName: command.selection.originalFileName,
      revision: 1,
      createdAt: _t0,
      updatedAt: _t0,
      archivedAt: null,
      relativePath: 'managed/${command.attachmentId}.png',
      mimeType: 'image/png',
      byteSize: command.selection.bytes.length,
      sha256Value: 'b'.padRight(64, 'b'),
      integrity: InventoryPhotoIntegrity.healthy,
    );
    return _remember(
      _result(
        command: command,
        sourceId: command.linkId,
        sourceRevision: 1,
        supportingId: command.attachmentId,
      ),
    );
  }

  @override
  Future<InventoryMutationResult> removeAssetPhoto(
    RemoveInventoryAssetPhotoCommand command,
  ) async {
    photoRemoveCalls += 1;
    _throwIfNeeded();
    final current = _current(command.projectId, command.assetId);
    _expectAssetRevision(current, command.expectedAssetRevision);
    final active = photo;
    if (active == null ||
        active.linkId != command.linkId ||
        active.revision != command.expectedLinkRevision) {
      throw const InventoryFailure('inventory_stale_revision');
    }
    photo = null;
    photoContent = null;
    return _remember(
      _result(
        command: command,
        sourceId: command.linkId,
        sourceRevision: active.revision + 1,
        supportingId: active.attachmentId,
      ),
    );
  }

  @override
  Future<InventoryMutationResult> createAsset(
    CreateInventoryAssetCommand command,
  ) async {
    createCalls += 1;
    lastCreate = command;
    _throwIfNeeded();
    final asset = InventoryAssetRecord(
      id: command.assetId,
      projectId: command.projectId,
      displayName: command.displayName,
      normalizedName: command.displayName.toLowerCase(),
      category: command.category,
      otherCategoryLabel: command.otherCategoryLabel,
      totalQuantity: command.totalQuantity,
      status: command.status,
      note: command.note,
      revision: 1,
      createdAt: _t0,
      updatedAt: _t0,
      statusChangedAt: _t0,
      archivedAt: null,
    );
    final placement = _placement(
      id: command.placementId,
      placementKey: command.placementKey,
      assetId: command.assetId,
      projectId: command.projectId,
      sketchId: command.sketchId,
      provenanceRevisionId: command.activeRevisionId,
      x: command.x,
      y: command.y,
      quantity: command.totalQuantity,
      floorId: command.floorId ?? _floorId,
    );
    projections[command.assetId] = InventoryAssetProjection(
      asset: asset,
      activePlacement: placement,
    );
    versions[command.assetId] = [placement];
    histories[command.assetId] = [
      _event(
        assetId: command.assetId,
        projectId: command.projectId,
        placementKey: command.placementKey,
      ),
    ];
    return _remember(
      _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: 1,
        supportingId: command.placementId,
        supportingRevision: 1,
        eventCount: 2,
      ),
    );
  }

  @override
  Future<InventoryMutationResult> updateAsset(
    UpdateInventoryAssetCommand command,
  ) async {
    updateCalls += 1;
    lastUpdate = command;
    _throwIfNeeded();
    final current = _current(command.projectId, command.assetId);
    _expectAssetRevision(current, command.expectedAssetRevision);
    final cleanOther = command.category == InventoryCategory.other
        ? command.otherCategoryLabel
        : null;
    final noOp =
        current.asset.displayName == command.displayName &&
        current.asset.category == command.category &&
        current.asset.otherCategoryLabel == cleanOther &&
        current.asset.note == command.note;
    if (!noOp) {
      _setAsset(
        current,
        _copyAsset(
          current.asset,
          displayName: command.displayName,
          category: command.category,
          otherCategoryLabel: cleanOther,
          note: command.note,
          revision: current.asset.revision + 1,
        ),
      );
    }
    return _remember(
      _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: current.asset.revision + (noOp ? 0 : 1),
        isNoOp: noOp,
        eventCount: noOp ? 0 : 1,
      ),
    );
  }

  @override
  Future<InventoryMutationResult> changeAssetStatus(
    ChangeInventoryAssetStatusCommand command,
  ) async {
    statusCalls += 1;
    lastStatus = command;
    _throwIfNeeded();
    final current = _current(command.projectId, command.assetId);
    _expectAssetRevision(current, command.expectedAssetRevision);
    final noOp = current.asset.status == command.status;
    if (!noOp) {
      _setAsset(
        current,
        _copyAsset(
          current.asset,
          status: command.status,
          revision: current.asset.revision + 1,
        ),
      );
    }
    return _remember(
      _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: current.asset.revision + (noOp ? 0 : 1),
        isNoOp: noOp,
        eventCount: noOp ? 0 : 1,
      ),
    );
  }

  @override
  Future<InventoryMutationResult> changeAssetQuantity(
    ChangeInventoryAssetQuantityCommand command,
  ) async {
    quantityCalls += 1;
    lastQuantity = command;
    _throwIfNeeded();
    if (command.totalQuantity < 1 || command.totalQuantity > 1000000) {
      throw const InventoryFailure('inventory_invalid_quantity');
    }
    final current = _current(command.projectId, command.assetId);
    _expectAssetRevision(current, command.expectedAssetRevision);
    final placement = _solePlacement(current);
    _expectPlacement(
      placement,
      key: command.placementKey,
      sequence: command.expectedPlacementSequence,
    );
    final noOp = current.asset.totalQuantity == command.totalQuantity;
    if (!noOp) {
      final ended = _endPlacement(
        placement,
        InventoryPlacementEndReason.quantityChanged,
      );
      final successor = _placement(
        id: command.successorPlacementId,
        placementKey: placement.placementKey,
        assetId: placement.assetId,
        projectId: placement.projectId,
        sketchId: placement.sketchId,
        provenanceRevisionId: placement.provenanceRevisionId,
        sequence: placement.sequence + 1,
        x: placement.x,
        y: placement.y,
        quantity: command.totalQuantity,
        supersedesPlacementId: placement.id,
      );
      _replaceLastVersion(command.assetId, ended, successor: successor);
      projections[command.assetId] = InventoryAssetProjection(
        asset: _copyAsset(
          current.asset,
          totalQuantity: command.totalQuantity,
          revision: current.asset.revision + 1,
        ),
        activePlacement: successor,
      );
    }
    return _remember(
      _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: current.asset.revision + (noOp ? 0 : 1),
        supportingId: noOp ? placement.id : command.successorPlacementId,
        supportingRevision: placement.sequence + (noOp ? 0 : 1),
        isNoOp: noOp,
        eventCount: noOp ? 0 : 2,
      ),
    );
  }

  @override
  Future<InventoryMutationResult> archiveAsset(
    ArchiveInventoryAssetCommand command,
  ) async {
    archiveCalls += 1;
    lastArchive = command;
    _throwIfNeeded();
    final current = _current(command.projectId, command.assetId);
    _expectAssetRevision(current, command.expectedAssetRevision);
    final placement = _solePlacement(current);
    final ended = _endPlacement(
      placement,
      InventoryPlacementEndReason.assetArchived,
    );
    _replaceLastVersion(command.assetId, ended);
    projections[command.assetId] = InventoryAssetProjection(
      asset: _copyAsset(
        current.asset,
        revision: current.asset.revision + 1,
        archivedAt: _t0.add(const Duration(minutes: 1)),
      ),
      activePlacement: null,
    );
    return _remember(
      _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: current.asset.revision + 1,
        supportingId: placement.id,
        supportingRevision: placement.sequence,
        eventCount: 2,
      ),
    );
  }

  @override
  Future<InventoryMutationResult> unarchiveAsset(
    UnarchiveInventoryAssetCommand command,
  ) async {
    unarchiveCalls += 1;
    lastUnarchive = command;
    _throwIfNeeded();
    final current = _current(command.projectId, command.assetId);
    if (current.asset.archivedAt == null || current.activePlacement != null) {
      throw const InventoryFailure('inventory_asset_state_invalid');
    }
    _expectAssetRevision(current, command.expectedAssetRevision);
    final chain = versions[command.assetId]!;
    final predecessor = chain.last;
    if (predecessor.isActive ||
        predecessor.placementKey != command.placementKey ||
        predecessor.sequence != command.expectedPreviousPlacementSequence) {
      throw const InventoryFailure('inventory_stale_revision');
    }
    final successor = _placement(
      id: command.successorPlacementId,
      placementKey: predecessor.placementKey,
      assetId: predecessor.assetId,
      projectId: predecessor.projectId,
      sketchId: command.sketchId,
      provenanceRevisionId: command.activeRevisionId,
      sequence: predecessor.sequence + 1,
      x: command.x,
      y: command.y,
      quantity: current.asset.totalQuantity,
      supersedesPlacementId: predecessor.id,
    );
    versions[command.assetId] = [...chain, successor];
    projections[command.assetId] = InventoryAssetProjection(
      asset: _copyAsset(
        current.asset,
        revision: current.asset.revision + 1,
        archivedAt: null,
      ),
      activePlacement: successor,
    );
    return _remember(
      _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: current.asset.revision + 1,
        supportingId: successor.id,
        supportingRevision: successor.sequence,
        eventCount: 2,
      ),
    );
  }

  @override
  Future<InventoryMutationResult> movePlacement(
    MoveInventoryPlacementCommand command,
  ) async {
    moveCalls += 1;
    lastMove = command;
    _throwIfNeeded();
    final current = _current(command.projectId, command.assetId);
    final placement = _solePlacement(current);
    _expectPlacement(
      placement,
      key: command.placementKey,
      sequence: command.expectedPlacementSequence,
    );
    final noOp = placement.x == command.x && placement.y == command.y;
    if (!noOp) {
      final ended = _endPlacement(placement, InventoryPlacementEndReason.moved);
      final successor = _placement(
        id: command.successorPlacementId,
        placementKey: placement.placementKey,
        assetId: placement.assetId,
        projectId: placement.projectId,
        sketchId: command.sketchId,
        provenanceRevisionId: command.activeRevisionId,
        sequence: placement.sequence + 1,
        x: command.x,
        y: command.y,
        quantity: placement.quantity,
        supersedesPlacementId: placement.id,
      );
      _replaceLastVersion(command.assetId, ended, successor: successor);
      projections[command.assetId] = InventoryAssetProjection(
        asset: current.asset,
        activePlacement: successor,
      );
    }
    return _remember(
      _result(
        command: command,
        sourceId: command.placementKey,
        sourceRevision: placement.sequence + (noOp ? 0 : 1),
        supportingId: noOp ? placement.id : command.successorPlacementId,
        supportingRevision: placement.sequence + (noOp ? 0 : 1),
        isNoOp: noOp,
        eventCount: noOp ? 0 : 2,
      ),
    );
  }

  InventoryAssetProjection _current(String projectId, String assetId) {
    final current = projections[assetId];
    if (current == null || current.asset.projectId != projectId) {
      throw const InventoryFailure('inventory_asset_not_found');
    }
    return current;
  }

  void _expectAssetRevision(
    InventoryAssetProjection current,
    int expectedRevision,
  ) {
    if (current.asset.revision != expectedRevision) {
      throw const InventoryFailure('inventory_stale_revision');
    }
  }

  InventoryPlacementRecord _solePlacement(InventoryAssetProjection current) {
    final placement = current.activePlacement;
    if (placement == null) {
      throw const InventoryFailure('inventory_active_placement_unavailable');
    }
    if (placement.quantity != current.asset.totalQuantity) {
      throw const InventoryFailure(
        'inventory_multiple_placements_not_supported_in_v1',
      );
    }
    return placement;
  }

  void _expectPlacement(
    InventoryPlacementRecord placement, {
    required String key,
    required int sequence,
  }) {
    if (placement.placementKey != key || placement.sequence != sequence) {
      throw const InventoryFailure('inventory_stale_revision');
    }
  }

  void _setAsset(InventoryAssetProjection current, InventoryAssetRecord asset) {
    projections[asset.id] = InventoryAssetProjection(
      asset: asset,
      activePlacement: current.activePlacement,
    );
  }

  void _replaceLastVersion(
    String assetId,
    InventoryPlacementRecord ended, {
    InventoryPlacementRecord? successor,
  }) {
    final chain = List<InventoryPlacementRecord>.of(versions[assetId]!);
    chain[chain.length - 1] = ended;
    if (successor != null) chain.add(successor);
    versions[assetId] = chain;
  }

  void _throwIfNeeded() {
    final failure = nextFailure;
    if (failure == null) return;
    nextFailure = null;
    throw failure;
  }

  InventoryMutationResult _remember(InventoryMutationResult result) {
    lastResult = result;
    return result;
  }

  InventoryMutationResult _result({
    required InventoryMutationCommand command,
    required String sourceId,
    required int sourceRevision,
    String? supportingId,
    int? supportingRevision,
    bool isNoOp = false,
    int eventCount = 1,
  }) => InventoryMutationResult(
    operationId: command.operationId,
    commandType: command.commandType,
    projectId: command.projectId,
    primaryAggregateType: command.primaryAggregateType,
    primaryAggregateId: command.primaryAggregateId,
    sourceId: sourceId,
    sourceRevision: sourceRevision,
    supportingId: supportingId,
    supportingRevision: supportingRevision,
    isNoOp: isNoOp,
    eventCount: eventCount,
    resultAt: _t0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _notProvided = Object();

InventoryAssetRecord _copyAsset(
  InventoryAssetRecord current, {
  String? displayName,
  InventoryCategory? category,
  Object? otherCategoryLabel = _notProvided,
  int? totalQuantity,
  InventoryAssetStatus? status,
  Object? note = _notProvided,
  int? revision,
  Object? archivedAt = _notProvided,
}) => InventoryAssetRecord(
  id: current.id,
  projectId: current.projectId,
  displayName: displayName ?? current.displayName,
  normalizedName: (displayName ?? current.displayName).toLowerCase(),
  category: category ?? current.category,
  otherCategoryLabel: identical(otherCategoryLabel, _notProvided)
      ? current.otherCategoryLabel
      : otherCategoryLabel as String?,
  totalQuantity: totalQuantity ?? current.totalQuantity,
  status: status ?? current.status,
  note: identical(note, _notProvided) ? current.note : note as String?,
  revision: revision ?? current.revision,
  createdAt: current.createdAt,
  updatedAt: _t0.add(const Duration(minutes: 1)),
  statusChangedAt: status == null || status == current.status
      ? current.statusChangedAt
      : _t0.add(const Duration(minutes: 1)),
  archivedAt: identical(archivedAt, _notProvided)
      ? current.archivedAt
      : archivedAt as DateTime?,
);

InventoryPlacementRecord _endPlacement(
  InventoryPlacementRecord current,
  InventoryPlacementEndReason reason,
) => InventoryPlacementRecord(
  id: current.id,
  placementKey: current.placementKey,
  projectId: current.projectId,
  assetId: current.assetId,
  sketchId: current.sketchId,
  floorId: current.floorId,
  provenanceRevisionId: current.provenanceRevisionId,
  sequence: current.sequence,
  x: current.x,
  y: current.y,
  quantity: current.quantity,
  createdAt: current.createdAt,
  endedAt: _t0.add(const Duration(minutes: 1)),
  endReason: reason,
  supersedesPlacementId: current.supersedesPlacementId,
);
