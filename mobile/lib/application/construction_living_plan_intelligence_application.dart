import 'dart:async';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/application/construction_living_plan_dependency_impact.dart';
import 'package:chief_site_engineer/application/construction_living_plan_forecast.dart';
import 'package:chief_site_engineer/application/construction_schedule_snapshot_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_intelligence_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_dependency_snapshot_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

typedef ConstructionLivingPlanIntelligenceSnapshotLoader =
    Future<ConstructionScheduleSnapshot?> Function(String snapshotId);
typedef ConstructionLivingPlanIntelligenceDependencyGraphLoader =
    Future<ConstructionScheduleSnapshotDependencyGraph?> Function(
      String snapshotId,
    );
typedef ConstructionLivingPlanIntelligenceCorpusLoader =
    Future<ConstructionCorpus> Function();

abstract interface class ConstructionLivingPlanIntelligenceApplicationPort {
  Future<Map<String, ConstructionLivingPlanIntelligence>> loadForItems({
    required Iterable<ConstructionLivingPlanItem> items,
    required DateTime asOfDate,
  });
}

class ConstructionLivingPlanIntelligenceApplication
    implements ConstructionLivingPlanIntelligenceApplicationPort {
  ConstructionLivingPlanIntelligenceApplication({
    required this._snapshotLoader,
    required this._dependencyGraphLoader,
    ConstructionLivingPlanIntelligenceCorpusLoader? corpusLoader,
    ConstructionLivingPlanForecastEngine? forecastEngine,
    ConstructionLivingPlanDependencyImpactEngine? impactEngine,
  }) : _corpusLoader =
           corpusLoader ?? BundledConstructionCorpusRepository().load,
       _forecastEngine =
           forecastEngine ?? const ConstructionLivingPlanForecastEngine(),
       _impactEngine =
           impactEngine ?? const ConstructionLivingPlanDependencyImpactEngine();

  final ConstructionLivingPlanIntelligenceSnapshotLoader _snapshotLoader;
  final ConstructionLivingPlanIntelligenceDependencyGraphLoader
  _dependencyGraphLoader;
  final ConstructionLivingPlanIntelligenceCorpusLoader _corpusLoader;
  final ConstructionLivingPlanForecastEngine _forecastEngine;
  final ConstructionLivingPlanDependencyImpactEngine _impactEngine;

  @override
  Future<Map<String, ConstructionLivingPlanIntelligence>> loadForItems({
    required Iterable<ConstructionLivingPlanItem> items,
    required DateTime asOfDate,
  }) async {
    _requireCanonicalDate(asOfDate);
    final source = List<ConstructionLivingPlanItem>.unmodifiable(items);
    final itemIds = <String>{};
    for (final item in source) {
      if (!itemIds.add(item.id)) {
        throw const ConstructionLivingPlanIntelligenceFailure(
          'living_plan_intelligence_duplicate_item',
        );
      }
    }

    final snapshots = <String, ConstructionScheduleSnapshot>{};
    final graphReads = <String, _DependencyGraphRead>{};
    ConstructionCorpus? corpus;
    var corpusRead = false;
    final result = <String, ConstructionLivingPlanIntelligence>{};

    for (final item in source) {
      final snapshot =
          snapshots[item.referenceSnapshotId] ??
          await _loadSnapshot(item.referenceSnapshotId);
      snapshots[item.referenceSnapshotId] = snapshot;
      final forecast = _forecastEngine.forecast(
        item: item,
        exactSnapshot: snapshot,
        asOfDate: asOfDate,
      );
      final graphRead =
          graphReads[item.referenceSnapshotId] ??
          await _loadDependencyGraph(item.referenceSnapshotId);
      graphReads[item.referenceSnapshotId] = graphRead;
      if (graphRead.graph == null) {
        result[item.id] = ConstructionLivingPlanIntelligence(
          itemId: item.id,
          forecast: forecast,
          impactAvailability:
              ConstructionLivingPlanIntelligenceImpactAvailability
                  .dependencyGraphUnavailable,
          dependencyImpact: null,
          impactedActivities: const [],
        );
        continue;
      }

      final impact = _impactEngine.calculate(
        sourceForecast: forecast,
        exactSnapshot: snapshot,
        exactDependencyGraph: graphRead.graph!,
      );
      if (impact.impactedActivities.isNotEmpty && !corpusRead) {
        corpusRead = true;
        try {
          corpus = await _corpusLoader();
        } on Object {
          corpus = null;
        }
      }
      final names =
          snapshot.metadata.corpusVersion == corpus?.metadata.corpusVersion
          ? {
              for (final activity in corpus!.activities)
                activity.activityId: activity.activityNameTr,
            }
          : const <String, String>{};
      result[item.id] = ConstructionLivingPlanIntelligence(
        itemId: item.id,
        forecast: forecast,
        impactAvailability:
            ConstructionLivingPlanIntelligenceImpactAvailability.available,
        dependencyImpact: impact,
        impactedActivities: impact.impactedActivities.map(
          (activity) => ConstructionLivingPlanIntelligenceImpactActivity(
            activityInstanceId: activity.activityInstanceId,
            activityId: activity.activityId,
            displayName: names[activity.activityId] ?? activity.activityId,
            projectedStartDate: activity.projectedStartDate,
            projectedFinishDate: activity.projectedFinishDate,
            finishShiftCalendarDays: activity.finishShiftCalendarDays,
          ),
        ),
      );
    }
    return Map.unmodifiable(result);
  }

  Future<ConstructionScheduleSnapshot> _loadSnapshot(String snapshotId) async {
    final snapshot = await _snapshotLoader(snapshotId);
    if (snapshot == null) {
      throw const ConstructionLivingPlanIntelligenceFailure(
        'living_plan_intelligence_snapshot_missing',
      );
    }
    return snapshot;
  }

  Future<_DependencyGraphRead> _loadDependencyGraph(String snapshotId) async {
    try {
      final graph = await _dependencyGraphLoader(snapshotId);
      if (graph == null) {
        throw const ConstructionLivingPlanIntelligenceFailure(
          'living_plan_intelligence_snapshot_missing',
        );
      }
      return _DependencyGraphRead(graph);
    } on ConstructionScheduleSnapshotFailure catch (failure) {
      if (failure.code == 'schedule_snapshot_dependency_graph_unavailable') {
        return const _DependencyGraphRead(null);
      }
      rethrow;
    }
  }
}

