import 'dart:async';
import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _project = MobileProject(
  id: '11111111-1111-4111-8111-111111111111',
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-09-04T08:00:00Z',
  updatedAt: '2026-09-04T08:00:00Z',
  revision: 1,
);

void main() {
  setUpAll(CseTimeCodec.initialize);

  test('daily forms use PopScope without WillPopScope', () {
    for (final path in [
      'lib/features/reminders/reminder_form_page.dart',
      'lib/features/agenda/log_form_page.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('PopScope<Object?>'));
      expect(source, isNot(contains('WillPopScope')));
    }
  });

  testWidgets('pristine Reminder and Log forms exit without confirmation', (
    tester,
  ) async {
    var harness = await _openForm(
      tester,
      (_) => ReminderFormPage(agenda: FakeAgendaApplication()),
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    _expectNormalCancel(harness, ReminderFormPage);

    harness = await _openForm(
      tester,
      (_) => LogFormPage(
        agenda: FakeAgendaApplication(projects: const [_project]),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    _expectNormalCancel(harness, LogFormPage);
  });

  testWidgets('dirty forms keep exact state or discard with one form pop', (
    tester,
  ) async {
    await _verifyDirtyFlow(
      tester,
      form: (_) => ReminderFormPage(agenda: FakeAgendaApplication()),
      formType: ReminderFormPage,
      fieldKey: const Key('reminder-title'),
      changedText: 'Korunacak hatırlatıcı',
    );
    await _verifyDirtyFlow(
      tester,
      form: (_) => LogFormPage(
        agenda: FakeAgendaApplication(projects: const [_project]),
      ),
      formType: LogFormPage,
      fieldKey: const Key('log-description'),
      changedText: 'Korunacak saha logu',
    );
  });

  testWidgets('kind-only Reminder edit is guarded and preserves exact state', (
    tester,
  ) async {
    final harness = await _openForm(
      tester,
      (_) => ReminderFormPage(agenda: FakeAgendaApplication()),
    );
    final formFinder = find.byType(ReminderFormPage);
    final originalState = tester.state(formFinder);
    final optional = find.byKey(const Key('reminder-optional-details'));
    await tester.scrollUntilVisible(
      optional,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(optional);
    await tester.pumpAndSettle();
    final kindFinder = find.byKey(const Key('reminder-kind'));
    await tester.ensureVisible(kindFinder);

    await tester.tap(kindFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderKind.recheck.label).last);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('unsaved-changes-dialog')), findsOneWidget);
    expect(find.text('Kaydedilmemiş değişiklikler'), findsOneWidget);

    final popScope = tester.widget<PopScope<Object?>>(
      find.descendant(of: formFinder, matching: find.byType(PopScope<Object?>)),
    );
    popScope.onPopInvokedWithResult!(false, null);
    await tester.pump();
    expect(find.byKey(const Key('unsaved-changes-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stay-on-form')));
    await tester.pumpAndSettle();
    expect(tester.state(formFinder), same(originalState));
    expect(
      tester.state<FormFieldState<ReminderKind>>(kindFinder).value,
      ReminderKind.recheck,
    );
    expect(harness.observer.formPops, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('unsaved-changes-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('discard-form')));
    await tester.pumpAndSettle();

    expect(find.byType(ReminderFormPage), findsNothing);
    expect(harness.result, isNull);
    expect(harness.completions, 1);
    expect(harness.observer.formPops, 1);
  });

  testWidgets('submit-in-flight blocks Back and success keeps route results', (
    tester,
  ) async {
    final reminderCompleter = Completer<MobileReminder>();
    final reminderAgenda = FakeAgendaApplication()
      ..createReminderCompleter = reminderCompleter;
    var harness = await _openForm(
      tester,
      (_) => ReminderFormPage(agenda: reminderAgenda),
    );
    await tester.enterText(
      find.byKey(const Key('reminder-title')),
      'Tamamlanan hatırlatıcı',
    );
    await _tapSubmit(tester, const Key('submit-reminder'));

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(ReminderFormPage), findsOneWidget);
    expect(find.byKey(const Key('unsaved-changes-dialog')), findsNothing);
    expect(harness.observer.formPops, 0);

    final reminder = _savedReminder();
    reminderCompleter.complete(reminder);
    await tester.pumpAndSettle();
    expect(harness.result, same(reminder));
    expect(harness.completions, 1);
    expect(harness.observer.formPops, 1);

    final logCompleter = Completer<AgendaLog>();
    final logAgenda = FakeAgendaApplication(projects: const [_project])
      ..createLogCompleter = logCompleter;
    harness = await _openForm(tester, (_) => LogFormPage(agenda: logAgenda));
    await tester.enterText(
      find.byKey(const Key('log-description')),
      'Tamamlanan saha logu',
    );
    await _tapSubmit(tester, const Key('submit-log'));

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(LogFormPage), findsOneWidget);
    expect(find.byKey(const Key('unsaved-changes-dialog')), findsNothing);
    expect(harness.observer.formPops, 0);

    logCompleter.complete(_savedLog());
    await tester.pumpAndSettle();
    expect(harness.result, '2026-09-04');
    expect(harness.completions, 1);
    expect(harness.observer.formPops, 1);
  });

  testWidgets('async project and location initialization stays pristine', (
    tester,
  ) async {
    await _verifyAsyncInitializationIsPristine(tester, reminder: true);
    await _verifyAsyncInitializationIsPristine(tester, reminder: false);
  });

  testWidgets('nested Reminder date dialog consumes Back normally', (
    tester,
  ) async {
    await _openForm(
      tester,
      (_) => ReminderFormPage(agenda: FakeAgendaApplication()),
    );
    await tester.tap(find.byKey(const Key('reminder-today')));
    await tester.pumpAndSettle();
    final reminderDate = find.byKey(const Key('reminder-custom-date'));
    await tester.ensureVisible(reminderDate);
    await tester.tap(reminderDate);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.byType(ReminderFormPage), findsOneWidget);
    expect(find.byKey(const Key('unsaved-changes-dialog')), findsNothing);
  });

  testWidgets('nested Log date dialog consumes Back normally', (tester) async {
    await _openForm(
      tester,
      (_) => LogFormPage(
        agenda: FakeAgendaApplication(projects: const [_project]),
      ),
    );
    final timeDetails = find.byKey(const Key('log-time-details'));
    await tester.ensureVisible(timeDetails);
    await tester.tap(timeDetails);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('log-date')));
    await tester.tap(find.byKey(const Key('log-date')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.byType(LogFormPage), findsOneWidget);
    expect(find.byKey(const Key('unsaved-changes-dialog')), findsNothing);
  });
}

