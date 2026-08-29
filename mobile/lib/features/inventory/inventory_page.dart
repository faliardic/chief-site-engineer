import 'dart:async';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/inventory/inventory_asset_detail_sheet.dart';
import 'package:chief_site_engineer/features/inventory/inventory_asset_quick_form.dart';
import 'package:chief_site_engineer/features/inventory/inventory_floor_view.dart';
import 'package:chief_site_engineer/features/inventory/inventory_map_view.dart';
import 'package:chief_site_engineer/features/inventory/inventory_sketch_editor_page.dart';
import 'package:flutter/material.dart';

typedef InventoryProjectLoader = Future<List<MobileProject>> Function();
typedef InventorySketchEditorLauncher =
    Future<bool?> Function(
      BuildContext context,
      String projectId,
      InventorySketchLaunchIntent launchIntent,
    );
typedef InventoryAssetDetailLauncher =
    Future<void> Function(
      BuildContext context,
      String projectId,
      String assetId,
    );

enum InventoryPageLoadStatus {
  idle,
  loadingProjects,
  projectRequired,
  projectSelectionRequired,
  loadingInventory,
  noSketch,
  ready,
  failed,
}

enum InventoryPageView { map, floors, list }

class InventoryAssetSpatialContext {
  const InventoryAssetSpatialContext({
    required this.block,
    required this.floor,
  });

  final InventoryBlockRecord block;
  final InventoryFloorRecord floor;
}

enum _InventoryDetailTargetRequest { move, unarchive }

enum InventoryArchiveFilter {
  active('Aktif'),
  archived('Arşivli'),
  all('Tümü');

  const InventoryArchiveFilter(this.label);
  final String label;
}

class InventoryPageController extends ChangeNotifier {
  InventoryPageController({
    required this.application,
    required this.listProjects,
    required this.projectChanges,
  });

  final InventoryApplicationPort application;
  final InventoryProjectLoader listProjects;
  final Stream<void> projectChanges;

  InventoryPageLoadStatus loadStatus = InventoryPageLoadStatus.idle;
  List<MobileProject> projects = const [];
  String? selectedProjectId;
  String? selectedProjectName;
  InventoryPrimarySketchProjection? sketch;
  List<InventoryAssetProjection> assets = const [];
  InventoryPageView view = InventoryPageView.map;
  String search = '';
  InventoryCategory? categoryFilter;
  InventoryAssetStatus? statusFilter;
  InventoryArchiveFilter archiveFilter = InventoryArchiveFilter.active;
  String? selectedBlockId;
  String? selectedFloorId;
  String? lastErrorCode;
  String? lastDiagnosticCode;
  String? sketchDiagnosticCode;

  StreamSubscription<void>? _projectSubscription;
  bool _initialized = false;
  bool _disposed = false;
  int _generation = 0;

  List<InventoryAssetProjection> get visibleAssets {
    final query = _normalizeName(search);
    return List<InventoryAssetProjection>.unmodifiable(
      assets.where((projection) {
        final asset = projection.asset;
        if (query.isNotEmpty && !asset.normalizedName.contains(query)) {
          return false;
        }
        if (categoryFilter != null && asset.category != categoryFilter) {
          return false;
        }
        if (statusFilter != null && asset.status != statusFilter) {
          return false;
        }
        if (!_matchesSpatialSelection(projection)) return false;
        return switch (archiveFilter) {
          InventoryArchiveFilter.active => asset.archivedAt == null,
          InventoryArchiveFilter.archived => asset.archivedAt != null,
          InventoryArchiveFilter.all => true,
        };
      }),
    );
  }

  List<InventoryAssetProjection> get canonicalActiveMapAssets =>
      List<InventoryAssetProjection>.unmodifiable(
        assets.where(
          (projection) =>
              projection.asset.archivedAt == null &&
              detachedSpatialContextFor(projection) == null,
        ),
      );

  List<InventoryAssetProjection> get visibleMapAssets =>
      List<InventoryAssetProjection>.unmodifiable(
        visibleAssets.where(
          (projection) =>
              projection.asset.archivedAt == null &&
              detachedSpatialContextFor(projection) == null,
        ),
      );

  List<InventoryBlockRecord> get activeBlocks {
    final projection = sketch;
    if (projection == null) return const [];
    final mappedIds = projection.activeBlockPolygons
        .map((mapping) => mapping.blockId)
        .toSet();
    final result =
        projection.blocks
            .where(
              (block) =>
                  block.projectId == selectedProjectId &&
                  block.state == InventoryBlockState.active &&
                  block.archivedAt == null &&
                  mappedIds.contains(block.id),
            )
            .toList(growable: false)
          ..sort(_compareBlocks);
    return List<InventoryBlockRecord>.unmodifiable(result);
  }

  List<InventoryFloorRecord> get activeFloors {
    final projection = sketch;
    if (projection == null) return const [];
    final blockIds = activeBlocks.map((block) => block.id).toSet();
    final result =
        projection.floors
            .where(
              (floor) =>
                  floor.projectId == selectedProjectId &&
                  floor.archivedAt == null &&
                  blockIds.contains(floor.blockId),
            )
            .toList(growable: false)
          ..sort(_compareFloors);
    return List<InventoryFloorRecord>.unmodifiable(result);
  }

  List<InventoryFloorRecord> get selectedBlockFloors {
    final blockId = selectedBlockId;
    if (blockId == null) return const [];
    return List<InventoryFloorRecord>.unmodifiable(
      activeFloors.where((floor) => floor.blockId == blockId),
    );
  }

  InventoryFloorViewModel get floorViewModel =>
      InventoryFloorViewModel.fromCanonical(
        activeBlocks: activeBlocks,
        activeFloors: activeFloors,
        assets: assets,
      );

  InventoryAssetSpatialContext? spatialContextFor(
    InventoryAssetProjection projection, {
    bool activeBlockOnly = false,
  }) {
    final currentSketch = sketch;
    final placement = projection.activePlacement;
    if (currentSketch == null ||
        projection.asset.archivedAt != null ||
        placement == null ||
        !placement.isActive ||
        placement.projectId != selectedProjectId ||
        placement.assetId != projection.asset.id ||
        placement.sketchId != currentSketch.sketch.id ||
        placement.quantity != projection.asset.totalQuantity) {
      return null;
    }
    final floor = _floorOrNull(placement.floorId);
    if (floor == null || floor.archivedAt != null) return null;
    final block = _blockOrNull(floor.blockId);
    if (block == null || block.archivedAt != null) return null;
    if (activeBlockOnly &&
        (block.state != InventoryBlockState.active ||
            !activeBlocks.any((candidate) => candidate.id == block.id))) {
      return null;
    }
    return InventoryAssetSpatialContext(block: block, floor: floor);
  }

