import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/application/project_information_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/domain/project_information_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectA = 'project-a';
const _projectB = 'project-b';
final _now = DateTime.utc(2026, 9, 13, 9);

void main() {
  test('composes canonical sources in deterministic hierarchy', () async {
    final source = _FakeProjectInformationSource.standard();
    source.metadataByProject[_projectA] = _metadata(
      _projectA,
      revision: 1,
      address: 'Şantiye adresi',
    );
    source.profileByProject[_projectA] = ProjectProfile(
      project: source.projects[_projectA]!,
      fields: [
        _profileField('custom-z', sortOrder: 4, value: 'Not'),
        _profileField(
          'builtin-area',
          sortOrder: 2,
          value: '999 m²',
          builtin: ProjectProfileBuiltinField.totalArea,
        ),
        _profileField(
          'builtin-yibf',
          sortOrder: 1,
          value: 'Y-42',
          builtin: ProjectProfileBuiltinField.yibfNumber,
        ),
      ],
    );
    source.partiesByProject[_projectA] = [
      _party(
        'party-chief',
        ProjectPartyRole.siteChief,
        workforceMemberId: 'member-chief',
      ),
      _party(
        'party-employer',
        ProjectPartyRole.employer,
        subcontractorId: 'company-employer',
      ),
    ];
    source.companiesByProject[_projectA] = [
      _company('company-employer', active: true),
    ];
    source.membersByProject[_projectA] = [
      _member('member-chief', active: false),
    ];
    source.inventoryByProject[_projectA] = _inventory(
      blocks: [
        _block('block-b', ordinal: 2, state: InventoryBlockState.detached),
        _block('block-c', ordinal: 3, state: InventoryBlockState.archived),
        _block('block-a', ordinal: 1),
      ],
      floors: [
        _floor('floor-a-2', 'block-a', ordinal: 2),
        _floor('floor-b-1', 'block-b', ordinal: 1),
        _floor('floor-a-1', 'block-a', ordinal: 1),
      ],
    );
    source.blockMetadataById.addAll({
      'block-a': _blockMetadata('block-a', revision: 1, area: 120, unit: 'm²'),
      'block-b': _blockMetadata('block-b'),
      'block-c': _blockMetadata('block-c'),
    });
    source.locationsByProject[_projectA] = [
      _location('location-z', 'Z Mahal'),
      _location('location-a', 'A Mahal'),
      _location('location-old', 'Eski Mahal', archived: true),
    ];
    source.floorLocationsByProject[_projectA] = [
      _floorLocation('relation-z', 'floor-a-1', 'location-z'),
      _floorLocation('relation-a', 'floor-a-1', 'location-a'),
      _floorLocation('relation-old', 'floor-a-2', 'location-old'),
    ];

    final result = await ProjectInformationApplication(
      source: source,
    ).createSession().loadProject(_projectA);

    final snapshot = (result as ProjectInformationReady).snapshot;
    expect(snapshot.project.id, _projectA);
    expect(snapshot.metadata?.address, 'Şantiye adresi');
    expect(snapshot.profileFields.map((field) => field.id), [
      'builtin-yibf',
      'builtin-area',
      'custom-z',
    ]);
    expect(snapshot.profileFields[1].value, '999 m²');
    expect(snapshot.parties.map((party) => party.assignment.role), [
      ProjectPartyRole.employer,
      ProjectPartyRole.siteChief,
    ]);
    expect(
      snapshot.parties[1].targetState,
      ProjectInformationPartyTargetState.resolvedArchived,
    );
    expect(snapshot.blocks.map((entry) => entry.block.id), [
      'block-a',
      'block-b',
      'block-c',
    ]);
    expect(snapshot.blocks.first.floors.map((entry) => entry.floor.id), [
      'floor-a-1',
      'floor-a-2',
    ]);
    expect(
      snapshot.blocks.first.floors.first.locations.map(
        (entry) => entry.location?.id,
      ),
      ['location-a', 'location-z'],
    );
    expect(
      snapshot.blocks.first.floors[1].locations.single.state,
      ProjectInformationFloorLocationState.archivedLocation,
    );
    expect(snapshot.derivedInventoryTotals.isDerived, isTrue);
    expect(snapshot.derivedInventoryTotals.activeBlockCount, 1);
    expect(snapshot.derivedInventoryTotals.detachedBlockCount, 1);
    expect(snapshot.derivedInventoryTotals.archivedBlockCount, 1);
    expect(snapshot.derivedInventoryTotals.activeFloorCount, 2);
    expect(
      snapshot.derivedInventoryTotals.areaState,
      ProjectInformationDerivedAreaState.available,
    );
    expect(snapshot.derivedInventoryTotals.totalArea, 120);
    expect(snapshot.derivedInventoryTotals.totalAreaUnit, 'm²');
  });

  test(
    'session generation rejects stale results without global interference',
    () async {
      final source = _FakeProjectInformationSource.standard(
        includeProjectB: true,
      );
      final delayedA = Completer<MobileProject>();
      source.projectReads[_projectA] = [delayedA.future];
      final application = ProjectInformationApplication(source: source);
      final sharedSession = application.createSession();

      final staleA = sharedSession.loadProject(_projectA);
      final currentB = await sharedSession.loadProject(_projectB);
      expect(currentB, isA<ProjectInformationReady>());
      delayedA.complete(source.projects[_projectA]);
      expect(await staleA, isA<ProjectInformationSuperseded>());

      final independentDelay = Completer<MobileProject>();
      source.projectReads[_projectA] = [independentDelay.future];
      final independentA = application.createSession().loadProject(_projectA);
      final independentB = await application.createSession().loadProject(
        _projectB,
      );
      expect(independentB, isA<ProjectInformationReady>());
      independentDelay.complete(source.projects[_projectA]);
      expect(await independentA, isA<ProjectInformationReady>());
    },
  );

  test(
    'keeps lifecycle and missing targets explicit under partial failure',
    () async {
      final source = _FakeProjectInformationSource.standard();
      source.partiesByProject[_projectA] = [
        _party(
          'party-missing',
          ProjectPartyRole.employer,
          subcontractorId: 'missing-company',
        ),
        _party(
          'party-chief',
          ProjectPartyRole.siteChief,
          workforceMemberId: 'member-chief',
        ),
      ];
      source.memberFailure = StateError('members unavailable');
      source.inventoryByProject[_projectA] = _inventory(
        blocks: [
          _block('block-active', ordinal: 1),
          _block(
            'block-detached',
            ordinal: 2,
            state: InventoryBlockState.detached,
          ),
          _block(
            'block-archived',
            ordinal: 3,
            state: InventoryBlockState.archived,
          ),
        ],
        floors: [
          _floor('floor-active', 'block-active', ordinal: 1),
          _floor('floor-archived', 'block-active', ordinal: 2, archived: true),
        ],
      );
      source.blockMetadataFailures['block-detached'] = StateError(
        'unavailable',
      );
      source.locationsByProject[_projectA] = [
        _location('location-old', 'Eski Mahal', archived: true),
      ];
      source.floorLocationsByProject[_projectA] = [
        _floorLocation('relation-old', 'floor-active', 'location-old'),
        _floorLocation('relation-missing', 'floor-active', 'location-missing'),
      ];

      final result = await ProjectInformationApplication(
        source: source,
      ).createSession().loadProject(_projectA);

      final snapshot = (result as ProjectInformationReady).snapshot;
      expect(snapshot.parties.map((party) => party.targetState), [
        ProjectInformationPartyTargetState.missing,
        ProjectInformationPartyTargetState.sourceUnavailable,
      ]);
      expect(
        snapshot.statusFor(ProjectInformationSource.workforceMembers).state,
        ProjectInformationReadState.failed,
      );
      expect(snapshot.blocks.map((entry) => entry.block.state), [
        InventoryBlockState.active,
        InventoryBlockState.detached,
        InventoryBlockState.archived,
      ]);
      expect(snapshot.blocks.first.floors[1].floor.archivedAt, isNotNull);
      expect(
        snapshot.blocks[1].metadata.state,
        ProjectInformationBlockMetadataState.failed,
      );
      expect(
        snapshot.statusFor(ProjectInformationSource.blockMetadata).state,
        ProjectInformationReadState.failed,
      );
      expect(
        snapshot.derivedInventoryTotals.areaState,
        ProjectInformationDerivedAreaState.incomplete,
      );
      expect(
        snapshot.blocks.first.floors.first.locations
            .map((entry) => entry.state)
            .toSet(),
        {
          ProjectInformationFloorLocationState.archivedLocation,
          ProjectInformationFloorLocationState.missingLocation,
        },
      );
      expect(
        snapshot.unresolvedFloorLocations.single.reason,
        ProjectInformationUnresolvedFloorLocationReason.missingLocation,
      );
    },
  );

  test(
    'distinguishes genuine empty reads from failure and never mutates',
    () async {
      final source = _FakeProjectInformationSource.standard();
      final application = ProjectInformationApplication(source: source);

      final emptyResult = await application.createSession().loadProject(
        _projectA,
      );
      final empty = (emptyResult as ProjectInformationReady).snapshot;
      expect(
        empty.statusFor(ProjectInformationSource.metadata).state,
        ProjectInformationReadState.empty,
      );
      expect(
        empty.statusFor(ProjectInformationSource.profile).state,
        ProjectInformationReadState.empty,
      );
      expect(
        empty.statusFor(ProjectInformationSource.inventory).state,
        ProjectInformationReadState.empty,
      );
      expect(source.mutationCalls, 0);
      expect(
        source.calls.where((call) => call.startsWith('getProject:')).length,
        2,
      );
      expect(
        source.calls.toSet(),
        containsAll({
          'getMetadata:$_projectA',
          'getProfile:$_projectA',
          'listProfileEvents:$_projectA',
          'listParties:$_projectA',
          'listCompanies:$_projectA',
          'listMembers:$_projectA',
          'loadInventory:$_projectA',
          'listLocations:$_projectA',
          'listFloorLocations:$_projectA',
        }),
      );

      source.inventoryFailure = const InventoryFailure('inventory_read_failed');
      final failedResult = await application.createSession().loadProject(
        _projectA,
      );
      final failed = (failedResult as ProjectInformationReady).snapshot;
      expect(
        failed.statusFor(ProjectInformationSource.inventory).state,
        ProjectInformationReadState.failed,
      );
      expect(
        failed.statusFor(ProjectInformationSource.inventory).errorCode,
        'inventory_read_failed',
      );
      expect(
        failed.statusFor(ProjectInformationSource.blockMetadata).errorCode,
        'inventory_source_failed',
      );
      expect(source.mutationCalls, 0);
    },
  );

  test(
    'preserves archived custom profile fields and distinguishes source states',
    () async {
      final source = _FakeProjectInformationSource.standard();
      source.profileEventsByProject[_projectA] = [
        _profileEvent(
          id: 'profile-event-create',
          fieldId: 'custom-archived',
          sequence: 1,
          type: ProjectProfileEventType.fieldCreated,
          payload: {'label': 'Eski not', 'value': 'Sakla', 'sort_order': 3},
        ),
        _profileEvent(
          id: 'profile-event-archive',
          fieldId: 'custom-archived',
          sequence: 2,
          type: ProjectProfileEventType.fieldArchived,
          payload: {
            'was_archived': false,
            'is_archived': true,
            'revision_before': 1,
            'revision_after': 2,
            'sort_order': 3,
          },
        ),
      ];

      final archivedResult = await ProjectInformationApplication(
        source: source,
      ).createSession().loadProject(_projectA);
      final archived = (archivedResult as ProjectInformationReady).snapshot;
      final archivedField = archived.profileFields.singleWhere(
        (field) => field.id == 'custom-archived',
      );
      expect(archivedField.isArchived, isTrue);
      expect(archivedField.archivedAt, '2026-09-13T09:02:00.000Z');
      expect(archivedField.value, 'Sakla');
      expect(
        archived.statusFor(ProjectInformationSource.profile).state,
        ProjectInformationReadState.loaded,
      );

      source.profileEventsByProject[_projectA] = [];
      final emptyResult = await ProjectInformationApplication(
        source: source,
      ).createSession().loadProject(_projectA);
      final empty = (emptyResult as ProjectInformationReady).snapshot;
      expect(
        empty.statusFor(ProjectInformationSource.profile).state,
        ProjectInformationReadState.empty,
      );

      source.profileEventFailure = StateError('profile events unavailable');
      final failedResult = await ProjectInformationApplication(
        source: source,
      ).createSession().loadProject(_projectA);
      final failed = (failedResult as ProjectInformationReady).snapshot;
      expect(failed.profileFields, isEmpty);
      expect(
        failed.statusFor(ProjectInformationSource.profile).state,
        ProjectInformationReadState.failed,
      );
      expect(source.mutationCalls, 0);
    },
  );

  test('fails foreign project data closed and rejects archived root', () async {
    final source = _FakeProjectInformationSource.standard();
    source.metadataByProject[_projectA] = _metadata(
      _projectB,
      revision: 1,
      address: 'Başka proje',
    );

    final result = await ProjectInformationApplication(
      source: source,
    ).createSession().loadProject(_projectA);
    final snapshot = (result as ProjectInformationReady).snapshot;
    expect(snapshot.metadata, isNull);
    expect(
      snapshot.statusFor(ProjectInformationSource.metadata).errorCode,
      'cross_project_data',
    );

    source.projects[_projectA] = _project(_projectA, archived: true);
    source.calls.clear();
    final archived = await ProjectInformationApplication(
      source: source,
    ).createSession().loadProject(_projectA);
    expect(archived, isA<ProjectInformationLoadFailure>());
    expect(
      (archived as ProjectInformationLoadFailure).failure.errorCode,
      'project_information_project_archived',
    );
    expect(source.calls, ['getProject:$_projectA']);

    source.projects[_projectA] = _project(_projectB);
    source.calls.clear();
    final foreignRoot = await ProjectInformationApplication(
      source: source,
    ).createSession().loadProject(_projectA);
    expect(foreignRoot, isA<ProjectInformationLoadFailure>());
    expect(
      (foreignRoot as ProjectInformationLoadFailure).failure.errorCode,
      'cross_project_data',
    );
    expect(source.calls, ['getProject:$_projectA']);
  });

  test('rejects project revision drift across the composed read', () async {
    final source = _FakeProjectInformationSource.standard();
    source.projectReads[_projectA] = [
      Future.value(_project(_projectA)),
      Future.value(_project(_projectA, revision: 2)),
    ];

    final result = await ProjectInformationApplication(
      source: source,
    ).createSession().loadProject(_projectA);

    expect(result, isA<ProjectInformationLoadFailure>());
    expect(
      (result as ProjectInformationLoadFailure).failure.errorCode,
      'project_information_project_changed_during_read',
    );
  });

  test('clearProject invalidates an in-flight result', () async {
    final source = _FakeProjectInformationSource.standard();
    final delayed = Completer<MobileProject>();
    source.projectReads[_projectA] = [delayed.future];
    final session = ProjectInformationApplication(
      source: source,
    ).createSession();
    final loading = session.loadProject(_projectA);
    session.clearProject();
    delayed.complete(source.projects[_projectA]);

    expect(await loading, isA<ProjectInformationSuperseded>());
    expect(session.projectId, isNull);
  });
}

