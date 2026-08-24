import 'dart:convert';

import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/daily_log_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class DailyLogApplicationPort {
  Future<List<DailyLogProject>> listProjects();

  Future<DailyLogDay> loadDay({
    required String projectId,
    required String localDay,
  });
}

class SqliteDailyLogApplication implements DailyLogApplicationPort {
  const SqliteDailyLogApplication({
    required this.databasePath,
    required this.databaseFactory,
  });

  final String databasePath;
  final DatabaseFactory databaseFactory;

  @override
  Future<List<DailyLogProject>> listProjects() {
    return _read((database) async {
      final rows = await database.query(
        'projects',
        columns: ['id', 'name'],
        where: 'archived_at IS NULL',
        orderBy: 'name COLLATE NOCASE ASC, id ASC',
      );
      return List.unmodifiable(
        rows.map(
          (row) => DailyLogProject(
            id: _requiredText(row, 'id'),
            name: _requiredText(row, 'name'),
          ),
        ),
      );
    });
  }

  @override
  Future<DailyLogDay> loadDay({
    required String projectId,
    required String localDay,
  }) {
    final exactProjectId = _requiredInput(
      projectId,
      'daily_log_invalid_project',
    );
    try {
      CseTimeCodec.validateIstanbulDay(localDay);
    } on Object {
      throw const DailyLogFailure('daily_log_invalid_day');
    }
    final bounds = CseTimeCodec.istanbulDayBounds(localDay);
    return _read((database) async {
      final projectRows = await database.query(
        'projects',
        columns: ['id', 'name'],
        where: 'id = ? AND archived_at IS NULL',
        whereArgs: [exactProjectId],
        limit: 2,
      );
      if (projectRows.length != 1) {
        throw const DailyLogFailure('daily_log_project_unavailable');
      }
      final projectName = _requiredText(projectRows.single, 'name');

      final attendance = await _loadSection(
        DailyLogSectionKind.attendance,
        () => _loadAttendance(database, exactProjectId, localDay),
      );
      final livingPlan = await _loadSection(
        DailyLogSectionKind.livingPlan,
        () => _loadLivingPlan(
          database,
          exactProjectId,
          bounds.start,
          bounds.endExclusive,
        ),
      );
      final concrete = await _loadSection(
        DailyLogSectionKind.concrete,
        () => _loadConcrete(
          database,
          exactProjectId,
          bounds.start,
          bounds.endExclusive,
        ),
      );
      final agenda = await _loadSection(
        DailyLogSectionKind.agenda,
        () => _loadAgenda(
          database,
          exactProjectId,
          bounds.start,
          bounds.endExclusive,
        ),
      );
      final followUps = await _loadSection(
        DailyLogSectionKind.openFollowUps,
        () => _loadOpenFollowUps(database, exactProjectId),
      );
      final sourceSections = [
        attendance,
        livingPlan,
        concrete,
        agenda,
        followUps,
      ];
      final sourceCount = sourceSections.fold<int>(
        0,
        (count, section) => count + section.entries.length,
      );
      final unavailableCount = sourceSections
          .where((section) => !section.isAvailable)
          .length;
      final summary = DailyLogSection.summary(
        text: _summaryText(sourceCount, unavailableCount),
      );
      return DailyLogDay(
        projectId: exactProjectId,
        projectName: projectName,
        localDay: localDay,
        sections: [summary, ...sourceSections],
      );
    });
  }

  Future<DailyLogSection> _loadSection(
    DailyLogSectionKind kind,
    Future<List<DailyLogEntry>> Function() loader,
  ) async {
    try {
      return DailyLogSection.available(kind: kind, entries: await loader());
    } on Object {
      return DailyLogSection.unavailable(
        kind: kind,
        failure: DailyLogSectionFailure(
          code: 'daily_log_${kind.name}_unavailable',
          message: '${kind.title} bölümü okunamadı',
        ),
      );
    }
  }

