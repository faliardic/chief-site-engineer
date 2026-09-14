import 'dart:convert';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/domain/project_information_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class ProjectInformationReadSource {
  Future<MobileProject> getProject(String projectId);

  Future<ProjectMetadata> getProjectMetadata(String projectId);

  Future<ProjectProfile> getProjectProfile(String projectId);

  Future<List<ProjectProfileEvent>> listProjectProfileEvents(String projectId);

  Future<List<ProjectPartyAssignment>> listProjectPartyAssignments(
    String projectId,
  );

  Future<List<Subcontractor>> listCompanies(String projectId);

  Future<List<WorkforceMember>> listWorkforceMembers(String projectId);

  Future<InventoryPrimarySketchProjection?> loadInventory(String projectId);

  Future<InventoryBlockMetadataRecord> loadBlockMetadata({
    required String projectId,
    required String blockId,
  });

  Future<List<MobileProjectLocation>> listLocations(String projectId);

  Future<List<ProjectFloorLocationRelation>> listFloorLocations(
    String projectId,
  );
}

class CanonicalProjectInformationReadSource
    implements ProjectInformationReadSource {
  const CanonicalProjectInformationReadSource({
    required this.projects,
    required this.metadata,
    required this.profiles,
    required this.parties,
    required this.projectLocations,
    required this.floorLocations,
    required this.attendance,
    required this.inventory,
    required this.blockMetadata,
  });

  final ProjectLifecycleApplication projects;
  final ProjectMetadataApplication metadata;
  final ProjectProfileApplication profiles;
  final ProjectPartyApplication parties;
  final ProjectLocationApplication projectLocations;
  final ProjectFloorLocationApplication floorLocations;
  final AttendanceApplication attendance;
  final InventoryApplicationPort inventory;
  final InventoryBlockMetadataApplicationPort blockMetadata;

  @override
  Future<MobileProject> getProject(String projectId) =>
      projects.getProject(projectId);

  @override
  Future<ProjectMetadata> getProjectMetadata(String projectId) =>
      metadata.getProjectMetadata(projectId);

  @override
  Future<ProjectProfile> getProjectProfile(String projectId) =>
      profiles.getProjectProfile(projectId);

  @override
  Future<List<ProjectProfileEvent>> listProjectProfileEvents(
    String projectId,
  ) => profiles.listProjectProfileEvents(projectId);

  @override
  Future<List<ProjectPartyAssignment>> listProjectPartyAssignments(
    String projectId,
  ) => parties.listProjectPartyAssignments(projectId);

  @override
  Future<List<Subcontractor>> listCompanies(String projectId) =>
      attendance.listSubcontractors(projectId, includeArchived: true);

  @override
  Future<List<WorkforceMember>> listWorkforceMembers(String projectId) =>
      attendance.listMembers(projectId, includeInactive: true);

  @override
  Future<InventoryPrimarySketchProjection?> loadInventory(String projectId) =>
      inventory.loadPrimarySketch(projectId);

  @override
  Future<InventoryBlockMetadataRecord> loadBlockMetadata({
    required String projectId,
    required String blockId,
  }) => blockMetadata.loadBlockMetadata(projectId: projectId, blockId: blockId);

  @override
  Future<List<MobileProjectLocation>> listLocations(String projectId) async {
    final results = await Future.wait([
      projectLocations.listProjectLocations(
        ProjectLocationQuery(projectId: projectId),
      ),
      projectLocations.listProjectLocations(
        ProjectLocationQuery(
          projectId: projectId,
          archiveFilter: ProjectLocationArchiveFilter.archived,
        ),
      ),
    ]);
    final byId = <String, MobileProjectLocation>{};
    for (final location in [...results[0], ...results[1]]) {
      if (byId.containsKey(location.id)) {
        throw const ProjectInformationSourceIntegrityFailure(
          'duplicate_location_id',
        );
      }
      byId[location.id] = location;
    }
    return byId.values.toList(growable: false);
  }

  @override
  Future<List<ProjectFloorLocationRelation>> listFloorLocations(
    String projectId,
  ) => floorLocations.listProjectFloorLocations(
    projectId,
    includeArchived: true,
  );
}

class ProjectInformationApplication {
  const ProjectInformationApplication({required this.source, this.mutations});

  final ProjectInformationReadSource source;
  final ProjectInformationMutationApplication? mutations;

  ProjectInformationSession createSession() =>
      ProjectInformationSession._(this);

  ProjectInformationMutationApplication get _mutations =>
      mutations ??
      (throw const ProjectInformationFailure('mutation_store_unavailable'));

