import 'dart:async';

import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/projects/project_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const _project = MobileProject(
  id: 'project-a',
  name: 'Proje A',
  createdAt: '2026-09-05',
  updatedAt: '2026-09-05',
  revision: 1,
);
Finder _key(String key) => find.byKey(Key(key));
Finder get _scroll => find
    .descendant(of: _key('attendance-page'), matching: find.byType(Scrollable))
    .first;

void main() {
  for (final size in [const Size(320, 360), const Size(390, 844)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'discovery failure retry and true empty state at $size text $scale',
        (tester) async {
          final agenda = _Agenda()..fail = true;
          final attendance = _Attendance();
          await _pump(tester, agenda, attendance, size: size, scale: scale);
          expect(_key('attendance-no-project'), findsNothing);
          expect(_key('attendance-create-project'), findsNothing);
          expect(
            find.text('Projeler açılamadı. Lütfen tekrar deneyin.'),
            findsOneWidget,
          );
          expect(find.textContaining('internal_uuid'), findsNothing);
          await _reveal(tester, _key('attendance-retry'));
          expect(_key('attendance-retry').hitTestable(), findsOneWidget);
          expect(
            tester.getSize(_key('attendance-retry')).height,
            greaterThanOrEqualTo(48),
          );
          final retry = tester
              .widget<OutlinedButton>(_key('attendance-retry'))
              .onPressed!;
          agenda.fail = false;
          final pending = Completer<List<MobileProject>>();
          agenda.pending = pending;
          retry();
          retry();
          await tester.pump();
          expect(agenda.listProjectsCalls, 2);
          expect(attendance.commands, isEmpty);
          pending.complete(const []);
          await tester.pumpAndSettle();
          expect(_key('attendance-page-error'), findsNothing);
          expect(_key('attendance-retry'), findsNothing);
          expect(_key('attendance-no-project'), findsOneWidget);
          expect(find.text('Yeni proje oluştur'), findsOneWidget);
          await _reveal(tester, _key('attendance-create-project'));
          expect(
            _key('attendance-create-project').hitTestable(),
            findsOneWidget,
          );
          expect(
            tester.getSize(_key('attendance-create-project')).height,
            greaterThanOrEqualTo(48),
          );
          expect(
            tester.getSize(_key('attendance-create-project')).width,
            greaterThanOrEqualTo(48),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'existing create route reports exact id and waits for shared adoption',
    (tester) async {
      final agenda = _Agenda();
      final attendance = _Attendance();
      String? activeId;
      final reported = <String>[];
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return AttendancePage(
                  attendance: attendance,
                  agenda: agenda,
                  activeProjectId: activeId,
                  isActive: true,
                  onProjectSelected: reported.add,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, _key('attendance-create-project'));
      expect(
        tester.widget<ProjectCreatePage>(find.byType(ProjectCreatePage)).agenda,
        same(agenda),
      );
      await tester.enterText(_key('project-name'), 'Yeni Proje');
      await _tap(tester, _key('save-project'));
      expect(agenda.projects.length, 1);
      expect(reported, [agenda.projects.single.id]);
      expect(attendance.commands, isEmpty);
      update(() => activeId = reported.single);
      await tester.pumpAndSettle();
      expect(attendance.commands.single.projectId, reported.single);
      expect(_key('open-attendance-day'), findsOneWidget);
    },
  );

  testWidgets(
    'create without callback refreshes discovery without adopting a project',
    (tester) async {
      final agenda = _Agenda();
      final attendance = _Attendance();
      await _pump(tester, agenda, attendance, activeId: null);
      final reads = agenda.listProjectsCalls;
      await _tap(tester, _key('attendance-create-project'));
      await tester.enterText(_key('project-name'), 'Yeni Proje');
      await _tap(tester, _key('save-project'));
      expect(agenda.listProjectsCalls, greaterThan(reads));
      final selector = find.byType(DropdownButtonFormField<String>);
      expect(tester.state<FormFieldState<String>>(selector).value, isNull);
      await _tap(tester, selector);
      expect(find.text('Yeni Proje'), findsOneWidget);
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.descendant(
                of: selector,
                matching: find.byType(DropdownButton<String>),
              ),
            )
            .items!
            .single
            .value,
        agenda.projects.single.id,
      );
      expect(attendance.commands, isEmpty);
      expect(_key('attendance-no-project'), findsNothing);
    },
  );

  testWidgets(
    'initial day retry reuses ensure identities and suppresses duplicate chains',
    (tester) async {
      final agenda = _Agenda()..projects = const [_project];
      final attendance = _Attendance()..failEnsure = true;
      await _pump(tester, agenda, attendance);
      final first = attendance.commands.single;
      expect(find.text('Puantaj günü açılamadı.'), findsOneWidget);
      expect(_key('attendance-no-project'), findsNothing);
      expect(find.textContaining('internal_uuid'), findsNothing);
      attendance.failEnsure = false;
      attendance.pendingEnsure = Completer<void>();
      final retry = tester
          .widget<OutlinedButton>(_key('attendance-retry'))
          .onPressed!;
      retry();
      retry();
      await tester.pump();
      expect(attendance.commands.length, 2);
      expect(attendance.rollingCalls, 0);
      attendance.pendingEnsure!.complete();
      await tester.pumpAndSettle();
      final retried = attendance.commands.last;
      expect(retried.id, first.id);
      expect(retried.eventId, first.eventId);
      expect(retried.projectId, first.projectId);
      expect(retried.localDate, first.localDate);
      expect(attendance.rollingCalls, 1);
      expect(attendance.detailReads, 1);
      expect(attendance.teamReads, 1);
      expect(_key('attendance-page-error'), findsNothing);
      expect(_key('open-attendance-day'), findsOneWidget);
    },
  );

  testWidgets(
    'failed return reload retains detail and scroll; retry recovers same day',
    (tester) async {
      final agenda = _Agenda()..projects = const [_project];
      final attendance = _Attendance();
      await _pump(
        tester,
        agenda,
        attendance,
        size: const Size(320, 360),
        scale: 2,
      );
      await _reveal(tester, _key('open-attendance-day'));
      final before = tester.state<ScrollableState>(_scroll).position.pixels;
      expect(before, greaterThan(0));
      final day = attendance.commands.single.localDate;
      await tester.tap(_key('open-attendance-day'));
      await tester.pumpAndSettle();
      attendance.pendingDetail = Completer<AttendanceDayDetail>();
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 350));
      expect(_key('open-attendance-day'), findsOneWidget);
      expect(_key('attendance-refreshing'), findsOneWidget);
      expect(
        tester.state<ScrollableState>(_scroll).position.pixels,
        closeTo(before, 1),
      );
      attendance.pendingDetail!.completeError(
        const AgendaValidationFailure('internal_uuid revision SQL'),
      );
      await tester.pumpAndSettle();
      expect(_key('open-attendance-day'), findsOneWidget);
      expect(find.text('Puantaj günü açılamadı.'), findsOneWidget);
      expect(
        tester.state<ScrollableState>(_scroll).position.pixels,
        closeTo(before, 1),
      );
      expect(find.textContaining('internal_uuid'), findsNothing);
      attendance.pendingDetail = null;
      final retry = tester
          .widget<OutlinedButton>(_key('attendance-retry'))
          .onPressed!;
      retry();
      retry();
      await tester.pumpAndSettle();
      expect(_key('attendance-page-error'), findsNothing);
      expect(_key('open-attendance-day'), findsOneWidget);
      expect(attendance.commands.length, 3);
      expect(attendance.commands.map((c) => c.localDate).toSet(), {day});
      expect(attendance.commands.map((c) => c.id).toSet().length, 1);
      expect(attendance.commands.map((c) => c.eventId).toSet().length, 1);
      expect(
        tester.state<ScrollableState>(_scroll).position.pixels,
        closeTo(before, 1),
      );
    },
  );
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  _Agenda agenda,
  _Attendance attendance, {
  Size size = const Size(390, 844),
  double scale = 1,
  String? activeId = 'project-a',
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
          agenda: agenda,
          activeProjectId: activeId,
          isActive: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Agenda extends FakeAgendaApplication {
  bool fail = false;
  Completer<List<MobileProject>>? pending;
  @override
  Future<List<MobileProject>> listProjects() async {
    listProjectsCalls++;
    if (fail) {
      throw const AgendaValidationFailure('internal_uuid project SQL');
    }
    if (pending != null) {
      return pending!.future;
    }
    return projects;
  }
}

class _Attendance extends FakeAttendanceApplication {
  final commands = <EnsureAttendanceDayCommand>[];
  bool failEnsure = false;
  Completer<void>? pendingEnsure;
  Completer<AttendanceDayDetail>? pendingDetail;
  int rollingCalls = 0;
  int detailReads = 0;
  int teamReads = 0;
  @override
  Future<AttendanceDay> ensureDay(EnsureAttendanceDayCommand command) async {
    commands.add(command);
    if (failEnsure) {
      throw const AgendaValidationFailure('internal_uuid ensure SQL');
    }
    if (pendingEnsure != null) {
      await pendingEnsure!.future;
    }
    return super.ensureDay(command);
  }

  @override
  Future<void> ensureRollingOccurrences() async {
    rollingCalls++;
  }

  @override
  Future<AttendanceDayDetail> getDayDetail(String dayId) async {
    detailReads++;
    if (pendingDetail != null) {
      return pendingDetail!.future;
    }
    return super.getDayDetail(dayId);
  }

  @override
  Future<List<ActiveTeamCount>> listActiveTeamCounts(String projectId) async {
    teamReads++;
    return const [];
  }
}
