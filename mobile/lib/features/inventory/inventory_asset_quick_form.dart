import 'dart:async';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:flutter/material.dart';

typedef InventoryCanonicalReload = Future<void> Function();

class InventoryPlacementTarget {
  const InventoryPlacementTarget({required this.x, required this.y});

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is InventoryPlacementTarget && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

bool isValidInventoryPlacementTarget(InventoryPlacementTarget target) =>
    target.x >= 0 &&
    target.x <= InventoryGeometryContract.canvasWidth &&
    target.y >= 0 &&
    target.y <= InventoryGeometryContract.canvasHeight &&
    target.x % InventoryGeometryContract.placementStep == 0 &&
    target.y % InventoryGeometryContract.placementStep == 0;

String inventoryCategoryLabel(InventoryCategory category) => switch (category) {
  InventoryCategory.equipment => 'Makine / ekipman',
  InventoryCategory.powerTool => 'Elektrikli el aleti',
  InventoryCategory.handTool => 'El aleti',
  InventoryCategory.measurementDevice => 'Ölçüm cihazı',
  InventoryCategory.safetyEquipment => 'İSG ekipmanı',
  InventoryCategory.temporaryWorks => 'Geçici imalat',
  InventoryCategory.siteFacility => 'Şantiye tesisi',
  InventoryCategory.other => 'Diğer',
};

String inventoryAssetStatusLabel(InventoryAssetStatus status) =>
    switch (status) {
      InventoryAssetStatus.available => 'Mevcut',
      InventoryAssetStatus.inUse => 'Kullanımda',
      InventoryAssetStatus.outOfService => 'Kullanım dışı',
      InventoryAssetStatus.missing => 'Kayıp',
    };

enum InventoryQuickCreateStatus { idle, submitting, succeeded, failed }

class InventoryAssetQuickCreateController extends ChangeNotifier {
  InventoryAssetQuickCreateController({
    required this.application,
    required this.projectId,
    required this.reloadCanonical,
    RecordIdFactory? idFactory,
  }) : idFactory = idFactory ?? RecordId.randomUuid;

  final InventoryApplicationPort application;
  final String projectId;
  final InventoryCanonicalReload reloadCanonical;
  final RecordIdFactory idFactory;

  InventoryQuickCreateStatus status = InventoryQuickCreateStatus.idle;
  String? lastErrorCode;
  String? lastCreatedAssetId;

  Future<bool> submit({
    required InventoryPlacementTarget target,
    required String displayName,
    required InventoryCategory? category,
    required String quantityText,
    String? otherCategoryLabel,
    InventoryAssetStatus assetStatus = InventoryAssetStatus.available,
    String? note,
  }) async {
    if (status == InventoryQuickCreateStatus.submitting) return false;
    lastCreatedAssetId = null;
    lastErrorCode = null;
    try {
      final cleanName = displayName.trim();
      if (cleanName.isEmpty || cleanName.runes.length > 120) {
        throw const InventoryFailure('inventory_invalid_asset_name');
      }
      if (category == null) {
        throw const InventoryFailure('inventory_invalid_asset_category');
      }
      final quantity = int.tryParse(quantityText.trim());
      if (quantity == null || quantity < 1 || quantity > 1000000) {
        throw const InventoryFailure('inventory_invalid_quantity');
      }
      final cleanOther = _cleanOptional(otherCategoryLabel);
      if (category == InventoryCategory.other) {
        if (cleanOther == null || cleanOther.runes.length > 80) {
          throw const InventoryFailure(
            'inventory_invalid_other_category_label',
          );
        }
      }
      final commandOther = category == InventoryCategory.other
          ? cleanOther
          : null;
      final cleanNote = _cleanOptional(note);
      if (cleanNote != null && cleanNote.runes.length > 1000) {
        throw const InventoryFailure('inventory_invalid_asset_note');
      }
      if (!isValidInventoryPlacementTarget(target)) {
        throw const InventoryFailure('inventory_invalid_placement_coordinate');
      }

      status = InventoryQuickCreateStatus.submitting;
      notifyListeners();
      final sketch = await _loadCurrentActiveSketch();
      final operationId = _nextId();
      final assetId = _nextId();
      final placementId = _nextId();
      final placementKey = _nextId();
      final result = await application.createAsset(
        CreateInventoryAssetCommand(
          operationId: operationId,
          projectId: projectId,
          assetId: assetId,
          placementId: placementId,
          placementKey: placementKey,
          sketchId: sketch.sketch.id,
          activeRevisionId: sketch.activeRevision!.id,
          displayName: cleanName,
          category: category,
          otherCategoryLabel: commandOther,
          totalQuantity: quantity,
          status: assetStatus,
          note: cleanNote,
          x: target.x,
          y: target.y,
        ),
      );
      if (result.commandType != InventoryCommandType.assetCreateWithPlacement ||
          result.projectId != projectId ||
          result.sourceId != assetId ||
          result.supportingId != placementId ||
          result.isNoOp) {
        throw const InventoryFailure(
          'inventory_asset_create_verification_failed',
        );
      }
      await reloadCanonical();
      lastCreatedAssetId = assetId;
      status = InventoryQuickCreateStatus.succeeded;
      notifyListeners();
      return true;
    } on Object catch (error) {
      status = InventoryQuickCreateStatus.failed;
      lastErrorCode = _safeInventoryCode(
        error,
        fallback: 'inventory_asset_create_failed',
      );
      notifyListeners();
      return false;
    }
  }

