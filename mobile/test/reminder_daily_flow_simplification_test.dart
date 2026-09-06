import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _projectBId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaab';
final _now = DateTime.utc(2026, 7, 20, 5);
const _project = MobileProject(
  id: _projectId,
  name: 'Şantiye A',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);
const _projectB = MobileProject(
  id: _projectBId,
  name: 'Şantiye B',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Q02 labelled right-aligned controls and quick sheet at $width px 2x',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final agenda = _TrackingAgenda();
          await _pumpLanding(tester, agenda, size: Size(width, 760), scale: 2);
          final filters = tester.widget<Wrap>(
            find.byKey(const Key('reminder-primary-filters')),
          );
          expect(filters.alignment, WrapAlignment.end);
          for (final name in ['today', 'tomorrow', 'after']) {
            final target = find.byKey(Key('reminder-primary-$name'));
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
            expect(target.hitTestable(), findsOneWidget);
            final data = tester.getSemantics(target).getSemanticsData();
            expect(data.hasAction(SemanticsAction.tap), isTrue);
            expect(
              data.flagsCollection.isSelected,
              name == 'today' ? Tristate.isTrue : Tristate.isFalse,
            );
          }
          for (final label in ['Bugün', 'Yarın', 'Sonrası']) {
            expect(find.text(label), findsOneWidget);
          }
          await _openQuick(tester);
          expect(find.byType(ReminderFormPage), findsNothing);
          expect(find.byType(ReminderQuickCaptureSheet), findsOneWidget);
          expect(find.byType(TextFormField), findsOneWidget);
          expect(find.byKey(const Key('reminder-project')), findsNothing);
          expect(find.text('Aktif proje: Şantiye A'), findsOneWidget);
          for (final key in [
            'quick-capture-today',
            'quick-capture-tomorrow',
            'quick-capture-date',
            'quick-capture-time',
            'quick-capture-save',
            'quick-capture-close',
          ]) {
            final target = find.byKey(Key(key));
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
            expect(
              tester
                  .getSemantics(target)
                  .getSemanticsData()
                  .hasAction(SemanticsAction.tap),
              isTrue,
            );
          }
          // A keyboard-sized inset must leave the content scrollable and usable.
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const Key('quick-capture-save')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('quick-capture-save')).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('Q02 active B dates isolate exact IDs and B to A is read-only', (
    tester,
  ) async {
    final records = [
      for (final projectId in [_projectId, _projectBId])
        for (final day in ['2026-07-20', '2026-07-21', '2026-07-22'])
          _item('$projectId-$day', projectId: projectId, day: day),
      _item('legacy', projectId: null, day: '2026-07-20'),
      _item(
        'B-tomorrow-end',
        projectId: _projectBId,
        at: '2026-07-21T20:59:59Z',
      ),
      _item(
        'B-after-start',
        projectId: _projectBId,
        at: '2026-07-21T21:00:00Z',
      ),
    ];
    final agenda = _TrackingAgenda(reminders: records);
    await _pumpLanding(tester, agenda, projectId: _projectBId);
    expect(find.byKey(Key('reminder-$_projectBId-2026-07-20')), findsOneWidget);
    expect(find.byKey(Key('reminder-$_projectId-2026-07-20')), findsNothing);
    expect(find.byKey(const Key('reminder-legacy')), findsNothing);
    await _tap(tester, 'reminder-primary-tomorrow');
    expect(find.byKey(Key('reminder-$_projectBId-2026-07-21')), findsOneWidget);
    expect(find.byKey(Key('reminder-$_projectId-2026-07-21')), findsNothing);
    await _tap(tester, 'reminder-primary-after');
    expect(find.byKey(Key('reminder-$_projectBId-2026-07-22')), findsOneWidget);
    expect(find.byKey(const Key('reminder-B-after-start')), findsOneWidget);
    expect(find.byKey(const Key('reminder-B-tomorrow-end')), findsNothing);
    expect(find.byKey(Key('reminder-$_projectBId-2026-07-21')), findsNothing);
    await _pumpLanding(tester, agenda, projectId: _projectId);
    expect(find.byKey(Key('reminder-$_projectId-2026-07-22')), findsOneWidget);
    expect(find.byKey(Key('reminder-$_projectBId-2026-07-22')), findsNothing);
    expect(agenda.reminders, orderedEquals(records));
    expect(agenda.createReminderCalls, 0);
    expect(agenda.mutateReminderCalls, 0);
  });

  testWidgets('Q02 late B read cannot overwrite the A project view', (
    tester,
  ) async {
    final agenda = _TrackingAgenda(
      reminders: [
        _item('A', projectId: _projectId, day: '2026-07-20'),
        _item('B', projectId: _projectBId, day: '2026-07-20'),
      ],
    );
    final pending = Completer<ReminderTodayOverview>();
    agenda.overviewResponses.add(pending.future);
    await _pumpLanding(tester, agenda, projectId: _projectBId, settle: false);
    await _pumpLanding(tester, agenda, projectId: _projectId);
    expect(find.byKey(const Key('reminder-A')), findsOneWidget);
    pending.complete(
      ReminderTodayOverview(
        istanbulDay: '2026-07-20',
        overdue: [],
        timedToday: [],
        allDayToday: [agenda.reminders.last],
        inboxCount: 0,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reminder-A')), findsOneWidget);
    expect(find.byKey(const Key('reminder-B')), findsNothing);
    expect(agenda.mutateReminderCalls, 0);
  });

  testWidgets(
    'Q02 no active project blocks creation but keeps legacy history and trash reachable',
    (tester) async {
      final records = [
        _item('legacy-active', projectId: null, day: '2026-07-20'),
        _item('legacy-inbox', projectId: null, status: ReminderStatus.inbox),
        _item(
          'legacy-history',
          projectId: null,
          status: ReminderStatus.completed,
        ),
        _item(
          'legacy-trash',
          projectId: null,
          trashedAt: '2026-07-19T08:00:00Z',
        ),
        _item('bound-A', projectId: _projectId, day: '2026-07-20'),
      ];
      final agenda = _TrackingAgenda(reminders: records);
      await _pumpLanding(tester, agenda, projectId: null);
      expect(
        find.textContaining('üstteki aktif proje alanından'),
        findsOneWidget,
      );
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
      expect(find.byKey(const Key('reminder-legacy-active')), findsNothing);
      await _tap(tester, 'reminder-primary-other');
      await _tap(tester, 'reminder-other-projectless');
      for (final id in [
        'legacy-active',
        'legacy-inbox',
        'legacy-history',
        'legacy-trash',
      ]) {
        await tester.scrollUntilVisible(
          find.byKey(Key('reminder-$id')),
          150,
          scrollable: _listScrollable(),
        );
        expect(find.byKey(Key('reminder-$id')), findsOneWidget);
      }
      expect(find.byKey(const Key('reminder-bound-A')), findsNothing);
      expect(agenda.reminders, orderedEquals(records));
      expect(agenda.createReminderCalls, 0);
      expect(agenda.mutateReminderCalls, 0);
    },
  );

  testWidgets(
    'Q02 Today empty has visible Unutma and capture defaults to date-only today',
    (tester) async {
      final agenda = _TrackingAgenda();
      await _pumpLanding(tester, agenda);
      expect(find.text('Bugün için hatırlatıcın yok.'), findsOneWidget);
      expect(
        find.byKey(const Key('reminder-empty-quick-capture')),
        findsOneWidget,
      );
      await _openQuick(tester);
      await _tap(tester, 'quick-capture-save');
      expect(find.text('Hatırlatıcı metni zorunludur.'), findsOneWidget);
      expect(agenda.createReminderCalls, 0);
      await tester.enterText(
        find.byKey(const Key('quick-capture-text')),
        'Malzemeyi unutma',
      );
      await _tap(tester, 'quick-capture-save');
      final command = agenda.commands.single;
      expect(command.projectId, _projectId);
      expect(command.title, 'Malzemeyi unutma');
      expect(command.captureText, command.title);
      expect(command.allDayLocalDate, '2026-07-20');
      expect(command.customAttentionAt, isNull);
      expect(command.schedule, ReminderScheduleKind.custom);
      expect(find.byType(ReminderQuickCaptureSheet), findsNothing);
      expect(agenda.reminders.single.id, command.id);
      expect(agenda.events, {command.id: command.eventId});
    },
  );

  testWidgets(
    'Q02 quick-capture tomorrow date and optional time use canonical scheduling',
    (tester) async {
      final agenda = _TrackingAgenda();
      await _pumpLanding(tester, agenda);
      await _openQuick(tester);
      await _tap(tester, 'quick-capture-tomorrow');
      expect(find.text('21.07.2026'), findsOneWidget);
      await _tap(tester, 'quick-capture-date');
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('23').last);
      await tester.tap(find.text('OK').last);
      await tester.pumpAndSettle();
      expect(find.text('23.07.2026'), findsOneWidget);
      await _tap(tester, 'quick-capture-time');
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('quick-capture-text')),
        'Saatli kontrol',
      );
      await _tap(tester, 'quick-capture-save');
      expect(agenda.commands.single.allDayLocalDate, isNull);
      expect(agenda.commands.single.customAttentionAt, '2026-07-23T06:00:00Z');
      CseTimeCodec.decodeCanonicalUtc(
        agenda.commands.single.customAttentionAt!,
      );
    },
  );

  testWidgets(
    'Q02 double tap and response-loss retry preserve one record and event',
    (tester) async {
      final agenda = _TrackingAgenda()..loseResponseOnce = true;
      await _pumpLanding(tester, agenda);
      await _openQuick(tester);
      await tester.enterText(
        find.byKey(const Key('quick-capture-text')),
        'Tek kayıt',
      );
      final submit = tester
          .widget<FilledButton>(find.byKey(const Key('quick-capture-save')))
          .onPressed!;
      submit();
      submit();
      await tester.pumpAndSettle();
      expect(agenda.commands, hasLength(1));
      expect(agenda.reminders, hasLength(1));
      expect(agenda.events, hasLength(1));
      expect(find.byKey(const Key('quick-capture-error')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('quick-capture-text')))
            .enabled,
        isFalse,
      );
      await _tap(tester, 'quick-capture-save');
      expect(agenda.commands, hasLength(2));
      expect(identical(agenda.commands.first, agenda.commands.last), isTrue);
      expect(agenda.commands.last.id, agenda.commands.first.id);
      expect(agenda.commands.last.eventId, agenda.commands.first.eventId);
      expect(agenda.reminders, hasLength(1));
      expect(agenda.events, hasLength(1));
      expect(find.byType(ReminderQuickCaptureSheet), findsNothing);
    },
  );

  testWidgets(
    'Q02 closing quick sheet preserves tomorrow view and scroll without writes',
    (tester) async {
      final agenda = _TrackingAgenda(
        reminders: [
          for (var i = 0; i < 25; i++) _item('item-$i', day: '2026-07-21'),
        ],
      );
      await _pumpLanding(tester, agenda);
      await _tap(tester, 'reminder-primary-tomorrow');
      final open = tester
          .widget<OutlinedButton>(find.byKey(const Key('quick-inbox-reminder')))
          .onPressed!;
      await tester.drag(
        find.byKey(const Key('reminder-list')),
        const Offset(0, -650),
      );
      await tester.pumpAndSettle();
      final before = tester
          .state<ScrollableState>(_listScrollable())
          .position
          .pixels;
      expect(before, greaterThan(0));
      open();
      await tester.pumpAndSettle();
      await _tap(tester, 'quick-capture-close');
      expect(
        tester.state<ScrollableState>(_listScrollable()).position.pixels,
        closeTo(before, 0.1),
      );
      expect(agenda.lastReminderGroup, ReminderViewGroup.tomorrow);
      expect(agenda.commands, isEmpty);
      expect(agenda.mutateReminderCalls, 0);
    },
  );

  testWidgets(
    'Q02 main new form locks captured B even when parent switches to A',
    (tester) async {
      final active = ValueNotifier<String?>(_projectBId);
      addTearDown(active.dispose);
      final agenda = _TrackingAgenda();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String?>(
              valueListenable: active,
              builder: (_, id, _) =>
                  RemindersPage(agenda: agenda, preferredProjectId: id),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, 'new-reminder');
      expect(find.byType(ReminderFormPage), findsOneWidget);
      expect(find.byKey(const Key('reminder-project')), findsNothing);
      expect(find.text('Aktif proje: Şantiye B'), findsOneWidget);
      active.value = _projectId;
      await tester.pumpAndSettle();
      expect(find.text('Aktif proje: Şantiye B'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'B taslağı',
      );
      await _tap(tester, 'submit-reminder');
      expect(agenda.commands.single.projectId, _projectBId);
      expect(find.byType(ReminderFormPage), findsNothing);
    },
  );

  for (final failure in ['missing', 'archived', 'read']) {
    testWidgets(
      'Q02 locked form $failure validation cannot fall back to projectless',
      (tester) async {
        final agenda = _TrackingAgenda();
        await _pumpLanding(tester, agenda);
        await _tap(tester, 'new-reminder');
        if (failure == 'missing') agenda.projects = const [_projectB];
        if (failure == 'archived') {
          agenda.projects = [
            MobileProject(
              id: _projectId,
              name: 'Şantiye A',
              createdAt: _project.createdAt,
              updatedAt: _project.updatedAt,
              revision: 2,
              archivedAt: '2026-07-20T08:00:00Z',
            ),
          ];
        }
        if (failure == 'read') agenda.projectReadFailure = true;
        await tester.enterText(
          find.byKey(const Key('reminder-title')),
          'Kaydedilmemeli',
        );
        await _tap(tester, 'submit-reminder');
        expect(agenda.commands, isEmpty);
        expect(find.byKey(const Key('reminder-form-error')), findsOneWidget);
        expect(find.byKey(const Key('reminder-project')), findsNothing);
      },
    );
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openQuick(WidgetTester tester) =>
    withClock(Clock.fixed(_now), () async {
      await _tap(tester, 'quick-inbox-reminder');
    });

Finder _listScrollable() => find
    .descendant(
      of: find.byKey(const Key('reminder-list')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _pumpLanding(
  WidgetTester tester,
  _TrackingAgenda agenda, {
  String? projectId = _projectId,
  Size size = const Size(390, 844),
  double scale = 1,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: RemindersPage(agenda: agenda, preferredProjectId: projectId),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

class _TrackingAgenda extends FakeAgendaApplication {
  _TrackingAgenda({super.reminders = const []})
    : super(projects: const [_project, _projectB], asOfUtc: _now);
  final commands = <CreateReminderCommand>[];
  final events = <String, String>{};
  final overviewResponses = <Future<ReminderTodayOverview>>[];
  bool loseResponseOnce = false;
  bool projectReadFailure = false;

  @override
  Future<List<MobileProject>> listProjects() async {
    if (projectReadFailure) throw StateError('project read failed');
    return super.listProjects();
  }

  @override
  Future<ReminderTodayOverview> getReminderTodayOverview() {
    if (overviewResponses.isNotEmpty) return overviewResponses.removeAt(0);
    return super.getReminderTodayOverview();
  }

  @override
  Future<MobileReminder> createReminder(CreateReminderCommand command) async {
    commands.add(command);
    final existing = reminders.where((r) => r.id == command.id);
    if (existing.isNotEmpty) {
      expect(events[command.id], command.eventId);
      return existing.single;
    }
    final result = await super.createReminder(command);
    events[result.id] = command.eventId;
    if (loseResponseOnce) {
      loseResponseOnce = false;
      throw StateError('response lost after persistence');
    }
    return result;
  }
}

MobileReminder _item(
  String id, {
  String? projectId = _projectId,
  String? day,
  String? at,
  ReminderStatus status = ReminderStatus.active,
  String? trashedAt,
}) => MobileReminder(
  id: id,
  projectId: projectId,
  projectName: projectId == _projectId ? 'Şantiye A' : 'Şantiye B',
  sourceLogId: null,
  title: id,
  kind: ReminderKind.action,
  status: status,
  nextAttentionAt: at,
  allDayLocalDate: day,
  trashedAt: trashedAt,
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);
