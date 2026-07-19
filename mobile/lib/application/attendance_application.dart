import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/platform/attendance_export_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class AttendanceApplication {
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
    AttendanceExportGateway? exportGateway,
    this.beforeAttendanceEventInsert,
  }) : exportGateway =
           exportGateway ?? const UnavailableAttendanceExportGateway();

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;
  final AgendaApplication agenda;
  final AttendanceExportGateway exportGateway;
  final AttendanceTransactionHook? beforeAttendanceEventInsert;
  Future<void> _databaseQueue = Future<void>.value();

  @override
  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  }) async {
    validateUuid(projectId, 'Proje kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.query(
        'workforce_members',
        where: includeInactive
            ? 'project_id = ?'
            : 'project_id = ? AND is_active = 1',
        whereArgs: [projectId],
        orderBy:
            'team_name COLLATE NOCASE ASC, '
            'full_name COLLATE NOCASE ASC, id ASC',
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
    final teamName = requiredTrimmed(
      command.teamName,
      'Ekip/taşeron',
      maxLength: 160,
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
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        await _requireProject(transaction, command.projectId);
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
              member.teamName != teamName ||
              member.roleName != roleName ||
              member.personnelCode != personnelCode) {
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
          'team_name': teamName,
          'role_name': roleName,
          'personnel_code': personnelCode,
          'is_active': 1,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        return _memberFromRow({
          'id': command.id,
          'project_id': command.projectId,
          'full_name': fullName,
          'team_name': teamName,
          'role_name': roleName,
          'personnel_code': personnelCode,
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
    final teamName = requiredTrimmed(
      command.teamName,
      'Ekip/taşeron',
      maxLength: 160,
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
    final now = _readClockOnce();
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final member = await _requireMember(transaction, command.id);
        _requireRevision(member.revision, command.expectedRevision);
        if (member.fullName == fullName &&
            member.teamName == teamName &&
            member.roleName == roleName &&
            member.personnelCode == personnelCode) {
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
            'team_name': teamName,
            'role_name': roleName,
            'personnel_code': personnelCode,
            'revision': member.revision + 1,
            'updated_at': timestamp,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [member.id, member.revision],
        );
        if (count != 1) throw _staleFailure();
        return _memberFromRow({
          'id': member.id,
          'project_id': member.projectId,
          'full_name': fullName,
          'team_name': teamName,
          'role_name': roleName,
          'personnel_code': personnelCode,
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
    final now = _readClockOnce();
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final member = await _requireMember(transaction, command.id);
        _requireRevision(member.revision, command.expectedRevision);
        if (!member.isActive) return member;
        final timestamp = CseTimeCodec.encodeUtc(now);
        final count = await transaction.update(
          'workforce_members',
          {
            'is_active': 0,
            'archived_at': timestamp,
            'updated_at': timestamp,
            'revision': member.revision + 1,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [member.id, member.revision],
        );
        if (count != 1) throw _staleFailure();
        return WorkforceMember(
          id: member.id,
          projectId: member.projectId,
          fullName: member.fullName,
          teamName: member.teamName,
          roleName: member.roleName,
          personnelCode: member.personnelCode,
          isActive: false,
          revision: member.revision + 1,
          createdAt: member.createdAt,
          updatedAt: timestamp,
          archivedAt: timestamp,
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
    final detail = await getDayDetail(command.dayId);
    final members = await listMembers(detail.day.projectId);
    final selected = members
        .where((member) => team == null || member.teamName == team)
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
      LIMIT 1
      ''',
      [projectId, localDate],
    );
    if (rows.isEmpty) return;
    final reminder = _reminderFromRow(rows.single);
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
        m.personnel_code, m.is_active AS member_is_active
      FROM attendance_entries e
      JOIN workforce_members m ON m.id = e.workforce_member_id
      WHERE e.attendance_day_id = ? AND e.removed_at IS NULL
      ORDER BY
        m.team_name COLLATE NOCASE ASC,
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
      WHERE f.attendance_day_id = ?
      ORDER BY f.created_at ASC, f.id ASC
      LIMIT 1
      ''',
      [dayId],
    );
    final totals = _calculateTotals(entries);
    final teams = <String, List<AttendanceEntry>>{};
    for (final entry in entries) {
      teams.putIfAbsent(entry.teamName, () => []).add(entry);
    }
    return AttendanceDayDetail(
      day: day,
      entries: entries,
      events: eventRows.map(_eventFromRow).toList(growable: false),
      totals: totals,
      teamSummaries: teams.entries
          .map(
            (entry) => AttendanceTeamSummary(
              teamName: entry.key,
              totals: _calculateTotals(entry.value),
            ),
          )
          .toList(growable: false),
      linkedReminder: reminderRows.isEmpty
          ? null
          : _reminderFromRow(reminderRows.single),
    );
  }

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
    final rows = await database.query(
      'workforce_members',
      where: 'id = ?',
      whereArgs: [memberId],
      limit: 1,
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
  ) {
    final completer = Completer<T>();
    _databaseQueue = _databaseQueue
        .then((_) async {
          final appDatabase = AppDatabase(
            path: databasePath,
            factory: databaseFactory,
            clock: () => operationTime,
          );
          try {
            await appDatabase.open();
            completer.complete(await action(appDatabase.database));
          } on Object catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          } finally {
            await appDatabase.close();
          }
        })
        .catchError((Object _, StackTrace _) {});
    return completer.future;
  }
}

WorkforceMember _memberFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final projectId = row['project_id']! as String;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final archivedAt = row['archived_at'] as String?;
  validateUuid(id, 'Personel kimliği');
  validateUuid(projectId, 'Proje kimliği');
  validateCanonicalTimestamp(createdAt, 'Personel oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Personel güncelleme zamanı');
  if (archivedAt != null) {
    validateCanonicalTimestamp(archivedAt, 'Personel pasifleştirme zamanı');
  }
  return WorkforceMember(
    id: id,
    projectId: projectId,
    fullName: requiredTrimmed(row['full_name']! as String, 'Personel adı'),
    teamName: requiredTrimmed(row['team_name']! as String, 'Ekip/taşeron'),
    roleName: requiredTrimmed(row['role_name']! as String, 'Meslek/pozisyon'),
    personnelCode: row['personnel_code'] as String?,
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
