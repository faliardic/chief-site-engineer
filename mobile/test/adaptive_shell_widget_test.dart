import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _destinationLabels = [
  'Ana Sayfa',
  'Hatırlatıcı',
  'Ajanda',
  'Envanter',
  'Puantaj',
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

  testWidgets('selected and visited tab state survives bar and rail resizes', (
    tester,
  ) async {
    _configureView(tester, const Size(599, 800));
    await _pumpShell(tester);

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

    await _resize(tester, const Size(600, 800));
    var rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 1);
    expect(
      tester.state(find.byType(RemindersPage, skipOffstage: false)),
      same(reminderState),
    );

    rail.onDestinationSelected!(2);
    await tester.pumpAndSettle();
    final agendaState = tester.state(
      find.byType(AgendaPage, skipOffstage: false),
    );

    await _resize(tester, const Size(840, 800));
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

    await _resize(tester, const Size(599, 800));
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('large compact text and short landscape remain overflow-free', (
    tester,
  ) async {
    _configureView(tester, const Size(320, 700));
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
    expect(tester.takeException(), isNull);

    await _resize(tester, const Size(840, 320));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(rail.scrollable, isTrue);
    expect(find.text('Ana Sayfa'), findsWidgets);
    expect(tester.takeException(), isNull);
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

Future<void> _pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    CseApp(
      bootstrap: Future.value(
        BootstrapSuccess(
          environmentLabel: 'Test',
          smokeRecordId: 'issue-620-adaptive-shell',
          smokeRecordCreatedAt: '2026-09-04T07:00:00Z',
          agenda: FakeAgendaApplication(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