  Future<InventoryPrimarySketchProjection> _loadCurrentActiveSketch() async {
    final projection = await application.loadPrimarySketch(projectId);
    final active = projection?.activeRevision;
    if (projection == null ||
        projection.sketch.projectId != projectId ||
        !projection.sketch.isPrimary ||
        projection.sketch.archivedAt != null ||
        projection.sketch.activeRevisionId == null ||
        projection.sketch.activeRevisionId != active?.id ||
        active?.projectId != projectId ||
        active?.sketchId != projection.sketch.id ||
        active?.state != InventorySketchRevisionState.active) {
      throw const InventoryFailure('inventory_active_revision_unavailable');
    }
    return projection;
  }

  String _nextId() {
    final value = idFactory();
    if (!RecordId.isUuid(value)) {
      throw const InventoryFailure('inventory_invalid_generated_id');
    }
    return value;
  }
}

class InventoryAssetQuickForm extends StatefulWidget {
  const InventoryAssetQuickForm({
    required this.controller,
    required this.target,
    this.onCreated,
    super.key,
  });

  final InventoryAssetQuickCreateController controller;
  final InventoryPlacementTarget target;
  final ValueChanged<String>? onCreated;

  @override
  State<InventoryAssetQuickForm> createState() =>
      _InventoryAssetQuickFormState();
}

class _InventoryAssetQuickFormState extends State<InventoryAssetQuickForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _other = TextEditingController();
  final _note = TextEditingController();
  InventoryCategory? _category;
  InventoryAssetStatus _status = InventoryAssetStatus.available;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant InventoryAssetQuickForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final succeeded = await widget.controller.submit(
      target: widget.target,
      displayName: _name.text,
      category: _category,
      otherCategoryLabel: _other.text,
      quantityText: _quantity.text,
      assetStatus: _status,
      note: _note.text,
    );
    final createdId = widget.controller.lastCreatedAssetId;
    if (succeeded && createdId != null) widget.onCreated?.call(createdId);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _name.dispose();
    _quantity.dispose();
    _other.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitting =
        widget.controller.status == InventoryQuickCreateStatus.submitting;
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('inventory-quick-form'),
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text('Envanter ekle', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Şematik kroki konumu: ${widget.target.x}, ${widget.target.y}'),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('inventory-quick-name'),
            controller: _name,
            decoration: const InputDecoration(labelText: 'Ad'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ad gerekli' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<InventoryCategory>(
            key: const Key('inventory-quick-category'),
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: [
              for (final category in InventoryCategory.values)
                DropdownMenuItem(
                  value: category,
                  child: Text(inventoryCategoryLabel(category)),
                ),
            ],
            onChanged: submitting
                ? null
                : (value) {
                    setState(() {
                      _category = value;
                      if (value != InventoryCategory.other) _other.clear();
                    });
                  },
            validator: (value) => value == null ? 'Kategori gerekli' : null,
          ),
          if (_category == InventoryCategory.other) ...[
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('inventory-quick-other-category'),
              controller: _other,
              decoration: const InputDecoration(labelText: 'Diğer kategori'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Diğer kategori gerekli'
                  : null,
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('inventory-quick-quantity'),
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Adet'),
            validator: (value) {
              final parsed = int.tryParse(value?.trim() ?? '');
              return parsed == null || parsed < 1 || parsed > 1000000
                  ? 'Geçerli pozitif adet gerekli'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<InventoryAssetStatus>(
            key: const Key('inventory-quick-status'),
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Durum'),
            items: [
              for (final status in InventoryAssetStatus.values)
                DropdownMenuItem(
                  value: status,
                  child: Text(inventoryAssetStatusLabel(status)),
                ),
            ],
            onChanged: submitting
                ? null
                : (value) {
                    if (value != null) setState(() => _status = value);
                  },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('inventory-quick-note'),
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Not (isteğe bağlı)'),
          ),
          if (widget.controller.lastErrorCode case final code?) ...[
            const SizedBox(height: 12),
            Text(
              'Kayıt oluşturulamadı. Tanı kodu: $code',
              key: const Key('inventory-quick-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('inventory-quick-submit'),
            onPressed: submitting ? null : () => unawaited(_submit()),
            icon: submitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_location_alt_outlined),
            label: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

String? _cleanOptional(String? value) {
  if (value == null) return null;
  final clean = value.trim();
  return clean.isEmpty ? null : clean;
}

String _safeInventoryCode(Object error, {required String fallback}) =>
    switch (error) {
      InventoryFailure() => error.code,
      InventoryGeometryFailure() => error.code,
      _ => fallback,
    };