  InventoryAssetSpatialContext? detachedSpatialContextFor(
    InventoryAssetProjection projection,
  ) {
    final currentSketch = sketch;
    final activeRevision = currentSketch?.activeRevision;
    final placement = projection.activePlacement;
    final context = spatialContextFor(projection);
    if (currentSketch == null ||
        activeRevision == null ||
        placement == null ||
        context == null ||
        projection.asset.projectId != selectedProjectId ||
        currentSketch.sketch.projectId != selectedProjectId ||
        activeRevision.projectId != selectedProjectId ||
        activeRevision.sketchId != currentSketch.sketch.id ||
        context.block.projectId != selectedProjectId ||
        context.block.state != InventoryBlockState.detached ||
        context.floor.projectId != selectedProjectId ||
        context.floor.blockId != context.block.id ||
        placement.floorId != context.floor.id ||
        currentSketch.blocks
                .where((block) => block.id == context.block.id)
                .length !=
            1 ||
        currentSketch.floors
                .where((floor) => floor.id == context.floor.id)
                .length !=
            1 ||
        currentSketch.activeBlockPolygons.any(
          (mapping) => mapping.blockId == context.block.id,
        )) {
      return null;
    }
    try {
      InventoryGeometryContract.validatePlacementCoordinate(
        placement.x,
        maximum: InventoryGeometryContract.canvasWidth,
      );
      InventoryGeometryContract.validatePlacementCoordinate(
        placement.y,
        maximum: InventoryGeometryContract.canvasHeight,
      );
    } on InventoryGeometryFailure {
      return null;
    }
    return context;
  }

  void setBlockSelection(String? blockId) {
    if (blockId != null && !activeBlocks.any((block) => block.id == blockId)) {
      lastDiagnosticCode = 'inventory_spatial_context_unavailable';
      _notify();
      return;
    }
    final floorStillValid =
        blockId != null &&
        selectedFloorId != null &&
        activeFloors.any(
          (floor) => floor.id == selectedFloorId && floor.blockId == blockId,
        );
    if (selectedBlockId == blockId &&
        (floorStillValid || selectedFloorId == null)) {
      return;
    }
    selectedBlockId = blockId;
    if (!floorStillValid) selectedFloorId = null;
    lastDiagnosticCode = null;
    _notify();
  }

  void setFloorSelection(String? floorId) {
    final blockId = selectedBlockId;
    if (floorId != null &&
        (blockId == null ||
            !activeFloors.any(
              (floor) => floor.id == floorId && floor.blockId == blockId,
            ))) {
      lastDiagnosticCode = 'inventory_spatial_context_unavailable';
      _notify();
      return;
    }
    if (selectedFloorId == floorId) return;
    selectedFloorId = floorId;
    lastDiagnosticCode = null;
    _notify();
  }

  bool selectSpatialContext({
    required String blockId,
    required String floorId,
    required InventoryPageView targetView,
  }) {
    final valid = activeFloors.any(
      (floor) => floor.id == floorId && floor.blockId == blockId,
    );
    if (!valid || targetView == InventoryPageView.floors) {
      lastDiagnosticCode = 'inventory_spatial_context_unavailable';
      _notify();
      return false;
    }
    selectedBlockId = blockId;
    selectedFloorId = floorId;
    view = targetView;
    lastDiagnosticCode = null;
    _notify();
    return true;
  }

  Future<void> initialize() async {
    if (!_initialized) {
      _initialized = true;
      _projectSubscription = projectChanges.listen((_) {
        unawaited(refreshProjects());
      });
    }
    await refreshProjects();
  }

  Future<void> refreshProjects() async {
    final generation = ++_generation;
    loadStatus = InventoryPageLoadStatus.loadingProjects;
    lastErrorCode = null;
    _notify();
    try {
      final loaded = await listProjects();
      if (!_isCurrent(generation)) return;
      final ids = <String>{};
      for (final project in loaded) {
        if (project.isArchived || !ids.add(project.id)) {
          throw const InventoryFailure('inventory_project_source_invalid');
        }
      }
      projects = List<MobileProject>.unmodifiable(loaded);
      final selectedId = selectedProjectId;
      if (selectedId != null) {
        final selected = _projectOrNull(selectedId);
        if (selected == null) {
          _clearProjectSession(keepSelection: true);
          loadStatus = InventoryPageLoadStatus.failed;
          lastErrorCode = 'inventory_project_unavailable';
          _notify();
          return;
        }
        selectedProjectName = selected.name;
        await _loadInventory(selected.id, generation);
        return;
      }
      if (projects.isEmpty) {
        _clearProjectSession();
        loadStatus = InventoryPageLoadStatus.projectRequired;
        _notify();
        return;
      }
      if (projects.length == 1) {
        final selected = projects.single;
        _clearProjectSession();
        selectedProjectId = selected.id;
        selectedProjectName = selected.name;
        await _loadInventory(selected.id, generation);
        return;
      }
      _clearProjectSession();
      loadStatus = InventoryPageLoadStatus.projectSelectionRequired;
      _notify();
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      projects = const [];
      _clearProjectSession(keepSelection: selectedProjectId != null);
      loadStatus = InventoryPageLoadStatus.failed;
      lastErrorCode = _safeCode(
        error,
        fallback: 'inventory_projects_load_failed',
      );
      _notify();
    }
  }

  Future<void> selectProject(String projectId) async {
    final selected = _projectOrNull(projectId);
    if (selected == null) {
      _clearProjectSession(keepSelection: true);
      selectedProjectId = projectId;
      loadStatus = InventoryPageLoadStatus.failed;
      lastErrorCode = 'inventory_project_unavailable';
      _notify();
      return;
    }
    final generation = ++_generation;
    _clearProjectSession();
    selectedProjectId = selected.id;
    selectedProjectName = selected.name;
    loadStatus = InventoryPageLoadStatus.loadingInventory;
    _notify();
    await _loadInventory(selected.id, generation);
  }

  Future<void> reloadSelected() => refreshProjects();

