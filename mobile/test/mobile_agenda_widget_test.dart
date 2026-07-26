import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const projectId = '11111111-1111-4111-8111-111111111111';
const logId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const reminderId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';

void main() {
  setUpAll(CseTimeCodec.initialize);

  MobileProject project() => const MobileProject(
    id: projectId,
    name: 'Çok Uzun Kuzey Şantiyesi Proje Adı',
    createdAt: '2026-07-19T08:00:00Z',
    updatedAt: '2026-07-19T08:00:00Z',
    revision: 1,
  );

  AgendaLog log() => const AgendaLog(
    id: logId,
    projectId: projectId,
    projectName: 'Çok Uzun Kuzey Şantiyesi Proje Adı',
    observedAt: '2026-07-19T07:30:00Z',
    createdAt: '2026-07-19T08:00:00Z',
    updatedAt: '2026-07-19T08:00:00Z',
    category: AgendaCategory.inspection,
    description:
        'Uzun Türkçe açıklama: döşeme donatısının bindirme boyları ve pas payları kontrol edildi.',
    location: 'A Blok 12. Kat Kuzey Cephesi',
    notes: 'Ayrıntılı saha notu.',
    revision: 1,
  );

  MobileReminder reminder() => const MobileReminder(
    id: reminderId,
    projectId: projectId,
    projectName: 'Çok Uzun Kuzey Şantiyesi Proje Adı',
    sourceLogId: logId,
    title: 'Donatı kontrol sonucunu tekrar doğrula',
    kind: ReminderKind.recheck,
    status: ReminderStatus.active,
    nextAttentionAt: '2026-07-19T10:00:00Z',
    createdAt: '2026-07-19T08:00:00Z',
    updatedAt: '2026-07-19T08:00:00Z',
    revision: 1,
  );

  testWidgets('Ajanda main action creates and selects a live project', (
    tester,
  ) async {
    final fake = FakeAgendaApplication();
    await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-agenda-project')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('agenda-project-name')),
      'Yeni Saha Projesi',
    );
    await tester.tap(find.byKey(const Key('save-agenda-project')));
    await tester.pumpAndSettle();
    expect(fake.projects.single.name, 'Yeni Saha Projesi');
    expect(find.text('Yeni Saha Projesi'), findsOneWidget);
  });

  testWidgets(
    'Ajanda works at 320 px with filters, long Turkish text and 44 px targets',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakeAgendaApplication(projects: [project()], logs: [log()]);

      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'Geliştirme',
              smokeRecordId: 'mobile-foundation-v1',
              smokeRecordCreatedAt: '2026-07-19T08:00:00Z',
              agenda: fake,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajanda').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('agenda-project-filter')), findsOneWidget);
      expect(find.byKey(const Key('agenda-category-filter')), findsOneWidget);
      expect(find.byKey(const Key('agenda-literal-search')), findsOneWidget);
      expect(find.textContaining('Uzun Türkçe açıklama'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('create-agenda-log'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('log validation keeps every typed field on failure', (
    tester,
  ) async {
    final fake = FakeAgendaApplication(projects: [project()])
      ..createLogFailure = const AgendaValidationFailure(
        'Gelecek tarihli olay kaydedilemez.',
      );
    await tester.pumpWidget(MaterialApp(home: LogFormPage(agenda: fake)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('log-description')),
      'Kullanıcının girdiği açıklama',
    );
    await tester.enterText(
      find.byKey(const Key('log-location')),
      'B Blok çatı mahali',
    );
    await tester.enterText(
      find.byKey(const Key('log-notes')),
      'Klavye açıldığında da korunacak uzun ayrıntılı not.',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('submit-log')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('submit-log')));
    await tester.pumpAndSettle();

    expect(fake.createLogCalls, 1);
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.text('Gelecek tarihli olay kaydedilemez.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('log-description')),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('log-description')))
          .controller!
          .text,
      'Kullanıcının girdiği açıklama',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('log-location')))
          .controller!
          .text,
      'B Blok çatı mahali',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('log-notes')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('log-notes')))
          .controller!
          .text,
      'Klavye açıldığında da korunacak uzun ayrıntılı not.',
    );
  });

  testWidgets(
    'submitting disables double tap while retaining one command UUID',
    (tester) async {
      final completer = Completer<AgendaLog>();
      final fake = FakeAgendaApplication(projects: [project()])
        ..createLogCompleter = completer;
      await tester.pumpWidget(MaterialApp(home: LogFormPage(agenda: fake)));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('log-description')),
        'Tek kayıt',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('submit-log')),
        300,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.tap(find.byKey(const Key('submit-log')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('submit-log')));
      await tester.pump();

      expect(fake.createLogCalls, 1);
      expect(find.text('Kaydediliyor…'), findsOneWidget);
      final commandId = fake.lastLogCommand!.id;
      completer.complete(log());
      await tester.pumpAndSettle();
      expect(fake.lastLogCommand!.id, commandId);
    },
  );

  testWidgets('log and reminder details provide bidirectional navigation', (
    tester,
  ) async {
    final detail = AgendaLogDetail(log: log(), reminders: [reminder()]);
    final fake = FakeAgendaApplication(
      projects: [project()],
      logs: [log()],
      reminders: [reminder()],
      logDetail: detail,
      reminderDetail: reminder(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LogDetailPage(agenda: fake, logId: logId),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(Key('linked-reminder-$reminderId')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pump();
    await tester.tap(find.byKey(Key('linked-reminder-$reminderId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-source-agenda-log')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('open-source-agenda-log')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('open-source-agenda-log')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail-reminder-action')), findsOneWidget);
  });

  testWidgets('reminder text is suggested from log and remains editable', (
    tester,
  ) async {
    final fake = FakeAgendaApplication(projects: [project()], logs: [log()]);
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderFormPage(agenda: fake, log: log()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(log().description), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('reminder-title')),
      'Kullanıcının değiştirdiği reminder metni',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('submit-reminder')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('submit-reminder')));
    await tester.pumpAndSettle();

    expect(fake.createReminderCalls, 1);
    expect(
      fake.lastReminderCommand!.title,
      'Kullanıcının değiştirdiği reminder metni',
    );
    expect(fake.lastReminderCommand!.sourceLogId, logId);
    expect(fake.lastReminderCommand!.projectId, projectId);
  });

  testWidgets(
    'reminder is an accessible AppBar icon and Sil archives then restores',
    (tester) async {
      final fake = FakeAgendaApplication(projects: [project()], logs: [log()]);
      await tester.pumpWidget(
        MaterialApp(
          home: LogDetailPage(agenda: fake, logId: logId),
        ),
      );
      await tester.pumpAndSettle();

      final reminderAction = find.byKey(const Key('detail-reminder-action'));
      expect(reminderAction, findsOneWidget);
      expect(tester.getSize(reminderAction).height, greaterThanOrEqualTo(44));
      expect(find.bySemanticsLabel('Hatırlatıcı oluştur'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Hatırlatıcı oluştur'),
        findsNothing,
      );

      await tester.tap(reminderAction);
      await tester.pumpAndSettle();
      expect(find.byType(ReminderFormPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('archive-agenda-log')));
      await tester.tap(find.byKey(const Key('archive-agenda-log')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Kayıt arşive taşınacak, geri getirilebilir'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirm-archive-log')));
      await tester.pumpAndSettle();
      expect(fake.logs.single.archivedAt, isNotNull);
      expect(find.byKey(const Key('restore-agenda-log')), findsOneWidget);

      await tester.tap(find.byKey(const Key('restore-agenda-log')));
      await tester.pumpAndSettle();
      expect(fake.logs.single.archivedAt, isNull);
      expect(find.byKey(const Key('archive-agenda-log')), findsOneWidget);
    },
  );

  testWidgets('camera denial preserves pending log input and creates no row', (
    tester,
  ) async {
    final fake = FakeAgendaApplication(projects: [project()]);
    final attachments = SafeAttachmentPicker(
      permissions: SafeCapabilityService(_DeniedPermission()),
      picker: _UnexpectedPicker(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LogFormPage(agenda: fake, attachments: attachments),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('log-description')),
      'İzin reddedilse de korunacak saha kaydı',
    );
    await tester.ensureVisible(find.byKey(const Key('log-add-photo')));
    await tester.tap(find.byKey(const Key('log-add-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kamera'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fotoğraf eklenmedi'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('log-description')))
          .controller!
          .text,
      'İzin reddedilse de korunacak saha kaydı',
    );
    expect(fake.logs, isEmpty);
    expect(fake.createLogCalls, 0);
  });
}

class _DeniedPermission implements PermissionGateway {
  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.denied;
}

class _UnexpectedPicker implements AttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) =>
      throw StateError('permission denial must stop before picker');
}
