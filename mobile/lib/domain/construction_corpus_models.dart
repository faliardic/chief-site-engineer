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

enum ConstructionProjectType {
  residential('KONUT'),
  office('OFIS'),
  commercial('TICARI'),
  school('OKUL'),
  dormitory('YURT'),
  generalHospital('HASTANE_GENEL'),
  publicBuilding('KAMU'),
  hotel('OTEL'),
  mixed('KARMA');

  const ConstructionProjectType(this.jsonValue);

  final String jsonValue;

  static ConstructionProjectType fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_project_profile_enum',
  );
}

enum ConstructionFoundationType {
  raft('RADYE'),
  isolated('TEKIL'),
  continuous('SUREKLI'),
  piledRaft('KAZIKLI_RADYE');

  const ConstructionFoundationType(this.jsonValue);

  final String jsonValue;

  static ConstructionFoundationType fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_project_profile_enum',
  );
}

enum ConstructionStructuralSystem {
  shearWallFrame('PERDE_CERCEVE'),
  frame('CERCEVE'),
  shearWallDominant('PERDE_AGIRLIKLI'),
  tunnelForm('TUNEL_KALIP'),
  mixed('KARMA');

  const ConstructionStructuralSystem(this.jsonValue);

  final String jsonValue;

  static ConstructionStructuralSystem fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_project_profile_enum',
  );
}

enum ConstructionFormworkSystem {
  conventional('KONVANSIYONEL'),
  tunnel('TUNEL'),
  climbing('TIRMANIR'),
  mixed('KARMA');

  const ConstructionFormworkSystem(this.jsonValue);

  final String jsonValue;

  static ConstructionFormworkSystem fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_project_profile_enum',
  );
}

enum ConstructionWallType {
  aeratedConcrete('GAZBETON'),
  brick('TUGLA'),
  drywall('ALCIPAN'),
  mixed('KARMA');

  const ConstructionWallType(this.jsonValue);

  final String jsonValue;

  static ConstructionWallType fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_project_profile_enum',
  );
}

enum ConstructionFacadeType {
  externalInsulation('MANTOLAMA'),
  curtainWall('GIYDIRME'),
  stone('TAS'),
  ceramic('SERAMIK'),
  mixed('KARMA'),
  other('DIGER'),
  none('NONE');

  const ConstructionFacadeType(this.jsonValue);

  final String jsonValue;

  static ConstructionFacadeType fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_project_profile_enum',
  );
}

enum ConstructionRoofType {
  terrace('TERAS'),
  pitched('EGIMLI'),
  mixed('KARMA');

  const ConstructionRoofType(this.jsonValue);

  final String jsonValue;

  static ConstructionRoofType fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_project_profile_enum',
  );
}

enum ConstructionHeatingSystem {
  central('MERKEZI'),
  independent('BAGIMSIZ'),
  heatPump('ISI_POMPASI'),
  none('YOK'),
  other('DIGER');

  const ConstructionHeatingSystem(this.jsonValue);

  final String jsonValue;

  static ConstructionHeatingSystem fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_project_profile_enum',
  );
}

enum ConstructionCoolingSystem {
  vrf('VRF'),
  chiller('CHILLER'),
  split('SPLIT'),
  none('YOK'),
  other('DIGER');

  const ConstructionCoolingSystem(this.jsonValue);

  final String jsonValue;

  static ConstructionCoolingSystem fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_project_profile_enum',
  );
}

class ConstructionProjectBlock {
  const ConstructionProjectBlock({
    required this.blockId,
    required this.floorCount,
    required this.basementCount,
  });

  final String blockId;
  final int floorCount;
  final int basementCount;

