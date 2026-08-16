import 'dart:convert';

import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

typedef ConstructionScheduleSnapshotIdFactory = String Function();
typedef ConstructionScheduleActivityInsertHook =
    Future<void> Function(int index, ConstructionScheduledActivity activity);
typedef ConstructionScheduleWindowIntegrityHook = Future<void> Function();
typedef ConstructionScheduleFullSnapshotMetadataHook = Future<void> Function();
typedef ConstructionSchedulePersistCommitHook = Future<void> Function();

class ConstructionScheduleActivityWindow {
  ConstructionScheduleActivityWindow({
    required this.metadata,
    required this.profile,
    required Iterable<ConstructionScheduledActivity> activities,
  }) : activities = List.unmodifiable(activities);

  final ConstructionScheduleSnapshotMetadata metadata;
  final ConstructionProjectProfile profile;
  final List<ConstructionScheduledActivity> activities;
}

class ConstructionScheduleSnapshotRepository {
  ConstructionScheduleSnapshotRepository({
    required this.database,
    required this.clock,
    ConstructionScheduleDateEngine? dateEngine,
    ConstructionScheduleSnapshotIdFactory? idFactory,
    this.beforeActivityInsert,
    this.afterWindowIntegrityCheck,
    this.afterFullSnapshotMetadataRead,
    this.afterPersistCommit,
  }) : _dateEngine = dateEngine ?? ConstructionScheduleDateEngine(),
       _idFactory = idFactory ?? RecordId.randomUuid;

  static const _metadataColumns = <String>[
    'id',
    'project_id',
    'profile_json',
    'corpus_version',
    'schedule_seed_version',
    'schedule_seed_provenance',
    'production_status',
    'duration_source',
    'baseline_status',
    'schedule_start',
    'schedule_finish',
    'activity_count',
    'root_count',
    'leaf_count',
    'isolated_count',
    'milestone_count',
    'projection_sha256',
    'generated_at',
    'superseded_at',
  ];

  final AppDatabase database;
  final UtcClock clock;
  final ConstructionScheduleDateEngine _dateEngine;
  final ConstructionScheduleSnapshotIdFactory _idFactory;
  final ConstructionScheduleActivityInsertHook? beforeActivityInsert;
  final ConstructionScheduleWindowIntegrityHook? afterWindowIntegrityCheck;
  final ConstructionScheduleFullSnapshotMetadataHook?
  afterFullSnapshotMetadataRead;
  final ConstructionSchedulePersistCommitHook? afterPersistCommit;