  Future<List<ProjectInformationEntry>> listUserEntries(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter =
        ProjectInformationArchiveFilter.active,
  }) => _mutations.listUserEntries(projectId, archiveFilter: archiveFilter);

  /// Same result as calling [listUserEntries], [listPins] and
  /// [getSiteLocation] separately, but performed inside a single
  /// coordinator/database turn (Issue #823 Phase 1) instead of three. This
  /// is a pure read-count optimization: it returns semantically identical
  /// data and preserves the existing at-most-one-open-connection-per-turn
  /// contract; it is never a durable cache.
  Future<ProjectInformationCompanionReads> listCompanionReads(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter =
        ProjectInformationArchiveFilter.active,
  }) => _mutations.listCompanionReads(projectId, archiveFilter: archiveFilter);

  Future<ProjectInformationEntry> createUserEntry(
    CreateProjectInformationEntryCommand command,
  ) => _mutations.createUserEntry(command);

  Future<ProjectInformationEntry> updateUserEntry(
    UpdateProjectInformationEntryCommand command,
  ) => _mutations.updateUserEntry(command);

  Future<ProjectInformationEntry> setUserEntryArchived(
    SetProjectInformationEntryArchiveCommand command,
  ) => _mutations.setUserEntryArchived(command);

  Future<List<ProjectInformationPin>> listPins(String projectId) =>
      _mutations.listPins(projectId);

  Future<ProjectInformationPin> setPin(
    SetProjectInformationPinCommand command,
  ) => _mutations.setPin(command);

  Future<List<ProjectInformationPin>> reorderPins(
    ReorderProjectInformationPinsCommand command,
  ) => _mutations.reorderPins(command);

  Future<void> removePin(RemoveProjectInformationPinCommand command) =>
      _mutations.removePin(command);

  Future<ProjectSiteLocation?> getSiteLocation(String projectId) =>
      _mutations.getSiteLocation(projectId);

  Future<ProjectSiteLocation> setSiteLocation(
    SetProjectSiteLocationCommand command,
  ) => _mutations.setSiteLocation(command);

  Future<void> clearSiteLocation(ClearProjectSiteLocationCommand command) =>
      _mutations.clearSiteLocation(command);

  Future<ProjectInformationLoadResult> _loadProject({
    required String projectId,
    required int generation,
  }) async {
    final projectRead = await _capture(
      ProjectInformationSource.project,
      () async {
        final project = await source.getProject(projectId);
        _requireProject(project.id, projectId);
        return project;
      },
    );
    if (!projectRead.succeeded) {
      return ProjectInformationLoadFailure(
        projectId: projectId,
        generation: generation,
        failure: projectRead.status(recordCount: 0),
      );
    }
    final project = projectRead.value!;
    if (project.isArchived) {
      return ProjectInformationLoadFailure(
        projectId: projectId,
        generation: generation,
        failure: const ProjectInformationSourceStatus(
          source: ProjectInformationSource.project,
          state: ProjectInformationReadState.failed,
          recordCount: 1,
          errorCode: 'project_information_project_archived',
        ),
      );
    }

    final metadataPending = _capture(
      ProjectInformationSource.metadata,
      () async {
        final value = await source.getProjectMetadata(projectId);
        _requireProject(value.projectId, projectId);
        return value;
      },
    );
    final profilePending = _capture(ProjectInformationSource.profile, () async {
      final activeProfile = await source.getProjectProfile(projectId);
      final events = await source.listProjectProfileEvents(projectId);
      _requireProject(activeProfile.project.id, projectId);
      _requireAllProjectIds(
        activeProfile.fields.map((field) => field.projectId),
        projectId,
      );
      _requireAllProjectIds(events.map((event) => event.projectId), projectId);
      _requireUniqueIds(activeProfile.fields.map((field) => field.id));
      _requireUniqueIds(events.map((event) => event.id));
      return _mergeProfileLifecycle(activeProfile, events);
    });
    final partiesPending = _capture(ProjectInformationSource.parties, () async {
      final values = await source.listProjectPartyAssignments(projectId);
      _requireAllProjectIds(
        values.map((assignment) => assignment.projectId),
        projectId,
      );
      _requireUniqueIds(values.map((assignment) => assignment.id));
      _requireUniqueActiveRoles(values);
      return values;
    });
    final companiesPending = _capture(
      ProjectInformationSource.companies,
      () async {
        final values = await source.listCompanies(projectId);
        _requireAllProjectIds(
          values.map((value) => value.projectId),
          projectId,
        );
        _requireUniqueIds(values.map((value) => value.id));
        return values;
      },
    );
    final membersPending = _capture(
      ProjectInformationSource.workforceMembers,
      () async {
        final values = await source.listWorkforceMembers(projectId);
        _requireAllProjectIds(
          values.map((value) => value.projectId),
          projectId,
        );
        _requireUniqueIds(values.map((value) => value.id));
        return values;
      },
    );
    final inventoryPending = _capture(
      ProjectInformationSource.inventory,
      () async {
        final value = await source.loadInventory(projectId);
        if (value == null) return null;
        _requireProject(value.sketch.projectId, projectId);
        _requireAllProjectIds(
          value.blocks.map((block) => block.projectId),
          projectId,
        );
        _requireAllProjectIds(
          value.floors.map((floor) => floor.projectId),
          projectId,
        );
        _requireUniqueIds(value.blocks.map((block) => block.id));
        _requireUniqueIds(value.floors.map((floor) => floor.id));
        return value;
      },
    );
    final locationsPending = _capture(
      ProjectInformationSource.locations,
      () async {
        final values = await source.listLocations(projectId);
        _requireAllProjectIds(
          values.map((value) => value.projectId),
          projectId,
        );
        _requireUniqueIds(values.map((value) => value.id));
        return values;
      },
    );
    final floorLocationsPending = _capture(
      ProjectInformationSource.floorLocations,
      () async {
        final values = await source.listFloorLocations(projectId);
        _requireAllProjectIds(
          values.map((value) => value.projectId),
          projectId,
        );
        _requireUniqueIds(values.map((value) => value.id));
        _requireUniqueActiveLocationAssignments(values);
        return values;
      },
    );

    final metadataRead = await metadataPending;
    final profileRead = await profilePending;
    final partiesRead = await partiesPending;
    final companiesRead = await companiesPending;
    final membersRead = await membersPending;
    final inventoryRead = await inventoryPending;
    final locationsRead = await locationsPending;
    final floorLocationsRead = await floorLocationsPending;

    final profileFields = [...?profileRead.value?.fields]
      ..sort(_compareProfileFields);
    final assignments = [...?partiesRead.value]..sort(_compareParties);
    final companies = [...?companiesRead.value];
    final members = [...?membersRead.value];
    final companyById = {for (final company in companies) company.id: company};
    final memberById = {for (final member in members) member.id: member};
    final resolvedParties = assignments
        .map(
          (assignment) => _resolveParty(
            assignment,
            companyById: companyById,
            memberById: memberById,
            companiesAvailable: companiesRead.succeeded,
            membersAvailable: membersRead.succeeded,
          ),
        )
        .toList(growable: false);

    final inventoryProjection = inventoryRead.value;
    final blocks = [...?inventoryProjection?.blocks]..sort(_compareBlocks);
    final floors = [...?inventoryProjection?.floors]..sort(_compareFloors);
    final locations = [...?locationsRead.value]..sort(_compareLocations);
    final relations = [...?floorLocationsRead.value]
      ..sort(_compareFloorLocations);

    final metadataByBlock = <String, ProjectInformationBlockMetadata>{};
    var materializedBlockMetadataCount = 0;
    var blockMetadataFailureCount = 0;
    if (inventoryRead.succeeded && inventoryProjection != null) {
      final reads = await Future.wait(
        blocks.map(
          (block) => _capture(ProjectInformationSource.blockMetadata, () async {
            final value = await source.loadBlockMetadata(
              projectId: projectId,
              blockId: block.id,
            );
            _requireProject(value.projectId, projectId);
            if (value.blockId != block.id) {
              throw const ProjectInformationSourceIntegrityFailure(
                'cross_block_data',
              );
            }
            return value;
          }),
        ),
      );
      for (var index = 0; index < blocks.length; index++) {
        final read = reads[index];
        if (!read.succeeded) {
          blockMetadataFailureCount += 1;
          metadataByBlock[blocks[index].id] = ProjectInformationBlockMetadata(
            state: ProjectInformationBlockMetadataState.failed,
            errorCode: read.errorCode,
          );
          continue;
        }
        final value = read.value!;
        if (value.revision == 0) {
          metadataByBlock[blocks[index].id] =
              const ProjectInformationBlockMetadata(
                state: ProjectInformationBlockMetadataState.empty,
              );
        } else {
          materializedBlockMetadataCount += 1;
          metadataByBlock[blocks[index].id] = ProjectInformationBlockMetadata(
            state: ProjectInformationBlockMetadataState.loaded,
            value: value,
          );
        }
      }
    }

    final locationById = {
      for (final location in locations) location.id: location,
    };
    final relationsByFloor = <String, List<ProjectInformationFloorLocation>>{};
    final unresolvedRelations = <ProjectInformationUnresolvedFloorLocation>[];
    final floorIds = floors.map((floor) => floor.id).toSet();
    for (final relation in relations) {
      final location = locationById[relation.locationId];
      if (!floorIds.contains(relation.floorId)) {
        unresolvedRelations.add(
          ProjectInformationUnresolvedFloorLocation(
            relation: relation,
            location: location,
            reason: inventoryRead.succeeded
                ? ProjectInformationUnresolvedFloorLocationReason.missingFloor
                : ProjectInformationUnresolvedFloorLocationReason
                      .floorSourceUnavailable,
          ),
        );
        continue;
      }
      final state = !locationsRead.succeeded
          ? ProjectInformationFloorLocationState.sourceUnavailable
          : location == null
          ? ProjectInformationFloorLocationState.missingLocation
          : relation.isArchived
          ? ProjectInformationFloorLocationState.archivedRelation
          : location.isArchived
          ? ProjectInformationFloorLocationState.archivedLocation
          : ProjectInformationFloorLocationState.resolvedActive;
      relationsByFloor
          .putIfAbsent(relation.floorId, () => [])
          .add(
            ProjectInformationFloorLocation(
              relation: relation,
              location: location,
              state: state,
            ),
          );
      if (location == null) {
        unresolvedRelations.add(
          ProjectInformationUnresolvedFloorLocation(
            relation: relation,
            reason: locationsRead.succeeded
                ? ProjectInformationUnresolvedFloorLocationReason
                      .missingLocation
                : ProjectInformationUnresolvedFloorLocationReason
                      .locationSourceUnavailable,
          ),
        );
      }
    }
    for (final values in relationsByFloor.values) {
      values.sort(_compareResolvedFloorLocations);
    }

    final floorsByBlock = <String, List<ProjectInformationFloor>>{};
    final blockIds = blocks.map((block) => block.id).toSet();
    final unresolvedFloors = <InventoryFloorRecord>[];
    for (final floor in floors) {
      if (!blockIds.contains(floor.blockId)) {
        unresolvedFloors.add(floor);
        continue;
      }
      floorsByBlock
          .putIfAbsent(floor.blockId, () => [])
          .add(
            ProjectInformationFloor(
              floor: floor,
              locations: relationsByFloor[floor.id] ?? const [],
            ),
          );
    }
    final composedBlocks = blocks
        .map(
          (block) => ProjectInformationBlock(
            block: block,
            metadata:
                metadataByBlock[block.id] ??
                ProjectInformationBlockMetadata(
                  state: inventoryRead.succeeded
                      ? ProjectInformationBlockMetadataState.empty
                      : ProjectInformationBlockMetadataState.failed,
                  errorCode: inventoryRead.succeeded
                      ? null
                      : 'inventory_source_failed',
                ),
            floors: floorsByBlock[block.id] ?? const [],
          ),
        )
        .toList(growable: false);

    final finalProjectRead = await _capture(
      ProjectInformationSource.project,
      () async {
        final value = await source.getProject(projectId);
        _requireProject(value.id, projectId);
        return value;
      },
    );
    if (!finalProjectRead.succeeded) {
      return ProjectInformationLoadFailure(
        projectId: projectId,
        generation: generation,
        failure: finalProjectRead.status(recordCount: 0),
      );
    }
    final finalProject = finalProjectRead.value!;
    if (finalProject.isArchived || finalProject.revision != project.revision) {
      return ProjectInformationLoadFailure(
        projectId: projectId,
        generation: generation,
        failure: const ProjectInformationSourceStatus(
          source: ProjectInformationSource.project,
          state: ProjectInformationReadState.failed,
          recordCount: 1,
          errorCode: 'project_information_project_changed_during_read',
        ),
      );
    }

    final statuses = <ProjectInformationSourceStatus>[
      projectRead.status(recordCount: 1),
      metadataRead.status(
        recordCount:
            metadataRead.value == null || _metadataIsEmpty(metadataRead.value!)
            ? 0
            : 1,
      ),
      profileRead.status(
        recordCount: profileFields.where(_profileFieldHasValue).length,
      ),
      partiesRead.status(recordCount: assignments.length),
      companiesRead.status(recordCount: companies.length),
      membersRead.status(recordCount: members.length),
      inventoryRead.status(
        recordCount: inventoryProjection == null
            ? 0
            : blocks.length + floors.length,
      ),
      ProjectInformationSourceStatus(
        source: ProjectInformationSource.blockMetadata,
        state: !inventoryRead.succeeded || blockMetadataFailureCount > 0
            ? ProjectInformationReadState.failed
            : materializedBlockMetadataCount == 0
            ? ProjectInformationReadState.empty
            : ProjectInformationReadState.loaded,
        recordCount: materializedBlockMetadataCount,
        errorCode: !inventoryRead.succeeded
            ? 'inventory_source_failed'
            : blockMetadataFailureCount > 0
            ? 'partial_block_metadata_read_failed'
            : null,
      ),
      locationsRead.status(recordCount: locations.length),
      floorLocationsRead.status(recordCount: relations.length),
    ];

    return ProjectInformationReady(
      projectId: projectId,
      generation: generation,
      snapshot: ProjectInformationSnapshot(
        projectId: projectId,
        generation: generation,
        project: finalProject,
        metadata: metadataRead.value,
        profileFields: profileFields,
        parties: resolvedParties,
        blocks: composedBlocks,
        unresolvedFloors: unresolvedFloors,
        locations: locations,
        unresolvedFloorLocations: unresolvedRelations,
        derivedInventoryTotals: _deriveInventoryTotals(composedBlocks),
        sourceStatuses: statuses,
      ),
    );
  }
}

