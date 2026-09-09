import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_directory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const _project = MobileProject(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-09-09T08:00:00Z',
  updatedAt: '2026-09-09T08:00:00Z',
  revision: 1,
);

const _projectB = MobileProject(
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  name: 'Güney Şantiyesi',
  createdAt: '2026-09-09T08:00:00Z',
  updatedAt: '2026-09-09T08:00:00Z',
  revision: 1,
);

void main() {
  testWidgets(
    'İş Gücü keeps canonical subview state and shared project at compact sizes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final attendance = _TrackingAttendance();
      final agenda = FakeAgendaApplication(projects: const [_project]);

      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'Test',
              smokeRecordId: 'issue-750-workforce-hub',
              smokeRecordCreatedAt: '2026-09-09T08:00:00Z',
              agenda: agenda,
              attendance: attendance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('active-project-indicator')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('active-project-option-${_project.id}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('İş Gücü').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workforce-hub')), findsOneWidget);
      expect(
        find.byKey(const Key('workforce-hub-stacked-selector')),
        findsOneWidget,
      );
      expect(find.byType(AttendancePage), findsOneWidget);
      expect(find.byKey(const Key('attendance-project')), findsNothing);
      expect(attendance.ensureDayCalls, 1);
      expect(attendance.directoryMemberLoads, 0);
      final attendanceState = tester.state(find.byType(AttendancePage));

      await tester.tap(find.byKey(const Key('workforce-hub-directory-tab')));
      await tester.pumpAndSettle();
      expect(find.byType(WorkforceDirectoryPage), findsOneWidget);
      expect(find.text('Görünen proje: ${_project.name}'), findsOneWidget);
      expect(attendance.directoryMemberLoads, 1);
      final directoryState = tester.state(find.byType(WorkforceDirectoryPage));
      await tester.tap(
        find.byKey(const Key('workforce-directory-search-action')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('workforce-directory-search')),
        'usta',
      );

      await tester.tap(find.byKey(const Key('workforce-hub-attendance-tab')));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(AttendancePage)), same(attendanceState));
      expect(attendance.ensureDayCalls, 1);

      await tester.tap(find.byKey(const Key('workforce-hub-directory-tab')));
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(WorkforceDirectoryPage)),
        same(directoryState),
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('workforce-directory-search')),
            )
            .controller!
            .text,
        'usta',
      );
      expect(attendance.directoryMemberLoads, 1);

      tester.platformDispatcher.textScaleFactorTestValue = 1;
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('workforce-hub-inline-selector')),
        findsOneWidget,
      );
      await agenda.createProject(
        const CreateProjectCommand(
          id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          name: 'Catalog signal',
        ),
      );
      await tester.pumpAndSettle();
      expect(attendance.ensureDayCalls, 1);
      await tester.tap(find.byKey(const Key('workforce-hub-attendance-tab')));
      await tester.pumpAndSettle();
      expect(attendance.ensureDayCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Sicil ignores a stale project discovery completion', (
    tester,
  ) async {
    final firstDiscovery = Completer<List<MobileProject>>();
    final agenda = FakeAgendaApplication()
      ..listProjectsResponses.addAll([
        firstDiscovery.future,
        Future.value(const [_project, _projectB]),
      ]);
    final attendance = _TrackingAttendance();

    Widget directory(String projectId) => MaterialApp(
      home: Scaffold(
        body: WorkforceDirectoryPage(
          attendance: attendance,
          agenda: agenda,
          activeProjectId: projectId,
          usesSharedProjectContext: true,
        ),
      ),
    );

    await tester.pumpWidget(directory(_project.id));
    await tester.pump();
    expect(agenda.listProjectsCalls, 1);

    await tester.pumpWidget(directory(_projectB.id));
    await tester.pumpAndSettle();
    expect(agenda.listProjectsCalls, 2);
    expect(find.text('Görünen proje: ${_projectB.name}'), findsOneWidget);

    firstDiscovery.complete(const [_project]);
    await tester.pumpAndSettle();

    expect(find.text('Görünen proje: ${_projectB.name}'), findsOneWidget);
    expect(find.text('Görünen proje: ${_project.name}'), findsNothing);
    expect(attendance.directoryProjectLoads, [_projectB.id]);
    expect(tester.takeException(), isNull);
  });
}

class _TrackingAttendance extends FakeAttendanceApplication {
  int ensureDayCalls = 0;
  int directoryMemberLoads = 0;
  final List<String> directoryProjectLoads = [];

  @override
  Future<AttendanceDay> ensureDay(EnsureAttendanceDayCommand command) {
    ensureDayCalls += 1;
    return super.ensureDay(command);
  }

  @override
  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  }) {
    if (includeInactive) {
      directoryMemberLoads += 1;
      directoryProjectLoads.add(projectId);
    }
    return super.listMembers(projectId, includeInactive: includeInactive);
  }
}
