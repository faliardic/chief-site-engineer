import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class AgendaApplication {
  Future<List<MobileProject>> listProjects();

  Future<MobileProject> createProject(CreateProjectCommand command);

  Future<List<AgendaLog>> listAgenda(AgendaQuery query);

  Future<AgendaLog> createAgendaLog(CreateAgendaLogCommand command);

  Future<AgendaLogDetail> getAgendaLogDetail(String logId);

  Future<MobileReminder> createReminder(CreateReminderCommand command);

  Future<List<MobileReminder>> listReminders(ReminderViewGroup group);

  Future<MobileReminder> getReminderDetail(String reminderId);

  Future<List<AppendOnlyEvent>> listObservationEvents(String logId);

  Future<List<AppendOnlyEvent>> listReminderEvents(String reminderId);
}

typedef ReminderTransactionHook =
    Future<void> Function(Transaction transaction);

class SqliteAgendaApplication implements AgendaApplication {
  SqliteAgendaApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.clock,
    this.beforeReminderEventInsert,
  });

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;
  final ReminderTransactionHook? beforeReminderEventInsert;
  Future<void> _databaseQueue = Future<void>.value();

  @override
  Future<List<MobileProject>> listProjects() async {
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.query(
        'projects',
        where: 'archived_at IS NULL',
        orderBy: 'name COLLATE NOCASE ASC, id ASC',
      );
      return rows.map(_projectFromRow).toList(growable: false);
    });
  }

  @override
  Future<MobileProject> createProject(CreateProjectCommand command) async {
    validateUuid(command.id, 'Proje kimliği');
    final name = requiredTrimmed(command.name, 'Proje adı', maxLength: 160);
    final now = _readClockOnce();
    final createdAt = CseTimeCodec.encodeUtc(now);
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final existing = await transaction.query(
          'projects',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final project = _projectFromRow(existing.single);
          if (project.name != name) {
            throw const AgendaValidationFailure(
              'Proje kimliği başka bir içerikle kullanılıyor.',
            );
          }
          return project;
        }
        await transaction.insert('projects', {
          'id': command.id,
          'name': name,
          'created_at': createdAt,
          'updated_at': createdAt,
          'revision': 1,
        });
        return MobileProject(
          id: command.id,
          name: name,
          createdAt: createdAt,
          updatedAt: createdAt,
          revision: 1,
        );
      });
    });
  }

  @override
  Future<List<AgendaLog>> listAgenda(AgendaQuery query) async {
    final bounds = CseTimeCodec.istanbulDayBounds(query.istanbulDay);
    final projectId = query.projectId;
    if (projectId != null) {
      validateUuid(projectId, 'Proje kimliği');
    }
    final search = query.literalSearch.trim();
    final where = <String>[
      'o.archived_at IS NULL',
      'o.observed_at >= ?',
      'o.observed_at < ?',
    ];
    final arguments = <Object?>[bounds.start, bounds.endExclusive];
    if (projectId != null) {
      where.add('o.project_id = ?');
      arguments.add(projectId);
    }
    if (query.category != null) {
      where.add('o.category = ?');
      arguments.add(query.category!.storageValue);
    }
    if (search.isNotEmpty) {
      where.add('''
        instr(
          lower(o.description || ' ' || coalesce(o.location, '') || ' ' ||
            coalesce(o.notes, '') || ' ' || p.name),
          lower(?)
        ) > 0
      ''');
      arguments.add(search);
    }
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.rawQuery('''
        SELECT o.*, p.name AS project_name
        FROM field_observations o
        JOIN projects p ON p.id = o.project_id
        WHERE ${where.join(' AND ')}
        ORDER BY o.observed_at ASC, o.created_at ASC, o.id ASC
      ''', arguments);
      return rows.map(_logFromRow).toList(growable: false);
    });
  }

  @override
  Future<AgendaLog> createAgendaLog(CreateAgendaLogCommand command) async {
    validateUuid(command.id, 'Log kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    validateCanonicalTimestamp(command.observedAt, 'Olay zamanı');
    final description = requiredTrimmed(
      command.description,
      'Kısa açıklama',
      maxLength: 500,
    );
    final location = optionalTrimmed(command.location, 'Mahál', maxLength: 200);
    final notes = optionalTrimmed(command.notes, 'Ayrıntılı not');
    final now = _readClockOnce();
    final observed = CseTimeCodec.decodeCanonicalUtc(command.observedAt);
    if (observed.isAfter(now)) {
      throw const AgendaValidationFailure('Gelecek tarihli olay kaydedilemez.');
    }
    final createdAt = CseTimeCodec.encodeUtc(now);
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final projects = await transaction.query(
          'projects',
          where: 'id = ? AND archived_at IS NULL',
          whereArgs: [command.projectId],
          limit: 1,
        );
        if (projects.isEmpty) {
          throw const AgendaValidationFailure('Seçilen proje bulunamadı.');
        }
        final project = _projectFromRow(projects.single);
        final existing = await transaction.rawQuery(
          '''
          SELECT o.*, p.name AS project_name
          FROM field_observations o
          JOIN projects p ON p.id = o.project_id
          WHERE o.id = ?
          LIMIT 1
        ''',
          [command.id],
        );
        if (existing.isNotEmpty) {
          final log = _logFromRow(existing.single);
          if (!_sameLogCommand(log, command, description, location, notes)) {
            throw const AgendaValidationFailure(
              'Log kimliği başka bir içerikle kullanılıyor.',
            );
          }
          return log;
        }
        await transaction.insert('field_observations', {
          'id': command.id,
          'project_id': command.projectId,
          'observed_at': command.observedAt,
          'created_at': createdAt,
          'updated_at': createdAt,
          'category': command.category.storageValue,
          'description': description,
          'location': location,
          'notes': notes,
          'revision': 1,
        });
        await transaction.insert('observation_events', {
          'id': command.eventId,
          'observation_id': command.id,
          'project_id': command.projectId,
          'event_type': 'created',
          'occurred_at': createdAt,
          'payload_json': jsonEncode({
            'category': command.category.storageValue,
            'description': description,
            'observed_at': command.observedAt,
          }),
        });
        return AgendaLog(
          id: command.id,
          projectId: command.projectId,
          projectName: project.name,
          observedAt: command.observedAt,
          createdAt: createdAt,
          updatedAt: createdAt,
          category: command.category,
          description: description,
          location: location,
          notes: notes,
          revision: 1,
        );
      });
    });
  }

  @override
  Future<AgendaLogDetail> getAgendaLogDetail(String logId) async {
    validateUuid(logId, 'Log kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final logs = await database.rawQuery(
        '''
        SELECT o.*, p.name AS project_name
        FROM field_observations o
        JOIN projects p ON p.id = o.project_id
        WHERE o.id = ? AND o.archived_at IS NULL
        LIMIT 1
      ''',
        [logId],
      );
      if (logs.isEmpty) {
        throw const AgendaValidationFailure('Ajanda kaydı bulunamadı.');
      }
      final reminders = await database.rawQuery(
        '''
        SELECT f.*, p.name AS project_name
        FROM follow_up_items f
        JOIN projects p ON p.id = f.project_id
        WHERE f.observation_id = ?
        ORDER BY f.created_at ASC, f.id ASC
      ''',
        [logId],
      );
      return AgendaLogDetail(
        log: _logFromRow(logs.single),
        reminders: reminders.map(_reminderFromRow).toList(growable: false),
      );
    });
  }

  @override
  Future<MobileReminder> createReminder(CreateReminderCommand command) async {
    validateUuid(command.id, 'Hatırlatıcı kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    validateUuid(command.sourceLogId, 'Kaynak log kimliği');
    final title = requiredTrimmed(
      command.title,
      'Hatırlatıcı metni',
      maxLength: 500,
    );
    final now = _readClockOnce();
    final schedule = _resolveSchedule(command, now);
    final createdAt = CseTimeCodec.encodeUtc(now);
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final projects = await transaction.query(
          'projects',
          where: 'id = ? AND archived_at IS NULL',
          whereArgs: [command.projectId],
          limit: 1,
        );
        if (projects.isEmpty) {
          throw const AgendaValidationFailure('Kaynak proje bulunamadı.');
        }
        final sources = await transaction.query(
          'field_observations',
          where: 'id = ? AND project_id = ? AND archived_at IS NULL',
          whereArgs: [command.sourceLogId, command.projectId],
          limit: 1,
        );
        if (sources.isEmpty) {
          throw const AgendaValidationFailure(
            'Kaynak Ajanda kaydı proje ile eşleşmiyor.',
          );
        }
        final existing = await transaction.rawQuery(
          '''
          SELECT f.*, p.name AS project_name
          FROM follow_up_items f
          JOIN projects p ON p.id = f.project_id
          WHERE f.id = ?
          LIMIT 1
        ''',
          [command.id],
        );
        if (existing.isNotEmpty) {
          final reminder = _reminderFromRow(existing.single);
          if (!_sameReminderCommand(reminder, command, title, schedule)) {
            throw const AgendaValidationFailure(
              'Hatırlatıcı kimliği başka bir içerikle kullanılıyor.',
            );
          }
          return reminder;
        }
        await transaction.insert('follow_up_items', {
          'id': command.id,
          'project_id': command.projectId,
          'observation_id': command.sourceLogId,
          'title': title,
          'item_type': command.kind.storageValue,
          'status': schedule.status.storageValue,
          'next_attention_at': schedule.nextAttentionAt,
          'revision': 1,
          'created_at': createdAt,
          'updated_at': createdAt,
        });
        await beforeReminderEventInsert?.call(transaction);
        await transaction.insert('follow_up_events', {
          'id': command.eventId,
          'follow_up_id': command.id,
          'project_id': command.projectId,
          'source_observation_id': command.sourceLogId,
          'event_type': 'created',
          'occurred_at': createdAt,
          'payload_json': jsonEncode({
            'item_type': command.kind.storageValue,
            'next_attention_at': schedule.nextAttentionAt,
            'source_observation_id': command.sourceLogId,
            'status': schedule.status.storageValue,
            'title': title,
          }),
        });
        return MobileReminder(
          id: command.id,
          projectId: command.projectId,
          projectName: _projectFromRow(projects.single).name,
          sourceLogId: command.sourceLogId,
          title: title,
          kind: command.kind,
          status: schedule.status,
          nextAttentionAt: schedule.nextAttentionAt,
          createdAt: createdAt,
          updatedAt: createdAt,
          revision: 1,
        );
      });
    });
  }

  @override
  Future<List<MobileReminder>> listReminders(ReminderViewGroup group) async {
    final now = _readClockOnce();
    final today = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
    final bounds = CseTimeCodec.istanbulDayBounds(today);
    final (where, arguments) = switch (group) {
      ReminderViewGroup.inbox => ('f.status = ?', <Object?>['inbox']),
      ReminderViewGroup.today => (
        "f.status IN ('active', 'waiting') AND f.next_attention_at < ?",
        <Object?>[bounds.endExclusive],
      ),
      ReminderViewGroup.upcoming => (
        "f.status IN ('active', 'waiting') AND f.next_attention_at >= ?",
        <Object?>[bounds.endExclusive],
      ),
    };
    return _withDatabase(now, (database) async {
      final rows = await database.rawQuery('''
        SELECT f.*, p.name AS project_name
        FROM follow_up_items f
        JOIN projects p ON p.id = f.project_id
        WHERE $where
        ORDER BY
          CASE WHEN f.next_attention_at IS NULL THEN 0 ELSE 1 END,
          f.next_attention_at ASC,
          f.created_at ASC,
          f.id ASC
      ''', arguments);
      return rows.map(_reminderFromRow).toList(growable: false);
    });
  }

  @override
  Future<MobileReminder> getReminderDetail(String reminderId) async {
    validateUuid(reminderId, 'Hatırlatıcı kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.rawQuery(
        '''
        SELECT f.*, p.name AS project_name
        FROM follow_up_items f
        JOIN projects p ON p.id = f.project_id
        WHERE f.id = ?
        LIMIT 1
      ''',
        [reminderId],
      );
      if (rows.isEmpty) {
        throw const AgendaValidationFailure('Hatırlatıcı bulunamadı.');
      }
      return _reminderFromRow(rows.single);
    });
  }

  @override
  Future<List<AppendOnlyEvent>> listObservationEvents(String logId) async {
    validateUuid(logId, 'Log kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.query(
        'observation_events',
        where: 'observation_id = ?',
        whereArgs: [logId],
        orderBy: 'occurred_at ASC, id ASC',
      );
      return rows
          .map(
            (row) => AppendOnlyEvent(
              id: row['id']! as String,
              recordId: row['observation_id']! as String,
              projectId: row['project_id']! as String,
              eventType: row['event_type']! as String,
              occurredAt: row['occurred_at']! as String,
              payloadJson: row['payload_json']! as String,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<List<AppendOnlyEvent>> listReminderEvents(String reminderId) async {
    validateUuid(reminderId, 'Hatırlatıcı kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.query(
        'follow_up_events',
        where: 'follow_up_id = ?',
        whereArgs: [reminderId],
        orderBy: 'occurred_at ASC, id ASC',
      );
      return rows
          .map(
            (row) => AppendOnlyEvent(
              id: row['id']! as String,
              recordId: row['follow_up_id']! as String,
              projectId: row['project_id']! as String,
              sourceLogId: row['source_observation_id']! as String,
              eventType: row['event_type']! as String,
              occurredAt: row['occurred_at']! as String,
              payloadJson: row['payload_json']! as String,
            ),
          )
          .toList(growable: false);
    });
  }

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

  _ResolvedReminderSchedule _resolveSchedule(
    CreateReminderCommand command,
    DateTime now,
  ) {
    String? nextAttentionAt;
    switch (command.schedule) {
      case ReminderScheduleKind.inbox:
        if (command.customAttentionAt != null) {
          throw const AgendaValidationFailure(
            'Unutma Kutusu için tarih/saat verilmemelidir.',
          );
        }
      case ReminderScheduleKind.in15Minutes:
        nextAttentionAt = CseTimeCodec.encodeUtc(
          now.add(const Duration(minutes: 15)),
        );
      case ReminderScheduleKind.in1Hour:
        nextAttentionAt = CseTimeCodec.encodeUtc(
          now.add(const Duration(hours: 1)),
        );
      case ReminderScheduleKind.todayEnd:
        final local = CseTimeCodec.toIstanbul(CseTimeCodec.encodeUtc(now));
        nextAttentionAt = CseTimeCodec.canonicalFromIstanbulComponents(
          year: local.year,
          month: local.month,
          day: local.day,
          hour: 18,
          minute: 0,
        );
      case ReminderScheduleKind.tomorrowMorning:
        final today = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
        final tomorrow = CseTimeCodec.shiftIstanbulDay(today, 1).split('-');
        nextAttentionAt = CseTimeCodec.canonicalFromIstanbulComponents(
          year: int.parse(tomorrow[0]),
          month: int.parse(tomorrow[1]),
          day: int.parse(tomorrow[2]),
          hour: 9,
          minute: 0,
        );
      case ReminderScheduleKind.custom:
        final custom = command.customAttentionAt;
        if (custom == null) {
          throw const AgendaValidationFailure(
            'Özel hatırlatıcı tarih/saat zorunludur.',
          );
        }
        validateCanonicalTimestamp(custom, 'Hatırlatıcı zamanı');
        nextAttentionAt = custom;
    }
    if (nextAttentionAt != null &&
        !CseTimeCodec.decodeCanonicalUtc(nextAttentionAt).isAfter(now)) {
      throw const AgendaValidationFailure(
        'Hatırlatıcı zamanı gelecekte olmalıdır.',
      );
    }
    final status = nextAttentionAt == null
        ? ReminderStatus.inbox
        : command.kind == ReminderKind.waiting
        ? ReminderStatus.waiting
        : ReminderStatus.active;
    return _ResolvedReminderSchedule(
      status: status,
      nextAttentionAt: nextAttentionAt,
    );
  }

  bool _sameLogCommand(
    AgendaLog log,
    CreateAgendaLogCommand command,
    String description,
    String? location,
    String? notes,
  ) {
    return log.projectId == command.projectId &&
        log.observedAt == command.observedAt &&
        log.category == command.category &&
        log.description == description &&
        log.location == location &&
        log.notes == notes;
  }

  bool _sameReminderCommand(
    MobileReminder reminder,
    CreateReminderCommand command,
    String title,
    _ResolvedReminderSchedule schedule,
  ) {
    return reminder.projectId == command.projectId &&
        reminder.sourceLogId == command.sourceLogId &&
        reminder.title == title &&
        reminder.kind == command.kind &&
        reminder.status == schedule.status &&
        reminder.nextAttentionAt == schedule.nextAttentionAt;
  }
}

