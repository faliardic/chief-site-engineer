import 'dart:convert';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/application/construction_dependency_repository.dart';
import 'package:chief_site_engineer/application/construction_project_graph_builder.dart';
import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/application/construction_schedule_seed_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/construction_profile_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UTC date-only calendar', () {
    final mondayToSaturday = _calendar(
      start: '2026-09-01',
      weekdays: const [0, 1, 2, 3, 4, 5],
      holidays: const ['2026-09-07'],
    );

    test('canonical weekday mapping is Monday 0 through Sunday 6', () {
      final monday = parseCanonicalConstructionDate('2026-09-07');
      expect([
        for (var offset = 0; offset < 7; offset += 1)
          canonicalConstructionWeekday(monday.add(Duration(days: offset))),
      ], orderedEquals(const [0, 1, 2, 3, 4, 5, 6]));
    });

    test('workday selection and holiday exclusion are exact', () {
      expect(
        isConstructionWorkday(
          parseCanonicalConstructionDate('2026-09-05'),
          mondayToSaturday,
        ),
        isTrue,
      );
      expect(
        isConstructionWorkday(
          parseCanonicalConstructionDate('2026-09-06'),
          mondayToSaturday,
        ),
        isFalse,
      );
      expect(
        isConstructionWorkday(
          parseCanonicalConstructionDate('2026-09-07'),
          mondayToSaturday,
        ),
        isFalse,
      );
    });

    test('next workday includes current and skips Sunday plus holiday', () {
      expect(
        formatCanonicalConstructionDate(
          nextConstructionWorkday(
            parseCanonicalConstructionDate('2026-09-05'),
            mondayToSaturday,
            includeCurrent: true,
          ),
        ),
        '2026-09-05',
      );
      expect(
        formatCanonicalConstructionDate(
          nextConstructionWorkday(
            parseCanonicalConstructionDate('2026-09-05'),
            mondayToSaturday,
            includeCurrent: false,
          ),
        ),
        '2026-09-08',
      );
    });

    test('arbitrary weekday configuration is respected', () {
      final tuesdayThursday = _calendar(
        start: '2026-09-01',
        weekdays: const [1, 3],
      );
      expect(
        formatCanonicalConstructionDate(
          nextConstructionWorkday(
            parseCanonicalConstructionDate('2026-09-02'),
            tuesdayThursday,
            includeCurrent: true,
          ),
        ),
        '2026-09-03',
      );
    });

    test('add workdays applies 0, 1 and N without an extra lag boundary', () {
      final friday = parseCanonicalConstructionDate('2026-09-04');
      expect(
        formatCanonicalConstructionDate(
          addConstructionWorkdays(friday, 0, mondayToSaturday),
        ),
        '2026-09-04',
      );
      expect(
        formatCanonicalConstructionDate(
          addConstructionWorkdays(friday, 1, mondayToSaturday),
        ),
        '2026-09-05',
      );
      expect(
        formatCanonicalConstructionDate(
          addConstructionWorkdays(friday, 2, mondayToSaturday),
        ),
        '2026-09-08',
      );
    });

    test('canonical parse and format reject invalid or non-UTC dates', () {
      expect(
        formatCanonicalConstructionDate(
          parseCanonicalConstructionDate('2026-02-28'),
        ),
        '2026-02-28',
      );
      for (final value in ['2026-2-28', '2026-02-30', 'not-a-date']) {
        expect(
          () => parseCanonicalConstructionDate(value),
          _throwsCorpusFailure('invalid_construction_date'),
        );
      }
      expect(
        () => formatCanonicalConstructionDate(DateTime(2026, 9, 1)),
        _throwsCorpusFailure('invalid_construction_date'),
      );
    });
  });

  group('duration semantics', () {
    final calendar = _calendar(
      start: '2026-09-01',
      weekdays: const [0, 1, 2, 3, 4, 5],
      holidays: const ['2026-09-07'],
    );
    final friday = parseCanonicalConstructionDate('2026-09-04');

    test('zero day is a same-day milestone', () {
      expect(
        constructionDurationFinishDate(
          startDate: friday,
          roundedSchedulingDays: 0,
          calendarType: ConstructionActivityDurationCalendarType.workingDay,
          calendar: calendar,
        ),
        friday,
      );
    });

    test('zero working days still require a selected workday start', () {
      final sparseCalendar = _calendar(
        start: '2026-09-01',
        weekdays: const [1, 3],
      );
      expect(
        () => constructionDurationFinishDate(
          startDate: parseCanonicalConstructionDate('2026-09-02'),
          roundedSchedulingDays: 0,
          calendarType: ConstructionActivityDurationCalendarType.workingDay,
          calendar: sparseCalendar,
        ),
        _throwsCorpusFailure('working_duration_non_workday_start'),
      );
    });

    test('working durations are inclusive and skip Sunday and holiday', () {
      expect(
        constructionDurationFinishDate(
          startDate: friday,
          roundedSchedulingDays: 1,
          calendarType: ConstructionActivityDurationCalendarType.workingDay,
          calendar: calendar,
        ),
        friday,
      );
      expect(
        formatCanonicalConstructionDate(
          constructionDurationFinishDate(
            startDate: friday,
            roundedSchedulingDays: 3,
            calendarType: ConstructionActivityDurationCalendarType.workingDay,
            calendar: calendar,
          ),
        ),
        '2026-09-08',
      );
    });

    test('calendar durations include Sunday and use N minus one days', () {
      expect(
        constructionDurationFinishDate(
          startDate: friday,
          roundedSchedulingDays: 1,
          calendarType: ConstructionActivityDurationCalendarType.calendarDay,
          calendar: calendar,
        ),
        friday,
      );
      expect(
        formatCanonicalConstructionDate(
          constructionDurationFinishDate(
            startDate: friday,
            roundedSchedulingDays: 3,
            calendarType: ConstructionActivityDurationCalendarType.calendarDay,
            calendar: calendar,
          ),
        ),
        '2026-09-06',
      );
    });

    test('negative rounded duration fails closed', () {
      expect(
        () => constructionDurationFinishDate(
          startDate: friday,
          roundedSchedulingDays: -1,
          calendarType: ConstructionActivityDurationCalendarType.workingDay,
          calendar: calendar,
        ),
        _throwsCorpusFailure('invalid_schedule_duration'),
      );
    });
  });

  group('dependency propagation and post-validation', () {
    test('FS0 uses finish plus one calendar day and no extra advance', () {
      final result = _microSchedule(
        seeds: [_seed('A', 1), _seed('B', 1)],
        edges: [_edge('A', 'B', relationship: 'FS', lag: 0)],
      );
      expect(_start(result, 'B'), '2026-09-05');
    });

    test('FS1 advances one selected working day', () {
      final result = _microSchedule(
        seeds: [_seed('A', 1), _seed('B', 1)],
        edges: [_edge('A', 'B', relationship: 'FS', lag: 1)],
      );
      expect(_start(result, 'B'), '2026-09-08');
    });

    test('FS0 across Sunday and a holiday normalizes to Tuesday', () {
      final result = _microSchedule(
        seeds: [_seed('A', 2), _seed('B', 1)],
        edges: [_edge('A', 'B', relationship: 'FS', lag: 0)],
      );
      expect(_start(result, 'B'), '2026-09-08');
    });

    test('SS0 and SS1 use predecessor start', () {
      final ss0 = _microSchedule(
        seeds: [_seed('A', 3), _seed('B', 1)],
        edges: [_edge('A', 'B', relationship: 'SS', lag: 0)],
      );
      final ss1 = _microSchedule(
        seeds: [_seed('A', 3), _seed('B', 1)],
        edges: [_edge('A', 'B', relationship: 'SS', lag: 1)],
      );
      expect(_start(ss0, 'B'), '2026-09-04');
      expect(_start(ss1, 'B'), '2026-09-05');
    });

    test('public dependency candidate helper preserves engine semantics', () {
      for (final specification in [
        _edge('A', 'B', relationship: 'FS', lag: 0),
        _edge('A', 'B', relationship: 'SS', lag: 1),
      ]) {
        final scenario = _microScenario(
          seeds: [_seed('A', 3), _seed('B', 1)],
          edges: [specification],
        );
        final schedule = scenario.engine.build(
          profile: scenario.profile,
          graph: scenario.graph,
          seedCatalog: scenario.catalog,
        );
        final predecessor = schedule.scheduledActivities.singleWhere(
          (activity) => activity.activityId == 'A',
        );
        final successor = schedule.scheduledActivities.singleWhere(
          (activity) => activity.activityId == 'B',
        );

        expect(
          constructionDependencyCandidateStart(
            predecessor: predecessor,
            successorCalendarType: successor.durationCalendarType,
            edge: scenario.graph.dependencyEdges.single,
            calendar: scenario.profile.calendar,
          ),
          successor.startDate,
        );
      }
    });

    test('multiple predecessors use the maximum candidate', () {
      final result = _microSchedule(
        seeds: [
          _seed('A', 1),
          _seed(
            'C',
            2,
            type: ConstructionActivityDurationCalendarType.calendarDay,
          ),
          _seed('B', 1),
        ],
        edges: [
          _edge('A', 'B', relationship: 'SS', lag: 0),
          _edge('C', 'B', relationship: 'FS', lag: 0),
        ],
      );
      expect(_start(result, 'B'), '2026-09-08');
    });

    test('working successor is normalized after a calendar predecessor', () {
      final result = _microSchedule(
        seeds: [
          _seed(
            'A',
            2,
            type: ConstructionActivityDurationCalendarType.calendarDay,
          ),
          _seed('B', 1),
        ],
        edges: [_edge('A', 'B', relationship: 'FS', lag: 0)],
      );
      expect(_start(result, 'B'), '2026-09-08');
    });

    test('unknown relationship and lag unit fail closed', () {
      expect(
        () => ConstructionDependencyRelationshipType.fromJson('FF'),
        _throwsCorpusFailure('invalid_dependency_relationship_type'),
      );
      expect(
        () => ConstructionDependencyLagUnit.fromJson('CALENDAR_DAY'),
        _throwsCorpusFailure('invalid_dependency_lag_unit'),
      );
    });

    test('a deliberately corrupted schedule fails independent validation', () {
      final scenario = _microScenario(
        seeds: [_seed('A', 2), _seed('B', 1)],
        edges: [_edge('A', 'B', relationship: 'FS', lag: 0)],
      );
      final valid = scenario.engine.build(
        profile: scenario.profile,
        graph: scenario.graph,
        seedCatalog: scenario.catalog,
      );
      final corruptedActivities = [
        for (final activity in valid.scheduledActivities)
          activity.activityId == 'B'
              ? activity.copyWith(
                  startDate: parseCanonicalConstructionDate('2026-09-05'),
                  finishDate: parseCanonicalConstructionDate('2026-09-05'),
                )
              : activity,
      ];
      expect(
        () => scenario.engine.validateSchedule(
          schedule: valid.copyWith(scheduledActivities: corruptedActivities),
          profile: scenario.profile,
          graph: scenario.graph,
          seedCatalog: scenario.catalog,
        ),
        _throwsCorpusFailure('schedule_dependency_constraint_violation'),
      );
    });

    test('a later legal successor start fails exact post-validation', () {
      final scenario = _microScenario(
        seeds: [_seed('A', 3), _seed('B', 1)],
        edges: [_edge('A', 'B', relationship: 'SS', lag: 0)],
      );
      final valid = scenario.engine.build(
        profile: scenario.profile,
        graph: scenario.graph,
        seedCatalog: scenario.catalog,
      );
      expect(_start(valid, 'B'), '2026-09-04');
      final corruptedActivities = [
        for (final activity in valid.scheduledActivities)
          activity.activityId == 'B'
              ? activity.copyWith(
                  startDate: parseCanonicalConstructionDate('2026-09-05'),
                  finishDate: parseCanonicalConstructionDate('2026-09-05'),
                )
              : activity,
      ];
      expect(
        () => scenario.engine.validateSchedule(
          schedule: valid.copyWith(scheduledActivities: corruptedActivities),
          profile: scenario.profile,
          graph: scenario.graph,
          seedCatalog: scenario.catalog,
        ),
        _throwsCorpusFailure('schedule_dependency_start_mismatch'),
      );
    });
  });

  group('canonical P01/P02/P03 schedule references', () {
    late ConstructionCorpus corpus;
    late ConstructionScheduleSeedCatalog seeds;
    late ConstructionDependencyCatalog dependencies;
    late ConstructionProjectActivityGraphBuilder graphBuilder;
    late ConstructionScheduleDateEngine engine;

    setUpAll(() async {
      corpus = await BundledConstructionCorpusRepository().load();
      seeds = await BundledConstructionScheduleSeedCatalogRepository().load(
        corpus,
      );
      dependencies = await BundledConstructionDependencyCatalogRepository()
          .load(corpus);
      graphBuilder = ConstructionProjectActivityGraphBuilder();
      engine = ConstructionScheduleDateEngine();
    });

    final references = <String, _Reference>{
      'CSE-P01': const _Reference(
        activities: 1687,
        dependencies: 1702,
        roots: 106,
        leaves: 127,
        isolated: 15,
        milestones: 4,
        start: '2026-09-01',
        finish: '2028-06-20',
        scheduleSha:
            '7b5cfff33f01cfff5f8430d5e6742d2ed2e18ddffe0c313e422e5e56c0116709',
        rootsSha:
            'd338a30a7f8dd4bf77d06cc83dd7115630eceb1ee2766f48c4626db7fc2bcac4',
        leavesSha:
            '8e89a80090050ca1c51248f472334ed1e5a066b05078068a6a57e2b6c8c16b62',
        isolatedSha:
            '509a879fd5745019040a82344a8346c0a2c51835b4fb6af1aa880f97a6ee7048',
      ),
      'CSE-P02': const _Reference(
        activities: 599,
        dependencies: 644,
        roots: 27,
        leaves: 43,
        isolated: 5,
        milestones: 4,
        start: '2026-09-01',
        finish: '2027-07-19',
        scheduleSha:
            'f1e186407c68dbdba8b377eadeaf881c667bdc7b48a84ae24b432a179b82962a',
        rootsSha:
            'db7c822ff9df622f0399516a6f75ae841ce39fb31b4ca9d64af463b410ddcba0',
        leavesSha:
            'c15c374ba515e8f4ec875b73900dc3b5502499e0f67a5f8d03697ccf0aaf44ca',
        isolatedSha:
            '3b60bea4b7eb73751af98e72f2e785d8ae10dc49e8f748c95d791be57b34411d',
      ),
      'CSE-P03': const _Reference(
        activities: 3537,
        dependencies: 3605,
        roots: 232,
        leaves: 244,
        isolated: 39,
        milestones: 4,
        start: '2026-09-01',
        finish: '2028-10-20',
        scheduleSha:
            '7772c14a62088f01c44996cb930374d5fa83f7dd982ef9ddff7eeea0023be545',
        rootsSha:
            'cb2b557a9a65578c4336fa54e2bacf3bc13feecd59e5b85a6e896e8b9e8078c0',
        leavesSha:
            'cb44204f8862423cae1d793733648c059ab82e5d08e684eab4f1c4d54d0dba5d',
        isolatedSha:
            '545902672d0f17c90ccd3cde3efa4c95c56c86a8572ee6ee058268bc51cac73b',
      ),
    };

    for (final entry in references.entries) {
      test('${entry.key} has exact counts, dates and fingerprints', () {
        final profile = switch (entry.key) {
          'CSE-P01' => referenceConstructionProfile01(),
          'CSE-P02' => referenceConstructionProfile02(),
          'CSE-P03' => referenceConstructionProfile03(),
          _ => throw StateError('unknown reference'),
        };
        final graph = graphBuilder.buildFromCatalogs(
          profile: profile,
          corpus: corpus,
          dependencyCatalog: dependencies,
        );
        final schedule = engine.build(
          profile: profile,
          graph: graph,
          seedCatalog: seeds,
        );
        final reference = entry.value;

        expect(graph.activityInstances, hasLength(reference.activities));
        expect(graph.dependencyEdges, hasLength(reference.dependencies));
        expect(schedule.rootInstanceIds, hasLength(reference.roots));
        expect(schedule.leafInstanceIds, hasLength(reference.leaves));
        expect(schedule.isolatedInstanceIds, hasLength(reference.isolated));
        expect(schedule.milestoneInstanceCount, reference.milestones);
        expect(
          formatCanonicalConstructionDate(schedule.scheduleStart),
          reference.start,
        );
        expect(
          formatCanonicalConstructionDate(schedule.scheduleFinish),
          reference.finish,
        );
        expect(_sha(_projection(schedule)), reference.scheduleSha);
        expect(_sha(jsonEncode(schedule.rootInstanceIds)), reference.rootsSha);
        expect(_sha(jsonEncode(schedule.leafInstanceIds)), reference.leavesSha);
        expect(
          _sha(jsonEncode(schedule.isolatedInstanceIds)),
          reference.isolatedSha,
        );
        expect(schedule.syntheticDependencyCount, 0);
        expect(schedule.workdaySundayViolations, 0);
        expect(schedule.workdayHolidayViolations, 0);
        expect(
          schedule.scheduledActivities
              .where((activity) => activity.isIsolated)
              .map((activity) => activity.instanceId),
          orderedEquals(schedule.isolatedInstanceIds),
        );

        final repeated = engine.build(
          profile: profile,
          graph: graph,
          seedCatalog: seeds,
        );
        expect(_projection(repeated), _projection(schedule));
        expect(
          repeated.rootInstanceIds,
          orderedEquals(schedule.rootInstanceIds),
        );
        expect(
          repeated.leafInstanceIds,
          orderedEquals(schedule.leafInstanceIds),
        );
      });
    }
  });
}

