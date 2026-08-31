import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/daily_log_application.dart';
import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/daily_log_models.dart';
import 'package:chief_site_engineer/domain/material_request_models.dart';
import 'package:chief_site_engineer/features/daily_log/daily_log_page.dart';
import 'package:chief_site_engineer/features/living_plan/living_plan_page.dart';
import 'package:chief_site_engineer/features/material_requests/material_requests_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  const projectA = MobileProject(
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    name: 'Kuzey',
    createdAt: '2026-08-30T06:00:00Z',
    updatedAt: '2026-08-30T06:00:00Z',
    revision: 1,
  );
  const projectB = MobileProject(
    id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    name: 'Güney',
    createdAt: '2026-08-30T06:00:00Z',
    updatedAt: '2026-08-30T06:00:00Z',
    revision: 1,
  );
  const projectC = MobileProject(
    id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    name: 'Doğu',
    createdAt: '2026-08-30T06:00:00Z',
    updatedAt: '2026-08-30T06:00:00Z',
    revision: 1,
  );

  testWidgets(
    'Dashboard forwards its exact project to all production core routes',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: const [projectA, projectB],
      );
      final daily = _DailyFake.fromMobile(const [projectA, projectB]);
      final plan = _PlanFake();
      final materials = _MaterialFake.fromMobile(const [projectA, projectB]);

      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'Test',
              smokeRecordId: 'project-context-routes',
              smokeRecordCreatedAt: '2026-08-30T08:00:00Z',
              agenda: agenda,
              dailyLog: daily,
              livingPlan: plan,
              materialRequests: materials,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Proje seç'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('dashboard-project-${projectB.id}')),
      );
      await tester.pumpAndSettle();

      await _openDashboardAction(tester, const Key('dashboard-open-today'));
      expect(
        tester.widget<DailyLogPage>(find.byType(DailyLogPage)).initialProjectId,
        projectB.id,
      );
      await _backToDashboard(tester);

      await _openDashboardAction(tester, const Key('dashboard-open-plan'));
      expect(
        tester
            .widget<LivingPlanPage>(find.byType(LivingPlanPage))
            .initialProjectId,
        projectB.id,
      );
      await _backToDashboard(tester);

      await _openDashboardAction(tester, const Key('dashboard-open-materials'));
      expect(
        tester
            .widget<MaterialRequestsPage>(find.byType(MaterialRequestsPage))
            .initialProjectId,
        projectB.id,
      );

      expect(daily.calls, isNotEmpty);
      expect(daily.calls, everyElement(projectB.id));
      expect(plan.calls, isNotEmpty);
      expect(plan.calls, everyElement(projectB.id));
      expect(materials.calls, isNotEmpty);
      expect(materials.calls, everyElement(projectB.id));
    },
  );

  testWidgets('valid initial context binds every page before its first read', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication(projects: const [projectA, projectB]);
    final plan = _PlanFake();
    await _pumpPage(
      tester,
      LivingPlanPage(
        agenda: agenda,
        livingPlan: plan,
        initialProjectId: projectB.id,
        clock: () => DateTime.utc(2026, 8, 30, 9),
      ),
    );
    expect(plan.calls, [projectB.id]);

    final daily = _DailyFake.fromMobile(const [projectA, projectB]);
    await _pumpPage(
      tester,
      DailyLogPage(dailyLog: daily, initialProjectId: projectB.id),
    );
    expect(daily.calls, [projectB.id]);

    final materials = _MaterialFake.fromMobile(const [projectA, projectB]);
    await _pumpPage(
      tester,
      MaterialRequestsPage(
        application: materials,
        initialProjectId: projectB.id,
      ),
    );
    expect(materials.calls, [projectB.id]);
  });

  testWidgets(
    'stale explicit context reads nothing and each local selector recovers',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: const [projectA, projectB],
      );
      final plan = _PlanFake();
      await _pumpPage(
        tester,
        LivingPlanPage(
          agenda: agenda,
          livingPlan: plan,
          initialProjectId: 'missing',
          clock: () => DateTime.utc(2026, 8, 30, 9),
        ),
      );
      expect(plan.calls, isEmpty);
      expect(
        find.byKey(const Key('living-plan-project-context-unavailable')),
        findsOneWidget,
      );
      await _chooseProject(
        tester,
        find.byKey(const Key('living-plan-project-selector')),
        projectB.name,
      );
      expect(plan.calls, [projectB.id]);

      final daily = _DailyFake.fromMobile(const [projectA, projectB]);
      await _pumpPage(
        tester,
        DailyLogPage(dailyLog: daily, initialProjectId: 'missing'),
      );
      expect(daily.calls, isEmpty);
      expect(
        find.byKey(const Key('daily-log-project-context-unavailable')),
        findsOneWidget,
      );
      await _chooseProject(
        tester,
        find.byKey(const Key('daily-log-project-none')),
        projectB.name,
      );
      expect(daily.calls, [projectB.id]);

      final materials = _MaterialFake.fromMobile(const [projectA, projectB]);
      await _pumpPage(
        tester,
        MaterialRequestsPage(
          application: materials,
          initialProjectId: 'missing',
        ),
      );
      expect(materials.calls, isEmpty);
      expect(
        find.byKey(const Key('material-request-project-context-unavailable')),
        findsOneWidget,
      );
      await _chooseProject(
        tester,
        find.byKey(const Key('material-request-project-none')),
        projectB.name,
      );
      expect(materials.calls, [projectB.id]);
    },
  );

  testWidgets('legacy callers keep first-project fallback', (tester) async {
    final agenda = FakeAgendaApplication(projects: const [projectA, projectB]);
    final plan = _PlanFake();
    await _pumpPage(
      tester,
      LivingPlanPage(
        agenda: agenda,
        livingPlan: plan,
        clock: () => DateTime.utc(2026, 8, 30, 9),
      ),
    );
    expect(plan.calls, [projectA.id]);

    final daily = _DailyFake.fromMobile(const [projectA, projectB]);
    await _pumpPage(tester, DailyLogPage(dailyLog: daily));
    expect(daily.calls, [projectA.id]);

    final materials = _MaterialFake.fromMobile(const [projectA, projectB]);
    await _pumpPage(tester, MaterialRequestsPage(application: materials));
    expect(materials.calls, [projectA.id]);
  });

  testWidgets(
    'refresh preserves a valid local choice then fails closed if it disappears',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: const [projectA, projectB],
      );
      final plan = _PlanFake();
      await _pumpPage(
        tester,
        LivingPlanPage(
          agenda: agenda,
          livingPlan: plan,
          initialProjectId: projectB.id,
          clock: () => DateTime.utc(2026, 8, 30, 9),
        ),
      );
      await _chooseProject(
        tester,
        find.byKey(const Key('living-plan-project-selector')),
        projectA.name,
      );
      agenda.projects = const [projectA, projectC];
      await tester.tap(find.byKey(const Key('living-plan-refresh')));
      await tester.pumpAndSettle();
      expect(plan.calls, [projectB.id, projectA.id, projectA.id]);

      agenda.projects = const [projectC];
      await tester.tap(find.byKey(const Key('living-plan-refresh')));
      await tester.pumpAndSettle();
      expect(plan.calls, [projectB.id, projectA.id, projectA.id]);
      expect(
        find.byKey(const Key('living-plan-project-context-unavailable')),
        findsOneWidget,
      );

      final materials = _MaterialFake.fromMobile(const [projectA, projectB]);
      await _pumpPage(
        tester,
        MaterialRequestsPage(
          application: materials,
          initialProjectId: projectB.id,
        ),
      );
      await _chooseProject(
        tester,
        find.byKey(Key('material-request-project-${projectB.id}')),
        projectA.name,
      );
      materials.projects = [
        MaterialRequestProject(id: projectA.id, name: projectA.name),
        MaterialRequestProject(id: projectC.id, name: projectC.name),
      ];
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(materials.calls, [projectB.id, projectA.id, projectA.id]);

      materials.projects = [
        MaterialRequestProject(id: projectC.id, name: projectC.name),
      ];
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(materials.calls, [projectB.id, projectA.id, projectA.id]);
      expect(
        find.byKey(const Key('material-request-project-context-unavailable')),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: CseApp.locale,
      supportedLocales: CseApp.supportedLocales,
      localizationsDelegates: CseApp.localizationsDelegates,
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _chooseProject(
  WidgetTester tester,
  Finder selector,
  String projectName,
) async {
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.tap(find.text(projectName).last);
  await tester.pumpAndSettle();
}

Future<void> _openDashboardAction(WidgetTester tester, Key key) async {
  final action = find.byKey(key);
  await tester.scrollUntilVisible(
    action,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> _backToDashboard(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

class _DailyFake implements DailyLogApplicationPort {
  _DailyFake(this.projects);

  factory _DailyFake.fromMobile(List<MobileProject> projects) => _DailyFake(
    projects
        .map((project) => DailyLogProject(id: project.id, name: project.name))
        .toList(growable: false),
  );

  List<DailyLogProject> projects;
  final List<String> calls = [];

  @override
  Future<List<DailyLogProject>> listProjects() async => projects;

  @override
  Future<DailyLogDay> loadDay({
    required String projectId,
    required String localDay,
  }) async {
    calls.add(projectId);
    final project = projects.singleWhere((item) => item.id == projectId);
    return DailyLogDay(
      projectId: project.id,
      projectName: project.name,
      localDay: localDay,
      sections: [
        DailyLogSection.summary(text: 'Kayıt yok'),
        for (final kind in DailyLogSectionKind.values.skip(1))
          DailyLogSection.available(kind: kind, entries: const []),
      ],
    );
  }
}

class _PlanFake extends UnavailableConstructionLivingPlanApplication {
  final List<String> calls = [];

  @override
  Future<List<ConstructionLivingPlanWindowItem>> loadSevenDayPlan({
    required String projectId,
    required DateTime windowStart,
  }) async {
    calls.add(projectId);
    return const [];
  }

  @override
  Future<List<ConstructionLivingPlanReferenceCandidate>>
  loadSevenDayReferenceSuggestions({
    required String projectId,
    required DateTime windowStart,
  }) async => const [];
}

class _MaterialFake implements MaterialRequestApplicationPort {
  _MaterialFake(this.projects);

  factory _MaterialFake.fromMobile(List<MobileProject> projects) =>
      _MaterialFake(
        projects
            .map(
              (project) =>
                  MaterialRequestProject(id: project.id, name: project.name),
            )
            .toList(growable: false),
      );

  List<MaterialRequestProject> projects;
  final List<String> calls = [];

  @override
  Future<List<MaterialRequestProject>> listProjects() async => projects;

  @override
  Future<List<MaterialRequest>> listMaterialRequests({
    required String projectId,
    required MaterialRequestListKind kind,
  }) async {
    calls.add(projectId);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
