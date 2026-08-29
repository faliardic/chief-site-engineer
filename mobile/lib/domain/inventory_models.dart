import 'dart:convert';

import 'package:crypto/crypto.dart' as hashes;

class InventoryGeometryFailure implements Exception {
  const InventoryGeometryFailure([this.reason = 'inventory_geometry_corrupt']);

  static const safeCode = 'inventory_geometry_corrupt';

  final String reason;
  String get code => safeCode;

  @override
  String toString() => '$safeCode: $reason';
}

abstract final class InventoryGeometryContract {
  static const geometryVersion = 1;
  static const canvasWidth = 4096;
  static const canvasHeight = 3072;
  static const sketchGridStep = 64;
  static const placementStep = 4;
  static const maximumPolylines = 64;
  static const maximumPointsPerPolyline = 1024;
  static const maximumTotalPoints = 4096;
  static const maximumTotalSegments = 4096;

  static int snapSketchCoordinate(int value, {required int maximum}) =>
      _snapCoordinate(value, step: sketchGridStep, maximum: maximum);

  static int snapPlacementCoordinate(int value, {required int maximum}) =>
      _snapCoordinate(value, step: placementStep, maximum: maximum);

  static void validatePlacementCoordinate(int value, {required int maximum}) {
    _validateCoordinate(value, step: placementStep, maximum: maximum);
  }

  static int _snapCoordinate(
    int value, {
    required int step,
    required int maximum,
  }) {
    if (maximum < 0 || maximum % step != 0 || value < 0 || value > maximum) {
      throw const InventoryGeometryFailure('coordinate_out_of_bounds');
    }
    final lower = value - (value % step);
    final remainder = value - lower;
    if (remainder * 2 <= step) {
      return lower;
    }
    return lower + step;
  }

  static void _validateCoordinate(
    int value, {
    required int step,
    required int maximum,
  }) {
    if (value < 0 || value > maximum) {
      throw const InventoryGeometryFailure('coordinate_out_of_bounds');
    }
    if (value % step != 0) {
      throw const InventoryGeometryFailure('coordinate_not_quantized');
    }
  }
}

class InventorySketchPoint {
  InventorySketchPoint({required this.x, required this.y}) {
    InventoryGeometryContract._validateCoordinate(
      x,
      step: InventoryGeometryContract.sketchGridStep,
      maximum: InventoryGeometryContract.canvasWidth,
    );
    InventoryGeometryContract._validateCoordinate(
      y,
      step: InventoryGeometryContract.sketchGridStep,
      maximum: InventoryGeometryContract.canvasHeight,
    );
  }

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is InventorySketchPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class InventoryPlacementCoordinates {
  const InventoryPlacementCoordinates({required this.x, required this.y});

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is InventoryPlacementCoordinates && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class InventoryPolyline {
  InventoryPolyline({
    required this.closed,
    required Iterable<InventorySketchPoint> points,
  }) : points = List<InventorySketchPoint>.unmodifiable(points) {
    _validate();
  }

  final bool closed;
  final List<InventorySketchPoint> points;

  int get segmentCount => closed ? points.length : points.length - 1;

  bool get isIncompleteDraft => !closed && points.length == 1;

  void _validate() {
    if (points.isEmpty) {
      throw const InventoryGeometryFailure('polyline_points_empty');
    }
    if (points.length > InventoryGeometryContract.maximumPointsPerPolyline) {
      throw const InventoryGeometryFailure('polyline_point_limit_exceeded');
    }
    if (closed && points.length < 3) {
      throw const InventoryGeometryFailure('closed_polyline_too_short');
    }
    if (closed && points.toSet().length < 3) {
      throw const InventoryGeometryFailure(
        'closed_polyline_distinct_points_too_few',
      );
    }
    for (var index = 1; index < points.length; index += 1) {
      if (points[index] == points[index - 1]) {
        throw const InventoryGeometryFailure('zero_length_segment');
      }
    }
    if (closed && points.first == points.last) {
      throw const InventoryGeometryFailure('repeated_closing_point');
    }
  }
}

class InventoryGeometry {
  InventoryGeometry({required Iterable<InventoryPolyline> polylines})
    : polylines = List<InventoryPolyline>.unmodifiable(polylines) {
    _validateDraftGeometry();
  }

  factory InventoryGeometry.emptyDraft() =>
      InventoryGeometry(polylines: const []);

  factory InventoryGeometry.decode(String value, {String? expectedSha256}) {
    try {
      if (expectedSha256 != null && !_isLowercaseSha256(expectedSha256)) {
        throw const InventoryGeometryFailure('checksum_invalid');
      }
      final decoded = jsonDecode(value);
      final root = _exactStringMap(decoded, const {
        'canvas_height',
        'canvas_width',
        'geometry_version',
        'polylines',
      });
      if (root['canvas_height'] != InventoryGeometryContract.canvasHeight ||
          root['canvas_width'] != InventoryGeometryContract.canvasWidth) {
        throw const InventoryGeometryFailure('canvas_mismatch');
      }
      if (root['geometry_version'] !=
          InventoryGeometryContract.geometryVersion) {
        throw const InventoryGeometryFailure('geometry_version_unsupported');
      }
      final rawPolylines = root['polylines'];
      if (rawPolylines is! List) {
        throw const InventoryGeometryFailure('polylines_invalid');
      }
      final geometry = InventoryGeometry(
        polylines: rawPolylines.map((rawPolyline) {
          final polyline = _exactStringMap(rawPolyline, const {
            'closed',
            'points',
          });
          final closed = polyline['closed'];
          final rawPoints = polyline['points'];
          if (closed is! bool || rawPoints is! List) {
            throw const InventoryGeometryFailure('polyline_invalid');
          }
          return InventoryPolyline(
            closed: closed,
            points: rawPoints.map((rawPoint) {
              if (rawPoint is! List || rawPoint.length != 2) {
                throw const InventoryGeometryFailure('point_invalid');
              }
              final x = rawPoint[0];
              final y = rawPoint[1];
              if (x is! int || y is! int) {
                throw const InventoryGeometryFailure('point_invalid');
              }
              return InventorySketchPoint(x: x, y: y);
            }),
          );
        }),
      );
      if (expectedSha256 != null && geometry.sha256 != expectedSha256) {
        throw const InventoryGeometryFailure('checksum_mismatch');
      }
      return geometry;
    } on InventoryGeometryFailure {
      rethrow;
    } on Object {
      throw const InventoryGeometryFailure('malformed_geometry_json');
    }
  }

  final List<InventoryPolyline> polylines;

  int get pointCount =>
      polylines.fold(0, (total, polyline) => total + polyline.points.length);

  int get segmentCount =>
      polylines.fold(0, (total, polyline) => total + polyline.segmentCount);

  String get canonicalJson {
    final buffer = StringBuffer(
      '{"canvas_height":${InventoryGeometryContract.canvasHeight},'
      '"canvas_width":${InventoryGeometryContract.canvasWidth},'
      '"geometry_version":${InventoryGeometryContract.geometryVersion},'
      '"polylines":[',
    );
    for (
      var polylineIndex = 0;
      polylineIndex < polylines.length;
      polylineIndex += 1
    ) {
      if (polylineIndex > 0) {
        buffer.write(',');
      }
      final polyline = polylines[polylineIndex];
      buffer.write('{"closed":${polyline.closed},"points":[');
      for (
        var pointIndex = 0;
        pointIndex < polyline.points.length;
        pointIndex += 1
      ) {
        if (pointIndex > 0) {
          buffer.write(',');
        }
        final point = polyline.points[pointIndex];
        buffer.write('[${point.x},${point.y}]');
      }
      buffer.write(']}');
    }
    buffer.write(']}');
    return buffer.toString();
  }

  String get sha256 =>
      hashes.sha256.convert(utf8.encode(canonicalJson)).toString();

  void validateFinalizable() {
    if (polylines.isEmpty || polylines.any((item) => item.isIncompleteDraft)) {
      throw const InventoryGeometryFailure('geometry_not_finalizable');
    }
    if (segmentCount < 1) {
      throw const InventoryGeometryFailure('geometry_not_finalizable');
    }
  }

  void _validateDraftGeometry() {
    if (polylines.length > InventoryGeometryContract.maximumPolylines) {
      throw const InventoryGeometryFailure('polyline_limit_exceeded');
    }
    final incomplete = polylines.where((item) => item.isIncompleteDraft).length;
    if (incomplete > 1 ||
        (incomplete == 1 && !polylines.last.isIncompleteDraft)) {
      throw const InventoryGeometryFailure('incomplete_draft_invalid');
    }
    if (pointCount > InventoryGeometryContract.maximumTotalPoints) {
      throw const InventoryGeometryFailure('total_point_limit_exceeded');
    }
    if (segmentCount > InventoryGeometryContract.maximumTotalSegments) {
      throw const InventoryGeometryFailure('total_segment_limit_exceeded');
    }
  }
}

abstract final class InventorySpatialContract {
  static const maximumBlockNameLength = 80;
  static const maximumBlockOrdinal = 1000000;
  static const maximumFloorNameLength = 80;
  static const maximumFloorCount = 100;

  static String normalizeBlockName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.length > maximumBlockNameLength) {
      throw const InventoryFailure('inventory_block_name_invalid');
    }
    return normalized;
  }

