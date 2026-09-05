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
          body: AttendancePage(
            attendance: attendance,
            agenda: agenda,
            activeProjectId: projectId,
            isActive: true,
          ),
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

    await tester.tap(find.byKey(const Key('manage-workforce')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workforce-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attendance-page')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('open-attendance-day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attendance-day-detail')), findsOneWidget);
    expect(find.byKey(const Key('attendance-roster-selector')), findsOneWidget);
    expect(find.byKey(Key('attendance-member-$memberId')), findsNothing);
    expect(find.textContaining('Önce İşveren seçin'), findsOneWidget);
    expect(find.byKey(const Key('mark-all-full')), findsOneWidget);
    final save = find.byKey(const Key('save-attendance-draft'));
    await tester.scrollUntilVisible(
      save,
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('attendance-day-detail')),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 12,
    );
    await tester.pumpAndSettle();
    expect(save, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Puantaj stays dormant while hidden and validates only shared project',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: [_project(), _secondProject()],
      );
      final attendance = _TrackingAttendanceApplication();
      var isActive = false;
      String? activeProjectId;
      late StateSetter updateHost;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return AttendancePage(
                  attendance: attendance,
                  agenda: agenda,
                  activeProjectId: activeProjectId,
                  isActive: isActive,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(agenda.listProjectsCalls, 0);
      expect(attendance.ensureProjectIds, isEmpty);
      expect(attendance.rollingCalls, 0);

      updateHost(() => isActive = true);
      await tester.pumpAndSettle();
      expect(agenda.listProjectsCalls, 1);
      expect(attendance.ensureProjectIds, isEmpty);

      updateHost(() => activeProjectId = 'stale-project');
      await tester.pumpAndSettle();
      expect(agenda.listProjectsCalls, 2);
      expect(attendance.ensureProjectIds, isEmpty);

      updateHost(() => activeProjectId = _secondProject().id);
      await tester.pumpAndSettle();
      expect(agenda.listProjectsCalls, 3);
      expect(attendance.ensureProjectIds, [_secondProject().id]);
      expect(attendance.rollingCalls, 1);

      updateHost(() {
        isActive = false;
        activeProjectId = projectId;
      });
      await tester.pumpAndSettle();
      await agenda.createProject(
        const CreateProjectCommand(
          id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
          name: 'Hidden signal',
        ),
      );
      await tester.pumpAndSettle();
      expect(agenda.listProjectsCalls, 3);
      expect(attendance.ensureProjectIds, [_secondProject().id]);
      expect(attendance.rollingCalls, 1);

      updateHost(() => isActive = true);
      await tester.pumpAndSettle();
      expect(agenda.listProjectsCalls, 4);
      expect(attendance.ensureProjectIds, [_secondProject().id, projectId]);
      expect(attendance.rollingCalls, 2);
    },
  );

  testWidgets(
    'Puantaj reports a deliberate project only after exact load succeeds',
    (tester) async {
      final agenda = FakeAgendaApplication(
        projects: [_project(), _secondProject()],
      );
      final attendance = _TrackingAttendanceApplication();
      final reportedProjects = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendancePage(
              attendance: attendance,
              agenda: agenda,
              activeProjectId: _secondProject().id,
              isActive: true,
              onProjectSelected: reportedProjects.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(attendance.ensureProjectIds, [_secondProject().id]);
      final projectField = find.descendant(
        of: find.byKey(const Key('attendance-project')),
        matching: find.byType(DropdownButtonFormField<String>),
      );

      attendance.failNextEnsureProjectId = projectId;
      await tester.tap(projectField);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_project().name).last);
      await tester.pumpAndSettle();
      expect(reportedProjects, isEmpty);
      expect(
        tester.state<FormFieldState<String>>(projectField).value,
        _secondProject().id,
      );

      await tester.tap(projectField);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_project().name).last);
      await tester.pumpAndSettle();
      expect(reportedProjects, [projectId]);
      expect(attendance.ensureProjectIds, [
        _secondProject().id,
        projectId,
        projectId,
      ]);
    },
  );

  testWidgets(
    'Kaydet saves the Puantaj roster while draft lifecycle stays open',
    (tester) async {
      await _setPhoneSize(tester, const Size(390, 820));
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
      await tester.scrollUntilVisible(
        find.byKey(const Key('save-attendance-draft')),
        240,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('attendance-day-detail')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Kaydet'), findsOneWidget);
      expect(find.text('Taslak kaydet'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const Key('save-attendance-draft')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-attendance-draft')));
      await tester.pumpAndSettle();

      expect(attendance.saveCalls, 1);
      expect(attendance.lastRosterCommand!.expectedRevision, 1);
      expect(attendance.lastRosterCommand!.eventId, isNotEmpty);
      expect(attendance.detail!.day.status, AttendanceDayStatus.draft);
      expect(find.byKey(const Key('complete-attendance-day')), findsOneWidget);
      expect(find.text('Günü tamamla'), findsOneWidget);
    },
  );

  testWidgets('Puantaj save failure uses explicit Turkish user language', (
    tester,
  ) async {
    await _setPhoneSize(tester, const Size(390, 820));
    final attendance = FakeAttendanceApplication(
      members: [_member()],
      detail: _detail(),
    )..saveFailure = StateError('synthetic failure');
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

    await tester.ensureVisible(find.byKey(const Key('save-attendance-draft')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-attendance-draft')));
    await tester.pumpAndSettle();

    expect(find.text('Puantaj kaydedilemedi.'), findsOneWidget);
    expect(find.textContaining('Taslak kaydedilemedi'), findsNothing);
    expect(attendance.detail!.day.status, AttendanceDayStatus.draft);
  });

  testWidgets(
    'Kaydet action fits 320 px large text dark theme without overflow',
    (tester) async {
      await _setPhoneSize(tester, const Size(320, 820));
      final attendance = FakeAttendanceApplication(
        members: [_member()],
        detail: _detail(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: AttendanceDayPage(
              attendance: attendance,
              agenda: FakeAgendaApplication(projects: [_project()]),
              dayId: dayId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final detailRoot = find.byKey(const Key('attendance-day-detail'));
      final detailScrollable = find
          .descendant(of: detailRoot, matching: find.byType(Scrollable))
          .first;
      final saveAction = find.byKey(const Key('save-attendance-draft'));
      await tester.scrollUntilVisible(
        saveAction,
        240,
        scrollable: detailScrollable,
        maxScrolls: 10,
      );
      await tester.pumpAndSettle();

      expect(saveAction, findsOneWidget);
      expect(
        find.descendant(of: saveAction, matching: find.text('Kaydet')),
        findsOneWidget,
      );
      expect(find.text('Taslak kaydet'), findsNothing);
      expect(find.byKey(const Key('complete-attendance-day')), findsOneWidget);
      expect(find.text('Günü tamamla'), findsOneWidget);
      expect(find.text('Çalışma yok'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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
    await tester.ensureVisible(find.byKey(const Key('save-attendance-draft')));
    await tester.pumpAndSettle();
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
    final save = find.byKey(const Key('save-workforce-member'));
    await _scrollWorkforceFormTo(tester, save);
    await tester.tap(save);
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
    await _scrollWorkforceFormTo(tester, save);
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
    expect(find.byKey(const Key('workforce-person-profile')), findsOneWidget);
    expect(find.text('İSG TAM'), findsOneWidget);
    expect(find.text('İSG eksik 0'), findsNothing);
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

  testWidgets(
    'Puantaj day detail return keeps project day and scroll after async reload',
    (tester) async {
      await _setPhoneSize(tester, const Size(320, 360));
      final attendance = _DelayedAttendanceApplication(
        detail: _detail(),
        teamCounts: List.generate(
          24,
          (index) => ActiveTeamCount(
            teamId:
                'eeeeeeee-eeee-4eee-8eee-${(index + 100).toString().padLeft(12, '0')}',
            teamName: 'CSE264 sentetik ekip $index',
            subcontractorName: 'CSE264 sentetik taşeron',
            activePersonCount: index + 1,
          ),
        ),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            theme: ThemeData(brightness: Brightness.dark),
            home: Scaffold(
              body: AttendancePage(
                attendance: attendance,
                agenda: FakeAgendaApplication(projects: [_project()]),
                activeProjectId: projectId,
                isActive: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('attendance-previous-day')));
      await tester.pumpAndSettle();
      final selectedDay = tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('attendance-date-picker')),
              matching: find.byType(Text),
            ),
          )
          .data;

      final detailCard = find.byKey(const Key('open-attendance-day'));
      await tester.scrollUntilVisible(
        detailCard,
        420,
        scrollable: _attendanceScrollableFinder(),
      );
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(detailCard),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      final before = _attendanceScrollOffset(tester);
      expect(before, greaterThan(300));

      await tester.tap(detailCard);
      await tester.pumpAndSettle();
      attendance.detail = _completedDetail();
      final delayedReload = Completer<AttendanceDayDetail>();
      attendance.delayedDetailReload = delayedReload;
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 350));
      delayedReload.complete(attendance.detail!);
      await tester.pumpAndSettle();

      expect(_attendanceScrollOffset(tester), closeTo(before, 4));
      expect(find.text(AttendanceDayStatus.completed.label), findsOneWidget);
      expect(find.text('24 aktif ekip • 300 aktif personel'), findsOneWidget);
      tester
          .state<ScrollableState>(_attendanceScrollableFinder())
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text(selectedDay!), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Puantaj detail double tap opens one route and controller disposes',
    (tester) async {
      final attendance = _DelayedAttendanceApplication(
        detail: _detail(),
        teamCounts: const [],
      );
      final observer = _AttendancePushCountingObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Scaffold(
            body: AttendancePage(
              attendance: attendance,
              agenda: FakeAgendaApplication(projects: [_project()]),
              activeProjectId: projectId,
              isActive: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      observer.pushes = 0;
      final detailCard = find.byKey(const Key('open-attendance-day'));

      final onTap = tester.widget<InkWell>(detailCard).onTap!;
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
}

double _attendanceScrollOffset(WidgetTester tester) {
  return tester
      .state<ScrollableState>(_attendanceScrollableFinder())
      .position
      .pixels;
}

Finder _attendanceScrollableFinder() => find
    .descendant(
      of: find.byKey(const Key('attendance-page')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _scrollWorkforceFormTo(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byKey(const Key('workforce-member-form')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: scrollable,
    maxScrolls: 8,
  );
  await tester.pumpAndSettle();
}

class _DelayedAttendanceApplication extends FakeAttendanceApplication {
  _DelayedAttendanceApplication({
    required super.detail,
    required this.teamCounts,
  });

  final List<ActiveTeamCount> teamCounts;
  Completer<AttendanceDayDetail>? delayedDetailReload;

  @override
  Future<AttendanceDayDetail> getDayDetail(String dayId) {
    final delayed = delayedDetailReload;
    if (delayed != null) {
      delayedDetailReload = null;
      return delayed.future;
    }
    return super.getDayDetail(dayId);
  }

  @override
  Future<List<ActiveTeamCount>> listActiveTeamCounts(String projectId) async =>
      teamCounts;
}

class _TrackingAttendanceApplication extends FakeAttendanceApplication {
  final List<String> ensureProjectIds = [];
  int rollingCalls = 0;
  String? failNextEnsureProjectId;

  @override
  Future<AttendanceDay> ensureDay(EnsureAttendanceDayCommand command) async {
    ensureProjectIds.add(command.projectId);
    if (failNextEnsureProjectId == command.projectId) {
      failNextEnsureProjectId = null;
      throw StateError('synthetic attendance load failure');
    }
    return super.ensureDay(command);
  }

  @override
  Future<void> ensureRollingOccurrences() async {
    rollingCalls += 1;
    return super.ensureRollingOccurrences();
  }
}

class _AttendancePushCountingObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes += 1;
    super.didPush(route, previousRoute);
  }
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

MobileProject _secondProject() => const MobileProject(
  id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
  name: 'İkinci Proje',
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

AttendanceDayDetail _completedDetail() {
  final current = _detail();
  return AttendanceDayDetail(
    day: AttendanceDay(
      id: current.day.id,
      projectId: current.day.projectId,
      projectName: current.day.projectName,
      localDate: current.day.localDate,
      status: AttendanceDayStatus.completed,
      generalNote: current.day.generalNote,
      revision: current.day.revision + 1,
      createdAt: current.day.createdAt,
      updatedAt: '2026-07-19T09:00:00Z',
      completedAt: '2026-07-19T09:00:00Z',
    ),
    entries: current.entries,
    events: current.events,
    totals: current.totals,
    teamSummaries: current.teamSummaries,
    linkedReminder: current.linkedReminder,
  );
}
