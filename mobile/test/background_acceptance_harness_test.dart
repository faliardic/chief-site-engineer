import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter_test/flutter_test.dart';

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
