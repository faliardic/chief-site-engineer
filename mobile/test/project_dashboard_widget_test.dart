import 'dart:async';

import 'package:chief_site_engineer/app.dart';
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
  _Fixture({required List<MobileProject> projects})
    : agenda = FakeAgendaApplication(projects: projects);

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

MobileProject _project(String id, String name) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-09-04T06:00:00Z',
  updatedAt: '2026-09-04T06:00:00Z',
  revision: 1,
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