  Future<ConstructionScheduleSnapshot> persistCurrentSnapshot({
    required ConstructionProjectReferenceSchedule schedule,
    required ConstructionProjectProfile profile,
    required ConstructionProjectActivityGraph graph,
    required ConstructionScheduleSeedCatalog seedCatalog,
  }) async {
    _dateEngine.validateSchedule(
      schedule: schedule,
      profile: profile,
      graph: graph,
      seedCatalog: seedCatalog,
    );
    if (schedule.projectId != profile.projectId) {
      throw const ConstructionScheduleSnapshotFailure(
        'schedule_snapshot_project_mismatch',
      );
    }

    final snapshotId = _idFactory();
    if (snapshotId.isEmpty || snapshotId.trim() != snapshotId) {
      throw const ConstructionScheduleSnapshotFailure(
        'invalid_schedule_snapshot_id',
      );
    }
    final profileJson = _canonicalProfileJson(profile);
    final projectionSha256 = constructionScheduleSnapshotProjectionSha256(
      schedule.scheduledActivities,
    );
    final generatedAt = CseTimeCodec.encodeUtc(clock());
    final scheduleStart = formatCanonicalConstructionDate(
      schedule.scheduleStart,
    );
    final scheduleFinish = formatCanonicalConstructionDate(
      schedule.scheduleFinish,
    );

    final stored = await database.database.transaction((transaction) async {
      final project = await transaction.query(
        'projects',
        columns: const ['id'],
        where: 'id = ?',
        whereArgs: [schedule.projectId],
        limit: 2,
      );
      if (project.length != 1) {
        throw const ConstructionScheduleSnapshotFailure(
          'missing_schedule_snapshot_project',
        );
      }

      final current = await transaction.query(
        'project_schedule_snapshots',
        columns: const ['id', 'generated_at'],
        where: 'project_id = ? AND superseded_at IS NULL',
        whereArgs: [schedule.projectId],
        limit: 2,
      );
      if (current.length > 1) {
        throw const ConstructionScheduleSnapshotFailure(
          'multiple_current_schedule_snapshots',
        );
      }
      if (current.isNotEmpty) {
        final currentGeneratedAt = _parseStoredTimestamp(
          current.single['generated_at'],
        );
        final proposedGeneratedAt = _parseStoredTimestamp(generatedAt);
        if (proposedGeneratedAt.isBefore(currentGeneratedAt)) {
          throw const ConstructionScheduleSnapshotFailure(
            'schedule_snapshot_clock_regression',
          );
        }
        final updated = await transaction.update(
          'project_schedule_snapshots',
          {'superseded_at': generatedAt},
          where: 'id = ? AND superseded_at IS NULL',
          whereArgs: [current.single['id']],
        );
        if (updated != 1) {
          throw const ConstructionScheduleSnapshotFailure(
            'schedule_snapshot_supersede_failed',
          );
        }
      }

      await transaction.insert('project_schedule_snapshots', {
        'id': snapshotId,
        'project_id': schedule.projectId,
        'profile_json': profileJson,
        'corpus_version': schedule.corpusVersion,
        'schedule_seed_version': schedule.scheduleSeedVersion,
        'schedule_seed_provenance': schedule.scheduleSeedProvenance,
        'production_status': schedule.productionStatus,
        'duration_source': schedule.durationSource,
        'baseline_status': schedule.baselineStatus,
        'schedule_start': scheduleStart,
        'schedule_finish': scheduleFinish,
        'activity_count': schedule.scheduledActivities.length,
        'root_count': schedule.rootInstanceIds.length,
        'leaf_count': schedule.leafInstanceIds.length,
        'isolated_count': schedule.isolatedInstanceIds.length,
        'milestone_count': schedule.milestoneInstanceCount,
        'projection_sha256': projectionSha256,
        'generated_at': generatedAt,
        'superseded_at': null,
      });

      for (
        var index = 0;
        index < schedule.scheduledActivities.length;
        index++
      ) {
        final activity = schedule.scheduledActivities[index];
        await beforeActivityInsert?.call(index, activity);
        await transaction.insert(
          'project_schedule_snapshot_activities',
          _activityRow(
            snapshotId: snapshotId,
            projectId: schedule.projectId,
            activity: activity,
          ),
        );
      }

      final insertedCount = Sqflite.firstIntValue(
        await transaction.rawQuery(
          '''
          SELECT count(*)
          FROM project_schedule_snapshot_activities
          WHERE snapshot_id = ?
        ''',
          [snapshotId],
        ),
      );
      final currentCount = Sqflite.firstIntValue(
        await transaction.rawQuery(
          '''
          SELECT count(*)
          FROM project_schedule_snapshots
          WHERE project_id = ? AND superseded_at IS NULL
        ''',
          [schedule.projectId],
        ),
      );
      if (insertedCount != schedule.scheduledActivities.length ||
          currentCount != 1) {
        throw const ConstructionScheduleSnapshotFailure(
          'schedule_snapshot_write_verification_failed',
        );
      }

      final storedRows = await transaction.query(
        'project_schedule_snapshots',
        columns: _metadataColumns,
        where: 'id = ?',
        whereArgs: [snapshotId],
        limit: 2,
      );
      if (storedRows.length != 1) {
        throw const ConstructionScheduleSnapshotFailure(
          'schedule_snapshot_commit_verification_failed',
        );
      }
      final stored = await _loadSnapshot(transaction, storedRows.single);
      if (!stored.metadata.isCurrent) {
        throw const ConstructionScheduleSnapshotFailure(
          'schedule_snapshot_commit_verification_failed',
        );
      }
      return stored;
    });
    await afterPersistCommit?.call();
    return stored;
  }