  static String normalizeFloorName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.length > maximumFloorNameLength) {
      throw const InventoryFailure('inventory_floor_name_invalid');
    }
    return normalized;
  }

  static void validateFloorCount(int value) {
    if (value < 1 || value > maximumFloorCount) {
      throw const InventoryFailure('inventory_floor_count_invalid');
    }
  }

  static void validateBlockPolygon(InventoryPolyline polygon) {
    if (!polygon.closed || polygon.points.length < 3) {
      throw const InventoryFailure('inventory_block_polygon_not_closed');
    }
    if (_twiceSignedArea(polygon.points) == 0) {
      throw const InventoryFailure('inventory_block_polygon_zero_area');
    }
    final points = polygon.points;
    for (var first = 0; first < points.length; first += 1) {
      final firstNext = (first + 1) % points.length;
      for (var second = first + 1; second < points.length; second += 1) {
        final secondNext = (second + 1) % points.length;
        if (first == second ||
            firstNext == second ||
            secondNext == first ||
            (first == 0 && secondNext == 0)) {
          continue;
        }
        if (_segmentsIntersect(
          points[first],
          points[firstNext],
          points[second],
          points[secondNext],
        )) {
          throw const InventoryFailure(
            'inventory_block_polygon_self_intersects',
          );
        }
      }
    }
  }

  static void validateNonOverlappingPolygons(
    Iterable<InventoryPolyline> polygons,
  ) {
    final values = List<InventoryPolyline>.of(polygons);
    for (final polygon in values) {
      validateBlockPolygon(polygon);
    }
    for (var first = 0; first < values.length; first += 1) {
      for (var second = first + 1; second < values.length; second += 1) {
        if (_polygonsConflict(values[first], values[second])) {
          throw const InventoryFailure('inventory_block_polygon_ambiguous');
        }
      }
    }
  }

  static bool containsPlacement(
    InventoryPolyline polygon, {
    required int x,
    required int y,
  }) {
    InventoryGeometryContract.validatePlacementCoordinate(
      x,
      maximum: InventoryGeometryContract.canvasWidth,
    );
    InventoryGeometryContract.validatePlacementCoordinate(
      y,
      maximum: InventoryGeometryContract.canvasHeight,
    );
    validateBlockPolygon(polygon);
    return _containsPoint(polygon.points, x, y);
  }

  static bool strictlyContainsPlacement(
    InventoryPolyline polygon, {
    required int x,
    required int y,
  }) {
    InventoryGeometryContract.validatePlacementCoordinate(
      x,
      maximum: InventoryGeometryContract.canvasWidth,
    );
    InventoryGeometryContract.validatePlacementCoordinate(
      y,
      maximum: InventoryGeometryContract.canvasHeight,
    );
    validateBlockPolygon(polygon);
    return _strictlyContainsPoint(polygon.points, x, y);
  }

  static bool _strictlyContainsPoint(
    List<InventorySketchPoint> points,
    int x,
    int y,
  ) {
    for (var index = 0; index < points.length; index += 1) {
      if (_pointOnSegment(
        points[index],
        points[(index + 1) % points.length],
        x,
        y,
      )) {
        return false;
      }
    }
    return _containsPoint(points, x, y);
  }

  static InventoryPlacementCoordinates safeInteriorPlacement(
    InventoryPolyline polygon, {
    required int spreadIndex,
    Iterable<InventoryPlacementCoordinates> occupied = const [],
  }) {
    if (spreadIndex < 0) {
      throw const InventoryFailure('inventory_safe_interior_unavailable');
    }
    validateBlockPolygon(polygon);
    final points = polygon.points;
    final area = _twiceSignedArea(points);
    var centroidXNumerator = 0;
    var centroidYNumerator = 0;
    var minimumX = InventoryGeometryContract.canvasWidth;
    var maximumX = 0;
    var minimumY = InventoryGeometryContract.canvasHeight;
    var maximumY = 0;
    for (var index = 0; index < points.length; index += 1) {
      final point = points[index];
      final next = points[(index + 1) % points.length];
      final cross = point.x * next.y - next.x * point.y;
      centroidXNumerator += (point.x + next.x) * cross;
      centroidYNumerator += (point.y + next.y) * cross;
      if (point.x < minimumX) minimumX = point.x;
      if (point.x > maximumX) maximumX = point.x;
      if (point.y < minimumY) minimumY = point.y;
      if (point.y > maximumY) maximumY = point.y;
    }
    final anchorX = InventoryGeometryContract.snapPlacementCoordinate(
      (centroidXNumerator / (3 * area)).round(),
      maximum: InventoryGeometryContract.canvasWidth,
    );
    final anchorY = InventoryGeometryContract.snapPlacementCoordinate(
      (centroidYNumerator / (3 * area)).round(),
      maximum: InventoryGeometryContract.canvasHeight,
    );
    const step = InventoryGeometryContract.placementStep;
    final maximumRing =
        [
              (anchorX - minimumX).abs(),
              (maximumX - anchorX).abs(),
              (anchorY - minimumY).abs(),
              (maximumY - anchorY).abs(),
            ].reduce((left, right) => left > right ? left : right) ~/
            step +
        1;
    final occupiedTargets = occupied.toSet();

    InventoryPlacementCoordinates? candidate(int x, int y) {
      if (x < minimumX ||
          x > maximumX ||
          y < minimumY ||
          y > maximumY ||
          x < 0 ||
          x > InventoryGeometryContract.canvasWidth ||
          y < 0 ||
          y > InventoryGeometryContract.canvasHeight ||
          !_strictlyContainsPoint(points, x, y)) {
        return null;
      }
      return InventoryPlacementCoordinates(x: x, y: y);
    }

    Iterable<InventoryPlacementCoordinates> candidates() sync* {
      for (var ring = 0; ring <= maximumRing; ring += 1) {
        if (ring == 0) {
          final target = candidate(anchorX, anchorY);
          if (target != null) yield target;
          continue;
        }
        final delta = ring * step;
        final left = anchorX - delta;
        final right = anchorX + delta;
        final top = anchorY - delta;
        final bottom = anchorY + delta;
        for (var x = left; x <= right; x += step) {
          final target = candidate(x, top);
          if (target != null) yield target;
        }
        for (var y = top + step; y <= bottom; y += step) {
          final target = candidate(right, y);
          if (target != null) yield target;
        }
        for (var x = right - step; x >= left; x -= step) {
          final target = candidate(x, bottom);
          if (target != null) yield target;
        }
        for (var y = bottom - step; y > top; y -= step) {
          final target = candidate(left, y);
          if (target != null) yield target;
        }
      }
    }

    var skipped = 0;
    for (final target in candidates()) {
      if (skipped < spreadIndex) {
        skipped += 1;
        continue;
      }
      if (!occupiedTargets.contains(target)) return target;
    }
    var wrapped = 0;
    for (final target in candidates()) {
      if (wrapped >= spreadIndex) break;
      wrapped += 1;
      if (!occupiedTargets.contains(target)) return target;
    }
    throw const InventoryFailure('inventory_safe_interior_unavailable');
  }

  static int _twiceSignedArea(List<InventorySketchPoint> points) {
    var result = 0;
    for (var index = 0; index < points.length; index += 1) {
      final next = points[(index + 1) % points.length];
      result += points[index].x * next.y - next.x * points[index].y;
    }
    return result;
  }

  static bool _polygonsConflict(
    InventoryPolyline first,
    InventoryPolyline second,
  ) {
    for (
      var firstIndex = 0;
      firstIndex < first.points.length;
      firstIndex += 1
    ) {
      final firstNext = (firstIndex + 1) % first.points.length;
      for (
        var secondIndex = 0;
        secondIndex < second.points.length;
        secondIndex += 1
      ) {
        final secondNext = (secondIndex + 1) % second.points.length;
        if (_segmentsIntersect(
          first.points[firstIndex],
          first.points[firstNext],
          second.points[secondIndex],
          second.points[secondNext],
        )) {
          return true;
        }
      }
    }
    final firstPoint = first.points.first;
    final secondPoint = second.points.first;
    return _containsPoint(second.points, firstPoint.x, firstPoint.y) ||
        _containsPoint(first.points, secondPoint.x, secondPoint.y);
  }

  static bool _containsPoint(
    List<InventorySketchPoint> polygon,
    int pointX,
    int pointY,
  ) {
    var inside = false;
    for (
      var current = 0, previous = polygon.length - 1;
      current < polygon.length;
      previous = current, current += 1
    ) {
      final start = polygon[previous];
      final end = polygon[current];
      if (_pointOnSegment(start, end, pointX, pointY)) return true;
      final crosses = (start.y > pointY) != (end.y > pointY);
      if (crosses) {
        final intersectionX =
            (end.x - start.x) * (pointY - start.y) / (end.y - start.y) +
            start.x;
        if (pointX < intersectionX) inside = !inside;
      }
    }
    return inside;
  }

  static bool _segmentsIntersect(
    InventorySketchPoint firstStart,
    InventorySketchPoint firstEnd,
    InventorySketchPoint secondStart,
    InventorySketchPoint secondEnd,
  ) {
    final firstOrientation = _orientation(
      firstStart,
      firstEnd,
      secondStart.x,
      secondStart.y,
    );
    final secondOrientation = _orientation(
      firstStart,
      firstEnd,
      secondEnd.x,
      secondEnd.y,
    );
    final thirdOrientation = _orientation(
      secondStart,
      secondEnd,
      firstStart.x,
      firstStart.y,
    );
    final fourthOrientation = _orientation(
      secondStart,
      secondEnd,
      firstEnd.x,
      firstEnd.y,
    );
    if (firstOrientation == 0 &&
        _pointOnSegment(firstStart, firstEnd, secondStart.x, secondStart.y)) {
      return true;
    }
    if (secondOrientation == 0 &&
        _pointOnSegment(firstStart, firstEnd, secondEnd.x, secondEnd.y)) {
      return true;
    }
    if (thirdOrientation == 0 &&
        _pointOnSegment(secondStart, secondEnd, firstStart.x, firstStart.y)) {
      return true;
    }
    if (fourthOrientation == 0 &&
        _pointOnSegment(secondStart, secondEnd, firstEnd.x, firstEnd.y)) {
      return true;
    }
    return (firstOrientation > 0) != (secondOrientation > 0) &&
        (thirdOrientation > 0) != (fourthOrientation > 0);
  }

  static int _orientation(
    InventorySketchPoint start,
    InventorySketchPoint end,
    int pointX,
    int pointY,
  ) =>
      (end.x - start.x) * (pointY - start.y) -
      (end.y - start.y) * (pointX - start.x);

  static bool _pointOnSegment(
    InventorySketchPoint start,
    InventorySketchPoint end,
    int pointX,
    int pointY,
  ) =>
      _orientation(start, end, pointX, pointY) == 0 &&
      pointX >= (start.x < end.x ? start.x : end.x) &&
      pointX <= (start.x > end.x ? start.x : end.x) &&
      pointY >= (start.y < end.y ? start.y : end.y) &&
      pointY <= (start.y > end.y ? start.y : end.y);
}

