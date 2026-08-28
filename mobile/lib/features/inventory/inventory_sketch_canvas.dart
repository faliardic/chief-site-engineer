import 'dart:math' as math;

import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:flutter/material.dart';

enum InventorySketchEditorMode { draw, select, pan }

class InventorySketchSelection {
  const InventorySketchSelection.segment({
    required this.polylineIndex,
    required this.segmentIndex,
  }) : wholePolyline = false;

  const InventorySketchSelection.polyline({required this.polylineIndex})
    : segmentIndex = null,
      wholePolyline = true;

  final int polylineIndex;
  final int? segmentIndex;
  final bool wholePolyline;

  String get semanticLabel => wholePolyline
      ? '${polylineIndex + 1}. çizgi seçili'
      : '${polylineIndex + 1}. çizginin ${(segmentIndex ?? 0) + 1}. parçası seçili';

  @override
  bool operator ==(Object other) =>
      other is InventorySketchSelection &&
      other.polylineIndex == polylineIndex &&
      other.segmentIndex == segmentIndex &&
      other.wholePolyline == wholePolyline;

  @override
  int get hashCode => Object.hash(polylineIndex, segmentIndex, wholePolyline);
}

class InventorySketchEditorSnapshot {
  InventorySketchEditorSnapshot._({
    required this.geometry,
    required this.mode,
    required this.selection,
    required this.workingPolylineIndex,
    required List<_InventoryEditorFrame> undoHistory,
    required List<_InventoryEditorFrame> redoHistory,
  }) : _undoHistory = List<_InventoryEditorFrame>.unmodifiable(undoHistory),
       _redoHistory = List<_InventoryEditorFrame>.unmodifiable(redoHistory);

  factory InventorySketchEditorSnapshot.recover(
    InventoryGeometry geometry, {
    InventorySketchEditorMode mode = InventorySketchEditorMode.draw,
  }) {
    final workingIndex =
        geometry.polylines.isNotEmpty &&
            geometry.polylines.last.isIncompleteDraft
        ? geometry.polylines.length - 1
        : null;
    return InventorySketchEditorSnapshot._(
      geometry: geometry,
      mode: mode,
      selection: null,
      workingPolylineIndex: workingIndex,
      undoHistory: const [],
      redoHistory: const [],
    );
  }

  static const maximumHistory = 100;
  static const selectionRadius = 24.0;

  final InventoryGeometry geometry;
  final InventorySketchEditorMode mode;
  final InventorySketchSelection? selection;
  final int? workingPolylineIndex;
  final List<_InventoryEditorFrame> _undoHistory;
  final List<_InventoryEditorFrame> _redoHistory;

  int get undoDepth => _undoHistory.length;
  int get redoDepth => _redoHistory.length;
  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;
  bool get hasWorkingPolyline => workingPolylineIndex != null;

  InventorySketchEditorSnapshot withMode(InventorySketchEditorMode value) =>
      InventorySketchEditorSnapshot._(
        geometry: geometry,
        mode: value,
        selection: value == InventorySketchEditorMode.select ? selection : null,
        workingPolylineIndex: workingPolylineIndex,
        undoHistory: _undoHistory,
        redoHistory: _redoHistory,
      );

  InventorySketchEditorSnapshot withSelection(
    InventorySketchSelection? value,
  ) => InventorySketchEditorSnapshot._(
    geometry: geometry,
    mode: mode,
    selection: value,
    workingPolylineIndex: workingPolylineIndex,
    undoHistory: _undoHistory,
    redoHistory: _redoHistory,
  );

  InventorySketchEditorSnapshot? drawPoint(InventorySketchPoint point) {
    if (mode != InventorySketchEditorMode.draw) return null;
    final polylines = geometry.polylines.toList(growable: true);
    final workingIndex = workingPolylineIndex;
    try {
      if (workingIndex == null) {
        polylines.add(InventoryPolyline(closed: false, points: [point]));
        return _recordGeometry(
          InventoryGeometry(polylines: polylines),
          polylines.length - 1,
        );
      }
      if (workingIndex != polylines.length - 1) return null;
      final working = polylines[workingIndex];
      if (working.closed || working.points.last == point) return null;
      if (working.points.length >= 3 && working.points.first == point) {
        polylines[workingIndex] = InventoryPolyline(
          closed: true,
          points: working.points,
        );
        return _recordGeometry(InventoryGeometry(polylines: polylines), null);
      }
      polylines[workingIndex] = InventoryPolyline(
        closed: false,
        points: [...working.points, point],
      );
      return _recordGeometry(
        InventoryGeometry(polylines: polylines),
        workingIndex,
      );
    } on InventoryGeometryFailure {
      return null;
    }
  }