class ProjectInformationSession {
  ProjectInformationSession._(this._application);

  final ProjectInformationApplication _application;
  int _generation = 0;
  String? _projectId;

  String? get projectId => _projectId;

  int get generation => _generation;

  Future<ProjectInformationLoadResult> loadProject(String projectId) async {
    final generation = ++_generation;
    _projectId = projectId;
    final result = await _application._loadProject(
      projectId: projectId,
      generation: generation,
    );
    if (_generation != generation || _projectId != projectId) {
      return ProjectInformationSuperseded(
        projectId: projectId,
        generation: generation,
      );
    }
    return result;
  }

  void clearProject() {
    _generation += 1;
    _projectId = null;
  }
}

class ProjectInformationSourceIntegrityFailure implements Exception {
  const ProjectInformationSourceIntegrityFailure(this.code);

  final String code;
}

class _CapturedRead<T> {
  const _CapturedRead.success(this.source, this.value)
    : succeeded = true,
      errorCode = null;

  const _CapturedRead.failure(this.source, this.errorCode)
    : succeeded = false,
      value = null;

  final ProjectInformationSource source;
  final bool succeeded;
  final T? value;
  final String? errorCode;

  ProjectInformationSourceStatus status({required int recordCount}) =>
      ProjectInformationSourceStatus(
        source: source,
        state: !succeeded
            ? ProjectInformationReadState.failed
            : recordCount == 0
            ? ProjectInformationReadState.empty
            : ProjectInformationReadState.loaded,
        recordCount: recordCount,
        errorCode: errorCode,
      );
}

Future<_CapturedRead<T>> _capture<T>(
  ProjectInformationSource source,
  Future<T> Function() read,
) async {
  try {
    return _CapturedRead.success(source, await read());
  } on ProjectInformationSourceIntegrityFailure catch (error) {
    return _CapturedRead.failure(source, error.code);
  } on InventoryFailure catch (error) {
    return _CapturedRead.failure(source, error.code);
  } on AgendaValidationFailure {
    return _CapturedRead.failure(source, 'agenda_read_failed');
  } on Object {
    return _CapturedRead.failure(source, 'source_read_failed');
  }
}

void _requireProject(String actual, String expected) {
  if (actual != expected) {
    throw const ProjectInformationSourceIntegrityFailure('cross_project_data');
  }
}

void _requireAllProjectIds(Iterable<String> values, String expected) {
  for (final value in values) {
    _requireProject(value, expected);
  }
}

void _requireUniqueIds(Iterable<String> values) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw const ProjectInformationSourceIntegrityFailure(
        'duplicate_source_identity',
      );
    }
  }
}

void _requireUniqueActiveRoles(List<ProjectPartyAssignment> assignments) {
  final seen = <ProjectPartyRole>{};
  for (final assignment in assignments.where((value) => !value.isArchived)) {
    if (!seen.add(assignment.role)) {
      throw const ProjectInformationSourceIntegrityFailure(
        'duplicate_active_party_role',
      );
    }
  }
}

void _requireUniqueActiveLocationAssignments(
  List<ProjectFloorLocationRelation> relations,
) {
  final seen = <String>{};
  for (final relation in relations.where((value) => !value.isArchived)) {
    if (!seen.add(relation.locationId)) {
      throw const ProjectInformationSourceIntegrityFailure(
        'duplicate_active_location_assignment',
      );
    }
  }
}

ProjectInformationParty _resolveParty(
  ProjectPartyAssignment assignment, {
  required Map<String, Subcontractor> companyById,
  required Map<String, WorkforceMember> memberById,
  required bool companiesAvailable,
  required bool membersAvailable,
}) {
  if (assignment.role.usesCompany) {
    if (assignment.subcontractorId == null ||
        assignment.workforceMemberId != null) {
      return ProjectInformationParty(
        assignment: assignment,
        targetState: ProjectInformationPartyTargetState.invalidAssignment,
      );
    }
    if (!companiesAvailable) {
      return ProjectInformationParty(
        assignment: assignment,
        targetState: ProjectInformationPartyTargetState.sourceUnavailable,
      );
    }
    final company = companyById[assignment.subcontractorId];
    return ProjectInformationParty(
      assignment: assignment,
      company: company,
      targetState: company == null
          ? ProjectInformationPartyTargetState.missing
          : company.isActive
          ? ProjectInformationPartyTargetState.resolvedActive
          : ProjectInformationPartyTargetState.resolvedArchived,
    );
  }
  if (assignment.workforceMemberId == null ||
      assignment.subcontractorId != null) {
    return ProjectInformationParty(
      assignment: assignment,
      targetState: ProjectInformationPartyTargetState.invalidAssignment,
    );
  }
  if (!membersAvailable) {
    return ProjectInformationParty(
      assignment: assignment,
      targetState: ProjectInformationPartyTargetState.sourceUnavailable,
    );
  }
  final member = memberById[assignment.workforceMemberId];
  return ProjectInformationParty(
    assignment: assignment,
    workforceMember: member,
    targetState: member == null
        ? ProjectInformationPartyTargetState.missing
        : member.isActive
        ? ProjectInformationPartyTargetState.resolvedActive
        : ProjectInformationPartyTargetState.resolvedArchived,
  );
}

ProjectInformationDerivedInventoryTotals _deriveInventoryTotals(
  List<ProjectInformationBlock> blocks,
) {
  final active = blocks
      .where(
        (entry) =>
            entry.block.state == InventoryBlockState.active &&
            entry.block.archivedAt == null,
      )
      .toList(growable: false);
  final detached = blocks.where(
    (entry) => entry.block.state == InventoryBlockState.detached,
  );
  final archived = blocks.where(
    (entry) =>
        entry.block.state == InventoryBlockState.archived ||
        entry.block.archivedAt != null,
  );
  final activeFloorCount = active.fold<int>(
    0,
    (sum, entry) =>
        sum +
        entry.floors.where((floor) => floor.floor.archivedAt == null).length,
  );
  if (active.isEmpty) {
    return ProjectInformationDerivedInventoryTotals(
      activeBlockCount: 0,
      detachedBlockCount: detached.length,
      archivedBlockCount: archived.length,
      activeFloorCount: activeFloorCount,
      areaState: ProjectInformationDerivedAreaState.unavailable,
    );
  }
  final values = <(double, String)>[];
  for (final entry in active) {
    final metadata = entry.metadata.value;
    final unit = metadata?.totalAreaUnit?.trim();
    if (entry.metadata.state != ProjectInformationBlockMetadataState.loaded ||
        metadata?.totalArea == null ||
        unit == null ||
        unit.isEmpty) {
      return ProjectInformationDerivedInventoryTotals(
        activeBlockCount: active.length,
        detachedBlockCount: detached.length,
        archivedBlockCount: archived.length,
        activeFloorCount: activeFloorCount,
        areaState: ProjectInformationDerivedAreaState.incomplete,
      );
    }
    values.add((metadata!.totalArea!, unit));
  }
  final unit = values.first.$2;
  if (values.any((value) => value.$2 != unit)) {
    return ProjectInformationDerivedInventoryTotals(
      activeBlockCount: active.length,
      detachedBlockCount: detached.length,
      archivedBlockCount: archived.length,
      activeFloorCount: activeFloorCount,
      areaState: ProjectInformationDerivedAreaState.mixedUnits,
    );
  }
  return ProjectInformationDerivedInventoryTotals(
    activeBlockCount: active.length,
    detachedBlockCount: detached.length,
    archivedBlockCount: archived.length,
    activeFloorCount: activeFloorCount,
    areaState: ProjectInformationDerivedAreaState.available,
    totalArea: values.fold<double>(0, (sum, value) => sum + value.$1),
    totalAreaUnit: unit,
  );
}

bool _metadataIsEmpty(ProjectMetadata value) =>
    value.revision == 0 &&
    value.address == null &&
    value.permitNumber == null &&
    value.permitDate == null &&
    value.cadastralBlock == null &&
    value.cadastralParcel == null &&
    value.projectStartDate == null &&
    value.targetFinishDate == null &&
    value.usageType == null &&
    value.structuralSystem == null;

