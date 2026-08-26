import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/domain/context_suggestion_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class ContextSuggestionApplication {
  Future<List<ContextSuggestion>> suggestPeopleAndCompanies(
    ContextSuggestionQuery query,
  );
}

class SqliteContextSuggestionApplication
    implements ContextSuggestionApplication {
  SqliteContextSuggestionApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.coordinator,
  });

  static const maximumSuggestionCount = 8;

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final MobileOperationCoordinator coordinator;

  @override
  Future<List<ContextSuggestion>> suggestPeopleAndCompanies(
    ContextSuggestionQuery query,
  ) {
    final projectId = _requiredInput(
      query.projectId,
      'context_suggestion_project_required',
    );
    if (query.limit < 1 || query.limit > maximumSuggestionCount) {
      throw const ContextSuggestionFailure('context_suggestion_limit_invalid');
    }
    final normalizedQuery = _normalizeForComparison(query.query);
    return coordinator.run(() async {
      Database? database;
      try {
        database = await databaseFactory.openDatabase(
          databasePath,
          options: OpenDatabaseOptions(singleInstance: false, readOnly: true),
        );
        if (await database.getVersion() != AppDatabase.schemaVersion) {
          throw const ContextSuggestionFailure(
            'context_suggestion_unsupported_schema',
          );
        }
        final history = await _loadHistory(database, projectId);
        final candidates = <_RankedSuggestion>[];
        final canonicalDisplays = <String>{};

        final people = await database.query(
          'workforce_members',
          columns: ['id', 'project_id', 'full_name'],
          where: 'project_id = ? AND is_active = 1',
          whereArgs: [projectId],
          orderBy: 'full_name COLLATE NOCASE ASC, id ASC',
        );
        for (final row in people) {
          final sourceId = _safeStoredText(row['id']);
          final rowProjectId = _safeStoredText(row['project_id']);
          final displayValue = _safeStoredText(row['full_name']);
          if (sourceId == null ||
              rowProjectId != projectId ||
              displayValue == null) {
            continue;
          }
          final matchQuality = _matchQuality(displayValue, normalizedQuery);
          if (matchQuality == null) continue;
          canonicalDisplays.add(displayValue);
          final usage = history[displayValue];
          candidates.add(
            _RankedSuggestion(
              suggestion: ContextSuggestion(
                kind: ContextSuggestionKind.person,
                displayValue: displayValue,
                sourceType: ContextSuggestionSourceType.workforceMember,
                sourceId: sourceId,
                projectId: projectId,
                reasonCode: ContextSuggestionReasonCode.activeDirectoryPerson,
                matchQuality: matchQuality,
                historicalUsageCount: usage?.count ?? 0,
                historicalLastUsedAt: usage?.lastUsedAt,
              ),
              normalizedDisplay: _normalizeForComparison(displayValue),
            ),
          );
        }

        final companies = await database.query(
          'subcontractors',
          columns: ['id', 'project_id', 'name'],
          where: "project_id = ? AND status = 'active'",
          whereArgs: [projectId],
          orderBy: 'name_normalized ASC, id ASC',
        );
        for (final row in companies) {
          final sourceId = _safeStoredText(row['id']);
          final rowProjectId = _safeStoredText(row['project_id']);
          final displayValue = _safeStoredText(row['name']);
          if (sourceId == null ||
              rowProjectId != projectId ||
              displayValue == null) {
            continue;
          }
          final matchQuality = _matchQuality(displayValue, normalizedQuery);
          if (matchQuality == null) continue;
          canonicalDisplays.add(displayValue);
          final usage = history[displayValue];
          candidates.add(
            _RankedSuggestion(
              suggestion: ContextSuggestion(
                kind: ContextSuggestionKind.company,
                displayValue: displayValue,
                sourceType: ContextSuggestionSourceType.subcontractor,
                sourceId: sourceId,
                projectId: projectId,
                reasonCode: ContextSuggestionReasonCode.activeDirectoryCompany,
                matchQuality: matchQuality,
                historicalUsageCount: usage?.count ?? 0,
                historicalLastUsedAt: usage?.lastUsedAt,
              ),
              normalizedDisplay: _normalizeForComparison(displayValue),
            ),
          );
        }

        for (final entry in history.entries) {
          if (canonicalDisplays.contains(entry.key)) continue;
          final matchQuality = _matchQuality(entry.key, normalizedQuery);
          if (matchQuality == null) continue;
          candidates.add(
            _RankedSuggestion(
              suggestion: ContextSuggestion(
                kind: ContextSuggestionKind.person,
                displayValue: entry.key,
                sourceType: ContextSuggestionSourceType.historicalRelatedPerson,
                sourceId: null,
                projectId: projectId,
                reasonCode: ContextSuggestionReasonCode.previousProjectUsage,
                matchQuality: matchQuality,
                historicalUsageCount: entry.value.count,
                historicalLastUsedAt: entry.value.lastUsedAt,
              ),
              normalizedDisplay: _normalizeForComparison(entry.key),
            ),
          );
        }

        candidates.sort(_compareSuggestions);
        return List.unmodifiable(
          candidates.take(query.limit).map((candidate) => candidate.suggestion),
        );
      } on ContextSuggestionFailure {
        rethrow;
      } on Object {
        throw const ContextSuggestionFailure('context_suggestion_read_failed');
      } finally {
        await database?.close();
      }
    });
  }

  Future<Map<String, _HistoricalUsage>> _loadHistory(
    Database database,
    String projectId,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT related_person, COUNT(*) AS usage_count,
        MAX(updated_at) AS last_used_at
      FROM follow_up_items
      WHERE project_id = ? AND trashed_at IS NULL
        AND related_person IS NOT NULL
        AND trim(related_person) <> ''
      GROUP BY related_person
      ORDER BY related_person ASC
      ''',
      [projectId],
    );
    final result = <String, _HistoricalUsage>{};
    for (final row in rows) {
      final displayValue = _safeStoredText(row['related_person']);
      final count = row['usage_count'];
      final lastUsedAt = _safeStoredText(row['last_used_at']);
      if (displayValue == null || count is! int || count < 1) continue;
      result[displayValue] = _HistoricalUsage(
        count: count,
        lastUsedAt: lastUsedAt,
      );
    }
    return result;
  }
}

class _HistoricalUsage {
  const _HistoricalUsage({required this.count, required this.lastUsedAt});

  final int count;
  final String? lastUsedAt;
}

class _RankedSuggestion {
  const _RankedSuggestion({
    required this.suggestion,
    required this.normalizedDisplay,
  });

  final ContextSuggestion suggestion;
  final String normalizedDisplay;
}

int _compareSuggestions(_RankedSuggestion left, _RankedSuggestion right) {
  var result = left.suggestion.matchQuality.index.compareTo(
    right.suggestion.matchQuality.index,
  );
  if (result != 0) return result;
  result = _sourcePriority(
    left.suggestion.sourceType,
  ).compareTo(_sourcePriority(right.suggestion.sourceType));
  if (result != 0) return result;
  result = right.suggestion.historicalUsageCount.compareTo(
    left.suggestion.historicalUsageCount,
  );
  if (result != 0) return result;
  result = _compareNullableTextDescending(
    left.suggestion.historicalLastUsedAt,
    right.suggestion.historicalLastUsedAt,
  );
  if (result != 0) return result;
  result = left.normalizedDisplay.compareTo(right.normalizedDisplay);
  if (result != 0) return result;
  result = left.suggestion.kind.index.compareTo(right.suggestion.kind.index);
  if (result != 0) return result;
  result = left.suggestion.sourceType.index.compareTo(
    right.suggestion.sourceType.index,
  );
  if (result != 0) return result;
  return (left.suggestion.sourceId ?? left.suggestion.displayValue).compareTo(
    right.suggestion.sourceId ?? right.suggestion.displayValue,
  );
}

int _sourcePriority(ContextSuggestionSourceType sourceType) =>
    sourceType == ContextSuggestionSourceType.historicalRelatedPerson ? 1 : 0;

int _compareNullableTextDescending(String? left, String? right) {
  if (left == null) return right == null ? 0 : 1;
  if (right == null) return -1;
  return right.compareTo(left);
}

ContextSuggestionMatchQuality? _matchQuality(
  String displayValue,
  String normalizedQuery,
) {
  if (normalizedQuery.isEmpty) return ContextSuggestionMatchQuality.all;
  final normalizedDisplay = _normalizeForComparison(displayValue);
  if (normalizedDisplay == normalizedQuery) {
    return ContextSuggestionMatchQuality.exact;
  }
  if (normalizedDisplay.startsWith(normalizedQuery)) {
    return ContextSuggestionMatchQuality.prefix;
  }
  if (normalizedDisplay.contains(normalizedQuery)) {
    return ContextSuggestionMatchQuality.substring;
  }
  return null;
}

String _normalizeForComparison(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

String _requiredInput(String value, String code) {
  if (value.isEmpty || value != value.trim()) {
    throw ContextSuggestionFailure(code);
  }
  return value;
}

String? _safeStoredText(Object? value) {
  if (value is! String || value.isEmpty || value != value.trim()) return null;
  return value;
}
