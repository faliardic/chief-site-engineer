import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets('zero projects keeps the existing New Project entry', (
    tester,
  ) async {
    final fixture = _Fixture(projects: const []);
    addTearDown(fixture.dispose);
    var createCalls = 0;

    await tester.pumpWidget(
      fixture.app(onCreateProject: () => createCalls += 1),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dashboard-create-project')));
    expect(createCalls, 1);
  });

  testWidgets('Home shows only exact Project Profile and compact tools', (
    tester,
  ) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project]);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('project-profile-home')), findsOneWidget);
    expect(find.byKey(const Key('project-profile-header')), findsOneWidget);
    expect(find.text('Kuzey'), findsOneWidget);
    expect(find.text('Toplam kat'), findsOneWidget);
    expect(find.text('Toplam alan'), findsOneWidget);
    expect(find.text('YİBF No'), findsOneWidget);
    expect(find.byKey(const Key('project-profile-tools')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-today-card')), findsNothing);
    expect(find.byKey(const Key('dashboard-plan-card')), findsNothing);
    expect(find.byKey(const Key('dashboard-materials-card')), findsNothing);
    expect(find.byKey(const Key('dashboard-quick-reminder')), findsNothing);
    expect(find.byKey(const Key('dashboard-concrete-package')), findsNothing);
    expect(find.byKey(const Key('dashboard-project-album')), findsNothing);
    expect(
      find.byKey(const Key('dashboard-workforce-directory')),
      findsNothing,
    );
    expect(find.byKey(const Key('dashboard-memory-backup')), findsNothing);
    expect(find.byKey(const Key('dashboard-attachment-catalog')), findsNothing);
  });

  testWidgets('builtin edit and custom add archive persist in Home state', (
    tester,
  ) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project]);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toplam kat'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-profile-edit-value')),
      '12',
    );
    await tester.tap(find.byKey(const Key('project-profile-save-field')));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.byKey(const Key('project-profile-add-field')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-profile-new-label')),
      'Yapı sınıfı',
    );
    await tester.enterText(
      find.byKey(const Key('project-profile-new-value')),
      '4A',
    );
    await tester.tap(find.byKey(const Key('project-profile-create-field')));
    await tester.pumpAndSettle();
    expect(find.text('Yapı sınıfı'), findsOneWidget);
    expect(find.text('4A'), findsOneWidget);

    final custom = fixture.agenda.projectProfileFields[project.id]!.singleWhere(
      (field) => !field.isBuiltIn,
    );
    await tester.tap(
      find.byKey(ValueKey('project-profile-archive-${custom.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('project-profile-confirm-archive')));
    await tester.pumpAndSettle();
    expect(find.text('Yapı sınıfı'), findsNothing);
  });

  testWidgets(
    'project name rename uses canonical revision and survives Home reload',
    (tester) async {
      final project = _project(
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'Kuzey',
        revision: 7,
      );
      final other = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
      final agenda = _RenamingAgenda(projects: [project, other]);
      final fixture = _Fixture(projects: agenda.projects, agenda: agenda);
      addTearDown(fixture.dispose);
      fixture.session.select(project.id, agenda.projects);
      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      final fieldsBefore = List.of(agenda.projectProfileFields[project.id]!);

      await _renameVisibleProject(tester, '  Yeni Kuzey  ');
      expect(find.text('Yeni Kuzey'), findsOneWidget);
      expect(find.text('Kuzey'), findsNothing);
      expect(fixture.session.selectedProjectId, project.id);
      expect(agenda.projects.first.name, 'Yeni Kuzey');
      expect(agenda.projects.first.revision, 8);
      expect(agenda.projects.last, same(other));
      final firstCommand = agenda.renameCommands.single;
      expect(firstCommand.projectId, project.id);
      expect(firstCommand.expectedRevision, 7);
      expect(firstCommand.name, 'Yeni Kuzey');
      expect(
        firstCommand.eventId,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );

      await _renameVisibleProject(tester, 'Son Kuzey');
      expect(agenda.renameCommands, hasLength(2));
      expect(agenda.renameCommands.last.expectedRevision, 8);
      expect(agenda.renameCommands.last.eventId, isNot(firstCommand.eventId));
      expect(find.text('Son Kuzey'), findsOneWidget);
      expect(agenda.projectProfileFields, {project.id: fieldsBefore});
      expect(agenda.projectProfileEvents, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      expect(find.text('Son Kuzey'), findsOneWidget);
      expect(fixture.session.selectedProjectId, project.id);
      expect(tester.takeException(), isNull);
    },
  );

  for (final stale in [true, false]) {
    testWidgets(
      'project name ${stale ? 'stale revision' : 'failure'} preserves name and selection',
      (tester) async {
        final project = _project(
          'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'Kuzey',
        );
        final agenda = _RenamingAgenda(projects: [project]);
        final fixture = _Fixture(projects: agenda.projects, agenda: agenda);
        addTearDown(fixture.dispose);
        await tester.pumpWidget(fixture.app());
        await tester.pumpAndSettle();
        final fieldsBefore = List.of(agenda.projectProfileFields[project.id]!);
        await tester.tap(find.byKey(const Key('project-profile-name')));
        await tester.pumpAndSettle();
        if (stale) {
          agenda.projects = [_project(project.id, project.name, revision: 2)];
        } else {
          agenda.renameFailure = StateError('synthetic rename failure');
        }
        await tester.enterText(
          find.byKey(const Key('project-profile-edit-name')),
          'Kaydedilmemeli',
        );
        await tester.tap(find.byKey(const Key('project-profile-save-name')));
        await tester.pumpAndSettle();

        expect(find.text('Kuzey'), findsOneWidget);
        expect(find.text('Kaydedilmemeli'), findsNothing);
        expect(agenda.projects.single.name, 'Kuzey');
        expect(fixture.session.selectedProjectId, project.id);
        expect(agenda.renameCommands.single.expectedRevision, 1);
        expect(agenda.appliedRenames, 0);
        expect(agenda.projectProfileFields, {project.id: fieldsBefore});
        expect(agenda.projectProfileEvents, isEmpty);
        expect(
          find.text(
            stale
                ? 'Proje başka bir işlem tarafından değiştirilmiş.'
                : 'Proje profili güncellenemedi. Kayıtlar korunuyor.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('pending rename does not retarget a newly selected project', (
    tester,
  ) async {
    final first = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final second = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
    final gate = Completer<void>();
    final agenda = _RenamingAgenda(projects: [first, second])
      ..renameGate = gate;
    final fixture = _Fixture(projects: agenda.projects, agenda: agenda);
    addTearDown(fixture.dispose);
    fixture.session.select(first.id, agenda.projects);
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();
    await _renameVisibleProject(tester, 'Yeni Kuzey');
    expect(agenda.renameCommands.single.projectId, first.id);
    expect(agenda.projects.first.name, 'Kuzey');
    expect(fixture.session.select(second.id, agenda.projects), isTrue);
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(fixture.session.selectedProjectId, second.id);
    expect(find.text('Güney'), findsOneWidget);
    expect(find.text('Yeni Kuzey'), findsNothing);
    expect(agenda.projects.first.name, 'Yeni Kuzey');
    expect(agenda.projects.last, same(second));
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag reorder persists the complete visible order', (
    tester,
  ) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project]);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    final list = tester.widget<ReorderableListView>(
      find.byKey(const Key('project-profile-fields')),
    );
    list.onReorderItem?.call(0, 2);
    await tester.pumpAndSettle();

    expect(
      fixture.agenda.projectProfileFields[project.id]!
          .where((field) => !field.isArchived)
          .map((field) => field.label),
      ['Toplam alan', 'YİBF No', 'Toplam kat'],
    );
    expect(
      fixture.agenda.projectProfileEvents.last.eventType,
      ProjectProfileEventType.fieldsReordered,
    );
  });

  testWidgets('compact tools preserves exact project actions', (tester) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project]);
    addTearDown(fixture.dispose);
    String? openedProject;

    await tester.pumpWidget(
      fixture.app(onOpenPlan: (projectId) => openedProject = projectId),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('project-profile-tools')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('project-profile-tools-sheet')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('dashboard-open-plan')));
    await tester.pumpAndSettle();
    expect(openedProject, project.id);
  });

  testWidgets('active project switch rejects stale profile result', (
    tester,
  ) async {
    final first = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final second = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
    final fixture = _Fixture(projects: [first, second]);
    addTearDown(fixture.dispose);
    final stale = Completer<ProjectProfile>();
    fixture.agenda.projectProfileResponses[first.id] = [stale.future];
    fixture.agenda.projectProfileResponses[second.id] = [
      Future.value(_profile(second, value: 'Güney profil değeri')),
    ];

    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('dashboard-project-selection-required')),
      findsOneWidget,
    );

    expect(fixture.session.select(first.id, [first, second]), isTrue);
    await tester.pump();
    expect(fixture.session.select(second.id, [first, second]), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Güney'), findsOneWidget);
    expect(find.text('Güney profil değeri'), findsOneWidget);

    stale.complete(_profile(first, value: 'ESKİ SONUÇ'));
    await tester.pumpAndSettle();
    expect(find.text('Güney'), findsOneWidget);
    expect(find.text('Güney profil değeri'), findsOneWidget);
    expect(find.text('ESKİ SONUÇ'), findsNothing);
  });
}

