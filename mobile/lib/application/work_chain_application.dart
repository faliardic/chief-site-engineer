import 'dart:convert';

import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/work_chain_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class WorkChainApplicationPort {
  Future<WorkChainDetail> loadFromAgendaLog(String logId);

  Future<WorkChainDetail> loadFromFollowUp(String followUpId);
}

class SqliteWorkChainApplication implements WorkChainApplicationPort {
  const SqliteWorkChainApplication({
    required this.databasePath,
    required this.databaseFactory,
  });

  final String databasePath;
  final DatabaseFactory databaseFactory;

  @override
  Future<WorkChainDetail> loadFromAgendaLog(String logId) {
    final exactId = _requiredId(logId, 'work_chain_invalid_agenda_id');
    return _read((database) => _loadCanonical(database, exactId));
  }

  @override
  Future<WorkChainDetail> loadFromFollowUp(String followUpId) {
    final exactId = _requiredId(followUpId, 'work_chain_invalid_follow_up_id');
    return _read((database) async {
      final rows = await _followUpRows(database, id: exactId);
      if (rows.isEmpty) {
        return const WorkChainDetail(
          root: null,
          followUps: [],
          diagnostics: [
            WorkChainDiagnostic(code: WorkChainDiagnosticCode.followUpMissing),
          ],
        );
      }
      if (rows.length != 1) {
        return const WorkChainDetail(
          root: null,
          followUps: [],
          diagnostics: [
            WorkChainDiagnostic(
              code: WorkChainDiagnosticCode.duplicateRelation,
            ),
          ],
        );
      }
      final sourceId = _optionalText(rows.single['observation_id']);
      if (sourceId == null) {
        final followUp = await _mapFollowUp(database, rows.single);
        return WorkChainDetail(
          root: null,
          followUps: [followUp.value],
          diagnostics: [
            WorkChainDiagnostic(
              code: WorkChainDiagnosticCode.sourceObservationMismatch,
              followUpId: exactId,
            ),
            ...followUp.diagnostics,
          ],
        );
      }
      return _loadCanonical(database, sourceId, expectedFollowUpId: exactId);
    });
  }

  Future<WorkChainDetail> _loadCanonical(
    Database database,
    String logId, {
    String? expectedFollowUpId,
  }) async {
    final rootRows = await database.rawQuery(
      '''
      SELECT o.id, o.project_id, p.name AS project_name, o.observed_at,
        o.category, o.description, o.location, o.notes, o.archived_at,
        l.display_name AS stable_location_name
      FROM field_observations o
      JOIN projects p ON p.id = o.project_id
      LEFT JOIN project_locations l
        ON l.id = o.location_id AND l.project_id = o.project_id
      WHERE o.id = ?
      LIMIT 2
      ''',
      [logId],
    );
    if (rootRows.length != 1) {
      return WorkChainDetail(
        root: null,
        followUps: const [],
        diagnostics: [
          WorkChainDiagnostic(
            code: rootRows.isEmpty
                ? WorkChainDiagnosticCode.agendaMissing
                : WorkChainDiagnosticCode.duplicateRelation,
          ),
        ],
      );
    }
    final root = _mapRoot(rootRows.single);
    final rows = await _followUpRows(database, observationId: logId);
    final diagnostics = <WorkChainDiagnostic>[];
    if (rows.isEmpty) {
      diagnostics.add(
        const WorkChainDiagnostic(
          code: WorkChainDiagnosticCode.followUpMissing,
        ),
      );
    }
    final seenIds = <String>{};
    final followUps = <WorkChainFollowUp>[];
    for (final row in rows) {
      final id = _requiredText(row, 'id');
      if (!seenIds.add(id)) {
        diagnostics.add(
          WorkChainDiagnostic(
            code: WorkChainDiagnosticCode.duplicateRelation,
            followUpId: id,
          ),
        );
        continue;
      }
      final mapped = await _mapFollowUp(database, row);
      followUps.add(mapped.value);
      diagnostics.addAll(mapped.diagnostics);
      if (mapped.value.sourceObservationId != root.id) {
        diagnostics.add(
          WorkChainDiagnostic(
            code: WorkChainDiagnosticCode.sourceObservationMismatch,
            followUpId: id,
          ),
        );
      }
      if (mapped.value.projectId != root.projectId) {
        diagnostics.add(
          WorkChainDiagnostic(
            code: WorkChainDiagnosticCode.projectMismatch,
            followUpId: id,
          ),
        );
      }
    }
    if (expectedFollowUpId != null && !seenIds.contains(expectedFollowUpId)) {
      diagnostics.add(
        WorkChainDiagnostic(
          code: WorkChainDiagnosticCode.sourceObservationMismatch,
          followUpId: expectedFollowUpId,
        ),
      );
    }
    return WorkChainDetail(
      root: root,
      followUps: List.unmodifiable(followUps),
      diagnostics: List.unmodifiable(diagnostics),
    );
  }

