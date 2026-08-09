import 'dart:io';
import 'dart:typed_data';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/platform/attendance_export_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const project1 = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const project2 = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const member1 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const member2 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
const member3 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3';
const day1 = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const entry1 = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';
const entry2 = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd2';
const entry3 = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd3';
const event1 = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1';
const event2 = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee2';
const event3 = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee3';
const event4 = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee4';
const event5 = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee5';
const event6 = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee6';
const subcontractor1 = '11111111-1111-4111-8111-111111111111';
const subcontractor2 = '11111111-1111-4111-8111-111111111112';
const team1 = '22222222-2222-4222-8222-222222222221';

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;
  late SqliteAgendaApplication agenda;
  late SqliteAttendanceApplication attendance;
  late _FakeAttendanceExportGateway exports;
  var now = DateTime.utc(2026, 7, 19, 8);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_attendance_');
    directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    await directories.ensureCreated();
    final database = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => now,
    );
    await database.open();
    await database.close();
    agenda = SqliteAgendaApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
    );
    await agenda.createProject(
      const CreateProjectCommand(id: project1, name: 'Şantiye A'),
    );
    exports = _FakeAttendanceExportGateway();
    attendance = SqliteAttendanceApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
      agenda: agenda,
      exportGateway: exports,
    );
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('member create update archive and stale revision fail closed', () async {
    final created = await _createMember(
      attendance,
      id: member1,
      name: 'Ali Usta',
      team: 'Kalıp Ekibi',
      code: 'K-01',
    );
    final retried = await _createMember(
      attendance,
      id: member1,
      name: 'Ali Usta',
      team: 'Kalıp Ekibi',
      code: 'K-01',
    );
    expect(retried.revision, 1);

    final updated = await attendance.updateMember(
      UpdateWorkforceMemberCommand(
        id: member1,
        expectedRevision: created.revision,
        fullName: 'Ali Usta',
        teamName: 'Kalıp Ekibi',
        roleName: 'Kalıpçı başı',
        personnelCode: 'K-01',
      ),
    );
    expect(updated.revision, 2);
    await expectLater(
      attendance.updateMember(
        const UpdateWorkforceMemberCommand(
          id: member1,
          expectedRevision: 1,
          fullName: 'Stale',
          teamName: 'Kalıp Ekibi',
          roleName: 'Kalıpçı',
        ),
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      _createMember(
        attendance,
        id: member2,
        name: 'Başka Personel',
        team: 'Kalıp Ekibi',
        code: 'K-01',
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );

    final archived = await attendance.archiveMember(
      ArchiveWorkforceMemberCommand(
        id: member1,
        expectedRevision: updated.revision,
      ),
    );
    expect(archived.isActive, isFalse);
    expect(await attendance.listMembers(project1), isEmpty);
    expect(
      (await attendance.listMembers(project1, includeInactive: true)).single.id,
      member1,
    );
  });

  test(
    'person attendance summary follows canonical id and keeps archived history',
    () async {
      final member = await _createMember(
        attendance,
        id: member1,
        name: 'Ali Usta',
        team: 'Kalıp Ekibi',
      );
      final firstDay = await attendance.ensureDay(
        const EnsureAttendanceDayCommand(
          id: day1,
          eventId: event1,
          projectId: project1,
          localDate: '2026-07-18',
        ),
      );
      await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: firstDay.id,
          eventId: event2,
          expectedRevision: firstDay.revision,
          values: const [
            AttendanceRosterValue(
              entryId: entry1,
              memberId: member1,
              result: AttendanceResult.halfDay,
              overtimeMinutes: 0,
            ),
          ],
        ),
      );
      final secondDay = await attendance.ensureDay(
        const EnsureAttendanceDayCommand(
          id: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2',
          eventId: event3,
          projectId: project1,
          localDate: '2026-07-19',
        ),
      );
      await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: secondDay.id,
          eventId: event4,
          expectedRevision: secondDay.revision,
          values: const [
            AttendanceRosterValue(
              entryId: entry2,
              memberId: member1,
              result: AttendanceResult.fullDay,
              overtimeMinutes: 0,
            ),
          ],
        ),
      );
      await attendance.archiveMember(
        ArchiveWorkforceMemberCommand(
          id: member.id,
          expectedRevision: member.revision,
        ),
      );

      final detail = await attendance.getPersonDetail(member.id);

      expect(detail.member.isActive, isFalse);
      expect(detail.attendanceSummary.personDayEquivalentTotal, 1.5);
      expect(
        detail.attendanceSummary.recentDays.map((item) => item.localDate),
        ['2026-07-19', '2026-07-18'],
      );
      expect(
        detail.attendanceSummary.lastAttendance!.result,
        AttendanceResult.fullDay,
      );
      expect(
        detail.attendanceSummary.lastAttendance!.dayStatus,
        AttendanceDayStatus.draft,
      );
    },
  );

  test(
    'schema 12 registry profiles persist preserve and clear explicitly',
    () async {
      final subcontractor = await attendance.createSubcontractor(
        const CreateSubcontractorCommand(
          id: subcontractor1,
          eventId: '33333333-3333-4333-8333-333333333301',
          projectId: project1,
          name: 'Profil taşeronu',
          contactName: 'Yetkili',
          phone: '0555 000 00 00',
          address: '  Şantiye adresi  ',
          specialty: '  İnce işler  ',
          startedOn: '2026-07-01',
          endedOn: '2026-12-31',
          note: 'Korunan not',
        ),
      );
      expect(subcontractor.address, 'Şantiye adresi');
      expect(subcontractor.specialty, 'İnce işler');
      expect(subcontractor.startedOn, '2026-07-01');
      expect(subcontractor.endedOn, '2026-12-31');

      final noOp = await attendance.updateSubcontractor(
        UpdateSubcontractorCommand(
          id: subcontractor.id,
          eventId: '33333333-3333-4333-8333-333333333302',
          expectedRevision: subcontractor.revision,
          name: subcontractor.name,
          contactName: subcontractor.contactName,
          phone: subcontractor.phone,
          note: subcontractor.note,
        ),
      );
      expect(noOp.revision, subcontractor.revision);
      expect(noOp.address, subcontractor.address);
      expect(noOp.specialty, subcontractor.specialty);
      expect(noOp.startedOn, subcontractor.startedOn);
      expect(noOp.endedOn, subcontractor.endedOn);

      final updatedSubcontractor = await attendance.updateSubcontractor(
        UpdateSubcontractorCommand(
          id: subcontractor.id,
          eventId: '33333333-3333-4333-8333-333333333303',
          expectedRevision: noOp.revision,
          name: subcontractor.name,
          contactName: subcontractor.contactName,
          phone: subcontractor.phone,
          specialty: 'Cephe ve ince işler',
          endedOn: null,
          replaceSpecialty: true,
          replaceEndedOn: true,
          note: subcontractor.note,
        ),
      );
      expect(updatedSubcontractor.address, 'Şantiye adresi');
      expect(updatedSubcontractor.specialty, 'Cephe ve ince işler');
      expect(updatedSubcontractor.startedOn, '2026-07-01');
      expect(updatedSubcontractor.endedOn, isNull);

      await expectLater(
        attendance.updateSubcontractor(
          UpdateSubcontractorCommand(
            id: subcontractor.id,
            eventId: '33333333-3333-4333-8333-333333333304',
            expectedRevision: updatedSubcontractor.revision,
            name: subcontractor.name,
            contactName: subcontractor.contactName,
            phone: subcontractor.phone,
            startedOn: '2026-08-01',
            endedOn: '2026-07-31',
            replaceStartedOn: true,
            replaceEndedOn: true,
            note: subcontractor.note,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );

      final team = await attendance.createTeam(
        const CreateWorkforceTeamCommand(
          id: team1,
          eventId: '33333333-3333-4333-8333-333333333305',
          projectId: project1,
          subcontractorId: subcontractor1,
          name: 'Profil ekibi',
        ),
      );
      final member = await attendance.createMember(
        CreateWorkforceMemberCommand(
          id: member1,
          eventId: '33333333-3333-4333-8333-333333333306',
          projectId: project1,
          subcontractorId: subcontractor1,
          teamId: team.id,
          fullName: 'Profil Personeli',
          teamName: team.name,
          roleName: 'Usta',
          address: 'Personel adresi',
          startedOn: '2026-07-02',
        ),
      );
      expect(member.address, 'Personel adresi');
      expect(member.startedOn, '2026-07-02');

      final unrelated = await attendance.updateMember(
        UpdateWorkforceMemberCommand(
          id: member.id,
          eventId: '33333333-3333-4333-8333-333333333307',
          expectedRevision: member.revision,
          fullName: member.fullName,
          subcontractorId: member.subcontractorId,
          teamId: member.teamId,
          teamName: member.teamName,
          roleName: 'Usta başı',
        ),
      );
      expect(unrelated.address, member.address);
      expect(unrelated.startedOn, member.startedOn);

      final cleared = await attendance.updateMember(
        UpdateWorkforceMemberCommand(
          id: member.id,
          eventId: '33333333-3333-4333-8333-333333333308',
          expectedRevision: unrelated.revision,
          fullName: unrelated.fullName,
          subcontractorId: unrelated.subcontractorId,
          teamId: unrelated.teamId,
          teamName: unrelated.teamName,
          roleName: unrelated.roleName,
          replaceAddress: true,
          address: null,
        ),
      );
      expect(cleared.address, isNull);
      expect(cleared.startedOn, '2026-07-02');

      final restarted = SqliteAttendanceApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        agenda: agenda,
      );
      final persistedSubcontractor = (await restarted.listSubcontractors(
        project1,
      )).single;
      final persistedMember = (await restarted.listMembers(project1)).single;
      expect(persistedSubcontractor.address, 'Şantiye adresi');
      expect(persistedSubcontractor.specialty, 'Cephe ve ince işler');
      expect(persistedSubcontractor.startedOn, '2026-07-01');
      expect(persistedSubcontractor.endedOn, isNull);
      expect(persistedMember.address, isNull);
      expect(persistedMember.startedOn, '2026-07-02');
    },
  );

  test(
    'registry lifecycle is optimistic append-only and blocks active-person archive',
    () async {
      final subcontractor = await attendance.createSubcontractor(
        const CreateSubcontractorCommand(
          id: subcontractor1,
          eventId: '33333333-3333-4333-8333-333333333331',
          projectId: project1,
          name: '  Örnek   Taşeron  ',
          contactName: 'Yetkili',
        ),
      );
      expect(subcontractor.name, 'Örnek   Taşeron');
      final noOp = await attendance.updateSubcontractor(
        UpdateSubcontractorCommand(
          id: subcontractor.id,
          eventId: '33333333-3333-4333-8333-333333333332',
          expectedRevision: subcontractor.revision,
          name: subcontractor.name,
          contactName: subcontractor.contactName,
        ),
      );
      expect(noOp.revision, 1);
      await expectLater(
        attendance.createSubcontractor(
          const CreateSubcontractorCommand(
            id: subcontractor2,
            eventId: '33333333-3333-4333-8333-333333333333',
            projectId: project1,
            name: 'örnek taşeron',
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
      final team = await attendance.createTeam(
        const CreateWorkforceTeamCommand(
          id: team1,
          eventId: '33333333-3333-4333-8333-333333333334',
          projectId: project1,
          subcontractorId: subcontractor1,
          name: 'Çevre duvarcı',
        ),
      );
      final member = await attendance.createMember(
        const CreateWorkforceMemberCommand(
          id: member1,
          eventId: '33333333-3333-4333-8333-333333333335',
          projectId: project1,
          subcontractorId: subcontractor1,
          teamId: team1,
          fullName: 'Ayşe Usta',
          teamName: 'Çevre duvarcı',
          roleName: 'Duvarcı',
        ),
      );
      final registry = (await attendance.listSubcontractors(project1)).single;
      expect(registry.activeTeamCount, 1);
      expect(registry.activePersonCount, 1);
      expect(
        (await attendance.listActiveTeamCounts(project1)).single.teamName,
        contains('Çevre duvarcı'),
      );
      await expectLater(
        attendance.transitionTeam(
          TransitionWorkforceTeamCommand(
            id: team.id,
            eventId: '33333333-3333-4333-8333-333333333336',
            expectedRevision: team.revision,
            archive: true,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      await expectLater(
        attendance.transitionSubcontractor(
          TransitionSubcontractorCommand(
            id: subcontractor.id,
            eventId: '33333333-3333-4333-8333-333333333337',
            expectedRevision: subcontractor.revision,
            archive: true,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      final archivedMember = await attendance.archiveMember(
        ArchiveWorkforceMemberCommand(
          id: member.id,
          eventId: '33333333-3333-4333-8333-333333333338',
          expectedRevision: member.revision,
        ),
      );
      final archivedTeam = await attendance.transitionTeam(
        TransitionWorkforceTeamCommand(
          id: team.id,
          eventId: '33333333-3333-4333-8333-333333333339',
          expectedRevision: team.revision,
          archive: true,
        ),
      );
      final archivedSubcontractor = await attendance.transitionSubcontractor(
        TransitionSubcontractorCommand(
          id: subcontractor.id,
          eventId: '33333333-3333-4333-8333-333333333340',
          expectedRevision: subcontractor.revision,
          archive: true,
        ),
      );
      expect(archivedMember.isActive, isFalse);
      expect(archivedTeam.isActive, isFalse);
      expect(archivedSubcontractor.isActive, isFalse);
      await expectLater(
        attendance.transitionTeam(
          TransitionWorkforceTeamCommand(
            id: team.id,
            eventId: '33333333-3333-4333-8333-333333333342',
            expectedRevision: archivedTeam.revision,
            archive: false,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      final reopenedSubcontractor = await attendance.transitionSubcontractor(
        TransitionSubcontractorCommand(
          id: subcontractor.id,
          eventId: '33333333-3333-4333-8333-333333333343',
          expectedRevision: archivedSubcontractor.revision,
          archive: false,
        ),
      );
      final reopenedTeam = await attendance.transitionTeam(
        TransitionWorkforceTeamCommand(
          id: team.id,
          eventId: '33333333-3333-4333-8333-333333333344',
          expectedRevision: archivedTeam.revision,
          archive: false,
        ),
      );
      final reopenedMember = await attendance.archiveMember(
        ArchiveWorkforceMemberCommand(
          id: member.id,
          eventId: '33333333-3333-4333-8333-333333333345',
          expectedRevision: archivedMember.revision,
          archive: false,
        ),
      );
      expect(reopenedSubcontractor.isActive, isTrue);
      expect(reopenedTeam.isActive, isTrue);
      expect(reopenedMember.isActive, isTrue);
      await expectLater(
        attendance.updateTeam(
          const UpdateWorkforceTeamCommand(
            id: team1,
            eventId: '33333333-3333-4333-8333-333333333341',
            expectedRevision: 1,
            name: 'Stale ekip',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect(
        await _count(directories.databaseFile, 'workforce_events'),
        9,
        reason: 'no-op and rejected mutations must not append an event',
      );
    },
  );

  test(
    'compliance date read-model and PPE lifecycle stay person-linked',
    () async {
      await _createMember(attendance, id: member1, name: 'Ayşe', team: 'A');
      final records = <WorkforceComplianceRecord>[];
      for (final value in const [
        (
          '44444444-4444-4444-8444-444444444441',
          ComplianceDocumentType.employmentEntry,
          ComplianceSourceStatus.missing,
          null,
        ),
        (
          '44444444-4444-4444-8444-444444444442',
          ComplianceDocumentType.healthReport,
          ComplianceSourceStatus.valid,
          '2026-07-29',
        ),
        (
          '44444444-4444-4444-8444-444444444443',
          ComplianceDocumentType.basicSafetyTraining,
          ComplianceSourceStatus.valid,
          '2026-07-18',
        ),
        (
          '44444444-4444-4444-8444-444444444444',
          ComplianceDocumentType.vocationalCertificate,
          ComplianceSourceStatus.valid,
          null,
        ),
      ]) {
        records.add(
          await attendance.saveComplianceRecord(
            SaveComplianceRecordCommand(
              id: value.$1,
              eventId: value.$1.replaceFirst('44444444', '55555555'),
              memberId: member1,
              expectedRevision: 0,
              documentType: value.$2,
              sourceStatus: value.$3,
              expiryDate: value.$4,
            ),
          ),
        );
      }
      expect(records.map((item) => item.readStatus), [
        ComplianceReadStatus.missing,
        ComplianceReadStatus.expiring,
        ComplianceReadStatus.expired,
        ComplianceReadStatus.valid,
      ]);
      final ppe = await attendance.savePpeAssignment(
        const SavePpeAssignmentCommand(
          id: '66666666-6666-4666-8666-666666666661',
          eventId: '77777777-7777-4777-8777-777777777771',
          memberId: member1,
          expectedRevision: 0,
          ppeType: 'Baret',
          quantity: 1,
          assignedDate: '2026-07-19',
          status: PpeAssignmentStatus.assigned,
        ),
      );
      final detail = await attendance.getPersonDetail(member1);
      expect(detail.missingComplianceCount, 1);
      expect(detail.expiringComplianceCount, 1);
      expect(detail.expiredComplianceCount, 1);
      expect(detail.validComplianceCount, 1);
      expect(detail.activePpeCount, 1);
      final returned = await attendance.savePpeAssignment(
        SavePpeAssignmentCommand(
          id: ppe.id,
          eventId: '77777777-7777-4777-8777-777777777772',
          memberId: member1,
          expectedRevision: ppe.revision,
          ppeType: ppe.ppeType,
          quantity: ppe.quantity,
          assignedDate: ppe.assignedDate,
          status: PpeAssignmentStatus.returned,
          returnedDate: '2026-07-20',
        ),
      );
      expect(returned.status, PpeAssignmentStatus.returned);
      expect((await attendance.getPersonDetail(member1)).activePpeCount, 0);
      await expectLater(
        attendance.savePpeAssignment(
          SavePpeAssignmentCommand(
            id: ppe.id,
            eventId: '77777777-7777-4777-8777-777777777773',
            memberId: member1,
            expectedRevision: ppe.revision,
            ppeType: ppe.ppeType,
            quantity: 1,
            assignedDate: ppe.assignedDate,
            status: PpeAssignmentStatus.lost,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
    },
  );

  test(
    'registry move and archive keep canonical attendance compliance and PPE links',
    () async {
      await attendance.createSubcontractor(
        const CreateSubcontractorCommand(
          id: subcontractor1,
          eventId: '12121212-1212-4212-8212-121212121201',
          projectId: project1,
          name: 'Birinci taşeron',
        ),
      );
      final firstTeam = await attendance.createTeam(
        const CreateWorkforceTeamCommand(
          id: team1,
          eventId: '12121212-1212-4212-8212-121212121202',
          projectId: project1,
          subcontractorId: subcontractor1,
          name: 'Birinci ekip',
        ),
      );
      final member = await attendance.createMember(
        CreateWorkforceMemberCommand(
          id: member1,
          eventId: '12121212-1212-4212-8212-121212121203',
          projectId: project1,
          subcontractorId: subcontractor1,
          teamId: firstTeam.id,
          fullName: 'Stable Personel',
          teamName: firstTeam.name,
          roleName: 'Usta',
          address: 'Korunan adres',
          startedOn: '2026-07-01',
        ),
      );
      final oldDay = await _ensureDay(attendance);
      await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: oldDay.id,
          eventId: event2,
          expectedRevision: oldDay.revision,
          values: const [
            AttendanceRosterValue(
              entryId: entry1,
              memberId: member1,
              result: AttendanceResult.fullDay,
              overtimeMinutes: 0,
            ),
          ],
        ),
      );
      await attendance.saveComplianceRecord(
        const SaveComplianceRecordCommand(
          id: '13131313-1313-4313-8313-131313131301',
          eventId: '14141414-1414-4414-8414-141414141401',
          memberId: member1,
          expectedRevision: 0,
          documentType: ComplianceDocumentType.employmentEntry,
          sourceStatus: ComplianceSourceStatus.valid,
          issuedDate: '2026-07-01',
        ),
      );
      await attendance.savePpeAssignment(
        const SavePpeAssignmentCommand(
          id: '15151515-1515-4515-8515-151515151501',
          eventId: '16161616-1616-4616-8616-161616161601',
          memberId: member1,
          expectedRevision: 0,
          ppeType: 'Baret',
          quantity: 1,
          assignedDate: '2026-07-01',
          status: PpeAssignmentStatus.assigned,
        ),
      );
      await attendance.createSubcontractor(
        const CreateSubcontractorCommand(
          id: subcontractor2,
          eventId: '12121212-1212-4212-8212-121212121204',
          projectId: project1,
          name: 'İkinci taşeron',
        ),
      );
      final secondTeam = await attendance.createTeam(
        const CreateWorkforceTeamCommand(
          id: '22222222-2222-4222-8222-222222222222',
          eventId: '12121212-1212-4212-8212-121212121205',
          projectId: project1,
          subcontractorId: subcontractor2,
          name: 'İkinci ekip',
        ),
      );
      final moved = await attendance.updateMember(
        UpdateWorkforceMemberCommand(
          id: member.id,
          eventId: '12121212-1212-4212-8212-121212121206',
          expectedRevision: member.revision,
          fullName: member.fullName,
          subcontractorId: subcontractor2,
          teamId: secondTeam.id,
          teamName: secondTeam.name,
          roleName: member.roleName,
        ),
      );
      expect(moved.id, member.id);
      expect(moved.subcontractorId, subcontractor2);
      expect(moved.teamId, secondTeam.id);
      expect(moved.address, member.address);
      expect(moved.startedOn, member.startedOn);

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      for (final table in [
        'attendance_entries',
        'workforce_compliance_records',
        'workforce_ppe_assignments',
      ]) {
        expect(
          (await raw.query(table)).single['workforce_member_id'],
          member.id,
        );
      }
      expect(await raw.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await raw.close();

      final archived = await attendance.archiveMember(
        ArchiveWorkforceMemberCommand(
          id: moved.id,
          eventId: '12121212-1212-4212-8212-121212121207',
          expectedRevision: moved.revision,
        ),
      );
      final historical = await attendance.getDayDetail(oldDay.id);
      expect(historical.entries.single.memberId, member.id);
      expect(historical.entries.single.memberIsActive, isFalse);

      final newDay = await attendance.ensureDay(
        const EnsureAttendanceDayCommand(
          id: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2',
          eventId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee5',
          projectId: project1,
          localDate: '2026-07-20',
        ),
      );
      await expectLater(
        attendance.saveRoster(
          SaveAttendanceRosterCommand(
            dayId: newDay.id,
            eventId: event6,
            expectedRevision: newDay.revision,
            values: const [
              AttendanceRosterValue(
                entryId: 'dddddddd-dddd-4ddd-8ddd-ddddddddddd2',
                memberId: member1,
                result: AttendanceResult.fullDay,
                overtimeMinutes: 0,
              ),
            ],
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      final restored = await attendance.archiveMember(
        ArchiveWorkforceMemberCommand(
          id: archived.id,
          eventId: '12121212-1212-4212-8212-121212121208',
          expectedRevision: archived.revision,
          archive: false,
        ),
      );
      expect(restored.id, member.id);
      expect(restored.isActive, isTrue);
      expect(restored.subcontractorId, subcontractor2);
      expect(restored.teamId, secondTeam.id);
      await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: newDay.id,
          eventId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee6',
          expectedRevision: newDay.revision,
          values: const [
            AttendanceRosterValue(
              entryId: 'dddddddd-dddd-4ddd-8ddd-ddddddddddd2',
              memberId: member1,
              result: AttendanceResult.fullDay,
              overtimeMinutes: 0,
            ),
          ],
        ),
      );
    },
  );

  test(
    'roster results summary ordering no-op and stale revision are exact',
    () async {
      await _createMember(
        attendance,
        id: member1,
        name: 'Zeki',
        team: 'B Ekibi',
      );
      await _createMember(
        attendance,
        id: member2,
        name: 'Ayşe',
        team: 'A Ekibi',
      );
      await _createMember(
        attendance,
        id: member3,
        name: 'Mehmet',
        team: 'A Ekibi',
      );
      final day = await _ensureDay(attendance);
      final saved = await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: day.id,
          eventId: event2,
          expectedRevision: day.revision,
          replaceGeneralNote: true,
          generalNote: 'Günlük kısa not',
          values: const [
            AttendanceRosterValue(
              entryId: entry1,
              memberId: member1,
              result: AttendanceResult.fullDay,
              overtimeMinutes: 120,
            ),
            AttendanceRosterValue(
              entryId: entry2,
              memberId: member2,
              result: AttendanceResult.halfDay,
              overtimeMinutes: 30,
            ),
            AttendanceRosterValue(
              entryId: entry3,
              memberId: member3,
              result: AttendanceResult.absent,
              overtimeMinutes: 0,
            ),
          ],
        ),
      );

      expect(saved.day.revision, 2);
      expect(saved.entries.map((item) => item.memberName), [
        'Ayşe',
        'Mehmet',
        'Zeki',
      ]);
      expect(saved.totals.fullDayCount, 1);
      expect(saved.totals.halfDayCount, 1);
      expect(saved.totals.absentCount, 1);
      expect(saved.totals.presentCount, 2);
      expect(saved.totals.personDayEquivalent, 1.5);
      expect(saved.totals.overtimeMinutes, 150);
      expect(saved.teamSummaries.map((item) => item.teamName), [
        'A Ekibi',
        'B Ekibi',
      ]);
      expect(saved.teamSummaries.first.totals.personDayEquivalent, 0.5);

      final noOp = await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: day.id,
          eventId: event3,
          expectedRevision: saved.day.revision,
          replaceGeneralNote: true,
          generalNote: 'Günlük kısa not',
          values: const [
            AttendanceRosterValue(
              entryId: entry1,
              memberId: member1,
              result: AttendanceResult.fullDay,
              overtimeMinutes: 120,
            ),
          ],
        ),
      );
      expect(noOp.day.revision, 2);
      expect(noOp.events.where((item) => item.id == event3), isEmpty);
      await expectLater(
        attendance.saveRoster(
          const SaveAttendanceRosterCommand(
            dayId: day1,
            eventId: event4,
            expectedRevision: 1,
            values: [],
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
    },
  );

  test('overtime invariants fail before mutation', () async {
    await _createMember(attendance, id: member1, name: 'Ali', team: 'Ekip');
    final day = await _ensureDay(attendance);
    await expectLater(
      attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: day.id,
          eventId: event2,
          expectedRevision: day.revision,
          values: const [
            AttendanceRosterValue(
              entryId: entry1,
              memberId: member1,
              result: AttendanceResult.leave,
              overtimeMinutes: 1,
            ),
          ],
        ),
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );
    expect((await attendance.getDayDetail(day.id)).entries, isEmpty);
  });

  test(
    'all-full and team-full quick commands are one aggregate mutation',
    () async {
      await _createMember(attendance, id: member1, name: 'Ali', team: 'A');
      await _createMember(attendance, id: member2, name: 'Veli', team: 'A');
      await _createMember(attendance, id: member3, name: 'Can', team: 'B');
      final day = await _ensureDay(attendance);
      final team = await attendance.markFullDay(
        MarkAttendanceFullCommand(
          dayId: day.id,
          eventId: event2,
          expectedRevision: day.revision,
          entryIdsByMember: const {
            member1: entry1,
            member2: entry2,
            member3: entry3,
          },
          teamName: 'A',
        ),
      );
      expect(team.entries.length, 2);
      expect(team.day.revision, 2);
      final all = await attendance.markFullDay(
        MarkAttendanceFullCommand(
          dayId: day.id,
          eventId: event3,
          expectedRevision: team.day.revision,
          entryIdsByMember: const {
            member1: entry1,
            member2: entry2,
            member3: entry3,
          },
        ),
      );
      expect(all.entries.length, 3);
      expect(all.totals.fullDayCount, 3);
      expect(all.day.revision, 3);
    },
  );

  test(
    'complete historical correction and no-work lifecycle preserve events',
    () async {
      await _createMember(attendance, id: member1, name: 'Ali', team: 'A');
      final day = await _ensureDay(attendance, localDate: '2026-07-18');
      var detail = await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: day.id,
          eventId: event2,
          expectedRevision: day.revision,
          values: const [
            AttendanceRosterValue(
              entryId: entry1,
              memberId: member1,
              result: AttendanceResult.fullDay,
              overtimeMinutes: 0,
            ),
          ],
        ),
      );
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event3,
          reminderEventId: event4,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      expect(detail.day.status, AttendanceDayStatus.completed);
      await expectLater(
        attendance.saveRoster(
          SaveAttendanceRosterCommand(
            dayId: day.id,
            eventId: event5,
            expectedRevision: detail.day.revision,
            values: const [],
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event5,
          reminderEventId: event6,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.reopen,
        ),
      );
      expect(detail.day.status, AttendanceDayStatus.draft);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: 'ffffffff-ffff-4fff-8fff-fffffffffff1',
          reminderEventId: 'ffffffff-ffff-4fff-8fff-fffffffffff2',
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.noWork,
        ),
      );
      expect(detail.day.status, AttendanceDayStatus.noWork);
      expect(detail.entries, isEmpty);
      expect(
        detail.events.map((item) => item.eventType),
        containsAll([
          'attendance_day.completed',
          'attendance_day.reopened',
          'attendance_day.no_work',
        ]),
      );
    },
  );

  test(
    'rolling 14-day ensure links one reminder and restores it on reopen',
    () async {
      final setting = await attendance.saveReminderSetting(
        const SaveAttendanceReminderSettingCommand(
          projectId: project1,
          expectedRevision: 0,
          isEnabled: true,
          localTime: '17:00',
          selectedWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      );
      expect(setting.revision, 1);
      await attendance.ensureRollingOccurrences();
      await attendance.ensureRollingOccurrences();
      expect(await _count(directories.databaseFile, 'attendance_days'), 14);
      expect(
        await _count(directories.databaseFile, 'attendance_day_reminder_links'),
        14,
      );
      expect(await _count(directories.databaseFile, 'follow_up_items'), 14);
      final firstUpcoming = await agenda.listReminders(
        ReminderViewGroup.upcoming,
      );
      expect(firstUpcoming, hasLength(1));
      expect(firstUpcoming.single.projectId, project1);
      expect(firstUpcoming.single.attendanceDayId, isNotNull);

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final todayRows = await raw.rawQuery(
        '''
      SELECT d.id, l.reminder_id, l.due_at
      FROM attendance_days d
      JOIN attendance_day_reminder_links l ON l.attendance_day_id = d.id
      WHERE d.project_id = ? AND d.local_date = '2026-07-19'
      ''',
        [project1],
      );
      await raw.close();
      expect(todayRows.single['due_at'], '2026-07-19T14:00:00Z');
      var detail = await attendance.getDayDetail(
        todayRows.single['id']! as String,
      );
      expect(detail.linkedReminder!.attendanceDayId, detail.day.id);

      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: detail.day.id,
          dayEventId: event2,
          reminderEventId: event3,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      expect(detail.linkedReminder!.status, ReminderStatus.completed);
      expect(detail.linkedReminder!.nextAttentionAt, isNull);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: detail.day.id,
          dayEventId: event4,
          reminderEventId: event5,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.reopen,
        ),
      );
      expect(detail.linkedReminder!.status, ReminderStatus.active);
      expect(detail.linkedReminder!.nextAttentionAt, '2026-07-19T14:00:00Z');
      final reminderDetail = await agenda.getReminderDetail(
        detail.linkedReminder!.id,
      );
      expect(reminderDetail.attendanceDayId, detail.day.id);

      final firstFuture = firstUpcoming.single;
      var firstFutureDay = await attendance.getDayDetail(
        firstFuture.attendanceDayId!,
      );
      firstFutureDay = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: firstFutureDay.day.id,
          dayEventId: 'ffffffff-ffff-4fff-8fff-fffffffffff3',
          reminderEventId: 'ffffffff-ffff-4fff-8fff-fffffffffff4',
          expectedRevision: firstFutureDay.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      expect(firstFutureDay.linkedReminder!.status, ReminderStatus.completed);
      final nextUpcoming = await agenda.listReminders(
        ReminderViewGroup.upcoming,
      );
      expect(nextUpcoming, hasLength(1));
      expect(nextUpcoming.single.id, isNot(firstFuture.id));
      expect(
        CseTimeCodec.decodeCanonicalUtc(
          nextUpcoming.single.nextAttentionAt!,
        ).isAfter(
          CseTimeCodec.decodeCanonicalUtc(firstFuture.nextAttentionAt!),
        ),
        isTrue,
      );
    },
  );

  test(
    'upcoming keeps one attendance per project and all independent reminders',
    () async {
      await agenda.createProject(
        const CreateProjectCommand(id: project2, name: 'Şantiye B'),
      );
      await attendance.saveReminderSetting(
        const SaveAttendanceReminderSettingCommand(
          projectId: project1,
          expectedRevision: 0,
          isEnabled: true,
          localTime: '17:00',
          selectedWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      );
      await attendance.saveReminderSetting(
        const SaveAttendanceReminderSettingCommand(
          projectId: project2,
          expectedRevision: 0,
          isEnabled: true,
          localTime: '18:00',
          selectedWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      );
      final independent = await agenda.createReminder(
        const CreateReminderCommand(
          id: '99999999-9999-4999-8999-999999999999',
          eventId: '88888888-8888-4888-8888-888888888888',
          projectId: project1,
          title: 'Bağımsız yaklaşan kontrol',
          kind: ReminderKind.recheck,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-20T10:00:00Z',
        ),
      );

      final upcoming = await agenda.listReminders(ReminderViewGroup.upcoming);
      final attendanceItems = upcoming
          .where((item) => item.attendanceDayId != null)
          .toList(growable: false);
      expect(upcoming, hasLength(3));
      expect(attendanceItems, hasLength(2));
      expect(attendanceItems.map((item) => item.projectId).toSet(), {
        project1,
        project2,
      });
      expect(upcoming.map((item) => item.id), contains(independent.id));
      expect(await _count(directories.databaseFile, 'follow_up_items'), 29);
    },
  );

  test(
    'tomorrow keeps earliest attendance per project and independent reminders',
    () async {
      await agenda.createProject(
        const CreateProjectCommand(id: project2, name: 'Şantiye B'),
      );
      await attendance.saveReminderSetting(
        const SaveAttendanceReminderSettingCommand(
          projectId: project1,
          expectedRevision: 0,
          isEnabled: true,
          localTime: '17:00',
          selectedWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      );
      await attendance.saveReminderSetting(
        const SaveAttendanceReminderSettingCommand(
          projectId: project2,
          expectedRevision: 0,
          isEnabled: true,
          localTime: '18:00',
          selectedWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      );
      final independent = await agenda.createReminder(
        const CreateReminderCommand(
          id: '99999999-9999-4999-8999-999999999998',
          eventId: '88888888-8888-4888-8888-888888888887',
          projectId: project1,
          title: 'Bağımsız yarın kontrolü',
          kind: ReminderKind.recheck,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-20T10:00:00Z',
        ),
      );
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final extraProject1 = await raw.rawQuery(
        '''
        SELECT f.id, f.attendance_day_id
        FROM follow_up_items f
        WHERE f.project_id = ?
          AND f.attendance_day_id IS NOT NULL
          AND f.next_attention_at > '2026-07-20T14:00:00Z'
        ORDER BY f.next_attention_at ASC, f.id ASC
        LIMIT 1
        ''',
        [project1],
      );
      final extraReminderId = extraProject1.single['id']! as String;
      final extraDayId = extraProject1.single['attendance_day_id']! as String;
      await raw.update(
        'follow_up_items',
        {'next_attention_at': '2026-07-20T15:30:00Z'},
        where: 'id = ?',
        whereArgs: [extraReminderId],
      );
      await raw.update(
        'attendance_day_reminder_links',
        {'due_at': '2026-07-20T15:30:00Z'},
        where: 'attendance_day_id = ?',
        whereArgs: [extraDayId],
      );
      final physicalTomorrowAttendance = Sqflite.firstIntValue(
        await raw.rawQuery('''
          SELECT COUNT(*)
          FROM follow_up_items
          WHERE attendance_day_id IS NOT NULL
            AND next_attention_at >= '2026-07-19T21:00:00Z'
            AND next_attention_at < '2026-07-20T21:00:00Z'
          '''),
      );
      await raw.close();

      final tomorrow = await agenda.listReminders(ReminderViewGroup.tomorrow);
      final attendanceItems = tomorrow
          .where((item) => item.attendanceDayId != null)
          .toList(growable: false);

      expect(physicalTomorrowAttendance, 3);
      expect(tomorrow, hasLength(3));
      expect(attendanceItems, hasLength(2));
      expect(attendanceItems.map((item) => item.projectId).toSet(), {
        project1,
        project2,
      });
      expect(
        attendanceItems
            .singleWhere((item) => item.projectId == project1)
            .nextAttentionAt,
        '2026-07-20T14:00:00Z',
      );
      expect(tomorrow.map((item) => item.id), contains(independent.id));
      expect(await _count(directories.databaseFile, 'follow_up_items'), 29);
    },
  );

  test('transaction hook failure leaves no partial day or event', () async {
    final failing = SqliteAttendanceApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
      agenda: agenda,
      beforeAttendanceEventInsert: (_) async {
        throw StateError('intentional transaction failure');
      },
    );
    await expectLater(
      failing.ensureDay(
        const EnsureAttendanceDayCommand(
          id: day1,
          eventId: event1,
          projectId: project1,
          localDate: '2026-07-19',
        ),
      ),
      throwsStateError,
    );
    expect(await _count(directories.databaseFile, 'attendance_days'), 0);
    expect(await _count(directories.databaseFile, 'attendance_events'), 0);
  });

  test('append-only events and physical delete guards are enforced', () async {
    await _createMember(attendance, id: member1, name: 'Ali', team: 'A');
    final day = await _ensureDay(attendance);
    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await raw.execute('PRAGMA foreign_keys = ON');
    await expectLater(
      raw.update(
        'attendance_events',
        {'payload_json': '{"changed":true}'},
        where: 'attendance_day_id = ?',
        whereArgs: [day.id],
      ),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      raw.delete('attendance_days', where: 'id = ?', whereArgs: [day.id]),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      raw.delete('workforce_members', where: 'id = ?', whereArgs: [member1]),
      throwsA(isA<DatabaseException>()),
    );
    await raw.close();
  });

  test(
    'CSV is deterministic UTF-8 safe and records event only after success',
    () async {
      await _createMember(
        attendance,
        id: member1,
        name: '=Ali, "Usta"',
        team: '+Ekip',
        code: '@KOD',
      );
      final day = await _ensureDay(attendance);
      final detail = await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: day.id,
          eventId: event2,
          expectedRevision: day.revision,
          values: const [
            AttendanceRosterValue(
              entryId: entry1,
              memberId: member1,
              result: AttendanceResult.fullDay,
              overtimeMinutes: 90,
              shortNote: '-risk',
            ),
          ],
        ),
      );
      final result = await attendance.exportDay(
        ExportAttendanceDayCommand(
          dayId: day.id,
          eventId: event3,
          expectedRevision: detail.day.revision,
        ),
      );
      expect(result.fileName, startsWith('puantaj_2026-07-19_'));
      expect(exports.bytes!.take(3), [0xef, 0xbb, 0xbf]);
      final csv = String.fromCharCodes(exports.bytes!.skip(3));
      expect(csv, contains("'=Ali"));
      expect(csv, contains("'+Ekip"));
      expect(csv, contains("'@KOD"));
      expect(csv, contains("'-risk"));
      expect(
        (await attendance.getDayDetail(day.id)).events.last.eventType,
        'attendance_day.csv_exported',
      );

      exports.failStage = true;
      await expectLater(
        attendance.exportDay(
          ExportAttendanceDayCommand(
            dayId: day.id,
            eventId: event4,
            expectedRevision: detail.day.revision,
          ),
        ),
        throwsStateError,
      );
      expect(
        (await attendance.getDayDetail(
          day.id,
        )).events.where((item) => item.id == event4),
        isEmpty,
      );
    },
  );

  test(
    'attendance and exact reminder links survive application restart',
    () async {
      await _createMember(attendance, id: member1, name: 'Ali', team: 'A');
      await attendance.saveReminderSetting(
        const SaveAttendanceReminderSettingCommand(
          projectId: project1,
          expectedRevision: 0,
          isEnabled: true,
          localTime: '17:00',
          selectedWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      );
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final dayId =
          (await raw.query(
                'attendance_days',
                columns: ['id'],
                where: "local_date = '2026-07-19'",
                limit: 1,
              )).single['id']!
              as String;
      await raw.close();
      now = DateTime.utc(2026, 7, 19, 9);
      final restarted = SqliteAttendanceApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        agenda: agenda,
      );
      final persisted = await restarted.getDayDetail(dayId);
      expect(persisted.day.localDate, '2026-07-19');
      expect(persisted.linkedReminder!.attendanceDayId, dayId);
      expect((await restarted.listMembers(project1)).single.fullName, 'Ali');
    },
  );
}

Future<WorkforceMember> _createMember(
  AttendanceApplication attendance, {
  required String id,
  required String name,
  required String team,
  String? code,
}) {
  return attendance.createMember(
    CreateWorkforceMemberCommand(
      id: id,
      projectId: project1,
      fullName: name,
      teamName: team,
      roleName: 'Usta',
      personnelCode: code,
    ),
  );
}

Future<AttendanceDay> _ensureDay(
  AttendanceApplication attendance, {
  String localDate = '2026-07-19',
}) {
  return attendance.ensureDay(
    EnsureAttendanceDayCommand(
      id: day1,
      eventId: event1,
      projectId: project1,
      localDate: localDate,
    ),
  );
}

Future<int> _count(String path, String table) async {
  final raw = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  final value = Sqflite.firstIntValue(
    await raw.rawQuery('SELECT COUNT(*) FROM $table'),
  )!;
  await raw.close();
  return value;
}

class _FakeAttendanceExportGateway implements AttendanceExportGateway {
  Uint8List? bytes;
  bool failStage = false;
  bool shared = false;
  bool cleaned = false;

  @override
  Future<void> cleanup(String absolutePath) async {
    cleaned = true;
  }

  @override
  Future<void> share(String absolutePath, String humanSummary) async {
    shared = true;
  }

  @override
  Future<String> stage(String fileName, Uint8List bytes) async {
    if (failStage) throw StateError('intentional export failure');
    this.bytes = bytes;
    return 'V:/safe/$fileName';
  }
}