Map<String, Object?> _exactStringMap(Object? value, Set<String> expectedKeys) {
  if (value is! Map || value.length != expectedKeys.length) {
    throw const InventoryGeometryFailure('geometry_keys_invalid');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String || !expectedKeys.contains(key)) {
      throw const InventoryGeometryFailure('geometry_keys_invalid');
    }
    result[key] = entry.value;
  }
  if (result.length != expectedKeys.length ||
      expectedKeys.any((key) => !result.containsKey(key))) {
    throw const InventoryGeometryFailure('geometry_keys_invalid');
  }
  return result;
}

bool _isLowercaseSha256(String value) =>
    RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

// Slice 1B typed application records are defined below.

class InventoryFailure implements Exception {
  const InventoryFailure(this.code);

  final String code;

  @override
  String toString() => 'InventoryFailure: $code';
}

enum InventoryCommandType {
  sketchCreate('sketch_create'),
  sketchDraftAutosave('sketch_draft_autosave'),
  sketchEditStart('sketch_edit_start'),
  sketchFinalize('sketch_finalize'),
  sketchDraftAbandon('sketch_draft_abandon'),
  sketchArchive('sketch_archive'),
  sketchUnarchive('sketch_unarchive'),
  assetCreateWithPlacement('asset_create_with_placement'),
  assetUpdate('asset_update'),
  assetStatusChange('asset_status_change'),
  assetQuantityChange('asset_quantity_change'),
  assetArchive('asset_archive'),
  assetUnarchiveWithPlacement('asset_unarchive_with_placement'),
  placementMove('placement_move'),
  photoLink('photo_link'),
  photoArchive('photo_archive'),
  photoRestore('photo_restore');