  Future<ConstructionScheduleSnapshot?> loadCurrentSnapshot(String projectId) =>
      database.database.transaction((transaction) async {
        final rows = await transaction.query(
          'project_schedule_snapshots',
          columns: _metadataColumns,
          where: 'project_id = ? AND superseded_at IS NULL',
          whereArgs: [projectId],
          limit: 2,
        );
        if (rows.length > 1) {
          throw const ConstructionScheduleSnapshotFailure(
            'multiple_current_schedule_snapshots',
          );
        }
        if (rows.isEmpty) {
          return null;
        }
        return _loadSnapshot(transaction, rows.single);
      });

  Future<ConstructionScheduleSnapshot?> loadSnapshotById(String snapshotId) =>
      database.database.transaction((transaction) async {
        final rows = await transaction.query(
          'project_schedule_snapshots',
          columns: _metadataColumns,
          where: 'id = ?',
          whereArgs: [snapshotId],
          limit: 2,
        );
        if (rows.length > 1) {
          throw const ConstructionScheduleSnapshotFailure(
            'duplicate_schedule_snapshot_id',
          );
        }
        if (rows.isEmpty) {
          return null;
        }
        return _loadSnapshot(transaction, rows.single);
      });

  Future<List<ConstructionScheduleSnapshotMetadata>> listSnapshotHistory(
    String projectId,
  ) async {
    final rows = await database.database.query(
      'project_schedule_snapshots',
      columns: _metadataColumns,
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'generated_at DESC, id DESC',
    );
    return List.unmodifiable(rows.map((row) => _metadataAndProfile(row).$1));
  }

