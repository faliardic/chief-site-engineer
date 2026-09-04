import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_directory_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_registry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const _project1 = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _project2 = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _subcontractor1 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _subcontractor2 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
const _team1 = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const _team2 = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2';
const _member1 = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';
const _member2 = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd2';
const _member3 = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd3';

void main() {
  testWidgets(
    'Saha Rehberi opens from Dashboard with the shared project control',
    (tester) async {
      await _setPhoneSize(tester);
      final attendance = FakeAttendanceApplication();
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            BootstrapSuccess(
              environmentLabel: 'debug',
              smokeRecordId: 'smoke',
              smokeRecordCreatedAt: '2026-08-09T08:00:00Z',
              agenda: FakeAgendaApplication(projects: const [_firstProject]),
              attendance: attendance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navigation = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(
        navigation.destinations.cast<NavigationDestination>().map(
          (item) => item.label,
        ),
        ['Ana Sayfa', 'Hatırlatıcı', 'Ajanda', 'Envanter', 'Puantaj'],
      );

      await _openDashboardTool(
        tester,
        const Key('dashboard-workforce-directory'),
      );
      expect(find.byKey(const Key('workforce-directory')), findsOneWidget);
      expect(find.byType(ActiveProjectControl), findsOneWidget);
      expect(
        find.byKey(const ValueKey('workforce-directory-project-$_project1')),
        findsNothing,
      );
      expect(find.text('Görünen proje: Proje Bir'), findsOneWidget);
    },
  );

  testWidgets('directory is project scoped and has a safe no-project state', (
    tester,
  ) async {
    final attendance = _directoryAttendance();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkforceDirectoryPage(
            attendance: attendance,
            agenda: FakeAgendaApplication(
              projects: const [_firstProject, _secondProject],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ayşe Usta'), findsOneWidget);
    expect(find.text('Zeynep Mimar'), findsNothing);
    expect(
      find.byKey(const ValueKey('workforce-directory-project-$_project1')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const Key('workforce-directory-search')),
      'ZEYNEP',
    );
    await tester.tap(find.text('Arşiv'));
    await tester.pump();
    final state = tester.state<WorkforceDirectoryPageState>(
      find.byType(WorkforceDirectoryPage),
    );
    await state.selectProject(_project2);
    await tester.pumpAndSettle();
    expect(find.text('Ayşe Usta'), findsNothing);
    expect(find.text('Zeynep Mimar'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('workforce-directory-search')),
          )
          .controller!
          .text,
      'ZEYNEP',
    );
    expect(find.text('Görünen proje: Proje İki'), findsOneWidget);
    await tester.tap(find.text('Aktif'));
    await tester.pump();
    expect(find.text('Zeynep Mimar'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkforceDirectoryPage(
            key: const ValueKey('empty-directory-harness'),
            attendance: FakeAttendanceApplication(),
            agenda: FakeAgendaApplication(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('workforce-directory-no-projects')),
      findsOneWidget,
    );
  });

  testWidgets('search covers all directory fields case-insensitively', (
    tester,
  ) async {
    final attendance = _directoryAttendance();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkforceDirectoryPage(
            attendance: attendance,
            agenda: FakeAgendaApplication(projects: const [_firstProject]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final search = find.byKey(const Key('workforce-directory-search'));

    for (final query in [
      'AYŞE',
      '555 01',
      'DEMİRCİ',
      'BETON AŞ',
      'GECE EKİBİ',
    ]) {
      await tester.enterText(search, query);
      await tester.pump();
      expect(find.text('Ayşe Usta'), findsOneWidget, reason: query);
    }
    await tester.enterText(search, 'eşleşmeyen');
    await tester.pump();
    expect(find.byKey(const Key('workforce-directory-empty')), findsOneWidget);
  });

  testWidgets(
    'status subcontractor and team filters compose deterministically',
    (tester) async {
      final attendance = _directoryAttendance();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkforceDirectoryPage(
              attendance: attendance,
              agenda: FakeAgendaApplication(projects: const [_firstProject]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ayşe Usta'), findsOneWidget);
      expect(find.text('Mehmet Arşiv'), findsNothing);

      await tester.tap(find.text('Arşiv'));
      await tester.pump();
      expect(find.text('Ayşe Usta'), findsNothing);
      expect(find.text('Mehmet Arşiv'), findsOneWidget);

      await tester.tap(find.text('Aktif'));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('workforce-directory-subcontractor')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beton AŞ').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('workforce-directory-team-$_subcontractor1-null'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gece Ekibi').last);
      await tester.pumpAndSettle();
      expect(find.text('Ayşe Usta'), findsOneWidget);
      expect(find.text('Zeynep Mimar'), findsNothing);
    },
  );

  testWidgets('canonical member id opens archived history and summary', (
    tester,
  ) async {
    final attendance =
        _TrackingAttendance(
            members: [_archivedMember],
            summary: const WorkforceAttendanceSummary(
              personDayEquivalentTotal: 3.5,
              recentDays: [
                WorkforceAttendanceDay(
                  attendanceDayId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1',
                  localDate: '2026-08-08',
                  dayStatus: AttendanceDayStatus.completed,
                  result: AttendanceResult.halfDay,
                ),
              ],
            ),
          )
          ..subcontractors = [_firstSubcontractor]
          ..teams = [_firstTeam];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkforceDirectoryPage(
            attendance: attendance,
            agenda: FakeAgendaApplication(projects: const [_firstProject]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arşiv'));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('workforce-directory-member-$_member2')),
    );
    await tester.pumpAndSettle();

    expect(attendance.openedMemberId, _member2);
    expect(find.text('Toplam 3.5 kişi-gün'), findsOneWidget);
    expect(find.textContaining('Son kayıt: 2026-08-08'), findsOneWidget);
    expect(find.text('Pasif'), findsWidgets);
  });

  testWidgets('member profile edit exposes values and explicit clear flags', (
    tester,
  ) async {
    final attendance = _ProfileAttendance(members: [_activeMember])
      ..subcontractors = [_firstSubcontractor]
      ..teams = [_firstTeam];
    await tester.pumpWidget(
      MaterialApp(
        home: WorkforceMemberFormPage(
          attendance: attendance,
          project: _firstProject,
          member: _activeMember,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final address = find.byKey(const Key('workforce-address'));
    final startedOn = find.byKey(const Key('workforce-started-on'));
    expect(address, findsOneWidget);
    expect(startedOn, findsOneWidget);
    expect(
      tester.widget<TextField>(address).controller!.text,
      'Şantiye lojmanı',
    );
    await tester.enterText(address, '');
    final save = find.byKey(const Key('save-workforce-member'));
    final formScrollable = find
        .descendant(
          of: find.byKey(const Key('workforce-member-form')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      save,
      240,
      scrollable: formScrollable,
      maxScrolls: 8,
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(attendance.memberUpdate!.replaceAddress, isTrue);
    expect(attendance.memberUpdate!.address, isEmpty);
    expect(attendance.memberUpdate!.replaceStartedOn, isTrue);
    expect(attendance.memberUpdate!.startedOn, '2026-07-01');
  });

  testWidgets('subcontractor profile edit exposes values and clear flags', (
    tester,
  ) async {
    final attendance = _ProfileAttendance()
      ..subcontractors = [_firstSubcontractor]
      ..teams = [_firstTeam];
    await tester.pumpWidget(
      MaterialApp(
        home: WorkforceRegistryPage(
          attendance: attendance,
          project: _firstProject,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düzenle').last);
    await tester.pumpAndSettle();

    final address = _textFieldWithLabel('Adres');
    final specialty = _textFieldWithLabel('İş kalemi/uzmanlık');
    expect(address, findsOneWidget);
    expect(specialty, findsOneWidget);
    expect(tester.widget<TextField>(address).controller!.text, 'Merkez adresi');
    await tester.enterText(address, '');
    await tester.ensureVisible(find.text('Kaydet').last);
    await tester.tap(find.text('Kaydet').last);
    await tester.pumpAndSettle();

    expect(attendance.subcontractorUpdate!.replaceAddress, isTrue);
    expect(attendance.subcontractorUpdate!.address, isEmpty);
    expect(attendance.subcontractorUpdate!.replaceSpecialty, isTrue);
    expect(attendance.subcontractorUpdate!.specialty, 'Kalıp');
    expect(attendance.subcontractorUpdate!.replaceStartedOn, isTrue);
    expect(attendance.subcontractorUpdate!.replaceEndedOn, isTrue);
  });
}

class _TrackingAttendance extends FakeAttendanceApplication {
  _TrackingAttendance({required super.members, required this.summary});

  final WorkforceAttendanceSummary summary;
  String? openedMemberId;

  @override
  Future<WorkforcePersonDetail> getPersonDetail(String memberId) async {
    openedMemberId = memberId;
    final detail = await super.getPersonDetail(memberId);
    return WorkforcePersonDetail(
      member: detail.member,
      compliance: detail.compliance,
      ppeAssignments: detail.ppeAssignments,
      missingComplianceCount: detail.missingComplianceCount,
      validComplianceCount: detail.validComplianceCount,
      expiringComplianceCount: detail.expiringComplianceCount,
      expiredComplianceCount: detail.expiredComplianceCount,
      activePpeCount: detail.activePpeCount,
      attendanceSummary: summary,
    );
  }
}

class _ProfileAttendance extends FakeAttendanceApplication {
  _ProfileAttendance({super.members});

  UpdateWorkforceMemberCommand? memberUpdate;
  UpdateSubcontractorCommand? subcontractorUpdate;

  @override
  Future<List<Subcontractor>> listSubcontractors(
    String projectId, {
    bool includeArchived = false,
  }) async => subcontractors
      .where(
        (item) =>
            item.projectId == projectId && (includeArchived || item.isActive),
      )
      .toList(growable: false);

  @override
  Future<WorkforceMember> updateMember(UpdateWorkforceMemberCommand command) {
    memberUpdate = command;
    return super.updateMember(command);
  }

  @override
  Future<Subcontractor> updateSubcontractor(
    UpdateSubcontractorCommand command,
  ) {
    subcontractorUpdate = command;
    return super.updateSubcontractor(command);
  }
}

FakeAttendanceApplication _directoryAttendance() =>
    FakeAttendanceApplication(
        members: [_activeMember, _archivedMember, _secondProjectMember],
      )
      ..subcontractors = [_firstSubcontractor, _secondSubcontractor]
      ..teams = [_firstTeam, _secondTeam];

Finder _textFieldWithLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _setPhoneSize(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 900);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Future<void> _openDashboardTool(WidgetTester tester, Key key) async {
  final list = find.byKey(const Key('project-dashboard-list'));
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  final state = tester.state<ScrollableState>(scrollable.first);
  state.position.jumpTo(state.position.minScrollExtent);
  await tester.pump();
  final target = find.byKey(key);
  while (target.evaluate().isEmpty &&
      state.position.pixels < state.position.maxScrollExtent) {
    state.position.jumpTo(
      (state.position.pixels + 240)
          .clamp(state.position.minScrollExtent, state.position.maxScrollExtent)
          .toDouble(),
    );
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

const _firstProject = MobileProject(
  id: _project1,
  name: 'Proje Bir',
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  revision: 1,
);

const _secondProject = MobileProject(
  id: _project2,
  name: 'Proje İki',
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  revision: 1,
);

const _firstSubcontractor = Subcontractor(
  id: _subcontractor1,
  projectId: _project1,
  name: 'Beton AŞ',
  contactName: 'Veli Yetkili',
  phone: '555 00',
  address: 'Merkez adresi',
  specialty: 'Kalıp',
  startedOn: '2026-01-01',
  endedOn: '2026-12-31',
  note: null,
  status: WorkforceRecordStatus.active,
  activeTeamCount: 1,
  activePersonCount: 1,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);

const _secondSubcontractor = Subcontractor(
  id: _subcontractor2,
  projectId: _project2,
  name: 'Mimari Ltd',
  contactName: null,
  phone: null,
  note: null,
  status: WorkforceRecordStatus.active,
  activeTeamCount: 1,
  activePersonCount: 1,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);

const _firstTeam = WorkforceTeam(
  id: _team1,
  projectId: _project1,
  subcontractorId: _subcontractor1,
  subcontractorName: 'Beton AŞ',
  name: 'Gece Ekibi',
  leadName: null,
  note: null,
  status: WorkforceRecordStatus.active,
  activePersonCount: 1,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);

const _secondTeam = WorkforceTeam(
  id: _team2,
  projectId: _project2,
  subcontractorId: _subcontractor2,
  subcontractorName: 'Mimari Ltd',
  name: 'Gündüz Ekibi',
  leadName: null,
  note: null,
  status: WorkforceRecordStatus.active,
  activePersonCount: 1,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);

const _activeMember = WorkforceMember(
  id: _member1,
  projectId: _project1,
  fullName: 'Ayşe Usta',
  teamName: 'Gece Ekibi',
  roleName: 'Demirci',
  personnelCode: 'A-01',
  subcontractorId: _subcontractor1,
  subcontractorName: 'Beton AŞ',
  teamId: _team1,
  phone: '555 01',
  address: 'Şantiye lojmanı',
  startedOn: '2026-07-01',
  note: null,
  isActive: true,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);

const _archivedMember = WorkforceMember(
  id: _member2,
  projectId: _project1,
  fullName: 'Mehmet Arşiv',
  teamName: 'Gece Ekibi',
  roleName: 'Usta',
  personnelCode: null,
  subcontractorId: _subcontractor1,
  subcontractorName: 'Beton AŞ',
  teamId: _team1,
  phone: null,
  isActive: false,
  revision: 2,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T09:00:00Z',
  archivedAt: '2026-08-09T09:00:00Z',
);

const _secondProjectMember = WorkforceMember(
  id: _member3,
  projectId: _project2,
  fullName: 'Zeynep Mimar',
  teamName: 'Gündüz Ekibi',
  roleName: 'Mimar',
  personnelCode: null,
  subcontractorId: _subcontractor2,
  subcontractorName: 'Mimari Ltd',
  teamId: _team2,
  phone: '555 02',
  isActive: true,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);
