import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectId = '11111111-1111-4111-8111-111111111111';
const _logId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _reminderId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';

void main() {
  testWidgets('Agenda retry preserves query context and blocks duplicates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    final agenda = _ScriptedAgenda(
      projects: const [_project],
      logs: const [_log],
    );
    await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: agenda)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('next-day')));
    await tester.pumpAndSettle();
    final search = find.byKey(const Key('agenda-literal-search'));
    await tester.enterText(search, 'korunacak arama');
    tester.widget<TextField>(search).onSubmitted!('korunacak arama');
    await tester.pumpAndSettle();
    await _openAgendaFilters(tester);
    await tester.tap(find.text('Arşivlenenler'));
    await _selectDropdown(
      tester,
      const Key('agenda-sort-order'),
      'En eski üstte',
    );
    await _selectDropdown(
      tester,
      const Key('agenda-project-filter'),
      _project.name,
    );
    await _selectDropdown(
      tester,
      const Key('agenda-category-filter'),
      AgendaCategory.inspection.label,
    );
    await tester.ensureVisible(find.byKey(const Key('agenda-filter-apply')));
    await tester.tap(find.byKey(const Key('agenda-filter-apply')));
    await tester.pumpAndSettle();

    final expected = agenda.lastAgendaQuery!;
    agenda.agendaFailure = StateError('read failure');
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();

    _expectRetryAction(tester, const Key('agenda-read-error-retry'));
    expect(
      find.text('Ajanda kayıtları güvenli biçimde okunamadı.'),
      findsOneWidget,
    );
    expect(find.text('Bu günde Ajanda kaydı yok.'), findsNothing);
    _expectAgendaQuery(agenda.lastAgendaQuery!, expected);

    final failedCalls = agenda.listAgendaCalls;
    final failedRetry = tester
        .widget<FilledButton>(find.byKey(const Key('agenda-read-error-retry')))
        .onPressed!;
    failedRetry();
    failedRetry();
    await tester.pumpAndSettle();
    expect(agenda.listAgendaCalls, failedCalls + 1);
    _expectRetryAction(tester, const Key('agenda-read-error-retry'));
    _expectAgendaQuery(agenda.lastAgendaQuery!, expected);

    agenda.agendaFailure = null;
    final gate = Completer<List<AgendaLog>>();
    agenda.agendaGate = gate;
    final successfulCalls = agenda.listAgendaCalls;
    final successfulRetry = tester
        .widget<FilledButton>(find.byKey(const Key('agenda-read-error-retry')))
        .onPressed!;
    successfulRetry();
    successfulRetry();
    await tester.pump();
    expect(agenda.listAgendaCalls, successfulCalls + 1);
    expect(find.byKey(const Key('agenda-read-error-retry')), findsNothing);
    gate.complete(const [_log]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agenda-log-$_logId')), findsOneWidget);
    expect(find.byKey(const Key('agenda-read-error-retry')), findsNothing);
    _expectAgendaQuery(agenda.lastAgendaQuery!, expected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reminder retry preserves Other group and blocks duplicates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    final agenda = _ScriptedReminderAgenda(reminders: const [_trashedReminder]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: agenda)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reminder-primary-other')));
    await tester.pumpAndSettle();
    final trash = find.byKey(const Key('reminder-other-trash'));
    for (var attempt = 0; attempt < 5 && trash.evaluate().isEmpty; attempt++) {
      await tester.drag(
        find.byKey(const Key('reminder-other-menu')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(trash);
    await tester.pumpAndSettle();
    expect(agenda.lastReminderGroup, ReminderViewGroup.trash);
    expect(find.text('Geri Dönüşüm Kutusu'), findsOneWidget);

    agenda.reminderFailure = StateError('read failure');
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();

    _expectRetryAction(tester, const Key('reminder-read-error-retry'));
    expect(
      find.text('Hatırlatıcılar güvenli biçimde okunamadı.'),
      findsOneWidget,
    );
    expect(find.text('Geri Dönüşüm Kutusu boş.'), findsNothing);
    expect(find.text('Geri Dönüşüm Kutusu'), findsOneWidget);

    final failedCalls = agenda.listReminderCalls;
    final failedRetry = tester
        .widget<FilledButton>(
          find.byKey(const Key('reminder-read-error-retry')),
        )
        .onPressed!;
    failedRetry();
    failedRetry();
    await tester.pumpAndSettle();
    expect(agenda.listReminderCalls, failedCalls + 1);
    _expectRetryAction(tester, const Key('reminder-read-error-retry'));
    expect(agenda.lastReminderGroup, ReminderViewGroup.trash);

    agenda.reminderFailure = null;
    final gate = Completer<List<MobileReminder>>();
    agenda.reminderGate = gate;
    final successfulCalls = agenda.listReminderCalls;
    final successfulRetry = tester
        .widget<FilledButton>(
          find.byKey(const Key('reminder-read-error-retry')),
        )
        .onPressed!;
    successfulRetry();
    successfulRetry();
    await tester.pump();
    expect(agenda.listReminderCalls, successfulCalls + 1);
    expect(find.byKey(const Key('reminder-read-error-retry')), findsNothing);
    gate.complete(const [_trashedReminder]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-$_reminderId')), findsOneWidget);
    expect(find.text('Geri Dönüşüm Kutusu'), findsOneWidget);
    expect(agenda.lastReminderGroup, ReminderViewGroup.trash);
    expect(find.byKey(const Key('reminder-read-error-retry')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial read failures expose retry instead of empty state', (
    tester,
  ) async {
    final agenda = _ScriptedAgenda()..agendaFailure = StateError('agenda read');
    await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: agenda)));
    await tester.pumpAndSettle();
    _expectRetryAction(tester, const Key('agenda-read-error-retry'));
    expect(find.text('Bu günde Ajanda kaydı yok.'), findsNothing);

    final reminders = _ScriptedReminderAgenda()
      ..todayFailure = StateError('reminder read');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: reminders)),
      ),
    );
    await tester.pumpAndSettle();
    _expectRetryAction(tester, const Key('reminder-read-error-retry'));
    expect(find.byKey(const Key('reminder-today-empty')), findsNothing);
  });

  testWidgets('operation errors do not expose generic read retry', (
    tester,
  ) async {
    final agenda = _AgendaProjectFailure();
    await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: agenda)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-agenda-project')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('agenda-project-name')),
      'Başarısız proje',
    );
    await tester.tap(find.byKey(const Key('save-agenda-project')));
    await tester.pumpAndSettle();
    expect(find.text('Proje oluşturulamadı.'), findsOneWidget);
    expect(find.byKey(const Key('agenda-read-error-retry')), findsNothing);

    final reminders = FakeAgendaApplication(reminders: const [_activeReminder])
      ..mutateReminderFailure = StateError('mutation failure');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: reminders)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminder-tomorrow-$_reminderId')));
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcı yarına ertelenemedi.'), findsOneWidget);
    expect(find.byKey(const Key('reminder-read-error-retry')), findsNothing);
  });

  testWidgets('empty list states do not expose read retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AgendaPage(agenda: FakeAgendaApplication())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bu günde Ajanda kaydı yok.'), findsOneWidget);
    expect(find.byKey(const Key('agenda-read-error-retry')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: FakeAgendaApplication())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reminder-today-empty')), findsOneWidget);
    expect(find.byKey(const Key('reminder-read-error-retry')), findsNothing);
  });
}