  void setView(InventoryPageView value) {
    if (value != InventoryPageView.list && sketch == null) {
      lastDiagnosticCode =
          sketchDiagnosticCode ?? 'inventory_active_revision_unavailable';
      _notify();
      return;
    }
    if (view == value) return;
    view = value;
    lastDiagnosticCode = null;
    _notify();
  }

  void setSearch(String value) {
    if (search == value) return;
    search = value;
    lastDiagnosticCode = null;
    _notify();
  }

  void setCategoryFilter(InventoryCategory? value) {
    if (categoryFilter == value) return;
    categoryFilter = value;
    lastDiagnosticCode = null;
    _notify();
  }

  void setStatusFilter(InventoryAssetStatus? value) {
    if (statusFilter == value) return;
    statusFilter = value;
    lastDiagnosticCode = null;
    _notify();
  }

  void setArchiveFilter(InventoryArchiveFilter value) {
    if (archiveFilter == value) return;
    archiveFilter = value;
    lastDiagnosticCode = null;
    _notify();
  }

  bool canFocus(InventoryAssetProjection projection) {
    final activeSketch = sketch;
    final revision = activeSketch?.activeRevision;
    final asset = projection.asset;
    final placement = projection.activePlacement;
    if (activeSketch == null ||
        revision == null ||
        asset.projectId != selectedProjectId ||
        asset.archivedAt != null ||
        placement == null ||
        !placement.isActive ||
        placement.projectId != selectedProjectId ||
        placement.assetId != asset.id ||
        placement.sketchId != activeSketch.sketch.id ||
        placement.quantity != asset.totalQuantity ||
        spatialContextFor(projection, activeBlockOnly: true) == null) {
      return false;
    }
    try {
      InventoryGeometryContract.validatePlacementCoordinate(
        placement.x,
        maximum: InventoryGeometryContract.canvasWidth,
      );
      InventoryGeometryContract.validatePlacementCoordinate(
        placement.y,
        maximum: InventoryGeometryContract.canvasHeight,
      );
      return true;
    } on InventoryGeometryFailure {
      return false;
    }
  }

  String focusFailureCode(InventoryAssetProjection projection) {
    if (sketch == null) {
      return sketchDiagnosticCode ?? 'inventory_active_revision_unavailable';
    }
    if (projection.activePlacement == null) {
      return 'inventory_active_placement_unavailable';
    }
    if (detachedSpatialContextFor(projection) != null) {
      return 'inventory_block_detached';
    }
    return 'inventory_projection_integrity_failed';
  }

  void recordFocusFailure(InventoryAssetProjection projection) {
    lastDiagnosticCode = focusFailureCode(projection);
    _notify();
  }

  void recordPresentationFailure(String code) {
    if (lastDiagnosticCode == code) return;
    lastDiagnosticCode = code;
    _notify();
  }

  void recordMapProjectionFailure(String code) {
    final diagnostic = lastDiagnosticCode ?? code;
    final changed =
        view != InventoryPageView.list || lastDiagnosticCode != diagnostic;
    view = InventoryPageView.list;
    lastDiagnosticCode = diagnostic;
    if (changed) _notify();
  }

  void clearDiagnostic() {
    if (lastDiagnosticCode == null) return;
    lastDiagnosticCode = null;
    _notify();
  }

  InventoryPlacementCoordinates safeCreateTargetForFloor({
    required String blockId,
    required String floorId,
  }) {
    try {
      final projection = sketch;
      final active = projection?.activeRevision;
      if (projection == null || active == null) {
        throw const InventoryFailure('inventory_safe_interior_unavailable');
      }
      final block = activeBlocks
          .where((candidate) => candidate.id == blockId)
          .toList(growable: false);
      final floor = activeFloors
          .where(
            (candidate) =>
                candidate.id == floorId && candidate.blockId == blockId,
          )
          .toList(growable: false);
      final mapping = projection.activeBlockPolygons
          .where(
            (candidate) =>
                candidate.blockId == blockId &&
                candidate.revisionId == active.id &&
                candidate.sketchId == projection.sketch.id,
          )
          .toList(growable: false);
      if (block.length != 1 ||
          floor.length != 1 ||
          mapping.length != 1 ||
          mapping.single.polygonIndex < 0 ||
          mapping.single.polygonIndex >= active.geometry.polylines.length) {
        throw const InventoryFailure('inventory_safe_interior_unavailable');
      }
      final occupied = <InventoryPlacementCoordinates>[];
      for (final asset in assets) {
        final context = spatialContextFor(asset, activeBlockOnly: true);
        final placement = asset.activePlacement;
        if (context?.block.id == blockId &&
            context?.floor.id == floorId &&
            placement != null) {
          occupied.add(
            InventoryPlacementCoordinates(x: placement.x, y: placement.y),
          );
        }
      }
      final target = InventorySpatialContract.safeInteriorPlacement(
        active.geometry.polylines[mapping.single.polygonIndex],
        spreadIndex: occupied.length,
        occupied: occupied,
      );
      if (!InventorySpatialContract.strictlyContainsPlacement(
        active.geometry.polylines[mapping.single.polygonIndex],
        x: target.x,
        y: target.y,
      )) {
        throw const InventoryFailure('inventory_safe_interior_unavailable');
      }
      return target;
    } on Object {
      throw const InventoryFailure('inventory_safe_interior_unavailable');
    }
  }

  Future<void> _loadInventory(String projectId, int generation) async {
    if (!_isCurrent(generation) || selectedProjectId != projectId) return;
    loadStatus = InventoryPageLoadStatus.loadingInventory;
    lastErrorCode = null;
    lastDiagnosticCode = null;
    sketchDiagnosticCode = null;
    sketch = null;
    assets = const [];
    _notify();
    InventoryPrimarySketchProjection? loadedSketch;
    String? geometryFailure;
    try {
      try {
        loadedSketch = await application.loadPrimarySketch(projectId);
      } on InventoryGeometryFailure catch (error) {
        geometryFailure = error.code;
      }
      if (!_isCurrent(generation) || selectedProjectId != projectId) return;
      if (loadedSketch == null && geometryFailure == null) {
        loadStatus = InventoryPageLoadStatus.noSketch;
        _notify();
        return;
      }
      if (loadedSketch != null) {
        _verifySketch(projectId, loadedSketch);
      }
      final loadedAssets = await application.listAssets(
        projectId: projectId,
        includeArchived: true,
      );
      if (!_isCurrent(generation) || selectedProjectId != projectId) return;
      _verifyAssetIdentities(projectId, loadedAssets);
      sketch = loadedSketch;
      assets = List<InventoryAssetProjection>.unmodifiable(loadedAssets);
      _revalidateSpatialSelection();
      sketchDiagnosticCode = geometryFailure;
      if (geometryFailure != null) {
        view = InventoryPageView.list;
        lastDiagnosticCode = geometryFailure;
      }
      loadStatus = InventoryPageLoadStatus.ready;
      _notify();
    } on Object catch (error) {
      if (!_isCurrent(generation) || selectedProjectId != projectId) return;
      sketch = null;
      assets = const [];
      loadStatus = InventoryPageLoadStatus.failed;
      lastErrorCode = _safeCode(error, fallback: 'inventory_page_load_failed');
      _notify();
    }
  }

