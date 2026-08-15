import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:flutter/services.dart';

typedef ConstructionDependencyAssetLoader = Future<String> Function(String key);

abstract interface class ConstructionDependencyCatalogRepository {
  Future<ConstructionDependencyCatalog> load(ConstructionCorpus activityCorpus);
}

class BundledConstructionDependencyCatalogRepository
    implements ConstructionDependencyCatalogRepository {
  BundledConstructionDependencyCatalogRepository({
    ConstructionDependencyAssetLoader? loader,
    this.assetPath = defaultAssetPath,
  }) : _loader = loader ?? ((key) => rootBundle.loadString(key));

  static const defaultAssetPath =
      'assets/corpus/cse_construction_dependency_catalog_v0_3.b64';
  static const expectedName =
      'CSE Construction Dependency Catalog Runtime v0.3';
  static const expectedCorpusVersion = '0.3-yfk-resource-seed';
  static const expectedPublicationStatus = 'RESEARCH_RESOURCE_SEED';
  static const expectedProductionStatus = 'NOT_FOR_PRODUCTION';
  static const expectedSourceZipSha256 =
      'de2bf1a542a331ea79fadddb81e315120e46c2e3b8204ea239e30fb4aaa616cd';
  static const expectedWarning =
      'All dependency templates are C_SUPPORTED_INFERENCE / '
      'REVIEW_REQUIRED. This runtime catalog is not an approved contractual '
      'schedule.';
  static const expectedRuntimeScope =
      'DEPENDENCY_CATALOG_READ_ONLY_NO_SCHEDULE_INSTANTIATION';
  static const expectedActiveActivityCount = 316;
  static const expectedDependencyCount = 362;
  static const expectedProfileFieldCount = 29;

  final ConstructionDependencyAssetLoader _loader;
  final String assetPath;

  @override
  Future<ConstructionDependencyCatalog> load(
    ConstructionCorpus activityCorpus,
  ) async {
    try {
      _validateActivityAuthority(activityCorpus);
      final encoded = (await _loader(assetPath)).trim();
      final compressed = base64Decode(encoded);
      final decodedText = utf8.decode(gzip.decode(compressed));
      final root = _asMap(
        jsonDecode(decodedText),
        'invalid_dependency_catalog_json',
      );
      final catalog = _parseCatalog(root);
      _validateCatalog(catalog, activityCorpus);
      return catalog;
    } on ConstructionCorpusFailure {
      rethrow;
    } on Object {
      throw const ConstructionCorpusFailure('dependency_catalog_load_failed');
    }
  }

  ConstructionDependencyCatalog _parseCatalog(Map<String, Object?> root) {
    _requireExactKeys(root, const {
      'metadata',
      'profile_fields',
      'dependencies',
    }, 'invalid_dependency_catalog');
    final metadataMap = _asMap(root['metadata'], 'invalid_dependency_metadata');
    _requireExactKeys(metadataMap, const {
      'name',
      'corpus_version',
      'source_publication_status',
      'source_production_status',
      'source_zip_sha256',
      'warning',
      'runtime_scope',
      'counts',
    }, 'invalid_dependency_metadata');
    final counts = _asMap(metadataMap['counts'], 'invalid_dependency_metadata');
    _requireExactKeys(counts, const {
      'active_activity_ids',
      'dependencies',
      'profile_fields',
    }, 'invalid_dependency_metadata');
    final metadata = ConstructionDependencyCatalogMetadata(
      name: _requiredString(metadataMap, 'name', 'invalid_dependency_metadata'),
      corpusVersion: _requiredString(
        metadataMap,
        'corpus_version',
        'invalid_dependency_metadata',
      ),
      sourcePublicationStatus: _requiredString(
        metadataMap,
        'source_publication_status',
        'invalid_dependency_metadata',
      ),
      sourceProductionStatus: _requiredString(
        metadataMap,
        'source_production_status',
        'invalid_dependency_metadata',
      ),
      sourceZipSha256: _requiredString(
        metadataMap,
        'source_zip_sha256',
        'invalid_dependency_metadata',
      ),
      warning: _requiredString(
        metadataMap,
        'warning',
        'invalid_dependency_metadata',
      ),
      runtimeScope: _requiredString(
        metadataMap,
        'runtime_scope',
        'invalid_dependency_metadata',
      ),
      activeActivityCount: _requiredInt(
        counts,
        'active_activity_ids',
        'invalid_dependency_metadata',
      ),
      dependencyCount: _requiredInt(
        counts,
        'dependencies',
        'invalid_dependency_metadata',
      ),
      profileFieldCount: _requiredInt(
        counts,
        'profile_fields',
        'invalid_dependency_metadata',
      ),
    );

    final profileFields = _stringList(
      root['profile_fields'],
      'invalid_dependency_profile_fields',
    );
    final dependencies = _asList(root['dependencies'], 'invalid_dependencies')
        .map((value) {
          final map = _asMap(value, 'invalid_dependency');
          _requireExactKeys(map, const {
            'dependency_id',
            'predecessor_activity_id',
            'successor_activity_id',
            'relationship_type',
            'lag_value',
            'lag_unit',
            'floor_offset',
            'scope_rule',
            'condition',
            'is_mandatory',
            'confidence',
            'review_status',
          }, 'invalid_dependency');
          final lagValue = _requiredInt(
            map,
            'lag_value',
            'invalid_dependency_lag',
          );
          if (lagValue < 0) {
            throw const ConstructionCorpusFailure('invalid_dependency_lag');
          }
          final floorOffset = _requiredInt(
            map,
            'floor_offset',
            'invalid_dependency_floor_offset',
          );
          if (floorOffset != 0 && floorOffset != 1) {
            throw const ConstructionCorpusFailure(
              'invalid_dependency_floor_offset',
            );
          }
          final isMandatory = map['is_mandatory'];
          if (isMandatory is! bool) {
            throw const ConstructionCorpusFailure(
              'invalid_dependency_mandatory',
            );
          }
          return ConstructionDependency(
            dependencyId: _requiredString(
              map,
              'dependency_id',
              'invalid_dependency',
            ),
            predecessorActivityId: _requiredString(
              map,
              'predecessor_activity_id',
              'invalid_dependency',
            ),
            successorActivityId: _requiredString(
              map,
              'successor_activity_id',
              'invalid_dependency',
            ),
            relationshipType: ConstructionDependencyRelationshipType.fromJson(
              map['relationship_type'],
            ),
            lagValue: lagValue,
            lagUnit: ConstructionDependencyLagUnit.fromJson(map['lag_unit']),
            floorOffset: floorOffset,
            scopeRule: ConstructionDependencyScopeRule.fromJson(
              map['scope_rule'],
            ),
            condition: ConstructionApplicabilityRule.fromJson(
              _asMap(map['condition'], 'invalid_applicability'),
            ),
            isMandatory: isMandatory,
            confidence: ConstructionDependencyConfidence.fromJson(
              map['confidence'],
            ),
            reviewStatus: ConstructionDependencyReviewStatus.fromJson(
              map['review_status'],
            ),
          );
        })
        .toList(growable: false);

    return ConstructionDependencyCatalog(
      metadata: metadata,
      profileFields: profileFields,
      dependencies: dependencies,
    );
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
        corpus.metadata.wbsCount !=
            BundledConstructionCorpusRepository.expectedWbsCount ||
        corpus.metadata.activityCount != expectedActiveActivityCount ||
        corpus.wbsPackages.length !=
            BundledConstructionCorpusRepository.expectedWbsCount ||
        corpus.activities.length != expectedActiveActivityCount ||
        !_sameOrderedValues(
          corpus.profileFields,
          ConstructionProjectProfile.applicabilityFieldNames,
        ) ||
        corpus.activities.map((item) => item.activityId).toSet().length !=
            expectedActiveActivityCount) {
      throw const ConstructionCorpusFailure(
        'invalid_dependency_activity_authority',
      );
    }
  }

  void _validateCatalog(
    ConstructionDependencyCatalog catalog,
    ConstructionCorpus activityCorpus,
  ) {
    final metadata = catalog.metadata;
    if (metadata.name != expectedName ||
        metadata.corpusVersion != expectedCorpusVersion ||
        metadata.sourcePublicationStatus != expectedPublicationStatus ||
        metadata.sourceProductionStatus != expectedProductionStatus ||
        metadata.sourceZipSha256 != expectedSourceZipSha256 ||
        metadata.warning != expectedWarning ||
        metadata.runtimeScope != expectedRuntimeScope) {
      throw const ConstructionCorpusFailure('unexpected_dependency_metadata');
    }
    if (metadata.activeActivityCount != expectedActiveActivityCount ||
        metadata.dependencyCount != expectedDependencyCount ||
        metadata.profileFieldCount != expectedProfileFieldCount) {
      throw const ConstructionCorpusFailure('unexpected_dependency_counts');
    }
    if (catalog.dependencies.length != metadata.dependencyCount ||
        catalog.profileFields.length != metadata.profileFieldCount) {
      throw const ConstructionCorpusFailure('dependency_count_mismatch');
    }
    if (!_sameOrderedValues(
          catalog.profileFields,
          ConstructionProjectProfile.applicabilityFieldNames,
        ) ||
        !_sameOrderedValues(
          catalog.profileFields,
          activityCorpus.profileFields,
        )) {
      throw const ConstructionCorpusFailure(
        'unexpected_dependency_profile_fields',
      );
    }
    if (_hasDuplicates(catalog.dependencies.map((item) => item.dependencyId))) {
      throw const ConstructionCorpusFailure('duplicate_dependency');
    }

    final activityIds = activityCorpus.activities
        .map((activity) => activity.activityId)
        .toSet();
    final profileFields = catalog.profileFields.toSet();
    for (final dependency in catalog.dependencies) {
      if (dependency.predecessorActivityId == dependency.successorActivityId) {
        throw const ConstructionCorpusFailure('dependency_self_loop');
      }
      if (!activityIds.contains(dependency.predecessorActivityId)) {
        throw const ConstructionCorpusFailure('unknown_dependency_predecessor');
      }
      if (!activityIds.contains(dependency.successorActivityId)) {
        throw const ConstructionCorpusFailure('unknown_dependency_successor');
      }
      dependency.condition.validateProfileFields(profileFields);
    }
  }
}

bool _sameOrderedValues(Iterable<String> left, Iterable<String> right) {
  final leftValues = left.toList(growable: false);
  final rightValues = right.toList(growable: false);
  if (leftValues.length != rightValues.length) {
    return false;
  }
  for (var index = 0; index < leftValues.length; index += 1) {
    if (leftValues[index] != rightValues[index]) {
      return false;
    }
  }
  return true;
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
