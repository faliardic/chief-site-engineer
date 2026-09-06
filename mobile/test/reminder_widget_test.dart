import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_photo_viewer_page.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/agenda/project_location_catalog_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const reminderId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const agendaProjectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const agendaSourceLogId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

String widgetReminderId(int value) =>
    'dddddddd-dddd-4ddd-8ddd-${value.toString().padLeft(12, '0')}';

MobileReminder reminder({
  String id = reminderId,
  String title = 'Mobil hızlı yakalama',
  String? captureText,
  String? description,
  ReminderKind kind = ReminderKind.action,
  ReminderStatus status = ReminderStatus.active,
  String? nextAttentionAt,
  String? allDayLocalDate,
  String? deadlineAt,
  String? trashedAt,
  bool isImportant = false,
  String? projectId = agendaProjectId,
  String? projectName,
  String? sourceLogId,
  String? attendanceDayId,
  String? locationId,
  String? stableLocationName,
  String? stableLocationArchivedAt,
  String? location,
  String? relatedPerson,
  String? conditionText,
  ReminderOutcomeType? outcomeType,
  String? outcomeNote,
  int revision = 1,
}) => MobileReminder(
  id: id,
  projectId: projectId,
  projectName: projectName,
  sourceLogId: sourceLogId,
  attendanceDayId: attendanceDayId,
  captureText: captureText ?? title,
  title: title,
  description: description,
  kind: kind,
  status: status,
  locationId: locationId,
  stableLocationName: stableLocationName,
  stableLocationArchivedAt: stableLocationArchivedAt,
  location: location,
  relatedPerson: relatedPerson,
  isImportant: isImportant,
  nextAttentionAt: status == ReminderStatus.inbox || allDayLocalDate != null
      ? null
      : nextAttentionAt ?? '2026-07-20T06:00:00Z',
  allDayLocalDate: allDayLocalDate,
  deadlineAt: deadlineAt,
  conditionText: conditionText,
  outcomeType: outcomeType,
  outcomeNote: outcomeNote,
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  trashedAt: trashedAt,
  revision: revision,
);

AgendaLog sourceAgendaLog({
  String id = agendaSourceLogId,
  String projectId = agendaProjectId,
  String description = 'Ajanda başlığı',
  String? notes = 'Ajanda açıklaması',
  String? locationId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  String? stableLocationName = 'A Blok / Kat 1',
  String? stableLocationArchivedAt,
  String? location = 'A Blok / Kat 1',
  String? archivedAt,
  int revision = 7,
}) => AgendaLog(
  id: id,
  projectId: projectId,
  projectName: 'Şantiye A',
  observedAt: '2026-07-20T06:00:00Z',
  createdAt: '2026-07-20T06:00:00Z',
  updatedAt: '2026-07-20T06:00:00Z',
  category: AgendaCategory.inspection,
  description: description,
  locationId: locationId,
  stableLocationName: stableLocationName,
  stableLocationArchivedAt: stableLocationArchivedAt,
  location: location,
  notes: notes,
  archivedAt: archivedAt,
  revision: revision,
);

MobileProject reminderProject(String id, String name, {String? archivedAt}) =>
    MobileProject(
      id: id,
      name: name,
      createdAt: '2026-08-30T06:00:00Z',
      updatedAt: '2026-08-30T06:00:00Z',
      revision: 1,
      archivedAt: archivedAt,
    );

Future<void> openAgendaReminderSyncDialog(WidgetTester tester) async {
  final action = find.byKey(const Key('sync-agenda-to-reminder'));
  await tester.scrollUntilVisible(
    action,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  _expectAccessibleIconTarget(tester, action, 'Ajanda’dan güncelle');
  expect(
    _iconButtonByKey(tester, const Key('sync-agenda-to-reminder')).tooltip,
    'Ajanda’dan güncelle',
  );
  expect(
    find.descendant(of: action, matching: find.byIcon(Icons.sync_outlined)),
    findsOneWidget,
  );
  expect(find.text('Ajanda’dan güncelle'), findsNothing);
  await tester.tap(action);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('agenda-reminder-sync-dialog')), findsOneWidget);
}

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

Future<void> chooseEarlierLocalTime(
  WidgetTester tester, {
  required int hour,
}) async {
  Future<void> tapDial({
    required int value,
    required int divisions,
    required bool inner,
  }) async {
    final dial = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter?.runtimeType.toString() == '_DialPainter',
    );
    expect(dial, findsOneWidget);
    final center = tester.getCenter(dial);
    final dialRadius = tester.getSize(dial).shortestSide / 2;
    final targetRadius = dialRadius * (inner ? 0.6 : 0.8);
    final angle = value * math.pi * 2 / divisions;
    await tester.tapAt(
      center.translate(
        math.sin(angle) * targetRadius,
        -math.cos(angle) * targetRadius,
      ),
    );
    await tester.pumpAndSettle();
  }

  await tester.tap(find.text('İleri'));
  await tester.pumpAndSettle();
  expect(find.byType(TimePickerDialog), findsOneWidget);
  await tapDial(
    value: hour % TimeOfDay.hoursPerPeriod,
    divisions: TimeOfDay.hoursPerPeriod,
    inner: hour >= TimeOfDay.hoursPerPeriod,
  );
  await tapDial(value: 0, divisions: 12, inner: false);
  await tester.tap(find.text('Tamam'));
  await tester.pumpAndSettle();
}

