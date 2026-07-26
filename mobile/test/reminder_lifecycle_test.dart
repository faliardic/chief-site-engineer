import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const logId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const reminder1 = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const reminder2 = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2';
const reminder3 = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc3';

String eventId(int value) =>
    'dddddddd-dddd-4ddd-8ddd-${value.toString().padLeft(12, '0')}';

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;
  late DateTime now;
  late _FakeNotificationGateway notifications;
  late SqliteAgendaApplication agenda;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_lifecycle_');
    directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    await directories.ensureCreated();
    now = DateTime.utc(2026, 7, 19, 8);
    notifications = _FakeNotificationGateway();
    agenda = SqliteAgendaApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
      notificationGateway: notifications,
    );
  });

  tearDown(() async {
    await notifications.close();
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  Future<void> createProjectAndLog() async {
    await agenda.createProject(
      const CreateProjectCommand(id: projectId, name: 'Şantiye A'),
    );
    await agenda.createAgendaLog(
      CreateAgendaLogCommand(
        id: logId,
        eventId: eventId(900),
        projectId: projectId,
        observedAt: '2026-07-19T07:00:00Z',
        category: AgendaCategory.generalNote,
        description: 'Kaynak saha logu',
      ),
    );
  }

  Future<void> setRepeatInterval(String reminderId, int minutes) async {
    final database = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      await database.update(
        'reminder_notification_bindings',
        {'repeat_interval_minutes': minutes},
        where: 'reminder_id = ?',
        whereArgs: [reminderId],
      );
    } finally {
      await database.close();
    }
  }

  test(
    'minimum standalone inbox capture is idempotent with one clock read',
    () async {
      var clockReads = 0;
      agenda = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () {
          clockReads += 1;
          return now;
        },
        notificationGateway: notifications,
      );
      final command = CreateReminderCommand(
        id: reminder1,
        eventId: eventId(1),
        title: '  İskele kontrolünü unutma  ',
        kind: ReminderKind.action,
        schedule: ReminderScheduleKind.inbox,
      );

      final created = await agenda.createReminder(command);
      expect(clockReads, 1);
      expect(created.projectId, isNull);
      expect(created.sourceLogId, isNull);
      expect(created.captureText, 'İskele kontrolünü unutma');
      expect(created.status, ReminderStatus.inbox);
      expect(created.revision, 1);

      now = DateTime.utc(2026, 7, 19, 9);
      final retried = await agenda.createReminder(command);
      expect(retried.id, created.id);
      expect(retried.createdAt, created.createdAt);
      expect((await agenda.listReminderEvents(reminder1)).length, 1);
      expect(await _countRows(directories.databaseFile, 'follow_up_items'), 1);
    },
  );

  test(
    'linked reminder lifecycle never mutates its source agenda log',
    () async {
      await createProjectAndLog();
      final sourceBefore = await agenda.getAgendaLogDetail(logId);
      final reminder = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(1),
          projectId: projectId,
          sourceLogId: logId,
          title: 'Bağlı kontrol',
          kind: ReminderKind.recheck,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(2),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.schedule,
          schedule: ReminderScheduleKind.in1Hour,
        ),
      );
      final sourceAfter = await agenda.getAgendaLogDetail(logId);

      expect(sourceAfter.log.updatedAt, sourceBefore.log.updatedAt);
      expect(sourceAfter.log.revision, sourceBefore.log.revision);
      expect(sourceAfter.reminders.single.sourceLogId, logId);
      expect(sourceAfter.reminders.single.projectId, projectId);
    },
  );

  test(
    'tomorrow keeps local clock or uses 09:00 and preserves source',
    () async {
      await createProjectAndLog();
      final sourceBefore = await agenda.getAgendaLogDetail(logId);
      var scheduled = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(910),
          title: 'Aynı saatte yarın',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-19T12:45:00Z',
          projectId: projectId,
          sourceLogId: logId,
        ),
      );
      scheduled = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: scheduled.id,
          eventId: eventId(911),
          expectedRevision: scheduled.revision,
          action: ReminderMutationAction.snoozeTomorrowMorning,
        ),
      );
      expect(scheduled.nextAttentionAt, '2026-07-20T12:45:00Z');
      expect(scheduled.revision, 2);
      expect(
        notifications.scheduled.last.scheduledAtUtc,
        '2026-07-20T12:45:00Z',
      );
      final lifecycle = await agenda.getReminderLifecycleDetail(scheduled.id);
      expect(
        lifecycle.events.map((event) => event.eventType),
        contains('snoozed'),
      );
      final sourceAfter = await agenda.getAgendaLogDetail(logId);
      expect(sourceAfter.log.revision, sourceBefore.log.revision);
      expect(sourceAfter.log.updatedAt, sourceBefore.log.updatedAt);

      var inbox = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder2,
          eventId: eventId(912),
          title: 'Saati olmayan kayıt',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      inbox = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: inbox.id,
          eventId: eventId(913),
          expectedRevision: inbox.revision,
          action: ReminderMutationAction.snoozeTomorrowMorning,
        ),
      );
      expect(inbox.status, ReminderStatus.active);
      expect(inbox.nextAttentionAt, '2026-07-20T06:00:00Z');
    },
  );

  test(
    'tomorrow is a no-op when the reminder already has that local time',
    () async {
      final scheduled = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(914),
          title: 'Zaten yarın aynı saat',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-20T12:45:00Z',
        ),
      );
      final eventCount = (await agenda.listReminderEvents(scheduled.id)).length;
      final nativeScheduleCount = notifications.scheduled.length;

      final unchanged = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: scheduled.id,
          eventId: eventId(915),
          expectedRevision: scheduled.revision,
          action: ReminderMutationAction.snoozeTomorrowMorning,
        ),
      );

      expect(unchanged.revision, scheduled.revision);
      expect(unchanged.nextAttentionAt, scheduled.nextAttentionAt);
      expect(
        await agenda.listReminderEvents(scheduled.id),
        hasLength(eventCount),
      );
      expect(notifications.scheduled, hasLength(nativeScheduleCount));
    },
  );

  test(
    'all-day reminders use local dates without native timed notifications',
    () async {
      now = DateTime.utc(2026, 12, 31, 20, 30);
      var today = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(920),
          title: 'Yıl sonu tam gün',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          allDayLocalDate: '2026-12-31',
        ),
      );
      final tomorrow = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder2,
          eventId: eventId(921),
          title: 'Yeni yıl tam gün',
          kind: ReminderKind.recheck,
          schedule: ReminderScheduleKind.custom,
          allDayLocalDate: '2027-01-01',
        ),
      );

      expect(today.status, ReminderStatus.active);
      expect(today.nextAttentionAt, isNull);
      expect(today.allDayLocalDate, '2026-12-31');
      expect(tomorrow.allDayLocalDate, '2027-01-01');
      expect(notifications.scheduled, isEmpty);
      expect(
        (await agenda.listReminders(ReminderViewGroup.today)).single.id,
        today.id,
      );
      expect(
        (await agenda.listReminders(ReminderViewGroup.tomorrow)).single.id,
        tomorrow.id,
      );
      final binding = await agenda.getReminderLifecycleDetail(today.id);
      expect(binding.notification.scheduledFor, isNull);
      expect(binding.notification.syncState, NotificationSyncState.cancelled);

      today = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: today.id,
          eventId: eventId(922),
          expectedRevision: today.revision,
          action: ReminderMutationAction.complete,
        ),
      );
      expect(today.status, ReminderStatus.completed);
      expect(today.allDayLocalDate, '2026-12-31');
      expect(today.nextAttentionAt, isNull);
      today = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: today.id,
          eventId: eventId(923),
          expectedRevision: today.revision,
          action: ReminderMutationAction.reopen,
        ),
      );
      expect(today.status, ReminderStatus.active);
      expect(today.allDayLocalDate, '2026-12-31');
      today = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: today.id,
          eventId: eventId(924),
          expectedRevision: today.revision,
          action: ReminderMutationAction.cancel,
        ),
      );
      expect(today.status, ReminderStatus.cancelled);
      expect(today.allDayLocalDate, '2026-12-31');
      expect(notifications.scheduled, isEmpty);

      await expectLater(
        agenda.createReminder(
          CreateReminderCommand(
            id: reminder3,
            eventId: eventId(925),
            title: 'Çelişkili schedule',
            kind: ReminderKind.action,
            schedule: ReminderScheduleKind.custom,
            customAttentionAt: '2027-01-01T06:00:00Z',
            allDayLocalDate: '2027-01-01',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
    },
  );

  test(
    'full lifecycle uses optimistic revision append-only events and no-op',
    () async {
      var reminder = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(1),
          title: 'Yaşam döngüsü',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(2),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.updateDetails,
          title: 'Güncellenen yaşam döngüsü',
          description: 'Açıklama',
          kind: ReminderKind.recheck,
          location: 'B Blok',
          relatedPerson: 'Usta Ali',
          isImportant: true,
          conditionText: 'Yağmur durunca',
        ),
      );
      expect(reminder.revision, 2);
      expect(reminder.isImportant, isTrue);
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(3),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.schedule,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
      );
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(4),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.schedule,
          schedule: ReminderScheduleKind.in1Hour,
        ),
      );
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(5),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.snoozeTomorrowMorning,
        ),
      );
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(6),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.moveToInbox,
        ),
      );
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(7),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.complete,
          outcomeType: ReminderOutcomeType.noLongerNeeded,
          outcomeNote: 'Başka ekip tamamladı',
        ),
      );
      expect(reminder.status, ReminderStatus.completed);
      expect(reminder.completedAt, isNotNull);
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(8),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.reopen,
        ),
      );
      expect(reminder.status, ReminderStatus.inbox);
      final noOp = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(9),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.reopen,
        ),
      );
      expect(noOp.revision, reminder.revision);
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(10),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.cancel,
          outcomeNote: 'İş kapsamdan çıktı',
        ),
      );
      expect(reminder.status, ReminderStatus.cancelled);
      expect(reminder.cancelledAt, isNotNull);
      final events = await agenda.listReminderEvents(reminder.id);
      final businessEvents = events
          .where((item) => !item.eventType.startsWith('notification_'))
          .toList();
      expect(businessEvents.map((item) => item.eventType), [
        'created',
        'details_updated',
        'scheduled',
        'rescheduled',
        'snoozed',
        'moved_to_inbox',
        'completed',
        'reopened',
        'cancelled',
      ]);
      expect(
        events.map((item) => item.sequence),
        List.generate(events.length, (i) => i + 1),
      );
      expect(
        events.map((item) => item.eventType),
        containsAll(['notification_scheduled', 'notification_cancelled']),
      );
      await expectLater(
        agenda.mutateReminder(
          MutateReminderCommand(
            reminderId: reminder.id,
            eventId: eventId(11),
            expectedRevision: 1,
            action: ReminderMutationAction.reopen,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
    },
  );

  test('lifecycle event failure rolls back row and event together', () async {
    final created = await agenda.createReminder(
      CreateReminderCommand(
        id: reminder1,
        eventId: eventId(1),
        title: 'Rollback',
        kind: ReminderKind.action,
        schedule: ReminderScheduleKind.inbox,
      ),
    );
    final failing = SqliteAgendaApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
      notificationGateway: notifications,
      beforeReminderEventInsert: (_) async {
        throw StateError('forced event failure');
      },
    );
    await expectLater(
      failing.mutateReminder(
        MutateReminderCommand(
          reminderId: created.id,
          eventId: eventId(2),
          expectedRevision: 1,
          action: ReminderMutationAction.snoozeTomorrowMorning,
        ),
      ),
      throwsA(anything),
    );
    final persisted = await agenda.getReminderDetail(created.id);
    expect(persisted.status, ReminderStatus.inbox);
    expect(persisted.revision, 1);
    expect((await agenda.listReminderEvents(created.id)).length, 1);
  });

  test(
    'permission denial and plugin failure never lose reminder rows',
    () async {
      notifications.permission = NotificationPermissionState.denied;
      final denied = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(1),
          title: 'İzin reddedildi',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
      );
      final deniedDetail = await agenda.getReminderLifecycleDetail(denied.id);
      expect(
        deniedDetail.notification.syncState,
        NotificationSyncState.permissionDenied,
      );
      expect(deniedDetail.notification.safeErrorCode, 'permission_denied');
      expect(notifications.requestCalls, 1);

      notifications.permission = NotificationPermissionState.granted;
      notifications.failSchedule = true;
      final failed = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder2,
          eventId: eventId(2),
          title: 'Plugin hatası',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in1Hour,
        ),
      );
      final failedDetail = await agenda.getReminderLifecycleDetail(failed.id);
      expect(failedDetail.notification.syncState, NotificationSyncState.failed);
      expect(failedDetail.notification.safeErrorCode, 'native_schedule_failed');
      expect(await _countRows(directories.databaseFile, 'follow_up_items'), 2);
    },
  );

  test(
    'platform capacity keeps later reminders visible and unscheduled',
    () async {
      notifications.maximumPendingNotifications = 1;
      final nearest = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(1),
          title: 'En yakın',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
      );
      final later = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder2,
          eventId: eventId(2),
          title: 'Daha sonra',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in1Hour,
        ),
      );

      expect(
        (await agenda.getReminderLifecycleDetail(
          nearest.id,
        )).notification.syncState,
        NotificationSyncState.scheduled,
      );
      final laterDetail = await agenda.getReminderLifecycleDetail(later.id);
      expect(
        laterDetail.notification.syncState,
        NotificationSyncState.unavailable,
      );
      expect(laterDetail.notification.safeErrorCode, 'platform_capacity');
      expect(await _countRows(directories.databaseFile, 'follow_up_items'), 2);
    },
  );

  test('unavailable platform leaves scheduled reminder intact', () async {
    notifications.permission = NotificationPermissionState.unavailable;
    final reminder = await agenda.createReminder(
      CreateReminderCommand(
        id: reminder3,
        eventId: eventId(3),
        title: 'Platform yokken de kaydet',
        kind: ReminderKind.action,
        schedule: ReminderScheduleKind.tomorrowMorning,
      ),
    );
    final detail = await agenda.getReminderLifecycleDetail(reminder.id);
    expect(detail.reminder.status, ReminderStatus.active);
    expect(detail.notification.syncState, NotificationSyncState.unavailable);
    expect(detail.notification.safeErrorCode, 'platform_unavailable');
  });

  test(
    'exact access denial keeps an explicit inexact fallback and retry upgrades it',
    () async {
      notifications.permission = NotificationPermissionState.exactAlarmDenied;
      final reminder = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(31),
          title: 'Exact erişim bekleyen kayıt',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
      );

      var detail = await agenda.getReminderLifecycleDetail(reminder.id);
      expect(detail.notification.syncState, NotificationSyncState.unavailable);
      expect(
        detail.notification.safeErrorCode,
        'exact_alarm_permission_required',
      );
      expect(notifications.fallbackScheduled, hasLength(1));
      expect(notifications.pending, hasLength(1));

      notifications.permission = NotificationPermissionState.granted;
      notifications.scheduled.clear();
      await agenda.reconcileNotifications();
      detail = await agenda.getReminderLifecycleDetail(reminder.id);
      expect(detail.notification.syncState, NotificationSyncState.scheduled);
      expect(detail.notification.safeErrorCode, isNull);
      expect(notifications.scheduled, hasLength(1));
      expect(notifications.pending, hasLength(1));
    },
  );

  test(
    'native schedule must be visible before binding says scheduled',
    () async {
      notifications.omitPendingAfterSchedule = true;
      final reminder = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(32),
          title: 'Native doğrulama',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in1Hour,
        ),
      );

      final detail = await agenda.getReminderLifecycleDetail(reminder.id);
      expect(detail.reminder.status, ReminderStatus.active);
      expect(detail.notification.syncState, NotificationSyncState.failed);
      expect(detail.notification.safeErrorCode, 'native_schedule_failed');
      expect(notifications.pending, isEmpty);
      final diagnostic = await agenda.getReminderDeliveryDiagnostic(
        reminder.id,
      );
      expect(
        diagnostic.delayClass,
        ReminderDeliveryDelayClass.nativeScheduleMissing,
      );
    },
  );

  test(
    'past active due is overdue without a native-plan failure class',
    () async {
      final reminder = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(35),
          title: 'Geçmiş aktif reminder',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
      );
      notifications.pending.clear();
      now = now.add(const Duration(hours: 1));

      final diagnostic = await agenda.getReminderDeliveryDiagnostic(
        reminder.id,
      );

      expect(diagnostic.nativeSchedulePresent, isFalse);
      expect(diagnostic.delayClass, ReminderDeliveryDelayClass.overdue);
      expect(
        diagnostic.delayClass,
        isNot(ReminderDeliveryDelayClass.nativeScheduleMissing),
      );
    },
  );

  test('channel enable and restart reconcile once without duplicate', () async {
    notifications.permission = NotificationPermissionState.channelDisabled;
    final reminder = await agenda.createReminder(
      CreateReminderCommand(
        id: reminder1,
        eventId: eventId(33),
        title: 'Kanalı kapalı kayıt',
        kind: ReminderKind.action,
        schedule: ReminderScheduleKind.in1Hour,
      ),
    );
    expect(
      (await agenda.getReminderLifecycleDetail(
        reminder.id,
      )).notification.safeErrorCode,
      'notification_channel_disabled',
    );

    notifications.permission = NotificationPermissionState.granted;
    final restarted = SqliteAgendaApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
      notificationGateway: notifications,
    );
    await restarted.reconcileNotifications();
    expect(notifications.scheduled, hasLength(1));
    await restarted.reconcileNotifications();
    expect(notifications.scheduled, hasLength(1));
    expect(notifications.pending, hasLength(1));
  });

  test('privacy-safe diagnostic exposes native and delay evidence', () async {
    final reminder = await agenda.createReminder(
      CreateReminderCommand(
        id: reminder1,
        eventId: eventId(34),
        title: 'Gizli şantiye notu',
        kind: ReminderKind.action,
        schedule: ReminderScheduleKind.in15Minutes,
      ),
    );
    notifications.diagnostic = const ReminderPlatformDiagnostic(
      permissionState: 'granted',
      channelState: 'enabled',
      exactAlarmState: 'granted',
      batteryOptimizationState: 'optimized',
      backgroundRestrictionState: 'allowed',
      standbyBucket: 'active',
      bootRescheduleState: 'completed',
      bootRescheduledAtUtc: '2026-07-19T08:05:00Z',
      activeNotificationPostedAtUtc: '2026-07-19T08:17:00Z',
    );

    final diagnostic = await agenda.getReminderDeliveryDiagnostic(reminder.id);
    expect(diagnostic.safeReminderId, 'cccccccc');
    expect(diagnostic.scheduleKind, 'one_shot');
    expect(diagnostic.nativeSchedulePresent, isTrue);
    expect(diagnostic.delayClass, ReminderDeliveryDelayClass.delayed);
    expect(diagnostic.bootRescheduleState, 'completed');
    expect(diagnostic.toString(), isNot(contains('Gizli şantiye notu')));
  });

  test(
    'reconciliation repairs missing and removes duplicate orphan pending',
    () async {
      final created = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(1),
          title: 'Reconcile',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in1Hour,
        ),
      );
      final detail = await agenda.getReminderLifecycleDetail(created.id);
      final expectedId = detail.notification.platformNotificationId;
      notifications.pending
        ..clear()
        ..add(
          PendingReminderNotification(
            platformId: expectedId + 100,
            reminderId: created.id,
          ),
        )
        ..add(
          const PendingReminderNotification(
            platformId: 2147483000,
            reminderId: null,
          ),
        );
      notifications.cancelled.clear();
      notifications.scheduled.clear();

      await agenda.reconcileNotifications();

      expect(notifications.cancelled, contains(expectedId + 100));
      expect(notifications.cancelled, contains(2147483000));
      expect(notifications.scheduled.single.platformId, expectedId);
      final repaired = await agenda.getReminderLifecycleDetail(created.id);
      expect(repaired.notification.syncState, NotificationSyncState.scheduled);

      notifications.pending
        ..clear()
        ..add(
          PendingReminderNotification(
            platformId: expectedId,
            reminderId: created.id,
            scheduleComplete: false,
          ),
        );
      notifications.cancelled.clear();
      notifications.scheduled.clear();
      await agenda.reconcileNotifications();
      expect(notifications.cancelled, contains(expectedId));
      expect(notifications.scheduled.single.platformId, expectedId);

      final completed = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: created.id,
          eventId: eventId(2),
          expectedRevision: created.revision,
          action: ReminderMutationAction.complete,
        ),
      );
      expect(completed.status, ReminderStatus.completed);
      expect(notifications.pending, isEmpty);
      expect(
        (await agenda.getReminderLifecycleDetail(
          created.id,
        )).notification.syncState,
        NotificationSyncState.cancelled,
      );
    },
  );

  test(
    'platform notification id collision probes to a unique integer',
    () async {
      await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(1),
          title: 'Birinci',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      final target = _stablePlatformId(reminder2);
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await raw.update(
        'reminder_notification_bindings',
        {'platform_notification_id': target},
        where: 'reminder_id = ?',
        whereArgs: [reminder1],
      );
      await raw.close();

      await agenda.createReminder(
        CreateReminderCommand(
          id: reminder2,
          eventId: eventId(2),
          title: 'İkinci',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      final second = await agenda.getReminderLifecycleDetail(reminder2);
      expect(second.notification.platformNotificationId, target + 1);
      final ids = await _bindingIds(directories.databaseFile);
      expect(ids.toSet().length, 2);
    },
  );

  test(
    'reminder events are append-only and aggregate cannot be deleted',
    () async {
      await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(1),
          title: 'Silinemez',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await expectLater(
        raw.update(
          'follow_up_events',
          {'event_type': 'details_updated'},
          where: 'follow_up_id = ?',
          whereArgs: [reminder1],
        ),
        throwsA(anything),
      );
      await expectLater(
        raw.delete(
          'follow_up_events',
          where: 'follow_up_id = ?',
          whereArgs: [reminder1],
        ),
        throwsA(anything),
      );
      await expectLater(
        raw.delete('follow_up_items', where: 'id = ?', whereArgs: [reminder1]),
        throwsA(anything),
      );
      await raw.close();
    },
  );

  test('read models expose every lifecycle group deterministically', () async {
    final schedules = [
      ReminderScheduleKind.inbox,
      ReminderScheduleKind.in15Minutes,
      ReminderScheduleKind.in1Hour,
      ReminderScheduleKind.tomorrowMorning,
    ];
    for (var index = 0; index < schedules.length; index += 1) {
      await agenda.createReminder(
        CreateReminderCommand(
          id: 'eeeeeeee-eeee-4eee-8eee-${index.toString().padLeft(12, '0')}',
          eventId: eventId(100 + index),
          title: 'Sıralı $index',
          kind: index == 3 ? ReminderKind.recheck : ReminderKind.action,
          schedule: schedules[index],
          isImportant: index == 2,
        ),
      );
    }
    expect(await agenda.listReminders(ReminderViewGroup.inbox), hasLength(1));
    expect(await agenda.listReminders(ReminderViewGroup.today), hasLength(2));
    expect(await agenda.listReminders(ReminderViewGroup.recheck), hasLength(1));
    expect(
      await agenda.listReminders(ReminderViewGroup.upcoming),
      hasLength(1),
    );
  });

  test(
    'trash and restore preserve linked timed lifecycle binding and audit',
    () async {
      await createProjectAndLog();
      final sourceBefore = await agenda.getAgendaLogDetail(logId);
      final created = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(201),
          projectId: projectId,
          sourceLogId: logId,
          title: 'Bağlı gelecekteki kontrol',
          kind: ReminderKind.recheck,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-19T10:00:00Z',
          deadlineAt: '2026-07-20T10:00:00Z',
          conditionText: 'Beton öncesi',
        ),
      );
      final bindingBefore = await agenda.getReminderLifecycleDetail(created.id);
      now = DateTime.utc(2026, 7, 19, 8, 5);
      final trashed = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: created.id,
          eventId: eventId(202),
          expectedRevision: created.revision,
          action: ReminderMutationAction.moveToTrash,
        ),
      );

      expect(trashed.trashedAt, '2026-07-19T08:05:00Z');
      expect(trashed.status, created.status);
      expect(trashed.kind, created.kind);
      expect(trashed.nextAttentionAt, created.nextAttentionAt);
      expect(trashed.deadlineAt, created.deadlineAt);
      expect(trashed.conditionText, created.conditionText);
      expect(trashed.sourceLogId, logId);
      expect(trashed.revision, created.revision + 1);
      expect(await agenda.listReminders(ReminderViewGroup.today), isEmpty);
      expect((await agenda.getReminderTodayOverview()).timedToday, isEmpty);
      expect(
        (await agenda.listReminders(ReminderViewGroup.trash)).single.id,
        created.id,
      );
      expect((await agenda.getAgendaLogDetail(logId)).reminders, isEmpty);
      final trashedDetail = await agenda.getReminderLifecycleDetail(created.id);
      expect(
        trashedDetail.notification.platformNotificationId,
        bindingBefore.notification.platformNotificationId,
      );
      expect(trashedDetail.notification.scheduledFor, isNull);
      expect(
        trashedDetail.notification.syncState,
        NotificationSyncState.cancelled,
      );
      final businessEventsBeforeNoOp = trashedDetail.events
          .where((item) => !item.eventType.startsWith('notification_'))
          .toList();
      expect(businessEventsBeforeNoOp.last.eventType, 'trashed');
      final trashPayload =
          jsonDecode(businessEventsBeforeNoOp.last.payloadJson)
              as Map<String, dynamic>;
      expect(trashPayload['revision'], trashed.revision);
      expect(trashPayload['status'], created.status.storageValue);
      expect(trashPayload['next_attention_at'], created.nextAttentionAt);
      expect(trashPayload['source_observation_id'], logId);

      final duplicate = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: trashed.id,
          eventId: eventId(203),
          expectedRevision: trashed.revision,
          action: ReminderMutationAction.moveToTrash,
        ),
      );
      expect(duplicate.revision, trashed.revision);
      expect(
        (await agenda.listReminderEvents(
          trashed.id,
        )).where((item) => item.eventType == 'trashed'),
        hasLength(1),
      );
      await expectLater(
        agenda.mutateReminder(
          MutateReminderCommand(
            reminderId: trashed.id,
            eventId: eventId(204),
            expectedRevision: created.revision,
            action: ReminderMutationAction.restoreFromTrash,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect((await agenda.getReminderDetail(trashed.id)).trashedAt, isNotNull);

      now = DateTime.utc(2026, 7, 19, 8, 10);
      final restored = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: trashed.id,
          eventId: eventId(205),
          expectedRevision: trashed.revision,
          action: ReminderMutationAction.restoreFromTrash,
        ),
      );
      expect(restored.trashedAt, isNull);
      expect(restored.status, created.status);
      expect(restored.nextAttentionAt, created.nextAttentionAt);
      expect(restored.deadlineAt, created.deadlineAt);
      expect(restored.sourceLogId, logId);
      expect(restored.revision, trashed.revision + 1);
      expect(await agenda.listReminders(ReminderViewGroup.trash), isEmpty);
      expect(
        (await agenda.getAgendaLogDetail(logId)).reminders.single.id,
        created.id,
      );
      final sourceAfter = await agenda.getAgendaLogDetail(logId);
      expect(sourceAfter.log.revision, sourceBefore.log.revision);
      expect(sourceAfter.log.updatedAt, sourceBefore.log.updatedAt);
      final restoredDetail = await agenda.getReminderLifecycleDetail(
        restored.id,
      );
      expect(
        restoredDetail.notification.platformNotificationId,
        bindingBefore.notification.platformNotificationId,
      );
      expect(
        restoredDetail.notification.syncState,
        NotificationSyncState.scheduled,
      );
      expect(
        restoredDetail.events.where(
          (item) => item.eventType == 'restored_from_trash',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'overdue repeat stays cancelled after trash restore and every reconcile',
    () async {
      now = DateTime.utc(2026, 7, 18, 8);
      final created = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(210),
          title: 'Gecikmiş saatlik tekrar',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-18T08:15:00Z',
        ),
      );
      await setRepeatInterval(created.id, 60);
      final originalBinding = await agenda.getReminderLifecycleDetail(
        created.id,
      );
      final platformId = originalBinding.notification.platformNotificationId;
      now = DateTime.utc(2026, 7, 19, 9);

      final trashed = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: created.id,
          eventId: eventId(211),
          expectedRevision: created.revision,
          action: ReminderMutationAction.moveToTrash,
        ),
      );
      final afterTrash = await agenda.getReminderLifecycleDetail(created.id);
      expect(afterTrash.notification.platformNotificationId, platformId);
      expect(afterTrash.notification.repeatIntervalMinutes, 60);
      expect(afterTrash.notification.scheduledFor, isNull);
      expect(
        afterTrash.notification.syncState,
        NotificationSyncState.cancelled,
      );
      final nativeScheduleCount = notifications.scheduled.length;

      now = DateTime.utc(2026, 7, 19, 9, 5);
      final restored = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: trashed.id,
          eventId: eventId(212),
          expectedRevision: trashed.revision,
          action: ReminderMutationAction.restoreFromTrash,
        ),
      );
      expect(notifications.scheduled, hasLength(nativeScheduleCount));
      expect(
        (await agenda.listReminders(ReminderViewGroup.overdue)).single.id,
        restored.id,
      );

      await agenda.reconcileNotifications();
      expect(notifications.scheduled, hasLength(nativeScheduleCount));

      final reopened = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        notificationGateway: notifications,
      );
      await reopened.reconcileNotifications();
      expect(notifications.scheduled, hasLength(nativeScheduleCount));

      final finalBinding = await reopened.getReminderLifecycleDetail(
        restored.id,
      );
      expect(finalBinding.notification.platformNotificationId, platformId);
      expect(finalBinding.notification.repeatIntervalMinutes, 60);
      expect(finalBinding.notification.scheduledFor, isNull);
      expect(
        finalBinding.notification.syncState,
        NotificationSyncState.cancelled,
      );
    },
  );

  test(
    'future repeat restore schedules with the same binding identity',
    () async {
      final created = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(220),
          title: 'Gelecekteki saatlik tekrar',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-19T10:00:00Z',
        ),
      );
      await setRepeatInterval(created.id, 60);
      final originalBinding = await agenda.getReminderLifecycleDetail(
        created.id,
      );
      final platformId = originalBinding.notification.platformNotificationId;
      now = DateTime.utc(2026, 7, 19, 8, 5);
      final trashed = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: created.id,
          eventId: eventId(221),
          expectedRevision: created.revision,
          action: ReminderMutationAction.moveToTrash,
        ),
      );
      notifications.scheduled.clear();

      now = DateTime.utc(2026, 7, 19, 8, 10);
      await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: trashed.id,
          eventId: eventId(222),
          expectedRevision: trashed.revision,
          action: ReminderMutationAction.restoreFromTrash,
        ),
      );

      expect(notifications.scheduled, hasLength(1));
      expect(notifications.scheduled.single.platformId, platformId);
      expect(notifications.scheduled.single.repeatIntervalMinutes, 60);
      final restoredBinding = await agenda.getReminderLifecycleDetail(
        created.id,
      );
      expect(restoredBinding.notification.platformNotificationId, platformId);
      expect(restoredBinding.notification.repeatIntervalMinutes, 60);
      expect(
        restoredBinding.notification.syncState,
        NotificationSyncState.scheduled,
      );
    },
  );

  test(
    'existing overdue repeat without trash keeps normal reconciliation',
    () async {
      final created = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(230),
          title: 'Mevcut saatlik tekrar',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-19T08:15:00Z',
        ),
      );
      await setRepeatInterval(created.id, 60);
      final originalBinding = await agenda.getReminderLifecycleDetail(
        created.id,
      );
      final platformId = originalBinding.notification.platformNotificationId;
      notifications.pending.clear();
      notifications.scheduled.clear();
      now = DateTime.utc(2026, 7, 19, 9);

      await agenda.reconcileNotifications();

      expect(notifications.scheduled, hasLength(1));
      expect(notifications.scheduled.single.platformId, platformId);
      expect(notifications.scheduled.single.repeatIntervalMinutes, 60);
      final reconciled = await agenda.getReminderLifecycleDetail(created.id);
      expect(reconciled.notification.repeatIntervalMinutes, 60);
      expect(
        reconciled.notification.syncState,
        NotificationSyncState.scheduled,
      );
    },
  );

  test(
    'trash ordering and restore preserve all-day inbox and terminal records',
    () async {
      final allDay = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(301),
          title: 'Tam gün',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          allDayLocalDate: '2026-07-19',
        ),
      );
      final overdue = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder2,
          eventId: eventId(302),
          title: 'Gecikmiş saatli',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-19T08:30:00Z',
        ),
      );
      final inbox = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder3,
          eventId: eventId(303),
          title: 'Plansız',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      var completed = await agenda.createReminder(
        CreateReminderCommand(
          id: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc4',
          eventId: eventId(304),
          title: 'Tamamlanan',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      completed = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: completed.id,
          eventId: eventId(305),
          expectedRevision: completed.revision,
          action: ReminderMutationAction.complete,
          outcomeNote: 'Korunacak sonuç',
        ),
      );
      var cancelled = await agenda.createReminder(
        CreateReminderCommand(
          id: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc5',
          eventId: eventId(306),
          title: 'İptal edilen',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      cancelled = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: cancelled.id,
          eventId: eventId(307),
          expectedRevision: cancelled.revision,
          action: ReminderMutationAction.cancel,
          outcomeNote: 'Korunacak iptal sonucu',
        ),
      );
      final originals = {
        for (final item in [allDay, overdue, inbox, completed, cancelled])
          item.id: item,
      };
      final trashed = <MobileReminder>[];
      var index = 0;
      for (final item in originals.values) {
        now = DateTime.utc(2026, 7, 19, 10, index);
        trashed.add(
          await agenda.mutateReminder(
            MutateReminderCommand(
              reminderId: item.id,
              eventId: eventId(320 + index),
              expectedRevision: item.revision,
              action: ReminderMutationAction.moveToTrash,
            ),
          ),
        );
        index += 1;
      }

      expect((await agenda.getReminderTodayOverview()).isEmpty, isTrue);
      expect((await agenda.getReminderTodayOverview()).inboxCount, 0);
      for (final group in ReminderViewGroup.values.where(
        (group) => group != ReminderViewGroup.trash,
      )) {
        expect(await agenda.listReminders(group), isEmpty);
      }
      final trash = await agenda.listReminders(ReminderViewGroup.trash);
      expect(
        trash.map((item) => item.id),
        trashed.reversed.map((item) => item.id),
      );

      final scheduledBeforeRestore = notifications.scheduled.length;
      index = 0;
      for (final item in trash) {
        final original = originals[item.id]!;
        now = DateTime.utc(2026, 7, 19, 11, index);
        final restored = await agenda.mutateReminder(
          MutateReminderCommand(
            reminderId: item.id,
            eventId: eventId(340 + index),
            expectedRevision: item.revision,
            action: ReminderMutationAction.restoreFromTrash,
          ),
        );
        expect(restored.status, original.status);
        expect(restored.nextAttentionAt, original.nextAttentionAt);
        expect(restored.allDayLocalDate, original.allDayLocalDate);
        expect(restored.outcomeType, original.outcomeType);
        expect(restored.outcomeNote, original.outcomeNote);
        expect(restored.completedAt, original.completedAt);
        expect(restored.cancelledAt, original.cancelledAt);
        index += 1;
      }
      expect(
        notifications.scheduled,
        hasLength(scheduledBeforeRestore),
        reason:
            'all-day, overdue, inbox and terminal restore fake alarm kurmaz',
      );
      expect(await agenda.listReminders(ReminderViewGroup.trash), isEmpty);
      expect(await agenda.listReminders(ReminderViewGroup.inbox), hasLength(1));
      expect(
        await agenda.listReminders(ReminderViewGroup.history),
        hasLength(2),
      );
    },
  );

  test(
    'notification cancel failure keeps trashed persistence authoritative',
    () async {
      final created = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(401),
          title: 'Cancel hatası',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in1Hour,
        ),
      );
      notifications.failCancel = true;
      now = DateTime.utc(2026, 7, 19, 8, 5);
      final trashed = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: created.id,
          eventId: eventId(402),
          expectedRevision: created.revision,
          action: ReminderMutationAction.moveToTrash,
        ),
      );

      expect(trashed.trashedAt, isNotNull);
      expect(
        (await agenda.listReminders(ReminderViewGroup.trash)).single.id,
        created.id,
      );
      final detail = await agenda.getReminderLifecycleDetail(created.id);
      expect(detail.notification.scheduledFor, isNull);
      expect(detail.notification.syncState, NotificationSyncState.failed);
      expect(detail.notification.safeErrorCode, 'cancel_failed');
      expect(
        detail.events.where((item) => item.eventType == 'trashed'),
        hasLength(1),
      );
    },
  );
}