  InventorySketchEditorSnapshot? finishWorkingPolyline() {
    final workingIndex = workingPolylineIndex;
    if (workingIndex == null || workingIndex >= geometry.polylines.length) {
      return null;
    }
    final working = geometry.polylines[workingIndex];
    if (working.closed) return null;
    if (working.points.length == 1) {
      final polylines = geometry.polylines.toList(growable: true)
        ..removeAt(workingIndex);
      return _recordGeometry(InventoryGeometry(polylines: polylines), null);
    }
    return _recordFrame(geometry, null);
  }

  InventorySketchEditorSnapshot selectAt(
    Offset viewPoint,
    InventoryViewport viewport,
  ) {
    if (mode != InventorySketchEditorMode.select) return this;
    var bestDistance = double.infinity;
    int? bestPolyline;
    int? bestSegment;
    for (
      var polylineIndex = 0;
      polylineIndex < geometry.polylines.length;
      polylineIndex += 1
    ) {
      final polyline = geometry.polylines[polylineIndex];
      for (
        var segmentIndex = 0;
        segmentIndex < polyline.segmentCount;
        segmentIndex += 1
      ) {
        final start = viewport.virtualToView(polyline.points[segmentIndex]);
        final endIndex = segmentIndex + 1 < polyline.points.length
            ? segmentIndex + 1
            : 0;
        final end = viewport.virtualToView(polyline.points[endIndex]);
        final distance = _distanceToSegment(viewPoint, start, end);
        if (distance <= selectionRadius && distance < bestDistance) {
          bestDistance = distance;
          bestPolyline = polylineIndex;
          bestSegment = segmentIndex;
        }
      }
    }
    if (bestPolyline == null || bestSegment == null) {
      return withSelection(null);
    }
    final current = selection;
    if (current != null &&
        current.wholePolyline &&
        current.polylineIndex == bestPolyline) {
      return this;
    }
    if (current != null &&
        current.polylineIndex == bestPolyline &&
        current.segmentIndex == bestSegment &&
        !current.wholePolyline) {
      return withSelection(
        InventorySketchSelection.polyline(polylineIndex: bestPolyline),
      );
    }
    return withSelection(
      InventorySketchSelection.segment(
        polylineIndex: bestPolyline,
        segmentIndex: bestSegment,
      ),
    );
  }

  InventorySketchEditorSnapshot? deleteSelection() {
    final current = selection;
    if (current == null ||
        current.polylineIndex < 0 ||
        current.polylineIndex >= geometry.polylines.length) {
      return null;
    }
    final polylines = geometry.polylines.toList(growable: true);
    final selected = polylines[current.polylineIndex];
    if (current.wholePolyline) {
      polylines.removeAt(current.polylineIndex);
      return _recordGeometry(
        InventoryGeometry(polylines: polylines),
        _workingIndexAfterRemoval(current.polylineIndex, 0),
      );
    }
    final segmentIndex = current.segmentIndex;
    if (segmentIndex == null ||
        segmentIndex < 0 ||
        segmentIndex >= selected.segmentCount) {
      return null;
    }
    final replacements = <InventoryPolyline>[];
    if (!selected.closed) {
      final prefix = selected.points.sublist(0, segmentIndex + 1);
      final suffix = selected.points.sublist(segmentIndex + 1);
      if (prefix.length >= 2) {
        replacements.add(InventoryPolyline(closed: false, points: prefix));
      }
      if (suffix.length >= 2) {
        replacements.add(InventoryPolyline(closed: false, points: suffix));
      }
    } else if (segmentIndex == selected.points.length - 1) {
      replacements.add(
        InventoryPolyline(closed: false, points: selected.points),
      );
    } else {
      final afterDeleted = selected.points.sublist(segmentIndex + 1);
      final throughDeletedStart = selected.points.sublist(0, segmentIndex + 1);
      replacements.add(
        InventoryPolyline(
          closed: false,
          points: [...afterDeleted, ...throughDeletedStart],
        ),
      );
    }
    polylines
      ..removeAt(current.polylineIndex)
      ..insertAll(current.polylineIndex, replacements);
    return _recordGeometry(
      InventoryGeometry(polylines: polylines),
      _workingIndexAfterRemoval(current.polylineIndex, replacements.length),
    );
  }

