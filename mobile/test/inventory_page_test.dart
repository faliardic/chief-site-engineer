import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/inventory/inventory_map_view.dart';
import 'package:chief_site_engineer/features/inventory/inventory_page.dart';
import 'package:chief_site_engineer/features/inventory/inventory_sketch_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _projectB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _sketchA = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _sketchB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
const _revisionA = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const _revisionB = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2';
const _revisionUpdated = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc3';
const _floorA = '99999999-9999-4999-8999-999999999991';
const _floorB = '99999999-9999-4999-8999-999999999992';
const _detachedBlockA = '88888888-8888-4888-8888-888888888881';
const _detachedBlockB = '88888888-8888-4888-8888-888888888882';
const _spatialBlockA = '88888888-8888-4888-8888-888888888883';
const _spatialBlockB = '88888888-8888-4888-8888-888888888884';
const _spatialFloorA1 = '99999999-9999-4999-8999-999999999993';
const _spatialFloorA2 = '99999999-9999-4999-8999-999999999994';
const _spatialFloorB1 = '99999999-9999-4999-8999-999999999995';
const _spatialFloorB2 = '99999999-9999-4999-8999-999999999996';
const _spatialFloorB3 = '99999999-9999-4999-8999-999999999997';
const _assetA = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';
const _assetB = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd2';
const _assetArchived = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd3';
const _assetMissing = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd4';
const _assetInvalid = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd5';
final _now = DateTime.parse('2026-08-28T08:00:00Z');

