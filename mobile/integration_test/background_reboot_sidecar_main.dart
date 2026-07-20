import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final result = await AppBootstrap.production().start();
  if (result is! BootstrapSuccess) {
    runApp(const _RebootApp(line: 'bootstrap_failed'));
    return;
  }
  final agenda = result.agenda;
  final dueAt = CseTimeCodec.encodeUtc(
    DateTime.now().toUtc().add(const Duration(minutes: 3)),
  );
  final reminder = await agenda.createReminder(
    CreateReminderCommand(
      id: '20202020-0003-4003-8003-202020202003',
      eventId: '20202020-1003-4003-8003-202020202003',
      title: 'Synthetic reboot and Doze acceptance',
      kind: ReminderKind.action,
      schedule: ReminderScheduleKind.custom,
      customAttentionAt: dueAt,
    ),
  );
  final detail = await agenda.getReminderLifecycleDetail(reminder.id);
  final diagnostic = await (agenda as ReminderDeliveryApplication)
      .getReminderDeliveryDiagnostic(reminder.id);
  if (detail.notification.syncState != NotificationSyncState.scheduled ||
      !diagnostic.nativeSchedulePresent) {
    throw StateError('reboot native schedule verification failed');
  }
  final line =
      'platformId=${detail.notification.platformNotificationId} dueAt=$dueAt';
  debugPrint('CSE_REBOOT_ACCEPTANCE $line');
  runApp(_RebootApp(line: line));
}

class _RebootApp extends StatelessWidget {
  const _RebootApp({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Issue 202 reboot acceptance')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(line),
        ),
      ),
    );
  }
}