  factory ConstructionProjectBlock.fromJson(Map<String, Object?> json) {
    _requireExactKeys(
      json,
      const {'block_id', 'floor_count', 'basement_count'},
      'unknown_project_block_property',
      'missing_project_block_property',
    );
    final blockId = _requiredProfileString(json, 'block_id');
    if (!_blockIdPattern.hasMatch(blockId)) {
      throw const ConstructionCorpusFailure('invalid_block_id');
    }
    final floorCount = _requiredProfileInt(json, 'floor_count');
    if (floorCount < 1 || floorCount > 100) {
      throw const ConstructionCorpusFailure('invalid_floor_count');
    }
    final basementCount = _requiredProfileInt(json, 'basement_count');
    if (basementCount < 0 || basementCount > 20) {
      throw const ConstructionCorpusFailure('invalid_basement_count');
    }
    return ConstructionProjectBlock(
      blockId: blockId,
      floorCount: floorCount,
      basementCount: basementCount,
    );
  }
}

class ConstructionProjectCalendar {
  ConstructionProjectCalendar({
    required this.startDate,
    required Iterable<int> workingWeekdays,
    required Iterable<DateTime> holidays,
    required this.workdayHours,
  }) : workingWeekdays = List.unmodifiable(workingWeekdays),
       holidays = List.unmodifiable(holidays);

  final DateTime startDate;
  final List<int> workingWeekdays;
  final List<DateTime> holidays;
  final double workdayHours;

  factory ConstructionProjectCalendar.fromJson(Map<String, Object?> json) {
    _requireExactKeys(
      json,
      const {'start_date', 'working_weekdays', 'holidays', 'workday_hours'},
      'unknown_project_calendar_property',
      'missing_project_calendar_property',
    );
    final startDate = _parseCanonicalDate(json['start_date']);
    final weekdayValues = _requiredProfileList(json, 'working_weekdays');
    if (weekdayValues.isEmpty || weekdayValues.length > 7) {
      throw const ConstructionCorpusFailure('invalid_working_weekdays');
    }
    final weekdays = <int>[];
    for (final value in weekdayValues) {
      if (value is! int || value < 0 || value > 6) {
        throw const ConstructionCorpusFailure('invalid_working_weekday');
      }
      weekdays.add(value);
    }
    if (_hasDuplicateValues(weekdays)) {
      throw const ConstructionCorpusFailure('duplicate_working_weekday');
    }

    final holidayValues = _requiredProfileList(json, 'holidays');
    final holidayTokens = <String>[];
    final holidays = <DateTime>[];
    for (final value in holidayValues) {
      if (value is! String) {
        throw const ConstructionCorpusFailure('invalid_project_date');
      }
      holidayTokens.add(value);
      holidays.add(_parseCanonicalDate(value));
    }
    if (_hasDuplicateValues(holidayTokens)) {
      throw const ConstructionCorpusFailure('duplicate_project_holiday');
    }

    final hoursValue = json['workday_hours'];
    if (hoursValue is! num) {
      throw const ConstructionCorpusFailure('invalid_workday_hours');
    }
    final workdayHours = hoursValue.toDouble();
    if (!workdayHours.isFinite || workdayHours <= 0 || workdayHours > 24) {
      throw const ConstructionCorpusFailure('invalid_workday_hours');
    }

    return ConstructionProjectCalendar(
      startDate: startDate,
      workingWeekdays: weekdays,
      holidays: holidays,
      workdayHours: workdayHours,
    );
  }
}

class ConstructionProjectProfile {
  ConstructionProjectProfile._({
    required this.projectId,
    required this.projectName,
    required this.projectType,
    required this.blockCount,
    required Iterable<ConstructionProjectBlock> blocks,
    required this.zonesPerBlock,
    required Iterable<String> facadeElevations,
    required this.lotCount,
    required this.testBatchCount,
    required this.foundationType,
    required this.structuralSystem,
    required this.formworkSystem,
    required this.wallType,
    required this.facadeType,
    required this.roofType,
    required this.heatingSystem,
    required this.coolingSystem,
    required this.excavationRequired,
    required this.hasShoring,
    required this.hasDewatering,
    required this.groundImprovementRequired,
    required this.hasPiles,
    required this.foundationWaterproofingRequired,
    required this.foundationThermalInsulationRequired,
    required this.hasSteelAuxiliary,
    required this.hasPrecastAuxiliary,
    required this.hasFireSystem,
    required this.hasSprinkler,
    required this.hasElevator,
    required this.hasGenerator,
    required this.hasUps,
    required this.hasTransformer,
    required this.hasBms,
    required this.hasParking,
    required this.hasInternalRoads,
    required this.hasLandscape,
    required this.hasBasement,
    required this.calendar,
  }) : blocks = List.unmodifiable(blocks),
       facadeElevations = List.unmodifiable(facadeElevations);

