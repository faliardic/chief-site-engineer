import 'dart:async';

import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const dayId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const subcontractorAId = '11111111-1111-4111-8111-111111111111';
const subcontractorBId = '22222222-2222-4222-8222-222222222222';
const teamA1Id = '33333333-3333-4333-8333-333333333331';
const teamA2Id = '33333333-3333-4333-8333-333333333332';
const teamBId = '44444444-4444-4444-8444-444444444444';
const memberA1Id = '55555555-5555-4555-8555-555555555551';
const memberA2Id = '55555555-5555-4555-8555-555555555552';
const memberBId = '66666666-6666-4666-8666-666666666666';
const archivedMemberId = '77777777-7777-4777-8777-777777777771';
const restoredMemberId = '77777777-7777-4777-8777-777777777772';

void main() {
  testWidgets(
    'subcontractor and team scope candidates while selected rows stay visible',
    (tester) async {
      final attendance = _attendance(
        members: [
          _member(
            id: memberA1Id,
            name: 'Ali Kalıpçı',
            subcontractorId: subcontractorAId,
            subcontractorName: 'Taşeron A',
            teamId: teamA1Id,
            teamName: 'Ekip A1',
            role: 'Kalıpçı',
            phone: '0555 111 11 11',
          ),
          _member(
            id: memberA2Id,
            name: 'Ayşe Demirci',
            subcontractorId: subcontractorAId,
            subcontractorName: 'Taşeron A',
            teamId: teamA2Id,
            teamName: 'Ekip A2',
            role: 'Demirci',
          ),
          _member(
            id: memberBId,
            name: 'Veli Sıvacı',
            subcontractorId: subcontractorBId,
            subcontractorName: 'Taşeron B',
            teamId: teamBId,
            teamName: 'Ekip B',
            role: 'Sıvacı',
          ),
        ],
      );
      await _pumpPage(tester, attendance);

      expect(
        find.byKey(const Key('attendance-roster-selector')),
        findsOneWidget,
      );
      expect(find.byKey(Key('attendance-candidate-$memberA1Id')), findsNothing);
      expect(find.byKey(Key('attendance-candidate-$memberBId')), findsNothing);

      await _selectSubcontractor(tester, 'Taşeron A');
      expect(
        find.byKey(Key('attendance-candidate-$memberA1Id')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('attendance-candidate-$memberA2Id')),
        findsOneWidget,
      );
      expect(find.byKey(Key('attendance-candidate-$memberBId')), findsNothing);
      expect(find.textContaining('0555 111 11 11'), findsOneWidget);

      await _selectTeam(tester, 'Ekip A1');
      expect(
        find.byKey(Key('attendance-candidate-$memberA1Id')),
        findsOneWidget,
      );
      expect(find.byKey(Key('attendance-candidate-$memberA2Id')), findsNothing);

      await tester.tap(find.byKey(Key('add-attendance-member-$memberA1Id')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('attendance-member-$memberA1Id')), findsOneWidget);
      expect(find.byKey(Key('attendance-candidate-$memberA1Id')), findsNothing);

      await _selectSubcontractor(tester, 'Taşeron B');
      expect(find.byKey(Key('attendance-member-$memberA1Id')), findsOneWidget);
      expect(
        find.byKey(Key('attendance-candidate-$memberBId')),
        findsOneWidget,
      );
      expect(find.byKey(Key('attendance-candidate-$memberA2Id')), findsNothing);
      expect(attendance.detail!.entries, isEmpty);
    },
  );

  testWidgets(
    'archived historical member stays selected but only restored member is candidate',
    (tester) async {
      final archived = _member(
        id: archivedMemberId,
        name: 'Arşivli Usta',
        subcontractorId: subcontractorAId,
        subcontractorName: 'Taşeron A',
        teamId: teamA1Id,
        teamName: 'Ekip A1',
        role: 'Usta',
        isActive: false,
      );
      final inactiveCandidate = _member(
        id: memberA2Id,
        name: 'Arşivli Aday',
        subcontractorId: subcontractorAId,
        subcontractorName: 'Taşeron A',
        teamId: teamA1Id,
        teamName: 'Ekip A1',
        role: 'İşçi',
        isActive: false,
      );
      final restored = _member(
        id: restoredMemberId,
        name: 'Geri Açılan Usta',
        subcontractorId: subcontractorAId,
        subcontractorName: 'Taşeron A',
        teamId: teamA1Id,
        teamName: 'Ekip A1',
        role: 'Usta',
      );
      final attendance = _attendance(
        members: [archived, inactiveCandidate, restored],
        detail: _detail(entries: [_entry(archived)]),
      );
      await _pumpPage(tester, attendance);

      expect(
        find.byKey(Key('attendance-member-$archivedMemberId')),
        findsOneWidget,
      );
      expect(find.text('Arşivli Usta (pasif)'), findsOneWidget);
      await _selectSubcontractor(tester, 'Taşeron A');

      expect(
        find.byKey(Key('attendance-candidate-$archivedMemberId')),
        findsNothing,
      );
      expect(find.byKey(Key('attendance-candidate-$memberA2Id')), findsNothing);
      expect(
        find.byKey(Key('attendance-candidate-$restoredMemberId')),
        findsOneWidget,
      );
    },
  );

  testWidgets('zero active team is an explicit fail-closed state', (
    tester,
  ) async {
    final attendance = FakeAttendanceApplication(detail: _detail())
      ..subcontractors = [_subcontractor(subcontractorAId, 'Taşeron A')];
    await _pumpPage(tester, attendance);
    await _selectSubcontractor(tester, 'Taşeron A');

    expect(find.byKey(const Key('attendance-no-active-team')), findsOneWidget);
    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('attendance-new-member')),
    );
    expect(button.onPressed, isNull);
    expect(attendance.createMemberCalls, 0);
  });

  testWidgets('multiple active teams require an explicit inline selection', (
    tester,
  ) async {
    final attendance = _attendance();
    await _pumpPage(tester, attendance);
    await _selectSubcontractor(tester, 'Taşeron A');
    await tester.tap(find.byKey(const Key('attendance-new-member')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('attendance-inline-member-name')),
      'Yeni Usta',
    );
    await tester.enterText(
      find.byKey(const Key('attendance-inline-member-role')),
      'Usta',
    );
    await tester.tap(find.byKey(const Key('save-attendance-inline-member')));
    await tester.pumpAndSettle();

    expect(find.text('Aktif ekip seçilmelidir.'), findsOneWidget);
    expect(attendance.createMemberCalls, 0);
    await _selectInlineTeam(tester, 'Ekip A2');
    await tester.tap(find.byKey(const Key('save-attendance-inline-member')));
    await tester.pumpAndSettle();

    expect(attendance.createMemberCalls, 1);
    expect(attendance.lastCreateMemberCommand!.projectId, projectId);
    expect(
      attendance.lastCreateMemberCommand!.subcontractorId,
      subcontractorAId,
    );
    expect(attendance.lastCreateMemberCommand!.teamId, teamA2Id);
    expect(
      find.byKey(const Key('attendance-new-member-warning')),
      findsOneWidget,
    );
    expect(attendance.detail!.entries, isEmpty);
  });

  testWidgets(
    'inline create is single-submit and roster save uses the same canonical ID',
    (tester) async {
      final pending = Completer<WorkforceMember>();
      final attendance = _attendance(teams: [_teamA1()])
        ..createMemberCompleter = pending;
      await _pumpPage(tester, attendance);
      await _selectSubcontractor(tester, 'Taşeron A');
      await tester.tap(find.byKey(const Key('attendance-new-member')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('attendance-inline-member-name')),
        'Tek Kimlikli Yeni Eleman',
      );
      await tester.enterText(
        find.byKey(const Key('attendance-inline-member-role')),
        'Elektrikçi',
      );
      await tester.enterText(
        find.byKey(const Key('attendance-inline-member-phone')),
        '0555 999 99 99',
      );
      final create = tester.widget<FilledButton>(
        find.byKey(const Key('save-attendance-inline-member')),
      );
      create.onPressed!();
      create.onPressed!();
      await tester.pump();

      expect(attendance.createMemberCalls, 1);
      final command = attendance.lastCreateMemberCommand!;
      expect(command.projectId, projectId);
      expect(command.subcontractorId, subcontractorAId);
      expect(command.teamId, teamA1Id);
      expect(command.teamName, 'Ekip A1');
      final created = _member(
        id: command.id,
        name: command.fullName,
        subcontractorId: subcontractorAId,
        subcontractorName: 'Taşeron A',
        teamId: teamA1Id,
        teamName: 'Ekip A1',
        role: command.roleName,
        phone: command.phone,
      );
      attendance.members = [created];
      pending.complete(created);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('attendance-new-member-warning')),
        findsOneWidget,
      );
      expect(
        find.textContaining('CSE resmi uygunluk kararı vermez'),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('attendance-member-${command.id}')),
        findsOneWidget,
      );
      expect(attendance.detail!.entries, isEmpty);

      await _scrollDayTo(
        tester,
        find.byKey(const Key('save-attendance-draft')),
      );
      await tester.tap(find.byKey(const Key('save-attendance-draft')));
      await tester.pumpAndSettle();

      expect(attendance.saveCalls, 1);
      expect(attendance.lastRosterCommand!.values, hasLength(1));
      expect(attendance.lastRosterCommand!.values.single.memberId, command.id);
      expect(attendance.detail!.entries.single.memberId, command.id);
    },
  );
}