  const InventoryCommandType(this.storageValue);
  final String storageValue;

  static InventoryCommandType fromStorage(Object? value) {
    for (final item in values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_receipt_corrupt');
  }
}

enum InventoryAggregateType {
  sketch('sketch'),
  asset('asset'),
  placement('placement'),
  attachmentLink('attachment_link');

  const InventoryAggregateType(this.storageValue);
  final String storageValue;

  static InventoryAggregateType fromStorage(Object? value) {
    for (final item in values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_history_integrity_failed');
  }
}

enum InventorySketchRevisionState {
  draft('DRAFT'),
  active('ACTIVE'),
  superseded('SUPERSEDED'),
  abandoned('ABANDONED');

  const InventorySketchRevisionState(this.storageValue);
  final String storageValue;

  static InventorySketchRevisionState fromStorage(Object? value) {
    for (final item in values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_projection_integrity_failed');
  }
}

enum InventoryBlockState {
  active('ACTIVE'),
  detached('DETACHED'),
  archived('ARCHIVED');

  const InventoryBlockState(this.storageValue);
  final String storageValue;

  static InventoryBlockState fromStorage(Object? value) {
    for (final item in values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_projection_integrity_failed');
  }
}

enum InventoryCategory {
  equipment('EQUIPMENT'),
  powerTool('POWER_TOOL'),
  handTool('HAND_TOOL'),
  measurementDevice('MEASUREMENT_DEVICE'),
  safetyEquipment('SAFETY_EQUIPMENT'),
  temporaryWorks('TEMPORARY_WORKS'),
  siteFacility('SITE_FACILITY'),
  other('OTHER');

  const InventoryCategory(this.storageValue);
  final String storageValue;

  static InventoryCategory fromStorage(Object? value) {
    for (final item in values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_projection_integrity_failed');
  }
}

enum InventoryAssetStatus {
  available('AVAILABLE'),
  inUse('IN_USE'),
  outOfService('OUT_OF_SERVICE'),
  missing('MISSING');

  const InventoryAssetStatus(this.storageValue);
  final String storageValue;

