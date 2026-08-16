import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/construction_project_graph_builder.dart';
import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/application/construction_schedule_seed_repository.dart';
import 'package:chief_site_engineer/application/construction_schedule_snapshot_repository.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:sqflite/sqflite.dart';

const livingPlanAcceptanceProjectId = '46400000-0000-4000-8000-000000000001';
const livingPlanAcceptanceProjectName = 'CSE 7 Günlük Plan Pilot';
const livingPlanAcceptanceSearchAlias = 'mobilizasyon planı';
const livingPlanAcceptancePlannedItemId =
    '46400000-0000-4000-8000-000000000011';
const livingPlanAcceptanceStartedItemId =
    '46400000-0000-4000-8000-000000000021';

const _plannedActivityId = 'TR-BLD-01-001-YER-TESLIMI';
const _startedActivityId = 'TR-BLD-01-003-SANTIYE-CEVRELEME-VE-GUVENLI';
const _addActivityId = 'TR-BLD-01-002-MOBILIZASYON-PLANI';

class LivingPlanAcceptanceFixture {
  const LivingPlanAcceptanceFixture({
    required this.projectId,
    required this.projectName,
    required this.windowStart,
    required this.plannedItemId,
    required this.startedItemId,
    required this.addCandidate,
  });

  final String projectId;
  final String projectName;
  final DateTime windowStart;
  final String plannedItemId;
  final String startedItemId;
  final ConstructionLivingPlanReferenceCandidate addCandidate;
}

Future<LivingPlanAcceptanceFixture> ensureLivingPlanAcceptanceFixture({
  required AppDirectories directories,
  required DatabaseFactory databaseFactory,
  required UtcClock clock,
}) async {
  await directories.ensureCreated();
  final windowStart = _dateOnly(clock());
  final database = AppDatabase(
    path: directories.databaseFile,
    factory: databaseFactory,
    clock: clock,
  );
  await database.open();
  try {
    await _ensureProject(database, clock);
    final snapshots = ConstructionScheduleSnapshotRepository(
      database: database,
      clock: clock,
    );
    if (await snapshots.loadCurrentSnapshot(livingPlanAcceptanceProjectId) ==
        null) {
      final corpus = await BundledConstructionCorpusRepository().load();
      final profile = ConstructionProjectProfile.fromJson(
        _profileJson(windowStart),
      );
      final graph = await ConstructionProjectActivityGraphBuilder().build(
        profile,
      );
      final seeds = await BundledConstructionScheduleSeedCatalogRepository()
          .load(corpus);
      final schedule = ConstructionScheduleDateEngine().build(
        profile: profile,
        graph: graph,
        seedCatalog: seeds,
      );
      await snapshots.persistCurrentSnapshot(
        schedule: schedule,
        profile: profile,
        graph: graph,
        seedCatalog: seeds,
      );
    }
  } finally {
    await database.close();
  }

  final livingPlan = SqliteConstructionLivingPlanApplication(
    databasePath: directories.databaseFile,
    databaseFactory: databaseFactory,
    clock: clock,
  );
  final plannedCandidate = await _uniqueCandidate(
    livingPlan,
    query: 'yer teslimi',
    expectedActivityId: _plannedActivityId,
  );
  final startedCandidate = await _uniqueCandidate(
    livingPlan,
    query: 'şantiye çevreleme ve güvenlik',
    expectedActivityId: _startedActivityId,
  );
  final addCandidate = await _uniqueCandidate(
    livingPlan,
    query: livingPlanAcceptanceSearchAlias,
    expectedActivityId: _addActivityId,
  );

  await _ensureCreatedItem(
    livingPlan,
    candidate: plannedCandidate,
    itemId: livingPlanAcceptancePlannedItemId,
    eventId: '46400000-0000-4000-8000-000000000012',
    plannedDate: windowStart.subtract(const Duration(days: 1)),
    note: 'Acceptance geciken iş',
  );
  final started = await _ensureCreatedItem(
    livingPlan,
    candidate: startedCandidate,
    itemId: livingPlanAcceptanceStartedItemId,
    eventId: '46400000-0000-4000-8000-000000000022',
    plannedDate: windowStart,
    note: 'Acceptance bugün başlayan iş',
  );
  if (started.status == ConstructionLivingPlanStatus.planned) {
    await livingPlan.startLivingPlanItem(
      const StartConstructionLivingPlanItemCommand(
        itemId: livingPlanAcceptanceStartedItemId,
        eventId: '46400000-0000-4000-8000-000000000023',
        expectedRevision: 1,
      ),
    );
  }

  return LivingPlanAcceptanceFixture(
    projectId: livingPlanAcceptanceProjectId,
    projectName: livingPlanAcceptanceProjectName,
    windowStart: windowStart,
    plannedItemId: livingPlanAcceptancePlannedItemId,
    startedItemId: livingPlanAcceptanceStartedItemId,
    addCandidate: addCandidate,
  );
}