  void _verifySketch(String projectId, InventoryPrimarySketchProjection value) {
    final active = value.activeRevision;
    if (value.sketch.projectId != projectId ||
        !value.sketch.isPrimary ||
        value.sketch.archivedAt != null ||
        value.sketch.activeRevisionId == null ||
        value.sketch.activeRevisionId != active?.id ||
        active?.projectId != projectId ||
        active?.sketchId != value.sketch.id ||
        active?.state != InventorySketchRevisionState.active) {
      throw const InventoryFailure('inventory_active_revision_unavailable');
    }
    final blockIds = <String>{};
    for (final block in value.blocks) {
      if (block.projectId != projectId || !blockIds.add(block.id)) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
    }
    final floorIds = <String>{};
    for (final floor in value.floors) {
      if (floor.projectId != projectId ||
          !blockIds.contains(floor.blockId) ||
          !floorIds.add(floor.id)) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
    }
    final mappedBlockIds = <String>{};
    final mappedPolygonIndices = <int>{};
    for (final mapping in value.activeBlockPolygons) {
      if (mapping.projectId != projectId ||
          mapping.sketchId != value.sketch.id ||
          mapping.revisionId != active!.id ||
          !blockIds.contains(mapping.blockId) ||
          mapping.polygonIndex < 0 ||
          mapping.polygonIndex >= active.geometry.polylines.length ||
          !mappedBlockIds.add(mapping.blockId) ||
          !mappedPolygonIndices.add(mapping.polygonIndex)) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
    }
    if (value.blocks.any(
      (block) =>
          block.state == InventoryBlockState.active &&
          !mappedBlockIds.contains(block.id),
    )) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
  }

  void _verifyAssetIdentities(
    String projectId,
    Iterable<InventoryAssetProjection> values,
  ) {
    final ids = <String>{};
    for (final projection in values) {
      if (projection.asset.projectId != projectId ||
          !ids.add(projection.asset.id)) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
    }
  }

