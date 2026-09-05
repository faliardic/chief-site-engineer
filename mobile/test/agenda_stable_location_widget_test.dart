import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/agenda/project_location_catalog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectA = '11111111-1111-4111-8111-111111111111';
const _projectB = '22222222-2222-4222-8222-222222222222';
const _root = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _child = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _other = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3';
const _log = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';

void main() {
  testWidgets('null ProjectLocation dependency preserves V1 free-text field', (
    tester,
  ) async {
    final agenda = RecordingAgendaApplication(projects: [_project(_projectA)]);
    await _pumpForm(tester, agenda: agenda);

    expect(find.byKey(const Key('log-location')), findsOneWidget);
    expect(find.byKey(const Key('log-location-selector')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('log-location')),
      'Serbest mahal',
    );
    await tester.enterText(
      find.byKey(const Key('log-description')),
      'Legacy kayıt',
    );
    await _tapSubmit(tester);
    expect(agenda.lastCreated?.locationId, isNull);
    expect(agenda.lastCreated?.location, 'Serbest mahal');
  });

  testWidgets('stable selector renders hierarchy and create sends locationId', (
    tester,
  ) async {
    final agenda = RecordingAgendaApplication(projects: [_project(_projectA)]);
    final locations = FakeLocationApplication(
      projects: agenda.projects,
      locations: [
        _location(_root, _projectA, 'A Blok'),
        _location(_child, _projectA, '1. Kat', parentId: _root),
      ],
    );
    await _pumpForm(tester, agenda: agenda, locations: locations);

    await tester.ensureVisible(find.byKey(const Key('log-location-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log-location-selector')));
    await tester.pumpAndSettle();
    expect(find.text('A Blok › 1. Kat'), findsOneWidget);
    expect(find.textContaining(_child), findsNothing);
    await tester.tap(find.text('A Blok › 1. Kat'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('log-description')),
      'Stable kayıt',
    );
    await _tapSubmit(tester);
    expect(agenda.lastCreated?.locationId, _child);
  });

  testWidgets(
    'project switch reloads and clears the previous stable selection',
    (tester) async {
      final agenda = RecordingAgendaApplication(
        projects: [
          _project(_projectA),
          _project(_projectB, name: 'Güney'),
        ],
      );
      final locations = FakeLocationApplication(
        projects: agenda.projects,
        locations: [
          _location(_root, _projectA, 'A Blok'),
          _location(_other, _projectB, 'Güney Blok'),
        ],
      );
      await _pumpForm(tester, agenda: agenda, locations: locations);
      await _selectDropdownText(
        tester,
        const Key('log-location-selector'),
        'A Blok',
      );
      await _selectDropdownText(tester, const Key('log-project'), 'Güney');

      expect(locations.lastListedProjectId, _projectB);
      final selector = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('log-location-selector')),
      );
      expect(selector.initialValue, isNull);
      await tester.ensureVisible(
        find.byKey(const Key('log-location-selector')),
      );
      await tester.tap(find.byKey(const Key('log-location-selector')));
      await tester.pumpAndSettle();
      expect(find.text('Güney Blok'), findsOneWidget);
      expect(find.text('A Blok'), findsNothing);
    },
  );

  testWidgets('empty and safe load-failure states never expose raw errors', (
    tester,
  ) async {
    final agenda = RecordingAgendaApplication(projects: [_project(_projectA)]);
    final locations = FakeLocationApplication(
      projects: agenda.projects,
      listFailure: StateError('raw location failure'),
    );
    await _pumpForm(tester, agenda: agenda, locations: locations);
    expect(find.byKey(const Key('log-location-load-error')), findsOneWidget);
    expect(find.textContaining('raw location failure'), findsNothing);

    locations.listFailure = null;
    await tester.ensureVisible(find.byKey(const Key('retry-log-locations')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('retry-log-locations')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('log-location-empty')), findsOneWidget);
  });

  testWidgets('catalog round-trip refreshes locations without losing draft', (
    tester,
  ) async {
    final agenda = RecordingAgendaApplication(projects: [_project(_projectA)]);
    final locations = FakeLocationApplication(projects: agenda.projects);
    await _pumpForm(tester, agenda: agenda, locations: locations);
    await tester.enterText(
      find.byKey(const Key('log-description')),
      'Korunan taslak',
    );

    await tester.ensureVisible(
      find.byKey(const Key('open-location-catalog-from-log')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-location-catalog-from-log')));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectLocationCatalogPage), findsOneWidget);
    locations.locations = [_location(_root, _projectA, 'Yeni Mahal')];
    await tester.pageBack();
    await tester.pumpAndSettle();

    final description = tester.widget<TextFormField>(
      find.byKey(const Key('log-description')),
    );
    expect(description.controller?.text, 'Korunan taslak');
    await tester.ensureVisible(find.byKey(const Key('log-location-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log-location-selector')));
    await tester.pumpAndSettle();
    expect(find.text('Yeni Mahal'), findsOneWidget);
  });

  testWidgets('active linked log preselects the current location', (
    tester,
  ) async {
    final active = _agendaLog(
      locationId: _root,
      snapshot: 'A Blok eski',
      currentName: 'A Blok güncel',
    );
    final agenda = RecordingAgendaApplication(
      projects: [_project(_projectA)],
      logs: [active],
    );
    final locations = FakeLocationApplication(
      projects: agenda.projects,
      locations: [_location(_root, _projectA, 'A Blok güncel')],
    );
    await _pumpForm(
      tester,
      agenda: agenda,
      locations: locations,
      existing: active,
    );
    expect(find.text('A Blok güncel'), findsOneWidget);
  });

  testWidgets('archived linked log preserves the link on unrelated edit', (
    tester,
  ) async {
    final archived = _agendaLog(
      locationId: _root,
      snapshot: 'A Blok eski',
      currentName: 'A Blok güncel',
      locationArchivedAt: '2026-08-09T08:00:00Z',
    );
    final agenda = RecordingAgendaApplication(
      projects: [_project(_projectA)],
      logs: [archived],
    );
    final locations = FakeLocationApplication(projects: agenda.projects);
    await _pumpForm(
      tester,
      agenda: agenda,
      locations: locations,
      existing: archived,
    );
    await _scrollToKey(tester, const Key('archived-location-context'));
    expect(find.byKey(const Key('archived-location-context')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('log-description')),
      'Yalnız açıklama değişti',
    );
    await _tapSubmit(tester);
    expect(agenda.lastUpdated?.locationId, _root);
  });

  testWidgets('legacy edit does not auto-map and preserves free text', (
    tester,
  ) async {
    final legacy = _agendaLog(snapshot: 'Aynı İsim');
    final agenda = RecordingAgendaApplication(
      projects: [_project(_projectA)],
      logs: [legacy],
    );
    final locations = FakeLocationApplication(
      projects: agenda.projects,
      locations: [_location(_root, _projectA, 'Aynı İsim')],
    );
    await _pumpForm(
      tester,
      agenda: agenda,
      locations: locations,
      existing: legacy,
    );
    expect(find.text('Eski serbest mahal: Aynı İsim'), findsOneWidget);
    await _tapSubmit(tester);
    expect(agenda.lastUpdated?.locationId, isNull);
    expect(agenda.lastUpdated?.location, 'Aynı İsim');
  });

  testWidgets('explicit stable selection upgrades only the edited legacy log', (
    tester,
  ) async {
    final legacy = _agendaLog(snapshot: 'Aynı İsim');
    final agenda = RecordingAgendaApplication(
      projects: [_project(_projectA)],
      logs: [legacy],
    );
    final locations = FakeLocationApplication(
      projects: agenda.projects,
      locations: [_location(_root, _projectA, 'Aynı İsim')],
    );
    await _pumpForm(
      tester,
      agenda: agenda,
      locations: locations,
      existing: legacy,
    );
    await _selectDropdownText(
      tester,
      const Key('log-location-selector'),
      'Aynı İsim',
    );
    await _tapSubmit(tester);
    expect(agenda.lastUpdated?.locationId, _root);
  });

  testWidgets(
    'Agenda card and detail use current stable name and archive label',
    (tester) async {
      final linked = _agendaLog(
        locationId: _root,
        snapshot: 'Tarihsel Ad',
        currentName: 'Güncel Ad',
        locationArchivedAt: '2026-08-09T08:00:00Z',
      );
      final agenda = RecordingAgendaApplication(
        projects: [_project(_projectA)],
        logs: [linked],
      );
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: agenda)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Güncel Ad'), findsOneWidget);
      expect(find.textContaining('Tarihsel Ad'), findsNothing);

      await tester.tap(find.byKey(const Key('agenda-log-$_log')));
      await tester.pumpAndSettle();
      expect(find.text('Güncel Ad'), findsOneWidget);
      expect(
        find.byKey(const Key('archived-stable-location-indicator')),
        findsOneWidget,
      );
    },
  );

  testWidgets('stable selector stays overflow-free at 390x760', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final agenda = RecordingAgendaApplication(projects: [_project(_projectA)]);
    final locations = FakeLocationApplication(
      projects: agenda.projects,
      locations: [
        _location(
          _root,
          _projectA,
          'Çok uzun kök mahal adı küçük ekranda taşmamalıdır',
        ),
        _location(
          _child,
          _projectA,
          'Çok uzun alt mahal adı güvenli biçimde kısalmalıdır',
          parentId: _root,
        ),
      ],
    );
    await _pumpForm(tester, agenda: agenda, locations: locations);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('log-location-selector')));
    await tester.ensureVisible(find.byKey(const Key('log-location-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log-location-selector')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required RecordingAgendaApplication agenda,
  FakeLocationApplication? locations,
  AgendaLog? existing,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LogFormPage(
        agenda: agenda,
        projectLocations: locations,
        existing: existing,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final optional = find.byKey(const Key('log-optional-details'));
  await tester.ensureVisible(optional);
  await tester.tap(optional);
  await tester.pumpAndSettle();
}

Future<void> _selectDropdownText(
  WidgetTester tester,
  Key key,
  String text,
) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _scrollToKey(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  final listView = find.byType(ListView);
  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(listView, const Offset(0, -250));
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await _scrollToKey(tester, const Key('submit-log'));
  await tester.tap(find.byKey(const Key('submit-log')));
  await tester.pumpAndSettle();
}

MobileProject _project(String id, {String name = 'Kuzey'}) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-08-09T06:00:00Z',
  updatedAt: '2026-08-09T06:00:00Z',
  revision: 1,
);

MobileProjectLocation _location(
  String id,
  String projectId,
  String name, {
  String? parentId,
}) => MobileProjectLocation(
  id: id,
  projectId: projectId,
  displayName: name,
  parentLocationId: parentId,
  revision: 1,
  createdAt: '2026-08-09T06:00:00Z',
  updatedAt: '2026-08-09T06:00:00Z',
  archivedAt: null,
);

AgendaLog _agendaLog({
  String? locationId,
  String? snapshot,
  String? currentName,
  String? locationArchivedAt,
}) => AgendaLog(
  id: _log,
  projectId: _projectA,
  projectName: 'Kuzey',
  observedAt: '2026-08-09T07:00:00Z',
  createdAt: '2026-08-09T07:00:00Z',
  updatedAt: '2026-08-09T07:00:00Z',
  category: AgendaCategory.inspection,
  description: 'Kontrol kaydı',
  location: snapshot,
  notes: 'Taslak not',
  revision: 1,
  locationId: locationId,
  stableLocationName: currentName,
  stableLocationArchivedAt: locationArchivedAt,
);

class RecordingAgendaApplication extends FakeAgendaApplication {
  RecordingAgendaApplication({super.projects, super.logs});

  CreateAgendaLogCommand? lastCreated;
  UpdateAgendaLogCommand? lastUpdated;

  @override
  Future<AgendaLog> createAgendaLog(CreateAgendaLogCommand command) async {
    lastCreated = command;
    return super.createAgendaLog(command);
  }

  @override
  Future<AgendaLog> updateAgendaLog(UpdateAgendaLogCommand command) async {
    lastUpdated = command;
    final current = logs.firstWhere((item) => item.id == command.id);
    return AgendaLog(
      id: current.id,
      projectId: command.projectId,
      projectName: current.projectName,
      observedAt: command.observedAt,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      category: command.category,
      description: command.description,
      location: command.location,
      notes: command.notes,
      revision: current.revision + 1,
      locationId: command.locationId,
      stableLocationName: current.stableLocationName,
      stableLocationArchivedAt: current.stableLocationArchivedAt,
    );
  }
}

class FakeLocationApplication implements ProjectLocationApplication {
  FakeLocationApplication({
    this.projects = const [],
    this.locations = const [],
    this.listFailure,
  });

  List<MobileProject> projects;
  List<MobileProjectLocation> locations;
  Object? listFailure;
  String? lastListedProjectId;
  final StreamController<void> _projectChanges =
      StreamController<void>.broadcast();
  final StreamController<void> _locationChanges =
      StreamController<void>.broadcast();

  @override
  Stream<void> get projectChanges => _projectChanges.stream;

  @override
  Stream<void> get projectLocationChanges => _locationChanges.stream;

  @override
  Future<List<MobileProject>> listProjects() async => projects;

  @override
  Future<MobileProject> createProject(CreateProjectCommand command) async {
    final created = _project(command.id, name: command.name);
    projects = [...projects, created];
    return created;
  }

  @override
  Future<List<MobileProjectLocation>> listProjectLocations(
    ProjectLocationQuery query,
  ) async {
    if (listFailure case final failure?) throw failure;
    lastListedProjectId = query.projectId;
    return locations
        .where(
          (item) =>
              item.projectId == query.projectId &&
              item.isArchived ==
                  (query.archiveFilter ==
                      ProjectLocationArchiveFilter.archived),
        )
        .toList(growable: false);
  }

  @override
  Future<MobileProjectLocation> getProjectLocation(String locationId) async =>
      locations.firstWhere((item) => item.id == locationId);

  @override
  Future<MobileProjectLocation> createProjectLocation(
    CreateProjectLocationCommand command,
  ) async => throw UnimplementedError();

  @override
  Future<MobileProjectLocation> renameProjectLocation(
    RenameProjectLocationCommand command,
  ) async => throw UnimplementedError();

  @override
  Future<MobileProjectLocation> reparentProjectLocation(
    ReparentProjectLocationCommand command,
  ) async => throw UnimplementedError();

  @override
  Future<MobileProjectLocation> mutateProjectLocationArchive(
    MutateProjectLocationArchiveCommand command,
  ) async => throw UnimplementedError();

  @override
  Future<List<ProjectLocationEvent>> listProjectLocationEvents(
    String locationId,
  ) async => const [];
}
