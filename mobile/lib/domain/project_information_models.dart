import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';

enum ProjectInformationSource {
  project,
  metadata,
  profile,
  parties,
  companies,
  workforceMembers,
  inventory,
  blockMetadata,
  locations,
  floorLocations,
}

enum ProjectInformationReadState { loaded, empty, failed }

class ProjectInformationSourceStatus {
  const ProjectInformationSourceStatus({
    required this.source,
    required this.state,
    required this.recordCount,
    this.errorCode,
  });

  final ProjectInformationSource source;
  final ProjectInformationReadState state;
  final int recordCount;
  final String? errorCode;
}

sealed class ProjectInformationLoadResult {
  const ProjectInformationLoadResult({
    required this.projectId,
    required this.generation,
  });

  final String projectId;
  final int generation;
}

class ProjectInformationReady extends ProjectInformationLoadResult {
  const ProjectInformationReady({
    required super.projectId,
    required super.generation,
    required this.snapshot,
  });

  final ProjectInformationSnapshot snapshot;
}

class ProjectInformationLoadFailure extends ProjectInformationLoadResult {
  const ProjectInformationLoadFailure({
    required super.projectId,
    required super.generation,
    required this.failure,
  });

  final ProjectInformationSourceStatus failure;
}

class ProjectInformationSuperseded extends ProjectInformationLoadResult {
  const ProjectInformationSuperseded({
    required super.projectId,
    required super.generation,
  });
}

enum ProjectInformationPartyTargetState {
  resolvedActive,
  resolvedArchived,
  missing,
  sourceUnavailable,
  invalidAssignment,
}

class ProjectInformationParty {
  const ProjectInformationParty({
    required this.assignment,
    required this.targetState,
    this.company,
    this.workforceMember,
  });

  final ProjectPartyAssignment assignment;
  final ProjectInformationPartyTargetState targetState;
  final Subcontractor? company;
  final WorkforceMember? workforceMember;
}

enum ProjectInformationBlockMetadataState { loaded, empty, failed }

class ProjectInformationBlockMetadata {
  const ProjectInformationBlockMetadata({
    required this.state,
    this.value,
    this.errorCode,
  });

  final ProjectInformationBlockMetadataState state;
  final InventoryBlockMetadataRecord? value;
  final String? errorCode;
}

enum ProjectInformationFloorLocationState {
  resolvedActive,
  archivedRelation,
  archivedLocation,
  missingLocation,
  sourceUnavailable,
}

class ProjectInformationFloorLocation {
  const ProjectInformationFloorLocation({
    required this.relation,
    required this.state,
    this.location,
  });

  final ProjectFloorLocationRelation relation;
  final ProjectInformationFloorLocationState state;
  final MobileProjectLocation? location;
}

class ProjectInformationFloor {
  ProjectInformationFloor({
    required this.floor,
    required List<ProjectInformationFloorLocation> locations,
  }) : locations = List.unmodifiable(locations);

  final InventoryFloorRecord floor;
  final List<ProjectInformationFloorLocation> locations;
}

class ProjectInformationBlock {
  ProjectInformationBlock({
    required this.block,
    required this.metadata,
    required List<ProjectInformationFloor> floors,
  }) : floors = List.unmodifiable(floors);

  final InventoryBlockRecord block;
  final ProjectInformationBlockMetadata metadata;
  final List<ProjectInformationFloor> floors;
}

class ProjectInformationUnresolvedFloorLocation {
  const ProjectInformationUnresolvedFloorLocation({
    required this.relation,
    required this.reason,
    this.location,
  });

  final ProjectFloorLocationRelation relation;
  final ProjectInformationUnresolvedFloorLocationReason reason;
  final MobileProjectLocation? location;
}

enum ProjectInformationUnresolvedFloorLocationReason {
  missingFloor,
  missingLocation,
  floorSourceUnavailable,
  locationSourceUnavailable,
}

enum ProjectInformationDerivedAreaState {
  unavailable,
  incomplete,
  mixedUnits,
  available,
}

class ProjectInformationDerivedInventoryTotals {
  const ProjectInformationDerivedInventoryTotals({
    required this.activeBlockCount,
    required this.detachedBlockCount,
    required this.archivedBlockCount,
    required this.activeFloorCount,
    required this.areaState,
    this.totalArea,
    this.totalAreaUnit,
  });