  static const applicabilityFieldNames = <String>[
    'project_type',
    'foundation_type',
    'structural_system',
    'formwork_system',
    'wall_type',
    'facade_type',
    'roof_type',
    'heating_system',
    'cooling_system',
    'excavation_required',
    'has_shoring',
    'has_dewatering',
    'ground_improvement_required',
    'has_piles',
    'foundation_waterproofing_required',
    'foundation_thermal_insulation_required',
    'has_steel_auxiliary',
    'has_precast_auxiliary',
    'has_fire_system',
    'has_sprinkler',
    'has_elevator',
    'has_generator',
    'has_ups',
    'has_transformer',
    'has_bms',
    'has_parking',
    'has_internal_roads',
    'has_landscape',
    'has_basement',
  ];

  final String projectId;
  final String projectName;
  final ConstructionProjectType projectType;
  final int blockCount;
  final List<ConstructionProjectBlock> blocks;
  final int zonesPerBlock;
  final List<String> facadeElevations;
  final int lotCount;
  final int testBatchCount;
  final ConstructionFoundationType foundationType;
  final ConstructionStructuralSystem structuralSystem;
  final ConstructionFormworkSystem formworkSystem;
  final ConstructionWallType wallType;
  final ConstructionFacadeType facadeType;
  final ConstructionRoofType roofType;
  final ConstructionHeatingSystem heatingSystem;
  final ConstructionCoolingSystem coolingSystem;
  final bool excavationRequired;
  final bool hasShoring;
  final bool hasDewatering;
  final bool groundImprovementRequired;
  final bool hasPiles;
  final bool foundationWaterproofingRequired;
  final bool foundationThermalInsulationRequired;
  final bool hasSteelAuxiliary;
  final bool hasPrecastAuxiliary;
  final bool hasFireSystem;
  final bool hasSprinkler;
  final bool hasElevator;
  final bool hasGenerator;
  final bool hasUps;
  final bool hasTransformer;
  final bool hasBms;
  final bool hasParking;
  final bool hasInternalRoads;
  final bool hasLandscape;
  final bool hasBasement;
  final ConstructionProjectCalendar calendar;

