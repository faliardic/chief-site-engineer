import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'synthetic debug reminders persist as verified native schedules',
    (tester) async {
      final result = await AppBootstrap.production().start();
      expect(result, isA<BootstrapSuccess>());
      final agenda = (result as BootstrapSuccess).agenda;
      final now = DateTime.now().toUtc();
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
        final reminder = await agenda.createReminder(
          CreateReminderCommand(
            id: item.reminderId,
            eventId: item.eventId,
            title: 'Synthetic ${item.minutes} minute acceptance',
            kind: ReminderKind.action,
            schedule: ReminderScheduleKind.custom,
            customAttentionAt: dueAt,
          ),
        );
        final detail = await agenda.getReminderLifecycleDetail(reminder.id);
        expect(detail.notification.syncState, NotificationSyncState.scheduled);
        expect(detail.notification.safeErrorCode, isNull);
        debugPrint(
          'CSE_BACKGROUND_ACCEPTANCE '
          'minutes=${item.minutes} '
          'platformId=${detail.notification.platformNotificationId} '
          'dueAt=$dueAt',
        );
      }

      await agenda.reconcileNotifications();
      for (final item in cases) {
        final diagnostic = await (agenda as ReminderDeliveryApplication)
            .getReminderDeliveryDiagnostic(item.reminderId);
        expect(diagnostic.nativeSchedulePresent, isTrue);
        expect(diagnostic.safeErrorCode, isNull);
      }
    },
  );
}
