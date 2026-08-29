import 'dart:async';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/inventory/inventory_sketch_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum InventorySketchLaunchIntent { createOrRecover, editActive }

enum InventorySketchLoadStatus { idle, loading, ready, failed }

enum InventorySketchSaveStatus { saved, saving, failed }

typedef InventoryOrientationSetter =
    Future<void> Function(List<DeviceOrientation> orientations);

Future<void> _defaultOrientationSetter(List<DeviceOrientation> orientations) =>
    SystemChrome.setPreferredOrientations(orientations);

class InventorySketchEditorController extends ChangeNotifier {
  InventorySketchEditorController({
    required this.application,
    required this.projectId,
    required this.launchIntent,
    RecordIdFactory? idFactory,
    this.autosaveDelay = const Duration(milliseconds: 500),
  }) : idFactory = idFactory ?? RecordId.randomUuid;

  final InventoryApplicationPort application;
  final String projectId;
  final InventorySketchLaunchIntent launchIntent;
  final RecordIdFactory idFactory;
  final Duration autosaveDelay;

  static const lockedBaseGeometryCode =
      'inventory_base_geometry_edit_not_supported';

  InventorySketchLoadStatus loadStatus = InventorySketchLoadStatus.idle;
  InventorySketchSaveStatus saveStatus = InventorySketchSaveStatus.saved;
  InventorySketchEditorSnapshot? editor;
  InventoryGeometry? acknowledgedGeometry;
  String? lastErrorCode;
  bool finalizing = false;
  bool finalizePersisted = false;

  String? _sketchId;
  String? _draftRevisionId;
  int? _expectedSketchRevision;
  int? _expectedContentRevision;
  Timer? _autosaveTimer;
  Future<bool>? _saveDrain;
  _PendingDraftSave? _pendingSave;
  int _geometryGeneration = 0;
  int? _normalSaveEligibleGeneration;
  bool _forceDrainRequested = false;
  bool _finalizeBlockedByStaleRevision = false;
  bool _disposed = false;
  int _basePolygonCount = 0;
  Set<int> _existingMappedPolygonIndexes = const {};
  List<InventoryBlockDraft> _newBlocks = const [];
  List<InventoryBlockDraft> _acknowledgedNewBlocks = const [];
  List<List<InventoryBlockDraft>> _undoBlockHistory = const [];
  List<List<InventoryBlockDraft>> _redoBlockHistory = const [];
  bool _freeLengthNextSegment = false;

  String? get sketchId => _sketchId;
  String? get draftRevisionId => _draftRevisionId;
  int? get expectedSketchRevision => _expectedSketchRevision;
  int? get expectedContentRevision => _expectedContentRevision;
  List<InventoryBlockDraft> get newBlocks => _newBlocks;
  bool get freeLengthNextSegment => _freeLengthNextSegment;

  InventoryPolyline? get workingPolyline {
    final current = editor;
    final index = current?.workingPolylineIndex;
    if (current == null ||
        index == null ||
        index < 0 ||
        index >= current.geometry.polylines.length) {
      return null;
    }
    return current.geometry.polylines[index];
  }

  bool get hasUnacknowledgedGeometry {
    final candidate = editor?.geometry;
    final acknowledged = acknowledgedGeometry;
    return _pendingSave != null ||
        (candidate != null &&
            acknowledged != null &&
            candidate.canonicalJson != acknowledged.canonicalJson);
  }

  String? get saveLabel {
    if (acknowledgedGeometry == null) return null;
    return switch (saveStatus) {
      InventorySketchSaveStatus.saved => 'Kaydedildi',
      InventorySketchSaveStatus.saving => 'Kaydediliyor…',
      InventorySketchSaveStatus.failed => 'Kaydedilemedi',
    };
  }

  bool get isFinalizeEnabled {
    final candidate = editor?.geometry;
    if (loadStatus != InventorySketchLoadStatus.ready ||
        candidate == null ||
        finalizing ||
        finalizePersisted ||
        _finalizeBlockedByStaleRevision ||
        !_hasDraftIdentity ||
        !_hasCompleteSpatialMetadata(candidate)) {
      return false;
    }
    try {
      candidate.validateFinalizable();
      return true;
    } on InventoryGeometryFailure {
      return false;
    }
  }

  bool get _hasDraftIdentity =>
      _sketchId != null &&
      _draftRevisionId != null &&
      _expectedSketchRevision != null &&
      _expectedContentRevision != null;

  Future<void> initialize() async {
    if (loadStatus == InventorySketchLoadStatus.loading ||
        loadStatus == InventorySketchLoadStatus.ready) {
      return;
    }
    loadStatus = InventorySketchLoadStatus.loading;
    lastErrorCode = null;
    _notify();
    try {
      var projection = await application.loadPrimarySketch(projectId);
      if (projection == null) {
        if (launchIntent != InventorySketchLaunchIntent.createOrRecover) {
          throw const InventoryFailure('inventory_active_revision_unavailable');
        }
        final operationId = _nextId();
        final sketchId = _nextId();
        final draftRevisionId = _nextId();
        await application.createSketch(
          CreateInventorySketchCommand(
            operationId: operationId,
            projectId: projectId,
            sketchId: sketchId,
            draftRevisionId: draftRevisionId,
          ),
        );
        projection = await application.loadPrimarySketch(projectId);
        if (projection == null ||
            projection.sketch.id != sketchId ||
            projection.draftRevision?.id != draftRevisionId) {
          throw const InventoryFailure(
            'inventory_sketch_launch_verification_failed',
          );
        }
      } else if (projection.draftRevision == null) {
        if (launchIntent != InventorySketchLaunchIntent.editActive) {
          throw const InventoryFailure('inventory_sketch_launch_invalid');
        }
        final active = projection.activeRevision;
        if (active == null) {
          throw const InventoryFailure('inventory_active_revision_unavailable');
        }
        final newDraftId = _nextId();
        await application.startSketchEdit(
          StartInventorySketchEditCommand(
            operationId: _nextId(),
            projectId: projectId,
            sketchId: projection.sketch.id,
            activeRevisionId: active.id,
            newDraftRevisionId: newDraftId,
            expectedSketchRevision: projection.sketch.revision,
          ),
        );
        final reloaded = await application.loadPrimarySketch(projectId);
        if (reloaded == null ||
            reloaded.sketch.id != projection.sketch.id ||
            reloaded.activeRevision?.id != active.id ||
            reloaded.draftRevision?.id != newDraftId ||
            reloaded.draftRevision?.baseRevisionId != active.id) {
          throw const InventoryFailure(
            'inventory_sketch_launch_verification_failed',
          );
        }
        projection = reloaded;
      }
      _adoptProjection(projection);
      loadStatus = InventorySketchLoadStatus.ready;
      saveStatus = InventorySketchSaveStatus.saved;
      lastErrorCode = null;
    } on Object catch (error) {
      loadStatus = InventorySketchLoadStatus.failed;
      lastErrorCode = _safeCode(error);
    }
    _notify();
  }

