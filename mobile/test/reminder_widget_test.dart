import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_photo_viewer_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const reminderId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

String widgetReminderId(int value) =>
    'dddddddd-dddd-4ddd-8ddd-${value.toString().padLeft(12, '0')}';

MobileReminder reminder({
  String id = reminderId,
  String title = 'Mobil hızlı yakalama',
  ReminderStatus status = ReminderStatus.active,
  String? nextAttentionAt,
  String? allDayLocalDate,
  String? trashedAt,
  bool isImportant = false,
  String? projectId,
  String? projectName,
  String? sourceLogId,
}) => MobileReminder(
  id: id,
  projectId: projectId,
  projectName: projectName,
  sourceLogId: sourceLogId,
  captureText: title,
  title: title,
  kind: ReminderKind.action,
  status: status,
  isImportant: isImportant,
  nextAttentionAt: status == ReminderStatus.inbox || allDayLocalDate != null
      ? null
      : nextAttentionAt ?? '2026-07-20T06:00:00Z',
  allDayLocalDate: allDayLocalDate,
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  trashedAt: trashedAt,
  revision: 1,
);

AgendaLogPhoto sourcePhoto({
  required String id,
  required String fileName,
  AgendaAttachmentIntegrity integrity = AgendaAttachmentIntegrity.ok,
  String? description,
}) => AgendaLogPhoto(
  id: id,
  logId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  originalFileName: fileName,
  mimeType: 'image/png',
  byteSize: 68,
  sha256: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  relativePath: 'agenda/source/$id.png',
  description: description,
  capturedAt: '2026-07-20T06:00:00Z',
  revision: 1,
  createdAt: '2026-07-20T06:00:00Z',
  updatedAt: '2026-07-20T06:00:00Z',
  archivedAt: null,
  integrity: integrity,
);

