import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

enum ProjectSearchSourceKind { agendaObservation, concretePour }

enum ProjectSearchMatchQuality { exact, prefix, substring }

class ProjectSearchQuery {
  const ProjectSearchQuery({required this.projectId, required this.query});

  final String projectId;
  final String query;
}

class ProjectSearchResult {
  const ProjectSearchResult({
    required this.projectId,
    required this.sourceKind,
    required this.sourceId,
    required this.title,
    required this.summary,
    required this.sourceDate,
    required this.statusLabel,
    required this.matchQuality,
  });

  final String projectId;
  final ProjectSearchSourceKind sourceKind;
  final String sourceId;
  final String title;
  final String summary;
  final String sourceDate;
  final String statusLabel;
  final ProjectSearchMatchQuality matchQuality;

  String get identity => '$projectId:${sourceKind.name}:$sourceId';
}

class ProjectSearchSourceFailure {
  const ProjectSearchSourceFailure({
    required this.sourceKind,
    required this.code,
  });

  final ProjectSearchSourceKind sourceKind;
  final String code;
}

class ProjectSearchResponse {
  const ProjectSearchResponse({required this.results, required this.failures});

  final List<ProjectSearchResult> results;
  final List<ProjectSearchSourceFailure> failures;
}

class ProjectSearchFailure implements Exception {
  const ProjectSearchFailure(this.code);

  final String code;
}

abstract interface class ProjectSearchApplicationPort {
  Future<ProjectSearchResponse> search(ProjectSearchQuery query);
}

class SqliteProjectSearchApplication implements ProjectSearchApplicationPort {
  SqliteProjectSearchApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.coordinator,
  });

  static const perSourceLimit = 10;
  static const overallLimit = 20;

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final MobileOperationCoordinator coordinator;

  @override
  Future<ProjectSearchResponse> search(ProjectSearchQuery query) {
    final projectId = _requiredExactInput(
      query.projectId,
      'project_search_project_required',
    );
    final literalQuery = query.query.trim();
    if (literalQuery.isEmpty) {
      return Future.value(
        const ProjectSearchResponse(results: [], failures: []),
      );
    }
    return coordinator.run(() async {
      Database? database;
      try {
        database = await databaseFactory.openDatabase(
          databasePath,
          options: OpenDatabaseOptions(singleInstance: false, readOnly: true),
        );
        if (await database.getVersion() != AppDatabase.schemaVersion) {
          throw const ProjectSearchFailure('project_search_unsupported_schema');
        }
        final projects = await database.query(
          'projects',
          columns: ['id'],
          where: 'id = ? AND archived_at IS NULL',
          whereArgs: [projectId],
          limit: 2,
        );
        if (projects.length != 1 || projects.single['id'] != projectId) {
          throw const ProjectSearchFailure(
            'project_search_project_unavailable',
          );
        }

        final failures = <ProjectSearchSourceFailure>[];
        final results = <ProjectSearchResult>[];
        try {
          results.addAll(
            await _searchAgenda(database, projectId, literalQuery),
          );
        } on Object {
          failures.add(
            const ProjectSearchSourceFailure(
              sourceKind: ProjectSearchSourceKind.agendaObservation,
              code: 'project_search_agenda_read_failed',
            ),
          );
        }
        try {
          results.addAll(
            await _searchConcrete(database, projectId, literalQuery),
          );
        } on Object {
          failures.add(
            const ProjectSearchSourceFailure(
              sourceKind: ProjectSearchSourceKind.concretePour,
              code: 'project_search_concrete_read_failed',
            ),
          );
        }
        results.sort(_compareResults);
        return ProjectSearchResponse(
          results: List.unmodifiable(results.take(overallLimit)),
          failures: List.unmodifiable(failures),
        );
      } on ProjectSearchFailure {
        rethrow;
      } on Object {
        throw const ProjectSearchFailure('project_search_read_failed');
      } finally {
        await database?.close();
      }
    });
  }

  Future<List<ProjectSearchResult>> _searchAgenda(
    Database database,
    String projectId,
    String literalQuery,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT observation.id, observation.project_id,
        observation.description, observation.observed_at,
        observation.category, observation.location, observation.notes,
        location.display_name AS stable_location_name,
        CASE
          WHEN lower(trim(observation.description)) = lower(?) THEN 0
          WHEN instr(lower(trim(observation.description)), lower(?)) = 1 THEN 1
          ELSE 2
        END AS match_rank
      FROM field_observations AS observation
      LEFT JOIN project_locations AS location
        ON location.id = observation.location_id
        AND location.project_id = observation.project_id
      WHERE observation.project_id = ?
        AND observation.archived_at IS NULL
        AND instr(
          lower(
            coalesce(observation.description, '') || ' ' ||
            coalesce(observation.category, '') || ' ' ||
            coalesce(observation.location, '') || ' ' ||
            coalesce(location.display_name, '') || ' ' ||
            coalesce(observation.notes, '')
          ),
          lower(?)
        ) > 0
      ORDER BY match_rank ASC, observation.observed_at DESC,
        observation.id ASC
      LIMIT $perSourceLimit
      ''',
      [literalQuery, literalQuery, projectId, literalQuery],
    );
    return List.unmodifiable(rows.map((row) => _agendaResult(row, projectId)));
  }

  Future<List<ProjectSearchResult>> _searchConcrete(
    Database database,
    String projectId,
    String literalQuery,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT pour.id, pour.project_id, pour.pour_code,
        pour.element_location, pour.block_name, pour.floor_name,
        pour.axis_name, pour.concrete_class, pour.status,
        pour.general_note, pour.planned_at, pour.actual_started_at,
        pour.actual_ended_at,
        location.display_name AS stable_location_name,
        coalesce(pour.actual_ended_at, pour.actual_started_at, pour.planned_at)
          AS source_date,
        CASE
          WHEN lower(trim(pour.pour_code)) = lower(?) THEN 0
          WHEN instr(lower(trim(pour.pour_code)), lower(?)) = 1 THEN 1
          ELSE 2
        END AS match_rank
      FROM concrete_pours AS pour
      LEFT JOIN project_locations AS location
        ON location.id = pour.location_id
        AND location.project_id = pour.project_id
      WHERE pour.project_id = ?
        AND instr(
          lower(
            coalesce(pour.pour_code, '') || ' ' ||
            coalesce(pour.element_location, '') || ' ' ||
            coalesce(location.display_name, '') || ' ' ||
            coalesce(pour.block_name, '') || ' ' ||
            coalesce(pour.floor_name, '') || ' ' ||
            coalesce(pour.axis_name, '') || ' ' ||
            coalesce(pour.concrete_class, '') || ' ' ||
            coalesce(pour.status, '') || ' ' ||
            coalesce(pour.general_note, '')
          ),
          lower(?)
        ) > 0
      ORDER BY match_rank ASC, source_date DESC, pour.id ASC
      LIMIT $perSourceLimit
      ''',
      [literalQuery, literalQuery, projectId, literalQuery],
    );
    return List.unmodifiable(
      rows.map((row) => _concreteResult(row, projectId)),
    );
  }
}

