import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const dayId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const memberId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const reminderId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';

void main() {
  testWidgets('Puantaj navigation and daily editor work at 320 px', (
    tester,
  ) async {
    await _setPhoneSize(tester, const Size(320, 780));
    final project = _project();
    final agenda = FakeAgendaApplication(projects: [project]);
    final attendance = FakeAttendanceApplication(
      members: [_member()],
      detail: _detail(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendancePage(attendance: attendance, agenda: agenda),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('attendance-page')), findsOneWidget);
    expect(find.byKey(const Key('attendance-project')), findsOneWidget);
    expect(find.byKey(const Key('attendance-date-picker')), findsOneWidget);
    expect(find.byKey(const Key('manage-workforce')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('manage-workforce'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('open-attendance-day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attendance-day-detail')), findsOneWidget);
    expect(find.byKey(Key('attendance-member-$memberId')), findsOneWidget);
    expect(find.textContaining('Çok Uzun Türkçe'), findsWidgets);
    expect(find.byKey(const Key('mark-all-full')), findsOneWidget);
    expect(find.byKey(const Key('save-attendance-draft')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validation preserves Puantaj inputs and double tap is bounded', (
    tester,
  ) async {
    await _setPhoneSize(tester, const Size(390, 820));
    final attendance = FakeAttendanceApplication(
      members: [_member()],
      detail: _detail(),
    );
    final pending = Completer<AttendanceDayDetail>();
    attendance.saveCompleter = pending;
    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceDayPage(
          attendance: attendance,
          agenda: FakeAgendaApplication(projects: [_project()]),
          dayId: dayId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('attendance-general-note')),
      'Korunacak Türkçe form girdisi',
    );
    await tester.tap(find.byKey(const Key('save-attendance-draft')));
    await tester.tap(find.byKey(const Key('save-attendance-draft')));
    await tester.pump();

    expect(attendance.saveCalls, 1);
    pending.completeError(
      const AgendaValidationFailure(
        'Puantaj kaydı başka bir işlemle değişti. Ekranı yenileyin.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('başka bir işlemle değişti'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('attendance-general-note')),
    );
    expect(field.controller!.text, 'Korunacak Türkçe form girdisi');
  });

  testWidgets('member form preserves values after safe validation failure', (
    tester,
  ) async {
    await _setPhoneSize(tester, const Size(430, 820));
    final attendance = FakeAttendanceApplication()
      ..createMemberFailure = const AgendaValidationFailure(
        'Personel kodu aynı proje içinde zaten kullanılıyor.',
      );
    await tester.pumpWidget(
      MaterialApp(
        home: WorkforceMemberFormPage(
          attendance: attendance,
          project: _project(),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('workforce-name')),
      'İşçi Öğrenci Şefi',
    );
    await tester.enterText(
      find.byKey(const Key('workforce-team')),
      'Çok Uzun Türkçe Taşeron Ekibi',
    );
    await tester.enterText(find.byKey(const Key('workforce-role')), 'Demirci');
    await tester.enterText(find.byKey(const Key('workforce-code')), 'D-01');
    await tester.tap(find.byKey(const Key('save-workforce-member')));
    await tester.pumpAndSettle();

    expect(find.textContaining('zaten kullanılıyor'), findsOneWidget);
    expect(find.text('İşçi Öğrenci Şefi'), findsOneWidget);
    expect(find.text('Çok Uzun Türkçe Taşeron Ekibi'), findsOneWidget);
  });

  testWidgets('completion and reopen confirmations remain reachable', (
    tester,
  ) async {
    final attendance = FakeAttendanceApplication(
      members: [_member()],
      detail: _detail(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceDayPage(
          attendance: attendance,
          agenda: FakeAgendaApplication(projects: [_project()]),
          dayId: dayId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('attendance-day-detail')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('complete-attendance-day')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('confirm-attendance-transition')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-attendance-transition')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reopen-attendance-day')), findsOneWidget);
  });

  testWidgets('notification tap deep-links directly to attendance day', (
    tester,
  ) async {
    final taps = StreamController<String>();
    addTearDown(taps.close);
    final reminder = MobileReminder(
      id: reminderId,
      projectId: projectId,
      projectName: 'Test Projesi',
      sourceLogId: null,
      attendanceDayId: dayId,
      captureText: 'Puantajı tamamla',
      title: 'Puantajı tamamla',
      kind: ReminderKind.action,
      status: ReminderStatus.active,
      nextAttentionAt: '2026-07-19T14:00:00Z',
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      revision: 1,
    );
    final agenda = FakeAgendaApplication(
      projects: [_project()],
      reminders: [reminder],
      reminderDetail: reminder,
      notificationTapStream: taps.stream,
    );
    final attendance = FakeAttendanceApplication(
      members: [_member()],
      detail: _detail(linkedReminder: reminder),
    );
    await tester.pumpWidget(
      CseApp(
        bootstrap: Future.value(
          BootstrapSuccess(
            environmentLabel: 'debug',
            smokeRecordId: 'smoke',
            smokeRecordCreatedAt: '2026-07-19T08:00:00Z',
            agenda: agenda,
            attendance: attendance,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    taps.add(reminderId);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('attendance-day-detail')), findsOneWidget);
    expect(find.text('Günlük Puantaj'), findsOneWidget);
  });
}

Future<void> _setPhoneSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

MobileProject _project() => const MobileProject(
  id: projectId,
  name: 'Test Projesi',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);

WorkforceMember _member() => const WorkforceMember(
  id: memberId,
  projectId: projectId,
  fullName: 'Çok Uzun Türkçe Personel Adı Öğrenci İşçi',
  teamName: 'Çok Uzun Türkçe Taşeron Ekibi',
  roleName: 'Demir Ustası',
  personnelCode: 'D-01',
  isActive: true,
  revision: 1,
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  archivedAt: null,
);

AttendanceDayDetail _detail({MobileReminder? linkedReminder}) =>
    AttendanceDayDetail(
      day: const AttendanceDay(
        id: dayId,
        projectId: projectId,
        projectName: 'Test Projesi',
        localDate: '2026-07-19',
        status: AttendanceDayStatus.draft,
        generalNote: null,
        revision: 1,
        createdAt: '2026-07-19T08:00:00Z',
        updatedAt: '2026-07-19T08:00:00Z',
        completedAt: null,
      ),
      entries: const [],
      events: const [],
      totals: const AttendanceTotals.zero(),
      teamSummaries: const [],
      linkedReminder: linkedReminder,
    );
