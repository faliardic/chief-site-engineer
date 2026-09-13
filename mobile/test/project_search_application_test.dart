import 'dart:io';

import 'package:chief_site_engineer/application/project_search_application.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _projectB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  late Directory root;
  late String databasePath;
  late SqliteProjectSearchApplication search;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cse_project_search_');
    databasePath = '${root.path}${Platform.pathSeparator}search.sqlite3';
    final database = AppDatabase(
      path: databasePath,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 9, 12, 8),
    );
    await database.open();
    await database.database.insert('projects', _project(_projectA, 'Kuzey'));
    await database.database.insert('projects', _project(_projectB, 'Güney'));
    await database.close();
    search = SqliteProjectSearchApplication(
      databasePath: databasePath,
      databaseFactory: databaseFactoryFfi,
      coordinator: MobileOperationCoordinator(),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('blank query performs no scan and returns no result', () async {
    final response = await search.search(
      const ProjectSearchQuery(projectId: _projectA, query: '   '),
    );

    expect(response.results, isEmpty);
    expect(response.failures, isEmpty);
  });

  test(
    'literal ranked search is project-bound and capped at ten per source',
    () async {
      final database = await _open(databasePath);
      for (var index = 0; index < 12; index += 1) {
        await database.insert(
          'field_observations',
          _observation(
            _id('1', index),
            _projectA,
            switch (index) {
              0 => 'needle',
              1 => 'needle başlangıç',
              _ => 'Kayıt $index needle içeriyor',
            },
            '2026-09-${(index + 1).toString().padLeft(2, '0')}T08:00:00Z',
          ),
        );
        await database.insert(
          'concrete_pours',
          _pour(
            _id('2', index),
            _projectA,
            switch (index) {
              0 => 'needle',
              1 => 'needle-B01',
              _ => 'B$index-needle',
            },
            '2026-09-${(index + 1).toString().padLeft(2, '0')}T09:00:00Z',
          ),
        );
      }
      await database.insert(
        'field_observations',
        _observation(
          _id('3', 1),
          _projectB,
          'needle başka proje',
          '2026-09-30T08:00:00Z',
        ),
      );
      await database.close();

      final response = await search.search(
        const ProjectSearchQuery(projectId: _projectA, query: ' needle '),
      );

      expect(response.failures, isEmpty);
      expect(response.results, hasLength(20));
      expect(
        response.results
            .where(
              (item) =>
                  item.sourceKind == ProjectSearchSourceKind.agendaObservation,
            )
            .length,
        10,
      );
      expect(
        response.results
            .where(
              (item) => item.sourceKind == ProjectSearchSourceKind.concretePour,
            )
            .length,
        10,
      );
      expect(
        response.results.every((item) => item.projectId == _projectA),
        isTrue,
      );
      expect(
        response.results.map((item) => item.identity).toSet(),
        hasLength(20),
      );
      expect(
        response.results.take(2).map((item) => item.matchQuality),
        everyElement(ProjectSearchMatchQuality.exact),
      );
    },
  );

  test('query treats wildcard characters literally', () async {
    final database = await _open(databasePath);
    await database.insert(
      'field_observations',
      _observation(
        _id('4', 1),
        _projectA,
        'Kontrol %_ işareti',
        '2026-09-12T08:00:00Z',
      ),
    );
    await database.insert(
      'field_observations',
      _observation(
        _id('4', 2),
        _projectA,
        'Kontrol sıradan metin',
        '2026-09-12T09:00:00Z',
      ),
    );
    await database.close();

    final response = await search.search(
      const ProjectSearchQuery(projectId: _projectA, query: '%_'),
    );

    expect(response.results.map((item) => item.sourceId), [_id('4', 1)]);
  });

  test(
    'all concrete lifecycle states remain searchable without grouping',
    () async {
      final database = await _open(databasePath);
      const statuses = [
        'draft',
        'prepared',
        'pouring',
        'poured',
        'follow_up',
        'closed',
        'cancelled',
      ];
      for (var index = 0; index < statuses.length; index += 1) {
        await database.insert(
          'concrete_pours',
          _pour(
            _id('5', index),
            _projectA,
            'life-$index',
            '2026-09-12T0${index + 1}:00:00Z',
            status: statuses[index],
          ),
        );
      }
      await database.close();

      final response = await search.search(
        const ProjectSearchQuery(projectId: _projectA, query: 'life'),
      );

      expect(response.failures, isEmpty);
      expect(response.results, hasLength(statuses.length));
      expect(
        response.results.map((item) => item.statusLabel).toSet(),
        hasLength(7),
      );
    },
  );

  test('one source failure preserves valid other-source results', () async {
    final database = await _open(databasePath);
    await database.insert(
      'field_observations',
      _observation(
        _id('6', 1),
        _projectA,
        'izole sonuç',
        '2026-09-12T08:00:00Z',
      ),
    );
    await database.execute('DROP TABLE concrete_pours');
    await database.close();

    final response = await search.search(
      const ProjectSearchQuery(projectId: _projectA, query: 'izole'),
    );

    expect(response.results.map((item) => item.sourceId), [_id('6', 1)]);
    expect(response.failures, hasLength(1));
    expect(
      response.failures.single.sourceKind,
      ProjectSearchSourceKind.concretePour,
    );
  });

  test('missing archived or malformed project context fails closed', () async {
    final database = await _open(databasePath);
    await database.update(
      'projects',
      {'archived_at': '2026-09-12T08:00:00Z'},
      where: 'id = ?',
      whereArgs: [_projectB],
    );
    await database.close();

    for (final projectId in [
      _projectB,
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      ' $_projectA',
      'not-a-project-id',
    ]) {
      await expectLater(
        Future.sync(
          () => search.search(
            ProjectSearchQuery(projectId: projectId, query: 'x'),
          ),
        ),
        throwsA(isA<ProjectSearchFailure>()),
      );
    }
  });
}

Future<Database> _open(String path) => databaseFactoryFfi.openDatabase(
  path,
  options: OpenDatabaseOptions(singleInstance: false),
);

Map<String, Object?> _project(String id, String name) => {
  'id': id,
  'name': name,
  'created_at': '2026-09-12T08:00:00Z',
  'updated_at': '2026-09-12T08:00:00Z',
  'revision': 1,
};

Map<String, Object?> _observation(
  String id,
  String projectId,
  String description,
  String observedAt,
) => {
  'id': id,
  'project_id': projectId,
  'observed_at': observedAt,
  'created_at': observedAt,
  'updated_at': observedAt,
  'category': 'general_note',
  'description': description,
  'location': 'A Blok',
  'notes': 'Güvenli not',
  'revision': 1,
};

Map<String, Object?> _pour(
  String id,
  String projectId,
  String code,
  String plannedAt, {
  String status = 'draft',
}) => {
  'id': id,
  'project_id': projectId,
  'pour_code': code,
  'element_location': 'A Blok temel',
  'planned_at': plannedAt,
  'concrete_class': 'C30/37',
  'planned_volume_m3': 12.5,
  'status': status,
  if (status == 'closed') 'closed_at': plannedAt,
  if (status == 'cancelled') 'cancelled_at': plannedAt,
  'general_note': 'Güvenli not',
  'revision': 1,
  'created_at': plannedAt,
  'updated_at': plannedAt,
};

String _id(String group, int value) =>
    '$group$group$group$group$group$group$group$group-$group$group$group$group-4$group$group$group-8$group$group$group-${value.toRadixString(16).padLeft(12, '0')}';
