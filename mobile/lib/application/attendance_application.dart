import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/platform/attendance_export_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class AttendanceApplication {
  Future<List<Subcontractor>> listSubcontractors(
    String projectId, {
    bool includeArchived = false,
  });

  Future<Subcontractor> createSubcontractor(CreateSubcontractorCommand command);

  Future<Subcontractor> updateSubcontractor(UpdateSubcontractorCommand command);

  Future<Subcontractor> transitionSubcontractor(
    TransitionSubcontractorCommand command,
  );

  Future<List<WorkforceTeam>> listTeams(
    String projectId, {
    String? subcontractorId,
    bool includeArchived = false,
  });

  Future<WorkforceTeam> createTeam(CreateWorkforceTeamCommand command);

  Future<WorkforceTeam> updateTeam(UpdateWorkforceTeamCommand command);

  Future<WorkforceTeam> transitionTeam(TransitionWorkforceTeamCommand command);

  Future<List<ActiveTeamCount>> listActiveTeamCounts(String projectId);

  Future<WorkforcePersonDetail> getPersonDetail(String memberId);

  Future<WorkforceComplianceRecord> saveComplianceRecord(
    SaveComplianceRecordCommand command,
  );

  Future<WorkforceComplianceRecord> archiveComplianceRecord(
    ArchiveComplianceRecordCommand command,
  );

  Future<WorkforcePpeAssignment> savePpeAssignment(
    SavePpeAssignmentCommand command,
  );

  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  });

  Future<WorkforceMember> createMember(CreateWorkforceMemberCommand command);

  Future<WorkforceMember> updateMember(UpdateWorkforceMemberCommand command);

  Future<WorkforceMember> archiveMember(ArchiveWorkforceMemberCommand command);

  Future<AttendanceDay> ensureDay(EnsureAttendanceDayCommand command);

  Future<AttendanceDayDetail> getDayDetail(String dayId);

  Future<AttendanceDayDetail> saveRoster(SaveAttendanceRosterCommand command);

  Future<AttendanceDayDetail> markFullDay(MarkAttendanceFullCommand command);

  Future<AttendanceDayDetail> removeEntry(RemoveAttendanceEntryCommand command);

  Future<AttendanceDayDetail> updateNote(UpdateAttendanceNoteCommand command);

  Future<AttendanceDayDetail> transitionDay(
    TransitionAttendanceDayCommand command,
  );

  Future<AttendanceReminderSetting> getReminderSetting(String projectId);

  Future<AttendanceReminderSetting> saveReminderSetting(
    SaveAttendanceReminderSettingCommand command,
  );

  Future<void> ensureRollingOccurrences();

  Future<AttendanceExportResult> exportDay(
    ExportAttendanceDayCommand command, {
    bool share = false,
  });
}

typedef AttendanceTransactionHook = Future<void> Function(Transaction value);

