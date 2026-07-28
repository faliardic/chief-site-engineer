import 'dart:io';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/issue252_smoke_acceptance.dart';
import '../integration_test/support/synthetic_acceptance_harness.dart';
import 'support/fake_agenda_application.dart';

void main() {
  testWidgets('runner failure replaces splash with privacy-safe fail UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      SyntheticAcceptanceApp(
        title: 'Synthetic test',
        runner: () async => throw StateError('private failure detail'),
      ),
    );
    expect(find.text('acceptance_starting'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('acceptance_failed'), findsOneWidget);
    expect(find.textContaining('private failure detail'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('fixed identity is reused without a second create mutation', () async {
    final existing = _reminder(nextAttentionAt: '2026-07-20T08:15:00Z');
    final agenda = FakeAgendaApplication(reminders: [existing]);

    final resolution = await findOrCreateSyntheticReminder(
      agenda: agenda,
      command: _command(customAttentionAt: '2026-07-21T08:15:00Z'),
    );

    expect(resolution.created, isFalse);
    expect(resolution.reminder, same(existing));
    expect(agenda.createReminderCalls, 0);
  });

  test('missing fixed identity is created once', () async {
    final agenda = _MissingReminderAgenda();

    final resolution = await findOrCreateSyntheticReminder(
      agenda: agenda,
      command: _command(customAttentionAt: '2026-07-21T08:15:00Z'),
    );

    expect(resolution.created, isTrue);
    expect(agenda.createReminderCalls, 1);
  });

  test('Issue 252 run identity and synthetic title are fail-closed', () {
    expect(
      issue252SmokeTitle('20260727153045'),
      'ISSUE252-SMOKE-20260727153045',
    );
    expect(
      () => issue252SmokeTitle('../production'),
      throwsA(isA<FormatException>()),
    );
  });

  test('Issue 252 due windows use operation time instead of prior due', () {
    final started = DateTime.utc(2026, 7, 27, 12);
    final finished = started.add(const Duration(seconds: 2));

    expect(
      isDueWithinOperationWindow(
        dueAt: '2026-07-27T15:00:01.000Z',
        operationStartedAt: started,
        operationFinishedAt: finished,
        offset: const Duration(hours: 3),
      ),
      isTrue,
    );
    expect(
      isDueWithinOperationWindow(
        dueAt: '2026-07-27T17:00:00.000Z',
        operationStartedAt: started,
        operationFinishedAt: finished,
        offset: const Duration(hours: 3),
      ),
      isFalse,
    );
  });

  test('Issue 252 restart state preserves exact synthetic identity', () async {
    final temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_issue254_helper_',
    );
    addTearDown(() async {
      if (await temporaryRoot.exists()) {
        await temporaryRoot.delete(recursive: true);
      }
    });
    final directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    final stateFile = issue252SmokeStateFile(directories);
    const state = Issue252SmokeState(
      runId: '20260727153045',
      reminderId: reminderId,
      title: 'ISSUE252-SMOKE-20260727153045',
      finalDueAt: '2026-07-27T15:00:01.000Z',
    );

    await writeIssue252SmokeState(stateFile, state);
    final restored = await readIssue252SmokeState(
      stateFile,
      expectedRunId: state.runId,
    );

    expect(restored.reminderId, state.reminderId);
    expect(restored.title, state.title);
    expect(restored.finalDueAt, state.finalDueAt);
  });

  test('Issue 252 synthetic reminder lookup rejects ambiguity', () {
    final reminder = _reminder(nextAttentionAt: '2026-07-20T08:15:00Z');
    expect(
      requireUniqueSyntheticReminder([
        reminder,
      ], title: 'Synthetic 15 minute acceptance'),
      same(reminder),
    );
    expect(
      () => requireUniqueSyntheticReminder([
        reminder,
        reminder,
      ], title: 'Synthetic 15 minute acceptance'),
      throwsStateError,
    );
  });
}

const reminderId = '20202020-0015-4015-8015-202020202015';

CreateReminderCommand _command({required String customAttentionAt}) =>
    CreateReminderCommand(
      id: reminderId,
      eventId: '20202020-1015-4015-8015-202020202015',
      title: 'Synthetic 15 minute acceptance',
      kind: ReminderKind.action,
      schedule: ReminderScheduleKind.custom,
      customAttentionAt: customAttentionAt,
    );

MobileReminder _reminder({required String nextAttentionAt}) => MobileReminder(
  id: reminderId,
  projectId: null,
  projectName: null,
  sourceLogId: null,
  captureText: 'Synthetic 15 minute acceptance',
  title: 'Synthetic 15 minute acceptance',
  description: null,
  kind: ReminderKind.action,
  status: ReminderStatus.active,
  location: null,
  relatedPerson: null,
  isImportant: false,
  nextAttentionAt: nextAttentionAt,
  deadlineAt: null,
  conditionText: null,
  outcomeType: null,
  outcomeNote: null,
  createdAt: '2026-07-20T08:00:00Z',
  updatedAt: '2026-07-20T08:00:00Z',
  completedAt: null,
  cancelledAt: null,
  revision: 1,
);

class _MissingReminderAgenda extends FakeAgendaApplication {
  @override
  Future<MobileReminder> getReminderDetail(String reminderId) =>
      throw const AgendaValidationFailure('Hatırlatıcı bulunamadı.');
}
