import 'dart:async';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/inventory/inventory_asset_quick_form.dart';
import 'package:flutter/material.dart';

enum InventoryAssetDetailLoadStatus { idle, loading, ready, failed }

class InventoryAssetDetailController extends ChangeNotifier {
  InventoryAssetDetailController({
    required this.application,
    required this.projectId,
    required this.assetId,
    required this.reloadMapCanonical,
    RecordIdFactory? idFactory,
  }) : idFactory = idFactory ?? RecordId.randomUuid;

  final InventoryApplicationPort application;
  final String projectId;
  final String assetId;
  final InventoryCanonicalReload reloadMapCanonical;
  final RecordIdFactory idFactory;

  InventoryAssetDetailLoadStatus loadStatus =
      InventoryAssetDetailLoadStatus.idle;
  InventoryAssetProjection? projection;
  List<InventoryPlacementRecord> placementVersions = const [];
  List<InventoryEventRecord> history = const [];
  InventoryPlacementTarget? pendingMoveTarget;
  InventoryPlacementTarget? pendingUnarchiveTarget;
  bool selectingMoveTarget = false;
  bool selectingUnarchiveTarget = false;
  bool actionRunning = false;
  String? lastErrorCode;
  bool _disposed = false;

  InventoryAssetRecord? get asset => projection?.asset;
  InventoryPlacementRecord? get activePlacement => projection?.activePlacement;
  bool get isArchived => asset?.archivedAt != null;
  bool get hasHardDeleteAction => false;

  Future<bool> reload() async {
    loadStatus = InventoryAssetDetailLoadStatus.loading;
    lastErrorCode = null;
    _notify();
    try {
      final loadedProjection = await application.loadAsset(
        projectId: projectId,
        assetId: assetId,
      );
      _verifyProjection(loadedProjection);
      final loadedHistory = await application.listAssetHistory(
        projectId: projectId,
        assetId: assetId,
      );
      _verifyHistory(loadedHistory);
      final placementKey = _exactPlacementKey(loadedProjection, loadedHistory);
      final loadedVersions = await application.listPlacementVersions(
        projectId: projectId,
        assetId: assetId,
        placementKey: placementKey,
      );
      _verifyPlacementVersions(loadedProjection, placementKey, loadedVersions);
      projection = loadedProjection;
      history = List<InventoryEventRecord>.unmodifiable(loadedHistory);
      placementVersions = List<InventoryPlacementRecord>.unmodifiable(
        loadedVersions,
      );
      loadStatus = InventoryAssetDetailLoadStatus.ready;
      lastErrorCode = null;
      _notify();
      return true;
    } on Object catch (error) {
      loadStatus = InventoryAssetDetailLoadStatus.failed;
      lastErrorCode = _safeCode(
        error,
        fallback: 'inventory_asset_detail_failed',
      );
      _notify();
      return false;
    }
  }

  Future<bool> updateMetadata({
    required String displayName,
    required InventoryCategory category,
    String? otherCategoryLabel,
    String? note,
  }) {
    final current = _requireUnarchivedProjection();
    final cleanOther = category == InventoryCategory.other
        ? _cleanOptional(otherCategoryLabel)
        : null;
    return _runMutation(
      () => application.updateAsset(
        UpdateInventoryAssetCommand(
          operationId: _nextId(),
          projectId: projectId,
          assetId: assetId,
          expectedAssetRevision: current.asset.revision,
          displayName: displayName.trim(),
          category: category,
          otherCategoryLabel: cleanOther,
          note: _cleanOptional(note),
        ),
      ),
    );
  }

  Future<bool> changeStatus(InventoryAssetStatus status) {
    final current = _requireUnarchivedProjection();
    return _runMutation(
      () => application.changeAssetStatus(
        ChangeInventoryAssetStatusCommand(
          operationId: _nextId(),
          projectId: projectId,
          assetId: assetId,
          expectedAssetRevision: current.asset.revision,
          status: status,
        ),
      ),
    );
  }

  Future<bool> changeQuantity(int totalQuantity) {
    final current = _requireUnarchivedProjection();
    final placement = _requireSoleCurrentPlacement(current);
    return _runMutation(
      () => application.changeAssetQuantity(
        ChangeInventoryAssetQuantityCommand(
          operationId: _nextId(),
          projectId: projectId,
          assetId: assetId,
          placementKey: placement.placementKey,
          successorPlacementId: _nextId(),
          expectedAssetRevision: current.asset.revision,
          expectedPlacementSequence: placement.sequence,
          totalQuantity: totalQuantity,
        ),
      ),
    );
  }

