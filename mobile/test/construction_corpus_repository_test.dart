import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled activity catalog loads expected read-only counts', () async {
    final corpus = await BundledConstructionCorpusRepository().load();

    expect(corpus.metadata.corpusVersion, '0.3-yfk-resource-seed');
    expect(corpus.metadata.sourceProductionStatus, 'NOT_FOR_PRODUCTION');
    expect(corpus.wbsPackages, hasLength(34));
    expect(corpus.activities, hasLength(316));
  });

  test('activity search is Turkish-normalized and deterministic', () async {
    final corpus = await BundledConstructionCorpusRepository().load();

    final first = corpus.searchActivities('DOLGU');
    final second = corpus.searchActivities('dolgu');

    expect(first, isNotEmpty);
    expect(
      first.map((item) => item.activityId),
      second.map((item) => item.activityId),
    );
    expect(first.any((item) => item.activityNameTr.contains('Dolgu')), isTrue);
  });

  test('project profile filters foundation branches deterministically', () async {
    final corpus = await BundledConstructionCorpusRepository().load();
    final profile = ConstructionProjectProfile({
      'foundation_type': 'RADYE',
      'excavation_required': true,
      'has_basement': true,
      'has_shoring': true,
      'has_piles': false,
      'ground_improvement_required': false,
      'has_dewatering': false,
      'foundation_waterproofing_required': true,
      'foundation_thermal_insulation_required': false,
      'has_steel_auxiliary': false,
      'has_precast_auxiliary': false,
      'facade_type': 'MANTOLAMA',
      'roof_type': 'TERAS',
      'wall_type': 'GAZBETON',
      'has_elevator': true,
      'has_generator': false,
      'has_ups': false,
      'has_transformer': false,
      'has_bms': false,
      'has_sprinkler': true,
      'has_fire_system': true,
      'has_parking': true,
      'has_landscape': true,
    });

    final first = corpus.filterActivities(profile);
    final second = corpus.filterActivities(profile);

    expect(
      first.map((item) => item.activityId),
      second.map((item) => item.activityId),
    );
    expect(first.any((item) => item.activityId.contains('RADYE')), isTrue);
    expect(first.any((item) => item.activityId.contains('TEKIL')), isFalse);
  });

  test('missing profile field fails closed for field rules', () {
    final rule = ConstructionApplicabilityRule.fromJson({
      'field': 'foundation_type',
      'op': 'neq',
      'value': 'NONE',
    });

    expect(rule.matches(const <String, Object?>{}), isFalse);
  });

  test('all and not applicability are supported', () {
    final rule = ConstructionApplicabilityRule.fromJson({
      'op': 'all',
      'rules': [
        {'field': 'has_basement', 'op': 'eq', 'value': true},
        {
          'op': 'not',
          'rule': {'field': 'foundation_type', 'op': 'eq', 'value': 'TEKIL'},
        },
      ],
    });

    expect(
      rule.matches({'has_basement': true, 'foundation_type': 'RADYE'}),
      isTrue,
    );
    expect(
      rule.matches({'has_basement': true, 'foundation_type': 'TEKIL'}),
      isFalse,
    );
  });

  test('unsupported applicability fails closed', () {
    expect(
      () => ConstructionApplicabilityRule.fromJson({'op': 'script'}),
      throwsA(
        isA<ConstructionCorpusFailure>().having(
          (failure) => failure.code,
          'code',
          'unsupported_applicability',
        ),
      ),
    );
  });

  test('duplicate activities are rejected', () async {
    final root = _minimalRoot();
    final activities = root['activities'] as List<dynamic>;
    activities.add(Map<String, dynamic>.from(activities.single as Map));
    (root['metadata'] as Map<String, dynamic>)['counts']['activities'] = 2;

    await expectLater(
      _repositoryForRoot(root).load(),
      throwsA(
        isA<ConstructionCorpusFailure>().having(
          (failure) => failure.code,
          'code',
          'duplicate_activity',
        ),
      ),
    );
  });

  test('unknown WBS/package references are rejected', () async {
    final root = _minimalRoot();
    final activity = (root['activities'] as List<dynamic>).single
        as Map<String, dynamic>;
    activity['wbs_code'] = '99';

    await expectLater(
      _repositoryForRoot(root).load(),
      throwsA(
        isA<ConstructionCorpusFailure>().having(
          (failure) => failure.code,
          'code',
          'dangling_activity_package',
        ),
      ),
    );
  });
}

BundledConstructionCorpusRepository _repositoryForRoot(
  Map<String, dynamic> root,
) => BundledConstructionCorpusRepository(
  loader: (_) async => base64Encode(gzip.encode(utf8.encode(jsonEncode(root)))),
);

Map<String, dynamic> _minimalRoot() => {
  'metadata': {
    'name': 'test',
    'corpus_version': 'test',
    'source_publication_status': 'RESEARCH_RESOURCE_SEED',
    'source_production_status': 'NOT_FOR_PRODUCTION',
    'warning': 'test only',
    'runtime_scope':
        'ACTIVITY_CATALOG_READ_ONLY_NO_YFK_RESOURCE_COEFFICIENTS',
    'counts': {'wbs_packages': 1, 'activities': 1},
  },
  'profile_fields': ['foundation_type'],
  'wbs_packages': [
    {
      'wbs_code': '01',
      'package_id': 'PKG-01',
      'package_name_tr': 'Test',
      'package_name_en': 'Test',
      'frequency_class': 'CORE',
    },
  ],
  'activities': [
    {
      'activity_id': 'A1',
      'wbs_code': '01',
      'package_id': 'PKG-01',
      'activity_name_tr': 'Dolgu',
      'aliases_tr': ['0/63 dolgu'],
      'applicability': {'op': 'always'},
      'repeat_dimension': 'PROJECT',
      'natural_unit': 'm3',
      'duration_status': 'AI_SEED_ESTIMATE',
      'duration_confidence': 'D_AI_SEED',
      'test_seed_duration_days': 2,
      'sequence_confidence': 'C_SUPPORTED_INFERENCE',
      'sequence_index': 1,
    },
  ],
};