class _FakeProjectInformationSource implements ProjectInformationReadSource {
  _FakeProjectInformationSource.standard({bool includeProjectB = false}) {
    projects[_projectA] = _project(_projectA);
    metadataByProject[_projectA] = _metadata(_projectA);
    profileByProject[_projectA] = _emptyProfile(projects[_projectA]!);
    partiesByProject[_projectA] = [];
    companiesByProject[_projectA] = [];
    membersByProject[_projectA] = [];
    inventoryByProject[_projectA] = null;
    locationsByProject[_projectA] = [];
    floorLocationsByProject[_projectA] = [];
    if (includeProjectB) {
      projects[_projectB] = _project(_projectB);
      metadataByProject[_projectB] = _metadata(_projectB);
      profileByProject[_projectB] = _emptyProfile(projects[_projectB]!);
      partiesByProject[_projectB] = [];
      companiesByProject[_projectB] = [];
      membersByProject[_projectB] = [];
      inventoryByProject[_projectB] = null;
      locationsByProject[_projectB] = [];
      floorLocationsByProject[_projectB] = [];
    }
  }

  final Map<String, MobileProject> projects = {};
  final Map<String, List<Future<MobileProject>>> projectReads = {};
  final Map<String, ProjectMetadata> metadataByProject = {};
  final Map<String, ProjectProfile> profileByProject = {};
  final Map<String, List<ProjectProfileEvent>> profileEventsByProject = {};
  final Map<String, List<ProjectPartyAssignment>> partiesByProject = {};
  final Map<String, List<Subcontractor>> companiesByProject = {};
  final Map<String, List<WorkforceMember>> membersByProject = {};
  final Map<String, InventoryPrimarySketchProjection?> inventoryByProject = {};
  final Map<String, InventoryBlockMetadataRecord> blockMetadataById = {};
  final Map<String, Object> blockMetadataFailures = {};
  final Map<String, List<MobileProjectLocation>> locationsByProject = {};
  final Map<String, List<ProjectFloorLocationRelation>>
  floorLocationsByProject = {};
  final List<String> calls = [];
  Object? metadataFailure;
  Object? profileFailure;
  Object? profileEventFailure;
  Object? partyFailure;
  Object? companyFailure;
  Object? memberFailure;
  Object? inventoryFailure;
  Object? locationFailure;
  Object? floorLocationFailure;
  int mutationCalls = 0;

