import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  setUpAll(CseTimeCodec.initialize);

  for (final width in [320.0, 390.0]) {
    testWidgets(
      'labeled calendar modes and exact visible-day query fit ${width.toInt()} px at 2x text',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final initialDay = _istanbulToday();
          final targetDay = _otherVisibleWeekDay(initialDay);
          final initialLog = _log(
            id: 'initial-log',
            day: initialDay,
            description: 'İlk gün saha kaydı',
          );
          final targetLog = _log(
            id: 'target-log',
            day: targetDay,
            description: 'Seçilen gün saha kaydı',
          );
          final agenda = _DayFilteringAgenda(
            projects: const [_project],
            logs: [initialLog, targetLog],
          );
          await _pumpAgenda(tester, agenda, size: Size(width, 480));

          final mode = find.byKey(const Key('agenda-calendar-mode'));
          final modeScroll = find.byKey(
            const Key('agenda-calendar-mode-scroll'),
          );
          final month = find.byKey(const Key('agenda-calendar-mode-month'));
          final week = find.byKey(const Key('agenda-calendar-mode-week'));
          expect(mode, findsOneWidget);
          expect(modeScroll, findsOneWidget);
          expect(month, findsOneWidget);
          expect(week, findsOneWidget);
          expect(tester.widget<Semantics>(month).properties.label, 'Aylık');
          expect(tester.widget<Semantics>(week).properties.label, 'Haftalık');
          expect(tester.getSize(mode).height, greaterThanOrEqualTo(48));
          expect(tester.getRect(modeScroll).left, greaterThanOrEqualTo(0));
          expect(tester.getRect(modeScroll).right, lessThanOrEqualTo(width));
          expect(tester.widget<SegmentedButton<bool>>(mode).selected, {false});

          final initialCalls = agenda.listAgendaCalls;
          await tester.tap(month);
          await tester.pumpAndSettle();
          expect(agenda.listAgendaCalls, initialCalls);
          expect(tester.widget<SegmentedButton<bool>>(mode).selected, {true});
          await tester.ensureVisible(week);
          await tester.pumpAndSettle();
          await tester.tap(week);
          await tester.pumpAndSettle();
          expect(agenda.listAgendaCalls, initialCalls);
          expect(tester.widget<SegmentedButton<bool>>(mode).selected, {false});

          final initialProject = agenda.lastAgendaQuery!.projectId;
          final target = find.byKey(Key('agenda-calendar-day-$targetDay'));
          expect(target, findsOneWidget);
          await _revealInAgenda(tester, target);
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(agenda.listAgendaCalls, initialCalls + 1);
          expect(agenda.lastAgendaQuery!.istanbulDay, targetDay);
          expect(agenda.lastAgendaQuery!.projectId, initialProject);
          expect(find.byKey(const Key('agenda-log-initial-log')), findsNothing);

          final targetCard = find.byKey(const Key('agenda-log-target-log'));
          await _revealInAgenda(tester, targetCard);
          expect(targetCard, findsOneWidget);
          expect(find.text('Seçilen gün saha kaydı'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'day selection retains active project and secondary tools before create',
    (tester) async {
      final initialDay = _istanbulToday();
      final targetDay = _otherVisibleWeekDay(initialDay);
      final agenda = _DayFilteringAgenda(
        projects: const [_project],
        logs: [
          _log(
            id: 'target-log',
            day: targetDay,
            description: 'Proje bağlamlı günlük kayıt',
          ),
        ],
      );
      await _pumpAgenda(tester, agenda, size: const Size(390, 520));

      final initialProject = agenda.lastAgendaQuery!.projectId;
      final targetDayAction = find.byKey(Key('agenda-calendar-day-$targetDay'));
      await _revealInAgenda(tester, targetDayAction);
      await tester.tap(targetDayAction);
      await tester.pumpAndSettle();
      expect(agenda.lastAgendaQuery!.istanbulDay, targetDay);
      expect(agenda.lastAgendaQuery!.projectId, initialProject);

      final search = find.byKey(const Key('agenda-search'));
      final filters = find.byKey(const Key('agenda-filter-action'));
      expect(search, findsOneWidget);
      expect(filters, findsOneWidget);
      expect(search.hitTestable(), findsOneWidget);
      expect(filters.hitTestable(), findsOneWidget);
      final callsBeforeSearch = agenda.listAgendaCalls;
      await tester.tap(search);
      await tester.pumpAndSettle();
      expect(agenda.listAgendaCalls, callsBeforeSearch);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('agenda-literal-search')))
            .focusNode!
            .hasFocus,
        isTrue,
      );

      await tester.tap(filters);
      await tester.pumpAndSettle();
      final filterSheet = find.byKey(const Key('agenda-filter-sheet'));
      final filterCancel = find.byKey(const Key('agenda-filter-cancel'));
      expect(filterSheet, findsOneWidget);
      await tester.scrollUntilVisible(
        filterCancel,
        120,
        scrollable: find.descendant(
          of: filterSheet,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(filterCancel);
      await tester.pumpAndSettle();
      expect(agenda.lastAgendaQuery!.istanbulDay, targetDay);
      expect(agenda.lastAgendaQuery!.projectId, initialProject);

      final create = find.byKey(const Key('create-agenda-log'));
      expect(create.hitTestable(), findsOneWidget);
      expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
      await tester.tap(create);
      await tester.pumpAndSettle();
      final form = tester.widget<LogFormPage>(find.byType(LogFormPage));
      expect(form.initialProjectId, _projectId);
      expect(form.initialIstanbulDay, targetDay);
      expect(find.byKey(const Key('log-description')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpAgenda(
  WidgetTester tester,
  _DayFilteringAgenda agenda, {
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
      home: AgendaPage(agenda: agenda, activeProjectId: _projectId),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _revealInAgenda(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byKey(const Key('agenda-day-list')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

String _istanbulToday() =>
    CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(DateTime.now().toUtc()));

String _otherVisibleWeekDay(String selectedDay) {
  final selected = DateTime.parse('${selectedDay}T00:00:00Z');
  final monday = selected.subtract(Duration(days: selected.weekday - 1));
  final target = selected.weekday == DateTime.monday
      ? monday.add(const Duration(days: 1))
      : monday;
  return '${target.year.toString().padLeft(4, '0')}-'
      '${target.month.toString().padLeft(2, '0')}-'
      '${target.day.toString().padLeft(2, '0')}';
}

AgendaLog _log({
  required String id,
  required String day,
  required String description,
}) => AgendaLog(
  id: id,
  projectId: _projectId,
  projectName: _project.name,
  observedAt: '${day}T06:00:00Z',
  createdAt: '${day}T06:00:00Z',
  updatedAt: '${day}T06:00:00Z',
  revision: 1,
  category: AgendaCategory.inspection,
  description: description,
  location: null,
  notes: null,
);

class _DayFilteringAgenda extends FakeAgendaApplication {
  _DayFilteringAgenda({required super.projects, required super.logs});

  @override
  Future<List<AgendaLog>> listAgenda(AgendaQuery query) async {
    listAgendaCalls += 1;
    lastAgendaQuery = query;
    agendaQueries.add(query);
    return logs
        .where(
          (log) =>
              CseTimeCodec.istanbulDayKey(log.observedAt) ==
                  query.istanbulDay &&
              (query.projectId == null || log.projectId == query.projectId),
        )
        .toList(growable: false);
  }
}

const _project = MobileProject(
  id: _projectId,
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-09-05T06:00:00Z',
  updatedAt: '2026-09-05T06:00:00Z',
  revision: 1,
);
