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

  String? get sketchId => _sketchId;
  String? get draftRevisionId => _draftRevisionId;
  int? get expectedSketchRevision => _expectedSketchRevision;
  int? get expectedContentRevision => _expectedContentRevision;

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
        saveStatus != InventorySketchSaveStatus.saved ||
        hasUnacknowledgedGeometry ||
        !_hasDraftIdentity) {
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

  bool drawPoint(InventorySketchPoint point) =>
      _applyEditorAction(editor?.drawPoint(point));

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
    if (current == null || !current.canUndo) return false;
    return _applyEditorAction(current.undo());
  }

  bool redo() {
    final current = editor;
    if (current == null || !current.canRedo) return false;
    return _applyEditorAction(current.redo());
  }

  bool _applyEditorAction(InventorySketchEditorSnapshot? next) {
    final current = editor;
    if (current == null || next == null || identical(current, next)) {
      return false;
    }
    final geometryChanged =
        current.geometry.canonicalJson != next.geometry.canonicalJson;
    editor = next;
    if (geometryChanged) _scheduleAutosave();
    _notify();
    return true;
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
    } on InventoryGeometryFailure catch (error) {
      lastErrorCode = error.code;
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
      final expectedSketchRevision = _expectedSketchRevision!;
      final expectedContentRevision = _expectedContentRevision!;
      final before = await application.loadPrimarySketch(projectId);
      final draft = _verifiedDraft(before, expectedGeometry: intended);
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
        draft.geometrySha256 != expectedGeometry.sha256) {
      throw const InventoryFailure('inventory_sketch_save_verification_failed');
    }
    return draft;
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
    editor = InventorySketchEditorSnapshot.recover(draft.geometry);
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _geometryGeneration = 0;
    _normalSaveEligibleGeneration = null;
    _forceDrainRequested = false;
    _finalizeBlockedByStaleRevision = false;
    _pendingSave = null;
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
  Object? _pendingPopResult;

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
    if (mounted) setState(() {});
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
    final finalized =
        controller.finalizePersisted || await controller.finalizeDraft();
    if (!finalized || !mounted) return;
    await _attemptExit(true);
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
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: const Key('inventory-editor-back'),
            tooltip: 'Geri',
            onPressed: () => unawaited(_attemptExit()),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Şematik kroki'),
          actions: [
            if (controller.saveLabel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      controller.saveLabel!,
                      key: const Key('inventory-editor-save-status'),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                key: const Key('inventory-editor-finalize'),
                onPressed: controller.isFinalizeEnabled
                    ? () => unawaited(_finalizeAndExit())
                    : null,
                icon: controller.finalizing
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  widget.launchIntent == InventorySketchLaunchIntent.editActive
                      ? 'Güncelle'
                      : 'Oluştur',
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(child: _buildBody(context)),
      ),
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
    return Column(
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
        if (_orientationFailed)
          MaterialBanner(
            content: const Text(
              'Ekran yönü güvenle doğrulanamadı. Kayıt durumu değiştirilmedi.',
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
        _EditorToolbar(
          editor: editor,
          onModeChanged: controller.setMode,
          onUndo: controller.undo,
          onRedo: controller.redo,
          onFinish: controller.finishWorkingPolyline,
          onDelete: controller.deleteSelection,
          onZoomOut: () => _canvasKey.currentState?.zoomOut(),
          onZoomIn: () => _canvasKey.currentState?.zoomIn(),
          onFit: () => _canvasKey.currentState?.fitCanvas(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: InventorySketchCanvas(
              key: _canvasKey,
              snapshot: editor,
              onDrawPoint: controller.drawPoint,
              onSelect: controller.selectAt,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.editor,
    required this.onModeChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onFinish,
    required this.onDelete,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onFit,
  });

  final InventorySketchEditorSnapshot editor;
  final ValueChanged<InventorySketchEditorMode> onModeChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onFinish;
  final VoidCallback onDelete;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SegmentedButton<InventorySketchEditorMode>(
            key: const Key('inventory-editor-modes'),
            segments: const [
              ButtonSegment(
                value: InventorySketchEditorMode.draw,
                icon: Icon(Icons.polyline_rounded),
                label: Text('Çiz'),
              ),
              ButtonSegment(
                value: InventorySketchEditorMode.select,
                icon: Icon(Icons.ads_click_rounded),
                label: Text('Seç'),
              ),
              ButtonSegment(
                value: InventorySketchEditorMode.pan,
                icon: Icon(Icons.pan_tool_alt_outlined),
                label: Text('Taşı'),
              ),
            ],
            selected: {editor.mode},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onModeChanged(selection.single);
            },
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            key: const Key('inventory-editor-undo'),
            tooltip: 'Geri al',
            onPressed: editor.canUndo ? onUndo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            key: const Key('inventory-editor-redo'),
            tooltip: 'İleri al',
            onPressed: editor.canRedo ? onRedo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            key: const Key('inventory-editor-finish-line'),
            onPressed: editor.hasWorkingPolyline ? onFinish : null,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Çizgiyi bitir'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: const Key('inventory-editor-delete'),
            onPressed: editor.selection == null ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Seçileni sil'),
          ),
          const SizedBox(width: 12),
          IconButton(
            key: const Key('inventory-editor-zoom-out'),
            tooltip: 'Uzaklaştır',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove_rounded),
          ),
          IconButton(
            key: const Key('inventory-editor-zoom-in'),
            tooltip: 'Yakınlaştır',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add_rounded),
          ),
          TextButton.icon(
            key: const Key('inventory-editor-fit'),
            onPressed: onFit,
            icon: const Icon(Icons.fit_screen_rounded),
            label: const Text('Tamamını göster'),
          ),
        ],
      ),
    );
  }
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
