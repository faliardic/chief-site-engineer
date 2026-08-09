import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/agenda/project_location_catalog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectA = '11111111-1111-4111-8111-111111111111';
const _projectB = '22222222-2222-4222-8222-222222222222';
const _rootA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _rootB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _child = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _grandchild = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const _archived = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';

void main() {
  testWidgets(
    'Agenda catalog entry is typed-optional and preserves V1 null UI',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: [project(_projectA, 'Kuzey')],
      );
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: agenda)));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('open-project-location-catalog')),
        findsNothing,
      );

      final locations = FakeProjectLocationApplication(
        projects: [project(_projectA, 'Kuzey')],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AgendaPage(agenda: agenda, projectLocations: locations),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('open-project-location-catalog')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('open-project-location-catalog')));
      await tester.pumpAndSettle();
      expect(find.text('Mahal Kataloğu'), findsOneWidget);
    },
  );

  testWidgets('initial project is preferred and no-project state is safe', (
    tester,
  ) async {
    final fake = FakeProjectLocationApplication(
      projects: [project(_projectA, 'Kuzey'), project(_projectB, 'Güney')],
      locations: [
        location(_rootA, _projectA, 'Kuzey mahal'),
        location(_rootB, _projectB, 'Güney mahal'),
      ],
    );
    await pumpCatalog(tester, fake, initialProjectId: _projectB);
    expect(find.text('Güney mahal'), findsOneWidget);
    expect(find.text('Kuzey mahal'), findsNothing);

    final empty = FakeProjectLocationApplication();
    await pumpCatalog(tester, empty);
    expect(
      find.text('Mahal yönetmek için önce aktif bir proje oluşturun.'),
      findsOneWidget,
    );
    final create = tester.widget<FilledButton>(
      find.byKey(const Key('create-project-location')),
    );
    expect(create.onPressed, isNull);
  });

  testWidgets('project switching reloads both active and archived lists', (
    tester,
  ) async {
    final fake = FakeProjectLocationApplication(
      projects: [project(_projectA, 'Kuzey'), project(_projectB, 'Güney')],
      locations: [
        location(_rootA, _projectA, 'Kuzey mahal'),
        location(_rootB, _projectB, 'Güney mahal'),
      ],
    );
    await pumpCatalog(tester, fake, initialProjectId: _projectA);
    expect(find.text('Kuzey mahal'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Güney').last);
    await tester.pumpAndSettle();

    expect(fake.lastListedProjectId, _projectB);
    expect(find.text('Güney mahal'), findsOneWidget);
    expect(find.text('Kuzey mahal'), findsNothing);
  });

  testWidgets('hierarchy shows parent context and filter isolates archives', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final fake = FakeProjectLocationApplication(
      projects: [project(_projectA, 'Kuzey')],
      locations: [
        location(_rootA, _projectA, 'A Blok'),
        location(_child, _projectA, '1. Kat', parentId: _rootA),
        location(
          _archived,
          _projectA,
          'Eski depo',
          archivedAt: '2026-08-09T08:00:00Z',
        ),
      ],
    );
    await pumpCatalog(tester, fake);
    expect(find.text('A Blok'), findsOneWidget);
    expect(find.text('1. Kat'), findsOneWidget);
    expect(find.text('Üst mahal: A Blok'), findsOneWidget);
    expect(find.bySemanticsLabel('1. Kat. Üst mahal: A Blok'), findsOneWidget);
    expect(find.text('Eski depo'), findsNothing);

    await tester.tap(find.text('Arşivlenenler'));
    await tester.pumpAndSettle();
    expect(find.text('Eski depo'), findsOneWidget);
    expect(find.text('A Blok'), findsNothing);
    semantics.dispose();
  });

  testWidgets('orphan and cyclic hierarchy falls back without hanging', (
    tester,
  ) async {
    final fake = FakeProjectLocationApplication(
      projects: [project(_projectA, 'Kuzey')],
      locations: [
        location(_rootA, _projectA, 'Döngü A', parentId: _rootB),
        location(_rootB, _projectA, 'Döngü B', parentId: _rootA),
        location(_child, _projectA, 'Yetim mahal', parentId: _grandchild),
      ],
    );
    await pumpCatalog(tester, fake);
    expect(
      find.text(
        'Bazı mahal ilişkileri güvenle gösterilemedi. Veriler değiştirilmedi.',
      ),
      findsOneWidget,
    );
    expect(find.text('Döngü A'), findsOneWidget);
    expect(find.text('Döngü B'), findsOneWidget);
    expect(find.text('Yetim mahal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create root and selected-parent child refresh automatically', (
    tester,
  ) async {
    final fake = FakeProjectLocationApplication(
      projects: [project(_projectA, 'Kuzey')],
    );
    await pumpCatalog(tester, fake);

    await tester.tap(find.byKey(const Key('create-project-location')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-location-name-input')),
      'A Blok',
    );
    await tester.tap(find.byKey(const Key('save-project-location')));
    await tester.pumpAndSettle();
    expect(fake.lastCreate?.parentLocationId, isNull);
    final rootId = fake.lastCreate!.id;
    expect(find.text('Mahal oluşturuldu.'), findsOneWidget);
    expect(find.byKey(Key('project-location-$rootId')), findsOneWidget);

    await openLocationAction(tester, rootId, 'Alt mahal oluştur');
    await tester.enterText(
      find.byKey(const Key('project-location-name-input')),
      '1. Kat',
    );
    await tester.tap(find.byKey(const Key('save-project-location')));
    await tester.pumpAndSettle();
    expect(fake.lastCreate?.parentLocationId, rootId);
    expect(find.text('1. Kat'), findsOneWidget);
    expect(find.text('Üst mahal: A Blok'), findsOneWidget);
  });

  testWidgets(
    'rename uses current revision and exposes safe validation failure',
    (tester) async {
      final fake = FakeProjectLocationApplication(
        projects: [project(_projectA, 'Kuzey')],
        locations: [location(_rootA, _projectA, 'Eski ad', revision: 4)],
      );
      await pumpCatalog(tester, fake);
      await openLocationAction(tester, _rootA, 'Yeniden adlandır');
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('rename-project-location-input')),
            )
            .controller!
            .text,
        'Eski ad',
      );
      await tester.enterText(
        find.byKey(const Key('rename-project-location-input')),
        'Yeni ad',
      );
      await tester.tap(find.byKey(const Key('save-project-location-rename')));
      await tester.pumpAndSettle();
      expect(fake.lastRename?.expectedRevision, 4);
      expect(find.text('Yeni ad'), findsOneWidget);
      expect(find.text('Mahal adı güncellendi.'), findsOneWidget);

      fake.renameFailure = const AgendaValidationFailure(
        'Aynı kardeş adı var.',
      );
      await openLocationAction(tester, _rootA, 'Yeniden adlandır');
      await tester.enterText(
        find.byKey(const Key('rename-project-location-input')),
        'Çakışan ad',
      );
      await tester.tap(find.byKey(const Key('save-project-location-rename')));
      await tester.pumpAndSettle();
      expect(find.text('Aynı kardeş adı var.'), findsOneWidget);
      expect(find.text('Yeni ad'), findsOneWidget);
    },
  );

  testWidgets(
    'reparent supports another parent and root while blocking cycles',
    (tester) async {
      final fake = FakeProjectLocationApplication(
        projects: [project(_projectA, 'Kuzey')],
        locations: [
          location(_rootA, _projectA, 'Root 1'),
          location(_rootB, _projectA, 'Root 2'),
          location(_child, _projectA, 'Child', parentId: _rootA),
          location(_grandchild, _projectA, 'Grandchild', parentId: _child),
        ],
      );
      await pumpCatalog(tester, fake);

      await openLocationAction(tester, _rootA, 'Üst mahali değiştir');
      expect(dropdownItem(_rootA), findsNothing);
      expect(dropdownItem(_child), findsNothing);
      expect(dropdownItem(_grandchild), findsNothing);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      await openLocationAction(tester, _child, 'Üst mahali değiştir');
      await tester.tap(
        find.byKey(const Key('project-location-parent-selector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Root 2').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-project-location-parent')));
      await tester.pumpAndSettle();
      expect(fake.lastReparent?.parentLocationId, _rootB);

      await openLocationAction(tester, _child, 'Üst mahali değiştir');
      await tester.tap(
        find.byKey(const Key('project-location-parent-selector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kök mahal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-project-location-parent')));
      await tester.pumpAndSettle();
      expect(fake.lastReparent?.parentLocationId, isNull);
    },
  );

  testWidgets('archive confirms and restore surfaces success and failures', (
    tester,
  ) async {
    final fake = FakeProjectLocationApplication(
      projects: [project(_projectA, 'Kuzey')],
      locations: [location(_rootA, _projectA, 'A Blok')],
    );
    await pumpCatalog(tester, fake);

    fake.archiveFailure = const AgendaValidationFailure(
      'Aktif alt mahali bulunan mahal arşivlenemez.',
    );
    await openLocationAction(tester, _rootA, 'Arşivle');
    expect(fake.archiveCalls, 0);
    await tester.tap(find.byKey(const Key('confirm-project-location-archive')));
    await tester.pumpAndSettle();
    expect(fake.archiveCalls, 1);
    expect(
      find.text('Aktif alt mahali bulunan mahal arşivlenemez.'),
      findsOneWidget,
    );
    expect(find.text('A Blok'), findsOneWidget);

    fake.archiveFailure = null;
    await openLocationAction(tester, _rootA, 'Arşivle');
    await tester.tap(find.byKey(const Key('confirm-project-location-archive')));
    await tester.pumpAndSettle();
    expect(find.text('Mahal arşivlendi.'), findsOneWidget);
    expect(find.text('A Blok'), findsNothing);

    await tester.tap(find.text('Arşivlenenler'));
    await tester.pumpAndSettle();
    expect(find.text('A Blok'), findsOneWidget);
    fake.restoreFailure = const AgendaValidationFailure(
      'Üst mahal arşivli olduğu için geri getirilemez.',
    );
    await tester.tap(find.byKey(Key('restore-project-location-$_rootA')));
    await tester.pumpAndSettle();
    expect(
      find.text('Üst mahal arşivli olduğu için geri getirilemez.'),
      findsOneWidget,
    );

    fake.restoreFailure = null;
    await tester.tap(find.byKey(Key('restore-project-location-$_rootA')));
    await tester.pumpAndSettle();
    expect(find.text('Mahal geri getirildi.'), findsOneWidget);
    expect(find.text('A Blok'), findsNothing);
  });

  testWidgets('pending mutation blocks duplicate submit', (tester) async {
    final completer = Completer<MobileProjectLocation>();
    final fake = FakeProjectLocationApplication(
      projects: [project(_projectA, 'Kuzey')],
      createCompleter: completer,
    );
    await pumpCatalog(tester, fake);
    await tester.tap(find.byKey(const Key('create-project-location')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-location-name-input')),
      'Bekleyen mahal',
    );
    await tester.tap(find.byKey(const Key('save-project-location')));
    await tester.pump();
    expect(fake.createCalls, 1);
    expect(
      find.byKey(const Key('project-location-mutation-progress')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('create-project-location')));
    await tester.pump();
    expect(fake.createCalls, 1);

    final command = fake.lastCreate!;
    completer.complete(
      location(command.id, command.projectId, command.displayName),
    );
    await tester.pumpAndSettle();
    expect(fake.createCalls, 1);
  });

  testWidgets('project and location streams refresh external changes', (
    tester,
  ) async {
    final fake = FakeProjectLocationApplication(
      projects: [project(_projectA, 'Kuzey')],
    );
    await pumpCatalog(tester, fake);
    expect(find.text('Dış mahal'), findsNothing);

    fake.locations = [location(_rootA, _projectA, 'Dış mahal')];
    fake.emitLocationChange();
    await tester.pumpAndSettle();
    expect(find.text('Dış mahal'), findsOneWidget);

    fake.projects = [project(_projectA, 'Kuzey'), project(_projectB, 'Güney')];
    fake.emitProjectChange();
    await tester.pumpAndSettle();
    expect(dropdownItem(_projectB), findsOneWidget);
  });

  testWidgets('read failure is safe and retry recovers', (tester) async {
    final fake = FakeProjectLocationApplication(
      projects: [project(_projectA, 'Kuzey')],
      listFailure: StateError('raw failure'),
    );
    await pumpCatalog(tester, fake);
    expect(
      find.text('Mahal Kataloğu güvenli biçimde okunamadı.'),
      findsOneWidget,
    );
    expect(find.textContaining('raw failure'), findsNothing);

    fake.listFailure = null;
    await tester.tap(find.byKey(const Key('retry-project-location-catalog')));
    await tester.pumpAndSettle();
    expect(find.text('Bu projede aktif mahal yok.'), findsOneWidget);
  });

  testWidgets('compact and tall viewports remain overflow-free with dialog', (
    tester,
  ) async {
    final fake = FakeProjectLocationApplication(
      projects: [
        project(
          _projectA,
          'Çok uzun proje adı küçük ekranda güvenli biçimde kısaltılmalıdır',
        ),
      ],
      locations: [
        location(
          _rootA,
          _projectA,
          'Çok uzun kök mahal adı küçük ekranda taşma üretmemelidir',
        ),
        location(
          _child,
          _projectA,
          'Çok uzun alt mahal adı güvenli biçimde görünmelidir',
          parentId: _rootA,
        ),
      ],
    );
    await setViewport(tester, const Size(390, 760));
    await pumpCatalog(tester, fake);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('create-project-location')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-location-name-input')),
      'Klavye açık mahal',
    );
    await tester.ensureVisible(find.byKey(const Key('save-project-location')));
    expect(
      find.byKey(const Key('save-project-location')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    await setViewport(tester, const Size(430, 1200));
    await tester.pumpWidget(
      MaterialApp(home: ProjectLocationCatalogPage(application: fake)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Finder dropdownItem(String value) => find.byWidgetPredicate(
  (widget) => widget is DropdownMenuItem<String> && widget.value == value,
  skipOffstage: false,
);

Future<void> openLocationAction(
  WidgetTester tester,
  String locationId,
  String actionLabel,
) async {
  await tester.tap(find.byKey(Key('project-location-actions-$locationId')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(actionLabel).last);
  await tester.pumpAndSettle();
}

Future<void> pumpCatalog(
  WidgetTester tester,
  FakeProjectLocationApplication fake, {
  String? initialProjectId,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProjectLocationCatalogPage(
        application: fake,
        initialProjectId: initialProjectId,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

MobileProject project(String id, String name) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  revision: 1,
);

MobileProjectLocation location(
  String id,
  String projectId,
  String name, {
  String? parentId,
  int revision = 1,
  String? archivedAt,
}) => MobileProjectLocation(
  id: id,
  projectId: projectId,
  displayName: name,
  parentLocationId: parentId,
  revision: revision,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: archivedAt,
);

class FakeProjectLocationApplication implements ProjectLocationApplication {
  FakeProjectLocationApplication({
    this.projects = const [],
    this.locations = const [],
    this.listFailure,
    this.createCompleter,
  });

  List<MobileProject> projects;
  List<MobileProjectLocation> locations;
  Object? listFailure;
  Object? renameFailure;
  Object? reparentFailure;
  Object? archiveFailure;
  Object? restoreFailure;
  Completer<MobileProjectLocation>? createCompleter;
  CreateProjectLocationCommand? lastCreate;
  RenameProjectLocationCommand? lastRename;
  ReparentProjectLocationCommand? lastReparent;
  MutateProjectLocationArchiveCommand? lastArchiveMutation;
  String? lastListedProjectId;
  int createCalls = 0;
  int archiveCalls = 0;
  final StreamController<void> _projectChanges =
      StreamController<void>.broadcast();
  final StreamController<void> _locationChanges =
      StreamController<void>.broadcast();

  @override
  Stream<void> get projectChanges => _projectChanges.stream;

  @override
  Stream<void> get projectLocationChanges => _locationChanges.stream;

  void emitProjectChange() => _projectChanges.add(null);

  void emitLocationChange() => _locationChanges.add(null);

  @override
  Future<List<MobileProject>> listProjects() async {
    if (listFailure case final failure?) throw failure;
    return projects;
  }

  @override
  Future<MobileProject> createProject(CreateProjectCommand command) async {
    final created = project(command.id, command.name.trim());
    projects = [...projects, created];
    emitProjectChange();
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
  ) async {
    createCalls += 1;
    lastCreate = command;
    final pending = createCompleter;
    final created = pending == null
        ? location(
            command.id,
            command.projectId,
            command.displayName.trim(),
            parentId: command.parentLocationId,
          )
        : await pending.future;
    locations = [...locations, created];
    emitLocationChange();
    return created;
  }

  @override
  Future<MobileProjectLocation> renameProjectLocation(
    RenameProjectLocationCommand command,
  ) async {
    lastRename = command;
    if (renameFailure case final failure?) throw failure;
    return _replace(
      command.locationId,
      (current) => location(
        current.id,
        current.projectId,
        command.displayName.trim(),
        parentId: current.parentLocationId,
        revision: current.revision + 1,
        archivedAt: current.archivedAt,
      ),
    );
  }

  @override
  Future<MobileProjectLocation> reparentProjectLocation(
    ReparentProjectLocationCommand command,
  ) async {
    lastReparent = command;
    if (reparentFailure case final failure?) throw failure;
    return _replace(
      command.locationId,
      (current) => location(
        current.id,
        current.projectId,
        current.displayName,
        parentId: command.parentLocationId,
        revision: current.revision + 1,
        archivedAt: current.archivedAt,
      ),
    );
  }

  @override
  Future<MobileProjectLocation> mutateProjectLocationArchive(
    MutateProjectLocationArchiveCommand command,
  ) async {
    lastArchiveMutation = command;
    archiveCalls += command.archive ? 1 : 0;
    final failure = command.archive ? archiveFailure : restoreFailure;
    if (failure != null) throw failure;
    return _replace(
      command.locationId,
      (current) => location(
        current.id,
        current.projectId,
        current.displayName,
        parentId: current.parentLocationId,
        revision: current.revision + 1,
        archivedAt: command.archive ? '2026-08-09T09:00:00Z' : null,
      ),
    );
  }

  MobileProjectLocation _replace(
    String locationId,
    MobileProjectLocation Function(MobileProjectLocation current) update,
  ) {
    final index = locations.indexWhere((item) => item.id == locationId);
    final updated = update(locations[index]);
    locations = [...locations]..[index] = updated;
    emitLocationChange();
    return updated;
  }

  @override
  Future<List<ProjectLocationEvent>> listProjectLocationEvents(
    String locationId,
  ) async => const [];
}
