enum ProjectLocationArchiveFilter { active, archived }

enum ProjectLocationEventType {
  created('location.created'),
  renamed('location.renamed'),
  reparented('location.reparented'),
  archived('location.archived'),
  restored('location.restored');

  const ProjectLocationEventType(this.storageValue);

  final String storageValue;
}

class MobileProjectLocation {
  const MobileProjectLocation({
    required this.id,
    required this.projectId,
    required this.displayName,
    required this.parentLocationId,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String projectId;
  final String displayName;
  final String? parentLocationId;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;

  bool get isArchived => archivedAt != null;
}

class ProjectLocationQuery {
  const ProjectLocationQuery({
    required this.projectId,
    this.archiveFilter = ProjectLocationArchiveFilter.active,
  });

  final String projectId;
  final ProjectLocationArchiveFilter archiveFilter;
}

class CreateProjectLocationCommand {
  const CreateProjectLocationCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.displayName,
    this.parentLocationId,
  });

  final String id;
  final String eventId;
  final String projectId;
  final String displayName;
  final String? parentLocationId;
}

class RenameProjectLocationCommand {
  const RenameProjectLocationCommand({
    required this.locationId,
    required this.eventId,
    required this.expectedRevision,
    required this.displayName,
  });

  final String locationId;
  final String eventId;
  final int expectedRevision;
  final String displayName;
}

class ReparentProjectLocationCommand {
  const ReparentProjectLocationCommand({
    required this.locationId,
    required this.eventId,
    required this.expectedRevision,
    this.parentLocationId,
  });

  final String locationId;
  final String eventId;
  final int expectedRevision;
  final String? parentLocationId;
}

class MutateProjectLocationArchiveCommand {
  const MutateProjectLocationArchiveCommand({
    required this.locationId,
    required this.eventId,
    required this.expectedRevision,
    required this.archive,
  });

  final String locationId;
  final String eventId;
  final int expectedRevision;
  final bool archive;
}

class ProjectLocationEvent {
  const ProjectLocationEvent({
    required this.id,
    required this.locationId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.payloadJson,
  });

  final String id;
  final String locationId;
  final int sequence;
  final ProjectLocationEventType eventType;
  final String occurredAt;
  final String payloadJson;
}

enum ProjectFloorLocationEventType {
  assigned('floor_location.assigned'),
  replaced('floor_location.replaced'),
  removed('floor_location.removed');

  const ProjectFloorLocationEventType(this.storageValue);

  final String storageValue;

  static ProjectFloorLocationEventType fromStorage(String value) =>
      values.firstWhere(
        (event) => event.storageValue == value,
        orElse: () => throw StateError(
          'project floor location event type is unsupported',
        ),
      );
}

class ProjectFloorLocationRelation {
  const ProjectFloorLocationRelation({
    required this.id,
    required this.projectId,
    required this.floorId,
    required this.locationId,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String projectId;
  final String floorId;
  final String locationId;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;

  bool get isArchived => archivedAt != null;
}

class CreateProjectFloorLocationRelationCommand {
  const CreateProjectFloorLocationRelationCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.floorId,
    required this.locationId,
  });

  final String id;
  final String eventId;
  final String projectId;
  final String floorId;
  final String locationId;
}

class ReplaceProjectFloorLocationRelationCommand {
  const ReplaceProjectFloorLocationRelationCommand({
    required this.relationId,
    required this.eventId,
    required this.projectId,
    required this.expectedRevision,
    required this.floorId,
  });

  final String relationId;
  final String eventId;
  final String projectId;
  final int expectedRevision;
  final String floorId;
}

class RemoveProjectFloorLocationRelationCommand {
  const RemoveProjectFloorLocationRelationCommand({
    required this.relationId,
    required this.eventId,
    required this.projectId,
    required this.expectedRevision,
  });

  final String relationId;
  final String eventId;
  final String projectId;
  final int expectedRevision;
}

class ProjectFloorLocationEvent {
  const ProjectFloorLocationEvent({
    required this.id,
    required this.relationId,
    required this.projectId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.payloadJson,
  });

  final String id;
  final String relationId;
  final String projectId;
  final int sequence;
  final ProjectFloorLocationEventType eventType;
  final String occurredAt;
  final String payloadJson;
}