ConstructionProjectCalendar _calendar({
  required String start,
  required List<int> weekdays,
  List<String> holidays = const [],
}) => ConstructionProjectCalendar.fromJson({
  'start_date': start,
  'working_weekdays': <Object?>[...weekdays],
  'holidays': <Object?>[...holidays],
  'workday_hours': 8,
});

ConstructionScheduleSeed _seed(
  String activityId,
  double duration, {
  ConstructionActivityDurationCalendarType type =
      ConstructionActivityDurationCalendarType.workingDay,
}) => ConstructionScheduleSeed(
  activityId: activityId,
  durationDays: duration,
  durationCalendarType: type,
  durationStatus: ConstructionScheduleDurationStatus.aiSeedEstimate,
  durationConfidence: ConstructionScheduleDurationConfidence.aiSeed,
);

_EdgeSpec _edge(
  String predecessor,
  String successor, {
  required String relationship,
  required int lag,
}) => _EdgeSpec(predecessor, successor, relationship, lag);

ConstructionProjectReferenceSchedule _microSchedule({
  required List<ConstructionScheduleSeed> seeds,
  required List<_EdgeSpec> edges,
}) {
  final scenario = _microScenario(seeds: seeds, edges: edges);
  return scenario.engine.build(
    profile: scenario.profile,
    graph: scenario.graph,
    seedCatalog: scenario.catalog,
  );
}

