import 'dart:async';

import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/inventory/inventory_asset_quick_form.dart';
import 'package:chief_site_engineer/features/inventory/inventory_sketch_canvas.dart';
import 'package:flutter/material.dart';

enum InventoryMapLoadStatus { idle, loading, ready, failed }

InventoryPlacementTarget? captureInventoryPlacementTarget(
  Offset viewPoint,
  InventoryViewport viewport,
) {
  final source = viewport.viewToVirtual(viewPoint);
  if (!source.dx.isFinite ||
      !source.dy.isFinite ||
      source.dx < 0 ||
      source.dx > InventoryGeometryContract.canvasWidth ||
      source.dy < 0 ||
      source.dy > InventoryGeometryContract.canvasHeight) {
    return null;
  }
  return InventoryPlacementTarget(
    x: _quantizePlacementDouble(
      source.dx,
      maximum: InventoryGeometryContract.canvasWidth,
    ),
    y: _quantizePlacementDouble(
      source.dy,
      maximum: InventoryGeometryContract.canvasHeight,
    ),
  );
}

int _quantizePlacementDouble(double value, {required int maximum}) {
  const step = InventoryGeometryContract.placementStep;
  final lower = (value / step).floor() * step;
  final remainder = value - lower;
  final snapped = remainder <= step / 2 ? lower : lower + step;
  return snapped.clamp(0, maximum).toInt();
}

class InventoryMapController extends ChangeNotifier {
  InventoryMapController({required this.application, required this.projectId});

  final InventoryApplicationPort application;
  final String projectId;

  InventoryMapLoadStatus loadStatus = InventoryMapLoadStatus.idle;
  InventoryPrimarySketchProjection? sketch;
  List<InventoryAssetProjection> projections = const [];
  InventoryPlacementTarget? pendingCreateTarget;
  String? movingAssetId;
  InventoryPlacementTarget? pendingMoveTarget;
  String? lastErrorCode;
  bool _disposed = false;

  InventorySketchRevisionRecord? get activeRevision => sketch?.activeRevision;
  bool get canMutateMap =>
      loadStatus == InventoryMapLoadStatus.ready && activeRevision != null;

  bool useCanonicalSnapshot({
    required InventoryPrimarySketchProjection activeSketch,
    required Iterable<InventoryAssetProjection> assets,
    Iterable<String>? visibleAssetIds,
  }) {
    try {
      _verifyActiveSketch(activeSketch);
      final verified = <InventoryAssetProjection>[];
      final assetIds = <String>{};
      for (final projection in assets) {
        if (!assetIds.add(projection.asset.id)) {
          throw const InventoryFailure(
            'inventory_multiple_placements_not_supported_in_v1',
          );
        }
        _verifyMarkerProjection(projection, activeSketch);
        verified.add(projection);
      }
      final requestedVisibleIds = visibleAssetIds?.toList(growable: false);
      final visibleIds = requestedVisibleIds?.toSet();
      if (requestedVisibleIds != null &&
          (visibleIds!.length != requestedVisibleIds.length ||
              !assetIds.containsAll(visibleIds))) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
      sketch = activeSketch;
      projections = List<InventoryAssetProjection>.unmodifiable(
        visibleIds == null
            ? verified
            : verified.where(
                (projection) => visibleIds.contains(projection.asset.id),
              ),
      );
      pendingCreateTarget = null;
      loadStatus = InventoryMapLoadStatus.ready;
      lastErrorCode = null;
      _notify();
      return true;
    } on Object catch (error) {
      _failSnapshot(_safeCode(error));
      return false;
    }
  }

  void clearSession() {
    sketch = null;
    projections = const [];
    pendingCreateTarget = null;
    movingAssetId = null;
    pendingMoveTarget = null;
    loadStatus = InventoryMapLoadStatus.idle;
    lastErrorCode = null;
    _notify();
  }

  Future<bool> reload() async {
    loadStatus = InventoryMapLoadStatus.loading;
    lastErrorCode = null;
    _notify();
    try {
      final loadedSketch = await application.loadPrimarySketch(projectId);
      _verifyActiveSketch(loadedSketch);
      final loadedAssets = await application.listAssets(
        projectId: projectId,
        includeArchived: false,
      );
      return useCanonicalSnapshot(
        activeSketch: loadedSketch!,
        assets: loadedAssets,
      );
    } on Object catch (error) {
      _failSnapshot(_safeCode(error));
      return false;
    }
  }

  void _failSnapshot(String code) {
    sketch = null;
    projections = const [];
    pendingCreateTarget = null;
    movingAssetId = null;
    pendingMoveTarget = null;
    loadStatus = InventoryMapLoadStatus.failed;
    lastErrorCode = code;
    _notify();
  }

