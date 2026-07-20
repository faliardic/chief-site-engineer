import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

import 'support/synthetic_acceptance_harness.dart';

const cseBackgroundAcceptanceEntrypointMarker =
    'CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint(cseBackgroundAcceptanceEntrypointMarker);
  runApp(
    const SyntheticAcceptanceApp(
      title: 'Issue 207 background acceptance',
      runner: _prepareBackgroundAcceptance,
    ),
  );
}

Future<List<String>> _prepareBackgroundAcceptance() async {
  final result = await AppBootstrap.production().start();
  if (result is! BootstrapSuccess) {
    return const ['bootstrap_failed'];
  }
  final agenda = result.agenda;
  final now = DateTime.now().toUtc();
  final lines = <String>[];
  final cases = <({String reminderId, String eventId, int minutes})>[
    (
      reminderId: '20202020-0015-4015-8015-202020202015',
      eventId: '20202020-1015-4015-8015-202020202015',
      minutes: 15,
    ),
    (
      reminderId: '20202020-0030-4030-8030-202020202030',
      eventId: '20202020-1030-4030-8030-202020202030',
      minutes: 30,
    ),
    (
      reminderId: '20202020-0060-4060-8060-202020202060',
      eventId: '20202020-1060-4060-8060-202020202060',
      minutes: 60,
    ),
  ];
  for (final item in cases) {
    final dueAt = CseTimeCodec.encodeUtc(
      now.add(Duration(minutes: item.minutes)),
    );
    final resolution = await findOrCreateSyntheticReminder(
      agenda: agenda,
      command: CreateReminderCommand(
        id: item.reminderId,
        eventId: item.eventId,
        title: 'Synthetic ${item.minutes} minute acceptance',
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
      throw StateError('synthetic native schedule verification failed');
    }
    final line =
        'minutes=${item.minutes} '
        'record=${resolution.created ? 'created' : 'reused'} '
        'platformId=${detail.notification.platformNotificationId} '
        'dueAt=${reminder.nextAttentionAt}';
    lines.add(line);
    debugPrint('CSE_BACKGROUND_ACCEPTANCE $line');
  }
  await agenda.reconcileNotifications();
  return lines;
}