  factory ConstructionProjectProfile.fromJson(Map<String, Object?> json) {
    _requireExactKeys(
      json,
      _projectProfileKeys,
      'unknown_project_profile_property',
      'missing_project_profile_property',
    );
    final projectId = _requiredProfileString(json, 'project_id');
    if (!_projectIdPattern.hasMatch(projectId)) {
      throw const ConstructionCorpusFailure('invalid_project_id');
    }
    final projectName = _requiredProfileString(json, 'project_name');
    if (projectName.trim().isEmpty || projectName.length > 200) {
      throw const ConstructionCorpusFailure('invalid_project_name');
    }

    final blockCount = _requiredProfileInt(json, 'block_count');
    if (blockCount < 1 || blockCount > 20) {
      throw const ConstructionCorpusFailure('invalid_block_count');
    }
    final blockValues = _requiredProfileList(json, 'blocks');
    final blocks = blockValues
        .map(
          (value) => ConstructionProjectBlock.fromJson(
            _asStringObjectMap(value, 'invalid_project_block'),
          ),
        )
        .toList(growable: false);
    if (blocks.length != blockCount) {
      throw const ConstructionCorpusFailure('block_count_mismatch');
    }
    if (_hasDuplicateValues(blocks.map((block) => block.blockId))) {
      throw const ConstructionCorpusFailure('duplicate_block_id');
    }

    final zonesPerBlock = _requiredProfileInt(json, 'zones_per_block');
    if (zonesPerBlock < 1 || zonesPerBlock > 100) {
      throw const ConstructionCorpusFailure('invalid_zones_per_block');
    }
    final facadeValues = _requiredProfileList(json, 'facade_elevations');
    if (facadeValues.isEmpty || facadeValues.length > 20) {
      throw const ConstructionCorpusFailure('invalid_facade_elevation');
    }
    final facadeElevations = <String>[];
    for (final value in facadeValues) {
      if (value is! String || !_facadeElevationPattern.hasMatch(value)) {
        throw const ConstructionCorpusFailure('invalid_facade_elevation');
      }
      facadeElevations.add(value);
    }
    if (_hasDuplicateValues(facadeElevations)) {
      throw const ConstructionCorpusFailure('duplicate_facade_elevation');
    }

    final lotCount = _requiredProfileInt(json, 'lot_count');
    if (lotCount < 1 || lotCount > 1000) {
      throw const ConstructionCorpusFailure('invalid_lot_count');
    }
    final testBatchCount = _requiredProfileInt(json, 'test_batch_count');
    if (testBatchCount < 1 || testBatchCount > 1000) {
      throw const ConstructionCorpusFailure('invalid_test_batch_count');
    }

    final hasBasement = _requiredProfileBool(json, 'has_basement');
    final hasPhysicalBasement = blocks.any((block) => block.basementCount > 0);
    if (hasBasement != hasPhysicalBasement) {
      throw const ConstructionCorpusFailure('inconsistent_basement_profile');
    }

    return ConstructionProjectProfile._(
      projectId: projectId,
      projectName: projectName,
      projectType: ConstructionProjectType.fromJson(json['project_type']),
      blockCount: blockCount,
      blocks: blocks,
      zonesPerBlock: zonesPerBlock,
      facadeElevations: facadeElevations,
      lotCount: lotCount,
      testBatchCount: testBatchCount,
      foundationType: ConstructionFoundationType.fromJson(
        json['foundation_type'],
      ),
      structuralSystem: ConstructionStructuralSystem.fromJson(
        json['structural_system'],
      ),
      formworkSystem: ConstructionFormworkSystem.fromJson(
        json['formwork_system'],
      ),
      wallType: ConstructionWallType.fromJson(json['wall_type']),
      facadeType: ConstructionFacadeType.fromJson(json['facade_type']),
      roofType: ConstructionRoofType.fromJson(json['roof_type']),
      heatingSystem: ConstructionHeatingSystem.fromJson(json['heating_system']),
      coolingSystem: ConstructionCoolingSystem.fromJson(json['cooling_system']),
      excavationRequired: _requiredProfileBool(json, 'excavation_required'),
      hasShoring: _requiredProfileBool(json, 'has_shoring'),
      hasDewatering: _requiredProfileBool(json, 'has_dewatering'),
      groundImprovementRequired: _requiredProfileBool(
        json,
        'ground_improvement_required',
      ),
      hasPiles: _requiredProfileBool(json, 'has_piles'),
      foundationWaterproofingRequired: _requiredProfileBool(
        json,
        'foundation_waterproofing_required',
      ),
      foundationThermalInsulationRequired: _requiredProfileBool(
        json,
        'foundation_thermal_insulation_required',
      ),
      hasSteelAuxiliary: _requiredProfileBool(json, 'has_steel_auxiliary'),
      hasPrecastAuxiliary: _requiredProfileBool(json, 'has_precast_auxiliary'),
      hasFireSystem: _requiredProfileBool(json, 'has_fire_system'),
      hasSprinkler: _requiredProfileBool(json, 'has_sprinkler'),
      hasElevator: _requiredProfileBool(json, 'has_elevator'),
      hasGenerator: _requiredProfileBool(json, 'has_generator'),
      hasUps: _requiredProfileBool(json, 'has_ups'),
      hasTransformer: _requiredProfileBool(json, 'has_transformer'),
      hasBms: _requiredProfileBool(json, 'has_bms'),
      hasParking: _requiredProfileBool(json, 'has_parking'),
      hasInternalRoads: _requiredProfileBool(json, 'has_internal_roads'),
      hasLandscape: _requiredProfileBool(json, 'has_landscape'),
      hasBasement: hasBasement,
      calendar: ConstructionProjectCalendar.fromJson(
        _asStringObjectMap(json['calendar'], 'invalid_project_calendar'),
      ),
    );
  }