ProjectSearchResult _agendaResult(
  Map<String, Object?> row,
  String expectedProjectId,
) {
  final sourceId = _requiredStoredText(row['id']);
  final projectId = _requiredStoredText(row['project_id']);
  final title = _requiredStoredText(row['description']);
  final sourceDate = _requiredStoredText(row['observed_at']);
  final category = AgendaCategory.fromStorage(
    _requiredStoredText(row['category']),
  );
  if (!RecordId.isUuid(sourceId) ||
      projectId != expectedProjectId ||
      DateTime.tryParse(sourceDate) == null) {
    throw const ProjectSearchFailure('project_search_agenda_ownership_invalid');
  }
  final location =
      _safeStoredText(row['stable_location_name']) ??
      _safeStoredText(row['location']);
  return ProjectSearchResult(
    projectId: projectId,
    sourceKind: ProjectSearchSourceKind.agendaObservation,
    sourceId: sourceId,
    title: title,
    summary: [category.label, if (location != null) location].join(' • '),
    sourceDate: sourceDate,
    statusLabel: 'Aktif',
    matchQuality: _matchQuality(row['match_rank']),
  );
}

ProjectSearchResult _concreteResult(
  Map<String, Object?> row,
  String expectedProjectId,
) {
  final sourceId = _requiredStoredText(row['id']);
  final projectId = _requiredStoredText(row['project_id']);
  final title = _requiredStoredText(row['pour_code']);
  final sourceDate = _requiredStoredText(row['source_date']);
  final status = ConcretePourStatus.fromStorage(
    _requiredStoredText(row['status']),
  );
  if (!RecordId.isUuid(sourceId) ||
      projectId != expectedProjectId ||
      DateTime.tryParse(sourceDate) == null) {
    throw const ProjectSearchFailure(
      'project_search_concrete_ownership_invalid',
    );
  }
  final location =
      _safeStoredText(row['stable_location_name']) ??
      _safeStoredText(row['element_location']);
  final concreteClass = _requiredStoredText(row['concrete_class']);
  return ProjectSearchResult(
    projectId: projectId,
    sourceKind: ProjectSearchSourceKind.concretePour,
    sourceId: sourceId,
    title: title,
    summary: [if (location != null) location, concreteClass].join(' • '),
    sourceDate: sourceDate,
    statusLabel: status.label,
    matchQuality: _matchQuality(row['match_rank']),
  );
}

ProjectSearchMatchQuality _matchQuality(Object? value) => switch (value) {
  0 => ProjectSearchMatchQuality.exact,
  1 => ProjectSearchMatchQuality.prefix,
  2 => ProjectSearchMatchQuality.substring,
  _ => throw const ProjectSearchFailure('project_search_match_invalid'),
};

int _compareResults(ProjectSearchResult left, ProjectSearchResult right) {
  var comparison = left.matchQuality.index.compareTo(right.matchQuality.index);
  if (comparison != 0) return comparison;
  comparison = DateTime.parse(
    right.sourceDate,
  ).compareTo(DateTime.parse(left.sourceDate));
  if (comparison != 0) return comparison;
  comparison = left.sourceKind.index.compareTo(right.sourceKind.index);
  if (comparison != 0) return comparison;
  return left.sourceId.compareTo(right.sourceId);
}

String _requiredExactInput(String value, String code) {
  if (!RecordId.isUuid(value) || value.trim() != value) {
    throw ProjectSearchFailure(code);
  }
  return value;
}

String _requiredStoredText(Object? value) {
  final result = _safeStoredText(value);
  if (result == null) {
    throw const ProjectSearchFailure('project_search_corrupt_row');
  }
  return result;
}

String? _safeStoredText(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