Future<void> _verifyDirtyFlow(
  WidgetTester tester, {
  required WidgetBuilder form,
  required Type formType,
  required Key fieldKey,
  required String changedText,
}) async {
  final harness = await _openForm(tester, form);
  final formFinder = find.byType(formType);
  final originalState = tester.state(formFinder);
  await tester.enterText(find.byKey(fieldKey), changedText);
  await tester.pump();

  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('unsaved-changes-dialog')), findsOneWidget);
  expect(find.text('Kaydedilmemiş değişiklikler'), findsOneWidget);

  final popScope = tester.widget<PopScope<Object?>>(
    find.descendant(of: formFinder, matching: find.byType(PopScope<Object?>)),
  );
  popScope.onPopInvokedWithResult!(false, null);
  await tester.pump();
  expect(find.byKey(const Key('unsaved-changes-dialog')), findsOneWidget);

  await tester.tap(find.byKey(const Key('stay-on-form')));
  await tester.pumpAndSettle();
  expect(tester.state(formFinder), same(originalState));
  expect(
    tester.widget<TextFormField>(find.byKey(fieldKey)).controller!.text,
    changedText,
  );
  expect(harness.observer.formPops, 0);

  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('unsaved-changes-dialog')), findsOneWidget);
  await tester.tap(find.byKey(const Key('discard-form')));
  await tester.pumpAndSettle();

  expect(find.byType(formType), findsNothing);
  expect(harness.result, isNull);
  expect(harness.completions, 1);
  expect(harness.observer.formPops, 1);
}

