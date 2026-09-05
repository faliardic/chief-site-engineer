import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _activeReminderId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'daily landing keeps active reminders first and labeled actions visible at ${width.toInt()} px 2x text',
      (tester) async {
        final agenda = _TrackingAgenda(
          projects: const [_project],
          reminders: const [_activeReminder],
        );
        await _pumpLanding(
          tester,
          agenda,
          size: Size(width, 520),
          textScale: 2,
        );

        final create = find.byKey(const Key('new-reminder'));
        final inbox = find.byKey(const Key('quick-inbox-reminder'));
        final active = find.byKey(const Key('reminder-$_activeReminderId'));
        expect(agenda.todayOverviewCalls, 1);
        expect(agenda.lastReminderGroup, isNull);
        expect(active, findsOneWidget);
        expect(create, findsOneWidget);
        expect(inbox, findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Yeni hatırlatıcı'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Unutma Kutusu'),
          findsOneWidget,
        );
        for (final action in [create, inbox]) {
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.getRect(action).left, greaterThanOrEqualTo(0));
          expect(tester.getRect(action).right, lessThanOrEqualTo(width));
          expect(tester.getRect(action).bottom, lessThanOrEqualTo(520));
        }
        expect(
          tester.getTopLeft(create).dy,
          lessThan(tester.getTopLeft(active).dy),
        );
        expect(
          tester.getTopLeft(inbox).dy,
          lessThan(tester.getTopLeft(active).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'one-tap inbox capture requires one text and preserves exact project create result',
    (tester) async {
      final agenda = _TrackingAgenda(
        projects: const [_project],
        reminders: const [_activeReminder],
      );
      await _pumpLanding(
        tester,
        agenda,
        size: const Size(320, 520),
        textScale: 2,
      );

      final inboxAction = find.byKey(const Key('quick-inbox-reminder'));
      expect(inboxAction.hitTestable(), findsOneWidget);
      await tester.tap(inboxAction);
      await tester.pumpAndSettle();

      expect(find.text('Unutma Kutusu'), findsOneWidget);
      expect(find.byKey(const Key('reminder-title')), findsOneWidget);
      expect(agenda.createReminderCalls, 0);
      final schedule = tester.widget<DropdownButton<ReminderScheduleKind>>(
        find.descendant(
          of: find.byKey(const Key('reminder-schedule')),
          matching: find.byType(DropdownButton<ReminderScheduleKind>),
        ),
      );
      expect(schedule.value, ReminderScheduleKind.inbox);
      final project = tester.widget<DropdownButton<String?>>(
        find.descendant(
          of: find.byKey(const Key('reminder-project')),
          matching: find.byType(DropdownButton<String?>),
        ),
      );
      expect(project.value, _projectId);
      expect(
        find.byKey(const Key('reminder-optional-details')),
        findsOneWidget,
      );

      final submit = find.byKey(const Key('submit-reminder'));
      expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
      expect(submit.hitTestable(), findsOneWidget);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Hatırlatıcı metni zorunludur.'), findsOneWidget);
      expect(agenda.createReminderCalls, 0);

      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'Malzeme teslimini unutma',
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();

      final command = agenda.lastReminderCommand!;
      final result = agenda.lastCreateResult!;
      expect(agenda.createReminderCalls, 1);
      expect(command.id, isNotEmpty);
      expect(command.eventId, isNotEmpty);
      expect(command.projectId, _projectId);
      expect(command.sourceLogId, isNull);
      expect(command.captureText, 'Malzeme teslimini unutma');
      expect(command.title, 'Malzeme teslimini unutma');
      expect(command.description, '');
      expect(command.kind, ReminderKind.action);
      expect(command.schedule, ReminderScheduleKind.inbox);
      expect(command.locationId, isNull);
      expect(command.location, '');
      expect(command.relatedPerson, '');
      expect(command.isImportant, isFalse);
      expect(command.deadlineAt, isNull);
      expect(command.conditionText, '');
      expect(command.customAttentionAt, isNull);
      expect(command.allDayLocalDate, isNull);
      expect(result.id, command.id);
      expect(result.projectId, _projectId);
      expect(result.title, command.title);
      expect(result.kind, ReminderKind.action);
      expect(result.status, ReminderStatus.inbox);
      expect(result.nextAttentionAt, isNull);
      expect(result.allDayLocalDate, isNull);
      expect(agenda.lastReminderGroup, ReminderViewGroup.inbox);
      expect(find.byKey(const Key('reminder-title')), findsNothing);
      final resultCard = find.byKey(Key('reminder-${result.id}'));
      await tester.scrollUntilVisible(
        resultCard,
        160,
        scrollable: find.descendant(
          of: find.byKey(const Key('reminder-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(resultCard, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'labeled full-create action preserves default schedule kind project and result',
    (tester) async {
      final agenda = _TrackingAgenda(
        projects: const [_project],
        reminders: const [_activeReminder],
      );
      await _pumpLanding(tester, agenda);

      await tester.tap(find.byKey(const Key('new-reminder')));
      await tester.pumpAndSettle();
      expect(find.text('Yeni hatırlatıcı'), findsOneWidget);
      expect(find.byKey(const Key('reminder-time-group')), findsOneWidget);
      expect(
        find.byKey(const Key('reminder-optional-details')),
        findsOneWidget,
      );
      final schedule = tester.widget<DropdownButton<ReminderScheduleKind>>(
        find.descendant(
          of: find.byKey(const Key('reminder-schedule')),
          matching: find.byType(DropdownButton<ReminderScheduleKind>),
        ),
      );
      expect(schedule.value, ReminderScheduleKind.in15Minutes);
      final project = tester.widget<DropdownButton<String?>>(
        find.descendant(
          of: find.byKey(const Key('reminder-project')),
          matching: find.byType(DropdownButton<String?>),
        ),
      );
      expect(project.value, _projectId);

      await tester.enterText(
        find.byKey(const Key('reminder-title')),
        'On beş dakika sonra kontrol et',
      );
      await tester.tap(find.byKey(const Key('submit-reminder')));
      await tester.pumpAndSettle();

      final command = agenda.lastReminderCommand!;
      final result = agenda.lastCreateResult!;
      expect(agenda.createReminderCalls, 1);
      expect(command.projectId, _projectId);
      expect(command.kind, ReminderKind.action);
      expect(command.schedule, ReminderScheduleKind.in15Minutes);
      expect(command.customAttentionAt, isNull);
      expect(command.allDayLocalDate, isNull);
      expect(result.id, command.id);
      expect(result.status, ReminderStatus.active);
      expect(result.kind, ReminderKind.action);
      expect(result.projectId, _projectId);
      expect(result.nextAttentionAt, isNotNull);
      expect(find.byKey(const Key('reminder-title')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpLanding(
  WidgetTester tester,
  _TrackingAgenda agenda, {
  Size size = const Size(390, 700),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: RemindersPage(agenda: agenda, preferredProjectId: _projectId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TrackingAgenda extends FakeAgendaApplication {
  _TrackingAgenda({required super.projects, required super.reminders})
    : super(asOfUtc: DateTime.utc(2026, 7, 20, 5));

  MobileReminder? lastCreateResult;

  @override
  Future<MobileReminder> createReminder(CreateReminderCommand command) async {
    final result = await super.createReminder(command);
    lastCreateResult = result;
    return result;
  }
}

const _project = MobileProject(
  id: _projectId,
  name: 'Şantiye A',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);

const _activeReminder = MobileReminder(
  id: _activeReminderId,
  projectId: _projectId,
  projectName: 'Şantiye A',
  sourceLogId: null,
  captureText: 'Aktif saha kontrolü',
  title: 'Aktif saha kontrolü',
  kind: ReminderKind.action,
  status: ReminderStatus.active,
  nextAttentionAt: '2026-07-20T06:00:00Z',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);