FakeAttendanceApplication _attendance({
  List<WorkforceMember> members = const [],
  List<WorkforceTeam>? teams,
  AttendanceDayDetail? detail,
}) => FakeAttendanceApplication(members: members, detail: detail ?? _detail())
  ..subcontractors = [
    _subcontractor(subcontractorAId, 'Taşeron A'),
    _subcontractor(subcontractorBId, 'Taşeron B'),
  ]
  ..teams =
      teams ??
      [
        _teamA1(),
        _team(
          id: teamA2Id,
          subcontractorId: subcontractorAId,
          subcontractorName: 'Taşeron A',
          name: 'Ekip A2',
        ),
        _team(
          id: teamBId,
          subcontractorId: subcontractorBId,
          subcontractorName: 'Taşeron B',
          name: 'Ekip B',
        ),
      ];

Subcontractor _subcontractor(String id, String name) => Subcontractor(
  id: id,
  projectId: projectId,
  name: name,
  contactName: null,
  phone: null,
  note: null,
  status: WorkforceRecordStatus.active,
  activeTeamCount: 0,
  activePersonCount: 0,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);

WorkforceTeam _teamA1() => _team(
  id: teamA1Id,
  subcontractorId: subcontractorAId,
  subcontractorName: 'Taşeron A',
  name: 'Ekip A1',
);