  Future<List<ConstructionScheduledActivity>> queryCurrentActivities({
    required String projectId,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async =>
      (await loadCurrentActivityWindow(
        projectId: projectId,
        windowStart: windowStart,
        windowEnd: windowEnd,
      ))?.activities ??
      const <ConstructionScheduledActivity>[];

  Future<ConstructionScheduleActivityWindow?> loadCurrentActivityWindow({
    required String projectId,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async {
    final start = formatCanonicalConstructionDate(windowStart);
    final finish = formatCanonicalConstructionDate(windowEnd);
    if (finish.compareTo(start) < 0) {
      throw const ConstructionScheduleSnapshotFailure(
        'invalid_schedule_snapshot_window',
      );
    }
    return database.database.transaction((transaction) async {
      final current = await transaction.query(
        'project_schedule_snapshots',
        columns: _metadataColumns,
        where: 'project_id = ? AND superseded_at IS NULL',
        whereArgs: [projectId],
        limit: 2,
      );
      if (current.length > 1) {
        throw const ConstructionScheduleSnapshotFailure(
          'multiple_current_schedule_snapshots',
        );
      }
      if (current.isEmpty) {
        return null;
      }
      final parsed = _metadataAndProfile(current.single);
      final metadata = parsed.$1;
      final storedActivityCount = Sqflite.firstIntValue(
        await transaction.rawQuery(
          '''
          SELECT count(*)
          FROM project_schedule_snapshot_activities
          WHERE snapshot_id = ?
        ''',
          [metadata.snapshotId],
        ),
      );
      if (storedActivityCount != metadata.activityCount) {
        throw const ConstructionScheduleSnapshotFailure(
          'schedule_snapshot_activity_count_mismatch',
        );
      }
      await afterWindowIntegrityCheck?.call();
      final rows = await transaction.query(
        'project_schedule_snapshot_activities',
        where: '''
          project_id = ? AND snapshot_id = ?
          AND start_date <= ? AND finish_date >= ?
        ''',
        whereArgs: [projectId, metadata.snapshotId, finish, start],
        orderBy: 'start_date ASC, finish_date ASC, instance_id ASC',
      );
      return ConstructionScheduleActivityWindow(
        metadata: metadata,
        profile: parsed.$2,
        activities: rows.map(
          (row) => _activityFromRow(
            row,
            expectedProjectId: projectId,
            expectedSnapshotId: metadata.snapshotId,
          ),
        ),
      );
    });
  }

  Future<ConstructionScheduleSnapshot> _loadSnapshot(
    DatabaseExecutor executor,
    Map<String, Object?> metadataRow,
  ) async {
    final parsed = _metadataAndProfile(metadataRow);
    final metadata = parsed.$1;
    await afterFullSnapshotMetadataRead?.call();
    final rows = await executor.query(
      'project_schedule_snapshot_activities',
      where: 'snapshot_id = ?',
      whereArgs: [metadata.snapshotId],
      orderBy: 'instance_id ASC',
    );
    if (rows.length != metadata.activityCount) {
      throw const ConstructionScheduleSnapshotFailure(
        'schedule_snapshot_activity_count_mismatch',
      );
    }

    final activities = <ConstructionScheduledActivity>[];
    String? previousInstanceId;
    for (final row in rows) {
      final activity = _activityFromRow(
        row,
        expectedProjectId: metadata.projectId,
        expectedSnapshotId: metadata.snapshotId,
      );
      if (previousInstanceId != null &&
          previousInstanceId.compareTo(activity.instanceId) >= 0) {
        throw const ConstructionScheduleSnapshotFailure(
          'unordered_schedule_snapshot_activities',
        );
      }
      previousInstanceId = activity.instanceId;
      activities.add(activity);
    }

    final isolatedCount = activities.where((item) => item.isIsolated).length;
    final milestoneCount = activities.where((item) => item.isMilestone).length;
    if (isolatedCount != metadata.isolatedCount ||
        milestoneCount != metadata.milestoneCount ||
        _minimumDate(activities.map((item) => item.startDate)) !=
            metadata.scheduleStart ||
        _maximumDate(activities.map((item) => item.finishDate)) !=
            metadata.scheduleFinish) {
      throw const ConstructionScheduleSnapshotFailure(
        'schedule_snapshot_summary_mismatch',
      );
    }
    if (constructionScheduleSnapshotProjectionSha256(activities) !=
        metadata.projectionSha256) {
      throw const ConstructionScheduleSnapshotFailure(
        'schedule_snapshot_fingerprint_mismatch',
      );
    }
    return ConstructionScheduleSnapshot(
      metadata: metadata,
      profile: parsed.$2,
      activities: activities,
    );
  }
}

String constructionScheduleSnapshotProjectionJson(
  Iterable<ConstructionScheduledActivity> source,
) {
  final activities = source.toList(growable: false)
    ..sort((left, right) => left.instanceId.compareTo(right.instanceId));
  String? previousInstanceId;
  final projection = <Map<String, Object?>>[];
  for (final activity in activities) {
    if (previousInstanceId == activity.instanceId) {
      throw const ConstructionScheduleSnapshotFailure(
        'duplicate_schedule_snapshot_instance',
      );
    }
    previousInstanceId = activity.instanceId;
    projection.add(_activityProjection(activity));
  }
  return jsonEncode(projection);
}

String constructionScheduleSnapshotProjectionSha256(
  Iterable<ConstructionScheduledActivity> activities,
) => sha256
    .convert(
      utf8.encode(constructionScheduleSnapshotProjectionJson(activities)),
    )
    .toString();

String constructionScheduleSnapshotActivityProjectionJson(
  ConstructionScheduledActivity activity,
) => jsonEncode(_activityProjection(activity));

String constructionScheduleSnapshotActivitySha256(
  ConstructionScheduledActivity activity,
) => sha256
    .convert(
      utf8.encode(constructionScheduleSnapshotActivityProjectionJson(activity)),
    )
    .toString();

Map<String, Object?> _activityProjection(
  ConstructionScheduledActivity activity,
) => <String, Object?>{
  'activity_id': activity.activityId,
  'duration_calendar_type': activity.durationCalendarType.jsonValue,
  'duration_confidence': activity.durationConfidence.jsonValue,
  'duration_days': activity.durationDays,
  'duration_status': activity.durationStatus.jsonValue,
  'finish_date': formatCanonicalConstructionDate(activity.finishDate),
  'instance_id': activity.instanceId,
  'is_isolated': activity.isIsolated,
  'is_milestone': activity.isMilestone,
  'rounded_scheduling_days': activity.roundedSchedulingDays,
  'start_date': formatCanonicalConstructionDate(activity.startDate),
};

Map<String, Object?> _activityRow({
  required String snapshotId,
  required String projectId,
  required ConstructionScheduledActivity activity,
}) => <String, Object?>{
  'snapshot_id': snapshotId,
  'project_id': projectId,
  'instance_id': activity.instanceId,
  'activity_id': activity.activityId,
  'start_date': formatCanonicalConstructionDate(activity.startDate),
  'finish_date': formatCanonicalConstructionDate(activity.finishDate),
  'duration_days': activity.durationDays,
  'rounded_scheduling_days': activity.roundedSchedulingDays,
  'duration_calendar_type': activity.durationCalendarType.jsonValue,
  'duration_status': activity.durationStatus.jsonValue,
  'duration_confidence': activity.durationConfidence.jsonValue,
  'is_milestone': activity.isMilestone ? 1 : 0,
  'is_isolated': activity.isIsolated ? 1 : 0,
  'row_sha256': constructionScheduleSnapshotActivitySha256(activity),
};

ConstructionScheduledActivity _activityFromRow(
  Map<String, Object?> row, {
  required String expectedProjectId,
  required String expectedSnapshotId,
}) {
  final snapshotId = _requiredString(row, 'snapshot_id');
  final projectId = _requiredString(row, 'project_id');
  if (snapshotId != expectedSnapshotId || projectId != expectedProjectId) {
    throw const ConstructionScheduleSnapshotFailure(
      'schedule_snapshot_activity_project_mismatch',
    );
  }
  final instanceId = _requiredString(row, 'instance_id');
  final activityId = _requiredString(row, 'activity_id');
  final duration = row['duration_days'];
  final rounded = row['rounded_scheduling_days'];
  if (duration is! num ||
      !duration.toDouble().isFinite ||
      duration < 0 ||
      rounded is! int ||
      rounded < 0 ||
      rounded != duration.toDouble().ceil()) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_duration',
    );
  }
  final start = _parseStoredDate(row['start_date']);
  final finish = _parseStoredDate(row['finish_date']);
  final isMilestone = _requiredStoredBool(row, 'is_milestone');
  final isIsolated = _requiredStoredBool(row, 'is_isolated');
  if (finish.isBefore(start) ||
      isMilestone != (rounded == 0) ||
      (isMilestone && start != finish)) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_activity_dates',
    );
  }
  late ConstructionScheduledActivity activity;
  try {
    activity = ConstructionScheduledActivity(
      instanceId: instanceId,
      activityId: activityId,
      startDate: start,
      finishDate: finish,
      durationDays: duration.toDouble(),
      roundedSchedulingDays: rounded,
      durationCalendarType: ConstructionActivityDurationCalendarType.fromJson(
        row['duration_calendar_type'],
      ),
      durationStatus: ConstructionScheduleDurationStatus.fromJson(
        row['duration_status'],
      ),
      durationConfidence: ConstructionScheduleDurationConfidence.fromJson(
        row['duration_confidence'],
      ),
      isMilestone: isMilestone,
      isIsolated: isIsolated,
    );
  } on ConstructionCorpusFailure {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_activity_enum',
    );
  }
  final storedRowSha256 = row['row_sha256'];
  if (storedRowSha256 is! String ||
      !RegExp(r'^[0-9a-f]{64}$').hasMatch(storedRowSha256) ||
      constructionScheduleSnapshotActivitySha256(activity) != storedRowSha256) {
    throw const ConstructionScheduleSnapshotFailure(
      'schedule_snapshot_activity_fingerprint_mismatch',
    );
  }
  return activity;
}

