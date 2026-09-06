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
  String? _draftBaseRevisionId;
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
  Map<String, int> _sourceActiveMappings = const {};
  Map<String, int> _existingBlockMappings = const {};
  Map<String, int> _acknowledgedExistingBlockMappings = const {};
  Map<String, InventoryBlockRecord> _blocksById = const {};
  Map<String, List<InventoryFloorRecord>> _floorsByBlockId = const {};
  List<InventoryPolyline> _lockedLegacyPolylines = const [];
  Map<String, InventoryExistingBlockAction> _lifecycleActions = const {};
  Map<String, InventoryExistingBlockAction> _acknowledgedLifecycleActions =
      const {};
  List<InventoryBlockDraft> _newBlocks = const [];
  List<InventoryBlockDraft> _acknowledgedNewBlocks = const [];
  List<_InventoryEditorSpatialFrame> _undoBlockHistory = const [];
  List<_InventoryEditorSpatialFrame> _redoBlockHistory = const [];
  bool _freeLengthNextSegment = false;

  String? get sketchId => _sketchId;
  String? get draftRevisionId => _draftRevisionId;
  int? get expectedSketchRevision => _expectedSketchRevision;
  int? get expectedContentRevision => _expectedContentRevision;
  List<InventoryBlockDraft> get newBlocks => _newBlocks;
  List<InventoryExistingBlockMappingDraft> get existingBlockMappings =>
      _mappingDrafts(_existingBlockMappings);
  bool get freeLengthNextSegment => _freeLengthNextSegment;

  InventoryBlockRecord? get selectedExistingBlock {
    final selection = editor?.selection;
    if (selection == null) return null;
    final blockId = _blockIdAtPolygonIndex(selection.polylineIndex);
    return blockId == null ? null : _blocksById[blockId];
  }

  bool get selectedWholeBlockNeedsLifecycleChoice {
    final selection = editor?.selection;
    final block = selectedExistingBlock;
    return selection != null &&
        selection.wholePolyline &&
        block != null &&
        _sourceActiveMappings.containsKey(block.id);
  }

  bool get hasUnresolvedLifecycleChoices {
    for (final blockId in _sourceActiveMappings.keys) {
      if (!_existingBlockMappings.containsKey(blockId) &&
          !_lifecycleActions.containsKey(blockId)) {
        return true;
      }
    }
    return false;
  }

  List<InventoryBlockRecord> get unresolvedLifecycleBlocks {
    final result = <InventoryBlockRecord>[];
    for (final blockId in _sourceActiveMappings.keys) {
      if (_existingBlockMappings.containsKey(blockId) ||
          _lifecycleActions.containsKey(blockId)) {
        continue;
      }
      final block = _blocksById[blockId];
      if (block != null) result.add(block);
    }
    result.sort((first, second) => first.ordinal.compareTo(second.ordinal));
    return List<InventoryBlockRecord>.unmodifiable(result);
  }

  List<InventoryFloorRecord> floorsForExistingBlock(String blockId) =>
      _floorsByBlockId[blockId] ?? const [];

  bool recordRecoveredLifecycleChoice(
    String blockId,
    InventoryExistingBlockAction action,
  ) {
    if ((action != InventoryExistingBlockAction.detach &&
            action != InventoryExistingBlockAction.archive) ||
        !_sourceActiveMappings.containsKey(blockId) ||
        _existingBlockMappings.containsKey(blockId)) {
      return false;
    }
    final pendingStateChanged =
        _lifecycleActions[blockId] != action && hasUnacknowledgedGeometry;
    _lifecycleActions = Map<String, InventoryExistingBlockAction>.unmodifiable({
      ..._lifecycleActions,
      blockId: action,
    });
    _acknowledgedLifecycleActions = _lifecycleActions;
    // A clean recovered choice remains local; pending work must capture it anew.
    if (pendingStateChanged) _scheduleAutosave();
    lastErrorCode = null;
    _notify();
    return true;
  }

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
            candidate.canonicalJson != acknowledged.canonicalJson) ||
        !_sameMappings(
          _existingBlockMappings,
          _acknowledgedExistingBlockMappings,
        ) ||
        !_sameBlockDrafts(_newBlocks, _acknowledgedNewBlocks) ||
        !_sameLifecycleActions(
          _lifecycleActions,
          _acknowledgedLifecycleActions,
        );
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
        hasUnresolvedLifecycleChoices ||
        !_hasCompleteSpatialMetadata(candidate)) {
      return false;
    }
    try {
      candidate.validateFinalizable(
        allowEmpty: _isLifecycleProvenEmpty(candidate),
      );
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
    final normalizedName = InventorySpatialContract.normalizeBlockName(
      displayName,
    );
    if (detachedBlockSuggestion(normalizedName) != null) {
      throw const InventoryFailure(
        'inventory_block_reattach_confirmation_required',
      );
    }
    return InventoryBlockDraft(
      id: _nextId(),
      displayName: normalizedName,
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

  InventoryBlockRecord? detachedBlockSuggestion(String displayName) {
    final normalized = _normalizeInventoryName(
      InventorySpatialContract.normalizeBlockName(displayName),
    );
    final activeMatches = _blocksById.values
        .where(
          (block) =>
              block.archivedAt == null &&
              block.state == InventoryBlockState.active &&
              block.normalizedName == normalized,
        )
        .toList(growable: false);
    final detachedMatches = _blocksById.values
        .where(
          (block) =>
              block.archivedAt == null &&
              block.state == InventoryBlockState.detached &&
              block.normalizedName == normalized,
        )
        .toList(growable: false);
    if (activeMatches.isNotEmpty) {
      throw const InventoryFailure('inventory_block_name_conflict');
    }
    if (detachedMatches.length > 1) {
      throw const InventoryFailure('inventory_block_name_ambiguous');
    }
    return detachedMatches.isEmpty ? null : detachedMatches.single;
  }

  void validateWorkingBlockClosure() {
    final proposal = _workingBlockClosureProposal();
    if (proposal == null) {
      throw const InventoryFailure('inventory_block_polygon_not_closed');
    }
    _validateWorkingBlockNonOverlap(proposal);
  }

  bool closeWorkingBlock(InventoryBlockDraft definition) {
    final proposal = _workingBlockClosureProposal();
    if (proposal == null || definition.polygonIndex != proposal.polygonIndex) {
      return false;
    }
    try {
      definition.validate(proposal.editor.geometry);
      _validateWorkingBlockNonOverlap(proposal);
    } on InventoryFailure catch (error) {
      lastErrorCode = error.code;
      _notify();
      return false;
    }
    final applied = _applyEditorAction(proposal.editor, addedBlock: definition);
    if (applied && _freeLengthNextSegment) {
      _freeLengthNextSegment = false;
      _notify();
    }
    return applied;
  }

  bool closeWorkingBlockAsReattach(String blockId) {
    final proposal = _workingBlockClosureProposal();
    final block = _blocksById[blockId];
    if (proposal == null ||
        block == null ||
        block.archivedAt != null ||
        block.state != InventoryBlockState.detached ||
        _existingBlockMappings.containsKey(blockId)) {
      return false;
    }
    try {
      if (detachedBlockSuggestion(block.displayName)?.id != blockId) {
        throw const InventoryFailure('inventory_block_name_ambiguous');
      }
      InventorySpatialContract.validateBlockPolygon(
        proposal.editor.geometry.polylines[proposal.polygonIndex],
      );
      final nextMappings = Map<String, int>.of(_existingBlockMappings)
        ..[blockId] = proposal.polygonIndex;
      _validateCandidateSpatial(
        proposal.editor.geometry,
        nextMappings,
        _newBlocks,
      );
      final applied = _applyEditorAction(
        proposal.editor,
        existingBlockMappings: nextMappings,
      );
      if (applied && _freeLengthNextSegment) {
        _freeLengthNextSegment = false;
        _notify();
      }
      return applied;
    } on Object catch (error) {
      lastErrorCode = _safeCode(error);
      _notify();
      return false;
    }
  }

  ({InventorySketchEditorSnapshot editor, int polygonIndex})?
  _workingBlockClosureProposal() {
    final current = editor;
    final polygonIndex = current?.workingPolylineIndex;
    final working = workingPolyline;
    if (current == null ||
        polygonIndex == null ||
        working == null ||
        working.points.length < 3) {
      return null;
    }
    final next = current.drawPoint(
      working.points.first,
      smartAlignment: !_freeLengthNextSegment,
    );
    if (next == null || next.workingPolylineIndex != null) return null;
    return (editor: next, polygonIndex: polygonIndex);
  }

  void _validateWorkingBlockNonOverlap(
    ({InventorySketchEditorSnapshot editor, int polygonIndex}) proposal,
  ) {
    final polygons = <InventoryPolyline>[
      for (final mappedIndex in _existingBlockMappings.values)
        proposal.editor.geometry.polylines[mappedIndex],
      for (final block in _newBlocks)
        proposal.editor.geometry.polylines[block.polygonIndex],
      proposal.editor.geometry.polylines[proposal.polygonIndex],
    ];
    InventorySpatialContract.validateNonOverlappingPolygons(polygons);
  }

  bool finishWorkingPolyline() =>
      _applyEditorAction(editor?.finishWorkingPolyline());

  void selectAt(Offset viewPoint, InventoryViewport viewport) {
    final current = editor;
    if (current == null) return;
    // A fresh edge tap after whole-block editing must leave whole selection.
    final selectable = current.selection?.wholePolyline == true
        ? current.withSelection(null)
        : current;
    final next = selectable.selectAt(viewPoint, viewport);
    if (identical(next, current) && next.selection == current.selection) return;
    editor = next;
    _notify();
  }

  void dismissHandledError() {
    if (lastErrorCode == null) return;
    lastErrorCode = null;
    _notify();
  }

  void clearSelection() {
    final current = editor;
    if (current == null || current.selection == null) return;
    editor = current.withSelection(null);
    _notify();
  }

  bool nudgeSelection(InventorySketchNudgeDirection direction) {
    final current = editor;
    final selection = current?.selection;
    if (current == null || selection == null) return false;
    final blockId = _blockIdAtPolygonIndex(selection.polylineIndex);
    if (blockId == null) {
      lastErrorCode = lockedBaseGeometryCode;
      _notify();
      return false;
    }
    try {
      final next = current.nudgeSelection(direction);
      if (next == null) return false;
      _validateCandidateSpatial(
        next.geometry,
        _existingBlockMappings,
        _newBlocks,
      );
      return _applyEditorAction(
        next,
        existingBlockMappings: _existingBlockMappings,
      );
    } on InventoryGeometryFailure catch (error) {
      lastErrorCode = error.reason == 'coordinate_out_of_bounds'
          ? 'inventory_block_nudge_out_of_bounds'
          : 'inventory_block_nudge_invalid';
      _notify();
      return false;
    } on Object catch (error) {
      lastErrorCode = _safeCode(error);
      _notify();
      return false;
    }
  }

  bool deleteSelection() {
    final current = editor;
    final selection = current?.selection;
    if (current == null || selection == null) return false;
    final blockId = _blockIdAtPolygonIndex(selection.polylineIndex);
    if (blockId != null) {
      if (_sourceActiveMappings.containsKey(blockId)) {
        lastErrorCode = selection.wholePolyline
            ? 'inventory_block_lifecycle_choice_required'
            : 'inventory_mapped_block_segment_delete_not_supported';
        _notify();
        return false;
      }
      if (!selection.wholePolyline) {
        lastErrorCode = 'inventory_mapped_block_segment_delete_not_supported';
        _notify();
        return false;
      }
      return _deleteMappedSelection(blockId: blockId);
    }
    if (_isLockedLegacyPolyline(
      current.geometry.polylines[selection.polylineIndex],
    )) {
      lastErrorCode = lockedBaseGeometryCode;
      _notify();
      return false;
    }
    return _applyEditorAction(current.deleteSelection());
  }

  bool deleteMappedSelection(InventoryExistingBlockAction action) {
    if (action != InventoryExistingBlockAction.detach &&
        action != InventoryExistingBlockAction.archive) {
      return false;
    }
    final selection = editor?.selection;
    if (selection == null || !selection.wholePolyline) return false;
    final blockId = _blockIdAtPolygonIndex(selection.polylineIndex);
    if (blockId == null || !_sourceActiveMappings.containsKey(blockId)) {
      return false;
    }
    return _deleteMappedSelection(blockId: blockId, action: action);
  }

  bool _deleteMappedSelection({
    required String blockId,
    InventoryExistingBlockAction? action,
  }) {
    final current = editor;
    final selection = current?.selection;
    final removedIndex = _existingBlockMappings[blockId];
    if (current == null ||
        selection == null ||
        !selection.wholePolyline ||
        removedIndex == null ||
        selection.polylineIndex != removedIndex) {
      return false;
    }
    final next = current.deleteSelection();
    if (next == null) return false;
    final nextMappings = <String, int>{
      for (final entry in _existingBlockMappings.entries)
        if (entry.key != blockId)
          entry.key: entry.value > removedIndex ? entry.value - 1 : entry.value,
    };
    final nextActions = Map<String, InventoryExistingBlockAction>.of(
      _lifecycleActions,
    );
    if (action == null) {
      nextActions.remove(blockId);
    } else {
      nextActions[blockId] = action;
    }
    return _applyEditorAction(
      next,
      existingBlockMappings: nextMappings,
      lifecycleActions: nextActions,
    );
  }

  bool undo() {
    final current = editor;
    if (current == null || !current.canUndo || _undoBlockHistory.isEmpty) {
      return false;
    }
    final previousFrame = _undoBlockHistory.last;
    _undoBlockHistory = List<_InventoryEditorSpatialFrame>.unmodifiable(
      _undoBlockHistory.sublist(0, _undoBlockHistory.length - 1),
    );
    _redoBlockHistory = _boundedBlockHistory([
      ..._redoBlockHistory,
      _currentSpatialFrame,
    ]);
    return _applyHistoryFrame(current.undo(), previousFrame);
  }

  bool redo() {
    final current = editor;
    if (current == null || !current.canRedo || _redoBlockHistory.isEmpty) {
      return false;
    }
    final nextFrame = _redoBlockHistory.last;
    _redoBlockHistory = List<_InventoryEditorSpatialFrame>.unmodifiable(
      _redoBlockHistory.sublist(0, _redoBlockHistory.length - 1),
    );
    _undoBlockHistory = _boundedBlockHistory([
      ..._undoBlockHistory,
      _currentSpatialFrame,
    ]);
    return _applyHistoryFrame(current.redo(), nextFrame);
  }

  bool _applyEditorAction(
    InventorySketchEditorSnapshot? next, {
    InventoryBlockDraft? addedBlock,
    Map<String, int>? existingBlockMappings,
    Map<String, InventoryExistingBlockAction>? lifecycleActions,
  }) {
    final current = editor;
    if (current == null || next == null || identical(current, next)) {
      return false;
    }
    final geometryChanged =
        current.geometry.canonicalJson != next.geometry.canonicalJson;
    final nextBlocks = geometryChanged
        ? _remapNewBlocks(
            current.geometry,
            next.geometry,
            addedBlock: addedBlock,
          )
        : _newBlocks;
    final nextMappings =
        existingBlockMappings ??
        (geometryChanged
            ? _remapExistingBlockMappings(current.geometry, next.geometry)
            : _existingBlockMappings);
    final nextActions = lifecycleActions ?? _lifecycleActions;
    if (nextBlocks == null ||
        nextMappings == null ||
        !_preservesLockedLegacy(next.geometry, nextMappings, nextBlocks)) {
      lastErrorCode = 'inventory_block_metadata_history_invalid';
      _notify();
      return false;
    }
    try {
      _validateCandidateSpatial(next.geometry, nextMappings, nextBlocks);
    } on Object catch (error) {
      lastErrorCode = _safeCode(error);
      _notify();
      return false;
    }
    final saveStateChanged =
        geometryChanged ||
        !_sameMappings(_existingBlockMappings, nextMappings) ||
        !_sameBlockDrafts(_newBlocks, nextBlocks) ||
        !_sameLifecycleActions(_lifecycleActions, nextActions);
    lastErrorCode = null;
    _undoBlockHistory = _boundedBlockHistory([
      ..._undoBlockHistory,
      _currentSpatialFrame,
    ]);
    _redoBlockHistory = const [];
    editor = next;
    _newBlocks = nextBlocks;
    _existingBlockMappings = Map<String, int>.unmodifiable(nextMappings);
    _lifecycleActions = Map<String, InventoryExistingBlockAction>.unmodifiable(
      nextActions,
    );
    if (saveStateChanged) {
      _scheduleAutosave();
    }
    _notify();
    return true;
  }

  bool _applyHistoryFrame(
    InventorySketchEditorSnapshot next,
    _InventoryEditorSpatialFrame nextFrame,
  ) {
    final current = editor!;
    final saveStateChanged =
        current.geometry.canonicalJson != next.geometry.canonicalJson ||
        !_sameMappings(
          _existingBlockMappings,
          nextFrame.existingBlockMappings,
        ) ||
        !_sameBlockDrafts(_newBlocks, nextFrame.newBlocks) ||
        !_sameLifecycleActions(_lifecycleActions, nextFrame.lifecycleActions);
    editor = next;
    _newBlocks = nextFrame.newBlocks;
    _existingBlockMappings = nextFrame.existingBlockMappings;
    _lifecycleActions = nextFrame.lifecycleActions;
    lastErrorCode = null;
    if (saveStateChanged) _scheduleAutosave();
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
        for (var index = 0; index < next.polylines.length; index += 1)
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
      if (index < 0 ||
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

  String? _blockIdAtPolygonIndex(int polygonIndex) {
    for (final entry in _existingBlockMappings.entries) {
      if (entry.value == polygonIndex) return entry.key;
    }
    return null;
  }

  Map<String, int>? _remapExistingBlockMappings(
    InventoryGeometry current,
    InventoryGeometry next,
  ) {
    final remapped = <String, int>{};
    final usedIndexes = <int>{};
    for (final entry in _existingBlockMappings.entries) {
      final sourceIndex = entry.value;
      if (sourceIndex < 0 || sourceIndex >= current.polylines.length) {
        return null;
      }
      final source = current.polylines[sourceIndex];
      final matches = <int>[
        for (var index = 0; index < next.polylines.length; index += 1)
          if (!usedIndexes.contains(index) &&
              _samePolyline(source, next.polylines[index]))
            index,
      ];
      if (matches.length != 1) return null;
      usedIndexes.add(matches.single);
      remapped[entry.key] = matches.single;
    }
    return Map<String, int>.unmodifiable(remapped);
  }

  bool _preservesLockedLegacy(
    InventoryGeometry geometry,
    Map<String, int> mappings,
    List<InventoryBlockDraft> newBlocks,
  ) {
    if (_lockedLegacyPolylines.isEmpty) return true;
    final reservedIndexes = <int>{
      ...mappings.values,
      ...newBlocks.map((block) => block.polygonIndex),
    };
    var searchIndex = 0;
    for (final locked in _lockedLegacyPolylines) {
      var found = false;
      while (searchIndex < geometry.polylines.length) {
        final index = searchIndex;
        searchIndex += 1;
        if (!reservedIndexes.contains(index) &&
            _samePolyline(locked, geometry.polylines[index])) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  bool _isLockedLegacyPolyline(InventoryPolyline polyline) =>
      _lockedLegacyPolylines.any((locked) => _samePolyline(locked, polyline));

  void _validateCandidateSpatial(
    InventoryGeometry geometry,
    Map<String, int> mappings,
    List<InventoryBlockDraft> newBlocks,
  ) {
    final usedIndexes = <int>{};
    final polygons = <InventoryPolyline>[];
    for (final entry in mappings.entries) {
      final block = _blocksById[entry.key];
      final index = entry.value;
      if (block == null ||
          block.archivedAt != null ||
          index < 0 ||
          index >= geometry.polylines.length ||
          !usedIndexes.add(index)) {
        throw const InventoryFailure(
          'inventory_block_mapping_integrity_failed',
        );
      }
      polygons.add(geometry.polylines[index]);
    }
    for (final block in newBlocks) {
      block.validate(geometry);
      if (!usedIndexes.add(block.polygonIndex)) {
        throw const InventoryFailure('inventory_block_identity_ambiguous');
      }
      polygons.add(geometry.polylines[block.polygonIndex]);
    }
    InventorySpatialContract.validateNonOverlappingPolygons(polygons);
  }

  _InventoryEditorSpatialFrame get _currentSpatialFrame =>
      _InventoryEditorSpatialFrame(
        existingBlockMappings: _existingBlockMappings,
        newBlocks: _newBlocks,
        lifecycleActions: _lifecycleActions,
      );

  List<InventoryExistingBlockMappingDraft> _mappingDrafts(
    Map<String, int> mappings,
  ) {
    final entries = mappings.entries.toList(growable: false)
      ..sort((first, second) => first.key.compareTo(second.key));
    return List<InventoryExistingBlockMappingDraft>.unmodifiable([
      for (final entry in entries)
        InventoryExistingBlockMappingDraft(
          blockId: entry.key,
          polygonIndex: entry.value,
        ),
    ]);
  }

  bool _sameMappings(Map<String, int> first, Map<String, int> second) {
    if (first.length != second.length) return false;
    for (final entry in first.entries) {
      if (second[entry.key] != entry.value) return false;
    }
    return true;
  }

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

  bool _sameLifecycleActions(
    Map<String, InventoryExistingBlockAction> first,
    Map<String, InventoryExistingBlockAction> second,
  ) =>
      first.length == second.length &&
      first.entries.every((entry) => second[entry.key] == entry.value);

  bool _isLifecycleProvenEmpty(InventoryGeometry geometry) =>
      launchIntent == InventorySketchLaunchIntent.editActive &&
      geometry.polylines.isEmpty &&
      _lockedLegacyPolylines.isEmpty &&
      _newBlocks.isEmpty &&
      _existingBlockMappings.isEmpty &&
      _sourceActiveMappings.isNotEmpty &&
      !hasUnresolvedLifecycleChoices;

  List<InventoryExistingBlockFinalizeIntent> _existingBlockFinalizeIntents() {
    final result = <InventoryExistingBlockFinalizeIntent>[];
    for (final entry in _sourceActiveMappings.entries) {
      final block = _blocksById[entry.key];
      if (block == null || block.state != InventoryBlockState.active) {
        throw const InventoryFailure(
          'inventory_block_mapping_integrity_failed',
        );
      }
      final targetIndex = _existingBlockMappings[entry.key];
      if (targetIndex != null) {
        if (_lifecycleActions.containsKey(entry.key)) {
          throw const InventoryFailure(
            'inventory_block_lifecycle_choice_invalid',
          );
        }
        result.add(
          InventoryExistingBlockFinalizeIntent(
            blockId: entry.key,
            action: InventoryExistingBlockAction.retainMapped,
            expectedBlockRevision: block.revision,
            targetPolygonIndex: targetIndex,
          ),
        );
        continue;
      }
      final action = _lifecycleActions[entry.key];
      if (action != InventoryExistingBlockAction.detach &&
          action != InventoryExistingBlockAction.archive) {
        throw const InventoryFailure(
          'inventory_block_lifecycle_choice_required',
        );
      }
      result.add(
        InventoryExistingBlockFinalizeIntent(
          blockId: entry.key,
          action: action!,
          expectedBlockRevision: block.revision,
        ),
      );
    }
    for (final entry in _existingBlockMappings.entries) {
      if (_sourceActiveMappings.containsKey(entry.key)) continue;
      final block = _blocksById[entry.key];
      if (block == null || block.state != InventoryBlockState.detached) {
        throw const InventoryFailure(
          'inventory_block_mapping_integrity_failed',
        );
      }
      result.add(
        InventoryExistingBlockFinalizeIntent(
          blockId: entry.key,
          action: InventoryExistingBlockAction.reattach,
          expectedBlockRevision: block.revision,
          targetPolygonIndex: entry.value,
        ),
      );
    }
    result.sort((first, second) => first.blockId.compareTo(second.blockId));
    return List<InventoryExistingBlockFinalizeIntent>.unmodifiable(result);
  }

  List<_InventoryEditorSpatialFrame> _boundedBlockHistory(
    Iterable<_InventoryEditorSpatialFrame> values,
  ) {
    final bounded = List<_InventoryEditorSpatialFrame>.of(values);
    if (bounded.length > InventorySketchEditorSnapshot.maximumHistory) {
      bounded.removeRange(
        0,
        bounded.length - InventorySketchEditorSnapshot.maximumHistory,
      );
    }
    return List<_InventoryEditorSpatialFrame>.unmodifiable(bounded);
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
      // An observed result must be reconciled before using newer revisions,
      // even when the editor has advanced beyond the submitted generation.
      if (_pendingSave?.geometryGeneration != _geometryGeneration &&
          !(_pendingSave?.mutationResultObserved ?? false)) {
        _pendingSave = null;
      }
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
        pending.mutationResultObserved = true;
        final projection = await application.loadPrimarySketch(projectId);
        final targetDraftRevisionId = result.supportingId;
        if (projection == null ||
            result.commandType != InventoryCommandType.sketchDraftAutosave ||
            result.projectId != projectId ||
            result.sourceId != projection.sketch.id ||
            result.sourceRevision != projection.sketch.revision ||
            targetDraftRevisionId == null) {
          throw const InventoryFailure(
            'inventory_sketch_save_verification_failed',
          );
        }
        final draft = _verifiedDraft(
          projection,
          expectedDraftRevisionId: targetDraftRevisionId,
          expectedGeometry: pending.geometry,
          expectedExistingBlockMappings: pending.command.existingBlockMappings,
          expectedNewBlocks: pending.command.newBlocks,
        );
        if (result.supportingRevision != draft.contentRevision) {
          throw const InventoryFailure(
            'inventory_sketch_save_verification_failed',
          );
        }
        acknowledgedGeometry = draft.geometry;
        _acknowledgedExistingBlockMappings = Map<String, int>.unmodifiable({
          for (final mapping
              in pending.command.existingBlockMappings ?? const [])
            mapping.blockId: mapping.polygonIndex,
        });
        _acknowledgedNewBlocks = List<InventoryBlockDraft>.unmodifiable(
          pending.command.newBlocks,
        );
        _acknowledgedLifecycleActions = pending.lifecycleActions;
        _draftRevisionId = draft.id;
        _expectedSketchRevision = projection.sketch.revision;
        _expectedContentRevision = draft.contentRevision;
        _pendingSave = null;
        if (_normalSaveEligibleGeneration == pending.geometryGeneration) {
          _normalSaveEligibleGeneration = null;
        }
        _notify();
      } on Object catch (error) {
        if (!pending.mutationResultObserved &&
            pending.geometryGeneration != _geometryGeneration) {
          _pendingSave = null;
          // Re-check eligibility in this serial drain: the newer timer may
          // already have fired while awaiting the failed older operation.
          continue;
        }
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
      lifecycleActions: _lifecycleActions,
      command: AutosaveInventorySketchDraftCommand(
        operationId: _nextId(),
        projectId: projectId,
        sketchId: _sketchId!,
        draftRevisionId: _draftRevisionId!,
        expectedSketchRevision: _expectedSketchRevision!,
        expectedContentRevision: _expectedContentRevision!,
        geometry: current,
        existingBlockMappings: _mappingDrafts(_existingBlockMappings),
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
    _newBlocks = _acknowledgedNewBlocks;
    _existingBlockMappings = _acknowledgedExistingBlockMappings;
    _lifecycleActions = _acknowledgedLifecycleActions;
    editor = _recoverEditor(acknowledged, mode: current.mode);
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
      if (hasUnresolvedLifecycleChoices) {
        throw const InventoryFailure(
          'inventory_block_lifecycle_choice_required',
        );
      }
      candidate.validateFinalizable(
        allowEmpty: _isLifecycleProvenEmpty(candidate),
      );
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
      if (hasUnresolvedLifecycleChoices) {
        throw const InventoryFailure(
          'inventory_block_lifecycle_choice_required',
        );
      }
      intended.validateFinalizable(
        allowEmpty: _isLifecycleProvenEmpty(intended),
      );
      if (!_hasCompleteSpatialMetadata(intended)) {
        throw const InventoryFailure('inventory_block_metadata_incomplete');
      }
      final expectedSketchRevision = _expectedSketchRevision!;
      final expectedContentRevision = _expectedContentRevision!;
      final before = await application.loadPrimarySketch(projectId);
      final draft = _verifiedDraft(
        before,
        expectedGeometry: intended,
        expectedExistingBlockMappings: _mappingDrafts(_existingBlockMappings),
        expectedNewBlocks: _newBlocks,
      );
      if (before!.sketch.revision != expectedSketchRevision) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      if (draft.contentRevision != expectedContentRevision) {
        throw const InventoryFailure('inventory_stale_content_revision');
      }
      final targetDraftId = draft.id;
      final existingBlockIntents = _existingBlockFinalizeIntents();
      final placementExpectations = await _placementExpectations();
      final result = await application.finalizeSketch(
        FinalizeInventorySketchCommand(
          operationId: _nextId(),
          projectId: projectId,
          sketchId: before.sketch.id,
          draftRevisionId: targetDraftId,
          expectedSketchRevision: expectedSketchRevision,
          expectedContentRevision: expectedContentRevision,
          existingBlockIntents: existingBlockIntents,
          placementExpectations: placementExpectations,
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
    String? expectedDraftRevisionId,
    required InventoryGeometry expectedGeometry,
    List<InventoryExistingBlockMappingDraft>? expectedExistingBlockMappings,
    List<InventoryBlockDraft>? expectedNewBlocks,
  }) {
    final targetDraftRevisionId = expectedDraftRevisionId ?? _draftRevisionId;
    final draft = projection?.draftRevision;
    if (projection == null ||
        projection.sketch.projectId != projectId ||
        projection.sketch.id != _sketchId ||
        targetDraftRevisionId == null ||
        projection.sketch.draftRevisionId != targetDraftRevisionId ||
        draft == null ||
        draft.id != targetDraftRevisionId ||
        draft.sketchId != _sketchId ||
        draft.projectId != projectId ||
        draft.state != InventorySketchRevisionState.draft ||
        draft.baseRevisionId != _draftBaseRevisionId ||
        projection.activeRevision?.id != _draftBaseRevisionId ||
        draft.geometry.canonicalJson != expectedGeometry.canonicalJson ||
        draft.geometrySha256 != expectedGeometry.sha256 ||
        (expectedExistingBlockMappings != null &&
            !_sameExistingBlockMappings(
              projection.draftBlockPolygons,
              expectedExistingBlockMappings,
              draft.id,
            )) ||
        (expectedNewBlocks != null &&
            !_sameBlockDefinitions(
              projection.draftNewBlocks,
              expectedNewBlocks,
            ))) {
      throw const InventoryFailure('inventory_sketch_save_verification_failed');
    }
    return draft;
  }

  bool _sameExistingBlockMappings(
    List<InventoryRevisionBlockPolygonRecord> actual,
    List<InventoryExistingBlockMappingDraft> expected,
    String expectedRevisionId,
  ) {
    if (actual.length != expected.length) return false;
    final actualByBlock = <String, int>{};
    for (final mapping in actual) {
      if (mapping.revisionId != expectedRevisionId ||
          mapping.projectId != projectId ||
          mapping.sketchId != _sketchId ||
          actualByBlock.containsKey(mapping.blockId)) {
        return false;
      }
      actualByBlock[mapping.blockId] = mapping.polygonIndex;
    }
    for (final mapping in expected) {
      if (actualByBlock[mapping.blockId] != mapping.polygonIndex) return false;
    }
    return true;
  }

  Future<List<InventoryPlacementReconciliationExpectation>>
  _placementExpectations() async {
    final assets = await application.listAssets(
      projectId: projectId,
      includeArchived: false,
    );
    final result = <InventoryPlacementReconciliationExpectation>[];
    for (final projection in assets) {
      final asset = projection.asset;
      final placement = projection.activePlacement;
      if (asset.projectId != projectId ||
          asset.archivedAt != null ||
          placement == null ||
          !placement.isActive ||
          placement.projectId != projectId ||
          placement.assetId != asset.id) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
      result.add(
        InventoryPlacementReconciliationExpectation(
          assetId: asset.id,
          expectedAssetRevision: asset.revision,
          placementId: placement.id,
          placementKey: placement.placementKey,
          expectedPlacementSequence: placement.sequence,
        ),
      );
    }
    result.sort((first, second) => first.assetId.compareTo(second.assetId));
    return List<InventoryPlacementReconciliationExpectation>.unmodifiable(
      result,
    );
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
    final active = projection.activeRevision;
    if (draft.baseRevisionId != active?.id ||
        (launchIntent == InventorySketchLaunchIntent.editActive &&
            active == null)) {
      throw const InventoryFailure('inventory_sketch_edit_lifecycle_invalid');
    }
    _sketchId = projection.sketch.id;
    _draftRevisionId = draft.id;
    _draftBaseRevisionId = draft.baseRevisionId;
    _expectedSketchRevision = projection.sketch.revision;
    _expectedContentRevision = draft.contentRevision;
    acknowledgedGeometry = draft.geometry;
    final blocksById = <String, InventoryBlockRecord>{};
    for (final block in projection.blocks) {
      if (block.projectId != projectId || blocksById.containsKey(block.id)) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
      blocksById[block.id] = block;
    }
    _blocksById = Map<String, InventoryBlockRecord>.unmodifiable(blocksById);
    final floorsByBlockId = <String, List<InventoryFloorRecord>>{};
    for (final floor in projection.floors) {
      if (floor.projectId != projectId ||
          !blocksById.containsKey(floor.blockId)) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
      floorsByBlockId.putIfAbsent(floor.blockId, () => []).add(floor);
    }
    for (final floors in floorsByBlockId.values) {
      floors.sort((first, second) => first.ordinal.compareTo(second.ordinal));
    }
    _floorsByBlockId = Map<String, List<InventoryFloorRecord>>.unmodifiable({
      for (final entry in floorsByBlockId.entries)
        entry.key: List<InventoryFloorRecord>.unmodifiable(entry.value),
    });
    Map<String, int> mappingMap(
      List<InventoryRevisionBlockPolygonRecord> mappings,
      InventoryGeometry geometry,
      String expectedRevisionId,
    ) {
      final result = <String, int>{};
      final indexes = <int>{};
      for (final mapping in mappings) {
        if (mapping.revisionId != expectedRevisionId ||
            mapping.projectId != projectId ||
            mapping.sketchId != projection.sketch.id ||
            !blocksById.containsKey(mapping.blockId) ||
            mapping.polygonIndex < 0 ||
            mapping.polygonIndex >= geometry.polylines.length ||
            result.containsKey(mapping.blockId) ||
            !indexes.add(mapping.polygonIndex)) {
          throw const InventoryFailure('inventory_projection_integrity_failed');
        }
        result[mapping.blockId] = mapping.polygonIndex;
      }
      return Map<String, int>.unmodifiable(result);
    }

    final activeGeometry = projection.activeRevision?.geometry;
    _sourceActiveMappings = activeGeometry == null
        ? const {}
        : mappingMap(
            projection.activeBlockPolygons,
            activeGeometry,
            projection.activeRevision!.id,
          );
    _existingBlockMappings = mappingMap(
      projection.draftBlockPolygons,
      draft.geometry,
      draft.id,
    );
    _acknowledgedExistingBlockMappings = _existingBlockMappings;
    final legacyGeometry = activeGeometry ?? draft.geometry;
    final legacyCount =
        activeGeometry?.polylines.length ?? projection.draftLegacyPolygonCount;
    if (legacyCount < 0 || legacyCount > legacyGeometry.polylines.length) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    final sourceMappedIndexes = _sourceActiveMappings.values.toSet();
    final draftClassifiedIndexes = <int>{
      ..._existingBlockMappings.values,
      ...projection.draftNewBlocks.map((block) => block.polygonIndex),
    };
    final legacyCandidates = <InventoryPolyline>[
      for (var index = 0; index < legacyGeometry.polylines.length; index += 1)
        if (!(activeGeometry == null
                ? draftClassifiedIndexes
                : sourceMappedIndexes)
            .contains(index))
          legacyGeometry.polylines[index],
    ];
    if (activeGeometry == null && legacyCount > legacyCandidates.length) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    _lockedLegacyPolylines = List<InventoryPolyline>.unmodifiable(
      legacyCandidates.take(legacyCount),
    );
    _lifecycleActions = const {};
    _acknowledgedLifecycleActions = const {};
    _newBlocks = projection.draftNewBlocks;
    _acknowledgedNewBlocks = projection.draftNewBlocks;
    _undoBlockHistory = const [];
    _redoBlockHistory = const [];
    _freeLengthNextSegment = false;
    editor = _recoverEditor(draft.geometry);
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _geometryGeneration = 0;
    _normalSaveEligibleGeneration = null;
    _forceDrainRequested = false;
    _finalizeBlockedByStaleRevision = false;
    _pendingSave = null;
  }

  InventorySketchEditorSnapshot _recoverEditor(
    InventoryGeometry geometry, {
    InventorySketchEditorMode mode = InventorySketchEditorMode.draw,
  }) {
    final classifiedIndexes = <int>{
      ..._existingBlockMappings.values,
      ..._newBlocks.map((block) => block.polygonIndex),
    };
    // Legacy count comes from the durable first-draft metadata or active
    // revision mappings. Geometry values cannot identify a new drawing: it
    // may have exactly the same points as an existing open legacy line.
    final drawingIndexes = <int>[
      for (var index = 0; index < geometry.polylines.length; index += 1)
        if (!classifiedIndexes.contains(index)) index,
    ].skip(_lockedLegacyPolylines.length).toList(growable: false);
    return InventorySketchEditorSnapshot.recover(
      geometry,
      mode: mode,
      resumeOpenPolyline:
          drawingIndexes.length == 1 &&
          drawingIndexes.single == geometry.polylines.length - 1 &&
          !geometry.polylines.last.closed,
    );
  }

  bool _hasCompleteSpatialMetadata(InventoryGeometry geometry) {
    try {
      _validateCandidateSpatial(geometry, _existingBlockMappings, _newBlocks);
      final accountedIndexes = <int>{
        ..._existingBlockMappings.values,
        ..._newBlocks.map((block) => block.polygonIndex),
      };
      final remaining = <InventoryPolyline>[
        for (var index = 0; index < geometry.polylines.length; index += 1)
          if (!accountedIndexes.contains(index)) geometry.polylines[index],
      ];
      if (remaining.length != _lockedLegacyPolylines.length) return false;
      for (var index = 0; index < remaining.length; index += 1) {
        if (!_samePolyline(remaining[index], _lockedLegacyPolylines[index])) {
          return false;
        }
      }
      for (final entry in _lifecycleActions.entries) {
        if (!_sourceActiveMappings.containsKey(entry.key) ||
            _existingBlockMappings.containsKey(entry.key) ||
            (entry.value != InventoryExistingBlockAction.detach &&
                entry.value != InventoryExistingBlockAction.archive)) {
          return false;
        }
      }
      return !hasUnresolvedLifecycleChoices;
    } on Object {
      return false;
    }
  }

  String _normalizeInventoryName(String value) => value
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

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

  static const portraitOrientations = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
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
        InventorySketchEditorPage.portraitOrientations,
      );
      if (!mounted) return;
      _standardRestored = false;
      _orientationFailed = false;
      _orientationRestoreFailed = false;
      await controller.initialize();
      if (mounted) await _promptRecoveredLifecycleChoices();
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
          InventorySketchEditorPage.portraitOrientations,
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
    try {
      controller.validateWorkingBlockClosure();
    } on Object catch (error) {
      controller.recordHandledError(error);
      return;
    }
    final input = await showDialog<_InventoryBlockMetadataInput>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _InventoryBlockMetadataDialog(),
    );
    if (input == null || !mounted) return;
    try {
      final suggestion = controller.detachedBlockSuggestion(input.displayName);
      if (suggestion != null) {
        final confirmed = await _showReattachDialog(suggestion);
        if (confirmed == true && mounted) {
          controller.closeWorkingBlockAsReattach(suggestion.id);
        }
        return;
      }
      final definition = controller.createBlockDraft(
        displayName: input.displayName,
        floorCount: input.floorCount,
      );
      controller.closeWorkingBlock(definition);
    } on Object catch (error) {
      controller.recordHandledError(error);
    }
  }

  Future<bool?> _showReattachDialog(InventoryBlockRecord block) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          key: const Key('inventory-block-reattach-dialog'),
          title: const Text('Mevcut bloğu yeniden bağla'),
          content: Text(
            '${block.displayName} adlı krokiden kaldırılmış blok ve '
            '${controller.floorsForExistingBlock(block.id).length} kat '
            'mevcut kimlikleriyle yeniden bağlanacak.',
          ),
          actions: [
            TextButton(
              key: const Key('inventory-block-reattach-cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              key: const Key('inventory-block-reattach-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Mevcut bloğu yeniden bağla'),
            ),
          ],
        ),
      );

  Future<InventoryExistingBlockAction?> _showBlockLifecycleDialog(
    InventoryBlockRecord block,
  ) => showDialog<InventoryExistingBlockAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      key: const Key('inventory-block-lifecycle-dialog'),
      title: Text(block.displayName),
      content: const Text(
        'Bu bloğun krokiden kaldırılması için kayıtların nasıl '
        'korunacağını seçin.',
      ),
      actions: [
        TextButton(
          key: const Key('inventory-block-lifecycle-archive'),
          onPressed: () =>
              Navigator.of(context).pop(InventoryExistingBlockAction.archive),
          child: const Text('Bloğu ve envanter kayıtlarını sil'),
        ),
        FilledButton(
          key: const Key('inventory-block-lifecycle-detach'),
          onPressed: () =>
              Navigator.of(context).pop(InventoryExistingBlockAction.detach),
          child: const Text('Bloğu krokiden kaldır, kayıtları koru'),
        ),
      ],
    ),
  );

  Future<void> _promptRecoveredLifecycleChoices() async {
    while (mounted && controller.hasUnresolvedLifecycleChoices) {
      final blocks = controller.unresolvedLifecycleBlocks;
      if (blocks.isEmpty) return;
      final block = blocks.first;
      final action = await _showBlockLifecycleDialog(block);
      if (!mounted || action == null) return;
      controller.recordRecoveredLifecycleChoice(block.id, action);
    }
  }

  Future<void> _deleteSelection() async {
    if (controller.selectedWholeBlockNeedsLifecycleChoice) {
      final block = controller.selectedExistingBlock;
      if (block == null) return;
      final action = await _showBlockLifecycleDialog(block);
      if (!mounted || action == null) return;
      controller.deleteMappedSelection(action);
      return;
    }
    controller.deleteSelection();
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
    final editorDiagnostic = _editorDiagnosticMessage(controller.lastErrorCode);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the wheel's original offset unless the top toolbar would overlap.
        final movementWheelBottom = (constraints.maxHeight - 56 - 160).clamp(
          0.0,
          80.0,
        );
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
                          key: const Key(
                            'inventory-editor-smart-alignment-guide',
                          ),
                          container: true,
                          label: 'Akıllı hizalama kılavuzu',
                          child: const SizedBox.expand(),
                        ),
                      ),
                  ],
                ),
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
            if (editor.mode == InventorySketchEditorMode.select &&
                editor.selection != null)
              Positioned(
                right: 80,
                bottom: movementWheelBottom,
                child: _SelectionMovementWheel(
                  onNudge: controller.nudgeSelection,
                  onConfirm: controller.clearSelection,
                ),
              ),
            Positioned(
              top: 64,
              left: 8,
              right: 8,
              bottom: 72,
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  key: const Key('inventory-editor-feedback'),
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
                              key: const Key(
                                'inventory-editor-discard-unsaved',
                              ),
                              onPressed: () => unawaited(_discardAndExit()),
                              child: const Text(
                                'Kaydedilmemiş değişiklikleri bırak',
                              ),
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
                          InventorySketchEditorController
                              .lockedBaseGeometryCode)
                        MaterialBanner(
                          key: const Key(
                            'inventory-editor-locked-geometry-message',
                          ),
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
                              onPressed:
                                  controller.dismissLockedGeometryMessage,
                              child: const Text('Anladım'),
                            ),
                          ],
                        ),
                      if (editorDiagnostic != null)
                        MaterialBanner(
                          key: const Key('inventory-editor-spatial-diagnostic'),
                          content: Text(editorDiagnostic),
                          actions: [
                            TextButton(
                              key: const Key(
                                'inventory-editor-spatial-diagnostic-dismiss',
                              ),
                              onPressed: controller.dismissHandledError,
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
                              key: const Key(
                                'inventory-editor-retry-orientation',
                              ),
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
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: _EditorToolbar(
                editor: editor,
                onBack: () => unawaited(_attemptExit()),
                onModeChanged: controller.setMode,
                onUndo: controller.undo,
                onRedo: controller.redo,
                onFinish: controller.finishWorkingPolyline,
                onClose: () => unawaited(_closeCurrentBlock()),
                onDelete: () => unawaited(_deleteSelection()),
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
      },
    );
  }

  String? _editorDiagnosticMessage(String? code) => switch (code) {
    'inventory_block_diagonal_edge_reshape_not_supported' =>
      'Çapraz bir kenar bu sürümde yeniden şekillendirilemez. '
          'Bloğun tamamını taşıyabilirsiniz.',
    'inventory_block_edge_nudge_direction_invalid' =>
      'Seçili kenar yalnız kendisine dik yönde taşınabilir.',
    'inventory_block_nudge_out_of_bounds' =>
      'Bu hareket bloğu kroki sınırlarının dışına çıkarır; kayıt değiştirilmedi.',
    'inventory_block_nudge_invalid' =>
      'Bu hareket geçerli bir blok kenarı oluşturmaz; kayıt değiştirilmedi.',
    'inventory_block_polygon_self_intersects' ||
    'inventory_block_polygon_zero_area' ||
    'inventory_block_polygon_ambiguous' =>
      'Bu hareket geçersiz veya başka bir bloğa temas eden bir şekil '
          'oluşturur; kayıt değiştirilmedi.',
    'inventory_mapped_block_segment_delete_not_supported' =>
      'Mevcut bloğun tek kenarı silinemez. Kenarı paralel taşıyın veya '
          'bloğun tamamını seçin.',
    'inventory_block_name_conflict' || 'inventory_block_name_ambiguous' =>
      'Bu ad mevcut blok kimliğiyle çakışıyor; yeni blok oluşturulmadı.',
    'inventory_block_lifecycle_choice_required' =>
      'Krokiden kaldırılan blok için kayıtları koruma seçimi gereklidir.',
    _ => null,
  };
}