bool _profileFieldHasValue(ProjectProfileField value) =>
    value.revision > 0 || value.value.trim().isNotEmpty || !value.isBuiltIn;

ProjectProfile _mergeProfileLifecycle(
  ProjectProfile activeProfile,
  List<ProjectProfileEvent> events,
) {
  if (activeProfile.fields.any((field) => field.isArchived)) {
    throw StateError('project_profile_active_reader_returned_archived_field');
  }
  final activeById = {
    for (final field in activeProfile.fields) field.id: field,
  };
  final replay = <String, ProjectProfileField>{};
  var expectedSequence = 1;

  for (final event in events) {
    if (event.sequence != expectedSequence) {
      throw StateError('project_profile_event_sequence_invalid');
    }
    expectedSequence += 1;
    final payload = _profileEventPayload(event);
    switch (event.eventType) {
      case ProjectProfileEventType.fieldCreated:
        final fieldId = _requiredProfileEventFieldId(event);
        if (replay.containsKey(fieldId)) {
          throw StateError('project_profile_field_created_twice');
        }
        replay[fieldId] = ProjectProfileField(
          id: fieldId,
          projectId: event.projectId,
          label: _requiredEventString(payload, 'label'),
          value: _requiredEventString(payload, 'value', allowEmpty: true),
          sortOrder: _requiredEventInt(payload, 'sort_order', minimum: 0),
          revision: 1,
          createdAt: event.occurredAt,
          updatedAt: event.occurredAt,
        );
      case ProjectProfileEventType.fieldUpdated:
        final fieldId = _requiredProfileEventFieldId(event);
        final current = replay[fieldId];
        if (current == null) {
          final active = activeById[fieldId];
          if (active != null && active.isBuiltIn) break;
          throw StateError('project_profile_field_update_without_create');
        }
        final revisionBefore = _requiredEventInt(
          payload,
          'revision_before',
          minimum: 1,
        );
        final revisionAfter = _requiredEventInt(
          payload,
          'revision_after',
          minimum: 2,
        );
        if (current.revision != revisionBefore ||
            revisionAfter != revisionBefore + 1 ||
            current.isArchived) {
          throw StateError('project_profile_field_update_revision_invalid');
        }
        replay[fieldId] = _copyProfileField(
          current,
          label: _requiredEventString(payload, 'new_label'),
          nextValue: _requiredEventString(
            payload,
            'new_value',
            allowEmpty: true,
          ),
          revision: revisionAfter,
          updatedAt: event.occurredAt,
        );
      case ProjectProfileEventType.fieldArchived:
      case ProjectProfileEventType.fieldRestored:
        final fieldId = _requiredProfileEventFieldId(event);
        final current = replay[fieldId];
        if (current == null || current.isBuiltIn) {
          throw StateError('project_profile_archive_without_custom_field');
        }
        final revisionBefore = _requiredEventInt(
          payload,
          'revision_before',
          minimum: 1,
        );
        final revisionAfter = _requiredEventInt(
          payload,
          'revision_after',
          minimum: 2,
        );
        final wasArchived = _requiredEventBool(payload, 'was_archived');
        final isArchived = _requiredEventBool(payload, 'is_archived');
        final expectedArchived =
            event.eventType == ProjectProfileEventType.fieldArchived;
        if (current.revision != revisionBefore ||
            revisionAfter != revisionBefore + 1 ||
            current.isArchived != wasArchived ||
            isArchived != expectedArchived) {
          throw StateError('project_profile_archive_revision_invalid');
        }
        replay[fieldId] = _copyProfileField(
          current,
          sortOrder: _requiredEventInt(payload, 'sort_order', minimum: 0),
          revision: revisionAfter,
          updatedAt: event.occurredAt,
          archivedAt: isArchived ? event.occurredAt : null,
          replaceArchivedAt: true,
        );
      case ProjectProfileEventType.fieldsReordered:
        if (event.fieldId != null) {
          throw StateError('project_profile_reorder_field_id_invalid');
        }
        final newOrder = _requiredEventStringList(payload, 'new_order');
        if (newOrder.toSet().length != newOrder.length) {
          throw StateError('project_profile_reorder_contains_duplicates');
        }
        for (final entry in replay.entries.toList(growable: false)) {
          final current = entry.value;
          if (current.isArchived) continue;
          final nextOrder = newOrder.indexOf(entry.key);
          if (nextOrder < 0) {
            throw StateError('project_profile_reorder_missing_custom_field');
          }
          if (current.sortOrder == nextOrder) continue;
          replay[entry.key] = _copyProfileField(
            current,
            sortOrder: nextOrder,
            revision: current.revision + 1,
            updatedAt: event.occurredAt,
          );
        }
    }
  }

  for (final field in replay.values.where((field) => !field.isArchived)) {
    final active = activeById[field.id];
    if (active == null || active.isBuiltIn) {
      throw StateError('project_profile_active_custom_field_missing');
    }
  }
  final archived = replay.values.where((field) => field.isArchived).toList();
  if (archived.any((field) => activeById.containsKey(field.id))) {
    throw StateError('project_profile_archived_field_reported_active');
  }
  return ProjectProfile(
    project: activeProfile.project,
    fields: List.unmodifiable([...activeProfile.fields, ...archived]),
  );
}

Map<String, dynamic> _profileEventPayload(ProjectProfileEvent event) {
  final decoded = jsonDecode(event.payloadJson);
  if (decoded is! Map<String, dynamic>) {
    throw StateError('project_profile_event_payload_invalid');
  }
  return decoded;
}

String _requiredProfileEventFieldId(ProjectProfileEvent event) {
  final value = event.fieldId;
  if (value == null || value.isEmpty) {
    throw StateError('project_profile_event_field_id_missing');
  }
  return value;
}

String _requiredEventString(
  Map<String, dynamic> payload,
  String key, {
  bool allowEmpty = false,
}) {
  final value = payload[key];
  if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
    throw StateError('project_profile_event_${key}_invalid');
  }
  return value;
}

int _requiredEventInt(
  Map<String, dynamic> payload,
  String key, {
  required int minimum,
}) {
  final value = payload[key];
  if (value is! int || value < minimum) {
    throw StateError('project_profile_event_${key}_invalid');
  }
  return value;
}

bool _requiredEventBool(Map<String, dynamic> payload, String key) {
  final value = payload[key];
  if (value is! bool) {
    throw StateError('project_profile_event_${key}_invalid');
  }
  return value;
}

List<String> _requiredEventStringList(
  Map<String, dynamic> payload,
  String key,
) {
  final value = payload[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw StateError('project_profile_event_${key}_invalid');
  }
  return value.cast<String>();
}

ProjectProfileField _copyProfileField(
  ProjectProfileField value, {
  String? label,
  String? nextValue,
  int? sortOrder,
  int? revision,
  String? updatedAt,
  String? archivedAt,
  bool replaceArchivedAt = false,
}) => ProjectProfileField(
  id: value.id,
  projectId: value.projectId,
  builtinField: value.builtinField,
  label: label ?? value.label,
  value: nextValue ?? value.value,
  sortOrder: sortOrder ?? value.sortOrder,
  revision: revision ?? value.revision,
  createdAt: value.createdAt,
  updatedAt: updatedAt ?? value.updatedAt,
  archivedAt: replaceArchivedAt ? archivedAt : value.archivedAt,
);

int _compareProfileFields(ProjectProfileField left, ProjectProfileField right) {
  final order = left.sortOrder.compareTo(right.sortOrder);
  return order != 0 ? order : left.id.compareTo(right.id);
}

int _compareParties(ProjectPartyAssignment left, ProjectPartyAssignment right) {
  final role = left.role.index.compareTo(right.role.index);
  return role != 0 ? role : left.id.compareTo(right.id);
}

int _compareBlocks(InventoryBlockRecord left, InventoryBlockRecord right) {
  final order = left.ordinal.compareTo(right.ordinal);
  return order != 0 ? order : left.id.compareTo(right.id);
}

int _compareFloors(InventoryFloorRecord left, InventoryFloorRecord right) {
  final block = left.blockId.compareTo(right.blockId);
  if (block != 0) return block;
  final order = left.ordinal.compareTo(right.ordinal);
  return order != 0 ? order : left.id.compareTo(right.id);
}

int _compareLocations(MobileProjectLocation left, MobileProjectLocation right) {
  final name = _compareText(left.displayName, right.displayName);
  return name != 0 ? name : left.id.compareTo(right.id);
}

int _compareFloorLocations(
  ProjectFloorLocationRelation left,
  ProjectFloorLocationRelation right,
) {
  final floor = left.floorId.compareTo(right.floorId);
  if (floor != 0) return floor;
  final location = left.locationId.compareTo(right.locationId);
  return location != 0 ? location : left.id.compareTo(right.id);
}