  MobileProject? _projectOrNull(String id) {
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  InventoryBlockRecord? _blockOrNull(String id) {
    for (final block in sketch?.blocks ?? const <InventoryBlockRecord>[]) {
      if (block.id == id) return block;
    }
    return null;
  }

  InventoryFloorRecord? _floorOrNull(String id) {
    for (final floor in sketch?.floors ?? const <InventoryFloorRecord>[]) {
      if (floor.id == id) return floor;
    }
    return null;
  }

  bool _matchesSpatialSelection(InventoryAssetProjection projection) {
    final blockId = selectedBlockId;
    if (blockId == null) return true;
    final context = spatialContextFor(projection, activeBlockOnly: true);
    if (context == null || context.block.id != blockId) return false;
    final floorId = selectedFloorId;
    return floorId == null || context.floor.id == floorId;
  }

  void _revalidateSpatialSelection() {
    final blockId = selectedBlockId;
    if (blockId == null || !activeBlocks.any((block) => block.id == blockId)) {
      selectedBlockId = null;
      selectedFloorId = null;
      return;
    }
    final floorId = selectedFloorId;
    if (floorId != null &&
        !activeFloors.any(
          (floor) => floor.id == floorId && floor.blockId == blockId,
        )) {
      selectedFloorId = null;
    }
  }

  void _clearProjectSession({bool keepSelection = false}) {
    sketch = null;
    assets = const [];
    view = InventoryPageView.map;
    search = '';
    categoryFilter = null;
    statusFilter = null;
    archiveFilter = InventoryArchiveFilter.active;
    selectedBlockId = null;
    selectedFloorId = null;
    lastErrorCode = null;
    lastDiagnosticCode = null;
    sketchDiagnosticCode = null;
    if (!keepSelection) {
      selectedProjectId = null;
      selectedProjectName = null;
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    unawaited(_projectSubscription?.cancel());
    super.dispose();
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    required this.application,
    required this.listProjects,
    required this.projectChanges,
    this.controller,
    this.sketchEditorLauncher,
    this.assetDetailLauncher,
    super.key,
  });

  final InventoryApplicationPort application;
  final InventoryProjectLoader listProjects;
  final Stream<void> projectChanges;
  final InventoryPageController? controller;
  final InventorySketchEditorLauncher? sketchEditorLauncher;
  final InventoryAssetDetailLauncher? assetDetailLauncher;

  @override
  State<InventoryPage> createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryPage> {
  final _mapKey = GlobalKey<InventoryMapViewState>();
  final _search = TextEditingController();
  late InventoryPageController controller;
  late bool _ownsController;
  InventoryMapController? _mapController;
  String? _mapProjectId;
  InventoryAssetDetailController? _activeDetailController;
  Completer<InventoryPlacementTarget?>? _targetSelectionCompleter;
  _InventoryDetailTargetRequest? _targetSelectionRequest;

  InventoryMapController? get mapController => _mapController;
  InventoryMapViewState? get mapViewState => _mapKey.currentState;

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  void _attachController() {
    _ownsController = widget.controller == null;
    controller =
        widget.controller ??
        InventoryPageController(
          application: widget.application,
          listProjects: widget.listProjects,
          projectChanges: widget.projectChanges,
        );
    controller.addListener(_refresh);
    final attached = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(controller, attached)) {
        unawaited(attached.initialize());
      }
    });
  }

  @override
  void didUpdateWidget(covariant InventoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller &&
        oldWidget.application == widget.application) {
      return;
    }
    controller.removeListener(_refresh);
    if (_ownsController) controller.dispose();
    _replaceMapController(null);
    _search.clear();
    _attachController();
  }

  void _refresh() {
    if (!mounted) return;
    _cancelPendingTargetForProjectBoundary();
    if (_search.text != controller.search) {
      _search.value = TextEditingValue(
        text: controller.search,
        selection: TextSelection.collapsed(offset: controller.search.length),
      );
    }
    _prepareMapController();
    setState(() {});
  }

  void _prepareMapController() {
    final projectId = controller.selectedProjectId;
    if (projectId == null) {
      _replaceMapController(null);
      return;
    }
    if (_mapController == null || _mapProjectId != projectId) {
      final next = InventoryMapController(
        application: widget.application,
        projectId: projectId,
      );
      _replaceMapController(next, projectId: projectId);
    }
    final map = _mapController!;
    final sketch = controller.sketch;
    if (controller.loadStatus == InventoryPageLoadStatus.ready &&
        sketch != null) {
      if (!map.useCanonicalSnapshot(
        activeSketch: sketch,
        assets: controller.canonicalActiveMapAssets,
        visibleAssetIds: controller.visibleMapAssets.map(
          (projection) => projection.asset.id,
        ),
      )) {
        controller.recordMapProjectionFailure(
          map.lastErrorCode ?? 'inventory_map_failed',
        );
      }
    } else {
      map.clearSession();
    }
  }

  void _replaceMapController(
    InventoryMapController? next, {
    String? projectId,
  }) {
    final previous = _mapController;
    if (identical(previous, next)) return;
    _mapController = next;
    _mapProjectId = projectId;
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    final pendingTarget = _targetSelectionCompleter;
    if (pendingTarget != null && !pendingTarget.isCompleted) {
      pendingTarget.complete(null);
    }
    controller.removeListener(_refresh);
    if (_ownsController) controller.dispose();
    _mapController?.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('inventory-page'),
      children: [
        _buildProjectSelector(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildProjectSelector() {
    final selectedId = controller.selectedProjectId;
    final selectableValue =
        controller.projects.any((project) => project.id == selectedId)
        ? selectedId
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: DropdownButtonFormField<String>(
        key: ValueKey(
          'inventory-project-${selectableValue ?? 'none'}-'
          '${controller.projects.length}',
        ),
        initialValue: selectableValue,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Aktif proje',
          border: OutlineInputBorder(),
        ),
        hint: Text(
          controller.projects.length > 1
              ? 'Proje seçin'
              : 'Aktif proje gerekli',
        ),
        items: [
          for (final project in controller.projects)
            DropdownMenuItem(value: project.id, child: Text(project.name)),
        ],
        onChanged: controller.projects.isEmpty
            ? null
            : (value) {
                if (value != null && value != controller.selectedProjectId) {
                  _cancelPendingDetailTargetSelection();
                  unawaited(controller.selectProject(value));
                }
              },
      ),
    );
  }

  Widget _buildBody() => switch (controller.loadStatus) {
    InventoryPageLoadStatus.idle ||
    InventoryPageLoadStatus.loadingProjects ||
    InventoryPageLoadStatus.loadingInventory => const Center(
      child: CircularProgressIndicator(),
    ),
    InventoryPageLoadStatus.projectRequired => _message(
      key: const Key('inventory-project-required'),
      icon: Icons.workspaces_outline,
      title: 'Envanter için aktif bir proje gerekli.',
      detail: 'Önce Ajanda bölümünden aktif bir proje oluşturun.',
    ),
    InventoryPageLoadStatus.projectSelectionRequired => _message(
      key: const Key('inventory-project-selection-required'),
      icon: Icons.touch_app_outlined,
      title: 'Envanter projesini seçin.',
      detail: 'Kroki ve Liste yalnız seçtiğiniz aktif projeyi gösterir.',
    ),
    InventoryPageLoadStatus.noSketch => _noSketch(),
    InventoryPageLoadStatus.ready => _ready(),
    InventoryPageLoadStatus.failed => _failure(),
  };

  Widget _noSketch() => _message(
    key: const Key('inventory-no-sketch'),
    icon: Icons.polyline_outlined,
    title: 'Bu projede henüz şematik kroki yok.',
    action: FilledButton.icon(
      key: const Key('inventory-add-sketch'),
      onPressed: () => unawaited(
        _openSketchEditor(InventorySketchLaunchIntent.createOrRecover),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Kroki ekle'),
    ),
  );

  Widget _ready() {
    final visible = controller.visibleAssets;
    return Column(
      children: [
        if (controller.view != InventoryPageView.floors) _filters(),
        if (controller.sketch != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: const Key('inventory-update-sketch'),
                onPressed: () => unawaited(
                  _openSketchEditor(InventorySketchLaunchIntent.editActive),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Krokiyi güncelle'),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<InventoryPageView>(
              key: const Key('inventory-view-switch'),
              segments: const [
                ButtonSegment(
                  value: InventoryPageView.map,
                  icon: Icon(Icons.map_outlined),
                  label: Text('Kroki'),
                ),
                ButtonSegment(
                  value: InventoryPageView.floors,
                  icon: Icon(Icons.layers_outlined),
                  label: Text('Katlar'),
                ),
                ButtonSegment(
                  value: InventoryPageView.list,
                  icon: Icon(Icons.view_list_outlined),
                  label: Text('Liste'),
                ),
              ],
              selected: {controller.view},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) controller.setView(selection.single);
              },
            ),
          ),
        ),
        if (controller.lastDiagnosticCode case final code?)
          MaterialBanner(
            key: const Key('inventory-typed-diagnostic'),
            content: Text('İşlem güvenle tamamlanamadı. Tanı kodu: $code'),
            actions: [
              TextButton(
                onPressed: controller.clearDiagnostic,
                child: const Text('Kapat'),
              ),
            ],
          ),
        Expanded(
          child: switch (controller.view) {
            InventoryPageView.map => _map(),
            InventoryPageView.floors => _floors(),
            InventoryPageView.list => _list(visible),
          },
        ),
      ],
    );
  }

  Widget _filters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Row(
      children: [
        _blockSelector(),
        const SizedBox(width: 8),
        _floorSelector(),
        const SizedBox(width: 8),
        SizedBox(
          width: 220,
          child: TextField(
            key: const Key('inventory-search'),
            controller: _search,
            onChanged: controller.setSearch,
            decoration: const InputDecoration(
              labelText: 'Ada göre ara',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<InventoryCategory?>(
            key: ValueKey(
              'inventory-category-${controller.categoryFilter?.name ?? 'all'}',
            ),
            initialValue: controller.categoryFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Tümü')),
              for (final value in InventoryCategory.values)
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    inventoryCategoryLabel(value),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: controller.setCategoryFilter,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<InventoryAssetStatus?>(
            key: ValueKey(
              'inventory-status-${controller.statusFilter?.name ?? 'all'}',
            ),
            initialValue: controller.statusFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Durum',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Tümü')),
              for (final value in InventoryAssetStatus.values)
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    inventoryAssetStatusLabel(value),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: controller.setStatusFilter,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<InventoryArchiveFilter>(
            key: ValueKey('inventory-archive-${controller.archiveFilter.name}'),
            initialValue: controller.archiveFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Kayıt',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final value in InventoryArchiveFilter.values)
                DropdownMenuItem(
                  value: value,
                  child: Text(value.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value != null) controller.setArchiveFilter(value);
            },
          ),
        ),
      ],
    ),
  );

  Widget _blockSelector() {
    final blocks = controller.activeBlocks;
    final selected = controller.selectedBlockId ?? '';
    return SizedBox(
      key: const Key('inventory-block-selector'),
      width: 170,
      child: DropdownButtonFormField<String>(
        key: ValueKey('inventory-block-$selected-${blocks.length}'),
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Blok',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Tümü')),
          for (final block in blocks)
            DropdownMenuItem(
              value: block.id,
              child: Text(block.displayName, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) => controller.setBlockSelection(
          value == null || value.isEmpty ? null : value,
        ),
      ),
    );
  }

  Widget _floorSelector() {
    final floors = controller.selectedBlockFloors;
    final enabled = controller.selectedBlockId != null;
    final selected = enabled ? controller.selectedFloorId ?? '' : '';
    return SizedBox(
      key: const Key('inventory-floor-selector'),
      width: 170,
      child: DropdownButtonFormField<String>(
        key: ValueKey('inventory-floor-$selected-${floors.length}-$enabled'),
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Kat',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Tüm katlar')),
          for (final floor in floors)
            DropdownMenuItem(
              value: floor.id,
              child: Text(floor.displayName, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: enabled
            ? (value) => controller.setFloorSelection(
                value == null || value.isEmpty ? null : value,
              )
            : null,
      ),
    );
  }

  Widget _floors() => InventoryFloorView(
    model: controller.floorViewModel,
    onOpenMap: (blockId, floorId) {
      controller.selectSpatialContext(
        blockId: blockId,
        floorId: floorId,
        targetView: InventoryPageView.map,
      );
    },
    onOpenList: (blockId, floorId) {
      controller.selectSpatialContext(
        blockId: blockId,
        floorId: floorId,
        targetView: InventoryPageView.list,
      );
    },
    onCreate: (blockId, floorId) =>
        unawaited(_openFloorQuickCreate(blockId, floorId)),
  );

  Widget _map() {
    final map = _mapController;
    if (map == null || controller.sketch == null) {
      return _message(
        key: const Key('inventory-map-unavailable'),
        icon: Icons.warning_amber_rounded,
        title: 'Şematik kroki güvenle açılamadı.',
        detail:
            'Tanı kodu: '
            '${controller.sketchDiagnosticCode ?? 'inventory_active_revision_unavailable'}',
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: InventoryMapView(
            key: _mapKey,
            controller: map,
            autoLoad: false,
            onCreateTarget: _openQuickCreate,
            onOpenAsset: _openAssetDetail,
            onSelectTarget: _targetSelectionRequest == null
                ? null
                : _acceptDetailTarget,
          ),
        ),
        if (controller.canonicalActiveMapAssets.isEmpty ||
            controller.visibleMapAssets.isEmpty)
          Positioned(
            left: 12,
            right: 12,
            bottom: _targetSelectionRequest == null ? 12 : 92,
            child: IgnorePointer(
              child: Card(
                key: controller.canonicalActiveMapAssets.isEmpty
                    ? const Key('inventory-map-empty')
                    : const Key('inventory-map-empty-filter'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        controller.canonicalActiveMapAssets.isEmpty
                            ? Icons.inventory_2_outlined
                            : Icons.search_off_rounded,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.canonicalActiveMapAssets.isEmpty
                              ? 'Bu projede henüz envanter kaydı yok. Krokiye dokunarak ekleyebilirsiniz.'
                              : 'Arama ve filtrelerle eşleşen kroki kaydı yok.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_targetSelectionRequest case final request?)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              key: const Key('inventory-target-selection'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request == _InventoryDetailTargetRequest.move
                            ? 'Taşınacak yeni konumu kroki üzerinde seçin.'
                            : 'Yeni aktif konumu kroki üzerinde seçin.',
                      ),
                    ),
                    TextButton(
                      key: const Key('inventory-target-selection-cancel'),
                      onPressed: _cancelDetailTargetSelection,
                      child: const Text('Vazgeç'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            children: [
              IconButton.filledTonal(
                key: const Key('inventory-map-zoom-in'),
                tooltip: 'Yaklaştır',
                onPressed: () => _mapKey.currentState?.zoomIn(),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(height: 4),
              IconButton.filledTonal(
                key: const Key('inventory-map-zoom-out'),
                tooltip: 'Uzaklaştır',
                onPressed: () => _mapKey.currentState?.zoomOut(),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(height: 4),
              IconButton.filledTonal(
                key: const Key('inventory-map-fit'),
                tooltip: 'Tamamını göster',
                onPressed: () => _mapKey.currentState?.fitCanvas(),
                icon: const Icon(Icons.fit_screen),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _list(List<InventoryAssetProjection> visible) {
    if (controller.assets.isEmpty) {
      return _message(
        key: const Key('inventory-empty'),
        icon: Icons.inventory_2_outlined,
        title: 'Bu projede henüz envanter kaydı yok.',
      );
    }
    if (visible.isEmpty) {
      return _message(
        key: const Key('inventory-empty-search'),
        icon: Icons.search_off_rounded,
        title: 'Arama ve filtrelerle eşleşen envanter kaydı yok.',
      );
    }
    return ListView.builder(
      key: const Key('inventory-list'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final projection = visible[index];
        final asset = projection.asset;
        final spatial = controller.spatialContextFor(projection);
        final detachedSpatial = controller.detachedSpatialContextFor(
          projection,
        );
        return Card(
          child: ListTile(
            key: Key('inventory-list-${asset.id}'),
            leading: Icon(
              asset.archivedAt == null
                  ? Icons.location_on_outlined
                  : Icons.archive_outlined,
            ),
            title: Text(asset.displayName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detachedSpatial != null)
                  Text(
                    'Krokisi kaldırılmış blok',
                    key: Key('inventory-list-detached-${asset.id}'),
                  ),
                if (detachedSpatial != null)
                  Text(
                    '${detachedSpatial.block.displayName} · '
                    '${detachedSpatial.floor.displayName}',
                    key: Key('inventory-list-detached-context-${asset.id}'),
                  ),
                if (spatial != null && detachedSpatial == null)
                  Text(
                    '${asset.displayName} · ${spatial.block.displayName} · '
                    '${spatial.floor.displayName}',
                    key: Key('inventory-list-spatial-${asset.id}'),
                  ),
                Text(
                  '${inventoryCategoryLabel(asset.category)} • '
                  '${inventoryAssetStatusLabel(asset.status)} • '
                  '${asset.totalQuantity} adet'
                  '${asset.archivedAt == null ? '' : ' • Arşivli'}',
                ),
              ],
            ),
            trailing: Icon(
              asset.archivedAt != null
                  ? Icons.chevron_right_rounded
                  : detachedSpatial != null
                  ? Icons.link_off_rounded
                  : Icons.my_location_rounded,
            ),
            onTap: asset.archivedAt == null
                ? () => _focusFromList(projection)
                : () => unawaited(_openAssetDetail(asset.id)),
          ),
        );
      },
    );
  }

  Widget _failure() => _message(
    key: const Key('inventory-load-failure'),
    icon: Icons.warning_amber_rounded,
    title: controller.lastErrorCode == 'inventory_project_unavailable'
        ? 'Seçili proje artık kullanılamıyor.'
        : 'Envanter güvenle yüklenemedi.',
    detail: 'Tanı kodu: ${controller.lastErrorCode ?? 'inventory_page_failed'}',
    action: FilledButton(
      key: const Key('inventory-retry'),
      onPressed: () => unawaited(controller.refreshProjects()),
      child: const Text('Tekrar dene'),
    ),
  );

  Widget _message({
    required Key key,
    required IconData icon,
    required String title,
    String? detail,
    Widget? action,
  }) => Center(
    key: key,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    ),
  );

  Future<void> _openSketchEditor(
    InventorySketchLaunchIntent launchIntent,
  ) async {
    final projectId = controller.selectedProjectId;
    if (projectId == null) return;
    final result = widget.sketchEditorLauncher != null
        ? await widget.sketchEditorLauncher!(context, projectId, launchIntent)
        : await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => InventorySketchEditorPage(
                application: widget.application,
                projectId: projectId,
                launchIntent: launchIntent,
              ),
            ),
          );
    if (result == true &&
        mounted &&
        controller.selectedProjectId == projectId) {
      await controller.reloadSelected();
    }
  }

  Future<void> _openQuickCreate(
    InventoryPlacementTarget target, {
    String? floorId,
    String? spatialContextLabel,
  }) async {
    final projectId = controller.selectedProjectId;
    if (projectId == null) return;
    final quickController = InventoryAssetQuickCreateController(
      application: widget.application,
      projectId: projectId,
      reloadCanonical: controller.reloadSelected,
      floorId: floorId,
    );
    final createdId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => InventoryAssetQuickForm(
        controller: quickController,
        target: target,
        spatialContextLabel: spatialContextLabel,
        onCreated: (assetId) => Navigator.of(sheetContext).pop(assetId),
      ),
    );
    quickController.dispose();
    _mapController?.clearCreateTarget();
    if (createdId != null && mounted) await _openAssetDetail(createdId);
  }

  Future<void> _openFloorQuickCreate(String blockId, String floorId) async {
    late final InventoryPlacementCoordinates coordinates;
    late final String spatialContextLabel;
    try {
      final block = controller.activeBlocks
          .where((candidate) => candidate.id == blockId)
          .toList(growable: false);
      final floor = controller.activeFloors
          .where(
            (candidate) =>
                candidate.id == floorId && candidate.blockId == blockId,
          )
          .toList(growable: false);
      if (block.length != 1 || floor.length != 1) {
        throw const InventoryFailure('inventory_safe_interior_unavailable');
      }
      coordinates = controller.safeCreateTargetForFloor(
        blockId: blockId,
        floorId: floorId,
      );
      spatialContextLabel =
          '${block.single.displayName} · ${floor.single.displayName}';
    } on Object {
      controller.recordPresentationFailure(
        'inventory_safe_interior_unavailable',
      );
      return;
    }
    await _openQuickCreate(
      InventoryPlacementTarget(x: coordinates.x, y: coordinates.y),
      floorId: floorId,
      spatialContextLabel: spatialContextLabel,
    );
  }

  Future<void> _openAssetDetail(String assetId) async {
    final projectId = controller.selectedProjectId;
    if (projectId == null) return;
    final launcher = widget.assetDetailLauncher;
    if (launcher != null) {
      await launcher(context, projectId, assetId);
      return;
    }
    if (_activeDetailController != null) return;
    final detailController = InventoryAssetDetailController(
      application: widget.application,
      projectId: projectId,
      assetId: assetId,
      reloadMapCanonical: controller.reloadSelected,
      isProjectContextCurrent: () => _canContinueDetailFlow(projectId),
    );
    _activeDetailController = detailController;
    try {
      while (_canContinueDetailFlow(projectId)) {
        final request = await _showAssetDetail(detailController);
        if (!_canContinueDetailFlow(projectId) || request == null) {
          break;
        }
        await _selectTargetForDetail(detailController, request);
      }
    } finally {
      if (identical(_activeDetailController, detailController)) {
        _activeDetailController = null;
      }
      final pendingTarget = _targetSelectionCompleter;
      if (pendingTarget != null && !pendingTarget.isCompleted) {
        pendingTarget.complete(null);
      }
      _targetSelectionCompleter = null;
      _targetSelectionRequest = null;
      detailController.dispose();
    }
    if (_canContinueDetailFlow(projectId)) {
      await controller.reloadSelected();
    }
  }

  Future<_InventoryDetailTargetRequest?> _showAssetDetail(
    InventoryAssetDetailController detailController,
  ) async {
    final unmounted = Completer<void>();
    var routeBuilt = false;
    final request = await showModalBottomSheet<_InventoryDetailTargetRequest>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        routeBuilt = true;
        return _InventoryDetailRouteHost(
          onDisposed: () {
            if (!unmounted.isCompleted) unmounted.complete();
          },
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: InventoryAssetDetailSheet(
              controller: detailController,
              onMoveTargetRequested: () => Navigator.of(
                sheetContext,
              ).pop(_InventoryDetailTargetRequest.move),
              onUnarchiveTargetRequested: () => Navigator.of(
                sheetContext,
              ).pop(_InventoryDetailTargetRequest.unarchive),
            ),
          ),
        );
      },
    );
    if (routeBuilt && !unmounted.isCompleted) await unmounted.future;
    return request;
  }

  Future<void> _selectTargetForDetail(
    InventoryAssetDetailController detailController,
    _InventoryDetailTargetRequest request,
  ) async {
    if (!mounted ||
        controller.selectedProjectId != detailController.projectId ||
        !identical(_activeDetailController, detailController)) {
      _cancelDetailControllerSelection(detailController, request);
      return;
    }
    controller.setView(InventoryPageView.map);
    final map = _mapController;
    if (controller.view != InventoryPageView.map ||
        map == null ||
        map.loadStatus != InventoryMapLoadStatus.ready) {
      _cancelDetailControllerSelection(detailController, request);
      controller.recordMapProjectionFailure(
        map?.lastErrorCode ?? 'inventory_map_failed',
      );
      return;
    }
    final selection = Completer<InventoryPlacementTarget?>();
    _targetSelectionCompleter = selection;
    _targetSelectionRequest = request;
    setState(() {});
    final target = await selection.future;
    if (identical(_targetSelectionCompleter, selection)) {
      _targetSelectionCompleter = null;
      _targetSelectionRequest = null;
    }
    if (!mounted ||
        controller.selectedProjectId != detailController.projectId ||
        !identical(_activeDetailController, detailController) ||
        target == null) {
      _cancelDetailControllerSelection(detailController, request);
    } else if (request == _InventoryDetailTargetRequest.move) {
      if (!detailController.previewMove(target)) {
        detailController.cancelMove();
        controller.recordPresentationFailure(
          'inventory_move_target_unavailable',
        );
      }
    } else if (!detailController.previewUnarchive(target)) {
      detailController.cancelUnarchive();
      controller.recordPresentationFailure(
        'inventory_unarchive_target_unavailable',
      );
    }
    if (mounted) setState(() {});
  }

  void _acceptDetailTarget(InventoryPlacementTarget target) {
    final selection = _targetSelectionCompleter;
    if (selection == null || selection.isCompleted) return;
    selection.complete(target);
  }

  void _cancelDetailTargetSelection() {
    final selection = _targetSelectionCompleter;
    if (selection == null || selection.isCompleted) return;
    selection.complete(null);
  }

  void _cancelPendingTargetForProjectBoundary() {
    final detailController = _activeDetailController;
    final selection = _targetSelectionCompleter;
    if (detailController == null ||
        selection == null ||
        selection.isCompleted ||
        _targetSelectionRequest == null) {
      return;
    }
    final projectChanged =
        controller.selectedProjectId != detailController.projectId;
    final projectUnavailable =
        controller.loadStatus == InventoryPageLoadStatus.failed &&
        controller.lastErrorCode == 'inventory_project_unavailable';
    if (projectChanged || projectUnavailable) {
      _cancelPendingDetailTargetSelection();
    }
  }

  void _cancelPendingDetailTargetSelection() {
    final detailController = _activeDetailController;
    final request = _targetSelectionRequest;
    final selection = _targetSelectionCompleter;
    if (selection == null || selection.isCompleted || request == null) return;
    selection.complete(null);
    _targetSelectionCompleter = null;
    _targetSelectionRequest = null;
    if (detailController != null) {
      _cancelDetailControllerSelection(detailController, request);
    }
  }

  bool _canContinueDetailFlow(String projectId) =>
      mounted &&
      controller.selectedProjectId == projectId &&
      !(controller.loadStatus == InventoryPageLoadStatus.failed &&
          controller.lastErrorCode == 'inventory_project_unavailable');

  void _cancelDetailControllerSelection(
    InventoryAssetDetailController detailController,
    _InventoryDetailTargetRequest request,
  ) {
    if (request == _InventoryDetailTargetRequest.move) {
      detailController.cancelMove();
    } else {
      detailController.cancelUnarchive();
    }
  }

  void _focusFromList(InventoryAssetProjection projection) {
    if (!controller.canFocus(projection)) {
      controller.recordFocusFailure(projection);
      return;
    }
    final spatial = controller.spatialContextFor(
      projection,
      activeBlockOnly: true,
    );
    if (spatial != null) {
      if (!controller.selectSpatialContext(
        blockId: spatial.block.id,
        floorId: spatial.floor.id,
        targetView: InventoryPageView.map,
      )) {
        return;
      }
    } else {
      controller.setBlockSelection(null);
      controller.setView(InventoryPageView.map);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focused = _mapKey.currentState?.focusAsset(projection.asset.id);
      if (focused != true) {
        controller.setView(InventoryPageView.list);
        controller.recordPresentationFailure('inventory_map_focus_failed');
      }
    });
  }
}

