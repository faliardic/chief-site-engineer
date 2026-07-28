import 'dart:io';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/issue252_smoke_acceptance.dart';

const issue252SmokeEntrypointMarker =
    'CSE_ENTRYPOINT_ISSUE252_SMOKE_ACCEPTANCE_V1';
const _runId = String.fromEnvironment('CSE_ISSUE254_RUN_ID');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  debugPrint(issue252SmokeEntrypointMarker);

  testWidgets(
    'Issue 252 synthetic physical smoke is isolated and restart-safe',
    (tester) async {
      final runId = validateIssue252SmokeRunId(_runId);
      final title = issue252SmokeTitle(runId);
      final supportRoot = issue252SmokeSupportRoot(runId);
      final directories = AppDirectories.fromSupportRoot(
        supportRoot,
        AppEnvironment.debug,
      );
      final stateFile = issue252SmokeStateFile(directories);
      final isRestartPhase = await stateFile.exists();

      if (!isRestartPhase && await supportRoot.exists()) {
        fail('Fresh Issue 254 support root is not empty.');
      }

      final result = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactory,
        clock: () => DateTime.now().toUtc(),
      ).start();
      expect(result, isA<BootstrapSuccess>());
      final success = result as BootstrapSuccess;
      final agenda = success.agenda;

      await tester.pumpWidget(CseApp(bootstrap: Future.value(success)));
      await tester.pumpAndSettle();
      expect(find.byType(BootstrapFailureScreen), findsNothing);

      if (isRestartPhase) {
        await _runRestartPhase(
          tester: tester,
          agenda: agenda,
          stateFile: stateFile,
          runId: runId,
        );
      } else {
        await _runFirstPhase(
          tester: tester,
          agenda: agenda,
          stateFile: stateFile,
          runId: runId,
          title: title,
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _runFirstPhase({
  required WidgetTester tester,
  required AgendaApplication agenda,
  required File stateFile,
  required String runId,
  required String title,
}) async {
  await _openReminders(tester);
  _expectPrimaryFilters();

  await tester.tap(find.byKey(const Key('quick-reminder')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('reminder-title')), findsOneWidget);
  await tester.enterText(find.byKey(const Key('reminder-title')), title);

  final schedule = find.byKey(const Key('reminder-schedule'));
  await tester.ensureVisible(schedule);
  await tester.tap(schedule);
  await tester.pumpAndSettle();
  expect(find.text('2 saat'), findsOneWidget);
  expect(find.text('3 saat'), findsOneWidget);
  await tester.tap(find.text('3 saat'));
  await tester.pumpAndSettle();

  await tester.tap(schedule);
  await tester.pumpAndSettle();
  expect(find.text('2 saat'), findsOneWidget);
  expect(find.text('3 saat'), findsOneWidget);
  await tester.tap(find.text('2 saat'));
  await tester.pumpAndSettle();

  final createStartedAt = DateTime.now().toUtc();
  final submit = find.byKey(const Key('submit-reminder'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
  if (find
      .byKey(const Key('reminder-delivery-warning'))
      .evaluate()
      .isNotEmpty) {
    await tester.tap(find.text('Anladım'));
    await tester.pumpAndSettle();
  }
  final createFinishedAt = DateTime.now().toUtc();

  var reminder = await _findSyntheticReminder(agenda, title);
  expect(reminder.status, ReminderStatus.active);
  expect(reminder.nextAttentionAt, isNotNull);
  expect(
    isDueWithinOperationWindow(
      dueAt: reminder.nextAttentionAt!,
      operationStartedAt: createStartedAt,
      operationFinishedAt: createFinishedAt,
      offset: const Duration(hours: 2),
    ),
    isTrue,
  );

  await _openSyntheticReminder(tester, reminder);
  _expectDetailMutationLabels();

  await _tapDetailAction(tester, const Key('snooze-tomorrow'));
  reminder = await agenda.getReminderDetail(reminder.id);
  expect(reminder.status, ReminderStatus.active);
  expect(reminder.nextAttentionAt, isNotNull);

  final twoHourStartedAt = DateTime.now().toUtc();
  await _tapDetailAction(tester, const Key('snooze-2h'));
  final twoHourFinishedAt = DateTime.now().toUtc();
  reminder = await agenda.getReminderDetail(reminder.id);
  expect(
    isDueWithinOperationWindow(
      dueAt: reminder.nextAttentionAt!,
      operationStartedAt: twoHourStartedAt,
      operationFinishedAt: twoHourFinishedAt,
      offset: const Duration(hours: 2),
    ),
    isTrue,
  );

  final threeHourStartedAt = DateTime.now().toUtc();
  await _tapDetailAction(tester, const Key('snooze-3h'));
  final threeHourFinishedAt = DateTime.now().toUtc();
  reminder = await agenda.getReminderDetail(reminder.id);
  expect(reminder.status, ReminderStatus.active);
  expect(
    isDueWithinOperationWindow(
      dueAt: reminder.nextAttentionAt!,
      operationStartedAt: threeHourStartedAt,
      operationFinishedAt: threeHourFinishedAt,
      offset: const Duration(hours: 3),
    ),
    isTrue,
  );

  await writeIssue252SmokeState(
    stateFile,
    Issue252SmokeState(
      runId: runId,
      reminderId: reminder.id,
      title: title,
      finalDueAt: reminder.nextAttentionAt!,
    ),
  );
  debugPrint('CSE_ISSUE254_PHASE1_PASS run=$runId reminder=${reminder.id}');
}

Future<void> _runRestartPhase({
  required WidgetTester tester,
  required AgendaApplication agenda,
  required File stateFile,
  required String runId,
}) async {
  final state = await readIssue252SmokeState(stateFile, expectedRunId: runId);
  final reminder = await agenda.getReminderDetail(state.reminderId);
  expect(reminder.title, state.title);
  expect(reminder.status, ReminderStatus.active);
  expect(reminder.nextAttentionAt, state.finalDueAt);
  expect(reminder.trashedAt, isNull);

  await _openReminders(tester);
  _expectPrimaryFilters();
  await _openSyntheticReminder(tester, reminder);
  _expectDetailMutationLabels();

  await _tapDetailAction(tester, const Key('trash-reminder'));
  expect(find.byKey(const Key('confirm-trash-reminder')), findsOneWidget);
  await tester.tap(find.byKey(const Key('confirm-trash-reminder')));
  await tester.pumpAndSettle();

  final trashed = await agenda.getReminderDetail(state.reminderId);
  expect(trashed.title, state.title);
  expect(trashed.trashedAt, isNotNull);
  final trash = await agenda.listReminders(ReminderViewGroup.trash);
  expect(
    requireUniqueSyntheticReminder(trash, title: state.title).id,
    state.reminderId,
  );
  debugPrint(
    'CSE_ISSUE254_PHASE2_PASS run=$runId reminder=${state.reminderId}',
  );
}

Future<void> _openReminders(WidgetTester tester) async {
  final navigationLabel = find.text('Hatırlatıcı');
  expect(navigationLabel, findsOneWidget);
  await tester.tap(navigationLabel);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('reminder-list')), findsOneWidget);
}

void _expectPrimaryFilters() {
  expect(
    find.descendant(
      of: find.byKey(const Key('reminder-primary-today')),
      matching: find.text('Bugün'),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const Key('reminder-primary-tomorrow')),
      matching: find.text('Yarın'),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const Key('reminder-primary-other')),
      matching: find.text('Diğer'),
    ),
    findsOneWidget,
  );
}

void _expectDetailMutationLabels() {
  for (final item in const [
    (key: Key('snooze-tomorrow'), label: 'Yarına ertele'),
    (key: Key('snooze-2h'), label: '2 saat ertele'),
    (key: Key('snooze-3h'), label: '3 saat ertele'),
  ]) {
    expect(
      find.descendant(
        of: find.byKey(item.key),
        matching: find.text(item.label),
      ),
      findsOneWidget,
    );
  }
}

Future<void> _openSyntheticReminder(
  WidgetTester tester,
  MobileReminder reminder,
) async {
  final dueAt = CseTimeCodec.toIstanbul(reminder.nextAttentionAt!);
  final now = CseTimeCodec.toIstanbul(
    CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
  );
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
  if (dueDay == today) {
    await tester.tap(find.byKey(const Key('reminder-primary-today')));
  } else if (dueDay == today.add(const Duration(days: 1))) {
    await tester.tap(find.byKey(const Key('reminder-primary-tomorrow')));
  } else {
    await tester.tap(find.byKey(const Key('reminder-primary-other')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminder-other-upcoming')));
  }
  await tester.pumpAndSettle();

  final card = find.byKey(Key('reminder-${reminder.id}'));
  expect(card, findsOneWidget);
  await tester.ensureVisible(card);
  await tester.tap(card);
  await tester.pumpAndSettle();
  expect(find.text(reminder.title), findsWidgets);
}

Future<void> _tapDetailAction(WidgetTester tester, Key key) async {
  final action = find.byKey(key);
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<MobileReminder> _findSyntheticReminder(
  AgendaApplication agenda,
  String title,
) async {
  final reminders = <String, MobileReminder>{};
  for (final group in const [
    ReminderViewGroup.today,
    ReminderViewGroup.tomorrow,
    ReminderViewGroup.upcoming,
  ]) {
    for (final reminder in await agenda.listReminders(group)) {
      reminders[reminder.id] = reminder;
    }
  }
  return requireUniqueSyntheticReminder(reminders.values, title: title);
}