  bool beginMove() {
    final current = projection;
    if (loadStatus != InventoryAssetDetailLoadStatus.ready ||
        actionRunning ||
        current == null ||
        current.asset.archivedAt != null ||
        current.activePlacement == null) {
      return false;
    }
    selectingMoveTarget = true;
    selectingUnarchiveTarget = false;
    pendingMoveTarget = null;
    pendingUnarchiveTarget = null;
    _notify();
    return true;
  }

  bool previewMove(InventoryPlacementTarget target) {
    if (!selectingMoveTarget || !isValidInventoryPlacementTarget(target)) {
      return false;
    }
    pendingMoveTarget = target;
    _notify();
    return true;
  }

  void cancelMove() {
    if (!selectingMoveTarget && pendingMoveTarget == null) return;
    selectingMoveTarget = false;
    pendingMoveTarget = null;
    _notify();
  }

  Future<bool> confirmMove() {
    final current = _requireUnarchivedProjection();
    final placement = _requireSoleCurrentPlacement(current);
    final target = pendingMoveTarget;
    if (!selectingMoveTarget ||
        target == null ||
        !isValidInventoryPlacementTarget(target)) {
      throw const InventoryFailure('inventory_move_target_unavailable');
    }
    return _runMutation(() async {
      final sketch = await _loadCurrentActiveSketch();
      final result = await application.movePlacement(
        MoveInventoryPlacementCommand(
          operationId: _nextId(),
          projectId: projectId,
          assetId: assetId,
          placementKey: placement.placementKey,
          successorPlacementId: _nextId(),
          sketchId: sketch.sketch.id,
          activeRevisionId: sketch.activeRevision!.id,
          expectedPlacementSequence: placement.sequence,
          x: target.x,
          y: target.y,
        ),
      );
      return result;
    }, clearMoveOnSuccess: true);
  }

  Future<bool> archive() {
    final current = _requireUnarchivedProjection();
    _requireSoleCurrentPlacement(current);
    return _runMutation(
      () => application.archiveAsset(
        ArchiveInventoryAssetCommand(
          operationId: _nextId(),
          projectId: projectId,
          assetId: assetId,
          expectedAssetRevision: current.asset.revision,
        ),
      ),
    );
  }

  bool beginUnarchive() {
    if (loadStatus != InventoryAssetDetailLoadStatus.ready ||
        actionRunning ||
        !isArchived ||
        placementVersions.isEmpty) {
      return false;
    }
    selectingUnarchiveTarget = true;
    selectingMoveTarget = false;
    pendingUnarchiveTarget = null;
    pendingMoveTarget = null;
    _notify();
    return true;
  }

  bool previewUnarchive(InventoryPlacementTarget target) {
    if (!selectingUnarchiveTarget || !isValidInventoryPlacementTarget(target)) {
      return false;
    }
    pendingUnarchiveTarget = target;
    _notify();
    return true;
  }

  void cancelUnarchive() {
    if (!selectingUnarchiveTarget && pendingUnarchiveTarget == null) return;
    selectingUnarchiveTarget = false;
    pendingUnarchiveTarget = null;
    _notify();
  }

  Future<bool> confirmUnarchive() {
    final current = projection;
    final target = pendingUnarchiveTarget;
    if (current == null ||
        current.asset.archivedAt == null ||
        current.activePlacement != null ||
        !selectingUnarchiveTarget ||
        target == null ||
        !isValidInventoryPlacementTarget(target) ||
        placementVersions.isEmpty) {
      throw const InventoryFailure('inventory_unarchive_target_unavailable');
    }
    final predecessor = placementVersions.last;
    if (predecessor.isActive) {
      throw const InventoryFailure('inventory_asset_state_invalid');
    }
    return _runMutation(() async {
      final sketch = await _loadCurrentActiveSketch();
      return application.unarchiveAsset(
        UnarchiveInventoryAssetCommand(
          operationId: _nextId(),
          projectId: projectId,
          assetId: assetId,
          placementKey: predecessor.placementKey,
          successorPlacementId: _nextId(),
          sketchId: sketch.sketch.id,
          activeRevisionId: sketch.activeRevision!.id,
          expectedAssetRevision: current.asset.revision,
          expectedPreviousPlacementSequence: predecessor.sequence,
          x: target.x,
          y: target.y,
        ),
      );
    }, clearUnarchiveOnSuccess: true);
  }