(ConstructionScheduleSnapshotMetadata, ConstructionProjectProfile)
_metadataAndProfile(Map<String, Object?> row) {
  final snapshotId = _requiredString(row, 'id');
  final projectId = _requiredString(row, 'project_id');
  final corpusVersion = _requiredString(row, 'corpus_version');
  final scheduleSeedVersion = _requiredString(row, 'schedule_seed_version');
  final scheduleSeedProvenance = _requiredString(
    row,
    'schedule_seed_provenance',
  );
  final productionStatus = _requiredString(row, 'production_status');
  final durationSource = _requiredString(row, 'duration_source');
  final baselineStatus = _requiredString(row, 'baseline_status');
  if (productionStatus != ConstructionScheduleDateEngine.productionStatus ||
      durationSource != ConstructionScheduleDateEngine.durationSource ||
      baselineStatus != ConstructionScheduleDateEngine.baselineStatus) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_provenance',
    );
  }

  final scheduleStart = _parseStoredDate(row['schedule_start']);
  final scheduleFinish = _parseStoredDate(row['schedule_finish']);
  if (scheduleFinish.isBefore(scheduleStart)) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_range',
    );
  }
  final activityCount = _requiredCount(row, 'activity_count', positive: true);
  final rootCount = _requiredCount(row, 'root_count');
  final leafCount = _requiredCount(row, 'leaf_count');
  final isolatedCount = _requiredCount(row, 'isolated_count');
  final milestoneCount = _requiredCount(row, 'milestone_count');
  if (rootCount > activityCount ||
      leafCount > activityCount ||
      isolatedCount > activityCount ||
      milestoneCount > activityCount) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_counts',
    );
  }
  final projectionSha256 = _requiredString(row, 'projection_sha256');
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(projectionSha256)) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_fingerprint',
    );
  }
  final generatedAt = _parseStoredTimestamp(row['generated_at']);
  final supersededValue = row['superseded_at'];
  final supersededAt = supersededValue == null
      ? null
      : _parseStoredTimestamp(supersededValue);
  if (supersededAt != null && supersededAt.isBefore(generatedAt)) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_superseded_at',
    );
  }

  final profileJson = _requiredString(row, 'profile_json', trim: false);
  ConstructionProjectProfile profile;
  try {
    final decoded = jsonDecode(profileJson);
    if (decoded is! Map) {
      throw const FormatException();
    }
    profile = ConstructionProjectProfile.fromJson(
      decoded.cast<String, Object?>(),
    );
  } on Object {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_profile',
    );
  }
  if (profile.projectId != projectId ||
      _canonicalProfileJson(profile) != profileJson) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_profile',
    );
  }

  return (
    ConstructionScheduleSnapshotMetadata(
      snapshotId: snapshotId,
      projectId: projectId,
      corpusVersion: corpusVersion,
      scheduleSeedVersion: scheduleSeedVersion,
      scheduleSeedProvenance: scheduleSeedProvenance,
      productionStatus: productionStatus,
      durationSource: durationSource,
      baselineStatus: baselineStatus,
      scheduleStart: scheduleStart,
      scheduleFinish: scheduleFinish,
      activityCount: activityCount,
      rootCount: rootCount,
      leafCount: leafCount,
      isolatedCount: isolatedCount,
      milestoneCount: milestoneCount,
      projectionSha256: projectionSha256,
      generatedAt: generatedAt,
      supersededAt: supersededAt,
    ),
    profile,
  );
}