  void setMode(InventorySketchEditorMode mode) {
    final current = editor;
    if (current == null || current.mode == mode) return;
    editor = current.withMode(mode);
    _notify();
  }

  InventorySketchDrawProposal? proposeDrawPoint(InventorySketchPoint point) =>
      editor?.proposeDrawPoint(point, smartAlignment: !_freeLengthNextSegment);

  bool drawPoint(InventorySketchPoint point) {
    final current = editor;
    if (current == null) return false;
    final next = current.drawPoint(
      point,
      smartAlignment: !_freeLengthNextSegment,
    );
    final commitsSegment =
        next != null &&
        current.hasWorkingPolyline &&
        current.geometry.canonicalJson != next.geometry.canonicalJson;
    final applied = _applyEditorAction(next);
    if (applied && commitsSegment && _freeLengthNextSegment) {
      _freeLengthNextSegment = false;
      _notify();
    }
    return applied;
  }

  void setFreeLengthNextSegment(bool value) {
    final current = editor;
    if (current == null ||
        current.mode != InventorySketchEditorMode.draw ||
        !current.hasWorkingPolyline ||
        _freeLengthNextSegment == value) {
      return;
    }
    _freeLengthNextSegment = value;
    _notify();
  }

  void dismissLockedGeometryMessage() {
    if (lastErrorCode != lockedBaseGeometryCode) return;
    lastErrorCode = null;
    _notify();
  }

  bool shouldCloseAt(InventorySketchPoint point) {
    final working = workingPolyline;
    if (working == null || working.points.length < 3) return false;
    final first = working.points.first;
    final dx = first.x - point.x;
    final dy = first.y - point.y;
    const radius = InventoryGeometryContract.sketchGridStep * 2;
    return dx * dx + dy * dy <= radius * radius &&
        proposeDrawPoint(first)?.end == first;
  }

  InventoryBlockDraft createBlockDraft({
    required String displayName,
    required int floorCount,
  }) {
    final current = editor;
    final polygonIndex = current?.workingPolylineIndex;
    if (current == null || polygonIndex == null) {
      throw const InventoryFailure('inventory_block_polygon_not_open');
    }
    InventorySpatialContract.validateFloorCount(floorCount);
    return InventoryBlockDraft(
      id: _nextId(),
      displayName: InventorySpatialContract.normalizeBlockName(displayName),
      polygonIndex: polygonIndex,
      floors: [
        for (var ordinal = 1; ordinal <= floorCount; ordinal += 1)
          InventoryFloorDraft(
            id: _nextId(),
            displayName: '$ordinal. Kat',
            ordinal: ordinal,
          ),
      ],
    );
  }

  bool closeWorkingBlock(InventoryBlockDraft definition) {
    final current = editor;
    final index = current?.workingPolylineIndex;
    final working = workingPolyline;
    if (current == null ||
        index == null ||
        working == null ||
        working.points.length < 3 ||
        definition.polygonIndex != index) {
      return false;
    }
    final next = current.drawPoint(
      working.points.first,
      smartAlignment: !_freeLengthNextSegment,
    );
    if (next == null || next.workingPolylineIndex != null) return false;
    try {
      definition.validate(next.geometry);
      final polygons = <InventoryPolyline>[
        for (final mappedIndex in _existingMappedPolygonIndexes)
          next.geometry.polylines[mappedIndex],
        for (final block in _newBlocks)
          next.geometry.polylines[block.polygonIndex],
        next.geometry.polylines[index],
      ];
      InventorySpatialContract.validateNonOverlappingPolygons(polygons);
    } on InventoryFailure catch (error) {
      lastErrorCode = error.code;
      _notify();
      return false;
    }
    final applied = _applyEditorAction(next, addedBlock: definition);
    if (applied && _freeLengthNextSegment) {
      _freeLengthNextSegment = false;
      _notify();
    }
    return applied;
  }

  bool finishWorkingPolyline() =>
      _applyEditorAction(editor?.finishWorkingPolyline());

  void selectAt(Offset viewPoint, InventoryViewport viewport) {
    final current = editor;
    if (current == null) return;
    final next = current.selectAt(viewPoint, viewport);
    if (identical(next, current) && next.selection == current.selection) return;
    editor = next;
    _notify();
  }

  bool deleteSelection() => _applyEditorAction(editor?.deleteSelection());

  bool undo() {
    final current = editor;
    if (current == null || !current.canUndo || _undoBlockHistory.isEmpty) {
      return false;
    }
    final previousBlocks = _undoBlockHistory.last;
    _undoBlockHistory = List<List<InventoryBlockDraft>>.unmodifiable(
      _undoBlockHistory.sublist(0, _undoBlockHistory.length - 1),
    );
    _redoBlockHistory = _boundedBlockHistory([
      ..._redoBlockHistory,
      _newBlocks,
    ]);
    return _applyHistoryFrame(current.undo(), previousBlocks);
  }

  bool redo() {
    final current = editor;
    if (current == null || !current.canRedo || _redoBlockHistory.isEmpty) {
      return false;
    }
    final nextBlocks = _redoBlockHistory.last;
    _redoBlockHistory = List<List<InventoryBlockDraft>>.unmodifiable(
      _redoBlockHistory.sublist(0, _redoBlockHistory.length - 1),
    );
    _undoBlockHistory = _boundedBlockHistory([
      ..._undoBlockHistory,
      _newBlocks,
    ]);
    return _applyHistoryFrame(current.redo(), nextBlocks);
  }