_MicroScenario _microScenario({
  required List<ConstructionScheduleSeed> seeds,
  required List<_EdgeSpec> edges,
}) {
  final profile = validConstructionProjectProfile(
    overrides: {
      'project_id': 'PRJ-MICRO',
      'calendar': <String, Object?>{
        'start_date': '2026-09-04',
        'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
        'holidays': <Object?>['2026-09-07'],
        'workday_hours': 8,
      },
    },
  );
  final instances = [for (final seed in seeds) _instance(seed.activityId)];
  final graphEdges = [
    for (var index = 0; index < edges.length; index += 1)
      ConstructionResolvedDependencyEdge(
        edgeKey: 'EDGE-$index',
        templateDependencyId: 'DEP-$index',
        predecessorInstanceId: '${edges[index].predecessor}@PROJECT',
        successorInstanceId: '${edges[index].successor}@PROJECT',
        relationshipType: ConstructionDependencyRelationshipType.fromJson(
          edges[index].relationship,
        ),
        lagValue: edges[index].lag,
        lagUnit: ConstructionDependencyLagUnit.workingDay,
        scopeRule: ConstructionDependencyScopeRule.project,
        isMandatory: true,
        confidence: ConstructionDependencyConfidence.supportedInference,
        reviewStatus: ConstructionDependencyReviewStatus.reviewRequired,
      ),
  ];
  final connected = <String>{};
  for (final edge in graphEdges) {
    connected
      ..add(edge.predecessorInstanceId)
      ..add(edge.successorInstanceId);
  }
  final graph = ConstructionProjectActivityGraph(
    projectId: profile.projectId,
    activityInstances: instances,
    dependencyEdges: graphEdges,
    isolatedInstanceIds: instances
        .map((instance) => instance.instanceId)
        .where((id) => !connected.contains(id)),
    corpusVersion: '0.3-yfk-resource-seed',
    selectedActivityTemplateCount: instances.length,
    selectedDependencyTemplateCount: graphEdges.length,
  );
  final catalog = ConstructionScheduleSeedCatalog(
    metadata: const ConstructionScheduleSeedCatalogMetadata(
      name: 'MICRO TEST SEEDS',
      corpusVersion: '0.3-yfk-resource-seed',
      sourcePublicationStatus: 'RESEARCH_RESOURCE_SEED',
      sourceProductionStatus: 'NOT_FOR_PRODUCTION',
      sourceZipSha256: 'test',
      warning: 'test',
      runtimeScope: 'SCHEDULE_SEED_CATALOG_READ_ONLY_NOT_A_BASELINE',
      activityCount: 0,
      workingDayCount: 0,
      calendarDayCount: 0,
      milestoneCount: 0,
      authoritativeCount: 0,
      aiSeedCount: 0,
      unknownConfidenceCount: 0,
      sourceBackedCount: 0,
      aiSeedEstimateCount: 0,
      unknownStatusCount: 0,
    ),
    seeds: seeds,
  );
  return _MicroScenario(
    profile,
    graph,
    catalog,
    ConstructionScheduleDateEngine(),
  );
}

