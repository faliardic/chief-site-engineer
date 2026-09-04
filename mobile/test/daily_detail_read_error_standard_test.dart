import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _logId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _reminderId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';

void main() {
  testWidgets(
    'Agenda primary read retry is accessible, guarded, and restores exact detail',
    (tester) async {
      _configureCompactLargeText(tester);
      final agenda = _ScriptedDailyDetailAgenda()
        ..agendaReadFailure = StateError('primary read failure');
      await tester.pumpWidget(
        MaterialApp(
          home: LogDetailPage(agenda: agenda, logId: _logId),
        ),
      );
      await tester.pumpAndSettle();

      final pageElement = tester.element(find.byType(LogDetailPage));
      _expectRetryAction(tester, const Key('agenda-detail-read-error-retry'));
      expect(
        find.text('Ajanda kaydı güvenli biçimde okunamadı.'),
        findsOneWidget,
      );
      expect(find.text(_log.description), findsNothing);

      final failedCalls = agenda.getAgendaLogDetailCalls;
      final failedRetry = tester
          .widget<FilledButton>(
            find.byKey(const Key('agenda-detail-read-error-retry')),
          )
          .onPressed!;
      failedRetry();
      failedRetry();
      await tester.pumpAndSettle();
      expect(agenda.getAgendaLogDetailCalls, failedCalls + 1);
      _expectRetryAction(tester, const Key('agenda-detail-read-error-retry'));

      agenda.agendaReadFailure = null;
      final gate = Completer<AgendaLogDetail>();
      agenda.agendaReadGate = gate;
      final successfulCalls = agenda.getAgendaLogDetailCalls;
      final successfulRetry = tester
          .widget<FilledButton>(
            find.byKey(const Key('agenda-detail-read-error-retry')),
          )
          .onPressed!;
      successfulRetry();
      successfulRetry();
      await tester.pump();

      expect(agenda.getAgendaLogDetailCalls, successfulCalls + 1);
      _expectLoading(tester, 'Ajanda kaydı yükleniyor');
      expect(
        find.byKey(const Key('agenda-detail-read-error-retry')),
        findsNothing,
      );

      gate.complete(_agendaDetail);
      await tester.pumpAndSettle();
      expect(tester.element(find.byType(LogDetailPage)), same(pageElement));
      expect(agenda.agendaReadIds, everyElement(_logId));
      expect(find.text(_log.description), findsOneWidget);
      expect(
        find.byKey(const Key('agenda-detail-read-error-retry')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reminder primary read retry is accessible, guarded, and restores exact detail',
    (tester) async {
      _configureCompactLargeText(tester);
      final agenda = _ScriptedDailyDetailAgenda()
        ..reminderReadFailure = StateError('primary read failure');
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: _reminderId),
        ),
      );
      await tester.pumpAndSettle();

      final pageElement = tester.element(find.byType(ReminderDetailPage));
      _expectRetryAction(tester, const Key('reminder-detail-read-error-retry'));
      expect(
        find.text('Hatırlatıcı güvenli biçimde okunamadı.'),
        findsOneWidget,
      );
      expect(find.text(_reminder.title), findsNothing);

      final failedCalls = agenda.reminderLifecycleDetailCalls;
      final failedRetry = tester
          .widget<FilledButton>(
            find.byKey(const Key('reminder-detail-read-error-retry')),
          )
          .onPressed!;
      failedRetry();
      failedRetry();
      await tester.pumpAndSettle();
      expect(agenda.reminderLifecycleDetailCalls, failedCalls + 1);
      _expectRetryAction(tester, const Key('reminder-detail-read-error-retry'));

      agenda.reminderReadFailure = null;
      final gate = Completer<ReminderDetail>();
      agenda.reminderReadGate = gate;
      final successfulCalls = agenda.reminderLifecycleDetailCalls;
      final successfulRetry = tester
          .widget<FilledButton>(
            find.byKey(const Key('reminder-detail-read-error-retry')),
          )
          .onPressed!;
      successfulRetry();
      successfulRetry();
      await tester.pump();

      expect(agenda.reminderLifecycleDetailCalls, successfulCalls + 1);
      _expectLoading(tester, 'Hatırlatıcı yükleniyor');
      expect(
        find.byKey(const Key('reminder-detail-read-error-retry')),
        findsNothing,
      );

      gate.complete(_reminderDetail(_reminder));
      await tester.pumpAndSettle();
      expect(
        tester.element(find.byType(ReminderDetailPage)),
        same(pageElement),
      );
      expect(agenda.reminderReadIds, everyElement(_reminderId));
      expect(find.text(_reminder.title), findsOneWidget);
      expect(
        find.byKey(const Key('reminder-detail-read-error-retry')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Agenda operation failure does not expose primary read retry', (
    tester,
  ) async {
    final agenda = _ScriptedDailyDetailAgenda()
      ..agendaMutationFailure = StateError('archive failure');
    await tester.pumpWidget(
      MaterialApp(
        home: LogDetailPage(agenda: agenda, logId: _logId),
      ),
    );
    await tester.pumpAndSettle();

    final archive = find.byKey(const Key('archive-agenda-log'));
    await tester.scrollUntilVisible(
      archive,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(archive);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-archive-log')));
    await tester.pumpAndSettle();
    _jumpDetailToTop(tester);
    await tester.pumpAndSettle();

    expect(find.text('İşlem güvenli biçimde tamamlanamadı.'), findsOneWidget);
    expect(
      find.byKey(const Key('agenda-detail-read-error-retry')),
      findsNothing,
    );
    expect(find.text(_log.description), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reminder mutation failure does not expose primary read retry', (
    tester,
  ) async {
    final agenda = _ScriptedDailyDetailAgenda()
      ..mutateReminderFailure = StateError('mutation failure');
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderDetailPage(agenda: agenda, reminderId: _reminderId),
      ),
    );
    await tester.pumpAndSettle();

    final snooze = find.byKey(const Key('snooze-15'));
    await tester.scrollUntilVisible(
      snooze,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(snooze);
    await tester.pumpAndSettle();
    _jumpDetailToTop(tester);
    await tester.pumpAndSettle();

    expect(find.text('İşlem güvenli biçimde tamamlanamadı.'), findsOneWidget);
    expect(
      find.byKey(const Key('reminder-detail-read-error-retry')),
      findsNothing,
    );
    expect(find.text(_reminder.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Reminder secondary source media and diagnostic failures stay degraded',
    (tester) async {
      final linked = _copyReminder(sourceLogId: _logId);
      final agenda = _ScriptedDailyDetailAgenda(reminder: linked)
        ..agendaReadFailure = StateError('source Agenda unavailable')
        ..sourceAgendaMediaFailure = StateError('source media unavailable')
        ..diagnosticFailure = StateError('diagnostic unavailable');
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: _reminderId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reminder-detail')), findsOneWidget);
      expect(find.text(linked.title), findsOneWidget);
      expect(
        find.byKey(const Key('reminder-source-agenda-photos-error')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('reminder-detail-read-error-retry')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('reminder-delivery-diagnostic')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'successful Reminder mutation reloads and source navigation works',
    (tester) async {
      final linked = _copyReminder(sourceLogId: _logId);
      final agenda = _ScriptedDailyDetailAgenda(reminder: linked);
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderDetailPage(agenda: agenda, reminderId: _reminderId),
        ),
      );
      await tester.pumpAndSettle();

      final trash = find.byKey(const Key('trash-reminder'));
      await tester.scrollUntilVisible(
        trash,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(trash);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-trash-reminder')));
      await tester.pumpAndSettle();

      expect(agenda.mutateReminderCalls, 1);
      expect(agenda.reminderLifecycleDetailCalls, 2);
      expect(agenda.reminderDetail!.revision, 2);
      expect(
        find.byKey(const Key('reminder-detail-read-error-retry')),
        findsNothing,
      );

      final sourceAction = find.byKey(const Key('open-source-agenda-log'));
      await tester.ensureVisible(sourceAction);
      await tester.tap(sourceAction);
      await tester.pumpAndSettle();
      expect(find.byType(LogDetailPage), findsOneWidget);
      expect(agenda.agendaReadIds.last, _logId);
      expect(find.text(_log.description), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

void _configureCompactLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 760);
  tester.view.devicePixelRatio = 1;
  tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
}

void _expectRetryAction(WidgetTester tester, Key key) {
  final action = find.byKey(key);
  expect(action, findsOneWidget);
  expect(tester.widget(action), isA<FilledButton>());
  final size = tester.getSize(action);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
  final semantics = find
      .ancestor(
        of: action,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Tekrar dene',
        ),
      )
      .first;
  final properties = tester.widget<Semantics>(semantics).properties;
  expect(tester.getSize(semantics), size);
  expect(properties.button, isTrue);
  expect(properties.enabled, isTrue);
  expect(properties.onTap, isNotNull);
}

void _expectLoading(WidgetTester tester, String label) {
  expect(
    find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    ),
    findsOneWidget,
  );
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
}

void _jumpDetailToTop(WidgetTester tester) {
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
}

class _ScriptedDailyDetailAgenda extends FakeAgendaApplication
    implements ReminderDeliveryApplication {
  _ScriptedDailyDetailAgenda({MobileReminder reminder = _reminder})
    : super(
        logs: const [_log],
        reminders: [reminder],
        logDetail: _agendaDetail,
        reminderDetail: reminder,
      );

  Object? agendaReadFailure;
  Object? reminderReadFailure;
  Object? agendaMutationFailure;
  Object? diagnosticFailure;
  Completer<AgendaLogDetail>? agendaReadGate;
  Completer<ReminderDetail>? reminderReadGate;
  final List<String> agendaReadIds = [];
  final List<String> reminderReadIds = [];

  @override
  Future<AgendaLogDetail> getAgendaLogDetail(String logId) async {
    getAgendaLogDetailCalls += 1;
    agendaReadIds.add(logId);
    final gate = agendaReadGate;
    if (gate != null) {
      agendaReadGate = null;
      return gate.future;
    }
    if (agendaReadFailure case final failure?) throw failure;
    return _agendaDetail;
  }

  @override
  Future<ReminderDetail> getReminderLifecycleDetail(String reminderId) async {
    reminderLifecycleDetailCalls += 1;
    reminderReadIds.add(reminderId);
    final gate = reminderReadGate;
    if (gate != null) {
      reminderReadGate = null;
      return gate.future;
    }
    if (reminderReadFailure case final failure?) throw failure;
    return _reminderDetail(reminderDetail!);
  }

  @override
  Future<AgendaLogDetail> mutateAgendaLogArchive(
    MutateAgendaLogArchiveCommand command,
  ) async {
    if (agendaMutationFailure case final failure?) throw failure;
    return super.mutateAgendaLogArchive(command);
  }

  @override
  Future<ReminderDeliveryDiagnostic> getReminderDeliveryDiagnostic(
    String reminderId,
  ) async {
    if (diagnosticFailure case final failure?) throw failure;
    return const ReminderDeliveryDiagnostic(
      safeReminderId: 'bbbbbbbb',
      scheduleKind: 'one_shot',
      canonicalDueAt: '2026-07-20T06:00:00Z',
      nativeSchedulePresent: true,
      lastReconciledAt: '2026-07-19T08:00:00Z',
      permissionState: 'granted',
      channelState: 'enabled',
      exactAlarmState: 'granted',
      batteryOptimizationState: 'unrestricted',
      backgroundRestrictionState: 'allowed',
      standbyBucket: 'active',
      bootRescheduleState: 'not_required',
      bootRescheduledAt: null,
      deliveredAt: null,
      delayClass: ReminderDeliveryDelayClass.pending,
      safeErrorCode: null,
    );
  }

  @override
  Future<void> retryReminderDelivery(String reminderId) async {}

  @override
  Future<void> openReminderNotificationSettings() async {}

  @override
  Future<void> openReminderBatteryOptimizationSettings() async {}
}

const _log = AgendaLog(
  id: _logId,
  projectId: '11111111-1111-4111-8111-111111111111',
  projectName: 'Kuzey Şantiyesi',
  observedAt: '2026-07-19T07:30:00Z',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  category: AgendaCategory.inspection,
  description: 'Exact Ajanda detay kaydı',
  location: 'A Blok',
  notes: 'Korunan ayrıntı',
  revision: 1,
);

const _agendaDetail = AgendaLogDetail(log: _log, reminders: []);

const _reminder = MobileReminder(
  id: _reminderId,
  projectId: null,
  projectName: null,
  sourceLogId: null,
  captureText: 'Exact Hatırlatıcı detay kaydı',
  title: 'Exact Hatırlatıcı detay kaydı',
  kind: ReminderKind.action,
  status: ReminderStatus.active,
  nextAttentionAt: '2026-07-20T06:00:00Z',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);

MobileReminder _copyReminder({required String sourceLogId}) => MobileReminder(
  id: _reminder.id,
  projectId: _log.projectId,
  projectName: _log.projectName,
  sourceLogId: sourceLogId,
  captureText: _reminder.captureText,
  title: _reminder.title,
  kind: _reminder.kind,
  status: _reminder.status,
  nextAttentionAt: _reminder.nextAttentionAt,
  createdAt: _reminder.createdAt,
  updatedAt: _reminder.updatedAt,
  revision: _reminder.revision,
);

ReminderDetail _reminderDetail(MobileReminder reminder) => ReminderDetail(
  reminder: reminder,
  events: const [],
  notification: NotificationBinding(
    reminderId: reminder.id,
    platformNotificationId: 1,
    scheduledFor: reminder.nextAttentionAt,
    syncState: NotificationSyncState.scheduled,
    lastSyncedAt: reminder.updatedAt,
    safeErrorCode: null,
  ),
);