int _compareResolvedFloorLocations(
  ProjectInformationFloorLocation left,
  ProjectInformationFloorLocation right,
) {
  final leftName = left.location?.displayName ?? '';
  final rightName = right.location?.displayName ?? '';
  final name = _compareText(leftName, rightName);
  return name != 0 ? name : left.relation.id.compareTo(right.relation.id);
}

int _compareText(String left, String right) {
  final folded = left.toLowerCase().compareTo(right.toLowerCase());
  return folded != 0 ? folded : left.compareTo(right);
}

/// Combined result of [ProjectInformationMutationApplication.listCompanionReads]
/// — semantically identical to calling `listUserEntries`, `listPins` and
/// `getSiteLocation` separately.
class ProjectInformationCompanionReads {
  const ProjectInformationCompanionReads({
    required this.userEntries,
    required this.pins,
    required this.siteLocation,
  });

  final List<ProjectInformationEntry> userEntries;
  final List<ProjectInformationPin> pins;
  final ProjectSiteLocation? siteLocation;
}

abstract interface class ProjectInformationMutationApplication {
  Future<List<ProjectInformationEntry>> listUserEntries(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter,
  });

  /// See [ProjectInformationApplication.listCompanionReads].
  Future<ProjectInformationCompanionReads> listCompanionReads(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter,
  });
  Future<ProjectInformationEntry> createUserEntry(
    CreateProjectInformationEntryCommand command,
  );
  Future<ProjectInformationEntry> updateUserEntry(
    UpdateProjectInformationEntryCommand command,
  );
  Future<ProjectInformationEntry> setUserEntryArchived(
    SetProjectInformationEntryArchiveCommand command,
  );
  Future<List<ProjectInformationPin>> listPins(String projectId);
  Future<ProjectInformationPin> setPin(SetProjectInformationPinCommand command);
  Future<List<ProjectInformationPin>> reorderPins(
    ReorderProjectInformationPinsCommand command,
  );
  Future<void> removePin(RemoveProjectInformationPinCommand command);

  Future<ProjectSiteLocation?> getSiteLocation(String projectId);
  Future<ProjectSiteLocation> setSiteLocation(
    SetProjectSiteLocationCommand command,
  );
  Future<void> clearSiteLocation(ClearProjectSiteLocationCommand command);
}