  Future<List<Map<String, Object?>>> _followUpRows(
    Database database, {
    String? id,
    String? observationId,
  }) {
    assert((id == null) != (observationId == null));
    return database.rawQuery(
      '''
      SELECT id, project_id, observation_id, item_type, status, title,
        description, next_attention_at, all_day_local_date, deadline_at,
        condition_text, outcome_type, outcome_note, revision, created_at,
        updated_at, completed_at, cancelled_at, trashed_at
      FROM follow_up_items
      WHERE ${id == null ? 'observation_id' : 'id'} = ?
      ORDER BY created_at ASC, id ASC
      ''',
      [id ?? observationId],
    );
  }

  Future<_MappedFollowUp> _mapFollowUp(
    Database database,
    Map<String, Object?> row,
  ) async {
    final id = _requiredText(row, 'id');
    final eventRows = await database.query(
      'follow_up_events',
      where: 'follow_up_id = ?',
      whereArgs: [id],
      orderBy: 'occurred_at ASC, sequence ASC, id ASC',
    );
    final allEvents = eventRows.map(_mapEvent).toList(growable: false);
    final diagnostics = <WorkChainDiagnostic>[];
    if (allEvents.isEmpty) {
      diagnostics.add(
        WorkChainDiagnostic(
          code: WorkChainDiagnosticCode.eventOrderIntegrity,
          followUpId: id,
        ),
      );
    }
    final projectId = _optionalText(row['project_id']);
    final sourceObservationId = _optionalText(row['observation_id']);
    for (final event in allEvents) {
      if (event.followUpId != id) {
        diagnostics.add(
          WorkChainDiagnostic(
            code: WorkChainDiagnosticCode.duplicateRelation,
            followUpId: id,
            eventId: event.id,
          ),
        );
      }
      if (event.projectId != projectId) {
        diagnostics.add(
          WorkChainDiagnostic(
            code: WorkChainDiagnosticCode.projectMismatch,
            followUpId: id,
            eventId: event.id,
          ),
        );
      }
      if (event.sourceObservationId != sourceObservationId) {
        diagnostics.add(
          WorkChainDiagnostic(
            code: WorkChainDiagnosticCode.sourceObservationMismatch,
            followUpId: id,
            eventId: event.id,
          ),
        );
      }
    }
    final sequences = allEvents.map((event) => event.sequence).toList()..sort();
    for (var index = 0; index < sequences.length; index += 1) {
      if (sequences[index] != index + 1) {
        diagnostics.add(
          WorkChainDiagnostic(
            code: WorkChainDiagnosticCode.eventOrderIntegrity,
            followUpId: id,
          ),
        );
        break;
      }
    }
    final bySequence = [...allEvents]
      ..sort((left, right) {
        final sequence = left.sequence.compareTo(right.sequence);
        return sequence != 0 ? sequence : left.id.compareTo(right.id);
      });
    for (var index = 1; index < bySequence.length; index += 1) {
      if (bySequence[index].occurredAt.compareTo(
            bySequence[index - 1].occurredAt,
          ) <
          0) {
        diagnostics.add(
          WorkChainDiagnostic(
            code: WorkChainDiagnosticCode.eventOrderIntegrity,
            followUpId: id,
            eventId: bySequence[index].id,
          ),
        );
        break;
      }
    }
    final status = WorkChainFollowUpStatus.fromStorage(
      _requiredText(row, 'status'),
    );
    final projected = _projectedStatus(bySequence);
    if (projected != null && projected != status) {
      diagnostics.add(
        WorkChainDiagnostic(
          code: WorkChainDiagnosticCode.projectionContradiction,
          followUpId: id,
        ),
      );
    }
    final outcome = _optionalText(row['outcome_type']);
    final followUp = WorkChainFollowUp(
      id: id,
      projectId: projectId,
      sourceObservationId: sourceObservationId,
      kind: WorkChainFollowUpKind.fromStorage(_requiredText(row, 'item_type')),
      status: status,
      title: _requiredText(row, 'title'),
      description: _optionalText(row['description']),
      nextAttentionAt: _optionalCanonical(row['next_attention_at']),
      allDayLocalDate: _optionalDay(row['all_day_local_date']),
      deadlineAt: _optionalCanonical(row['deadline_at']),
      conditionText: _optionalText(row['condition_text']),
      revision: _requiredInt(row, 'revision'),
      createdAt: _requiredCanonical(row, 'created_at'),
      updatedAt: _requiredCanonical(row, 'updated_at'),
      trashedAt: _optionalCanonical(row['trashed_at']),
      events: List.unmodifiable(allEvents.where(_isMeaningfulEvent)),
      result: WorkChainResult(
        status: status,
        outcomeType: outcome == null
            ? null
            : WorkChainOutcomeType.fromStorage(outcome),
        note: _optionalText(row['outcome_note']),
        completedAt: _optionalCanonical(row['completed_at']),
        cancelledAt: _optionalCanonical(row['cancelled_at']),
      ),
    );
    return _MappedFollowUp(followUp, List.unmodifiable(diagnostics));
  }

