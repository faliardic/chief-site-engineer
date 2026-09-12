import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:chief_site_engineer/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _destinationLabels = [
  'Ana Sayfa',
  'Hatırlatıcı',
  'Ajanda',
  'Envanter',
  'İş Gücü',
];

void main() {
  testWidgets('shell switches at the exact window-width boundaries', (
    tester,
  ) async {
    _configureView(tester, const Size(599, 800));
    await _pumpShell(tester);

    final compact = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      compact.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );
    expect(
      compact.destinations.cast<NavigationDestination>().map(
        (destination) => destination.label,
      ),
      orderedEquals(_destinationLabels),
    );
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Daha', skipOffstage: false), findsNothing);

    await _resize(tester, const Size(600, 800));
    _expectNarrowRail(tester);

    await _resize(tester, const Size(839, 800));
    _expectNarrowRail(tester);

    await _resize(tester, const Size(840, 800));
    final expanded = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(expanded.extended, isTrue);
    expect(expanded.labelType, isNull);
    expect(_railLabels(expanded), orderedEquals(_destinationLabels));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Daha', skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'portrait-landscape resize preserves selected, visited and project state',
    (tester) async {
      const project = MobileProject(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        name: 'Kuzey Şantiyesi',
        createdAt: '2026-09-04T07:00:00Z',
        updatedAt: '2026-09-04T07:00:00Z',
        revision: 1,
      );
      _configureView(tester, const Size(390, 844));
      await _pumpShell(
        tester,
        agenda: FakeAgendaApplication(projects: const [project]),
      );

      await tester.tap(find.byKey(const Key('active-project-indicator')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('active-project-option-${project.id}')),
      );
      await tester.pumpAndSettle();
      _expectActiveProject(tester, project.name);

      final compactNavigation = find.byType(NavigationBar);
      await tester.tap(
        find.descendant(
          of: compactNavigation,
          matching: find.text('Hatırlatıcı'),
        ),
      );
      await tester.pumpAndSettle();
      final reminderState = tester.state(
        find.byType(RemindersPage, skipOffstage: false),
      );

      await _resize(tester, const Size(840, 390));
      var rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 1);
      expect(
        tester.state(find.byType(RemindersPage, skipOffstage: false)),
        same(reminderState),
      );
      _expectActiveProject(tester, project.name);

      rail.onDestinationSelected!(2);
      await tester.pumpAndSettle();
      final agendaState = tester.state(
        find.byType(AgendaPage, skipOffstage: false),
      );

      await _resize(tester, const Size(390, 844));
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      expect(
        tester.state(find.byType(RemindersPage, skipOffstage: false)),
        same(reminderState),
      );
      expect(
        tester.state(find.byType(AgendaPage, skipOffstage: false)),
        same(agendaState),
      );
      _expectActiveProject(tester, project.name);

      await _resize(tester, const Size(840, 390));
      rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 2);
      expect(
        tester.state(find.byType(RemindersPage, skipOffstage: false)),
        same(reminderState),
      );
      expect(
        tester.state(find.byType(AgendaPage, skipOffstage: false)),
        same(agendaState),
      );
      _expectActiveProject(tester, project.name);

      await tester.tap(find.byKey(const Key('shell-settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byKey(const Key('active-project-indicator')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 2);
      _expectActiveProject(tester, project.name);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large compact text and short landscape remain overflow-free', (
    tester,
  ) async {
    _configureView(tester, const Size(320, 700));
    final semantics = tester.ensureSemantics();
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    await _pumpShell(tester);

    final compact = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(compact.destinations, hasLength(5));
    expect(
      compact.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );

    for (final width in [320.0, 390.0, 600.0, 840.0]) {
      await _resize(tester, Size(width, 700));
      final settings = find.byKey(const Key('shell-settings'));
      expect(settings, findsOneWidget);
      expect(find.byTooltip('Ayarlar'), findsOneWidget);
      expect(tester.getSize(settings).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(settings).height, greaterThanOrEqualTo(48));
      final settingsSemantics = tester.getSemantics(
        find.bySemanticsLabel('Ayarlar'),
      );
      final settingsData = settingsSemantics.getSemanticsData();
      expect(settingsData.label, 'Ayarlar');
      expect(settingsData.hasAction(SemanticsAction.tap), isTrue);
      expect(settingsSemantics.rect.width, greaterThanOrEqualTo(48));
      expect(settingsSemantics.rect.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byKey(const Key('shell-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byKey(const Key('active-project-indicator')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await _resize(tester, const Size(840, 320));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(rail.scrollable, isTrue);
    expect(find.text('Ana Sayfa'), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

void _configureView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _resize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  await tester.pumpAndSettle();
}

Future<void> _pumpShell(
  WidgetTester tester, {
  FakeAgendaApplication? agenda,
}) async {
  await tester.pumpWidget(
    CseApp(
      bootstrap: Future.value(
        BootstrapSuccess(
          environmentLabel: 'Test',
          smokeRecordId: 'issue-620-adaptive-shell',
          smokeRecordCreatedAt: '2026-09-04T07:00:00Z',
          agenda: agenda ?? FakeAgendaApplication(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectActiveProject(WidgetTester tester, String name) {
  final control = tester.widget<ActiveProjectControl>(
    find.byType(ActiveProjectControl),
  );
  expect(control.label, name);
}

void _expectNarrowRail(WidgetTester tester) {
  final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
  expect(rail.extended, isFalse);
  expect(rail.labelType, NavigationRailLabelType.all);
  expect(rail.scrollable, isTrue);
  expect(_railLabels(rail), orderedEquals(_destinationLabels));
  expect(find.byType(NavigationBar), findsNothing);
}

Iterable<String?> _railLabels(NavigationRail rail) =>
    rail.destinations.map((destination) => (destination.label as Text).data);