class SqliteProjectInformationMutationApplication
    implements ProjectInformationMutationApplication {
  SqliteProjectInformationMutationApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.clock,
    MobileOperationCoordinator? coordinator,
  }) : coordinator = coordinator ?? MobileOperationCoordinator();

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;
  final MobileOperationCoordinator coordinator;

  @override
  Future<List<ProjectInformationEntry>> listUserEntries(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter =
        ProjectInformationArchiveFilter.active,
  }) {
    _requireUuid(projectId, 'invalid_project_id');
    return _withDatabase((database, _) async {
      final archiveClause = switch (archiveFilter) {
        ProjectInformationArchiveFilter.active => 'archived_at IS NULL',
        ProjectInformationArchiveFilter.archived => 'archived_at IS NOT NULL',
        ProjectInformationArchiveFilter.all => '1 = 1',
      };
      final rows = await database.query(
        'project_information_entries',
        where: 'project_id = ? AND $archiveClause',
        whereArgs: [projectId],
        orderBy: 'category ASC, label COLLATE NOCASE ASC, id ASC',
      );
      return rows.map(_entryFromRow).toList(growable: false);
    });
  }

  @override
  Future<ProjectInformationEntry> createUserEntry(
    CreateProjectInformationEntryCommand command,
  ) {
    _requireUuid(command.id, 'invalid_entry_id');
    _requireUuid(command.eventId, 'invalid_event_id');
    _requireUuid(command.projectId, 'invalid_project_id');
    final values = _validatedEntryValues(
      category: command.category,
      label: command.label,
      value: command.value,
      unit: command.unit,
      note: command.note,
    );
    return _withDatabase(
      (database, timestamp) => database.transaction((transaction) async {
        await _requireActiveProject(transaction, command.projectId);
        await _validateContactReference(transaction, command.projectId, values);
        try {
          await transaction.insert('project_information_entries', {
            'id': command.id,
            'project_id': command.projectId,
            ...values,
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
          });
          await _insertEntryEvent(
            transaction,
            id: command.eventId,
            entryId: command.id,
            projectId: command.projectId,
            sequence: 1,
            eventType: 'entry.created',
            occurredAt: timestamp,
          );
        } on DatabaseException catch (error) {
          throw ProjectInformationFailure(
            error.isUniqueConstraintError()
                ? 'duplicate_identity'
                : 'constraint_violation',
          );
        }
        return _loadEntry(transaction, command.projectId, command.id);
      }),
    );
  }

  @override
  Future<ProjectInformationEntry> updateUserEntry(
    UpdateProjectInformationEntryCommand command,
  ) {
    _requireUuid(command.id, 'invalid_entry_id');
    _requireUuid(command.eventId, 'invalid_event_id');
    _requireUuid(command.projectId, 'invalid_project_id');
    if (command.expectedRevision < 1) {
      throw const ProjectInformationFailure('invalid_expected_revision');
    }
    final values = _validatedEntryValues(
      category: command.category,
      label: command.label,
      value: command.value,
      unit: command.unit,
      note: command.note,
    );
    return _withDatabase(
      (database, timestamp) => database.transaction((transaction) async {
        final current = await _loadEntry(
          transaction,
          command.projectId,
          command.id,
        );
        if (current.revision != command.expectedRevision) {
          throw const ProjectInformationRevisionConflict();
        }
        if (current.category != command.category ||
            current.value.kind != command.value.kind) {
          throw const ProjectInformationFailure('entry_semantics_immutable');
        }
        await _validateContactReference(transaction, command.projectId, values);
        final changed = await transaction.update(
          'project_information_entries',
          {
            ...values,
            'revision': current.revision + 1,
            'updated_at': timestamp,
          },
          where: 'id = ? AND project_id = ? AND revision = ?',
          whereArgs: [command.id, command.projectId, command.expectedRevision],
        );
        if (changed != 1) throw const ProjectInformationRevisionConflict();
        await _insertEntryEvent(
          transaction,
          id: command.eventId,
          entryId: command.id,
          projectId: command.projectId,
          sequence: current.revision + 1,
          eventType: 'entry.updated',
          occurredAt: timestamp,
        );
        return _loadEntry(transaction, command.projectId, command.id);
      }),
    );
  }

  @override
  Future<ProjectInformationEntry> setUserEntryArchived(
    SetProjectInformationEntryArchiveCommand command,
  ) {
    _requireUuid(command.id, 'invalid_entry_id');
    _requireUuid(command.eventId, 'invalid_event_id');
    _requireUuid(command.projectId, 'invalid_project_id');
    return _withDatabase(
      (database, timestamp) => database.transaction((transaction) async {
        final current = await _loadEntry(
          transaction,
          command.projectId,
          command.id,
        );
        if (current.revision != command.expectedRevision) {
          throw const ProjectInformationRevisionConflict();
        }
        if (current.isArchived == command.archived) return current;
        await transaction.update(
          'project_information_entries',
          {
            'revision': current.revision + 1,
            'updated_at': timestamp,
            'archived_at': command.archived ? timestamp : null,
          },
          where: 'id = ? AND project_id = ? AND revision = ?',
          whereArgs: [command.id, command.projectId, command.expectedRevision],
        );
        await _insertEntryEvent(
          transaction,
          id: command.eventId,
          entryId: command.id,
          projectId: command.projectId,
          sequence: current.revision + 1,
          eventType: command.archived ? 'entry.archived' : 'entry.restored',
          occurredAt: timestamp,
        );
        return _loadEntry(transaction, command.projectId, command.id);
      }),
    );
  }

  @override
  Future<List<ProjectInformationPin>> listPins(String projectId) {
    _requireUuid(projectId, 'invalid_project_id');
    return _withDatabase((database, _) async {
      final rows = await database.query(
        'project_information_pins',
        where: 'project_id = ? AND archived_at IS NULL',
        whereArgs: [projectId],
        orderBy: 'sort_order ASC, id ASC',
      );
      final result = <ProjectInformationPin>[];
      for (final row in rows) {
        result.add(
          _pinFromRow(
            row,
            await _sourceAvailable(
              database,
              projectId,
              row['source_space']! as String,
              row['source_id']! as String,
            ),
          ),
        );
      }
      return List.unmodifiable(result);
    });
  }

  @override
  Future<ProjectInformationPin> setPin(
    SetProjectInformationPinCommand command,
  ) {
    _requireUuid(command.id, 'invalid_pin_id');
    _requireUuid(command.eventId, 'invalid_event_id');
    _requireUuid(command.projectId, 'invalid_project_id');
    final sourceId = _required(command.key.id, 'invalid_source_id', 240);
    final sourceSpace = _keySpaceToDb(command.key.space);
    return _withDatabase(
      (database, timestamp) => database.transaction((transaction) async {
        await _requireActiveProject(transaction, command.projectId);
        if (!await _sourceAvailable(
          transaction,
          command.projectId,
          sourceSpace,
          sourceId,
        )) {
          throw const ProjectInformationFailure('pin_source_unavailable');
        }
        final matches = await transaction.query(
          'project_information_pins',
          where: 'project_id = ? AND source_space = ? AND source_id = ?',
          whereArgs: [command.projectId, sourceSpace, sourceId],
          orderBy: 'created_at ASC, id ASC',
        );
        final active = matches
            .where((row) => row['archived_at'] == null)
            .toList();
        if (active.isNotEmpty) {
          if (active.single['id'] != command.id) {
            throw const ProjectInformationFailure('duplicate_active_pin');
          }
          return _pinFromRow(active.single, true);
        }
        if (matches.isNotEmpty) {
          final row = matches.last;
          if (row['id'] != command.id) {
            throw const ProjectInformationFailure('pin_identity_mismatch');
          }
          final revision = row['revision']! as int;
          final nextOrder = await _nextPinOrder(transaction, command.projectId);
          await transaction.update(
            'project_information_pins',
            {
              'sort_order': nextOrder,
              'revision': revision + 1,
              'updated_at': timestamp,
              'archived_at': null,
            },
            where: 'id = ? AND project_id = ? AND revision = ?',
            whereArgs: [command.id, command.projectId, revision],
          );
          await _insertPinEvent(
            transaction,
            '${command.eventId}:${command.id}',
            command.id,
            command.projectId,
            revision + 1,
            'pin.restored',
            timestamp,
          );
        } else {
          await transaction.insert('project_information_pins', {
            'id': command.id,
            'project_id': command.projectId,
            'source_space': sourceSpace,
            'source_id': sourceId,
            'sort_order': await _nextPinOrder(transaction, command.projectId),
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
          });
          await _insertPinEvent(
            transaction,
            command.eventId,
            command.id,
            command.projectId,
            1,
            'pin.created',
            timestamp,
          );
        }
        final row = (await transaction.query(
          'project_information_pins',
          where: 'id = ? AND project_id = ?',
          whereArgs: [command.id, command.projectId],
          limit: 1,
        )).single;
        return _pinFromRow(row, true);
      }),
    );
  }

  @override
  Future<List<ProjectInformationPin>> reorderPins(
    ReorderProjectInformationPinsCommand command,
  ) {
    _requireUuid(command.eventId, 'invalid_event_id');
    _requireUuid(command.projectId, 'invalid_project_id');
    return _withDatabase(
      (database, timestamp) => database.transaction((transaction) async {
        final rows = await transaction.query(
          'project_information_pins',
          where: 'project_id = ? AND archived_at IS NULL',
          whereArgs: [command.projectId],
          orderBy: 'sort_order ASC, id ASC',
        );
        final ids = rows.map((row) => row['id']! as String).toSet();
        if (command.orderedPinIds.length != ids.length ||
            command.orderedPinIds.toSet().length != ids.length ||
            !command.orderedPinIds.toSet().containsAll(ids)) {
          throw const ProjectInformationFailure(
            'pin_order_must_cover_active_set',
          );
        }
        if (command.expectedRevisions.keys.toSet().length != ids.length ||
            !command.expectedRevisions.keys.toSet().containsAll(ids)) {
          throw const ProjectInformationFailure('pin_revision_set_mismatch');
        }
        final byId = {for (final row in rows) row['id']! as String: row};
        for (var index = 0; index < command.orderedPinIds.length; index++) {
          final id = command.orderedPinIds[index];
          final row = byId[id]!;
          final revision = row['revision']! as int;
          if (command.expectedRevisions[id] != revision) {
            throw const ProjectInformationRevisionConflict();
          }
          if (row['sort_order'] == index) continue;
          final changed = await transaction.update(
            'project_information_pins',
            {
              'sort_order': index,
              'revision': revision + 1,
              'updated_at': timestamp,
            },
            where: 'id = ? AND project_id = ? AND revision = ?',
            whereArgs: [id, command.projectId, revision],
          );
          if (changed != 1) throw const ProjectInformationRevisionConflict();
          await _insertPinEvent(
            transaction,
            '${command.eventId}:$id',
            id,
            command.projectId,
            revision + 1,
            'pin.reordered',
            timestamp,
          );
        }
        return listPinsInTransaction(transaction, command.projectId);
      }),
    );
  }

  @override
  Future<void> removePin(RemoveProjectInformationPinCommand command) {
    _requireUuid(command.id, 'invalid_pin_id');
    _requireUuid(command.eventId, 'invalid_event_id');
    _requireUuid(command.projectId, 'invalid_project_id');
    return _withDatabase(
      (database, timestamp) => database.transaction((transaction) async {
        final rows = await transaction.query(
          'project_information_pins',
          where: 'id = ? AND project_id = ? AND archived_at IS NULL',
          whereArgs: [command.id, command.projectId],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw const ProjectInformationFailure('pin_not_found');
        }
        final revision = rows.single['revision']! as int;
        if (revision != command.expectedRevision) {
          throw const ProjectInformationRevisionConflict();
        }
        final changed = await transaction.update(
          'project_information_pins',
          {
            'revision': revision + 1,
            'updated_at': timestamp,
            'archived_at': timestamp,
          },
          where: 'id = ? AND project_id = ? AND revision = ?',
          whereArgs: [command.id, command.projectId, revision],
        );
        if (changed != 1) throw const ProjectInformationRevisionConflict();
        await _insertPinEvent(
          transaction,
          command.eventId,
          command.id,
          command.projectId,
          revision + 1,
          'pin.removed',
          timestamp,
        );
      }),
    );
  }

  @override
  Future<ProjectSiteLocation?> getSiteLocation(String projectId) {
    _requireUuid(projectId, 'invalid_project_id');
    return _withDatabase((database, _) async {
      final rows = await database.query(
        'project_site_locations',
        where: 'project_id = ? AND cleared_at IS NULL',
        whereArgs: [projectId],
        limit: 1,
      );
      return rows.isEmpty ? null : _siteLocationFromRow(rows.single);
    });
  }

  @override
  Future<ProjectInformationCompanionReads> listCompanionReads(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter =
        ProjectInformationArchiveFilter.active,
  }) {
    _requireUuid(projectId, 'invalid_project_id');
    return _withDatabase((database, _) async {
      final archiveClause = switch (archiveFilter) {
        ProjectInformationArchiveFilter.active => 'archived_at IS NULL',
        ProjectInformationArchiveFilter.archived => 'archived_at IS NOT NULL',
        ProjectInformationArchiveFilter.all => '1 = 1',
      };
      final entryRows = await database.query(
        'project_information_entries',
        where: 'project_id = ? AND $archiveClause',
        whereArgs: [projectId],
        orderBy: 'category ASC, label COLLATE NOCASE ASC, id ASC',
      );
      final entries = entryRows.map(_entryFromRow).toList(growable: false);

      final pinRows = await database.query(
        'project_information_pins',
        where: 'project_id = ? AND archived_at IS NULL',
        whereArgs: [projectId],
        orderBy: 'sort_order ASC, id ASC',
      );
      final pins = <ProjectInformationPin>[];
      for (final row in pinRows) {
        pins.add(
          _pinFromRow(
            row,
            await _sourceAvailable(
              database,
              projectId,
              row['source_space']! as String,
              row['source_id']! as String,
            ),
          ),
        );
      }

      final locationRows = await database.query(
        'project_site_locations',
        where: 'project_id = ? AND cleared_at IS NULL',
        whereArgs: [projectId],
        limit: 1,
      );
      final siteLocation = locationRows.isEmpty
          ? null
          : _siteLocationFromRow(locationRows.single);

      return ProjectInformationCompanionReads(
        userEntries: entries,
        pins: List.unmodifiable(pins),
        siteLocation: siteLocation,
      );
    });
  }

  @override
  Future<ProjectSiteLocation> setSiteLocation(
    SetProjectSiteLocationCommand command,
  ) async {
    _requireUuid(command.eventId, 'invalid_event_id');
    _requireUuid(command.projectId, 'invalid_project_id');
    if (!command.latitude.isFinite ||
        command.latitude < -90 ||
        command.latitude > 90 ||
        !command.longitude.isFinite ||
        command.longitude < -180 ||
        command.longitude > 180) {
      throw const ProjectInformationFailure('invalid_site_location');
    }
    return _withDatabase(
      (database, timestamp) => database.transaction((transaction) async {
        await _requireActiveProject(transaction, command.projectId);
        final rows = await transaction.query(
          'project_site_locations',
          where: 'project_id = ?',
          whereArgs: [command.projectId],
          limit: 1,
        );
        if (rows.isEmpty) {
          if (command.expectedRevision != null) {
            throw const ProjectInformationRevisionConflict();
          }
          await transaction.insert('project_site_locations', {
            'project_id': command.projectId,
            'latitude': command.latitude,
            'longitude': command.longitude,
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
            'cleared_at': null,
          });
          await _insertSiteLocationEvent(
            transaction,
            id: command.eventId,
            projectId: command.projectId,
            sequence: 1,
            eventType: 'site_location.set',
            occurredAt: timestamp,
          );
        } else {
          // The row's identity (project_id) is stable even after a clear —
          // `cleared_at` only marks it inactive, it is never physically
          // deleted. A clear leaves this branch active on the next save, so
          // a cleared row is treated as a fresh first-set (no
          // expectedRevision) that resurrects the same row via UPDATE
          // instead of INSERT, rather than a stale-revision conflict.
          final currentRevision = rows.single['revision']! as int;
          final wasCleared = rows.single['cleared_at'] != null;
          final expectedRevisionForActiveRow = wasCleared
              ? null
              : currentRevision;
          if (command.expectedRevision != expectedRevisionForActiveRow) {
            throw const ProjectInformationRevisionConflict();
          }
          final changed = await transaction.update(
            'project_site_locations',
            {
              'latitude': command.latitude,
              'longitude': command.longitude,
              'revision': currentRevision + 1,
              'updated_at': timestamp,
              'cleared_at': null,
            },
            where: 'project_id = ? AND revision = ?',
            whereArgs: [command.projectId, currentRevision],
          );
          if (changed != 1) {
            throw const ProjectInformationRevisionConflict();
          }
          await _insertSiteLocationEvent(
            transaction,
            id: command.eventId,
            projectId: command.projectId,
            sequence: currentRevision + 1,
            eventType: wasCleared
                ? 'site_location.set'
                : 'site_location.updated',
            occurredAt: timestamp,
          );
        }
        final saved = await transaction.query(
          'project_site_locations',
          where: 'project_id = ?',
          whereArgs: [command.projectId],
          limit: 1,
        );
        return _siteLocationFromRow(saved.single);
      }),
    );
  }

  @override
  Future<void> clearSiteLocation(
    ClearProjectSiteLocationCommand command,
  ) async {
    _requireUuid(command.eventId, 'invalid_event_id');
    _requireUuid(command.projectId, 'invalid_project_id');
    return _withDatabase(
      (database, timestamp) => database.transaction((transaction) async {
        final rows = await transaction.query(
          'project_site_locations',
          where: 'project_id = ? AND cleared_at IS NULL',
          whereArgs: [command.projectId],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw const ProjectInformationFailure('site_location_not_found');
        }
        final revision = rows.single['revision']! as int;
        if (revision != command.expectedRevision) {
          throw const ProjectInformationRevisionConflict();
        }
        final changed = await transaction.update(
          'project_site_locations',
          {
            'revision': revision + 1,
            'updated_at': timestamp,
            'cleared_at': timestamp,
          },
          where: 'project_id = ? AND revision = ?',
          whereArgs: [command.projectId, revision],
        );
        if (changed != 1) throw const ProjectInformationRevisionConflict();
        await _insertSiteLocationEvent(
          transaction,
          id: command.eventId,
          projectId: command.projectId,
          sequence: revision + 1,
          eventType: 'site_location.cleared',
          occurredAt: timestamp,
        );
      }),
    );
  }

  Future<List<ProjectInformationPin>> listPinsInTransaction(
    DatabaseExecutor database,
    String projectId,
  ) async {
    final rows = await database.query(
      'project_information_pins',
      where: 'project_id = ? AND archived_at IS NULL',
      whereArgs: [projectId],
      orderBy: 'sort_order ASC, id ASC',
    );
    final result = <ProjectInformationPin>[];
    for (final row in rows) {
      result.add(
        _pinFromRow(
          row,
          await _sourceAvailable(
            database,
            projectId,
            row['source_space']! as String,
            row['source_id']! as String,
          ),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  Future<T> _withDatabase<T>(
    Future<T> Function(Database database, String timestamp) action,
  ) {
    final operationTime = clock();
    final encoded = CseTimeCodec.encodeUtc(operationTime);
    final fixedTime = CseTimeCodec.decodeCanonicalUtc(encoded);
    return coordinator.run(() async {
      final appDatabase = AppDatabase(
        path: databasePath,
        factory: databaseFactory,
        clock: () => fixedTime,
      );
      try {
        await appDatabase.open();
        return await action(appDatabase.database, encoded);
      } finally {
        await appDatabase.close();
      }
    });
  }
}

void _requireUuid(String value, String code) {
  if (!RecordId.isUuid(value)) throw ProjectInformationFailure(code);
}

String _required(String value, String code, int maxLength) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > maxLength) {
    throw ProjectInformationFailure(code);
  }
  return normalized;
}

String? _optional(String? value, String code, int maxLength) {
  if (value == null || value.trim().isEmpty) return null;
  return _required(value, code, maxLength);
}

Map<String, Object?> _validatedEntryValues({
  required ProjectInformationCategory category,
  required String label,
  required ProjectInformationEntryValue value,
  required String? unit,
  required String? note,
}) {
  if ((category == ProjectInformationCategory.contact) !=
      (value.kind == ProjectInformationValueKind.contact)) {
    throw const ProjectInformationFailure('contact_category_kind_mismatch');
  }
  if (value.kind == ProjectInformationValueKind.contact &&
      note != null &&
      note.trim().isNotEmpty) {
    throw const ProjectInformationFailure('contact_note_must_be_structured');
  }
  final result = <String, Object?>{
    'category': _categoryToDb(category),
    'semantic_kind': _kindToDb(value.kind),
    'label': _required(label, 'invalid_label', 160),
    'unit': value.kind == ProjectInformationValueKind.number
        ? _optional(unit, 'invalid_unit', 40)
        : null,
    'note': value.kind == ProjectInformationValueKind.contact
        ? null
        : _optional(note, 'invalid_note', 4000),
  };
  if (unit != null && value.kind != ProjectInformationValueKind.number) {
    throw const ProjectInformationFailure('unit_requires_number');
  }
  switch (value.kind) {
    case ProjectInformationValueKind.text:
      result['text_value'] = _required(value.text ?? '', 'invalid_text', 4000);
    case ProjectInformationValueKind.number:
      final number = value.number;
      if (number == null || !number.isFinite) {
        throw const ProjectInformationFailure('invalid_number');
      }
      result['number_value'] = number;
    case ProjectInformationValueKind.date:
      final date = value.date ?? '';
      final parsed = DateTime.tryParse(date);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
          parsed == null ||
          parsed.toIso8601String().substring(0, 10) != date) {
        throw const ProjectInformationFailure('invalid_date');
      }
      result['date_value'] = date;
    case ProjectInformationValueKind.boolean:
      final boolean = value.boolean;
      if (boolean == null) {
        throw const ProjectInformationFailure('invalid_boolean');
      }
      result['boolean_value'] = boolean ? 1 : 0;
    case ProjectInformationValueKind.contact:
      final contact = value.contact;
      if (contact == null) {
        throw const ProjectInformationFailure('invalid_contact');
      }
      final hasType = contact.referenceType != null;
      final hasId = contact.referenceId != null;
      if (hasType != hasId) {
        throw const ProjectInformationFailure('incomplete_contact_reference');
      }
      if (hasId) {
        _requireUuid(contact.referenceId!, 'invalid_contact_reference');
      }
      result.addAll({
        'contact_name': _required(contact.name, 'invalid_contact_name', 160),
        'contact_company': _optional(
          contact.company,
          'invalid_contact_company',
          160,
        ),
        'contact_role': _optional(contact.role, 'invalid_contact_role', 160),
        'contact_phone': _optional(contact.phone, 'invalid_contact_phone', 80),
        'contact_whatsapp': _optional(
          contact.whatsAppNumber,
          'invalid_contact_whatsapp',
          80,
        ),
        'contact_note': _optional(contact.note, 'invalid_contact_note', 4000),
        'workforce_member_id':
            contact.referenceType ==
                ProjectInformationReferenceType.workforceMember
            ? contact.referenceId
            : null,
        'subcontractor_id':
            contact.referenceType ==
                ProjectInformationReferenceType.subcontractor
            ? contact.referenceId
            : null,
      });
  }
  return result;
}