void _expectRetryAction(WidgetTester tester, Key key) {
  final action = find.byKey(key);
  expect(action, findsOneWidget);
  expect(tester.widget(action), isA<FilledButton>());
  final size = tester.getSize(action);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
  final semantics = find
      .ancestor(
        of: action,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Tekrar dene',
        ),
      )
      .first;
  final properties = tester.widget<Semantics>(semantics).properties;
  expect(tester.getSize(semantics), size);
  expect(properties.button, isTrue);
  expect(properties.enabled, isTrue);
  expect(properties.onTap, isNotNull);
}

void _expectAgendaQuery(AgendaQuery actual, AgendaQuery expected) {
  expect(actual.istanbulDay, expected.istanbulDay);
  expect(actual.literalSearch, expected.literalSearch);
  expect(actual.archiveFilter, expected.archiveFilter);
  expect(actual.sortOrder, expected.sortOrder);
  expect(actual.projectId, expected.projectId);
  expect(actual.category, expected.category);
}

Future<void> _openAgendaFilters(WidgetTester tester) async {
  final action = find.byKey(const Key('agenda-filter-action'));
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('agenda-filter-sheet')), findsOneWidget);
}

Future<void> _selectDropdown(WidgetTester tester, Key key, String label) async {
  final field = find.byKey(key);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

class _ScriptedAgenda extends FakeAgendaApplication {
  _ScriptedAgenda({super.projects, super.logs});

  Object? agendaFailure;
  Completer<List<AgendaLog>>? agendaGate;

  @override
  Future<List<AgendaLog>> listAgenda(AgendaQuery query) async {
    listAgendaCalls += 1;
    lastAgendaQuery = query;
    agendaQueries.add(query);
    final gate = agendaGate;
    if (gate != null) {
      agendaGate = null;
      return gate.future;
    }
    if (agendaFailure case final failure?) throw failure;
    return List.unmodifiable(logs);
  }
}

class _ScriptedReminderAgenda extends FakeAgendaApplication {
  _ScriptedReminderAgenda({super.reminders});

  int listReminderCalls = 0;
  Object? reminderFailure;
  Object? todayFailure;
  Completer<List<MobileReminder>>? reminderGate;

  @override
  Future<ReminderTodayOverview> getReminderTodayOverview() async {
    todayOverviewCalls += 1;
    if (todayFailure case final failure?) throw failure;
    return const ReminderTodayOverview(
      istanbulDay: '2026-07-20',
      overdue: [],
      timedToday: [],
      allDayToday: [],
      inboxCount: 0,
    );
  }

  @override
  Future<List<MobileReminder>> listReminders(ReminderViewGroup group) async {
    listReminderCalls += 1;
    lastReminderGroup = group;
    final gate = reminderGate;
    if (gate != null) {
      reminderGate = null;
      return gate.future;
    }
    if (reminderFailure case final failure?) throw failure;
    return List.unmodifiable(reminders);
  }
}

class _AgendaProjectFailure extends FakeAgendaApplication {
  @override
  Future<MobileProject> createProject(CreateProjectCommand command) async {
    throw StateError('project create failure');
  }
}

const _project = MobileProject(
  id: _projectId,
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);

const _log = AgendaLog(
  id: _logId,
  projectId: _projectId,
  projectName: 'Kuzey Şantiyesi',
  observedAt: '2026-07-19T07:30:00Z',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  category: AgendaCategory.inspection,
  description: 'Korunacak Ajanda kaydı',
  location: null,
  notes: null,
  revision: 1,
);

const _activeReminder = MobileReminder(
  id: _reminderId,
  projectId: null,
  projectName: null,
  sourceLogId: null,
  captureText: 'Kontrolü hatırla',
  title: 'Kontrolü hatırla',
  kind: ReminderKind.action,
  status: ReminderStatus.active,
  nextAttentionAt: '2026-07-20T06:00:00Z',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);

const _trashedReminder = MobileReminder(
  id: _reminderId,
  projectId: null,
  projectName: null,
  sourceLogId: null,
  captureText: 'Silinen hatırlatıcı',
  title: 'Silinen hatırlatıcı',
  kind: ReminderKind.action,
  status: ReminderStatus.active,
  nextAttentionAt: null,
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  trashedAt: '2026-07-20T08:00:00Z',
  revision: 1,
);