  Future<List<DailyLogEntry>> _loadAttendance(
    Database database,
    String projectId,
    String localDay,
  ) async {
    final days = await database.query(
      'attendance_days',
      columns: ['id', 'status', 'general_note'],
      where: 'project_id = ? AND local_date = ?',
      whereArgs: [projectId, localDay],
      limit: 2,
    );
    if (days.isEmpty) return const [];
    if (days.length != 1) throw const FormatException();
    final day = days.single;
    final dayId = _requiredText(day, 'id');
    final status = _requiredText(day, 'status');
    final entries = await database.query(
      'attendance_entries',
      columns: ['id', 'result'],
      where: 'attendance_day_id = ? AND removed_at IS NULL',
      whereArgs: [dayId],
      orderBy: 'id ASC',
    );
    var presentCount = 0;
    for (final entry in entries) {
      final result = _requiredText(entry, 'result');
      if (result == 'full_day' || result == 'half_day') {
        presentCount += 1;
      } else if (result != 'absent' && result != 'leave') {
        throw const FormatException();
      }
    }
    final note = _optionalText(day['general_note']);
    final statusText = switch (status) {
      'draft' => 'Taslak',
      'completed' => 'Tamamlandı',
      'no_work' => 'Çalışma yok',
      _ => throw const FormatException(),
    };
    final text = StringBuffer()
      ..write('$presentCount kişi sahada · ${entries.length} kişi kayıtlı')
      ..write(' · $statusText');
    if (note != null) text.write(' · Not: $note');
    return [
      DailyLogEntry(
        id: 'attendance:$dayId',
        text: text.toString(),
        sourceRefs: [
          DailyLogSourceRef(
            kind: DailyLogSourceKind.attendanceDay,
            sourceId: dayId,
          ),
        ],
      ),
    ];
  }