Future<void> _requireActiveProject(
  DatabaseExecutor database,
  String projectId,
) async {
  final rows = await database.query(
    'projects',
    columns: ['id'],
    where: 'id = ? AND archived_at IS NULL',
    whereArgs: [projectId],
    limit: 1,
  );
  if (rows.isEmpty) throw const ProjectInformationFailure('project_not_found');
}

Future<void> _validateContactReference(
  DatabaseExecutor database,
  String projectId,
  Map<String, Object?> values,
) async {
  final workforceId = values['workforce_member_id'] as String?;
  final subcontractorId = values['subcontractor_id'] as String?;
  if (workforceId == null && subcontractorId == null) return;
  final table = workforceId != null ? 'workforce_members' : 'subcontractors';
  final id = workforceId ?? subcontractorId!;
  final rows = await database.query(
    table,
    columns: ['id'],
    where: 'id = ? AND project_id = ?',
    whereArgs: [id, projectId],
    limit: 1,
  );
  if (rows.isEmpty) {
    throw const ProjectInformationFailure('contact_reference_not_in_project');
  }
}

Future<ProjectInformationEntry> _loadEntry(
  DatabaseExecutor database,
  String projectId,
  String id,
) async {
  final rows = await database.query(
    'project_information_entries',
    where: 'id = ? AND project_id = ?',
    whereArgs: [id, projectId],
    limit: 1,
  );
  if (rows.isEmpty) throw const ProjectInformationFailure('entry_not_found');
  return _entryFromRow(rows.single);
}

