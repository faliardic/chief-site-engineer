import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/project_information_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/projects/project_information_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectA = 'project-a';
const _projectB = 'project-b';
final _now = DateTime.utc(2026, 9, 13, 9);

void main() {
  testWidgets(
    'shows source categories, bounded search, copy/share and block hierarchy',
    (tester) async {
      final source = _FakeProjectInformationSource.standard();
      source.metadataByProject[_projectA] = _metadata(
        _projectA,
        address: 'Merkez Mahallesi 42',
      );
      source.profileByProject[_projectA] = ProjectProfile(
        project: source.projects[_projectA]!,
        fields: [
          ..._emptyProfile(source.projects[_projectA]!).fields,
          for (var index = 0; index < 45; index += 1)
            _profileField(
              'custom-$index',
              label: 'Mekanik not $index',
              value: 'Değer $index',
              sortOrder: 10 + index,
            ),
        ],
      );
      source.inventoryByProject[_projectA] = _inventory(
        blocks: [
          _block('block-a', 'A Blok', state: InventoryBlockState.detached),
        ],
        floors: [_floor('floor-a', 'block-a', 'Zemin Kat', archived: true)],
      );
      source.blockMetadataById['block-a'] = _blockMetadata(
        'block-a',
        totalArea: 640,
        totalAreaUnit: 'm²',
        usageType: 'Konut',
      );
      source.locationsByProject[_projectA] = [
        _location('location-a', 'Mekanik Oda', archived: true),
      ];
      source.floorLocationsByProject[_projectA] = [
        _floorLocation('relation-a', 'floor-a', 'location-a'),
      ];
      final copied = <String>[];
      final shared = <String>[];

      await tester.pumpWidget(
        _testApp(
          source,
          copyText: (text) async => copied.add(text),
          shareText: (text) async => shared.add(text),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tüm proje bilgileri'), findsOneWidget);
      expect(find.text('Proje Bilgileri'), findsOneWidget);
      expect(find.text('Konum ve Adres'), findsOneWidget);
      expect(find.text('Önemli Kişiler'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('project-information-search')),
            )
            .maxLength,
        120,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-address')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('project-information-section-address')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('project-information-copy-address')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('project-information-share-address')),
      );
      await tester.pump();
      expect(copied, ['Merkez Mahallesi 42']);
      expect(shared, ['Adres: Merkez Mahallesi 42']);
      expect(source.mutationCalls, 0);

      for (final category in const [
        ('official', 'Resmî Bilgiler'),
        ('technical', 'Teknik Bilgiler'),
        ('site', 'Saha Bilgileri'),
        ('custom', 'Özel Alanlar'),
      ]) {
        await tester.scrollUntilVisible(
          find.byKey(Key('project-information-section-${category.$1}')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(category.$2), findsOneWidget);
      }

      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-search')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('project-information-search')),
        'mekanik',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('project-information-search-results')),
        findsOneWidget,
      );
      expect(find.text('İlk 40 eşleşme gösteriliyor.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('project-information-search')),
        '640',
      );
      await tester.pumpAndSettle();
      expect(find.text('Toplam alan'), findsOneWidget);
      expect(find.text('640 m²'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('project-information-search')),
        '',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('project-information-section-blocks')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('project-information-section-blocks')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('A Blok'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A Blok'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Zemin Kat'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zemin Kat'));
      await tester.pumpAndSettle();
      expect(find.text('Krokiden ayrılmış blok'), findsOneWidget);
      expect(find.text('Kat arşivlenmiş'), findsOneWidget);
      expect(find.text('Mekanik Oda'), findsOneWidget);
      expect(find.text('Mahal arşivlenmiş'), findsOneWidget);
    },
  );

  testWidgets('shows empty, partial failure and root error safely', (
    tester,
  ) async {
    final partialSource = _FakeProjectInformationSource.standard()
      ..metadataFailure = StateError('metadata unavailable');
    await tester.pumpWidget(_testApp(partialSource));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('project-information-partial-error')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-address')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bu kaynaktaki bilgiler okunamadı.'), findsOneWidget);
    expect(find.text('Adres henüz girilmedi.'), findsNothing);
    expect(partialSource.mutationCalls, 0);

    final emptySource = _FakeProjectInformationSource.standard();
    await tester.pumpWidget(_testApp(emptySource));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-address')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Adres henüz girilmedi.'), findsOneWidget);

    final failedSource = _FakeProjectInformationSource.standard()
      ..projectFailure = StateError('project unavailable');
    await tester.pumpWidget(_testApp(failedSource));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-information-error')), findsOneWidget);
    expect(
      find.text('Proje bilgileri güvenli biçimde okunamadı.'),
      findsOneWidget,
    );
  });

  testWidgets('project switch never paints a stale snapshot', (tester) async {
    final source = _FakeProjectInformationSource.standard(
      includeProjectB: true,
    );
    final delayedA = Completer<MobileProject>();
    source.projectReads[_projectA] = [delayedA.future];
    final application = ProjectInformationApplication(source: source);
    const pageKey = ValueKey('stable-project-information-page');

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectInformationPage(
          key: pageKey,
          application: application,
          projectId: _projectA,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('project-information-loading')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectInformationPage(
          key: pageKey,
          application: application,
          projectId: _projectB,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('project-information-project-name')).first,
          )
          .data,
      'B Projesi',
    );
    expect(find.text('A Projesi'), findsNothing);

    delayedA.complete(source.projects[_projectA]);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('project-information-project-name')).first,
          )
          .data,
      'B Projesi',
    );
    expect(find.text('A Projesi'), findsNothing);
  });

  testWidgets('archived custom field is explicit and only restore mutates', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    source.profileEventsByProject[_projectA] = [
      _profileEvent(
        id: 'event-create',
        fieldId: 'archived-field',
        sequence: 1,
        type: ProjectProfileEventType.fieldCreated,
        payload: {
          'label': 'Eski not',
          'value': 'Korunan değer',
          'sort_order': 7,
        },
      ),
      _profileEvent(
        id: 'event-archive',
        fieldId: 'archived-field',
        sequence: 2,
        type: ProjectProfileEventType.fieldArchived,
        payload: {
          'was_archived': false,
          'is_archived': true,
          'revision_before': 1,
          'revision_after': 2,
          'sort_order': 7,
        },
      ),
    ];
    final profileApplication = _RestoreProfileApplication(source);

    await tester.pumpWidget(
      _testApp(source, profileApplication: profileApplication),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-archived-fields')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.text('Arşivlenmiş özel alanlar'), findsOneWidget);
    expect(find.text('1 alan · kayıtlar korunuyor'), findsOneWidget);
    await tester.tap(find.text('Arşivlenmiş özel alanlar'));
    await tester.pumpAndSettle();
    expect(find.text('Eski not'), findsOneWidget);
    expect(find.text('Korunan değer'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('project-information-restore-archived-field')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -48));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('project-information-restore-archived-field')),
    );
    await tester.pumpAndSettle();

    expect(profileApplication.commands, hasLength(1));
    expect(profileApplication.commands.single.projectId, _projectA);
    expect(profileApplication.commands.single.fieldId, 'archived-field');
    expect(profileApplication.commands.single.archive, isFalse);
    expect(profileApplication.commands.single.expectedRevision, 2);
    expect(
      find.byKey(const Key('project-information-archived-fields')),
      findsNothing,
    );
    expect(source.mutationCalls, 0);
  });

  testWidgets('failed and unresolved sources never look empty or actionable', (
    tester,
  ) async {
    final failedSource = _FakeProjectInformationSource.standard()
      ..partyFailure = StateError('party unavailable')
      ..inventoryFailure = StateError('inventory unavailable');
    await tester.pumpWidget(_testApp(failedSource));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      'işveren',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Atama durumu okunamadı; kayıtlar korundu'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('project-information-copy-party-employer')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      'aktif blok sayısı',
    );
    await tester.pumpAndSettle();
    expect(find.text('Okunamadı; kayıtlar korundu'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('project-information-copy-derived-active-blocks'),
      ),
      findsNothing,
    );

    final archivedTargetSource = _FakeProjectInformationSource.standard();
    archivedTargetSource.partiesByProject[_projectA] = [
      _party('party-employer', subcontractorId: 'company-employer'),
    ];
    archivedTargetSource.companiesByProject[_projectA] = [
      _company('company-employer', active: false),
    ];
    await tester.pumpWidget(_testApp(archivedTargetSource));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      'işveren',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('kayıt arşivli'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('project-information-copy-party-employer')),
      findsNothing,
    );

    final unresolvedSource = _FakeProjectInformationSource.standard();
    unresolvedSource.inventoryByProject[_projectA] = _inventory(
      blocks: const [],
      floors: [_floor('orphan-floor', 'missing-block', 'Bağsız Kat')],
    );
    unresolvedSource.locationsByProject[_projectA] = [
      _location('location-a', 'Bağsız Mahal'),
    ];
    unresolvedSource.floorLocationsByProject[_projectA] = [
      _floorLocation('orphan-relation', 'missing-floor', 'location-a'),
    ];
    await tester.pumpWidget(_testApp(unresolvedSource));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-blocks')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const Key('project-information-section-blocks')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Çözümlenemeyen yapı kayıtları'), findsOneWidget);
    expect(find.text('Bağsız Kat'), findsOneWidget);
    expect(find.text('Bağlı blok bulunamadı'), findsOneWidget);
    expect(find.text('Bağsız Mahal'), findsOneWidget);
    expect(find.text('Bağlı kat bulunamadı'), findsOneWidget);
  });

  testWidgets('failed floor-location read is not shown as no connection', (
    tester,
  ) async {
    final source = _FakeProjectInformationSource.standard();
    source.inventoryByProject[_projectA] = _inventory(
      blocks: [_block('block-a', 'A Blok')],
      floors: [_floor('floor-a', 'block-a', 'Zemin Kat')],
    );
    source.blockMetadataById['block-a'] = _blockMetadata('block-a');
    source.floorLocationFailure = StateError('relations unavailable');
    await tester.pumpWidget(_testApp(source));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      'zemin kat',
    );
    await tester.pumpAndSettle();
    expect(find.text('Zemin Kat'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('project-information-search')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('project-information-section-blocks')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const Key('project-information-section-blocks')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('A Blok'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A Blok'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Zemin Kat'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zemin Kat'));
    await tester.pumpAndSettle();
    expect(
      find.text('Mahal bağlantıları okunamadı. Kayıtlar korundu.'),
      findsOneWidget,
    );
    expect(find.text('Mahal bağlantısı bulunmuyor.'), findsNothing);
  });
}

Widget _testApp(
  _FakeProjectInformationSource source, {
  ProjectProfileApplication? profileApplication,
  ProjectInformationTextAction? copyText,
  ProjectInformationTextAction? shareText,
}) => MaterialApp(
  home: ProjectInformationPage(
    application: ProjectInformationApplication(source: source),
    projectId: _projectA,
    profileApplication: profileApplication,
    copyText: copyText,
    shareText: shareText,
  ),
);

class _RestoreProfileApplication implements ProjectProfileApplication {
  _RestoreProfileApplication(this.source);

  final _FakeProjectInformationSource source;
  final List<MutateProjectProfileFieldArchiveCommand> commands = [];

  @override
  Future<ProjectProfileField> mutateProjectProfileFieldArchive(
    MutateProjectProfileFieldArchiveCommand command,
  ) async {
    commands.add(command);
    final restored = _profileField(
      command.fieldId,
      label: 'Eski not',
      value: 'Korunan değer',
      sortOrder: 7,
      revision: command.expectedRevision + 1,
    );
    source.profileEventsByProject[command.projectId] = [];
    source.profileByProject[command.projectId] = ProjectProfile(
      project: source.projects[command.projectId]!,
      fields: [
        ..._emptyProfile(source.projects[command.projectId]!).fields,
        restored,
      ],
    );
    return restored;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProjectInformationSource implements ProjectInformationReadSource {
  _FakeProjectInformationSource.standard({bool includeProjectB = false}) {
    _seedProject(_projectA);
    if (includeProjectB) _seedProject(_projectB);
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
  final Map<String, List<MobileProjectLocation>> locationsByProject = {};
  final Map<String, List<ProjectFloorLocationRelation>>
  floorLocationsByProject = {};
  Object? projectFailure;
  Object? metadataFailure;
  Object? partyFailure;
  Object? inventoryFailure;
  Object? floorLocationFailure;
  int mutationCalls = 0;

  void _seedProject(String projectId) {
    final project = _project(projectId);
    projects[projectId] = project;
    metadataByProject[projectId] = _metadata(projectId);
    profileByProject[projectId] = _emptyProfile(project);
    partiesByProject[projectId] = [];
    companiesByProject[projectId] = [];
    membersByProject[projectId] = [];
    inventoryByProject[projectId] = null;
    locationsByProject[projectId] = [];
    floorLocationsByProject[projectId] = [];
  }

  @override
  Future<MobileProject> getProject(String projectId) async {
    if (projectFailure != null) throw projectFailure!;
    final queued = projectReads[projectId];
    if (queued != null && queued.isNotEmpty) return queued.removeAt(0);
    return projects[projectId] ?? (throw StateError('missing project'));
  }

  @override
  Future<ProjectMetadata> getProjectMetadata(String projectId) async {
    if (metadataFailure != null) throw metadataFailure!;
    return metadataByProject[projectId] ?? _metadata(projectId);
  }

  @override
  Future<ProjectProfile> getProjectProfile(String projectId) async =>
      profileByProject[projectId] ?? _emptyProfile(projects[projectId]!);

  @override
  Future<List<ProjectProfileEvent>> listProjectProfileEvents(
    String projectId,
  ) async => profileEventsByProject[projectId] ?? const [];

  @override
  Future<List<ProjectPartyAssignment>> listProjectPartyAssignments(
    String projectId,
  ) async {
    if (partyFailure != null) throw partyFailure!;
    return partiesByProject[projectId] ?? const [];
  }

  @override
  Future<List<Subcontractor>> listCompanies(String projectId) async =>
      companiesByProject[projectId] ?? const [];

  @override
  Future<List<WorkforceMember>> listWorkforceMembers(String projectId) async =>
      membersByProject[projectId] ?? const [];

  @override
  Future<InventoryPrimarySketchProjection?> loadInventory(
    String projectId,
  ) async {
    if (inventoryFailure != null) throw inventoryFailure!;
    return inventoryByProject[projectId];
  }

  @override
  Future<InventoryBlockMetadataRecord> loadBlockMetadata({
    required String projectId,
    required String blockId,
  }) async => blockMetadataById[blockId] ?? _blockMetadata(blockId);

  @override
  Future<List<MobileProjectLocation>> listLocations(String projectId) async =>
      locationsByProject[projectId] ?? const [];

  @override
  Future<List<ProjectFloorLocationRelation>> listFloorLocations(
    String projectId,
  ) async {
    if (floorLocationFailure != null) throw floorLocationFailure!;
    return floorLocationsByProject[projectId] ?? const [];
  }
}

MobileProject _project(String id) => MobileProject(
  id: id,
  name: id == _projectA ? 'A Projesi' : 'B Projesi',
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  revision: 1,
);

ProjectMetadata _metadata(String projectId, {String? address}) =>
    ProjectMetadata(
      projectId: projectId,
      revision: 1,
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
  required String label,
  required String value,
  required int sortOrder,
  int revision = 1,
}) => ProjectProfileField(
  id: id,
  projectId: _projectA,
  label: label,
  value: value,
  sortOrder: sortOrder,
  revision: revision,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: null,
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

ProjectPartyAssignment _party(String id, {required String subcontractorId}) =>
    ProjectPartyAssignment(
      id: id,
      projectId: _projectA,
      role: ProjectPartyRole.employer,
      subcontractorId: subcontractorId,
      workforceMemberId: null,
      revision: 1,
      createdAt: '2026-09-13T09:00:00.000Z',
      updatedAt: '2026-09-13T09:00:00.000Z',
    );

Subcontractor _company(String id, {required bool active}) => Subcontractor(
  id: id,
  projectId: _projectA,
  name: 'İşveren Firma',
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
  String id,
  String name, {
  InventoryBlockState state = InventoryBlockState.active,
}) => InventoryBlockRecord(
  id: id,
  projectId: _projectA,
  displayName: name,
  normalizedName: name.toLowerCase(),
  ordinal: 1,
  state: state,
  revision: 1,
  createdAt: _now,
  updatedAt: _now,
  archivedAt: state == InventoryBlockState.archived ? _now : null,
);

InventoryFloorRecord _floor(
  String id,
  String blockId,
  String name, {
  bool archived = false,
}) => InventoryFloorRecord(
  id: id,
  blockId: blockId,
  projectId: _projectA,
  displayName: name,
  ordinal: 1,
  revision: 1,
  createdAt: _now,
  updatedAt: _now,
  archivedAt: archived ? _now : null,
);

InventoryBlockMetadataRecord _blockMetadata(
  String blockId, {
  double? totalArea,
  String? totalAreaUnit,
  String? usageType,
}) => InventoryBlockMetadataRecord(
  blockId: blockId,
  projectId: _projectA,
  basementCount: null,
  basementClassification: null,
  totalArea: totalArea,
  totalAreaUnit: totalAreaUnit,
  footprintArea: null,
  footprintAreaUnit: null,
  independentUnitCount: null,
  usageType: usageType,
  revision: totalArea != null || usageType != null ? 1 : 0,
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
  String locationId,
) => ProjectFloorLocationRelation(
  id: id,
  projectId: _projectA,
  floorId: floorId,
  locationId: locationId,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  archivedAt: null,
);