  Map<String, Object?> toApplicabilityMap() => Map.unmodifiable({
    'project_type': projectType.jsonValue,
    'foundation_type': foundationType.jsonValue,
    'structural_system': structuralSystem.jsonValue,
    'formwork_system': formworkSystem.jsonValue,
    'wall_type': wallType.jsonValue,
    'facade_type': facadeType.jsonValue,
    'roof_type': roofType.jsonValue,
    'heating_system': heatingSystem.jsonValue,
    'cooling_system': coolingSystem.jsonValue,
    'excavation_required': excavationRequired,
    'has_shoring': hasShoring,
    'has_dewatering': hasDewatering,
    'ground_improvement_required': groundImprovementRequired,
    'has_piles': hasPiles,
    'foundation_waterproofing_required': foundationWaterproofingRequired,
    'foundation_thermal_insulation_required':
        foundationThermalInsulationRequired,
    'has_steel_auxiliary': hasSteelAuxiliary,
    'has_precast_auxiliary': hasPrecastAuxiliary,
    'has_fire_system': hasFireSystem,
    'has_sprinkler': hasSprinkler,
    'has_elevator': hasElevator,
    'has_generator': hasGenerator,
    'has_ups': hasUps,
    'has_transformer': hasTransformer,
    'has_bms': hasBms,
    'has_parking': hasParking,
    'has_internal_roads': hasInternalRoads,
    'has_landscape': hasLandscape,
    'has_basement': hasBasement,
  });
}

enum ConstructionDependencyRelationshipType {
  finishToStart('FS'),
  startToStart('SS');

  const ConstructionDependencyRelationshipType(this.jsonValue);

  final String jsonValue;

  static ConstructionDependencyRelationshipType fromJson(Object? value) =>
      _enumFromJson(
        value,
        values,
        (item) => item.jsonValue,
        'invalid_dependency_relationship_type',
      );
}

enum ConstructionDependencyLagUnit {
  workingDay('WORKING_DAY');

  const ConstructionDependencyLagUnit(this.jsonValue);

  final String jsonValue;

  static ConstructionDependencyLagUnit fromJson(Object? value) => _enumFromJson(
    value,
    values,
    (item) => item.jsonValue,
    'invalid_dependency_lag_unit',
  );
}

enum ConstructionDependencyConfidence {
  supportedInference('C_SUPPORTED_INFERENCE');

  const ConstructionDependencyConfidence(this.jsonValue);

  final String jsonValue;

  static ConstructionDependencyConfidence fromJson(Object? value) =>
      _enumFromJson(
        value,
        values,
        (item) => item.jsonValue,
        'invalid_dependency_confidence',
      );
}

enum ConstructionDependencyReviewStatus {
  reviewRequired('REVIEW_REQUIRED');

  const ConstructionDependencyReviewStatus(this.jsonValue);

  final String jsonValue;

  static ConstructionDependencyReviewStatus fromJson(Object? value) =>
      _enumFromJson(
        value,
        values,
        (item) => item.jsonValue,
        'invalid_dependency_review_status',
      );
}