Future<void> openDetailAllDayPicker(WidgetTester tester) async {
  final scheduleButton = find.byKey(const Key('schedule-reminder'));
  final detailListView = find.byWidgetPredicate(
    (widget) =>
        widget is ListView && widget.key == const Key('reminder-detail'),
    description: 'outer reminder detail ListView',
  );
  expect(detailListView, findsOneWidget);
  for (
    var attempt = 0;
    scheduleButton.evaluate().isEmpty && attempt < 8;
    attempt += 1
  ) {
    await tester.drag(detailListView, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  expect(scheduleButton, findsOneWidget);
  await tester.ensureVisible(scheduleButton);
  await tester.pumpAndSettle();
  await tester.tap(scheduleButton);
  await tester.pumpAndSettle();
  final allDay = find.byKey(const Key('reminder-schedule-option-allDay'));
  await tester.scrollUntilVisible(
    allDay,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(allDay);
  await tester.pumpAndSettle();
}

Future<void> _pumpReminderFormRoute(
  WidgetTester tester, {
  required Key openerKey,
  required WidgetBuilder builder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            key: openerKey,
            onPressed: () => Navigator.of(
              context,
            ).push<void>(MaterialPageRoute(builder: builder)),
            child: const Text('Formu aç'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(openerKey));
  await tester.pumpAndSettle();
}

Future<void> _submitReminderFormThroughUi(WidgetTester tester) async {
  final submit = find.byKey(const Key('submit-reminder'));
  expect(submit, findsOneWidget);
  final formScrollable = find
      .descendant(
        of: find.byKey(const Key('reminder-form-scroll')),
        matching: find.byType(Scrollable),
      )
      .first;
  expect(formScrollable, findsOneWidget);
  await tester.scrollUntilVisible(submit, 200, scrollable: formScrollable);
  await tester.pumpAndSettle();
  for (
    var dragCount = 0;
    dragCount < 6 && submit.hitTestable().evaluate().isEmpty;
    dragCount += 1
  ) {
    await tester.drag(formScrollable, const Offset(0, -48));
    await tester.pumpAndSettle();
  }
  final hitTestableSubmit = submit.hitTestable();
  expect(hitTestableSubmit, findsOneWidget);
  await tester.tap(hitTestableSubmit);
  await tester.pumpAndSettle();
}

IconButton _iconButtonByKey(WidgetTester tester, Key key) {
  final keyed = find.byKey(key);
  final keyedWidget = tester.widget(keyed);
  if (keyedWidget is IconButton) return keyedWidget;
  return tester.widget<IconButton>(
    find.descendant(of: keyed, matching: find.byType(IconButton)),
  );
}

Semantics _semanticsByKey(WidgetTester tester, Key key) {
  return tester.widget<Semantics>(
    find.ancestor(of: find.byKey(key), matching: find.byType(Semantics)).first,
  );
}

void _expectAccessibleIconTarget(
  WidgetTester tester,
  Finder finder,
  String semanticsLabel,
) {
  final renderedSize = tester.getSize(finder);
  expect(renderedSize, const Size.square(48));
  final semantics = find
      .ancestor(
        of: finder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == semanticsLabel,
        ),
      )
      .first;
  expect(tester.getSize(semantics), renderedSize);
}

void _expectPrimaryFormAction(
  WidgetTester tester,
  Finder finder,
  String label, {
  bool enabled = true,
}) {
  expect(finder, findsOneWidget);
  expect(tester.widget(finder), isA<FilledButton>());
  expect(
    find.descendant(of: finder, matching: find.byType(IconButton)),
    findsNothing,
  );
  final renderedSize = tester.getSize(finder);
  expect(renderedSize.width, greaterThanOrEqualTo(48));
  expect(renderedSize.height, greaterThanOrEqualTo(48));
  expect(
    find.descendant(of: finder, matching: find.text(label)),
    findsOneWidget,
  );
  final semantics = find
      .ancestor(
        of: finder,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == label,
        ),
      )
      .first;
  final properties = tester.widget<Semantics>(semantics).properties;
  expect(tester.getSize(semantics), renderedSize);
  expect(properties.button, isTrue);
  expect(properties.enabled, enabled);
  expect(tester.widget<FilledButton>(finder).onPressed != null, enabled);
}

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'history uses Turkish labels and preserves order and time at ${width.toInt()} px with 2x text',
      (tester) async {
        tester.view.physicalSize = Size(width, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const descriptions = [
          ('created', 'Hatırlatıcı oluşturuldu'),
          ('scheduled', 'Hatırlatıcı planlandı'),
          ('rescheduled', 'Hatırlatıcı yeniden planlandı'),
          ('details_updated', 'Hatırlatıcı bilgileri güncellendi'),
          ('waiting_started', 'Beklemeye alındı'),
          ('legacy_waiting_normalized', 'Bekleme kaydı güncellendi'),
          ('snoozed', 'Hatırlatıcı ertelendi'),
          ('completed', 'Hatırlatıcı tamamlandı'),
          ('cancelled', 'Hatırlatıcı iptal edildi'),
          ('reopened', 'Hatırlatıcı yeniden açıldı'),
          ('moved_to_inbox', 'Unutma Kutusu’na taşındı'),
          ('trashed', 'Geri Dönüşüm Kutusu’na taşındı'),
          ('restored_from_trash', 'Geri yüklendi'),
          ('notification_scheduled', 'Bildirim planlandı'),
          ('notification_cancelled', 'Bildirim planı kaldırıldı'),
          ('fixture_unknown_event', 'Hatırlatıcı kaydı güncellendi'),
        ];
        final events = List<AppendOnlyEvent>.unmodifiable([
          for (var index = 0; index < descriptions.length; index++)
            AppendOnlyEvent(
              id: widgetReminderId(index + 700),
              recordId: reminderId,
              projectId: agendaProjectId,
              eventType: descriptions[index].$1,
              occurredAt: index.isEven
                  ? '2026-09-05T22:10:00Z'
                  : '2026-09-05T08:10:00Z',
              payloadJson: '{"internal":"history_payload_should_stay_private"}',
              sequence: 10 + index * 3,
            ),
        ]);
        final item = reminder(
          projectId: agendaProjectId,
          projectName: 'Şantiye A',
        );
        final detail = ReminderDetail(
          reminder: item,
          events: events,
          notification: NotificationBinding(
            reminderId: reminderId,
            platformNotificationId: 1,
            scheduledFor: item.nextAttentionAt,
            syncState: NotificationSyncState.scheduled,
            lastSyncedAt: item.updatedAt,
            safeErrorCode: null,
          ),
        );
        final agenda = _HistoryReminderAgenda(detail);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrollable = find
            .descendant(
              of: find.byKey(const Key('reminder-detail')),
              matching: find.byType(Scrollable),
            )
            .first;
        final renderedLabels = <String?>[];
        var previousOffset = -1.0;
        for (var index = 0; index < events.length; index++) {
          final event = events[index];
          final row = find.byKey(Key('reminder-history-event-${event.id}'));
          await tester.scrollUntilVisible(
            row,
            260,
            scrollable: scrollable,
            maxScrolls: 30,
          );
          await tester.pumpAndSettle();
          expect(row, findsOneWidget);
          final tile = tester.widget<ListTile>(row);
          renderedLabels.add((tile.title! as Text).data);
          expect(
            (tile.subtitle! as Text).data,
            index.isEven ? '06.09.2026 01:10:00' : '05.09.2026 11:10:00',
          );
          expect(
            find.descendant(
              of: row,
              matching: find.byIcon(Icons.history_outlined),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: row, matching: find.byType(CircleAvatar)),
            findsNothing,
          );
          expect(
            find.descendant(of: row, matching: find.text('${event.sequence}')),
            findsNothing,
          );
          expect(find.textContaining(event.eventType), findsNothing);
          expect(tester.getRect(row).left, greaterThanOrEqualTo(0));
          expect(tester.getRect(row).right, lessThanOrEqualTo(width));
          final offset = tester
              .state<ScrollableState>(scrollable)
              .position
              .pixels;
          expect(offset, greaterThanOrEqualTo(previousOffset));
          previousOffset = offset;
          expect(tester.takeException(), isNull);
        }
        expect(
          renderedLabels,
          descriptions.map((description) => description.$2),
        );
        expect(find.text('Hatırlatıcı kaydı güncellendi'), findsOneWidget);
        expect(find.textContaining('fixture_unknown_event'), findsNothing);
        expect(
          find.textContaining('history_payload_should_stay_private'),
          findsNothing,
        );
        expect(agenda.lifecycleDetail, same(detail));
        expect(agenda.lifecycleDetail.events, same(events));
        expect(
          events.map((event) => event.sequence),
          List.generate(events.length, (index) => 10 + index * 3),
        );
        expect(agenda.mutateReminderCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('preferred project is initial only and cancel creates nothing', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication(
      projects: [reminderProject(agendaProjectId, 'Şantiye A')],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ReminderFormPage(
                    agenda: agenda,
                    preferredProjectId: agendaProjectId,
                  ),
                ),
              ),
              child: const Text('Formu aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Formu aç'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-project')), findsOneWidget);
    expect(find.text('Şantiye A'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(agenda.createReminderCalls, 0);
  });

  testWidgets('preferred project can be changed to personal before save', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication(
      projects: [reminderProject(agendaProjectId, 'Şantiye A')],
    );
    await _pumpReminderFormRoute(
      tester,
      openerKey: const Key('open-personal-preferred-form'),
      builder: (_) =>
          ReminderFormPage(agenda: agenda, preferredProjectId: agendaProjectId),
    );

    await tester.tap(find.byKey(const Key('reminder-project')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kişisel / projesiz').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-title')),
      'Kişisel kontrol',
    );
    await _submitReminderFormThroughUi(tester);

    expect(agenda.createReminderCalls, 1);
    expect(agenda.lastReminderCommand, isNotNull);
    expect(agenda.lastReminderCommand!.projectId, isNull);
    expect(
      find.byKey(const Key('open-personal-preferred-form')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('submit-reminder')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid preferred project clears but source log project wins', (
    tester,
  ) async {
    final preferred = reminderProject(
      'ffffffff-ffff-4fff-8fff-ffffffffffff',
      'Arşivli',
      archivedAt: '2026-08-30T07:00:00Z',
    );
    final sourceProject = reminderProject(agendaProjectId, 'Şantiye A');
    final invalidAgenda = FakeAgendaApplication(projects: [preferred]);
    await _pumpReminderFormRoute(
      tester,
      openerKey: const Key('open-invalid-preferred-form'),
      builder: (_) => ReminderFormPage(
        agenda: invalidAgenda,
        preferredProjectId: preferred.id,
      ),
    );
    await tester.enterText(
      find.byKey(const Key('reminder-title')),
      'Arşivli projeye yazma',
    );
    await _submitReminderFormThroughUi(tester);
    expect(invalidAgenda.createReminderCalls, 1);
    expect(invalidAgenda.lastReminderCommand, isNotNull);
    expect(invalidAgenda.lastReminderCommand!.projectId, isNull);

    final sourceAgenda = FakeAgendaApplication(
      projects: [sourceProject, preferred],
    );
    await _pumpReminderFormRoute(
      tester,
      openerKey: const Key('open-source-log-form'),
      builder: (_) => ReminderFormPage(
        agenda: sourceAgenda,
        log: sourceAgendaLog(),
        preferredProjectId: preferred.id,
      ),
    );
    expect(find.byKey(const Key('reminder-project')), findsNothing);
    await _submitReminderFormThroughUi(tester);
    expect(sourceAgenda.createReminderCalls, 1);
    expect(sourceAgenda.lastReminderCommand, isNotNull);
    expect(sourceAgenda.lastReminderCommand!.projectId, agendaProjectId);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily create actions stay labeled on compact text scales', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    final agenda = FakeAgendaApplication();

    for (final textScale in <double>[1, 2]) {
      tester.binding.platformDispatcher.textScaleFactorTestValue = textScale;
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey('reminder-list-$textScale'),
          home: Scaffold(
            body: RemindersPage(
              agenda: agenda,
              preferredProjectId: agendaProjectId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final create = find.byKey(const Key('new-reminder'));
      final inbox = find.byKey(const Key('quick-inbox-reminder'));
      expect(create, findsOneWidget);
      expect(inbox, findsOneWidget);
      expect(tester.widget(create), isA<FilledButton>());
      expect(tester.widget(inbox), isA<OutlinedButton>());
      expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(inbox).height, greaterThanOrEqualTo(48));
      expect(create.hitTestable(), findsOneWidget);
      expect(inbox.hitTestable(), findsOneWidget);
      expect(find.text('Yeni hatırlatıcı'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '+ Unutma'), findsOneWidget);
      expect(
        find.descendant(
          of: create,
          matching: find.byIcon(Icons.add_alert_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inbox, matching: find.byIcon(Icons.inbox_outlined)),
        findsOneWidget,
      );

      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey('reminder-form-$textScale'),
          home: ReminderFormPage(agenda: agenda),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Yeni hatırlatıcı'), findsOneWidget);
      expect(find.byKey(const Key('reminder-title')), findsOneWidget);
      _expectAccessibleIconTarget(
        tester,
        find.byKey(const Key('reminder-today')),
        'Bugün',
      );
      final submit = find.byKey(const Key('submit-reminder'));
      await tester.scrollUntilVisible(
        submit,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      _expectPrimaryFormAction(tester, submit, 'Kaydet');
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });

  testWidgets(
    'form exposes quick Bugün and true Tam gün without waiting or fake time',
    (tester) async {
      final semantics = tester.ensureSemantics();
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
      for (final action in const [
        (Key('reminder-today'), 'Bugün'),
        (Key('reminder-all-day-tomorrow'), 'Yarın • Tam gün'),
      ]) {
        expect(tester.getSize(find.byKey(action.$1)), const Size.square(48));
        expect(_iconButtonByKey(tester, action.$1).tooltip, action.$2);
        expect(find.bySemanticsLabel(action.$2), findsOneWidget);
      }

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
      expect(
        find.descendant(
          of: find.byKey(const Key('reminder-custom-date')),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );

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
      semantics.dispose();
    },
  );

  testWidgets('form keeps selected schedule and deadline values visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final agenda = FakeAgendaApplication();
    await tester.pumpWidget(
      MaterialApp(home: ReminderFormPage(agenda: agenda)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reminder-schedule')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ReminderScheduleKind.custom.label).last);
    await tester.pumpAndSettle();
    for (final key in const [
      Key('reminder-custom-date'),
      Key('reminder-custom-time'),
    ]) {
      final valueAction = find.byKey(key);
      expect(valueAction, findsOneWidget);
      expect(
        find.descendant(of: valueAction, matching: find.byType(Text)),
        findsOneWidget,
      );
    }

    final optional = find.byKey(const Key('reminder-optional-details'));
    await tester.scrollUntilVisible(
      optional,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(optional);
    await tester.pumpAndSettle();
    final hasDeadline = find.byKey(const Key('reminder-has-deadline'));
    await tester.scrollUntilVisible(
      hasDeadline,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(hasDeadline);
    await tester.pumpAndSettle();
    for (final key in const [
      Key('reminder-deadline-date'),
      Key('reminder-deadline-time'),
    ]) {
      final valueAction = find.byKey(key);
      expect(valueAction, findsOneWidget);
      expect(
        find.descendant(of: valueAction, matching: find.byType(Text)),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mahal Kataloğu icon action keeps exact navigation callback', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final project = reminderProject(agendaProjectId, 'Şantiye A');
    final agenda = FakeAgendaApplication(projects: [project]);
    final locations = _FakeProjectLocations([project]);
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderFormPage(
          agenda: agenda,
          projectLocations: locations,
          preferredProjectId: project.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final optional = find.byKey(const Key('reminder-optional-details'));
    await tester.scrollUntilVisible(
      optional,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(optional);
    await tester.pumpAndSettle();
    final action = find.byKey(const Key('open-location-catalog-from-reminder'));
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getSize(action), const Size.square(48));
    expect(
      _iconButtonByKey(
        tester,
        const Key('open-location-catalog-from-reminder'),
      ).tooltip,
      'Mahal Kataloğu',
    );
    expect(find.bySemanticsLabel('Mahal Kataloğu'), findsOneWidget);
    expect(find.text('Mahal Kataloğu'), findsNothing);
    _iconButtonByKey(
      tester,
      const Key('open-location-catalog-from-reminder'),
    ).onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.byType(ProjectLocationCatalogPage), findsOneWidget);
    semantics.dispose();
  });

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
        final submit = find.byKey(
          const Key('submit-reminder'),
          skipOffstage: false,
        );
        final formListView = find.byKey(const Key('reminder-form-scroll'));
        final formScrollable = find
            .descendant(of: formListView, matching: find.byType(Scrollable))
            .first;
        expect(formListView, findsOneWidget);
        expect(formScrollable, findsOneWidget);
        expect(
          find.descendant(of: formListView, matching: formScrollable),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          submit,
          200,
          scrollable: formScrollable,
        );
        await tester.pumpAndSettle();

        bool submitIsFullyInViewport() {
          final viewport = tester.getRect(
            find.byKey(const Key('reminder-form-viewport')),
          );
          final submitRect = tester.getRect(submit);
          return submitRect.left >= viewport.left &&
              submitRect.right <= viewport.right &&
              submitRect.top >= viewport.top + 1 &&
              submitRect.bottom <= viewport.bottom - 1;
        }

        for (
          var correction = 0;
          correction < 6 && !submitIsFullyInViewport();
          correction += 1
        ) {
          final viewport = tester.getRect(
            find.byKey(const Key('reminder-form-viewport')),
          );
          final submitRect = tester.getRect(submit);
          final dragDy = submitRect.bottom > viewport.bottom - 1
              ? -math.max(submitRect.bottom - viewport.bottom + 24, 32.0)
              : math.max(viewport.top - submitRect.top + 24, 32.0);
          await tester.drag(formScrollable, Offset(0, dragDy));
          await tester.pumpAndSettle();
        }

        expect(submitIsFullyInViewport(), isTrue);
        expect(submit.hitTestable(), findsOneWidget);
        await tester.tap(submit.hitTestable());
        await tester.pumpAndSettle();

        expect(agenda.lastReminderCommand!.schedule, schedule);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'detail planning sheet exposes week-start scheduling before selection',
    (tester) async {
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

      final weekStart = find.byKey(
        const Key('reminder-schedule-option-nextWeekStart'),
      );
      await tester.scrollUntilVisible(
        weekStart,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(weekStart, findsOneWidget);
    },
  );

  for (final scheduleCase in [
    (
      schedule: ReminderScheduleKind.tomorrowMorning,
      preview: 'Yarın sabah — 31.07.2026 08:00',
      expectedUtc: '2026-07-31T05:00:00Z',
    ),
    (
      schedule: ReminderScheduleKind.nextWeekStart,
      preview: 'Hafta başına ertele — 03.08.2026 08:00',
      expectedUtc: '2026-08-03T05:00:00Z',
    ),
  ]) {
    testWidgets('form previews and submits ${scheduleCase.schedule.label}', (
      tester,
    ) async {
      await withClock(Clock.fixed(DateTime.utc(2026, 7, 30, 2)), () async {
        final agenda = FakeAgendaApplication();
        await tester.pumpWidget(
          MaterialApp(home: ReminderFormPage(agenda: agenda)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('reminder-schedule')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(scheduleCase.schedule.label).last);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('reminder-schedule-preview')),
          findsOneWidget,
        );
        expect(find.text(scheduleCase.preview), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('reminder-title')),
          scheduleCase.schedule.label,
        );
        final submit = find.byKey(const Key('submit-reminder'));
        await tester.scrollUntilVisible(
          submit,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(submit);
        await tester.pumpAndSettle();

        expect(agenda.lastReminderCommand!.schedule, scheduleCase.schedule);
        expect(
          agenda.lastReminderCommand!.customAttentionAt,
          scheduleCase.expectedUtc,
        );
      });
    });
  }

  testWidgets(
    'Today is default and renders overdue all-day and timed sections once in priority order',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
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
          home: Scaffold(
            body: RemindersPage(
              agenda: agenda,
              preferredProjectId: agendaProjectId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(agenda.todayOverviewCalls, 1);
      expect(find.byType(ChoiceChip), findsNothing);
      for (final action in const [
        (Key('reminder-primary-today'), 'Bugün', Icons.today_outlined, true),
        (
          Key('reminder-primary-tomorrow'),
          'Yarın',
          Icons.wb_sunny_outlined,
          false,
        ),
        (
          Key('reminder-primary-after'),
          'Sonrası',
          Icons.date_range_outlined,
          false,
        ),
      ]) {
        final finder = find.byKey(action.$1);
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
        expect(
          find.descendant(of: finder, matching: find.text(action.$2)),
          findsOneWidget,
        );
        expect(
          _semanticsByKey(tester, action.$1).properties.selected,
          action.$4,
        );
        expect(find.bySemanticsLabel(action.$2), findsOneWidget);
        expect(
          find.descendant(of: finder, matching: find.byIcon(action.$3)),
          findsOneWidget,
        );
      }
      final overdueSection = find.byKey(const Key('reminder-section-overdue'));
      final allDaySection = find.byKey(const Key('reminder-section-all-day'));
      final timedSection = find.byKey(
        const Key('reminder-section-timed-today'),
      );
      expect(overdueSection, findsOneWidget);
      expect(allDaySection, findsOneWidget);
      expect(timedSection, findsOneWidget);
      expect(
        tester.getTopLeft(overdueSection).dy,
        lessThan(tester.getTopLeft(allDaySection).dy),
      );
      expect(
        tester.getTopLeft(allDaySection).dy,
        lessThan(tester.getTopLeft(timedSection).dy),
      );
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
      semantics.dispose();
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
        home: Scaffold(
          body: RemindersPage(
            agenda: agenda,
            preferredProjectId: agendaProjectId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-today-empty')), findsOneWidget);
    expect(find.text('Bugün için hatırlatıcın yok.'), findsOneWidget);
    expect(find.byKey(const Key('reminder-section-overdue')), findsNothing);
    expect(find.byKey(const Key('reminder-section-timed-today')), findsNothing);
    expect(find.byKey(const Key('reminder-section-all-day')), findsNothing);
  });

  testWidgets('Other menu keeps secondary views and inbox count reachable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final agenda = FakeAgendaApplication(
      reminders: [
        for (var index = 0; index < 3; index++)
          reminder(
            id: widgetReminderId(index + 900),
            status: ReminderStatus.inbox,
          ),
      ],
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
        home: Scaffold(
          body: RemindersPage(
            agenda: agenda,
            preferredProjectId: agendaProjectId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inboxAction = find.byKey(const Key('reminder-inbox-count'));
    expect(inboxAction, findsOneWidget);
    expect(tester.getSize(inboxAction), const Size.square(48));
    expect(
      _iconButtonByKey(tester, const Key('reminder-inbox-count')).tooltip,
      'Unutma Kutusu, 3 kayıt',
    );
    expect(
      _iconButtonByKey(tester, const Key('reminder-inbox-count')).isSelected,
      isNull,
    );
    expect(
      _semanticsByKey(
        tester,
        const Key('reminder-inbox-count'),
      ).properties.selected,
      isNull,
    );
    expect(
      find.descendant(of: inboxAction, matching: find.text('3')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Unutma Kutusu, 3 kayıt',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Unutma Kutusunda'), findsNothing);
    await tester.tap(inboxAction);
    await tester.pumpAndSettle();
    expect(agenda.lastReminderGroup, ReminderViewGroup.inbox);
    expect(
      tester.widget<Text>(find.byKey(const Key('reminder-other-title'))).data,
      'Unutma Kutusu',
    );

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
    semantics.dispose();
  });

  testWidgets('trash view has exact empty state', (tester) async {
    final agenda = FakeAgendaApplication();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemindersPage(
            agenda: agenda,
            preferredProjectId: agendaProjectId,
          ),
        ),
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
            home: Scaffold(
              body: RemindersPage(
                agenda: agenda,
                preferredProjectId: agendaProjectId,
              ),
            ),
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
      await tester.pumpAndSettle();
      expect(tester.getSize(restore), const Size.square(48));
      expect(
        _iconButtonByKey(tester, Key('restore-reminder-${item.id}')).tooltip,
        'Geri yükle',
      );
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
    expect(tester.getSize(trash), const Size.square(48));
    expect(
      _iconButtonByKey(tester, const Key('trash-reminder')).tooltip,
      'Sil',
    );
    await tester.tap(trash);
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcı silinsin mi?'), findsOneWidget);
    expect(find.textContaining('Ajanda, Puantaj veya Beton'), findsOneWidget);
    expect(find.textContaining('geri getirilebilir'), findsOneWidget);
    expect(find.text('Vazgeç'), findsOneWidget);
    expect(find.text('Sil'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-trash-reminder')));
    await tester.pumpAndSettle();

    expect(
      agenda.lastMutationCommand!.action,
      ReminderMutationAction.moveToTrash,
    );
    expect(find.byKey(const Key('reminder-trashed-at')), findsOneWidget);
    final restore = find.byKey(const Key('restore-reminder'));
    expect(restore, findsOneWidget);
    expect(tester.getSize(restore), const Size.square(48));
    expect(
      _iconButtonByKey(tester, const Key('restore-reminder')).tooltip,
      'Geri yükle',
    );
    expect(find.text('Geri yükle'), findsNothing);
    expect(find.byKey(const Key('edit-reminder')), findsNothing);
  });

  testWidgets('trashed source-linked detail keeps archived Agenda state', (
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
        sourceLogArchivedAt: '2026-07-20T07:00:00Z',
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
      find.byKey(const Key('reminder-source-agenda-archived')),
      findsOneWidget,
    );
    expect(find.text('Kaynak Ajanda arşivde'), findsOneWidget);
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
          home: ReminderDetailPage(
            key: UniqueKey(),
            agenda: agenda,
            reminderId: item.id,
          ),
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

  testWidgets('source Agenda action is icon-only and opens the exact log', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final source = sourceAgendaLog();
    final item = reminder(
      projectId: source.projectId,
      projectName: source.projectName,
      sourceLogId: source.id,
    );
    final agenda = FakeAgendaApplication(
      logs: [source],
      reminders: [item],
      reminderDetail: item,
      sourceAgendaMedia: ReminderSourceAgendaMedia.loaded(
        sourceLogId: source.id,
        sourceLogArchivedAt: null,
        photos: const [],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(const Key('open-source-agenda-log'));
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getSize(action), const Size.square(48));
    expect(
      _iconButtonByKey(tester, const Key('open-source-agenda-log')).tooltip,
      'Kaynak Ajanda kaydına dön',
    );
    expect(find.bySemanticsLabel('Kaynak Ajanda kaydına dön'), findsOneWidget);
    expect(find.text('Kaynak Ajanda kaydına dön'), findsNothing);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(LogDetailPage), findsOneWidget);
    semantics.dispose();
  });

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

  testWidgets('Ajanda sync action appears only for eligible real field diffs', (
    tester,
  ) async {
    final source = sourceAgendaLog();

    MobileReminder matchingTarget({
      String title = 'Ajanda başlığı',
      String? description = 'Ajanda açıklaması',
      ReminderStatus status = ReminderStatus.active,
      String? trashedAt,
      String projectId = agendaProjectId,
      String? locationId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      String? stableLocationName = 'A Blok / Kat 1',
      String? location = 'A Blok / Kat 1',
    }) => reminder(
      title: title,
      description: description,
      status: status,
      trashedAt: trashedAt,
      projectId: projectId,
      projectName: 'Şantiye A',
      sourceLogId: agendaSourceLogId,
      locationId: locationId,
      stableLocationName: stableLocationName,
      location: location,
    );

    Future<void> pumpCase(
      String name, {
      required MobileReminder item,
      required AgendaLog log,
      required bool actionVisible,
      Object? sourceFailure,
    }) async {
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
        logs: [log],
        agendaLogDetailFailure: sourceFailure,
      );
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey('sync-case-$name'),
          home: ReminderDetailPage(
            key: ValueKey('sync-detail-$name'),
            agenda: agenda,
            reminderId: item.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final syncAction = find.byKey(
        const Key('sync-agenda-to-reminder'),
        skipOffstage: false,
      );
      expect(
        syncAction,
        actionVisible ? findsOneWidget : findsNothing,
        reason: name,
      );
      expect(agenda.syncAgendaToReminderCalls, 0, reason: name);
    }

    await pumpCase(
      'title',
      item: matchingTarget(title: 'Eski başlık'),
      log: source,
      actionVisible: true,
    );
    await pumpCase(
      'description',
      item: matchingTarget(description: 'Eski açıklama'),
      log: source,
      actionVisible: true,
    );
    await pumpCase(
      'location',
      item: matchingTarget(
        locationId: null,
        stableLocationName: null,
        location: 'Eski mahal',
      ),
      log: source,
      actionVisible: true,
    );
    await pumpCase(
      'no-diff',
      item: matchingTarget(),
      log: source,
      actionVisible: false,
    );
    await pumpCase(
      'archived-source',
      item: matchingTarget(title: 'Eski başlık'),
      log: sourceAgendaLog(archivedAt: '2026-07-20T07:00:00Z'),
      actionVisible: false,
    );
    await pumpCase(
      'trashed-target',
      item: matchingTarget(
        title: 'Eski başlık',
        trashedAt: '2026-07-20T07:00:00Z',
      ),
      log: source,
      actionVisible: false,
    );
    await pumpCase(
      'completed-target',
      item: matchingTarget(
        title: 'Eski başlık',
        status: ReminderStatus.completed,
      ),
      log: source,
      actionVisible: false,
    );
    await pumpCase(
      'cancelled-target',
      item: matchingTarget(
        title: 'Eski başlık',
        status: ReminderStatus.cancelled,
      ),
      log: source,
      actionVisible: false,
    );
    await pumpCase(
      'project-mismatch',
      item: matchingTarget(
        title: 'Eski başlık',
        projectId: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
      ),
      log: source,
      actionVisible: false,
    );
    await pumpCase(
      'source-load-failure',
      item: matchingTarget(title: 'Eski başlık'),
      log: source,
      sourceFailure: StateError('private database path'),
      actionVisible: false,
    );
  });

  testWidgets(
    'Ajanda sync dialog shows only diffs and requires a selected field',
    (tester) async {
      final source = sourceAgendaLog(notes: null);
      final item = reminder(
        title: 'Eski başlık',
        description: 'Eski açıklama',
        projectId: agendaProjectId,
        projectName: 'Şantiye A',
        sourceLogId: agendaSourceLogId,
      );
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
        logs: [source],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
        ),
      );
      await tester.pumpAndSettle();
      await openAgendaReminderSyncDialog(tester);

      for (final field in AgendaReminderSyncField.values) {
        final tile = find.byKey(Key('agenda-sync-field-${field.storageValue}'));
        expect(tile, findsOneWidget);
        expect(tester.widget<CheckboxListTile>(tile).value, isTrue);
      }
      final dialog = find.byKey(const Key('agenda-reminder-sync-dialog'));
      expect(
        find.descendant(of: dialog, matching: find.text('Başlık')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Açıklama')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Mahal')),
        findsOneWidget,
      );
      expect(find.text('Hatırlatıcı: Eski başlık'), findsOneWidget);
      expect(find.text('Ajanda: Ajanda başlığı'), findsOneWidget);
      expect(find.text('Hatırlatıcı: Eski açıklama'), findsOneWidget);
      expect(find.text('Ajanda: Boş'), findsOneWidget);
      expect(find.text('Hatırlatıcı: Boş'), findsOneWidget);
      expect(find.text('Ajanda: A Blok / Kat 1'), findsOneWidget);

      for (final field in AgendaReminderSyncField.values) {
        final tile = find.byKey(Key('agenda-sync-field-${field.storageValue}'));
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pump();
      }
      final confirm = find.byKey(const Key('confirm-agenda-reminder-sync'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.tap(find.byKey(const Key('cancel-agenda-reminder-sync')));
      await tester.pumpAndSettle();
      expect(agenda.syncAgendaToReminderCalls, 0);
    },
  );

  testWidgets(
    'Ajanda sync confirm sends exact snapshots and preserves unselected fields',
    (tester) async {
      final source = sourceAgendaLog(revision: 7);
      final item = reminder(
        title: 'Eski başlık',
        captureText: 'İlk hızlı yakalama değişmez',
        description: 'Eski açıklama',
        kind: ReminderKind.recheck,
        projectId: agendaProjectId,
        projectName: 'Şantiye A',
        sourceLogId: agendaSourceLogId,
        location: 'Eski mahal',
        relatedPerson: 'Ahmet Usta',
        isImportant: true,
        nextAttentionAt: '2026-07-20T09:30:00Z',
        deadlineAt: '2026-07-21T12:00:00Z',
        conditionText: 'Yağmur durunca',
        outcomeType: ReminderOutcomeType.noLongerNeeded,
        outcomeNote: 'Korunacak sonuç',
        revision: 4,
      );
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
        logs: [source],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
        ),
      );
      await tester.pumpAndSettle();
      await openAgendaReminderSyncDialog(tester);

      for (final field in [
        AgendaReminderSyncField.description,
        AgendaReminderSyncField.location,
      ]) {
        final tile = find.byKey(Key('agenda-sync-field-${field.storageValue}'));
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pump();
      }
      await tester.tap(find.byKey(const Key('confirm-agenda-reminder-sync')));
      await tester.pumpAndSettle();

      expect(agenda.syncAgendaToReminderCalls, 1);
      final command = agenda.lastSyncAgendaToReminderCommand!;
      expect(command.sourceLogId, agendaSourceLogId);
      expect(command.reminderId, item.id);
      expect(command.expectedSourceRevision, 7);
      expect(command.expectedTargetRevision, 4);
      expect(command.selectedFields, {AgendaReminderSyncField.title});
      final ids = {
        command.operationId,
        command.sourceEventId,
        command.targetEventId,
      };
      expect(ids.length, 3);
      expect(ids.every(RecordId.isUuid), isTrue);

      final updated = agenda.reminderDetail!;
      expect(updated.title, source.description);
      expect(updated.description, item.description);
      expect(updated.locationId, item.locationId);
      expect(updated.location, item.location);
      expect(updated.captureText, item.captureText);
      expect(updated.kind, item.kind);
      expect(updated.status, item.status);
      expect(updated.nextAttentionAt, item.nextAttentionAt);
      expect(updated.deadlineAt, item.deadlineAt);
      expect(updated.isImportant, item.isImportant);
      expect(updated.relatedPerson, item.relatedPerson);
      expect(updated.conditionText, item.conditionText);
      expect(updated.outcomeType, item.outcomeType);
      expect(updated.outcomeNote, item.outcomeNote);
      expect(updated.revision, 5);
      expect(find.byKey(const Key('sync-agenda-to-reminder')), findsOneWidget);
    },
  );

  testWidgets(
    'Ajanda sync success reloads exact target and leaves sibling untouched',
    (tester) async {
      final source = sourceAgendaLog();
      final item = reminder(
        title: 'Eski başlık',
        description: 'Eski açıklama',
        projectId: agendaProjectId,
        projectName: 'Şantiye A',
        sourceLogId: agendaSourceLogId,
        location: 'Eski mahal',
        revision: 2,
      );
      final sibling = reminder(
        id: widgetReminderId(196),
        title: 'Diğer bağlı Hatırlatıcı',
        description: 'Değişmemeli',
        projectId: agendaProjectId,
        projectName: 'Şantiye A',
        sourceLogId: agendaSourceLogId,
        location: 'Diğer mahal',
        revision: 8,
      );
      final agenda = FakeAgendaApplication(
        reminders: [item, sibling],
        reminderDetail: item,
        logs: [source],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
        ),
      );
      await tester.pumpAndSettle();
      await openAgendaReminderSyncDialog(tester);
      await tester.tap(find.byKey(const Key('confirm-agenda-reminder-sync')));
      await tester.pumpAndSettle();

      expect(agenda.syncAgendaToReminderCalls, 1);
      expect(agenda.reminderLifecycleDetailCalls, greaterThanOrEqualTo(2));
      expect(agenda.getAgendaLogDetailCalls, greaterThanOrEqualTo(2));
      expect(agenda.reminderDetail!.title, source.description);
      expect(agenda.reminderDetail!.description, source.notes);
      expect(agenda.reminderDetail!.locationId, source.locationId);
      expect(agenda.reminderDetail!.location, source.stableLocationName);
      expect(agenda.reminderDetail!.revision, 3);
      final unchangedSibling = agenda.reminders.singleWhere(
        (value) => value.id == sibling.id,
      );
      expect(unchangedSibling.title, sibling.title);
      expect(unchangedSibling.description, sibling.description);
      expect(unchangedSibling.location, sibling.location);
      expect(unchangedSibling.revision, sibling.revision);
      expect(find.byKey(const Key('sync-agenda-to-reminder')), findsNothing);
      expect(find.text('Ajanda’dan güncellendi'), findsOneWidget);
    },
  );

  testWidgets(
    'Ajanda sync stale failure keeps old snapshot and safely reloads diff',
    (tester) async {
      final source = sourceAgendaLog();
      final item = reminder(
        title: 'Eski başlık',
        description: source.notes,
        projectId: agendaProjectId,
        projectName: 'Şantiye A',
        sourceLogId: agendaSourceLogId,
        locationId: source.locationId,
        stableLocationName: source.stableLocationName,
        location: source.stableLocationName,
      );
      const staleMessage =
          'Hatırlatıcı başka bir işlemle değişti. Ekranı yenileyin.';
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
        logs: [source],
        syncAgendaToReminderFailure: const AgendaValidationFailure(
          staleMessage,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
        ),
      );
      await tester.pumpAndSettle();
      await openAgendaReminderSyncDialog(tester);
      await tester.tap(find.byKey(const Key('confirm-agenda-reminder-sync')));
      await tester.pumpAndSettle();

      expect(agenda.syncAgendaToReminderCalls, 1);
      expect(agenda.reminderLifecycleDetailCalls, greaterThanOrEqualTo(2));
      expect(agenda.getAgendaLogDetailCalls, greaterThanOrEqualTo(2));
      expect(agenda.reminderDetail!.title, item.title);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pump();
      expect(find.text(item.title), findsOneWidget);
      expect(find.byKey(const Key('reminder-detail-error')), findsOneWidget);
      expect(find.text(staleMessage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('sync-agenda-to-reminder')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('sync-agenda-to-reminder')), findsOneWidget);
    },
  );

  testWidgets('Ajanda sync action and confirm are double-tap safe', (
    tester,
  ) async {
    final source = sourceAgendaLog();
    final item = reminder(
      title: 'Eski başlık',
      description: source.notes,
      projectId: agendaProjectId,
      projectName: 'Şantiye A',
      sourceLogId: agendaSourceLogId,
      locationId: source.locationId,
      stableLocationName: source.stableLocationName,
      location: source.stableLocationName,
    );
    final completer = Completer<AgendaReminderSyncResult>();
    final agenda = FakeAgendaApplication(
      reminders: [item],
      reminderDetail: item,
      logs: [source],
    )..syncAgendaToReminderCompleter = completer;
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: item.id),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(const Key('sync-agenda-to-reminder'));
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(action);
    await tester.tap(action, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('agenda-reminder-sync-dialog')),
      findsOneWidget,
    );

    final confirm = find.byKey(const Key('confirm-agenda-reminder-sync'));
    await tester.tap(confirm);
    await tester.tap(confirm, warnIfMissed: false);
    await tester.pump();
    expect(agenda.syncAgendaToReminderCalls, 1);
    expect(find.byType(ReminderDetailPage), findsOneWidget);

    final command = agenda.lastSyncAgendaToReminderCommand!;
    completer.complete(
      AgendaReminderSyncResult(
        operationId: command.operationId,
        sourceLogId: command.sourceLogId,
        reminderId: command.reminderId,
        sourceRevision: source.revision,
        targetRevisionBefore: item.revision,
        targetRevisionAfter: item.revision,
        selectedFields: const [AgendaReminderSyncField.title],
        copiedFields: const [],
        changes: const {},
        changed: false,
        idempotent: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(agenda.syncAgendaToReminderCalls, 1);
    expect(find.byKey(const Key('sync-agenda-to-reminder')), findsOneWidget);
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
      _expectPrimaryFormAction(tester, submit, 'Kaydediliyor…', enabled: false);
      expect(
        find.descendant(
          of: submit,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
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

  testWidgets('Yarın 08:00 quick action is guarded against double tap', (
    tester,
  ) async {
    final completer = Completer<MobileReminder>();
    final item = reminder();
    final agenda = FakeAgendaApplication(reminders: [item])
      ..mutateReminderCompleter = completer;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemindersPage(
            agenda: agenda,
            preferredProjectId: agendaProjectId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(Key('reminder-tomorrow-${item.id}'));
    expect(action, findsOneWidget);
    expect(tester.getSize(action), const Size.square(48));
    expect(
      _iconButtonByKey(tester, Key('reminder-tomorrow-${item.id}')).tooltip,
      "Yarın 08:00'a ertele",
    );
    expect(find.text('Yarın 08:00'), findsNothing);
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
    'Yarın 08:00 moves Today card to Tomorrow and then stays hidden',
    (tester) async {
      final item = reminder();
      final agenda = FakeAgendaApplication(reminders: [item]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemindersPage(
              agenda: agenda,
              preferredProjectId: agendaProjectId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final todayAction = find.byKey(Key('reminder-tomorrow-${item.id}'));
      expect(todayAction, findsOneWidget);
      expect(
        _iconButtonByKey(tester, Key('reminder-tomorrow-${item.id}')).tooltip,
        "Yarın 08:00'a ertele",
      );
      expect(find.text('Yarın 08:00'), findsNothing);
      expect(find.text('Yarın'), findsOneWidget);
      await tester.tap(todayAction);
      await tester.pumpAndSettle();
      expect(agenda.reminders.single.nextAttentionAt, '2026-07-21T05:00:00Z');
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
      expect(upcomingAction, findsNothing);
    },
  );

  testWidgets('all-day card retains Yarına ertele and advances one day', (
    tester,
  ) async {
    final item = reminder(allDayLocalDate: '2026-07-20');
    final agenda = FakeAgendaApplication(reminders: [item]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemindersPage(
            agenda: agenda,
            preferredProjectId: agendaProjectId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(Key('reminder-tomorrow-${item.id}'));
    expect(action, findsOneWidget);
    expect(
      _iconButtonByKey(tester, Key('reminder-tomorrow-${item.id}')).tooltip,
      'Yarına ertele',
    );
    expect(find.text('Yarına ertele'), findsNothing);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(agenda.reminders.single.allDayLocalDate, '2026-07-21');
    expect(agenda.reminders.single.nextAttentionAt, isNull);
  });

  testWidgets(
    'Today and overdue cards show tomorrow while future stays hidden',
    (tester) async {
      final today = reminder(
        id: widgetReminderId(101),
        title: 'Sentetik bugün',
        nextAttentionAt: '2026-07-20T06:00:00Z',
      );
      final overdue = reminder(
        id: widgetReminderId(102),
        title: 'Sentetik geciken',
        nextAttentionAt: '2026-07-20T04:00:00Z',
      );
      final future = reminder(
        id: widgetReminderId(103),
        title: 'Sentetik gelecek',
        nextAttentionAt: '2026-07-22T06:00:00Z',
      );
      final agenda = FakeAgendaApplication(reminders: [today, overdue, future]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemindersPage(
              agenda: agenda,
              preferredProjectId: agendaProjectId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('reminder-tomorrow-${today.id}')), findsOneWidget);
      expect(
        find.byKey(Key('reminder-tomorrow-${overdue.id}')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('reminder-primary-other')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-other-upcoming')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('reminder-${future.id}')), findsOneWidget);
      expect(find.byKey(Key('reminder-tomorrow-${future.id}')), findsNothing);
    },
  );

  testWidgets(
    'Puantaj card and detail hide tomorrow and source action still opens',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final item = reminder(
        id: widgetReminderId(104),
        title: 'Sentetik Puantaj hatırlatıcısı',
        nextAttentionAt: '2026-07-20T06:00:00Z',
        projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        projectName: 'Sentetik proje',
        attendanceDayId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      );
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
      );
      final attendance = FakeAttendanceApplication();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: Scaffold(
              body: RemindersPage(
                agenda: agenda,
                attendance: attendance,
                preferredProjectId: agendaProjectId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('reminder-${item.id}')), findsOneWidget);
      expect(find.byKey(Key('reminder-tomorrow-${item.id}')), findsNothing);
      await tester.tap(find.byKey(Key('reminder-${item.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('snooze-tomorrow')), findsNothing);
      final source = find.byKey(const Key('open-source-attendance-day'));
      await tester.scrollUntilVisible(
        source,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(source, findsOneWidget);
      expect(tester.getSize(source), const Size.square(48));
      expect(
        _iconButtonByKey(
          tester,
          const Key('open-source-attendance-day'),
        ).tooltip,
        'Kaynak Puantaj gününe dön',
      );
      expect(
        find.bySemanticsLabel('Kaynak Puantaj gününe dön'),
        findsOneWidget,
      );
      expect(find.text('Kaynak Puantaj gününe dön'), findsNothing);
      await tester.tap(source);
      await tester.pumpAndSettle();
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isTrue,
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
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
        home: Scaffold(
          body: RemindersPage(
            agenda: agenda,
            preferredProjectId: agendaProjectId,
          ),
        ),
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
        home: Scaffold(
          body: RemindersPage(
            agenda: agenda,
            preferredProjectId: agendaProjectId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reminder-primary-tomorrow')));
    await tester.pumpAndSettle();

    expect(agenda.lastReminderGroup, ReminderViewGroup.tomorrow);
    expect(
      _semanticsByKey(
        tester,
        const Key('reminder-primary-today'),
      ).properties.selected,
      isFalse,
    );
    expect(
      _semanticsByKey(
        tester,
        const Key('reminder-primary-tomorrow'),
      ).properties.selected,
      isTrue,
    );
    expect(
      _semanticsByKey(
        tester,
        const Key('reminder-primary-after'),
      ).properties.selected,
      isFalse,
    );
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
      final item = reminder(nextAttentionAt: '2026-07-21T06:00:00Z');
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: MaterialApp(
            theme: ThemeData(brightness: configuration.brightness),
            home: Scaffold(
              body: RemindersPage(
                agenda: agenda,
                preferredProjectId: agendaProjectId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tomorrowGroup = find.byKey(const Key('reminder-primary-tomorrow'));
      expect(tomorrowGroup, findsOneWidget);
      expect(tester.getSize(tomorrowGroup).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(tomorrowGroup).width, greaterThanOrEqualTo(48));
      await tester.tap(tomorrowGroup);
      await tester.pumpAndSettle();
      expect(agenda.lastReminderGroup, ReminderViewGroup.tomorrow);
      expect(find.byKey(Key('reminder-tomorrow-${item.id}')), findsNothing);

      final reminderCard = find.byKey(Key('reminder-${item.id}'));
      await tester.ensureVisible(reminderCard);
      await tester.pumpAndSettle();
      await tester.tap(reminderCard);
      await tester.pumpAndSettle();
      expect(find.byType(ReminderDetailPage), findsOneWidget);
      final detailTomorrow = find.byKey(const Key('snooze-tomorrow'));
      expect(detailTomorrow, findsNothing);
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
          home: ReminderDetailPage(
            agenda: agenda,
            reminderId: reminderId,
            istanbulToday: '2026-07-20',
          ),
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

  testWidgets('Erkene al is visible only for eligible active timed reminder', (
    tester,
  ) async {
    Future<void> pumpDetail(MobileReminder item) async {
      final agenda = FakeAgendaApplication(
        reminders: [item],
        reminderDetail: item,
        asOfUtc: DateTime.utc(2026, 7, 19, 8),
      );
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: ReminderDetailPage(
            key: UniqueKey(),
            agenda: agenda,
            reminderId: item.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpDetail(reminder(nextAttentionAt: '2026-07-19T12:00:00Z'));
    final earlier = find.byKey(const Key('earlier-reminder'));
    expect(earlier, findsOneWidget);
    await tester.scrollUntilVisible(
      earlier,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      _iconButtonByKey(tester, const Key('earlier-reminder')).tooltip,
      'Erkene al',
    );
    expect(find.text('Erkene al'), findsNothing);

    for (final item in [
      reminder(allDayLocalDate: '2026-07-19'),
      reminder(status: ReminderStatus.inbox),
      reminder(status: ReminderStatus.completed),
      reminder(trashedAt: '2026-07-19T08:00:00Z'),
      reminder(
        nextAttentionAt: '2026-07-19T12:00:00Z',
        attendanceDayId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      ),
    ]) {
      await pumpDetail(item);
      expect(find.byKey(const Key('earlier-reminder')), findsNothing);
    }
  });

  testWidgets(
    'Erkene al shows exact old-new values and submits future earlier once',
    (tester) async {
      await withClock(Clock.fixed(DateTime.utc(2026, 7, 19, 8)), () async {
        final item = reminder(nextAttentionAt: '2026-07-19T12:00:00Z');
        final updatedItem = reminder(nextAttentionAt: '2026-07-19T11:00:00Z');
        final mutationCompleter = Completer<MobileReminder>();
        final agenda = FakeAgendaApplication(
          reminders: [item],
          reminderDetail: item,
          asOfUtc: DateTime.utc(2026, 7, 19, 8),
        )..mutateReminderCompleter = mutationCompleter;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(alwaysUse24HourFormat: true),
            child: MaterialApp(
              home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final earlier = find.byKey(const Key('earlier-reminder'));
        expect(earlier, findsOneWidget);
        await tester.scrollUntilVisible(
          earlier,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(earlier);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        await chooseEarlierLocalTime(tester, hour: 14);

        expect(
          find.byKey(const Key('reminder-earlier-current-time')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('reminder-earlier-selected-time')),
          findsOneWidget,
        );
        expect(find.text('19.07.2026 15:00'), findsOneWidget);
        expect(find.text('19.07.2026 14:00'), findsOneWidget);
        final confirm = find.byKey(const Key('confirm-earlier-reminder'));
        await tester.tap(confirm);
        await tester.pump();
        await tester.tap(confirm, warnIfMissed: false);

        expect(agenda.mutateReminderCalls, 1);
        agenda
          ..reminders = [updatedItem]
          ..reminderDetail = updatedItem;
        mutationCompleter.complete(updatedItem);
        await tester.pumpAndSettle();
        expect(
          agenda.lastMutationCommand!.action,
          ReminderMutationAction.schedule,
        );
        expect(
          agenda.lastMutationCommand!.schedule,
          ReminderScheduleKind.custom,
        );
        expect(
          agenda.lastMutationCommand!.customAttentionAt,
          '2026-07-19T11:00:00Z',
        );
      });
    },
  );

  testWidgets(
    'past earlier selection requires second explicit confirmation and cancel is safe',
    (tester) async {
      await withClock(Clock.fixed(DateTime.utc(2026, 7, 19, 8)), () async {
        final item = reminder(nextAttentionAt: '2026-07-19T12:00:00Z');
        final agenda = FakeAgendaApplication(
          reminders: [item],
          reminderDetail: item,
          asOfUtc: DateTime.utc(2026, 7, 19, 8),
        );
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(alwaysUse24HourFormat: true),
            child: MaterialApp(
              home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final earlier = find.byKey(const Key('earlier-reminder'));
        expect(earlier, findsOneWidget);
        await tester.scrollUntilVisible(
          earlier,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(earlier);
        await tester.pumpAndSettle();
        await chooseEarlierLocalTime(tester, hour: 10);
        await tester.tap(find.byKey(const Key('confirm-earlier-reminder')));
        await tester.pumpAndSettle();

        expect(agenda.mutateReminderCalls, 1);
        expect(
          find.byKey(const Key('confirm-past-earlier-reminder')),
          findsOneWidget,
        );
        expect(find.textContaining('geçmişte kalıyor'), findsOneWidget);
        expect(find.text('Geçmiş zamana al'), findsOneWidget);
        await tester.tap(find.text('Vazgeç'));
        await tester.pumpAndSettle();
        expect(agenda.mutateReminderCalls, 1);
        expect(agenda.reminders.single.revision, item.revision);

        await tester.scrollUntilVisible(
          earlier,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(earlier);
        await tester.pumpAndSettle();
        await chooseEarlierLocalTime(tester, hour: 10);
        await tester.tap(find.byKey(const Key('confirm-earlier-reminder')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('confirm-past-earlier-reminder')),
        );
        await tester.pumpAndSettle();

        expect(agenda.mutateReminderCalls, 3);
        expect(
          agenda.lastMutationCommand!.customAttentionAt,
          '2026-07-19T07:00:00Z',
        );
        expect(agenda.reminders.single.nextAttentionAt, '2026-07-19T07:00:00Z');
        expect(agenda.reminders.single.revision, item.revision + 1);
      });
    },
  );

  testWidgets(
    'same or later earlier selection offers Planla without mutation',
    (tester) async {
      await withClock(Clock.fixed(DateTime.utc(2026, 7, 19, 8)), () async {
        final item = reminder(nextAttentionAt: '2026-07-19T12:00:00Z');
        final agenda = FakeAgendaApplication(
          reminders: [item],
          reminderDetail: item,
          asOfUtc: DateTime.utc(2026, 7, 19, 8),
        );
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(alwaysUse24HourFormat: true),
            child: MaterialApp(
              home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final earlier = find.byKey(const Key('earlier-reminder'));
        expect(earlier, findsOneWidget);
        await tester.scrollUntilVisible(
          earlier,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(earlier);
        await tester.pumpAndSettle();
        await chooseEarlierLocalTime(tester, hour: 15);

        expect(agenda.mutateReminderCalls, 0);
        expect(
          find.textContaining('mevcut zamandan daha erken'),
          findsOneWidget,
        );
        final plan = find.byKey(const Key('open-schedule-from-earlier'));
        expect(plan, findsOneWidget);
        await tester.tap(plan);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('reminder-schedule-option-in15Minutes')),
          findsOneWidget,
        );
        expect(agenda.mutateReminderCalls, 0);
      });
    },
  );

  testWidgets('earlier date picker cancellation leaves reminder untouched', (
    tester,
  ) async {
    final item = reminder(nextAttentionAt: '2026-07-19T12:00:00Z');
    final agenda = FakeAgendaApplication(
      reminders: [item],
      reminderDetail: item,
      asOfUtc: DateTime.utc(2026, 7, 19, 8),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: reminderId),
      ),
    );
    await tester.pumpAndSettle();

    final earlier = find.byKey(const Key('earlier-reminder'));
    expect(earlier, findsOneWidget);
    await tester.scrollUntilVisible(
      earlier,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(earlier);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect(agenda.mutateReminderCalls, 0);
    expect(agenda.reminders.single.revision, item.revision);
  });

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
        home: ReminderDetailPage(
          agenda: agenda,
          reminderId: reminderId,
          istanbulToday: '2026-07-20',
        ),
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
      key: 'snooze-1h',
      label: '1 saat ertele',
      badge: '1',
      action: ReminderMutationAction.snooze1Hour,
    ),
    (
      key: 'snooze-2h',
      label: '2 saat ertele',
      badge: '2',
      action: ReminderMutationAction.snooze2Hours,
    ),
    (
      key: 'snooze-3h',
      label: '3 saat ertele',
      badge: '3',
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
      expect(tester.getSize(action), const Size.square(48));
      expect(
        _iconButtonByKey(tester, Key(quickAction.key)).tooltip,
        quickAction.label,
      );
      expect(
        find.descendant(of: action, matching: find.text(quickAction.badge)),
        findsOneWidget,
      );
      expect(find.text(quickAction.label), findsNothing);
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

  testWidgets('active timed detail planning sheet exposes Tam gün option', (
    tester,
  ) async {
    final item = reminder(nextAttentionAt: '2026-07-20T06:00:00Z');
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

    final allDay = find.byKey(const Key('reminder-schedule-option-allDay'));
    await tester.scrollUntilVisible(
      allDay,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(allDay, findsOneWidget);
    expect(find.text('Tam gün'), findsOneWidget);
  });

  for (final configuration in [
    (
      name: 'timed local day',
      item: reminder(nextAttentionAt: '2026-07-20T21:30:00Z'),
      today: '2026-07-19',
      expected: DateTime(2026, 7, 21),
    ),
    (
      name: 'existing all-day',
      item: reminder(allDayLocalDate: '2026-07-24'),
      today: '2026-07-19',
      expected: DateTime(2026, 7, 24),
    ),
    (
      name: 'inbox Istanbul today',
      item: reminder(status: ReminderStatus.inbox),
      today: '2026-07-19',
      expected: DateTime(2026, 7, 19),
    ),
  ]) {
    testWidgets('Tam gün picker starts from ${configuration.name}', (
      tester,
    ) async {
      final agenda = FakeAgendaApplication(
        reminders: [configuration.item],
        reminderDetail: configuration.item,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(
            agenda: agenda,
            reminderId: reminderId,
            istanbulToday: configuration.today,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openDetailAllDayPicker(tester);

      final picker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(picker.initialDate, configuration.expected);
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(agenda.mutateReminderCalls, 0);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(agenda.mutateReminderCalls, 0);
    });
  }

  testWidgets(
    'Tam gün previews exact day and mutates only after explicit confirmation',
    (tester) async {
      await withClock(Clock.fixed(DateTime.utc(2026, 7, 19, 8)), () async {
        final item = reminder(nextAttentionAt: '2026-07-20T06:00:00Z');
        final agenda = FakeAgendaApplication(
          reminders: [item],
          reminderDetail: item,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: ReminderDetailPage(
              agenda: agenda,
              reminderId: reminderId,
              istanbulToday: '2026-07-19',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await openDetailAllDayPicker(tester);
        expect(find.byType(TimePickerDialog), findsNothing);
        await tester.tap(find.text('21').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('İleri'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('reminder-all-day-schedule-preview')),
          findsOneWidget,
        );
        expect(find.text('21.07.2026 • Tam gün'), findsOneWidget);
        expect(agenda.mutateReminderCalls, 0);

        final confirm = find.byKey(
          const Key('confirm-reminder-all-day-schedule'),
        );
        await tester.tap(confirm);
        await tester.pumpAndSettle();

        expect(agenda.mutateReminderCalls, 1);
        expect(
          agenda.lastMutationCommand!.action,
          ReminderMutationAction.schedule,
        );
        expect(
          agenda.lastMutationCommand!.schedule,
          ReminderScheduleKind.custom,
        );
        expect(agenda.lastMutationCommand!.customAttentionAt, isNull);
        expect(agenda.lastMutationCommand!.allDayLocalDate, '2026-07-21');
        expect(agenda.reminders.single.nextAttentionAt, isNull);
        expect(agenda.reminders.single.allDayLocalDate, '2026-07-21');
        expect(find.text('21.07.2026 • Tam gün'), findsOneWidget);
      });
    },
  );

  testWidgets('Tam gün async mutation is double-tap guarded', (tester) async {
    final item = reminder(nextAttentionAt: '2026-07-20T06:00:00Z');
    final completer = Completer<MobileReminder>();
    final agenda = FakeAgendaApplication(
      reminders: [item],
      reminderDetail: item,
    )..mutateReminderCompleter = completer;
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(
          agenda: agenda,
          reminderId: reminderId,
          istanbulToday: '2026-07-19',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openDetailAllDayPicker(tester);
    await tester.tap(find.text('21').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm-reminder-all-day-schedule')),
    );
    await tester.pump();

    expect(agenda.mutateReminderCalls, 1);
    final scheduleButton = find.byKey(const Key('schedule-reminder'));
    expect(
      _iconButtonByKey(tester, const Key('schedule-reminder')).onPressed,
      isNull,
    );
    await tester.tap(scheduleButton, warnIfMissed: false);
    await tester.pump();
    expect(agenda.mutateReminderCalls, 1);

    completer.complete(item);
    await tester.pumpAndSettle();
  });

  testWidgets('Tam gün picker and confirmation cancellation mutate nothing', (
    tester,
  ) async {
    final item = reminder(nextAttentionAt: '2026-07-20T06:00:00Z');
    final agenda = FakeAgendaApplication(
      reminders: [item],
      reminderDetail: item,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(
          agenda: agenda,
          reminderId: reminderId,
          istanbulToday: '2026-07-19',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openDetailAllDayPicker(tester);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(agenda.mutateReminderCalls, 0);

    await openDetailAllDayPicker(tester);
    await tester.tap(find.text('21').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();
    expect(find.text('21.07.2026 • Tam gün'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(agenda.mutateReminderCalls, 0);
  });

  testWidgets('attendance-managed detail hides direct Tam gün option', (
    tester,
  ) async {
    final item = reminder(
      attendanceDayId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    );
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

    expect(
      find.byKey(const Key('reminder-schedule-option-allDay')),
      findsNothing,
    );
    expect(agenda.mutateReminderCalls, 0);
  });

  for (final item in [
    reminder(status: ReminderStatus.completed),
    reminder(trashedAt: '2026-07-20T07:00:00Z'),
  ]) {
    testWidgets(
      '${item.status.name}/${item.trashedAt == null ? 'active' : 'trash'} '
      'detail cannot open planning sheet',
      (tester) async {
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

        expect(find.byKey(const Key('schedule-reminder')), findsNothing);
        expect(
          find.byKey(const Key('reminder-schedule-option-allDay')),
          findsNothing,
        );
      },
    );
  }

  testWidgets('all-day detail can return to an exact timed quick schedule', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 7, 19, 8)), () async {
      final item = reminder(allDayLocalDate: '2026-07-20');
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
      await tester.tap(
        find.byKey(const Key('reminder-schedule-option-tomorrowMorning')),
      );
      await tester.pumpAndSettle();

      expect(
        agenda.lastMutationCommand!.schedule,
        ReminderScheduleKind.tomorrowMorning,
      );
      expect(
        agenda.lastMutationCommand!.customAttentionAt,
        '2026-07-20T05:00:00Z',
      );
      expect(agenda.lastMutationCommand!.allDayLocalDate, isNull);
      expect(agenda.reminders.single.allDayLocalDate, isNull);
      expect(agenda.reminders.single.nextAttentionAt, '2026-07-20T05:00:00Z');
    });
  });

  testWidgets('Tam gün flow is overflow-safe at 320 px large dark text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = reminder(nextAttentionAt: '2026-07-20T06:00:00Z');
    final agenda = FakeAgendaApplication(
      reminders: [item],
      reminderDetail: item,
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: ReminderDetailPage(
            agenda: agenda,
            reminderId: reminderId,
            istanbulToday: '2026-07-19',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openDetailAllDayPicker(tester);

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.byType(TimePickerDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail sheet previews and submits exact quick schedules', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 7, 27, 9)), () async {
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

      expect(
        find.byKey(const Key('reminder-schedule-preview-tomorrowMorning')),
        findsOneWidget,
      );
      expect(find.text('28.07.2026 08:00'), findsOneWidget);
      final weekStart = find.byKey(
        const Key('reminder-schedule-option-nextWeekStart'),
      );
      await tester.scrollUntilVisible(
        weekStart,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.byKey(const Key('reminder-schedule-preview-nextWeekStart')),
        findsOneWidget,
      );
      expect(find.text('03.08.2026 08:00'), findsOneWidget);

      await tester.tap(weekStart);
      await tester.pumpAndSettle();
      expect(
        agenda.lastMutationCommand!.action,
        ReminderMutationAction.schedule,
      );
      expect(
        agenda.lastMutationCommand!.schedule,
        ReminderScheduleKind.nextWeekStart,
      );
      expect(
        agenda.lastMutationCommand!.customAttentionAt,
        '2026-08-03T05:00:00Z',
      );
    });
  });

  for (final configuration in [
    (width: 320.0, brightness: Brightness.dark),
    (width: 430.0, brightness: Brightness.light),
  ]) {
    testWidgets('lifecycle actions fit ${configuration.width.toInt()} px '
        '${configuration.brightness.name} with large Turkish text', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
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
      expect(tester.getSize(complete), const Size.square(48));
      expect(
        _iconButtonByKey(tester, const Key('complete-reminder')).tooltip,
        'Tamamla',
      );
      expect(find.bySemanticsLabel('Tamamla'), findsOneWidget);
      expect(find.byKey(const Key('schedule-reminder')), findsOneWidget);
      expect(find.byKey(const Key('start-waiting')), findsNothing);
      final tomorrow = find.byKey(const Key('snooze-tomorrow'));
      await tester.ensureVisible(tomorrow);
      expect(tester.getSize(tomorrow), const Size.square(48));
      expect(
        _iconButtonByKey(tester, const Key('snooze-tomorrow')).tooltip,
        "Yarın 08:00'a ertele",
      );
      expect(find.bySemanticsLabel("Yarın 08:00'a ertele"), findsOneWidget);
      for (final action in const [
        (Key('complete-reminder'), 'Tamamla'),
        (Key('snooze-tomorrow'), "Yarın 08:00'a ertele"),
        (Key('snooze-15'), '15 dk ertele'),
        (Key('snooze-1h'), '1 saat ertele'),
        (Key('snooze-2h'), '2 saat ertele'),
        (Key('snooze-3h'), '3 saat ertele'),
        (Key('earlier-reminder'), 'Erkene al'),
        (Key('schedule-reminder'), 'Yeni tarih'),
        (Key('edit-reminder'), 'Düzenle'),
        (Key('trash-reminder'), 'Sil'),
        (Key('move-inbox'), 'Unutma Kutusu'),
        (Key('cancel-reminder'), 'İptal et'),
      ]) {
        final finder = find.byKey(action.$1);
        if (finder.evaluate().isEmpty) continue;
        expect(tester.getSize(finder), const Size.square(48));
        expect(_iconButtonByKey(tester, action.$1).tooltip, action.$2);
        expect(find.text(action.$2), findsNothing);
      }
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('delivery diagnostic exposes retry and user-opened settings', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
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
    expect(tester.getSize(notificationSettings), const Size.square(48));
    expect(
      _iconButtonByKey(tester, const Key('open-notification-settings')).tooltip,
      'Bildirim ayarları',
    );
    expect(find.bySemanticsLabel('Bildirim ayarları'), findsOneWidget);
    await tester.tap(notificationSettings);
    await tester.pump();
    final batterySettings = find.byKey(const Key('open-battery-settings'));
    await tester.scrollUntilVisible(
      batterySettings,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getSize(batterySettings), const Size.square(48));
    expect(
      _iconButtonByKey(tester, const Key('open-battery-settings')).tooltip,
      'Batarya ayarları',
    );
    await tester.tap(batterySettings);
    await tester.pump();
    final retry = find.byKey(const Key('retry-reminder-delivery'));
    await tester.scrollUntilVisible(
      retry,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getSize(retry), const Size.square(48));
    expect(
      _iconButtonByKey(tester, const Key('retry-reminder-delivery')).tooltip,
      'Yeniden doğrula',
    );
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(agenda.notificationSettingsCalls, 1);
    expect(agenda.batterySettingsCalls, 1);
    expect(agenda.retryCalls, 1);
    expect(find.text('Yeniden doğrula'), findsNothing);
    expect(find.text('Bildirim ayarları'), findsNothing);
    expect(find.text('Batarya ayarları'), findsNothing);
    semantics.dispose();
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

    final reopen = find.byKey(const Key('reopen-reminder'));
    expect(reopen, findsOneWidget);
    expect(tester.getSize(reopen), const Size.square(48));
    expect(
      _iconButtonByKey(tester, const Key('reopen-reminder')).tooltip,
      'Yeniden aç',
    );
    expect(find.text('Yeniden aç'), findsNothing);
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

  testWidgets(
    'Hatırlatıcı detail return keeps Diğer subview and scroll after async reload',
    (tester) async {
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reminders = List.generate(
        24,
        (index) => reminder(
          id: widgetReminderId(index + 200),
          title: 'CSE264 yaklaşan sentetik kayıt $index',
          nextAttentionAt: '2026-07-22T06:00:00Z',
        ),
      );
      final agenda = _DelayedReminderAgenda(reminders);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemindersPage(
              agenda: agenda,
              preferredProjectId: agendaProjectId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-primary-other')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-other-upcoming')));
      await tester.pumpAndSettle();

      final target = reminders[18];
      final targetFinder = find.byKey(Key('reminder-${target.id}'));
      await tester.scrollUntilVisible(
        targetFinder,
        420,
        scrollable: _reminderScrollableFinder(),
      );
      final before = _reminderScrollOffset(tester);
      expect(before, greaterThan(300));

      await tester.tap(targetFinder);
      await tester.pumpAndSettle();
      agenda.reminders = [
        for (var index = 0; index < reminders.length; index++)
          index == 18
              ? reminder(
                  id: target.id,
                  title: 'CSE264 güncel Hatırlatıcı başlığı',
                  nextAttentionAt: target.nextAttentionAt,
                )
              : reminders[index],
      ];
      final delayedReload = Completer<List<MobileReminder>>();
      agenda.delayedReminderReload = delayedReload;
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 350));
      delayedReload.complete(agenda.reminders);
      await tester.pumpAndSettle();

      expect(_reminderScrollOffset(tester), closeTo(before, 4));
      expect(agenda.lastReminderGroup, ReminderViewGroup.upcoming);
      expect(find.text('CSE264 güncel Hatırlatıcı başlığı'), findsOneWidget);
      _reminderScrollable(tester).position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('Yaklaşanlar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Hatırlatıcı detail removal clamps offset and duplicate tap opens one route',
    (tester) async {
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reminders = List.generate(
        20,
        (index) => reminder(
          id: widgetReminderId(index + 300),
          title: 'CSE264 clamp sentetik kayıt $index',
          nextAttentionAt: '2026-07-22T06:00:00Z',
        ),
      );
      final agenda = _DelayedReminderAgenda(reminders);
      final observer = _ReminderPushCountingObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Scaffold(
            body: RemindersPage(
              agenda: agenda,
              preferredProjectId: agendaProjectId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-primary-other')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder-other-upcoming')));
      await tester.pumpAndSettle();
      final target = reminders[17];
      final targetFinder = find.byKey(Key('reminder-${target.id}'));
      await tester.scrollUntilVisible(
        targetFinder,
        420,
        scrollable: _reminderScrollableFinder(),
      );
      observer.pushes = 0;

      final onTap = tester.widget<ListTile>(targetFinder).onTap!;
      onTap();
      onTap();
      await tester.pumpAndSettle();
      expect(observer.pushes, 1);

      agenda.reminders = reminders.take(2).toList();
      final delayedReload = Completer<List<MobileReminder>>();
      agenda.delayedReminderReload = delayedReload;
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 350));
      delayedReload.complete(agenda.reminders);
      await tester.pumpAndSettle();

      final scrollable = _reminderScrollable(tester);
      expect(
        scrollable.position.pixels,
        inInclusiveRange(
          scrollable.position.minScrollExtent,
          scrollable.position.maxScrollExtent,
        ),
      );
      expect(find.byKey(Key('reminder-${target.id}')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

ScrollableState _reminderScrollable(WidgetTester tester) {
  return tester.state<ScrollableState>(_reminderScrollableFinder());
}

Finder _reminderScrollableFinder() => find
    .descendant(
      of: find.byKey(const Key('reminder-list')),
      matching: find.byType(Scrollable),
    )
    .first;

double _reminderScrollOffset(WidgetTester tester) =>
    _reminderScrollable(tester).position.pixels;

class _HistoryReminderAgenda extends FakeAgendaApplication {
  _HistoryReminderAgenda(this.lifecycleDetail)
    : super(
        reminders: [lifecycleDetail.reminder],
        reminderDetail: lifecycleDetail.reminder,
      );

  final ReminderDetail lifecycleDetail;

  @override
  Future<ReminderDetail> getReminderLifecycleDetail(String reminderId) async {
    reminderLifecycleDetailCalls += 1;
    return lifecycleDetail;
  }
}

class _DelayedReminderAgenda extends FakeAgendaApplication {
  _DelayedReminderAgenda(List<MobileReminder> reminders)
    : super(reminders: reminders);

  Completer<List<MobileReminder>>? delayedReminderReload;

  @override
  Future<List<MobileReminder>> listReminders(ReminderViewGroup group) async {
    lastReminderGroup = group;
    final delayed = delayedReminderReload;
    if (delayed != null) {
      delayedReminderReload = null;
      return delayed.future;
    }
    return super.listReminders(group);
  }
}

class _ReminderPushCountingObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes += 1;
    super.didPush(route, previousRoute);
  }
}

class _FakeProjectLocations implements ProjectLocationApplication {
  _FakeProjectLocations(this.projects);

  final List<MobileProject> projects;

  @override
  Stream<void> get projectChanges => const Stream<void>.empty();

  @override
  Stream<void> get projectLocationChanges => const Stream<void>.empty();

  @override
  Future<List<MobileProject>> listProjects() async => projects;

  @override
  Future<List<MobileProjectLocation>> listProjectLocations(
    ProjectLocationQuery query,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
