import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/screen_tool_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _project = MobileProject(
  id: '11111111-1111-4111-8111-111111111111',
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-09-05T06:00:00Z',
  updatedAt: '2026-09-05T06:00:00Z',
  revision: 1,
);

void main() {
  setUpAll(CseTimeCodec.initialize);

  for (final size in [
    const Size(320, 760),
    const Size(390, 760),
    const Size(320, 320),
    const Size(390, 240),
  ]) {
    testWidgets('Agenda rail is reachable at $size and 2x text', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final fake = _ReadAgenda();
        await _pump(tester, fake, size: size);
        final rail = find.byType(ScreenToolRail);
        final list = find.byKey(const Key('agenda-day-list'));
        expect(
          tester.getRect(list).right,
          lessThanOrEqualTo(tester.getRect(rail).left),
        );
        final actions = tester.widget<ScreenToolRail>(rail).actions;
        expect(actions.map((action) => action.label), ['Ara', 'Filtreler']);
        expect(find.byKey(const Key('agenda-search')), findsOneWidget);
        expect(find.byKey(const Key('agenda-literal-search')), findsNothing);
        expect(find.byKey(const Key('agenda-search-input')), findsNothing);
        double? previousY;
        for (final action in actions) {
          final target = find.byKey(action.key);
          expect(find.descendant(of: list, matching: target), findsNothing);
          final y = tester.getTopLeft(target).dy;
          if (previousY != null) expect(y, greaterThan(previousY));
          previousY = y;
        }
        for (final action in actions) {
          final target = find.byKey(action.key);
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
          expect(tester.getSize(target), const Size.square(48));
          expect(tester.widget<IconButton>(target).tooltip, action.label);
          final data = tester
              .getSemantics(find.bySemanticsLabel(action.label))
              .getSemanticsData();
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          expect(
            tester.getRect(target).bottom,
            lessThanOrEqualTo(tester.getRect(rail).bottom),
          );
        }
        final primary = find.byKey(const Key('create-agenda-log'));
        expect(primary.hitTestable(), findsOneWidget);
        expect(tester.getSize(primary).height, greaterThanOrEqualTo(48));
        expect(
          find.descendant(
            of: primary,
            matching: find.text('Ajanda kaydı ekle'),
          ),
          findsOneWidget,
        );
        expect(find.descendant(of: rail, matching: primary), findsNothing);
        for (final key in [
          'agenda-calendar-previous-period',
          'selected-day',
          'agenda-calendar-next-period',
        ]) {
          expect(
            find.descendant(of: list, matching: find.byKey(Key(key))),
            findsOneWidget,
          );
          expect(
            find.descendant(of: rail, matching: find.byKey(Key(key))),
            findsNothing,
          );
        }
        final empty = find.text('Seçili gün için Ajanda kaydı yok.');
        await _revealContent(tester, empty);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(empty).right,
          lessThan(tester.getRect(rail).left),
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('Agenda applies only explicit modal search submissions', (
    tester,
  ) async {
    final fake = _ReadAgenda();
    await _pump(tester, fake, size: const Size(320, 320));
    final searchAction = find.byKey(const Key('agenda-search'));
    expect(searchAction, findsOneWidget);
    expect(find.byKey(const Key('agenda-literal-search')), findsNothing);
    expect(find.byKey(const Key('agenda-search-input')), findsNothing);
    expect(find.text('Literal ara'), findsNothing);
    expect(fake.lastAgendaQuery?.literalSearch, '');
    final callsBeforeOpen = fake.readAttempts;

    await tester.tap(searchAction);
    await tester.pumpAndSettle();

    final dialog = find.byKey(const Key('agenda-search-dialog'));
    final field = find.byKey(const Key('agenda-search-input'));
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    expect(dialog, findsOneWidget);
    expect(field, findsOneWidget);
    expect(find.byKey(const Key('agenda-literal-search')), findsNothing);
    expect(find.text('Literal ara'), findsNothing);
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
    expect(fake.readAttempts, callsBeforeOpen);

    await tester.enterText(field, 'saha');
    await tester.tap(find.byKey(const Key('agenda-search-cancel')));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(fake.lastAgendaQuery?.literalSearch, '');
    expect(fake.readAttempts, callsBeforeOpen);

    await tester.tap(searchAction);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editable).controller.text, '');
    await tester.enterText(field, 'saha');
    await tester.tap(find.byKey(const Key('agenda-search-submit')));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(fake.lastAgendaQuery?.literalSearch, 'saha');

    final callsBeforeClear = fake.readAttempts;
    await tester.tap(searchAction);
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(editable).controller.text, 'saha');
    expect(fake.readAttempts, callsBeforeClear);
    await tester.enterText(field, '');
    await tester.tap(find.byKey(const Key('agenda-search-submit')));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(fake.lastAgendaQuery?.literalSearch, '');
    expect(fake.readAttempts, greaterThan(callsBeforeClear));
    expect(find.byKey(const Key('agenda-literal-search')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'retry and empty state remain reachable and absent capability has no tool',
    (tester) async {
      final fake = _ReadAgenda()..failRead = true;
      await _pump(tester, fake, size: const Size(320, 320));
      expect(
        find.byKey(const Key('open-project-location-catalog')),
        findsNothing,
      );
      final rail = find.byType(ScreenToolRail);
      final retry = find.byKey(const Key('agenda-read-error-retry'));
      await _revealContent(tester, retry);
      await tester.pumpAndSettle();
      expect(retry.hitTestable(), findsOneWidget);
      expect(tester.getRect(retry).right, lessThan(tester.getRect(rail).left));
      final attemptsBeforeRetry = fake.readAttempts;
      fake.failRead = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('agenda-read-error-retry')), findsNothing);
      expect(find.text('Seçili gün için Ajanda kaydı yok.'), findsOneWidget);
      expect(fake.readAttempts, greaterThan(attemptsBeforeRetry));
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _revealContent(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byKey(const Key('agenda-day-list')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(target, 100, scrollable: scrollable);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  FakeAgendaApplication fake, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: AgendaPage(agenda: fake, activeProjectId: _project.id),
    ),
  );
  await tester.pumpAndSettle();
}

class _ReadAgenda extends FakeAgendaApplication {
  _ReadAgenda() : super(projects: [_project]);
  bool failRead = false;
  int readAttempts = 0;

  @override
  Future<List<AgendaLog>> listAgenda(AgendaQuery query) {
    readAttempts++;
    if (failRead) throw StateError('Synthetic read failure');
    return super.listAgenda(query);
  }
}