class _SelectionMovementWheel extends StatelessWidget {
  const _SelectionMovementWheel({
    required this.onNudge,
    required this.onConfirm,
  });

  final ValueChanged<InventorySketchNudgeDirection> onNudge;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('inventory-editor-movement-wheel'),
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    elevation: 4,
    shape: const CircleBorder(),
    child: SizedBox.square(
      dimension: 160,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: _MovementWheelButton(
                key: const Key('inventory-editor-wheel-up'),
                label: 'Yukarı taşı',
                icon: Icons.keyboard_arrow_up_rounded,
                onPressed: () => onNudge(InventorySketchNudgeDirection.up),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _MovementWheelButton(
                key: const Key('inventory-editor-wheel-right'),
                label: 'Sağa taşı',
                icon: Icons.keyboard_arrow_right_rounded,
                onPressed: () => onNudge(InventorySketchNudgeDirection.right),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _MovementWheelButton(
                key: const Key('inventory-editor-wheel-down'),
                label: 'Aşağı taşı',
                icon: Icons.keyboard_arrow_down_rounded,
                onPressed: () => onNudge(InventorySketchNudgeDirection.down),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _MovementWheelButton(
                key: const Key('inventory-editor-wheel-left'),
                label: 'Sola taşı',
                icon: Icons.keyboard_arrow_left_rounded,
                onPressed: () => onNudge(InventorySketchNudgeDirection.left),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: _MovementWheelButton(
                key: const Key('inventory-editor-wheel-confirm'),
                label: 'Seçimi tamamla',
                icon: Icons.check_rounded,
                emphasized: true,
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MovementWheelButton extends StatelessWidget {
  const _MovementWheelButton({
    required super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: SizedBox.square(
        dimension: 48,
        child: emphasized
            ? IconButton.filled(onPressed: onPressed, icon: Icon(icon))
            : IconButton(onPressed: onPressed, icon: Icon(icon)),
      ),
    ),
  );
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
      key: const Key('inventory-editor-top-toolbar'),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            key: const Key('inventory-editor-modes'),
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarIconButton(
                key: const Key('inventory-editor-back'),
                label: 'Geri',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack,
              ),
              const SizedBox(height: 32, child: VerticalDivider(width: 8)),
              _ToolbarIconButton(
                key: const Key('inventory-editor-mode-draw'),
                label: 'Çiz',
                selected: editor.mode == InventorySketchEditorMode.draw,
                selectedIndicatorKey: const Key(
                  'inventory-editor-mode-selected-draw',
                ),
                icon: const Icon(Icons.polyline_rounded),
                onPressed: () => onModeChanged(InventorySketchEditorMode.draw),
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
                onPressed: () => onModeChanged(InventorySketchEditorMode.pan),
              ),
              const SizedBox(height: 32, child: VerticalDivider(width: 8)),
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
              const SizedBox(height: 32, child: VerticalDivider(width: 8)),
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
              const SizedBox(height: 32, child: VerticalDivider(width: 8)),
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
            ],
          ),
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
    this.selected,
    this.selectedIndicatorKey,
    this.emphasized = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool? selected;
  final Key? selectedIndicatorKey;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final decoratedIcon = selected == true
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
        : selected == true
        ? IconButton.filledTonal(onPressed: onPressed, icon: decoratedIcon)
        : IconButton(onPressed: onPressed, icon: decoratedIcon);
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Tooltip(
        message: label,
        child: SizedBox.square(dimension: 48, child: button),
      ),
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

class _InventoryEditorSpatialFrame {
  _InventoryEditorSpatialFrame({
    required Map<String, int> existingBlockMappings,
    required List<InventoryBlockDraft> newBlocks,
    required Map<String, InventoryExistingBlockAction> lifecycleActions,
  }) : existingBlockMappings = Map<String, int>.unmodifiable(
         existingBlockMappings,
       ),
       newBlocks = List<InventoryBlockDraft>.unmodifiable(newBlocks),
       lifecycleActions =
           Map<String, InventoryExistingBlockAction>.unmodifiable(
             lifecycleActions,
           );

  final Map<String, int> existingBlockMappings;
  final List<InventoryBlockDraft> newBlocks;
  final Map<String, InventoryExistingBlockAction> lifecycleActions;
}

class _PendingDraftSave {
  _PendingDraftSave({
    required this.geometry,
    required this.geometryGeneration,
    required this.lifecycleActions,
    required this.command,
  });

  final InventoryGeometry geometry;
  final int geometryGeneration;
  final Map<String, InventoryExistingBlockAction> lifecycleActions;
  final AutosaveInventorySketchDraftCommand command;
  // Stays bound to this exact command through retries until it is acknowledged
  // or the pending state is explicitly discarded/replaced by an adopted draft.
  bool mutationResultObserved = false;
}