class SqliteAttendanceApplication implements AttendanceApplication {
  SqliteAttendanceApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.clock,
    required this.agenda,
    MobileOperationCoordinator? coordinator,
    AttendanceExportGateway? exportGateway,
    this.beforeAttendanceEventInsert,
  }) : coordinator = coordinator ?? MobileOperationCoordinator(),
       exportGateway =
           exportGateway ?? const UnavailableAttendanceExportGateway();

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;
  final AgendaApplication agenda;
  final MobileOperationCoordinator coordinator;
  final AttendanceExportGateway exportGateway;
  final AttendanceTransactionHook? beforeAttendanceEventInsert;

  @override
  Future<List<Subcontractor>> listSubcontractors(
    String projectId, {
    bool includeArchived = false,
  }) async {
    validateUuid(projectId, 'Proje kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.rawQuery(
        '''
        SELECT s.*,
          (SELECT count(*) FROM workforce_teams t
            WHERE t.subcontractor_id = s.id AND t.status = 'active')
            AS active_team_count,
          (SELECT count(*) FROM workforce_members m
            WHERE m.subcontractor_id = s.id AND m.is_active = 1)
            AS active_person_count
        FROM subcontractors s
        WHERE s.project_id = ?
          ${includeArchived ? '' : "AND s.status = 'active'"}
        ORDER BY s.name_normalized ASC, s.id ASC
      ''',
        [projectId],
      );
      return rows.map(_subcontractorFromRow).toList(growable: false);
    });
  }

  @override
  Future<Subcontractor> createSubcontractor(
    CreateSubcontractorCommand command,
  ) async {
    validateUuid(command.id, 'Taşeron kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    final name = requiredTrimmed(command.name, 'Taşeron adı', maxLength: 200);
    final normalized = _normalizeRegistryName(name);
    final contact = optionalTrimmed(
      command.contactName,
      'Yetkili adı',
      maxLength: 200,
    );
    final phone = optionalTrimmed(command.phone, 'Telefon', maxLength: 80);
    final address = optionalTrimmed(command.address, 'Adres', maxLength: 1000);
    final specialty = optionalTrimmed(
      command.specialty,
      'İş kalemi/uzmanlık',
      maxLength: 200,
    );
    final startedOn = _optionalLocalDate(command.startedOn, 'Başlangıç tarihi');
    final endedOn = _optionalLocalDate(command.endedOn, 'Bitiş tarihi');
    _validateRegistryDateRange(startedOn, endedOn);
    final note = optionalTrimmed(command.note, 'Not', maxLength: 1000);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(
      now,
      (database) => database.transaction((tx) async {
        await _requireProject(tx, command.projectId);
        final existing = await tx.query(
          'subcontractors',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final value = await _loadSubcontractor(tx, command.id);
          if (value.projectId != command.projectId ||
              value.name != name ||
              value.contactName != contact ||
              value.phone != phone ||
              value.address != address ||
              value.specialty != specialty ||
              value.startedOn != startedOn ||
              value.endedOn != endedOn ||
              value.note != note) {
            throw const AgendaValidationFailure(
              'Taşeron kimliği başka bir içerikle kullanılıyor.',
            );
          }
          return value;
        }
        await tx.insert('subcontractors', {
          'id': command.id,
          'project_id': command.projectId,
          'name': name,
          'name_normalized': normalized,
          'contact_name': contact,
          'phone': phone,
          'address': address,
          'specialty': specialty,
          'started_on': startedOn,
          'ended_on': endedOn,
          'note': note,
          'status': WorkforceRecordStatus.active.storageValue,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        await _insertWorkforceEvent(
          tx,
          id: command.eventId,
          type: 'subcontractor',
          aggregateId: command.id,
          projectId: command.projectId,
          eventType: 'subcontractor.created',
          occurredAt: timestamp,
          payload: {'name': name},
        );
        return _loadSubcontractor(tx, command.id);
      }),
    );
  }

  @override
  Future<Subcontractor> updateSubcontractor(
    UpdateSubcontractorCommand command,
  ) async {
    validateUuid(command.id, 'Taşeron kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final name = requiredTrimmed(command.name, 'Taşeron adı', maxLength: 200);
    final contact = optionalTrimmed(
      command.contactName,
      'Yetkili adı',
      maxLength: 200,
    );
    final phone = optionalTrimmed(command.phone, 'Telefon', maxLength: 80);
    final requestedAddress = optionalTrimmed(
      command.address,
      'Adres',
      maxLength: 1000,
    );
    final requestedSpecialty = optionalTrimmed(
      command.specialty,
      'İş kalemi/uzmanlık',
      maxLength: 200,
    );
    final requestedStartedOn = _optionalLocalDate(
      command.startedOn,
      'Başlangıç tarihi',
    );
    final requestedEndedOn = _optionalLocalDate(
      command.endedOn,
      'Bitiş tarihi',
    );
    final note = optionalTrimmed(command.note, 'Not', maxLength: 1000);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(
      now,
      (database) => database.transaction((tx) async {
        final current = await _loadSubcontractor(tx, command.id);
        _requireRevision(current.revision, command.expectedRevision);
        final address = command.replaceAddress
            ? requestedAddress
            : current.address;
        final specialty = command.replaceSpecialty
            ? requestedSpecialty
            : current.specialty;
        final startedOn = command.replaceStartedOn
            ? requestedStartedOn
            : current.startedOn;
        final endedOn = command.replaceEndedOn
            ? requestedEndedOn
            : current.endedOn;
        _validateRegistryDateRange(startedOn, endedOn);
        if (current.name == name &&
            current.contactName == contact &&
            current.phone == phone &&
            current.address == address &&
            current.specialty == specialty &&
            current.startedOn == startedOn &&
            current.endedOn == endedOn &&
            current.note == note) {
          return current;
        }
        final changed = await tx.update(
          'subcontractors',
          {
            'name': name,
            'name_normalized': _normalizeRegistryName(name),
            'contact_name': contact,
            'phone': phone,
            'address': address,
            'specialty': specialty,
            'started_on': startedOn,
            'ended_on': endedOn,
            'note': note,
            'revision': current.revision + 1,
            'updated_at': timestamp,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [current.id, current.revision],
        );
        if (changed != 1) throw _staleFailure();
        await _insertWorkforceEvent(
          tx,
          id: command.eventId,
          type: 'subcontractor',
          aggregateId: current.id,
          projectId: current.projectId,
          eventType: 'subcontractor.updated',
          occurredAt: timestamp,
          payload: {'name': name},
        );
        return _loadSubcontractor(tx, current.id);
      }),
    );
  }

  @override
  Future<Subcontractor> transitionSubcontractor(
    TransitionSubcontractorCommand command,
  ) async {
    validateUuid(command.id, 'Taşeron kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(
      now,
      (database) => database.transaction((tx) async {
        final current = await _loadSubcontractor(tx, command.id);
        _requireRevision(current.revision, command.expectedRevision);
        if (current.isActive != command.archive) return current;
        if (command.archive && current.activePersonCount > 0) {
          throw const AgendaValidationFailure(
            'Aktif personeli bulunan taşeron pasifleştirilemez. Önce personeli taşıyın veya pasifleştirin.',
          );
        }
        final status = command.archive
            ? WorkforceRecordStatus.archived
            : WorkforceRecordStatus.active;
        final changed = await tx.update(
          'subcontractors',
          {
            'status': status.storageValue,
            'archived_at': command.archive ? timestamp : null,
            'revision': current.revision + 1,
            'updated_at': timestamp,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [current.id, current.revision],
        );
        if (changed != 1) throw _staleFailure();
        await _insertWorkforceEvent(
          tx,
          id: command.eventId,
          type: 'subcontractor',
          aggregateId: current.id,
          projectId: current.projectId,
          eventType: command.archive
              ? 'subcontractor.archived'
              : 'subcontractor.reopened',
          occurredAt: timestamp,
          payload: const {},
        );
        return _loadSubcontractor(tx, current.id);
      }),
    );
  }

  @override
  Future<List<WorkforceTeam>> listTeams(
    String projectId, {
    String? subcontractorId,
    bool includeArchived = false,
  }) async {
    validateUuid(projectId, 'Proje kimliği');
    if (subcontractorId != null) {
      validateUuid(subcontractorId, 'Taşeron kimliği');
    }
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final where = <String>['t.project_id = ?'];
      final args = <Object?>[projectId];
      if (subcontractorId != null) {
        where.add('t.subcontractor_id = ?');
        args.add(subcontractorId);
      }
      if (!includeArchived) {
        where.add("t.status = 'active'");
        where.add("s.status = 'active'");
      }
      final rows = await database.rawQuery('''
        SELECT t.*, s.name AS subcontractor_name,
          (SELECT count(*) FROM workforce_members m
            WHERE m.team_id = t.id AND m.is_active = 1)
            AS active_person_count
        FROM workforce_teams t
        JOIN subcontractors s ON s.id = t.subcontractor_id
        WHERE ${where.join(' AND ')}
        ORDER BY s.name_normalized ASC, t.name_normalized ASC, t.id ASC
      ''', args);
      return rows.map(_teamFromRow).toList(growable: false);
    });
  }

  @override
  Future<WorkforceTeam> createTeam(CreateWorkforceTeamCommand command) async {
    validateUuid(command.id, 'Ekip kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    validateUuid(command.subcontractorId, 'Taşeron kimliği');
    final name = requiredTrimmed(command.name, 'Ekip adı', maxLength: 200);
    final lead = optionalTrimmed(
      command.leadName,
      'Ekip sorumlusu',
      maxLength: 200,
    );
    final note = optionalTrimmed(command.note, 'Not', maxLength: 1000);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(
      now,
      (database) => database.transaction((tx) async {
        final subcontractor = await _loadSubcontractor(
          tx,
          command.subcontractorId,
        );
        if (subcontractor.projectId != command.projectId ||
            !subcontractor.isActive) {
          throw const AgendaValidationFailure(
            'Ekip yalnız aktif ve aynı projedeki taşerona bağlanabilir.',
          );
        }
        final existing = await tx.query(
          'workforce_teams',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final value = await _loadTeam(tx, command.id);
          if (value.projectId != command.projectId ||
              value.subcontractorId != command.subcontractorId ||
              value.name != name ||
              value.leadName != lead ||
              value.note != note) {
            throw const AgendaValidationFailure(
              'Ekip kimliği başka bir içerikle kullanılıyor.',
            );
          }
          return value;
        }
        await tx.insert('workforce_teams', {
          'id': command.id,
          'project_id': command.projectId,
          'subcontractor_id': command.subcontractorId,
          'name': name,
          'name_normalized': _normalizeRegistryName(name),
          'lead_name': lead,
          'note': note,
          'status': WorkforceRecordStatus.active.storageValue,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        await _insertWorkforceEvent(
          tx,
          id: command.eventId,
          type: 'team',
          aggregateId: command.id,
          projectId: command.projectId,
          eventType: 'team.created',
          occurredAt: timestamp,
          payload: {'subcontractor_id': command.subcontractorId, 'name': name},
        );
        return _loadTeam(tx, command.id);
      }),
    );
  }

  @override
  Future<WorkforceTeam> updateTeam(UpdateWorkforceTeamCommand command) async {
    validateUuid(command.id, 'Ekip kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final name = requiredTrimmed(command.name, 'Ekip adı', maxLength: 200);
    final lead = optionalTrimmed(
      command.leadName,
      'Ekip sorumlusu',
      maxLength: 200,
    );
    final note = optionalTrimmed(command.note, 'Not', maxLength: 1000);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(
      now,
      (database) => database.transaction((tx) async {
        final current = await _loadTeam(tx, command.id);
        _requireRevision(current.revision, command.expectedRevision);
        if (current.name == name &&
            current.leadName == lead &&
            current.note == note) {
          return current;
        }
        final changed = await tx.update(
          'workforce_teams',
          {
            'name': name,
            'name_normalized': _normalizeRegistryName(name),
            'lead_name': lead,
            'note': note,
            'revision': current.revision + 1,
            'updated_at': timestamp,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [current.id, current.revision],
        );
        if (changed != 1) throw _staleFailure();
        await tx.update(
          'workforce_members',
          {'team_name': name, 'updated_at': timestamp},
          where: 'team_id = ?',
          whereArgs: [current.id],
        );
        await _insertWorkforceEvent(
          tx,
          id: command.eventId,
          type: 'team',
          aggregateId: current.id,
          projectId: current.projectId,
          eventType: 'team.updated',
          occurredAt: timestamp,
          payload: {'name': name},
        );
        return _loadTeam(tx, current.id);
      }),
    );
  }

  @override
  Future<WorkforceTeam> transitionTeam(
    TransitionWorkforceTeamCommand command,
  ) async {
    validateUuid(command.id, 'Ekip kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(
      now,
      (database) => database.transaction((tx) async {
        final current = await _loadTeam(tx, command.id);
        _requireRevision(current.revision, command.expectedRevision);
        if (current.isActive != command.archive) return current;
        if (command.archive && current.activePersonCount > 0) {
          throw const AgendaValidationFailure(
            'Aktif personeli bulunan ekip pasifleştirilemez.',
          );
        }
        if (!command.archive) {
          final subcontractor = await _loadSubcontractor(
            tx,
            current.subcontractorId,
          );
          if (!subcontractor.isActive) {
            throw const AgendaValidationFailure(
              'Ekip yeniden açılmadan önce taşeron yeniden açılmalıdır.',
            );
          }
        }
        final changed = await tx.update(
          'workforce_teams',
          {
            'status': command.archive ? 'archived' : 'active',
            'archived_at': command.archive ? timestamp : null,
            'revision': current.revision + 1,
            'updated_at': timestamp,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [current.id, current.revision],
        );
        if (changed != 1) throw _staleFailure();
        await _insertWorkforceEvent(
          tx,
          id: command.eventId,
          type: 'team',
          aggregateId: current.id,
          projectId: current.projectId,
          eventType: command.archive ? 'team.archived' : 'team.reopened',
          occurredAt: timestamp,
          payload: const {},
        );
        return _loadTeam(tx, current.id);
      }),
    );
  }

  @override
  Future<List<ActiveTeamCount>> listActiveTeamCounts(String projectId) async {
    final teams = await listTeams(projectId);
    return teams
        .map(
          (team) => ActiveTeamCount(
            teamId: team.id,
            teamName: team.name,
            subcontractorName: team.subcontractorName,
            activePersonCount: team.activePersonCount,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<WorkforcePersonDetail> getPersonDetail(String memberId) async {
    validateUuid(memberId, 'Personel kimliği');
    final now = _readClockOnce();
    final today = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
    return _withDatabase(now, (database) async {
      final memberRows = await database.rawQuery(
        '''
        SELECT m.*, s.name AS subcontractor_name,
          t.name AS registry_team_name
        FROM workforce_members m
        JOIN subcontractors s ON s.id = m.subcontractor_id
        JOIN workforce_teams t ON t.id = m.team_id
        WHERE m.id = ? LIMIT 1
      ''',
        [memberId],
      );
      if (memberRows.isEmpty) {
        throw const AgendaValidationFailure('Personel bulunamadı.');
      }
      final complianceRows = await database.query(
        'workforce_compliance_records',
        where: 'workforce_member_id = ? AND archived_at IS NULL',
        whereArgs: [memberId],
        orderBy: 'document_type ASC, expiry_date ASC, id ASC',
      );
      final archivedComplianceRows = await database.query(
        'workforce_compliance_records',
        where: 'workforce_member_id = ? AND archived_at IS NOT NULL',
        whereArgs: [memberId],
        orderBy: 'archived_at DESC, id ASC',
      );
      final member = _memberFromRow(memberRows.single);
      final eventRows = await database.rawQuery(
        '''
        SELECT e.id, e.aggregate_id, e.project_id, e.sequence,
          e.event_type, e.occurred_at, e.payload_json
        FROM workforce_events e
        JOIN workforce_compliance_records c ON c.id = e.aggregate_id
        WHERE e.aggregate_type = 'compliance'
          AND c.workforce_member_id = ? AND e.project_id = ?
        ORDER BY e.aggregate_id ASC, e.sequence ASC
        ''',
        [memberId, member.projectId],
      );
      final complianceEvents = <WorkforceComplianceEvent>[];
      for (final row in eventRows) {
        final payload = jsonDecode(row['payload_json']! as String);
        if (payload is! Map || payload['member_id'] != memberId) continue;
        complianceEvents.add(
          WorkforceComplianceEvent(
            id: row['id']! as String,
            recordId: row['aggregate_id']! as String,
            memberId: memberId,
            projectId: row['project_id']! as String,
            sequence: row['sequence']! as int,
            eventType: row['event_type']! as String,
            occurredAt: row['occurred_at']! as String,
          ),
        );
      }
      final ppeRows = await database.query(
        'workforce_ppe_assignments',
        where: 'workforce_member_id = ?',
        whereArgs: [memberId],
        orderBy: 'assigned_date DESC, created_at DESC, id ASC',
      );
      final attendanceTotalRows = await database.rawQuery(
        '''
        SELECT COALESCE(SUM(
          CASE e.result
            WHEN 'full_day' THEN 1.0
            WHEN 'half_day' THEN 0.5
            ELSE 0.0
          END
        ), 0.0) AS person_day_equivalent
        FROM attendance_entries e
        WHERE e.workforce_member_id = ? AND e.removed_at IS NULL
        ''',
        [memberId],
      );
      final attendanceRows = await database.rawQuery(
        '''
        SELECT e.attendance_day_id, d.local_date, d.status, e.result
        FROM attendance_entries e
        JOIN attendance_days d ON d.id = e.attendance_day_id
        WHERE e.workforce_member_id = ? AND e.removed_at IS NULL
        ORDER BY d.local_date DESC, e.updated_at DESC, e.id ASC
        LIMIT 30
        ''',
        [memberId],
      );
      final compliance = complianceRows
          .map((row) => _complianceFromRow(row, today))
          .toList(growable: false);
      final ppe = ppeRows.map(_ppeFromRow).toList(growable: false);
      return WorkforcePersonDetail(
        member: member,
        compliance: compliance,
        archivedCompliance: archivedComplianceRows
            .map((row) => _complianceFromRow(row, today))
            .toList(growable: false),
        complianceEvents: List.unmodifiable(complianceEvents),
        ppeAssignments: ppe,
        missingComplianceCount: compliance
            .where((item) => item.readStatus == ComplianceReadStatus.missing)
            .length,
        validComplianceCount: compliance
            .where((item) => item.readStatus == ComplianceReadStatus.valid)
            .length,
        expiringComplianceCount: compliance
            .where((item) => item.readStatus == ComplianceReadStatus.expiring)
            .length,
        expiredComplianceCount: compliance
            .where((item) => item.readStatus == ComplianceReadStatus.expired)
            .length,
        activePpeCount: ppe
            .where((item) => item.status == PpeAssignmentStatus.assigned)
            .fold(0, (sum, item) => sum + item.quantity),
        attendanceSummary: WorkforceAttendanceSummary(
          personDayEquivalentTotal:
              (attendanceTotalRows.single['person_day_equivalent']! as num)
                  .toDouble(),
          recentDays: attendanceRows
              .map(
                (row) => WorkforceAttendanceDay(
                  attendanceDayId: row['attendance_day_id']! as String,
                  localDate: row['local_date']! as String,
                  dayStatus: AttendanceDayStatus.fromStorage(
                    row['status']! as String,
                  ),
                  result: AttendanceResult.fromStorage(
                    row['result']! as String,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      );
    });
  }

  @override
  Future<WorkforceComplianceRecord> saveComplianceRecord(
    SaveComplianceRecordCommand command,
  ) async {
    validateUuid(command.id, 'İSG kayıt kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.memberId, 'Personel kimliği');
    if (command.expectedRevision < 0) {
      throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
    }
    final number = optionalTrimmed(
      command.documentNumber,
      'Belge numarası',
      maxLength: 160,
    );
    final issued = _optionalLocalDate(command.issuedDate, 'Düzenlenme tarihi');
    final expiry = _optionalLocalDate(command.expiryDate, 'Geçerlilik tarihi');
    if (issued != null && expiry != null && expiry.compareTo(issued) < 0) {
      throw const AgendaValidationFailure(
        'Geçerlilik tarihi düzenlenme tarihinden önce olamaz.',
      );
    }
    final note = optionalTrimmed(command.note, 'Not', maxLength: 1000);
    final reason = optionalTrimmed(command.reason, 'Gerekçe', maxLength: 1000);
    if ((command.sourceStatus == ComplianceSourceStatus.notApplicable ||
            command.sourceStatus == ComplianceSourceStatus.exception) &&
        reason == null) {
      throw const AgendaValidationFailure(
        'Uygulanamaz veya istisna kaydı için gerekçe zorunludur.',
      );
    }
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    final today = CseTimeCodec.istanbulDayKey(timestamp);
    return _withDatabase(
      now,
      (database) => database.transaction((tx) async {
        final member = await _requireMember(tx, command.memberId);
        final rows = await tx.query(
          'workforce_compliance_records',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        final values = <String, Object?>{
          'document_type': command.documentType.storageValue,
          'document_number': number,
          'issued_date': issued,
          'expiry_date': expiry,
          'source_status': command.sourceStatus.storageValue,
          'note': note,
          'reason': reason,
        };
        if (rows.isEmpty) {
          if (command.expectedRevision != 0) throw _staleFailure();
          await tx.insert('workforce_compliance_records', {
            'id': command.id,
            'workforce_member_id': command.memberId,
            ...values,
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
          });
          await _insertWorkforceEvent(
            tx,
            id: command.eventId,
            type: 'compliance',
            aggregateId: command.id,
            projectId: member.projectId,
            eventType: 'compliance.created',
            occurredAt: timestamp,
            payload: {'member_id': member.id},
          );
        } else {
          final current = _complianceFromRow(rows.single, today);
          if (current.memberId != command.memberId) {
            throw const AgendaValidationFailure(
              'İSG kayıt kimliği başka personele bağlıdır.',
            );
          }
          _requireRevision(current.revision, command.expectedRevision);
          if (_complianceMatches(current, values)) return current;
          final changed = await tx.update(
            'workforce_compliance_records',
            {
              ...values,
              'revision': current.revision + 1,
              'updated_at': timestamp,
            },
            where: 'id = ? AND revision = ?',
            whereArgs: [current.id, current.revision],
          );
          if (changed != 1) throw _staleFailure();
          await _insertWorkforceEvent(
            tx,
            id: command.eventId,
            type: 'compliance',
            aggregateId: command.id,
            projectId: member.projectId,
            eventType: 'compliance.updated',
            occurredAt: timestamp,
            payload: {'member_id': member.id},
          );
        }
        final saved = await tx.query(
          'workforce_compliance_records',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        return _complianceFromRow(saved.single, today);
      }),
    );
  }

  @override
  Future<WorkforceComplianceRecord> archiveComplianceRecord(
    ArchiveComplianceRecordCommand command,
  ) async {
    validateUuid(command.id, 'İSG kayıt kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    final today = CseTimeCodec.istanbulDayKey(timestamp);
    return _withDatabase(
      now,
      (database) => database.transaction((tx) async {
        final rows = await tx.query(
          'workforce_compliance_records',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw const AgendaValidationFailure('İSG kaydı bulunamadı.');
        }
        final current = _complianceFromRow(rows.single, today);
        _requireRevision(current.revision, command.expectedRevision);
        if (current.archivedAt != null) return current;
        final member = await _requireMember(tx, current.memberId);
        final changed = await tx.update(
          'workforce_compliance_records',
          {
            'archived_at': timestamp,
            'updated_at': timestamp,
            'revision': current.revision + 1,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [current.id, current.revision],
        );
        if (changed != 1) throw _staleFailure();
        await _insertWorkforceEvent(
          tx,
          id: command.eventId,
          type: 'compliance',
          aggregateId: current.id,
          projectId: member.projectId,
          eventType: 'compliance.archived',
          occurredAt: timestamp,
          payload: {'member_id': member.id},
        );
        final saved = await tx.query(
          'workforce_compliance_records',
          where: 'id = ?',
          whereArgs: [current.id],
          limit: 1,
        );
        return _complianceFromRow(saved.single, today);
      }),
    );
  }

  @override
  Future<WorkforcePpeAssignment> savePpeAssignment(
    SavePpeAssignmentCommand command,
  ) async {
    validateUuid(command.id, 'KKD zimmet kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.memberId, 'Personel kimliği');
    if (command.expectedRevision < 0 || command.quantity < 1) {
      throw const AgendaValidationFailure(
        'KKD adet veya revision geçersizdir.',
      );
    }
    final ppeType = requiredTrimmed(
      command.ppeType,
      'KKD türü',
      maxLength: 160,
    );
    final assigned = _requiredLocalDate(command.assignedDate, 'Zimmet tarihi');
    final returned = _optionalLocalDate(command.returnedDate, 'İade tarihi');
    if (command.status == PpeAssignmentStatus.returned && returned == null) {
      throw const AgendaValidationFailure(
        'İade edilen KKD için tarih zorunludur.',
      );
    }
    final brand = optionalTrimmed(
      command.brandModel,
      'Marka/model',
      maxLength: 200,
    );
    final size = optionalTrimmed(command.size, 'Beden', maxLength: 80);
    final serial = optionalTrimmed(
      command.serialTag,
      'Seri/etiket',
      maxLength: 160,
    );
    final note = optionalTrimmed(command.note, 'Not', maxLength: 1000);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(
      now,
      (database) => database.transaction((tx) async {
        final member = await _requireMember(tx, command.memberId);
        final rows = await tx.query(
          'workforce_ppe_assignments',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        final values = <String, Object?>{
          'ppe_type': ppeType,
          'brand_model': brand,
          'size': size,
          'serial_tag': serial,
          'quantity': command.quantity,
          'assigned_date': assigned,
          'status': command.status.storageValue,
          'returned_date': returned,
          'note': note,
          'archived_at': command.status == PpeAssignmentStatus.archived
              ? timestamp
              : null,
        };
        if (rows.isEmpty) {
          if (command.expectedRevision != 0) throw _staleFailure();
          await tx.insert('workforce_ppe_assignments', {
            'id': command.id,
            'workforce_member_id': command.memberId,
            ...values,
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
          });
          await _insertWorkforceEvent(
            tx,
            id: command.eventId,
            type: 'ppe',
            aggregateId: command.id,
            projectId: member.projectId,
            eventType: 'ppe.created',
            occurredAt: timestamp,
            payload: {
              'member_id': member.id,
              'status': command.status.storageValue,
            },
          );
        } else {
          final current = _ppeFromRow(rows.single);
          if (current.memberId != command.memberId) {
            throw const AgendaValidationFailure(
              'KKD zimmet kimliği başka personele bağlıdır.',
            );
          }
          _requireRevision(current.revision, command.expectedRevision);
          if (_ppeMatches(current, values)) return current;
          final changed = await tx.update(
            'workforce_ppe_assignments',
            {
              ...values,
              'revision': current.revision + 1,
              'updated_at': timestamp,
            },
            where: 'id = ? AND revision = ?',
            whereArgs: [current.id, current.revision],
          );
          if (changed != 1) throw _staleFailure();
          await _insertWorkforceEvent(
            tx,
            id: command.eventId,
            type: 'ppe',
            aggregateId: command.id,
            projectId: member.projectId,
            eventType: 'ppe.updated',
            occurredAt: timestamp,
            payload: {
              'member_id': member.id,
              'status': command.status.storageValue,
            },
          );
        }
        final saved = await tx.query(
          'workforce_ppe_assignments',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        return _ppeFromRow(saved.single);
      }),
    );
  }

  @override
  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  }) async {
    validateUuid(projectId, 'Proje kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.rawQuery(
        '''
        SELECT m.*, s.name AS subcontractor_name,
          t.name AS registry_team_name
        FROM workforce_members m
        JOIN subcontractors s ON s.id = m.subcontractor_id
        JOIN workforce_teams t ON t.id = m.team_id
        WHERE m.project_id = ?
          ${includeInactive ? '' : 'AND m.is_active = 1'}
        ORDER BY s.name_normalized ASC, t.name_normalized ASC,
          m.full_name COLLATE NOCASE ASC, m.id ASC
      ''',
        [projectId],
      );
      return rows.map(_memberFromRow).toList(growable: false);
    });
  }

  @override
  Future<WorkforceMember> createMember(
    CreateWorkforceMemberCommand command,
  ) async {
    validateUuid(command.id, 'Personel kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    final fullName = requiredTrimmed(
      command.fullName,
      'Personel adı',
      maxLength: 200,
    );
    final requestedTeamName = requiredTrimmed(
      command.teamName,
      'Ekip',
      maxLength: 200,
    );
    final roleName = requiredTrimmed(
      command.roleName,
      'Meslek/pozisyon',
      maxLength: 160,
    );
    final personnelCode = optionalTrimmed(
      command.personnelCode,
      'Personel kodu',
      maxLength: 80,
    );
    final phone = optionalTrimmed(command.phone, 'Telefon', maxLength: 80);
    final address = optionalTrimmed(command.address, 'Adres', maxLength: 1000);
    final startedOn = _optionalLocalDate(
      command.startedOn,
      'İşe başlama tarihi',
    );
    final note = optionalTrimmed(command.note, 'Not', maxLength: 1000);
    if (command.eventId != null) {
      validateUuid(command.eventId!, 'Event kimliği');
    }
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        await _requireProject(transaction, command.projectId);
        final registry = await _resolveRegistrySelection(
          transaction,
          projectId: command.projectId,
          requestedTeamName: requestedTeamName,
          subcontractorId: command.subcontractorId,
          teamId: command.teamId,
          timestamp: timestamp,
        );
        final existing = await transaction.query(
          'workforce_members',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final member = _memberFromRow(existing.single);
          if (member.projectId != command.projectId ||
              member.fullName != fullName ||
              member.teamId != registry.team.id ||
              member.subcontractorId != registry.subcontractor.id ||
              member.roleName != roleName ||
              member.personnelCode != personnelCode ||
              member.phone != phone ||
              member.address != address ||
              member.startedOn != startedOn ||
              member.note != note) {
            throw const AgendaValidationFailure(
              'Personel kimliği başka bir içerikle kullanılıyor.',
            );
          }
          return member;
        }
        await _requireUniquePersonnelCode(
          transaction,
          projectId: command.projectId,
          personnelCode: personnelCode,
        );
        await transaction.insert('workforce_members', {
          'id': command.id,
          'project_id': command.projectId,
          'full_name': fullName,
          'team_name': registry.team.name,
          'role_name': roleName,
          'personnel_code': personnelCode,
          'subcontractor_id': registry.subcontractor.id,
          'team_id': registry.team.id,
          'phone': phone,
          'address': address,
          'started_on': startedOn,
          'note': note,
          'is_active': 1,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        await _insertWorkforceEvent(
          transaction,
          id: command.eventId ?? _stableUuid('person-created:${command.id}'),
          type: 'person',
          aggregateId: command.id,
          projectId: command.projectId,
          eventType: 'person.created',
          occurredAt: timestamp,
          payload: {
            'subcontractor_id': registry.subcontractor.id,
            'team_id': registry.team.id,
          },
        );
        return _memberFromRow({
          'id': command.id,
          'project_id': command.projectId,
          'full_name': fullName,
          'team_name': registry.team.name,
          'registry_team_name': registry.team.name,
          'subcontractor_id': registry.subcontractor.id,
          'subcontractor_name': registry.subcontractor.name,
          'team_id': registry.team.id,
          'role_name': roleName,
          'personnel_code': personnelCode,
          'phone': phone,
          'address': address,
          'started_on': startedOn,
          'note': note,
          'is_active': 1,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
          'archived_at': null,
        });
      });
    });
  }

  @override
  Future<WorkforceMember> updateMember(
    UpdateWorkforceMemberCommand command,
  ) async {
    validateUuid(command.id, 'Personel kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final fullName = requiredTrimmed(
      command.fullName,
      'Personel adı',
      maxLength: 200,
    );
    final requestedTeamName = requiredTrimmed(
      command.teamName,
      'Ekip',
      maxLength: 200,
    );
    final roleName = requiredTrimmed(
      command.roleName,
      'Meslek/pozisyon',
      maxLength: 160,
    );
    final personnelCode = optionalTrimmed(
      command.personnelCode,
      'Personel kodu',
      maxLength: 80,
    );
    final phone = optionalTrimmed(command.phone, 'Telefon', maxLength: 80);
    final requestedAddress = optionalTrimmed(
      command.address,
      'Adres',
      maxLength: 1000,
    );
    final requestedStartedOn = _optionalLocalDate(
      command.startedOn,
      'İşe başlama tarihi',
    );
    final note = optionalTrimmed(command.note, 'Not', maxLength: 1000);
    if (command.eventId != null) {
      validateUuid(command.eventId!, 'Event kimliği');
    }
    final now = _readClockOnce();
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final member = await _requireMember(transaction, command.id);
        _requireRevision(member.revision, command.expectedRevision);
        final address = command.replaceAddress
            ? requestedAddress
            : member.address;
        final startedOn = command.replaceStartedOn
            ? requestedStartedOn
            : member.startedOn;
        final registry = await _resolveRegistrySelection(
          transaction,
          projectId: member.projectId,
          requestedTeamName: requestedTeamName,
          subcontractorId: command.subcontractorId ?? member.subcontractorId,
          teamId: command.teamId ?? member.teamId,
          timestamp: CseTimeCodec.encodeUtc(now),
        );
        if (member.fullName == fullName &&
            member.teamId == registry.team.id &&
            member.subcontractorId == registry.subcontractor.id &&
            member.roleName == roleName &&
            member.personnelCode == personnelCode &&
            member.phone == phone &&
            member.address == address &&
            member.startedOn == startedOn &&
            member.note == note) {
          return member;
        }
        await _requireUniquePersonnelCode(
          transaction,
          projectId: member.projectId,
          personnelCode: personnelCode,
          excludingId: member.id,
        );
        final timestamp = CseTimeCodec.encodeUtc(now);
        final count = await transaction.update(
          'workforce_members',
          {
            'full_name': fullName,
            'team_name': registry.team.name,
            'subcontractor_id': registry.subcontractor.id,
            'team_id': registry.team.id,
            'role_name': roleName,
            'personnel_code': personnelCode,
            'phone': phone,
            'address': address,
            'started_on': startedOn,
            'note': note,
            'revision': member.revision + 1,
            'updated_at': timestamp,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [member.id, member.revision],
        );
        if (count != 1) throw _staleFailure();
        await _insertWorkforceEvent(
          transaction,
          id:
              command.eventId ??
              _stableUuid('person-updated:${member.id}:${member.revision + 1}'),
          type: 'person',
          aggregateId: member.id,
          projectId: member.projectId,
          eventType: 'person.updated',
          occurredAt: timestamp,
          payload: {
            'subcontractor_id': registry.subcontractor.id,
            'team_id': registry.team.id,
          },
        );
        return _memberFromRow({
          'id': member.id,
          'project_id': member.projectId,
          'full_name': fullName,
          'team_name': registry.team.name,
          'registry_team_name': registry.team.name,
          'subcontractor_id': registry.subcontractor.id,
          'subcontractor_name': registry.subcontractor.name,
          'team_id': registry.team.id,
          'role_name': roleName,
          'personnel_code': personnelCode,
          'phone': phone,
          'address': address,
          'started_on': startedOn,
          'note': note,
          'is_active': member.isActive ? 1 : 0,
          'revision': member.revision + 1,
          'created_at': member.createdAt,
          'updated_at': timestamp,
          'archived_at': member.archivedAt,
        });
      });
    });
  }

  @override
  Future<WorkforceMember> archiveMember(
    ArchiveWorkforceMemberCommand command,
  ) async {
    validateUuid(command.id, 'Personel kimliği');
    _validateExpectedRevision(command.expectedRevision);
    if (command.eventId != null) {
      validateUuid(command.eventId!, 'Event kimliği');
    }
    final now = _readClockOnce();
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final member = await _requireMember(transaction, command.id);
        _requireRevision(member.revision, command.expectedRevision);
        if (member.isActive != command.archive) return member;
        if (!command.archive) {
          final subcontractor = await _loadSubcontractor(
            transaction,
            member.subcontractorId!,
          );
          final team = await _loadTeam(transaction, member.teamId!);
          if (!subcontractor.isActive || !team.isActive) {
            throw const AgendaValidationFailure(
              'Personel yeniden açılmadan önce taşeron ve ekip yeniden açılmalıdır.',
            );
          }
        }
        final timestamp = CseTimeCodec.encodeUtc(now);
        final count = await transaction.update(
          'workforce_members',
          {
            'is_active': command.archive ? 0 : 1,
            'archived_at': command.archive ? timestamp : null,
            'updated_at': timestamp,
            'revision': member.revision + 1,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [member.id, member.revision],
        );
        if (count != 1) throw _staleFailure();
        await _insertWorkforceEvent(
          transaction,
          id:
              command.eventId ??
              _stableUuid(
                'person-${command.archive ? 'archived' : 'reopened'}:'
                '${member.id}:${member.revision + 1}',
              ),
          type: 'person',
          aggregateId: member.id,
          projectId: member.projectId,
          eventType: command.archive ? 'person.archived' : 'person.reopened',
          occurredAt: timestamp,
          payload: const {},
        );
        return WorkforceMember(
          id: member.id,
          projectId: member.projectId,
          fullName: member.fullName,
          teamName: member.teamName,
          roleName: member.roleName,
          personnelCode: member.personnelCode,
          subcontractorId: member.subcontractorId,
          subcontractorName: member.subcontractorName,
          teamId: member.teamId,
          phone: member.phone,
          address: member.address,
          startedOn: member.startedOn,
          note: member.note,
          isActive: !command.archive,
          revision: member.revision + 1,
          createdAt: member.createdAt,
          updatedAt: timestamp,
          archivedAt: command.archive ? timestamp : null,
        );
      });
    });
  }

  @override
  Future<AttendanceDay> ensureDay(EnsureAttendanceDayCommand command) async {
    validateUuid(command.id, 'Puantaj günü kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    validateAttendanceDayKey(command.localDate);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final projectName = await _requireProject(
          transaction,
          command.projectId,
        );
        final byDate = await transaction.rawQuery(
          '''
          SELECT d.*, p.name AS project_name
          FROM attendance_days d
          JOIN projects p ON p.id = d.project_id
          WHERE d.project_id = ? AND d.local_date = ?
          LIMIT 1
          ''',
          [command.projectId, command.localDate],
        );
        if (byDate.isNotEmpty) return _dayFromRow(byDate.single);
        final byId = await transaction.query(
          'attendance_days',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        if (byId.isNotEmpty) {
          throw const AgendaValidationFailure(
            'Puantaj günü kimliği başka bir gün için kullanılıyor.',
          );
        }
        await transaction.insert('attendance_days', {
          'id': command.id,
          'project_id': command.projectId,
          'local_date': command.localDate,
          'status': AttendanceDayStatus.draft.storageValue,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        await beforeAttendanceEventInsert?.call(transaction);
        await transaction.insert('attendance_events', {
          'id': command.eventId,
          'attendance_day_id': command.id,
          'sequence': 1,
          'event_type': 'attendance_day.created',
          'occurred_at': timestamp,
          'payload_json': jsonEncode({
            'local_date': command.localDate,
            'project_id': command.projectId,
          }),
        });
        return AttendanceDay(
          id: command.id,
          projectId: command.projectId,
          projectName: projectName,
          localDate: command.localDate,
          status: AttendanceDayStatus.draft,
          generalNote: null,
          revision: 1,
          createdAt: timestamp,
          updatedAt: timestamp,
          completedAt: null,
        );
      });
    });
  }

  @override
  Future<AttendanceDayDetail> getDayDetail(String dayId) async {
    validateUuid(dayId, 'Puantaj günü kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) => _loadDetail(database, dayId));
  }

  @override
  Future<AttendanceDayDetail> saveRoster(
    SaveAttendanceRosterCommand command,
  ) async {
    validateUuid(command.dayId, 'Puantaj günü kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final normalized = _normalizeRosterValues(command.values);
    final normalizedNote = command.replaceGeneralNote
        ? optionalTrimmed(command.generalNote, 'Genel not')
        : null;
    final now = _readClockOnce();
    await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        if (await _isIdempotentEvent(
          transaction,
          command.eventId,
          command.dayId,
        )) {
          return;
        }
        final day = await _requireDay(transaction, command.dayId);
        _requireRevision(day.revision, command.expectedRevision);
        _requireDraft(day);
        final changes = <Map<String, Object?>>[];
        for (final value in normalized) {
          final member = await _requireMember(transaction, value.memberId);
          if (member.projectId != day.projectId) {
            throw const AgendaValidationFailure(
              'Personel seçilen Puantaj projesine ait değildir.',
            );
          }
          final existingRows = await transaction.query(
            'attendance_entries',
            where: 'attendance_day_id = ? AND workforce_member_id = ?',
            whereArgs: [day.id, member.id],
            limit: 1,
          );
          final timestamp = CseTimeCodec.encodeUtc(now);
          if (existingRows.isEmpty) {
            if (!member.isActive) {
              throw const AgendaValidationFailure(
                'Pasif personele yeni Puantaj kaydı eklenemez.',
              );
            }
            await transaction.insert('attendance_entries', {
              'id': value.entryId,
              'attendance_day_id': day.id,
              'workforce_member_id': member.id,
              'result': value.result.storageValue,
              'overtime_minutes': value.overtimeMinutes,
              'short_note': value.shortNote,
              'created_at': timestamp,
              'updated_at': timestamp,
            });
            changes.add({
              'entry_id': value.entryId,
              'member_id': member.id,
              'team_name': member.teamName,
              'before': null,
              'after': _entryPayload(value),
            });
            continue;
          }
          final existing = existingRows.single;
          if (existing['id'] != value.entryId) {
            throw const AgendaValidationFailure(
              'Puantaj entry kimliği mevcut personel kaydıyla eşleşmiyor.',
            );
          }
          final before = <String, Object?>{
            'result': existing['result'],
            'overtime_minutes': existing['overtime_minutes'],
            'short_note': existing['short_note'],
            'removed': existing['removed_at'] != null,
          };
          final unchanged =
              existing['result'] == value.result.storageValue &&
              existing['overtime_minutes'] == value.overtimeMinutes &&
              existing['short_note'] == value.shortNote &&
              existing['removed_at'] == null;
          if (unchanged) continue;
          await transaction.update(
            'attendance_entries',
            {
              'result': value.result.storageValue,
              'overtime_minutes': value.overtimeMinutes,
              'short_note': value.shortNote,
              'updated_at': timestamp,
              'removed_at': null,
            },
            where: 'id = ?',
            whereArgs: [value.entryId],
          );
          changes.add({
            'entry_id': value.entryId,
            'member_id': member.id,
            'team_name': member.teamName,
            'before': before,
            'after': _entryPayload(value),
          });
        }
        final noteChanged =
            command.replaceGeneralNote && day.generalNote != normalizedNote;
        if (changes.isEmpty && !noteChanged) return;
        final timestamp = CseTimeCodec.encodeUtc(now);
        final updateValues = <String, Object?>{
          'updated_at': timestamp,
          'revision': day.revision + 1,
        };
        if (command.replaceGeneralNote) {
          updateValues['general_note'] = normalizedNote;
        }
        final updated = await transaction.update(
          'attendance_days',
          updateValues,
          where: 'id = ? AND revision = ?',
          whereArgs: [day.id, day.revision],
        );
        if (updated != 1) throw _staleFailure();
        await _insertAttendanceEvent(
          transaction,
          id: command.eventId,
          dayId: day.id,
          eventType: changes.isEmpty
              ? 'attendance_day.note_updated'
              : 'attendance_entry.upserted',
          occurredAt: timestamp,
          payload: {
            'changes': changes,
            if (noteChanged)
              'general_note': {
                'before': day.generalNote,
                'after': normalizedNote,
              },
            'revision': day.revision + 1,
          },
        );
      });
    });
    return getDayDetail(command.dayId);
  }

  @override
  Future<AttendanceDayDetail> markFullDay(
    MarkAttendanceFullCommand command,
  ) async {
    validateUuid(command.dayId, 'Puantaj günü kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final team = optionalTrimmed(command.teamName, 'Ekip/taşeron');
    if (command.teamId != null) validateUuid(command.teamId!, 'Ekip kimliği');
    final detail = await getDayDetail(command.dayId);
    final members = await listMembers(detail.day.projectId);
    final selected = members
        .where(
          (member) => command.teamId != null
              ? member.teamId == command.teamId
              : team == null || member.teamName == team,
        )
        .toList(growable: false);
    if (selected.isEmpty) {
      throw const AgendaValidationFailure(
        'Tam gün işaretlenecek aktif personel bulunamadı.',
      );
    }
    final existingByMember = {
      for (final entry in detail.entries) entry.memberId: entry,
    };
    final values = <AttendanceRosterValue>[];
    for (final member in selected) {
      final entryId =
          existingByMember[member.id]?.id ??
          command.entryIdsByMember[member.id];
      if (entryId == null) {
        throw const AgendaValidationFailure(
          'Hızlı işlem entry kimliği eksiktir.',
        );
      }
      values.add(
        AttendanceRosterValue(
          entryId: entryId,
          memberId: member.id,
          result: AttendanceResult.fullDay,
          overtimeMinutes: 0,
        ),
      );
    }
    return saveRoster(
      SaveAttendanceRosterCommand(
        dayId: command.dayId,
        eventId: command.eventId,
        expectedRevision: command.expectedRevision,
        values: values,
      ),
    );
  }

  @override
  Future<AttendanceDayDetail> removeEntry(
    RemoveAttendanceEntryCommand command,
  ) async {
    validateUuid(command.dayId, 'Puantaj günü kimliği');
    validateUuid(command.entryId, 'Puantaj entry kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final now = _readClockOnce();
    await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        if (await _isIdempotentEvent(
          transaction,
          command.eventId,
          command.dayId,
        )) {
          return;
        }
        final day = await _requireDay(transaction, command.dayId);
        _requireRevision(day.revision, command.expectedRevision);
        _requireDraft(day);
        final rows = await transaction.query(
          'attendance_entries',
          where: 'id = ? AND attendance_day_id = ?',
          whereArgs: [command.entryId, day.id],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw const AgendaValidationFailure('Puantaj entry bulunamadı.');
        }
        if (rows.single['removed_at'] != null) return;
        final timestamp = CseTimeCodec.encodeUtc(now);
        await transaction.update(
          'attendance_entries',
          {'removed_at': timestamp, 'updated_at': timestamp},
          where: 'id = ?',
          whereArgs: [command.entryId],
        );
        await _advanceDayRevision(transaction, day, timestamp);
        await _insertAttendanceEvent(
          transaction,
          id: command.eventId,
          dayId: day.id,
          eventType: 'attendance_entry.removed',
          occurredAt: timestamp,
          payload: {
            'entry_id': command.entryId,
            'member_id': rows.single['workforce_member_id'],
            'before': {
              'result': rows.single['result'],
              'overtime_minutes': rows.single['overtime_minutes'],
              'short_note': rows.single['short_note'],
            },
            'revision': day.revision + 1,
          },
        );
      });
    });
    return getDayDetail(command.dayId);
  }

  @override
  Future<AttendanceDayDetail> updateNote(
    UpdateAttendanceNoteCommand command,
  ) async {
    validateUuid(command.dayId, 'Puantaj günü kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final note = optionalTrimmed(command.generalNote, 'Genel not');
    final now = _readClockOnce();
    await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        if (await _isIdempotentEvent(
          transaction,
          command.eventId,
          command.dayId,
        )) {
          return;
        }
        final day = await _requireDay(transaction, command.dayId);
        _requireRevision(day.revision, command.expectedRevision);
        _requireDraft(day);
        if (day.generalNote == note) return;
        final timestamp = CseTimeCodec.encodeUtc(now);
        await transaction.update(
          'attendance_days',
          {
            'general_note': note,
            'updated_at': timestamp,
            'revision': day.revision + 1,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [day.id, day.revision],
        );
        await _insertAttendanceEvent(
          transaction,
          id: command.eventId,
          dayId: day.id,
          eventType: 'attendance_day.note_updated',
          occurredAt: timestamp,
          payload: {
            'before': day.generalNote,
            'after': note,
            'revision': day.revision + 1,
          },
        );
      });
    });
    return getDayDetail(command.dayId);
  }

  @override
  Future<AttendanceDayDetail> transitionDay(
    TransitionAttendanceDayCommand command,
  ) async {
    validateUuid(command.dayId, 'Puantaj günü kimliği');
    validateUuid(command.dayEventId, 'Puantaj event kimliği');
    validateUuid(command.reminderEventId, 'Hatırlatıcı event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final now = _readClockOnce();
    await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        if (await _isIdempotentEvent(
          transaction,
          command.dayEventId,
          command.dayId,
        )) {
          return;
        }
        final day = await _requireDay(transaction, command.dayId);
        _requireRevision(day.revision, command.expectedRevision);
        final timestamp = CseTimeCodec.encodeUtc(now);
        late final AttendanceDayStatus nextStatus;
        late final String eventType;
        final payload = <String, Object?>{
          'before_status': day.status.storageValue,
          'revision': day.revision + 1,
        };
        switch (command.transition) {
          case AttendanceTransition.complete:
            _requireDraft(day);
            nextStatus = AttendanceDayStatus.completed;
            eventType = 'attendance_day.completed';
          case AttendanceTransition.noWork:
            _requireDraft(day);
            final entries = await transaction.query(
              'attendance_entries',
              columns: ['id'],
              where: 'attendance_day_id = ? AND removed_at IS NULL',
              whereArgs: [day.id],
              orderBy: 'id ASC',
            );
            for (final entry in entries) {
              await transaction.update(
                'attendance_entries',
                {'removed_at': timestamp, 'updated_at': timestamp},
                where: 'id = ?',
                whereArgs: [entry['id']],
              );
            }
            payload['cleared_entry_ids'] = entries
                .map((entry) => entry['id'])
                .toList(growable: false);
            nextStatus = AttendanceDayStatus.noWork;
            eventType = 'attendance_day.no_work';
          case AttendanceTransition.reopen:
            if (day.status == AttendanceDayStatus.draft) {
              throw const AgendaValidationFailure(
                'Puantaj günü zaten taslak durumundadır.',
              );
            }
            nextStatus = AttendanceDayStatus.draft;
            eventType = 'attendance_day.reopened';
        }
        payload['after_status'] = nextStatus.storageValue;
        final count = await transaction.update(
          'attendance_days',
          {
            'status': nextStatus.storageValue,
            'updated_at': timestamp,
            'completed_at': nextStatus == AttendanceDayStatus.draft
                ? null
                : timestamp,
            'revision': day.revision + 1,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [day.id, day.revision],
        );
        if (count != 1) throw _staleFailure();
        await beforeAttendanceEventInsert?.call(transaction);
        await _insertAttendanceEvent(
          transaction,
          id: command.dayEventId,
          dayId: day.id,
          eventType: eventType,
          occurredAt: timestamp,
          payload: payload,
          invokeHook: false,
        );
        final links = await transaction.query(
          'attendance_day_reminder_links',
          where: 'attendance_day_id = ?',
          whereArgs: [day.id],
          limit: 1,
        );
        if (links.isNotEmpty) {
          final link = links.single;
          if (nextStatus == AttendanceDayStatus.draft) {
            await _reopenLinkedReminder(
              transaction,
              reminderId: link['reminder_id']! as String,
              attendanceDayId: day.id,
              projectId: day.projectId,
              dueAt: link['due_at']! as String,
              eventId: command.reminderEventId,
              occurredAt: timestamp,
            );
          } else {
            await _completeLinkedReminder(
              transaction,
              reminderId: link['reminder_id']! as String,
              attendanceDayId: day.id,
              projectId: day.projectId,
              eventId: command.reminderEventId,
              occurredAt: timestamp,
            );
          }
        }
      });
    });
    await _safeReconcileNotifications(
      requestPermission: command.transition == AttendanceTransition.reopen,
    );
    return getDayDetail(command.dayId);
  }

  @override
  Future<AttendanceReminderSetting> getReminderSetting(String projectId) async {
    validateUuid(projectId, 'Proje kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.query(
        'attendance_reminder_settings',
        where: 'project_id = ?',
        whereArgs: [projectId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return AttendanceReminderSetting(
          projectId: projectId,
          isEnabled: false,
          localTime: '17:00',
          selectedWeekdays: const {1, 2, 3, 4, 5, 6},
          timezoneName: CseTimeCodec.istanbulTimezoneName,
          revision: 0,
          createdAt: '',
          updatedAt: '',
        );
      }
      return _settingFromRow(rows.single);
    });
  }

  @override
  Future<AttendanceReminderSetting> saveReminderSetting(
    SaveAttendanceReminderSettingCommand command,
  ) async {
    validateUuid(command.projectId, 'Proje kimliği');
    if (command.expectedRevision < 0) {
      throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
    }
    validateAttendanceLocalTime(command.localTime);
    if (command.selectedWeekdays.isEmpty ||
        command.selectedWeekdays.any((day) => day < 1 || day > 7)) {
      throw const AgendaValidationFailure(
        'En az bir geçerli çalışma günü seçilmelidir.',
      );
    }
    final weekdays = command.selectedWeekdays.toList()..sort();
    final weekdayValue = weekdays.join(',');
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    final result = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        await _requireProject(transaction, command.projectId);
        final rows = await transaction.query(
          'attendance_reminder_settings',
          where: 'project_id = ?',
          whereArgs: [command.projectId],
          limit: 1,
        );
        if (rows.isEmpty) {
          if (command.expectedRevision != 0) throw _staleFailure();
          await transaction.insert('attendance_reminder_settings', {
            'project_id': command.projectId,
            'is_enabled': command.isEnabled ? 1 : 0,
            'local_time': command.localTime,
            'selected_weekdays': weekdayValue,
            'timezone_name': CseTimeCodec.istanbulTimezoneName,
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
          });
          return AttendanceReminderSetting(
            projectId: command.projectId,
            isEnabled: command.isEnabled,
            localTime: command.localTime,
            selectedWeekdays: Set.unmodifiable(weekdays),
            timezoneName: CseTimeCodec.istanbulTimezoneName,
            revision: 1,
            createdAt: timestamp,
            updatedAt: timestamp,
          );
        }
        final current = _settingFromRow(rows.single);
        _requireRevision(current.revision, command.expectedRevision);
        if (current.isEnabled == command.isEnabled &&
            current.localTime == command.localTime &&
            current.selectedWeekdays.join(',') == weekdayValue) {
          return current;
        }
        final count = await transaction.update(
          'attendance_reminder_settings',
          {
            'is_enabled': command.isEnabled ? 1 : 0,
            'local_time': command.localTime,
            'selected_weekdays': weekdayValue,
            'updated_at': timestamp,
            'revision': current.revision + 1,
          },
          where: 'project_id = ? AND revision = ?',
          whereArgs: [command.projectId, current.revision],
        );
        if (count != 1) throw _staleFailure();
        return AttendanceReminderSetting(
          projectId: current.projectId,
          isEnabled: command.isEnabled,
          localTime: command.localTime,
          selectedWeekdays: Set.unmodifiable(weekdays),
          timezoneName: current.timezoneName,
          revision: current.revision + 1,
          createdAt: current.createdAt,
          updatedAt: timestamp,
        );
      });
    });
    await ensureRollingOccurrences();
    return result;
  }

  @override
  Future<void> ensureRollingOccurrences() async {
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    final today = CseTimeCodec.istanbulDayKey(timestamp);
    await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final settings = await transaction.rawQuery('''
          SELECT s.*, p.name AS project_name
          FROM attendance_reminder_settings s
          JOIN projects p ON p.id = s.project_id
          WHERE p.archived_at IS NULL
          ORDER BY p.name COLLATE NOCASE ASC, p.id ASC
        ''');
        for (final row in settings) {
          final setting = _settingFromRow(row);
          final projectName = row['project_name']! as String;
          for (var offset = 0; offset < 14; offset += 1) {
            final localDate = CseTimeCodec.shiftIstanbulDay(today, offset);
            final weekday = DateTime.parse(localDate).weekday;
            final eligible =
                setting.isEnabled && setting.selectedWeekdays.contains(weekday);
            if (eligible) {
              final dueAt = CseTimeCodec.canonicalFromIstanbulLocal(
                '${localDate}T${setting.localTime}:00',
              );
              await _ensureOccurrence(
                transaction,
                projectId: setting.projectId,
                projectName: projectName,
                localDate: localDate,
                dueAt: dueAt,
                occurredAt: timestamp,
              );
            } else {
              await _cancelUnselectedOccurrence(
                transaction,
                projectId: setting.projectId,
                localDate: localDate,
                occurredAt: timestamp,
              );
            }
          }
        }
      });
    });
    await _safeReconcileNotifications(requestPermission: false);
  }

  @override
  Future<AttendanceExportResult> exportDay(
    ExportAttendanceDayCommand command, {
    bool share = false,
  }) async {
    validateUuid(command.dayId, 'Puantaj günü kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final detail = await getDayDetail(command.dayId);
    _requireRevision(detail.day.revision, command.expectedRevision);
    final fileName =
        'puantaj_${detail.day.localDate}_${detail.day.projectId.substring(0, 8)}_'
        '${command.eventId.substring(0, 8)}.csv';
    final bytes = AttendanceCsvFormatter.format(detail);
    final summary = AttendanceCsvFormatter.humanSummary(detail);
    final absolutePath = await exportGateway.stage(fileName, bytes);
    try {
      final now = _readClockOnce();
      await _withDatabase(now, (database) {
        return database.transaction((transaction) async {
          final existing = await transaction.query(
            'attendance_events',
            where: 'id = ?',
            whereArgs: [command.eventId],
            limit: 1,
          );
          if (existing.isNotEmpty) {
            throw const AgendaValidationFailure(
              'Bu CSV dışa aktarma işlemi daha önce tamamlandı.',
            );
          }
          final current = await _requireDay(transaction, command.dayId);
          _requireRevision(current.revision, command.expectedRevision);
          await _insertAttendanceEvent(
            transaction,
            id: command.eventId,
            dayId: current.id,
            eventType: 'attendance_day.csv_exported',
            occurredAt: CseTimeCodec.encodeUtc(now),
            payload: {'file_name': fileName},
          );
        });
      });
    } on Object {
      await exportGateway.cleanup(absolutePath);
      rethrow;
    }
    if (share) await exportGateway.share(absolutePath, summary);
    return AttendanceExportResult(
      fileName: fileName,
      absolutePath: absolutePath,
      humanSummary: summary,
    );
  }

  Future<void> _ensureOccurrence(
    Transaction transaction, {
    required String projectId,
    required String projectName,
    required String localDate,
    required String dueAt,
    required String occurredAt,
  }) async {
    final dayRows = await transaction.query(
      'attendance_days',
      where: 'project_id = ? AND local_date = ?',
      whereArgs: [projectId, localDate],
      limit: 1,
    );
    late final String dayId;
    late final AttendanceDayStatus dayStatus;
    if (dayRows.isEmpty) {
      dayId = _stableUuid('attendance-day:$projectId:$localDate');
      dayStatus = AttendanceDayStatus.draft;
      await transaction.insert('attendance_days', {
        'id': dayId,
        'project_id': projectId,
        'local_date': localDate,
        'status': dayStatus.storageValue,
        'revision': 1,
        'created_at': occurredAt,
        'updated_at': occurredAt,
      });
      await _insertAttendanceEvent(
        transaction,
        id: _stableUuid('attendance-created:$projectId:$localDate'),
        dayId: dayId,
        eventType: 'attendance_day.created',
        occurredAt: occurredAt,
        payload: {'local_date': localDate, 'project_id': projectId},
      );
    } else {
      dayId = dayRows.single['id']! as String;
      dayStatus = AttendanceDayStatus.fromStorage(
        dayRows.single['status']! as String,
      );
    }
    final links = await transaction.query(
      'attendance_day_reminder_links',
      where: 'attendance_day_id = ?',
      whereArgs: [dayId],
      limit: 1,
    );
    if (links.isEmpty) {
      final reminderId = _stableUuid(
        'attendance-reminder:$projectId:$localDate',
      );
      final reminderEventId = _stableUuid(
        'attendance-reminder-created:$projectId:$localDate',
      );
      final title = 'Puantajı tamamla — $projectName — $localDate';
      final open = dayStatus == AttendanceDayStatus.draft;
      await transaction.insert('follow_up_items', {
        'id': reminderId,
        'capture_text': title,
        'title': title,
        'description': 'Günlük saha puantajını tamamlayın.',
        'item_type': ReminderKind.action.storageValue,
        'status': open
            ? ReminderStatus.active.storageValue
            : ReminderStatus.completed.storageValue,
        'project_id': projectId,
        'attendance_day_id': dayId,
        'is_important': 0,
        'next_attention_at': open ? dueAt : null,
        'outcome_type': open
            ? null
            : ReminderOutcomeType.completed.storageValue,
        'revision': 1,
        'created_at': occurredAt,
        'updated_at': occurredAt,
        'completed_at': open ? null : occurredAt,
      });
      await transaction.insert('follow_up_events', {
        'id': reminderEventId,
        'follow_up_id': reminderId,
        'sequence': 1,
        'project_id': projectId,
        'source_attendance_day_id': dayId,
        'event_type': 'created',
        'occurred_at': occurredAt,
        'payload_json': jsonEncode({
          'next_attention_at': open ? dueAt : null,
          'source_attendance_day_id': dayId,
          'status': open
              ? ReminderStatus.active.storageValue
              : ReminderStatus.completed.storageValue,
        }),
      });
      final platformId = await _allocatePlatformNotificationId(
        transaction,
        reminderId,
      );
      await transaction.insert('reminder_notification_bindings', {
        'reminder_id': reminderId,
        'platform_notification_id': platformId,
        'scheduled_for': open ? dueAt : null,
        'sync_state': open
            ? NotificationSyncState.unavailable.storageValue
            : NotificationSyncState.cancelled.storageValue,
        'last_synced_at': occurredAt,
        'safe_error_code': open ? 'pending_sync' : null,
      });
      await transaction.insert('attendance_day_reminder_links', {
        'attendance_day_id': dayId,
        'reminder_id': reminderId,
        'due_at': dueAt,
        'created_at': occurredAt,
      });
      await _insertAttendanceEvent(
        transaction,
        id: _stableUuid('attendance-linked:$projectId:$localDate'),
        dayId: dayId,
        eventType: 'attendance_day.reminder_linked',
        occurredAt: occurredAt,
        payload: {'due_at': dueAt, 'reminder_id': reminderId},
      );
      return;
    }
    final link = links.single;
    final reminderId = link['reminder_id']! as String;
    if (link['due_at'] != dueAt) {
      await transaction.update(
        'attendance_day_reminder_links',
        {'due_at': dueAt},
        where: 'attendance_day_id = ?',
        whereArgs: [dayId],
      );
    }
    if (dayStatus == AttendanceDayStatus.draft) {
      await _reopenLinkedReminder(
        transaction,
        reminderId: reminderId,
        attendanceDayId: dayId,
        projectId: projectId,
        dueAt: dueAt,
        eventId: RecordId.randomUuid(),
        occurredAt: occurredAt,
      );
    } else {
      await _completeLinkedReminder(
        transaction,
        reminderId: reminderId,
        attendanceDayId: dayId,
        projectId: projectId,
        eventId: RecordId.randomUuid(),
        occurredAt: occurredAt,
      );
    }
  }

  Future<void> _cancelUnselectedOccurrence(
    Transaction transaction, {
    required String projectId,
    required String localDate,
    required String occurredAt,
  }) async {
    final rows = await transaction.rawQuery(
      '''
      SELECT f.*
      FROM attendance_days d
      JOIN attendance_day_reminder_links l ON l.attendance_day_id = d.id
      JOIN follow_up_items f ON f.id = l.reminder_id
      WHERE d.project_id = ? AND d.local_date = ? AND d.status = 'draft'
        AND f.trashed_at IS NULL
      LIMIT 1
      ''',
      [projectId, localDate],
    );
    if (rows.isEmpty) return;
    final reminder = _reminderFromRow(rows.single);
    if (reminder.trashedAt != null) return;
    if (reminder.status == ReminderStatus.completed ||
        reminder.status == ReminderStatus.cancelled) {
      return;
    }
    await transaction.update(
      'follow_up_items',
      {
        'status': ReminderStatus.cancelled.storageValue,
        'next_attention_at': null,
        'outcome_type': ReminderOutcomeType.noLongerNeeded.storageValue,
        'outcome_note': null,
        'completed_at': null,
        'cancelled_at': occurredAt,
        'updated_at': occurredAt,
        'revision': reminder.revision + 1,
      },
      where: 'id = ? AND revision = ?',
      whereArgs: [reminder.id, reminder.revision],
    );
    await _insertReminderEvent(
      transaction,
      id: RecordId.randomUuid(),
      reminderId: reminder.id,
      projectId: projectId,
      attendanceDayId: reminder.attendanceDayId!,
      eventType: 'cancelled',
      occurredAt: occurredAt,
      payload: {'reason': 'attendance_setting_not_selected'},
    );
  }

  Future<void> _completeLinkedReminder(
    Transaction transaction, {
    required String reminderId,
    required String attendanceDayId,
    required String projectId,
    required String eventId,
    required String occurredAt,
  }) async {
    final rows = await transaction.query(
      'follow_up_items',
      where: 'id = ? AND attendance_day_id = ? AND project_id = ?',
      whereArgs: [reminderId, attendanceDayId, projectId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure(
        'Puantaj hatırlatıcı bağlantısı geçersizdir.',
      );
    }
    final reminder = _reminderFromRow(rows.single);
    if (reminder.trashedAt != null) return;
    if (reminder.status == ReminderStatus.completed ||
        reminder.status == ReminderStatus.cancelled) {
      return;
    }
    await transaction.update(
      'follow_up_items',
      {
        'status': ReminderStatus.completed.storageValue,
        'next_attention_at': null,
        'outcome_type': ReminderOutcomeType.completed.storageValue,
        'outcome_note': null,
        'completed_at': occurredAt,
        'cancelled_at': null,
        'updated_at': occurredAt,
        'revision': reminder.revision + 1,
      },
      where: 'id = ? AND revision = ?',
      whereArgs: [reminder.id, reminder.revision],
    );
    await _insertReminderEvent(
      transaction,
      id: eventId,
      reminderId: reminder.id,
      projectId: projectId,
      attendanceDayId: attendanceDayId,
      eventType: 'completed',
      occurredAt: occurredAt,
      payload: {'source': 'attendance_day'},
    );
  }

  Future<void> _reopenLinkedReminder(
    Transaction transaction, {
    required String reminderId,
    required String attendanceDayId,
    required String projectId,
    required String dueAt,
    required String eventId,
    required String occurredAt,
  }) async {
    final rows = await transaction.query(
      'follow_up_items',
      where: 'id = ? AND attendance_day_id = ? AND project_id = ?',
      whereArgs: [reminderId, attendanceDayId, projectId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure(
        'Puantaj hatırlatıcı bağlantısı geçersizdir.',
      );
    }
    final reminder = _reminderFromRow(rows.single);
    if (reminder.trashedAt != null) return;
    final unchanged =
        reminder.status == ReminderStatus.active &&
        reminder.nextAttentionAt == dueAt;
    if (unchanged) return;
    final eventType =
        reminder.status == ReminderStatus.completed ||
            reminder.status == ReminderStatus.cancelled
        ? 'reopened'
        : 'rescheduled';
    await transaction.update(
      'follow_up_items',
      {
        'status': ReminderStatus.active.storageValue,
        'next_attention_at': dueAt,
        'outcome_type': null,
        'outcome_note': null,
        'completed_at': null,
        'cancelled_at': null,
        'updated_at': occurredAt,
        'revision': reminder.revision + 1,
      },
      where: 'id = ? AND revision = ?',
      whereArgs: [reminder.id, reminder.revision],
    );
    await _insertReminderEvent(
      transaction,
      id: eventId,
      reminderId: reminder.id,
      projectId: projectId,
      attendanceDayId: attendanceDayId,
      eventType: eventType,
      occurredAt: occurredAt,
      payload: {'next_attention_at': dueAt, 'source': 'attendance_day'},
    );
  }

  Future<void> _insertAttendanceEvent(
    Transaction transaction, {
    required String id,
    required String dayId,
    required String eventType,
    required String occurredAt,
    required Map<String, Object?> payload,
    bool invokeHook = true,
  }) async {
    if (invokeHook) await beforeAttendanceEventInsert?.call(transaction);
    final sequenceRows = await transaction.rawQuery(
      '''
      SELECT COALESCE(MAX(sequence), 0) + 1 AS next_sequence
      FROM attendance_events
      WHERE attendance_day_id = ?
      ''',
      [dayId],
    );
    await transaction.insert('attendance_events', {
      'id': id,
      'attendance_day_id': dayId,
      'sequence': sequenceRows.single['next_sequence']! as int,
      'event_type': eventType,
      'occurred_at': occurredAt,
      'payload_json': jsonEncode(payload),
    });
  }

  Future<void> _insertReminderEvent(
    Transaction transaction, {
    required String id,
    required String reminderId,
    required String projectId,
    required String attendanceDayId,
    required String eventType,
    required String occurredAt,
    required Map<String, Object?> payload,
  }) async {
    final existing = await transaction.query(
      'follow_up_events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    final sequenceRows = await transaction.rawQuery(
      '''
      SELECT COALESCE(MAX(sequence), 0) + 1 AS next_sequence
      FROM follow_up_events
      WHERE follow_up_id = ?
      ''',
      [reminderId],
    );
    await transaction.insert('follow_up_events', {
      'id': id,
      'follow_up_id': reminderId,
      'sequence': sequenceRows.single['next_sequence']! as int,
      'project_id': projectId,
      'source_attendance_day_id': attendanceDayId,
      'event_type': eventType,
      'occurred_at': occurredAt,
      'payload_json': jsonEncode(payload),
    });
  }

  Future<AttendanceDayDetail> _loadDetail(
    DatabaseExecutor database,
    String dayId,
  ) async {
    final dayRows = await database.rawQuery(
      '''
      SELECT d.*, p.name AS project_name
      FROM attendance_days d
      JOIN projects p ON p.id = d.project_id
      WHERE d.id = ?
      LIMIT 1
      ''',
      [dayId],
    );
    if (dayRows.isEmpty) {
      throw const AgendaValidationFailure('Puantaj günü bulunamadı.');
    }
    final day = _dayFromRow(dayRows.single);
    final entryRows = await database.rawQuery(
      '''
      SELECT
        e.*, m.full_name AS member_name, m.team_name, m.role_name,
        m.personnel_code, m.is_active AS member_is_active, m.team_id,
        s.name AS subcontractor_name
      FROM attendance_entries e
      JOIN workforce_members m ON m.id = e.workforce_member_id
      JOIN subcontractors s ON s.id = m.subcontractor_id
      JOIN workforce_teams t ON t.id = m.team_id
      WHERE e.attendance_day_id = ? AND e.removed_at IS NULL
      ORDER BY
        s.name_normalized ASC,
        t.name_normalized ASC,
        m.full_name COLLATE NOCASE ASC,
        m.id ASC
      ''',
      [dayId],
    );
    final entries = entryRows.map(_entryFromRow).toList(growable: false);
    final eventRows = await database.query(
      'attendance_events',
      where: 'attendance_day_id = ?',
      whereArgs: [dayId],
      orderBy: 'sequence ASC, id ASC',
    );
    final reminderRows = await database.rawQuery(
      '''
      SELECT f.*, p.name AS project_name
      FROM follow_up_items f
      LEFT JOIN projects p ON p.id = f.project_id
      WHERE f.attendance_day_id = ? AND f.trashed_at IS NULL
      ORDER BY f.created_at ASC, f.id ASC
      LIMIT 1
      ''',
      [dayId],
    );
    final totals = _calculateTotals(entries);
    final teams = <String, List<AttendanceEntry>>{};
    for (final entry in entries) {
      teams.putIfAbsent(entry.teamId ?? entry.teamName, () => []).add(entry);
    }
    return AttendanceDayDetail(
      day: day,
      entries: entries,
      events: eventRows.map(_eventFromRow).toList(growable: false),
      totals: totals,
      teamSummaries: teams.entries
          .map(
            (entry) => AttendanceTeamSummary(
              teamName: entry.value.first.teamName,
              teamId: entry.value.first.teamId,
              subcontractorName: entry.value.first.subcontractorName,
              totals: _calculateTotals(entry.value),
            ),
          )
          .toList(growable: false),
      linkedReminder: reminderRows.isEmpty
          ? null
          : _reminderFromRow(reminderRows.single),
    );
  }

  Future<Subcontractor> _loadSubcontractor(
    DatabaseExecutor database,
    String id,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT s.*,
        (SELECT count(*) FROM workforce_teams t
          WHERE t.subcontractor_id = s.id AND t.status = 'active')
          AS active_team_count,
        (SELECT count(*) FROM workforce_members m
          WHERE m.subcontractor_id = s.id AND m.is_active = 1)
          AS active_person_count
      FROM subcontractors s WHERE s.id = ? LIMIT 1
    ''',
      [id],
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Taşeron bulunamadı.');
    }
    return _subcontractorFromRow(rows.single);
  }

  Future<WorkforceTeam> _loadTeam(DatabaseExecutor database, String id) async {
    final rows = await database.rawQuery(
      '''
      SELECT t.*, s.name AS subcontractor_name,
        (SELECT count(*) FROM workforce_members m
          WHERE m.team_id = t.id AND m.is_active = 1)
          AS active_person_count
      FROM workforce_teams t
      JOIN subcontractors s ON s.id = t.subcontractor_id
      WHERE t.id = ? LIMIT 1
    ''',
      [id],
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Ekip bulunamadı.');
    }
    return _teamFromRow(rows.single);
  }

  Future<_RegistrySelection> _resolveRegistrySelection(
    DatabaseExecutor database, {
    required String projectId,
    required String requestedTeamName,
    required String? subcontractorId,
    required String? teamId,
    required String timestamp,
  }) async {
    if ((subcontractorId == null) != (teamId == null)) {
      throw const AgendaValidationFailure(
        'Taşeron ve ekip birlikte seçilmelidir.',
      );
    }
    if (subcontractorId != null && teamId != null) {
      validateUuid(subcontractorId, 'Taşeron kimliği');
      validateUuid(teamId, 'Ekip kimliği');
      final subcontractor = await _loadSubcontractor(database, subcontractorId);
      final team = await _loadTeam(database, teamId);
      if (subcontractor.projectId != projectId ||
          team.projectId != projectId ||
          team.subcontractorId != subcontractor.id ||
          !subcontractor.isActive ||
          !team.isActive) {
        throw const AgendaValidationFailure(
          'Personel yalnız aktif ve aynı projedeki taşeron/ekibe bağlanabilir.',
        );
      }
      return _RegistrySelection(subcontractor, team);
    }

    // Schema v4 callers remain source compatible. Mobile UI never exposes this
    // free-text compatibility path; it deterministically creates a legacy pair.
    final normalized = _normalizeRegistryName(requestedTeamName);
    final subcontractorStableId = _stableUuid(
      'legacy-subcontractor:$projectId:$normalized',
    );
    final teamStableId = _stableUuid('legacy-team:$projectId:$normalized');
    final subcontractorRows = await database.query(
      'subcontractors',
      columns: ['id'],
      where: 'project_id = ? AND name_normalized = ?',
      whereArgs: [projectId, normalized],
      limit: 1,
    );
    final resolvedSubcontractorId = subcontractorRows.isEmpty
        ? subcontractorStableId
        : subcontractorRows.single['id']! as String;
    if (subcontractorRows.isEmpty) {
      await database.insert('subcontractors', {
        'id': resolvedSubcontractorId,
        'project_id': projectId,
        'name': requestedTeamName,
        'name_normalized': normalized,
        'status': 'active',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await _insertWorkforceEvent(
        database,
        id: _stableUuid(
          'legacy-subcontractor-created:$resolvedSubcontractorId',
        ),
        type: 'subcontractor',
        aggregateId: resolvedSubcontractorId,
        projectId: projectId,
        eventType: 'subcontractor.created',
        occurredAt: timestamp,
        payload: {'compatibility_path': true},
      );
    }
    final teamRows = await database.query(
      'workforce_teams',
      columns: ['id'],
      where: 'subcontractor_id = ? AND name_normalized = ?',
      whereArgs: [resolvedSubcontractorId, normalized],
      limit: 1,
    );
    final resolvedTeamId = teamRows.isEmpty
        ? teamStableId
        : teamRows.single['id']! as String;
    if (teamRows.isEmpty) {
      await database.insert('workforce_teams', {
        'id': resolvedTeamId,
        'project_id': projectId,
        'subcontractor_id': resolvedSubcontractorId,
        'name': requestedTeamName,
        'name_normalized': normalized,
        'status': 'active',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await _insertWorkforceEvent(
        database,
        id: _stableUuid('legacy-team-created:$resolvedTeamId'),
        type: 'team',
        aggregateId: resolvedTeamId,
        projectId: projectId,
        eventType: 'team.created',
        occurredAt: timestamp,
        payload: {'compatibility_path': true},
      );
    }
    return _RegistrySelection(
      await _loadSubcontractor(database, resolvedSubcontractorId),
      await _loadTeam(database, resolvedTeamId),
    );
  }

  Future<void> _insertWorkforceEvent(
    DatabaseExecutor database, {
    required String id,
    required String type,
    required String aggregateId,
    required String projectId,
    required String eventType,
    required String occurredAt,
    required Map<String, Object?> payload,
  }) async {
    final sequenceRows = await database.rawQuery(
      '''
      SELECT coalesce(max(sequence), 0) + 1 AS value
      FROM workforce_events
      WHERE aggregate_type = ? AND aggregate_id = ?
    ''',
      [type, aggregateId],
    );
    await database.insert('workforce_events', {
      'id': id,
      'aggregate_type': type,
      'aggregate_id': aggregateId,
      'project_id': projectId,
      'sequence': sequenceRows.single['value'],
      'event_type': eventType,
      'occurred_at': occurredAt,
      'payload_json': jsonEncode(payload),
    });
  }

  String _requiredLocalDate(String value, String field) {
    final parsed = _optionalLocalDate(value, field);
    if (parsed == null) throw AgendaValidationFailure('$field zorunludur.');
    return parsed;
  }

  String? _optionalLocalDate(String? value, String field) {
    final normalized = optionalTrimmed(value, field, maxLength: 10);
    if (normalized == null) return null;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)) {
      throw AgendaValidationFailure('$field YYYY-AA-GG biçiminde olmalıdır.');
    }
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null ||
        '${parsed.year.toString().padLeft(4, '0')}-'
                '${parsed.month.toString().padLeft(2, '0')}-'
                '${parsed.day.toString().padLeft(2, '0')}' !=
            normalized) {
      throw AgendaValidationFailure('$field geçersizdir.');
    }
    return normalized;
  }

  void _validateRegistryDateRange(String? startedOn, String? endedOn) {
    if (startedOn != null &&
        endedOn != null &&
        endedOn.compareTo(startedOn) < 0) {
      throw const AgendaValidationFailure(
        'Bitiş tarihi başlangıç tarihinden önce olamaz.',
      );
    }
  }

  bool _complianceMatches(
    WorkforceComplianceRecord current,
    Map<String, Object?> values,
  ) =>
      current.documentType.storageValue == values['document_type'] &&
      current.documentNumber == values['document_number'] &&
      current.issuedDate == values['issued_date'] &&
      current.expiryDate == values['expiry_date'] &&
      current.sourceStatus.storageValue == values['source_status'] &&
      current.note == values['note'] &&
      current.reason == values['reason'];

  bool _ppeMatches(
    WorkforcePpeAssignment current,
    Map<String, Object?> values,
  ) =>
      current.ppeType == values['ppe_type'] &&
      current.brandModel == values['brand_model'] &&
      current.size == values['size'] &&
      current.serialTag == values['serial_tag'] &&
      current.quantity == values['quantity'] &&
      current.assignedDate == values['assigned_date'] &&
      current.status.storageValue == values['status'] &&
      current.returnedDate == values['returned_date'] &&
      current.note == values['note'];

  Future<String> _requireProject(
    DatabaseExecutor database,
    String projectId,
  ) async {
    final rows = await database.query(
      'projects',
      columns: ['name'],
      where: 'id = ? AND archived_at IS NULL',
      whereArgs: [projectId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Seçilen proje bulunamadı.');
    }
    return rows.single['name']! as String;
  }

  Future<WorkforceMember> _requireMember(
    DatabaseExecutor database,
    String memberId,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT m.*, s.name AS subcontractor_name,
        t.name AS registry_team_name
      FROM workforce_members m
      JOIN subcontractors s ON s.id = m.subcontractor_id
      JOIN workforce_teams t ON t.id = m.team_id
      WHERE m.id = ? LIMIT 1
    ''',
      [memberId],
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Personel bulunamadı.');
    }
    return _memberFromRow(rows.single);
  }

  Future<AttendanceDay> _requireDay(
    DatabaseExecutor database,
    String dayId,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT d.*, p.name AS project_name
      FROM attendance_days d
      JOIN projects p ON p.id = d.project_id
      WHERE d.id = ?
      LIMIT 1
      ''',
      [dayId],
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Puantaj günü bulunamadı.');
    }
    return _dayFromRow(rows.single);
  }

  Future<void> _requireUniquePersonnelCode(
    DatabaseExecutor database, {
    required String projectId,
    required String? personnelCode,
    String? excludingId,
  }) async {
    if (personnelCode == null) return;
    final rows = await database.query(
      'workforce_members',
      columns: ['id'],
      where: excludingId == null
          ? 'project_id = ? AND personnel_code = ?'
          : 'project_id = ? AND personnel_code = ? AND id != ?',
      whereArgs: excludingId == null
          ? [projectId, personnelCode]
          : [projectId, personnelCode, excludingId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      throw const AgendaValidationFailure(
        'Personel kodu aynı proje içinde zaten kullanılıyor.',
      );
    }
  }

  Future<bool> _isIdempotentEvent(
    DatabaseExecutor database,
    String eventId,
    String dayId,
  ) async {
    final rows = await database.query(
      'attendance_events',
      columns: ['attendance_day_id'],
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    if (rows.single['attendance_day_id'] != dayId) {
      throw const AgendaValidationFailure(
        'Event kimliği başka bir Puantaj günü için kullanılıyor.',
      );
    }
    return true;
  }

  Future<void> _advanceDayRevision(
    DatabaseExecutor database,
    AttendanceDay day,
    String timestamp,
  ) async {
    final count = await database.update(
      'attendance_days',
      {'updated_at': timestamp, 'revision': day.revision + 1},
      where: 'id = ? AND revision = ?',
      whereArgs: [day.id, day.revision],
    );
    if (count != 1) throw _staleFailure();
  }

  Future<int> _allocatePlatformNotificationId(
    DatabaseExecutor database,
    String reminderId,
  ) async {
    var candidate = 2166136261;
    for (final value in reminderId.codeUnits) {
      candidate ^= value;
      candidate = (candidate * 16777619) & 0x7fffffff;
    }
    if (candidate == 0) candidate = 1;
    for (var attempts = 0; attempts < 2147483647; attempts += 1) {
      final collision = await database.query(
        'reminder_notification_bindings',
        columns: ['reminder_id'],
        where: 'platform_notification_id = ?',
        whereArgs: [candidate],
        limit: 1,
      );
      if (collision.isEmpty || collision.single['reminder_id'] == reminderId) {
        return candidate;
      }
      candidate = candidate == 2147483647 ? 1 : candidate + 1;
    }
    throw const AgendaValidationFailure(
      'Bildirim kimliği güvenli biçimde ayrılamadı.',
    );
  }

  Future<void> _safeReconcileNotifications({
    required bool requestPermission,
  }) async {
    try {
      await agenda.reconcileNotifications(requestPermission: requestPermission);
    } on Object {
      // SQLite remains authoritative; bootstrap retries platform reconciliation.
    }
  }

  List<AttendanceRosterValue> _normalizeRosterValues(
    List<AttendanceRosterValue> values,
  ) {
    final memberIds = <String>{};
    final entryIds = <String>{};
    return values
        .map((value) {
          validateUuid(value.entryId, 'Puantaj entry kimliği');
          validateUuid(value.memberId, 'Personel kimliği');
          if (!memberIds.add(value.memberId) || !entryIds.add(value.entryId)) {
            throw const AgendaValidationFailure(
              'Puantaj listesinde yinelenen personel veya entry vardır.',
            );
          }
          if (value.overtimeMinutes < 0) {
            throw const AgendaValidationFailure('Fazla mesai negatif olamaz.');
          }
          if ((value.result == AttendanceResult.absent ||
                  value.result == AttendanceResult.leave) &&
              value.overtimeMinutes != 0) {
            throw const AgendaValidationFailure(
              'Gelmedi veya izinli kaydında fazla mesai sıfır olmalıdır.',
            );
          }
          return AttendanceRosterValue(
            entryId: value.entryId,
            memberId: value.memberId,
            result: value.result,
            overtimeMinutes: value.overtimeMinutes,
            shortNote: optionalTrimmed(
              value.shortNote,
              'Kısa not',
              maxLength: 500,
            ),
          );
        })
        .toList(growable: false);
  }

  Map<String, Object?> _entryPayload(AttendanceRosterValue value) => {
    'result': value.result.storageValue,
    'overtime_minutes': value.overtimeMinutes,
    'short_note': value.shortNote,
    'removed': false,
  };

  void _validateExpectedRevision(int revision) {
    if (revision < 1) {
      throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
    }
  }

  void _requireRevision(int current, int expected) {
    if (current != expected) throw _staleFailure();
  }

  void _requireDraft(AttendanceDay day) {
    if (day.status != AttendanceDayStatus.draft) {
      throw const AgendaValidationFailure(
        'Tamamlanmış Puantaj günü önce yeniden açılmalıdır.',
      );
    }
  }

  AgendaValidationFailure _staleFailure() => const AgendaValidationFailure(
    'Puantaj kaydı başka bir işlemle değişti. Ekranı yenileyin.',
  );

  DateTime _readClockOnce() {
    final value = clock();
    CseTimeCodec.encodeUtc(value);
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    );
  }

  Future<T> _withDatabase<T>(
    DateTime operationTime,
    Future<T> Function(Database database) action,
  ) => coordinator.run(() async {
    final appDatabase = AppDatabase(
      path: databasePath,
      factory: databaseFactory,
      clock: () => operationTime,
    );
    try {
      await appDatabase.open();
      return await action(appDatabase.database);
    } finally {
      await appDatabase.close();
    }
  });
}

Subcontractor _subcontractorFromRow(Map<String, Object?> row) => Subcontractor(
  id: row['id']! as String,
  projectId: row['project_id']! as String,
  name: requiredTrimmed(row['name']! as String, 'Taşeron adı'),
  contactName: row['contact_name'] as String?,
  phone: row['phone'] as String?,
  address: row['address'] as String?,
  specialty: row['specialty'] as String?,
  startedOn: row['started_on'] as String?,
  endedOn: row['ended_on'] as String?,
  note: row['note'] as String?,
  status: WorkforceRecordStatus.fromStorage(row['status']! as String),
  activeTeamCount: (row['active_team_count'] as int?) ?? 0,
  activePersonCount: (row['active_person_count'] as int?) ?? 0,
  revision: row['revision']! as int,
  createdAt: row['created_at']! as String,
  updatedAt: row['updated_at']! as String,
  archivedAt: row['archived_at'] as String?,
);

WorkforceTeam _teamFromRow(Map<String, Object?> row) => WorkforceTeam(
  id: row['id']! as String,
  projectId: row['project_id']! as String,
  subcontractorId: row['subcontractor_id']! as String,
  subcontractorName: row['subcontractor_name']! as String,
  name: requiredTrimmed(row['name']! as String, 'Ekip adı'),
  leadName: row['lead_name'] as String?,
  note: row['note'] as String?,
  status: WorkforceRecordStatus.fromStorage(row['status']! as String),
  activePersonCount: (row['active_person_count'] as int?) ?? 0,
  revision: row['revision']! as int,
  createdAt: row['created_at']! as String,
  updatedAt: row['updated_at']! as String,
  archivedAt: row['archived_at'] as String?,
);

WorkforceMember _memberFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final projectId = row['project_id']! as String;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final archivedAt = row['archived_at'] as String?;
  final subcontractorId = row['subcontractor_id'] as String?;
  final teamId = row['team_id'] as String?;
  validateUuid(id, 'Personel kimliği');
  validateUuid(projectId, 'Proje kimliği');
  validateCanonicalTimestamp(createdAt, 'Personel oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Personel güncelleme zamanı');
  if (archivedAt != null) {
    validateCanonicalTimestamp(archivedAt, 'Personel pasifleştirme zamanı');
  }
  if (subcontractorId != null) {
    validateUuid(subcontractorId, 'Taşeron kimliği');
  }
  if (teamId != null) validateUuid(teamId, 'Ekip kimliği');
  return WorkforceMember(
    id: id,
    projectId: projectId,
    fullName: requiredTrimmed(row['full_name']! as String, 'Personel adı'),
    teamName: requiredTrimmed(
      (row['registry_team_name'] ?? row['team_name'])! as String,
      'Ekip',
    ),
    roleName: requiredTrimmed(row['role_name']! as String, 'Meslek/pozisyon'),
    personnelCode: row['personnel_code'] as String?,
    subcontractorId: subcontractorId,
    subcontractorName: row['subcontractor_name'] as String?,
    teamId: teamId,
    phone: row['phone'] as String?,
    address: row['address'] as String?,
    startedOn: row['started_on'] as String?,
    note: row['note'] as String?,
    isActive: row['is_active'] == 1,
    revision: row['revision']! as int,
    createdAt: createdAt,
    updatedAt: updatedAt,
    archivedAt: archivedAt,
  );
}

AttendanceDay _dayFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final projectId = row['project_id']! as String;
  final localDate = row['local_date']! as String;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final completedAt = row['completed_at'] as String?;
  validateUuid(id, 'Puantaj günü kimliği');
  validateUuid(projectId, 'Proje kimliği');
  validateAttendanceDayKey(localDate);
  validateCanonicalTimestamp(createdAt, 'Puantaj oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Puantaj güncelleme zamanı');
  if (completedAt != null) {
    validateCanonicalTimestamp(completedAt, 'Puantaj tamamlanma zamanı');
  }
  return AttendanceDay(
    id: id,
    projectId: projectId,
    projectName: requiredTrimmed(row['project_name']! as String, 'Proje adı'),
    localDate: localDate,
    status: AttendanceDayStatus.fromStorage(row['status']! as String),
    generalNote: row['general_note'] as String?,
    revision: row['revision']! as int,
    createdAt: createdAt,
    updatedAt: updatedAt,
    completedAt: completedAt,
  );
}

AttendanceEntry _entryFromRow(Map<String, Object?> row) {
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  validateCanonicalTimestamp(createdAt, 'Puantaj entry oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Puantaj entry güncelleme zamanı');
  return AttendanceEntry(
    id: row['id']! as String,
    attendanceDayId: row['attendance_day_id']! as String,
    memberId: row['workforce_member_id']! as String,
    memberName: row['member_name']! as String,
    teamName: row['team_name']! as String,
    teamId: row['team_id'] as String?,
    subcontractorName: row['subcontractor_name'] as String?,
    roleName: row['role_name']! as String,
    personnelCode: row['personnel_code'] as String?,
    memberIsActive: row['member_is_active'] == 1,
    result: AttendanceResult.fromStorage(row['result']! as String),
    overtimeMinutes: row['overtime_minutes']! as int,
    shortNote: row['short_note'] as String?,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

WorkforceComplianceRecord _complianceFromRow(
  Map<String, Object?> row,
  String today,
) {
  final source = ComplianceSourceStatus.fromStorage(
    row['source_status']! as String,
  );
  final expiry = row['expiry_date'] as String?;
  final readStatus = switch (source) {
    ComplianceSourceStatus.missing => ComplianceReadStatus.missing,
    ComplianceSourceStatus.notApplicable ||
    ComplianceSourceStatus.exception => ComplianceReadStatus.exception,
    ComplianceSourceStatus.valid =>
      expiry == null
          ? ComplianceReadStatus.valid
          : expiry.compareTo(today) < 0
          ? ComplianceReadStatus.expired
          : DateTime.parse(expiry).difference(DateTime.parse(today)).inDays <=
                30
          ? ComplianceReadStatus.expiring
          : ComplianceReadStatus.valid,
  };
  return WorkforceComplianceRecord(
    id: row['id']! as String,
    memberId: row['workforce_member_id']! as String,
    documentType: ComplianceDocumentType.fromStorage(
      row['document_type']! as String,
    ),
    documentNumber: row['document_number'] as String?,
    issuedDate: row['issued_date'] as String?,
    expiryDate: expiry,
    sourceStatus: source,
    readStatus: readStatus,
    note: row['note'] as String?,
    reason: row['reason'] as String?,
    revision: row['revision']! as int,
    createdAt: row['created_at']! as String,
    updatedAt: row['updated_at']! as String,
    archivedAt: row['archived_at'] as String?,
  );
}

WorkforcePpeAssignment _ppeFromRow(Map<String, Object?> row) =>
    WorkforcePpeAssignment(
      id: row['id']! as String,
      memberId: row['workforce_member_id']! as String,
      ppeType: row['ppe_type']! as String,
      brandModel: row['brand_model'] as String?,
      size: row['size'] as String?,
      serialTag: row['serial_tag'] as String?,
      quantity: row['quantity']! as int,
      assignedDate: row['assigned_date']! as String,
      status: PpeAssignmentStatus.fromStorage(row['status']! as String),
      returnedDate: row['returned_date'] as String?,
      note: row['note'] as String?,
      revision: row['revision']! as int,
      createdAt: row['created_at']! as String,
      updatedAt: row['updated_at']! as String,
      archivedAt: row['archived_at'] as String?,
    );

AttendanceEvent _eventFromRow(Map<String, Object?> row) => AttendanceEvent(
  id: row['id']! as String,
  attendanceDayId: row['attendance_day_id']! as String,
  sequence: row['sequence']! as int,
  eventType: row['event_type']! as String,
  occurredAt: row['occurred_at']! as String,
  payloadJson: row['payload_json']! as String,
);

AttendanceReminderSetting _settingFromRow(Map<String, Object?> row) {
  final weekdays = (row['selected_weekdays']! as String)
      .split(',')
      .map(int.parse)
      .toSet();
  return AttendanceReminderSetting(
    projectId: row['project_id']! as String,
    isEnabled: row['is_enabled'] == 1,
    localTime: row['local_time']! as String,
    selectedWeekdays: Set.unmodifiable(weekdays),
    timezoneName: row['timezone_name']! as String,
    revision: row['revision']! as int,
    createdAt: row['created_at']! as String,
    updatedAt: row['updated_at']! as String,
  );
}

AttendanceTotals _calculateTotals(Iterable<AttendanceEntry> entries) {
  var full = 0;
  var half = 0;
  var absent = 0;
  var leave = 0;
  var overtime = 0;
  for (final entry in entries) {
    switch (entry.result) {
      case AttendanceResult.fullDay:
        full += 1;
      case AttendanceResult.halfDay:
        half += 1;
      case AttendanceResult.absent:
        absent += 1;
      case AttendanceResult.leave:
        leave += 1;
    }
    overtime += entry.overtimeMinutes;
  }
  return AttendanceTotals(
    fullDayCount: full,
    halfDayCount: half,
    absentCount: absent,
    leaveCount: leave,
    presentCount: full + half,
    personDayEquivalent: full + half * 0.5,
    overtimeMinutes: overtime,
  );
}

MobileReminder _reminderFromRow(Map<String, Object?> row) {
  final outcome = row['outcome_type'] as String?;
  return MobileReminder(
    id: row['id']! as String,
    projectId: row['project_id'] as String?,
    projectName: row['project_name'] as String?,
    sourceLogId: row['observation_id'] as String?,
    attendanceDayId: row['attendance_day_id'] as String?,
    concretePourId: row['concrete_pour_id'] as String?,
    captureText: row['capture_text']! as String,
    title: row['title']! as String,
    description: row['description'] as String?,
    kind: ReminderKind.fromStorage(row['item_type']! as String),
    status: ReminderStatus.fromStorage(row['status']! as String),
    location: row['location'] as String?,
    relatedPerson: row['related_person'] as String?,
    isImportant: row['is_important'] == 1,
    nextAttentionAt: row['next_attention_at'] as String?,
    allDayLocalDate: row['all_day_local_date'] as String?,
    deadlineAt: row['deadline_at'] as String?,
    conditionText: row['condition_text'] as String?,
    outcomeType: outcome == null
        ? null
        : ReminderOutcomeType.fromStorage(outcome),
    outcomeNote: row['outcome_note'] as String?,
    createdAt: row['created_at']! as String,
    updatedAt: row['updated_at']! as String,
    completedAt: row['completed_at'] as String?,
    cancelledAt: row['cancelled_at'] as String?,
    trashedAt: row['trashed_at'] as String?,
    revision: row['revision']! as int,
  );
}

String _stableUuid(String seed) {
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

String _normalizeRegistryName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

class _RegistrySelection {
  const _RegistrySelection(this.subcontractor, this.team);

  final Subcontractor subcontractor;
  final WorkforceTeam team;
}
