import 'dart:ui' show SemanticsAction, Tristate;

import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectA = MobileProject(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Kuzey',
  createdAt: '2026-09-01T08:00:00Z',
  updatedAt: '2026-09-01T08:00:00Z',
  revision: 1,
);
const _projectB = MobileProject(
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  name: 'Güney',
  createdAt: '2026-09-01T08:00:00Z',
  updatedAt: '2026-09-01T08:00:00Z',
  revision: 1,
);

Finder _key(String value) => find.byKey(Key(value));

void main() {
  setUpAll(CseTimeCodec.initialize);

  testWidgets('>=336 usable width keeps direct 48x48 day targets', (
    tester,
  ) async {
    final agenda = _FilteringAgenda(projects: const [_projectA]);
    await _pumpAgenda(tester, agenda, size: const Size(520, 900));
    await _selectDate(tester, DateTime(2026, 9, 9));
    await _selectMode(tester, month: true);

    final day = _key('agenda-calendar-day-2026-09-09');
    expect(day, findsOneWidget);
    expect(tester.getSize(day).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(day).height, greaterThanOrEqualTo(48));
    expect(day.hitTestable(), findsOneWidget);
    final semantics = tester
        .getSemantics(
          find
              .ancestor(
                of: day,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Semantics &&
                      widget.properties.label == '2026-09-09',
                ),
              )
              .first,
        )
        .getSemanticsData();
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    expect(
      find.descendant(
        of: _key('agenda-calendar-days'),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
    expect(_key('agenda-compact-day-selector'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '<336 width supports direct day taps and primary 48x48 selector',
    (tester) async {
      final agenda = _FilteringAgenda(
        projects: const [_projectA],
        logs: [
          _log('monday', '2026-09-07', _projectA),
          _log('tuesday', '2026-09-08', _projectA),
        ],
      );
      await _pumpAgenda(
        tester,
        agenda,
        size: const Size(320, 900),
        textScale: 2,
      );
      await _selectDate(tester, DateTime(2026, 9, 9));

      final visualDays = [
        for (var day = 7; day <= 13; day += 1)
          _key('agenda-calendar-day-2026-09-${day.toString().padLeft(2, '0')}'),
      ];
      final visualRects = visualDays.map(tester.getRect).toList();
      final semanticsRects = <Rect>[];
      for (var index = 0; index < visualDays.length; index += 1) {
        final day = visualDays[index];
        final label = '2026-09-${(index + 7).toString().padLeft(2, '0')}';
        expect(day, findsOneWidget);
        expect(tester.getSize(day).width, lessThan(48));
        expect(day.hitTestable(), findsOneWidget);
        expect(
          visualRects.where((rect) => rect.contains(visualRects[index].center)),
          hasLength(1),
        );
        final semanticsFinder = find
            .ancestor(
              of: day,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics && widget.properties.label == label,
              ),
            )
            .first;
        final semantics = tester
            .getSemantics(semanticsFinder)
            .getSemanticsData();
        expect(semantics.flagsCollection.isButton, isTrue);
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
        expect(tester.getRect(semanticsFinder), visualRects[index]);
        semanticsRects.add(tester.getRect(semanticsFinder));
      }
      for (var index = 0; index < visualRects.length - 1; index += 1) {
        expect(visualRects[index].overlaps(visualRects[index + 1]), isFalse);
        expect(
          semanticsRects[index].overlaps(semanticsRects[index + 1]),
          isFalse,
        );
      }

      final monday = visualDays.first;
      final callsBeforeVisualTap = agenda.listAgendaCalls;
      await tester.tap(monday);
      await tester.pumpAndSettle();
      expect(agenda.listAgendaCalls, greaterThan(callsBeforeVisualTap));
      expect(agenda.lastAgendaQuery?.istanbulDay, '2026-09-07');
      expect(find.text('2026-09-07'), findsOneWidget);
      expect(_key('agenda-log-monday'), findsOneWidget);
      expect(_key('agenda-log-tuesday'), findsNothing);

      await tester.tap(visualDays[1]);
      await tester.pumpAndSettle();
      expect(agenda.lastAgendaQuery?.istanbulDay, '2026-09-08');
      expect(find.text('2026-09-08'), findsOneWidget);
      expect(_key('agenda-log-monday'), findsNothing);
      expect(_key('agenda-log-tuesday'), findsOneWidget);

      for (final key in ['previous-day', 'selected-day', 'next-day']) {
        final control = _key(key);
        expect(control, findsOneWidget);
        expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
        expect(control.hitTestable(), findsOneWidget);
      }
      expect(
        tester.getRect(_key('agenda-calendar-days')).left,
        greaterThanOrEqualTo(tester.getRect(_key('agenda-day-list')).left),
      );
      expect(
        tester.getRect(_key('agenda-calendar-days')).right,
        lessThanOrEqualTo(tester.getRect(_key('agenda-day-list')).right),
      );
      expect(
        find.descendant(
          of: _key('agenda-calendar-days'),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      await tester.tap(_key('previous-day'));
      await tester.pumpAndSettle();
      expect(find.text('2026-09-07'), findsOneWidget);
      expect(agenda.lastAgendaQuery?.istanbulDay, '2026-09-07');
      await tester.tap(_key('next-day'));
      await tester.pumpAndSettle();
      expect(find.text('2026-09-08'), findsOneWidget);
      expect(agenda.lastAgendaQuery?.istanbulDay, '2026-09-08');
      await tester.tap(_key('selected-day'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('calendar density is bounded at 1-3 dots and count at 4+', (
    tester,
  ) async {
    final agenda = _FilteringAgenda(
      projects: const [_projectA],
      logs: [
        _log('one', '2026-09-07', _projectA),
        for (var index = 0; index < 3; index++)
          _log('three-$index', '2026-09-08', _projectA),
        for (var index = 0; index < 100; index++)
          _log('hundred-$index', '2026-09-09', _projectA),
      ],
    );
    await _pumpAgenda(tester, agenda, size: const Size(520, 900));
    await _selectDate(tester, DateTime(2026, 9, 9));
    await _selectMode(tester, month: true);

    expect(_key('agenda-calendar-density-2026-09-07'), findsOneWidget);
    expect(_key('agenda-calendar-density-2026-09-08'), findsOneWidget);
    final crowded = _key('agenda-calendar-density-2026-09-09');
    expect(crowded, findsOneWidget);
    expect(
      find.descendant(of: crowded, matching: find.text('100')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: crowded, matching: find.byType(Container)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('active project switch only reloads context and never mutates', (
    tester,
  ) async {
    final agenda = _FilteringAgenda(
      projects: const [_projectA, _projectB],
      logs: [
        _log('north', _today(), _projectA),
        _log('south', _today(), _projectB),
      ],
    );
    await _pumpAgenda(tester, agenda, size: const Size(520, 900));
    expect(_key('agenda-log-north'), findsOneWidget);
    expect(_key('agenda-log-south'), findsNothing);
    expect(
      agenda.agendaQueries.every((query) => query.projectId == _projectA.id),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AgendaPage(agenda: agenda, activeProjectId: _projectB.id),
      ),
    );
    await tester.pumpAndSettle();
    expect(_key('agenda-log-north'), findsNothing);
    expect(_key('agenda-log-south'), findsOneWidget);
    expect(agenda.lastAgendaQuery?.projectId, _projectB.id);
    expect(agenda.createLogCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty states and tools follow active-project Q03 contract', (
    tester,
  ) async {
    final agenda = _FilteringAgenda(projects: const [_projectA]);
    await _pumpAgenda(tester, agenda, size: const Size(520, 900));
    expect(find.text('Seçili gün için Ajanda kaydı yok.'), findsOneWidget);
    expect(_key('agenda-empty-create'), findsOneWidget);
    expect(_key('create-agenda-project'), findsNothing);
    expect(_key('open-project-location-catalog'), findsNothing);
    await _selectMode(tester, month: true);
    expect(find.text('Bu ay için Ajanda kaydı bulunmuyor.'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: agenda)));
    await tester.pumpAndSettle();
    expect(
      find.text('Ajanda kayıtlarını görmek için üstten aktif proje seçin.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(_key('create-agenda-log')).onPressed,
      isNull,
    );
  });
}

Future<void> _pumpAgenda(
  WidgetTester tester,
  _FilteringAgenda agenda, {
  required Size size,
  double textScale = 1,
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
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: AgendaPage(agenda: agenda, activeProjectId: _projectA.id),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectDate(WidgetTester tester, DateTime date) async {
  await tester.ensureVisible(_key('selected-day'));
  await tester.tap(_key('selected-day'));
  await tester.pumpAndSettle();
  Navigator.of(tester.element(find.byType(DatePickerDialog))).pop(date);
  await tester.pumpAndSettle();
}

Future<void> _selectMode(WidgetTester tester, {required bool month}) async {
  final key = month
      ? 'agenda-calendar-mode-month'
      : 'agenda-calendar-mode-week';
  await tester.ensureVisible(_key(key));
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

String _today() =>
    CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(DateTime.now().toUtc()));

AgendaLog _log(String id, String day, MobileProject project) => AgendaLog(
  id: id,
  projectId: project.id,
  projectName: project.name,
  observedAt: '${day}T06:00:00Z',
  createdAt: '${day}T06:00:00Z',
  updatedAt: '${day}T06:00:00Z',
  revision: 1,
  category: AgendaCategory.inspection,
  description: '$id kaydı',
  location: null,
  notes: null,
);

class _FilteringAgenda extends FakeAgendaApplication {
  _FilteringAgenda({required super.projects, super.logs});

  @override
  Future<List<AgendaLog>> listAgenda(AgendaQuery query) async {
    listAgendaCalls += 1;
    lastAgendaQuery = query;
    agendaQueries.add(query);
    return logs
        .where(
          (log) =>
              log.projectId == query.projectId &&
              CseTimeCodec.istanbulDayKey(log.observedAt) == query.istanbulDay,
        )
        .toList(growable: false);
  }
}
