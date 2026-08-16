import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:flutter/services.dart';

typedef ConstructionScheduleSeedAssetLoader =
    Future<String> Function(String key);

abstract interface class ConstructionScheduleSeedCatalogRepository {
  Future<ConstructionScheduleSeedCatalog> load(ConstructionCorpus corpus);
}

class BundledConstructionScheduleSeedCatalogRepository
    implements ConstructionScheduleSeedCatalogRepository {
  BundledConstructionScheduleSeedCatalogRepository({
    ConstructionScheduleSeedAssetLoader? loader,
    this.assetPath = defaultAssetPath,
  }) : _loader = loader ?? ((key) => rootBundle.loadString(key));

  static const defaultAssetPath =
      'assets/corpus/cse_construction_schedule_seed_catalog_v0_3.b64';
  static const expectedName =
      'CSE Construction Schedule Seed Catalog Runtime v0.3';
  static const expectedCorpusVersion = '0.3-yfk-resource-seed';
  static const expectedPublicationStatus = 'RESEARCH_RESOURCE_SEED';
  static const expectedProductionStatus = 'NOT_FOR_PRODUCTION';
  static const expectedSourceZipSha256 =
      'de2bf1a542a331ea79fadddb81e315120e46c2e3b8204ea239e30fb4aaa616cd';
  static const expectedWarning =
      'Durations are reference/test seeds. D_AI_SEED and E_UNKNOWN values '
      'are not contractual, authoritative, or production baselines.';
  static const expectedRuntimeScope =
      'SCHEDULE_SEED_CATALOG_READ_ONLY_NOT_A_BASELINE';
  static const expectedActivityCount = 316;
  static const expectedWorkingDayCount = 313;
  static const expectedCalendarDayCount = 3;
  static const expectedMilestoneCount = 4;
  static const expectedAuthoritativeCount = 1;
  static const expectedAiSeedCount = 295;
  static const expectedUnknownConfidenceCount = 20;
  static const expectedSourceBackedCount = 1;
  static const expectedAiSeedEstimateCount = 295;
  static const expectedUnknownStatusCount = 20;

  final ConstructionScheduleSeedAssetLoader _loader;
  final String assetPath;

  @override
  Future<ConstructionScheduleSeedCatalog> load(
    ConstructionCorpus corpus,
  ) async {
    try {
      _validateActivityAuthority(corpus);
      final encoded = (await _loader(assetPath)).trim();
      final decodedText = utf8.decode(gzip.decode(base64Decode(encoded)));
      final root = _asMap(
        jsonDecode(decodedText),
        'invalid_schedule_seed_catalog_json',
      );
      final catalog = _parseCatalog(root);
      _validateCatalog(catalog, corpus);
      return catalog;
    } on ConstructionCorpusFailure {
      rethrow;
    } on Object {
      throw const ConstructionCorpusFailure(
        'schedule_seed_catalog_load_failed',
      );
    }
  }

  ConstructionScheduleSeedCatalog _parseCatalog(Map<String, Object?> root) {
    _requireExactKeys(root, const {
      'metadata',
      'records',
    }, 'invalid_schedule_seed_catalog');
    final metadataMap = _asMap(
      root['metadata'],
      'invalid_schedule_seed_metadata',
    );
    _requireExactKeys(metadataMap, const {
      'name',
      'corpus_version',
      'source_publication_status',
      'source_production_status',
      'source_zip_sha256',
      'warning',
      'runtime_scope',
      'counts',
      'duration_confidence_counts',
      'duration_status_counts',
    }, 'invalid_schedule_seed_metadata');

    final counts = _asMap(
      metadataMap['counts'],
      'invalid_schedule_seed_metadata',
    );
    _requireExactKeys(counts, const {
      'activities',
      'calendar_day',
      'milestones',
      'working_day',
    }, 'invalid_schedule_seed_metadata');
    final confidenceCounts = _asMap(
      metadataMap['duration_confidence_counts'],
      'invalid_schedule_seed_metadata',
    );
    _requireExactKeys(confidenceCounts, const {
      'A_AUTHORITATIVE',
      'D_AI_SEED',
      'E_UNKNOWN',
    }, 'invalid_schedule_seed_metadata');
    final statusCounts = _asMap(
      metadataMap['duration_status_counts'],
      'invalid_schedule_seed_metadata',
    );
    _requireExactKeys(statusCounts, const {
      'AI_SEED_ESTIMATE',
      'SOURCE_BACKED',
      'UNKNOWN',
    }, 'invalid_schedule_seed_metadata');

    final metadata = ConstructionScheduleSeedCatalogMetadata(
      name: _requiredString(metadataMap, 'name'),
      corpusVersion: _requiredString(metadataMap, 'corpus_version'),
      sourcePublicationStatus: _requiredString(
        metadataMap,
        'source_publication_status',
      ),
      sourceProductionStatus: _requiredString(
        metadataMap,
        'source_production_status',
      ),
      sourceZipSha256: _requiredString(metadataMap, 'source_zip_sha256'),
      warning: _requiredString(metadataMap, 'warning'),
      runtimeScope: _requiredString(metadataMap, 'runtime_scope'),
      activityCount: _requiredInt(counts, 'activities'),
      workingDayCount: _requiredInt(counts, 'working_day'),
      calendarDayCount: _requiredInt(counts, 'calendar_day'),
      milestoneCount: _requiredInt(counts, 'milestones'),
      authoritativeCount: _requiredInt(confidenceCounts, 'A_AUTHORITATIVE'),
      aiSeedCount: _requiredInt(confidenceCounts, 'D_AI_SEED'),
      unknownConfidenceCount: _requiredInt(confidenceCounts, 'E_UNKNOWN'),
      sourceBackedCount: _requiredInt(statusCounts, 'SOURCE_BACKED'),
      aiSeedEstimateCount: _requiredInt(statusCounts, 'AI_SEED_ESTIMATE'),
      unknownStatusCount: _requiredInt(statusCounts, 'UNKNOWN'),
    );

    final seeds = _asList(root['records'], 'invalid_schedule_seed_records')
        .map((value) {
          final map = _asMap(value, 'invalid_schedule_seed');
          _requireExactKeys(map, const {
            'activity_id',
            'duration_days',
            'duration_calendar_type',
            'duration_status',
            'duration_confidence',
          }, 'invalid_schedule_seed');
          final duration = map['duration_days'];
          if (duration is! num) {
            throw const ConstructionCorpusFailure(
              'invalid_schedule_seed_duration',
            );
          }
          return ConstructionScheduleSeed(
            activityId: _requiredString(map, 'activity_id'),
            durationDays: duration.toDouble(),
            durationCalendarType:
                ConstructionActivityDurationCalendarType.fromJson(
                  map['duration_calendar_type'],
                ),
            durationStatus: ConstructionScheduleDurationStatus.fromJson(
              map['duration_status'],
            ),
            durationConfidence: ConstructionScheduleDurationConfidence.fromJson(
              map['duration_confidence'],
            ),
          );
        })
        .toList(growable: false);
    return ConstructionScheduleSeedCatalog(metadata: metadata, seeds: seeds);
  }

  void _validateActivityAuthority(ConstructionCorpus corpus) {
    if (corpus.metadata.corpusVersion !=
            BundledConstructionCorpusRepository.expectedCorpusVersion ||
        corpus.metadata.sourcePublicationStatus !=
            BundledConstructionCorpusRepository.expectedPublicationStatus ||
        corpus.metadata.sourceProductionStatus !=
            BundledConstructionCorpusRepository.expectedProductionStatus ||
        corpus.metadata.runtimeScope !=
            BundledConstructionCorpusRepository.expectedRuntimeScope ||
        corpus.metadata.activityCount != expectedActivityCount ||
        corpus.activities.length != expectedActivityCount ||
        corpus.activities.map((item) => item.activityId).toSet().length !=
            expectedActivityCount) {
      throw const ConstructionCorpusFailure(
        'invalid_schedule_seed_activity_authority',
      );
    }
  }

  void _validateCatalog(
    ConstructionScheduleSeedCatalog catalog,
    ConstructionCorpus corpus,
  ) {
    final metadata = catalog.metadata;
    if (metadata.name != expectedName ||
        metadata.corpusVersion != expectedCorpusVersion ||
        metadata.sourcePublicationStatus != expectedPublicationStatus ||
        metadata.sourceProductionStatus != expectedProductionStatus ||
        metadata.sourceZipSha256 != expectedSourceZipSha256 ||
        metadata.warning != expectedWarning ||
        metadata.runtimeScope != expectedRuntimeScope) {
      throw const ConstructionCorpusFailure(
        'unexpected_schedule_seed_metadata',
      );
    }
    if (metadata.activityCount != expectedActivityCount ||
        metadata.workingDayCount != expectedWorkingDayCount ||
        metadata.calendarDayCount != expectedCalendarDayCount ||
        metadata.milestoneCount != expectedMilestoneCount ||
        metadata.authoritativeCount != expectedAuthoritativeCount ||
        metadata.aiSeedCount != expectedAiSeedCount ||
        metadata.unknownConfidenceCount != expectedUnknownConfidenceCount ||
        metadata.sourceBackedCount != expectedSourceBackedCount ||
        metadata.aiSeedEstimateCount != expectedAiSeedEstimateCount ||
        metadata.unknownStatusCount != expectedUnknownStatusCount) {
      throw const ConstructionCorpusFailure('unexpected_schedule_seed_counts');
    }
    if (catalog.seeds.length != metadata.activityCount) {
      throw const ConstructionCorpusFailure('schedule_seed_count_mismatch');
    }

    final calendarCounts = _counts(
      catalog.seeds.map((seed) => seed.durationCalendarType),
    );
    final confidenceCounts = _counts(
      catalog.seeds.map((seed) => seed.durationConfidence),
    );
    final statusCounts = _counts(
      catalog.seeds.map((seed) => seed.durationStatus),
    );
    if (calendarCounts[ConstructionActivityDurationCalendarType.workingDay] !=
            metadata.workingDayCount ||
        calendarCounts[ConstructionActivityDurationCalendarType.calendarDay] !=
            metadata.calendarDayCount ||
        catalog.seeds.where((seed) => seed.isMilestone).length !=
            metadata.milestoneCount ||
        confidenceCounts[ConstructionScheduleDurationConfidence
                .authoritative] !=
            metadata.authoritativeCount ||
        confidenceCounts[ConstructionScheduleDurationConfidence.aiSeed] !=
            metadata.aiSeedCount ||
        confidenceCounts[ConstructionScheduleDurationConfidence.unknown] !=
            metadata.unknownConfidenceCount ||
        statusCounts[ConstructionScheduleDurationStatus.sourceBacked] !=
            metadata.sourceBackedCount ||
        statusCounts[ConstructionScheduleDurationStatus.aiSeedEstimate] !=
            metadata.aiSeedEstimateCount ||
        statusCounts[ConstructionScheduleDurationStatus.unknown] !=
            metadata.unknownStatusCount) {
      throw const ConstructionCorpusFailure('physical_schedule_seed_mismatch');
    }

    final activityById = {
      for (final activity in corpus.activities) activity.activityId: activity,
    };
    final seedIds = catalog.seedsByActivityId.keys.toSet();
    final activityIds = activityById.keys.toSet();
    if (seedIds.difference(activityIds).isNotEmpty) {
      throw const ConstructionCorpusFailure('unknown_schedule_seed_activity');
    }
    if (activityIds.difference(seedIds).isNotEmpty) {
      throw const ConstructionCorpusFailure('missing_schedule_seed_activity');
    }
    for (final seed in catalog.seeds) {
      final activity = activityById[seed.activityId]!;
      if (activity.testSeedDurationDays != seed.durationDays ||
          activity.durationStatus != seed.durationStatus.jsonValue ||
          activity.durationConfidence != seed.durationConfidence.jsonValue) {
        throw const ConstructionCorpusFailure(
          'schedule_seed_activity_metadata_mismatch',
        );
      }
    }
  }
}

Map<T, int> _counts<T>(Iterable<T> values) {
  final result = <T, int>{};
  for (final value in values) {
    result[value] = (result[value] ?? 0) + 1;
  }
  return result;
}

void _requireExactKeys(
  Map<String, Object?> map,
  Set<String> expectedKeys,
  String failureCode,
) {
  if (map.length != expectedKeys.length ||
      map.keys.any((key) => !expectedKeys.contains(key))) {
    throw ConstructionCorpusFailure(failureCode);
  }
}

Map<String, Object?> _asMap(Object? value, String failureCode) {
  if (value is! Map) {
    throw ConstructionCorpusFailure(failureCode);
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw ConstructionCorpusFailure(failureCode);
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<Object?> _asList(Object? value, String failureCode) {
  if (value is! List) {
    throw ConstructionCorpusFailure(failureCode);
  }
  return List<Object?>.from(value);
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw const ConstructionCorpusFailure('invalid_schedule_seed_value');
  }
  return value;
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) {
    throw const ConstructionCorpusFailure('invalid_schedule_seed_value');
  }
  return value;
}