  bool _applyEditorAction(
    InventorySketchEditorSnapshot? next, {
    InventoryBlockDraft? addedBlock,
  }) {
    final current = editor;
    if (current == null || next == null || identical(current, next)) {
      return false;
    }
    final geometryChanged =
        current.geometry.canonicalJson != next.geometry.canonicalJson;
    if (geometryChanged && !_preservesEditActiveBase(next.geometry)) {
      lastErrorCode = lockedBaseGeometryCode;
      _notify();
      return false;
    }
    final nextBlocks = geometryChanged
        ? _remapNewBlocks(
            current.geometry,
            next.geometry,
            addedBlock: addedBlock,
          )
        : _newBlocks;
    if (nextBlocks == null) {
      lastErrorCode = 'inventory_block_metadata_history_invalid';
      _notify();
      return false;
    }
    _undoBlockHistory = _boundedBlockHistory([
      ..._undoBlockHistory,
      _newBlocks,
    ]);
    _redoBlockHistory = const [];
    editor = next;
    _newBlocks = nextBlocks;
    if (geometryChanged) {
      _scheduleAutosave();
    }
    _notify();
    return true;
  }

  bool _applyHistoryFrame(
    InventorySketchEditorSnapshot next,
    List<InventoryBlockDraft> nextBlocks,
  ) {
    final current = editor!;
    final geometryChanged =
        current.geometry.canonicalJson != next.geometry.canonicalJson;
    editor = next;
    _newBlocks = nextBlocks;
    if (geometryChanged) _scheduleAutosave();
    _notify();
    return true;
  }

  List<InventoryBlockDraft>? _remapNewBlocks(
    InventoryGeometry current,
    InventoryGeometry next, {
    InventoryBlockDraft? addedBlock,
  }) {
    final remapped = <InventoryBlockDraft>[];
    final usedIndexes = <int>{};
    for (final block in _newBlocks) {
      if (block.polygonIndex < 0 ||
          block.polygonIndex >= current.polylines.length) {
        return null;
      }
      final source = current.polylines[block.polygonIndex];
      final matches = <int>[
        for (
          var index = _basePolygonCount;
          index < next.polylines.length;
          index += 1
        )
          if (!usedIndexes.contains(index) &&
              _samePolyline(source, next.polylines[index]))
            index,
      ];
      if (matches.length > 1) return null;
      if (matches.isEmpty) continue;
      final index = matches.single;
      usedIndexes.add(index);
      remapped.add(_blockAtPolygonIndex(block, index));
    }
    if (addedBlock != null) {
      final index = addedBlock.polygonIndex;
      if (index < _basePolygonCount ||
          index >= next.polylines.length ||
          usedIndexes.contains(index) ||
          !next.polylines[index].closed) {
        return null;
      }
      usedIndexes.add(index);
      remapped.add(_blockAtPolygonIndex(addedBlock, index));
    }
    remapped.sort(
      (first, second) => first.polygonIndex.compareTo(second.polygonIndex),
    );
    return List<InventoryBlockDraft>.unmodifiable(remapped);
  }

  InventoryBlockDraft _blockAtPolygonIndex(
    InventoryBlockDraft block,
    int polygonIndex,
  ) => block.polygonIndex == polygonIndex
      ? block
      : InventoryBlockDraft(
          id: block.id,
          displayName: block.displayName,
          polygonIndex: polygonIndex,
          floors: block.floors,
        );

  bool _samePolyline(InventoryPolyline first, InventoryPolyline second) {
    if (first.closed != second.closed ||
        first.points.length != second.points.length) {
      return false;
    }
    for (var index = 0; index < first.points.length; index += 1) {
      if (first.points[index] != second.points[index]) return false;
    }
    return true;
  }

  bool _preservesEditActiveBase(InventoryGeometry candidate) {
    if (launchIntent != InventorySketchLaunchIntent.editActive) return true;
    final acknowledged = acknowledgedGeometry;
    if (acknowledged == null ||
        candidate.polylines.length < _basePolygonCount ||
        acknowledged.polylines.length < _basePolygonCount) {
      return false;
    }
    for (var index = 0; index < _basePolygonCount; index += 1) {
      if (!_samePolyline(
        acknowledged.polylines[index],
        candidate.polylines[index],
      )) {
        return false;
      }
    }
    return true;
  }

  List<List<InventoryBlockDraft>> _boundedBlockHistory(
    Iterable<List<InventoryBlockDraft>> values,
  ) {
    final bounded = List<List<InventoryBlockDraft>>.of(values);
    if (bounded.length > InventorySketchEditorSnapshot.maximumHistory) {
      bounded.removeRange(
        0,
        bounded.length - InventorySketchEditorSnapshot.maximumHistory,
      );
    }
    return List<List<InventoryBlockDraft>>.unmodifiable(bounded);
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _geometryGeneration += 1;
    final scheduledGeneration = _geometryGeneration;
    _normalSaveEligibleGeneration = null;
    saveStatus = InventorySketchSaveStatus.saving;
    lastErrorCode = null;
    _autosaveTimer = Timer(autosaveDelay, () {
      _autosaveTimer = null;
      if (_geometryGeneration != scheduledGeneration) return;
      _normalSaveEligibleGeneration = scheduledGeneration;
      unawaited(_ensureSaveDrain());
    });
  }