class _FakeNotificationGateway
    implements ReminderNotificationGateway, ReminderDeliveryControl {
  NotificationPermissionState permission = NotificationPermissionState.granted;
  bool failSchedule = false;
  bool failCancel = false;
  bool failInitialize = false;
  bool omitPendingAfterSchedule = false;
  int requestCalls = 0;
  final List<ReminderNotificationRequest> scheduled = [];
  final List<ReminderNotificationRequest> fallbackScheduled = [];
  final List<int> cancelled = [];
  final List<PendingReminderNotification> pending = [];
  final StreamController<String> taps = StreamController<String>.broadcast();
  ReminderPlatformDiagnostic diagnostic =
      const ReminderPlatformDiagnostic.unavailable();

  @override
  int maximumPendingNotifications = 60;

  @override
  int pendingNotificationSlotCost(int? repeatIntervalMinutes) => 1;

  @override
  String? initialTapReminderId;

  @override
  Stream<String> get notificationTaps => taps.stream;

  @override
  Future<void> initialize() async {
    if (failInitialize) throw StateError('hidden plugin detail');
  }

  @override
  Future<NotificationPermissionState> permissionStatus() async => permission;

  @override
  Future<NotificationPermissionState> requestPermission() async {
    requestCalls += 1;
    return permission;
  }

  @override
  Future<List<PendingReminderNotification>> pendingNotifications() async =>
      List.unmodifiable(pending);

  @override
  Future<void> schedule(ReminderNotificationRequest request) async {
    if (failSchedule) throw StateError('hidden plugin detail');
    scheduled.add(request);
    if (omitPendingAfterSchedule) return;
    pending.removeWhere((item) => item.platformId == request.platformId);
    pending.add(
      PendingReminderNotification(
        platformId: request.platformId,
        reminderId: request.reminderId,
      ),
    );
  }

  @override
  Future<void> scheduleInexactFallback(
    ReminderNotificationRequest request,
  ) async {
    fallbackScheduled.add(request);
    pending.removeWhere((item) => item.platformId == request.platformId);
    pending.add(
      PendingReminderNotification(
        platformId: request.platformId,
        reminderId: request.reminderId,
      ),
    );
  }

  @override
  Future<ReminderPlatformDiagnostic> deliveryDiagnostic(int platformId) async =>
      diagnostic;

  @override
  Future<void> openBatteryOptimizationSettings() async {}

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> cancel(int platformId) async {
    if (failCancel) throw StateError('hidden cancel failure');
    cancelled.add(platformId);
    pending.removeWhere((item) => item.platformId == platformId);
  }

  Future<void> close() => taps.close();
}

Future<int> _countRows(String path, String table) async {
  final database = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  final count = Sqflite.firstIntValue(
    await database.rawQuery('SELECT COUNT(*) FROM $table'),
  );
  await database.close();
  return count ?? 0;
}

Future<List<int>> _bindingIds(String path) async {
  final database = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  final rows = await database.query(
    'reminder_notification_bindings',
    columns: ['platform_notification_id'],
  );
  await database.close();
  return rows.map((row) => row['platform_notification_id']! as int).toList();
}

int _stablePlatformId(String reminderId) {
  var candidate = 2166136261;
  for (final value in reminderId.codeUnits) {
    candidate ^= value;
    candidate = (candidate * 16777619) & 0x7fffffff;
  }
  return candidate == 0 ? 1 : candidate;
}