ProjectInformationEntry _entryFromRow(Map<String, Object?> row) {
  final kind = _kindFromDb(row['semantic_kind']! as String);
  final value = switch (kind) {
    ProjectInformationValueKind.text => ProjectInformationEntryValue.text(
      row['text_value']! as String,
    ),
    ProjectInformationValueKind.number => ProjectInformationEntryValue.number(
      (row['number_value']! as num).toDouble(),
    ),
    ProjectInformationValueKind.date => ProjectInformationEntryValue.date(
      row['date_value']! as String,
    ),
    ProjectInformationValueKind.boolean => ProjectInformationEntryValue.boolean(
      row['boolean_value']! as int == 1,
    ),
    ProjectInformationValueKind.contact => ProjectInformationEntryValue.contact(
      ProjectInformationContact(
        name: row['contact_name']! as String,
        company: row['contact_company'] as String?,
        role: row['contact_role'] as String?,
        phone: row['contact_phone'] as String?,
        whatsAppNumber: row['contact_whatsapp'] as String?,
        note: row['contact_note'] as String?,
        referenceType: row['workforce_member_id'] != null
            ? ProjectInformationReferenceType.workforceMember
            : row['subcontractor_id'] != null
            ? ProjectInformationReferenceType.subcontractor
            : null,
        referenceId:
            (row['workforce_member_id'] ?? row['subcontractor_id']) as String?,
      ),
    ),
  };
  return ProjectInformationEntry(
    id: row['id']! as String,
    projectId: row['project_id']! as String,
    category: _categoryFromDb(row['category']! as String),
    label: row['label']! as String,
    value: value,
    unit: row['unit'] as String?,
    note: row['note'] as String?,
    revision: row['revision']! as int,
    createdAt: row['created_at']! as String,
    updatedAt: row['updated_at']! as String,
    archivedAt: row['archived_at'] as String?,
  );
}

Future<void> _insertEntryEvent(
  DatabaseExecutor database, {
  required String id,
  required String entryId,
  required String projectId,
  required int sequence,
  required String eventType,
  required String occurredAt,
}) => database.insert('project_information_entry_events', {
  'id': id,
  'entry_id': entryId,
  'project_id': projectId,
  'sequence': sequence,
  'event_type': eventType,
  'occurred_at': occurredAt,
  'payload_json': jsonEncode({'revision': sequence}),
});

Future<void> _insertPinEvent(
  DatabaseExecutor database,
  String id,
  String pinId,
  String projectId,
  int sequence,
  String eventType,
  String occurredAt,
) => database.insert('project_information_pin_events', {
  'id': id,
  'pin_id': pinId,
  'project_id': projectId,
  'sequence': sequence,
  'event_type': eventType,
  'occurred_at': occurredAt,
  'payload_json': jsonEncode({'revision': sequence}),
});

ProjectSiteLocation _siteLocationFromRow(Map<String, Object?> row) =>
    ProjectSiteLocation(
      projectId: row['project_id']! as String,
      latitude: (row['latitude']! as num).toDouble(),
      longitude: (row['longitude']! as num).toDouble(),
      revision: row['revision']! as int,
      createdAt: row['created_at']! as String,
      updatedAt: row['updated_at']! as String,
    );

Future<void> _insertSiteLocationEvent(
  DatabaseExecutor database, {
  required String id,
  required String projectId,
  required int sequence,
  required String eventType,
  required String occurredAt,
}) => database.insert('project_site_location_events', {
  'id': id,
  'project_id': projectId,
  'sequence': sequence,
  'event_type': eventType,
  'occurred_at': occurredAt,
  'payload_json': jsonEncode({'revision': sequence}),
});

Future<int> _nextPinOrder(DatabaseExecutor database, String projectId) async {
  final value = Sqflite.firstIntValue(
    await database.rawQuery(
      'SELECT MAX(sort_order) FROM project_information_pins '
      'WHERE project_id = ? AND archived_at IS NULL',
      [projectId],
    ),
  );
  return (value ?? -1) + 1;
}

Future<bool> _sourceAvailable(
  DatabaseExecutor database,
  String projectId,
  String sourceSpace,
  String sourceId,
) async {
  if (sourceSpace == 'system_value') {
    if (sourceId == ProjectInformationSystemValue.projectName.storageKey) {
      final rows = await database.query(
        'projects',
        columns: ['id'],
        where: 'id = ? AND archived_at IS NULL AND length(trim(name)) > 0',
        whereArgs: [projectId],
        limit: 1,
      );
      return rows.isNotEmpty;
    }
    final column = _metadataColumnForSystemKey(sourceId);
    final rows = await database.query(
      'project_metadata',
      columns: ['project_id'],
      where: 'project_id = ? AND $column IS NOT NULL',
      whereArgs: [projectId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
  final table = switch (sourceSpace) {
    'profile_field' => 'project_profile_fields',
    'party_assignment' => 'project_party_assignments',
    'inventory_block' => 'inventory_blocks',
    'inventory_floor' => 'inventory_floors',
    'location' => 'project_locations',
    'user_entry' => 'project_information_entries',
    _ => throw const ProjectInformationFailure('unknown_pin_source_space'),
  };
  final rows = await database.query(
    table,
    columns: ['id'],
    where: 'id = ? AND project_id = ? AND archived_at IS NULL',
    whereArgs: [sourceId, projectId],
    limit: 1,
  );
  return rows.isNotEmpty;
}

String _metadataColumnForSystemKey(String sourceId) => switch (sourceId) {
  'metadata.address' => 'address',
  'metadata.permit_number' => 'permit_number',
  'metadata.permit_date' => 'permit_date',
  'metadata.cadastral_block' => 'cadastral_block',
  'metadata.cadastral_parcel' => 'cadastral_parcel',
  'metadata.project_start_date' => 'project_start_date',
  'metadata.target_finish_date' => 'target_finish_date',
  'metadata.usage_type' => 'usage_type',
  'metadata.structural_system' => 'structural_system',
  _ => throw const ProjectInformationFailure('unknown_system_value_key'),
};

ProjectInformationPin _pinFromRow(Map<String, Object?> row, bool available) =>
    ProjectInformationPin(
      id: row['id']! as String,
      projectId: row['project_id']! as String,
      key: ProjectInformationKey(
        space: _keySpaceFromDb(row['source_space']! as String),
        id: row['source_id']! as String,
      ),
      sortOrder: row['sort_order']! as int,
      revision: row['revision']! as int,
      createdAt: row['created_at']! as String,
      updatedAt: row['updated_at']! as String,
      sourceAvailable: available,
    );

String _categoryToDb(ProjectInformationCategory value) => switch (value) {
  ProjectInformationCategory.project => 'project',
  ProjectInformationCategory.location => 'location',
  ProjectInformationCategory.technical => 'technical',
  ProjectInformationCategory.official => 'official',
  ProjectInformationCategory.siteReference => 'site_reference',
  ProjectInformationCategory.contact => 'contact',
};
ProjectInformationCategory _categoryFromDb(String value) => switch (value) {
  'project' => ProjectInformationCategory.project,
  'location' => ProjectInformationCategory.location,
  'technical' => ProjectInformationCategory.technical,
  'official' => ProjectInformationCategory.official,
  'site_reference' => ProjectInformationCategory.siteReference,
  'contact' => ProjectInformationCategory.contact,
  _ => throw const ProjectInformationFailure('unknown_category'),
};
String _kindToDb(ProjectInformationValueKind value) => value.name;
ProjectInformationValueKind _kindFromDb(String value) =>
    ProjectInformationValueKind.values.firstWhere(
      (item) => item.name == value,
      orElse: () => throw const ProjectInformationFailure('unknown_value_kind'),
    );
String _keySpaceToDb(ProjectInformationKeySpace value) => switch (value) {
  ProjectInformationKeySpace.systemValue => 'system_value',
  ProjectInformationKeySpace.profileField => 'profile_field',
  ProjectInformationKeySpace.partyAssignment => 'party_assignment',
  ProjectInformationKeySpace.inventoryBlock => 'inventory_block',
  ProjectInformationKeySpace.inventoryFloor => 'inventory_floor',
  ProjectInformationKeySpace.location => 'location',
  ProjectInformationKeySpace.userEntry => 'user_entry',
};
ProjectInformationKeySpace _keySpaceFromDb(String value) => switch (value) {
  'system_value' => ProjectInformationKeySpace.systemValue,
  'profile_field' => ProjectInformationKeySpace.profileField,
  'party_assignment' => ProjectInformationKeySpace.partyAssignment,
  'inventory_block' => ProjectInformationKeySpace.inventoryBlock,
  'inventory_floor' => ProjectInformationKeySpace.inventoryFloor,
  'location' => ProjectInformationKeySpace.location,
  'user_entry' => ProjectInformationKeySpace.userEntry,
  _ => throw const ProjectInformationFailure('unknown_pin_source_space'),
};