enum ConstructionDependencyScopeRule {
  allToBlock('ALL_TO_BLOCK'),
  allToProject('ALL_TO_PROJECT'),
  anyZoneToProject('ANY_ZONE_TO_PROJECT'),
  automatic('AUTO'),
  blockToFirstBasement('BLOCK_TO_FIRST_BASEMENT'),
  blockToFirstFloor('BLOCK_TO_FIRST_FLOOR'),
  blockToFirstFloorIfNoBasement('BLOCK_TO_FIRST_FLOOR_IF_NO_BASEMENT'),
  floorThresholdToFacade('FLOOR_THRESHOLD_TO_FACADE'),
  lastBasementToFirstFloor('LAST_BASEMENT_TO_FIRST_FLOOR'),
  nextBasement('NEXT_BASEMENT'),
  nextFloor('NEXT_FLOOR'),
  project('PROJECT'),
  projectToAll('PROJECT_TO_ALL'),
  sameBasement('SAME_BASEMENT'),
  sameBlock('SAME_BLOCK'),
  sameFacade('SAME_FACADE'),
  sameFloor('SAME_FLOOR'),
  sameRoof('SAME_ROOF'),
  sameSystem('SAME_SYSTEM'),
  topFloorToRoof('TOP_FLOOR_TO_ROOF');

  const ConstructionDependencyScopeRule(this.jsonValue);

  final String jsonValue;

  static ConstructionDependencyScopeRule fromJson(Object? value) =>
      _enumFromJson(
        value,
        values,
        (item) => item.jsonValue,
        'invalid_dependency_scope_rule',
      );
}

class ConstructionDependency {
  const ConstructionDependency({
    required this.dependencyId,
    required this.predecessorActivityId,
    required this.successorActivityId,
    required this.relationshipType,
    required this.lagValue,
    required this.lagUnit,
    required this.floorOffset,
    required this.scopeRule,
    required this.condition,
    required this.isMandatory,
    required this.confidence,
    required this.reviewStatus,
  });

  final String dependencyId;
  final String predecessorActivityId;
  final String successorActivityId;
  final ConstructionDependencyRelationshipType relationshipType;
  final int lagValue;
  final ConstructionDependencyLagUnit lagUnit;
  final int floorOffset;
  final ConstructionDependencyScopeRule scopeRule;
  final ConstructionApplicabilityRule condition;
  final bool isMandatory;
  final ConstructionDependencyConfidence confidence;
  final ConstructionDependencyReviewStatus reviewStatus;
}

class ConstructionDependencyCatalogMetadata {
  const ConstructionDependencyCatalogMetadata({
    required this.name,
    required this.corpusVersion,
    required this.sourcePublicationStatus,
    required this.sourceProductionStatus,
    required this.sourceZipSha256,
    required this.warning,
    required this.runtimeScope,
    required this.activeActivityCount,
    required this.dependencyCount,
    required this.profileFieldCount,
  });

  final String name;
  final String corpusVersion;
  final String sourcePublicationStatus;
  final String sourceProductionStatus;
  final String sourceZipSha256;
  final String warning;
  final String runtimeScope;
  final int activeActivityCount;
  final int dependencyCount;
  final int profileFieldCount;
}

class ConstructionDependencyCatalog {
  ConstructionDependencyCatalog({
    required this.metadata,
    required Iterable<String> profileFields,
    required Iterable<ConstructionDependency> dependencies,
  }) : profileFields = List.unmodifiable(profileFields),
       dependencies = List.unmodifiable(dependencies);

  final ConstructionDependencyCatalogMetadata metadata;
  final List<String> profileFields;
  final List<ConstructionDependency> dependencies;