  final int activeBlockCount;
  final int detachedBlockCount;
  final int archivedBlockCount;
  final int activeFloorCount;
  final ProjectInformationDerivedAreaState areaState;
  final double? totalArea;
  final String? totalAreaUnit;

  bool get isDerived => true;
}

class ProjectInformationSnapshot {
  ProjectInformationSnapshot({
    required this.projectId,
    required this.generation,
    required this.project,
    required this.metadata,
    required List<ProjectProfileField> profileFields,
    required List<ProjectInformationParty> parties,
    required List<ProjectInformationBlock> blocks,
    required List<InventoryFloorRecord> unresolvedFloors,
    required List<MobileProjectLocation> locations,
    required List<ProjectInformationUnresolvedFloorLocation>
    unresolvedFloorLocations,
    required this.derivedInventoryTotals,
    required List<ProjectInformationSourceStatus> sourceStatuses,
  }) : profileFields = List.unmodifiable(profileFields),
       parties = List.unmodifiable(parties),
       blocks = List.unmodifiable(blocks),
       unresolvedFloors = List.unmodifiable(unresolvedFloors),
       locations = List.unmodifiable(locations),
       unresolvedFloorLocations = List.unmodifiable(unresolvedFloorLocations),
       sourceStatuses = List.unmodifiable(sourceStatuses);

  final String projectId;
  final int generation;
  final MobileProject project;
  final ProjectMetadata? metadata;
  final List<ProjectProfileField> profileFields;
  final List<ProjectInformationParty> parties;
  final List<ProjectInformationBlock> blocks;
  final List<InventoryFloorRecord> unresolvedFloors;
  final List<MobileProjectLocation> locations;
  final List<ProjectInformationUnresolvedFloorLocation>
  unresolvedFloorLocations;
  final ProjectInformationDerivedInventoryTotals derivedInventoryTotals;
  final List<ProjectInformationSourceStatus> sourceStatuses;

  ProjectInformationSourceStatus statusFor(ProjectInformationSource source) =>
      sourceStatuses.singleWhere((status) => status.source == source);
}

enum ProjectInformationCategory {
  project,
  location,
  technical,
  official,
  siteReference,
  contact,
}

enum ProjectInformationValueKind { text, number, date, boolean, contact }

enum ProjectInformationArchiveFilter { active, archived, all }

enum ProjectInformationReferenceType { workforceMember, subcontractor }

class ProjectInformationContact {
  const ProjectInformationContact({
    required this.name,
    this.company,
    this.role,
    this.phone,
    this.whatsAppNumber,
    this.note,
    this.referenceType,
    this.referenceId,
  });
  final String name;
  final String? company;
  final String? role;
  final String? phone;
  final String? whatsAppNumber;
  final String? note;
  final ProjectInformationReferenceType? referenceType;
  final String? referenceId;
}

class ProjectInformationEntryValue {
  const ProjectInformationEntryValue._({
    required this.kind,
    this.text,
    this.number,
    this.date,
    this.boolean,
    this.contact,
  });
  const ProjectInformationEntryValue.text(String value)
    : this._(kind: ProjectInformationValueKind.text, text: value);
  const ProjectInformationEntryValue.number(double value)
    : this._(kind: ProjectInformationValueKind.number, number: value);
  const ProjectInformationEntryValue.date(String value)
    : this._(kind: ProjectInformationValueKind.date, date: value);
  const ProjectInformationEntryValue.boolean(bool value)
    : this._(kind: ProjectInformationValueKind.boolean, boolean: value);
  const ProjectInformationEntryValue.contact(ProjectInformationContact value)
    : this._(kind: ProjectInformationValueKind.contact, contact: value);
  final ProjectInformationValueKind kind;
  final String? text;
  final double? number;
  final String? date;
  final bool? boolean;
  final ProjectInformationContact? contact;
}

class ProjectInformationEntry {
  const ProjectInformationEntry({
    required this.id,
    required this.projectId,
    required this.category,
    required this.label,
    required this.value,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.unit,
    this.note,
    this.archivedAt,
  });
  final String id;
  final String projectId;
  final ProjectInformationCategory category;
  final String label;
  final ProjectInformationEntryValue value;
  final String? unit;
  final String? note;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;
  bool get isArchived => archivedAt != null;
}

class CreateProjectInformationEntryCommand {
  const CreateProjectInformationEntryCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.category,
    required this.label,
    required this.value,
    this.unit,
    this.note,
  });
  final String id;
  final String eventId;
  final String projectId;
  final ProjectInformationCategory category;
  final String label;
  final ProjectInformationEntryValue value;
  final String? unit;
  final String? note;
}