  Future<bool> _runMutation(
    Future<InventoryMutationResult> Function() mutation, {
    bool clearMoveOnSuccess = false,
    bool clearUnarchiveOnSuccess = false,
  }) async {
    if (actionRunning) return false;
    actionRunning = true;
    lastErrorCode = null;
    _notify();
    try {
      await mutation();
      if (!await reload()) {
        throw InventoryFailure(
          lastErrorCode ?? 'inventory_asset_reload_failed',
        );
      }
      await reloadMapCanonical();
      if (clearMoveOnSuccess) {
        selectingMoveTarget = false;
        pendingMoveTarget = null;
      }
      if (clearUnarchiveOnSuccess) {
        selectingUnarchiveTarget = false;
        pendingUnarchiveTarget = null;
      }
      actionRunning = false;
      lastErrorCode = null;
      _notify();
      return true;
    } on Object catch (error) {
      actionRunning = false;
      lastErrorCode = _safeCode(
        error,
        fallback: 'inventory_asset_mutation_failed',
      );
      _notify();
      return false;
    }
  }

  InventoryAssetProjection _requireUnarchivedProjection() {
    final current = projection;
    if (loadStatus != InventoryAssetDetailLoadStatus.ready || current == null) {
      throw const InventoryFailure('inventory_asset_unavailable');
    }
    if (current.asset.archivedAt != null) {
      throw const InventoryFailure('inventory_asset_archived');
    }
    return current;
  }