Future<void> _ensureProject(AppDatabase database, UtcClock clock) async {
  final rows = await database.database.query(
    'projects',
    where: 'id = ?',
    whereArgs: const [livingPlanAcceptanceProjectId],
    limit: 2,
  );
  if (rows.isEmpty) {
    final timestamp = CseTimeCodec.encodeUtc(clock());
    await database.database.insert('projects', {
      'id': livingPlanAcceptanceProjectId,
      'name': livingPlanAcceptanceProjectName,
      'created_at': timestamp,
      'updated_at': timestamp,
      'revision': 1,
      'archived_at': null,
    });
    return;
  }
  if (rows.length != 1 ||
      rows.single['name'] != livingPlanAcceptanceProjectName) {
    throw StateError('living_plan_acceptance_project_conflict');
  }
}

Future<ConstructionLivingPlanReferenceCandidate> _uniqueCandidate(
  ConstructionLivingPlanApplicationPort livingPlan, {
  required String query,
  required String expectedActivityId,
}) async {
  final matches = await livingPlan.searchCurrentReferenceCandidates(
    projectId: livingPlanAcceptanceProjectId,
    query: query,
  );
  final exact = matches
      .where((candidate) => candidate.activityId == expectedActivityId)
      .toList(growable: false);
  if (exact.length != 1) {
    throw StateError('living_plan_acceptance_candidate_mismatch');
  }
  return exact.single;
}

Future<ConstructionLivingPlanItem> _ensureCreatedItem(
  ConstructionLivingPlanApplicationPort livingPlan, {
  required ConstructionLivingPlanReferenceCandidate candidate,
  required String itemId,
  required String eventId,
  required DateTime plannedDate,
  required String note,
}) async {
  final existing = await livingPlan.loadLivingPlanItem(itemId);
  if (existing != null) {
    if (existing.projectId != livingPlanAcceptanceProjectId ||
        existing.activityInstanceId != candidate.activityInstanceId) {
      throw StateError('living_plan_acceptance_item_conflict');
    }
    return existing;
  }
  if (candidate.existingLivingPlanItemId != null) {
    throw StateError('living_plan_acceptance_activity_conflict');
  }
  return livingPlan.createLivingPlanItem(
    CreateConstructionLivingPlanItemCommand(
      itemId: itemId,
      eventId: eventId,
      projectId: livingPlanAcceptanceProjectId,
      expectedReferenceSnapshotId: candidate.referenceSnapshotId,
      activityInstanceId: candidate.activityInstanceId,
      plannedDate: plannedDate,
      note: note,
    ),
  );
}

DateTime _dateOnly(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

Map<String, Object?> _profileJson(DateTime startDate) => <String, Object?>{
  'project_id': livingPlanAcceptanceProjectId,
  'project_name': livingPlanAcceptanceProjectName,
  'project_type': 'KONUT',
  'blocks': <Object?>[
    <String, Object?>{'block_id': 'A', 'floor_count': 10, 'basement_count': 1},
  ],
  'block_count': 1,
  'zones_per_block': 2,
  'facade_elevations': <Object?>['NORTH', 'SOUTH'],
  'lot_count': 2,
  'test_batch_count': 3,
  'foundation_type': 'RADYE',
  'structural_system': 'PERDE_CERCEVE',
  'formwork_system': 'KONVANSIYONEL',
  'wall_type': 'GAZBETON',
  'facade_type': 'MANTOLAMA',
  'roof_type': 'TERAS',
  'heating_system': 'MERKEZI',
  'cooling_system': 'SPLIT',
  'excavation_required': true,
  'has_shoring': true,
  'has_dewatering': false,
  'ground_improvement_required': false,
  'has_piles': false,
  'foundation_waterproofing_required': true,
  'foundation_thermal_insulation_required': false,
  'has_steel_auxiliary': false,
  'has_precast_auxiliary': false,
  'has_fire_system': true,
  'has_sprinkler': true,
  'has_elevator': true,
  'has_generator': false,
  'has_ups': false,
  'has_transformer': false,
  'has_bms': false,
  'has_parking': true,
  'has_internal_roads': true,
  'has_landscape': true,
  'has_basement': true,
  'calendar': <String, Object?>{
    'start_date': formatCanonicalConstructionDate(startDate),
    'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
    'holidays': <Object?>[],
    'workday_hours': 8,
  },
};