  Future<T> _read<T>(Future<T> Function(Database database) action) async {
    Database? database;
    try {
      database = await databaseFactory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(singleInstance: false, readOnly: true),
      );
      if (await database.getVersion() != AppDatabase.schemaVersion) {
        throw const WorkChainFailure('work_chain_unsupported_schema');
      }
      return await action(database);
    } on WorkChainFailure {
      rethrow;
    } on Object {
      throw const WorkChainFailure('work_chain_read_failed');
    } finally {
      await database?.close();
    }
  }
}

WorkChainRoot _mapRoot(Map<String, Object?> row) => WorkChainRoot(
  id: _requiredText(row, 'id'),
  projectId: _requiredText(row, 'project_id'),
  projectName: _requiredText(row, 'project_name'),
  observedAt: _requiredCanonical(row, 'observed_at'),
  category: _requiredText(row, 'category'),
  description: _requiredText(row, 'description'),
  location:
      _optionalText(row['stable_location_name']) ??
      _optionalText(row['location']),
  notes: _optionalText(row['notes']),
  archivedAt: _optionalCanonical(row['archived_at']),
);

WorkChainEvent _mapEvent(Map<String, Object?> row) {
  final payloadValue = jsonDecode(
    _requiredText(row, 'payload_json', trim: false),
  );
  if (payloadValue is! Map) throw const FormatException();
  return WorkChainEvent(
    id: _requiredText(row, 'id'),
    followUpId: _requiredText(row, 'follow_up_id'),
    projectId: _optionalText(row['project_id']),
    sourceObservationId: _optionalText(row['source_observation_id']),
    sequence: _requiredInt(row, 'sequence'),
    eventType: _requiredText(row, 'event_type'),
    occurredAt: _requiredCanonical(row, 'occurred_at'),
    payload: Map.unmodifiable(payloadValue.cast<String, Object?>()),
  );
}

WorkChainFollowUpStatus? _projectedStatus(List<WorkChainEvent> events) {
  for (final event in events.reversed) {
    final status = event.payload['status'];
    if (status is String) {
      try {
        return WorkChainFollowUpStatus.fromStorage(status);
      } on FormatException {
        return null;
      }
    }
    final implied = switch (event.eventType) {
      'completed' => WorkChainFollowUpStatus.completed,
      'cancelled' => WorkChainFollowUpStatus.cancelled,
      'moved_to_inbox' => WorkChainFollowUpStatus.inbox,
      'scheduled' ||
      'rescheduled' ||
      'waiting_started' ||
      'snoozed' => WorkChainFollowUpStatus.active,
      _ => null,
    };
    if (implied != null) return implied;
  }
  return null;
}

const _meaningfulEventTypes = {
  'created',
  'scheduled',
  'rescheduled',
  'details_updated',
  'waiting_started',
  'legacy_waiting_normalized',
  'snoozed',
  'completed',
  'cancelled',
  'reopened',
  'moved_to_inbox',
  'trashed',
  'restored_from_trash',
};

bool _isMeaningfulEvent(WorkChainEvent event) =>
    _meaningfulEventTypes.contains(event.eventType);

String _requiredId(String value, String code) {
  if (value.isEmpty || value != value.trim()) throw WorkChainFailure(code);
  return value;
}

String _requiredText(Map<String, Object?> row, String key, {bool trim = true}) {
  final value = row[key];
  if (value is! String || value.isEmpty || (trim && value != value.trim())) {
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

int _requiredInt(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! int || value < 1) throw const FormatException();
  return value;
}

String _requiredCanonical(Map<String, Object?> row, String key) {
  final value = _requiredText(row, key);
  CseTimeCodec.decodeCanonicalUtc(value);
  return value;
}

String? _optionalCanonical(Object? value) {
  final text = _optionalText(value);
  if (text != null) CseTimeCodec.decodeCanonicalUtc(text);
  return text;
}

String? _optionalDay(Object? value) {
  final text = _optionalText(value);
  if (text != null) CseTimeCodec.validateIstanbulDay(text);
  return text;
}

class _MappedFollowUp {
  const _MappedFollowUp(this.value, this.diagnostics);

  final WorkChainFollowUp value;
  final List<WorkChainDiagnostic> diagnostics;
}
