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
const teamAId = '33333333-3333-4333-8333-333333333331';
const teamBId = '44444444-4444-4444-8444-444444444444';
const memberAId = '55555555-5555-4555-8555-555555555551';
const memberBId = '66666666-6666-4666-8666-666666666666';
const archivedMemberId = '77777777-7777-4777-8777-777777777771';
const inactiveMemberId = '77777777-7777-4777-8777-777777777772';

void main() {
  testWidgets(
    'Q04-C1 active people are immediately visible in deterministic flat order',
    (tester) async {
      final attendance = _attendance(
        members: [
          _member(
            id: memberBId,
            name: 'Veli Sıvacı',
            subcontractorId: subcontractorBId,
            subcontractorName: 'Taşeron B',
            teamId: teamBId,
            teamName: 'Ekip B',
            role: 'Sıvacı',
          ),
          _member(
            id: memberAId,
            name: 'Ali Kalıpçı',
            subcontractorId: subcontractorAId,
            subcontractorName: 'Taşeron A',
            teamId: teamAId,
            teamName: 'Ekip A',
            role: 'Kalıpçı',
            phone: '0555 111 11 11',
          ),
        ],
      );

      await _pumpPage(tester, attendance);

      expect(find.byKey(const Key('attendance-flat-list')), findsOneWidget);
      expect(find.byKey(const Key('attendance-roster-selector')), findsNothing);
      expect(
        find.byKey(const Key('attendance-inline-member-form')),
        findsNothing,
      );
      expect(find.byKey(Key('attendance-member-$memberAId')), findsOneWidget);
      expect(find.byKey(Key('attendance-member-$memberBId')), findsOneWidget);
      expect(find.text('Taşeron A • Kalıpçı'), findsOneWidget);
      expect(find.textContaining('0555 111 11 11'), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(Key('attendance-member-$memberAId'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(Key('attendance-member-$memberBId'))).dy,
        ),
      );
      expect(attendance.detail!.entries, isEmpty);
      expect(attendance.saveCalls, 0);
    },
  );

  testWidgets(
    'Q04-C1 inactive historical person stays visible and inactive non-entry stays hidden',
    (tester) async {
      final archived = _member(
        id: archivedMemberId,
        name: 'Arşivli Usta',
        subcontractorId: subcontractorAId,
        subcontractorName: 'Taşeron A',
        teamId: teamAId,
        teamName: 'Ekip A',
        role: 'Usta',
        isActive: false,
      );
      final inactive = _member(
        id: inactiveMemberId,
        name: 'Eski Aday',
        subcontractorId: subcontractorAId,
        subcontractorName: 'Taşeron A',
        teamId: teamAId,
        teamName: 'Ekip A',
        role: 'İşçi',
        isActive: false,
      );
      final attendance = _attendance(
        members: [inactive, archived],
        detail: _detail(entries: [_entry(archived)]),
      );

      await _pumpPage(tester, attendance);

      expect(
        find.byKey(Key('attendance-member-$archivedMemberId')),
        findsOneWidget,
      );
      expect(find.text('Arşivli Usta (pasif)'), findsOneWidget);
      expect(
        find.byKey(Key('attendance-member-$inactiveMemberId')),
        findsNothing,
      );
      expect(attendance.saveCalls, 0);
    },
  );

  testWidgets('Q04-C1 bulk marking stays local until explicit save', (
    tester,
  ) async {
    final attendance = _attendance(
      members: [
        _member(
          id: memberAId,
          name: 'Ali Kalıpçı',
          subcontractorId: subcontractorAId,
          subcontractorName: 'Taşeron A',
          teamId: teamAId,
          teamName: 'Ekip A',
          role: 'Kalıpçı',
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

    await _scrollDayTo(tester, find.byKey(const Key('attendance-bulk-tools')));
    await tester.tap(find.byKey(const Key('attendance-bulk-tools')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mark-all-full')));
    await tester.pump();

    expect(attendance.saveCalls, 0);
    expect(attendance.detail!.entries, isEmpty);
    expect(
      find.text('Tam gün 2 • Yarım gün 0 • Gelmedi 0 • İzinli 0'),
      findsOneWidget,
    );
    expect(find.text('İşaretlenmedi 0'), findsOneWidget);

    await _scrollDayTo(tester, find.byKey(const Key('save-attendance-draft')));
    await tester.tap(find.byKey(const Key('save-attendance-draft')));
    await tester.pumpAndSettle();

    expect(attendance.saveCalls, 1);
    expect(attendance.lastRosterCommand!.values, hasLength(2));
    expect(
      attendance.lastRosterCommand!.values.map((value) => value.memberId),
      containsAll(<String>[memberAId, memberBId]),
    );
  });

  testWidgets('Q04-C1 Personel ekle reuses the canonical Sicil form', (
    tester,
  ) async {
    final attendance = _attendance(
      members: [
        _member(
          id: memberAId,
          name: 'Ali Kalıpçı',
          subcontractorId: subcontractorAId,
          subcontractorName: 'Taşeron A',
          teamId: teamAId,
          teamName: 'Ekip A',
          role: 'Kalıpçı',
        ),
      ],
      subcontractors: [_subcontractor(subcontractorAId, 'Taşeron A')],
    );
    await _pumpPage(tester, attendance);

    await _scrollDayTo(tester, find.byKey(const Key('attendance-add-person')));
    await tester.tap(find.byKey(const Key('attendance-add-person')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('workforce-member-form')), findsOneWidget);
    expect(
      find.byKey(const Key('workforce-subcontractor-context')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('attendance-inline-member-form')),
      findsNothing,
    );
    expect(attendance.createMemberCalls, 0);
  });

  testWidgets('Q04-C1 no company shows one canonical company CTA', (
    tester,
  ) async {
    final attendance = _attendance(subcontractors: const []);
    await _pumpPage(tester, attendance);

    expect(find.byKey(const Key('attendance-add-company')), findsOneWidget);
    expect(find.byKey(const Key('attendance-add-person')), findsNothing);
    expect(attendance.detail!.entries, isEmpty);
    expect(attendance.saveCalls, 0);

    await tester.tap(find.byKey(const Key('attendance-add-company')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('workforce-directory-first-use')),
      findsOneWidget,
    );
    expect(attendance.detail!.entries, isEmpty);
    expect(attendance.saveCalls, 0);
  });

  testWidgets('Q04-C1 company without people shows one canonical person CTA', (
    tester,
  ) async {
    final attendance = _attendance(
      subcontractors: [_subcontractor(subcontractorAId, 'Taşeron A')],
    );
    await _pumpPage(tester, attendance);

    expect(find.byKey(const Key('attendance-add-company')), findsNothing);
    expect(find.byKey(const Key('attendance-add-person')), findsOneWidget);
    expect(attendance.detail!.entries, isEmpty);
    expect(attendance.saveCalls, 0);

    await tester.tap(find.byKey(const Key('attendance-add-person')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workforce-member-form')), findsOneWidget);
    expect(
      find.byKey(const Key('workforce-subcontractor-context')),
      findsOneWidget,
    );
    expect(attendance.detail!.entries, isEmpty);
    expect(attendance.saveCalls, 0);
  });

  testWidgets('Q04-C1 technical team stays hidden in direct list', (
    tester,
  ) async {
    final technicalMember = _member(
      id: memberAId,
      name: 'Ekipsiz Personel',
      subcontractorId: subcontractorAId,
      subcontractorName: 'Taseron A',
      teamId: workforceTechnicalTeamId(projectId, subcontractorAId),
      teamName: workforceTechnicalTeamStorageName,
      role: 'Usta',
    );
    final attendance = _attendance(members: [technicalMember]);
    await _pumpPage(tester, attendance);

    expect(find.text('Taseron A • Usta'), findsOneWidget);
    expect(
      find.textContaining(workforceTechnicalTeamStorageName),
      findsNothing,
    );
    await tester.tap(
      find.byKey(Key('attendance-member-details-${technicalMember.id}')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Ekip:'), findsNothing);
    expect(attendance.saveCalls, 0);
  });
}

FakeAttendanceApplication _attendance({
  List<WorkforceMember> members = const [],
  List<Subcontractor>? subcontractors,
  AttendanceDayDetail? detail,
}) => FakeAttendanceApplication(members: members, detail: detail ?? _detail())
  ..subcontractors =
      subcontractors ??
      [
        _subcontractor(subcontractorAId, 'Taşeron A'),
        _subcontractor(subcontractorBId, 'Taşeron B'),
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
        project: _project,
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
    maxScrolls: 16,
  );
  await tester.pumpAndSettle();
}
