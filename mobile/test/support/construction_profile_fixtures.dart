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

ConstructionProjectProfile referenceConstructionProfile01() =>
    validConstructionProjectProfile(
      overrides: {
        'project_id': 'CSE-P01',
        'project_name': 'Profil 01 — 14 katlı radye temelli konut',
        'blocks': <Object?>[
          <String, Object?>{
            'block_id': 'A',
            'floor_count': 14,
            'basement_count': 2,
          },
        ],
        'zones_per_block': 8,
        'facade_elevations': <Object?>['N', 'E', 'S', 'W'],
        'lot_count': 4,
        'test_batch_count': 4,
        'cooling_system': 'VRF',
        'has_dewatering': true,
        'foundation_thermal_insulation_required': true,
      },
    );

ConstructionProjectProfile referenceConstructionProfile02() =>
    validConstructionProjectProfile(
      overrides: {
        'project_id': 'CSE-P02',
        'project_name': 'Profil 02 — 4 katlı küçük bina',
        'blocks': <Object?>[
          <String, Object?>{
            'block_id': 'A',
            'floor_count': 4,
            'basement_count': 0,
          },
        ],
        'zones_per_block': 8,
        'facade_elevations': <Object?>['N', 'E', 'S', 'W'],
        'lot_count': 4,
        'test_batch_count': 4,
        'foundation_type': 'TEKIL',
        'wall_type': 'TUGLA',
        'roof_type': 'EGIMLI',
        'cooling_system': 'VRF',
        'has_shoring': false,
        'foundation_thermal_insulation_required': false,
        'has_fire_system': false,
        'has_sprinkler': false,
        'has_elevator': false,
        'has_parking': false,
        'has_basement': false,
      },
    );

ConstructionProjectProfile referenceConstructionProfile03() =>
    validConstructionProjectProfile(
      overrides: {
        'project_id': 'CSE-P03',
        'project_name': 'Profil 03 — iki bloklu kazıklı radye karma yapı',
        'blocks': <Object?>[
          <String, Object?>{
            'block_id': 'A',
            'floor_count': 18,
            'basement_count': 3,
          },
          <String, Object?>{
            'block_id': 'B',
            'floor_count': 12,
            'basement_count': 3,
          },
        ],
        'block_count': 2,
        'zones_per_block': 8,
        'facade_elevations': <Object?>['N', 'E', 'S', 'W'],
        'lot_count': 4,
        'test_batch_count': 4,
        'foundation_type': 'KAZIKLI_RADYE',
        'wall_type': 'KARMA',
        'facade_type': 'GIYDIRME',
        'roof_type': 'KARMA',
        'cooling_system': 'VRF',
        'has_dewatering': true,
        'ground_improvement_required': true,
        'has_piles': true,
        'foundation_thermal_insulation_required': true,
        'has_steel_auxiliary': true,
        'has_precast_auxiliary': true,
        'has_generator': true,
        'has_ups': true,
        'has_transformer': true,
        'has_bms': true,
      },
    );