class _Fixture {
  _Fixture({
    required List<MobileProject> projects,
    FakeAgendaApplication? agenda,
  }) : agenda = agenda ?? FakeAgendaApplication(projects: projects);

  final FakeAgendaApplication agenda;
  final ActiveProjectSession session = ActiveProjectSession();

  Widget app({
    VoidCallback? onCreateProject,
    DashboardProjectAction? onOpenPlan,
  }) => MaterialApp(
    locale: CseApp.locale,
    supportedLocales: CseApp.supportedLocales,
    localizationsDelegates: CseApp.localizationsDelegates,
    home: Scaffold(
      body: ProjectDashboardPage(
        agenda: agenda,
        livingPlan: const UnavailableConstructionLivingPlanApplication(),
        session: session,
        onCreateProject: onCreateProject ?? () {},
        onOpenPlan: onOpenPlan,
        clock: () => DateTime.utc(2026, 9, 4, 9),
      ),
    ),
  );

  void dispose() => session.dispose();
}

Future<void> _renameVisibleProject(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('project-profile-name')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('project-profile-edit-name')),
    name,
  );
  await tester.tap(find.byKey(const Key('project-profile-save-name')));
  await tester.pumpAndSettle();
}

class _RenamingAgenda extends FakeAgendaApplication
    implements ProjectLifecycleApplication {
  _RenamingAgenda({required super.projects});

  final List<RenameProjectCommand> renameCommands = [];
  Object? renameFailure;
  Completer<void>? renameGate;
  int appliedRenames = 0;

  @override
  Future<MobileProject> renameProject(RenameProjectCommand command) async {
    renameCommands.add(command);
    final gate = renameGate;
    if (gate != null) await gate.future;
    final failure = renameFailure;
    if (failure != null) throw failure;
    final project = projects.singleWhere(
      (item) => item.id == command.projectId,
    );
    if (project.revision != command.expectedRevision) {
      throw const AgendaValidationFailure(
        'Proje başka bir işlem tarafından değiştirilmiş.',
      );
    }
    final renamed = MobileProject(
      id: project.id,
      name: command.name,
      createdAt: project.createdAt,
      updatedAt: '2026-09-05T04:00:00Z',
      revision: project.revision + 1,
      archivedAt: project.archivedAt,
    );
    projects = [
      for (final item in projects)
        if (item.id == project.id) renamed else item,
    ];
    appliedRenames += 1;
    return renamed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected lifecycle call: ${invocation.memberName}');
}

MobileProject _project(String id, String name, {int revision = 1}) =>
    MobileProject(
      id: id,
      name: name,
      createdAt: '2026-09-04T06:00:00Z',
      updatedAt: '2026-09-04T06:00:00Z',
      revision: revision,
    );

ProjectProfile _profile(MobileProject project, {required String value}) =>
    ProjectProfile(
      project: project,
      fields: [
        for (
          var index = 0;
          index < ProjectProfileBuiltinField.values.length;
          index += 1
        )
          ProjectProfileField(
            id:
                'project-profile:${project.id}:'
                '${ProjectProfileBuiltinField.values[index].storageValue}',
            projectId: project.id,
            builtinField: ProjectProfileBuiltinField.values[index],
            label: ProjectProfileBuiltinField.values[index].label,
            value: index == 0 ? value : '',
            sortOrder: index,
            revision: 1,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt,
          ),
      ],
    );
