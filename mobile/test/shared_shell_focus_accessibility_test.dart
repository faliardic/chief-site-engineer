import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _destinationLabels = [
  'Ana Sayfa',
  'Hatırlatıcı',
  'Ajanda',
  'Envanter',
  'Puantaj',
];

const _project = MobileProject(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-09-04T07:00:00Z',
  updatedAt: '2026-09-04T07:00:00Z',
  revision: 1,
);

void main() {
  testWidgets(
    'compact and rail shell destinations traverse and activate by keyboard',
    (tester) async {
      _configureView(tester, const Size(390, 844));
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpShell(tester);

      var navigation = find.byType(NavigationBar);
      _expectCompactLabels(tester);
      expect(
        await _collectForwardDestinationOrder(tester, navigation),
        _destinationLabels,
      );
      expect(await _previousDestinationLabel(tester, navigation), 'Envanter');
      await _activateFocusedDestination(tester, LogicalKeyboardKey.space);
      expect(tester.widget<NavigationBar>(navigation).selectedIndex, 3);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await _tabUntilDestination(tester, navigation, 'Puantaj');
      await _activateFocusedDestination(tester, LogicalKeyboardKey.enter);
      expect(tester.widget<NavigationBar>(navigation).selectedIndex, 4);

      await _resize(tester, const Size(700, 844));
      _expectCurrentFocusIsValid();
      expect(find.byType(NavigationBar), findsNothing);
      var rail = find.byType(NavigationRail);
      _expectRailLabels(tester, extended: false);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(
        await _collectForwardDestinationOrder(tester, rail),
        _destinationLabels,
      );
      tester.widget<NavigationRail>(rail).onDestinationSelected!(4);
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await _tabUntilDestination(tester, rail, 'Ana Sayfa');
      await _activateFocusedDestination(tester, LogicalKeyboardKey.enter);
      expect(tester.widget<NavigationRail>(rail).selectedIndex, 0);

      await _resize(tester, const Size(900, 844));
      _expectCurrentFocusIsValid();
      rail = find.byType(NavigationRail);
      _expectRailLabels(tester, extended: true);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(
        await _collectForwardDestinationOrder(tester, rail),
        _destinationLabels,
      );
      await _activateFocusedDestination(tester, LogicalKeyboardKey.enter);
      expect(tester.widget<NavigationRail>(rail).selectedIndex, 4);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await _tabUntilDestination(tester, rail, 'Ajanda');
      await _activateFocusedDestination(tester, LogicalKeyboardKey.space);
      expect(tester.widget<NavigationRail>(rail).selectedIndex, 2);

      await _resize(tester, const Size(390, 844));
      _expectCurrentFocusIsValid();
      expect(find.byType(NavigationRail), findsNothing);
      navigation = find.byType(NavigationBar);
      _expectCompactLabels(tester);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await _tabUntilDestination(tester, navigation, 'Ana Sayfa');
      await _activateFocusedDestination(tester, LogicalKeyboardKey.space);
      expect(tester.widget<NavigationBar>(navigation).selectedIndex, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'active project control keeps target semantics and opens one chooser by keyboard',
    (tester) async {
      final semantics = tester.ensureSemantics();
      _configureView(tester, const Size(390, 844));
      await _pumpShell(
        tester,
        agenda: FakeAgendaApplication(projects: const [_project]),
      );

      final control = find.byKey(const Key('active-project-indicator'));
      await tester.tap(control.hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byKey(ValueKey('active-project-option-${_project.id}'))
            .hitTestable(),
      );
      await tester.pumpAndSettle();

      const accessibleLabel = 'Aktif proje: Kuzey Şantiyesi';
      expect(find.byTooltip(accessibleLabel), findsOneWidget);
      final labeledSemantics = find.bySemanticsLabel(accessibleLabel);
      expect(labeledSemantics, findsOneWidget);
      final size = tester.getSize(control);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(labeledSemantics).getSemanticsData().label,
        accessibleLabel,
      );
      final controlSemantics = tester.getSemantics(control).getSemanticsData();
      expect(controlSemantics.label, contains(_project.name));
      expect(controlSemantics.flagsCollection.isButton, isTrue);
      expect(controlSemantics.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.getRect(labeledSemantics), tester.getRect(control));

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await _tabUntilWithin(tester, control);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('active-project-chooser')), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
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
          smokeRecordId: 'issue-642-shared-shell-focus',
          smokeRecordCreatedAt: '2026-09-04T07:00:00Z',
          agenda: agenda ?? FakeAgendaApplication(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _activateFocusedDestination(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<List<String>> _collectForwardDestinationOrder(
  WidgetTester tester,
  Finder navigation,
) async {
  final visited = <String>[];
  for (var attempt = 0; attempt < 80; attempt += 1) {
    await _sendTab(tester);
    final label = _focusedDestinationLabel(navigation);
    if (label != null && (visited.isEmpty || visited.last != label)) {
      visited.add(label);
      if (visited.length == _destinationLabels.length) return visited;
    }
  }
  fail('Tab traversal did not reach every navigation destination.');
}

Future<String> _previousDestinationLabel(
  WidgetTester tester,
  Finder navigation,
) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await _sendShiftTab(tester);
    final label = _focusedDestinationLabel(navigation);
    if (label != null) return label;
  }
  fail('Shift+Tab did not reach a navigation destination.');
}

Future<void> _tabUntilDestination(
  WidgetTester tester,
  Finder navigation,
  String expectedLabel, {
  int maximumTabs = 80,
}) async {
  for (var attempt = 0; attempt < maximumTabs; attempt += 1) {
    if (_focusedDestinationLabel(navigation) == expectedLabel) return;
    await _sendTab(tester);
  }
  fail('Tab traversal did not reach $expectedLabel.');
}

String? _focusedDestinationLabel(Finder navigation) {
  final primaryFocus = FocusManager.instance.primaryFocus;
  if (primaryFocus == null) return null;
  for (final label in _destinationLabels) {
    final labels = find.descendant(of: navigation, matching: find.text(label));
    for (final labelElement in labels.evaluate()) {
      if (identical(Focus.maybeOf(labelElement), primaryFocus)) return label;
    }
  }
  return null;
}

Future<void> _sendTab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

Future<void> _sendShiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}

Future<void> _tabUntilWithin(
  WidgetTester tester,
  Finder owner, {
  int maximumTabs = 80,
}) async {
  for (var attempt = 0; attempt < maximumTabs; attempt += 1) {
    if (_primaryFocusIsWithin(owner)) return;
    await _sendTab(tester);
  }
  fail('Tab traversal did not reach the expected control.');
}

bool _primaryFocusIsWithin(Finder owner) {
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext is! Element) return false;
  for (final ownerElement in owner.evaluate()) {
    if (identical(focusedContext, ownerElement)) return true;
    var found = false;
    focusedContext.visitAncestorElements((ancestor) {
      if (identical(ancestor, ownerElement)) {
        found = true;
        return false;
      }
      return true;
    });
    if (found) return true;
  }
  return false;
}

void _expectCurrentFocusIsValid() {
  final context = FocusManager.instance.primaryFocus?.context;
  expect(context == null || context.mounted, isTrue);
}

void _expectCompactLabels(WidgetTester tester) {
  final navigation = find.byType(NavigationBar);
  expect(navigation, findsOneWidget);
  final widget = tester.widget<NavigationBar>(navigation);
  expect(widget.destinations, hasLength(_destinationLabels.length));
  expect(
    widget.destinations.cast<NavigationDestination>().map(
      (destination) => destination.label,
    ),
    orderedEquals(_destinationLabels),
  );
  expect(widget.labelBehavior, NavigationDestinationLabelBehavior.alwaysShow);
  for (final label in _destinationLabels) {
    expect(
      find.descendant(of: navigation, matching: find.text(label)),
      findsOneWidget,
    );
  }
}

void _expectRailLabels(WidgetTester tester, {required bool extended}) {
  final rail = find.byType(NavigationRail);
  expect(rail, findsOneWidget);
  final widget = tester.widget<NavigationRail>(rail);
  expect(widget.extended, extended);
  expect(widget.destinations, hasLength(_destinationLabels.length));
  expect(
    widget.destinations.map((destination) => (destination.label as Text).data),
    orderedEquals(_destinationLabels),
  );
  for (final label in _destinationLabels) {
    expect(
      find.descendant(of: rail, matching: find.text(label)),
      findsOneWidget,
    );
  }
}
