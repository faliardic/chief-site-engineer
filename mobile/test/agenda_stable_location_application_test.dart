import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = '11111111-1111-4111-8111-111111111111';
const _projectB = '22222222-2222-4222-8222-222222222222';
const _locationA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _locationB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _locationOther = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3';

String _logId(int value) =>
    'bbbbbbbb-bbbb-4bbb-8bbb-${value.toString().padLeft(12, '0')}';

String _eventId(int value) =>
    'eeeeeeee-eeee-4eee-8eee-${value.toString().padLeft(12, '0')}';

void main() {
  late Directory temporaryRoot;
  late String databasePath;
  late DateTime now;
  late SqliteAgendaApplication application;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_agenda_stable_location_',
    );
    databasePath = path.join(temporaryRoot.path, 'cse.sqlite3');
    now = DateTime.utc(2026, 8, 9, 12);
    final database = AppDatabase(
      path: databasePath,
      factory: databaseFactoryFfi,
      clock: () => now,
    );
    await database.open();
    await database.close();
    application = SqliteAgendaApplication(
      databasePath: databasePath,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
    );
    await application.createProject(
      const CreateProjectCommand(id: _projectA, name: 'Kuzey'),
    );
    await application.createProject(
      const CreateProjectCommand(id: _projectB, name: 'Güney'),
    );
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  Future<T> withDatabase<T>(
    Future<T> Function(Database database) action,
  ) async {
    final database = AppDatabase(
      path: databasePath,
      factory: databaseFactoryFfi,
      clock: () => now,
    );
    await database.open();
    try {
      return await action(database.database);
    } finally {
      await database.close();
    }
  }

  Future<MobileProjectLocation> createLocation({
    required String id,
    required int event,
    required String name,
    String projectId = _projectA,
  }) => application.createProjectLocation(
    CreateProjectLocationCommand(
      id: id,
      eventId: _eventId(event),
      projectId: projectId,
      displayName: name,
    ),
  );

  CreateAgendaLogCommand createCommand({
    required int log,
    required int event,
    String projectId = _projectA,
    String? locationId,
    String? location = 'Serbest mahal',
    String description = 'Saha kontrolü',
  }) => CreateAgendaLogCommand(
    id: _logId(log),
    eventId: _eventId(event),
    projectId: projectId,
    observedAt: '2026-08-09T07:00:00Z',
    category: AgendaCategory.inspection,
    description: description,
    location: location,
    locationId: locationId,
  );

  UpdateAgendaLogCommand updateCommand({
    required AgendaLog current,
    required int event,
    String? projectId,
    String? locationId,
    String? location,
    String description = 'Güncellenmiş kontrol',
  }) => UpdateAgendaLogCommand(
    id: current.id,
    eventId: _eventId(event),
    expectedRevision: current.revision,
    projectId: projectId ?? current.projectId,
    observedAt: current.observedAt,
    category: current.category,
    description: description,
    location: location,
    locationId: locationId,
    notes: current.notes,
  );

  test(
    'legacy create stays free-text and stable create trusts catalog name',
    () async {
      await createLocation(id: _locationA, event: 1, name: 'A Blok');

      final legacy = await application.createAgendaLog(
        createCommand(log: 1, event: 11, location: 'Eski serbest mahal'),
      );
      final stable = await application.createAgendaLog(
        createCommand(
          log: 2,
          event: 12,
          locationId: _locationA,
          location: 'Caller tarafından güvenilmemeli',
        ),
      );

      expect(legacy.locationId, isNull);
      expect(legacy.location, 'Eski serbest mahal');
      expect(legacy.displayLocation, 'Eski serbest mahal');
      expect(stable.locationId, _locationA);
      expect(stable.location, 'A Blok');
      expect(stable.stableLocationName, 'A Blok');
      expect(stable.displayLocation, 'A Blok');
      final row = await withDatabase(
        (database) => database.query(
          'field_observations',
          where: 'id = ?',
          whereArgs: [stable.id],
          limit: 1,
        ),
      );
      expect(row.single['location_id'], _locationA);
      expect(row.single['location'], 'A Blok');
    },
  );

  test(
    'malformed missing archived and cross-project create fail atomically',
    () async {
      final active = await createLocation(
        id: _locationA,
        event: 1,
        name: 'Aktif',
      );
      await createLocation(
        id: _locationOther,
        event: 2,
        name: 'Başka proje',
        projectId: _projectB,
      );
      await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: active.id,
          eventId: _eventId(3),
          expectedRevision: active.revision,
          archive: true,
        ),
      );

      final invalidIds = <String>[
        'not-a-uuid',
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaafff',
        _locationA,
        _locationOther,
      ];
      for (var index = 0; index < invalidIds.length; index += 1) {
        await expectLater(
          application.createAgendaLog(
            createCommand(
              log: index + 1,
              event: 20 + index,
              locationId: invalidIds[index],
            ),
          ),
          throwsA(isA<AgendaValidationFailure>()),
        );
      }
      expect(
        await withDatabase(
          (database) async => Sqflite.firstIntValue(
            await database.rawQuery('SELECT count(*) FROM field_observations'),
          ),
        ),
        0,
      );
    },
  );

  test('stable create idempotency includes the location link', () async {
    await createLocation(id: _locationA, event: 1, name: 'A Blok');
    await createLocation(id: _locationB, event: 2, name: 'B Blok');
    final command = createCommand(log: 1, event: 11, locationId: _locationA);

    final first = await application.createAgendaLog(command);
    final retried = await application.createAgendaLog(command);
    expect(retried.id, first.id);
    await expectLater(
      application.createAgendaLog(
        createCommand(log: 1, event: 11, locationId: _locationB),
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );
    expect(
      await withDatabase(
        (database) async => Sqflite.firstIntValue(
          await database.rawQuery('SELECT count(*) FROM observation_events'),
        ),
      ),
      1,
    );
  });

  test(
    'rename changes resolved name without rewriting snapshot and search finds both',
    () async {
      final location = await createLocation(
        id: _locationA,
        event: 1,
        name: 'Eski Mahal',
      );
      final created = await application.createAgendaLog(
        createCommand(log: 1, event: 11, locationId: location.id),
      );
      await application.renameProjectLocation(
        RenameProjectLocationCommand(
          locationId: location.id,
          eventId: _eventId(12),
          expectedRevision: location.revision,
          displayName: 'Yeni Mahal',
        ),
      );

      final read = (await application.getAgendaLogDetail(created.id)).log;
      expect(read.location, 'Eski Mahal');
      expect(read.stableLocationName, 'Yeni Mahal');
      expect(read.displayLocation, 'Yeni Mahal');
      for (final search in ['Eski Mahal', 'Yeni Mahal']) {
        final found = await application.listAgenda(
          AgendaQuery(istanbulDay: '2026-08-09', literalSearch: search),
        );
        expect(found.map((item) => item.id), contains(created.id));
      }
    },
  );

  test(
    'archived linked location remains readable with current archive metadata',
    () async {
      final location = await createLocation(
        id: _locationA,
        event: 1,
        name: 'Arşivlenecek',
      );
      final created = await application.createAgendaLog(
        createCommand(log: 1, event: 11, locationId: location.id),
      );
      now = DateTime.utc(2026, 8, 9, 13);
      await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: location.id,
          eventId: _eventId(12),
          expectedRevision: location.revision,
          archive: true,
        ),
      );

      final read = (await application.getAgendaLogDetail(created.id)).log;
      expect(read.locationId, location.id);
      expect(read.stableLocationName, 'Arşivlenecek');
      expect(read.stableLocationArchivedAt, '2026-08-09T13:00:00Z');
    },
  );

  test(
    'update changes stable link and records location id before and after',
    () async {
      await createLocation(id: _locationA, event: 1, name: 'A Blok');
      await createLocation(id: _locationB, event: 2, name: 'B Blok');
      final created = await application.createAgendaLog(
        createCommand(log: 1, event: 11, locationId: _locationA),
      );

      final updated = await application.updateAgendaLog(
        updateCommand(
          current: created,
          event: 12,
          locationId: _locationB,
          location: 'Caller snapshot',
        ),
      );
      expect(updated.locationId, _locationB);
      expect(updated.location, 'B Blok');
      expect(updated.revision, 2);
      final events = await application.listObservationEvents(updated.id);
      final payload =
          jsonDecode(events.last.payloadJson) as Map<String, Object?>;
      final before = payload['before']! as Map<String, Object?>;
      final after = payload['after']! as Map<String, Object?>;
      expect(before['location_id'], _locationA);
      expect(after['location_id'], _locationB);
    },
  );

  test(
    'new archived or cross-project update target rejects without partial mutation',
    () async {
      final active = await createLocation(
        id: _locationA,
        event: 1,
        name: 'Arşivli hedef',
      );
      await createLocation(
        id: _locationOther,
        event: 2,
        name: 'Güney hedef',
        projectId: _projectB,
      );
      await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: active.id,
          eventId: _eventId(3),
          expectedRevision: active.revision,
          archive: true,
        ),
      );
      final legacy = await application.createAgendaLog(
        createCommand(log: 1, event: 11, location: 'Korunacak'),
      );

      for (final target in [_locationA, _locationOther]) {
        await expectLater(
          application.updateAgendaLog(
            updateCommand(
              current: legacy,
              event: target == _locationA ? 12 : 13,
              locationId: target,
            ),
          ),
          throwsA(isA<AgendaValidationFailure>()),
        );
      }
      final unchanged = (await application.getAgendaLogDetail(legacy.id)).log;
      expect(unchanged.revision, 1);
      expect(unchanged.locationId, isNull);
      expect(unchanged.location, 'Korunacak');
      expect((await application.listObservationEvents(legacy.id)).length, 1);
    },
  );

  test(
    'same archived link survives unrelated edit and keeps historical snapshot',
    () async {
      final location = await createLocation(
        id: _locationA,
        event: 1,
        name: 'İlk Ad',
      );
      final created = await application.createAgendaLog(
        createCommand(log: 1, event: 11, locationId: location.id),
      );
      final renamed = await application.renameProjectLocation(
        RenameProjectLocationCommand(
          locationId: location.id,
          eventId: _eventId(12),
          expectedRevision: location.revision,
          displayName: 'Güncel Ad',
        ),
      );
      await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: renamed.id,
          eventId: _eventId(13),
          expectedRevision: renamed.revision,
          archive: true,
        ),
      );

      final updated = await application.updateAgendaLog(
        updateCommand(
          current: created,
          event: 14,
          locationId: location.id,
          location: 'Yeniden yazılmamalı',
          description: 'Yalnız açıklama değişti',
        ),
      );
      expect(updated.locationId, location.id);
      expect(updated.location, 'İlk Ad');
      expect(updated.stableLocationName, 'Güncel Ad');
      expect(updated.stableLocationArchivedAt, isNotNull);
    },
  );

  test(
    'unlink and legacy updates are explicit and do not mutate catalog rows',
    () async {
      await createLocation(id: _locationA, event: 1, name: 'A Blok');
      final stable = await application.createAgendaLog(
        createCommand(log: 1, event: 11, locationId: _locationA),
      );
      final catalogBefore = await withDatabase(
        (database) => database.query('project_locations'),
      );

      final unlinked = await application.updateAgendaLog(
        updateCommand(
          current: stable,
          event: 12,
          locationId: null,
          location: 'Açık serbest mahal',
        ),
      );
      expect(unlinked.locationId, isNull);
      expect(unlinked.location, 'Açık serbest mahal');
      final legacyUpdated = await application.updateAgendaLog(
        updateCommand(
          current: unlinked,
          event: 13,
          locationId: null,
          location: unlinked.location,
          description: 'Legacy metin korunarak düzenlendi',
        ),
      );
      expect(legacyUpdated.locationId, isNull);
      expect(legacyUpdated.location, 'Açık serbest mahal');
      final catalogAfter = await withDatabase(
        (database) => database.query('project_locations'),
      );
      expect(catalogAfter, catalogBefore);
    },
  );
}
