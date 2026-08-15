class ConstructionCorpusFailure implements Exception {
  const ConstructionCorpusFailure(this.code);

  final String code;

  @override
  String toString() => code;
}

class ConstructionCorpusMetadata {
  const ConstructionCorpusMetadata({
    required this.name,
    required this.corpusVersion,
    required this.sourcePublicationStatus,
    required this.sourceProductionStatus,
    required this.warning,
    required this.runtimeScope,
    required this.wbsCount,
    required this.activityCount,
  });

  final String name;
  final String corpusVersion;
  final String sourcePublicationStatus;
  final String sourceProductionStatus;
  final String warning;
  final String runtimeScope;
  final int wbsCount;
  final int activityCount;
}

class ConstructionWbsPackage {
  const ConstructionWbsPackage({
    required this.wbsCode,
    required this.packageId,
    required this.packageNameTr,
    required this.packageNameEn,
    required this.frequencyClass,
  });

  final String wbsCode;
  final String packageId;
  final String packageNameTr;
  final String packageNameEn;
  final String frequencyClass;
}

class ConstructionActivity {
  ConstructionActivity({
    required this.activityId,
    required this.wbsCode,
    required this.packageId,
    required this.activityNameTr,
    required Iterable<String> aliasesTr,
    required this.applicability,
    required this.repeatDimension,
    required this.naturalUnit,
    required this.durationStatus,
    required this.durationConfidence,
    required this.testSeedDurationDays,
    required this.sequenceConfidence,
    required this.sequenceIndex,
  }) : aliasesTr = List.unmodifiable(aliasesTr);

  final String activityId;
  final String wbsCode;
  final String packageId;
  final String activityNameTr;
  final List<String> aliasesTr;
  final ConstructionApplicabilityRule applicability;
  final String repeatDimension;
  final String naturalUnit;
  final String durationStatus;
  final String durationConfidence;
  final double? testSeedDurationDays;
  final String sequenceConfidence;
  final int sequenceIndex;

  bool matchesSearch(String query) {
    final normalized = normalizeConstructionSearch(query);
    if (normalized.isEmpty) {
      return true;
    }
    return normalizeConstructionSearch(activityNameTr).contains(normalized) ||
        aliasesTr.any(
          (alias) => normalizeConstructionSearch(alias).contains(normalized),
        );
  }
}

class ConstructionProjectProfile {
  ConstructionProjectProfile(Map<String, Object?> values)
    : values = Map.unmodifiable(values);

  final Map<String, Object?> values;
}

class ConstructionCorpus {
  ConstructionCorpus({
    required this.metadata,
    required Iterable<String> profileFields,
    required Iterable<ConstructionWbsPackage> wbsPackages,
    required Iterable<ConstructionActivity> activities,
  }) : profileFields = List.unmodifiable(profileFields),
       wbsPackages = List.unmodifiable(wbsPackages),
       activities = List.unmodifiable(activities);

  final ConstructionCorpusMetadata metadata;
  final List<String> profileFields;
  final List<ConstructionWbsPackage> wbsPackages;
  final List<ConstructionActivity> activities;

  List<ConstructionActivity> searchActivities(String query) {
    final result =
        activities.where((activity) => activity.matchesSearch(query)).toList()
          ..sort(compareConstructionActivities);
    return List.unmodifiable(result);
  }

  List<ConstructionActivity> filterActivities(
    ConstructionProjectProfile profile,
  ) {
    final result =
        activities
            .where((activity) => activity.applicability.matches(profile.values))
            .toList()
          ..sort(compareConstructionActivities);
    return List.unmodifiable(result);
  }
}

int compareConstructionActivities(
  ConstructionActivity left,
  ConstructionActivity right,
) {
  final wbs = left.wbsCode.compareTo(right.wbsCode);
  if (wbs != 0) {
    return wbs;
  }
  final sequence = left.sequenceIndex.compareTo(right.sequenceIndex);
  if (sequence != 0) {
    return sequence;
  }
  final name = left.activityNameTr.compareTo(right.activityNameTr);
  if (name != 0) {
    return name;
  }
  return left.activityId.compareTo(right.activityId);
}

sealed class ConstructionApplicabilityRule {
  const ConstructionApplicabilityRule();

  bool matches(Map<String, Object?> profile) =>
      _evaluate(profile) == _ConstructionApplicabilityMatch.matches;

  _ConstructionApplicabilityMatch _evaluate(Map<String, Object?> profile);

  void validateProfileFields(Set<String> profileFields);

