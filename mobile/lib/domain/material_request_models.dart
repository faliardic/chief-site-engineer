class MaterialRequestFailure implements Exception {
  const MaterialRequestFailure(this.code);

  final String code;

  @override
  String toString() => 'MaterialRequestFailure: $code';
}

enum MaterialRequestStatus {
  needed,
  requested,
  received,
  cancelled;

  String get storageValue => name;

  String get label => switch (this) {
    needed => 'İhtiyaç var',
    requested => 'İstendi',
    received => 'Geldi',
    cancelled => 'İptal',
  };

  bool get isOpen => this == needed || this == requested;

  static MaterialRequestStatus fromStorage(String value) => switch (value) {
    'needed' => needed,
    'requested' => requested,
    'received' => received,
    'cancelled' => cancelled,
    _ => throw const MaterialRequestFailure('material_request_corrupt_status'),
  };
}

enum MaterialRequestPriority {
  normal,
  high,
  urgent;

  String get storageValue => name;

  String get label => switch (this) {
    normal => 'Normal',
    high => 'Yüksek',
    urgent => 'Acil',
  };

  static MaterialRequestPriority fromStorage(String value) => switch (value) {
    'normal' => normal,
    'high' => high,
    'urgent' => urgent,
    _ => throw const MaterialRequestFailure(
      'material_request_corrupt_priority',
    ),
  };
}

enum MaterialRequestListKind { open, history }

enum MaterialRequestEventType {
  created,
  detailsUpdated,
  requested,
  received,
  cancelled,
  reopened;

  String get storageValue => switch (this) {
    created => 'material_request.created',
    detailsUpdated => 'material_request.updated',
    requested => 'material_request.requested',
    received => 'material_request.received',
    cancelled => 'material_request.cancelled',
    reopened => 'material_request.reopened',
  };

  String get label => switch (this) {
    created => 'İhtiyaç kaydedildi',
    detailsUpdated => 'Bilgiler güncellendi',
    requested => 'İstendi',
    received => 'Geldi',
    cancelled => 'İptal',
    reopened => 'Yeniden açıldı',
  };

  static MaterialRequestEventType fromStorage(String value) => switch (value) {
    'material_request.created' => created,
    'material_request.updated' => detailsUpdated,
    'material_request.requested' => requested,
    'material_request.received' => received,
    'material_request.cancelled' => cancelled,
    'material_request.reopened' => reopened,
    _ => throw const MaterialRequestFailure(
      'material_request_corrupt_event_type',
    ),
  };
}

class MaterialRequestProject {
  const MaterialRequestProject({required this.id, required this.name});

  final String id;
  final String name;
}

class MaterialRequestLocationOption {
  const MaterialRequestLocationOption({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}

class MaterialRequestLivingPlanOption {
  const MaterialRequestLivingPlanOption({
    required this.id,
    required this.activityName,
    required this.plannedDate,
    required this.status,
  });

  final String id;
  final String activityName;
  final String plannedDate;
  final String status;
}

class MaterialRequest {
  const MaterialRequest({
    required this.id,
    required this.projectId,
    required this.materialName,
    required this.priority,
    required this.status,
    required this.revision,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.statusChangedAtUtc,
    this.locationId,
    this.locationName,
    this.livingPlanItemId,
    this.livingPlanActivityName,
    this.quantity,
    this.unit,
    this.neededOn,
    this.description,
    this.requestedAtUtc,
    this.receivedAtUtc,
    this.cancelledAtUtc,
  });

  final String id;
  final String projectId;
  final String? locationId;
  final String? locationName;
  final String? livingPlanItemId;
  final String? livingPlanActivityName;
  final String materialName;
  final double? quantity;
  final String? unit;
  final String? neededOn;
  final MaterialRequestPriority priority;
  final String? description;
  final MaterialRequestStatus status;
  final int revision;
  final String createdAtUtc;
  final String updatedAtUtc;
  final String statusChangedAtUtc;
  final String? requestedAtUtc;
  final String? receivedAtUtc;
  final String? cancelledAtUtc;
}

class MaterialRequestEvent {
  const MaterialRequestEvent({
    required this.id,
    required this.materialRequestId,
    required this.projectId,
    required this.sequence,
    required this.type,
    required this.occurredAtUtc,
  });

  final String id;
  final String materialRequestId;
  final String projectId;
  final int sequence;
  final MaterialRequestEventType type;
  final String occurredAtUtc;
}

class MaterialRequestDetail {
  const MaterialRequestDetail({required this.request, required this.events});

  final MaterialRequest request;
  final List<MaterialRequestEvent> events;
}

class CreateMaterialRequestCommand {
  const CreateMaterialRequestCommand({
    required this.requestId,
    required this.eventId,
    required this.projectId,
    required this.materialName,
    required this.priority,
    this.locationId,
    this.livingPlanItemId,
    this.quantity,
    this.unit,
    this.neededOn,
    this.description,
  });

  final String requestId;
  final String eventId;
  final String projectId;
  final String? locationId;
  final String? livingPlanItemId;
  final String materialName;
  final double? quantity;
  final String? unit;
  final String? neededOn;
  final MaterialRequestPriority priority;
  final String? description;
}

class UpdateMaterialRequestCommand {
  const UpdateMaterialRequestCommand({
    required this.requestId,
    required this.eventId,
    required this.expectedRevision,
    required this.materialName,
    required this.priority,
    this.locationId,
    this.livingPlanItemId,
    this.quantity,
    this.unit,
    this.neededOn,
    this.description,
  });

  final String requestId;
  final String eventId;
  final int expectedRevision;
  final String? locationId;
  final String? livingPlanItemId;
  final String materialName;
  final double? quantity;
  final String? unit;
  final String? neededOn;
  final MaterialRequestPriority priority;
  final String? description;
}

class TransitionMaterialRequestCommand {
  const TransitionMaterialRequestCommand({
    required this.requestId,
    required this.eventId,
    required this.expectedRevision,
    required this.targetStatus,
  });

  final String requestId;
  final String eventId;
  final int expectedRevision;
  final MaterialRequestStatus targetStatus;
}
