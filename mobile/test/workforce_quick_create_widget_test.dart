import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_directory_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_registry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const _projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';

void main() {
  testWidgets(
    'first use creates a company then repeated people in the same registry context',
    (tester) async {
      await _setViewport(tester, const Size(390, 844));
      final attendance = FakeAttendanceApplication();
      await tester.pumpWidget(
        _scaledApp(
          scale: 2,
          child: WorkforceDirectoryPage(
            attendance: attendance,
            agenda: FakeAgendaApplication(projects: const [_project]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('workforce-directory-first-use')),
        findsOneWidget,
      );
      expect(find.text('Taşeron / İşveren ekle'), findsOneWidget);
      expect(find.byKey(const Key('workforce-directory-empty')), findsNothing);

      final firstCompany = find.byKey(const Key('add-first-workforce-company'));
      await tester.ensureVisible(firstCompany);
      await tester.pumpAndSettle();
      await tester.tap(firstCompany);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Firma ekle'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('subcontractor-name')), findsOneWidget);
      expect(find.byKey(const Key('subcontractor-contact')), findsOneWidget);
      expect(find.byKey(const Key('subcontractor-phone')), findsOneWidget);
      expect(find.byKey(const Key('subcontractor-address')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('subcontractor-name')),
        'Örnek Yapı',
      );
      await tester.enterText(
        find.byKey(const Key('subcontractor-contact')),
        'Veli Yetkili',
      );
      await tester.enterText(
        find.byKey(const Key('subcontractor-phone')),
        '555 00 00',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workforce-member-form')), findsOneWidget);
      expect(find.text('Örnek Yapı'), findsOneWidget);
      expect(
        find.byKey(const Key('workforce-subcontractor-context')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('workforce-team')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('workforce-name')),
        'Ayşe Usta',
      );
      await tester.enterText(
        find.byKey(const Key('workforce-role')),
        'Demirci',
      );
      await tester.tap(find.byKey(const Key('workforce-other-information')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workforce-team')), findsOneWidget);
      await _tapSaveMember(tester);

      expect(find.text('Personel kaydedildi'), findsOneWidget);
      expect(attendance.createMemberCalls, 1);
      final companyId = attendance.subcontractors.single.id;
      final firstMemberId = attendance.lastCreateMemberCommand!.id;
      expect(attendance.lastCreateMemberCommand!.subcontractorId, companyId);
      expect(attendance.lastCreateMemberCommand!.teamId, isNull);

      await tester.tap(
        find.byKey(const Key('workforce-quick-flow-add-another')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Örnek Yapı'), findsOneWidget);
      expect(find.byKey(const Key('workforce-team')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('workforce-name')),
        'Mehmet Kalfa',
      );
      await tester.enterText(
        find.byKey(const Key('workforce-role')),
        'Kalıpçı',
      );
      await _tapSaveMember(tester);

      expect(find.text('Personel kaydedildi'), findsOneWidget);
      expect(attendance.createMemberCalls, 2);
      expect(attendance.lastCreateMemberCommand!.id, isNot(firstMemberId));
      expect(attendance.lastCreateMemberCommand!.subcontractorId, companyId);
      expect(attendance.lastCreateMemberCommand!.teamId, isNull);
      await tester.tap(find.byKey(const Key('workforce-quick-flow-done')));
      await tester.pumpAndSettle();

      expect(find.text('Ayşe Usta'), findsOneWidget);
      expect(find.text('Mehmet Kalfa'), findsOneWidget);
      expect(
        find.textContaining(workforceTechnicalTeamStorageName),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('manage-workforce-directory')));
      await tester.pumpAndSettle();
      expect(find.byType(WorkforcePage), findsOneWidget);
      expect(
        find.byKey(const Key('manage-workforce-registry')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('manage-workforce-registry')));
      await tester.pumpAndSettle();
      expect(find.byType(WorkforceRegistryPage), findsOneWidget);
      expect(find.text('Firmalar ve ekipler'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact forms do not overflow at 320 px and high text scale', (
    tester,
  ) async {
    await _setViewport(tester, const Size(320, 800));
    final attendance = FakeAttendanceApplication()
      ..subcontractors = const [_longCompany]
      ..teams = const [_longTeam];

    await tester.pumpWidget(
      _scaledApp(
        scale: 2,
        child: WorkforceMemberFormPage(
          attendance: attendance,
          project: _project,
          initialSubcontractorId: _longCompany.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('workforce-subcontractor-context')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('workforce-team')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('workforce-other-information')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workforce-team')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_longTeamName).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _scaledApp(
        scale: 2,
        child: WorkforceRegistryPage(
          attendance: FakeAttendanceApplication(),
          project: _project,
          startWithCompanyForm: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Firma ekle'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('subcontractor-address')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-use CTA requires a valid project and current directory', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkforceDirectoryPage(
            attendance: FakeAttendanceApplication(),
            agenda: FakeAgendaApplication(projects: const [_project]),
            activeProjectId: 'missing-project',
            usesSharedProjectContext: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('workforce-directory-project-context-unavailable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('workforce-directory-first-use')),
      findsNothing,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkforceDirectoryPage(
            key: const ValueKey('failing-directory'),
            attendance: _FailingDirectoryAttendance(),
            agenda: FakeAgendaApplication(projects: const [_project]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workforce-directory-error')), findsOneWidget);
    expect(
      find.byKey(const Key('workforce-directory-first-use')),
      findsNothing,
    );
  });
}

class _FailingDirectoryAttendance extends FakeAttendanceApplication {
  @override
  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  }) async => throw StateError('synthetic directory failure');
}

Widget _scaledApp({required double scale, required Widget child}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: child),
      ),
    );

Future<void> _tapSaveMember(WidgetTester tester) async {
  final save = find.byKey(const Key('save-workforce-member'));
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

const _project = MobileProject(
  id: _projectId,
  name: 'Proje Bir',
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  revision: 1,
);

const _longCompany = Subcontractor(
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
  projectId: _projectId,
  name: 'Çok Uzun Firma Adıyla Dar Ekran Taşma Kontrolü Limited Şirketi',
  contactName: null,
  phone: null,
  note: null,
  status: WorkforceRecordStatus.active,
  activeTeamCount: 1,
  activePersonCount: 0,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);

const _longTeamName = 'Çok Uzun Cephe Uygulamaları ve İnce İşler Saha Ekibi';

const _longTeam = WorkforceTeam(
  id: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
  projectId: _projectId,
  subcontractorId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
  subcontractorName:
      'Çok Uzun Firma Adıyla Dar Ekran Taşma Kontrolü Limited Şirketi',
  name: _longTeamName,
  leadName: null,
  note: null,
  status: WorkforceRecordStatus.active,
  activePersonCount: 0,
  revision: 1,
  createdAt: '2026-08-09T08:00:00Z',
  updatedAt: '2026-08-09T08:00:00Z',
  archivedAt: null,
);