  @override
  Future<MobileProject> getProject(String projectId) async {
    calls.add('getProject:$projectId');
    final queued = projectReads[projectId];
    if (queued != null && queued.isNotEmpty) return queued.removeAt(0);
    return projects[projectId] ?? (throw StateError('missing project'));
  }

  @override
  Future<ProjectMetadata> getProjectMetadata(String projectId) async {
    calls.add('getMetadata:$projectId');
    if (metadataFailure != null) throw metadataFailure!;
    return metadataByProject[projectId] ?? _metadata(projectId);
  }

  @override
  Future<ProjectProfile> getProjectProfile(String projectId) async {
    calls.add('getProfile:$projectId');
    if (profileFailure != null) throw profileFailure!;
    return profileByProject[projectId] ?? _emptyProfile(projects[projectId]!);
  }

  @override
  Future<List<ProjectProfileEvent>> listProjectProfileEvents(
    String projectId,
  ) async {
    calls.add('listProfileEvents:$projectId');
    if (profileEventFailure != null) throw profileEventFailure!;
    return profileEventsByProject[projectId] ?? const [];
  }

  @override
  Future<List<ProjectPartyAssignment>> listProjectPartyAssignments(
    String projectId,
  ) async {
    calls.add('listParties:$projectId');
    if (partyFailure != null) throw partyFailure!;
    return partiesByProject[projectId] ?? const [];
  }