WorkforceTeam _team({
  required String id,
  required String subcontractorId,
  required String subcontractorName,
  required String name,
}) => WorkforceTeam(
  id: id,
  projectId: projectId,
  subcontractorId: subcontractorId,
  subcontractorName: subcontractorName,
  name: name,
  leadName: null,
  note: null,
  status: WorkforceRecordStatus.active,
  activePersonCount: 0,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);

WorkforceMember _member({
  required String id,
  required String name,
  required String subcontractorId,
  required String subcontractorName,
  required String teamId,
  required String teamName,
  required String role,
  String? phone,
  bool isActive = true,
}) => WorkforceMember(
  id: id,
  projectId: projectId,
  fullName: name,
  teamName: teamName,
  roleName: role,
  personnelCode: null,
  subcontractorId: subcontractorId,
  subcontractorName: subcontractorName,
  teamId: teamId,
  phone: phone,
  isActive: isActive,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: isActive ? null : '2026-08-09T09:00:00Z',
);

AttendanceEntry _entry(WorkforceMember member) => AttendanceEntry(
  id: '88888888-8888-4888-8888-888888888888',
  attendanceDayId: dayId,
  memberId: member.id,
  memberName: member.fullName,
  teamName: member.teamName,
  teamId: member.teamId,
  subcontractorName: member.subcontractorName,
  roleName: member.roleName,
  personnelCode: member.personnelCode,
  memberIsActive: member.isActive,
  result: AttendanceResult.fullDay,
  overtimeMinutes: 0,
  shortNote: null,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
);

AttendanceDayDetail _detail({List<AttendanceEntry> entries = const []}) =>
    AttendanceDayDetail(
      day: const AttendanceDay(
        id: dayId,
        projectId: projectId,
        projectName: 'Test Projesi',
        localDate: '2026-08-09',
        status: AttendanceDayStatus.draft,
        generalNote: null,
        revision: 1,
        createdAt: '2026-08-09T08:00:00Z',
        updatedAt: '2026-08-09T08:00:00Z',
        completedAt: null,
      ),
      entries: entries,
      events: const [],
      totals: entries.isEmpty
          ? const AttendanceTotals.zero()
          : const AttendanceTotals(
              fullDayCount: 1,
              halfDayCount: 0,
              absentCount: 0,
              leaveCount: 0,
              presentCount: 1,
              personDayEquivalent: 1,
              overtimeMinutes: 0,
            ),
      teamSummaries: const [],
      linkedReminder: null,
    );

Future<void> _pumpPage(
  WidgetTester tester,
  FakeAttendanceApplication attendance,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1400);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: AttendanceDayPage(
        attendance: attendance,
        agenda: FakeAgendaApplication(projects: const [_project]),
        dayId: dayId,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _project = MobileProject(
  id: projectId,
  name: 'Test Projesi',
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  revision: 1,
);

Future<void> _selectSubcontractor(WidgetTester tester, String name) async {
  final dropdown = find.descendant(
    of: find.byKey(const Key('attendance-subcontractor-selector')),
    matching: find.byType(DropdownButtonFormField<String>),
  );
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _selectTeam(WidgetTester tester, String name) async {
  final dropdown = find.descendant(
    of: find.byKey(const Key('attendance-team-filter')),
    matching: find.byType(DropdownButtonFormField<String>),
  );
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _selectInlineTeam(WidgetTester tester, String name) async {
  final dropdown = find.byKey(const Key('attendance-inline-member-team'));
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _scrollDayTo(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byKey(const Key('attendance-day-detail')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(
    target,
    260,
    scrollable: scrollable,
    maxScrolls: 12,
  );
  await tester.pumpAndSettle();
}
