import 'dart:convert';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/domain/project_information_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';

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
  const ProjectInformationApplication({required this.source});

  final ProjectInformationReadSource source;

  ProjectInformationSession createSession() =>
      ProjectInformationSession._(this);

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