  InventorySketchEditorSnapshot undo() {
    if (_undoHistory.isEmpty) return this;
    final previous = _undoHistory.last;
    final redo = _boundedHistory([
      ..._redoHistory,
      _InventoryEditorFrame(geometry, workingPolylineIndex),
    ]);
    return InventorySketchEditorSnapshot._(
      geometry: previous.geometry,
      mode: mode,
      selection: null,
      workingPolylineIndex: previous.workingPolylineIndex,
      undoHistory: _undoHistory.sublist(0, _undoHistory.length - 1),
      redoHistory: redo,
    );
  }

  InventorySketchEditorSnapshot redo() {
    if (_redoHistory.isEmpty) return this;
    final next = _redoHistory.last;
    final undo = _boundedHistory([
      ..._undoHistory,
      _InventoryEditorFrame(geometry, workingPolylineIndex),
    ]);
    return InventorySketchEditorSnapshot._(
      geometry: next.geometry,
      mode: mode,
      selection: null,
      workingPolylineIndex: next.workingPolylineIndex,
      undoHistory: undo,
      redoHistory: _redoHistory.sublist(0, _redoHistory.length - 1),
    );
  }

  InventorySketchEditorSnapshot _recordGeometry(
    InventoryGeometry value,
    int? nextWorkingIndex,
  ) => _recordFrame(value, nextWorkingIndex);

  InventorySketchEditorSnapshot _recordFrame(
    InventoryGeometry value,
    int? nextWorkingIndex,
  ) => InventorySketchEditorSnapshot._(
    geometry: value,
    mode: mode,
    selection: null,
    workingPolylineIndex: nextWorkingIndex,
    undoHistory: _boundedHistory([
      ..._undoHistory,
      _InventoryEditorFrame(geometry, workingPolylineIndex),
    ]),
    redoHistory: const [],
  );

  int? _workingIndexAfterRemoval(int removedIndex, int replacementCount) {
    final current = workingPolylineIndex;
    if (current == null) return null;
    if (current == removedIndex) return null;
    if (current < removedIndex) return current;
    return current - 1 + replacementCount;
  }

  static List<_InventoryEditorFrame> _boundedHistory(
    List<_InventoryEditorFrame> values,
  ) => values.length <= maximumHistory
      ? values
      : values.sublist(values.length - maximumHistory);
}

class InventoryViewport {
  const InventoryViewport._({
    required this.viewSize,
    required this.zoom,
    required this.pan,
  });

  factory InventoryViewport.fit(Size viewSize) {
    if (viewSize.width <= 0 || viewSize.height <= 0) {
      return const InventoryViewport._(
        viewSize: Size(1, 1),
        zoom: 1,
        pan: Offset.zero,
      );
    }
    return InventoryViewport._(viewSize: viewSize, zoom: 1, pan: Offset.zero);
  }

  static const minimumZoom = 0.5;
  static const maximumZoom = 4.0;
  static const minimumVisibleFraction = 0.15;

  final Size viewSize;
  final double zoom;
  final Offset pan;

  double get fitScale => math.min(
    viewSize.width / InventoryGeometryContract.canvasWidth,
    viewSize.height / InventoryGeometryContract.canvasHeight,
  );

  double get scale => fitScale * zoom;

  Size get canvasViewSize => Size(
    InventoryGeometryContract.canvasWidth * scale,
    InventoryGeometryContract.canvasHeight * scale,
  );

  Offset get origin => Offset(
    (viewSize.width - canvasViewSize.width) / 2 + pan.dx,
    (viewSize.height - canvasViewSize.height) / 2 + pan.dy,
  );

  Offset virtualToView(InventorySketchPoint point) =>
      origin + Offset(point.x * scale, point.y * scale);

  Offset viewToVirtual(Offset point) =>
      Offset((point.dx - origin.dx) / scale, (point.dy - origin.dy) / scale);

  InventorySketchPoint? snapViewPoint(Offset point) {
    final virtual = viewToVirtual(point);
    if (virtual.dx < 0 ||
        virtual.dx > InventoryGeometryContract.canvasWidth ||
        virtual.dy < 0 ||
        virtual.dy > InventoryGeometryContract.canvasHeight) {
      return null;
    }
    return InventorySketchPoint(
      x: _snapDouble(
        virtual.dx,
        maximum: InventoryGeometryContract.canvasWidth,
      ),
      y: _snapDouble(
        virtual.dy,
        maximum: InventoryGeometryContract.canvasHeight,
      ),
    );
  }