Future<void> _verifyAsyncInitializationIsPristine(
  WidgetTester tester, {
  required bool reminder,
}) async {
  final projectGate = Completer<void>();
  final locationGate = Completer<List<MobileProjectLocation>>();
  final agenda = FakeAgendaApplication(projects: const [_project])
    ..listProjectsGate = projectGate;
  final locations = _DeferredLocations(locationGate);
  final harness = await _openForm(
    tester,
    reminder
        ? (_) => ReminderFormPage(
            agenda: agenda,
            projectLocations: locations,
            preferredProjectId: _project.id,
          )
        : (_) => LogFormPage(
            agenda: agenda,
            projectLocations: locations,
            initialProjectId: _project.id,
          ),
    settle: false,
  );

  projectGate.complete();
  await tester.pump();
  await tester.pump();
  expect(locations.calls, 1);
  locationGate.complete(const []);
  await tester.pumpAndSettle();

  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('unsaved-changes-dialog')), findsNothing);
  expect(harness.completions, 1);
  expect(harness.observer.formPops, 1);
}

Future<_RouteHarness> _openForm(
  WidgetTester tester,
  WidgetBuilder form, {
  bool settle = true,
}) async {
  final harness = _RouteHarness();
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: [harness.observer],
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const Key('open-form'),
            onPressed: () async {
              harness.result = await Navigator.of(context).push<Object?>(
                MaterialPageRoute<Object?>(
                  settings: const RouteSettings(name: 'guarded-form'),
                  builder: form,
                ),
              );
              harness.completions += 1;
            },
            child: const Text('Formu aç'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open-form')));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return harness;
}

Future<void> _tapSubmit(WidgetTester tester, Key key) async {
  tester.testTextInput.hide();
  await tester.pump();
  final submit = find.byKey(key);
  await tester.scrollUntilVisible(
    submit,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pump();
}

void _expectNormalCancel(_RouteHarness harness, Type formType) {
  expect(find.byType(formType), findsNothing);
  expect(find.byKey(const Key('unsaved-changes-dialog')), findsNothing);
  expect(harness.result, isNull);
  expect(harness.completions, 1);
  expect(harness.observer.formPops, 1);
}

MobileReminder _savedReminder() => const MobileReminder(
  id: '22222222-2222-4222-8222-222222222222',
  projectId: null,
  projectName: null,
  sourceLogId: null,
  captureText: 'Tamamlanan hatırlatıcı',
  title: 'Tamamlanan hatırlatıcı',
  kind: ReminderKind.action,
  status: ReminderStatus.inbox,
  nextAttentionAt: null,
  createdAt: '2026-09-04T08:00:00Z',
  updatedAt: '2026-09-04T08:00:00Z',
  revision: 1,
);

AgendaLog _savedLog() => const AgendaLog(
  id: '33333333-3333-4333-8333-333333333333',
  projectId: '11111111-1111-4111-8111-111111111111',
  projectName: 'Kuzey Şantiyesi',
  observedAt: '2026-09-04T08:00:00Z',
  createdAt: '2026-09-04T08:00:00Z',
  updatedAt: '2026-09-04T08:00:00Z',
  category: AgendaCategory.generalNote,
  description: 'Tamamlanan saha logu',
  location: null,
  notes: null,
  revision: 1,
);

class _RouteHarness {
  final observer = _FormPopObserver();
  Object? result;
  int completions = 0;
}

class _FormPopObserver extends NavigatorObserver {
  int formPops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == 'guarded-form') formPops += 1;
    super.didPop(route, previousRoute);
  }
}

class _DeferredLocations extends Fake implements ProjectLocationApplication {
  _DeferredLocations(this.gate);

  final Completer<List<MobileProjectLocation>> gate;
  int calls = 0;

  @override
  Future<List<MobileProjectLocation>> listProjectLocations(
    ProjectLocationQuery query,
  ) {
    calls += 1;
    return gate.future;
  }
}
