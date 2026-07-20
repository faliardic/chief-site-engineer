import 'dart:async';
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
          action: ReminderMutationAction.startWaiting,
        ),
      );
      expect(reminder.status, ReminderStatus.waiting);
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(7),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.moveToInbox,
        ),
      );
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(8),
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
          eventId: eventId(9),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.reopen,
        ),
      );
      expect(reminder.status, ReminderStatus.inbox);
      final noOp = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(10),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.reopen,
        ),
      );
      expect(noOp.revision, reminder.revision);
      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(11),
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
        'waiting_started',
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
            eventId: eventId(12),
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
          action: ReminderMutationAction.schedule,
          schedule: ReminderScheduleKind.in1Hour,
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
      ReminderScheduleKind.waiting,
    ];
    for (var index = 0; index < schedules.length; index += 1) {
      await agenda.createReminder(
        CreateReminderCommand(
          id: 'eeeeeeee-eeee-4eee-8eee-${index.toString().padLeft(12, '0')}',
          eventId: eventId(100 + index),
          title: 'Sıralı $index',
          kind: schedules[index] == ReminderScheduleKind.waiting
              ? ReminderKind.waiting
              : index == 3
              ? ReminderKind.recheck
              : ReminderKind.action,
          schedule: schedules[index],
          isImportant: index == 2,
        ),
      );
    }
    expect(await agenda.listReminders(ReminderViewGroup.inbox), hasLength(1));
    expect(await agenda.listReminders(ReminderViewGroup.today), hasLength(2));
    expect(await agenda.listReminders(ReminderViewGroup.waiting), hasLength(1));
    expect(await agenda.listReminders(ReminderViewGroup.recheck), hasLength(1));
    expect(
      await agenda.listReminders(ReminderViewGroup.upcoming),
      hasLength(2),
    );
  });
}

class _FakeNotificationGateway
    implements ReminderNotificationGateway, ReminderDeliveryControl {
  NotificationPermissionState permission = NotificationPermissionState.granted;
  bool failSchedule = false;
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