String _canonicalProfileJson(
  ConstructionProjectProfile profile,
) => jsonEncode(<String, Object?>{
  'block_count': profile.blockCount,
  'blocks': [
    for (final block in profile.blocks)
      <String, Object?>{
        'basement_count': block.basementCount,
        'block_id': block.blockId,
        'floor_count': block.floorCount,
      },
  ],
  'calendar': <String, Object?>{
    'holidays': [
      for (final holiday in profile.calendar.holidays)
        formatCanonicalConstructionDate(holiday),
    ],
    'start_date': formatCanonicalConstructionDate(profile.calendar.startDate),
    'workday_hours': profile.calendar.workdayHours,
    'working_weekdays': profile.calendar.workingWeekdays,
  },
  'cooling_system': profile.coolingSystem.jsonValue,
  'excavation_required': profile.excavationRequired,
  'facade_elevations': profile.facadeElevations,
  'facade_type': profile.facadeType.jsonValue,
  'formwork_system': profile.formworkSystem.jsonValue,
  'foundation_thermal_insulation_required':
      profile.foundationThermalInsulationRequired,
  'foundation_type': profile.foundationType.jsonValue,
  'foundation_waterproofing_required': profile.foundationWaterproofingRequired,
  'ground_improvement_required': profile.groundImprovementRequired,
  'has_basement': profile.hasBasement,
  'has_bms': profile.hasBms,
  'has_dewatering': profile.hasDewatering,
  'has_elevator': profile.hasElevator,
  'has_fire_system': profile.hasFireSystem,
  'has_generator': profile.hasGenerator,
  'has_internal_roads': profile.hasInternalRoads,
  'has_landscape': profile.hasLandscape,
  'has_parking': profile.hasParking,
  'has_piles': profile.hasPiles,
  'has_precast_auxiliary': profile.hasPrecastAuxiliary,
  'has_shoring': profile.hasShoring,
  'has_sprinkler': profile.hasSprinkler,
  'has_steel_auxiliary': profile.hasSteelAuxiliary,
  'has_transformer': profile.hasTransformer,
  'has_ups': profile.hasUps,
  'heating_system': profile.heatingSystem.jsonValue,
  'lot_count': profile.lotCount,
  'project_id': profile.projectId,
  'project_name': profile.projectName,
  'project_type': profile.projectType.jsonValue,
  'roof_type': profile.roofType.jsonValue,
  'structural_system': profile.structuralSystem.jsonValue,
  'test_batch_count': profile.testBatchCount,
  'wall_type': profile.wallType.jsonValue,
  'zones_per_block': profile.zonesPerBlock,
});

