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