class UpdateProjectInformationEntryCommand {
  const UpdateProjectInformationEntryCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.expectedRevision,
    required this.category,
    required this.label,
    required this.value,
    this.unit,
    this.note,
  });
  final String id;
  final String eventId;
  final String projectId;
  final int expectedRevision;
  final ProjectInformationCategory category;
  final String label;
  final ProjectInformationEntryValue value;
  final String? unit;
  final String? note;
}

class SetProjectInformationEntryArchiveCommand {
  const SetProjectInformationEntryArchiveCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.expectedRevision,
    required this.archived,
  });
  final String id;
  final String eventId;
  final String projectId;
  final int expectedRevision;
  final bool archived;
}

/// Canonical project-scoped geographic site location (`Şantiye konumu`).
/// Distinct from the free-text postal `metadata.address` and from
/// `MobileProjectLocation` (Mahal/construction hierarchy) — this value is
/// only ever explicitly chosen by the owner from the map picker.
class ProjectSiteLocation {
  const ProjectSiteLocation({
    required this.projectId,
    required this.latitude,
    required this.longitude,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });
  final String projectId;
  final double latitude;
  final double longitude;
  final int revision;
  final String createdAt;
  final String updatedAt;
}

class SetProjectSiteLocationCommand {
  const SetProjectSiteLocationCommand({
    required this.eventId,
    required this.projectId,
    required this.latitude,
    required this.longitude,
    this.expectedRevision,
  });
  final String eventId;
  final String projectId;
  final double latitude;
  final double longitude;

  /// Null only for the first-ever save of a project's site location.
  final int? expectedRevision;
}

class ClearProjectSiteLocationCommand {
  const ClearProjectSiteLocationCommand({
    required this.eventId,
    required this.projectId,
    required this.expectedRevision,
  });
  final String eventId;
  final String projectId;
  final int expectedRevision;
}

enum ProjectInformationKeySpace {
  systemValue,
  profileField,
  partyAssignment,
  inventoryBlock,
  inventoryFloor,
  location,
  userEntry,
}

enum ProjectInformationSystemValue {
  projectName('project.name'),
  address('metadata.address'),
  permitNumber('metadata.permit_number'),
  permitDate('metadata.permit_date'),
  cadastralBlock('metadata.cadastral_block'),
  cadastralParcel('metadata.cadastral_parcel'),
  projectStartDate('metadata.project_start_date'),
  targetFinishDate('metadata.target_finish_date'),
  usageType('metadata.usage_type'),
  structuralSystem('metadata.structural_system');

  const ProjectInformationSystemValue(this.storageKey);
  final String storageKey;
}

class ProjectInformationKey {
  const ProjectInformationKey({required this.space, required this.id});
  ProjectInformationKey.system(ProjectInformationSystemValue value)
    : space = ProjectInformationKeySpace.systemValue,
      id = value.storageKey;
  final ProjectInformationKeySpace space;
  final String id;
}

class ProjectInformationPin {
  const ProjectInformationPin({
    required this.id,
    required this.projectId,
    required this.key,
    required this.sortOrder,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceAvailable,
  });
  final String id;
  final String projectId;
  final ProjectInformationKey key;
  final int sortOrder;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final bool sourceAvailable;
}

class SetProjectInformationPinCommand {
  const SetProjectInformationPinCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.key,
  });
  final String id;
  final String eventId;
  final String projectId;
  final ProjectInformationKey key;
}

class ReorderProjectInformationPinsCommand {
  const ReorderProjectInformationPinsCommand({
    required this.eventId,
    required this.projectId,
    required this.orderedPinIds,
    required this.expectedRevisions,
  });
  final String eventId;
  final String projectId;
  final List<String> orderedPinIds;
  final Map<String, int> expectedRevisions;
}

class RemoveProjectInformationPinCommand {
  const RemoveProjectInformationPinCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.expectedRevision,
  });
  final String id;
  final String eventId;
  final String projectId;
  final int expectedRevision;
}

class ProjectInformationFailure implements Exception {
  const ProjectInformationFailure(this.code);
  final String code;
  @override
  String toString() => 'ProjectInformationFailure($code)';
}

class ProjectInformationRevisionConflict extends ProjectInformationFailure {
  const ProjectInformationRevisionConflict() : super('revision_conflict');
}
