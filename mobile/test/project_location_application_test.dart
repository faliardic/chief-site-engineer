import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = '11111111-1111-4111-8111-111111111111';
const _projectB = '22222222-2222-4222-8222-222222222222';
const _missingProject = '33333333-3333-4333-8333-333333333333';

String _locationId(int value) =>
    'aaaaaaaa-aaaa-4aaa-8aaa-${value.toString().padLeft(12, '0')}';

String _eventId(int value) =>
    'eeeeeeee-eeee-4eee-8eee-${value.toString().padLeft(12, '0')}';

String _blockId(int value) =>
    'bbbbbbbb-bbbb-4bbb-8bbb-${value.toString().padLeft(12, '0')}';

String _floorId(int value) =>
    'ffffffff-ffff-4fff-8fff-${value.toString().padLeft(12, '0')}';

String _relationId(int value) =>
    'dddddddd-dddd-4ddd-8ddd-${value.toString().padLeft(12, '0')}';

void main() {
  late Directory temporaryRoot;
  late String databasePath;
  late DateTime now;
  late SqliteAgendaApplication application;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_project_location_application_',
    );
    databasePath = path.join(temporaryRoot.path, 'cse.sqlite3');
    now = DateTime.utc(2026, 8, 8, 8);
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
      const CreateProjectCommand(id: _projectA, name: 'Kuzey Projesi'),
    );
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  Future<void> createProjectB() => application.createProject(
    const CreateProjectCommand(id: _projectB, name: 'Güney Projesi'),
  );

  Future<MobileProjectLocation> createLocation({
    required int id,
    required int event,
    required String displayName,
    String projectId = _projectA,
    String? parentLocationId,
  }) => application.createProjectLocation(
    CreateProjectLocationCommand(
      id: _locationId(id),
      eventId: _eventId(event),
      projectId: projectId,
      displayName: displayName,
      parentLocationId: parentLocationId,
    ),
  );

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

  Future<void> archiveProject(String projectId) => withDatabase((database) {
    return database.update(
      'projects',
      {
        'archived_at': '2026-08-08T08:00:00Z',
        'updated_at': '2026-08-08T08:00:00Z',
        'revision': 2,
      },
      where: 'id = ?',
      whereArgs: [projectId],
    );
  });

  Future<({String blockId, String floorId})> seedFloor({
    required int seed,
    String projectId = _projectA,
  }) async {
    final blockId = _blockId(seed);
    final floorId = _floorId(seed);
    await withDatabase((database) async {
      const timestamp = '2026-08-08T08:00:00Z';
      await database.insert('inventory_blocks', {
        'id': blockId,
        'project_id': projectId,
        'display_name': 'Blok $seed',
        'normalized_name': 'blok $seed',
        'ordinal': seed,
        'state': 'ACTIVE',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await database.insert('inventory_floors', {
        'id': floorId,
        'block_id': blockId,
        'project_id': projectId,
        'display_name': '$seed. Kat',
        'ordinal': 1,
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
    });
    return (blockId: blockId, floorId: floorId);
  }

  test(
    'shares project behavior and lists active or archived locations deterministically',
    () async {
      final contract = application as ProjectLocationApplication;
      final projectChanged = contract.projectChanges.first;
      await contract.createProject(
        const CreateProjectCommand(id: _projectB, name: 'Güney Projesi'),
      );
      await projectChanged;
      expect((await contract.listProjects()).map((item) => item.id), [
        _projectB,
        _projectA,
      ]);

      final zeta = await createLocation(
        id: 1,
        event: 1,
        displayName: '  Zeta   Kat  ',
      );
      final alpha = await createLocation(
        id: 2,
        event: 2,
        displayName: 'Alfa Kat',
      );
      final child = await createLocation(
        id: 3,
        event: 3,
        displayName: 'Beta Oda',
        parentLocationId: alpha.id,
      );

      expect(zeta.displayName, 'Zeta Kat');
      expect(
        (await contract.listProjectLocations(
          const ProjectLocationQuery(projectId: _projectA),
        )).map((item) => item.id),
        [alpha.id, child.id, zeta.id],
      );
      expect(
        (await contract.getProjectLocation(child.id)).parentLocationId,
        alpha.id,
      );

      final archived = await contract.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: zeta.id,
          eventId: _eventId(4),
          expectedRevision: 1,
          archive: true,
        ),
      );
      expect(archived.isArchived, isTrue);
      expect(
        (await contract.listProjectLocations(
          const ProjectLocationQuery(projectId: _projectA),
        )).map((item) => item.id),
        [alpha.id, child.id],
      );
      expect(
        (await contract.listProjectLocations(
          const ProjectLocationQuery(
            projectId: _projectA,
            archiveFilter: ProjectLocationArchiveFilter.archived,
          ),
        )).map((item) => item.id),
        [zeta.id],
      );
    },
  );

  test(
    'create fails closed for invalid project parent name and identity',
    () async {
      await createProjectB();
      final otherProjectParent = await createLocation(
        id: 10,
        event: 10,
        displayName: 'Güney Kök',
        projectId: _projectB,
      );
      final archivedParent = await createLocation(
        id: 11,
        event: 11,
        displayName: 'Eski Kök',
      );
      await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: archivedParent.id,
          eventId: _eventId(12),
          expectedRevision: 1,
          archive: true,
        ),
      );
      final activeParent = await createLocation(
        id: 12,
        event: 13,
        displayName: 'Aktif Kök',
      );
      final firstChild = await createLocation(
        id: 13,
        event: 14,
        displayName: '  Daire   1 ',
        parentLocationId: activeParent.id,
      );

      for (final command in [
        CreateProjectLocationCommand(
          id: _locationId(20),
          eventId: _eventId(20),
          projectId: _missingProject,
          displayName: 'Eksik proje',
        ),
        CreateProjectLocationCommand(
          id: _locationId(21),
          eventId: _eventId(21),
          projectId: _projectA,
          displayName: 'Çapraz proje',
          parentLocationId: otherProjectParent.id,
        ),
        CreateProjectLocationCommand(
          id: _locationId(22),
          eventId: _eventId(22),
          projectId: _projectA,
          displayName: 'Arşivli üst',
          parentLocationId: archivedParent.id,
        ),
        CreateProjectLocationCommand(
          id: _locationId(23),
          eventId: _eventId(23),
          projectId: _projectA,
          displayName: 'daire 1',
          parentLocationId: activeParent.id,
        ),
        CreateProjectLocationCommand(
          id: firstChild.id,
          eventId: _eventId(24),
          projectId: _projectA,
          displayName: 'Başka içerik',
          parentLocationId: activeParent.id,
        ),
        CreateProjectLocationCommand(
          id: _locationId(25),
          eventId: _eventId(25),
          projectId: _projectA,
          displayName: '   ',
        ),
      ]) {
        await expectLater(
          application.createProjectLocation(command),
          throwsA(isA<AgendaValidationFailure>()),
        );
      }

      await archiveProject(_projectB);
      await expectLater(
        createLocation(
          id: 26,
          event: 26,
          displayName: 'Arşivli proje',
          projectId: _projectB,
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      final secondParent = await createLocation(
        id: 27,
        event: 27,
        displayName: 'İkinci Kök',
      );
      expect(
        (await createLocation(
          id: 28,
          event: 28,
          displayName: 'Daire 1',
          parentLocationId: secondParent.id,
        )).parentLocationId,
        secondParent.id,
      );
    },
  );

  test(
    'rename is optimistic transactional and records old and new names',
    () async {
      final first = await createLocation(
        id: 30,
        event: 30,
        displayName: 'Eski Ad',
      );
      await createLocation(id: 31, event: 31, displayName: 'Çakışan Ad');
      now = DateTime.utc(2026, 8, 8, 9);

      final renamed = await application.renameProjectLocation(
        RenameProjectLocationCommand(
          locationId: first.id,
          eventId: _eventId(32),
          expectedRevision: 1,
          displayName: '  Yeni   Ad ',
        ),
      );
      expect(renamed.displayName, 'Yeni Ad');
      expect(renamed.revision, 2);
      expect(renamed.updatedAt, '2026-08-08T09:00:00Z');
      final events = await application.listProjectLocationEvents(first.id);
      expect(events.map((item) => item.sequence), [1, 2]);
      expect(events.map((item) => item.eventType), [
        ProjectLocationEventType.created,
        ProjectLocationEventType.renamed,
      ]);
      expect(jsonDecode(events.last.payloadJson), {
        'old_display_name': 'Eski Ad',
        'new_display_name': 'Yeni Ad',
      });

      await expectLater(
        application.renameProjectLocation(
          RenameProjectLocationCommand(
            locationId: first.id,
            eventId: _eventId(33),
            expectedRevision: 1,
            displayName: 'Stale Ad',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      await expectLater(
        application.renameProjectLocation(
          RenameProjectLocationCommand(
            locationId: first.id,
            eventId: _eventId(34),
            expectedRevision: 2,
            displayName: 'çakışan ad',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect(
        (await application.getProjectLocation(first.id)).displayName,
        'Yeni Ad',
      );
      expect(
        await application.listProjectLocationEvents(first.id),
        hasLength(2),
      );

      final archived = await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: first.id,
          eventId: _eventId(35),
          expectedRevision: 2,
          archive: true,
        ),
      );
      await expectLater(
        application.renameProjectLocation(
          RenameProjectLocationCommand(
            locationId: first.id,
            eventId: _eventId(36),
            expectedRevision: archived.revision,
            displayName: 'Arşivde yeni ad',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
    },
  );

  test(
    'reparent supports root and rejects cross-project archived self or cycle',
    () async {
      await createProjectB();
      final parentOne = await createLocation(
        id: 40,
        event: 40,
        displayName: 'Birinci Kök',
      );
      final parentTwo = await createLocation(
        id: 41,
        event: 41,
        displayName: 'İkinci Kök',
      );
      final child = await createLocation(
        id: 42,
        event: 42,
        displayName: 'Çocuk',
        parentLocationId: parentOne.id,
      );
      final grandchild = await createLocation(
        id: 43,
        event: 43,
        displayName: 'Torun',
        parentLocationId: child.id,
      );
      final otherProjectParent = await createLocation(
        id: 44,
        event: 44,
        displayName: 'Diğer Proje Kök',
        projectId: _projectB,
      );
      final archivedParent = await createLocation(
        id: 45,
        event: 45,
        displayName: 'Arşivli Kök',
      );
      await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: archivedParent.id,
          eventId: _eventId(46),
          expectedRevision: 1,
          archive: true,
        ),
      );

      final moved = await application.reparentProjectLocation(
        ReparentProjectLocationCommand(
          locationId: child.id,
          eventId: _eventId(47),
          expectedRevision: 1,
          parentLocationId: parentTwo.id,
        ),
      );
      expect(moved.parentLocationId, parentTwo.id);
      expect(moved.revision, 2);
      final rooted = await application.reparentProjectLocation(
        ReparentProjectLocationCommand(
          locationId: child.id,
          eventId: _eventId(48),
          expectedRevision: 2,
        ),
      );
      expect(rooted.parentLocationId, isNull);
      expect(rooted.revision, 3);

      for (final parentId in [
        otherProjectParent.id,
        archivedParent.id,
        child.id,
        grandchild.id,
      ]) {
        await expectLater(
          application.reparentProjectLocation(
            ReparentProjectLocationCommand(
              locationId: child.id,
              eventId: _eventId(50 + parentId.hashCode.abs() % 1000),
              expectedRevision: 3,
              parentLocationId: parentId,
            ),
          ),
          throwsA(isA<AgendaValidationFailure>()),
        );
      }
      expect(
        (await application.getProjectLocation(child.id)).parentLocationId,
        isNull,
      );
      expect(
        (await application.listProjectLocationEvents(
          child.id,
        )).map((item) => item.eventType),
        [
          ProjectLocationEventType.created,
          ProjectLocationEventType.reparented,
          ProjectLocationEventType.reparented,
        ],
      );
    },
  );

  test(
    'archive and restore preserve hierarchy terminal idempotency and names',
    () async {
      final parent = await createLocation(
        id: 60,
        event: 60,
        displayName: 'Kök',
      );
      final child = await createLocation(
        id: 61,
        event: 61,
        displayName: 'Daire',
        parentLocationId: parent.id,
      );
      await expectLater(
        application.mutateProjectLocationArchive(
          MutateProjectLocationArchiveCommand(
            locationId: parent.id,
            eventId: _eventId(62),
            expectedRevision: 1,
            archive: true,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );

      final archivedChild = await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: child.id,
          eventId: _eventId(63),
          expectedRevision: 1,
          archive: true,
        ),
      );
      final repeatedArchive = await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: child.id,
          eventId: _eventId(64),
          expectedRevision: 1,
          archive: true,
        ),
      );
      expect(repeatedArchive.revision, archivedChild.revision);
      expect(
        await application.listProjectLocationEvents(child.id),
        hasLength(2),
      );

      final archivedParent = await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: parent.id,
          eventId: _eventId(65),
          expectedRevision: 1,
          archive: true,
        ),
      );
      await expectLater(
        application.mutateProjectLocationArchive(
          MutateProjectLocationArchiveCommand(
            locationId: child.id,
            eventId: _eventId(66),
            expectedRevision: archivedChild.revision,
            archive: false,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: parent.id,
          eventId: _eventId(67),
          expectedRevision: archivedParent.revision,
          archive: false,
        ),
      );
      final replacement = await createLocation(
        id: 62,
        event: 68,
        displayName: 'daire',
        parentLocationId: parent.id,
      );
      await expectLater(
        application.mutateProjectLocationArchive(
          MutateProjectLocationArchiveCommand(
            locationId: child.id,
            eventId: _eventId(69),
            expectedRevision: archivedChild.revision,
            archive: false,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      final archivedReplacement = await application
          .mutateProjectLocationArchive(
            MutateProjectLocationArchiveCommand(
              locationId: replacement.id,
              eventId: _eventId(70),
              expectedRevision: 1,
              archive: true,
            ),
          );
      expect(archivedReplacement.isArchived, isTrue);
      final restored = await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: child.id,
          eventId: _eventId(71),
          expectedRevision: archivedChild.revision,
          archive: false,
        ),
      );
      final repeatedRestore = await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: child.id,
          eventId: _eventId(72),
          expectedRevision: archivedChild.revision,
          archive: false,
        ),
      );
      expect(restored.isArchived, isFalse);
      expect(repeatedRestore.revision, restored.revision);
      expect(
        (await application.listProjectLocationEvents(
          child.id,
        )).map((item) => item.eventType),
        [
          ProjectLocationEventType.created,
          ProjectLocationEventType.archived,
          ProjectLocationEventType.restored,
        ],
      );
    },
  );

  test(
    'event failure rolls back row and notification then successful commit fires once',
    () async {
      final location = await createLocation(
        id: 80,
        event: 80,
        displayName: 'İlk Ad',
      );
      var notifications = 0;
      final subscription = application.projectLocationChanges.listen((_) {
        notifications += 1;
      });

      now = DateTime.utc(2026, 8, 8, 10);
      await expectLater(
        application.renameProjectLocation(
          RenameProjectLocationCommand(
            locationId: location.id,
            eventId: _eventId(80),
            expectedRevision: 1,
            displayName: 'Rollback Adı',
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 0);
      expect(
        (await application.getProjectLocation(location.id)).displayName,
        'İlk Ad',
      );
      expect((await application.getProjectLocation(location.id)).revision, 1);
      expect(
        await application.listProjectLocationEvents(location.id),
        hasLength(1),
      );

      final renamed = await application.renameProjectLocation(
        RenameProjectLocationCommand(
          locationId: location.id,
          eventId: _eventId(81),
          expectedRevision: 1,
          displayName: 'Kalıcı Ad',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(renamed.revision, 2);
      expect(notifications, 1);
      await application.renameProjectLocation(
        RenameProjectLocationCommand(
          locationId: location.id,
          eventId: _eventId(82),
          expectedRevision: 2,
          displayName: 'Kalıcı Ad',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 1);
      expect(
        await application.listProjectLocationEvents(location.id),
        hasLength(2),
      );
      await subscription.cancel();
    },
  );

  test(
    'stable Floor-Mahal relation assigns replaces removes and keeps identity through rename',
    () async {
      final firstFloor = await seedFloor(seed: 1);
      final secondFloor = await seedFloor(seed: 2);
      final firstLocation = await createLocation(
        id: 101,
        event: 101,
        displayName: 'Mahal Bir',
      );
      final secondLocation = await createLocation(
        id: 102,
        event: 102,
        displayName: 'Mahal İki',
      );
      final contract = application as ProjectFloorLocationApplication;
      final create = CreateProjectFloorLocationRelationCommand(
        id: _relationId(101),
        eventId: _eventId(111),
        projectId: _projectA,
        floorId: firstFloor.floorId,
        locationId: firstLocation.id,
      );
      final assigned = await contract.createProjectFloorLocation(create);
      expect(assigned.revision, 1);
      expect((await contract.createProjectFloorLocation(create)).revision, 1);
      await contract.createProjectFloorLocation(
        CreateProjectFloorLocationRelationCommand(
          id: _relationId(102),
          eventId: _eventId(112),
          projectId: _projectA,
          floorId: firstFloor.floorId,
          locationId: secondLocation.id,
        ),
      );
      expect(await contract.listProjectFloorLocations(_projectA), hasLength(2));

      now = DateTime.utc(2026, 8, 8, 9);
      await application.renameProjectLocation(
        RenameProjectLocationCommand(
          locationId: firstLocation.id,
          eventId: _eventId(113),
          expectedRevision: firstLocation.revision,
          displayName: 'Yeni Mahal Adı',
        ),
      );
      final replaced = await contract.replaceProjectFloorLocation(
        ReplaceProjectFloorLocationRelationCommand(
          relationId: assigned.id,
          eventId: _eventId(114),
          projectId: _projectA,
          expectedRevision: assigned.revision,
          floorId: secondFloor.floorId,
        ),
      );
      expect(replaced.floorId, secondFloor.floorId);
      expect(replaced.locationId, firstLocation.id);
      expect(replaced.revision, 2);
      final noOp = await contract.replaceProjectFloorLocation(
        ReplaceProjectFloorLocationRelationCommand(
          relationId: replaced.id,
          eventId: _eventId(115),
          projectId: _projectA,
          expectedRevision: replaced.revision,
          floorId: replaced.floorId,
        ),
      );
      expect(noOp.revision, 2);

      now = DateTime.utc(2026, 8, 8, 10);
      final removed = await contract.removeProjectFloorLocation(
        RemoveProjectFloorLocationRelationCommand(
          relationId: replaced.id,
          eventId: _eventId(116),
          projectId: _projectA,
          expectedRevision: replaced.revision,
        ),
      );
      expect(removed.isArchived, isTrue);
      expect(removed.revision, 3);
      expect(
        (await contract.removeProjectFloorLocation(
          RemoveProjectFloorLocationRelationCommand(
            relationId: removed.id,
            eventId: _eventId(117),
            projectId: _projectA,
            expectedRevision: removed.revision,
          ),
        )).revision,
        3,
      );
      expect(await contract.listProjectFloorLocations(_projectA), hasLength(1));
      expect(
        await contract.listProjectFloorLocations(
          _projectA,
          includeArchived: true,
        ),
        hasLength(2),
      );
      expect(
        (await contract.getProjectFloorLocation(removed.id)).isArchived,
        isTrue,
      );
      expect(
        (await contract.listProjectFloorLocationEvents(
          removed.id,
        )).map((event) => event.eventType),
        [
          ProjectFloorLocationEventType.assigned,
          ProjectFloorLocationEventType.replaced,
          ProjectFloorLocationEventType.removed,
        ],
      );
      final reassigned = await contract.createProjectFloorLocation(
        CreateProjectFloorLocationRelationCommand(
          id: _relationId(103),
          eventId: _eventId(118),
          projectId: _projectA,
          floorId: firstFloor.floorId,
          locationId: firstLocation.id,
        ),
      );
      expect(reassigned.id, isNot(removed.id));
    },
  );

  test(
    'Floor-Mahal relation rejects cross-project stale duplicate and orphaning writes',
    () async {
      await createProjectB();
      final floorA = await seedFloor(seed: 10);
      final floorB = await seedFloor(seed: 20, projectId: _projectB);
      final locationA = await createLocation(
        id: 201,
        event: 201,
        displayName: 'A Mahal',
      );
      final locationB = await createLocation(
        id: 202,
        event: 202,
        displayName: 'B Mahal',
        projectId: _projectB,
      );
      final contract = application as ProjectFloorLocationApplication;
      for (final command in [
        CreateProjectFloorLocationRelationCommand(
          id: _relationId(201),
          eventId: _eventId(211),
          projectId: _projectA,
          floorId: floorB.floorId,
          locationId: locationA.id,
        ),
        CreateProjectFloorLocationRelationCommand(
          id: _relationId(202),
          eventId: _eventId(212),
          projectId: _projectA,
          floorId: floorA.floorId,
          locationId: locationB.id,
        ),
      ]) {
        await expectLater(
          contract.createProjectFloorLocation(command),
          throwsA(isA<AgendaValidationFailure>()),
        );
      }
      final relation = await contract.createProjectFloorLocation(
        CreateProjectFloorLocationRelationCommand(
          id: _relationId(203),
          eventId: _eventId(213),
          projectId: _projectA,
          floorId: floorA.floorId,
          locationId: locationA.id,
        ),
      );
      await expectLater(
        contract.createProjectFloorLocation(
          CreateProjectFloorLocationRelationCommand(
            id: _relationId(204),
            eventId: _eventId(214),
            projectId: _projectA,
            floorId: floorA.floorId,
            locationId: locationA.id,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      await expectLater(
        contract.replaceProjectFloorLocation(
          ReplaceProjectFloorLocationRelationCommand(
            relationId: relation.id,
            eventId: _eventId(215),
            projectId: _projectA,
            expectedRevision: relation.revision + 1,
            floorId: floorA.floorId,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      now = DateTime.utc(2026, 8, 8, 11);
      await expectLater(
        application.mutateProjectLocationArchive(
          MutateProjectLocationArchiveCommand(
            locationId: locationA.id,
            eventId: _eventId(216),
            expectedRevision: locationA.revision,
            archive: true,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
      await withDatabase((database) async {
        await expectLater(
          database.update(
            'inventory_floors',
            {
              'revision': 2,
              'updated_at': '2026-08-08T11:00:00Z',
              'archived_at': '2026-08-08T11:00:00Z',
            },
            where: 'id = ?',
            whereArgs: [floorA.floorId],
          ),
          throwsA(isA<DatabaseException>()),
        );
        await expectLater(
          database.update(
            'inventory_blocks',
            {
              'state': 'ARCHIVED',
              'revision': 2,
              'updated_at': '2026-08-08T11:00:00Z',
              'archived_at': '2026-08-08T11:00:00Z',
            },
            where: 'id = ?',
            whereArgs: [floorA.blockId],
          ),
          throwsA(isA<DatabaseException>()),
        );
        await expectLater(
          database.update(
            'project_floor_location_relation_events',
            {'payload_json': '{}'},
            where: 'relation_id = ?',
            whereArgs: [relation.id],
          ),
          throwsA(isA<DatabaseException>()),
        );
        await expectLater(
          database.delete(
            'project_floor_location_relations',
            where: 'id = ?',
            whereArgs: [relation.id],
          ),
          throwsA(isA<DatabaseException>()),
        );
        expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      });
      expect((await contract.getProjectFloorLocation(relation.id)).revision, 1);

      await expectLater(
        contract.createProjectFloorLocation(
          CreateProjectFloorLocationRelationCommand(
            id: _relationId(205),
            eventId: _eventId(213),
            projectId: _projectB,
            floorId: floorB.floorId,
            locationId: locationB.id,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        contract.getProjectFloorLocation(_relationId(205)),
        throwsA(isA<AgendaValidationFailure>()),
      );
    },
  );

  test(
    'stable project identity and append-only event storage remain enforced',
    () async {
      await createProjectB();
      final location = await createLocation(
        id: 90,
        event: 90,
        displayName: 'Sabit Proje',
      );
      await withDatabase((database) async {
        await expectLater(
          database.update(
            'project_locations',
            {'project_id': _projectB},
            where: 'id = ?',
            whereArgs: [location.id],
          ),
          throwsA(isA<DatabaseException>()),
        );
        await expectLater(
          database.update(
            'project_location_events',
            {'payload_json': '{"changed":true}'},
            where: 'location_id = ?',
            whereArgs: [location.id],
          ),
          throwsA(isA<DatabaseException>()),
        );
        await expectLater(
          database.delete(
            'project_location_events',
            where: 'location_id = ?',
            whereArgs: [location.id],
          ),
          throwsA(isA<DatabaseException>()),
        );
        expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      });
      expect(
        (await application.getProjectLocation(location.id)).projectId,
        _projectA,
      );
      expect(
        (await application.listProjectLocationEvents(
          location.id,
        )).single.sequence,
        1,
      );
    },
  );

  test('missing and malformed read identities fail safely', () async {
    await expectLater(
      application.getProjectLocation(_locationId(999)),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      application.listProjectLocationEvents(_locationId(999)),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      application.listProjectLocations(
        const ProjectLocationQuery(projectId: _missingProject),
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      application.getProjectLocation('not-a-uuid'),
      throwsA(isA<AgendaValidationFailure>()),
    );
  });
}