  Future<List<DailyLogEntry>> _loadLivingPlan(
    Database database,
    String projectId,
    String start,
    String endExclusive,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT e.id, e.living_plan_item_id, e.event_type, e.occurred_at,
        e.payload_json, i.activity_name_snapshot
      FROM project_living_plan_events e
      JOIN project_living_plan_items i
        ON i.id = e.living_plan_item_id AND i.project_id = e.project_id
      WHERE e.project_id = ?
        AND e.occurred_at >= ? AND e.occurred_at < ?
      ORDER BY e.occurred_at ASC, e.id ASC
      ''',
      [projectId, start, endExclusive],
    );
    return List.unmodifiable(rows.map(_livingPlanEntry));
  }

  DailyLogEntry _livingPlanEntry(Map<String, Object?> row) {
    final eventId = _requiredText(row, 'id');
    final itemId = _requiredText(row, 'living_plan_item_id');
    final eventType = _requiredText(row, 'event_type');
    final occurredAt = _canonicalTimestamp(row, 'occurred_at');
    final activityName = _requiredText(row, 'activity_name_snapshot');
    final payload = _jsonObject(
      _requiredText(row, 'payload_json', trim: false),
    );
    final resultValue = payload['result'];
    if (resultValue is! Map) throw const FormatException();
    final result = resultValue.cast<String, Object?>();
    final status = _requiredJsonText(result, 'status');
    final plannedDate = _requiredJsonText(result, 'planned_date');
    CseTimeCodec.validateIstanbulDay(plannedDate);
    final progress = result['progress_percent'];
    if (progress != null &&
        (progress is! int || progress < 0 || progress > 100)) {
      throw const FormatException();
    }
    final note = _optionalText(result['note']);
    final statusLabel = _livingPlanStatusLabel(status);
    final progressText = progress == null ? '' : ' · %$progress';
    final text = switch (eventType) {
      'CREATED' => '$activityName: Plana eklendi · $statusLabel$progressText',
      'STARTED' => '$activityName: Başladı$progressText',
      'COMPLETED' => '$activityName: Tamamlandı · %100',
      'DEFERRED' =>
        '$activityName: Ertelendi · ${CseTimeCodec.formatIstanbulDay(plannedDate)}$progressText',
      'REOPENED' =>
        '$activityName: Yeniden açıldı · $statusLabel · İlerleme girilmedi',
      'NOTE_UPDATED' =>
        note == null
            ? '$activityName: Not kaldırıldı'
            : '$activityName: Not güncellendi · $note',
      'PROGRESS_UPDATED' =>
        progress == null
            ? throw const FormatException()
            : '$activityName: İlerleme %$progress',
      _ => throw const FormatException(),
    };
    return DailyLogEntry(
      id: 'living-plan-event:$eventId',
      text: text,
      occurredAt: occurredAt,
      sourceRefs: [
        DailyLogSourceRef(
          kind: DailyLogSourceKind.livingPlanItem,
          sourceId: itemId,
        ),
        DailyLogSourceRef(
          kind: DailyLogSourceKind.livingPlanEvent,
          sourceId: eventId,
        ),
      ],
    );
  }

  Future<List<DailyLogEntry>> _loadConcrete(
    Database database,
    String projectId,
    String start,
    String endExclusive,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT id, pour_code, element_location, concrete_class,
        planned_volume_m3, status, planned_at, actual_started_at,
        actual_ended_at
      FROM concrete_pours
      WHERE project_id = ? AND (
        (planned_at >= ? AND planned_at < ?)
        OR (actual_started_at >= ? AND actual_started_at < ?)
        OR (actual_ended_at >= ? AND actual_ended_at < ?)
      )
      ORDER BY id ASC
      ''',
      [
        projectId,
        start,
        endExclusive,
        start,
        endExclusive,
        start,
        endExclusive,
      ],
    );
    final entries = <DailyLogEntry>[];
    for (final row in rows) {
      final id = _requiredText(row, 'id');
      final timestamps = <String>[];
      for (final key in [
        'planned_at',
        'actual_started_at',
        'actual_ended_at',
      ]) {
        final value = _optionalText(row[key]);
        if (value != null &&
            value.compareTo(start) >= 0 &&
            value.compareTo(endExclusive) < 0) {
          CseTimeCodec.decodeCanonicalUtc(value);
          timestamps.add(value);
        }
      }
      if (timestamps.isEmpty) throw const FormatException();
      timestamps.sort();
      entries.add(
        DailyLogEntry(
          id: 'concrete:$id',
          occurredAt: timestamps.first,
          text:
              '${_requiredText(row, 'pour_code')} · '
              '${_requiredText(row, 'element_location')} · '
              '${_requiredText(row, 'concrete_class')} · '
              '${_formatNumber(row['planned_volume_m3'])} m³ · '
              '${_concreteStatusLabel(_requiredText(row, 'status'))}',
          sourceRefs: [
            DailyLogSourceRef(
              kind: DailyLogSourceKind.concretePour,
              sourceId: id,
            ),
          ],
        ),
      );
    }
    entries.sort(_compareEntries);
    return List.unmodifiable(entries);
  }

  Future<List<DailyLogEntry>> _loadAgenda(
    Database database,
    String projectId,
    String start,
    String endExclusive,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT o.id, o.observed_at, o.category, o.description, o.location,
        o.notes, l.display_name AS stable_location_name
      FROM field_observations o
      LEFT JOIN project_locations l
        ON l.id = o.location_id AND l.project_id = o.project_id
      WHERE o.project_id = ? AND o.archived_at IS NULL
        AND o.observed_at >= ? AND o.observed_at < ?
      ORDER BY o.observed_at ASC, o.id ASC
      ''',
      [projectId, start, endExclusive],
    );
    return List.unmodifiable(
      rows.map((row) {
        final id = _requiredText(row, 'id');
        final location =
            _optionalText(row['stable_location_name']) ??
            _optionalText(row['location']);
        final note = _optionalText(row['notes']);
        final text = StringBuffer()
          ..write('${_agendaCategoryLabel(_requiredText(row, 'category'))}: ')
          ..write(_requiredText(row, 'description'));
        if (location != null) text.write(' · $location');
        if (note != null) text.write(' · $note');
        return DailyLogEntry(
          id: 'agenda:$id',
          occurredAt: _canonicalTimestamp(row, 'observed_at'),
          text: text.toString(),
          sourceRefs: [
            DailyLogSourceRef(kind: DailyLogSourceKind.agendaLog, sourceId: id),
          ],
        );
      }),
    );
  }

  Future<List<DailyLogEntry>> _loadOpenFollowUps(
    Database database,
    String projectId,
  ) async {
    final rows = await database.query(
      'follow_up_items',
      columns: ['id', 'title', 'status', 'next_attention_at', 'created_at'],
      where: '''
        project_id = ? AND trashed_at IS NULL
        AND status IN ('inbox', 'active')
      ''',
      whereArgs: [projectId],
      orderBy: 'coalesce(next_attention_at, created_at) ASC, id ASC',
    );
    return List.unmodifiable(
      rows.map((row) {
        final id = _requiredText(row, 'id');
        final nextAttentionAt = _optionalText(row['next_attention_at']);
        if (nextAttentionAt != null) {
          CseTimeCodec.decodeCanonicalUtc(nextAttentionAt);
        }
        CseTimeCodec.decodeCanonicalUtc(_requiredText(row, 'created_at'));
        return DailyLogEntry(
          id: 'reminder:$id',
          occurredAt: nextAttentionAt,
          text:
              '${_requiredText(row, 'title')} · '
              '${_followUpStatusLabel(_requiredText(row, 'status'))}',
          sourceRefs: [
            DailyLogSourceRef(kind: DailyLogSourceKind.reminder, sourceId: id),
          ],
        );
      }),
    );
  }

  Future<T> _read<T>(Future<T> Function(Database database) action) async {
    Database? database;
    try {
      database = await databaseFactory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(singleInstance: false, readOnly: true),
      );
      if (await database.getVersion() != AppDatabase.schemaVersion) {
        throw const DailyLogFailure('daily_log_unsupported_schema');
      }
      return await action(database);
    } on DailyLogFailure {
      rethrow;
    } on Object {
      throw const DailyLogFailure('daily_log_read_failed');
    } finally {
      await database?.close();
    }
  }
}

String _summaryText(int sourceCount, int unavailableCount) {
  final sourceText = sourceCount == 0
      ? 'Bu gün için kaynak kaydı bulunamadı'
      : '$sourceCount kaynak kaydı derlendi';
  return unavailableCount == 0
      ? sourceText
      : '$sourceText · $unavailableCount bölüm kullanılamadı';
}

String _requiredInput(String value, String code) {
  if (value.isEmpty || value != value.trim()) throw DailyLogFailure(code);
  return value;
}

String _requiredText(Map<String, Object?> row, String key, {bool trim = true}) {
  final value = row[key];
  if (value is! String || value.isEmpty || (trim && value != value.trim())) {
    throw const FormatException();
  }
  return value;
}

String _requiredJsonText(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! String || value.isEmpty || value != value.trim()) {
    throw const FormatException();
  }
  return value;
}

String? _optionalText(Object? value) {
  if (value == null) return null;
  if (value is! String || value.isEmpty || value != value.trim()) {
    throw const FormatException();
  }
  return value;
}

String _canonicalTimestamp(Map<String, Object?> row, String key) {
  final value = _requiredText(row, key);
  CseTimeCodec.decodeCanonicalUtc(value);
  return value;
}

Map<String, Object?> _jsonObject(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! Map) throw const FormatException();
  return decoded.cast<String, Object?>();
}

String _livingPlanStatusLabel(String value) => switch (value) {
  'PLANNED' => 'Planlandı',
  'STARTED' => 'Başladı',
  'COMPLETED' => 'Tamamlandı',
  'DEFERRED' => 'Ertelendi',
  _ => throw const FormatException(),
};

String _concreteStatusLabel(String value) => switch (value) {
  'draft' => 'Taslak',
  'prepared' => 'Hazır',
  'pouring' => 'Dökülüyor',
  'poured' => 'Döküm bitti',
  'follow_up' => 'Takipte',
  'closed' => 'Kapalı',
  'cancelled' => 'İptal',
  _ => throw const FormatException(),
};

String _agendaCategoryLabel(String value) => switch (value) {
  'general_note' => 'Genel not',
  'manufacturing' => 'İmalat',
  'inspection' => 'Kontrol',
  'meeting_decision' => 'Toplantı kararı',
  'delivery' => 'Teslimat',
  'safety' => 'İSG',
  'concrete' => 'Beton',
  'issue_delay' => 'Sorun / gecikme',
  _ => throw const FormatException(),
};

String _followUpStatusLabel(String value) => switch (value) {
  'inbox' => 'Unutma kutusu',
  'active' => 'Açık',
  _ => throw const FormatException(),
};

String _formatNumber(Object? value) {
  if (value is int) return value.toString();
  if (value is double && value.isFinite) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
  throw const FormatException();
}

int _compareEntries(DailyLogEntry left, DailyLogEntry right) {
  final leftTime = left.occurredAt ?? '';
  final rightTime = right.occurredAt ?? '';
  final byTime = leftTime.compareTo(rightTime);
  return byTime != 0 ? byTime : left.id.compareTo(right.id);
}