  InventoryPlacementTarget? captureEmptyMapTap(
    Offset viewPoint,
    InventoryViewport viewport,
  ) {
    if (!canMutateMap || _hitsMarker(viewPoint, viewport)) return null;
    final target = captureInventoryPlacementTarget(viewPoint, viewport);
    if (target == null) return null;
    pendingCreateTarget = target;
    _notify();
    return target;
  }

  void clearCreateTarget() {
    if (pendingCreateTarget == null) return;
    pendingCreateTarget = null;
    _notify();
  }

  bool beginMove(String assetId) {
    final projection = _projectionFor(assetId);
    if (!canMutateMap || projection?.activePlacement == null) return false;
    movingAssetId = assetId;
    pendingMoveTarget = null;
    pendingCreateTarget = null;
    _notify();
    return true;
  }

  InventoryPlacementTarget? previewMoveTarget(
    Offset viewPoint,
    InventoryViewport viewport,
  ) {
    if (!canMutateMap || movingAssetId == null) return null;
    final target = captureInventoryPlacementTarget(viewPoint, viewport);
    if (target == null) return null;
    pendingMoveTarget = target;
    _notify();
    return target;
  }

  void cancelMove() {
    if (movingAssetId == null && pendingMoveTarget == null) return;
    movingAssetId = null;
    pendingMoveTarget = null;
    _notify();
  }

  InventoryAssetProjection? _projectionFor(String assetId) {
    for (final projection in projections) {
      if (projection.asset.id == assetId) return projection;
    }
    return null;
  }

  bool _hitsMarker(Offset viewPoint, InventoryViewport viewport) {
    for (final projection in projections) {
      final placement = projection.activePlacement;
      if (placement == null) continue;
      final center = _placementToView(placement, viewport);
      if ((viewPoint.dx - center.dx).abs() <= 24 &&
          (viewPoint.dy - center.dy).abs() <= 24) {
        return true;
      }
    }
    return false;
  }

  void _verifyActiveSketch(InventoryPrimarySketchProjection? value) {
    final active = value?.activeRevision;
    if (value == null ||
        value.sketch.projectId != projectId ||
        !value.sketch.isPrimary ||
        value.sketch.archivedAt != null ||
        value.sketch.activeRevisionId == null ||
        value.sketch.activeRevisionId != active?.id ||
        active?.projectId != projectId ||
        active?.sketchId != value.sketch.id ||
        active?.state != InventorySketchRevisionState.active) {
      throw const InventoryFailure('inventory_active_revision_unavailable');
    }
  }

  void _verifyMarkerProjection(
    InventoryAssetProjection value,
    InventoryPrimarySketchProjection activeSketch,
  ) {
    final asset = value.asset;
    final placement = value.activePlacement;
    if (placement != null && placement.quantity != asset.totalQuantity) {
      throw const InventoryFailure(
        'inventory_multiple_placements_not_supported_in_v1',
      );
    }
    if (asset.projectId != projectId ||
        asset.archivedAt != null ||
        placement == null ||
        !placement.isActive ||
        placement.projectId != projectId ||
        placement.assetId != asset.id ||
        placement.sketchId != activeSketch.sketch.id ||
        !isValidInventoryPlacementTarget(
          InventoryPlacementTarget(x: placement.x, y: placement.y),
        )) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
  }