  List<ConstructionDependency> dependenciesForSelectedActivities(
    Set<String> selectedActivityIds,
    ConstructionProjectProfile profile,
  ) {
    final applicabilityProfile = profile.toApplicabilityMap();
    final result =
        dependencies
            .where(
              (dependency) =>
                  selectedActivityIds.contains(
                    dependency.predecessorActivityId,
                  ) &&
                  selectedActivityIds.contains(
                    dependency.successorActivityId,
                  ) &&
                  dependency.condition.matches(applicabilityProfile),
            )
            .toList()
          ..sort(
            (left, right) => left.dependencyId.compareTo(right.dependencyId),
          );
    return List.unmodifiable(result);
  }
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
            .where(
              (activity) =>
                  activity.applicability.matches(profile.toApplicabilityMap()),
            )
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
        _requireExactKeys(
          json,
          const {'op'},
          'invalid_applicability',
          'invalid_applicability',
        );
        return const ConstructionAlwaysRule();
      case 'eq':
      case 'neq':
        _requireExactKeys(
          json,
          const {'op', 'field', 'value'},
          'invalid_applicability',
          'invalid_applicability',
        );
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
        _requireExactKeys(
          json,
          const {'op', 'field', 'values'},
          'invalid_applicability',
          'invalid_applicability',
        );
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
        _requireExactKeys(
          json,
          const {'op', 'rules'},
          'invalid_applicability',
          'invalid_applicability',
        );
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
        _requireExactKeys(
          json,
          const {'op', 'rule'},
          'invalid_applicability',
          'invalid_applicability',
        );
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

const _projectProfileKeys = <String>{
  'project_id',
  'project_name',
  'project_type',
  'blocks',
  'block_count',
  'zones_per_block',
  'facade_elevations',
  'lot_count',
  'test_batch_count',
  'foundation_type',
  'structural_system',
  'formwork_system',
  'wall_type',
  'facade_type',
  'roof_type',
  'heating_system',
  'cooling_system',
  'excavation_required',
  'has_shoring',
  'has_dewatering',
  'ground_improvement_required',
  'has_piles',
  'foundation_waterproofing_required',
  'foundation_thermal_insulation_required',
  'has_steel_auxiliary',
  'has_precast_auxiliary',
  'has_fire_system',
  'has_sprinkler',
  'has_elevator',
  'has_generator',
  'has_ups',
  'has_transformer',
  'has_bms',
  'has_parking',
  'has_internal_roads',
  'has_landscape',
  'has_basement',
  'calendar',
};

final _projectIdPattern = RegExp(r'^[A-Z0-9][A-Z0-9_-]{2,63}$');
final _blockIdPattern = RegExp(r'^[A-Z0-9][A-Z0-9_-]{0,15}$');
final _facadeElevationPattern = RegExp(r'^[A-Z0-9_-]+$');
final _canonicalDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

T _enumFromJson<T>(
  Object? value,
  Iterable<T> values,
  String Function(T item) jsonValue,
  String failureCode,
) {
  if (value is String) {
    for (final item in values) {
      if (jsonValue(item) == value) {
        return item;
      }
    }
  }
  throw ConstructionCorpusFailure(failureCode);
}

void _requireExactKeys(
  Map<String, Object?> map,
  Set<String> expectedKeys,
  String unknownFailureCode,
  String missingFailureCode,
) {
  if (map.keys.any((key) => !expectedKeys.contains(key))) {
    throw ConstructionCorpusFailure(unknownFailureCode);
  }
  if (expectedKeys.any((key) => !map.containsKey(key))) {
    throw ConstructionCorpusFailure(missingFailureCode);
  }
}

String _requiredProfileString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String) {
    throw const ConstructionCorpusFailure('invalid_project_profile_value');
  }
  return value;
}

int _requiredProfileInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) {
    throw const ConstructionCorpusFailure('invalid_project_profile_value');
  }
  return value;
}

bool _requiredProfileBool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! bool) {
    throw const ConstructionCorpusFailure('invalid_project_profile_value');
  }
  return value;
}

List<Object?> _requiredProfileList(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! List) {
    throw const ConstructionCorpusFailure('invalid_project_profile_value');
  }
  return List<Object?>.from(value);
}

DateTime _parseCanonicalDate(Object? value) {
  if (value is! String || !_canonicalDatePattern.hasMatch(value)) {
    throw const ConstructionCorpusFailure('invalid_project_date');
  }
  final parts = value.split('-').map(int.parse).toList(growable: false);
  final parsed = DateTime.utc(parts[0], parts[1], parts[2]);
  if (parsed.year != parts[0] ||
      parsed.month != parts[1] ||
      parsed.day != parts[2]) {
    throw const ConstructionCorpusFailure('invalid_project_date');
  }
  return parsed;
}

bool _hasDuplicateValues<T>(Iterable<T> values) {
  final seen = <T>{};
  for (final value in values) {
    if (!seen.add(value)) {
      return true;
    }
  }
  return false;
}