class _ResolvedReminderSchedule {
  const _ResolvedReminderSchedule({
    required this.status,
    required this.nextAttentionAt,
  });

  final ReminderStatus status;
  final String? nextAttentionAt;
}

MobileProject _projectFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  validateUuid(id, 'Proje kimliği');
  validateCanonicalTimestamp(createdAt, 'Proje oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Proje güncelleme zamanı');
  return MobileProject(
    id: id,
    name: requiredTrimmed(row['name']! as String, 'Proje adı'),
    createdAt: createdAt,
    updatedAt: updatedAt,
    revision: row['revision']! as int,
  );
}

AgendaLog _logFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final projectId = row['project_id']! as String;
  final observedAt = row['observed_at']! as String;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  validateUuid(id, 'Log kimliği');
  validateUuid(projectId, 'Proje kimliği');
  validateCanonicalTimestamp(observedAt, 'Olay zamanı');
  validateCanonicalTimestamp(createdAt, 'Log oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Log güncelleme zamanı');
  return AgendaLog(
    id: id,
    projectId: projectId,
    projectName: requiredTrimmed(row['project_name']! as String, 'Proje adı'),
    observedAt: observedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    category: AgendaCategory.fromStorage(row['category']! as String),
    description: requiredTrimmed(
      row['description']! as String,
      'Kısa açıklama',
    ),
    location: row['location'] as String?,
    notes: row['notes'] as String?,
    revision: row['revision']! as int,
  );
}

MobileReminder _reminderFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final projectId = row['project_id']! as String;
  final sourceLogId = row['observation_id']! as String;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final nextAttentionAt = row['next_attention_at'] as String?;
  validateUuid(id, 'Hatırlatıcı kimliği');
  validateUuid(projectId, 'Proje kimliği');
  validateUuid(sourceLogId, 'Kaynak log kimliği');
  validateCanonicalTimestamp(createdAt, 'Hatırlatıcı oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Hatırlatıcı güncelleme zamanı');
  if (nextAttentionAt != null) {
    validateCanonicalTimestamp(nextAttentionAt, 'Hatırlatıcı zamanı');
  }
  return MobileReminder(
    id: id,
    projectId: projectId,
    projectName: requiredTrimmed(row['project_name']! as String, 'Proje adı'),
    sourceLogId: sourceLogId,
    title: requiredTrimmed(row['title']! as String, 'Hatırlatıcı metni'),
    kind: ReminderKind.fromStorage(row['item_type']! as String),
    status: ReminderStatus.fromStorage(row['status']! as String),
    nextAttentionAt: nextAttentionAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    revision: row['revision']! as int,
  );
}
