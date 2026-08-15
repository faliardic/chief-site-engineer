import 'package:chief_site_engineer/domain/construction_corpus_models.dart';

Map<String, Object?> validConstructionProjectProfileJson({
  Map<String, Object?> overrides = const {},
}) => <String, Object?>{
  'project_id': 'PRJ-001',
  'project_name': 'Kanonik Test Projesi',
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
    'start_date': '2026-08-15',
    'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
    'holidays': <Object?>['2026-08-30'],
    'workday_hours': 8,
  },
  ...overrides,
};

ConstructionProjectProfile validConstructionProjectProfile({
  Map<String, Object?> overrides = const {},
}) => ConstructionProjectProfile.fromJson(
  validConstructionProjectProfileJson(overrides: overrides),
);