void main() {
  test(
    'shared context rejects late discovery and late scoped completions',
    () async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _sketch(_projectA)
        ..assets[_projectA] = [_asset(_projectA, _assetA)];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'A'), _project(_projectB, 'B')];
      final controller = _controller(inventory, source);
      addTearDown(controller.dispose);
      addTearDown(source.dispose);
      await controller.updateProjectContext(
        activeProjectId: _projectB,
        isActive: true,
      );
      final discovery = Completer<List<MobileProject>>();
      source.responses.add(discovery.future);
      final oldDiscovery = controller.initialize();
      await controller.updateProjectContext(
        activeProjectId: _projectA,
        isActive: true,
      );
      discovery.complete(source.projects);
      await oldDiscovery;
      expect(inventory.primaryProjectIds, [_projectA]);
      expect(controller.assets.single.asset.id, _assetA);

      final primary = Completer<InventoryPrimarySketchProjection?>();
      inventory.primaryResponses[_projectB] = [primary.future];
      final oldPrimary = controller.updateProjectContext(
        activeProjectId: _projectB,
        isActive: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(inventory.primaryProjectIds.last, _projectB);
      await controller.updateProjectContext(
        activeProjectId: _projectA,
        isActive: true,
      );
      primary.complete(_sketch(_projectB));
      await oldPrimary;
      expect(inventory.assetProjectIds, everyElement(_projectA));
      expect(controller.selectedProjectId, _projectA);
      expect(controller.sketch?.sketch.projectId, _projectA);
      expect(controller.assets.single.asset.id, _assetA);

      inventory.sketches[_projectB] = _sketch(_projectB);
      final assets = Completer<List<InventoryAssetProjection>>();
      inventory.assetResponses[_projectB] = [assets.future];
      final oldAssets = controller.updateProjectContext(
        activeProjectId: _projectB,
        isActive: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(inventory.assetProjectIds.last, _projectB);
      await controller.updateProjectContext(
        activeProjectId: _projectA,
        isActive: true,
      );
      assets.complete([_asset(_projectB, _assetB)]);
      await oldAssets;
      expect(controller.assets.single.asset.id, _assetA);
      expect(controller.selectedProjectId, _projectA);
      expect(inventory.mutations, 0);
    },
  );

  test(
    'null stale archived and undiscovered shared IDs remain inert',
    () async {
      final inventory = _FakeInventory();
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'A'), _project(_projectB, 'B')];
      final controller = _controller(inventory, source);
      addTearDown(controller.dispose);
      addTearDown(source.dispose);
      await controller.updateProjectContext(
        activeProjectId: null,
        isActive: true,
      );
      await controller.initialize();
      expect(
        controller.loadStatus,
        InventoryPageLoadStatus.projectSelectionRequired,
      );
      source.projects = [_project(_projectA, 'A')];
      await controller.refreshProjects();
      expect(
        controller.loadStatus,
        InventoryPageLoadStatus.projectSelectionRequired,
      );
      await controller.updateProjectContext(
        activeProjectId: _projectB,
        isActive: true,
      );
      expect(controller.lastErrorCode, 'inventory_project_unavailable');
      expect(controller.selectedProjectId, isNull);
      source.projects = const [
        MobileProject(
          id: _projectB,
          name: 'Archived',
          createdAt: '2026-08-28T08:00:00Z',
          updatedAt: '2026-08-28T08:00:00Z',
          revision: 2,
          archivedAt: '2026-08-29T08:00:00Z',
        ),
      ];
      await controller.refreshProjects();
      expect(controller.lastErrorCode, 'inventory_project_source_invalid');
      final failedDiscovery = Completer<List<MobileProject>>();
      source.responses.add(failedDiscovery.future);
      final loading = controller.updateProjectContext(
        activeProjectId: _projectA,
        isActive: true,
      );
      failedDiscovery.completeError(StateError('project discovery failed'));
      await loading;
      expect(controller.loadStatus, InventoryPageLoadStatus.failed);
      expect(inventory.primaryProjectIds, isEmpty);
      expect(inventory.assetProjectIds, isEmpty);
      expect(inventory.mutations, 0);
    },
  );

  testWidgets(
    'AppBar adoption waits for exact load and failed load retains prior shared project',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _sketch(_projectA)
        ..sketches[_projectB] = _sketch(_projectB)
        ..assets[_projectB] = [_asset(_projectB, _assetB)];
      final source = _ProjectSource()
        ..projects = [
          _project(_projectA, 'Proje A'),
          _project(_projectB, 'Proje B'),
        ];
      final shared = ValueNotifier<String?>(_projectB);
      final callbacks = <String>[];
      addTearDown(shared.dispose);
      addTearDown(source.dispose);
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        sharedProject: shared,
        onProjectSelected: callbacks.add,
      );
      expect(callbacks, isEmpty);
      expect(find.text('Aktif proje'), findsNothing);
      final pending = Completer<List<InventoryAssetProjection>>();
      inventory.assetResponses[_projectA] = [pending.future];
      await _chooseInventoryProject(tester, _projectA, settle: false);
      expect(inventory.assetProjectIds.last, _projectA);
      expect(shared.value, _projectB);
      expect(callbacks, isEmpty);
      pending.complete([_asset(_projectA, _assetA)]);
      await tester.pumpAndSettle();
      final state = tester.state<InventoryPageState>(
        find.byType(InventoryPage),
      );
      expect(state.controller.assets.single.asset.id, _assetA);
      expect(shared.value, _projectA);
      expect(callbacks, [_projectA]);

      final failed = Completer<InventoryPrimarySketchProjection?>();
      inventory.primaryResponses[_projectB] = [failed.future];
      await _chooseInventoryProject(tester, _projectB, settle: false);
      failed.completeError(
        const InventoryFailure('inventory_test_load_failed'),
      );
      await tester.pumpAndSettle();
      expect(shared.value, _projectA);
      expect(state.controller.selectedProjectId, _projectA);
      expect(state.controller.loadStatus, InventoryPageLoadStatus.failed);
      expect(state.controller.lastErrorCode, 'inventory_test_load_failed');
      expect(callbacks, [_projectA]);
      expect(inventory.mutations, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hidden Inventory ignores pending error and resumes latest external project',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _sketch(_projectA)
        ..assets[_projectA] = [_asset(_projectA, _assetA)];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'A'), _project(_projectB, 'B')];
      final shared = ValueNotifier<String?>(_projectB);
      final active = ValueNotifier(false);
      final callbacks = <String>[];
      addTearDown(shared.dispose);
      addTearDown(active.dispose);
      addTearDown(source.dispose);
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        sharedProject: shared,
        active: active,
        onProjectSelected: callbacks.add,
        settle: false,
      );
      expect(source.calls, 0);
      expect(inventory.reads, 0);
      final pending = Completer<InventoryPrimarySketchProjection?>();
      inventory.primaryResponses[_projectB] = [pending.future];
      active.value = true;
      await tester.pump();
      expect(inventory.primaryProjectIds, [_projectB]);
      active.value = false;
      shared.value = _projectA;
      await tester.pump();
      final discoveryCalls = source.calls;
      source.emit();
      pending.completeError(StateError('late hidden Inventory failure'));
      await tester.pump();
      expect(source.calls, discoveryCalls);
      expect(inventory.assetProjectIds, isEmpty);
      expect(callbacks, isEmpty);
      expect(inventory.mutations, 0);
      expect(tester.takeException(), isNull);
      active.value = true;
      await tester.pumpAndSettle();
      final controller = tester
          .state<InventoryPageState>(find.byType(InventoryPage))
          .controller;
      expect(controller.selectedProjectId, _projectA);
      expect(controller.assets.single.asset.id, _assetA);
      expect(inventory.primaryProjectIds, [_projectB, _projectA]);
      expect(callbacks, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

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
      final createdGeometry = _finalizedCreateGeometry();
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      var launches = 0;
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        sketchEditorLauncher: (context, projectId, launchIntent) async {
          launches += 1;
          expect(projectId, _projectA);
          expect(launchIntent, InventorySketchLaunchIntent.createOrRecover);
          inventory
            ..sketches[_projectA] = _sketch(
              _projectA,
              geometryOverride: createdGeometry,
            )
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
      final pageState = tester.state<InventoryPageState>(
        find.byType(InventoryPage),
      );
      expect(
        pageState.controller.sketch!.activeRevision!.geometry.canonicalJson,
        createdGeometry.canonicalJson,
      );
      expect(
        pageState.mapController!.activeRevision!.geometry.canonicalJson,
        createdGeometry.canonicalJson,
      );
    },
  );

  testWidgets(
    'ready sketch update is map-only, launches edit-active, and reloads successor',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _sketch(_projectA)
        ..assets[_projectA] = [];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      final controller = _controller(inventory, source);
      addTearDown(controller.dispose);
      addTearDown(source.dispose);
      var launches = 0;
      final successorGeometry = _editSuccessorGeometry();
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        controller: controller,
        sketchEditorLauncher: (context, projectId, launchIntent) async {
          launches += 1;
          expect(projectId, _projectA);
          expect(launchIntent, InventorySketchLaunchIntent.editActive);
          inventory.sketches[_projectA] = _sketch(
            _projectA,
            revisionId: _revisionUpdated,
            sketchRevision: 2,
            revisionNumber: 2,
            geometryOverride: successorGeometry,
          );
          return true;
        },
      );

      expect(find.text('Krokiyi güncelle'), findsNothing);
      expect(
        find.byKey(const Key('inventory-update-sketch')).hitTestable(),
        findsOneWidget,
      );
      expect(controller.view, InventoryPageView.map);
      expect(inventory.primaryReads, 1);

      await tester.tap(find.byKey(const Key('inventory-view-list')));
      await tester.pumpAndSettle();
      expect(controller.view, InventoryPageView.list);
      expect(find.byKey(const Key('inventory-update-sketch')), findsNothing);
      await tester.tap(find.byKey(const Key('inventory-view-floors')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-update-sketch')), findsNothing);
      await tester.tap(find.byKey(const Key('inventory-view-map')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory-update-sketch')));
      await tester.pumpAndSettle();

      expect(launches, 1);
      expect(controller.selectedProjectId, _projectA);
      expect(inventory.primaryReads, 2);
      expect(inventory.listReads, 2);
      expect(controller.sketch!.activeRevision!.id, _revisionUpdated);
      expect(
        controller.sketch!.activeRevision!.geometry.canonicalJson,
        successorGeometry.canonicalJson,
      );
      final pageState = tester.state<InventoryPageState>(
        find.byType(InventoryPage),
      );
      expect(
        pageState.mapController!.activeRevision!.geometry.canonicalJson,
        successorGeometry.canonicalJson,
      );
      expect(
        pageState.mapController!.activeRevision!.geometry.polylines,
        hasLength(2),
      );
    },
  );

  testWidgets(
    'Kroki and Liste share exact identities and all filters are projection-only',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _activeMappedSketch(_projectA)
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
      await tester.tap(find.byKey(const Key('inventory-filters-tool')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-category-all')), findsOneWidget);
      expect(find.byKey(const Key('inventory-status-all')), findsOneWidget);
      expect(find.byKey(const Key('inventory-archive-active')), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Kapat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-search-tool')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-search')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('inventory-search')),
        '  KULE   VİNÇ ',
      );
      await tester.pump();
      expect(map.projections.single, same(controller.assets[0]));
      expect(inventory.mutations, 0);
      await tester.tap(find.widgetWithText(TextButton, 'Kapat'));
      await tester.pumpAndSettle();

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
    expect(find.byKey(const Key('inventory-map-empty')), findsOneWidget);
    emptyController.setView(InventoryPageView.list);
    await tester.pump();
    expect(find.byKey(const Key('inventory-empty')), findsOneWidget);

    final populated = _FakeInventory()
      ..sketches[_projectA] = _activeMappedSketch(_projectA)
      ..assets[_projectA] = [_asset(_projectA, _assetA)];
    final populatedController = _controller(populated, source);
    addTearDown(populatedController.dispose);
    await _pumpPage(
      tester,
      inventory: populated,
      source: source,
      controller: populatedController,
    );
    populatedController.setSearch('eşleşmeyen');
    await tester.pump();
    expect(find.byKey(const Key('inventory-map-empty-filter')), findsOneWidget);
    populatedController.setView(InventoryPageView.list);
    await tester.pump();
    expect(find.byKey(const Key('inventory-empty-search')), findsOneWidget);

    final failed = _FakeInventory()
      ..sketches[_projectA] = _sketch(_projectA)
      ..listFailure = const InventoryFailure('inventory_test_load_failed');
    await _pumpPage(tester, inventory: failed, source: source);
    expect(find.byKey(const Key('inventory-load-failure')), findsOneWidget);
    expect(find.textContaining('inventory_test_load_failed'), findsOneWidget);
  });

  testWidgets('large text keeps critical Inventory controls usable', (
    tester,
  ) async {
    final inventory = _FakeInventory()
      ..sketches[_projectA] = _spatialSketch()
      ..assets[_projectA] = [
        _asset(_projectA, _assetA, floorId: _spatialFloorA1, x: 256, y: 256),
      ];
    final source = _ProjectSource()
      ..projects = [_project(_projectA, 'Proje A')];

    await _pumpPage(
      tester,
      inventory: inventory,
      source: source,
      textScale: 2.5,
    );

    expect(find.byKey(const Key('inventory-search-tool')), findsOneWidget);
    expect(find.byKey(const Key('inventory-update-sketch')), findsOneWidget);
    expect(find.byKey(const Key('inventory-view-switch')), findsOneWidget);
    expect(find.byKey(const Key('inventory-marker-$_assetA')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inventory-view-floors')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inventory-floor-view')), findsOneWidget);
    expect(
      find.byKey(const Key('inventory-floor-row-$_spatialFloorB3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '586 narrow rails expose bounded exact context without mutations',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final inventory = _FakeInventory()
          ..sketches[_projectA] = _spatialSketch()
          ..assets[_projectA] = [
            _asset(
              _projectA,
              _assetA,
              floorId: _spatialFloorA1,
              x: 256,
              y: 256,
            ),
          ];
        final source = _ProjectSource()
          ..projects = [_project(_projectA, 'Proje A')];
        final controller = _controller(inventory, source);
        addTearDown(source.dispose);
        addTearDown(controller.dispose);
        await _pumpPage(
          tester,
          inventory: inventory,
          source: source,
          controller: controller,
          textScale: 1.6,
        );

        final views = ['map', 'floors', 'list'];
        for (var i = 0; i < views.length; i++) {
          final control = find.byKey(ValueKey('inventory-view-${views[i]}'));
          expect(control.hitTestable(), findsOneWidget);
          expect(tester.getSize(control), const Size(44, 44));
          expect(
            tester
                .getSemantics(control)
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            i == 0 ? Tristate.isTrue : Tristate.isFalse,
          );
          if (i > 0) {
            expect(
              tester.getTopLeft(control).dy,
              greaterThan(
                tester
                    .getTopLeft(
                      find.byKey(ValueKey('inventory-view-${views[i - 1]}')),
                    )
                    .dy,
              ),
            );
          }
        }
        for (final name in [
          'search-tool',
          'block-tool',
          'floor-tool',
          'filters-tool',
          'map-zoom-in',
          'map-zoom-out',
          'map-fit',
          'update-sketch',
        ]) {
          final control = find.byKey(Key('inventory-$name'));
          expect(control.hitTestable(), findsOneWidget);
          expect(tester.getSize(control), const Size(44, 44));
          expect(
            tester
                .getSemantics(control)
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            Tristate.none,
          );
          expect(
            find.descendant(of: control, matching: find.byType(Tooltip)),
            findsOneWidget,
          );
        }
        final floorTool = find.byKey(const Key('inventory-floor-tool'));
        expect(tester.widget<Semantics>(floorTool).properties.enabled, isFalse);
        await tester.tap(floorTool);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('inventory-tool-panel')), findsNothing);

        await tester.tap(find.byKey(const Key('inventory-block-tool')));
        await tester.pumpAndSettle();
        expect(controller.selectedBlockId, isNull);
        // Measure the visible card, not the dialog's route-sized layout shell.
        final panelSurface = find.descendant(
          of: find.byKey(const Key('inventory-tool-panel')),
          matching: find.byWidgetPredicate(
            (widget) => widget is Material && widget.type == MaterialType.card,
          ),
        );
        expect(panelSurface, findsOneWidget);
        expect(panelSurface.hitTestable(), findsOneWidget);
        final logicalViewport =
            tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(
          tester.getSize(panelSurface).height,
          lessThan(logicalViewport.height),
        );
        await tester.tap(find.byKey(const Key('inventory-block-selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('A Blok').last);
        await tester.pumpAndSettle();
        expect(controller.selectedBlockId, _spatialBlockA);
        await tester.tap(find.widgetWithText(TextButton, 'Kapat'));
        await tester.pumpAndSettle();
        expect(tester.widget<Semantics>(floorTool).properties.enabled, isTrue);
        await tester.tap(floorTool);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('inventory-floor-selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('A 1. Kat').last);
        await tester.pumpAndSettle();
        expect(controller.selectedFloorId, _spatialFloorA1);
        await tester.tap(find.widgetWithText(TextButton, 'Kapat'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Semantics>(floorTool).properties.label,
          'Kat: A 1. Kat',
        );

        await tester.tap(find.byKey(const Key('inventory-filters-tool')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('inventory-category-all')), findsOneWidget);
        expect(find.byKey(const Key('inventory-status-all')), findsOneWidget);
        expect(
          find.byKey(const Key('inventory-archive-active')),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Kapat'));
        await tester.pumpAndSettle();
        expect(controller.categoryFilter, isNull);
        expect(controller.statusFilter, isNull);
        expect(controller.archiveFilter, InventoryArchiveFilter.active);
        expect(controller.selectedProjectId, _projectA);
        expect(controller.selectedBlockId, _spatialBlockA);
        expect(controller.selectedFloorId, _spatialFloorA1);
        expect(inventory.mutations, 0);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    '586 real gestures hide hit targets then restore without viewport movement',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _activeMappedSketch(_projectA)
        ..assets[_projectA] = [_asset(_projectA, _assetA)];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      final controller = _controller(inventory, source);
      addTearDown(source.dispose);
      addTearDown(controller.dispose);
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        controller: controller,
      );
      final page = tester.state<InventoryPageState>(find.byType(InventoryPage));
      final map = find.byKey(const Key('inventory-map-gesture'));
      final rect = tester.getRect(map);
      final controls = [
        'inventory-view-map',
        'inventory-search-tool',
        'inventory-update-sketch',
      ];
      Future<void> expectHidden() async {
        for (final key in controls) {
          expect(find.byKey(Key(key)).hitTestable(), findsNothing);
        }
        expect(tester.getRect(map), rect);
        expect(find.byType(AppBar).hitTestable(), findsOneWidget);
      }

      final gesture = await tester.startGesture(rect.center);
      await gesture.moveBy(const Offset(50, 30));
      await tester.pump();
      await expectHidden();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 599));
      await expectHidden();
      // A second real movement must cancel the first idle deadline.
      final first = await tester.startGesture(
        rect.center - const Offset(40, 0),
        pointer: 2,
      );
      final second = await tester.startGesture(
        rect.center + const Offset(40, 0),
        pointer: 3,
      );
      await first.moveBy(const Offset(-35, 0));
      await second.moveBy(const Offset(35, 0));
      await tester.pump(const Duration(milliseconds: 10));
      await expectHidden();
      await first.up();
      await second.up();
      final viewport = page.mapViewState!.viewport!;
      await tester.pump(const Duration(milliseconds: 599));
      await expectHidden();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 150));
      for (final key in controls) {
        expect(find.byKey(Key(key)).hitTestable(), findsOneWidget);
      }
      expect(page.mapViewState!.viewport!.pan, viewport.pan);
      expect(page.mapViewState!.viewport!.zoom, viewport.zoom);
      expect(tester.getRect(map), rect);
      expect(inventory.mutations, 0);
      expect(inventory.primaryReads, 1);

      final last = await tester.startGesture(rect.center);
      await last.moveBy(const Offset(40, 0));
      await tester.pump();
      await last.up();
      controller.setView(InventoryPageView.list);
      await tester.pump();
      expect(
        find.byKey(const Key('inventory-view-map')).hitTestable(),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('marker opens exact existing asset detail identity', (
    tester,
  ) async {
    final inventory = _FakeInventory()
      ..sketches[_projectA] = _activeMappedSketch(_projectA)
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
    'real detail move selects map target confirms and canonical reloads',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _activeMappedSketch(_projectA)
        ..assets[_projectA] = [_asset(_projectA, _assetA)];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      await _pumpPage(tester, inventory: inventory, source: source);
      final readsBeforeMutation = inventory.listReads;

      await tester.tap(find.byKey(const Key('inventory-marker-$_assetA')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-asset-detail')), findsOneWidget);
      await tester.tap(find.byKey(const Key('inventory-detail-move')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-target-selection')),
        findsOneWidget,
      );

      await _tapMapTarget(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-quick-form')), findsNothing);
      expect(find.byKey(const Key('inventory-asset-detail')), findsOneWidget);
      final confirm = tester.widget<FilledButton>(
        find.byKey(const Key('inventory-detail-move-confirm')),
      );
      expect(confirm.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('inventory-detail-move-confirm')));
      await tester.pumpAndSettle();
      expect(inventory.moveCalls, 1);
      expect(inventory.lastMove?.projectId, _projectA);
      expect(inventory.lastMove?.assetId, _assetA);
      expect(inventory.mutations, 1);
      expect(inventory.listReads, greaterThan(readsBeforeMutation));
      final moved = inventory.assets[_projectA]!.single.activePlacement!;
      expect(moved.x, inventory.lastMove!.x);
      expect(moved.y, inventory.lastMove!.y);
      expect(moved.x == 100 && moved.y == 100, isFalse);
      expect(tester.takeException(), isNull);

      await _dismissDetail(tester);
    },
  );

  testWidgets('real detail move target cancellation performs no mutation', (
    tester,
  ) async {
    final inventory = _FakeInventory()
      ..sketches[_projectA] = _activeMappedSketch(_projectA)
      ..assets[_projectA] = [_asset(_projectA, _assetA)];
    final source = _ProjectSource()
      ..projects = [_project(_projectA, 'Proje A')];
    await _pumpPage(tester, inventory: inventory, source: source);

    await tester.tap(find.byKey(const Key('inventory-marker-$_assetA')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inventory-detail-move')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('inventory-target-selection-cancel')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory-asset-detail')), findsOneWidget);
    expect(
      find.byKey(const Key('inventory-detail-move-confirm')),
      findsNothing,
    );
    expect(inventory.moveCalls, 0);
    expect(inventory.mutations, 0);
    expect(tester.takeException(), isNull);

    await _dismissDetail(tester);
  });

  testWidgets(
    'project switch cancels pending real-detail target and isolates new project',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches.addAll({
          _projectA: _activeMappedSketch(_projectA),
          _projectB: _activeMappedSketch(_projectB),
        })
        ..assets.addAll({
          _projectA: [_asset(_projectA, _assetA, name: 'Kule vinç A')],
          _projectB: [_asset(_projectB, _assetB, name: 'Lazer metre B')],
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
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory-marker-$_assetA')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-detail-move')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-target-selection')),
        findsOneWidget,
      );

      await _chooseInventoryProject(tester, _projectB);

      expect(find.byKey(const Key('inventory-target-selection')), findsNothing);
      expect(inventory.moveCalls, 0);
      expect(inventory.mutations, 0);
      expect(controller.selectedProjectId, _projectB);
      expect(controller.assets.single.asset.id, _assetB);
      final pageState = tester.state<InventoryPageState>(
        find.byType(InventoryPage),
      );
      expect(pageState.mapController?.projections.single.asset.id, _assetB);
      expect(find.byKey(const Key('inventory-marker-$_assetA')), findsNothing);
      expect(
        find.byKey(const Key('inventory-marker-$_assetB')),
        findsOneWidget,
      );

      controller.setView(InventoryPageView.list);
      await tester.pump();
      expect(find.byKey(const Key('inventory-list-$_assetB')), findsOneWidget);
      expect(find.byKey(const Key('inventory-list-$_assetA')), findsNothing);
      controller.setView(InventoryPageView.map);
      await tester.pump();
      await tester.tap(find.byKey(const Key('inventory-marker-$_assetB')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-asset-detail')), findsOneWidget);
      expect(find.text('Lazer metre B'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _dismissDetail(tester);
    },
  );

  testWidgets(
    'archived row opens real detail and unarchives through map target',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _activeMappedSketch(_projectA)
        ..assets[_projectA] = [
          _asset(_projectA, _assetArchived, archived: true),
        ]
        ..seedArchivedPlacement(_projectA, _assetArchived);
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
      controller
        ..setArchiveFilter(InventoryArchiveFilter.archived)
        ..setView(InventoryPageView.list);
      await tester.pump();
      final readsBeforeMutation = inventory.listReads;

      await tester.tap(find.byKey(const Key('inventory-list-$_assetArchived')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-asset-detail')), findsOneWidget);
      await tester.tap(find.byKey(const Key('inventory-detail-unarchive')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-target-selection')),
        findsOneWidget,
      );

      await _tapMapTarget(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-quick-form')), findsNothing);
      final confirm = tester.widget<FilledButton>(
        find.byKey(const Key('inventory-detail-unarchive-confirm')),
      );
      expect(confirm.onPressed, isNotNull);
      await tester.tap(
        find.byKey(const Key('inventory-detail-unarchive-confirm')),
      );
      await tester.pumpAndSettle();

      expect(inventory.unarchiveCalls, 1);
      expect(inventory.lastUnarchive?.projectId, _projectA);
      expect(inventory.lastUnarchive?.assetId, _assetArchived);
      expect(inventory.mutations, 1);
      expect(inventory.listReads, greaterThan(readsBeforeMutation));
      final recovered = inventory.assets[_projectA]!.single;
      expect(recovered.asset.archivedAt, isNull);
      expect(recovered.activePlacement, isNotNull);
      expect(recovered.activePlacement!.x, inventory.lastUnarchive!.x);
      expect(recovered.activePlacement!.y, inventory.lastUnarchive!.y);
      expect(tester.takeException(), isNull);

      await _dismissDetail(tester);
    },
  );

  testWidgets(
    'list row centers exact placement and highlights for two seconds',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches.addAll({
          _projectA: _activeMappedSketch(_projectA),
          _projectB: _activeMappedSketch(_projectB),
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
    'invalid full active projection fails Kroki closed without partial markers',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _activeMappedSketch(_projectA)
        ..assets[_projectA] = [
          _asset(_projectA, _assetA),
          _asset(_projectA, _assetMissing, placement: false),
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

      expect(controller.activeBlocks.single.state, InventoryBlockState.active);
      expect(controller.canonicalActiveMapAssets, hasLength(2));
      expect(controller.view, InventoryPageView.list);
      expect(
        controller.lastDiagnosticCode,
        'inventory_projection_integrity_failed',
      );
      expect(
        pageState.mapController?.loadStatus,
        InventoryMapLoadStatus.failed,
      );
      expect(pageState.mapController?.projections, isEmpty);
      expect(find.byKey(const Key('inventory-list-$_assetA')), findsOneWidget);
      expect(
        find.byKey(const Key('inventory-list-$_assetMissing')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inventory-marker-$_assetA')), findsNothing);
      expect(
        find.byKey(const Key('inventory-typed-diagnostic')),
        findsOneWidget,
      );
      expect(
        find.textContaining('inventory_projection_integrity_failed'),
        findsOneWidget,
      );

      controller.setSearch('Kule vinç');
      await tester.pump();
      expect(pageState.mapController?.projections, isEmpty);
      expect(inventory.mutations, 0);
    },
  );

  testWidgets(
    'missing invalid and corrupt geometry stay in Liste with typed failure',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _activeMappedSketch(_projectA)
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

  testWidgets(
    'AT-533-009 detached asset stays Liste with exact label and typed focus failure',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _sketch(_projectA)
        ..assets[_projectA] = [_asset(_projectA, _assetA)];
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

      expect(controller.visibleAssets.single.asset.id, _assetA);
      expect(controller.canonicalActiveMapAssets, isEmpty);
      expect(controller.visibleMapAssets, isEmpty);
      expect(pageState.mapController?.projections, isEmpty);
      expect(find.byKey(const Key('inventory-marker-$_assetA')), findsNothing);
      expect(controller.canFocus(controller.assets.single), isFalse);
      expect(
        controller.focusFailureCode(controller.assets.single),
        'inventory_block_detached',
      );

      controller.setView(InventoryPageView.list);
      await tester.pump();
      expect(
        find.byKey(const Key('inventory-list-detached-$_assetA')),
        findsOneWidget,
      );
      expect(find.text('Krokisi kaldırılmış blok'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory-list-detached-context-$_assetA')),
        findsOneWidget,
      );
      expect(find.text('Eski alan · 1. Kat'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory-list-spatial-$_assetA')),
        findsNothing,
      );
      expect(find.text('Kule vinç · Eski alan · 1. Kat'), findsNothing);
      expect(find.byIcon(Icons.link_off_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('inventory-list-$_assetA')));
      await tester.pump();
      expect(controller.view, InventoryPageView.list);
      expect(controller.lastDiagnosticCode, 'inventory_block_detached');
      expect(
        find.byKey(const Key('inventory-typed-diagnostic')),
        findsOneWidget,
      );
      expect(find.textContaining('inventory_block_detached'), findsOneWidget);
      expect(pageState.mapController?.projections, isEmpty);
      expect(find.byKey(const Key('inventory-marker-$_assetA')), findsNothing);
      expect(inventory.mutations, 0);
    },
  );

  testWidgets(
    'AT-531-001/002 Kat Görünümü keeps stable stacks and exact active counts',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _spatialSketch()
        ..assets[_projectA] = [
          _asset(_projectA, _assetA, floorId: _spatialFloorA1, x: 256, y: 256),
          _asset(_projectA, _assetB, floorId: _spatialFloorA2, x: 512, y: 512),
          _asset(
            _projectA,
            _assetInvalid,
            floorId: _spatialFloorB3,
            x: 2304,
            y: 256,
          ),
          _asset(
            _projectA,
            _assetArchived,
            archived: true,
            floorId: _spatialFloorA1,
          ),
        ];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      await _pumpPage(tester, inventory: inventory, source: source);

      await tester.tap(find.byKey(const Key('inventory-view-floors')));
      await tester.pumpAndSettle();

      final blockA = find.byKey(
        const Key('inventory-floor-block-$_spatialBlockA'),
      );
      final blockB = find.byKey(
        const Key('inventory-floor-block-$_spatialBlockB'),
      );
      expect(blockA, findsOneWidget);
      expect(blockB, findsOneWidget);
      expect(
        tester.getTopLeft(blockA).dx,
        lessThan(tester.getTopLeft(blockB).dx),
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const Key('inventory-floor-row-$_spatialFloorA2')),
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const Key('inventory-floor-row-$_spatialFloorA1')),
              )
              .dy,
        ),
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('inventory-floor-project-total')),
            )
            .data,
        'Proje toplamı: 3 kayıt',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const Key('inventory-floor-block-total-$_spatialBlockA'),
              ),
            )
            .data,
        '2 kayıt',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('inventory-floor-count-$_spatialFloorB3')),
            )
            .data,
        '1 kayıt',
      );
      expect(inventory.mutations, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AT-531-003/004 floor navigation isolates markers and block clears stale floor',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _spatialSketch()
        ..assets[_projectA] = [
          _asset(_projectA, _assetA, floorId: _spatialFloorA1, x: 256, y: 256),
          _asset(_projectA, _assetB, floorId: _spatialFloorA2, x: 512, y: 512),
          _asset(
            _projectA,
            _assetInvalid,
            floorId: _spatialFloorB1,
            x: 2304,
            y: 256,
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

      controller.setView(InventoryPageView.floors);
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('inventory-floor-map-$_spatialFloorA1')),
      );
      await tester.pumpAndSettle();

      expect(controller.view, InventoryPageView.map);
      expect(controller.selectedBlockId, _spatialBlockA);
      expect(controller.selectedFloorId, _spatialFloorA1);
      expect(
        find.byKey(const Key('inventory-marker-$_assetA')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inventory-marker-$_assetB')), findsNothing);
      expect(
        find.byKey(const Key('inventory-marker-$_assetInvalid')),
        findsNothing,
      );

      controller.setBlockSelection(_spatialBlockB);
      await tester.pump();
      expect(controller.selectedFloorId, isNull);
      expect(
        find.byKey(const Key('inventory-marker-$_assetInvalid')),
        findsOneWidget,
      );
      controller.setFloorSelection(_spatialFloorA1);
      await tester.pump();
      expect(controller.selectedFloorId, isNull);
      expect(
        controller.lastDiagnosticCode,
        'inventory_spatial_context_unavailable',
      );
      expect(inventory.mutations, 0);
    },
  );

  testWidgets(
    'AT-531-005 spatial labels and filters compose without archived floor invention',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _spatialSketch()
        ..assets[_projectA] = [
          _asset(
            _projectA,
            _assetA,
            name: 'Kule vinç',
            floorId: _spatialFloorA1,
            x: 256,
            y: 256,
          ),
          _asset(
            _projectA,
            _assetB,
            name: 'Lazer metre',
            category: InventoryCategory.measurementDevice,
            floorId: _spatialFloorA2,
            x: 512,
            y: 512,
          ),
          _asset(
            _projectA,
            _assetInvalid,
            name: 'B matkabı',
            floorId: _spatialFloorB1,
            x: 2304,
            y: 256,
          ),
          _asset(
            _projectA,
            _assetArchived,
            name: 'Arşiv kaydı',
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

      controller.setView(InventoryPageView.list);
      await tester.pump();
      expect(find.text('Kule vinç · A Blok · A 1. Kat'), findsOneWidget);
      expect(
        find.byKey(const Key('inventory-list-spatial-$_assetArchived')),
        findsNothing,
      );

      controller.setBlockSelection(_spatialBlockA);
      await tester.pump();
      expect(find.byKey(const Key('inventory-list-$_assetA')), findsOneWidget);
      expect(find.byKey(const Key('inventory-list-$_assetB')), findsOneWidget);
      expect(
        find.byKey(const Key('inventory-list-$_assetInvalid')),
        findsNothing,
      );
      controller.setFloorSelection(_spatialFloorA2);
      controller.setCategoryFilter(InventoryCategory.measurementDevice);
      controller.setSearch('Lazer');
      await tester.pump();
      expect(find.byKey(const Key('inventory-list-$_assetB')), findsOneWidget);
      expect(find.byKey(const Key('inventory-list-$_assetA')), findsNothing);

      controller
        ..setSearch('')
        ..setCategoryFilter(null)
        ..setBlockSelection(null)
        ..setArchiveFilter(InventoryArchiveFilter.archived);
      await tester.pump();
      expect(
        find.byKey(const Key('inventory-list-$_assetArchived')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inventory-list-spatial-$_assetArchived')),
        findsNothing,
      );
      expect(inventory.mutations, 0);
    },
  );

  testWidgets(
    'AT-531-006 list focus selects exact block floor before existing cue',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _spatialSketch()
        ..assets[_projectA] = [
          _asset(_projectA, _assetA, floorId: _spatialFloorA1, x: 256, y: 256),
          _asset(_projectA, _assetB, floorId: _spatialFloorB2, x: 3008, y: 768),
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

      await tester.tap(find.byKey(const Key('inventory-list-$_assetB')));
      await tester.pump();

      expect(controller.view, InventoryPageView.map);
      expect(controller.selectedBlockId, _spatialBlockB);
      expect(controller.selectedFloorId, _spatialFloorB2);
      expect(find.byKey(const Key('inventory-marker-$_assetA')), findsNothing);
      expect(
        find.byKey(const Key('inventory-marker-$_assetB')),
        findsOneWidget,
      );
      final pageState = tester.state<InventoryPageState>(
        find.byType(InventoryPage),
      );
      expect(pageState.mapViewState?.highlightedAssetId, _assetB);
      await tester.pump(const Duration(milliseconds: 2100));
      expect(pageState.mapViewState?.highlightedAssetId, isNull);
      expect(inventory.mutations, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AT-531-007/008 floor plus uses exact floor and deterministic safe spread',
    (tester) async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _spatialSketch()
        ..assets[_projectA] = [
          _asset(_projectA, _assetA, floorId: _spatialFloorA1, x: 256, y: 256),
        ];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      final controller = _controller(inventory, source);
      addTearDown(controller.dispose);
      final opened = <String>[];
      await _pumpPage(
        tester,
        inventory: inventory,
        source: source,
        controller: controller,
        assetDetailLauncher: (context, projectId, assetId) async {
          expect(projectId, _projectA);
          opened.add(assetId);
        },
      );
      controller.setView(InventoryPageView.floors);
      await tester.pump();

      Future<CreateInventoryAssetCommand> create(String name) async {
        await tester.tap(
          find.byKey(const Key('inventory-floor-create-$_spatialFloorA1')),
        );
        await tester.pumpAndSettle();
        expect(find.text('A Blok · A 1. Kat'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('inventory-quick-name')),
          name,
        );
        await tester.tap(find.byKey(const Key('inventory-quick-category')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Makine / ekipman').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('inventory-quick-submit')));
        await tester.pumpAndSettle();
        return inventory.lastCreate!;
      }

      final first = await create('Kat aracı 1');
      expect(first.floorId, _spatialFloorA1);
      expect(
        InventorySpatialContract.strictlyContainsPlacement(
          _spatialSketch().activeRevision!.geometry.polylines.first,
          x: first.x,
          y: first.y,
        ),
        isTrue,
      );
      final second = await create('Kat aracı 2');
      expect(second.floorId, _spatialFloorA1);
      expect((second.x, second.y), isNot((first.x, first.y)));
      expect(second.x % InventoryGeometryContract.placementStep, 0);
      expect(second.y % InventoryGeometryContract.placementStep, 0);
      expect(
        InventorySpatialContract.strictlyContainsPlacement(
          _spatialSketch().activeRevision!.geometry.polylines.first,
          x: second.x,
          y: second.y,
        ),
        isTrue,
      );
      expect(inventory.createCalls, 2);
      expect(opened, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'AT-531-009 detached or unmapped floor has no safe create write',
    () async {
      final inventory = _FakeInventory()
        ..sketches[_projectA] = _sketch(_projectA)
        ..assets[_projectA] = [];
      final source = _ProjectSource()
        ..projects = [_project(_projectA, 'Proje A')];
      final controller = _controller(inventory, source);
      addTearDown(controller.dispose);
      addTearDown(source.dispose);
      await controller.initialize();

      expect(
        () => controller.safeCreateTargetForFloor(
          blockId: _detachedBlockA,
          floorId: _floorA,
        ),
        throwsA(
          isA<InventoryFailure>().having(
            (failure) => failure.code,
            'code',
            'inventory_safe_interior_unavailable',
          ),
        ),
      );
      expect(
        () => controller.safeCreateTargetForFloor(
          blockId: _spatialBlockA,
          floorId: _spatialFloorA1,
        ),
        throwsA(
          isA<InventoryFailure>().having(
            (failure) => failure.code,
            'code',
            'inventory_safe_interior_unavailable',
          ),
        ),
      );

      final spatial = _spatialSketch();
      final unmappedController = _controller(inventory, source)
        ..selectedProjectId = _projectA
        ..sketch = InventoryPrimarySketchProjection(
          sketch: spatial.sketch,
          activeRevision: spatial.activeRevision,
          draftRevision: spatial.draftRevision,
          blocks: spatial.blocks,
          floors: spatial.floors,
        )
        ..assets = const [];
      addTearDown(unmappedController.dispose);
      expect(
        () => unmappedController.safeCreateTargetForFloor(
          blockId: _spatialBlockA,
          floorId: _spatialFloorA1,
        ),
        throwsA(
          isA<InventoryFailure>().having(
            (failure) => failure.code,
            'code',
            'inventory_safe_interior_unavailable',
          ),
        ),
      );
      expect(inventory.createCalls, 0);
      expect(inventory.mutations, 0);
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
  double textScale = 1,
  ValueNotifier<String?>? sharedProject,
  ValueNotifier<bool>? active,
  ValueChanged<String>? onProjectSelected,
  bool settle = true,
}) async {
  final selection =
      sharedProject ??
      ValueNotifier<String?>(
        source.projects.length == 1 ? source.projects.single.id : null,
      );
  final visibility = active ?? ValueNotifier(true);
  if (sharedProject == null) addTearDown(selection.dispose);
  if (active == null) addTearDown(visibility.dispose);
  final pageKey = GlobalKey<InventoryPageState>();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ListenableBuilder(
        listenable: Listenable.merge([selection, visibility]),
        builder: (context, child) => Scaffold(
          appBar: AppBar(
            actions: [
              ActiveProjectControl(
                label:
                    source.projects
                        .where((p) => p.id == selection.value)
                        .firstOrNull
                        ?.name ??
                    'Proje seçilmedi',
                projects: source.projects.where((p) => !p.isArchived).toList(),
                onSelected: (id) =>
                    unawaited(pageKey.currentState!.selectProject(id)),
              ),
            ],
          ),
          body: InventoryPage(
            key: pageKey,
            application: inventory,
            listProjects: source.list,
            projectChanges: source.changes,
            activeProjectId: selection.value,
            isActive: visibility.value,
            onProjectSelected: (id) {
              selection.value = id;
              onProjectSelected?.call(id);
            },
            controller: controller,
            sketchEditorLauncher: sketchEditorLauncher,
            assetDetailLauncher: assetDetailLauncher,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

Future<void> _chooseInventoryProject(
  WidgetTester tester,
  String id, {
  bool settle = true,
}) async {
  final control = find
      .byKey(const Key('active-project-indicator'))
      .hitTestable();
  expect(control, findsOneWidget);
  await tester.tap(control);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final option = find
      .byKey(ValueKey('active-project-option-$id'))
      .hitTestable();
  expect(option, findsOneWidget);
  await tester.tap(option);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  if (settle) await tester.pumpAndSettle();
}

Future<void> _tapMapTarget(WidgetTester tester) async {
  final gesture = find.byKey(const Key('inventory-map-gesture'));
  expect(gesture, findsOneWidget);
  await tester.tapAt(tester.getCenter(gesture));
}

Future<void> _dismissDetail(WidgetTester tester) async {
  await tester.tapAt(const Offset(4, 4));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('inventory-asset-detail')), findsNothing);
}

class _ProjectSource {
  List<MobileProject> projects = const [];
  final List<Future<List<MobileProject>>> responses = [];
  int calls = 0;
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;
  Future<List<MobileProject>> list() async {
    calls += 1;
    if (responses.isNotEmpty) return responses.removeAt(0);
    return List.unmodifiable(projects);
  }

  void emit() => _changes.add(null);
  void dispose() => _changes.close();
}

class _FakeInventory extends UnavailableInventoryApplication {
  final Map<String, List<Future<InventoryPrimarySketchProjection?>>>
  primaryResponses = {};
  final Map<String, List<Future<List<InventoryAssetProjection>>>>
  assetResponses = {};
  final List<String> primaryProjectIds = [];
  final List<String> assetProjectIds = [];
  final Map<String, InventoryPrimarySketchProjection?> sketches = {};
  final Map<String, List<InventoryAssetProjection>> assets = {};
  final Map<String, List<InventoryPlacementRecord>> placementVersions = {};
  Object? primaryFailure;
  Object? listFailure;
  int primaryReads = 0;
  int listReads = 0;
  int mutations = 0;
  int moveCalls = 0;
  int unarchiveCalls = 0;
  int createCalls = 0;
  CreateInventoryAssetCommand? lastCreate;
  MoveInventoryPlacementCommand? lastMove;
  UnarchiveInventoryAssetCommand? lastUnarchive;

  int get reads => primaryReads + listReads;

  void seedArchivedPlacement(String projectId, String assetId) {
    placementVersions[assetId] = [
      _placement(
        projectId,
        assetId,
        endedAt: _now.add(const Duration(minutes: 1)),
        endReason: InventoryPlacementEndReason.assetArchived,
      ),
    ];
  }

  @override
  Future<InventoryPrimarySketchProjection?> loadPrimarySketch(
    String projectId,
  ) async {
    primaryReads += 1;
    primaryProjectIds.add(projectId);
    final responses = primaryResponses[projectId];
    if (responses != null && responses.isNotEmpty) return responses.removeAt(0);
    if (primaryFailure case final error?) throw error;
    return sketches[projectId];
  }

  @override
  Future<List<InventoryAssetProjection>> listAssets({
    required String projectId,
    bool includeArchived = false,
  }) async {
    listReads += 1;
    assetProjectIds.add(projectId);
    final responses = assetResponses[projectId];
    if (responses != null && responses.isNotEmpty) return responses.removeAt(0);
    if (listFailure case final error?) throw error;
    final values = assets[projectId] ?? const [];
    return List.unmodifiable(
      includeArchived
          ? values
          : values.where((item) => item.asset.archivedAt == null),
    );
  }

  @override
  Future<InventoryAssetProjection> loadAsset({
    required String projectId,
    required String assetId,
  }) async {
    final projection = _projection(projectId, assetId);
    if (projection == null) {
      throw const InventoryFailure('inventory_asset_not_found');
    }
    return projection;
  }

  @override
  Future<List<InventoryEventRecord>> listAssetHistory({
    required String projectId,
    required String assetId,
  }) async {
    final projection = _projection(projectId, assetId);
    if (projection == null) {
      throw const InventoryFailure('inventory_asset_not_found');
    }
    final key =
        projection.activePlacement?.placementKey ??
        placementVersions[assetId]?.last.placementKey;
    if (key == null) {
      throw const InventoryFailure('inventory_placement_history_unavailable');
    }
    return [_placementEvent(projectId, assetId, key)];
  }

  @override
  Future<List<InventoryPlacementRecord>> listPlacementVersions({
    required String projectId,
    required String assetId,
    required String placementKey,
  }) async {
    final projection = _projection(projectId, assetId);
    if (projection == null) {
      throw const InventoryFailure('inventory_asset_not_found');
    }
    final stored = placementVersions[assetId];
    final values =
        stored ?? <InventoryPlacementRecord>[?projection.activePlacement];
    if (values.isEmpty ||
        values.any(
          (placement) =>
              placement.projectId != projectId ||
              placement.assetId != assetId ||
              placement.placementKey != placementKey,
        )) {
      throw const InventoryFailure('inventory_placement_not_found');
    }
    return List.unmodifiable(values);
  }

  @override
  Future<InventoryMutationResult> createAsset(
    CreateInventoryAssetCommand command,
  ) async {
    createCalls += 1;
    mutations += 1;
    lastCreate = command;
    final projection = InventoryAssetProjection(
      asset: InventoryAssetRecord(
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
        createdAt: _now,
        updatedAt: _now,
        statusChangedAt: _now,
        archivedAt: null,
      ),
      activePlacement: InventoryPlacementRecord(
        id: command.placementId,
        placementKey: command.placementKey,
        projectId: command.projectId,
        assetId: command.assetId,
        sketchId: command.sketchId,
        floorId: command.floorId ?? _floorA,
        provenanceRevisionId: command.activeRevisionId,
        sequence: 1,
        x: command.x,
        y: command.y,
        quantity: command.totalQuantity,
        createdAt: _now,
        endedAt: null,
        endReason: null,
        supersedesPlacementId: null,
      ),
    );
    assets[command.projectId] = [
      ...assets[command.projectId] ?? const <InventoryAssetProjection>[],
      projection,
    ];
    return _mutationResult(
      command,
      sourceId: command.assetId,
      sourceRevision: 1,
      supportingId: command.placementId,
      supportingRevision: 1,
    );
  }

  @override
  Future<InventoryMutationResult> movePlacement(
    MoveInventoryPlacementCommand command,
  ) async {
    moveCalls += 1;
    mutations += 1;
    lastMove = command;
    final current = _projection(command.projectId, command.assetId);
    final placement = current?.activePlacement;
    if (current == null ||
        placement == null ||
        placement.placementKey != command.placementKey ||
        placement.sequence != command.expectedPlacementSequence) {
      throw const InventoryFailure('inventory_stale_revision');
    }
    final ended = _copyPlacement(
      placement,
      endedAt: _now.add(const Duration(minutes: 1)),
      endReason: InventoryPlacementEndReason.moved,
    );
    final successor = InventoryPlacementRecord(
      id: command.successorPlacementId,
      placementKey: placement.placementKey,
      projectId: placement.projectId,
      assetId: placement.assetId,
      sketchId: command.sketchId,
      floorId: placement.floorId,
      provenanceRevisionId: command.activeRevisionId,
      sequence: placement.sequence + 1,
      x: command.x,
      y: command.y,
      quantity: placement.quantity,
      createdAt: _now.add(const Duration(minutes: 1)),
      endedAt: null,
      endReason: null,
      supersedesPlacementId: placement.id,
    );
    final previous = placementVersions[command.assetId] ?? [placement];
    placementVersions[command.assetId] = [
      ...previous.take(previous.length - 1),
      ended,
      successor,
    ];
    _replaceProjection(
      command.projectId,
      InventoryAssetProjection(
        asset: current.asset,
        activePlacement: successor,
      ),
    );
    return _mutationResult(
      command,
      sourceId: command.placementKey,
      sourceRevision: successor.sequence,
      supportingId: successor.id,
      supportingRevision: successor.sequence,
    );
  }

  @override
  Future<InventoryMutationResult> unarchiveAsset(
    UnarchiveInventoryAssetCommand command,
  ) async {
    unarchiveCalls += 1;
    mutations += 1;
    lastUnarchive = command;
    final current = _projection(command.projectId, command.assetId);
    final previous = placementVersions[command.assetId];
    if (current == null ||
        current.asset.archivedAt == null ||
        current.activePlacement != null ||
        previous == null ||
        previous.isEmpty) {
      throw const InventoryFailure('inventory_asset_state_invalid');
    }
    final predecessor = previous.last;
    if (predecessor.isActive ||
        predecessor.placementKey != command.placementKey ||
        predecessor.sequence != command.expectedPreviousPlacementSequence ||
        current.asset.revision != command.expectedAssetRevision) {
      throw const InventoryFailure('inventory_stale_revision');
    }
    final successor = InventoryPlacementRecord(
      id: command.successorPlacementId,
      placementKey: predecessor.placementKey,
      projectId: predecessor.projectId,
      assetId: predecessor.assetId,
      sketchId: command.sketchId,
      floorId: predecessor.floorId,
      provenanceRevisionId: command.activeRevisionId,
      sequence: predecessor.sequence + 1,
      x: command.x,
      y: command.y,
      quantity: current.asset.totalQuantity,
      createdAt: _now.add(const Duration(minutes: 2)),
      endedAt: null,
      endReason: null,
      supersedesPlacementId: predecessor.id,
    );
    placementVersions[command.assetId] = [...previous, successor];
    _replaceProjection(
      command.projectId,
      InventoryAssetProjection(
        asset: _copyAsset(
          current.asset,
          revision: current.asset.revision + 1,
          archivedAt: null,
        ),
        activePlacement: successor,
      ),
    );
    return _mutationResult(
      command,
      sourceId: command.assetId,
      sourceRevision: current.asset.revision + 1,
      supportingId: successor.id,
      supportingRevision: successor.sequence,
    );
  }

  InventoryAssetProjection? _projection(String projectId, String assetId) {
    for (final projection in assets[projectId] ?? const []) {
      if (projection.asset.id == assetId) return projection;
    }
    return null;
  }

  void _replaceProjection(
    String projectId,
    InventoryAssetProjection replacement,
  ) {
    assets[projectId] = [
      for (final projection in assets[projectId] ?? const [])
        if (projection.asset.id == replacement.asset.id)
          replacement
        else
          projection,
    ];
  }
}

MobileProject _project(String id, String name) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-08-28T08:00:00Z',
  updatedAt: '2026-08-28T08:00:00Z',
  revision: 1,
);

InventoryPrimarySketchProjection _sketch(
  String projectId, {
  String? revisionId,
  int sketchRevision = 1,
  int revisionNumber = 1,
  int endpointX = 4096,
  InventoryGeometry? geometryOverride,
}) {
  final sketchId = projectId == _projectA ? _sketchA : _sketchB;
  final activeRevisionId =
      revisionId ?? (projectId == _projectA ? _revisionA : _revisionB);
  final geometry =
      geometryOverride ??
      InventoryGeometry(
        polylines: [
          InventoryPolyline(
            closed: false,
            points: [
              InventorySketchPoint(x: 0, y: 0),
              InventorySketchPoint(x: endpointX, y: 3072),
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
      activeRevisionId: activeRevisionId,
      draftRevisionId: null,
      revision: sketchRevision,
      createdAt: _now,
      updatedAt: _now,
      archivedAt: null,
    ),
    activeRevision: InventorySketchRevisionRecord(
      id: activeRevisionId,
      sketchId: sketchId,
      projectId: projectId,
      revisionNumber: revisionNumber,
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
    blocks: [
      _block(
        id: projectId == _projectA ? _detachedBlockA : _detachedBlockB,
        projectId: projectId,
        name: 'Eski alan',
        ordinal: 1,
        state: InventoryBlockState.detached,
      ),
    ],
    floors: [
      _floor(
        id: projectId == _projectA ? _floorA : _floorB,
        blockId: projectId == _projectA ? _detachedBlockA : _detachedBlockB,
        projectId: projectId,
        name: '1. Kat',
        ordinal: 1,
      ),
    ],
  );
}

InventoryPrimarySketchProjection _activeMappedSketch(String projectId) {
  final geometry = InventoryGeometry(polylines: [_rectangle(0, 0, 4096, 3072)]);
  final base = _sketch(projectId, geometryOverride: geometry);
  final blockId = projectId == _projectA ? _detachedBlockA : _detachedBlockB;
  final floorId = projectId == _projectA ? _floorA : _floorB;
  return InventoryPrimarySketchProjection(
    sketch: base.sketch,
    activeRevision: base.activeRevision,
    draftRevision: null,
    blocks: [
      _block(
        id: blockId,
        projectId: projectId,
        name: 'Aktif alan',
        ordinal: 1,
        state: InventoryBlockState.active,
      ),
    ],
    floors: [
      _floor(
        id: floorId,
        blockId: blockId,
        projectId: projectId,
        name: '1. Kat',
        ordinal: 1,
      ),
    ],
    activeBlockPolygons: [
      InventoryRevisionBlockPolygonRecord(
        revisionId: base.activeRevision!.id,
        blockId: blockId,
        projectId: projectId,
        sketchId: base.sketch.id,
        polygonIndex: 0,
        createdAt: _now,
      ),
    ],
  );
}

InventoryPrimarySketchProjection _spatialSketch() {
  final geometry = InventoryGeometry(
    polylines: [_rectangle(0, 0, 1536, 1536), _rectangle(2048, 0, 3584, 1536)],
  );
  final base = _sketch(_projectA, geometryOverride: geometry);
  return InventoryPrimarySketchProjection(
    sketch: base.sketch,
    activeRevision: base.activeRevision,
    draftRevision: null,
    blocks: [
      _block(
        id: _spatialBlockB,
        projectId: _projectA,
        name: 'B Blok',
        ordinal: 2,
        state: InventoryBlockState.active,
      ),
      _block(
        id: _spatialBlockA,
        projectId: _projectA,
        name: 'A Blok',
        ordinal: 1,
        state: InventoryBlockState.active,
      ),
    ],
    floors: [
      _floor(
        id: _spatialFloorB2,
        blockId: _spatialBlockB,
        projectId: _projectA,
        name: 'B 2. Kat',
        ordinal: 2,
      ),
      _floor(
        id: _spatialFloorA2,
        blockId: _spatialBlockA,
        projectId: _projectA,
        name: 'A 2. Kat',
        ordinal: 2,
      ),
      _floor(
        id: _spatialFloorB3,
        blockId: _spatialBlockB,
        projectId: _projectA,
        name: 'B 3. Kat',
        ordinal: 3,
      ),
      _floor(
        id: _spatialFloorA1,
        blockId: _spatialBlockA,
        projectId: _projectA,
        name: 'A 1. Kat',
        ordinal: 1,
      ),
      _floor(
        id: _spatialFloorB1,
        blockId: _spatialBlockB,
        projectId: _projectA,
        name: 'B 1. Kat',
        ordinal: 1,
      ),
    ],
    activeBlockPolygons: [
      InventoryRevisionBlockPolygonRecord(
        revisionId: _revisionA,
        blockId: _spatialBlockB,
        projectId: _projectA,
        sketchId: _sketchA,
        polygonIndex: 1,
        createdAt: _now,
      ),
      InventoryRevisionBlockPolygonRecord(
        revisionId: _revisionA,
        blockId: _spatialBlockA,
        projectId: _projectA,
        sketchId: _sketchA,
        polygonIndex: 0,
        createdAt: _now,
      ),
    ],
  );
}

InventoryBlockRecord _block({
  required String id,
  required String projectId,
  required String name,
  required int ordinal,
  required InventoryBlockState state,
}) => InventoryBlockRecord(
  id: id,
  projectId: projectId,
  displayName: name,
  normalizedName: name.toLowerCase(),
  ordinal: ordinal,
  state: state,
  revision: 1,
  createdAt: _now,
  updatedAt: _now,
  archivedAt: null,
);

InventoryFloorRecord _floor({
  required String id,
  required String blockId,
  required String projectId,
  required String name,
  required int ordinal,
}) => InventoryFloorRecord(
  id: id,
  blockId: blockId,
  projectId: projectId,
  displayName: name,
  ordinal: ordinal,
  revision: 1,
  createdAt: _now,
  updatedAt: _now,
  archivedAt: null,
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

InventoryGeometry _finalizedCreateGeometry() => InventoryGeometry(
  polylines: [
    InventoryPolyline(
      closed: true,
      points: [
        InventorySketchPoint(x: 0, y: 0),
        InventorySketchPoint(x: 1024, y: 0),
        InventorySketchPoint(x: 1024, y: 1024),
        InventorySketchPoint(x: 0, y: 1024),
      ],
    ),
  ],
);

InventoryGeometry _editSuccessorGeometry() => InventoryGeometry(
  polylines: [
    InventoryPolyline(
      closed: true,
      points: [
        InventorySketchPoint(x: 0, y: 0),
        InventorySketchPoint(x: 1024, y: 0),
        InventorySketchPoint(x: 1024, y: 1024),
        InventorySketchPoint(x: 0, y: 1024),
      ],
    ),
    InventoryPolyline(
      closed: true,
      points: [
        InventorySketchPoint(x: 1536, y: 0),
        InventorySketchPoint(x: 2560, y: 0),
        InventorySketchPoint(x: 2560, y: 1024),
        InventorySketchPoint(x: 1536, y: 1024),
      ],
    ),
  ],
);

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
  String? floorId,
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
            floorId: floorId ?? (projectId == _projectA ? _floorA : _floorB),
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

InventoryPlacementRecord _placement(
  String projectId,
  String assetId, {
  int sequence = 1,
  int x = 100,
  int y = 100,
  DateTime? endedAt,
  InventoryPlacementEndReason? endReason,
  String? supersedesPlacementId,
}) {
  final sketchId = projectId == _projectA ? _sketchA : _sketchB;
  final revisionId = projectId == _projectA ? _revisionA : _revisionB;
  return InventoryPlacementRecord(
    id: 'eeeeeeee-eeee-4eee-8eee-${assetId.substring(24)}',
    placementKey: 'ffffffff-ffff-4fff-8fff-${assetId.substring(24)}',
    projectId: projectId,
    assetId: assetId,
    sketchId: sketchId,
    floorId: projectId == _projectA ? _floorA : _floorB,
    provenanceRevisionId: revisionId,
    sequence: sequence,
    x: x,
    y: y,
    quantity: 2,
    createdAt: _now,
    endedAt: endedAt,
    endReason: endReason,
    supersedesPlacementId: supersedesPlacementId,
  );
}

InventoryPlacementRecord _copyPlacement(
  InventoryPlacementRecord current, {
  required DateTime? endedAt,
  required InventoryPlacementEndReason? endReason,
}) => InventoryPlacementRecord(
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
  endedAt: endedAt,
  endReason: endReason,
  supersedesPlacementId: current.supersedesPlacementId,
);

InventoryEventRecord _placementEvent(
  String projectId,
  String assetId,
  String placementKey,
) => InventoryEventRecord(
  id: '11111111-1111-4111-8111-${assetId.substring(24)}',
  operationId: '22222222-2222-4222-8222-${assetId.substring(24)}',
  projectId: projectId,
  aggregateType: InventoryAggregateType.placement,
  aggregateId: placementKey,
  sequence: 1,
  eventType: InventoryEventType.placementCreated,
  occurredAt: _now,
  payload: <String, Object?>{'asset_id': assetId},
  payloadJson: '{"asset_id":"$assetId"}',
  payloadSha256: 'a'.padRight(64, 'a'),
);

InventoryMutationResult _mutationResult(
  InventoryMutationCommand command, {
  required String sourceId,
  required int sourceRevision,
  required String supportingId,
  required int supportingRevision,
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
  isNoOp: false,
  eventCount: 2,
  resultAt: _now,
);

const _notProvided = Object();

InventoryAssetRecord _copyAsset(
  InventoryAssetRecord current, {
  int? revision,
  Object? archivedAt = _notProvided,
}) => InventoryAssetRecord(
  id: current.id,
  projectId: current.projectId,
  displayName: current.displayName,
  normalizedName: current.normalizedName,
  category: current.category,
  otherCategoryLabel: current.otherCategoryLabel,
  totalQuantity: current.totalQuantity,
  status: current.status,
  note: current.note,
  revision: revision ?? current.revision,
  createdAt: current.createdAt,
  updatedAt: _now.add(const Duration(minutes: 2)),
  statusChangedAt: current.statusChangedAt,
  archivedAt: identical(archivedAt, _notProvided)
      ? current.archivedAt
      : archivedAt as DateTime?,
);