  Future<bool> forceSave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _forceDrainRequested = true;
    return _ensureSaveDrain();
  }

  Future<bool> _ensureSaveDrain() {
    final running = _saveDrain;
    if (running != null) return running;
    late final Future<bool> tracked;
    tracked = _drainSaves().whenComplete(() {
      if (identical(_saveDrain, tracked)) _saveDrain = null;
    });
    _saveDrain = tracked;
    return tracked;
  }

  Future<bool> _drainSaves() async {
    if (!_hasDraftIdentity || editor == null || acknowledgedGeometry == null) {
      _forceDrainRequested = false;
      saveStatus = InventorySketchSaveStatus.failed;
      lastErrorCode = 'inventory_sketch_draft_unavailable';
      _notify();
      return false;
    }
    while (hasUnacknowledgedGeometry) {
      if (_pendingSave == null &&
          !_forceDrainRequested &&
          _normalSaveEligibleGeneration != _geometryGeneration) {
        saveStatus = InventorySketchSaveStatus.saving;
        _notify();
        return true;
      }
      final pending = _pendingSave ?? _createPendingSave();
      _pendingSave = pending;
      saveStatus = InventorySketchSaveStatus.saving;
      lastErrorCode = null;
      _notify();
      try {
        final result = await application.autosaveSketchDraft(pending.command);
        final projection = await application.loadPrimarySketch(projectId);
        final draft = _verifiedDraft(
          projection,
          expectedGeometry: pending.geometry,
          expectedNewBlocks: pending.command.newBlocks,
        );
        if (result.commandType != InventoryCommandType.sketchDraftAutosave ||
            result.projectId != projectId ||
            result.sourceId != projection!.sketch.id ||
            result.sourceRevision != projection.sketch.revision ||
            result.supportingId != draft.id ||
            result.supportingRevision != draft.contentRevision) {
          throw const InventoryFailure(
            'inventory_sketch_save_verification_failed',
          );
        }
        acknowledgedGeometry = draft.geometry;
        _acknowledgedNewBlocks = projection.draftNewBlocks;
        _expectedSketchRevision = projection.sketch.revision;
        _expectedContentRevision = draft.contentRevision;
        _pendingSave = null;
        if (_normalSaveEligibleGeneration == pending.geometryGeneration) {
          _normalSaveEligibleGeneration = null;
        }
        _notify();
      } on Object catch (error) {
        _forceDrainRequested = false;
        saveStatus = InventorySketchSaveStatus.failed;
        lastErrorCode = _safeCode(error);
        _notify();
        return false;
      }
    }
    _forceDrainRequested = false;
    saveStatus = InventorySketchSaveStatus.saved;
    lastErrorCode = null;
    _notify();
    return true;
  }

  _PendingDraftSave _createPendingSave() {
    final current = editor!.geometry;
    return _PendingDraftSave(
      geometry: current,
      geometryGeneration: _geometryGeneration,
      command: AutosaveInventorySketchDraftCommand(
        operationId: _nextId(),
        projectId: projectId,
        sketchId: _sketchId!,
        draftRevisionId: _draftRevisionId!,
        expectedSketchRevision: _expectedSketchRevision!,
        expectedContentRevision: _expectedContentRevision!,
        geometry: current,
        newBlocks: _newBlocks,
      ),
    );
  }

  void discardUnsaved() {
    final acknowledged = acknowledgedGeometry;
    final current = editor;
    if (acknowledged == null || current == null) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _normalSaveEligibleGeneration = null;
    _forceDrainRequested = false;
    _pendingSave = null;
    editor = InventorySketchEditorSnapshot.recover(
      acknowledged,
      mode: current.mode,
    );
    _newBlocks = _acknowledgedNewBlocks;
    _undoBlockHistory = const [];
    _redoBlockHistory = const [];
    _freeLengthNextSegment = false;
    saveStatus = InventorySketchSaveStatus.saved;
    lastErrorCode = null;
    _notify();
  }

  Future<bool> finalizeDraft() async {
    if (finalizing ||
        finalizePersisted ||
        _finalizeBlockedByStaleRevision ||
        !_hasDraftIdentity) {
      return false;
    }
    final candidate = editor?.geometry;
    if (candidate == null) return false;
    try {
      candidate.validateFinalizable();
      if (!_hasCompleteSpatialMetadata(candidate)) {
        throw const InventoryFailure('inventory_block_metadata_incomplete');
      }
    } on Object catch (error) {
      lastErrorCode = _safeCode(error);
      _notify();
      return false;
    }
    finalizing = true;
    lastErrorCode = null;
    _notify();
    try {
      if (!await forceSave()) return false;
      final intended = editor!.geometry;
      intended.validateFinalizable();
      if (!_hasCompleteSpatialMetadata(intended)) {
        throw const InventoryFailure('inventory_block_metadata_incomplete');
      }
      final expectedSketchRevision = _expectedSketchRevision!;
      final expectedContentRevision = _expectedContentRevision!;
      final before = await application.loadPrimarySketch(projectId);
      final draft = _verifiedDraft(
        before,
        expectedGeometry: intended,
        expectedNewBlocks: _newBlocks,
      );
      if (before!.sketch.revision != expectedSketchRevision) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      if (draft.contentRevision != expectedContentRevision) {
        throw const InventoryFailure('inventory_stale_content_revision');
      }
      final targetDraftId = draft.id;
      final result = await application.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _nextId(),
          projectId: projectId,
          sketchId: before.sketch.id,
          draftRevisionId: targetDraftId,
          expectedSketchRevision: expectedSketchRevision,
          expectedContentRevision: expectedContentRevision,
          newBlocks: _newBlocks,
        ),
      );
      final after = await application.loadPrimarySketch(projectId);
      if (after == null ||
          after.sketch.id != before.sketch.id ||
          after.draftRevision != null ||
          after.activeRevision?.id != targetDraftId ||
          after.activeRevision?.geometry.canonicalJson !=
              intended.canonicalJson ||
          result.commandType != InventoryCommandType.sketchFinalize ||
          result.sourceId != after.sketch.id ||
          result.sourceRevision != after.sketch.revision ||
          result.supportingId != targetDraftId ||
          result.supportingRevision != after.activeRevision?.contentRevision) {
        throw const InventoryFailure(
          'inventory_sketch_finalize_verification_failed',
        );
      }
      finalizePersisted = true;
      lastErrorCode = null;
      return true;
    } on Object catch (error) {
      final errorCode = _safeCode(error);
      lastErrorCode = errorCode;
      if (errorCode == 'inventory_stale_revision' ||
          errorCode == 'inventory_stale_content_revision') {
        _finalizeBlockedByStaleRevision = true;
      }
      return false;
    } finally {
      finalizing = false;
      _notify();
    }
  }

  void recordHandledError(Object error) {
    lastErrorCode = _safeCode(error);
    _notify();
  }

  InventorySketchRevisionRecord _verifiedDraft(
    InventoryPrimarySketchProjection? projection, {
    required InventoryGeometry expectedGeometry,
    List<InventoryBlockDraft>? expectedNewBlocks,
  }) {
    final draft = projection?.draftRevision;
    if (projection == null ||
        projection.sketch.projectId != projectId ||
        projection.sketch.id != _sketchId ||
        projection.sketch.draftRevisionId != _draftRevisionId ||
        draft == null ||
        draft.id != _draftRevisionId ||
        draft.sketchId != _sketchId ||
        draft.projectId != projectId ||
        draft.state != InventorySketchRevisionState.draft ||
        draft.geometry.canonicalJson != expectedGeometry.canonicalJson ||
        draft.geometrySha256 != expectedGeometry.sha256 ||
        (expectedNewBlocks != null &&
            !_sameBlockDefinitions(
              projection.draftNewBlocks,
              expectedNewBlocks,
            ))) {
      throw const InventoryFailure('inventory_sketch_save_verification_failed');
    }
    return draft;
  }

  bool _sameBlockDefinitions(
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
      for (
        var floorIndex = 0;
        floorIndex < left.floors.length;
        floorIndex += 1
      ) {
        final leftFloor = left.floors[floorIndex];
        final rightFloor = right.floors[floorIndex];
        if (leftFloor.id != rightFloor.id ||
            leftFloor.displayName != rightFloor.displayName ||
            leftFloor.ordinal != rightFloor.ordinal) {
          return false;
        }
      }
    }
    return true;
  }

  void _adoptProjection(InventoryPrimarySketchProjection projection) {
    final draft = projection.draftRevision;
    if (projection.sketch.projectId != projectId ||
        !projection.sketch.isPrimary ||
        projection.sketch.archivedAt != null ||
        draft == null ||
        projection.sketch.draftRevisionId != draft.id ||
        draft.projectId != projectId ||
        draft.sketchId != projection.sketch.id ||
        draft.state != InventorySketchRevisionState.draft) {
      throw const InventoryFailure('inventory_sketch_draft_unavailable');
    }
    if (launchIntent == InventorySketchLaunchIntent.editActive) {
      final active = projection.activeRevision;
      if (active == null || draft.baseRevisionId != active.id) {
        throw const InventoryFailure('inventory_sketch_edit_lifecycle_invalid');
      }
    }
    _sketchId = projection.sketch.id;
    _draftRevisionId = draft.id;
    _expectedSketchRevision = projection.sketch.revision;
    _expectedContentRevision = draft.contentRevision;
    acknowledgedGeometry = draft.geometry;
    _basePolygonCount =
        projection.activeRevision?.geometry.polylines.length ??
        projection.draftLegacyPolygonCount;
    _existingMappedPolygonIndexes = projection.draftBlockPolygons
        .map((mapping) => mapping.polygonIndex)
        .toSet();
    _newBlocks = projection.draftNewBlocks;
    _acknowledgedNewBlocks = projection.draftNewBlocks;
    _undoBlockHistory = const [];
    _redoBlockHistory = const [];
    _freeLengthNextSegment = false;
    editor = InventorySketchEditorSnapshot.recover(draft.geometry);
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _geometryGeneration = 0;
    _normalSaveEligibleGeneration = null;
    _forceDrainRequested = false;
    _finalizeBlockedByStaleRevision = false;
    _pendingSave = null;
  }

  bool _hasCompleteSpatialMetadata(InventoryGeometry geometry) {
    final expectedIndexes = <int>{
      for (
        var index = _basePolygonCount;
        index < geometry.polylines.length;
        index += 1
      )
        index,
    };
    final actualIndexes = _newBlocks.map((block) => block.polygonIndex).toSet();
    if (expectedIndexes.length != actualIndexes.length ||
        !actualIndexes.containsAll(expectedIndexes)) {
      return false;
    }
    try {
      final polygons = <InventoryPolyline>[
        for (final index in _existingMappedPolygonIndexes)
          geometry.polylines[index],
        for (final block in _newBlocks) geometry.polylines[block.polygonIndex],
      ];
      InventorySpatialContract.validateNonOverlappingPolygons(polygons);
      return true;
    } on Object {
      return false;
    }
  }

  String _nextId() {
    final value = idFactory();
    if (!RecordId.isUuid(value)) {
      throw const InventoryFailure('inventory_invalid_generated_id');
    }
    return value;
  }

  String _safeCode(Object error) => switch (error) {
    InventoryFailure() => error.code,
    InventoryGeometryFailure() => error.code,
    _ => 'inventory_editor_failed',
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autosaveTimer?.cancel();
    super.dispose();
  }
}

