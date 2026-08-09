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
const _projectC = '33333333-3333-4333-8333-333333333333';
const _missingProject = '44444444-4444-4444-8444-444444444444';
const _logId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _reminderId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _attendanceDayId = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';
const _concretePourId = 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1';
const _attachmentId = 'abababab-abab-4aba-8aba-abababababab';
const _concreteClassId = 'cdcdcdcd-cdcd-4dcd-8dcd-cdcdcdcdcdcd';

String _eventId(int value) =>
    'eeeeeeee-eeee-4eee-8eee-${value.toString().padLeft(12, '0')}';

String _locationId(int value) =>
    '99999999-9999-4999-8999-${value.toString().padLeft(12, '0')}';

void main() {
  late Directory temporaryRoot;
  late String databasePath;
  late DateTime now;
  late SqliteAgendaApplication application;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_project_lifecycle_application_',
    );
    databasePath = path.join(temporaryRoot.path, 'cse.sqlite3');
    now = DateTime.utc(2026, 8, 9, 8);
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

  Future<MobileProject> createProject(String id, String name) =>
      application.createProject(CreateProjectCommand(id: id, name: name));

  Future<void> settleStreams() => Future<void>.delayed(Duration.zero);

  Future<void> seedChildGraph() async {
    await application.createProjectLocation(
      CreateProjectLocationCommand(
        id: _locationId(1),
        eventId: _eventId(101),
        projectId: _projectA,
        displayName: 'A Blok',
      ),
    );
    await application.createAgendaLog(
      CreateAgendaLogCommand(
        id: _logId,
        eventId: _eventId(102),
        projectId: _projectA,
        observedAt: '2026-08-09T07:00:00Z',
        category: AgendaCategory.inspection,
        description: 'Kolon kontrolü',
        location: 'A Blok',
      ),
    );
    await application.createReminder(
      CreateReminderCommand(
        id: _reminderId,
        eventId: _eventId(103),
        projectId: _projectA,
        sourceLogId: _logId,
        title: 'Kontrol sonucunu kaydet',
        kind: ReminderKind.action,
        schedule: ReminderScheduleKind.inbox,
      ),
    );
    await withDatabase((database) {
      return database.transaction((transaction) async {
        const timestamp = '2026-08-09T08:00:00Z';
        await transaction.insert('attendance_days', {
          'id': _attendanceDayId,
          'project_id': _projectA,
          'local_date': '2026-08-09',
          'status': 'draft',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        await transaction.insert('attendance_events', {
          'id': _eventId(104),
          'attendance_day_id': _attendanceDayId,
          'sequence': 1,
          'event_type': 'attendance_day.created',
          'occurred_at': timestamp,
          'payload_json': '{}',
        });
        await transaction.insert('concrete_pours', {
          'id': _concretePourId,
          'project_id': _projectA,
          'pour_code': 'DOK-001',
          'element_location': 'A Blok Temel',
          'planned_at': '2026-08-10T05:00:00Z',
          'concrete_class': 'C30/37',
          'planned_volume_m3': 12.5,
          'status': 'draft',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        await transaction.insert('concrete_pour_events', {
          'id': _eventId(105),
          'concrete_pour_id': _concretePourId,
          'sequence': 1,
          'event_type': 'pour.created',
          'occurred_at': timestamp,
          'payload_json': '{}',
        });
        await transaction.insert('agenda_log_attachments', {
          'id': _attachmentId,
          'observation_id': _logId,
          'project_id': _projectA,
          'attachment_type': 'site_photo',
          'original_file_name': 'kolon.png',
          'mime_type': 'image/png',
          'byte_size': 1,
          'sha256': List.filled(64, 'a').join(),
          'relative_path': 'agenda/kolon.png',
          'captured_at': timestamp,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        await transaction.insert('project_concrete_classes', {
          'id': _concreteClassId,
          'project_id': _projectA,
          'display_name': 'C30/37',
          'normalized_name': 'c30/37',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        await transaction.insert('project_concrete_class_events', {
          'id': _eventId(106),
          'concrete_class_id': _concreteClassId,
          'sequence': 1,
          'event_type': 'class.created',
          'occurred_at': timestamp,
          'payload_json': '{}',
        });
        await transaction.insert('concrete_pour_context_links', {
          'concrete_pour_id': _concretePourId,
          'project_id': _projectA,
          'concrete_class_id': _concreteClassId,
          'agenda_log_id': _logId,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
      });
    });
  }

  Future<Map<String, List<Map<String, Object?>>>> childSnapshot() {
    const columnsByTable = <String, List<String>>{
      'project_locations': ['id', 'project_id'],
      'field_observations': ['id', 'project_id'],
      'follow_up_items': ['id', 'project_id'],
      'attendance_days': ['id', 'project_id'],
      'concrete_pours': ['id', 'project_id'],
      'agenda_log_attachments': ['id', 'observation_id', 'project_id'],
      'observation_events': ['id', 'observation_id', 'project_id'],
      'follow_up_events': ['id', 'follow_up_id', 'project_id'],
      'attendance_events': ['id', 'attendance_day_id'],
      'concrete_pour_events': ['id', 'concrete_pour_id'],
      'project_location_events': ['id', 'location_id'],
      'project_concrete_class_events': ['id', 'concrete_class_id'],
      'concrete_pour_context_links': [
        'concrete_pour_id',
        'project_id',
        'concrete_class_id',
        'agenda_log_id',
      ],
    };
    return withDatabase((database) async {
      final snapshot = <String, List<Map<String, Object?>>>{};
      for (final entry in columnsByTable.entries) {
        snapshot[entry.key] = await database.query(
          entry.key,
          columns: entry.value,
          orderBy: '${entry.value.first} ASC',
        );
      }
      return snapshot;
    });
  }

  test(
    'lifecycle contract gets active and archived projects in deterministic order',
    () async {
      final ProjectLifecycleApplication contract = application;
      final active = await contract.getProject(_projectA);
      expect(active.isArchived, isFalse);

      await contract.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: _eventId(1),
          expectedRevision: 1,
          archive: true,
        ),
      );
      await createProject(_projectB, 'kuzey   projesi');
      await contract.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectB,
          eventId: _eventId(2),
          expectedRevision: 1,
          archive: true,
        ),
      );
      await createProject(_projectC, 'Alfa Projesi');

      expect((await application.listProjects()).map((item) => item.id), [
        _projectC,
      ]);
      expect(
        (await contract.listProjectRecords(
          ProjectArchiveFilter.active,
        )).map((item) => item.id),
        [_projectC],
      );
      expect(
        (await contract.listProjectRecords(
          ProjectArchiveFilter.archived,
        )).map((item) => item.id),
        [_projectA, _projectB],
      );
      final archived = await contract.getProject(_projectA);
      expect(archived.isArchived, isTrue);
      expect(archived.archivedAt, '2026-08-09T08:00:00Z');
    },
  );

  test(
    'rename updates revision, appends payload, preserves child identity, and no-ops exactly',
    () async {
      await application.createAgendaLog(
        CreateAgendaLogCommand(
          id: _logId,
          eventId: _eventId(110),
          projectId: _projectA,
          observedAt: '2026-08-09T07:00:00Z',
          category: AgendaCategory.generalNote,
          description: 'Mevcut child kayıt',
        ),
      );
      var signals = 0;
      final subscription = application.projectChanges.listen((_) {
        signals += 1;
      });
      addTearDown(subscription.cancel);

      now = DateTime.utc(2026, 8, 9, 9);
      final renamed = await application.renameProject(
        RenameProjectCommand(
          projectId: _projectA,
          eventId: _eventId(10),
          expectedRevision: 1,
          name: '  Yeni Kuzey  ',
        ),
      );
      await settleStreams();
      expect(renamed.name, 'Yeni Kuzey');
      expect(renamed.revision, 2);
      expect(renamed.updatedAt, '2026-08-09T09:00:00Z');
      expect(renamed.isArchived, isFalse);

      final events = await application.listProjectEvents(_projectA);
      expect(events, hasLength(1));
      expect(events.single.sequence, 1);
      expect(events.single.eventType, ProjectEventType.renamed);
      expect(jsonDecode(events.single.payloadJson), {
        'old_name': 'Kuzey Projesi',
        'new_name': 'Yeni Kuzey',
      });

      final joinedLog = (await application.listAgenda(
        const AgendaQuery(istanbulDay: '2026-08-09'),
      )).single;
      expect(joinedLog.id, _logId);
      expect(joinedLog.projectId, _projectA);
      expect(joinedLog.projectName, 'Yeni Kuzey');

      final noOp = await application.renameProject(
        RenameProjectCommand(
          projectId: _projectA,
          eventId: _eventId(11),
          expectedRevision: 2,
          name: '  Yeni Kuzey  ',
        ),
      );
      expect(noOp.revision, 2);
      await expectLater(
        application.renameProject(
          RenameProjectCommand(
            projectId: _projectA,
            eventId: _eventId(12),
            expectedRevision: 1,
            name: 'Stale ad',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      await settleStreams();
      expect(signals, 1);
      expect((await application.getProject(_projectA)).name, 'Yeni Kuzey');
      expect(await application.listProjectEvents(_projectA), hasLength(1));
    },
  );

  test(
    'rename rejects active collision and archived projects atomically',
    () async {
      await createProject(_projectB, 'Güney Projesi');
      await expectLater(
        application.renameProject(
          RenameProjectCommand(
            projectId: _projectB,
            eventId: _eventId(20),
            expectedRevision: 1,
            name: ' kuzey   projesi ',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect((await application.getProject(_projectB)).name, 'Güney Projesi');
      expect(await application.listProjectEvents(_projectB), isEmpty);

      await application.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: _eventId(21),
          expectedRevision: 1,
          archive: true,
        ),
      );
      await expectLater(
        application.renameProject(
          RenameProjectCommand(
            projectId: _projectA,
            eventId: _eventId(22),
            expectedRevision: 2,
            name: 'Arşivde yeni ad',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      final archived = await application.getProject(_projectA);
      expect(archived.name, 'Kuzey Projesi');
      expect(archived.revision, 2);
      expect(await application.listProjectEvents(_projectA), hasLength(1));
    },
  );

  test(
    'archive and restore preserve every fixture child and emit only real transitions',
    () async {
      await seedChildGraph();
      final before = await childSnapshot();
      expect(before['project_locations'], hasLength(1));
      expect(before['field_observations'], hasLength(1));
      expect(before['follow_up_items'], hasLength(1));
      expect(before['attendance_days'], hasLength(1));
      expect(before['concrete_pours'], hasLength(1));
      expect(before['agenda_log_attachments'], hasLength(1));
      expect(before['concrete_pour_context_links'], hasLength(1));

      var signals = 0;
      final subscription = application.projectChanges.listen((_) {
        signals += 1;
      });
      addTearDown(subscription.cancel);

      now = DateTime.utc(2026, 8, 9, 9);
      final archived = await application.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: _eventId(30),
          expectedRevision: 1,
          archive: true,
        ),
      );
      expect(archived.revision, 2);
      expect(archived.archivedAt, '2026-08-09T09:00:00Z');
      expect(await application.listProjects(), isEmpty);
      expect(await childSnapshot(), equals(before));

      final repeatedArchive = await application.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: _eventId(30),
          expectedRevision: 1,
          archive: true,
        ),
      );
      expect(repeatedArchive.revision, 2);

      now = DateTime.utc(2026, 8, 9, 10);
      final restored = await application.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: _eventId(31),
          expectedRevision: 2,
          archive: false,
        ),
      );
      expect(restored.revision, 3);
      expect(restored.archivedAt, isNull);
      expect((await application.listProjects()).single.id, _projectA);
      expect(await childSnapshot(), equals(before));

      final repeatedRestore = await application.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: _eventId(31),
          expectedRevision: 2,
          archive: false,
        ),
      );
      expect(repeatedRestore.revision, 3);
      await settleStreams();
      expect(signals, 2);

      final events = await application.listProjectEvents(_projectA);
      expect(events.map((item) => item.sequence), [1, 2]);
      expect(events.map((item) => item.eventType), [
        ProjectEventType.archived,
        ProjectEventType.restored,
      ]);
      expect(jsonDecode(events.first.payloadJson), {
        'was_archived': false,
        'is_archived': true,
      });
      expect(jsonDecode(events.last.payloadJson), {
        'was_archived': true,
        'is_archived': false,
      });
    },
  );

  test(
    'restore rejects a normalized active-name collision without mutation',
    () async {
      await application.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: _eventId(40),
          expectedRevision: 1,
          archive: true,
        ),
      );
      await createProject(_projectB, ' kuzey   projesi ');
      var signals = 0;
      final subscription = application.projectChanges.listen((_) {
        signals += 1;
      });
      addTearDown(subscription.cancel);

      await expectLater(
        application.mutateProjectArchive(
          MutateProjectArchiveCommand(
            projectId: _projectA,
            eventId: _eventId(41),
            expectedRevision: 2,
            archive: false,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      await settleStreams();
      expect(signals, 0);
      final archived = await application.getProject(_projectA);
      expect(archived.isArchived, isTrue);
      expect(archived.revision, 2);
      expect(await application.listProjectEvents(_projectA), hasLength(1));
    },
  );

  test(
    'event id collision rolls aggregate update back and emits no change',
    () async {
      await application.renameProject(
        RenameProjectCommand(
          projectId: _projectA,
          eventId: _eventId(50),
          expectedRevision: 1,
          name: 'Yeni Kuzey',
        ),
      );
      await createProject(_projectB, 'Güney Projesi');
      var signals = 0;
      final subscription = application.projectChanges.listen((_) {
        signals += 1;
      });
      addTearDown(subscription.cancel);

      await expectLater(
        application.renameProject(
          RenameProjectCommand(
            projectId: _projectB,
            eventId: _eventId(50),
            expectedRevision: 1,
            name: 'Yeni Güney',
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
      await settleStreams();
      expect(signals, 0);
      final project = await application.getProject(_projectB);
      expect(project.name, 'Güney Projesi');
      expect(project.revision, 1);
      expect(await application.listProjectEvents(_projectB), isEmpty);
    },
  );

  test('malformed and missing lifecycle identifiers fail safely', () async {
    await expectLater(
      application.getProject('not-a-uuid'),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      application.getProject(_missingProject),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      application.listProjectEvents(_missingProject),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      application.renameProject(
        const RenameProjectCommand(
          projectId: _projectA,
          eventId: 'not-a-uuid',
          expectedRevision: 1,
          name: 'Yeni ad',
        ),
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      application.renameProject(
        RenameProjectCommand(
          projectId: _missingProject,
          eventId: _eventId(70),
          expectedRevision: 1,
          name: 'Yeni ad',
        ),
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      application.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: _eventId(71),
          expectedRevision: 0,
          archive: true,
        ),
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );
    await expectLater(
      application.mutateProjectArchive(
        const MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: 'not-a-uuid',
          expectedRevision: 1,
          archive: true,
        ),
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );
    expect((await application.getProject(_projectA)).revision, 1);
    expect(await application.listProjectEvents(_projectA), isEmpty);
  });

  test(
    'project events remain ordered, append-only, and reject unknown storage',
    () async {
      await application.renameProject(
        RenameProjectCommand(
          projectId: _projectA,
          eventId: _eventId(80),
          expectedRevision: 1,
          name: 'Yeni Kuzey',
        ),
      );
      await application.mutateProjectArchive(
        MutateProjectArchiveCommand(
          projectId: _projectA,
          eventId: _eventId(81),
          expectedRevision: 2,
          archive: true,
        ),
      );
      expect(
        (await application.listProjectEvents(
          _projectA,
        )).map((item) => item.sequence),
        [1, 2],
      );

      await withDatabase((database) async {
        await expectLater(
          database.update(
            'project_events',
            {'payload_json': '{"changed":true}'},
            where: 'project_id = ?',
            whereArgs: [_projectA],
          ),
          throwsA(isA<DatabaseException>()),
        );
        await expectLater(
          database.delete(
            'project_events',
            where: 'project_id = ?',
            whereArgs: [_projectA],
          ),
          throwsA(isA<DatabaseException>()),
        );
        await database.execute('PRAGMA ignore_check_constraints = ON');
        try {
          await database.insert('project_events', {
            'id': _eventId(82),
            'project_id': _projectA,
            'sequence': 3,
            'event_type': 'project.unknown',
            'occurred_at': '2026-08-09T08:00:00Z',
            'payload_json': '{}',
          });
        } finally {
          await database.execute('PRAGMA ignore_check_constraints = OFF');
        }
      });
      await expectLater(
        application.listProjectEvents(_projectA),
        throwsA(isA<AgendaValidationFailure>()),
      );
    },
  );
}