ConstructionProjectActivityInstance _instance(String activityId) =>
    ConstructionProjectActivityInstance(
      instanceId: '$activityId@PROJECT',
      activityId: activityId,
      wbsCode: 'TEST',
      packageId: 'TEST',
      activityNameTr: activityId,
      repeatDimension: ConstructionActivityRepeatDimension.project,
      context: const ConstructionProjectActivityContext(),
      naturalUnit: 'TEST',
      durationStatus: 'AI_SEED_ESTIMATE',
      durationConfidence: 'D_AI_SEED',
      testSeedDurationDays: 1,
    );

String _start(
  ConstructionProjectReferenceSchedule schedule,
  String activityId,
) => formatCanonicalConstructionDate(
  schedule.scheduledActivities
      .singleWhere((activity) => activity.activityId == activityId)
      .startDate,
);

String _projection(ConstructionProjectReferenceSchedule schedule) =>
    jsonEncode([
      for (final activity in schedule.scheduledActivities)
        <String, Object?>{
          'activity_id': activity.activityId,
          'duration_calendar_type': activity.durationCalendarType.jsonValue,
          'duration_confidence': activity.durationConfidence.jsonValue,
          'duration_days': activity.durationDays,
          'duration_status': activity.durationStatus.jsonValue,
          'finish_date': formatCanonicalConstructionDate(activity.finishDate),
          'instance_id': activity.instanceId,
          'is_isolated': activity.isIsolated,
          'start_date': formatCanonicalConstructionDate(activity.startDate),
        },
    ]);