  InventoryViewport zoomAt(double value, Offset anchor) {
    final bounded = value.clamp(minimumZoom, maximumZoom).toDouble();
    final virtualAnchor = viewToVirtual(anchor);
    final nextScale = fitScale * bounded;
    final nextCanvas = Size(
      InventoryGeometryContract.canvasWidth * nextScale,
      InventoryGeometryContract.canvasHeight * nextScale,
    );
    final centered = Offset(
      (viewSize.width - nextCanvas.width) / 2,
      (viewSize.height - nextCanvas.height) / 2,
    );
    final desiredOrigin =
        anchor -
        Offset(virtualAnchor.dx * nextScale, virtualAnchor.dy * nextScale);
    return InventoryViewport._(
      viewSize: viewSize,
      zoom: bounded,
      pan: desiredOrigin - centered,
    )._constrained();
  }

  InventoryViewport panBy(Offset delta) => InventoryViewport._(
    viewSize: viewSize,
    zoom: zoom,
    pan: pan + delta,
  )._constrained();

  InventoryViewport reset() => InventoryViewport.fit(viewSize);

  InventoryViewport _constrained() {
    final size = canvasViewSize;
    final rawOrigin = origin;
    final minimumX = -(size.width * (1 - minimumVisibleFraction));
    final maximumX = viewSize.width - size.width * minimumVisibleFraction;
    final minimumY = -(size.height * (1 - minimumVisibleFraction));
    final maximumY = viewSize.height - size.height * minimumVisibleFraction;
    final constrainedOrigin = Offset(
      rawOrigin.dx.clamp(minimumX, maximumX).toDouble(),
      rawOrigin.dy.clamp(minimumY, maximumY).toDouble(),
    );
    final centered = Offset(
      (viewSize.width - size.width) / 2,
      (viewSize.height - size.height) / 2,
    );
    return InventoryViewport._(
      viewSize: viewSize,
      zoom: zoom,
      pan: constrainedOrigin - centered,
    );
  }

  static int _snapDouble(double value, {required int maximum}) {
    const step = InventoryGeometryContract.sketchGridStep;
    final lower = (value / step).floor() * step;
    final result = value - lower <= step / 2 ? lower : lower + step;
    return result.clamp(0, maximum).toInt();
  }
}

class InventorySketchCanvas extends StatefulWidget {
  const InventorySketchCanvas({
    required this.snapshot,
    required this.onDrawPoint,
    required this.onSelect,
    super.key,
  });

  final InventorySketchEditorSnapshot snapshot;
  final ValueChanged<InventorySketchPoint> onDrawPoint;
  final void Function(Offset viewPoint, InventoryViewport viewport) onSelect;

  @override
  State<InventorySketchCanvas> createState() => InventorySketchCanvasState();
}

class InventorySketchCanvasState extends State<InventorySketchCanvas> {
  InventoryViewport? _viewport;
  InventoryViewport? _gestureStartViewport;
  Offset _gestureStartFocal = Offset.zero;
  Offset _lastFocal = Offset.zero;
  bool _multiTouchGesture = false;

  InventoryViewport? get viewport => _viewport;

  void zoomIn() => _changeZoom(1.25);
  void zoomOut() => _changeZoom(0.8);