class InventorySketchEditorPage extends StatefulWidget {
  const InventorySketchEditorPage({
    required this.application,
    required this.projectId,
    required this.launchIntent,
    this.idFactory,
    this.orientationSetter = _defaultOrientationSetter,
    super.key,
  });

  static const landscapeOrientations = <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const standardOrientations = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  final InventoryApplicationPort application;
  final String projectId;
  final InventorySketchLaunchIntent launchIntent;
  final RecordIdFactory? idFactory;
  final InventoryOrientationSetter orientationSetter;

  @override
  State<InventorySketchEditorPage> createState() =>
      InventorySketchEditorPageState();
}

class InventorySketchEditorPageState extends State<InventorySketchEditorPage>
    with WidgetsBindingObserver {
  final _canvasKey = GlobalKey<InventorySketchCanvasState>();
  late final InventorySketchEditorController controller;
  Future<void> _lifecycleTail = Future<void>.value();
  bool _allowPop = false;
  bool _standardRestored = false;
  bool _exitBlockedBySave = false;
  bool _orientationFailed = false;
  bool _orientationRestoreFailed = false;
  bool _finalizeFailed = false;
  Object? _pendingPopResult;
  InventorySketchDrawProposal? _previewProposal;

  @override
  void initState() {
    super.initState();
    controller = InventorySketchEditorController(
      application: widget.application,
      projectId: widget.projectId,
      launchIntent: widget.launchIntent,
      idFactory: widget.idFactory,
    )..addListener(_refresh);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_enterEditor());
    });
  }

  Future<void> _enterEditor() async {
    try {
      await widget.orientationSetter(
        InventorySketchEditorPage.landscapeOrientations,
      );
      if (!mounted) return;
      _standardRestored = false;
      _orientationFailed = false;
      _orientationRestoreFailed = false;
      await controller.initialize();
    } on Object catch (error) {
      controller.recordHandledError(error);
      if (mounted) setState(() => _orientationFailed = true);
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _previewProposal = null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleTail = _lifecycleTail.then((_) => _handleLifecycle(state));
  }

  Future<void> _handleLifecycle(AppLifecycleState state) async {
    if (!mounted) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      await controller.forceSave();
      await _restoreStandard();
      return;
    }
    if (state == AppLifecycleState.resumed &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      try {
        await widget.orientationSetter(
          InventorySketchEditorPage.landscapeOrientations,
        );
        if (mounted) {
          setState(() {
            _standardRestored = false;
            _orientationFailed = false;
            _orientationRestoreFailed = false;
          });
        }
      } on Object catch (error) {
        controller.recordHandledError(error);
        if (mounted) setState(() => _orientationFailed = true);
      }
    }
  }

  Future<void> waitForLifecycleForTest() => _lifecycleTail;

  Future<bool> _restoreStandard() async {
    if (_standardRestored) return true;
    try {
      await widget.orientationSetter(
        InventorySketchEditorPage.standardOrientations,
      );
      if (mounted) {
        setState(() {
          _standardRestored = true;
          _orientationFailed = false;
          _orientationRestoreFailed = false;
        });
      } else {
        _standardRestored = true;
      }
      return true;
    } on Object catch (error) {
      controller.recordHandledError(error);
      if (mounted) {
        setState(() {
          _orientationFailed = true;
          _orientationRestoreFailed = true;
        });
      }
      return false;
    }
  }

  Future<void> _attemptExit([Object? result]) async {
    if (_allowPop) return;
    _pendingPopResult = result;
    final hasSaveableDraft =
        controller.editor != null && controller.acknowledgedGeometry != null;
    final saved =
        controller.finalizePersisted ||
        !hasSaveableDraft ||
        await controller.forceSave();
    if (!saved) {
      if (mounted) setState(() => _exitBlockedBySave = true);
      return;
    }
    if (!await _restoreStandard()) return;
    if (!mounted) return;
    setState(() {
      _exitBlockedBySave = false;
      _allowPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(_pendingPopResult);
    });
  }

  Future<void> _finalizeAndExit() async {
    if (controller.finalizing) return;
    if (_finalizeFailed && mounted) {
      setState(() => _finalizeFailed = false);
    }
    final finalized =
        controller.finalizePersisted || await controller.finalizeDraft();
    if (!mounted) return;
    if (!finalized) {
      setState(() => _finalizeFailed = true);
      return;
    }
    await _attemptExit(true);
  }

  void _handleDrawPoint(InventorySketchPoint point) {
    if (controller.shouldCloseAt(point)) {
      unawaited(_closeCurrentBlock());
      return;
    }
    controller.drawPoint(point);
  }

  Future<void> _closeCurrentBlock() async {
    final working = controller.workingPolyline;
    if (working == null || working.points.length < 3) return;
    final input = await showDialog<_InventoryBlockMetadataInput>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _InventoryBlockMetadataDialog(),
    );
    if (input == null || !mounted) return;
    try {
      final definition = controller.createBlockDraft(
        displayName: input.displayName,
        floorCount: input.floorCount,
      );
      controller.closeWorkingBlock(definition);
    } on Object catch (error) {
      controller.recordHandledError(error);
    }
  }

  void _updatePreview(Offset localPosition) {
    final viewport = _canvasKey.currentState?.viewport;
    final editor = controller.editor;
    if (viewport == null ||
        editor == null ||
        editor.mode != InventorySketchEditorMode.draw ||
        !editor.hasWorkingPolyline) {
      if (_previewProposal != null) {
        setState(() => _previewProposal = null);
      }
      return;
    }
    final point = viewport.snapViewPoint(localPosition);
    InventorySketchDrawProposal? proposal;
    if (point != null && controller.shouldCloseAt(point)) {
      proposal = controller.proposeDrawPoint(
        controller.workingPolyline!.points.first,
      );
    } else if (point != null) {
      proposal = controller.proposeDrawPoint(point);
    }
    if (proposal != _previewProposal) {
      setState(() => _previewProposal = proposal);
    }
  }

  Future<void> _retryBlockedExit() => _attemptExit(_pendingPopResult);

  Future<void> _discardAndExit() async {
    controller.discardUnsaved();
    await _attemptExit(_pendingPopResult);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller
      ..removeListener(_refresh)
      ..dispose();
    if (!_standardRestored) {
      unawaited(
        widget.orientationSetter(
          InventorySketchEditorPage.standardOrientations,
        ),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_attemptExit(result));
      },
      child: Scaffold(body: SafeArea(child: _buildBody(context))),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.loadStatus == InventorySketchLoadStatus.loading ||
        controller.loadStatus == InventorySketchLoadStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.loadStatus == InventorySketchLoadStatus.failed ||
        controller.editor == null) {
      return _EditorFailurePanel(
        code: controller.lastErrorCode ?? 'inventory_editor_failed',
        onRetry: controller.initialize,
        onBack: _attemptExit,
      );
    }
    final editor = controller.editor!;
    final finalizeLabel =
        widget.launchIntent == InventorySketchLaunchIntent.editActive
        ? 'Krokiyi yayınla ve güncelle'
        : 'Krokiyi yayınla';
    return Stack(
      key: const Key('inventory-editor-fullscreen-workspace'),
      fit: StackFit.expand,
      children: [
        MouseRegion(
          onHover: (event) => _updatePreview(event.localPosition),
          onExit: (_) {
            if (_previewProposal != null) {
              setState(() => _previewProposal = null);
            }
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: (event) => _updatePreview(event.localPosition),
            child: Stack(
              fit: StackFit.expand,
              children: [
                InventorySketchCanvas(
                  key: _canvasKey,
                  snapshot: editor,
                  onDrawPoint: _handleDrawPoint,
                  onSelect: controller.selectAt,
                ),
                IgnorePointer(
                  child: CustomPaint(
                    key: const Key('inventory-editor-edge-preview'),
                    painter: _InventoryProposedEdgePainter(
                      viewport: _canvasKey.currentState?.viewport,
                      start: _previewProposal?.start,
                      end: _previewProposal?.end,
                      alignmentGuide: _previewProposal?.alignmentGuide,
                    ),
                  ),
                ),
                if (_previewProposal?.alignmentGuide != null)
                  IgnorePointer(
                    child: Semantics(
                      key: const Key('inventory-editor-smart-alignment-guide'),
                      container: true,
                      label: 'Akıllı hizalama kılavuzu',
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          right: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_exitBlockedBySave)
                MaterialBanner(
                  content: const Text(
                    'Taslak kaydedilemedi. Şematik kroki açık bırakıldı.',
                  ),
                  actions: [
                    TextButton(
                      key: const Key('inventory-editor-retry-save'),
                      onPressed: () => unawaited(_retryBlockedExit()),
                      child: const Text('Tekrar dene'),
                    ),
                    TextButton(
                      key: const Key('inventory-editor-discard-unsaved'),
                      onPressed: () => unawaited(_discardAndExit()),
                      child: const Text('Kaydedilmemiş değişiklikleri bırak'),
                    ),
                  ],
                ),
              if (_finalizeFailed)
                MaterialBanner(
                  key: const Key('inventory-editor-finalize-failure'),
                  content: const Text(
                    'Kroki yayınlanamadı. Dayanıklı taslak korundu; '
                    'tekrar deneyebilirsiniz.',
                  ),
                  actions: [
                    TextButton(
                      key: const Key('inventory-editor-retry-finalize'),
                      onPressed: () => unawaited(_finalizeAndExit()),
                      child: const Text('Yayınlamayı tekrar dene'),
                    ),
                  ],
                ),
              if (controller.lastErrorCode ==
                  InventorySketchEditorController.lockedBaseGeometryCode)
                MaterialBanner(
                  key: const Key('inventory-editor-locked-geometry-message'),
                  content: const Text(
                    'Mevcut alanın şekli henüz değiştirilemez. '
                    'Krokiyi güncelle ekranında yeni bir alan çizebilirsiniz; '
                    'kayıt değiştirilmedi.',
                  ),
                  actions: [
                    TextButton(
                      key: const Key(
                        'inventory-editor-locked-geometry-dismiss',
                      ),
                      onPressed: controller.dismissLockedGeometryMessage,
                      child: const Text('Anladım'),
                    ),
                  ],
                ),
              if (_orientationFailed)
                MaterialBanner(
                  content: const Text(
                    'Ekran yönü güvenle doğrulanamadı. '
                    'Kayıt durumu değiştirilmedi.',
                  ),
                  actions: [
                    TextButton(
                      key: const Key('inventory-editor-retry-orientation'),
                      onPressed: () => unawaited(
                        _orientationRestoreFailed
                            ? _attemptExit(_pendingPopResult)
                            : _enterEditor(),
                      ),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (controller.saveLabel != null)
          Positioned(
            left: 8,
            bottom: 8,
            child: Material(
              key: const Key('inventory-editor-save-status-overlay'),
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Semantics(
                  liveRegion: true,
                  label: 'Taslak durumu: ${controller.saveLabel}',
                  child: Text(
                    controller.saveLabel!,
                    key: const Key('inventory-editor-save-status'),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          bottom: 8,
          child: _EditorToolbar(
            editor: editor,
            onBack: () => unawaited(_attemptExit()),
            onModeChanged: controller.setMode,
            onUndo: controller.undo,
            onRedo: controller.redo,
            onFinish: controller.finishWorkingPolyline,
            onClose: () => unawaited(_closeCurrentBlock()),
            onDelete: controller.deleteSelection,
            freeLengthNextSegment: controller.freeLengthNextSegment,
            onFreeLengthChanged: controller.setFreeLengthNextSegment,
            onZoomOut: () => _canvasKey.currentState?.zoomOut(),
            onZoomIn: () => _canvasKey.currentState?.zoomIn(),
            onFit: () => _canvasKey.currentState?.fitCanvas(),
            finalizeLabel: finalizeLabel,
            finalizing: controller.finalizing,
            onFinalize: controller.isFinalizeEnabled
                ? () => unawaited(_finalizeAndExit())
                : null,
          ),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.editor,
    required this.onBack,
    required this.onModeChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onFinish,
    required this.onClose,
    required this.onDelete,
    required this.freeLengthNextSegment,
    required this.onFreeLengthChanged,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onFit,
    required this.finalizeLabel,
    required this.finalizing,
    required this.onFinalize,
  });

  final InventorySketchEditorSnapshot editor;
  final VoidCallback onBack;
  final ValueChanged<InventorySketchEditorMode> onModeChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onFinish;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final bool freeLengthNextSegment;
  final ValueChanged<bool> onFreeLengthChanged;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onFit;
  final String finalizeLabel;
  final bool finalizing;
  final VoidCallback? onFinalize;

  @override
  Widget build(BuildContext context) {
    final canClose =
        editor.hasWorkingPolyline &&
        editor.geometry.polylines[editor.workingPolylineIndex!].points.length >=
            3;
    return Material(
      key: const Key('inventory-editor-right-toolbar'),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            const SizedBox(height: 4),
            _ToolbarIconButton(
              key: const Key('inventory-editor-back'),
              label: 'Geri',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            ),
            const Divider(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  key: const Key('inventory-editor-modes'),
                  children: [
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-mode-draw'),
                      label: 'Çiz',
                      selected: editor.mode == InventorySketchEditorMode.draw,
                      selectedIndicatorKey: const Key(
                        'inventory-editor-mode-selected-draw',
                      ),
                      icon: const Icon(Icons.polyline_rounded),
                      onPressed: () =>
                          onModeChanged(InventorySketchEditorMode.draw),
                    ),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-mode-select'),
                      label: 'Seç',
                      selected: editor.mode == InventorySketchEditorMode.select,
                      selectedIndicatorKey: const Key(
                        'inventory-editor-mode-selected-select',
                      ),
                      icon: const Icon(Icons.ads_click_rounded),
                      onPressed: () =>
                          onModeChanged(InventorySketchEditorMode.select),
                    ),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-mode-pan'),
                      label: 'Taşı',
                      selected: editor.mode == InventorySketchEditorMode.pan,
                      selectedIndicatorKey: const Key(
                        'inventory-editor-mode-selected-pan',
                      ),
                      icon: const Icon(Icons.pan_tool_alt_outlined),
                      onPressed: () =>
                          onModeChanged(InventorySketchEditorMode.pan),
                    ),
                    const Divider(height: 8),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-undo'),
                      label: 'Geri al',
                      icon: const Icon(Icons.undo_rounded),
                      onPressed: editor.canUndo ? onUndo : null,
                    ),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-redo'),
                      label: 'İleri al',
                      icon: const Icon(Icons.redo_rounded),
                      onPressed: editor.canRedo ? onRedo : null,
                    ),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-finish-line'),
                      label: 'Çizgiyi bitir',
                      icon: const Icon(Icons.stop_rounded),
                      onPressed: editor.hasWorkingPolyline ? onFinish : null,
                    ),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-close-block'),
                      label: 'Alanı kapat',
                      icon: const Icon(Icons.polyline_rounded),
                      onPressed: canClose ? onClose : null,
                    ),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-free-length'),
                      label: 'Serbest uzunluk',
                      selected: freeLengthNextSegment,
                      selectedIndicatorKey: const Key(
                        'inventory-editor-free-length-selected',
                      ),
                      icon: const Icon(Icons.straighten_rounded),
                      onPressed:
                          editor.mode == InventorySketchEditorMode.draw &&
                              editor.hasWorkingPolyline
                          ? () => onFreeLengthChanged(!freeLengthNextSegment)
                          : null,
                    ),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-delete'),
                      label: 'Seçileni sil',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: editor.selection == null ? null : onDelete,
                    ),
                    const Divider(height: 8),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-zoom-out'),
                      label: 'Uzaklaştır',
                      icon: const Icon(Icons.remove_rounded),
                      onPressed: onZoomOut,
                    ),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-zoom-in'),
                      label: 'Yakınlaştır',
                      icon: const Icon(Icons.add_rounded),
                      onPressed: onZoomIn,
                    ),
                    _ToolbarIconButton(
                      key: const Key('inventory-editor-fit'),
                      label: 'Tamamını göster',
                      icon: const Icon(Icons.fit_screen_rounded),
                      onPressed: onFit,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 8),
            _ToolbarIconButton(
              key: const Key('inventory-editor-finalize'),
              label: finalizeLabel,
              emphasized: true,
              icon: finalizing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded),
              onPressed: onFinalize,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.selectedIndicatorKey,
    this.emphasized = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool selected;
  final Key? selectedIndicatorKey;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final decoratedIcon = selected
        ? SizedBox.square(
            dimension: 24,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                icon,
                Positioned(
                  key: selectedIndicatorKey,
                  top: -5,
                  right: -5,
                  child: const Icon(Icons.check_circle, size: 11),
                ),
              ],
            ),
          )
        : icon;
    final button = emphasized
        ? IconButton.filled(onPressed: onPressed, icon: decoratedIcon)
        : selected
        ? IconButton.filledTonal(onPressed: onPressed, icon: decoratedIcon)
        : IconButton(onPressed: onPressed, icon: decoratedIcon);
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Tooltip(message: label, child: button),
    );
  }
}

