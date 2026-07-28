import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_destination_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const projectId = '11111111-1111-4111-8111-111111111111';
const logId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const reminderId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const pourId = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';

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

  AgendaLog concreteSignalLog({
    AgendaCategory category = AgendaCategory.inspection,
  }) => AgendaLog(
    id: logId,
    projectId: projectId,
    projectName: 'Çok Uzun Kuzey Şantiyesi Proje Adı',
    observedAt: '2026-07-19T07:30:00Z',
    createdAt: '2026-07-19T08:00:00Z',
    updatedAt: '2026-07-19T08:00:00Z',
    category: category,
    description: 'Yarın beton dökülecek.',
    location: 'A Blok 12. Kat Kuzey Cephesi',
    notes: 'Pompa erişimi ayrıca kontrol edilecek.',
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

  testWidgets(
    'Beton suggestion can be ignored and fail-soft save keeps text and category',
    (tester) async {
      final fake = FakeAgendaApplication(projects: [project()]);
      await tester.pumpWidget(MaterialApp(home: LogFormPage(agenda: fake)));
      await tester.pumpAndSettle();

      const description = 'Yarın beton dökülecek.';
      await tester.enterText(
        find.byKey(const Key('log-description')),
        description,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('agenda-concrete-form-suggestion')),
        300,
        scrollable: find.byType(Scrollable).last,
      );

      expect(
        find.text('Bu kayıt Beton işiyle ilgili görünüyor.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('agenda-concrete-form-open')), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('log-description')))
            .controller!
            .text,
        description,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('submit-log')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('submit-log')));
      await tester.pumpAndSettle();

      expect(fake.createLogCalls, 1);
      expect(fake.lastLogCommand?.description, description);
      expect(fake.lastLogCommand?.category, AgendaCategory.generalNote);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'form deep-link preserves the exact draft and creates no records',
    (tester) async {
      tester.view.physicalSize = const Size(320, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakeAgendaApplication(projects: [project()]);
      final concrete = _RecordingConcrete();
      final attachments = SafeAttachmentPicker(
        permissions: SafeCapabilityService(_GrantedPermission()),
        picker: _SelectedPicker(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: LogFormPage(
              agenda: fake,
              attachments: attachments,
              concrete: concrete,
              concreteAttachments: attachments,
              initialProjectId: projectId,
              initialIstanbulDay: '2026-07-19',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final formListView = find.descendant(
        of: find.byType(LogFormPage),
        matching: find.byType(ListView),
      );
      expect(formListView, findsOneWidget);
      final formScrollable = find
          .descendant(of: formListView, matching: find.byType(Scrollable))
          .first;
      expect(formScrollable, findsOneWidget);

      const description = 'Beton dökümü yarın başlayacak.';
      const location = 'B Blok temel';
      const notes = 'Betonaj öncesi pompa yolu açık tutulacak.';
      await tester.enterText(
        find.byKey(const Key('log-description')),
        description,
      );
      final categoryField = find.byType(
        DropdownButtonFormField<AgendaCategory>,
      );
      expect(
        tester.state<FormFieldState<AgendaCategory>>(categoryField).value,
        AgendaCategory.generalNote,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('agenda-concrete-form-suggestion')),
        300,
        scrollable: formScrollable,
      );
      expect(
        tester
            .getSize(find.byKey(const Key('agenda-concrete-select-category')))
            .height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('agenda-concrete-form-open')))
            .height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(
        find.byKey(const Key('agenda-concrete-select-category')),
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('log-category')),
        -300,
        scrollable: formScrollable,
      );
      expect(
        tester.state<FormFieldState<AgendaCategory>>(categoryField).value,
        AgendaCategory.concrete,
      );
      expect(fake.createLogCalls, 0);

      await tester.scrollUntilVisible(
        find.byKey(const Key('log-location')),
        -300,
        scrollable: formScrollable,
      );
      await tester.enterText(find.byKey(const Key('log-location')), location);
      await tester.enterText(find.byKey(const Key('log-notes')), notes);
      await tester.scrollUntilVisible(
        find.byKey(const Key('log-add-photo')),
        -300,
        scrollable: formScrollable,
      );
      await tester.tap(find.byKey(const Key('log-add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sistem fotoğraf seçici'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pending-log-photo-0')), findsOneWidget);

      final openConcreteAction = find.byKey(
        const Key('agenda-concrete-form-open'),
      );
      await tester.scrollUntilVisible(
        openConcreteAction,
        300,
        scrollable: formScrollable,
      );
      await Scrollable.ensureVisible(
        tester.element(openConcreteAction),
        alignment: 0.5,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      expect(openConcreteAction, findsOneWidget);
      expect(openConcreteAction.hitTestable(), findsOneWidget);
      await tester.tap(openConcreteAction);
      await tester.pumpAndSettle();

      expect(find.byType(ConcreteDestinationPage), findsOneWidget);
      expect(concrete.lastListQuery?.projectId, projectId);
      expect(concrete.lastListQuery?.istanbulDay, '2026-07-19');
      expect(concrete.lastListQuery?.group, ConcretePourGroup.today);
      expect(fake.createLogCalls, 0);
      expect(concrete.createPourCalls, 0);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('log-category')),
        -300,
        scrollable: formScrollable,
      );
      expect(
        tester.state<FormFieldState<AgendaCategory>>(categoryField).value,
        AgendaCategory.concrete,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('log-description')),
        300,
        scrollable: formScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('log-description')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('log-description')))
            .controller!
            .text,
        description,
      );
      final locationField = find.byKey(const Key('log-location'));
      await tester.scrollUntilVisible(
        locationField,
        200,
        scrollable: formScrollable,
      );
      await tester.pumpAndSettle();
      expect(locationField, findsOneWidget);
      expect(
        tester.widget<TextFormField>(locationField).controller!.text,
        location,
      );
      final notesField = find.byKey(const Key('log-notes'));
      await tester.scrollUntilVisible(
        notesField,
        200,
        scrollable: formScrollable,
      );
      await tester.pumpAndSettle();
      expect(notesField, findsOneWidget);
      expect(tester.widget<TextFormField>(notesField).controller!.text, notes);
      await tester.scrollUntilVisible(
        find.byKey(const Key('pending-log-photo-0')),
        -300,
        scrollable: formScrollable,
      );
      expect(find.byKey(const Key('pending-log-photo-0')), findsOneWidget);
      final dateButton = find.byKey(const Key('log-date'));
      await tester.scrollUntilVisible(
        dateButton,
        -300,
        scrollable: formScrollable,
      );
      await tester.pumpAndSettle();
      expect(dateButton, findsOneWidget);
      expect(
        find.descendant(of: dateButton, matching: find.text('19.07.2026')),
        findsOneWidget,
      );
      expect(fake.createLogCalls, 0);
      expect(concrete.createPourCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unmanaged signal detail is fail-soft without Concrete dependencies',
    (tester) async {
      final signalLog = concreteSignalLog();
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: [signalLog],
        logDetail: AgendaLogDetail(log: signalLog, reminders: const []),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LogDetailPage(agenda: fake, logId: logId),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Bu kayıt Beton işiyle ilgili olabilir.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('agenda-concrete-detail-open')),
        findsNothing,
      );
      expect(find.text(signalLog.description), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unmanaged detail deep-links with the log project and Istanbul day',
    (tester) async {
      final signalLog = concreteSignalLog();
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: [signalLog],
        logDetail: AgendaLogDetail(log: signalLog, reminders: const []),
      );
      final concrete = _RecordingConcrete();
      final attachments = SafeAttachmentPicker(
        permissions: SafeCapabilityService(_GrantedPermission()),
        picker: _SelectedPicker(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LogDetailPage(
            agenda: fake,
            concrete: concrete,
            concreteAttachments: attachments,
            logId: logId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final openAction = find.byKey(const Key('agenda-concrete-detail-open'));
      expect(tester.getSize(openAction).height, greaterThanOrEqualTo(44));
      await tester.tap(openAction);
      await tester.pumpAndSettle();

      expect(find.byType(ConcreteDestinationPage), findsOneWidget);
      expect(concrete.lastListQuery?.projectId, projectId);
      expect(concrete.lastListQuery?.istanbulDay, '2026-07-19');
      expect(concrete.lastListQuery?.group, ConcretePourGroup.today);
      expect(concrete.createPourCalls, 0);
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

  testWidgets(
    'managed concrete Agenda detail is read-only and deep-links to package',
    (tester) async {
      final managed = AgendaLogDetail(
        log: concreteSignalLog(category: AgendaCategory.concrete),
        reminders: const [],
        managedConcretePourId: pourId,
      );
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: [log()],
        logDetail: managed,
      );
      final attachments = SafeAttachmentPicker(
        permissions: SafeCapabilityService(_DeniedPermission()),
        picker: _UnexpectedPicker(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LogDetailPage(
            agenda: fake,
            concrete: _NoopConcrete(),
            concreteAttachments: attachments,
            logId: logId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beton paketi tarafından yönetiliyor'), findsOneWidget);
      expect(
        find.byKey(const Key('agenda-concrete-detail-suggestion')),
        findsNothing,
      );
      expect(find.byKey(const Key('edit-agenda-log')), findsNothing);
      expect(find.byKey(const Key('archive-agenda-log')), findsNothing);
      expect(find.byKey(const Key('detail-reminder-action')), findsNothing);
      await tester.tap(find.byKey(const Key('managed-concrete-agenda')));
      await tester.pumpAndSettle();
      expect(find.byType(ConcretePourDetailPage), findsOneWidget);
    },
  );

  testWidgets(
    'Ajanda detail return keeps route-local filters search and scroll after reload',
    (tester) async {
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final logs = List.generate(24, _navigationLog);
      final fake = _DelayedAgendaApplication(projects: [project()], logs: logs);
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('next-day')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agenda-project-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(project().name).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agenda-category-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AgendaCategory.inspection.label).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('agenda-literal-search')),
        'CSE264 arama',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      final target = logs[18];
      final targetFinder = find.byKey(Key('agenda-log-${target.id}'));
      await tester.scrollUntilVisible(
        targetFinder,
        420,
        scrollable: _scrollableFor(find.byKey(const Key('agenda-day-list'))),
      );
      final before = _scrollOffset(tester, const Key('agenda-day-list'));
      expect(before, greaterThan(300));

      await tester.tap(targetFinder);
      await tester.pumpAndSettle();
      fake.logs = [
        for (var index = 0; index < logs.length; index++)
          index == 18
              ? _navigationLog(
                  index,
                  description: 'CSE264 güncel Ajanda açıklaması',
                )
              : logs[index],
      ];
      final delayedReload = Completer<List<AgendaLog>>();
      fake.delayedAgendaReload = delayedReload;
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 350));
      delayedReload.complete(fake.logs);
      await tester.pumpAndSettle();

      final after = _scrollOffset(tester, const Key('agenda-day-list'));
      expect(after, closeTo(before, 4));
      expect(fake.lastAgendaQuery?.projectId, projectId);
      expect(fake.lastAgendaQuery?.category, AgendaCategory.inspection);
      expect(fake.lastAgendaQuery?.literalSearch, 'CSE264 arama');
      expect(find.text('CSE264 güncel Ajanda açıklaması'), findsOneWidget);
      tester
          .state<ScrollableState>(
            _scrollableFor(find.byKey(const Key('agenda-day-list'))),
          )
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'CSE264 arama',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ajanda detail navigation blocks duplicate tap and disposes safely',
    (tester) async {
      final observer = _PushCountingObserver();
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: [_navigationLog(0)],
      );
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: AgendaPage(agenda: fake),
        ),
      );
      await tester.pumpAndSettle();
      observer.pushes = 0;
      final card = find.byKey(Key('agenda-log-${fake.logs.single.id}'));

      final onTap = tester
          .widget<InkWell>(
            find.descendant(of: card, matching: find.byType(InkWell)),
          )
          .onTap!;
      onTap();
      onTap();
      await tester.pumpAndSettle();

      expect(observer.pushes, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('two Ajanda route instances keep isolated scroll state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final logs = List.generate(18, _navigationLog);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: KeyedSubtree(
                  key: const Key('agenda-instance-one'),
                  child: AgendaPage(
                    agenda: FakeAgendaApplication(
                      projects: [project()],
                      logs: logs,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: KeyedSubtree(
                  key: const Key('agenda-instance-two'),
                  child: AgendaPage(
                    agenda: FakeAgendaApplication(
                      projects: [project()],
                      logs: logs,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final firstList = find.descendant(
      of: find.byKey(const Key('agenda-instance-one')),
      matching: find.byKey(const Key('agenda-day-list')),
    );

    await tester.drag(firstList, const Offset(0, -520));
    await tester.pumpAndSettle();

    expect(
      _scrollOffsetWithin(tester, const Key('agenda-instance-one')),
      greaterThan(200),
    );
    expect(
      _scrollOffsetWithin(tester, const Key('agenda-instance-two')),
      closeTo(0, 0.1),
    );
    expect(tester.takeException(), isNull);
  });

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

double _scrollOffset(WidgetTester tester, Key listKey) {
  final scrollable = _scrollableFor(find.byKey(listKey));
  return tester.state<ScrollableState>(scrollable).position.pixels;
}

Finder _scrollableFor(Finder list) =>
    find.descendant(of: list, matching: find.byType(Scrollable)).first;

double _scrollOffsetWithin(WidgetTester tester, Key instanceKey) {
  final list = find.descendant(
    of: find.byKey(instanceKey),
    matching: find.byKey(const Key('agenda-day-list')),
  );
  final scrollable = _scrollableFor(list);
  return tester.state<ScrollableState>(scrollable).position.pixels;
}

AgendaLog _navigationLog(int index, {String? description}) => AgendaLog(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-${(index + 100).toString().padLeft(12, '0')}',
  projectId: projectId,
  projectName: 'Çok Uzun Kuzey Şantiyesi Proje Adı',
  observedAt: '2026-07-19T07:30:00Z',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  category: AgendaCategory.inspection,
  description: description ?? 'CSE264 Ajanda sentetik kayıt $index',
  location: 'CSE264 kat ${index + 1}',
  notes: 'CSE264 route-local fixture',
  revision: 1,
);

class _DelayedAgendaApplication extends FakeAgendaApplication {
  _DelayedAgendaApplication({required super.projects, required super.logs});

  Completer<List<AgendaLog>>? delayedAgendaReload;
  AgendaQuery? lastAgendaQuery;

  @override
  Future<List<AgendaLog>> listAgenda(AgendaQuery query) async {
    lastAgendaQuery = query;
    final delayed = delayedAgendaReload;
    if (delayed != null) {
      delayedAgendaReload = null;
      return delayed.future;
    }
    return super.listAgenda(query);
  }
}

class _PushCountingObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes += 1;
    super.didPush(route, previousRoute);
  }
}

class _DeniedPermission implements PermissionGateway {
  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.denied;
}

class _GrantedPermission implements PermissionGateway {
  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.granted;
}

class _SelectedPicker implements AttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async =>
      SelectedAttachment(
        name: 'beton-hazirlik.jpg',
        bytes: const [0xff, 0xd8, 0xff, 0xd9],
        source: source,
      );
}

class _UnexpectedPicker implements AttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) =>
      throw StateError('permission denial must stop before picker');
}

class _NoopConcrete implements ConcreteApplication {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingConcrete implements ConcreteApplication {
  ConcretePourQuery? lastListQuery;
  int createPourCalls = 0;

  @override
  Future<List<ConcretePour>> listPours(ConcretePourQuery query) async {
    lastListQuery = query;
    return const [];
  }

  @override
  Future<ConcretePourDetail> createPour(
    CreateConcretePourCommand command,
  ) async {
    createPourCalls += 1;
    throw StateError('Deep-link must not create a Concrete package.');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
