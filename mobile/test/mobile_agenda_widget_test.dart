import 'dart:async';
import 'dart:convert';
import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_destination_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
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

  AgendaLog log({String? archivedAt}) => AgendaLog(
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
    archivedAt: archivedAt,
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

  MobileReminder reminder({
    String id = reminderId,
    String title = 'Donatı kontrol sonucunu tekrar doğrula',
    String? trashedAt,
  }) => MobileReminder(
    id: id,
    projectId: projectId,
    projectName: 'Çok Uzun Kuzey Şantiyesi Proje Adı',
    sourceLogId: logId,
    title: title,
    kind: ReminderKind.recheck,
    status: ReminderStatus.active,
    nextAttentionAt: '2026-07-19T10:00:00Z',
    createdAt: '2026-07-19T08:00:00Z',
    updatedAt: '2026-07-19T08:00:00Z',
    trashedAt: trashedAt,
    revision: 1,
  );

  testWidgets('Issue 268 baseline: Ajanda exposes newest-first sort control', (
    tester,
  ) async {
    final fake = FakeAgendaApplication(projects: [project()], logs: [log()]);

    await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agenda-sort-order')), findsOneWidget);
    expect(find.text('En yeni üstte'), findsOneWidget);
  });

  testWidgets('Ajanda changes deterministic card order in both directions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final early = _sortLog(
      1,
      observedAt: '2026-07-19T06:00:00Z',
      description: 'CSE268 erken',
    );
    final middle = _sortLog(
      2,
      observedAt: '2026-07-19T07:30:00Z',
      description: 'CSE268 orta',
    );
    final latest = _sortLog(
      3,
      observedAt: '2026-07-19T09:00:00Z',
      description: 'CSE268 en geç',
    );
    final fake = FakeAgendaApplication(
      projects: [project()],
      logs: [middle, early, latest],
    );

    await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
    await tester.pumpAndSettle();

    expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.newestFirst);
    expect(
      tester.getTopLeft(find.byKey(Key('agenda-log-${latest.id}'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(Key('agenda-log-${middle.id}'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(Key('agenda-log-${middle.id}'))).dy,
      lessThan(tester.getTopLeft(find.byKey(Key('agenda-log-${early.id}'))).dy),
    );

    await tester.tap(find.byKey(const Key('agenda-sort-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('En eski üstte').last);
    await tester.pumpAndSettle();

    expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.oldestFirst);
    expect(
      tester.getTopLeft(find.byKey(Key('agenda-log-${early.id}'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(Key('agenda-log-${middle.id}'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(Key('agenda-log-${middle.id}'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(Key('agenda-log-${latest.id}'))).dy,
      ),
    );

    await tester.tap(find.byKey(const Key('agenda-sort-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('En yeni üstte').last);
    await tester.pumpAndSettle();

    expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.newestFirst);
    expect(
      tester.getTopLeft(find.byKey(Key('agenda-log-${latest.id}'))).dy,
      lessThan(tester.getTopLeft(find.byKey(Key('agenda-log-${early.id}'))).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sort change reloads and safely resets a long list scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fake = FakeAgendaApplication(
      projects: [project()],
      logs: List.generate(30, _navigationLog),
    );

    await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
    await tester.pumpAndSettle();
    final changeSort = tester
        .widget<DropdownButtonFormField<AgendaSortOrder>>(
          find.byKey(const Key('agenda-sort-order')),
        )
        .onChanged!;
    await tester.drag(
      find.byKey(const Key('agenda-day-list')),
      const Offset(0, -1400),
    );
    await tester.pumpAndSettle();
    expect(
      _scrollOffset(tester, const Key('agenda-day-list')),
      greaterThan(500),
    );

    changeSort(AgendaSortOrder.oldestFirst);
    await tester.pumpAndSettle();

    expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.oldestFirst);
    expect(
      _scrollOffset(tester, const Key('agenda-day-list')),
      closeTo(0, 0.1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Agenda sort control is safe at 320 px large text dark theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: AgendaPage(
            agenda: FakeAgendaApplication(projects: [project()], logs: [log()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agenda-sort-order')), findsOneWidget);
    expect(find.text('En yeni üstte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
      expect(find.byKey(const Key('agenda-sort-order')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('agenda-log-$logId')),
        240,
        scrollable: _scrollableFor(find.byKey(const Key('agenda-day-list'))),
      );
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

  testWidgets('new Agenda log keeps every photo from one multi selection', (
    tester,
  ) async {
    final fake = FakeAgendaApplication(projects: [project()]);
    final attachments = SafeAttachmentPicker(
      permissions: SafeCapabilityService(_GrantedPermission()),
      picker: _ManySelectedPicker(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LogFormPage(agenda: fake, attachments: attachments),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('log-description')),
      'Çoklu saha fotoğrafı',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('log-add-photo')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('log-add-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sistem fotoğraf seçici'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pending-log-photo-0')), findsOneWidget);
    expect(find.byKey(const Key('pending-log-photo-1')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('submit-log')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('submit-log')));
    await tester.pumpAndSettle();

    expect(fake.createLogCalls, 1);
    expect(fake.lastLogCommand?.photos.map((item) => item.originalFileName), [
      'bir.jpg',
      'iki.png',
    ]);
  });

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

  testWidgets('Agenda detail explicitly links a healthy catalog image', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fake = _CatalogAgendaFake(
      projects: [project()],
      logs: [log()],
      logDetail: AgendaLogDetail(log: log(), reminders: const []),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LogDetailPage(agenda: fake, logId: logId),
      ),
    );
    await tester.pumpAndSettle();

    final linkButton = find.byKey(
      const Key('detail-link-existing-agenda-photo'),
    );
    await tester.scrollUntilVisible(
      linkButton,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(linkButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('attachment-catalog-project-selector')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const Key(
          'attachment-catalog-item-dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.linkExistingCalls, 1);
    expect(
      fake.lastExistingCommand?.physicalAttachmentId,
      'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    );
    expect(find.text('katalog-fotografi.png'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets(
    'Agenda keeps 0..N cards exact, separates trash and create stays independent',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const secondId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
      const trashId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3';
      final first = reminder();
      final second = reminder(id: secondId, title: 'İkinci aktif takip');
      final trashed = reminder(
        id: trashId,
        title: 'Çöpteki bağlı takip',
        trashedAt: '2026-07-19T09:00:00Z',
      );
      final detail = AgendaLogDetail(
        log: log(),
        reminders: [first, second],
        trashedReminders: [trashed],
      );
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: [log()],
        reminders: [first, second, trashed],
        logDetail: detail,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LogDetailPage(agenda: fake, logId: logId),
        ),
      );
      await tester.pumpAndSettle();

      final createAction = find.byKey(const Key('detail-reminder-action'));
      expect(find.bySemanticsLabel('Hatırlatıcı oluştur'), findsOneWidget);
      await tester.tap(createAction);
      await tester.pumpAndSettle();
      expect(find.byType(ReminderFormPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      final secondCard = find.byKey(const Key('linked-reminder-$secondId'));
      await tester.scrollUntilVisible(
        secondCard,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pump();
      await tester.tap(secondCard);
      await tester.pumpAndSettle();
      expect(find.byType(ReminderDetailPage), findsOneWidget);
      expect(find.text('İkinci aktif takip'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      final trashCard = find.byKey(
        const Key('trashed-linked-reminder-$trashId'),
      );
      await tester.scrollUntilVisible(
        trashCard,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Çöpteki bağlı hatırlatıcılar'), findsOneWidget);
      expect(find.byKey(const Key('linked-reminder-$trashId')), findsNothing);
      await tester.tap(trashCard);
      await tester.pumpAndSettle();
      expect(find.text('Çöpteki bağlı takip'), findsOneWidget);
      expect(find.byKey(const Key('restore-reminder')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'archived Agenda disables create but keeps linked cards visible',
    (tester) async {
      final archived = log(archivedAt: '2026-07-19T09:00:00Z');
      final linked = reminder();
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: [archived],
        reminders: [linked],
        logDetail: AgendaLogDetail(log: archived, reminders: [linked]),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LogDetailPage(agenda: fake, logId: logId),
        ),
      );
      await tester.pumpAndSettle();

      final action = tester.widget<IconButton>(
        find.byKey(const Key('detail-reminder-action')),
      );
      expect(action.tooltip, 'Hatırlatıcı oluştur');
      expect(action.onPressed, isNull);
      expect(find.text('Bu kayıt arşivde'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('linked-reminder-$reminderId')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.byKey(const Key('linked-reminder-$reminderId')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Ajanda detail renders immutable field change history from update events',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const oldestUpdateId = '10000000-0000-4000-8000-000000000002';
      const malformedUpdateId = '10000000-0000-4000-8000-000000000004';
      const newestUpdateId = '10000000-0000-4000-8000-000000000006';
      const replacementProjectId = '22222222-2222-4222-8222-222222222222';
      const longBeforeNotes =
          'Uzun saha notu; kuzey cephedeki donatı bindirmeleri, pas payları ve '
          'kalıp aksları birlikte kontrol edildi.';
      const longAfterDescription =
          'Kalıp ve donatı kontrolü tamamlandı; kuzey cephedeki bütün bindirme '
          'boyları, pas payları ve aks ölçüleri saha ekibiyle yeniden doğrulandı.';
      final events = [
        const AppendOnlyEvent(
          id: '10000000-0000-4000-8000-000000000001',
          recordId: logId,
          projectId: projectId,
          eventType: 'agenda_log.created',
          occurredAt: '2026-07-15T07:00:00Z',
          payloadJson: '{}',
        ),
        AppendOnlyEvent(
          id: oldestUpdateId,
          recordId: logId,
          projectId: projectId,
          eventType: 'agenda_log.updated',
          occurredAt: '2026-07-15T10:00:00Z',
          payloadJson: jsonEncode({
            'before': {
              'project_id': projectId,
              'observed_at': '2026-07-15T08:00:00Z',
              'category': 'inspection',
              'description': 'Aynı kalan açıklama',
              'location': null,
              'notes': longBeforeNotes,
            },
            'after': {
              'project_id': projectId,
              'observed_at': '2026-07-15T09:00:00Z',
              'category': 'safety',
              'description': 'Aynı kalan açıklama',
              'location': 'A Blok 2. Kat',
              'notes': null,
            },
          }),
        ),
        const AppendOnlyEvent(
          id: '10000000-0000-4000-8000-000000000003',
          recordId: logId,
          projectId: projectId,
          eventType: 'agenda_log.photo_attached',
          occurredAt: '2026-07-15T11:00:00Z',
          payloadJson: '{}',
        ),
        const AppendOnlyEvent(
          id: malformedUpdateId,
          recordId: logId,
          projectId: projectId,
          eventType: 'agenda_log.updated',
          occurredAt: 'invalid-event-time',
          payloadJson: '{"before": [], "after": {}}',
        ),
        const AppendOnlyEvent(
          id: '10000000-0000-4000-8000-000000000005',
          recordId: logId,
          projectId: projectId,
          eventType: 'agenda_log.archived',
          occurredAt: '2026-07-15T13:00:00Z',
          payloadJson: '{}',
        ),
        AppendOnlyEvent(
          id: newestUpdateId,
          recordId: logId,
          projectId: projectId,
          eventType: 'agenda_log.updated',
          occurredAt: '2026-07-15T14:30:00Z',
          payloadJson: jsonEncode({
            'before': {
              'project_id': projectId,
              'observed_at': '2026-07-15T09:00:00Z',
              'category': 'safety',
              'description': 'Kalıp kontrolü tamamlandı.',
              'location': 'A Blok 2. Kat',
              'notes': null,
            },
            'after': {
              'project_id': replacementProjectId,
              'observed_at': '2026-07-15T09:00:00Z',
              'category': 'safety',
              'description': longAfterDescription,
              'location': 'A Blok 2. Kat',
              'notes': null,
            },
          }),
        ),
      ];
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: [log()],
        reminders: [reminder()],
        logDetail: AgendaLogDetail(
          log: log(),
          reminders: [reminder()],
          events: events,
        ),
        reminderDetail: reminder(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: LogDetailPage(agenda: fake, logId: logId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('edit-agenda-log')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const Key('edit-agenda-log')), findsOneWidget);
      expect(find.byKey(const Key('archive-agenda-log')), findsOneWidget);
      expect(find.byKey(const Key('detail-reminder-action')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Fotoğraflar'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Bu kayda bağlı fotoğraf yok.'), findsOneWidget);

      const sectionKey = Key('agenda-change-history-section');
      await tester.scrollUntilVisible(
        find.byKey(sectionKey),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      final section = find.byKey(sectionKey);
      final newestCard = find.byKey(
        const Key('agenda-change-history-$newestUpdateId'),
      );
      final malformedCard = find.byKey(
        const Key('agenda-change-history-$malformedUpdateId'),
      );
      final oldestCard = find.byKey(
        const Key('agenda-change-history-$oldestUpdateId'),
      );
      expect(find.text('Değişiklik geçmişi'), findsOneWidget);
      expect(
        find.descendant(of: section, matching: find.byType(Card)),
        findsNWidgets(3),
      );
      expect(newestCard, findsOneWidget);
      expect(malformedCard, findsOneWidget);
      expect(oldestCard, findsOneWidget);
      expect(
        tester.getTopLeft(newestCard).dy,
        lessThan(tester.getTopLeft(malformedCard).dy),
      );
      expect(
        tester.getTopLeft(malformedCard).dy,
        lessThan(tester.getTopLeft(oldestCard).dy),
      );
      expect(
        find.descendant(
          of: newestCard,
          matching: find.text('15.07.2026 17:30:00'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: oldestCard,
          matching: find.text('15.07.2026 13:00:00'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: oldestCard, matching: find.text('Olay zamanı')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: oldestCard,
          matching: find.text('Önce: 15.07.2026 11:00:00'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: oldestCard,
          matching: find.text('Sonra: 15.07.2026 12:00:00'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: oldestCard, matching: find.text('Tür')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: oldestCard, matching: find.text('Önce: Kontrol')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: oldestCard,
          matching: find.text('Sonra: İş güvenliği'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: oldestCard, matching: find.text('Mahal')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: oldestCard, matching: find.text('Önce: —')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: oldestCard,
          matching: find.text('Sonra: A Blok 2. Kat'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: oldestCard, matching: find.text('Ayrıntılı not')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: oldestCard,
          matching: find.text('Önce: $longBeforeNotes'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: oldestCard, matching: find.text('Sonra: —')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: oldestCard, matching: find.text('Açıklama')),
        findsNothing,
      );
      expect(
        find.descendant(of: oldestCard, matching: find.text('Proje kimliği')),
        findsNothing,
      );
      expect(
        find.descendant(of: newestCard, matching: find.text('Açıklama')),
        findsOneWidget,
      );
      final longAfter = find.descendant(
        of: newestCard,
        matching: find.text('Sonra: $longAfterDescription'),
      );
      expect(longAfter, findsOneWidget);
      expect(tester.getSize(longAfter).height, greaterThan(40));
      expect(
        find.descendant(of: newestCard, matching: find.text('Proje kimliği')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: newestCard,
          matching: find.text('Önce: $projectId'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: newestCard,
          matching: find.text('Sonra: $replacementProjectId'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: malformedCard,
          matching: find.text('Zaman okunamadı'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: malformedCard,
          matching: find.text('Değişiklik ayrıntısı okunamadı.'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key(
            'agenda-change-history-10000000-0000-4000-8000-000000000001',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const Key(
            'agenda-change-history-10000000-0000-4000-8000-000000000003',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const Key(
            'agenda-change-history-10000000-0000-4000-8000-000000000005',
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: section, matching: find.byType(TextButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: section, matching: find.byType(FilledButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: section, matching: find.byType(OutlinedButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: section, matching: find.byType(IconButton)),
        findsNothing,
      );
      expect(Theme.of(tester.element(section)).brightness, Brightness.dark);
      expect(tester.takeException(), isNull);

      final linkedReminder = find.byKey(
        const Key('linked-reminder-$reminderId'),
      );
      await tester.scrollUntilVisible(
        linkedReminder,
        -300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(linkedReminder);
      await tester.pumpAndSettle();
      expect(find.byType(ReminderDetailPage), findsOneWidget);
      expect(find.byKey(const Key('open-source-agenda-log')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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
    'Agenda search app bar detail return preserves text without focus',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final logs = List.generate(18, _navigationLog);
      final fake = FakeAgendaApplication(projects: [project()], logs: logs);
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
      await tester.pumpAndSettle();

      await _enterAgendaSearch(tester, fake, 'CSE275 app bar');
      final searchEditable = tester.widget<EditableText>(
        _agendaSearchEditable(),
      );
      final searchFocusNode = searchEditable.focusNode;
      final searchController = searchEditable.controller;
      expect(searchFocusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(searchController.text, 'CSE275 app bar');
      final target = find.byKey(Key('agenda-log-${logs.last.id}'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      expect(searchFocusNode.hasFocus, isTrue);

      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.byType(LogDetailPage), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      final restoredOffset = _scrollOffset(
        tester,
        const Key('agenda-day-list'),
      );
      final restoredFocus = searchFocusNode.hasFocus;
      final restoredKeyboard = tester.testTextInput.isVisible;
      expect(searchController.text, 'CSE275 app bar');
      expect(fake.lastAgendaQuery?.literalSearch, 'CSE275 app bar');
      expect(restoredOffset, greaterThan(0));
      expect(restoredKeyboard, isFalse);
      expect(restoredFocus, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Agenda search system back preserves text without restoring focus',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final logs = List.generate(18, _navigationLog);
      final fake = FakeAgendaApplication(projects: [project()], logs: logs);
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
      await tester.pumpAndSettle();

      await _enterAgendaSearch(tester, fake, 'CSE275 system back');
      final target = find.byKey(Key('agenda-log-${logs.last.id}'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.byType(LogDetailPage), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final restoredOffset = _scrollOffset(
        tester,
        const Key('agenda-day-list'),
      );
      final restoredFocus = _agendaSearchHasFocus(tester);
      final restoredKeyboard = tester.testTextInput.isVisible;
      expect(fake.lastAgendaQuery?.literalSearch, 'CSE275 system back');
      expect(restoredOffset, greaterThan(0));
      expect(restoredKeyboard, isFalse);
      await _expectAgendaSearchTextAfterReveal(tester, 'CSE275 system back');
      expect(restoredFocus, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Agenda user scroll dismisses search focus without text or query churn',
    (tester) async {
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: List.generate(30, _navigationLog),
      );
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
      await tester.pumpAndSettle();

      await _enterAgendaSearch(tester, fake, 'CSE275 drag');
      final searchEditable = tester.widget<EditableText>(
        _agendaSearchEditable(),
      );
      final searchFocusNode = searchEditable.focusNode;
      final searchController = searchEditable.controller;
      expect(searchFocusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(searchController.text, 'CSE275 drag');
      final callsBeforeDrag = fake.listAgendaCalls;
      await tester.drag(
        find.byKey(const Key('agenda-literal-search')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      final offsetAfterDrag = _scrollOffset(
        tester,
        const Key('agenda-day-list'),
      );
      final focusAfterDrag = searchFocusNode.hasFocus;
      final keyboardAfterDrag = tester.testTextInput.isVisible;
      expect(offsetAfterDrag, greaterThan(0));
      expect(fake.lastAgendaQuery?.literalSearch, 'CSE275 drag');
      expect(fake.listAgendaCalls, callsBeforeDrag);
      expect(searchController.text, 'CSE275 drag');
      expect(focusAfterDrag, isFalse);
      expect(keyboardAfterDrag, isFalse);
      expect(
        tester
            .widget<RefreshIndicator>(find.byType(RefreshIndicator))
            .onRefresh,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Agenda drag fling and direction change never create search focus',
    (tester) async {
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: List.generate(34, _navigationLog),
      );
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: fake)));
      await tester.pumpAndSettle();
      final list = find.byKey(const Key('agenda-day-list'));
      final callsBeforeScroll = fake.listAgendaCalls;

      await tester.drag(list, const Offset(0, -360));
      await tester.pumpAndSettle();
      expect(_agendaSearchHasFocus(tester), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.fling(list, const Offset(0, -420), 1600);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();
      expect(_agendaSearchHasFocus(tester), isFalse);

      final gesture = await tester.startGesture(tester.getCenter(list));
      await gesture.moveBy(const Offset(0, -180));
      await gesture.moveBy(const Offset(0, 110));
      await gesture.up();
      await tester.pumpAndSettle();

      final offsetAfterGestures = _scrollOffset(
        tester,
        const Key('agenda-day-list'),
      );
      _expectAgendaSearchFocusAndKeyboard(
        tester,
        hasFocus: false,
        keyboardVisible: false,
      );
      expect(offsetAfterGestures, greaterThan(0));
      expect(fake.lastAgendaQuery?.literalSearch, '');
      expect(fake.listAgendaCalls, callsBeforeScroll);
      await _expectAgendaSearchTextAfterReveal(tester, '');
      expect(tester.takeException(), isNull);
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

      expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.newestFirst);
      await tester.tap(find.text('Arşivlenenler'));
      await tester.pumpAndSettle();
      expect(fake.lastAgendaQuery?.archiveFilter, AgendaArchiveFilter.archived);
      expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.newestFirst);
      await tester.tap(find.byKey(const Key('next-day')));
      await tester.pumpAndSettle();
      expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.newestFirst);
      await tester.ensureVisible(
        find.byKey(const Key('agenda-project-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agenda-project-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(project().name).last);
      await tester.pumpAndSettle();
      expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.newestFirst);
      await tester.ensureVisible(
        find.byKey(const Key('agenda-category-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agenda-category-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AgendaCategory.inspection.label).last);
      await tester.pumpAndSettle();
      expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.newestFirst);
      await tester.ensureVisible(
        find.byKey(const Key('agenda-literal-search')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('agenda-literal-search')),
        'CSE264 arama',
      );
      tester
          .widget<TextField>(find.byKey(const Key('agenda-literal-search')))
          .onSubmitted!('CSE264 arama');
      await tester.pumpAndSettle();
      expect(_agendaSearchHasFocus(tester), isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      final target = logs[18];
      final list = find.byKey(const Key('agenda-day-list'));
      final scrollable = find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first;
      final targetFinder = find.byKey(Key('agenda-log-${target.id}'));
      for (var attempt = 0; attempt < 12; attempt++) {
        if (targetFinder.evaluate().isNotEmpty) break;
        await tester.drag(scrollable, const Offset(0, -420));
        await tester.pumpAndSettle();
      }
      expect(targetFinder, findsOneWidget);
      await tester.ensureVisible(targetFinder);
      await tester.pumpAndSettle();
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
      delayedReload.complete(fake.logs.reversed.toList(growable: false));
      await tester.pumpAndSettle();

      final after = _scrollOffset(tester, const Key('agenda-day-list'));
      expect(after, closeTo(before, 4));
      expect(fake.lastAgendaQuery?.projectId, projectId);
      expect(fake.lastAgendaQuery?.category, AgendaCategory.inspection);
      expect(fake.lastAgendaQuery?.literalSearch, 'CSE264 arama');
      expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.newestFirst);
      expect(find.text('CSE264 güncel Ajanda açıklaması'), findsOneWidget);
      expect(targetFinder, findsOneWidget);
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
      expect(_agendaSearchHasFocus(tester), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ajanda card shows only real linked reminder indicator and opens reminder detail',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semanticsHandle = tester.ensureSemantics();

      final linkedLog = log();
      final noLinkLog = _navigationLog(
        1,
        description: 'Bağlı Hatırlatıcı bulunmayan Ajanda kaydı',
      );
      final unrelatedLog = _navigationLog(
        2,
        description: 'Aynı projedeki ilgisiz Hatırlatıcılar',
      );
      final linkedReminder = reminder();
      const unrelatedSourceId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa999';
      final fake = FakeAgendaApplication(
        projects: [project()],
        logs: [linkedLog, noLinkLog, unrelatedLog],
        reminders: [
          linkedReminder,
          const MobileReminder(
            id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
            projectId: projectId,
            projectName: 'Çok Uzun Kuzey Şantiyesi Proje Adı',
            sourceLogId: unrelatedSourceId,
            title: 'Aynı projede başka kaynaklı Hatırlatıcı',
            kind: ReminderKind.recheck,
            status: ReminderStatus.active,
            nextAttentionAt: '2026-07-19T11:00:00Z',
            createdAt: '2026-07-19T08:00:00Z',
            updatedAt: '2026-07-19T08:00:00Z',
            revision: 1,
          ),
          const MobileReminder(
            id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3',
            projectId: projectId,
            projectName: 'Çok Uzun Kuzey Şantiyesi Proje Adı',
            sourceLogId: null,
            title: 'Aynı projede kaynaksız Hatırlatıcı',
            kind: ReminderKind.action,
            status: ReminderStatus.inbox,
            nextAttentionAt: null,
            createdAt: '2026-07-19T08:00:00Z',
            updatedAt: '2026-07-19T08:00:00Z',
            revision: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: AgendaPage(agenda: fake),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('agenda-sort-order')));
      await tester.tap(find.byKey(const Key('agenda-sort-order')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('En eski üstte').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('agenda-project-filter')),
      );
      await tester.tap(find.byKey(const Key('agenda-project-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(project().name).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('agenda-category-filter')),
      );
      await tester.tap(find.byKey(const Key('agenda-category-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AgendaCategory.inspection.label).last);
      await tester.pumpAndSettle();
      await _enterAgendaSearch(tester, fake, 'bağlı kaynak');

      final indicator = find.byKey(
        Key('agenda-log-linked-reminder-${linkedLog.id}'),
      );
      await tester.ensureVisible(indicator);
      await tester.pumpAndSettle();

      expect(indicator, findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      expect(
        find.byKey(Key('agenda-log-linked-reminder-${noLinkLog.id}')),
        findsNothing,
      );
      expect(
        find.byKey(Key('agenda-log-linked-reminder-${unrelatedLog.id}')),
        findsNothing,
      );
      final indicatorWidget = tester.widget<IconButton>(indicator);
      expect(indicatorWidget.tooltip, 'Bağlı hatırlatıcıyı aç');
      final linkedReminderSemantics = find.bySemanticsLabel(
        'Bağlı hatırlatıcıyı aç',
      );
      expect(linkedReminderSemantics, findsOneWidget);
      final indicatorSemantics = tester
          .getSemantics(linkedReminderSemantics)
          .getSemanticsData();
      expect(indicatorSemantics.flagsCollection.isButton, isTrue);
      expect(indicatorSemantics.hasAction(SemanticsAction.tap), isTrue);
      final linkedReminderSemanticsNode = find.semantics.byLabel(
        'Bağlı hatırlatıcıyı aç',
      );
      expect(linkedReminderSemanticsNode, findsOneWidget);
      expect(tester.getSize(indicator).shortestSide, greaterThanOrEqualTo(48));
      expect(Theme.of(tester.element(indicator)).brightness, Brightness.dark);
      expect(tester.takeException(), isNull);

      tester.semantics.performAction(
        linkedReminderSemanticsNode,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReminderDetailPage), findsOneWidget);
      expect(
        tester
            .widget<ReminderDetailPage>(find.byType(ReminderDetailPage))
            .reminderId,
        linkedReminder.id,
      );
      expect(find.byType(LogDetailPage), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(indicator);
      await tester.pumpAndSettle();
      await tester.tap(indicator);
      await tester.pumpAndSettle();

      expect(find.byType(ReminderDetailPage), findsOneWidget);
      expect(
        tester
            .widget<ReminderDetailPage>(find.byType(ReminderDetailPage))
            .reminderId,
        linkedReminder.id,
      );
      expect(find.byType(LogDetailPage), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('agenda-day-list')), findsOneWidget);
      expect(indicator, findsOneWidget);
      expect(fake.lastAgendaQuery?.projectId, projectId);
      expect(fake.lastAgendaQuery?.category, AgendaCategory.inspection);
      expect(fake.lastAgendaQuery?.literalSearch, 'bağlı kaynak');
      expect(fake.lastAgendaQuery?.sortOrder, AgendaSortOrder.oldestFirst);
      expect(_agendaSearchHasFocus(tester), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.takeException(), isNull);
      semanticsHandle.dispose();
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
    final firstFake = FakeAgendaApplication(projects: [project()], logs: logs);
    final secondFake = FakeAgendaApplication(projects: [project()], logs: logs);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: KeyedSubtree(
                  key: const Key('agenda-instance-one'),
                  child: AgendaPage(agenda: firstFake),
                ),
              ),
              Expanded(
                child: KeyedSubtree(
                  key: const Key('agenda-instance-two'),
                  child: AgendaPage(agenda: secondFake),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final firstSearch = _agendaSearchEditable(
      within: find.byKey(const Key('agenda-instance-one')),
    );
    final secondSearch = _agendaSearchEditable(
      within: find.byKey(const Key('agenda-instance-two')),
    );
    expect(
      identical(
        tester.widget<EditableText>(firstSearch).focusNode,
        tester.widget<EditableText>(secondSearch).focusNode,
      ),
      isFalse,
    );
    final firstList = find.descendant(
      of: find.byKey(const Key('agenda-instance-one')),
      matching: find.byKey(const Key('agenda-day-list')),
    );
    final firstSort = find.descendant(
      of: find.byKey(const Key('agenda-instance-one')),
      matching: find.byKey(const Key('agenda-sort-order')),
    );
    await tester.tap(firstSort);
    await tester.pumpAndSettle();
    await tester.tap(find.text('En eski üstte').last);
    await tester.pumpAndSettle();

    expect(firstFake.lastAgendaQuery?.sortOrder, AgendaSortOrder.oldestFirst);
    expect(secondFake.lastAgendaQuery?.sortOrder, AgendaSortOrder.newestFirst);
    expect(
      find.descendant(
        of: find.byKey(const Key('agenda-instance-one')),
        matching: find.text('En eski üstte'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('agenda-instance-two')),
        matching: find.text('En yeni üstte'),
      ),
      findsOneWidget,
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

class _CatalogAgendaFake extends FakeAgendaApplication
    implements AttachmentCatalogHost, AgendaExistingAttachmentApplication {
  _CatalogAgendaFake({
    required super.projects,
    required super.logs,
    required super.logDetail,
  });

  int linkExistingCalls = 0;
  LinkExistingAgendaPhotoCommand? lastExistingCommand;

  @override
  final AttachmentCatalogApplication attachmentCatalog = _FakeCatalog();

  @override
  Future<AgendaLogDetail> linkExistingAgendaPhoto(
    LinkExistingAgendaPhotoCommand command,
  ) async {
    linkExistingCalls += 1;
    lastExistingCommand = command;
    final current = logDetail!;
    final updatedLog = AgendaLog(
      id: current.log.id,
      projectId: current.log.projectId,
      projectName: current.log.projectName,
      observedAt: current.log.observedAt,
      createdAt: current.log.createdAt,
      updatedAt: '2026-07-19T08:05:00Z',
      category: current.log.category,
      description: current.log.description,
      location: current.log.location,
      notes: current.log.notes,
      revision: current.log.revision + 1,
      archivedAt: current.log.archivedAt,
    );
    final photo = AgendaLogPhoto(
      id: command.linkId,
      logId: command.logId,
      projectId: current.log.projectId,
      originalFileName: 'katalog-fotografi.png',
      mimeType: 'image/png',
      byteSize: 9,
      sha256: List.filled(64, 'a').join(),
      relativePath: 'managed/${command.physicalAttachmentId}.png',
      description: null,
      capturedAt: '2026-07-19T08:05:00Z',
      revision: 1,
      createdAt: '2026-07-19T08:05:00Z',
      updatedAt: '2026-07-19T08:05:00Z',
      archivedAt: null,
      integrity: AgendaAttachmentIntegrity.ok,
    );
    logDetail = AgendaLogDetail(
      log: updatedLog,
      reminders: current.reminders,
      photos: [...current.photos, photo],
      events: current.events,
      managedConcretePourId: current.managedConcretePourId,
    );
    logs = [updatedLog];
    return logDetail!;
  }
}

class _FakeCatalog implements AttachmentCatalogApplication {
  static const physicalId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';

  @override
  Future<List<AttachmentCatalogProject>> listProjects() async => const [
    AttachmentCatalogProject(id: projectId, name: 'Kuzey Şantiyesi'),
  ];

  @override
  Future<List<ProjectAttachmentCatalogItem>> listProjectAttachments(
    String projectId,
  ) async => [
    ProjectAttachmentCatalogItem(
      physicalAttachmentId: physicalId,
      relativePath: 'managed/$physicalId.png',
      mimeType: 'image/png',
      byteSize: 9,
      sha256Value: List.filled(64, 'a').join(),
      createdAt: '2026-07-19T07:00:00Z',
      integrity: ManagedAttachmentIntegrity.healthy,
      links: const [
        AttachmentCatalogLink(
          id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
          sourceType: AttachmentCatalogSourceType.agendaObservation,
          sourceId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa9',
          sourceLabel: 'Ajanda • Kaynak kayıt',
          role: 'site_photo',
          originalFileName: 'katalog-fotografi.png',
          createdAt: '2026-07-19T07:00:00Z',
          archivedAt: null,
        ),
      ],
    ),
  ];
}

Finder _agendaSearchEditable({Finder? within}) {
  final field = within == null
      ? find.byKey(const Key('agenda-literal-search'))
      : find.descendant(
          of: within,
          matching: find.byKey(const Key('agenda-literal-search')),
        );
  return find.descendant(of: field, matching: find.byType(EditableText));
}

bool _agendaSearchHasFocus(WidgetTester tester, {Finder? within}) {
  final matches = _agendaSearchEditable(
    within: within,
  ).evaluate().toList(growable: false);
  expect(
    matches.length,
    lessThanOrEqualTo(1),
    reason: 'Expected at most one exact Agenda search EditableText.',
  );
  if (matches.isEmpty) return false;
  final widget = matches.single.widget;
  expect(widget, isA<EditableText>());
  return (widget as EditableText).focusNode.hasFocus;
}

Future<void> _enterAgendaSearch(
  WidgetTester tester,
  FakeAgendaApplication fake,
  String text,
) async {
  final field = find.byKey(const Key('agenda-literal-search'));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pump();
  await tester.enterText(field, text);
  tester.widget<TextField>(field).onSubmitted!(text);
  await tester.pumpAndSettle();
  expect(fake.lastAgendaQuery?.literalSearch, text);
}

void _expectAgendaSearchFocusAndKeyboard(
  WidgetTester tester, {
  required bool hasFocus,
  required bool keyboardVisible,
}) {
  expect(_agendaSearchHasFocus(tester), hasFocus);
  expect(tester.testTextInput.isVisible, keyboardVisible);
}

Future<void> _expectAgendaSearchTextAfterReveal(
  WidgetTester tester,
  String text,
) async {
  final list = find.byKey(const Key('agenda-day-list'));
  final position = tester.state<ScrollableState>(_scrollableFor(list)).position;
  position.jumpTo(position.minScrollExtent);
  await tester.pumpAndSettle();
  final editable = _agendaSearchEditable();
  expect(editable, findsOneWidget);
  expect(tester.widget<EditableText>(editable).controller.text, text);
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

AgendaLog _sortLog(
  int index, {
  required String observedAt,
  required String description,
  String createdAt = '2026-07-19T10:00:00Z',
}) => AgendaLog(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-${(index + 200).toString().padLeft(12, '0')}',
  projectId: projectId,
  projectName: 'Çok Uzun Kuzey Şantiyesi Proje Adı',
  observedAt: observedAt,
  createdAt: createdAt,
  updatedAt: createdAt,
  category: AgendaCategory.inspection,
  description: description,
  location: 'CSE268 sentetik mahal',
  notes: 'CSE268 sort fixture',
  revision: 1,
);

class _DelayedAgendaApplication extends FakeAgendaApplication {
  _DelayedAgendaApplication({required super.projects, required super.logs});

  Completer<List<AgendaLog>>? delayedAgendaReload;

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

class _ManySelectedPicker
    implements AttachmentPickerPort, MultipleAttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async =>
      (await pickMany(source))!.first;

  @override
  Future<List<SelectedAttachment>?> pickMany(AttachmentSource source) async => [
    SelectedAttachment(
      name: 'bir.jpg',
      bytes: const [0xff, 0xd8, 0xff, 1],
      source: source,
    ),
    SelectedAttachment(
      name: 'iki.png',
      bytes: const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
      source: source,
    ),
  ];
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
