import 'dart:ui' show Tristate;
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_agenda_application.dart';

Finder _key(String key) => find.byKey(Key(key));
Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _date(WidgetTester tester, DateTime date) async {
  await _tap(tester, _key('selected-day'));
  final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
  expect(picker.firstDate, DateTime(2000));
  expect(picker.lastDate, DateTime(2100));
  Navigator.of(tester.element(find.byType(DatePickerDialog))).pop(date);
  await tester.pumpAndSettle();
}

Future<void> _mode(WidgetTester tester, bool month) async {
  await _tap(
    tester,
    find.descendant(
      of: _key('agenda-calendar-mode'),
      matching: find.text(month ? 'Ay' : 'Hafta'),
    ),
  );
}

void main() {
  setUpAll(CseTimeCodec.initialize);
  testWidgets(
    'week Monday-Sunday, presentation-only mode and one query per exact day',
    (tester) async {
      final fake = FakeAgendaApplication();
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
      await tester.pumpAndSettle();
      expect(fake.listAgendaCalls, 1);
      expect(
        tester
            .widget<SegmentedButton<bool>>(_key('agenda-calendar-mode'))
            .selected,
        {false},
      );
      expect(_key('previous-day'), findsNothing);
      expect(_key('next-day'), findsNothing);
      await _date(tester, DateTime(2026, 9, 9));
      expect(fake.listAgendaCalls, 2);
      for (var day = 7; day <= 13; day++) {
        expect(
          _key('agenda-calendar-day-2026-09-${day.toString().padLeft(2, '0')}'),
          findsOneWidget,
        );
      }
      final before = fake.listAgendaCalls;
      await _mode(tester, true);
      expect(fake.listAgendaCalls, before);
      expect(fake.lastAgendaQuery!.istanbulDay, '2026-09-09');
      final monday = tester.getRect(_key('agenda-calendar-day-2026-09-07'));
      final tuesday = tester.getRect(_key('agenda-calendar-day-2026-09-01'));
      expect(tuesday.left - monday.left, 56);
      expect(tuesday.top, lessThan(monday.top));
      expect(_key('agenda-calendar-day-2026-08-31'), findsNothing);
      expect(_key('agenda-calendar-day-2026-10-01'), findsNothing);
      await _tap(tester, _key('agenda-calendar-day-2026-09-30'));
      expect(fake.listAgendaCalls, before + 1);
      expect(fake.lastAgendaQuery!.istanbulDay, '2026-09-30');
      await _mode(tester, false);
      expect(fake.listAgendaCalls, before + 1);
      await _tap(tester, _key('agenda-calendar-day-2026-10-01'));
      expect(fake.listAgendaCalls, before + 2);
      expect(fake.lastAgendaQuery!.istanbulDay, '2026-10-01');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'calendar preserves exact non-default query and mode across day selection',
    (tester) async {
      const project = MobileProject(
        id: 'project-a',
        name: 'Kuzey',
        createdAt: '2026-09-01T08:00:00Z',
        updatedAt: '2026-09-01T08:00:00Z',
        revision: 1,
      );
      final fake = FakeAgendaApplication(projects: [project]);
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
      await tester.pumpAndSettle();
      await _date(tester, DateTime(2026, 9, 9));
      await _tap(tester, _key('agenda-filter-action'));
      tester
          .widget<SegmentedButton<AgendaArchiveFilter>>(
            _key('agenda-archive-filter'),
          )
          .onSelectionChanged!({AgendaArchiveFilter.archived});
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<AgendaSortOrder>>(
            _key('agenda-sort-order'),
          )
          .onChanged!(AgendaSortOrder.oldestFirst);
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<String?>>(
            _key('agenda-project-filter'),
          )
          .onChanged!(project.id);
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<AgendaCategory?>>(
            _key('agenda-category-filter'),
          )
          .onChanged!(AgendaCategory.inspection);
      await tester.pump();
      await _tap(tester, _key('agenda-filter-apply'));
      await _tap(tester, _key('agenda-search'));
      await tester.enterText(_key('agenda-literal-search'), '100% _ exact');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      final calls = fake.listAgendaCalls;
      await _mode(tester, true);
      expect(fake.listAgendaCalls, calls);
      await _tap(tester, _key('agenda-calendar-day-2026-09-18'));
      expect(fake.listAgendaCalls, calls + 1);
      final query = fake.lastAgendaQuery!;
      expect(query.istanbulDay, '2026-09-18');
      expect(query.literalSearch, '100% _ exact');
      expect(query.projectId, project.id);
      expect(query.category, AgendaCategory.inspection);
      expect(query.archiveFilter, AgendaArchiveFilter.archived);
      expect(query.sortOrder, AgendaSortOrder.oldestFirst);
      await _mode(tester, false);
      expect(fake.listAgendaCalls, calls + 1);
      expect(fake.lastAgendaQuery, same(query));
    },
  );

  testWidgets(
    'periods use seven days and clamp month ends including leap year; today resets',
    (tester) async {
      final fake = FakeAgendaApplication();
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
      await tester.pumpAndSettle();
      await _date(tester, DateTime(2026, 12, 30));
      var calls = fake.listAgendaCalls;
      await _tap(tester, _key('agenda-calendar-next-period'));
      expect(fake.lastAgendaQuery!.istanbulDay, '2027-01-06');
      expect(fake.listAgendaCalls, ++calls);
      await _tap(tester, _key('agenda-calendar-previous-period'));
      expect(fake.lastAgendaQuery!.istanbulDay, '2026-12-30');
      expect(fake.listAgendaCalls, ++calls);
      await _mode(tester, true);
      expect(fake.listAgendaCalls, calls);
      for (final sample in [
        (DateTime(2024, 1, 31), '2024-02-29'),
        (DateTime(2025, 1, 31), '2025-02-28'),
        (DateTime(2026, 12, 31), '2027-01-31'),
      ]) {
        await _date(tester, sample.$1);
        calls = fake.listAgendaCalls;
        await _tap(tester, _key('agenda-calendar-next-period'));
        expect(fake.lastAgendaQuery!.istanbulDay, sample.$2);
        expect(fake.listAgendaCalls, calls + 1);
      }
      await _date(tester, DateTime(2026, 3, 31));
      calls = fake.listAgendaCalls;
      await _tap(tester, _key('agenda-calendar-previous-period'));
      expect(fake.lastAgendaQuery!.istanbulDay, '2026-02-28');
      expect(fake.listAgendaCalls, calls + 1);
      await _tap(tester, _key('agenda-today'));
      expect(
        fake.lastAgendaQuery!.istanbulDay,
        CseTimeCodec.istanbulDayKey(
          CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
        ),
      );
      expect(fake.listAgendaCalls, calls + 2);
    },
  );

  for (final size in [
    const Size(320, 760),
    const Size(390, 760),
    const Size(320, 300),
    const Size(390, 240),
  ]) {
    testWidgets(
      'calendar horizontal scroll retains 48dp targets and semantics at $size 2x',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        try {
          final fake = FakeAgendaApplication();
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: AgendaPage(agenda: fake),
            ),
          );
          await tester.pumpAndSettle();
          await _date(tester, DateTime(2026, 9, 7));
          for (final month in [false, true]) {
            await _mode(tester, month);
            final target = _key('agenda-calendar-day-2026-09-13');
            await _tap(tester, target);
            expect(target.hitTestable(), findsOneWidget);
            expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
            final data = tester
                .getSemantics(
                  find
                      .ancestor(
                        of: target,
                        matching: find.byWidgetPredicate(
                          (widget) =>
                              widget is Semantics &&
                              widget.properties.label == '2026-09-13',
                        ),
                      )
                      .first,
                )
                .getSemanticsData();
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.flagsCollection.isSelected, Tristate.isTrue);
            expect(_key('create-agenda-log').hitTestable(), findsOneWidget);
            final horizontal = find.descendant(
              of: _key('agenda-calendar-days'),
              matching: find.byType(Scrollable),
            );
            expect(
              tester
                  .state<ScrollableState>(horizontal)
                  .position
                  .maxScrollExtent,
              greaterThan(0),
            );
            expect(
              tester.getRect(_key('agenda-calendar')).right,
              lessThanOrEqualTo(tester.getRect(_key('agenda-day-list')).right),
            );
            expect(tester.takeException(), isNull);
          }
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
