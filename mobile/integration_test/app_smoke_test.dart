import 'dart:io';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/domain/mobile_backup_models.dart';
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
      await attendance.createSubcontractor(
        const CreateSubcontractorCommand(
          id: '22222222-2222-4222-8222-000000000001',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000004',
          projectId: '11111111-1111-4111-8111-111111111111',
          name: 'Emülatör Taşeronu',
          contactName: 'Saha Yetkilisi',
        ),
      );
      await attendance.createTeam(
        const CreateWorkforceTeamCommand(
          id: '22222222-2222-4222-8222-000000000002',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000005',
          projectId: '11111111-1111-4111-8111-111111111111',
          subcontractorId: '22222222-2222-4222-8222-000000000001',
          name: 'Emülatör Ekibi',
          leadName: 'Ekip Lideri',
        ),
      );
      await attendance.createMember(
        const CreateWorkforceMemberCommand(
          id: '22222222-2222-4222-8222-222222222222',
          projectId: '11111111-1111-4111-8111-111111111111',
          fullName: 'Emülatör Personeli',
          teamName: 'Emülatör Ekibi',
          roleName: 'Saha Ustası',
          personnelCode: 'EMU-01',
          subcontractorId: '22222222-2222-4222-8222-000000000001',
          teamId: '22222222-2222-4222-8222-000000000002',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000006',
        ),
      );
      await attendance.saveComplianceRecord(
        const SaveComplianceRecordCommand(
          id: '22222222-2222-4222-8222-000000000003',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000007',
          memberId: '22222222-2222-4222-8222-222222222222',
          expectedRevision: 0,
          documentType: ComplianceDocumentType.basicSafetyTraining,
          sourceStatus: ComplianceSourceStatus.valid,
          issuedDate: '2026-07-19',
          expiryDate: '2027-07-19',
        ),
      );
      await attendance.savePpeAssignment(
        const SavePpeAssignmentCommand(
          id: '22222222-2222-4222-8222-000000000004',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000008',
          memberId: '22222222-2222-4222-8222-222222222222',
          expectedRevision: 0,
          ppeType: 'Baret',
          quantity: 1,
          assignedDate: '2026-07-19',
          status: PpeAssignmentStatus.assigned,
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
      final currentIstanbulDay = CseTimeCodec.istanbulDayKey(
        CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
      );
      final nextIstanbulDay = CseTimeCodec.shiftIstanbulDay(
        currentIstanbulDay,
        1,
      );
      final nextDayStart = CseTimeCodec.istanbulDayBounds(
        nextIstanbulDay,
      ).start;
      final plannedPourAt = CseTimeCodec.encodeUtc(
        CseTimeCodec.decodeCanonicalUtc(
          nextDayStart,
        ).add(const Duration(hours: 9)),
      );
      var concrete = await firstSuccess.concrete!.createPour(
        CreateConcretePourCommand(
          id: '55555555-5555-4555-8555-555555555555',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000020',
          projectId: '11111111-1111-4111-8111-111111111111',
          pourCode: 'EMU-BT-01',
          elementLocation: 'Emülatör KOLON A1',
          plannedAt: plannedPourAt,
          concreteClass: 'C30/37',
          plannedVolumeM3: 20,
        ),
      );
      expect(concrete.checks, hasLength(11));
      final hourlyFieldTasks = concrete.linkedReminders
          .where(
            (item) =>
                item.title.endsWith('Laboratuvar randevusunu al/doğrula') ||
                item.title.endsWith('Yapı denetime haber ver'),
          )
          .toList(growable: false);
      expect(hourlyFieldTasks, hasLength(2));
      for (final linked in hourlyFieldTasks) {
        expect(linked.concretePourId, concrete.pour.id);
        final notification = await firstSuccess.agenda
            .getReminderLifecycleDetail(linked.id);
        expect(notification.notification.repeatIntervalMinutes, 60);
      }
      concrete = await firstSuccess.concrete!.attachEvidence(
        AttachConcreteEvidenceCommand(
          id: '66666666-6666-4666-8666-666666666666',
          pourId: concrete.pour.id,
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000021',
          expectedPourRevision: concrete.pour.revision,
          evidenceType: ConcreteEvidenceType.sitePhoto,
          originalFileName: 'emulator.jpg',
          bytes: const [0xff, 0xd8, 0xff, 0xe0, 1, 8, 9],
          capturedAt: observedAt,
          description: 'Android yedek taşınabilirlik kanıtı',
        ),
      );
      expect(
        concrete.attachments.single.integrity,
        ConcreteAttachmentIntegrity.ok,
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
      expect(
        attendanceDetail.entries.single.subcontractorName,
        'Emülatör Taşeronu',
      );
      expect(
        attendanceDetail.entries.single.teamId,
        '22222222-2222-4222-8222-000000000002',
      );
      expect(attendanceDetail.entries.single.overtimeMinutes, 30);
      expect(attendanceDetail.linkedReminder!.id, attendanceReminder.id);
      final personDetail = await restartedSuccess.attendance!.getPersonDetail(
        '22222222-2222-4222-8222-222222222222',
      );
      expect(personDetail.member.subcontractorName, 'Emülatör Taşeronu');
      expect(
        personDetail.compliance.single.readStatus,
        ComplianceReadStatus.valid,
      );
      expect(personDetail.ppeAssignments.single.ppeType, 'Baret');
      final persistedConcrete = await restartedSuccess.concrete!.getPourDetail(
        concrete.pour.id,
      );
      expect(persistedConcrete.pour.pourCode, 'EMU-BT-01');
      expect(persistedConcrete.events.first.eventType, 'pour.created');
      expect(
        persistedConcrete.attachments.single.integrity,
        ConcreteAttachmentIntegrity.ok,
      );

      final backup = restartedSuccess.backup!;
      final createdBackup = await backup.createBackup(
        const CreateMobileBackupCommand(
          password: 'android-integration-parola',
          passwordConfirmation: 'android-integration-parola',
        ),
      );
      expect(await File(createdBackup.absolutePath).exists(), isTrue);
      await restartedSuccess.agenda.createProject(
        const CreateProjectCommand(
          id: '77777777-7777-4777-8777-777777777777',
          name: 'Yedek sonrası geçici proje',
        ),
      );
      final backupPreflight = await backup.preflightBackup(
        createdBackup.absolutePath,
        'android-integration-parola',
      );
      await backup.restoreBackup(
        RestoreMobileBackupCommand(
          packagePath: createdBackup.absolutePath,
          password: 'android-integration-parola',
          expectedPackageSha256: backupPreflight.packageSha256,
        ),
      );
      expect(
        (await restartedSuccess.agenda.listProjects()).map((item) => item.id),
        isNot(contains('77777777-7777-4777-8777-777777777777')),
      );
      expect(
        (await restartedSuccess.concrete!.getPourDetail(
          concrete.pour.id,
        )).attachments.single.integrity,
        ConcreteAttachmentIntegrity.ok,
      );
      final restoredPerson = await restartedSuccess.attendance!.getPersonDetail(
        '22222222-2222-4222-8222-222222222222',
      );
      expect(restoredPerson.member.teamName, 'Emülatör Ekibi');
      expect(restoredPerson.compliance.single.documentNumber, isNull);
      expect(
        restoredPerson.ppeAssignments.single.status,
        PpeAssignmentStatus.assigned,
      );

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

      await tester.tap(find.text('Beton Paketi').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('concrete-page')), findsOneWidget);
      await tester.tap(find.text('Yaklaşan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('EMU-BT-01'), findsOneWidget);

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