  @override
  Future<List<Subcontractor>> listCompanies(String projectId) async {
    calls.add('listCompanies:$projectId');
    if (companyFailure != null) throw companyFailure!;
    return companiesByProject[projectId] ?? const [];
  }

  @override
  Future<List<WorkforceMember>> listWorkforceMembers(String projectId) async {
    calls.add('listMembers:$projectId');
    if (memberFailure != null) throw memberFailure!;
    return membersByProject[projectId] ?? const [];
  }

  @override
  Future<InventoryPrimarySketchProjection?> loadInventory(
    String projectId,
  ) async {
    calls.add('loadInventory:$projectId');
    if (inventoryFailure != null) throw inventoryFailure!;
    return inventoryByProject[projectId];
  }

  @override
  Future<InventoryBlockMetadataRecord> loadBlockMetadata({
    required String projectId,
    required String blockId,
  }) async {
    calls.add('loadBlockMetadata:$projectId:$blockId');
    final failure = blockMetadataFailures[blockId];
    if (failure != null) throw failure;
    return blockMetadataById[blockId] ?? _blockMetadata(blockId);
  }

  @override
  Future<List<MobileProjectLocation>> listLocations(String projectId) async {
    calls.add('listLocations:$projectId');
    if (locationFailure != null) throw locationFailure!;
    return locationsByProject[projectId] ?? const [];
  }

