import 'dart:async';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/inventory/inventory_map_view.dart';
import 'package:chief_site_engineer/features/inventory/inventory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _projectB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _sketchA = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _sketchB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
const _revisionA = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const _revisionB = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2';
const _assetA = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';
const _assetB = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd2';
const _assetArchived = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd3';
const _assetMissing = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd4';
const _assetInvalid = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd5';
final _now = DateTime.parse('2026-08-28T08:00:00Z');

void main() {
  test(
    'zero one many project binding is exact and zero-project does no I/O',
    () async {
      final inventory = _FakeInventory();
      final source = _ProjectSource();
      final zero = _controller(inventory, source);
      addTearDown(zero.dispose);
      addTearDown(source.dispose);

      await zero.initialize();
      expect(zero.loadStatus, InventoryPageLoadStatus.projectRequired);
      expect(zero.selectedProjectId, isNull);
      expect(inventory.reads, 0);

      source.projects = [_project(_projectA, 'Proje A')];
      await zero.refreshProjects();
      expect(zero.selectedProjectId, _projectA);
      expect(zero.loadStatus, InventoryPageLoadStatus.noSketch);
      expect(inventory.primaryReads, 1);
      expect(inventory.listReads, 0);

      final manyInventory = _FakeInventory()
        ..sketches[_projectA] = _sketch(_projectA)
        ..assets[_projectA] = [_asset(_projectA, _assetA)];
      final manySource = _ProjectSource()
        ..projects = [
          _project(_projectA, 'Proje A'),
          _project(_projectB, 'Proje B'),
        ];
      final many = _controller(manyInventory, manySource);
      addTearDown(many.dispose);
      addTearDown(manySource.dispose);
      await many.initialize();
      expect(many.loadStatus, InventoryPageLoadStatus.projectSelectionRequired);
      expect(manyInventory.reads, 0);
      await many.selectProject(_projectA);
      expect(many.selectedProjectId, _projectA);
      expect(many.loadStatus, InventoryPageLoadStatus.ready);
    },
  );

  test(
    'explicit project switch clears session and unavailable project does not auto-switch',
    () async {
      final inventory = _FakeInventory()
        ..sketches.addAll({
          _projectA: _sketch(_projectA),
          _projectB: _sketch(_projectB),
        })
        ..assets.addAll({
          _projectA: [_asset(_projectA, _assetA)],
          _projectB: [_asset(_projectB, _assetB)],
        });
      final source = _ProjectSource()
        ..projects = [
          _project(_projectA, 'Proje A'),
          _project(_projectB, 'Proje B'),
        ];
      final controller = _controller(inventory, source);
      addTearDown(controller.dispose);
      addTearDown(source.dispose);
      await controller.initialize();
      await controller.selectProject(_projectA);
      controller
        ..setSearch('vinç')
        ..setCategoryFilter(InventoryCategory.equipment)
        ..setStatusFilter(InventoryAssetStatus.inUse)
        ..setArchiveFilter(InventoryArchiveFilter.all)
        ..setView(InventoryPageView.list);

      await controller.selectProject(_projectB);
      expect(controller.selectedProjectId, _projectB);
      expect(controller.search, isEmpty);
      expect(controller.categoryFilter, isNull);
      expect(controller.statusFilter, isNull);
      expect(controller.archiveFilter, InventoryArchiveFilter.active);
      expect(controller.view, InventoryPageView.map);
      expect(controller.assets.single.asset.id, _assetB);

      source.projects = [_project(_projectA, 'Proje A')];
      await controller.refreshProjects();
      expect(controller.selectedProjectId, _projectB);
      expect(controller.assets, isEmpty);
      expect(controller.loadStatus, InventoryPageLoadStatus.failed);
      expect(controller.lastErrorCode, 'inventory_project_unavailable');
    },
  );

  testWidgets(
    'no-sketch exact action reuses editor result and reloads only after finalize',
    (tester) async {
      final inventory = _FakeInventory();
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      var launches = 0;
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        sketchEditorLauncher: (context, projectId) async {
          launches += 1;
          expect(projectId, _projectA);
          inventory
            ..sketches[_projectA] = _sketch(_projectA)
            ..assets[_projectA] = [];
          return true;
        },
      );

      expect(find.text('Bu projede henüz şematik kroki yok.'), findsOneWidget);
      expect(find.text('Kroki ekle'), findsOneWidget);
      expect(inventory.primaryReads, 1);
      await tester.tap(find.byKey(const Key('inventory-add-sketch')));
      await tester.pumpAndSettle();

      expect(launches, 1);
      expect(inventory.primaryReads, 2);
      expect(inventory.listReads, 1);
      expect(find.byType(InventoryMapView), findsOneWidget);
    },
  );

  testWidgets(
    'Kroki and Liste share exact identities and all filters are projection-only',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _sketch(_projectA)
        ..assets[_projectA] = [
          _asset(
            _projectA,
            _assetA,
            name: 'Kule vinç',
            category: InventoryCategory.equipment,
            status: InventoryAssetStatus.inUse,
            x: 1024,
            y: 1024,
          ),
          _asset(
            _projectA,
            _assetB,
            name: 'Lazer metre',
            category: InventoryCategory.measurementDevice,
            status: InventoryAssetStatus.available,
            x: 2048,
            y: 1024,
          ),
          _asset(
            _projectA,
            _assetArchived,
            name: 'Eski matkap',
            category: InventoryCategory.powerTool,
            archived: true,
          ),
        ];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      final controller = _controller(inventory, source);
      addTearDown(controller.dispose);
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        controller: controller,
      );

      final pageState = tester.state<InventoryPageState>(
        find.byType(InventoryPage),
      );
      final map = pageState.mapController!;
      expect(map.projections, hasLength(2));
      expect(map.projections[0], same(controller.assets[0]));
      expect(map.projections[1], same(controller.assets[1]));
      expect(
        find.byKey(const Key('inventory-marker-$_assetArchived')),
        findsNothing,
      );
      expect(find.byKey(const Key('inventory-search')), findsOneWidget);
      expect(find.byKey(const Key('inventory-category-all')), findsOneWidget);
      expect(find.byKey(const Key('inventory-status-all')), findsOneWidget);
      expect(find.byKey(const Key('inventory-archive-active')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('inventory-search')),
        '  KULE   VİNÇ ',
      );
      await tester.pump();
      expect(map.projections.single, same(controller.assets[0]));
      expect(inventory.mutations, 0);

      controller
        ..setSearch('')
        ..setCategoryFilter(InventoryCategory.measurementDevice)
        ..setStatusFilter(InventoryAssetStatus.available);
      await tester.pump();
      expect(map.projections.single.asset.id, _assetB);
      expect(inventory.mutations, 0);

      controller
        ..setCategoryFilter(null)
        ..setStatusFilter(null)
        ..setArchiveFilter(InventoryArchiveFilter.archived)
        ..setView(InventoryPageView.list);
      await tester.pump();
      expect(
        find.byKey(const Key('inventory-list-$_assetArchived')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inventory-list-$_assetA')), findsNothing);
      expect(
        find.byKey(const Key('inventory-marker-$_assetArchived')),
        findsNothing,
      );
      expect(inventory.mutations, 0);
    },
  );

  testWidgets('empty inventory empty search and load failure are distinct', (
    tester,
  ) async {
    final source = _ProjectSource()
      ..projects = [_project(_projectA, 'Proje A')];
    final empty = _FakeInventory()
      ..sketches[_projectA] = _sketch(_projectA)
      ..assets[_projectA] = [];
    final emptyController = _controller(empty, source);
    addTearDown(emptyController.dispose);
    await _pumpPage(
      tester,
      inventory: empty,
      source: source,
      controller: emptyController,
    );
    emptyController.setView(InventoryPageView.list);
    await tester.pump();
    expect(find.byKey(const Key('inventory-empty')), findsOneWidget);

    final populated = _FakeInventory()
      ..sketches[_projectA] = _sketch(_projectA)
      ..assets[_projectA] = [_asset(_projectA, _assetA)];
    final populatedController = _controller(populated, source);
    addTearDown(populatedController.dispose);
    await _pumpPage(
      tester,
      inventory: populated,
      source: source,
      controller: populatedController,
    );
    populatedController
      ..setView(InventoryPageView.list)
      ..setSearch('eşleşmeyen');
    await tester.pump();
    expect(find.byKey(const Key('inventory-empty-search')), findsOneWidget);

    final failed = _FakeInventory()
      ..sketches[_projectA] = _sketch(_projectA)
      ..listFailure = const InventoryFailure('inventory_test_load_failed');
    await _pumpPage(tester, inventory: failed, source: source);
    expect(find.byKey(const Key('inventory-load-failure')), findsOneWidget);
    expect(find.textContaining('inventory_test_load_failed'), findsOneWidget);
  });

  testWidgets('marker opens exact existing asset detail identity', (
    tester,
  ) async {
    final inventory = _FakeInventory()
      ..sketches[_projectA] = _sketch(_projectA)
      ..assets[_projectA] = [_asset(_projectA, _assetA)];
    final source = _ProjectSource()
      ..projects = [_project(_projectA, 'Proje A')];
    final opened = <String>[];
    await _pumpPage(
      tester,
      inventory: inventory,
      source: source,
      assetDetailLauncher: (context, projectId, assetId) async {
        expect(projectId, _projectA);
        opened.add(assetId);
      },
    );

    await tester.tap(find.byKey(const Key('inventory-marker-$_assetA')));
    await tester.pump();
    expect(opened, [_assetA]);
  });

  testWidgets(
    'list row centers exact placement and highlights for two seconds',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches.addAll({
          _projectA: _sketch(_projectA),
          _projectB: _sketch(_projectB),
        })
        ..assets.addAll({
          _projectA: [_asset(_projectA, _assetA, x: 1024, y: 768)],
          _projectB: [_asset(_projectB, _assetB)],
        });
      final source = _ProjectSource()
        ..projects = [
          _project(_projectA, 'Proje A'),
          _project(_projectB, 'Proje B'),
        ];
      final controller = _controller(inventory, source);
      addTearDown(controller.dispose);
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        controller: controller,
      );
      await controller.selectProject(_projectA);
      controller.setView(InventoryPageView.list);
      await tester.pump();

      await tester.tap(find.byKey(const Key('inventory-list-$_assetA')));
      await tester.pump();
      await tester.pump();
      final pageState = tester.state<InventoryPageState>(
        find.byType(InventoryPage),
      );
      final mapState = pageState.mapViewState!;
      expect(controller.view, InventoryPageView.map);
      expect(mapState.highlightedAssetId, _assetA);
      final viewport = mapState.viewport!;
      final placement = controller.assets.single.activePlacement!;
      final markerPoint =
          viewport.origin +
          Offset(placement.x * viewport.scale, placement.y * viewport.scale);
      expect(
        (markerPoint - viewport.viewSize.center(Offset.zero)).distance,
        lessThan(0.01),
      );
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(inventory.mutations, 0);

      controller.setSearch('eski oturum');
      await controller.selectProject(_projectB);
      await tester.pump();
      await tester.pump();
      expect(controller.search, isEmpty);
      expect(controller.selectedProjectId, _projectB);
      expect(pageState.mapViewState?.highlightedAssetId, isNull);
      expect(find.byKey(const Key('inventory-marker-$_assetA')), findsNothing);
      expect(
        find.byKey(const Key('inventory-marker-$_assetB')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 2100));
      expect(pageState.mapViewState?.highlightedAssetId, isNull);
      expect(inventory.mutations, 0);
    },
  );

  testWidgets(
    'missing invalid and corrupt geometry stay in Liste with typed failure',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _sketch(_projectA)
        ..assets[_projectA] = [
          _asset(_projectA, _assetMissing, placement: false),
          _asset(_projectA, _assetInvalid, x: 101, y: 100),
        ];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      final controller = _controller(inventory, source);
      addTearDown(controller.dispose);
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        controller: controller,
      );
      controller.setView(InventoryPageView.list);
      await tester.pump();

      await tester.tap(find.byKey(const Key('inventory-list-$_assetMissing')));
      await tester.pump();
      expect(controller.view, InventoryPageView.list);
      expect(
        controller.lastDiagnosticCode,
        'inventory_active_placement_unavailable',
      );
      controller.clearDiagnostic();
      await tester.tap(find.byKey(const Key('inventory-list-$_assetInvalid')));
      await tester.pump();
      expect(controller.view, InventoryPageView.list);
      expect(
        controller.lastDiagnosticCode,
        'inventory_projection_integrity_failed',
      );
      expect(inventory.mutations, 0);

      final corrupt = _FakeInventory()
        ..primaryFailure = const InventoryGeometryFailure('synthetic_corrupt')
        ..assets[_projectA] = [_asset(_projectA, _assetA)];
      final corruptController = _controller(corrupt, source);
      addTearDown(corruptController.dispose);
      await _pumpPage(
        tester,
        inventory: corrupt,
        source: source,
        controller: corruptController,
      );
      expect(corruptController.loadStatus, InventoryPageLoadStatus.ready);
      expect(corruptController.view, InventoryPageView.list);
      expect(
        corruptController.lastDiagnosticCode,
        InventoryGeometryFailure.safeCode,
      );
      await tester.tap(find.byKey(const Key('inventory-list-$_assetA')));
      await tester.pump();
      expect(corruptController.view, InventoryPageView.list);
      expect(
        corruptController.lastDiagnosticCode,
        InventoryGeometryFailure.safeCode,
      );
      expect(corrupt.mutations, 0);
    },
  );
}