class _InventoryDetailRouteHost extends StatefulWidget {
  const _InventoryDetailRouteHost({
    required this.child,
    required this.onDisposed,
  });

  final Widget child;
  final VoidCallback onDisposed;

  @override
  State<_InventoryDetailRouteHost> createState() =>
      _InventoryDetailRouteHostState();
}

class _InventoryDetailRouteHostState extends State<_InventoryDetailRouteHost> {
  @override
  void dispose() {
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

String _normalizeName(String value) => value
    .replaceAll('I', 'ı')
    .replaceAll('İ', 'i')
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int _compareBlocks(InventoryBlockRecord left, InventoryBlockRecord right) {
  final ordinal = left.ordinal.compareTo(right.ordinal);
  return ordinal != 0 ? ordinal : left.id.compareTo(right.id);
}

int _compareFloors(InventoryFloorRecord left, InventoryFloorRecord right) {
  final block = left.blockId.compareTo(right.blockId);
  if (block != 0) return block;
  final ordinal = left.ordinal.compareTo(right.ordinal);
  return ordinal != 0 ? ordinal : left.id.compareTo(right.id);
}

String _safeCode(Object error, {required String fallback}) => switch (error) {
  InventoryFailure() => error.code,
  InventoryGeometryFailure() => error.code,
  _ => fallback,
};