String _requiredString(
  Map<String, Object?> row,
  String key, {
  bool trim = true,
}) {
  final value = row[key];
  if (value is! String || value.isEmpty || (trim && value.trim() != value)) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_metadata',
    );
  }
  return value;
}

int _requiredCount(
  Map<String, Object?> row,
  String key, {
  bool positive = false,
}) {
  final value = row[key];
  if (value is! int || (positive ? value <= 0 : value < 0)) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_counts',
    );
  }
  return value;
}

bool _requiredStoredBool(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value != 0 && value != 1) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_boolean',
    );
  }
  return value == 1;
}

DateTime _parseStoredDate(Object? value) {
  if (value is! String) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_date',
    );
  }
  try {
    return parseCanonicalConstructionDate(value);
  } on ConstructionCorpusFailure {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_date',
    );
  }
}

DateTime _parseStoredTimestamp(Object? value) {
  if (value is! String) {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_timestamp',
    );
  }
  try {
    return CseTimeCodec.decodeCanonicalUtc(value);
  } on Object {
    throw const ConstructionScheduleSnapshotFailure(
      'invalid_schedule_snapshot_timestamp',
    );
  }
}

DateTime _minimumDate(Iterable<DateTime> values) {
  final iterator = values.iterator;
  if (!iterator.moveNext()) {
    throw const ConstructionScheduleSnapshotFailure('empty_schedule_snapshot');
  }
  var result = iterator.current;
  while (iterator.moveNext()) {
    if (iterator.current.isBefore(result)) {
      result = iterator.current;
    }
  }
  return result;
}

DateTime _maximumDate(Iterable<DateTime> values) {
  final iterator = values.iterator;
  if (!iterator.moveNext()) {
    throw const ConstructionScheduleSnapshotFailure('empty_schedule_snapshot');
  }
  var result = iterator.current;
  while (iterator.moveNext()) {
    if (iterator.current.isAfter(result)) {
      result = iterator.current;
    }
  }
  return result;
}
