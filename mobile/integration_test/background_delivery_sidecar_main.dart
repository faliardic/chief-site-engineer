import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final result = await AppBootstrap.production().start();
  if (result is! BootstrapSuccess) {
    runApp(const _AcceptanceApp(lines: ['bootstrap_failed']));
    return;
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
    MobileReminder reminder;
    try {
      reminder = await agenda.getReminderDetail(item.reminderId);
    } on AgendaValidationFailure {
      final dueAt = CseTimeCodec.encodeUtc(
        now.add(Duration(minutes: item.minutes)),
      );
      reminder = await agenda.createReminder(
        CreateReminderCommand(
          id: item.reminderId,
          eventId: item.eventId,
          title: 'Synthetic ${item.minutes} minute acceptance',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: dueAt,
        ),
      );
    }
    final detail = await agenda.getReminderLifecycleDetail(reminder.id);
    final diagnostic = await (agenda as ReminderDeliveryApplication)
        .getReminderDeliveryDiagnostic(reminder.id);
    if (detail.notification.syncState != NotificationSyncState.scheduled ||
        !diagnostic.nativeSchedulePresent) {
      throw StateError('synthetic native schedule verification failed');
    }
    final line =
        'minutes=${item.minutes} '
        'platformId=${detail.notification.platformNotificationId} '
        'dueAt=${reminder.nextAttentionAt}';
    lines.add(line);
    debugPrint('CSE_BACKGROUND_ACCEPTANCE $line');
  }
  await agenda.reconcileNotifications();
  runApp(_AcceptanceApp(lines: lines));
}

class _AcceptanceApp extends StatelessWidget {
  const _AcceptanceApp({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Issue 202 synthetic acceptance')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Native schedules verified. Safe to close the app.'),
            for (final line in lines) SelectableText(line),
          ],
        ),
      ),
    );
  }
}