String _sha(String value) => sha256.convert(utf8.encode(value)).toString();

Matcher _throwsCorpusFailure(String code) => throwsA(
  isA<ConstructionCorpusFailure>().having(
    (failure) => failure.code,
    'code',
    code,
  ),
);

class _EdgeSpec {
  const _EdgeSpec(
    this.predecessor,
    this.successor,
    this.relationship,
    this.lag,
  );

  final String predecessor;
  final String successor;
  final String relationship;
  final int lag;
}

class _MicroScenario {
  const _MicroScenario(this.profile, this.graph, this.catalog, this.engine);

  final ConstructionProjectProfile profile;
  final ConstructionProjectActivityGraph graph;
  final ConstructionScheduleSeedCatalog catalog;
  final ConstructionScheduleDateEngine engine;
}

class _Reference {
  const _Reference({
    required this.activities,
    required this.dependencies,
    required this.roots,
    required this.leaves,
    required this.isolated,
    required this.milestones,
    required this.start,
    required this.finish,
    required this.scheduleSha,
    required this.rootsSha,
    required this.leavesSha,
    required this.isolatedSha,
  });

  final int activities;
  final int dependencies;
  final int roots;
  final int leaves;
  final int isolated;
  final int milestones;
  final String start;
  final String finish;
  final String scheduleSha;
  final String rootsSha;
  final String leavesSha;
  final String isolatedSha;
}