class _InventoryBlockMetadataInput {
  const _InventoryBlockMetadataInput({
    required this.displayName,
    required this.floorCount,
  });

  final String displayName;
  final int floorCount;
}

class _InventoryBlockMetadataDialog extends StatefulWidget {
  const _InventoryBlockMetadataDialog();

  @override
  State<_InventoryBlockMetadataDialog> createState() =>
      _InventoryBlockMetadataDialogState();
}

class _InventoryBlockMetadataDialogState
    extends State<_InventoryBlockMetadataDialog> {
  final _nameController = TextEditingController();
  final _floorCountController = TextEditingController(text: '1');
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _floorCountController.dispose();
    super.dispose();
  }

  void _submit() {
    final floorCount = int.tryParse(_floorCountController.text);
    try {
      final name = InventorySpatialContract.normalizeBlockName(
        _nameController.text,
      );
      if (floorCount == null) {
        throw const InventoryFailure('inventory_floor_count_invalid');
      }
      InventorySpatialContract.validateFloorCount(floorCount);
      Navigator.of(context).pop(
        _InventoryBlockMetadataInput(displayName: name, floorCount: floorCount),
      );
    } on InventoryFailure {
      setState(() {
        _errorText =
            'Alan adı boş bırakılamaz; kat sayısı 1 ile '
            '${InventorySpatialContract.maximumFloorCount} arasında olmalıdır.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('inventory-block-metadata-dialog'),
      title: const Text('Alan bilgileri'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('inventory-block-name'),
              controller: _nameController,
              autofocus: true,
              maxLength: InventorySpatialContract.maximumBlockNameLength,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Alan adı',
                hintText: 'Örn. A Blok',
              ),
            ),
            TextField(
              key: const Key('inventory-block-floor-count'),
              controller: _floorCountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Kat sayısı',
                errorText: _errorText,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('inventory-block-metadata-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          key: const Key('inventory-block-metadata-save'),
          onPressed: _submit,
          child: const Text('Alanı ekle'),
        ),
      ],
    );
  }
}