  static InventoryAssetStatus fromStorage(Object? value) {
    for (final item in values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_projection_integrity_failed');
  }
}

enum InventoryPlacementEndReason {
  moved('MOVED'),
  quantityChanged('QUANTITY_CHANGED'),
  assetArchived('ASSET_ARCHIVED');

  const InventoryPlacementEndReason(this.storageValue);
  final String storageValue;

  static InventoryPlacementEndReason? fromStorage(Object? value) {
    if (value == null) return null;
    for (final item in values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_projection_integrity_failed');
  }
}

enum InventoryEventType {
  sketchCreated('inventory.sketch_created'),
  sketchDraftAutosaved('inventory.sketch_draft_autosaved'),
  sketchEditStarted('inventory.sketch_edit_started'),
  sketchFinalized('inventory.sketch_finalized'),
  sketchDraftAbandoned('inventory.sketch_draft_abandoned'),
  sketchArchived('inventory.sketch_archived'),
  sketchUnarchived('inventory.sketch_unarchived'),
  assetCreated('inventory.asset_created'),
  assetUpdated('inventory.asset_updated'),
  assetStatusChanged('inventory.asset_status_changed'),
  assetArchived('inventory.asset_archived'),
  assetUnarchived('inventory.asset_unarchived'),
  placementCreated('inventory.placement_created'),
  placementMoved('inventory.placement_moved'),
  placementQuantityChanged('inventory.placement_quantity_changed'),
  placementRetired('inventory.placement_retired'),
  photoLinked('inventory.photo_linked'),
  photoArchived('inventory.photo_archived'),
  photoRestored('inventory.photo_restored');

  const InventoryEventType(this.storageValue);
  final String storageValue;