  InventoryPlacementRecord _requireSoleCurrentPlacement(
    InventoryAssetProjection current,
  ) {
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

  Future<InventoryPrimarySketchProjection> _loadCurrentActiveSketch() async {
    final loaded = await application.loadPrimarySketch(projectId);
    final active = loaded?.activeRevision;
    if (loaded == null ||
        loaded.sketch.projectId != projectId ||
        !loaded.sketch.isPrimary ||
        loaded.sketch.archivedAt != null ||
        loaded.sketch.activeRevisionId != active?.id ||
        active?.projectId != projectId ||
        active?.sketchId != loaded.sketch.id ||
        active?.state != InventorySketchRevisionState.active) {
      throw const InventoryFailure('inventory_active_revision_unavailable');
    }
    return loaded;
  }

  void _verifyProjection(InventoryAssetProjection value) {
    final placement = value.activePlacement;
    if (placement != null && placement.quantity != value.asset.totalQuantity) {
      throw const InventoryFailure(
        'inventory_multiple_placements_not_supported_in_v1',
      );
    }
    if (value.asset.id != assetId ||
        value.asset.projectId != projectId ||
        (value.asset.archivedAt != null && placement != null) ||
        (value.asset.archivedAt == null && placement == null) ||
        (placement != null &&
            (placement.assetId != assetId ||
                placement.projectId != projectId ||
                !placement.isActive ||
                !isValidInventoryPlacementTarget(
                  InventoryPlacementTarget(x: placement.x, y: placement.y),
                )))) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
  }

  void _verifyHistory(List<InventoryEventRecord> values) {
    for (var index = 0; index < values.length; index += 1) {
      final event = values[index];
      if (event.projectId != projectId ||
          (event.aggregateType == InventoryAggregateType.asset &&
              event.aggregateId != assetId)) {
        throw const InventoryFailure('inventory_history_integrity_failed');
      }
      if (index == 0) continue;
      final previous = values[index - 1];
      final ordered =
          previous.occurredAt.isAfter(event.occurredAt) ||
          (previous.occurredAt == event.occurredAt &&
              previous.id.compareTo(event.id) < 0);
      if (!ordered) {
        throw const InventoryFailure('inventory_history_integrity_failed');
      }
    }
  }

  String _exactPlacementKey(
    InventoryAssetProjection value,
    List<InventoryEventRecord> events,
  ) {
    final keys = <String>{
      if (value.activePlacement case final placement?) placement.placementKey,
      for (final event in events)
        if (event.aggregateType == InventoryAggregateType.placement)
          event.aggregateId,
    };
    if (keys.length != 1) {
      throw const InventoryFailure(
        'inventory_multiple_placements_not_supported_in_v1',
      );
    }
    return keys.single;
  }

  void _verifyPlacementVersions(
    InventoryAssetProjection current,
    String placementKey,
    List<InventoryPlacementRecord> values,
  ) {
    if (values.isEmpty) {
      throw const InventoryFailure('inventory_placement_history_unavailable');
    }
    for (var index = 0; index < values.length; index += 1) {
      final value = values[index];
      if (value.projectId != projectId ||
          value.assetId != assetId ||
          value.placementKey != placementKey ||
          value.sequence != index + 1 ||
          (index == 0 && value.supersedesPlacementId != null) ||
          (index > 0 && value.supersedesPlacementId != values[index - 1].id)) {
        throw const InventoryFailure(
          'inventory_placement_history_integrity_failed',
        );
      }
    }
    final last = values.last;
    if ((current.asset.archivedAt == null &&
            (!last.isActive || current.activePlacement?.id != last.id)) ||
        (current.asset.archivedAt != null && last.isActive)) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
  }

  String _nextId() {
    final value = idFactory();
    if (!RecordId.isUuid(value)) {
      throw const InventoryFailure('inventory_invalid_generated_id');
    }
    return value;
  }

  String _safeCode(Object error, {required String fallback}) => switch (error) {
    InventoryFailure() => error.code,
    InventoryGeometryFailure() => error.code,
    _ => fallback,
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String inventoryEventSummary(InventoryEventRecord event) {
  final keys = event.payload.keys.where((key) {
    return key.startsWith('before_') ||
        key.startsWith('after_') ||
        key.endsWith('_status') ||
        key.endsWith('_quantity') ||
        key.endsWith('_reason') ||
        key == 'x' ||
        key == 'y';
  }).toList()..sort();
  if (keys.isEmpty) return event.eventType.storageValue;
  final values = keys.map((key) => '$key=${event.payload[key]}').join(', ');
  return '${event.eventType.storageValue}: $values';
}

class InventoryAssetDetailSheet extends StatefulWidget {
  const InventoryAssetDetailSheet({
    required this.controller,
    this.autoLoad = true,
    this.onMoveTargetRequested,
    this.onUnarchiveTargetRequested,
    super.key,
  });

  final InventoryAssetDetailController controller;
  final bool autoLoad;
  final VoidCallback? onMoveTargetRequested;
  final VoidCallback? onUnarchiveTargetRequested;

  @override
  State<InventoryAssetDetailSheet> createState() =>
      _InventoryAssetDetailSheetState();
}

class _InventoryAssetDetailSheetState extends State<InventoryAssetDetailSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(widget.controller.reload().then((_) {}));
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant InventoryAssetDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.loadStatus == InventoryAssetDetailLoadStatus.idle ||
        controller.loadStatus == InventoryAssetDetailLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.loadStatus == InventoryAssetDetailLoadStatus.failed ||
        controller.asset == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Envanter ayrıntısı açılamadı: ${controller.lastErrorCode}'),
            FilledButton(
              key: const Key('inventory-detail-retry'),
              onPressed: () => unawaited(controller.reload().then((_) {})),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }
    final asset = controller.asset!;
    final placement = controller.activePlacement;
    return ListView(
      key: const Key('inventory-asset-detail'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(asset.displayName, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          asset.category == InventoryCategory.other
              ? '${inventoryCategoryLabel(asset.category)} — ${asset.otherCategoryLabel}'
              : inventoryCategoryLabel(asset.category),
        ),
        Text('${asset.totalQuantity} adet'),
        Text(inventoryAssetStatusLabel(asset.status)),
        if (asset.note case final note?) Text(note),
        if (placement != null)
          Text('Şematik kroki konumu: ${placement.x}, ${placement.y}')
        else
          const Text('Arşivli — aktif kroki yerleşimi yok'),
        if (controller.lastErrorCode case final code?)
          Text(
            'İşlem tamamlanamadı. Tanı kodu: $code',
            key: const Key('inventory-detail-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        if (!controller.isArchived) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('inventory-detail-edit-metadata'),
                onPressed: controller.actionRunning
                    ? null
                    : () => unawaited(_editMetadata(context, controller)),
                child: const Text('Bilgileri düzenle'),
              ),
              PopupMenuButton<InventoryAssetStatus>(
                key: const Key('inventory-detail-status'),
                tooltip: 'Durumu değiştir',
                enabled: !controller.actionRunning,
                onSelected: (status) =>
                    unawaited(controller.changeStatus(status)),
                itemBuilder: (_) => [
                  for (final status in InventoryAssetStatus.values)
                    PopupMenuItem(
                      value: status,
                      child: Text(inventoryAssetStatusLabel(status)),
                    ),
                ],
              ),
              OutlinedButton(
                key: const Key('inventory-detail-quantity'),
                onPressed: controller.actionRunning
                    ? null
                    : () => unawaited(_editQuantity(context, controller)),
                child: const Text('Adedi değiştir'),
              ),
              OutlinedButton(
                key: const Key('inventory-detail-move'),
                onPressed: controller.actionRunning
                    ? null
                    : () {
                        if (controller.beginMove()) {
                          widget.onMoveTargetRequested?.call();
                        }
                      },
                child: const Text('Taşı'),
              ),
              OutlinedButton(
                key: const Key('inventory-detail-archive'),
                onPressed: controller.actionRunning
                    ? null
                    : () => unawaited(controller.archive()),
                child: const Text('Arşivle'),
              ),
            ],
          ),
          if (controller.selectingMoveTarget) ...[
            const SizedBox(height: 8),
            Text(
              controller.pendingMoveTarget == null
                  ? 'Yeni konumu kroki üzerinde seçin.'
                  : 'Yeni konum: ${controller.pendingMoveTarget!.x}, ${controller.pendingMoveTarget!.y}',
            ),
            Row(
              children: [
                TextButton(
                  key: const Key('inventory-detail-move-cancel'),
                  onPressed: controller.cancelMove,
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  key: const Key('inventory-detail-move-confirm'),
                  onPressed:
                      controller.pendingMoveTarget == null ||
                          controller.actionRunning
                      ? null
                      : () => unawaited(controller.confirmMove()),
                  child: const Text('Konumu güncelle'),
                ),
              ],
            ),
          ],
        ] else ...[
          FilledButton(
            key: const Key('inventory-detail-unarchive'),
            onPressed: controller.actionRunning
                ? null
                : () {
                    if (controller.beginUnarchive()) {
                      widget.onUnarchiveTargetRequested?.call();
                    }
                  },
            child: const Text('Arşivden çıkar'),
          ),
          if (controller.selectingUnarchiveTarget) ...[
            Text(
              controller.pendingUnarchiveTarget == null
                  ? 'Yeni aktif kroki konumunu seçin.'
                  : 'Yeni konum: ${controller.pendingUnarchiveTarget!.x}, ${controller.pendingUnarchiveTarget!.y}',
            ),
            Row(
              children: [
                TextButton(
                  key: const Key('inventory-detail-unarchive-cancel'),
                  onPressed: controller.cancelUnarchive,
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  key: const Key('inventory-detail-unarchive-confirm'),
                  onPressed:
                      controller.pendingUnarchiveTarget == null ||
                          controller.actionRunning
                      ? null
                      : () => unawaited(controller.confirmUnarchive()),
                  child: const Text('Konumu doğrula ve çıkar'),
                ),
              ],
            ),
          ],
        ],
        const Divider(height: 32),
        Text('Geçmiş', style: Theme.of(context).textTheme.titleMedium),
        for (final event in controller.history)
          ListTile(
            key: Key('inventory-history-${event.id}'),
            dense: true,
            title: Text(event.eventType.storageValue),
            subtitle: Text(inventoryEventSummary(event)),
            trailing: Text(event.occurredAt.toIso8601String()),
          ),
      ],
    );
  }

  Future<void> _editMetadata(
    BuildContext context,
    InventoryAssetDetailController controller,
  ) async {
    final current = controller.asset!;
    final name = TextEditingController(text: current.displayName);
    final other = TextEditingController(text: current.otherCategoryLabel);
    final note = TextEditingController(text: current.note);
    var category = current.category;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Envanter bilgileri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Ad'),
                ),
                DropdownButtonFormField<InventoryCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [
                    for (final value in InventoryCategory.values)
                      DropdownMenuItem(
                        value: value,
                        child: Text(inventoryCategoryLabel(value)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      category = value;
                      if (value != InventoryCategory.other) other.clear();
                    });
                  },
                ),
                if (category == InventoryCategory.other)
                  TextField(
                    controller: other,
                    decoration: const InputDecoration(
                      labelText: 'Diğer kategori',
                    ),
                  ),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Not'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (submitted == true) {
      await controller.updateMetadata(
        displayName: name.text,
        category: category,
        otherCategoryLabel: other.text,
        note: note.text,
      );
    }
    name.dispose();
    other.dispose();
    note.dispose();
  }

  Future<void> _editQuantity(
    BuildContext context,
    InventoryAssetDetailController controller,
  ) async {
    final text = TextEditingController(
      text: controller.asset!.totalQuantity.toString(),
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adedi değiştir'),
        content: TextField(
          controller: text,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Adet'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    final quantity = int.tryParse(text.text.trim());
    text.dispose();
    if (submitted == true && quantity != null) {
      await controller.changeQuantity(quantity);
    }
  }
}

String? _cleanOptional(String? value) {
  if (value == null) return null;
  final clean = value.trim();
  return clean.isEmpty ? null : clean;
}