StoredAttachmentContent sourcePhotoContent(String fileName) =>
    StoredAttachmentContent(
      fileName: fileName,
      mimeType: 'image/png',
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
        '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
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
    'form exposes quick Bugün and true Tam gün without waiting or fake time',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final agenda = FakeAgendaApplication();
      await tester.pumpWidget(
        MaterialApp(home: ReminderFormPage(agenda: agenda)),
      );
      expect(find.text('Bekliyorum'), findsNothing);
      expect(find.byKey(const Key('reminder-today')), findsOneWidget);
      expect(find.byKey(const Key('reminder-all-day')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'Bugün tam gün saha turu',
      );
      await tester.tap(find.byKey(const Key('reminder-today')));
      await tester.pump();
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('reminder-all-day')))
            .value,
        isTrue,
      );
      expect(find.byKey(const Key('reminder-custom-date')), findsOneWidget);
      expect(find.byKey(const Key('reminder-custom-time')), findsNothing);

      final submit = find.byKey(const Key('submit-reminder'));
      await tester.scrollUntilVisible(
        submit,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(agenda.lastReminderCommand!.allDayLocalDate, isNotNull);
      expect(agenda.lastReminderCommand!.customAttentionAt, isNull);
      expect(agenda.lastReminderCommand!.kind, ReminderKind.action);
    },
  );

  for (final schedule in [
    ReminderScheduleKind.in2Hours,
    ReminderScheduleKind.in3Hours,
  ]) {
    testWidgets(
      'form selects ${schedule.label} at 320 px with large dark text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final agenda = FakeAgendaApplication();
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: MaterialApp(
              theme: ThemeData(brightness: Brightness.dark),
              home: ReminderFormPage(agenda: agenda),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('reminder-schedule')));
        await tester.pumpAndSettle();
        final option = find.text(schedule.label).last;
        expect(option, findsOneWidget);
        await tester.tap(option);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('reminder-title')),
          '${schedule.label} sonra kontrol',
        );
        final submit = find.byKey(const Key('submit-reminder'));
        await tester.scrollUntilVisible(
          submit,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(submit);
        await tester.pumpAndSettle();

        expect(agenda.lastReminderCommand!.schedule, schedule);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Today is default and renders overdue timed and all-day sections once',
    (tester) async {
      final overdue = reminder(
        id: widgetReminderId(1),
        title: 'Geciken kontrol',
        nextAttentionAt: '2026-07-20T04:00:00Z',
      );
      final timed = reminder(
        id: widgetReminderId(2),
        title: 'Saatli kontrol',
        nextAttentionAt: '2026-07-20T06:00:00Z',
      );
      final allDay = reminder(
        id: widgetReminderId(3),
        title: 'Tam gün kontrol',
        allDayLocalDate: '2026-07-20',
      );
      final agenda = FakeAgendaApplication(
        reminders: [overdue, timed, allDay],
        todayOverview: ReminderTodayOverview(
          istanbulDay: '2026-07-20',
          overdue: [overdue],
          timedToday: [timed],
          allDayToday: [allDay],
          inboxCount: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RemindersPage(agenda: agenda)),
        ),
      );
      await tester.pumpAndSettle();

      expect(agenda.todayOverviewCalls, 1);
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const Key('reminder-primary-today')))
            .selected,
        isTrue,
      );
      expect(find.byKey(const Key('reminder-section-overdue')), findsOneWidget);
      expect(
        find.byKey(const Key('reminder-section-timed-today')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reminder-section-all-day')), findsOneWidget);
      expect(find.byKey(Key('reminder-${overdue.id}')), findsOneWidget);
      expect(find.byKey(Key('reminder-${timed.id}')), findsOneWidget);
      expect(find.byKey(Key('reminder-${allDay.id}')), findsOneWidget);
      expect(
        find.textContaining('Gecikti • 20.07.2026 07:00:00'),
        findsOneWidget,
      );
      expect(find.textContaining('Bugün • 09:00'), findsOneWidget);
      expect(find.textContaining('Yarın •'), findsNothing);
      expect(find.byKey(Key('reminder-tomorrow-${allDay.id}')), findsOneWidget);
    },
  );

  testWidgets('Today hides empty sections and uses one simple empty state', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication(
      todayOverview: const ReminderTodayOverview(
        istanbulDay: '2026-07-20',
        overdue: [],
        timedToday: [],
        allDayToday: [],
        inboxCount: 0,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: agenda)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-today-empty')), findsOneWidget);
    expect(find.text('Bugün için açık hatırlatıcı yok.'), findsOneWidget);
    expect(find.byKey(const Key('reminder-section-overdue')), findsNothing);
    expect(find.byKey(const Key('reminder-section-timed-today')), findsNothing);
    expect(find.byKey(const Key('reminder-section-all-day')), findsNothing);
  });

  testWidgets('Other menu keeps secondary views and inbox count reachable', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication(
      todayOverview: const ReminderTodayOverview(
        istanbulDay: '2026-07-20',
        overdue: [],
        timedToday: [],
        allDayToday: [],
        inboxCount: 3,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: agenda)),
      ),
    );
    await tester.pumpAndSettle();

    final inboxAction = find.byKey(const Key('reminder-inbox-count'));
    expect(inboxAction, findsOneWidget);
    expect(tester.getSize(inboxAction).height, greaterThanOrEqualTo(44));
    await tester.tap(inboxAction);
    await tester.pumpAndSettle();
    expect(agenda.lastReminderGroup, ReminderViewGroup.inbox);
    expect(find.text('Unutma Kutusu'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reminder-primary-other')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reminder-other-menu')), findsOneWidget);
    for (final group in [
      ReminderViewGroup.upcoming,
      ReminderViewGroup.inbox,
      ReminderViewGroup.recheck,
      ReminderViewGroup.history,
      ReminderViewGroup.trash,
    ]) {
      expect(find.byKey(Key('reminder-other-${group.name}')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('reminder-other-upcoming')));
    await tester.pumpAndSettle();
    expect(agenda.lastReminderGroup, ReminderViewGroup.upcoming);
    expect(find.text('Yaklaşanlar'), findsOneWidget);
  });

  testWidgets('trash view has exact empty state', (tester) async {
    final agenda = FakeAgendaApplication();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: agenda)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reminder-primary-other')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('reminder-other-menu')),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminder-other-trash')));
    await tester.pumpAndSettle();

    expect(agenda.lastReminderGroup, ReminderViewGroup.trash);
    expect(find.text('Geri Dönüşüm Kutusu boş.'), findsOneWidget);
  });

  testWidgets(
    'trash list restores once with preserved summary and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final item = reminder(
        title: 'Geri getirilecek saha kontrolü',
        allDayLocalDate: '2026-07-20',
        trashedAt: '2026-07-20T07:30:00Z',
        projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        projectName: 'Şantiye A',
        sourceLogId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      final agenda = FakeAgendaApplication(reminders: [item]);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: MaterialApp(
            home: Scaffold(body: RemindersPage(agenda: agenda)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reminder-primary-other')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('reminder-other-menu')),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-other-trash')));
      await tester.pumpAndSettle();

      expect(find.text('Geri getirilecek saha kontrolü'), findsOneWidget);
      expect(find.textContaining('Aktif'), findsOneWidget);
      expect(find.textContaining('Tam gün'), findsOneWidget);
      expect(find.textContaining('Taşındı:'), findsOneWidget);
      expect(find.textContaining('Şantiye A • Ajanda'), findsOneWidget);
      final restore = find.byKey(Key('restore-reminder-${item.id}'));
      await tester.ensureVisible(restore);
      expect(tester.getSize(restore).height, greaterThanOrEqualTo(44));
      await tester.tap(restore);
      await tester.pumpAndSettle();

      expect(
        agenda.lastMutationCommand!.action,
        ReminderMutationAction.restoreFromTrash,
      );
      expect(find.text('Geri Dönüşüm Kutusu boş.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('detail Sil confirmation moves record to trash without delete', (
    tester,
  ) async {
    final item = reminder();
    final agenda = FakeAgendaApplication(
      reminders: [item],
      reminderDetail: item,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
      ),
    );
    await tester.pumpAndSettle();

    final trash = find.byKey(const Key('trash-reminder'));
    await tester.scrollUntilVisible(
      trash,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getSize(trash).height, greaterThanOrEqualTo(44));
    await tester.tap(trash);
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcı silinsin mi?'), findsOneWidget);
    expect(find.textContaining('Ajanda, Puantaj veya Beton'), findsOneWidget);
    expect(find.textContaining('geri getirilebilir'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-trash-reminder')));
    await tester.pumpAndSettle();

    expect(
      agenda.lastMutationCommand!.action,
      ReminderMutationAction.moveToTrash,
    );
    expect(find.byKey(const Key('reminder-trashed-at')), findsOneWidget);
    expect(find.byKey(const Key('restore-reminder')), findsOneWidget);
    expect(find.byKey(const Key('edit-reminder')), findsNothing);
  });

  testWidgets('trashed source-linked detail keeps Agenda deep-link', (
    tester,
  ) async {
    final item = reminder(
      trashedAt: '2026-07-20T07:30:00Z',
      projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      projectName: 'Şantiye A',
      sourceLogId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    );
    final photo = sourcePhoto(
      id: widgetReminderId(90),
      fileName: 'trash-kaynak.png',
    );
    final agenda = FakeAgendaApplication(
      reminders: [item],
      reminderDetail: item,
      sourceAgendaMedia: ReminderSourceAgendaMedia.loaded(
        sourceLogId: item.sourceLogId!,
        sourceLogArchivedAt: null,
        photos: [photo],
      ),
      agendaPhotoContents: {
        photo.id: sourcePhotoContent(photo.originalFileName),
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kaynak Ajanda fotoğrafları'), findsOneWidget);
    expect(
      find.byKey(Key('reminder-source-agenda-photo-${photo.id}')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-source-agenda-log')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('open-source-agenda-log')), findsOneWidget);
    expect(find.byKey(const Key('restore-reminder')), findsOneWidget);
    expect(find.byKey(const Key('trash-reminder')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'source Agenda photos show metadata once and open the existing viewer',
    (tester) async {
      final item = reminder(
        projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        projectName: 'Şantiye A',
        sourceLogId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      final photo = sourcePhoto(
        id: widgetReminderId(91),
        fileName: 'donati-kontrol.png',
        description: 'Bindirme boyu kanıtı',
      );
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
        sourceAgendaMedia: ReminderSourceAgendaMedia.loaded(
          sourceLogId: item.sourceLogId!,
          sourceLogArchivedAt: null,
          photos: [photo, photo],
        ),
        agendaPhotoContents: {
          photo.id: sourcePhotoContent(photo.originalFileName),
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
        ),
      );
      await tester.pumpAndSettle();

      final tile = find.byKey(Key('reminder-source-agenda-photo-${photo.id}'));
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(agenda.sourceAgendaMediaCalls, 1);
      expect(find.text('Kaynak Ajanda fotoğrafları'), findsOneWidget);
      expect(find.text(photo.originalFileName), findsOneWidget);
      expect(find.textContaining('Dosya doğrulandı • 68 byte'), findsOneWidget);
      expect(find.textContaining('Bindirme boyu kanıtı'), findsOneWidget);
      expect(tile, findsOneWidget);
      expect(find.byKey(const Key('detail-add-agenda-photo')), findsNothing);
      expect(tester.getSize(tile).height, greaterThanOrEqualTo(44));

      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byType(AgendaPhotoViewerPage), findsOneWidget);
      expect(find.byKey(const Key('agenda-full-photo')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing tampered and invalid MIME photos stay visible with diagnostics',
    (tester) async {
      final item = reminder(
        projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        projectName: 'Şantiye A',
        sourceLogId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      final photos = [
        sourcePhoto(
          id: widgetReminderId(92),
          fileName: 'eksik.png',
          integrity: AgendaAttachmentIntegrity.missing,
        ),
        sourcePhoto(
          id: widgetReminderId(93),
          fileName: 'bozuk.png',
          integrity: AgendaAttachmentIntegrity.tampered,
        ),
        sourcePhoto(
          id: widgetReminderId(94),
          fileName: 'gecersiz.png',
          integrity: AgendaAttachmentIntegrity.invalidMime,
        ),
      ];
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
        sourceAgendaMedia: ReminderSourceAgendaMedia.loaded(
          sourceLogId: item.sourceLogId!,
          sourceLogArchivedAt: null,
          photos: photos,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
        ),
      );
      await tester.pumpAndSettle();

      for (final photo in photos) {
        final tile = find.byKey(
          Key('reminder-source-agenda-photo-${photo.id}'),
        );
        expect(tile, findsOneWidget);
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(find.byType(AgendaPhotoViewerPage), findsOneWidget);
        expect(
          find.textContaining('Tanı: ${photo.integrity.name}'),
          findsOneWidget,
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('reminder-detail')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'source media failure keeps reminder content and safe diagnostic visible',
    (tester) async {
      final item = reminder(
        title: 'Ana detay görünür kalır',
        projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        projectName: 'Şantiye A',
        sourceLogId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
        sourceAgendaMediaFailure: StateError('private database path'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana detay görünür kalır'), findsOneWidget);
      expect(
        find.byKey(const Key('reminder-source-agenda-photos-error')),
        findsOneWidget,
      );
      expect(
        find.textContaining('source_agenda_media_unavailable'),
        findsOneWidget,
      );
      expect(find.textContaining('private database path'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('open-source-agenda-log')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('open-source-agenda-log')), findsOneWidget);
    },
  );

  testWidgets(
    'source photo section is controlled for empty and absent source',
    (tester) async {
      final linked = reminder(
        projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        projectName: 'Şantiye A',
        sourceLogId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      final linkedAgenda = FakeAgendaApplication(
        reminders: [linked],
        reminderDetail: linked,
        sourceAgendaMedia: ReminderSourceAgendaMedia.loaded(
          sourceLogId: linked.sourceLogId!,
          sourceLogArchivedAt: null,
          photos: const [],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: linkedAgenda, reminderId: linked.id),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Kaynak Ajanda kaydında aktif fotoğraf yok.'),
        findsOneWidget,
      );

      final standalone = reminder(id: widgetReminderId(95));
      final standaloneAgenda = FakeAgendaApplication(
        reminders: [standalone],
        reminderDetail: standalone,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(
            key: const ValueKey('standalone-reminder-detail'),
            agenda: standaloneAgenda,
            reminderId: standalone.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kaynak Ajanda fotoğrafları'), findsNothing);
      expect(standaloneAgenda.sourceAgendaMediaCalls, 0);
    },
  );

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

  testWidgets('Yarına ertele quick action is guarded against double tap', (
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
    expect(find.text('Yarına ertele'), findsOneWidget);
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
    'Yarına ertele moves Today card to Tomorrow and stays on Upcoming',
    (tester) async {
      final item = reminder();
      final agenda = FakeAgendaApplication(reminders: [item]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RemindersPage(agenda: agenda)),
        ),
      );
      await tester.pumpAndSettle();

      final todayAction = find.byKey(Key('reminder-tomorrow-${item.id}'));
      expect(todayAction, findsOneWidget);
      expect(find.text('Yarına ertele'), findsOneWidget);
      expect(find.text('Yarın'), findsOneWidget);
      await tester.tap(todayAction);
      await tester.pumpAndSettle();
      expect(agenda.reminders.single.nextAttentionAt, '2026-07-21T06:00:00Z');
      expect(find.byKey(Key('reminder-${item.id}')), findsNothing);

      await tester.tap(find.byKey(const Key('reminder-primary-tomorrow')));
      await tester.pumpAndSettle();
      expect(agenda.lastReminderGroup, ReminderViewGroup.tomorrow);
      expect(find.byKey(Key('reminder-${item.id}')), findsOneWidget);
      expect(find.byKey(Key('reminder-tomorrow-${item.id}')), findsNothing);

      await tester.tap(find.byKey(const Key('reminder-primary-other')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-other-upcoming')));
      await tester.pumpAndSettle();
      final upcomingAction = find.byKey(Key('reminder-tomorrow-${item.id}'));
      expect(upcomingAction, findsOneWidget);
      expect(tester.getSize(upcomingAction).height, greaterThanOrEqualTo(48));
    },
  );

  testWidgets('Yarına ertele card failure uses the standard message', (
    tester,
  ) async {
    final item = reminder();
    final agenda = FakeAgendaApplication(reminders: [item])
      ..mutateReminderFailure = StateError('forced failure');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: agenda)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('reminder-tomorrow-${item.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Hatırlatıcı yarına ertelenemedi.'), findsOneWidget);
    expect(agenda.reminders.single.revision, item.revision);
  });

  testWidgets('Yarın filter has dedicated empty state without diagnostics', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RemindersPage(agenda: agenda)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reminder-primary-tomorrow')));
    await tester.pumpAndSettle();

    expect(agenda.lastReminderGroup, ReminderViewGroup.tomorrow);
    expect(find.text('Yarın için planlanmış hatırlatıcı yok.'), findsOneWidget);
    expect(find.byKey(const Key('reminder-delivery-diagnostic')), findsNothing);
  });

  for (final configuration in [
    (width: 320.0, brightness: Brightness.dark),
    (width: 430.0, brightness: Brightness.light),
  ]) {
    testWidgets('Yarın filter fits ${configuration.width.toInt()} px '
        '${configuration.brightness.name} and opens detail', (tester) async {
      tester.view.physicalSize = Size(configuration.width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final item = reminder();
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: MaterialApp(
            theme: ThemeData(brightness: configuration.brightness),
            home: Scaffold(body: RemindersPage(agenda: agenda)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tomorrowGroup = find.byKey(const Key('reminder-primary-tomorrow'));
      expect(tomorrowGroup, findsOneWidget);
      expect(tester.getSize(tomorrowGroup).height, greaterThanOrEqualTo(48));
      await tester.tap(tomorrowGroup);
      await tester.pumpAndSettle();
      expect(agenda.lastReminderGroup, ReminderViewGroup.tomorrow);
      expect(find.byKey(Key('reminder-tomorrow-${item.id}')), findsNothing);

      final reminderCard = find.byKey(Key('reminder-${item.id}'));
      await tester.ensureVisible(reminderCard);
      await tester.tap(reminderCard);
      await tester.pumpAndSettle();
      expect(find.byType(ReminderDetailPage), findsOneWidget);
      final detailTomorrow = find.byKey(const Key('snooze-tomorrow'));
      await tester.scrollUntilVisible(
        detailTomorrow,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(detailTomorrow, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

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
      final tomorrow = find.byKey(const Key('snooze-tomorrow'));
      await tester.scrollUntilVisible(
        tomorrow,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tomorrow);
      await tester.pumpAndSettle();
      expect(agenda.mutateReminderCalls, 1);
      expect(
        agenda.lastMutationCommand!.action,
        ReminderMutationAction.snoozeTomorrowMorning,
      );
    },
  );

  testWidgets(
    'detail Yarına ertele blocks double tap and keeps stale visible',
    (tester) async {
      final item = reminder();
      final completer = Completer<MobileReminder>();
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
      )..mutateReminderCompleter = completer;
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
        ),
      );
      await tester.pumpAndSettle();
      final tomorrow = find.byKey(const Key('snooze-tomorrow'));
      await tester.scrollUntilVisible(
        tomorrow,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tomorrow);
      await tester.pump();
      await tester.tap(tomorrow, warnIfMissed: false);
      await tester.pump();
      expect(agenda.mutateReminderCalls, 1);
      completer.complete(item);
      await tester.pumpAndSettle();

      agenda
        ..mutateReminderCompleter = null
        ..mutateReminderFailure = const AgendaValidationFailure(
          'Hatırlatıcı başka bir işlemle değişti. Ekranı yenileyin.',
        );
      await tester.scrollUntilVisible(
        tomorrow,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tomorrow);
      await tester.pumpAndSettle();
      expect(agenda.mutateReminderCalls, 2);
      final staleError = find.textContaining('başka bir işlemle değişti');
      await tester.scrollUntilVisible(
        staleError,
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(staleError, findsOneWidget);
      expect(agenda.reminders.single.revision, item.revision);
    },
  );

  testWidgets('detail Yarına ertele failure uses the standard message', (
    tester,
  ) async {
    final item = reminder();
    final agenda = FakeAgendaApplication(
      reminders: [item],
      reminderDetail: item,
    )..mutateReminderFailure = StateError('forced failure');
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
      ),
    );
    await tester.pumpAndSettle();

    final tomorrow = find.byKey(const Key('snooze-tomorrow'));
    await tester.scrollUntilVisible(
      tomorrow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tomorrow);
    await tester.pumpAndSettle();
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcı yarına ertelenemedi.'), findsOneWidget);
    expect(agenda.reminders.single.revision, item.revision);
  });

  for (final quickAction in [
    (
      key: 'snooze-2h',
      label: '2 saat ertele',
      action: ReminderMutationAction.snooze2Hours,
    ),
    (
      key: 'snooze-3h',
      label: '3 saat ertele',
      action: ReminderMutationAction.snooze3Hours,
    ),
  ]) {
    testWidgets('${quickAction.label} is selectable and double-tap safe', (
      tester,
    ) async {
      final item = reminder();
      final completer = Completer<MobileReminder>();
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
      )..mutateReminderCompleter = completer;
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
        ),
      );
      await tester.pumpAndSettle();

      final action = find.byKey(Key(quickAction.key));
      await tester.scrollUntilVisible(
        action,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(action, findsOneWidget);
      expect(find.text(quickAction.label), findsOneWidget);
      await tester.tap(action);
      await tester.pump();
      await tester.tap(action, warnIfMissed: false);
      await tester.pump();

      expect(agenda.mutateReminderCalls, 1);
      expect(agenda.lastMutationCommand!.action, quickAction.action);
      completer.complete(item);
      await tester.pumpAndSettle();
    });
  }

  for (final schedule in [
    ReminderScheduleKind.in2Hours,
    ReminderScheduleKind.in3Hours,
  ]) {
    testWidgets('detail planning sheet selects ${schedule.label}', (
      tester,
    ) async {
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

      final scheduleButton = find.byKey(const Key('schedule-reminder'));
      await tester.scrollUntilVisible(
        scheduleButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(scheduleButton);
      await tester.pumpAndSettle();
      final option = find.text(schedule.label);
      expect(option, findsOneWidget);
      await tester.tap(option);
      await tester.pumpAndSettle();

      expect(
        agenda.lastMutationCommand!.action,
        ReminderMutationAction.schedule,
      );
      expect(agenda.lastMutationCommand!.schedule, schedule);
    });
  }

  for (final configuration in [
    (width: 320.0, brightness: Brightness.dark),
    (width: 430.0, brightness: Brightness.light),
  ]) {
    testWidgets('lifecycle actions fit ${configuration.width.toInt()} px '
        '${configuration.brightness.name} with large Turkish text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(configuration.width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final item = reminder();
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: MaterialApp(
            theme: ThemeData(brightness: configuration.brightness),
            home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final complete = find.byKey(const Key('complete-reminder'));
      await tester.scrollUntilVisible(
        complete,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(complete, findsOneWidget);
      await tester.ensureVisible(complete);
      expect(tester.getSize(complete).height, greaterThanOrEqualTo(44));
      expect(find.byKey(const Key('schedule-reminder')), findsOneWidget);
      expect(find.byKey(const Key('start-waiting')), findsNothing);
      final tomorrow = find.byKey(const Key('snooze-tomorrow'));
      await tester.ensureVisible(tomorrow);
      expect(tester.getSize(tomorrow).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('delivery diagnostic exposes retry and user-opened settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
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

    final diagnosticCard = find.byKey(
      const Key('reminder-delivery-diagnostic'),
    );
    await tester.scrollUntilVisible(
      diagnosticCard,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(diagnosticCard, findsOneWidget);
    expect(find.text('Arka plan teslimatı garanti edilemiyor'), findsOneWidget);
    expect(find.textContaining('Android Zorla durdur işlemi'), findsNothing);
    final notificationSettings = find.byKey(
      const Key('open-notification-settings'),
    );
    await tester.scrollUntilVisible(
      notificationSettings,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(notificationSettings);
    await tester.pump();
    final batterySettings = find.byKey(const Key('open-battery-settings'));
    await tester.scrollUntilVisible(
      batterySettings,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(batterySettings);
    await tester.pump();
    final retry = find.byKey(const Key('retry-reminder-delivery'));
    await tester.scrollUntilVisible(
      retry,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(agenda.notificationSettingsCalls, 1);
    expect(agenda.batterySettingsCalls, 1);
    expect(agenda.retryCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('past active reminder is overdue without critical diagnostic', (
    tester,
  ) async {
    final item = reminder();
    final agenda = _DeliveryAgenda(
      item,
      delayClass: ReminderDeliveryDelayClass.overdue,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-overdue-status')), findsOneWidget);
    expect(find.text('Gecikti'), findsOneWidget);
    expect(find.byKey(const Key('reminder-delivery-diagnostic')), findsNothing);
    expect(find.byKey(const Key('complete-reminder')), findsOneWidget);
    expect(find.byKey(const Key('snooze-tomorrow')), findsOneWidget);
  });

  testWidgets('terminal reminder never shows native-plan diagnostic', (
    tester,
  ) async {
    final item = reminder(status: ReminderStatus.completed);
    final agenda = _DeliveryAgenda(item);
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reopen-reminder')), findsOneWidget);
    expect(find.byKey(const Key('reminder-overdue-status')), findsNothing);
    expect(find.byKey(const Key('reminder-delivery-diagnostic')), findsNothing);
  });

  testWidgets('all-day detail shows local day without delivery diagnostic', (
    tester,
  ) async {
    final item = reminder(allDayLocalDate: '2026-07-20');
    final agenda = _DeliveryAgenda(item);
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-all-day-value')), findsOneWidget);
    expect(find.text('20.07.2026 • Tam gün'), findsOneWidget);
    expect(
      find.text('Tam gün kayıt için saatli native bildirim kurulmaz'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reminder-delivery-diagnostic')), findsNothing);
  });
}

class _DeliveryAgenda extends FakeAgendaApplication
    implements ReminderDeliveryApplication {
  _DeliveryAgenda(
    MobileReminder reminder, {
    this.delayClass = ReminderDeliveryDelayClass.nativeScheduleMissing,
  }) : super(reminders: [reminder], reminderDetail: reminder);

  final ReminderDeliveryDelayClass delayClass;

  int retryCalls = 0;
  int notificationSettingsCalls = 0;
  int batterySettingsCalls = 0;

  @override
  Future<ReminderDeliveryDiagnostic> getReminderDeliveryDiagnostic(
    String reminderId,
  ) async => ReminderDeliveryDiagnostic(
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
    delayClass: delayClass,
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