  static InventoryEventType fromStorage(Object? value) {
    for (final item in values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_history_integrity_failed');
  }
}

abstract interface class InventoryMutationCommand {
  String get operationId;
  String get projectId;
  String get primaryAggregateId;
  InventoryAggregateType get primaryAggregateType;
  InventoryCommandType get commandType;
}

class CreateInventorySketchCommand implements InventoryMutationCommand {
  const CreateInventorySketchCommand({
    required this.operationId,
    required this.projectId,
    required this.sketchId,
    required this.draftRevisionId,
    this.displayName = 'Saha krokisi',
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String sketchId;
  final String draftRevisionId;
  final String displayName;
  @override
  String get primaryAggregateId => sketchId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.sketch;
  @override
  InventoryCommandType get commandType => InventoryCommandType.sketchCreate;
}

class AutosaveInventorySketchDraftCommand implements InventoryMutationCommand {
  const AutosaveInventorySketchDraftCommand({
    required this.operationId,
    required this.projectId,
    required this.sketchId,
    required this.draftRevisionId,
    required this.expectedSketchRevision,
    required this.expectedContentRevision,
    required this.geometry,
    this.newBlocks = const [],
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String sketchId;
  final String draftRevisionId;
  final int expectedSketchRevision;
  final int expectedContentRevision;
  final InventoryGeometry geometry;
  final List<InventoryBlockDraft> newBlocks;
  @override
  String get primaryAggregateId => sketchId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.sketch;
  @override
  InventoryCommandType get commandType =>
      InventoryCommandType.sketchDraftAutosave;
}

class StartInventorySketchEditCommand implements InventoryMutationCommand {
  const StartInventorySketchEditCommand({
    required this.operationId,
    required this.projectId,
    required this.sketchId,
    required this.activeRevisionId,
    required this.newDraftRevisionId,
    required this.expectedSketchRevision,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String sketchId;
  final String activeRevisionId;
  final String newDraftRevisionId;
  final int expectedSketchRevision;
  @override
  String get primaryAggregateId => sketchId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.sketch;
  @override
  InventoryCommandType get commandType => InventoryCommandType.sketchEditStart;
}

class FinalizeInventorySketchCommand implements InventoryMutationCommand {
  const FinalizeInventorySketchCommand({
    required this.operationId,
    required this.projectId,
    required this.sketchId,
    required this.draftRevisionId,
    required this.expectedSketchRevision,
    required this.expectedContentRevision,
    this.newBlocks = const [],
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String sketchId;
  final String draftRevisionId;
  final int expectedSketchRevision;
  final int expectedContentRevision;
  final List<InventoryBlockDraft> newBlocks;
  @override
  String get primaryAggregateId => sketchId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.sketch;
  @override
  InventoryCommandType get commandType => InventoryCommandType.sketchFinalize;
}

class InventoryFloorDraft {
  const InventoryFloorDraft({
    required this.id,
    required this.displayName,
    required this.ordinal,
  });

  final String id;
  final String displayName;
  final int ordinal;

  void validate() {
    if (InventorySpatialContract.normalizeFloorName(displayName) !=
        displayName) {
      throw const InventoryFailure('inventory_floor_name_invalid');
    }
    if (ordinal < 1 || ordinal > InventorySpatialContract.maximumFloorCount) {
      throw const InventoryFailure('inventory_floor_ordinal_invalid');
    }
  }
}

class InventoryBlockDraft {
  InventoryBlockDraft({
    required this.id,
    required this.displayName,
    required this.polygonIndex,
    required Iterable<InventoryFloorDraft> floors,
  }) : floors = List<InventoryFloorDraft>.unmodifiable(
         List<InventoryFloorDraft>.of(floors)
           ..sort((first, second) => first.ordinal.compareTo(second.ordinal)),
       );

  final String id;
  final String displayName;
  final int polygonIndex;
  final List<InventoryFloorDraft> floors;

  void validate(InventoryGeometry geometry) {
    if (InventorySpatialContract.normalizeBlockName(displayName) !=
        displayName) {
      throw const InventoryFailure('inventory_block_name_invalid');
    }
    InventorySpatialContract.validateFloorCount(floors.length);
    if (polygonIndex < 0 || polygonIndex >= geometry.polylines.length) {
      throw const InventoryFailure('inventory_block_polygon_index_invalid');
    }
    InventorySpatialContract.validateBlockPolygon(
      geometry.polylines[polygonIndex],
    );
    final floorIds = <String>{};
    final ordinals = <int>{};
    for (final floor in floors) {
      floor.validate();
      if (!floorIds.add(floor.id) || !ordinals.add(floor.ordinal)) {
        throw const InventoryFailure('inventory_floor_identity_ambiguous');
      }
    }
    for (var ordinal = 1; ordinal <= floors.length; ordinal += 1) {
      if (!ordinals.contains(ordinal)) {
        throw const InventoryFailure('inventory_floor_order_invalid');
      }
    }
  }
}

class AbandonInventorySketchDraftCommand implements InventoryMutationCommand {
  const AbandonInventorySketchDraftCommand({
    required this.operationId,
    required this.projectId,
    required this.sketchId,
    required this.draftRevisionId,
    required this.expectedSketchRevision,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String sketchId;
  final String draftRevisionId;
  final int expectedSketchRevision;
  @override
  String get primaryAggregateId => sketchId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.sketch;
  @override
  InventoryCommandType get commandType =>
      InventoryCommandType.sketchDraftAbandon;
}

class ArchiveInventorySketchCommand implements InventoryMutationCommand {
  const ArchiveInventorySketchCommand({
    required this.operationId,
    required this.projectId,
    required this.sketchId,
    required this.expectedSketchRevision,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String sketchId;
  final int expectedSketchRevision;
  @override
  String get primaryAggregateId => sketchId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.sketch;
  @override
  InventoryCommandType get commandType => InventoryCommandType.sketchArchive;
}

class UnarchiveInventorySketchCommand implements InventoryMutationCommand {
  const UnarchiveInventorySketchCommand({
    required this.operationId,
    required this.projectId,
    required this.sketchId,
    required this.expectedSketchRevision,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String sketchId;
  final int expectedSketchRevision;
  @override
  String get primaryAggregateId => sketchId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.sketch;
  @override
  InventoryCommandType get commandType => InventoryCommandType.sketchUnarchive;
}

class CreateInventoryAssetCommand implements InventoryMutationCommand {
  const CreateInventoryAssetCommand({
    required this.operationId,
    required this.projectId,
    required this.assetId,
    required this.placementId,
    required this.placementKey,
    required this.sketchId,
    required this.activeRevisionId,
    required this.displayName,
    required this.category,
    required this.totalQuantity,
    required this.x,
    required this.y,
    this.floorId,
    this.otherCategoryLabel,
    this.status = InventoryAssetStatus.available,
    this.note,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String assetId;
  final String placementId;
  final String placementKey;
  final String sketchId;
  final String activeRevisionId;
  final String? floorId;
  final String displayName;
  final InventoryCategory category;
  final String? otherCategoryLabel;
  final int totalQuantity;
  final InventoryAssetStatus status;
  final String? note;
  final int x;
  final int y;
  @override
  String get primaryAggregateId => assetId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.asset;
  @override
  InventoryCommandType get commandType =>
      InventoryCommandType.assetCreateWithPlacement;
}

class UpdateInventoryAssetCommand implements InventoryMutationCommand {
  const UpdateInventoryAssetCommand({
    required this.operationId,
    required this.projectId,
    required this.assetId,
    required this.expectedAssetRevision,
    required this.displayName,
    required this.category,
    this.otherCategoryLabel,
    this.note,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String assetId;
  final int expectedAssetRevision;
  final String displayName;
  final InventoryCategory category;
  final String? otherCategoryLabel;
  final String? note;
  @override
  String get primaryAggregateId => assetId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.asset;
  @override
  InventoryCommandType get commandType => InventoryCommandType.assetUpdate;
}

class ChangeInventoryAssetStatusCommand implements InventoryMutationCommand {
  const ChangeInventoryAssetStatusCommand({
    required this.operationId,
    required this.projectId,
    required this.assetId,
    required this.expectedAssetRevision,
    required this.status,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String assetId;
  final int expectedAssetRevision;
  final InventoryAssetStatus status;
  @override
  String get primaryAggregateId => assetId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.asset;
  @override
  InventoryCommandType get commandType =>
      InventoryCommandType.assetStatusChange;
}

class ChangeInventoryAssetQuantityCommand implements InventoryMutationCommand {
  const ChangeInventoryAssetQuantityCommand({
    required this.operationId,
    required this.projectId,
    required this.assetId,
    required this.placementKey,
    required this.successorPlacementId,
    required this.expectedAssetRevision,
    required this.expectedPlacementSequence,
    required this.totalQuantity,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String assetId;
  final String placementKey;
  final String successorPlacementId;
  final int expectedAssetRevision;
  final int expectedPlacementSequence;
  final int totalQuantity;
  @override
  String get primaryAggregateId => assetId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.asset;
  @override
  InventoryCommandType get commandType =>
      InventoryCommandType.assetQuantityChange;
}

class ArchiveInventoryAssetCommand implements InventoryMutationCommand {
  const ArchiveInventoryAssetCommand({
    required this.operationId,
    required this.projectId,
    required this.assetId,
    required this.expectedAssetRevision,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String assetId;
  final int expectedAssetRevision;
  @override
  String get primaryAggregateId => assetId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.asset;
  @override
  InventoryCommandType get commandType => InventoryCommandType.assetArchive;
}

class UnarchiveInventoryAssetCommand implements InventoryMutationCommand {
  const UnarchiveInventoryAssetCommand({
    required this.operationId,
    required this.projectId,
    required this.assetId,
    required this.placementKey,
    required this.successorPlacementId,
    required this.sketchId,
    required this.activeRevisionId,
    required this.expectedAssetRevision,
    required this.expectedPreviousPlacementSequence,
    required this.x,
    required this.y,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String assetId;
  final String placementKey;
  final String successorPlacementId;
  final String sketchId;
  final String activeRevisionId;
  final int expectedAssetRevision;
  final int expectedPreviousPlacementSequence;
  final int x;
  final int y;
  @override
  String get primaryAggregateId => assetId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.asset;
  @override
  InventoryCommandType get commandType =>
      InventoryCommandType.assetUnarchiveWithPlacement;
}

class MoveInventoryPlacementCommand implements InventoryMutationCommand {
  const MoveInventoryPlacementCommand({
    required this.operationId,
    required this.projectId,
    required this.assetId,
    required this.placementKey,
    required this.successorPlacementId,
    required this.sketchId,
    required this.activeRevisionId,
    required this.expectedPlacementSequence,
    required this.x,
    required this.y,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String assetId;
  final String placementKey;
  final String successorPlacementId;
  final String sketchId;
  final String activeRevisionId;
  final int expectedPlacementSequence;
  final int x;
  final int y;
  @override
  String get primaryAggregateId => placementKey;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.placement;
  @override
  InventoryCommandType get commandType => InventoryCommandType.placementMove;
}

enum InventoryPhotoSource { camera, photoLibrary }

enum InventoryPhotoPickOutcome { selected, denied, cancelled, unavailable }

enum InventoryPhotoIntegrity {
  healthy('healthy'),
  missingFile('missing_file'),
  sizeMismatch('size_mismatch'),
  hashMismatch('hash_mismatch'),
  mimeMismatch('mime_mismatch'),
  unsafePath('unsafe_path');

  const InventoryPhotoIntegrity(this.code);

  final String code;
}

class InventoryPhotoSelection {
  InventoryPhotoSelection({
    required this.originalFileName,
    required Iterable<int> bytes,
    required this.source,
  }) : bytes = List<int>.unmodifiable(bytes);

  final String originalFileName;
  final List<int> bytes;
  final InventoryPhotoSource source;
}

class InventoryPhotoPickResult {
  const InventoryPhotoPickResult({required this.outcome, this.selection});

  final InventoryPhotoPickOutcome outcome;
  final InventoryPhotoSelection? selection;
}

class StagedInventoryPhoto {
  const StagedInventoryPhoto({
    required this.relativePath,
    required this.mimeType,
    required this.byteSize,
    required this.sha256Value,
  });

  final String relativePath;
  final String mimeType;
  final int byteSize;
  final String sha256Value;
}

class InventoryPhotoContent {
  InventoryPhotoContent({
    required this.fileName,
    required this.mimeType,
    required Iterable<int> bytes,
  }) : bytes = List<int>.unmodifiable(bytes);

  final String fileName;
  final String mimeType;
  final List<int> bytes;
}

abstract interface class InventoryAttachmentGateway {
  Future<InventoryPhotoPickResult> pick(InventoryPhotoSource source);

  Future<StagedInventoryPhoto> stage({
    required String assetId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  });

  Future<InventoryPhotoIntegrity> inspect({
    required String relativePath,
    required String expectedSha256,
    required String expectedMimeType,
    required int expectedByteSize,
  });

  Future<InventoryPhotoContent> read({
    required String relativePath,
    required String originalFileName,
    required String expectedSha256,
    required String expectedMimeType,
    required int expectedByteSize,
  });

  Future<void> cleanup(String relativePath);
}

class UnavailableInventoryAttachmentGateway
    implements InventoryAttachmentGateway {
  const UnavailableInventoryAttachmentGateway();

  Never _fail() => throw const InventoryFailure('inventory_photo_unavailable');

  @override
  Future<void> cleanup(String relativePath) async {}

  @override
  Future<InventoryPhotoIntegrity> inspect({
    required String relativePath,
    required String expectedSha256,
    required String expectedMimeType,
    required int expectedByteSize,
  }) async => InventoryPhotoIntegrity.missingFile;

  @override
  Future<InventoryPhotoPickResult> pick(InventoryPhotoSource source) async =>
      const InventoryPhotoPickResult(
        outcome: InventoryPhotoPickOutcome.unavailable,
      );

  @override
  Future<InventoryPhotoContent> read({
    required String relativePath,
    required String originalFileName,
    required String expectedSha256,
    required String expectedMimeType,
    required int expectedByteSize,
  }) async => _fail();

  @override
  Future<StagedInventoryPhoto> stage({
    required String assetId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) async => _fail();
}

class AddOrReplaceInventoryAssetPhotoCommand
    implements InventoryMutationCommand {
  AddOrReplaceInventoryAssetPhotoCommand({
    required this.operationId,
    required this.projectId,
    required this.assetId,
    required this.linkId,
    required this.attachmentId,
    required this.expectedAssetRevision,
    required this.selection,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String assetId;
  final String linkId;
  final String attachmentId;
  final int expectedAssetRevision;
  final InventoryPhotoSelection selection;

  @override
  InventoryCommandType get commandType => InventoryCommandType.photoLink;
  @override
  String get primaryAggregateId => linkId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.attachmentLink;
}

class RemoveInventoryAssetPhotoCommand implements InventoryMutationCommand {
  const RemoveInventoryAssetPhotoCommand({
    required this.operationId,
    required this.projectId,
    required this.assetId,
    required this.linkId,
    required this.expectedAssetRevision,
    required this.expectedLinkRevision,
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String assetId;
  final String linkId;
  final int expectedAssetRevision;
  final int expectedLinkRevision;

  @override
  InventoryCommandType get commandType => InventoryCommandType.photoArchive;
  @override
  String get primaryAggregateId => linkId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.attachmentLink;
}

class InventoryMutationResult {
  const InventoryMutationResult({
    required this.operationId,
    required this.commandType,
    required this.projectId,
    required this.primaryAggregateType,
    required this.primaryAggregateId,
    required this.sourceId,
    required this.sourceRevision,
    required this.supportingId,
    required this.supportingRevision,
    required this.isNoOp,
    required this.eventCount,
    required this.resultAt,
  });

  final String operationId;
  final InventoryCommandType commandType;
  final String projectId;
  final InventoryAggregateType primaryAggregateType;
  final String primaryAggregateId;
  final String sourceId;
  final int sourceRevision;
  final String? supportingId;
  final int? supportingRevision;
  final bool isNoOp;
  final int eventCount;
  final DateTime resultAt;
}

class InventoryAvailability {
  const InventoryAvailability({
    required this.projectId,
    required this.projectAvailable,
    required this.hasPrimarySketch,
  });

  final String projectId;
  final bool projectAvailable;
  final bool hasPrimarySketch;
}

class InventorySketchRecord {
  const InventorySketchRecord({
    required this.id,
    required this.projectId,
    required this.displayName,
    required this.isPrimary,
    required this.activeRevisionId,
    required this.draftRevisionId,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String projectId;
  final String displayName;
  final bool isPrimary;
  final String? activeRevisionId;
  final String? draftRevisionId;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class InventorySketchRevisionRecord {
  const InventorySketchRevisionRecord({
    required this.id,
    required this.sketchId,
    required this.projectId,
    required this.revisionNumber,
    required this.baseRevisionId,
    required this.state,
    required this.geometry,
    required this.geometrySha256,
    required this.contentRevision,
    required this.createdAt,
    required this.updatedAt,
    required this.finalizedAt,
    required this.supersededAt,
    required this.abandonedAt,
  });

  final String id;
  final String sketchId;
  final String projectId;
  final int revisionNumber;
  final String? baseRevisionId;
  final InventorySketchRevisionState state;
  final InventoryGeometry geometry;
  final String geometrySha256;
  final int contentRevision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? finalizedAt;
  final DateTime? supersededAt;
  final DateTime? abandonedAt;
}

class InventoryPrimarySketchProjection {
  const InventoryPrimarySketchProjection({
    required this.sketch,
    required this.activeRevision,
    required this.draftRevision,
    this.blocks = const [],
    this.floors = const [],
    this.activeBlockPolygons = const [],
    this.draftBlockPolygons = const [],
    this.draftNewBlocks = const [],
    this.draftLegacyPolygonCount = 0,
  });

  final InventorySketchRecord sketch;
  final InventorySketchRevisionRecord? activeRevision;
  final InventorySketchRevisionRecord? draftRevision;
  final List<InventoryBlockRecord> blocks;
  final List<InventoryFloorRecord> floors;
  final List<InventoryRevisionBlockPolygonRecord> activeBlockPolygons;
  final List<InventoryRevisionBlockPolygonRecord> draftBlockPolygons;
  final List<InventoryBlockDraft> draftNewBlocks;
  final int draftLegacyPolygonCount;
}

class InventoryBlockRecord {
  const InventoryBlockRecord({
    required this.id,
    required this.projectId,
    required this.displayName,
    required this.normalizedName,
    required this.ordinal,
    required this.state,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String projectId;
  final String displayName;
  final String normalizedName;
  final int ordinal;
  final InventoryBlockState state;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class InventoryFloorRecord {
  const InventoryFloorRecord({
    required this.id,
    required this.blockId,
    required this.projectId,
    required this.displayName,
    required this.ordinal,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String blockId;
  final String projectId;
  final String displayName;
  final int ordinal;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class InventoryRevisionBlockPolygonRecord {
  const InventoryRevisionBlockPolygonRecord({
    required this.revisionId,
    required this.blockId,
    required this.projectId,
    required this.sketchId,
    required this.polygonIndex,
    required this.createdAt,
  });

  final String revisionId;
  final String blockId;
  final String projectId;
  final String sketchId;
  final int polygonIndex;
  final DateTime createdAt;
}

class InventoryAssetRecord {
  const InventoryAssetRecord({
    required this.id,
    required this.projectId,
    required this.displayName,
    required this.normalizedName,
    required this.category,
    required this.otherCategoryLabel,
    required this.totalQuantity,
    required this.status,
    required this.note,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.statusChangedAt,
    required this.archivedAt,
  });

  final String id;
  final String projectId;
  final String displayName;
  final String normalizedName;
  final InventoryCategory category;
  final String? otherCategoryLabel;
  final int totalQuantity;
  final InventoryAssetStatus status;
  final String? note;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime statusChangedAt;
  final DateTime? archivedAt;
}

class InventoryPlacementRecord {
  const InventoryPlacementRecord({
    required this.id,
    required this.placementKey,
    required this.projectId,
    required this.assetId,
    required this.sketchId,
    required this.floorId,
    required this.provenanceRevisionId,
    required this.sequence,
    required this.x,
    required this.y,
    required this.quantity,
    required this.createdAt,
    required this.endedAt,
    required this.endReason,
    required this.supersedesPlacementId,
  });

  final String id;
  final String placementKey;
  final String projectId;
  final String assetId;
  final String sketchId;
  final String floorId;
  final String provenanceRevisionId;
  final int sequence;
  final int x;
  final int y;
  final int quantity;
  final DateTime createdAt;
  final DateTime? endedAt;
  final InventoryPlacementEndReason? endReason;
  final String? supersedesPlacementId;
  bool get isActive => endedAt == null;
}

class InventoryAssetProjection {
  const InventoryAssetProjection({
    required this.asset,
    required this.activePlacement,
  });

  final InventoryAssetRecord asset;
  final InventoryPlacementRecord? activePlacement;
}

class InventoryAssetPhotoRecord {
  const InventoryAssetPhotoRecord({
    required this.linkId,
    required this.attachmentId,
    required this.assetId,
    required this.projectId,
    required this.originalFileName,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
    required this.relativePath,
    required this.mimeType,
    required this.byteSize,
    required this.sha256Value,
    required this.integrity,
  });

  final String linkId;
  final String attachmentId;
  final String assetId;
  final String projectId;
  final String originalFileName;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final String relativePath;
  final String mimeType;
  final int byteSize;
  final String sha256Value;
  final InventoryPhotoIntegrity integrity;

  bool get isActive => archivedAt == null;
  bool get supportsInlinePreview =>
      mimeType == 'image/jpeg' || mimeType == 'image/png';
}

class InventoryEventRecord {
  InventoryEventRecord({
    required this.id,
    required this.operationId,
    required this.projectId,
    required this.aggregateType,
    required this.aggregateId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required Map<String, Object?> payload,
    required this.payloadJson,
    required this.payloadSha256,
  }) : payload = Map<String, Object?>.unmodifiable(payload);

  final String id;
  final String operationId;
  final String projectId;
  final InventoryAggregateType aggregateType;
  final String aggregateId;
  final int sequence;
  final InventoryEventType eventType;
  final DateTime occurredAt;
  final Map<String, Object?> payload;
  final String payloadJson;
  final String payloadSha256;
}
