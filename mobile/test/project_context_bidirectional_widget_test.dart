import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/daily_log_application.dart';
import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/daily_log_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/domain/material_request_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/agenda/phone_call_result_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_directory_page.dart';
import 'package:chief_site_engineer/features/attachments/project_media_album_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/daily_log/daily_log_page.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/inventory/inventory_page.dart';
import 'package:chief_site_engineer/features/living_plan/living_plan_page.dart';
import 'package:chief_site_engineer/features/material_requests/material_requests_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const _projectA = MobileProject(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Kuzey',
  createdAt: '2026-08-31T06:00:00Z',
  updatedAt: '2026-08-31T06:00:00Z',
  revision: 1,
);
const _projectB = MobileProject(
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  name: 'Güney',
  createdAt: '2026-08-31T06:00:00Z',
  updatedAt: '2026-08-31T06:00:00Z',
  revision: 1,
);

void main() {
  for (final outcome in [
    'success',
    'retry',
    'failed back',
    'pending back success',
    'pending back failure',
    'pending back immediate success',
    'pending back immediate failure',
  ]) {
    testWidgets('Daily Log shared switch settles with usable Home: $outcome', (
      tester,
    ) async {
      final daily = _OrderedDailyFake();
      final agenda = _DailySwitchAgenda(daily);
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'Test',
              smokeRecordId: 'issue-699-daily-switch',
              smokeRecordCreatedAt: '2026-09-05T08:00:00Z',
              agenda: agenda,
              dailyLog: daily,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _chooseSharedProject(tester, _projectB.id);
      await tester.pumpAndSettle();
      final session = tester
          .widget<ProjectDashboardPage>(find.byType(ProjectDashboardPage))
          .session;
      final changes = <String?>[];
      void observe() => changes.add(session.selectedProjectId);
      session.addListener(observe);
      await _openDashboardTool(tester, const Key('dashboard-open-today'));
      final selectedDay = tester
          .widget<Text>(find.byKey(const Key('daily-log-day-heading')))
          .data!
          .split(' · ')
          .first;
      expect(changes, isEmpty);
      final pending = Completer<void>();
      daily.nextRead = pending;
      final profileBaseline = agenda.profileReads.length;
      await _startProjectSelection(
        tester,
        find.byKey(ValueKey('daily-log-project-${_projectB.id}')),
        _projectA.name,
      );
      // The route owns this unfinished read. It must not start Home's read
      // or replace the shared project until its entire load has settled.
      expect(daily.reading, isTrue);
      expect(session.selectedProjectId, _projectB.id);
      expect(changes, isEmpty);
      expect(agenda.profileReads.length, profileBaseline);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final backWhilePending = outcome.startsWith('pending back');
      if (backWhilePending) {
        await tester.tap(find.byType(BackButton));
        if (outcome.contains('immediate')) {
          // A popped route remains mounted during its reverse animation.
          expect(find.byType(DailyLogPage), findsOneWidget);
        } else {
          await tester.pumpAndSettle();
          _expectSettledDailyHome(tester, _projectB);
        }
      }
      if (outcome.endsWith('success')) {
        pending.complete();
      } else {
        pending.completeError(const DailyLogFailure('daily_log_read_failed'));
      }
      await tester.pumpAndSettle();

      if (outcome == 'retry' || outcome == 'failed back') {
        expect(changes, isEmpty);
        expect(session.selectedProjectId, _projectB.id);
        expect(find.text('Günlük Log güvenle okunamadı.'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(agenda.profileReads.length, profileBaseline);
        if (outcome == 'retry') {
          await tester.tap(find.byKey(const Key('daily-log-project-retry')));
          await tester.pumpAndSettle();
        }
      }
      final adopted = outcome == 'success' || outcome == 'retry';
      if (adopted) {
        expect(changes, [_projectA.id]);
        expect(session.selectedProjectId, _projectA.id);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('daily-log-day-heading')))
              .data,
          '$selectedDay · ${_projectA.name}',
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(agenda.profileReads.skip(profileBaseline), isNotEmpty);
        expect(
          agenda.profileReads.skip(profileBaseline),
          everyElement(_projectA.id),
        );
      } else {
        expect(changes, isEmpty);
        expect(session.selectedProjectId, _projectB.id);
      }
      if (!backWhilePending) {
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      _expectSettledDailyHome(tester, adopted ? _projectA : _projectB);
      expect(agenda.overlappingProfileReads, isEmpty);
      expect(agenda.createLogCalls, 0);
      expect(agenda.createReminderCalls, 0);
      expect(tester.takeException(), isNull);
      session.removeListener(observe);
    });
  }

  testWidgets(
    'Inventory AppBar selection commits shared A once only after success and preserves A in captures',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      final inventory = _SelectionInventory();
      final attendance = _TrackingAttendance();
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'Test',
              smokeRecordId: 'issue-556-shell',
              smokeRecordCreatedAt: '2026-09-02T08:00:00Z',
              agenda: agenda,
              inventory: inventory,
              attendance: attendance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _chooseSharedProject(tester, _projectB.id);
      await tester.pumpAndSettle();
      final session = tester
          .widget<ProjectDashboardPage>(
            find.byType(ProjectDashboardPage, skipOffstage: false),
          )
          .session;
      final sharedChanges = <String?>[];
      void observe() => sharedChanges.add(session.selectedProjectId);
      session.addListener(observe);
      await tester.tap(find.text('Envanter').last);
      await tester.pumpAndSettle();
      expect(inventory.projects, [_projectB.id]);
      final pending = Completer<InventoryPrimarySketchProjection?>();
      inventory.next = pending;
      await _chooseSharedProject(tester, _projectA.id);
      expect(inventory.projects, [_projectB.id, _projectA.id]);
      expect(session.selectedProjectId, _projectB.id);
      expect(sharedChanges, isEmpty);
      pending.complete(null);
      await tester.pumpAndSettle();
      expect(session.selectedProjectId, _projectA.id);
      expect(sharedChanges, [_projectA.id]);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(_projectA.name),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .state<InventoryPageState>(find.byType(InventoryPage))
            .controller
            .selectedProjectId,
        _projectA.id,
      );

      final failure = Completer<InventoryPrimarySketchProjection?>();
      inventory.next = failure;
      await _chooseSharedProject(tester, _projectB.id);
      failure.completeError(
        const InventoryFailure('inventory_load_test_failure'),
      );
      await tester.pumpAndSettle();
      expect(session.selectedProjectId, _projectA.id);
      expect(sharedChanges, [_projectA.id]);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(_projectA.name),
        ),
        findsOneWidget,
      );
      final page = tester.state<InventoryPageState>(find.byType(InventoryPage));
      expect(page.controller.selectedProjectId, _projectA.id);
      expect(page.controller.lastErrorCode, 'inventory_load_test_failure');

      final staleLocal = Completer<InventoryPrimarySketchProjection?>();
      inventory.next = staleLocal;
      await _chooseSharedProject(tester, _projectB.id);
      await tester.tap(find.text('Hatırlatıcı').last);
      await tester.pumpAndSettle();
      staleLocal.complete(null);
      await tester.pumpAndSettle();
      expect(sharedChanges, [_projectA.id]);
      expect(session.selectedProjectId, _projectA.id);
      await tester.tap(find.byKey(const Key('new-reminder')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(
              find.byKey(const Key('reminder-project')),
            )
            .initialValue,
        _projectA.id,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(agenda.createReminderCalls, 0);
      expect(attendance.ensureProjectIds, isEmpty);
      expect(attendance.rollingCalls, 0);
      expect(inventory.unexpectedCalls, isEmpty);
      expect(tester.takeException(), isNull);
      session.removeListener(observe);
    },
  );

  testWidgets(
    'Living Plan adopts A only after its exact target read succeeds',
    (tester) async {
      final callbacks = <String>[];
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      final plan = _OrderedPlanFake();
      await _pumpPage(
        tester,
        LivingPlanPage(
          agenda: agenda,
          livingPlan: plan,
          initialProjectId: _projectB.id,
          onProjectSelected: (projectId) {
            callbacks.add(projectId);
            plan.events.add('callback:$projectId');
          },
          clock: () => DateTime.utc(2026, 8, 31, 9),
        ),
      );

      expect(plan.planCalls, [_projectB.id]);
      expect(callbacks, isEmpty);
      final targetRead = Completer<List<ConstructionLivingPlanWindowItem>>();
      plan.nextPlanRead = targetRead;
      await _startProjectSelection(
        tester,
        find.byKey(const Key('living-plan-project-selector')),
        _projectA.name,
      );

      expect(plan.planCalls, [_projectB.id, _projectA.id]);
      expect(plan.events.last, 'plan:${_projectA.id}:start');
      expect(callbacks, isEmpty);
      targetRead.complete(const []);
      await tester.pumpAndSettle();

      expect(callbacks, [_projectA.id]);
      expect(
        plan.events.indexOf('plan:${_projectA.id}:success'),
        lessThan(plan.events.indexOf('callback:${_projectA.id}')),
      );
      expect(
        plan.events.indexOf('suggestions:${_projectA.id}:success'),
        lessThan(plan.events.indexOf('callback:${_projectA.id}')),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Living Plan failed target and non-selection reads never adopt a project',
    (tester) async {
      final callbacks = <String>[];
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      final plan = _OrderedPlanFake();
      await _pumpPage(
        tester,
        LivingPlanPage(
          agenda: agenda,
          livingPlan: plan,
          initialProjectId: _projectB.id,
          onProjectSelected: callbacks.add,
          clock: () => DateTime.utc(2026, 8, 31, 9),
        ),
      );
      expect(callbacks, isEmpty);

      final failedRead = Completer<List<ConstructionLivingPlanWindowItem>>();
      plan.nextPlanRead = failedRead;
      await _startProjectSelection(
        tester,
        find.byKey(const Key('living-plan-project-selector')),
        _projectA.name,
      );
      expect(callbacks, isEmpty);
      failedRead.completeError(
        const ConstructionLivingPlanFailure('target_read_failed'),
      );
      await tester.pumpAndSettle();

      expect(callbacks, isEmpty);
      expect(
        find.text('Plan güvenli biçimde okunamadı. Kayıtlar değiştirilmedi.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('living-plan-read-error-retry')));
      await tester.pumpAndSettle();
      expect(callbacks, isEmpty);

      await tester.tap(find.byKey(const Key('living-plan-refresh')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('living-plan-next-window')));
      await tester.pumpAndSettle();
      final callsBeforeSameProject = plan.planCalls.length;
      await _chooseProject(
        tester,
        find.byKey(const Key('living-plan-project-selector')),
        _projectA.name,
      );
      expect(plan.planCalls, hasLength(callsBeforeSameProject));
      expect(callbacks, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Living Plan adopts a missing-snapshot target but keeps add gated',
    (tester) async {
      final callbacks = <String>[];
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      final plan = _OrderedPlanFake(missingSnapshotProjects: {_projectA.id});
      await _pumpPage(
        tester,
        LivingPlanPage(
          agenda: agenda,
          livingPlan: plan,
          initialProjectId: _projectB.id,
          onProjectSelected: callbacks.add,
          clock: () => DateTime.utc(2026, 8, 31, 9),
        ),
      );

      await _chooseProject(
        tester,
        find.byKey(const Key('living-plan-project-selector')),
        _projectA.name,
      );
      expect(callbacks, [_projectA.id]);
      expect(plan.planCalls, [_projectB.id, _projectA.id]);
      expect(
        tester
            .widget<FloatingActionButton>(
              find.byKey(const Key('add-living-plan-item')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'core routes report only deliberate local selection and then read A',
    (tester) async {
      final callbacks = <String>[];
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      final plan = _PlanFake();
      await _pumpPage(
        tester,
        LivingPlanPage(
          agenda: agenda,
          livingPlan: plan,
          initialProjectId: _projectB.id,
          onProjectSelected: callbacks.add,
          clock: () => DateTime.utc(2026, 8, 31, 9),
        ),
      );
      expect(callbacks, isEmpty);
      expect(plan.calls, [_projectB.id]);
      await _chooseProject(
        tester,
        find.byKey(const Key('living-plan-project-selector')),
        _projectA.name,
      );
      expect(callbacks, [_projectA.id]);
      expect(plan.calls.last, _projectA.id);

      callbacks.clear();
      final daily = _DailyFake.fromMobile(const [_projectA, _projectB]);
      await _pumpPage(
        tester,
        DailyLogPage(
          dailyLog: daily,
          initialProjectId: _projectB.id,
          onProjectSelected: callbacks.add,
        ),
      );
      expect(callbacks, isEmpty);
      expect(daily.calls, [_projectB.id]);
      await _chooseProject(
        tester,
        find.byKey(ValueKey('daily-log-project-${_projectB.id}')),
        _projectA.name,
      );
      expect(callbacks, [_projectA.id]);
      expect(daily.calls.last, _projectA.id);

      callbacks.clear();
      final materials = _MaterialFake.fromMobile(const [_projectA, _projectB]);
      await _pumpPage(
        tester,
        MaterialRequestsPage(
          application: materials,
          initialProjectId: _projectB.id,
          onProjectSelected: callbacks.add,
        ),
      );
      expect(callbacks, isEmpty);
      expect(materials.calls, [_projectB.id]);
      await _chooseProject(
        tester,
        find.byKey(ValueKey('material-request-project-${_projectB.id}')),
        _projectA.name,
      );
      expect(callbacks, [_projectA.id]);
      expect(materials.calls.last, _projectA.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new routes keep stale explicit context inert until deliberate recovery',
    (tester) async {
      final callbacks = <String>[];
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      final concrete = _ConcreteFake();
      await _pumpPage(
        tester,
        Scaffold(
          body: ConcretePage(
            concrete: concrete,
            agenda: agenda,
            attachments: _picker(),
            initialProjectId: 'stale',
            onProjectSelected: callbacks.add,
          ),
        ),
      );
      expect(concrete.projectCalls, isEmpty);
      expect(
        find.byKey(const Key('concrete-project-context-unavailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('concrete-project-filter')), findsNothing);
      await tester
          .state<ConcretePageState>(find.byType(ConcretePage))
          .selectProject(_projectA.id);
      await tester.pumpAndSettle();
      expect(concrete.projectCalls, [_projectA.id]);
      expect(callbacks, [_projectA.id]);

      callbacks.clear();
      final attendance = _TrackingAttendance();
      await _pumpPage(
        tester,
        Scaffold(
          body: WorkforceDirectoryPage(
            attendance: attendance,
            agenda: agenda,
            initialProjectId: 'stale',
            onProjectSelected: callbacks.add,
          ),
        ),
      );
      expect(attendance.directoryProjectCalls, isEmpty);
      expect(
        find.byKey(
          const Key('workforce-directory-project-context-unavailable'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workforce-directory-project-null')),
        findsNothing,
      );
      await tester
          .state<WorkforceDirectoryPageState>(
            find.byType(WorkforceDirectoryPage),
          )
          .selectProject(_projectA.id);
      await tester.pumpAndSettle();
      expect(attendance.memberProjectCalls, [_projectA.id]);
      expect(attendance.subcontractorProjectCalls, [_projectA.id]);
      expect(attendance.teamProjectCalls, [_projectA.id]);
      expect(callbacks, [_projectA.id]);

      callbacks.clear();
      final catalog = _CatalogFake();
      await _pumpPage(
        tester,
        ProjectMediaAlbumPage(
          catalog: catalog,
          agenda: agenda,
          initialProjectId: 'stale',
          onProjectSelected: callbacks.add,
          appBarProjectControlBuilder: _buildAlbumProjectControl,
        ),
      );
      expect(catalog.scopedCalls, isEmpty);
      expect(
        find.byKey(const Key('project-media-album-context-unavailable')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('album-project-null')), findsNothing);
      await _chooseSharedProject(tester, _projectA.id);
      expect(catalog.scopedCalls, [_projectA.id]);
      expect(callbacks, [_projectA.id]);

      callbacks.clear();
      final locations = _LocationFake();
      final phoneAgenda = _PhoneAgenda(projects: const [_projectA, _projectB]);
      await _pumpPage(
        tester,
        PhoneCallResultPage(
          agenda: phoneAgenda,
          projectLocations: locations,
          initialProjectId: 'stale',
          onProjectSelected: callbacks.add,
        ),
      );
      expect(locations.projectCalls, isEmpty);
      expect(phoneAgenda.captureCalls, 0);
      await _chooseProject(
        tester,
        find.byKey(const ValueKey('phone-call-project-none')),
        _projectA.name,
      );
      expect(locations.projectCalls, [_projectA.id]);
      expect(callbacks, [_projectA.id]);
      expect(phoneAgenda.captureCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'project discovery failure never operationalizes supplied initial IDs',
    (tester) async {
      final callbacks = <String>[];
      final concreteAgenda = _FailOnceAgenda(
        projects: const [_projectA, _projectB],
      );
      final concrete = _ConcreteFake();
      await _pumpPage(
        tester,
        Scaffold(
          body: ConcretePage(
            concrete: concrete,
            agenda: concreteAgenda,
            attachments: _picker(),
            initialProjectId: _projectB.id,
            onProjectSelected: callbacks.add,
          ),
        ),
      );
      expect(concrete.projectCalls, isEmpty);
      await tester.tap(find.byKey(const Key('concrete-project-retry')));
      await tester.pumpAndSettle();
      expect(concrete.projectCalls, [_projectB.id]);
      expect(callbacks, isEmpty);

      final workforceAgenda = _FailOnceAgenda(
        projects: const [_projectA, _projectB],
      );
      final attendance = _TrackingAttendance();
      await _pumpPage(
        tester,
        Scaffold(
          body: WorkforceDirectoryPage(
            attendance: attendance,
            agenda: workforceAgenda,
            initialProjectId: _projectB.id,
            onProjectSelected: callbacks.add,
          ),
        ),
      );
      expect(attendance.directoryProjectCalls, isEmpty);
      await tester.tap(
        find.byKey(const Key('workforce-directory-project-retry')),
      );
      await tester.pumpAndSettle();
      expect(attendance.memberProjectCalls, [_projectB.id]);
      expect(attendance.subcontractorProjectCalls, [_projectB.id]);
      expect(attendance.teamProjectCalls, [_projectB.id]);
      expect(callbacks, isEmpty);

      final catalog = _CatalogFake()..failDiscovery = true;
      await _pumpPage(
        tester,
        ProjectMediaAlbumPage(
          catalog: catalog,
          agenda: FakeAgendaApplication(projects: const [_projectA, _projectB]),
          initialProjectId: _projectB.id,
          onProjectSelected: callbacks.add,
          appBarProjectControlBuilder: _buildAlbumProjectControl,
        ),
      );
      expect(catalog.scopedCalls, isEmpty);
      catalog.failDiscovery = false;
      await tester.tap(find.byKey(const Key('project-media-album-retry')));
      await tester.pumpAndSettle();
      expect(catalog.scopedCalls, [_projectB.id]);
      expect(callbacks, isEmpty);

      final phoneAgenda = _FailOncePhoneAgenda(
        projects: const [_projectA, _projectB],
      );
      final locations = _LocationFake();
      await _pumpPage(
        tester,
        PhoneCallResultPage(
          agenda: phoneAgenda,
          projectLocations: locations,
          initialProjectId: _projectB.id,
          onProjectSelected: callbacks.add,
        ),
      );
      expect(locations.projectCalls, isEmpty);
      expect(phoneAgenda.captureCalls, 0);
      await tester.tap(find.byKey(const Key('phone-call-project-retry')));
      await tester.pumpAndSettle();
      expect(locations.projectCalls, [_projectB.id]);
      expect(callbacks, isEmpty);
      expect(phoneAgenda.captureCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared project tools validate and switch in place before Album adoption',
    (tester) async {
      final agenda = _PhoneAgenda(projects: const [_projectA, _projectB]);
      final daily = _DailyFake.fromMobile(const [_projectA, _projectB]);
      final plan = _PlanFake();
      final materials = _MaterialFake.fromMobile(const [_projectA, _projectB]);
      final concrete = _ConcreteFake();
      final attendance = _TrackingAttendance();
      final catalog = _CatalogFake();
      final locations = _LocationFake();

      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'Test',
              smokeRecordId: 'issue-547-shell',
              smokeRecordCreatedAt: '2026-08-31T08:00:00Z',
              agenda: agenda,
              dailyLog: daily,
              livingPlan: plan,
              materialRequests: materials,
              attendance: attendance,
              concrete: concrete,
              concreteAttachments: _picker(),
              attachmentCatalog: catalog,
              projectLocations: locations,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(attendance.ensureDayCalls, 0);
      expect(attendance.rollingCalls, 0);
      final baselineEnsureDay = attendance.ensureDayCalls;
      final baselineRolling = attendance.rollingCalls;

      await _chooseSharedProject(tester, _projectB.id);
      await tester.pumpAndSettle();
      final session = tester
          .widget<ProjectDashboardPage>(
            find.byType(ProjectDashboardPage, skipOffstage: false),
          )
          .session;
      expect(attendance.ensureDayCalls, 0);
      expect(attendance.rollingCalls, 0);

      agenda.failNextProjectDiscovery = true;
      await _openDashboardTool(tester, const Key('dashboard-concrete-package'));
      final concreteState = tester.state<ConcretePageState>(
        find.byType(ConcretePage),
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(ActiveProjectControl),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('concrete-project-filter')), findsNothing);
      expect(concrete.projectCalls, isEmpty);
      expect(find.byKey(const Key('concrete-project-retry')), findsOneWidget);
      await _chooseSharedProject(tester, _projectA.id);
      expect(session.selectedProjectId, _projectB.id);
      expect(concrete.projectCalls, isEmpty);
      expect(
        tester.state<ConcretePageState>(find.byType(ConcretePage)),
        same(concreteState),
      );
      await tester.tap(find.byKey(const Key('concrete-project-retry')));
      await tester.pumpAndSettle();
      expect(concrete.projectCalls.first, _projectB.id);
      await tester.enterText(
        find.widgetWithText(TextField, 'Kod, mahal, blok, kat veya aks ara'),
        'korunan beton araması',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('concrete-tool-filters')));
      await tester.pumpAndSettle();
      final concreteFilterSheet = find.byKey(
        const Key('concrete-filter-sheet'),
      );
      final followUpFilter = find.byKey(const Key('concrete-group-followUp'));
      final filterScroll = find
          .descendant(
            of: concreteFilterSheet,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        followUpFilter,
        100,
        scrollable: filterScroll,
      );
      await tester.tap(followUpFilter);
      await tester.pumpAndSettle();
      final applyFilters = find.byKey(const Key('concrete-apply-filters'));
      await tester.scrollUntilVisible(
        applyFilters,
        100,
        scrollable: filterScroll,
      );
      await tester.tap(applyFilters);
      await tester.pumpAndSettle();
      final concreteDay = concrete.queries.last.istanbulDay;
      await _chooseSharedProject(tester, _projectA.id);
      expect(session.selectedProjectId, _projectA.id);
      expect(concrete.queries.last.projectId, _projectA.id);
      expect(concrete.queries.last.literalSearch, 'korunan beton araması');
      expect(concrete.queries.last.group, ConcretePourGroup.followUp);
      expect(concrete.queries.last.istanbulDay, concreteDay);
      expect(
        tester.state<ConcretePageState>(find.byType(ConcretePage)),
        same(concreteState),
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      final workforceMemberBaseline = attendance.memberProjectCalls.length;
      agenda.failNextProjectDiscovery = true;
      await _openDashboardTool(
        tester,
        const Key('dashboard-workforce-directory'),
      );
      final workforceState = tester.state<WorkforceDirectoryPageState>(
        find.byType(WorkforceDirectoryPage),
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(ActiveProjectControl),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('workforce-directory-project-${_projectA.id}')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey('workforce-directory-project-${_projectB.id}')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('workforce-directory-project-null')),
        findsNothing,
      );
      expect(attendance.memberProjectCalls.length, workforceMemberBaseline);
      expect(
        find.byKey(const Key('workforce-directory-project-retry')),
        findsOneWidget,
      );
      await _chooseSharedProject(tester, _projectB.id);
      expect(session.selectedProjectId, _projectA.id);
      expect(attendance.memberProjectCalls.length, workforceMemberBaseline);
      await tester.tap(
        find.byKey(const Key('workforce-directory-project-retry')),
      );
      await tester.pumpAndSettle();
      expect(attendance.memberProjectCalls.length, workforceMemberBaseline + 1);
      expect(attendance.memberProjectCalls.last, _projectA.id);
      expect(attendance.subcontractorProjectCalls.last, _projectA.id);
      expect(attendance.teamProjectCalls.last, _projectA.id);
      await tester.enterText(
        find.byKey(const Key('workforce-directory-search')),
        'korunan rehber araması',
      );
      await tester.tap(
        find.byKey(const Key('workforce-directory-filter-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arşiv'));
      await tester.tap(
        find.byKey(const Key('workforce-directory-filter-apply')),
      );
      await tester.pumpAndSettle();
      await _chooseSharedProject(tester, _projectB.id);
      expect(session.selectedProjectId, _projectB.id);
      expect(attendance.memberProjectCalls.last, _projectB.id);
      expect(attendance.subcontractorProjectCalls.last, _projectB.id);
      expect(attendance.teamProjectCalls.last, _projectB.id);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('workforce-directory-search')),
            )
            .controller!
            .text,
        'korunan rehber araması',
      );
      expect(
        tester.state<WorkforceDirectoryPageState>(
          find.byType(WorkforceDirectoryPage),
        ),
        same(workforceState),
      );
      expect(find.text('Görünen proje: ${_projectB.name}'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ana Sayfa').last);
      await tester.pumpAndSettle();

      await _openDashboardTool(
        tester,
        const Key('dashboard-phone-call-result'),
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(ValueKey('phone-call-project-${_projectB.id}')),
            )
            .initialValue,
        _projectB.id,
      );
      expect(locations.projectCalls.last, _projectB.id);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(agenda.captureCalls, 0);

      await _openDashboardTool(tester, const Key('dashboard-project-album'));
      expect(catalog.scopedCalls.first, _projectB.id);
      final albumState = tester.state(find.byType(ProjectMediaAlbumPage));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(ActiveProjectControl),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('album-project-${_projectB.id}')),
        findsNothing,
      );
      await _chooseSharedProject(tester, _projectA.id);
      expect(catalog.scopedCalls.last, _projectA.id);
      expect(session.selectedProjectId, _projectA.id);
      expect(
        tester.state(find.byType(ProjectMediaAlbumPage)),
        same(albumState),
      );
      expect(attendance.ensureDayCalls, baselineEnsureDay);
      expect(attendance.rollingCalls, baselineRolling);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('project-profile-header')),
          matching: find.text(_projectA.name),
        ),
        findsOneWidget,
      );
      await _openDashboardTool(tester, const Key('dashboard-open-today'));
      expect(daily.calls.last, _projectA.id);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _openDashboardTool(tester, const Key('dashboard-open-plan'));
      expect(plan.calls.last, _projectA.id);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _openDashboardTool(tester, const Key('dashboard-open-materials'));
      expect(materials.calls.last, _projectA.id);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(attendance.ensureDayCalls, baselineEnsureDay);
      expect(attendance.rollingCalls, baselineRolling);
      expect(agenda.captureCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shell opens Puantaj on exact shared project and adopts only successful load',
    (tester) async {
      final agenda = _PhoneAgenda(projects: const [_projectA, _projectB]);
      final attendance = _TrackingAttendance();
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'Test',
              smokeRecordId: 'issue-561-shell',
              smokeRecordCreatedAt: '2026-09-01T08:00:00Z',
              agenda: agenda,
              dailyLog: _DailyFake.fromMobile(const [_projectA, _projectB]),
              livingPlan: _PlanFake(),
              materialRequests: _MaterialFake.fromMobile(const [
                _projectA,
                _projectB,
              ]),
              attendance: attendance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(attendance.ensureProjectIds, isEmpty);
      expect(attendance.rollingCalls, 0);

      await _chooseSharedProject(tester, _projectB.id);
      await tester.pumpAndSettle();
      expect(attendance.ensureProjectIds, isEmpty);
      expect(attendance.rollingCalls, 0);

      await tester.tap(find.text('Puantaj').last);
      await tester.pumpAndSettle();
      expect(attendance.ensureProjectIds, [_projectB.id]);
      expect(attendance.rollingCalls, 1);
      final attendanceProjectField = find.descendant(
        of: find.byKey(const Key('attendance-project')),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      expect(
        tester.state<FormFieldState<String>>(attendanceProjectField).value,
        _projectB.id,
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(_projectB.name),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Ana Sayfa').last);
      await tester.pumpAndSettle();
      await _chooseSharedProject(tester, _projectA.id);
      await tester.pumpAndSettle();
      expect(attendance.ensureProjectIds, [_projectB.id]);
      expect(attendance.rollingCalls, 1);

      await agenda.createProject(
        const CreateProjectCommand(
          id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
          name: 'Hidden project signal',
        ),
      );
      await tester.pumpAndSettle();
      expect(attendance.ensureProjectIds, [_projectB.id]);
      expect(attendance.rollingCalls, 1);

      await tester.tap(find.text('Puantaj').last);
      await tester.pumpAndSettle();
      expect(attendance.ensureProjectIds, [_projectB.id, _projectA.id]);
      expect(attendance.rollingCalls, 2);
      expect(
        tester.state<FormFieldState<String>>(attendanceProjectField).value,
        _projectA.id,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('attendance-project')),
          matching: find.text(_projectA.name),
        ),
        findsOneWidget,
      );

      attendance.failNextEnsureProjectId = _projectB.id;
      await _chooseProject(tester, attendanceProjectField, _projectB.name);
      expect(attendance.ensureProjectIds.last, _projectB.id);
      expect(attendance.rollingCalls, 2);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(_projectA.name),
        ),
        findsOneWidget,
      );

      await _chooseProject(tester, attendanceProjectField, _projectB.name);
      expect(attendance.rollingCalls, 3);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(_projectB.name),
        ),
        findsOneWidget,
      );

      await _chooseProject(tester, attendanceProjectField, _projectA.name);
      expect(attendance.rollingCalls, 4);
      expect(attendance.ensureProjectIds.last, _projectA.id);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(_projectA.name),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Dashboard with two projects requires selection before scoped tools',
    (tester) async {
      final agenda = _PhoneAgenda(projects: const [_projectA, _projectB]);
      final concrete = _ConcreteFake();
      final attendance = _TrackingAttendance();
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'Test',
              smokeRecordId: 'issue-547-more',
              smokeRecordCreatedAt: '2026-08-31T08:00:00Z',
              agenda: agenda,
              attendance: attendance,
              concrete: concrete,
              concreteAttachments: _picker(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final directoryBaseline = attendance.directoryProjectCalls.length;

      expect(concrete.projectCalls, isEmpty);
      expect(
        find.byKey(const Key('dashboard-project-selection-required')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('active-project-indicator')), findsOneWidget);
      expect(find.byKey(const Key('dashboard-select-project')), findsNothing);
      expect(find.byKey(const Key('dashboard-change-project')), findsNothing);
      expect(find.byKey(const Key('dashboard-concrete-package')), findsNothing);
      expect(
        find.byKey(const Key('dashboard-workforce-directory')),
        findsNothing,
      );
      expect(attendance.directoryProjectCalls.length, directoryBaseline);
      expect(agenda.captureCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('concrete notification anchors the five-tab shell on Ana Sayfa', (
    tester,
  ) async {
    final taps = StreamController<String>.broadcast();
    addTearDown(taps.close);
    final reminder = MobileReminder(
      id: 'notification-reminder',
      projectId: _projectA.id,
      projectName: _projectA.name,
      sourceLogId: null,
      concretePourId: 'pour-from-notification',
      title: 'Beton detayı',
      kind: ReminderKind.action,
      status: ReminderStatus.active,
      nextAttentionAt: '2026-09-04T08:00:00Z',
      createdAt: '2026-09-04T07:00:00Z',
      updatedAt: '2026-09-04T07:00:00Z',
      revision: 1,
    );
    final agenda = FakeAgendaApplication(
      projects: const [_projectA],
      reminderDetail: reminder,
      notificationTapStream: taps.stream,
    );
    await tester.pumpWidget(
      CseApp(
        bootstrap: Future.value(
          BootstrapSuccess(
            environmentLabel: 'Test',
            smokeRecordId: 'issue-620-concrete-notification',
            smokeRecordCreatedAt: '2026-09-04T07:00:00Z',
            agenda: agenda,
            concrete: _ConcreteFake(),
            concreteAttachments: _picker(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajanda').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      2,
    );

    taps.add(reminder.id);
    await tester.pumpAndSettle();

    final detail = tester.widget<ConcretePourDetailPage>(
      find.byType(ConcretePourDetailPage),
    );
    expect(detail.pourId, 'pour-from-notification');
    expect(
      tester
          .widget<NavigationRail>(
            find.byType(NavigationRail, skipOffstage: false),
          )
          .selectedIndex,
      0,
    );
    expect(find.text('Daha', skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _chooseSharedProject(WidgetTester tester, String id) async {
  final control = find
      .byKey(const Key('active-project-indicator'))
      .hitTestable();
  expect(control, findsOneWidget);
  await tester.tap(control);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final option = find
      .byKey(ValueKey('active-project-option-$id'))
      .hitTestable();
  expect(option, findsOneWidget);
  await tester.tap(option);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

class _SelectionInventory implements InventoryApplicationPort {
  final List<String> projects = [];
  final List<Symbol> unexpectedCalls = [];
  Completer<InventoryPrimarySketchProjection?>? next;

  @override
  Future<InventoryPrimarySketchProjection?> loadPrimarySketch(
    String projectId,
  ) async {
    projects.add(projectId);
    final pending = next;
    next = null;
    return pending == null ? null : await pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    unexpectedCalls.add(invocation.memberName);
    throw StateError(
      'Unexpected Inventory operation: ${invocation.memberName}',
    );
  }
}

Future<void> _pumpPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pumpAndSettle();
}

Widget _buildAlbumProjectControl(ValueChanged<String> onSelected) =>
    ActiveProjectControl(
      label: _projectA.name,
      projects: const [_projectA, _projectB],
      onSelected: onSelected,
    );

Future<void> _chooseProject(
  WidgetTester tester,
  Finder dropdown,
  String projectName,
) async {
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(projectName).last);
  await tester.pumpAndSettle();
}

Future<void> _startProjectSelection(
  WidgetTester tester,
  Finder dropdown,
  String projectName,
) async {
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(projectName).last);
  await tester.pump();
}

Future<void> _openDashboardTool(WidgetTester tester, Key key) async {
  final tools = find.byKey(const Key('project-profile-tools'));
  expect(tools, findsOneWidget);
  await tester.ensureVisible(tools);
  await tester.tap(tools);
  await tester.pumpAndSettle();
  final list = find.byKey(const Key('project-profile-tools-sheet'));
  expect(list, findsOneWidget);
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  final state = tester.state<ScrollableState>(scrollable.first);
  state.position.jumpTo(state.position.minScrollExtent);
  await tester.pump();
  final target = find.byKey(key);
  while (target.evaluate().isEmpty &&
      state.position.pixels < state.position.maxScrollExtent) {
    final next = (state.position.pixels + 240)
        .clamp(state.position.minScrollExtent, state.position.maxScrollExtent)
        .toDouble();
    state.position.jumpTo(next);
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

void _expectSettledDailyHome(WidgetTester tester, MobileProject project) {
  expect(find.byType(DailyLogPage), findsNothing);
  expect(find.byKey(const Key('project-profile-home')), findsOneWidget);
  expect(find.byKey(const Key('project-profile-fields')), findsOneWidget);
  expect(find.byKey(const Key('dashboard-loading-projects')), findsNothing);
  expect(find.byKey(const Key('project-profile-loading')), findsNothing);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(
    tester.widget<Text>(find.byKey(const Key('project-profile-name'))).data,
    project.name,
  );
}

class _DailySwitchAgenda extends FakeAgendaApplication {
  _DailySwitchAgenda(this.daily)
    : super(projects: const [_projectA, _projectB]);

  final _OrderedDailyFake daily;
  final profileReads = <String>[];
  final overlappingProfileReads = <String>[];

  @override
  Future<ProjectProfile> getProjectProfile(String projectId) {
    profileReads.add(projectId);
    if (daily.reading) overlappingProfileReads.add(projectId);
    return super.getProjectProfile(projectId);
  }
}

class _OrderedDailyFake extends _DailyFake {
  _OrderedDailyFake()
    : super([
        DailyLogProject(id: _projectA.id, name: _projectA.name),
        DailyLogProject(id: _projectB.id, name: _projectB.name),
      ]);

  Completer<void>? nextRead;
  bool reading = false;

  @override
  Future<DailyLogDay> loadDay({
    required String projectId,
    required String localDay,
  }) async {
    final pending = nextRead;
    nextRead = null;
    reading = true;
    try {
      if (pending != null) await pending.future;
      return await super.loadDay(projectId: projectId, localDay: localDay);
    } finally {
      reading = false;
    }
  }
}

class _DailyFake implements DailyLogApplicationPort {
  _DailyFake(this.projects);

  factory _DailyFake.fromMobile(List<MobileProject> projects) => _DailyFake(
    projects
        .map((project) => DailyLogProject(id: project.id, name: project.name))
        .toList(growable: false),
  );

  final List<DailyLogProject> projects;
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

class _OrderedPlanFake extends UnavailableConstructionLivingPlanApplication {
  _OrderedPlanFake({this.missingSnapshotProjects = const {}});

  final Set<String> missingSnapshotProjects;
  final List<String> planCalls = [];
  final List<String> events = [];
  Completer<List<ConstructionLivingPlanWindowItem>>? nextPlanRead;

  @override
  Future<List<ConstructionLivingPlanWindowItem>> loadSevenDayPlan({
    required String projectId,
    required DateTime windowStart,
  }) async {
    planCalls.add(projectId);
    events.add('plan:$projectId:start');
    final pending = nextPlanRead;
    nextPlanRead = null;
    final result = pending == null
        ? const <ConstructionLivingPlanWindowItem>[]
        : await pending.future;
    events.add('plan:$projectId:success');
    return result;
  }

  @override
  Future<List<ConstructionLivingPlanReferenceCandidate>>
  loadSevenDayReferenceSuggestions({
    required String projectId,
    required DateTime windowStart,
  }) async {
    if (missingSnapshotProjects.contains(projectId)) {
      events.add('suggestions:$projectId:missing');
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_snapshot_missing',
      );
    }
    events.add('suggestions:$projectId:success');
    return const [];
  }
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

  final List<MaterialRequestProject> projects;
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

class _ConcreteFake implements ConcreteApplication {
  final List<String> projectCalls = [];
  final List<ConcretePourQuery> queries = [];

  @override
  Future<List<ConcretePour>> listPours(ConcretePourQuery query) async {
    queries.add(query);
    if (query.projectId case final projectId?) projectCalls.add(projectId);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingAttendance extends FakeAttendanceApplication {
  final List<String> memberProjectCalls = [];
  final List<String> subcontractorProjectCalls = [];
  final List<String> teamProjectCalls = [];
  int ensureDayCalls = 0;
  int rollingCalls = 0;
  final List<String> ensureProjectIds = [];
  String? failNextEnsureProjectId;

  List<String> get directoryProjectCalls => [
    ...memberProjectCalls,
    ...subcontractorProjectCalls,
    ...teamProjectCalls,
  ];

  @override
  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  }) async {
    memberProjectCalls.add(projectId);
    return super.listMembers(projectId, includeInactive: includeInactive);
  }

  @override
  Future<List<Subcontractor>> listSubcontractors(
    String projectId, {
    bool includeArchived = false,
  }) async {
    subcontractorProjectCalls.add(projectId);
    return super.listSubcontractors(
      projectId,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<List<WorkforceTeam>> listTeams(
    String projectId, {
    String? subcontractorId,
    bool includeArchived = false,
  }) async {
    teamProjectCalls.add(projectId);
    return super.listTeams(
      projectId,
      subcontractorId: subcontractorId,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<AttendanceDay> ensureDay(EnsureAttendanceDayCommand command) async {
    ensureDayCalls += 1;
    ensureProjectIds.add(command.projectId);
    if (failNextEnsureProjectId == command.projectId) {
      failNextEnsureProjectId = null;
      throw StateError('synthetic attendance load failure');
    }
    return super.ensureDay(command);
  }

  @override
  Future<void> ensureRollingOccurrences() async {
    rollingCalls += 1;
    return super.ensureRollingOccurrences();
  }
}

class _CatalogFake implements AttachmentCatalogApplication {
  bool failDiscovery = false;
  final List<String> scopedCalls = [];

  @override
  Future<List<AttachmentCatalogProject>> listProjects() async {
    if (failDiscovery) throw StateError('synthetic discovery');
    return const [
      AttachmentCatalogProject(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        name: 'Kuzey',
      ),
      AttachmentCatalogProject(
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        name: 'Güney',
      ),
    ];
  }

  @override
  Future<List<ProjectAttachmentCatalogItem>> listProjectAttachments(
    String projectId,
  ) async {
    scopedCalls.add(projectId);
    return const [];
  }
}

class _LocationFake implements ProjectLocationApplication {
  final List<String> projectCalls = [];

  @override
  Future<List<MobileProjectLocation>> listProjectLocations(
    ProjectLocationQuery query,
  ) async {
    projectCalls.add(query.projectId);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PhoneAgenda extends FakeAgendaApplication
    implements AgendaPhoneCallCaptureApplication {
  _PhoneAgenda({required super.projects});

  int captureCalls = 0;
  bool failNextProjectDiscovery = false;

  @override
  Future<List<MobileProject>> listProjects() async {
    if (failNextProjectDiscovery) {
      failNextProjectDiscovery = false;
      throw StateError('synthetic discovery');
    }
    return super.listProjects();
  }

  @override
  Future<AgendaLog> createPhoneCallAgendaLog(
    CreatePhoneCallAgendaLogCommand command,
  ) async {
    captureCalls += 1;
    throw StateError('phone capture must not run in this test');
  }
}

class _FailOnceAgenda extends FakeAgendaApplication {
  _FailOnceAgenda({required super.projects});

  var _failNextProjectDiscovery = true;

  @override
  Future<List<MobileProject>> listProjects() async {
    if (_failNextProjectDiscovery) {
      _failNextProjectDiscovery = false;
      throw StateError('synthetic discovery');
    }
    return super.listProjects();
  }
}

class _FailOncePhoneAgenda extends _PhoneAgenda {
  _FailOncePhoneAgenda({required super.projects});

  var _failNextProjectDiscovery = true;

  @override
  Future<List<MobileProject>> listProjects() async {
    if (_failNextProjectDiscovery) {
      _failNextProjectDiscovery = false;
      throw StateError('synthetic discovery');
    }
    return super.listProjects();
  }
}

SafeAttachmentPicker _picker() => SafeAttachmentPicker(
  permissions: SafeCapabilityService(_GrantedPermission()),
  picker: _EmptyPicker(),
);

class _GrantedPermission implements PermissionGateway {
  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.granted;
}

class _EmptyPicker implements AttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async => null;
}
