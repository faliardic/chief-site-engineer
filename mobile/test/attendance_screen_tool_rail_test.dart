import 'dart:async';

import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_settings_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/screen_tool_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const _project = MobileProject(
  id: 'project-a',
  name: 'Aktif proje',
  createdAt: '2026-07-01',
  updatedAt: '2026-07-01',
  revision: 1,
);
Finder _key(String key) => find.byKey(Key(key));
Finder get _scroll => find
    .descendant(of: _key('attendance-page'), matching: find.byType(Scrollable))
    .first;

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(320, 360),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('day first layout and rail at $size text $scale', (
        tester,
      ) async {
        final attendance = _Attendance();
        await _pump(tester, attendance, size: size, scale: scale);
        final semantics = tester.ensureSemantics();
        try {
          expect(find.byType(ScreenToolRail), findsOneWidget);
          final rail = tester.widget<ScreenToolRail>(
            find.byType(ScreenToolRail),
          );
          expect(rail.actions.map((a) => a.label), ['Personel', 'Hatırlatıcı']);
          final content = tester.getRect(_key('attendance-page'));
          expect(
            content.right,
            lessThanOrEqualTo(tester.getRect(find.byType(ScreenToolRail)).left),
          );
          for (final action in rail.actions) {
            final button = find.byKey(action.key);
            expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
            expect(tester.widget<IconButton>(button).tooltip, action.label);
            final node = tester
                .getSemantics(
                  find
                      .ancestor(of: button, matching: find.byType(Semantics))
                      .first,
                )
                .getSemanticsData();
            expect(node.label, action.label);
            expect(node.flagsCollection.isButton, isTrue);
            expect(
              find.descendant(of: _key('attendance-page'), matching: button),
              findsNothing,
            );
          }
          expect(
            tester.getTopLeft(_key('manage-workforce')).dy,
            lessThan(
              tester.getTopLeft(_key('attendance-reminder-settings')).dy,
            ),
          );
          expect(find.text('Taşeronlar ve ekipler'), findsNothing);
          expect(find.text('Puantaj hatırlatıcısı'), findsNothing);
          expect(
            tester.getTopLeft(_key('attendance-project')).dy,
            lessThan(tester.getTopLeft(_key('attendance-date-picker')).dy),
          );
          expect(
            tester.getTopLeft(_key('attendance-date-picker')).dy,
            lessThan(tester.getTopLeft(_key('open-attendance-day')).dy),
          );
          expect(
            tester.getSize(_key('open-attendance-day')).width,
            lessThanOrEqualTo(840),
          );
          for (final key in [
            'attendance-date-picker',
            'attendance-previous-day',
            'attendance-next-day',
            'attendance-today',
            'open-attendance-day',
          ]) {
            final target = _key(key);
            await Scrollable.ensureVisible(
              tester.element(target),
              alignment: 0.5,
            );
            await tester.pumpAndSettle();
            expect(target.hitTestable(), findsOneWidget);
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
          }
          expect(find.text('3.5 kişi-gün • 45 dk fazla mesai'), findsOneWidget);
          expect(find.text(AttendanceDayStatus.draft.label), findsOneWidget);
          expect(find.text('Puantaj gününü aç'), findsOneWidget);
          expect(find.text('2 aktif ekip • 7 aktif personel'), findsOneWidget);
          expect(_key('attendance-workforce-prerequisite'), findsNothing);
          expect(find.text('Ekip A'), findsNothing);
          expect(attendance.commands.length, 1);
          expect(attendance.rolling, 1);
          expect(attendance.teamReads, ['project-a']);
          expect(attendance.detailReads, [attendance.commands.single.id]);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  for (final width in [320.0, 390.0]) {
    for (final counts in <List<ActiveTeamCount>>[
      const [],
      const [
        ActiveTeamCount(
          teamId: 'team-a',
          teamName: 'Ekip A',
          subcontractorName: 'Firma',
          activePersonCount: 0,
        ),
      ],
    ]) {
      testWidgets(
        'empty draft prerequisite at $width with ${counts.length} teams',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final attendance = _Attendance()..teamCountsOverride = counts;
            final agenda = FakeAgendaApplication(projects: [_project]);
            await _pump(
              tester,
              attendance,
              agenda: agenda,
              size: Size(width, 360),
              scale: 2,
            );
            expect(_key('attendance-workforce-prerequisite'), findsOneWidget);
            expect(
              find.textContaining('Bu projede aktif personel yok.'),
              findsOneWidget,
            );
            final setup = _key('attendance-setup-workforce');
            await tester.ensureVisible(setup);
            await tester.pumpAndSettle();
            expect(setup.hitTestable(), findsOneWidget);
            expect(tester.getSize(setup).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(setup).height, greaterThanOrEqualTo(48));
            final data = tester.getSemantics(setup).getSemanticsData();
            expect(data.label, 'Personel yönetimini aç');
            expect(data.flagsCollection.isButton, isTrue);
            expect(tester.takeException(), isNull);
            expect(agenda.listProjectsCalls, 1);
            expect(attendance.commands.length, 1);
            expect(attendance.rolling, 1);
            expect(attendance.detailReads, [attendance.commands.single.id]);
            expect(attendance.teamReads, ['project-a']);
            expect(attendance.workforceReads, isEmpty);
            expect(
              tester.widget<InkWell>(_key('open-attendance-day')).onTap,
              isNotNull,
            );

            await _tap(tester, 'attendance-setup-workforce');
            final management = tester.widget<WorkforcePage>(
              find.byType(WorkforcePage),
            );
            expect(management.project.id, 'project-a');
            expect(management.attendance, same(attendance));
            expect(attendance.commands.length, 1);
            expect(attendance.workforceReads, ['members:project-a']);
            attendance.teamCountsOverride = const [
              ActiveTeamCount(
                teamId: 'team-a',
                teamName: 'Ekip A',
                subcontractorName: 'Firma',
                activePersonCount: 1,
              ),
            ];
            await tester.pageBack();
            await tester.pumpAndSettle();
            expect(_key('attendance-workforce-prerequisite'), findsNothing);
            expect(
              find.text('1 aktif ekip • 1 aktif personel'),
              findsOneWidget,
            );
            expect(attendance.commands.length, 2);
            expect(attendance.commands.last.id, attendance.commands.first.id);
            expect(
              attendance.commands.last.eventId,
              attendance.commands.first.eventId,
            );
            expect(
              attendance.commands.last.localDate,
              attendance.commands.first.localDate,
            );
            expect(attendance.rolling, 2);
            expect(attendance.detailReads.length, 2);
            expect(attendance.teamReads, ['project-a', 'project-a']);
            expect(agenda.listProjectsCalls, 1);
            expect(attendance.saveCalls, 0);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets(
    'date previous next today and picker keep exact query and identity',
    (tester) async {
      final attendance = _Attendance();
      await _pump(tester, attendance);
      final initial = attendance.commands.single;
      await _tap(tester, 'attendance-previous-day');
      expect(
        attendance.commands.last.localDate,
        CseTimeCodec.shiftIstanbulDay(initial.localDate, -1),
      );
      await _tap(tester, 'attendance-next-day');
      expect(attendance.commands.last.localDate, initial.localDate);
      expect(attendance.commands.last.id, initial.id);
      expect(attendance.commands.last.eventId, initial.eventId);
      await _tap(tester, 'attendance-next-day');
      expect(
        attendance.commands.last.localDate,
        CseTimeCodec.shiftIstanbulDay(initial.localDate, 1),
      );
      await _tap(tester, 'attendance-today');
      expect(attendance.commands.last.localDate, initial.localDate);
      await _tap(tester, 'attendance-date-picker');
      expect(attendance.commands.length, 5);
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '08/17/2026');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(attendance.commands.last.localDate, '2026-08-17');
      expect(attendance.commands.map((c) => c.projectId).toSet(), {
        'project-a',
      });
      expect(attendance.commands.length, 6);
      expect(attendance.rolling, 6);
      expect(attendance.teamReads.length, 6);
      expect(attendance.detailReads.length, 6);
      await _tap(tester, 'attendance-date-picker');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(attendance.commands.length, 6);
    },
  );

  testWidgets(
    'rail routes retain project and restore scroll after exact return reload',
    (tester) async {
      final attendance = _Attendance();
      await _pump(tester, attendance, size: const Size(320, 360), scale: 2);
      await Scrollable.ensureVisible(
        tester.element(_key('open-attendance-day')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      final before = tester.state<ScrollableState>(_scroll).position.pixels;
      expect(before, greaterThan(0));
      for (final key in ['manage-workforce', 'attendance-reminder-settings']) {
        final loads = attendance.commands.length;
        await _tap(tester, key);
        if (key == 'manage-workforce') {
          expect(
            tester.widget<WorkforcePage>(find.byType(WorkforcePage)).project.id,
            'project-a',
          );
        } else {
          expect(
            tester
                .widget<AttendanceSettingsPage>(
                  find.byType(AttendanceSettingsPage),
                )
                .project
                .id,
            'project-a',
          );
        }
        expect(attendance.commands.length, loads);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(attendance.commands.length, loads + 1);
        expect(
          attendance.commands.last.localDate,
          attendance.commands.first.localDate,
        );
        expect(attendance.commands.last.id, attendance.commands.first.id);
        expect(
          tester.state<ScrollableState>(_scroll).position.pixels,
          closeTo(before, 1),
        );
        expect(attendance.saveCalls, 0);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'no project and loading error remain visible without extra reads',
    (tester) async {
      final attendance = _Attendance();
      await _pump(tester, attendance, projects: const []);
      expect(
        find.text('Puantaj için önce Ajanda bölümünden bir proje oluşturun.'),
        findsOneWidget,
      );
      expect(attendance.commands, isEmpty);
      expect(_key('attendance-workforce-prerequisite'), findsNothing);
      expect(
        tester.widget<IconButton>(_key('manage-workforce')).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(_key('attendance-reminder-settings'))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      final failing = _Attendance()..pending = Completer<AttendanceDay>();
      await _pump(tester, failing, settle: false);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      failing.pending!.completeError(StateError('synthetic day failure'));
      await tester.pumpAndSettle();
      expect(find.text('Puantaj günü açılamadı.'), findsOneWidget);
      expect(failing.commands.length, 1);
      expect(failing.rolling, 0);
      expect(failing.teamReads, isEmpty);
      expect(_key('attendance-workforce-prerequisite'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  _Attendance attendance, {
  Size size = const Size(390, 844),
  double scale = 1,
  List<MobileProject> projects = const [_project],
  bool settle = true,
  FakeAgendaApplication? agenda,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: AttendancePage(
          attendance: attendance,
          agenda: agenda ?? FakeAgendaApplication(projects: projects),
          activeProjectId: 'project-a',
          isActive: true,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

class _Attendance extends FakeAttendanceApplication {
  List<ActiveTeamCount>? teamCountsOverride;
  final workforceReads = <String>[];
  final commands = <EnsureAttendanceDayCommand>[];
  final teamReads = <String>[];
  final detailReads = <String>[];
  int rolling = 0;
  Completer<AttendanceDay>? pending;
  @override
  Future<AttendanceDay> ensureDay(EnsureAttendanceDayCommand command) async {
    commands.add(command);
    if (pending != null) return pending!.future;
    detail = null;
    final day = await super.ensureDay(command);
    detail = AttendanceDayDetail(
      day: day,
      entries: const [],
      events: const [],
      totals: const AttendanceTotals(
        fullDayCount: 3,
        halfDayCount: 1,
        absentCount: 0,
        leaveCount: 0,
        presentCount: 4,
        personDayEquivalent: 3.5,
        overtimeMinutes: 45,
      ),
      teamSummaries: const [],
      linkedReminder: null,
    );
    return day;
  }

  @override
  Future<void> ensureRollingOccurrences() async {
    rolling++;
  }

  @override
  Future<AttendanceDayDetail> getDayDetail(String dayId) async {
    detailReads.add(dayId);
    return super.getDayDetail(dayId);
  }

  @override
  Future<List<ActiveTeamCount>> listActiveTeamCounts(String projectId) async {
    teamReads.add(projectId);
    return teamCountsOverride ??
        const [
          ActiveTeamCount(
            teamId: 'team-a',
            teamName: 'Ekip A',
            subcontractorName: 'Firma',
            activePersonCount: 3,
          ),
          ActiveTeamCount(
            teamId: 'team-b',
            teamName: 'Ekip B',
            subcontractorName: 'Firma',
            activePersonCount: 4,
          ),
        ];
  }

  @override
  Future<List<Subcontractor>> listSubcontractors(
    String projectId, {
    bool includeArchived = false,
  }) {
    workforceReads.add('employers:$projectId');
    return super.listSubcontractors(
      projectId,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  }) {
    workforceReads.add('members:$projectId');
    return super.listMembers(projectId, includeInactive: includeInactive);
  }

  @override
  Future<List<WorkforceTeam>> listTeams(
    String projectId, {
    String? subcontractorId,
    bool includeArchived = false,
  }) {
    workforceReads.add('teams:$projectId');
    return super.listTeams(
      projectId,
      subcontractorId: subcontractorId,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<WorkforcePersonDetail> getPersonDetail(String memberId) =>
      throw StateError('Unexpected compliance/person detail read');
}