void _requireCanonicalDate(DateTime value) {
  if (!value.isUtc ||
      value.hour != 0 ||
      value.minute != 0 ||
      value.second != 0 ||
      value.millisecond != 0 ||
      value.microsecond != 0) {
    throw const ConstructionLivingPlanIntelligenceFailure(
      'living_plan_intelligence_as_of_date_not_canonical',
    );
  }
}

class _DependencyGraphRead {
  const _DependencyGraphRead(this.graph);
  final ConstructionScheduleSnapshotDependencyGraph? graph;
}

/// Opens the active SQLite truth for one complete read and closes it afterwards.
/// Backup/restore may therefore replace the database between calls without a
/// stale handle or a current-snapshot shortcut being retained.
class SqliteConstructionLivingPlanIntelligenceApplication
    implements ConstructionLivingPlanIntelligenceApplicationPort {
  SqliteConstructionLivingPlanIntelligenceApplication({
    required this.databasePath,
    required this.databaseFactory,
    ConstructionLivingPlanIntelligenceCorpusLoader? corpusLoader,
  }) : _corpusLoader =
           corpusLoader ?? BundledConstructionCorpusRepository().load;

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final ConstructionLivingPlanIntelligenceCorpusLoader _corpusLoader;
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<Map<String, ConstructionLivingPlanIntelligence>> loadForItems({
    required Iterable<ConstructionLivingPlanItem> items,
    required DateTime asOfDate,
  }) {
    final frozenItems = List<ConstructionLivingPlanItem>.unmodifiable(items);
    final completer =
        Completer<Map<String, ConstructionLivingPlanIntelligence>>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await _run(items: frozenItems, asOfDate: asOfDate));
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<Map<String, ConstructionLivingPlanIntelligence>> _run({
    required List<ConstructionLivingPlanItem> items,
    required DateTime asOfDate,
  }) async {
    _requireCanonicalDate(asOfDate);
    final database = AppDatabase(
      path: databasePath,
      factory: databaseFactory,
      clock: () => asOfDate,
    );
    await database.open();
    try {
      final snapshots = ConstructionScheduleSnapshotRepository(
        database: database,
        clock: () => asOfDate,
      );
      return await ConstructionLivingPlanIntelligenceApplication(
        snapshotLoader: snapshots.loadSnapshotById,
        dependencyGraphLoader: snapshots.loadDependencyGraphBySnapshotId,
        corpusLoader: _corpusLoader,
      ).loadForItems(items: items, asOfDate: asOfDate);
    } finally {
      await database.close();
    }
  }
}

class UnavailableConstructionLivingPlanIntelligenceApplication
    implements ConstructionLivingPlanIntelligenceApplicationPort {
  const UnavailableConstructionLivingPlanIntelligenceApplication();

  @override
  Future<Map<String, ConstructionLivingPlanIntelligence>> loadForItems({
    required Iterable<ConstructionLivingPlanItem> items,
    required DateTime asOfDate,
  }) async => throw const ConstructionLivingPlanIntelligenceFailure(
    'living_plan_intelligence_unavailable',
  );
}
