import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const reminderId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

MobileReminder reminder({ReminderStatus status = ReminderStatus.active}) =>
    MobileReminder(
      id: reminderId,
      projectId: null,
      projectName: null,
      sourceLogId: null,
      captureText: 'Mobil hızlı yakalama',
      title: 'Mobil hızlı yakalama',
      kind: ReminderKind.action,
      status: status,
      nextAttentionAt: status == ReminderStatus.inbox
          ? null
          : '2026-07-20T06:00:00Z',
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      revision: 1,
    );

void main() {
  testWidgets('+ Unutma is usable at 320 px with 44 px targets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final agenda = FakeAgendaApplication();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: agenda)),
      ),
    );
    await tester.pumpAndSettle();
    final quick = find.byKey(const Key('quick-reminder'));
    expect(quick, findsOneWidget);
    expect(tester.getSize(quick).height, greaterThanOrEqualTo(44));

    await tester.tap(quick);
    await tester.pumpAndSettle();
    expect(find.text('+ Unutma'), findsOneWidget);
    expect(find.byKey(const Key('reminder-title')), findsOneWidget);
    final submit = find.byKey(const Key('submit-reminder'));
    await tester.ensureVisible(submit);
    expect(tester.getSize(submit).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'quick capture preserves input on validation/application failure',
    (tester) async {
      final agenda = FakeAgendaApplication()
        ..createReminderFailure = const AgendaValidationFailure(
          'Kontrollü hata',
        );
      await tester.pumpWidget(
        MaterialApp(home: ReminderFormPage(agenda: agenda)),
      );
      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'Kullanıcının korunacak metni',
      );
      final submit = find.byKey(const Key('submit-reminder'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Kontrollü hata'), findsOneWidget);
      expect(find.text('Kullanıcının korunacak metni'), findsOneWidget);
      expect(agenda.createReminderCalls, 1);
    },
  );

  testWidgets(
    'quick capture disables duplicate submit while command is pending',
    (tester) async {
      final completer = Completer<MobileReminder>();
      final agenda = FakeAgendaApplication()
        ..createReminderCompleter = completer;
      await tester.pumpWidget(
        MaterialApp(home: ReminderFormPage(agenda: agenda)),
      );
      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'Tek kez oluştur',
      );
      final submit = find.byKey(const Key('submit-reminder'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      await tester.tap(submit);
      await tester.pump();

      expect(agenda.createReminderCalls, 1);
      final commandId = agenda.lastReminderCommand!.id;
      final completed = reminder();
      agenda.reminders = [completed];
      completer.complete(completed);
      await tester.pumpAndSettle();
      expect(agenda.lastReminderCommand!.id, commandId);
    },
  );

  testWidgets('scheduled capture never hides native delivery failure', (
    tester,
  ) async {
    final agenda = _UnverifiedCreationAgenda();
    await tester.pumpWidget(
      MaterialApp(home: ReminderFormPage(agenda: agenda)),
    );
    await tester.enterText(
      find.byKey(const Key('reminder-title')),
      'Teslimatı doğrulanacak kayıt',
    );
    await tester.tap(find.byKey(const Key('submit-reminder')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-delivery-warning')), findsOneWidget);
    expect(find.text('Kayıt oluşturuldu'), findsOneWidget);
    expect(agenda.createReminderCalls, 1);
    await tester.tap(find.text('Anladım'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Yarın quick action is guarded against double tap', (
    tester,
  ) async {
    final completer = Completer<MobileReminder>();
    final item = reminder();
    final agenda = FakeAgendaApplication(reminders: [item])
      ..mutateReminderCompleter = completer;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: agenda)),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(Key('reminder-tomorrow-${item.id}'));
    expect(action, findsOneWidget);
    await tester.tap(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pump();
    expect(agenda.mutateReminderCalls, 1);
    expect(
      agenda.lastMutationCommand!.action,
      ReminderMutationAction.snoozeTomorrowMorning,
    );
    completer.complete(item);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'notification launch payload opens the matching reminder detail',
    (tester) async {
      final item = reminder();
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
        initialNotificationReminderId: reminderId,
      );
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'test',
              smokeRecordId: 'foundation',
              smokeRecordCreatedAt: '2026-07-19T08:00:00Z',
              agenda: agenda,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReminderDetailPage), findsOneWidget);
      expect(find.byKey(const Key('reminder-detail')), findsOneWidget);
      expect(find.text('Mobil hızlı yakalama'), findsWidgets);
    },
  );

  testWidgets('lifecycle operations remain reachable with long Turkish text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = reminder();
    final agenda = FakeAgendaApplication(
      reminders: [item],
      reminderDetail: item,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
      ),
    );
    await tester.pumpAndSettle();
    final complete = find.byKey(const Key('complete-reminder'));
    expect(complete, findsOneWidget);
    await tester.ensureVisible(complete);
    expect(tester.getSize(complete).height, greaterThanOrEqualTo(44));
    expect(find.byKey(const Key('schedule-reminder')), findsOneWidget);
    expect(find.byKey(const Key('start-waiting')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivery diagnostic exposes retry and user-opened settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = reminder();
    final agenda = _DeliveryAgenda(item);
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('reminder-delivery-diagnostic')),
      findsOneWidget,
    );
    expect(find.text('Arka plan teslimatı garanti edilemiyor'), findsOneWidget);
    expect(
      find.textContaining('Android Zorla durdur işlemi'),
      findsOneWidget,
    );
    final notificationSettings = find.byKey(
      const Key('open-notification-settings'),
    );
    await tester.ensureVisible(notificationSettings);
    await tester.tap(notificationSettings);
    await tester.pump();
    final batterySettings = find.byKey(const Key('open-battery-settings'));
    await tester.ensureVisible(batterySettings);
    await tester.tap(batterySettings);
    await tester.pump();
    final retry = find.byKey(const Key('retry-reminder-delivery'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(agenda.notificationSettingsCalls, 1);
    expect(agenda.batterySettingsCalls, 1);
    expect(agenda.retryCalls, 1);
    expect(tester.takeException(), isNull);
  });
}

class _DeliveryAgenda extends FakeAgendaApplication
    implements ReminderDeliveryApplication {
  _DeliveryAgenda(MobileReminder reminder)
    : super(reminders: [reminder], reminderDetail: reminder);

  int retryCalls = 0;
  int notificationSettingsCalls = 0;
  int batterySettingsCalls = 0;

  @override
  Future<ReminderDeliveryDiagnostic> getReminderDeliveryDiagnostic(
    String reminderId,
  ) async => const ReminderDeliveryDiagnostic(
    safeReminderId: 'cccccccc',
    scheduleKind: 'one_shot',
    canonicalDueAt: '2026-07-20T06:00:00Z',
    nativeSchedulePresent: false,
    lastReconciledAt: '2026-07-19T08:00:00Z',
    permissionState: 'granted',
    channelState: 'enabled',
    exactAlarmState: 'denied',
    batteryOptimizationState: 'optimized',
    backgroundRestrictionState: 'allowed',
    standbyBucket: 'rare',
    bootRescheduleState: 'not_observed',
    bootRescheduledAt: null,
    deliveredAt: null,
    delayClass: ReminderDeliveryDelayClass.nativeScheduleMissing,
    safeErrorCode: 'exact_alarm_permission_required',
  );

  @override
  Future<void> retryReminderDelivery(String reminderId) async {
    retryCalls += 1;
  }

  @override
  Future<void> openReminderNotificationSettings() async {
    notificationSettingsCalls += 1;
  }

  @override
  Future<void> openReminderBatteryOptimizationSettings() async {
    batterySettingsCalls += 1;
  }
}

class _UnverifiedCreationAgenda extends FakeAgendaApplication {
  @override
  Future<ReminderDetail> getReminderLifecycleDetail(String reminderId) async {
    final detail = await super.getReminderLifecycleDetail(reminderId);
    return ReminderDetail(
      reminder: detail.reminder,
      events: detail.events,
      notification: NotificationBinding(
        reminderId: reminderId,
        platformNotificationId: 202,
        scheduledFor: detail.reminder.nextAttentionAt,
        syncState: NotificationSyncState.failed,
        lastSyncedAt: detail.reminder.updatedAt,
        safeErrorCode: 'native_schedule_failed',
      ),
    );
  }
}
