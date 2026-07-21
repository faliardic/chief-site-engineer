import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

import 'support/synthetic_acceptance_harness.dart';

const cseRebootAcceptanceEntrypointMarker =
    'CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint(cseRebootAcceptanceEntrypointMarker);
  runApp(
    const SyntheticAcceptanceApp(
      title: 'Issue 207 reboot acceptance',
      runner: _prepareRebootAcceptance,
    ),
  );
}

Future<List<String>> _prepareRebootAcceptance() async {
  final result = await AppBootstrap.production().start();
  if (result is! BootstrapSuccess) {
    return const ['bootstrap_failed'];
  }
  final agenda = result.agenda;
  final dueAt = CseTimeCodec.encodeUtc(
    DateTime.now().toUtc().add(const Duration(minutes: 3)),
  );
  final resolution = await findOrCreateSyntheticReminder(
    agenda: agenda,
    command: CreateReminderCommand(
      id: '20202020-0003-4003-8003-202020202003',
      eventId: '20202020-1003-4003-8003-202020202003',
      title: 'Synthetic reboot and Doze acceptance',
      kind: ReminderKind.action,
      schedule: ReminderScheduleKind.custom,
      customAttentionAt: dueAt,
    ),
  );
  final reminder = resolution.reminder;
  final detail = await agenda.getReminderLifecycleDetail(reminder.id);
  final diagnostic = await (agenda as ReminderDeliveryApplication)
      .getReminderDeliveryDiagnostic(reminder.id);
  if (resolution.created &&
      (detail.notification.syncState != NotificationSyncState.scheduled ||
          !diagnostic.nativeSchedulePresent)) {
    throw StateError('reboot native schedule verification failed');
  }
  final line =
      'record=${resolution.created ? 'created' : 'reused'} '
      'platformId=${detail.notification.platformNotificationId} '
      'dueAt=${reminder.nextAttentionAt}';
  debugPrint('CSE_REBOOT_ACCEPTANCE $line');
  return [line];
}