  String _safeCode(Object error) => switch (error) {
    InventoryFailure() => error.code,
    InventoryGeometryFailure() => error.code,
    _ => 'inventory_map_failed',
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

class InventoryMapView extends StatefulWidget {
  const InventoryMapView({
    required this.controller,
    required this.onCreateTarget,
    required this.onOpenAsset,
    this.onSelectTarget,
    this.autoLoad = true,
    super.key,
  });

  final InventoryMapController controller;
  final ValueChanged<InventoryPlacementTarget> onCreateTarget;
  final ValueChanged<String> onOpenAsset;
  final ValueChanged<InventoryPlacementTarget>? onSelectTarget;
  final bool autoLoad;

  @override
  State<InventoryMapView> createState() => InventoryMapViewState();
}

class InventoryMapViewState extends State<InventoryMapView> {
  InventoryViewport? _viewport;
  InventoryViewport? _gestureStartViewport;
  Offset _gestureStartFocal = Offset.zero;
  Offset _lastFocal = Offset.zero;
  bool _multiTouchGesture = false;
  Timer? _highlightTimer;
  String? _highlightedAssetId;

  InventoryViewport? get viewport => _viewport;
  String? get highlightedAssetId => _highlightedAssetId;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(widget.controller.reload());
      });
    }
  }

  @override
  void didUpdateWidget(covariant InventoryMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
      _highlightTimer?.cancel();
      _highlightTimer = null;
      _highlightedAssetId = null;
      _viewport = null;
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void zoomIn() => _changeZoom(1.25);
  void zoomOut() => _changeZoom(0.8);

  void fitCanvas() {
    final current = _viewport;
    if (current != null) setState(() => _viewport = current.reset());
  }

  bool focusAsset(
    String assetId, {
    Duration highlightDuration = const Duration(seconds: 2),
  }) {
    final current = _viewport;
    if (current == null) return false;
    InventoryPlacementRecord? placement;
    for (final projection in widget.controller.projections) {
      if (projection.asset.id == assetId) {
        placement = projection.activePlacement;
        break;
      }
    }
    if (placement == null) return false;
    final initialPoint = _placementToView(placement, current);
    var focused = current.zoom < 2 ? current.zoomAt(2, initialPoint) : current;
    final focusedPoint = _placementToView(placement, focused);
    focused = focused.panBy(
      focused.viewSize.center(Offset.zero) - focusedPoint,
    );
    _highlightTimer?.cancel();
    setState(() {
      _viewport = focused;
      _highlightedAssetId = assetId;
    });
    _highlightTimer = Timer(highlightDuration, () {
      if (mounted && _highlightedAssetId == assetId) {
        setState(() => _highlightedAssetId = null);
      }
    });
    return true;
  }

  void clearFocus() {
    _highlightTimer?.cancel();
    _highlightTimer = null;
    if (_highlightedAssetId != null && mounted) {
      setState(() => _highlightedAssetId = null);
    } else {
      _highlightedAssetId = null;
    }
  }

  void _changeZoom(double factor) {
    final current = _viewport;
    if (current == null) return;
    setState(() {
      _viewport = current.zoomAt(
        current.zoom * factor,
        current.viewSize.center(Offset.zero),
      );
    });
  }

  void _handleTap(TapUpDetails details) {
    if (_multiTouchGesture) {
      _multiTouchGesture = false;
      return;
    }
    final current = _viewport;
    if (current == null) return;
    final selectTarget = widget.onSelectTarget;
    if (selectTarget != null) {
      final target = captureInventoryPlacementTarget(
        details.localPosition,
        current,
      );
      if (target != null) selectTarget(target);
      return;
    }
    if (widget.controller.movingAssetId != null) {
      widget.controller.previewMoveTarget(details.localPosition, current);
      return;
    }
    final target = widget.controller.captureEmptyMapTap(
      details.localPosition,
      current,
    );
    if (target != null) widget.onCreateTarget(target);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    final current = _viewport;
    if (current == null) return;
    _gestureStartViewport = current;
    _gestureStartFocal = details.localFocalPoint;
    _lastFocal = details.localFocalPoint;
    _multiTouchGesture = details.pointerCount >= 2;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final start = _gestureStartViewport;
    final current = _viewport;
    if (start == null || current == null) return;
    if (details.pointerCount >= 2) {
      _multiTouchGesture = true;
      final zoomed = start.zoomAt(
        start.zoom * details.scale,
        _gestureStartFocal,
      );
      setState(() {
        _viewport = zoomed.panBy(details.localFocalPoint - _gestureStartFocal);
      });
      _lastFocal = details.localFocalPoint;
      return;
    }
    final delta = details.localFocalPoint - _lastFocal;
    setState(() => _viewport = current.panBy(delta));
    _lastFocal = details.localFocalPoint;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _gestureStartViewport = null;
    _multiTouchGesture = false;
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.loadStatus == InventoryMapLoadStatus.loading ||
        widget.controller.loadStatus == InventoryMapLoadStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.controller.loadStatus == InventoryMapLoadStatus.failed ||
        widget.controller.activeRevision == null) {
      return _InventoryMapFailure(
        code: widget.controller.lastErrorCode ?? 'inventory_map_failed',
        onRetry: widget.controller.reload,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_viewport == null || _viewport!.viewSize != size) {
          _viewport = InventoryViewport.fit(size);
        }
        final viewport = _viewport!;
        return Semantics(
          container: true,
          label: 'Şematik kroki envanter haritası',
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('inventory-map-gesture'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _handleTap,
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    onScaleEnd: _handleScaleEnd,
                    child: CustomPaint(
                      key: const Key('inventory-map-paint'),
                      painter: _InventoryMapPainter(
                        geometry: widget.controller.activeRevision!.geometry,
                        viewport: viewport,
                        preview: widget.controller.pendingMoveTarget,
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                for (final projection in widget.controller.projections)
                  _InventoryMarker(
                    projection: projection,
                    viewport: viewport,
                    highlighted: _highlightedAssetId == projection.asset.id,
                    onTap: () {
                      final selectTarget = widget.onSelectTarget;
                      if (selectTarget != null) {
                        final placement = projection.activePlacement!;
                        selectTarget(
                          InventoryPlacementTarget(
                            x: placement.x,
                            y: placement.y,
                          ),
                        );
                        return;
                      }
                      widget.onOpenAsset(projection.asset.id);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InventoryMarker extends StatelessWidget {
  const _InventoryMarker({
    required this.projection,
    required this.viewport,
    required this.highlighted,
    required this.onTap,
  });

  final InventoryAssetProjection projection;
  final InventoryViewport viewport;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placement = projection.activePlacement!;
    final center = _placementToView(placement, viewport);
    final status = inventoryAssetStatusLabel(projection.asset.status);
    final label =
        '${projection.asset.displayName}, ${projection.asset.totalQuantity} adet, $status'
        '${highlighted ? ', odaklandı' : ''}';
    return Positioned(
      left: center.dx - 24,
      top: center.dy - 24,
      width: 48,
      height: 48,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        liveRegion: highlighted,
        button: true,
        label: label,
        onTap: onTap,
        child: Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: CircleBorder(
            side: highlighted
                ? BorderSide(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    width: 3,
                  )
                : BorderSide.none,
          ),
          child: InkWell(
            key: Key('inventory-marker-${projection.asset.id}'),
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  projection.asset.totalQuantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (highlighted)
                  const Positioned(
                    right: 1,
                    top: 1,
                    child: Icon(Icons.center_focus_strong, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Offset _placementToView(
  InventoryPlacementRecord placement,
  InventoryViewport viewport,
) =>
    viewport.origin +
    Offset(placement.x * viewport.scale, placement.y * viewport.scale);

class _InventoryMapPainter extends CustomPainter {
  const _InventoryMapPainter({
    required this.geometry,
    required this.viewport,
    required this.preview,
    required this.colorScheme,
  });

  final InventoryGeometry geometry;
  final InventoryViewport viewport;
  final InventoryPlacementTarget? preview;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(colorScheme.surfaceContainerLowest, BlendMode.src);
    final canvasRect = viewport.origin & viewport.canvasViewSize;
    canvas.drawRect(
      canvasRect,
      Paint()
        ..color = colorScheme.surface
        ..style = PaintingStyle.fill,
    );
    canvas.save();
    canvas.clipRect(canvasRect);
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.fill;
    for (var x = 0; x <= InventoryGeometryContract.canvasWidth; x += 64) {
      for (var y = 0; y <= InventoryGeometryContract.canvasHeight; y += 64) {
        final point =
            viewport.origin + Offset(x * viewport.scale, y * viewport.scale);
        canvas.drawCircle(point, 1.2, gridPaint);
      }
    }
    final linePaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final polyline in geometry.polylines) {
      final path = Path();
      final first = viewport.virtualToView(polyline.points.first);
      path.moveTo(first.dx, first.dy);
      for (var index = 1; index < polyline.points.length; index += 1) {
        final point = viewport.virtualToView(polyline.points[index]);
        path.lineTo(point.dx, point.dy);
      }
      if (polyline.closed) path.close();
      canvas.drawPath(path, linePaint);
    }
    if (preview case final target?) {
      final point =
          viewport.origin +
          Offset(target.x * viewport.scale, target.y * viewport.scale);
      final previewPaint = Paint()
        ..color = colorScheme.tertiary
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(point, 12, previewPaint);
      canvas.drawLine(
        point - const Offset(16, 0),
        point + const Offset(16, 0),
        previewPaint,
      );
      canvas.drawLine(
        point - const Offset(0, 16),
        point + const Offset(0, 16),
        previewPaint,
      );
    }
    canvas.restore();
    canvas.drawRect(
      canvasRect,
      Paint()
        ..color = colorScheme.outline
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_InventoryMapPainter oldDelegate) =>
      oldDelegate.geometry.canonicalJson != geometry.canonicalJson ||
      oldDelegate.viewport.zoom != viewport.zoom ||
      oldDelegate.viewport.pan != viewport.pan ||
      oldDelegate.viewport.viewSize != viewport.viewSize ||
      oldDelegate.preview != preview ||
      oldDelegate.colorScheme != colorScheme;
}

class _InventoryMapFailure extends StatelessWidget {
  const _InventoryMapFailure({required this.code, required this.onRetry});

  final String code;
  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('Şematik kroki güvenle açılamadı.'),
          const SizedBox(height: 8),
          Text('Tanı kodu: $code'),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('inventory-map-retry'),
            onPressed: () => unawaited(onRetry().then((_) {})),
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    ),
  );
}