  @override
  Future<List<ProjectFloorLocationRelation>> listFloorLocations(
    String projectId,
  ) async {
    calls.add('listFloorLocations:$projectId');
    if (floorLocationFailure != null) throw floorLocationFailure!;
    return floorLocationsByProject[projectId] ?? const [];
  }
}

MobileProject _project(String id, {bool archived = false, int revision = 1}) =>
    MobileProject(
      id: id,
      name: id == _projectA ? 'A Projesi' : 'B Projesi',
      createdAt: '2026-09-13T09:00:00.000Z',
      updatedAt: '2026-09-13T09:00:00.000Z',
      revision: revision,
      archivedAt: archived ? '2026-09-13T10:00:00.000Z' : null,
    );

ProjectMetadata _metadata(
  String projectId, {
  int revision = 0,
  String? address,
}) => ProjectMetadata(
  projectId: projectId,
  revision: revision,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  address: address,
);

ProjectProfile _emptyProfile(MobileProject project) => ProjectProfile(
  project: project,
  fields: ProjectProfileBuiltinField.values
      .map(
        (builtin) => ProjectProfileField(
          id: 'profile-${project.id}-${builtin.storageValue}',
          projectId: project.id,
          label: builtin.label,
          value: '',
          sortOrder: builtin.index,
          revision: 0,
          createdAt: project.createdAt,
          updatedAt: project.updatedAt,
          builtinField: builtin,
        ),
      )
      .toList(growable: false),
);

