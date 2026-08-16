import 'dart:convert';

import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';

enum ConstructionLivingPlanStatus {
  planned('PLANNED'),
  started('STARTED'),
  completed('COMPLETED'),
  deferred('DEFERRED');

  const ConstructionLivingPlanStatus(this.storageValue);

  final String storageValue;

  static ConstructionLivingPlanStatus fromStorage(Object? value) {
    for (final status in values) {
      if (status.storageValue == value) {
        return status;
      }
    }
    throw const ConstructionLivingPlanFailure('living_plan_invalid_status');
  }
}

enum ConstructionLivingPlanEventType {
  created('CREATED'),
  started('STARTED'),
  completed('COMPLETED'),
  deferred('DEFERRED'),
  reopened('REOPENED'),
  noteUpdated('NOTE_UPDATED');

  const ConstructionLivingPlanEventType(this.storageValue);

  final String storageValue;

  static ConstructionLivingPlanEventType fromStorage(Object? value) {
    for (final type in values) {
      if (type.storageValue == value) {
        return type;
      }
    }
    throw const ConstructionLivingPlanFailure('living_plan_invalid_event_type');
  }
}

class ConstructionLivingPlanReferenceCandidate {
  const ConstructionLivingPlanReferenceCandidate({
    required this.referenceSnapshotId,
    required this.projectId,
    required this.activityInstanceId,
    required this.activityId,
    required this.activityName,
    required this.activityContext,
    required this.naturalUnit,
    required this.suggestedStartDate,
    required this.suggestedFinishDate,
    required this.durationStatus,
    required this.durationConfidence,
    required this.activitySequence,
    required this.existingLivingPlanItemId,
    required this.existingLivingPlanStatus,
  });

  final String referenceSnapshotId;
  final String projectId;
  final String activityInstanceId;
  final String activityId;
  final String activityName;
  final ConstructionProjectActivityContext activityContext;
  final String naturalUnit;
  final DateTime suggestedStartDate;
  final DateTime suggestedFinishDate;
  final ConstructionScheduleDurationStatus durationStatus;
  final ConstructionScheduleDurationConfidence durationConfidence;
  final int activitySequence;
  final String? existingLivingPlanItemId;
  final ConstructionLivingPlanStatus? existingLivingPlanStatus;
}

class ConstructionLivingPlanItem {
  const ConstructionLivingPlanItem({
    required this.id,
    required this.projectId,
    required this.referenceSnapshotId,
    required this.activityInstanceId,
    required this.activityId,
    required this.activityNameSnapshot,
    required this.activityContext,
    required this.naturalUnitSnapshot,
    required this.plannedDate,
    required this.status,
    required this.note,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.statusChangedAt,
  });

  final String id;
  final String projectId;
  final String referenceSnapshotId;
  final String activityInstanceId;
  final String activityId;
  final String activityNameSnapshot;
  final ConstructionProjectActivityContext activityContext;
  final String naturalUnitSnapshot;
  final DateTime plannedDate;
  final ConstructionLivingPlanStatus status;
  final String? note;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime statusChangedAt;
}

class ConstructionLivingPlanWindowItem {
  const ConstructionLivingPlanWindowItem({
    required this.item,
    required this.isOverdue,
    required this.originSnapshotIsCurrent,
  });

  final ConstructionLivingPlanItem item;
  final bool isOverdue;
  final bool originSnapshotIsCurrent;
}

class ConstructionLivingPlanEvent {
  ConstructionLivingPlanEvent({
    required this.id,
    required this.livingPlanItemId,
    required this.projectId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.payloadJson,
    required Map<String, Object?> payload,
  }) : payload = Map.unmodifiable(payload);

  final String id;
  final String livingPlanItemId;
  final String projectId;
  final int sequence;
  final ConstructionLivingPlanEventType eventType;
  final DateTime occurredAt;
  final String payloadJson;
  final Map<String, Object?> payload;
}

class CreateConstructionLivingPlanItemCommand {
  const CreateConstructionLivingPlanItemCommand({
    required this.itemId,
    required this.eventId,
    required this.projectId,
    required this.expectedReferenceSnapshotId,
    required this.activityInstanceId,
    required this.plannedDate,
    this.note,
  });

