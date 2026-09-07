import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/attachments/project_media_album_page.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/inventory/inventory_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
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
    'REM06 running body and Ertele keep exact B under shared active A',
    (tester) async {
      final item = _notificationReminder();
      final agenda = _IntentAgenda(reminders: [item]);
      addTearDown(agenda.intents.close);
      await _pumpShell(tester, agenda);
      await _chooseSharedProject(tester, _projectA.id);
      agenda.intents.add(ReminderNotificationIntent(reminderId: item.id));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ReminderDetailPage>(find.byType(ReminderDetailPage))
            .reminderId,
        item.id,
      );
      expect(
        find.byKey(const Key('reminder-schedule-option-in1Hour')),
        findsNothing,
      );
      final action = ReminderNotificationIntent(
        reminderId: item.id,
        action: ReminderNotificationAction.snooze,
      );
      agenda.intents.add(action);
      agenda.intents.add(action);
      await tester.pumpAndSettle();
      expect(
        find.byType(ReminderDetailPage, skipOffstage: false),
        findsOneWidget,
      );
      final option = find.byKey(const Key('reminder-schedule-option-in1Hour'));
      expect(option, findsOneWidget);
      agenda.intents.add(action);
      await tester.pumpAndSettle();
      expect(option, findsOneWidget);
      expect(
        find.byType(ReminderDetailPage, skipOffstage: false),
        findsOneWidget,
      );
      Navigator.of(tester.element(option)).pop();
      await tester.pumpAndSettle();
      expect(agenda.mutateReminderCalls, 0);
      expect(agenda.reminders, [item]);
      agenda.intents.add(action);
      await tester.pumpAndSettle();
      expect(option, findsOneWidget);
      expect(
        find.byType(ReminderDetailPage, skipOffstage: false),
        findsOneWidget,
      );
      Navigator.of(tester.element(option)).pop();
      await tester.pumpAndSettle();
      _popRoute(tester, find.byType(ReminderDetailPage));
      await tester.pumpAndSettle();
      _expectIndicator(_projectA.name);
    },
  );
  testWidgets('REM06 pending body read retains Ertele without a second route', (
    tester,
  ) async {
    final item = _notificationReminder();
    final agenda = _IntentAgenda(reminders: [item]);
    addTearDown(agenda.intents.close);
    await _pumpShell(tester, agenda);
    final pending = Completer<MobileReminder>();
    agenda.nextNotificationRead = pending;
    agenda.intents.add(ReminderNotificationIntent(reminderId: item.id));
    await tester.pump();
    final action = ReminderNotificationIntent(
      reminderId: item.id,
      action: ReminderNotificationAction.snooze,
    );
    agenda.intents.add(action);
    agenda.intents.add(action);
    await tester.pump();
    expect(find.byType(ReminderDetailPage), findsNothing);
    pending.complete(item);
    await tester.pumpAndSettle();
    expect(
      find.byType(ReminderDetailPage, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('reminder-schedule-option-in1Hour')),
      findsOneWidget,
    );
    expect(agenda.mutateReminderCalls, 0);
    expect(agenda.reminders, [item]);
  });
  testWidgets(
    'REM06 cold action consumed once across shell rebuild and remount',
    (tester) async {
      final item = _notificationReminder();
      final agenda = _IntentAgenda(
        reminders: [item],
        initial: ReminderNotificationIntent(
          reminderId: item.id,
          action: ReminderNotificationAction.snooze,
        ),
      );
      addTearDown(agenda.intents.close);
      await _pumpShell(tester, agenda);
      final option = find.byKey(const Key('reminder-schedule-option-in2Hours'));
      expect(option, findsOneWidget);
      expect(agenda.initialReads, 1);
      Navigator.of(tester.element(option)).pop();
      await tester.pumpAndSettle();
      _popRoute(tester, find.byType(ReminderDetailPage));
      await tester.pumpAndSettle();
      await _chooseSharedProject(tester, _projectA.id);
      expect(option, findsNothing);
      await tester.pumpWidget(const SizedBox());
      await _pumpShell(tester, agenda);
      expect(agenda.initialReads, 2);
      expect(find.byType(ReminderDetailPage), findsNothing);
      expect(option, findsNothing);
      expect(agenda.mutateReminderCalls, 0);
    },
  );
  testWidgets('REM06 invalid or stale intent cannot target another reminder', (
    tester,
  ) async {
    final item = _notificationReminder();
    final agenda = _IntentAgenda(reminders: [item]);
    addTearDown(agenda.intents.close);
    await _pumpShell(tester, agenda);
    agenda.intents.add(
      const ReminderNotificationIntent(
        reminderId: 'invalid',
        action: ReminderNotificationAction.snooze,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReminderDetailPage), findsNothing);
    const staleId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
    agenda.intents.add(
      const ReminderNotificationIntent(
        reminderId: staleId,
        action: ReminderNotificationAction.snooze,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ReminderDetailPage>(find.byType(ReminderDetailPage))
          .reminderId,
      staleId,
    );
    expect(
      find.byKey(const Key('reminder-detail-read-error-retry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('reminder-schedule-option-in1Hour')),
      findsNothing,
    );
    expect(agenda.mutateReminderCalls, 0);
    expect(agenda.reminders, [item]);
  });
  testWidgets(
    'Dashboard B opens exact Inventory B and hidden external A is adopted on return',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      final inventory = _ContextInventory();
      await _pumpShell(tester, agenda, inventory: inventory);
      expect(inventory.projects, isEmpty);
      await _chooseSharedProject(tester, _projectB.id);
      expect(inventory.projects, isEmpty);
      await _openTab(tester, 'Envanter');
      _expectIndicator(_projectB.name);
      expect(inventory.projects, [_projectB.id]);
      final inventoryPage = find.byType(InventoryPage);
      final state = tester.state<InventoryPageState>(inventoryPage);
      expect(state.controller.selectedProjectId, _projectB.id);
      expect(state.controller.loadStatus, InventoryPageLoadStatus.noSketch);
      expect(
        find.descendant(
          of: inventoryPage,
          matching: find.byType(DropdownButtonFormField<String>),
        ),
        findsNothing,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('inventory-page'))).dy,
        tester.getBottomLeft(find.byType(AppBar)).dy,
      );

      await _openTab(tester, 'Hatırlatıcı');
      await tester.tap(
        find.byKey(const Key('active-project-indicator')).hitTestable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byKey(ValueKey('active-project-option-${_projectA.id}'))
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      _expectIndicator(_projectA.name);
      expect(inventory.projects, [_projectB.id]);
      await _openTab(tester, 'Envanter');
      _expectIndicator(_projectA.name);
      expect(inventory.projects, [_projectB.id, _projectA.id]);
      expect(state.controller.selectedProjectId, _projectA.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared AppBar chooser stays textual bounded and usable at 320px large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      try {
        const archived = MobileProject(
          id: 'archived',
          name: 'Arşivli proje',
          createdAt: '2026-09-01T08:00:00Z',
          updatedAt: '2026-09-01T08:00:00Z',
          revision: 2,
          archivedAt: '2026-09-02T08:00:00Z',
        );
        final agenda = FakeAgendaApplication(
          projects: const [_projectA, _projectB, archived],
        );
        final inventory = _ContextInventory();
        await _pumpShell(tester, agenda, inventory: inventory);
        await _openTabIcon(tester, Icons.notifications_none_rounded);
        final control = find
            .byKey(const Key('active-project-indicator'))
            .hitTestable();
        expect(control, findsOneWidget);
        expect(tester.getSize(control).height, greaterThanOrEqualTo(40));
        _expectIndicator('Proje seçilmedi');
        expect(find.byTooltip('Aktif proje: Proje seçilmedi'), findsOneWidget);
        await tester.tap(control);
        await tester.pumpAndSettle();
        final chooser = find.byKey(const Key('active-project-chooser'));
        expect(chooser, findsOneWidget);
        final chooserSurface = find.descendant(
          of: chooser,
          matching: find.byWidgetPredicate(
            (widget) => widget is Material && widget.type == MaterialType.card,
          ),
        );
        expect(chooserSurface, findsOneWidget);
        final logicalViewport =
            tester.view.physicalSize / tester.view.devicePixelRatio;
        final chooserSize = tester.getSize(chooserSurface);
        debugPrint(
          'Chooser Material surface: $chooserSize; logical viewport: '
          '$logicalViewport; DPR: ${tester.view.devicePixelRatio}',
        );
        expect(chooserSize.width, lessThanOrEqualTo(logicalViewport.width));
        expect(chooserSize.height, lessThan(logicalViewport.height));
        expect(
          find.byKey(const Key('active-project-option-archived')),
          findsNothing,
        );
        final option = find
            .byKey(ValueKey('active-project-option-${_projectB.id}'))
            .hitTestable();
        expect(option, findsOneWidget);
        await tester.tap(option);
        await tester.pumpAndSettle();
        _expectIndicator(_projectB.name);
        final controlSemantics = tester
            .getSemantics(control)
            .getSemanticsData();
        expect(controlSemantics.label, contains(_projectB.name));
        expect(controlSemantics.hasAction(SemanticsAction.tap), isTrue);
        agenda.projects = const [_projectA, _projectB];
        await _openTabIcon(tester, Icons.inventory_2_outlined);
        _expectIndicator(_projectB.name);
        expect(inventory.projects, [_projectB.id]);
        expect(control, findsOneWidget);
        await tester.tap(control);
        await tester.pumpAndSettle();
        final inventoryOption = find
            .byKey(ValueKey('active-project-option-${_projectA.id}'))
            .hitTestable();
        expect(inventoryOption, findsOneWidget);
        await tester.tap(inventoryOption);
        await tester.pumpAndSettle();
        _expectIndicator(_projectA.name);
        expect(inventory.projects, [_projectB.id, _projectA.id]);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'no active project stays visible and never becomes an implicit Agenda default',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
      );
      await _pumpShell(tester, agenda);

      _expectIndicator('Proje seçilmedi');
      expect(find.byKey(const Key('dashboard-select-project')), findsNothing);
      expect(find.byKey(const Key('dashboard-change-project')), findsNothing);

      await _openTab(tester, 'Hatırlatıcı');
      _expectIndicator('Proje seçilmedi');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('new-reminder')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('quick-inbox-reminder')),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(ReminderFormPage), findsNothing);
      expect(find.textContaining('bir proje seçin'), findsOneWidget);
      expect(agenda.createReminderCalls, 0);

      await _openTab(tester, 'Ajanda');
      _expectIndicator('Proje seçilmedi');
      await tester.tap(find.byKey(const Key('agenda-filter-action')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(
              find.byKey(const Key('agenda-project-filter')),
            )
            .initialValue,
        isNull,
      );
      await tester.tap(find.byKey(const Key('agenda-filter-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-agenda-log')));
      await tester.pumpAndSettle();
      expect(find.byType(LogFormPage), findsNothing);
      expect(
        find.text('Önce aktif proje veya Ajanda proje filtresi seçin.'),
        findsOneWidget,
      );

      await _openTab(tester, 'Envanter');
      _expectIndicator('Proje seçilmedi');
      expect(
        find.byKey(const Key('inventory-project-selection-required')),
        findsOneWidget,
      );
      await _openTab(tester, 'Puantaj');
      _expectIndicator('Proje seçilmedi');
      await _openTab(tester, 'Hatırlatıcı');
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
      await _chooseSharedProject(tester, _projectB.id);

      await _openTab(tester, 'Hatırlatıcı');
      _expectIndicator(_projectB.name);
      await tester.tap(find.byKey(const Key('new-reminder')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder-project')), findsNothing);
      expect(find.text('Aktif proje: ${_projectB.name}'), findsOneWidget);
      _popRoute(tester, find.byType(ReminderFormPage));
      await tester.pumpAndSettle();
      _expectIndicator(_projectB.name);

      await tester.tap(find.byKey(const Key('new-reminder')));
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
      await tester.tap(find.byKey(const Key('agenda-filter-action')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(
              find.byKey(const Key('agenda-project-filter')),
            )
            .initialValue,
        isNull,
      );
      await tester.tap(find.byKey(const Key('agenda-filter-cancel')));
      await tester.pumpAndSettle();
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

      await tester.tap(find.byKey(const Key('agenda-filter-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agenda-project-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_projectA.name).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agenda-filter-apply')));
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

      await _openTab(tester, 'Hatırlatıcı');
      _expectIndicator(_projectB.name);
      await _openTab(tester, 'Ana Sayfa');
      _expectIndicator(_projectB.name);
      expect(find.byKey(const Key('dashboard-select-project')), findsNothing);
      expect(find.byKey(const Key('dashboard-change-project')), findsNothing);
      await _chooseSharedProject(tester, _projectA.id);
      await _openTab(tester, 'Hatırlatıcı');
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
      await _chooseSharedProject(tester, _projectB.id);
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
      await tester.tap(find.byKey(const Key('new-reminder')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder-project')), findsNothing);
      expect(find.text('Aktif proje: ${_projectB.name}'), findsOneWidget);
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
    'Album validates shared switches in place and rejects failed or stale catalog discovery',
    (tester) async {
      final catalog = _ControlledAlbumCatalog();
      final agenda = _OverlapTrackingAgenda(
        projects: const [_projectA, _projectB],
        isCatalogDiscoveryInFlight: () => catalog.discoveryInFlight,
      );
      await _pumpShell(tester, agenda, attachmentCatalog: catalog);
      await _chooseSharedProject(tester, _projectB.id);
      final session = tester
          .widget<ProjectDashboardPage>(
            find.byType(ProjectDashboardPage, skipOffstage: false),
          )
          .session;

      await _openDashboardTool(tester, const Key('dashboard-project-album'));
      expect(catalog.scopedCalls, [_projectB.id]);
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

      final discoveryBaseline = agenda.listProjectsCalls;
      final scopedBaseline = catalog.scopedCalls.length;
      final localReload = Completer<List<AttachmentCatalogProject>>();
      catalog.nextDiscovery = localReload;
      await tester.tap(
        find.byKey(const Key('active-project-indicator')).hitTestable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byKey(ValueKey('active-project-option-${_projectA.id}'))
            .hitTestable(),
      );
      await tester.pump();

      expect(catalog.discoveryInFlight, isTrue);
      expect(session.selectedProjectId, _projectB.id);
      expect(catalog.scopedCalls.length, scopedBaseline);
      expect(agenda.listProjectsCalls, discoveryBaseline);
      expect(agenda.overlappingProjectDiscoveryCalls, 0);

      localReload.complete(catalog.projects);
      await tester.pumpAndSettle();
      expect(catalog.scopedCalls.last, _projectA.id);
      expect(session.selectedProjectId, _projectA.id);
      expect(
        tester.state(find.byType(ProjectMediaAlbumPage)),
        same(albumState),
      );
      _expectIndicator(_projectA.name);
      expect(agenda.listProjectsCalls, discoveryBaseline);

      await tester.tap(
        find.byKey(const Key('active-project-indicator')).hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('active-project-option-${_albumOnlyProject.id}')),
        findsNothing,
      );
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      catalog.projects = [
        AttachmentCatalogProject(id: _projectA.id, name: _projectA.name),
        _albumOnlyProject,
      ];
      final staleScopedBaseline = catalog.scopedCalls.length;
      await _chooseSharedProject(tester, _projectB.id);
      expect(session.selectedProjectId, _projectA.id);
      expect(catalog.scopedCalls.length, staleScopedBaseline);
      expect(
        find.byKey(const Key('project-media-album-context-unavailable')),
        findsOneWidget,
      );
      expect(
        tester.state(find.byType(ProjectMediaAlbumPage)),
        same(albumState),
      );

      catalog.projects = [
        AttachmentCatalogProject(id: _projectA.id, name: _projectA.name),
        AttachmentCatalogProject(id: _projectB.id, name: _projectB.name),
        _albumOnlyProject,
      ];
      final failedDiscovery = Completer<List<AttachmentCatalogProject>>();
      catalog.nextDiscovery = failedDiscovery;
      final failedScopedBaseline = catalog.scopedCalls.length;
      await tester.tap(
        find.byKey(const Key('active-project-indicator')).hitTestable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byKey(ValueKey('active-project-option-${_projectB.id}'))
            .hitTestable(),
      );
      await tester.pump();
      failedDiscovery.completeError(StateError('synthetic catalog failure'));
      await tester.pumpAndSettle();
      expect(session.selectedProjectId, _projectA.id);
      expect(catalog.scopedCalls.length, failedScopedBaseline);
      expect(
        find.byKey(const Key('project-media-album-error')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('project-media-album-retry')));
      await tester.pumpAndSettle();
      expect(catalog.scopedCalls.last, _projectA.id);
      expect(session.selectedProjectId, _projectA.id);
      expect(agenda.overlappingProjectDiscoveryCalls, 0);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('project-profile-header')),
          matching: find.text(_projectA.name),
        ),
        findsOneWidget,
      );

      await _openTab(tester, 'Hatırlatıcı');
      _expectIndicator(_projectA.name);
      await _openTab(tester, 'Ajanda');
      _expectIndicator(_projectA.name);
      await _openTab(tester, 'Puantaj');
      _expectIndicator(_projectA.name);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpShell(
  WidgetTester tester,
  FakeAgendaApplication agenda, {
  AttachmentCatalogApplication? attachmentCatalog,
  InventoryApplicationPort? inventory,
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
          inventory: inventory ?? const UnavailableInventoryApplication(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _chooseSharedProject(WidgetTester tester, String id) async {
  final control = find
      .byKey(const Key('active-project-indicator'))
      .hitTestable();
  expect(control, findsOneWidget);
  await tester.tap(control);
  await tester.pumpAndSettle();
  final option = find
      .byKey(ValueKey('active-project-option-$id'))
      .hitTestable();
  expect(option, findsOneWidget);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _openTabIcon(WidgetTester tester, IconData icon) async {
  final navigation = find.byType(NavigationBar).evaluate().isNotEmpty
      ? find.byType(NavigationBar)
      : find.byType(NavigationRail);
  expect(navigation, findsOneWidget);
  final destination = find
      .descendant(of: navigation, matching: find.byIcon(icon))
      .hitTestable();
  expect(destination, findsOneWidget);
  await tester.tap(destination);
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
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
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void _expectIndicator(String label) {
  expect(find.byType(ActiveProjectControl), findsOneWidget);
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
  final hitTestableSubmit = submit.hitTestable();
  expect(hitTestableSubmit, findsOneWidget);
  await tester.tap(hitTestableSubmit);
  await tester.pumpAndSettle();
  if (find.text('Anladım').evaluate().isNotEmpty) {
    await tester.tap(find.text('Anladım'));
    await tester.pumpAndSettle();
  }
}

class _ContextInventory extends UnavailableInventoryApplication {
  final List<String> projects = [];

  @override
  Future<InventoryPrimarySketchProjection?> loadPrimarySketch(
    String projectId,
  ) async {
    projects.add(projectId);
    return null;
  }
}

class _ControlledAlbumCatalog implements AttachmentCatalogApplication {
  List<AttachmentCatalogProject> projects = const [
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

class _IntentAgenda extends FakeAgendaApplication
    implements ReminderNotificationIntentSource {
  _IntentAgenda({required super.reminders, this.initial})
    : super(projects: const [_projectA, _projectB]);
  ReminderNotificationIntent? initial;
  final intents = StreamController<ReminderNotificationIntent>.broadcast();
  Completer<MobileReminder>? nextNotificationRead;
  int initialReads = 0;
  @override
  Future<MobileReminder> getReminderDetail(String reminderId) {
    final pending = nextNotificationRead;
    nextNotificationRead = null;
    return pending?.future ?? super.getReminderDetail(reminderId);
  }

  @override
  Stream<ReminderNotificationIntent> get notificationIntents => intents.stream;
  @override
  ReminderNotificationIntent? takeInitialNotificationIntent() {
    initialReads += 1;
    final result = initial;
    initial = null;
    return result;
  }
}

MobileReminder _notificationReminder() => MobileReminder(
  id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  projectId: _projectB.id,
  projectName: _projectB.name,
  sourceLogId: null,
  title: 'B bildirim kaydı',
  kind: ReminderKind.action,
  status: ReminderStatus.active,
  nextAttentionAt: '2026-09-09T06:00:00Z',
  createdAt: '2026-09-07T03:00:00Z',
  updatedAt: '2026-09-07T03:00:00Z',
  revision: 1,
);
