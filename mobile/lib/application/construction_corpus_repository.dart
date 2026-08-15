import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:flutter/services.dart';

typedef ConstructionCorpusAssetLoader = Future<String> Function(String key);

abstract interface class ConstructionCorpusRepository {
  Future<ConstructionCorpus> load();
}

class BundledConstructionCorpusRepository
    implements ConstructionCorpusRepository {
  BundledConstructionCorpusRepository({
    ConstructionCorpusAssetLoader? loader,
    this.assetPath = defaultAssetPath,
  }) : _loader = loader ?? ((key) => rootBundle.loadString(key));

  static const defaultAssetPath =
      'assets/corpus/cse_construction_activity_catalog_v0_3.b64';
  static const expectedCorpusVersion = '0.3-yfk-resource-seed';
  static const expectedPublicationStatus = 'RESEARCH_RESOURCE_SEED';
  static const expectedProductionStatus = 'NOT_FOR_PRODUCTION';
  static const expectedRuntimeScope =
      'ACTIVITY_CATALOG_READ_ONLY_NO_YFK_RESOURCE_COEFFICIENTS';
  static const expectedWbsCount = 34;
  static const expectedActivityCount = 316;
  static const expectedProfileFieldCount = 29;

  final ConstructionCorpusAssetLoader _loader;
  final String assetPath;

  @override
  Future<ConstructionCorpus> load() async {
    try {
      final encoded = (await _loader(assetPath)).trim();
      final compressed = base64Decode(encoded);
      final decodedText = utf8.decode(gzip.decode(compressed));
      final root = _asMap(jsonDecode(decodedText), 'invalid_corpus_json');
      final corpus = _parseCorpus(root);
      _validateCorpus(corpus);
      return corpus;
    } on ConstructionCorpusFailure {
      rethrow;
    } on Object {
      throw const ConstructionCorpusFailure('corpus_load_failed');
    }
  }

  ConstructionCorpus _parseCorpus(Map<String, Object?> root) {
    final metadataMap = _asMap(root['metadata'], 'invalid_metadata');
    final counts = _asMap(metadataMap['counts'], 'invalid_metadata');
    final metadata = ConstructionCorpusMetadata(
      name: _requiredString(metadataMap, 'name', 'invalid_metadata'),
      corpusVersion: _requiredString(
        metadataMap,
        'corpus_version',
        'invalid_metadata',
      ),
      sourcePublicationStatus: _requiredString(
        metadataMap,
        'source_publication_status',
        'invalid_metadata',
      ),
      sourceProductionStatus: _requiredString(
        metadataMap,
        'source_production_status',
        'invalid_metadata',
      ),
      warning: _requiredString(metadataMap, 'warning', 'invalid_metadata'),
      runtimeScope: _requiredString(
        metadataMap,
        'runtime_scope',
        'invalid_metadata',
      ),
      wbsCount: _requiredInt(counts, 'wbs_packages', 'invalid_metadata'),
      activityCount: _requiredInt(counts, 'activities', 'invalid_metadata'),
    );

    final profileFields = _stringList(
      root['profile_fields'],
      'invalid_profile_fields',
    );
    final wbsPackages = _asList(root['wbs_packages'], 'invalid_wbs')
        .map((value) {
          final map = _asMap(value, 'invalid_wbs');
          return ConstructionWbsPackage(
            wbsCode: _requiredString(map, 'wbs_code', 'invalid_wbs'),
            packageId: _requiredString(map, 'package_id', 'invalid_wbs'),
            packageNameTr: _requiredString(
              map,
              'package_name_tr',
              'invalid_wbs',
            ),
            packageNameEn: _requiredString(
              map,
              'package_name_en',
              'invalid_wbs',
            ),
            frequencyClass: _requiredString(
              map,
              'frequency_class',
              'invalid_wbs',
            ),
          );
        })
        .toList(growable: false);

    final activities = _asList(root['activities'], 'invalid_activities')
        .map((value) {
          final map = _asMap(value, 'invalid_activity');
          return ConstructionActivity(
            activityId: _requiredString(map, 'activity_id', 'invalid_activity'),
            wbsCode: _requiredString(map, 'wbs_code', 'invalid_activity'),
            packageId: _requiredString(map, 'package_id', 'invalid_activity'),
            activityNameTr: _requiredString(
              map,
              'activity_name_tr',
              'invalid_activity',
            ),
            aliasesTr: _stringList(map['aliases_tr'], 'invalid_activity'),
            applicability: ConstructionApplicabilityRule.fromJson(
              _asMap(map['applicability'], 'invalid_applicability'),
            ),
            repeatDimension: _requiredString(
              map,
              'repeat_dimension',
              'invalid_activity',
            ),
            naturalUnit: _requiredString(
              map,
              'natural_unit',
              'invalid_activity',
            ),
            durationStatus: _requiredString(
              map,
              'duration_status',
              'invalid_activity',
            ),
            durationConfidence: _requiredString(
              map,
              'duration_confidence',
              'invalid_activity',
            ),
            testSeedDurationDays: _optionalDouble(
              map['test_seed_duration_days'],
              'invalid_activity',
            ),
            sequenceConfidence: _requiredString(
              map,
              'sequence_confidence',
              'invalid_activity',
            ),
            sequenceIndex: _requiredInt(
              map,
              'sequence_index',
              'invalid_activity',
            ),
          );
        })
        .toList(growable: false);

    return ConstructionCorpus(
      metadata: metadata,
      profileFields: profileFields,
      wbsPackages: wbsPackages,
      activities: activities,
    );
  }

  void _validateCorpus(ConstructionCorpus corpus) {
    if (corpus.metadata.corpusVersion != expectedCorpusVersion) {
      throw const ConstructionCorpusFailure('unsupported_corpus_version');
    }
    if (corpus.metadata.sourcePublicationStatus != expectedPublicationStatus) {
      throw const ConstructionCorpusFailure('unexpected_publication_status');
    }
    if (corpus.metadata.sourceProductionStatus != expectedProductionStatus) {
      throw const ConstructionCorpusFailure('unexpected_production_status');
    }
    if (corpus.metadata.runtimeScope != expectedRuntimeScope) {
      throw const ConstructionCorpusFailure('unsupported_runtime_scope');
    }
    if (corpus.metadata.wbsCount != expectedWbsCount ||
        corpus.metadata.activityCount != expectedActivityCount) {
      throw const ConstructionCorpusFailure('unexpected_corpus_counts');
    }
    if (corpus.profileFields.length != expectedProfileFieldCount) {
      throw const ConstructionCorpusFailure('unexpected_profile_field_count');
    }
    if (corpus.metadata.wbsCount != corpus.wbsPackages.length ||
        corpus.metadata.activityCount != corpus.activities.length) {
      throw const ConstructionCorpusFailure('corpus_count_mismatch');
    }
    if (_hasDuplicates(corpus.profileFields)) {
      throw const ConstructionCorpusFailure('duplicate_profile_field');
    }
    if (_hasDuplicates(corpus.wbsPackages.map((item) => item.wbsCode)) ||
        _hasDuplicates(corpus.wbsPackages.map((item) => item.packageId))) {
      throw const ConstructionCorpusFailure('duplicate_wbs');
    }
    if (_hasDuplicates(corpus.activities.map((item) => item.activityId))) {
      throw const ConstructionCorpusFailure('duplicate_activity');
    }
    final knownPairs = corpus.wbsPackages
        .map((item) => (item.wbsCode, item.packageId))
        .toSet();
    final profileFields = corpus.profileFields.toSet();
    for (final activity in corpus.activities) {
      if (!knownPairs.contains((activity.wbsCode, activity.packageId))) {
        throw const ConstructionCorpusFailure('dangling_activity_package');
      }
      activity.applicability.validateProfileFields(profileFields);
    }
  }
}

bool _hasDuplicates(Iterable<String> values) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      return true;
    }
  }
  return false;
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

List<String> _stringList(Object? value, String failureCode) {
  final result = <String>[];
  for (final item in _asList(value, failureCode)) {
    if (item is! String || item.isEmpty) {
      throw ConstructionCorpusFailure(failureCode);
    }
    result.add(item);
  }
  return List.unmodifiable(result);
}

String _requiredString(
  Map<String, Object?> map,
  String key,
  String failureCode,
) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw ConstructionCorpusFailure(failureCode);
  }
  return value;
}

int _requiredInt(Map<String, Object?> map, String key, String failureCode) {
  final value = map[key];
  if (value is! int) {
    throw ConstructionCorpusFailure(failureCode);
  }
  return value;
}

double? _optionalDouble(Object? value, String failureCode) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw ConstructionCorpusFailure(failureCode);
}
