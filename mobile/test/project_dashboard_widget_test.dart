import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/daily_log_application.dart';
import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/daily_log_models.dart';
import 'package:chief_site_engineer/domain/material_request_models.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets('zero projects shows setup and runs no project-bound read', (
    tester,
  ) async {
    final fixture = _Fixture(projects: const []);
    addTearDown(fixture.dispose);
    var setupCalls = 0;

    await tester.pumpWidget(
      fixture.app(onCreateProject: () => setupCalls += 1),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);
    expect(fixture.daily.calls, isEmpty);
    expect(fixture.plan.calls, isEmpty);
    expect(fixture.materials.calls, isEmpty);

    await tester.tap(find.text('Proje kurulumuna git'));
    expect(setupCalls, 1);
  });

  testWidgets('multiple projects fail closed until exact explicit selection', (
    tester,
  ) async {
    final fixture = _Fixture(
      projects: [_project('a', 'Kuzey'), _project('b', 'Güney')],
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dashboard-project-selection-required')),
      findsOneWidget,
    );
    expect(fixture.daily.calls, isEmpty);
    expect(fixture.plan.calls, isEmpty);
    expect(fixture.materials.calls, isEmpty);

    await tester.tap(find.text('Proje seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dashboard-project-b')));
    await tester.pumpAndSettle();

    expect(fixture.session.selectedProjectId, 'b');
    expect(fixture.daily.calls.single, ('b', '2026-08-30'));
    expect(fixture.plan.calls.single.$1, 'b');
    expect(fixture.plan.calls.single.$2, DateTime(2026, 8, 30));
    expect(fixture.materials.calls.single, 'b');
    expect(find.text('Güney'), findsOneWidget);
  });

  testWidgets(
    'projectChanges invalidates stale selection without read leakage',
    (tester) async {
      final fixture = _Fixture(projects: [_project('a', 'Kuzey')]);
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      expect(fixture.session.selectedProjectId, 'a');
      expect(fixture.daily.calls, hasLength(1));

      fixture.agenda.projects = [_project('b', 'Güney'), _project('c', 'Doğu')];
      fixture.agenda.emitProjectChange();
      await tester.pumpAndSettle();

      expect(fixture.session.selectedProjectId, isNull);
      expect(
        find.byKey(const Key('dashboard-project-selection-required')),
        findsOneWidget,
      );
      expect(fixture.daily.calls, hasLength(1));
      expect(fixture.plan.calls, hasLength(1));
      expect(fixture.materials.calls, hasLength(1));
    },
  );

  testWidgets(
    'section failure is isolated and retry rereads only that source',
    (tester) async {
      final fixture = _Fixture(projects: [_project('a', 'Kuzey')]);
      addTearDown(fixture.dispose);
      fixture.daily.fail = true;

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard-today-retry')), findsOneWidget);
      expect(find.text('Plan penceresinde kayıt yok.'), findsOneWidget);
      expect(fixture.plan.calls, hasLength(1));
      expect(fixture.materials.calls, hasLength(1));

      fixture.daily.fail = false;
      await tester.tap(find.byKey(const Key('dashboard-today-retry')));
      await tester.pumpAndSettle();

      expect(fixture.daily.calls, hasLength(2));
      expect(fixture.plan.calls, hasLength(1));
      expect(fixture.materials.calls, hasLength(1));
      expect(find.textContaining('Puantaj: kullanılamıyor'), findsOneWidget);
      expect(find.textContaining('Ajanda: 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('dashboard-materials-card')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Açık malzeme ihtiyacı yok.'), findsOneWidget);
    },
  );

  testWidgets(
    'quick actions receive exact session project/day and cancel writes nothing',
    (tester) async {
      final fixture = _Fixture(projects: [_project('a', 'Kuzey')]);
      addTearDown(fixture.dispose);
      final captures = <(String, String, String)>[];

      await tester.pumpWidget(
        fixture.app(
          onReminder: (projectId, day) async {
            captures.add(('reminder', projectId, day));
            return false;
          },
          onAgenda: (projectId, day) async {
            captures.add(('agenda', projectId, day));
            return false;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard-quick-reminder')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('dashboard-quick-agenda')));
      await tester.pump();

      expect(captures, [
        ('reminder', 'a', '2026-08-30'),
        ('agenda', 'a', '2026-08-30'),
      ]);
      expect(fixture.agenda.createReminderCalls, 0);
      expect(fixture.agenda.createLogCalls, 0);
    },
  );

  testWidgets(
    'small large-text Dashboard scrolls with 48dp actions and semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final fixture = _Fixture(
        projects: [_project('a', 'Çok Uzun Kuzey Projesi')],
      );
      addTearDown(fixture.dispose);

      await tester.pumpWidget(
        fixture.app(
          onReminder: (_, _) async => false,
          onAgenda: (_, _) async => false,
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      final reminder = find.byKey(const Key('dashboard-quick-reminder'));
      final agenda = find.byKey(const Key('dashboard-quick-agenda'));
      expect(tester.getSize(reminder).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(agenda).height, greaterThanOrEqualTo(48));
      expect(
        find.bySemanticsLabel(RegExp('Aktif proje Çok Uzun Kuzey Projesi')),
        findsOneWidget,
      );
      expect(find.byType(ListView), findsWidgets);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}

class _Fixture {
  _Fixture({required List<MobileProject> projects})
    : agenda = _AgendaFake(projects: projects);

  final _AgendaFake agenda;
  final _DailyFake daily = _DailyFake();
  final _PlanFake plan = _PlanFake();
  final _MaterialFake materials = _MaterialFake();
  final ActiveProjectSession session = ActiveProjectSession();

  Widget app({
    VoidCallback? onCreateProject,
    DashboardCaptureAction? onReminder,
    DashboardCaptureAction? onAgenda,
    Brightness brightness = Brightness.light,
  }) => MaterialApp(
    locale: CseApp.locale,
    supportedLocales: CseApp.supportedLocales,
    localizationsDelegates: CseApp.localizationsDelegates,
    theme: ThemeData(brightness: brightness),
    home: Scaffold(
      body: ProjectDashboardPage(
        agenda: agenda,
        dailyLog: daily,
        livingPlan: plan,
        materialRequests: materials,
        session: session,
        onCreateProject: onCreateProject ?? () {},
        onAddReminder: onReminder,
        onAddAgenda: onAgenda,
        clock: () => DateTime.utc(2026, 8, 30, 9),
      ),
    ),
  );

  void dispose() {
    agenda.disposeDashboardFake();
    session.dispose();
  }
}

class _AgendaFake extends FakeAgendaApplication {
  _AgendaFake({required super.projects});

  final StreamController<void> _dashboardProjectChanges =
      StreamController<void>.broadcast();

  @override
  Stream<void> get projectChanges => _dashboardProjectChanges.stream;

  void emitProjectChange() => _dashboardProjectChanges.add(null);

  void disposeDashboardFake() => _dashboardProjectChanges.close();
}

class _DailyFake implements DailyLogApplicationPort {
  final List<(String, String)> calls = [];
  bool fail = false;

  @override
  Future<List<DailyLogProject>> listProjects() async => const [];

  @override
  Future<DailyLogDay> loadDay({
    required String projectId,
    required String localDay,
  }) async {
    calls.add((projectId, localDay));
    if (fail) throw const DailyLogFailure('synthetic_daily_failure');
    return DailyLogDay(
      projectId: projectId,
      projectName: 'Kuzey',
      localDay: localDay,
      sections: [
        DailyLogSection.summary(text: '1 kaynak kaydı'),
        DailyLogSection.unavailable(
          kind: DailyLogSectionKind.attendance,
          failure: const DailyLogSectionFailure(
            code: 'attendance_unavailable',
            message: 'Puantaj okunamadı.',
          ),
        ),
        DailyLogSection.available(
          kind: DailyLogSectionKind.livingPlan,
          entries: const [],
        ),
        DailyLogSection.available(
          kind: DailyLogSectionKind.concrete,
          entries: const [],
        ),
        DailyLogSection.available(
          kind: DailyLogSectionKind.agenda,
          entries: [
            DailyLogEntry(
              id: 'agenda-1',
              text: 'Saha turu',
              sourceRefs: [
                DailyLogSourceRef(
                  kind: DailyLogSourceKind.agendaLog,
                  sourceId: 'agenda-1',
                ),
              ],
            ),
          ],
        ),
        DailyLogSection.available(
          kind: DailyLogSectionKind.openFollowUps,
          entries: const [],
        ),
      ],
    );
  }
}

class _PlanFake extends UnavailableConstructionLivingPlanApplication {
  final List<(String, DateTime)> calls = [];

  @override
  Future<List<ConstructionLivingPlanWindowItem>> loadSevenDayPlan({
    required String projectId,
    required DateTime windowStart,
  }) async {
    calls.add((projectId, windowStart));
    return const [];
  }
}

class _MaterialFake implements MaterialRequestApplicationPort {
  final List<String> calls = [];

  @override
  Future<List<MaterialRequest>> listMaterialRequests({
    required String projectId,
    required MaterialRequestListKind kind,
  }) async {
    calls.add(projectId);
    expect(kind, MaterialRequestListKind.open);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MobileProject _project(String id, String name) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-08-30T06:00:00Z',
  updatedAt: '2026-08-30T06:00:00Z',
  revision: 1,
);
