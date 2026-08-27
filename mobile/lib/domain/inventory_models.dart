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
  placementMove('placement_move');

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
  placement('placement');

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
  placementRetired('inventory.placement_retired');

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
  });

  @override
  final String operationId;
  @override
  final String projectId;
  final String sketchId;
  final String draftRevisionId;
  final int expectedSketchRevision;
  final int expectedContentRevision;
  @override
  String get primaryAggregateId => sketchId;
  @override
  InventoryAggregateType get primaryAggregateType =>
      InventoryAggregateType.sketch;
  @override
  InventoryCommandType get commandType => InventoryCommandType.sketchFinalize;
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
  });

  final InventorySketchRecord sketch;
  final InventorySketchRevisionRecord? activeRevision;
  final InventorySketchRevisionRecord? draftRevision;
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
