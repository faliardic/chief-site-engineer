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