ProjectProfileField _profileField(
  String id, {
  required int sortOrder,
  required String value,
  ProjectProfileBuiltinField? builtin,
}) => ProjectProfileField(
  id: id,
  projectId: _projectA,
  label: builtin?.label ?? 'Özel alan',
  value: value,
  sortOrder: sortOrder,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  builtinField: builtin,
);

ProjectProfileEvent _profileEvent({
  required String id,
  required String fieldId,
  required int sequence,
  required ProjectProfileEventType type,
  required Map<String, Object?> payload,
}) => ProjectProfileEvent(
  id: id,
  projectId: _projectA,
  fieldId: fieldId,
  sequence: sequence,
  eventType: type,
  occurredAt: '2026-09-13T09:0$sequence:00.000Z',
  payloadJson: jsonEncode(payload),
);

ProjectPartyAssignment _party(
  String id,
  ProjectPartyRole role, {
  String? subcontractorId,
  String? workforceMemberId,
}) => ProjectPartyAssignment(
  id: id,
  projectId: _projectA,
  role: role,
  subcontractorId: subcontractorId,
  workforceMemberId: workforceMemberId,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
);

Subcontractor _company(String id, {required bool active}) => Subcontractor(
  id: id,
  projectId: _projectA,
  name: 'Firma',
  contactName: 'Yetkili',
  phone: '555',
  note: null,
  status: active
      ? WorkforceRecordStatus.active
      : WorkforceRecordStatus.archived,
  activeTeamCount: 0,
  activePersonCount: 0,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: active ? null : '2026-09-13T10:00:00.000Z',
);

WorkforceMember _member(String id, {required bool active}) => WorkforceMember(
  id: id,
  projectId: _projectA,
  fullName: 'Şantiye Şefi',
  teamName: 'Yönetim',
  roleName: 'Şantiye Şefi',
  personnelCode: null,
  phone: '555',
  isActive: active,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: active ? null : '2026-09-13T10:00:00.000Z',
);

InventoryPrimarySketchProjection _inventory({
  required List<InventoryBlockRecord> blocks,
  required List<InventoryFloorRecord> floors,
}) => InventoryPrimarySketchProjection(
  sketch: InventorySketchRecord(
    id: 'sketch-a',
    projectId: _projectA,
    displayName: 'Saha krokisi',
    isPrimary: true,
    activeRevisionId: null,
    draftRevisionId: null,
    revision: 1,
    createdAt: _now,
    updatedAt: _now,
    archivedAt: null,
  ),
  activeRevision: null,
  draftRevision: null,
  blocks: blocks,
  floors: floors,
);

InventoryBlockRecord _block(
  String id, {
  required int ordinal,
  InventoryBlockState state = InventoryBlockState.active,
}) => InventoryBlockRecord(
  id: id,
  projectId: _projectA,
  displayName: id,
  normalizedName: id,
  ordinal: ordinal,
  state: state,
  revision: 1,
  createdAt: _now,
  updatedAt: _now,
  archivedAt: state == InventoryBlockState.archived ? _now : null,
);

InventoryFloorRecord _floor(
  String id,
  String blockId, {
  required int ordinal,
  bool archived = false,
}) => InventoryFloorRecord(
  id: id,
  blockId: blockId,
  projectId: _projectA,
  displayName: id,
  ordinal: ordinal,
  revision: 1,
  createdAt: _now,
  updatedAt: _now,
  archivedAt: archived ? _now : null,
);

InventoryBlockMetadataRecord _blockMetadata(
  String blockId, {
  int revision = 0,
  double? area,
  String? unit,
}) => InventoryBlockMetadataRecord(
  blockId: blockId,
  projectId: _projectA,
  basementCount: null,
  basementClassification: null,
  totalArea: area,
  totalAreaUnit: unit,
  footprintArea: null,
  footprintAreaUnit: null,
  independentUnitCount: null,
  usageType: null,
  revision: revision,
  createdAt: _now,
  updatedAt: _now,
);

MobileProjectLocation _location(
  String id,
  String name, {
  bool archived = false,
}) => MobileProjectLocation(
  id: id,
  projectId: _projectA,
  displayName: name,
  parentLocationId: null,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: archived ? '2026-09-13T10:00:00.000Z' : null,
);

ProjectFloorLocationRelation _floorLocation(
  String id,
  String floorId,
  String locationId, {
  bool archived = false,
}) => ProjectFloorLocationRelation(
  id: id,
  projectId: _projectA,
  floorId: floorId,
  locationId: locationId,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: archived ? '2026-09-13T10:00:00.000Z' : null,
);
