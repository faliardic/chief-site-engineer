import 'dart:io';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android offline agenda reminder and attendance survive restart',
    (tester) async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'cse_mobile_integration_',
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
      final observedAt = CseTimeCodec.encodeUtc(DateTime.now().toUtc());
      final firstNotifications = FlutterReminderNotificationGateway();
      final first = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactory,
        clock: () => DateTime.now().toUtc(),
        notificationGateway: firstNotifications,
      ).start();
      expect(first, isA<BootstrapSuccess>());
      final firstSuccess = first as BootstrapSuccess;
      await firstSuccess.agenda.createProject(
        const CreateProjectCommand(
          id: '11111111-1111-4111-8111-111111111111',
          name: 'Emülatör Şantiyesi',
        ),
      );
      final attendance = firstSuccess.attendance!;
      await attendance.createMember(
        const CreateWorkforceMemberCommand(
          id: '22222222-2222-4222-8222-222222222222',
          projectId: '11111111-1111-4111-8111-111111111111',
          fullName: 'Emülatör Personeli',
          teamName: 'Emülatör Ekibi',
          roleName: 'Saha Ustası',
          personnelCode: 'EMU-01',
        ),
      );
      final futureLocal = CseTimeCodec.toIstanbul(
        CseTimeCodec.encodeUtc(
          DateTime.now().toUtc().add(const Duration(hours: 2)),
        ),
      );
      final attendanceDate =
          '${futureLocal.year.toString().padLeft(4, '0')}-'
          '${futureLocal.month.toString().padLeft(2, '0')}-'
          '${futureLocal.day.toString().padLeft(2, '0')}';
      final attendanceTime =
          '${futureLocal.hour.toString().padLeft(2, '0')}:'
          '${futureLocal.minute.toString().padLeft(2, '0')}';
      await attendance.saveReminderSetting(
        SaveAttendanceReminderSettingCommand(
          projectId: '11111111-1111-4111-8111-111111111111',
          expectedRevision: 0,
          isEnabled: true,
          localTime: attendanceTime,
          selectedWeekdays: {futureLocal.weekday},
        ),
      );
      final attendanceDay = await attendance.ensureDay(
        EnsureAttendanceDayCommand(
          id: '33333333-3333-4333-8333-333333333333',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000010',
          projectId: '11111111-1111-4111-8111-111111111111',
          localDate: attendanceDate,
        ),
      );
      var attendanceDetail = await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: attendanceDay.id,
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000011',
          expectedRevision: attendanceDay.revision,
          values: const [
            AttendanceRosterValue(
              entryId: '44444444-4444-4444-8444-444444444444',
              memberId: '22222222-2222-4222-8222-222222222222',
              result: AttendanceResult.fullDay,
              overtimeMinutes: 30,
              shortNote: 'Android offline Puantaj',
            ),
          ],
        ),
      );
      expect(attendanceDetail.linkedReminder, isNotNull);
      final attendanceReminder = attendanceDetail.linkedReminder!;
      final attendanceNotification = await firstSuccess.agenda
          .getReminderLifecycleDetail(attendanceReminder.id);
      expect(
        attendanceNotification.notification.syncState,
        NotificationSyncState.scheduled,
      );
      final log = await firstSuccess.agenda.createAgendaLog(
        CreateAgendaLogCommand(
          id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000001',
          projectId: '11111111-1111-4111-8111-111111111111',
          observedAt: observedAt,
          category: AgendaCategory.inspection,
          description: 'Android offline Ajanda kaydı',
          location: 'A Blok',
        ),
      );
      final reminder = await firstSuccess.agenda.createReminder(
        CreateReminderCommand(
          id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000002',
          projectId: log.projectId,
          sourceLogId: log.id,
          title: 'Android offline reminder',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
      );
      final firstNotificationState = await firstSuccess.agenda
          .getReminderLifecycleDetail(reminder.id);
      expect(
        firstNotificationState.notification.syncState,
        NotificationSyncState.scheduled,
      );
      expect(
        (await firstNotifications.pendingNotifications()).where(
          (item) => item.reminderId == reminder.id,
        ),
        hasLength(1),
      );
      final restartedNotifications = FlutterReminderNotificationGateway();
      final restarted = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactory,
        clock: () => DateTime.now().toUtc(),
        notificationGateway: restartedNotifications,
      ).start();
      expect(restarted, isA<BootstrapSuccess>());
      expect(
        (restarted as BootstrapSuccess).smokeRecordCreatedAt,
        firstSuccess.smokeRecordCreatedAt,
      );
      final restartedSuccess = restarted;
      final persisted = await restartedSuccess.agenda.getAgendaLogDetail(
        log.id,
      );
      expect(persisted.log.description, 'Android offline Ajanda kaydı');
      expect(persisted.reminders.single.title, 'Android offline reminder');
      final observedDay = CseTimeCodec.istanbulDayKey(observedAt);
      final restartedDay = await restartedSuccess.agenda.listAgenda(
        AgendaQuery(istanbulDay: observedDay),
      );
      expect(restartedDay.single.id, log.id);
      attendanceDetail = await restartedSuccess.attendance!.getDayDetail(
        attendanceDay.id,
      );
      expect(attendanceDetail.entries.single.memberName, 'Emülatör Personeli');
      expect(attendanceDetail.entries.single.overtimeMinutes, 30);
      expect(attendanceDetail.linkedReminder!.id, attendanceReminder.id);

      await tester.pumpWidget(
        CseApp(bootstrap: Future.value(restartedSuccess)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saha hafızanız cihazınızda.'), findsOneWidget);
      expect(find.text('Offline temel hazır'), findsOneWidget);
      await tester.tap(find.text('Ajanda').last);
      await tester.pumpAndSettle();
      expect(find.text(observedDay), findsOneWidget);
      expect(find.byKey(const Key('agenda-day-list')), findsOneWidget);
      await tester.tap(find.text('Hatırlatıcı').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder-list')), findsOneWidget);

      await tester.tap(find.text('Puantaj').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attendance-page')), findsOneWidget);

      await restartedSuccess.agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000003',
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.complete,
        ),
      );
      expect(
        (await restartedNotifications.pendingNotifications()).where(
          (item) => item.reminderId == reminder.id,
        ),
        isEmpty,
      );
      attendanceDetail = await restartedSuccess.attendance!.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: attendanceDay.id,
          dayEventId: 'eeeeeeee-eeee-4eee-8eee-000000000012',
          reminderEventId: 'eeeeeeee-eeee-4eee-8eee-000000000013',
          expectedRevision: attendanceDetail.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      expect(attendanceDetail.day.status, AttendanceDayStatus.completed);
      expect(attendanceDetail.linkedReminder!.status, ReminderStatus.completed);
      expect(
        (await restartedNotifications.pendingNotifications()).where(
          (item) => item.reminderId == attendanceReminder.id,
        ),
        isEmpty,
      );
    },
  );
}
