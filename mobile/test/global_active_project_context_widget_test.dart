import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

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

const _albumOnlyProject = AttachmentCatalogProject(
  id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  name: 'Albümde eski proje',
);

void main() {
  testWidgets(
    'no active project stays visible and never becomes an implicit Agenda default',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      await _pumpShell(tester, agenda);

      expect(find.byKey(const Key('active-project-indicator')), findsNothing);

      await _openTab(tester, 'Hatırlatıcı');
      _expectIndicator('Proje seçilmedi');
      await tester.tap(find.byKey(const Key('quick-reminder')));
      await tester.pumpAndSettle();
      expect(find.byType(ReminderFormPage), findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(
              find.byKey(const Key('reminder-project')),
            )
            .initialValue,
        isNull,
      );
      _popRoute(tester, find.byType(ReminderFormPage));
      await tester.pumpAndSettle();

      await _openTab(tester, 'Ajanda');
      _expectIndicator('Proje seçilmedi');
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(
              find.byKey(const Key('agenda-project-filter')),
            )
            .initialValue,
        isNull,
      );
      await tester.tap(find.byKey(const Key('create-agenda-log')));
      await tester.pumpAndSettle();
      expect(find.byType(LogFormPage), findsNothing);
      expect(
        find.text('Önce aktif proje veya Ajanda proje filtresi seçin.'),
        findsOneWidget,
      );

      await _openTab(tester, 'Envanter');
      expect(find.byKey(const Key('active-project-indicator')), findsNothing);
      await _openTab(tester, 'Puantaj');
      _expectIndicator('Proje seçilmedi');
      await _openTab(tester, 'Daha');
      _expectIndicator('Proje seçilmedi');

      expect(agenda.createReminderCalls, 0);
      expect(agenda.createLogCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'active B is visible and defaults new captures without form-local retargeting',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      await _pumpShell(tester, agenda);
      await tester.tap(find.byTooltip('Proje seç'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('dashboard-project-${_projectB.id}')),
      );
      await tester.pumpAndSettle();

      await _openTab(tester, 'Hatırlatıcı');
      _expectIndicator(_projectB.name);
      await tester.tap(find.byKey(const Key('quick-reminder')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(
              find.byKey(const Key('reminder-project')),
            )
            .initialValue,
        _projectB.id,
      );
      await tester.tap(find.byKey(const Key('reminder-project')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_projectA.name).last);
      await tester.pumpAndSettle();
      _popRoute(tester, find.byType(ReminderFormPage));
      await tester.pumpAndSettle();
      _expectIndicator(_projectB.name);

      await tester.tap(find.byKey(const Key('quick-reminder')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'B projesi saha kontrolü',
      );
      await _submitReminder(tester);
      expect(agenda.createReminderCalls, 1);
      expect(agenda.lastReminderCommand?.projectId, _projectB.id);
      _expectIndicator(_projectB.name);

      await _openTab(tester, 'Ajanda');
      _expectIndicator(_projectB.name);
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(
              find.byKey(const Key('agenda-project-filter')),
            )
            .initialValue,
        isNull,
      );
      await tester.tap(find.byKey(const Key('create-agenda-log')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LogFormPage>(find.byType(LogFormPage)).initialProjectId,
        _projectB.id,
      );
      await tester.tap(find.byKey(const Key('log-project')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_projectA.name).last);
      await tester.pumpAndSettle();
      _popRoute(tester, find.byType(LogFormPage));
      await tester.pumpAndSettle();
      _expectIndicator(_projectB.name);

      await tester.tap(find.byKey(const Key('agenda-project-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_projectA.name).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-agenda-log')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LogFormPage>(find.byType(LogFormPage)).initialProjectId,
        _projectA.id,
      );
      _popRoute(tester, find.byType(LogFormPage));
      await tester.pumpAndSettle();
      _expectIndicator(_projectB.name);

      await _openTab(tester, 'Daha');
      _expectIndicator(_projectB.name);
      await _openTab(tester, 'Başlangıç');
      expect(find.byKey(const Key('active-project-indicator')), findsNothing);
      await tester.tap(find.byKey(const Key('dashboard-change-project')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('dashboard-project-${_projectA.id}')),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, 'Daha');
      _expectIndicator(_projectA.name);

      expect(agenda.createLogCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'transient project refresh failure preserves visible and capture B context',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      await _pumpShell(tester, agenda);
      await tester.tap(find.byTooltip('Proje seç'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('dashboard-project-${_projectB.id}')),
      );
      await tester.pumpAndSettle();
      await _openTab(tester, 'Hatırlatıcı');
      _expectIndicator(_projectB.name);

      final failedRefresh = Completer<List<MobileProject>>();
      agenda.listProjectsResponses.add(failedRefresh.future);
      await agenda.createProject(
        const CreateProjectCommand(
          id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          name: 'Doğu',
        ),
      );
      await tester.pump();
      failedRefresh.completeError(
        StateError('transient project discovery failure'),
      );
      await tester.pumpAndSettle();

      _expectIndicator(_projectB.name);
      await tester.tap(find.byKey(const Key('quick-reminder')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(
              find.byKey(const Key('reminder-project')),
            )
            .initialValue,
        _projectB.id,
      );
      _popRoute(tester, find.byType(ReminderFormPage));
      await tester.pumpAndSettle();

      await _openTab(tester, 'Ajanda');
      _expectIndicator(_projectB.name);
      await tester.tap(find.byKey(const Key('create-agenda-log')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LogFormPage>(find.byType(LogFormPage)).initialProjectId,
        _projectB.id,
      );
      _popRoute(tester, find.byType(LogFormPage));
      await tester.pumpAndSettle();

      expect(agenda.createReminderCalls, 0);
      expect(agenda.createLogCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Album adopts cached A without overlapping discovery and rejects stale ID',
    (tester) async {
      final catalog = _ControlledAlbumCatalog();
      final agenda = _OverlapTrackingAgenda(
        projects: const [_projectA, _projectB],
        isCatalogDiscoveryInFlight: () => catalog.discoveryInFlight,
      );
      await _pumpShell(tester, agenda, attachmentCatalog: catalog);
      await tester.tap(find.byTooltip('Proje seç'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('dashboard-project-${_projectB.id}')),
      );
      await tester.pumpAndSettle();

      await _openDashboardTool(tester, const Key('dashboard-project-album'));
      expect(catalog.scopedCalls, [_projectB.id]);

      final discoveryBaseline = agenda.listProjectsCalls;
      final localReload = Completer<List<AttachmentCatalogProject>>();
      catalog.nextDiscovery = localReload;
      await tester.tap(find.byKey(ValueKey('album-project-${_projectB.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_projectA.name).last);
      await tester.pump();

      expect(catalog.discoveryInFlight, isTrue);
      expect(agenda.listProjectsCalls, discoveryBaseline);
      expect(agenda.overlappingProjectDiscoveryCalls, 0);

      localReload.complete(catalog.projects);
      await tester.pumpAndSettle();
      expect(catalog.scopedCalls.last, _projectA.id);

      final staleValidationBaseline = agenda.listProjectsCalls;
      await tester.tap(find.byKey(ValueKey('album-project-${_projectA.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_albumOnlyProject.name).last);
      await tester.pumpAndSettle();
      expect(agenda.listProjectsCalls, staleValidationBaseline + 1);
      expect(agenda.overlappingProjectDiscoveryCalls, 0);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('dashboard-project-header')),
          matching: find.text(_projectA.name),
        ),
        findsOneWidget,
      );

      await _openTab(tester, 'Hatırlatıcı');
      _expectIndicator(_projectA.name);
      await _openTab(tester, 'Ajanda');
      _expectIndicator(_projectA.name);
      await _openTab(tester, 'Daha');
      _expectIndicator(_projectA.name);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpShell(
  WidgetTester tester,
  FakeAgendaApplication agenda, {
  AttachmentCatalogApplication? attachmentCatalog,
}) async {
  await tester.pumpWidget(
    CseApp(
      bootstrap: Future.value(
        BootstrapSuccess(
          environmentLabel: 'test',
          smokeRecordId: 'global-active-project-context',
          smokeRecordCreatedAt: '2026-08-31T08:00:00Z',
          agenda: agenda,
          attachmentCatalog: attachmentCatalog,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _openDashboardTool(WidgetTester tester, Key key) async {
  final list = find.byKey(const Key('project-dashboard-list'));
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
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void _expectIndicator(String label) {
  final indicator = find.byKey(const Key('active-project-indicator'));
  expect(indicator, findsOneWidget);
  expect(
    find.descendant(of: indicator, matching: find.text(label)),
    findsOneWidget,
  );
}

void _popRoute(WidgetTester tester, Finder routeContent) {
  Navigator.of(tester.element(routeContent)).pop();
}

Future<void> _submitReminder(WidgetTester tester) async {
  final submit = find.byKey(const Key('submit-reminder'));
  final scrollable = find.ancestor(
    of: submit,
    matching: find.byType(Scrollable),
  );
  expect(scrollable, findsOneWidget);
  await tester.scrollUntilVisible(submit, 200, scrollable: scrollable);
  await tester.pumpAndSettle();
  for (
    var dragCount = 0;
    dragCount < 6 && submit.hitTestable().evaluate().isEmpty;
    dragCount += 1
  ) {
    await tester.drag(scrollable, const Offset(0, -48));
    await tester.pumpAndSettle();
  }
  final hitTestableSubmit = submit.hitTestable();
  expect(hitTestableSubmit, findsOneWidget);
  await tester.tap(hitTestableSubmit);
  await tester.pumpAndSettle();
}

class _ControlledAlbumCatalog implements AttachmentCatalogApplication {
  final List<AttachmentCatalogProject> projects = const [
    AttachmentCatalogProject(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      name: 'Kuzey',
    ),
    AttachmentCatalogProject(
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      name: 'Güney',
    ),
    _albumOnlyProject,
  ];
  final List<String> scopedCalls = [];
  Completer<List<AttachmentCatalogProject>>? nextDiscovery;
  bool discoveryInFlight = false;

  @override
  Future<List<AttachmentCatalogProject>> listProjects() async {
    final pending = nextDiscovery;
    if (pending == null) return List.unmodifiable(projects);
    nextDiscovery = null;
    discoveryInFlight = true;
    try {
      return List.unmodifiable(await pending.future);
    } finally {
      discoveryInFlight = false;
    }
  }

  @override
  Future<List<ProjectAttachmentCatalogItem>> listProjectAttachments(
    String projectId,
  ) async {
    scopedCalls.add(projectId);
    return const [];
  }
}

class _OverlapTrackingAgenda extends FakeAgendaApplication {
  _OverlapTrackingAgenda({
    required super.projects,
    required this.isCatalogDiscoveryInFlight,
  });

  final bool Function() isCatalogDiscoveryInFlight;
  int overlappingProjectDiscoveryCalls = 0;

  @override
  Future<List<MobileProject>> listProjects() async {
    if (isCatalogDiscoveryInFlight()) {
      overlappingProjectDiscoveryCalls += 1;
    }
    return super.listProjects();
  }
}