InventoryPageController _controller(
  _FakeInventory inventory,
  _ProjectSource source,
) => InventoryPageController(
  application: inventory,
  listProjects: source.list,
  projectChanges: source.changes,
);

Future<void> _pumpPage(
  WidgetTester tester, {
  required _FakeInventory inventory,
  required _ProjectSource source,
  InventoryPageController? controller,
  InventorySketchEditorLauncher? sketchEditorLauncher,
  InventoryAssetDetailLauncher? assetDetailLauncher,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: InventoryPage(
          application: inventory,
          listProjects: source.list,
          projectChanges: source.changes,
          controller: controller,
          sketchEditorLauncher: sketchEditorLauncher,
          assetDetailLauncher: assetDetailLauncher,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

class _ProjectSource {
  List<MobileProject> projects = const [];
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;
  Future<List<MobileProject>> list() async => List.unmodifiable(projects);
  void dispose() => _changes.close();
}

class _FakeInventory extends UnavailableInventoryApplication {
  final Map<String, InventoryPrimarySketchProjection?> sketches = {};
  final Map<String, List<InventoryAssetProjection>> assets = {};
  Object? primaryFailure;
  Object? listFailure;
  int primaryReads = 0;
  int listReads = 0;
  int mutations = 0;

  int get reads => primaryReads + listReads;

  @override
  Future<InventoryPrimarySketchProjection?> loadPrimarySketch(
    String projectId,
  ) async {
    primaryReads += 1;
    if (primaryFailure case final error?) throw error;
    return sketches[projectId];
  }

  @override
  Future<List<InventoryAssetProjection>> listAssets({
    required String projectId,
    bool includeArchived = false,
  }) async {
    listReads += 1;
    if (listFailure case final error?) throw error;
    final values = assets[projectId] ?? const [];
    return List.unmodifiable(
      includeArchived
          ? values
          : values.where((item) => item.asset.archivedAt == null),
    );
  }
}

MobileProject _project(String id, String name) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-08-28T08:00:00Z',
  updatedAt: '2026-08-28T08:00:00Z',
  revision: 1,
);

InventoryPrimarySketchProjection _sketch(String projectId) {
  final sketchId = projectId == _projectA ? _sketchA : _sketchB;
  final revisionId = projectId == _projectA ? _revisionA : _revisionB;
  final geometry = InventoryGeometry(
    polylines: [
      InventoryPolyline(
        closed: false,
        points: [
          InventorySketchPoint(x: 0, y: 0),
          InventorySketchPoint(x: 4096, y: 3072),
        ],
      ),
    ],
  );
  return InventoryPrimarySketchProjection(
    sketch: InventorySketchRecord(
      id: sketchId,
      projectId: projectId,
      displayName: 'Saha krokisi',
      isPrimary: true,
      activeRevisionId: revisionId,
      draftRevisionId: null,
      revision: 1,
      createdAt: _now,
      updatedAt: _now,
      archivedAt: null,
    ),
    activeRevision: InventorySketchRevisionRecord(
      id: revisionId,
      sketchId: sketchId,
      projectId: projectId,
      revisionNumber: 1,
      baseRevisionId: null,
      state: InventorySketchRevisionState.active,
      geometry: geometry,
      geometrySha256: geometry.sha256,
      contentRevision: 1,
      createdAt: _now,
      updatedAt: _now,
      finalizedAt: _now,
      supersededAt: null,
      abandonedAt: null,
    ),
    draftRevision: null,
  );
}

InventoryAssetProjection _asset(
  String projectId,
  String assetId, {
  String name = 'Kule vinç',
  InventoryCategory category = InventoryCategory.equipment,
  InventoryAssetStatus status = InventoryAssetStatus.available,
  bool archived = false,
  bool placement = true,
  int x = 100,
  int y = 100,
}) {
  final normalized = name
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase();
  final sketchId = projectId == _projectA ? _sketchA : _sketchB;
  final revisionId = projectId == _projectA ? _revisionA : _revisionB;
  return InventoryAssetProjection(
    asset: InventoryAssetRecord(
      id: assetId,
      projectId: projectId,
      displayName: name,
      normalizedName: normalized,
      category: category,
      otherCategoryLabel: null,
      totalQuantity: 2,
      status: status,
      note: null,
      revision: 1,
      createdAt: _now,
      updatedAt: _now,
      statusChangedAt: _now,
      archivedAt: archived ? _now : null,
    ),
    activePlacement: !placement || archived
        ? null
        : InventoryPlacementRecord(
            id: 'eeeeeeee-eeee-4eee-8eee-${assetId.substring(24)}',
            placementKey: 'ffffffff-ffff-4fff-8fff-${assetId.substring(24)}',
            projectId: projectId,
            assetId: assetId,
            sketchId: sketchId,
            provenanceRevisionId: revisionId,
            sequence: 1,
            x: x,
            y: y,
            quantity: 2,
            createdAt: _now,
            endedAt: null,
            endReason: null,
            supersedesPlacementId: null,
          ),
  );
}