  final String itemId;
  final String eventId;
  final String projectId;
  final String expectedReferenceSnapshotId;
  final String activityInstanceId;
  final DateTime plannedDate;
  final String? note;
}

class StartConstructionLivingPlanItemCommand {
  const StartConstructionLivingPlanItemCommand({
    required this.itemId,
    required this.eventId,
    required this.expectedRevision,
  });

  final String itemId;
  final String eventId;
  final int expectedRevision;
}

class CompleteConstructionLivingPlanItemCommand {
  const CompleteConstructionLivingPlanItemCommand({
    required this.itemId,
    required this.eventId,
    required this.expectedRevision,
  });

  final String itemId;
  final String eventId;
  final int expectedRevision;
}

class DeferConstructionLivingPlanItemCommand {
  const DeferConstructionLivingPlanItemCommand({
    required this.itemId,
    required this.eventId,
    required this.expectedRevision,
    required this.plannedDate,
  });

  final String itemId;
  final String eventId;
  final int expectedRevision;
  final DateTime plannedDate;
}

class ReopenConstructionLivingPlanItemCommand {
  const ReopenConstructionLivingPlanItemCommand({
    required this.itemId,
    required this.eventId,
    required this.expectedRevision,
    required this.plannedDate,
  });

  final String itemId;
  final String eventId;
  final int expectedRevision;
  final DateTime plannedDate;
}

class UpdateConstructionLivingPlanNoteCommand {
  const UpdateConstructionLivingPlanNoteCommand({
    required this.itemId,
    required this.eventId,
    required this.expectedRevision,
    this.note,
  });

  final String itemId;
  final String eventId;
  final int expectedRevision;
  final String? note;
}

class ConstructionLivingPlanFailure implements Exception {
  const ConstructionLivingPlanFailure(this.code);

  final String code;

  @override
  String toString() => 'ConstructionLivingPlanFailure($code)';
}

String encodeConstructionLivingPlanJson(Object? value) =>
    jsonEncode(_canonicalJsonValue(value));

String encodeConstructionLivingPlanContext(
  ConstructionProjectActivityContext context,
) => encodeConstructionLivingPlanJson(context.toJson());

ConstructionProjectActivityContext decodeConstructionLivingPlanContext(
  String value,
) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException();
    }
    final map = decoded.cast<String, Object?>();
    const keys = {
      'basement_index',
      'block_id',
      'facade_elevation',
      'floor_index',
      'lot_id',
      'roof_id',
      'system_id',
      'zone_id',
    };
    if (map.keys.any((key) => !keys.contains(key))) {
      throw const FormatException();
    }
    String? optionalString(String key) {
      final item = map[key];
      if (item == null) {
        return null;
      }
      if (item is! String || item.isEmpty || item.trim() != item) {
        throw const FormatException();
      }
      return item;
    }

    int? optionalInt(String key) {
      final item = map[key];
      if (item == null) {
        return null;
      }
      if (item is! int || item < 1) {
        throw const FormatException();
      }
      return item;
    }

    final context = ConstructionProjectActivityContext(
      blockId: optionalString('block_id'),
      basementIndex: optionalInt('basement_index'),
      floorIndex: optionalInt('floor_index'),
      zoneId: optionalString('zone_id'),
      facadeElevation: optionalString('facade_elevation'),
      roofId: optionalString('roof_id'),
      lotId: optionalInt('lot_id'),
      systemId: optionalString('system_id'),
    );
    if (encodeConstructionLivingPlanContext(context) != value) {
      throw const FormatException();
    }
    return context;
  } on ConstructionLivingPlanFailure {
    rethrow;
  } on Object {
    throw const ConstructionLivingPlanFailure(
      'living_plan_invalid_activity_context',
    );
  }
}

Object? _canonicalJsonValue(Object? value) {
  if (value == null || value is String || value is bool || value is num) {
    return value;
  }
  if (value is List) {
    return [for (final item in value) _canonicalJsonValue(item)];
  }
  if (value is Map) {
    final entries = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const ConstructionLivingPlanFailure('living_plan_invalid_json');
      }
      entries[entry.key as String] = entry.value;
    }
    final keys = entries.keys.toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalJsonValue(entries[key]),
    };
  }
  throw const ConstructionLivingPlanFailure('living_plan_invalid_json');
}