  factory ConstructionApplicabilityRule.fromJson(Map<String, Object?> json) {
    final op = json['op'];
    if (op is! String) {
      throw const ConstructionCorpusFailure('invalid_applicability');
    }
    switch (op) {
      case 'always':
        return const ConstructionAlwaysRule();
      case 'eq':
      case 'neq':
        final field = json['field'];
        if (field is! String || field.isEmpty || !json.containsKey('value')) {
          throw const ConstructionCorpusFailure('invalid_applicability');
        }
        return ConstructionFieldComparisonRule(
          field: field,
          expected: json['value'],
          isEqual: op == 'eq',
        );
      case 'in':
        final field = json['field'];
        final values = json['values'];
        if (field is! String ||
            field.isEmpty ||
            values is! List ||
            values.isEmpty) {
          throw const ConstructionCorpusFailure('invalid_applicability');
        }
        return ConstructionInRule(field: field, values: values);
      case 'any':
      case 'all':
        final rules = json['rules'];
        if (rules is! List || rules.isEmpty) {
          throw const ConstructionCorpusFailure('invalid_applicability');
        }
        return ConstructionGroupRule(
          rules: rules.map(
            (rule) => ConstructionApplicabilityRule.fromJson(
              _asStringObjectMap(rule, 'invalid_applicability'),
            ),
          ),
          matchAny: op == 'any',
        );
      case 'not':
        return ConstructionNotRule(
          ConstructionApplicabilityRule.fromJson(
            _asStringObjectMap(json['rule'], 'invalid_applicability'),
          ),
        );
      default:
        throw const ConstructionCorpusFailure('unsupported_applicability');
    }
  }
}

class ConstructionAlwaysRule extends ConstructionApplicabilityRule {
  const ConstructionAlwaysRule();

  @override
  _ConstructionApplicabilityMatch _evaluate(Map<String, Object?> profile) =>
      _ConstructionApplicabilityMatch.matches;

  @override
  void validateProfileFields(Set<String> profileFields) {}
}

class ConstructionFieldComparisonRule extends ConstructionApplicabilityRule {
  const ConstructionFieldComparisonRule({
    required this.field,
    required this.expected,
    required this.isEqual,
  });

  final String field;
  final Object? expected;
  final bool isEqual;

  @override
  _ConstructionApplicabilityMatch _evaluate(Map<String, Object?> profile) {
    if (!profile.containsKey(field)) {
      return _ConstructionApplicabilityMatch.missingField;
    }
    final equal = profile[field] == expected;
    return (isEqual ? equal : !equal)
        ? _ConstructionApplicabilityMatch.matches
        : _ConstructionApplicabilityMatch.doesNotMatch;
  }

  @override
  void validateProfileFields(Set<String> profileFields) {
    _validateProfileField(field, profileFields);
  }
}

class ConstructionInRule extends ConstructionApplicabilityRule {
  ConstructionInRule({required this.field, required Iterable<Object?> values})
    : values = List.unmodifiable(values);

  final String field;
  final List<Object?> values;

  @override
  _ConstructionApplicabilityMatch _evaluate(Map<String, Object?> profile) {
    if (!profile.containsKey(field)) {
      return _ConstructionApplicabilityMatch.missingField;
    }
    return values.contains(profile[field])
        ? _ConstructionApplicabilityMatch.matches
        : _ConstructionApplicabilityMatch.doesNotMatch;
  }

  @override
  void validateProfileFields(Set<String> profileFields) {
    _validateProfileField(field, profileFields);
  }
}

class ConstructionGroupRule extends ConstructionApplicabilityRule {
  ConstructionGroupRule({
    required Iterable<ConstructionApplicabilityRule> rules,
    required this.matchAny,
  }) : rules = List.unmodifiable(rules);

  final List<ConstructionApplicabilityRule> rules;
  final bool matchAny;

  @override
  _ConstructionApplicabilityMatch _evaluate(Map<String, Object?> profile) {
    final results = rules.map((rule) => rule._evaluate(profile)).toList();
    if (results.contains(_ConstructionApplicabilityMatch.missingField)) {
      return _ConstructionApplicabilityMatch.missingField;
    }
    final matches = matchAny
        ? results.any(
            (result) => result == _ConstructionApplicabilityMatch.matches,
          )
        : results.every(
            (result) => result == _ConstructionApplicabilityMatch.matches,
          );
    return matches
        ? _ConstructionApplicabilityMatch.matches
        : _ConstructionApplicabilityMatch.doesNotMatch;
  }

  @override
  void validateProfileFields(Set<String> profileFields) {
    for (final rule in rules) {
      rule.validateProfileFields(profileFields);
    }
  }
}

class ConstructionNotRule extends ConstructionApplicabilityRule {
  const ConstructionNotRule(this.rule);

  final ConstructionApplicabilityRule rule;

  @override
  _ConstructionApplicabilityMatch _evaluate(Map<String, Object?> profile) {
    return switch (rule._evaluate(profile)) {
      _ConstructionApplicabilityMatch.matches =>
        _ConstructionApplicabilityMatch.doesNotMatch,
      _ConstructionApplicabilityMatch.doesNotMatch =>
        _ConstructionApplicabilityMatch.matches,
      _ConstructionApplicabilityMatch.missingField =>
        _ConstructionApplicabilityMatch.missingField,
    };
  }

  @override
  void validateProfileFields(Set<String> profileFields) {
    rule.validateProfileFields(profileFields);
  }
}

enum _ConstructionApplicabilityMatch { matches, doesNotMatch, missingField }

void _validateProfileField(String field, Set<String> profileFields) {
  if (!profileFields.contains(field)) {
    throw const ConstructionCorpusFailure('unknown_applicability_field');
  }
}

String normalizeConstructionSearch(String input) => input
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .trim();

Map<String, Object?> _asStringObjectMap(Object? value, String failureCode) {
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