  void fitCanvas() {
    final current = _viewport;
    if (current == null) return;
    setState(() => _viewport = current.reset());
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
    switch (widget.snapshot.mode) {
      case InventorySketchEditorMode.draw:
        final point = current.snapViewPoint(details.localPosition);
        if (point != null) widget.onDrawPoint(point);
        break;
      case InventorySketchEditorMode.select:
        widget.onSelect(details.localPosition, current);
        break;
      case InventorySketchEditorMode.pan:
        break;
    }
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
    final current = _viewport;
    final start = _gestureStartViewport;
    if (current == null || start == null) return;
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
    if (widget.snapshot.mode == InventorySketchEditorMode.pan) {
      final delta = details.localFocalPoint - _lastFocal;
      setState(() => _viewport = current.panBy(delta));
      _lastFocal = details.localFocalPoint;
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _gestureStartViewport = null;
    _multiTouchGesture = false;
  }

  @override
  Widget build(BuildContext context) {
    final selectionLabel = widget.snapshot.selection?.semanticLabel;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_viewport == null || _viewport!.viewSize != size) {
          _viewport = InventoryViewport.fit(size);
        }
        final current = _viewport!;
        return Semantics(
          container: true,
          label: selectionLabel == null
              ? 'Şematik kroki çizim alanı'
              : 'Şematik kroki çizim alanı, $selectionLabel',
          child: ClipRect(
            child: GestureDetector(
              key: const Key('inventory-sketch-canvas-gesture'),
              behavior: HitTestBehavior.opaque,
              onTapUp: _handleTap,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: CustomPaint(
                key: const Key('inventory-sketch-canvas-paint'),
                painter: _InventorySketchPainter(
                  geometry: widget.snapshot.geometry,
                  selection: widget.snapshot.selection,
                  workingPolylineIndex: widget.snapshot.workingPolylineIndex,
                  viewport: current,
                  colorScheme: Theme.of(context).colorScheme,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InventorySketchPainter extends CustomPainter {
  const _InventorySketchPainter({
    required this.geometry,
    required this.selection,
    required this.workingPolylineIndex,
    required this.viewport,
    required this.colorScheme,
  });

  final InventoryGeometry geometry;
  final InventorySketchSelection? selection;
  final int? workingPolylineIndex;
  final InventoryViewport viewport;
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
        final point = viewport.virtualToView(InventorySketchPoint(x: x, y: y));
        canvas.drawCircle(point, 1.2, gridPaint);
      }
    }
    for (
      var polylineIndex = 0;
      polylineIndex < geometry.polylines.length;
      polylineIndex += 1
    ) {
      final polyline = geometry.polylines[polylineIndex];
      final path = Path();
      final first = viewport.virtualToView(polyline.points.first);
      path.moveTo(first.dx, first.dy);
      for (
        var pointIndex = 1;
        pointIndex < polyline.points.length;
        pointIndex++
      ) {
        final point = viewport.virtualToView(polyline.points[pointIndex]);
        path.lineTo(point.dx, point.dy);
      }
      if (polyline.closed) path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = colorScheme.onSurface
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      if (selection?.polylineIndex == polylineIndex) {
        final selectedPaint = Paint()
          ..color = colorScheme.primary
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.square
          ..style = PaintingStyle.stroke;
        if (selection!.wholePolyline) {
          canvas.drawPath(path, selectedPaint);
          for (final point in polyline.points) {
            canvas.drawCircle(
              viewport.virtualToView(point),
              5,
              Paint()
                ..color = colorScheme.primaryContainer
                ..style = PaintingStyle.fill,
            );
          }
        } else {
          final segmentIndex = selection!.segmentIndex!;
          final start = viewport.virtualToView(polyline.points[segmentIndex]);
          final endIndex = segmentIndex + 1 < polyline.points.length
              ? segmentIndex + 1
              : 0;
          final end = viewport.virtualToView(polyline.points[endIndex]);
          canvas.drawLine(start, end, selectedPaint);
          canvas.drawCircle(start, 6, selectedPaint);
          canvas.drawCircle(end, 6, selectedPaint);
        }
      }
      if (workingPolylineIndex == polylineIndex) {
        canvas.drawCircle(
          viewport.virtualToView(polyline.points.last),
          7,
          Paint()
            ..color = colorScheme.tertiary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
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
  bool shouldRepaint(_InventorySketchPainter oldDelegate) =>
      oldDelegate.geometry.canonicalJson != geometry.canonicalJson ||
      oldDelegate.selection != selection ||
      oldDelegate.workingPolylineIndex != workingPolylineIndex ||
      oldDelegate.viewport.zoom != viewport.zoom ||
      oldDelegate.viewport.pan != viewport.pan ||
      oldDelegate.viewport.viewSize != viewport.viewSize ||
      oldDelegate.colorScheme != colorScheme;
}

class _InventoryEditorFrame {
  const _InventoryEditorFrame(this.geometry, this.workingPolylineIndex);

  final InventoryGeometry geometry;
  final int? workingPolylineIndex;
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final segment = end - start;
  final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
  if (lengthSquared == 0) return (point - start).distance;
  final fromStart = point - start;
  final projection =
      (fromStart.dx * segment.dx + fromStart.dy * segment.dy) / lengthSquared;
  final bounded = projection.clamp(0.0, 1.0).toDouble();
  final closest = start + segment * bounded;
  return (point - closest).distance;
}
