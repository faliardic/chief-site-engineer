import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
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
        await _pump(tester, fake, size: size, locations: _Locations());
        final rail = find.byType(ScreenToolRail);
        final list = find.byKey(const Key('agenda-day-list'));
        expect(
          tester.getRect(list).right,
          lessThanOrEqualTo(tester.getRect(rail).left),
        );
        final actions = tester.widget<ScreenToolRail>(rail).actions;
        expect(actions.map((action) => action.label), [
          'Ara',
          'Filtreler',
          'Yeni proje',
          'Mahal Kataloğu',
        ]);
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
        final empty = find.text('Bu günde Ajanda kaydı yok.');
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

  testWidgets(
    'search rail reveals the same field and only submit runs the query',
    (tester) async {
      final fake = _ReadAgenda()
        ..logs = List.generate(
          20,
          (index) => AgendaLog(
            id: 'log-$index',
            projectId: _project.id,
            projectName: _project.name,
            observedAt: '2026-09-05T06:00:00Z',
            createdAt: '2026-09-05T06:00:00Z',
            updatedAt: '2026-09-05T06:00:00Z',
            revision: 1,
            category: AgendaCategory.inspection,
            description: 'Saha kaydı $index',
            location: null,
            notes: null,
          ),
        );
      await _pump(tester, fake, size: const Size(320, 320));
      final initialQuery = fake.lastAgendaQuery;
      final search = find.byKey(const Key('agenda-search'));
      await tester.tap(search);
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('agenda-literal-search'));
      final input = tester.widget<TextField>(field);
      expect(input.focusNode!.hasFocus, isTrue);
      expect(fake.lastAgendaQuery, same(initialQuery));
      expect(fake.listAgendaCalls, 1);
      expect(input.decoration!.suffixIcon, isNull);
      await tester.enterText(field, '100% _ beton');
      final before = fake.listAgendaCalls;
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(fake.listAgendaCalls, before + 1);
      expect(fake.lastAgendaQuery!.literalSearch, '100% _ beton');
      expect(fake.lastAgendaQuery!.istanbulDay, initialQuery!.istanbulDay);
      input.focusNode!.unfocus();
      final list = tester.widget<ListView>(
        find.byKey(const Key('agenda-day-list')),
      );
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final afterSubmit = fake.listAgendaCalls;
      await tester.tap(search);
      await tester.pumpAndSettle();
      final revealed = tester.widget<TextField>(field);
      expect(revealed.controller, same(input.controller));
      expect(revealed.controller!.text, '100% _ beton');
      expect(revealed.focusNode!.hasFocus, isTrue);
      expect(field.hitTestable(), findsOneWidget);
      expect(fake.listAgendaCalls, afterSubmit);
      expect(tester.takeException(), isNull);
    },
  );

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
      fake.failRead = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('agenda-read-error-retry')), findsNothing);
      expect(find.text('Bu günde Ajanda kaydı yok.'), findsOneWidget);
      expect(fake.readAttempts, 2);
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
  ProjectLocationApplication? locations,
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
      home: AgendaPage(
        agenda: fake,
        activeProjectId: _project.id,
        projectLocations: locations,
      ),
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

class _Locations implements ProjectLocationApplication {
  @override
  Stream<void> get projectChanges => const Stream.empty();
  @override
  Stream<void> get projectLocationChanges => const Stream.empty();
  @override
  Future<List<MobileProject>> listProjects() async => [_project];
  @override
  Future<List<MobileProjectLocation>> listProjectLocations(
    ProjectLocationQuery query,
  ) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
