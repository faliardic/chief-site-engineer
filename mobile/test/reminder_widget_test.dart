import 'dart:async';

import 'package:chief_site_engineer/app.dart';
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
      completer.complete(reminder());
      await tester.pumpAndSettle();
      expect(agenda.lastReminderCommand!.id, commandId);
    },
  );

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
}
