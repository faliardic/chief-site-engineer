import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_person_detail_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_registry_page.dart';
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
    final subcontractor = await attendance.createSubcontractor(
      const CreateSubcontractorCommand(
        id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        eventId: '11111111-1111-4111-8111-111111111111',
        projectId: projectId,
        name: 'Uzun Türkçe Taşeron',
      ),
    );
    await attendance.createTeam(
      CreateWorkforceTeamCommand(
        id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        eventId: '22222222-2222-4222-8222-222222222222',
        projectId: projectId,
        subcontractorId: subcontractor.id,
        name: 'Çok Uzun Türkçe Taşeron Ekibi',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WorkforceMemberFormPage(
          attendance: attendance,
          project: _project(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workforce-subcontractor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uzun Türkçe Taşeron').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workforce-team')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çok Uzun Türkçe Taşeron Ekibi').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workforce-name')),
      'İşçi Öğrenci Şefi',
    );
    await tester.enterText(find.byKey(const Key('workforce-role')), 'Demirci');
    await tester.enterText(find.byKey(const Key('workforce-code')), 'D-01');
    await tester.tap(find.byKey(const Key('save-workforce-member')));
    await tester.pumpAndSettle();

    expect(find.textContaining('zaten kullanılıyor'), findsOneWidget);
    expect(find.text('İşçi Öğrenci Şefi'), findsOneWidget);
    expect(find.text('Çok Uzun Türkçe Taşeron Ekibi'), findsOneWidget);
  });

  testWidgets('member form double tap submits one identity command', (
    tester,
  ) async {
    await _setPhoneSize(tester, const Size(430, 820));
    final pending = Completer<WorkforceMember>();
    final attendance = FakeAttendanceApplication()
      ..createMemberCompleter = pending;
    final subcontractor = await attendance.createSubcontractor(
      const CreateSubcontractorCommand(
        id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        eventId: '11111111-1111-4111-8111-111111111111',
        projectId: projectId,
        name: 'Taşeron A',
      ),
    );
    final team = await attendance.createTeam(
      CreateWorkforceTeamCommand(
        id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        eventId: '22222222-2222-4222-8222-222222222222',
        projectId: projectId,
        subcontractorId: subcontractor.id,
        name: 'Ekip A',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WorkforceMemberFormPage(
          attendance: attendance,
          project: _project(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workforce-subcontractor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(subcontractor.name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workforce-team')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(team.name).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workforce-name')),
      'Tek kayıt personeli',
    );
    await tester.enterText(find.byKey(const Key('workforce-role')), 'Usta');
    final save = find.byKey(const Key('save-workforce-member'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    expect(attendance.createMemberCalls, 1);
    expect(
      attendance.lastCreateMemberCommand!.subcontractorId,
      subcontractor.id,
    );
    expect(attendance.lastCreateMemberCommand!.teamId, team.id);
    pending.complete(_member());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'member selectors create and auto-select subcontractor and team',
    (tester) async {
      await _setPhoneSize(tester, const Size(430, 820));
      final attendance = FakeAttendanceApplication();
      await tester.pumpWidget(
        MaterialApp(
          home: WorkforceMemberFormPage(
            attendance: attendance,
            project: _project(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workforce-subcontractor')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Yeni taşeron ekle').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Yeni Taşeron');
      await tester.tap(find.text('Oluştur'));
      await tester.pumpAndSettle();
      expect(find.text('Yeni Taşeron'), findsOneWidget);

      await tester.tap(find.byKey(const Key('workforce-team')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Yeni ekip ekle').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Yeni Ekip');
      await tester.tap(find.text('Oluştur'));
      await tester.pumpAndSettle();
      expect(find.text('Yeni Ekip'), findsOneWidget);
      expect(attendance.subcontractors, hasLength(1));
      expect(attendance.teams, hasLength(1));
    },
  );

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

  testWidgets('workforce registry and person tabs fit phone widths', (
    tester,
  ) async {
    await _setPhoneSize(tester, const Size(320, 780));
    final attendance = FakeAttendanceApplication();
    final subcontractor = await attendance.createSubcontractor(
      const CreateSubcontractorCommand(
        id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        eventId: '11111111-1111-4111-8111-111111111111',
        projectId: projectId,
        name: 'Çok Uzun Türkçe Taşeron Unvanı',
      ),
    );
    final team = await attendance.createTeam(
      CreateWorkforceTeamCommand(
        id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        eventId: '22222222-2222-4222-8222-222222222222',
        projectId: projectId,
        subcontractorId: subcontractor.id,
        name: 'Çevre duvarcı ve saha destek ekibi',
      ),
    );
    final member = await attendance.createMember(
      CreateWorkforceMemberCommand(
        id: memberId,
        eventId: '33333333-3333-4333-8333-333333333333',
        projectId: projectId,
        subcontractorId: subcontractor.id,
        teamId: team.id,
        fullName: 'Çok Uzun Türkçe Personel Adı Öğrenci İşçi',
        teamName: team.name,
        roleName: 'Duvar ustası',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WorkforceRegistryPage(
          attendance: attendance,
          project: _project(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 aktif ekip • 1 aktif personel'), findsOneWidget);
    expect(find.text('1 aktif personel'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: WorkforcePersonDetailPage(
          attendance: attendance,
          memberId: member.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Genel / Puantaj'), findsOneWidget);
    expect(find.text('İSG belgeleri'), findsOneWidget);
    expect(find.text('KKD zimmetleri'), findsOneWidget);
    await tester.drag(find.byType(TabBar), const Offset(-180, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İSG belgeleri'));
    await tester.pumpAndSettle();
    expect(find.text('İSG belgesi ekle'), findsOneWidget);
    await tester.drag(find.byType(TabBar), const Offset(-140, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KKD zimmetleri'));
    await tester.pumpAndSettle();
    expect(find.text('KKD zimmeti ekle'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
