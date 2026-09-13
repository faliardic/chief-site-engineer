import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
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

  test(
    '20B history preserves exact records and per-record sequence without writes',
    () async {
      final originalClock = now;
      addTearDown(() => now = originalClock);
      await _createMember(attendance, id: member1, name: 'Ayşe', team: 'A');
      await _createMember(
        attendance,
        id: member2,
        name: 'Başka kişi',
        team: 'A',
      );
      await agenda.createProject(
        const CreateProjectCommand(id: project2, name: 'B'),
      );
      await attendance.createMember(
        const CreateWorkforceMemberCommand(
          id: member3,
          projectId: project2,
          fullName: 'Başka proje',
          teamName: 'B',
          roleName: 'Usta',
        ),
      );
      String uuid(int n) =>
          '44444444-4444-4444-8444-${n.toString().padLeft(12, '0')}';
      for (var i = 1; i <= 6; i++) {
        await attendance.saveComplianceRecord(
          SaveComplianceRecordCommand(
            id: uuid(i),
            eventId: uuid(100 + i),
            memberId: i == 5
                ? member2
                : i == 6
                ? member3
                : member1,
            expectedRevision: 0,
            documentType: ComplianceDocumentType.healthReport,
            sourceStatus: i <= 2
                ? ComplianceSourceStatus.valid
                : ComplianceSourceStatus.exception,
            documentNumber: 'Belge $i',
            issuedDate: '2026-07-01',
            expiryDate: i <= 2 ? null : '2026-07-18',
            note: 'Not $i',
            reason: 'Gerekçe $i',
          ),
        );
      }
      now = originalClock.subtract(const Duration(days: 1));
      await attendance.saveComplianceRecord(
        SaveComplianceRecordCommand(
          id: uuid(3),
          eventId: uuid(203),
          memberId: member1,
          expectedRevision: 1,
          documentType: ComplianceDocumentType.healthReport,
          sourceStatus: ComplianceSourceStatus.notApplicable,
          documentNumber: 'Düzeltilmiş 3',
          issuedDate: '2026-07-01',
          expiryDate: '2026-07-18',
          note: 'Korunan not',
          reason: 'Korunan gerekçe',
        ),
      );
      now = originalClock.subtract(const Duration(days: 2));
      for (final i in [3, 4, 5, 6]) {
        await attendance.archiveComplianceRecord(
          ArchiveComplianceRecordCommand(
            id: uuid(i),
            eventId: uuid(300 + i),
            expectedRevision: i == 3 ? 2 : 1,
          ),
        );
      }
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        // Synthetic ownership mismatches must never become another person's history.
        for (var i = 1; i <= 3; i++) {
          await raw.insert('workforce_events', {
            'id': uuid(400 + i),
            'aggregate_type': i == 3 ? 'person' : 'compliance',
            'aggregate_id': uuid(3),
            'project_id': i == 1 ? project2 : project1,
            'sequence': 10 + i,
            'event_type': 'compliance.updated',
            'occurred_at': '2026-07-19T08:00:00Z',
            'payload_json': '{"member_id":"${i == 2 ? member2 : member1}"}',
          });
        }
        Future<List<List<Map<String, Object?>>>> snapshot() async => [
          for (final table in [
            'workforce_members',
            'workforce_compliance_records',
            'workforce_events',
          ])
            await raw.query(table, orderBy: 'id'),
        ];
        final before = await snapshot();
        for (var read = 0; read < 2; read++) {
          final detail = await attendance.getPersonDetail(member1);
          expect(detail.compliance.map((r) => r.id), [uuid(1), uuid(2)]);
          expect(detail.validComplianceCount, 2);
          expect(
            detail.missingComplianceCount +
                detail.expiredComplianceCount +
                detail.expiringComplianceCount,
            0,
          );
          expect(detail.archivedCompliance.map((r) => r.id), [
            uuid(3),
            uuid(4),
          ]);
          final archived = detail.archivedCompliance.first;
          expect(archived.sourceStatus, ComplianceSourceStatus.notApplicable);
          expect(archived.revision, 3);
          expect(archived.documentNumber, 'Düzeltilmiş 3');
          expect(archived.note, 'Korunan not');
          expect(archived.reason, 'Korunan gerekçe');
          expect(archived.issuedDate, '2026-07-01');
          expect(archived.expiryDate, '2026-07-18');
          expect(archived.archivedAt, isNotNull);
          final events = detail.complianceEvents
              .where((e) => e.recordId == uuid(3))
              .toList();
          expect(events.map((e) => e.sequence), [1, 2, 3]);
          expect(events.map((e) => e.eventType), [
            'compliance.created',
            'compliance.updated',
            'compliance.archived',
          ]);
          expect(
            events.first.occurredAt.compareTo(events.last.occurredAt),
            greaterThan(0),
          );
          expect(detail.complianceEvents, hasLength(7));
          expect(
            detail.complianceEvents.every(
              (e) => e.memberId == member1 && e.projectId == project1,
            ),
            isTrue,
          );
        }
        expect(await snapshot(), before);
        final allArchived = await attendance.getPersonDetail(member2);
        expect(allArchived.compliance, isEmpty);
        expect(allArchived.archivedCompliance.single.id, uuid(5));
        expect(allArchived.complianceEvents.map((e) => e.sequence), [1, 2]);
        expect(
          allArchived.validComplianceCount +
              allArchived.missingComplianceCount +
              allArchived.expiringComplianceCount +
              allArchived.expiredComplianceCount,
          0,
        );
        final otherProject = await attendance.getPersonDetail(member3);
        expect(otherProject.archivedCompliance.single.id, uuid(6));
        expect(
          otherProject.complianceEvents.every((e) => e.projectId == project2),
          isTrue,
        );
        expect(await snapshot(), before);
      } finally {
        await raw.close();
      }
    },
  );

  test(
    'compliance restore is same-record atomic isolated and fail-closed',
    () async {
      await _createMember(attendance, id: member1, name: 'Ayşe', team: 'A');
      await _createMember(attendance, id: member2, name: 'Ali', team: 'A');
      await agenda.createProject(
        const CreateProjectCommand(id: project2, name: 'Şantiye B'),
      );
      final created = await attendance.saveComplianceRecord(
        const SaveComplianceRecordCommand(
          id: '44444444-4444-4444-8444-444444444451',
          eventId: '55555555-5555-4555-8555-555555555551',
          memberId: member1,
          expectedRevision: 0,
          documentType: ComplianceDocumentType.healthReport,
          sourceStatus: ComplianceSourceStatus.valid,
          documentNumber: 'R-51',
        ),
      );
      final sibling = await attendance.saveComplianceRecord(
        const SaveComplianceRecordCommand(
          id: '44444444-4444-4444-8444-444444444452',
          eventId: '55555555-5555-4555-8555-555555555552',
          memberId: member1,
          expectedRevision: 0,
          documentType: ComplianceDocumentType.healthReport,
          sourceStatus: ComplianceSourceStatus.valid,
        ),
      );
      final archived = await attendance.archiveComplianceRecord(
        ArchiveComplianceRecordCommand(
          id: created.id,
          eventId: '55555555-5555-4555-8555-555555555553',
          expectedRevision: created.revision,
        ),
      );

      Future<int> eventCount() async {
        final raw = await databaseFactoryFfi.openDatabase(
          directories.databaseFile,
          options: OpenDatabaseOptions(singleInstance: false),
        );
        try {
          return Sqflite.firstIntValue(
            await raw.rawQuery(
              'SELECT count(*) FROM workforce_events WHERE aggregate_id = ?',
              [created.id],
            ),
          )!;
        } finally {
          await raw.close();
        }
      }

      final beforeRejected = await eventCount();
      for (final command in [
        RestoreComplianceRecordCommand(
          id: archived.id,
          eventId: '55555555-5555-4555-8555-555555555554',
          memberId: member2,
          projectId: project1,
          expectedRevision: archived.revision,
        ),
        RestoreComplianceRecordCommand(
          id: archived.id,
          eventId: '55555555-5555-4555-8555-555555555555',
          memberId: member1,
          projectId: project2,
          expectedRevision: archived.revision,
        ),
        RestoreComplianceRecordCommand(
          id: archived.id,
          eventId: '55555555-5555-4555-8555-555555555551',
          memberId: member1,
          projectId: project1,
          expectedRevision: archived.revision,
        ),
      ]) {
        await expectLater(
          attendance.restoreComplianceRecord(command),
          throwsA(anything),
        );
        final unchanged = (await attendance.getPersonDetail(
          member1,
        )).archivedCompliance.singleWhere((record) => record.id == archived.id);
        expect(unchanged.revision, archived.revision);
        expect(unchanged.archivedAt, archived.archivedAt);
        expect(await eventCount(), beforeRejected);
      }

      now = now.add(const Duration(minutes: 1));
      final restored = await attendance.restoreComplianceRecord(
        RestoreComplianceRecordCommand(
          id: archived.id,
          eventId: '55555555-5555-4555-8555-555555555556',
          memberId: member1,
          projectId: project1,
          expectedRevision: archived.revision,
        ),
      );
      expect(restored.id, created.id);
      expect(restored.revision, archived.revision + 1);
      expect(restored.archivedAt, isNull);
      expect(restored.updatedAt, CseTimeCodec.encodeUtc(now));
      final detail = await attendance.getPersonDetail(member1);
      expect(detail.archivedCompliance, isEmpty);
      expect(detail.compliance.map((record) => record.id), [
        created.id,
        sibling.id,
      ]);
      final lifecycle = detail.complianceEvents
          .where((event) => event.recordId == created.id)
          .toList(growable: false);
      expect(lifecycle.map((event) => event.sequence), [1, 2, 3]);
      expect(lifecycle.map((event) => event.eventType), [
        'compliance.created',
        'compliance.archived',
        'compliance.reopened',
      ]);

      for (final command in [
        RestoreComplianceRecordCommand(
          id: restored.id,
          eventId: '55555555-5555-4555-8555-555555555557',
          memberId: member1,
          projectId: project1,
          expectedRevision: archived.revision,
        ),
        RestoreComplianceRecordCommand(
          id: restored.id,
          eventId: '55555555-5555-4555-8555-555555555558',
          memberId: member1,
          projectId: project1,
          expectedRevision: restored.revision,
        ),
      ]) {
        await expectLater(
          attendance.restoreComplianceRecord(command),
          throwsA(isA<AgendaValidationFailure>()),
        );
      }
      expect(await eventCount(), 3);
    },
  );

  test(
    'quick compliance create retry is idempotent with stable identities',
    () async {
      await _createMember(attendance, id: member1, name: 'Ayşe', team: 'A');
      const command = SaveComplianceRecordCommand(
        id: '44444444-4444-4444-8444-444444444461',
        eventId: '55555555-5555-4555-8555-555555555561',
        memberId: member1,
        expectedRevision: 0,
        documentType: ComplianceDocumentType.basicSafetyTraining,
        sourceStatus: ComplianceSourceStatus.valid,
      );
      final created = await attendance.saveComplianceRecord(command);
      final retried = await attendance.saveComplianceRecord(command);
      expect(retried.id, created.id);
      expect(retried.revision, 1);
      final detail = await attendance.getPersonDetail(member1);
      expect(
        detail.compliance.where((record) => record.id == created.id),
        hasLength(1),
      );
      expect(
        detail.complianceEvents.where((event) => event.recordId == created.id),
        hasLength(1),
      );
      await expectLater(
        attendance.saveComplianceRecord(
          const SaveComplianceRecordCommand(
            id: '44444444-4444-4444-8444-444444444461',
            eventId: '55555555-5555-4555-8555-555555555562',
            memberId: member1,
            expectedRevision: 0,
            documentType: ComplianceDocumentType.basicSafetyTraining,
            sourceStatus: ComplianceSourceStatus.valid,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
    },
  );

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
    'Q04-A2 technical team is deterministic idempotent masked and explicit teams stay stable',
    () async {
      final subcontractor = await attendance.createSubcontractor(
        const CreateSubcontractorCommand(
          id: subcontractor1,
          eventId: '33333333-3333-4333-8333-333333333311',
          projectId: project1,
          name: 'Atlas Yapı',
        ),
      );
      final explicitTeam = await attendance.createTeam(
        const CreateWorkforceTeamCommand(
          id: team1,
          eventId: '33333333-3333-4333-8333-333333333312',
          projectId: project1,
          subcontractorId: subcontractor1,
          name: 'Kalıp Ekibi',
        ),
      );
      final technical = await attendance.createMember(
        const CreateWorkforceMemberCommand(
          id: member1,
          projectId: project1,
          subcontractorId: subcontractor1,
          fullName: 'Ekipsiz Ali',
          roleName: 'Usta',
        ),
      );
      final retry = await attendance.createMember(
        const CreateWorkforceMemberCommand(
          id: member1,
          projectId: project1,
          subcontractorId: subcontractor1,
          fullName: 'Ekipsiz Ali',
          roleName: 'Usta',
        ),
      );
      final secondTechnical = await attendance.createMember(
        const CreateWorkforceMemberCommand(
          id: member2,
          projectId: project1,
          subcontractorId: subcontractor1,
          fullName: 'Ekipsiz Ayşe',
          roleName: 'Usta',
        ),
      );
      final explicit = await attendance.createMember(
        const CreateWorkforceMemberCommand(
          id: member3,
          projectId: project1,
          subcontractorId: subcontractor1,
          teamId: team1,
          teamName: 'Kalıp Ekibi',
          fullName: 'Ekipli Can',
          roleName: 'Usta',
        ),
      );

      final technicalId = workforceTechnicalTeamId(project1, subcontractor1);
      expect(technical.teamId, technicalId);
      expect(retry.teamId, technicalId);
      expect(secondTechnical.teamId, technicalId);
      expect(explicit.teamId, explicitTeam.id);
      expect((await attendance.listTeams(project1)).map((team) => team.id), [
        team1,
      ]);
      final firm = (await attendance.listSubcontractors(project1)).single;
      expect(firm.activeTeamCount, 1);
      expect(firm.activePersonCount, 3);

      final preserved = await attendance.updateMember(
        UpdateWorkforceMemberCommand(
          id: explicit.id,
          expectedRevision: explicit.revision,
          fullName: 'Ekipli Can Güncel',
          roleName: explicit.roleName,
        ),
      );
      expect(preserved.teamId, team1);
      expect(preserved.subcontractorId, subcontractor1);
      final moved = await attendance.updateMember(
        UpdateWorkforceMemberCommand(
          id: preserved.id,
          expectedRevision: preserved.revision,
          fullName: preserved.fullName,
          roleName: preserved.roleName,
          subcontractorId: subcontractor1,
          useTechnicalTeam: true,
        ),
      );
      expect(moved.teamId, technicalId);
      expect(
        (await attendance.listMembers(
          project1,
        )).firstWhere((member) => member.id == member1).teamId,
        technicalId,
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
              overtimeMinutes: 0,
            ),
            AttendanceRosterValue(
              entryId: entry2,
              memberId: member2,
              result: AttendanceResult.halfDay,
              overtimeMinutes: 0,
            ),
          ],
        ),
      );
      expect(detail.entries.map((entry) => entry.teamName).toSet(), {
        subcontractor.name,
      });
      expect(detail.teamSummaries.map((summary) => summary.teamName).toSet(), {
        subcontractor.name,
      });
      final exported = await attendance.exportDay(
        ExportAttendanceDayCommand(
          dayId: day.id,
          eventId: event3,
          expectedRevision: detail.day.revision,
        ),
        share: true,
      );
      final csv = utf8.decode(exports.bytes!.skip(3).toList());
      expect(csv, contains(subcontractor.name));
      expect(csv, isNot(contains(workforceTechnicalTeamStorageName)));
      expect(exported.humanSummary, contains(subcontractor.name));
      expect(
        exported.humanSummary,
        isNot(contains(workforceTechnicalTeamStorageName)),
      );

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        Sqflite.firstIntValue(
          await raw.rawQuery(
            'SELECT count(*) FROM workforce_teams WHERE id = ?',
            [technicalId],
          ),
        ),
        1,
      );
      expect(
        Sqflite.firstIntValue(
          await raw.rawQuery(
            "SELECT count(*) FROM workforce_events WHERE aggregate_type = 'team' AND aggregate_id = ? AND event_type = 'team.created'",
            [technicalId],
          ),
        ),
        1,
      );
      expect(
        (await raw.query(
          'workforce_members',
          columns: ['team_id'],
          where: 'id = ?',
          whereArgs: [member1],
        )).single['team_id'],
        technicalId,
      );
      await raw.close();
    },
  );

  test(
    'Q04-A2 technical team collisions mismatches and archived rows fail closed',
    () async {
      const targetFirm = '11111111-1111-4111-8111-111111111121';
      const otherFirm = '11111111-1111-4111-8111-111111111122';
      const nameFirm = '11111111-1111-4111-8111-111111111123';
      const archivedFirm = '11111111-1111-4111-8111-111111111124';
      for (final value in const [
        (targetFirm, 'Hedef Firma', '33333333-3333-4333-8333-333333333321'),
        (otherFirm, 'Diğer Firma', '33333333-3333-4333-8333-333333333322'),
        (nameFirm, 'Ad Çakışması', '33333333-3333-4333-8333-333333333323'),
        (archivedFirm, 'Pasif Teknik', '33333333-3333-4333-8333-333333333324'),
      ]) {
        await attendance.createSubcontractor(
          CreateSubcontractorCommand(
            id: value.$1,
            eventId: value.$3,
            projectId: project1,
            name: value.$2,
          ),
        );
      }
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      const timestamp = '2026-07-19T08:00:00.000Z';
      Future<void> insertTeam({
        required String id,
        required String firmId,
        required String name,
        required String status,
      }) => raw.insert('workforce_teams', {
        'id': id,
        'project_id': project1,
        'subcontractor_id': firmId,
        'name': name,
        'name_normalized': name.toLowerCase(),
        'status': status,
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
        'archived_at': status == 'archived' ? timestamp : null,
      });
      await insertTeam(
        id: workforceTechnicalTeamId(project1, targetFirm),
        firmId: otherFirm,
        name: workforceTechnicalTeamStorageName,
        status: 'active',
      );
      await insertTeam(
        id: '22222222-2222-4222-8222-222222222231',
        firmId: nameFirm,
        name: workforceTechnicalTeamStorageName,
        status: 'active',
      );
      await insertTeam(
        id: workforceTechnicalTeamId(project1, archivedFirm),
        firmId: archivedFirm,
        name: workforceTechnicalTeamStorageName,
        status: 'archived',
      );
      await raw.close();

      Future<void> expectRejected(String id, String firmId) async {
        await expectLater(
          attendance.createMember(
            CreateWorkforceMemberCommand(
              id: id,
              projectId: project1,
              subcontractorId: firmId,
              fullName: 'Fail closed',
              roleName: 'Usta',
            ),
          ),
          throwsA(isA<AgendaValidationFailure>()),
        );
      }

      await expectRejected('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbc1', targetFirm);
      await expectRejected('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbc2', nameFirm);
      await expectRejected(
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbc3',
        archivedFirm,
      );
    },
  );

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
          address: 'Yaşam döngüsü firma adresi',
          specialty: 'Kalıp ve beton',
          startedOn: '2026-07-01',
          endedOn: '2026-12-31',
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
          address: 'Yaşam döngüsü personel adresi',
          startedOn: '2026-07-02',
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
      expect(reopenedSubcontractor.address, 'Yaşam döngüsü firma adresi');
      expect(reopenedSubcontractor.specialty, 'Kalıp ve beton');
      expect(reopenedSubcontractor.startedOn, '2026-07-01');
      expect(reopenedSubcontractor.endedOn, '2026-12-31');
      expect(reopenedTeam.isActive, isTrue);
      expect(reopenedMember.isActive, isTrue);
      expect(reopenedMember.address, 'Yaşam döngüsü personel adresi');
      expect(reopenedMember.startedOn, '2026-07-02');
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
    'compliance date boundaries and source precedence use the existing Istanbul read model',
    () async {
      final originalClock = now;
      addTearDown(() => now = originalClock);
      now = DateTime.utc(2026, 7, 19, 20, 59, 59);
      await _createMember(attendance, id: member1, name: 'Ayşe', team: 'A');
      final cases = [
        (
          ComplianceSourceStatus.valid,
          '2026-07-18',
          ComplianceReadStatus.expired,
        ),
        (
          ComplianceSourceStatus.valid,
          '2026-07-19',
          ComplianceReadStatus.expiring,
        ),
        (
          ComplianceSourceStatus.valid,
          '2026-08-18',
          ComplianceReadStatus.expiring,
        ),
        (
          ComplianceSourceStatus.valid,
          '2026-08-19',
          ComplianceReadStatus.valid,
        ),
        (ComplianceSourceStatus.valid, null, ComplianceReadStatus.valid),
        (
          ComplianceSourceStatus.missing,
          '2026-07-18',
          ComplianceReadStatus.missing,
        ),
        (
          ComplianceSourceStatus.notApplicable,
          '2026-07-18',
          ComplianceReadStatus.exception,
        ),
        (
          ComplianceSourceStatus.exception,
          '2026-08-19',
          ComplianceReadStatus.exception,
        ),
      ];
      final saved = <WorkforceComplianceRecord>[];
      for (var index = 0; index < cases.length; index++) {
        final value = cases[index];
        final suffix = (index + 1).toString().padLeft(12, '0');
        final record = await attendance.saveComplianceRecord(
          SaveComplianceRecordCommand(
            id: '44444444-4444-4444-8444-$suffix',
            eventId: '55555555-5555-4555-8555-$suffix',
            memberId: member1,
            expectedRevision: 0,
            documentType: ComplianceDocumentType.healthReport,
            sourceStatus: value.$1,
            expiryDate: value.$2,
            reason: 'Kullanıcı açıklaması $index',
          ),
        );
        saved.add(record);
        expect(record.readStatus, value.$3);
        expect(record.sourceStatus, value.$1);
        expect(record.expiryDate, value.$2);
      }
      final before = await attendance.getPersonDetail(member1);
      expect(
        before.compliance.map((item) => item.id),
        unorderedEquals(saved.map((item) => item.id)),
      );
      expect(before.missingComplianceCount, 1);
      expect(before.expiredComplianceCount, 1);
      expect(before.expiringComplianceCount, 2);
      expect(before.validComplianceCount, 2);

      now = DateTime.utc(2026, 7, 19, 21);
      final after = await attendance.getPersonDetail(member1);
      final byId = {for (final record in after.compliance) record.id: record};
      expect(byId[saved[1].id]!.readStatus, ComplianceReadStatus.expired);
      expect(byId[saved[3].id]!.readStatus, ComplianceReadStatus.expiring);
      expect(byId[saved[4].id]!.readStatus, ComplianceReadStatus.valid);
      expect(byId[saved[5].id]!.readStatus, ComplianceReadStatus.missing);
      expect(
        byId[saved[6].id]!.sourceStatus,
        ComplianceSourceStatus.notApplicable,
      );
      expect(byId[saved[7].id]!.sourceStatus, ComplianceSourceStatus.exception);
      for (final record in saved) {
        expect(byId[record.id]!.revision, record.revision);
        expect(byId[record.id]!.updatedAt, record.updatedAt);
        expect(byId[record.id]!.reason, record.reason);
      }
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

  test(
    'tombstoned roster entry revives canonical identity and refreshes Agenda',
    () async {
      final originalClock = now;
      addTearDown(() => now = originalClock);
      await _createMember(
        attendance,
        id: member1,
        name: 'Ali Usta',
        team: 'Kalıp Ekibi',
      );
      final day = await _ensureDay(attendance);
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
      final initialRosterSnapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      final initialEntryRow =
          initialRosterSnapshot['attendance_entries']!.single;

      now = DateTime.utc(2026, 7, 19, 9);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event3,
          reminderEventId: event4,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      final initialAgendaSnapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      final initialAgendaRow =
          initialAgendaSnapshot['field_observations']!.single;
      final initialAgendaLink =
          initialAgendaSnapshot['attendance_day_agenda_links']!.single;

      now = DateTime.utc(2026, 7, 19, 10);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event5,
          reminderEventId: event6,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.reopen,
        ),
      );
      now = DateTime.utc(2026, 7, 19, 11);
      detail = await attendance.removeEntry(
        RemoveAttendanceEntryCommand(
          dayId: day.id,
          entryId: entry1,
          eventId: 'f4000000-0000-4000-8000-000000000001',
          expectedRevision: detail.day.revision,
        ),
      );
      expect(detail.entries, isEmpty);
      final tombstonedSnapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      expect(tombstonedSnapshot['attendance_entries'], hasLength(1));
      expect(
        tombstonedSnapshot['attendance_entries']!.single['removed_at'],
        isNotNull,
      );

      now = DateTime.utc(2026, 7, 19, 12);
      final reactivate = SaveAttendanceRosterCommand(
        dayId: day.id,
        eventId: 'f4000000-0000-4000-8000-000000000002',
        expectedRevision: detail.day.revision,
        values: const [
          AttendanceRosterValue(
            entryId: entry2,
            memberId: member1,
            result: AttendanceResult.halfDay,
            overtimeMinutes: 30,
            shortNote: 'Yeniden sahada',
          ),
        ],
      );
      detail = await attendance.saveRoster(reactivate);
      expect(detail.entries, hasLength(1));
      expect(detail.entries.single.id, entry1);
      expect(detail.entries.single.result, AttendanceResult.halfDay);
      expect(detail.entries.single.overtimeMinutes, 30);
      final revivedSnapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      expect(revivedSnapshot['attendance_entries'], hasLength(1));
      final revivedEntryRow = revivedSnapshot['attendance_entries']!.single;
      expect(revivedEntryRow['id'], entry1);
      expect(revivedEntryRow['created_at'], initialEntryRow['created_at']);
      expect(revivedEntryRow['removed_at'], isNull);
      expect(revivedEntryRow['result'], 'half_day');
      expect(revivedEntryRow['overtime_minutes'], 30);
      expect(revivedEntryRow['short_note'], 'Yeniden sahada');
      final reactivationEvent = revivedSnapshot['attendance_events']!
          .singleWhere(
            (row) => row['id'] == 'f4000000-0000-4000-8000-000000000002',
          );
      final reactivationPayload =
          jsonDecode(reactivationEvent['payload_json']! as String)
              as Map<String, dynamic>;
      final reactivationChange =
          (reactivationPayload['changes']! as List<dynamic>).single
              as Map<String, dynamic>;
      expect(reactivationChange['entry_id'], entry1);

      now = DateTime.utc(2026, 7, 19, 13);
      final retried = await attendance.saveRoster(reactivate);
      expect(retried.day.revision, detail.day.revision);
      expect(
        await _attendanceAgendaSnapshot(directories.databaseFile, day.id),
        revivedSnapshot,
      );

      now = DateTime.utc(2026, 7, 19, 14);
      await expectLater(
        attendance.saveRoster(
          SaveAttendanceRosterCommand(
            dayId: day.id,
            eventId: 'f4000000-0000-4000-8000-000000000003',
            expectedRevision: retried.day.revision,
            values: const [
              AttendanceRosterValue(
                entryId: entry2,
                memberId: member1,
                result: AttendanceResult.absent,
                overtimeMinutes: 0,
              ),
            ],
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect(
        await _attendanceAgendaSnapshot(directories.databaseFile, day.id),
        revivedSnapshot,
      );

      now = DateTime.utc(2026, 7, 19, 15);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: 'f4000000-0000-4000-8000-000000000004',
          reminderEventId: 'f4000000-0000-4000-8000-000000000005',
          expectedRevision: retried.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      final finalSnapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      expect(finalSnapshot['attendance_entries'], hasLength(1));
      expect(finalSnapshot['attendance_entries']!.single['id'], entry1);
      expect(finalSnapshot['field_observations'], hasLength(1));
      expect(finalSnapshot['field_observations']!.single, {
        ...initialAgendaRow,
        'observed_at': detail.day.updatedAt,
        'updated_at': detail.day.updatedAt,
        'revision': 2,
      });
      expect(finalSnapshot['attendance_day_agenda_links'], [initialAgendaLink]);
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
    'attendance completion owns one Agenda projection across retry and lifecycle',
    () async {
      final originalClock = now;
      addTearDown(() => now = originalClock);
      final day = await _ensureDay(attendance);
      const complete = TransitionAttendanceDayCommand(
        dayId: day1,
        dayEventId: event2,
        reminderEventId: event3,
        expectedRevision: 1,
        transition: AttendanceTransition.complete,
      );
      var detail = await attendance.transitionDay(complete);
      expect(detail.day.status, AttendanceDayStatus.completed);
      expect(detail.day.revision, 2);
      final acceptedCompletionAt = detail.day.updatedAt;

      final firstSnapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      detail = await attendance.transitionDay(complete);
      expect(detail.day.revision, 2);
      expect(
        await _attendanceAgendaSnapshot(directories.databaseFile, day.id),
        firstSnapshot,
      );
      await expectLater(
        attendance.transitionDay(
          const TransitionAttendanceDayCommand(
            dayId: day1,
            dayEventId: '99999999-9999-4999-8999-999999999991',
            reminderEventId: '99999999-9999-4999-8999-999999999992',
            expectedRevision: 1,
            transition: AttendanceTransition.reopen,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect(
        await _attendanceAgendaSnapshot(directories.databaseFile, day.id),
        firstSnapshot,
      );

      final links = firstSnapshot['attendance_day_agenda_links']!;
      expect(links, hasLength(1));
      expect(links.single['attendance_day_id'], day.id);
      expect(links.single['project_id'], project1);
      final agendaLogId = links.single['agenda_log_id']! as String;
      final agendaRows = firstSnapshot['field_observations']!;
      expect(agendaRows, hasLength(1));
      expect(agendaRows.single, containsPair('id', agendaLogId));
      expect(agendaRows.single['project_id'], project1);
      expect(agendaRows.single['observed_at'], acceptedCompletionAt);
      expect(agendaRows.single['created_at'], acceptedCompletionAt);
      expect(agendaRows.single['category'], 'general_note');
      expect(agendaRows.single['description'], 'Puantaj gün tamamlama kaydı');
      expect(
        agendaRows.single['notes'],
        'Bu kayıt tamamlanan Puantaj gününden otomatik oluşturuldu.',
      );
      expect(agendaRows.single['location'], isNull);
      expect(agendaRows.single['location_id'], isNull);
      expect(agendaRows.single['revision'], 1);

      final sourceDetail = await agenda.getAgendaLogDetail(agendaLogId);
      expect(sourceDetail.managedAttendanceSource?.attendanceDayId, day.id);
      expect(sourceDetail.managedAttendanceSource?.projectId, project1);
      expect(sourceDetail.managedAttendanceSource?.localDate, '2026-07-19');

      now = DateTime.utc(2026, 7, 19, 9);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event4,
          reminderEventId: event5,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.reopen,
        ),
      );
      now = DateTime.utc(2026, 7, 19, 10);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event6,
          reminderEventId: 'ffffffff-ffff-4fff-8fff-fffffffffff1',
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      final noMutationRecompletion = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      expect(noMutationRecompletion['field_observations'], agendaRows);
      expect(noMutationRecompletion['attendance_day_agenda_links'], links);

      now = DateTime.utc(2026, 7, 19, 11);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: 'ffffffff-ffff-4fff-8fff-fffffffffff2',
          reminderEventId: 'ffffffff-ffff-4fff-8fff-fffffffffff3',
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.reopen,
        ),
      );
      now = DateTime.utc(2026, 7, 19, 12);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: 'ffffffff-ffff-4fff-8fff-fffffffffff4',
          reminderEventId: 'ffffffff-ffff-4fff-8fff-fffffffffff5',
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.noWork,
        ),
      );
      expect(detail.day.status, AttendanceDayStatus.noWork);

      final lifecycle = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      expect(lifecycle['field_observations'], agendaRows);
      expect(lifecycle['attendance_day_agenda_links'], links);
      final lifecycleEvents = lifecycle['observation_events']!;
      expect(lifecycleEvents.map((row) => row['event_type']), [
        'attendance_day.completed',
        'attendance_day.reopened',
        'attendance_day.completed',
        'attendance_day.reopened',
        'attendance_day.no_work',
      ]);
      expect(
        lifecycleEvents.map(
          (row) =>
              jsonDecode(row['payload_json']! as String)['attendance_revision'],
        ),
        [2, 3, 4, 5, 6],
      );

      final restarted = SqliteAttendanceApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        agenda: agenda,
      );
      expect((await restarted.getDayDetail(day.id)).day.revision, 6);
      expect(
        (await agenda.getAgendaLogDetail(
          agendaLogId,
        )).managedAttendanceSource?.attendanceDayId,
        day.id,
      );
    },
  );

  test(
    'changed recompletion refreshes one managed Agenda projection and retry is exact',
    () async {
      final originalClock = now;
      addTearDown(() => now = originalClock);
      await _createMember(
        attendance,
        id: member1,
        name: 'Ali Usta',
        team: 'Kalıp Ekibi',
      );
      final day = await _ensureDay(attendance);
      var detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event2,
          reminderEventId: event3,
          expectedRevision: day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      final initialSnapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      final initialAgendaRow = Map<String, Object?>.from(
        initialSnapshot['field_observations']!.single,
      );
      final initialLink =
          initialSnapshot['attendance_day_agenda_links']!.single;
      final agendaLogId = initialAgendaRow['id']! as String;

      now = DateTime.utc(2026, 7, 19, 9);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event4,
          reminderEventId: event5,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.reopen,
        ),
      );
      now = DateTime.utc(2026, 7, 19, 10);
      detail = await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: day.id,
          eventId: event6,
          expectedRevision: detail.day.revision,
          values: const [
            AttendanceRosterValue(
              entryId: entry1,
              memberId: member1,
              result: AttendanceResult.fullDay,
              overtimeMinutes: 60,
            ),
          ],
        ),
      );
      now = DateTime.utc(2026, 7, 19, 11);
      final recomplete = TransitionAttendanceDayCommand(
        dayId: day.id,
        dayEventId: 'f1000000-0000-4000-8000-000000000001',
        reminderEventId: 'f1000000-0000-4000-8000-000000000002',
        expectedRevision: detail.day.revision,
        transition: AttendanceTransition.complete,
      );
      detail = await attendance.transitionDay(recomplete);
      final refreshedAt = detail.day.updatedAt;
      final refreshedSnapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      expect(refreshedSnapshot['field_observations'], hasLength(1));
      expect(refreshedSnapshot['field_observations']!.single, {
        ...initialAgendaRow,
        'observed_at': refreshedAt,
        'updated_at': refreshedAt,
        'revision': 2,
      });
      expect(refreshedSnapshot['attendance_day_agenda_links'], [initialLink]);

      now = DateTime.utc(2026, 7, 19, 12);
      final retried = await attendance.transitionDay(recomplete);
      expect(retried.day.revision, detail.day.revision);
      expect(
        await _attendanceAgendaSnapshot(directories.databaseFile, day.id),
        refreshedSnapshot,
      );

      final restartedAgenda = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
      );
      final restartedAttendance = SqliteAttendanceApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        agenda: restartedAgenda,
      );
      final restartedSource = await restartedAgenda.getAgendaLogDetail(
        agendaLogId,
      );
      expect(restartedSource.log.observedAt, refreshedAt);
      expect(restartedSource.log.updatedAt, refreshedAt);
      expect(restartedSource.log.createdAt, initialAgendaRow['created_at']);
      expect(restartedSource.log.revision, 2);
      expect(restartedSource.managedAttendanceSource?.attendanceDayId, day.id);
      expect((await restartedAttendance.getDayDetail(day.id)).day.revision, 5);
    },
  );

  test(
    'entry removal and note update each refresh changed recompletion',
    () async {
      final originalClock = now;
      addTearDown(() => now = originalClock);
      await _createMember(
        attendance,
        id: member1,
        name: 'Ali Usta',
        team: 'Kalıp Ekibi',
      );
      final day = await _ensureDay(attendance);
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
      now = DateTime.utc(2026, 7, 19, 9);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event3,
          reminderEventId: event4,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      final initialSnapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      final initialRow = initialSnapshot['field_observations']!.single;
      final initialLink =
          initialSnapshot['attendance_day_agenda_links']!.single;

      now = DateTime.utc(2026, 7, 19, 10);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event5,
          reminderEventId: event6,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.reopen,
        ),
      );
      now = DateTime.utc(2026, 7, 19, 11);
      detail = await attendance.removeEntry(
        RemoveAttendanceEntryCommand(
          dayId: day.id,
          entryId: entry1,
          eventId: 'f2000000-0000-4000-8000-000000000001',
          expectedRevision: detail.day.revision,
        ),
      );
      now = DateTime.utc(2026, 7, 19, 12);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: 'f2000000-0000-4000-8000-000000000002',
          reminderEventId: 'f2000000-0000-4000-8000-000000000003',
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      final removalRefreshAt = detail.day.updatedAt;
      var refreshed = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      expect(
        refreshed['field_observations']!.single['observed_at'],
        removalRefreshAt,
      );
      expect(
        refreshed['field_observations']!.single['updated_at'],
        removalRefreshAt,
      );
      expect(refreshed['field_observations']!.single['revision'], 2);

      now = DateTime.utc(2026, 7, 19, 13);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: 'f2000000-0000-4000-8000-000000000004',
          reminderEventId: 'f2000000-0000-4000-8000-000000000005',
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.reopen,
        ),
      );
      now = DateTime.utc(2026, 7, 19, 14);
      detail = await attendance.updateNote(
        UpdateAttendanceNoteCommand(
          dayId: day.id,
          eventId: 'f2000000-0000-4000-8000-000000000006',
          expectedRevision: detail.day.revision,
          generalNote: 'Reopen sonrası saha notu',
        ),
      );
      now = DateTime.utc(2026, 7, 19, 15);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: 'f2000000-0000-4000-8000-000000000007',
          reminderEventId: 'f2000000-0000-4000-8000-000000000008',
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      final noteRefreshAt = detail.day.updatedAt;
      refreshed = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      final finalRow = refreshed['field_observations']!.single;
      expect(finalRow['observed_at'], noteRefreshAt);
      expect(finalRow['updated_at'], noteRefreshAt);
      expect(finalRow['revision'], 3);
      expect(finalRow['created_at'], initialRow['created_at']);
      expect(finalRow['id'], initialRow['id']);
      expect(finalRow['project_id'], initialRow['project_id']);
      expect(refreshed['field_observations'], hasLength(1));
      expect(refreshed['attendance_day_agenda_links'], [initialLink]);
    },
  );

  test(
    'managed Agenda update failure rolls back Attendance reminder Agenda and link',
    () async {
      final originalClock = now;
      addTearDown(() => now = originalClock);
      await _createMember(
        attendance,
        id: member1,
        name: 'Ali Usta',
        team: 'Kalıp Ekibi',
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
      await attendance.ensureRollingOccurrences();
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final dayId =
          (await raw.query(
                'attendance_days',
                columns: ['id'],
                where: 'project_id = ? AND local_date = ?',
                whereArgs: [project1, '2026-07-19'],
                limit: 1,
              )).single['id']!
              as String;
      await raw.close();
      var detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: dayId,
          dayEventId: event2,
          reminderEventId: event3,
          expectedRevision: 1,
          transition: AttendanceTransition.complete,
        ),
      );
      now = DateTime.utc(2026, 7, 19, 9);
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: dayId,
          dayEventId: event4,
          reminderEventId: event5,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.reopen,
        ),
      );
      now = DateTime.utc(2026, 7, 19, 10);
      detail = await attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: dayId,
          eventId: event6,
          expectedRevision: detail.day.revision,
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
      final before = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        dayId,
      );
      final agendaLogId = before['field_observations']!.single['id']! as String;
      final triggerDatabase = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await triggerDatabase.execute('''
        CREATE TRIGGER fail_managed_agenda_refresh
        BEFORE UPDATE OF observed_at, updated_at, revision
        ON field_observations
        WHEN OLD.id = '$agendaLogId'
        BEGIN
          SELECT RAISE(ABORT, 'intentional managed Agenda update failure');
        END
      ''');
      await triggerDatabase.close();

      now = DateTime.utc(2026, 7, 19, 11);
      final failing = SqliteAttendanceApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        agenda: agenda,
      );
      await expectLater(
        failing.transitionDay(
          TransitionAttendanceDayCommand(
            dayId: dayId,
            dayEventId: 'f3000000-0000-4000-8000-000000000001',
            reminderEventId: 'f3000000-0000-4000-8000-000000000002',
            expectedRevision: detail.day.revision,
            transition: AttendanceTransition.complete,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        await _attendanceAgendaSnapshot(directories.databaseFile, dayId),
        before,
      );
    },
  );

  test(
    'Agenda projection failures roll back Attendance reminder Agenda and link',
    () async {
      await attendance.saveReminderSetting(
        const SaveAttendanceReminderSettingCommand(
          projectId: project1,
          expectedRevision: 0,
          isEnabled: true,
          localTime: '17:00',
          selectedWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      );
      await attendance.ensureRollingOccurrences();
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final dayId =
          (await raw.query(
                'attendance_days',
                columns: ['id'],
                where: 'project_id = ? AND local_date = ?',
                whereArgs: [project1, '2026-07-19'],
                limit: 1,
              )).single['id']!
              as String;
      await raw.close();
      final before = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        dayId,
      );

      for (var index = 0; index < 3; index += 1) {
        final stage = ['base', 'event', 'link'][index];
        Future<void> fail(Transaction _) async {
          throw StateError('intentional $stage failure');
        }

        final failing = SqliteAttendanceApplication(
          databasePath: directories.databaseFile,
          databaseFactory: databaseFactoryFfi,
          clock: () => now,
          agenda: agenda,
          beforeManagedAgendaBaseInsert: stage == 'base' ? fail : null,
          beforeManagedAgendaEventInsert: stage == 'event' ? fail : null,
          beforeManagedAgendaLinkInsert: stage == 'link' ? fail : null,
        );
        await expectLater(
          failing.transitionDay(
            TransitionAttendanceDayCommand(
              dayId: dayId,
              dayEventId:
                  '44444444-4444-4444-8444-${(100 + index).toString().padLeft(12, '0')}',
              reminderEventId:
                  '55555555-5555-4555-8555-${(100 + index).toString().padLeft(12, '0')}',
              expectedRevision: 1,
              transition: AttendanceTransition.complete,
            ),
          ),
          throwsStateError,
        );
        expect(
          await _attendanceAgendaSnapshot(directories.databaseFile, dayId),
          before,
          reason: stage,
        );
      }
    },
  );

  test(
    'no-work without a prior completion creates no Agenda projection',
    () async {
      final day = await _ensureDay(attendance);
      final result = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event2,
          reminderEventId: event3,
          expectedRevision: day.revision,
          transition: AttendanceTransition.noWork,
        ),
      );
      expect(result.day.status, AttendanceDayStatus.noWork);
      expect(
        await _count(directories.databaseFile, 'attendance_day_agenda_links'),
        0,
      );
      expect(await _count(directories.databaseFile, 'field_observations'), 0);
      expect(await _count(directories.databaseFile, 'observation_events'), 0);
    },
  );

  test(
    'concurrent completion accepts one writer and rejects one stale writer',
    () async {
      final day = await _ensureDay(attendance);
      final firstReachedEventBoundary = Completer<void>();
      final releaseFirst = Completer<void>();
      final coordinator = MobileOperationCoordinator();
      final firstWriter = SqliteAttendanceApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        agenda: agenda,
        coordinator: coordinator,
        beforeAttendanceEventInsert: (_) async {
          if (!firstReachedEventBoundary.isCompleted) {
            firstReachedEventBoundary.complete();
            await releaseFirst.future;
          }
        },
      );
      final secondWriter = SqliteAttendanceApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        agenda: agenda,
        coordinator: coordinator,
      );
      Future<Object?> outcome(Future<AttendanceDayDetail> operation) async {
        try {
          await operation;
          return null;
        } on Object catch (error) {
          return error;
        }
      }

      final accepted = outcome(
        firstWriter.transitionDay(
          TransitionAttendanceDayCommand(
            dayId: day.id,
            dayEventId: event2,
            reminderEventId: event3,
            expectedRevision: day.revision,
            transition: AttendanceTransition.complete,
          ),
        ),
      );
      await firstReachedEventBoundary.future;
      final stale = outcome(
        secondWriter.transitionDay(
          TransitionAttendanceDayCommand(
            dayId: day.id,
            dayEventId: event4,
            reminderEventId: event5,
            expectedRevision: day.revision,
            transition: AttendanceTransition.complete,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      releaseFirst.complete();
      final outcomes = await Future.wait([accepted, stale]);

      expect(outcomes.first, isNull);
      expect(outcomes.last, isA<AgendaValidationFailure>());
      final snapshot = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      expect(snapshot['attendance_day_agenda_links'], hasLength(1));
      expect(snapshot['field_observations'], hasLength(1));
      expect(snapshot['observation_events'], hasLength(1));
      expect(
        snapshot['attendance_events']!.where(
          (row) => row['event_type'] == 'attendance_day.completed',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'same local date in two projects creates isolated Agenda source records',
    () async {
      await agenda.createProject(
        const CreateProjectCommand(id: project2, name: 'Şantiye B'),
      );
      final first = await _ensureDay(attendance);
      final second = await attendance.ensureDay(
        const EnsureAttendanceDayCommand(
          id: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2',
          eventId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeee21',
          projectId: project2,
          localDate: '2026-07-19',
        ),
      );
      await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: first.id,
          dayEventId: event2,
          reminderEventId: event3,
          expectedRevision: first.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: second.id,
          dayEventId: event4,
          reminderEventId: event5,
          expectedRevision: second.revision,
          transition: AttendanceTransition.complete,
        ),
      );

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final links = await raw.query(
        'attendance_day_agenda_links',
        orderBy: 'project_id ASC',
      );
      final observations = await raw.rawQuery('''
        SELECT o.id, o.project_id, o.description, l.attendance_day_id
        FROM field_observations o
        JOIN attendance_day_agenda_links l ON l.agenda_log_id = o.id
        ORDER BY o.project_id ASC
      ''');
      await raw.close();

      expect(links, hasLength(2));
      expect(links.map((row) => row['project_id']), [project1, project2]);
      expect(links.map((row) => row['agenda_log_id']).toSet(), hasLength(2));
      expect(observations, hasLength(2));
      expect(observations.map((row) => row['project_id']), [
        project1,
        project2,
      ]);
      expect(observations.map((row) => row['attendance_day_id']), [
        first.id,
        second.id,
      ]);
      expect(observations.map((row) => row['description']).toSet(), {
        'Puantaj gün tamamlama kaydı',
      });
    },
  );

  test(
    'legacy completed day is linked only after a later explicit completion',
    () async {
      final day = await _ensureDay(attendance);
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await raw.update(
        'attendance_days',
        {
          'status': 'completed',
          'revision': 2,
          'updated_at': '2026-07-19T08:00:00Z',
          'completed_at': '2026-07-19T08:00:00Z',
        },
        where: 'id = ? AND revision = 1',
        whereArgs: [day.id],
      );
      await raw.insert('attendance_events', {
        'id': event2,
        'attendance_day_id': day.id,
        'sequence': 2,
        'event_type': 'attendance_day.completed',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': jsonEncode({
          'before_status': 'draft',
          'after_status': 'completed',
          'revision': 2,
        }),
      });
      await raw.close();

      var detail = await attendance.transitionDay(
        const TransitionAttendanceDayCommand(
          dayId: day1,
          dayEventId: event3,
          reminderEventId: event4,
          expectedRevision: 2,
          transition: AttendanceTransition.reopen,
        ),
      );
      expect(
        await _count(directories.databaseFile, 'attendance_day_agenda_links'),
        0,
      );
      detail = await attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: day.id,
          dayEventId: event5,
          reminderEventId: event6,
          expectedRevision: detail.day.revision,
          transition: AttendanceTransition.complete,
        ),
      );
      expect(detail.day.revision, 4);
      expect(
        await _count(directories.databaseFile, 'attendance_day_agenda_links'),
        1,
      );
      final projection = await _attendanceAgendaSnapshot(
        directories.databaseFile,
        day.id,
      );
      expect(
        projection['observation_events']!.map((row) => row['event_type']),
        ['attendance_day.completed'],
      );
    },
  );

  test(
    'deterministic Agenda id collision fails without adopting ordinary data',
    () async {
      final day = await _ensureDay(attendance);
      final collidingId = _attendanceAgendaTestUuid(
        'attendance-managed-agenda:${day.id}',
      );
      await agenda.createAgendaLog(
        CreateAgendaLogCommand(
          id: collidingId,
          eventId: event2,
          projectId: project1,
          observedAt: '2026-07-19T07:00:00Z',
          category: AgendaCategory.generalNote,
          description: 'Sıradan kullanıcı kaydı',
          location: null,
          notes: null,
        ),
      );

      await expectLater(
        attendance.transitionDay(
          TransitionAttendanceDayCommand(
            dayId: day.id,
            dayEventId: event3,
            reminderEventId: event4,
            expectedRevision: day.revision,
            transition: AttendanceTransition.complete,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
      final unchangedDay = await attendance.getDayDetail(day.id);
      expect(unchangedDay.day.status, AttendanceDayStatus.draft);
      expect(unchangedDay.day.revision, 1);
      expect(
        (await agenda.getAgendaLogDetail(collidingId)).log.description,
        'Sıradan kullanıcı kaydı',
      );
      expect(
        await _count(directories.databaseFile, 'attendance_day_agenda_links'),
        0,
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

Future<Map<String, List<Map<String, Object?>>>> _attendanceAgendaSnapshot(
  String path,
  String attendanceDayId,
) async {
  final agendaLogId = _attendanceAgendaTestUuid(
    'attendance-managed-agenda:$attendanceDayId',
  );
  final raw = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  final snapshot = <String, List<Map<String, Object?>>>{
    'attendance_days': await raw.query(
      'attendance_days',
      where: 'id = ?',
      whereArgs: [attendanceDayId],
    ),
    'attendance_events': await raw.query(
      'attendance_events',
      where: 'attendance_day_id = ?',
      whereArgs: [attendanceDayId],
      orderBy: 'sequence ASC, id ASC',
    ),
    'attendance_entries': await raw.query(
      'attendance_entries',
      where: 'attendance_day_id = ?',
      whereArgs: [attendanceDayId],
      orderBy: 'id ASC',
    ),
    'attendance_day_reminder_links': await raw.query(
      'attendance_day_reminder_links',
      where: 'attendance_day_id = ?',
      whereArgs: [attendanceDayId],
    ),
    'follow_up_items': await raw.query(
      'follow_up_items',
      where: 'attendance_day_id = ?',
      whereArgs: [attendanceDayId],
      orderBy: 'id ASC',
    ),
    'follow_up_events': await raw.query(
      'follow_up_events',
      where: 'source_attendance_day_id = ?',
      whereArgs: [attendanceDayId],
      orderBy: 'id ASC',
    ),
    'field_observations': await raw.query(
      'field_observations',
      where: 'id = ?',
      whereArgs: [agendaLogId],
      orderBy: 'id ASC',
    ),
    'observation_events': await raw.query(
      'observation_events',
      where: 'observation_id = ?',
      whereArgs: [agendaLogId],
      orderBy: 'rowid ASC',
    ),
    'attendance_day_agenda_links': await raw.query(
      'attendance_day_agenda_links',
      where: 'attendance_day_id = ?',
      whereArgs: [attendanceDayId],
    ),
  };
  await raw.close();
  return snapshot;
}

String _attendanceAgendaTestUuid(String seed) {
  int hash(String value, int salt) {
    var result = (2166136261 ^ salt) & 0xffffffff;
    for (final unit in value.codeUnits) {
      result ^= unit;
      result = (result * 16777619) & 0xffffffff;
    }
    return result;
  }

  final raw = List.generate(
    4,
    (index) =>
        hash(seed, 0x9e3779b9 * (index + 1)).toRadixString(16).padLeft(8, '0'),
  ).join();
  final chars = raw.split('');
  chars[12] = '4';
  chars[16] = '8';
  final value = chars.join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
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