class _InventoryProposedEdgePainter extends CustomPainter {
  const _InventoryProposedEdgePainter({
    required this.viewport,
    required this.start,
    required this.end,
    required this.alignmentGuide,
  });

  final InventoryViewport? viewport;
  final InventorySketchPoint? start;
  final InventorySketchPoint? end;
  final InventorySketchAlignmentGuide? alignmentGuide;

  @override
  void paint(Canvas canvas, Size size) {
    final currentViewport = viewport;
    final currentStart = start;
    final currentEnd = end;
    if (currentViewport == null ||
        currentStart == null ||
        currentEnd == null ||
        currentStart == currentEnd) {
      return;
    }
    final guide = alignmentGuide;
    if (guide != null) {
      final guideStart = guide.axis == InventorySketchAxis.vertical
          ? InventorySketchPoint(x: guide.coordinate, y: 0)
          : InventorySketchPoint(x: 0, y: guide.coordinate);
      final guideEnd = guide.axis == InventorySketchAxis.vertical
          ? InventorySketchPoint(
              x: guide.coordinate,
              y: InventoryGeometryContract.canvasHeight,
            )
          : InventorySketchPoint(
              x: InventoryGeometryContract.canvasWidth,
              y: guide.coordinate,
            );
      canvas.drawLine(
        currentViewport.virtualToView(guideStart),
        currentViewport.virtualToView(guideEnd),
        Paint()
          ..color = Colors.lightBlueAccent.withAlpha(150)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
    final startOffset = currentViewport.virtualToView(currentStart);
    final endOffset = currentViewport.virtualToView(currentEnd);
    final vector = endOffset - startOffset;
    final distance = vector.distance;
    if (distance <= 0) return;
    final direction = vector / distance;
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const dash = 10.0;
    const gap = 7.0;
    for (var offset = 0.0; offset < distance; offset += dash + gap) {
      canvas.drawLine(
        startOffset + direction * offset,
        startOffset +
            direction * (offset + dash).clamp(0.0, distance).toDouble(),
        paint,
      );
    }
    canvas.drawCircle(endOffset, 7, paint);
  }

  @override
  bool shouldRepaint(_InventoryProposedEdgePainter oldDelegate) =>
      oldDelegate.viewport != viewport ||
      oldDelegate.start != start ||
      oldDelegate.end != end ||
      oldDelegate.alignmentGuide != alignmentGuide;
}

class _EditorFailurePanel extends StatelessWidget {
  const _EditorFailurePanel({
    required this.code,
    required this.onRetry,
    required this.onBack,
  });

  final String code;
  final Future<void> Function() onRetry;
  final Future<void> Function([Object? result]) onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Şematik kroki güvenle açılamadı.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Tanı kodu: $code'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('inventory-editor-load-back'),
                  onPressed: () => unawaited(onBack()),
                  child: const Text('Geri'),
                ),
                FilledButton(
                  key: const Key('inventory-editor-load-retry'),
                  onPressed: () => unawaited(onRetry()),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingDraftSave {
  const _PendingDraftSave({
    required this.geometry,
    required this.geometryGeneration,
    required this.command,
  });

  final InventoryGeometry geometry;
  final int geometryGeneration;
  final AutosaveInventorySketchDraftCommand command;
}
