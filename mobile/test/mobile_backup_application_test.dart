import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/application/construction_schedule_snapshot_repository.dart';
import 'package:chief_site_engineer/application/mobile_backup_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:chief_site_engineer/domain/mobile_backup_models.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:chief_site_engineer/platform/mobile_backup_gateway.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:chief_site_engineer/storage/smoke_record.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/construction_profile_fixtures.dart';

const _password = 'guvenli-parola';
const _now = '2026-07-19T09:30:00Z';
const _closureManagedAttachmentId = '11111111-1111-4111-8111-111111111111';
const _closureLegacyAttachmentId = '22222222-2222-4222-8222-222222222222';
const _closureManagedPath = 'managed/11111111-1111-4111-8111-111111111111.jpg';
const _closureLegacyPath = 'agenda/closure-observation-legacy/site-photo.jpg';

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;
  late _FakeFileGateway gateway;
  late int notificationReconciliations;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_backup_test_');
    directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    await directories.ensureCreated();
    await _bootstrapDatabase(directories);
    gateway = _FakeFileGateway(directories);
    notificationReconciliations = 0;
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('backup creation reports real stages in pipeline order', () async {
    final application = _application(directories, gateway: gateway);
    final stages = <MobileBackupCreationStage>[];

    final created = await application.createBackup(
      const CreateMobileBackupCommand(
        password: _password,
        passwordConfirmation: _password,
      ),
      onProgress: stages.add,
    );

    const expectedStages = [
      MobileBackupCreationStage.preparing,
      MobileBackupCreationStage.packaging,
      MobileBackupCreationStage.verifying,
      MobileBackupCreationStage.saving,
    ];
    expect(stages, expectedStages);
    expect(stages.toSet(), hasLength(expectedStages.length));
    final package = File(created.absolutePath);
    expect(await package.exists(), isTrue);
    final packageBytes = await package.readAsBytes();
    expect(packageBytes, hasLength(created.summary.packageByteSize));
    expect(sha256.convert(packageBytes).toString(), created.packageSha256);
    expect(
      (await application.lastSuccessfulBackup())?.toJson(),
      created.summary.toJson(),
    );

    final invalidStages = <MobileBackupCreationStage>[];
    await expectLater(
      application.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: 'baska-parola',
        ),
        onProgress: invalidStages.add,
      ),
      _failureCode('password_confirmation_mismatch'),
    );
    expect(invalidStages, isEmpty);
  });

  test('empty fixture round-trips and remains valid after restart', () async {
    final application = _application(
      directories,
      gateway: gateway,
      reconcile: () async => notificationReconciliations += 1,
    );

    final created = await application.createBackup(
      const CreateMobileBackupCommand(
        password: _password,
        passwordConfirmation: _password,
      ),
    );
    final preflight = await application.preflightBackup(
      created.package,
      _password,
    );
    final restored = await application.restoreBackup(
      RestoreMobileBackupCommand(
        package: created.package,
        password: _password,
        expectedPackageSha256: preflight.packageSha256,
      ),
    );

    expect(preflight.manifest.attachments, isEmpty);
    expect(preflight.migratedSchemaVersion, AppDatabase.schemaVersion);
    expect(restored.restoredManifest.formatVersion, 1);
    expect(await File(restored.safetyBackupPath).exists(), isTrue);
    expect(notificationReconciliations, 1);
    final restarted = await _openRaw(directories);
    expect(
      Sqflite.firstIntValue(
        await restarted.rawQuery('SELECT count(*) FROM smoke_records'),
      ),
      1,
    );
    await restarted.close();
  });

  test(
    'current database smoke requires every schema 20 Inventory table',
    () async {
      final raw = await _openRaw(directories);
      await raw.execute('DROP TABLE inventory_events');
      await raw.close();
      final application = _application(directories, gateway: gateway);

      await expectLater(
        application.createBackup(
          const CreateMobileBackupCommand(
            password: _password,
            passwordConfirmation: _password,
          ),
        ),
        _failureCode('corrupt_database'),
      );
    },
  );

  test(
    'format 1 backup round-trips current schema trashed all-day reminder and audit',
    () async {
      final agenda = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => DateTime.parse(_now),
        notificationGateway: const UnavailableReminderNotificationGateway(),
      );
      final reminder = await agenda.createReminder(
        const CreateReminderCommand(
          id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          eventId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          title: 'Tam gün backup kaydı',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          allDayLocalDate: '2026-07-20',
        ),
      );
      expect(reminder.nextAttentionAt, isNull);
      final trashed = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.moveToTrash,
        ),
      );
      expect(trashed.trashedAt, isNotNull);

      final application = _application(directories, gateway: gateway);
      final created = await application.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );
      final preflight = await application.preflightBackup(
        created.package,
        _password,
      );
      await application.restoreBackup(
        RestoreMobileBackupCommand(
          package: created.package,
          password: _password,
          expectedPackageSha256: preflight.packageSha256,
        ),
      );

      final restored = await _openRaw(directories);
      final row = (await restored.query(
        'follow_up_items',
        where: 'id = ?',
        whereArgs: [reminder.id],
      )).single;
      expect(preflight.manifest.formatVersion, 1);
      expect(preflight.migratedSchemaVersion, AppDatabase.schemaVersion);
      expect(row['status'], 'active');
      expect(row['next_attention_at'], isNull);
      expect(row['all_day_local_date'], '2026-07-20');
      expect(row['trashed_at'], trashed.trashedAt);
      final binding = (await restored.query(
        'reminder_notification_bindings',
        where: 'reminder_id = ?',
        whereArgs: [reminder.id],
      )).single;
      expect(binding['scheduled_for'], isNull);
      expect(binding['sync_state'], 'cancelled');
      expect(
        await restored.query(
          'follow_up_events',
          where: "follow_up_id = ? AND event_type = 'trashed'",
          whereArgs: [reminder.id],
        ),
        hasLength(1),
      );
      await restored.close();
    },
  );

  test(
    'format 1 current schema backup restores dependency graph progress history receipt and origin',
    () async {
      final scenario = _backupScheduleScenario();
      final sourceDatabase = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.parse(_now),
      );
      await sourceDatabase.open();
      await sourceDatabase.database.insert('projects', {
        'id': scenario.profile.projectId,
        'name': 'Backup schedule project',
        'created_at': _now,
        'updated_at': _now,
      });
      final sourceRepository = ConstructionScheduleSnapshotRepository(
        database: sourceDatabase,
        clock: () => DateTime.parse(_now),
        idFactory: () => 'backup-schedule-snapshot-a',
      );
      final sourceSnapshotA = await sourceRepository.persistCurrentSnapshot(
        schedule: scenario.schedule,
        profile: scenario.profile,
        graph: scenario.graph,
        seedCatalog: scenario.catalog,
      );
      const livingItemId = '33333333-3333-4333-8333-333333333333';
      const createdEventId = '44444444-4444-4444-8444-444444444444';
      const startedEventId = '55555555-5555-4555-8555-555555555555';
      const progressEventId = '88888888-8888-4888-8888-888888888888';
      const noteEventId = '66666666-6666-4666-8666-666666666666';
      const noOpEventId = '77777777-7777-4777-8777-777777777777';
      var livingNow = DateTime.parse(_now);
      final sourceLivingApplication = ConstructionLivingPlanApplication(
        database: sourceDatabase,
        snapshotRepository: sourceRepository,
        clock: () => livingNow,
        graphLoader: (_) async => scenario.graph,
        corpusLoader: () async => scenario.corpus,
      );
      final createdLivingItem = await sourceLivingApplication
          .createLivingPlanItem(
            CreateConstructionLivingPlanItemCommand(
              itemId: livingItemId,
              eventId: createdEventId,
              projectId: scenario.profile.projectId,
              expectedReferenceSnapshotId: sourceSnapshotA.metadata.snapshotId,
              activityInstanceId: 'ACT-BACKUP@PROJECT',
              plannedDate: parseCanonicalConstructionDate('2026-09-04'),
              note: 'İlk saha notu',
            ),
          );
      expect(createdLivingItem.revision, 1);
      livingNow = DateTime.parse('2026-07-19T09:31:00Z');
      final startedLivingItem = await sourceLivingApplication
          .startLivingPlanItem(
            const StartConstructionLivingPlanItemCommand(
              itemId: livingItemId,
              eventId: startedEventId,
              expectedRevision: 1,
            ),
          );
      expect(startedLivingItem.revision, 2);
      livingNow = DateTime.parse('2026-07-19T09:31:30Z');
      final progressedLivingItem = await sourceLivingApplication
          .updateLivingPlanProgress(
            const UpdateConstructionLivingPlanProgressCommand(
              itemId: livingItemId,
              eventId: progressEventId,
              expectedRevision: 2,
              progressPercent: 48,
            ),
          );
      expect(progressedLivingItem.progressPercent, 48);
      expect(progressedLivingItem.revision, 3);
      final noOpResult = await sourceLivingApplication.startLivingPlanItem(
        const StartConstructionLivingPlanItemCommand(
          itemId: livingItemId,
          eventId: noOpEventId,
          expectedRevision: 3,
        ),
      );
      final immediateNoOpReplay = await sourceLivingApplication
          .startLivingPlanItem(
            const StartConstructionLivingPlanItemCommand(
              itemId: livingItemId,
              eventId: noOpEventId,
              expectedRevision: 3,
            ),
          );
      expect(immediateNoOpReplay.revision, noOpResult.revision);
      expect(immediateNoOpReplay.updatedAt, noOpResult.updatedAt);
      livingNow = DateTime.parse('2026-07-19T09:32:00Z');
      final notedLivingItem = await sourceLivingApplication
          .updateLivingPlanNote(
            const UpdateConstructionLivingPlanNoteCommand(
              itemId: livingItemId,
              eventId: noteEventId,
              expectedRevision: 3,
              note: 'Ekip teslimi tamamlandı',
            ),
          );
      expect(notedLivingItem.progressPercent, 48);
      expect(notedLivingItem.revision, 4);
      final lateNoOpReplay = await sourceLivingApplication.startLivingPlanItem(
        const StartConstructionLivingPlanItemCommand(
          itemId: livingItemId,
          eventId: noOpEventId,
          expectedRevision: 3,
        ),
      );
      expect(lateNoOpReplay.revision, 3);
      expect(lateNoOpReplay.progressPercent, 48);
      expect(lateNoOpReplay.note, 'İlk saha notu');
      final sourceEvents = await sourceDatabase.database.query(
        'project_living_plan_events',
        where: 'living_plan_item_id = ?',
        whereArgs: [livingItemId],
        orderBy: 'sequence ASC',
      );
      final sourceReceipts = await sourceDatabase.database.query(
        'project_living_plan_command_receipts',
        where: 'living_plan_item_id = ?',
        whereArgs: [livingItemId],
        orderBy: 'result_revision ASC, id ASC',
      );
      expect(sourceEvents, hasLength(4));
      expect(sourceReceipts, hasLength(5));
      final sourceProgressEvent = sourceEvents.singleWhere(
        (row) => row['id'] == progressEventId,
      );
      expect(sourceProgressEvent['event_type'], 'PROGRESS_UPDATED');
      expect(
        (jsonDecode(sourceProgressEvent['payload_json']! as String)
            as Map<String, Object?>)['change'],
        {'new_progress_percent': 48, 'previous_progress_percent': null},
      );
      final sourceProgressReceipt = sourceReceipts.singleWhere(
        (row) => row['id'] == progressEventId,
      );
      expect(sourceProgressReceipt['event_type'], 'PROGRESS_UPDATED');
      expect(sourceProgressReceipt['event_sequence'], 3);
      expect(
        (jsonDecode(sourceProgressReceipt['result_json']! as String)
            as Map<String, Object?>)['progress_percent'],
        48,
      );
      expect(
        sourceReceipts.singleWhere((row) => row['id'] == noOpEventId),
        containsPair('is_no_op', 1),
      );
      final sourceSnapshotB =
          await ConstructionScheduleSnapshotRepository(
            database: sourceDatabase,
            clock: () => DateTime.parse('2026-07-19T09:33:00Z'),
            idFactory: () => 'backup-schedule-snapshot-b',
          ).persistCurrentSnapshot(
            schedule: scenario.schedule,
            profile: scenario.profile,
            graph: scenario.graph,
            seedCatalog: scenario.catalog,
          );
      final sourceDependencyGraphA = await sourceRepository
          .loadDependencyGraphBySnapshotId(sourceSnapshotA.metadata.snapshotId);
      final sourceDependencyGraphB = await sourceRepository
          .loadDependencyGraphBySnapshotId(sourceSnapshotB.metadata.snapshotId);
      expect(sourceDependencyGraphA, isNotNull);
      expect(sourceDependencyGraphB, isNotNull);
      expect(sourceDependencyGraphA!.dependencyCount, 1);
      expect(
        sourceDependencyGraphA.projectionSha256,
        sourceDependencyGraphB!.projectionSha256,
      );
      await sourceDatabase.close();

      final sourceApplication = _application(directories, gateway: gateway);
      final created = await sourceApplication.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );
      final targetDirectories = AppDirectories.fromSupportRoot(
        Directory(path.join(temporaryRoot.path, 'schedule-restore-target')),
        AppEnvironment.debug,
      );
      await targetDirectories.ensureCreated();
      await _bootstrapDatabase(targetDirectories);
      final packageFile = File(created.absolutePath);
      final targetGateway = DeviceMobileBackupFileGateway(
        directories: targetDirectories,
        picker: () async => PlatformFile(
          name: 'schedule-current.csebackup',
          size: created.summary.packageByteSize,
          readStream: packageFile.openRead(),
        ),
        clock: () => DateTime.parse(_now),
        importIdFactory: (_) => 'schedule-current-clean-target',
      );
      final targetApplication = _application(
        targetDirectories,
        gateway: targetGateway,
      );
      final imported = (await targetApplication.pickBackupPackage())!;
      final preflight = await targetApplication.preflightBackup(
        imported,
        _password,
      );
      final restored = await targetApplication.restoreBackup(
        RestoreMobileBackupCommand(
          package: preflight.package,
          password: _password,
          expectedPackageSha256: preflight.packageSha256,
        ),
      );

      expect(preflight.manifest.formatVersion, 1);
      expect(preflight.manifest.mobileSchemaVersion, AppDatabase.schemaVersion);
      expect(preflight.migratedSchemaVersion, AppDatabase.schemaVersion);
      expect(restored.restoredManifest.formatVersion, 1);
      expect(restored.activeSchemaVersion, AppDatabase.schemaVersion);
      final reopened = AppDatabase(
        path: targetDirectories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.parse(_now),
      );
      await reopened.open();
      final restoredRepository = ConstructionScheduleSnapshotRepository(
        database: reopened,
        clock: () => DateTime.parse(_now),
      );
      final restoredSnapshot = await restoredRepository.loadCurrentSnapshot(
        scenario.profile.projectId,
      );
      expect(restoredSnapshot, isNotNull);
      expect(
        restoredSnapshot!.metadata.snapshotId,
        sourceSnapshotB.metadata.snapshotId,
      );
      expect(restoredSnapshot.metadata.isCurrent, isTrue);
      expect(
        restoredSnapshot.metadata.projectionSha256,
        sourceSnapshotB.metadata.projectionSha256,
      );
      expect(
        _backupActivityProjection(restoredSnapshot.activities),
        _backupActivityProjection(sourceSnapshotB.activities),
      );
      final restoredOrigin = await restoredRepository.loadSnapshotById(
        sourceSnapshotA.metadata.snapshotId,
      );
      expect(restoredOrigin?.metadata.isCurrent, isFalse);
      expect(
        restoredOrigin?.metadata.supersededAt,
        DateTime.parse('2026-07-19T09:33:00Z'),
      );
      final restoredDependencyGraphA = await restoredRepository
          .loadDependencyGraphBySnapshotId(sourceSnapshotA.metadata.snapshotId);
      final restoredDependencyGraphB = await restoredRepository
          .loadDependencyGraphBySnapshotId(sourceSnapshotB.metadata.snapshotId);
      expect(restoredDependencyGraphA, isNotNull);
      expect(restoredDependencyGraphB, isNotNull);
      expect(
        restoredDependencyGraphA!.projectionSha256,
        sourceDependencyGraphA.projectionSha256,
      );
      expect(
        restoredDependencyGraphB!.projectionSha256,
        sourceDependencyGraphB.projectionSha256,
      );
      expect(
        constructionScheduleSnapshotDependencyProjectionJson(
          restoredDependencyGraphA.edges,
        ),
        constructionScheduleSnapshotDependencyProjectionJson(
          sourceDependencyGraphA.edges,
        ),
      );
      expect(
        constructionScheduleSnapshotDependencyProjectionJson(
          restoredDependencyGraphB.edges,
        ),
        constructionScheduleSnapshotDependencyProjectionJson(
          sourceDependencyGraphB.edges,
        ),
      );
      final restoredItem = (await reopened.database.query(
        'project_living_plan_items',
        where: 'id = ?',
        whereArgs: [livingItemId],
      )).single;
      expect(restoredItem, {
        'id': livingItemId,
        'project_id': scenario.profile.projectId,
        'reference_snapshot_id': sourceSnapshotA.metadata.snapshotId,
        'activity_instance_id': 'ACT-BACKUP@PROJECT',
        'activity_id': 'ACT-BACKUP',
        'activity_name_snapshot': 'Backup milestone',
        'activity_context_json': '{}',
        'natural_unit_snapshot': 'TEST',
        'planned_date': '2026-09-04',
        'status': 'STARTED',
        'progress_percent': 48,
        'note': 'Ekip teslimi tamamlandı',
        'revision': 4,
        'created_at': _now,
        'updated_at': '2026-07-19T09:32:00Z',
        'status_changed_at': '2026-07-19T09:31:00Z',
      });
      final restoredEvents = await reopened.database.query(
        'project_living_plan_events',
        where: 'living_plan_item_id = ?',
        whereArgs: [livingItemId],
        orderBy: 'sequence ASC',
      );
      expect(restoredEvents.map((row) => row['sequence']), [1, 2, 3, 4]);
      expect(restoredEvents.map((row) => row['event_type']), [
        'CREATED',
        'STARTED',
        'PROGRESS_UPDATED',
        'NOTE_UPDATED',
      ]);
      expect(
        restoredEvents.map((row) => row['payload_json']),
        sourceEvents.map((row) => row['payload_json']),
      );
      final restoredReceipts = await reopened.database.query(
        'project_living_plan_command_receipts',
        where: 'living_plan_item_id = ?',
        whereArgs: [livingItemId],
        orderBy: 'result_revision ASC, id ASC',
      );
      expect(restoredReceipts, sourceReceipts);
      expect(
        restoredReceipts.singleWhere((row) => row['id'] == noOpEventId),
        containsPair('event_sequence', isNull),
      );
      final restoredLivingApplication = ConstructionLivingPlanApplication(
        database: reopened,
        snapshotRepository: restoredRepository,
        clock: () => DateTime.parse('2026-07-19T09:34:00Z'),
        graphLoader: (_) async => scenario.graph,
        corpusLoader: () async => scenario.corpus,
      );
      final restoredNoOpReplay = await restoredLivingApplication
          .startLivingPlanItem(
            const StartConstructionLivingPlanItemCommand(
              itemId: livingItemId,
              eventId: noOpEventId,
              expectedRevision: 3,
            ),
          );
      expect(restoredNoOpReplay.revision, 3);
      expect(restoredNoOpReplay.status, ConstructionLivingPlanStatus.started);
      expect(restoredNoOpReplay.progressPercent, 48);
      expect(restoredNoOpReplay.note, 'İlk saha notu');
      expect(
        (await restoredLivingApplication.loadLivingPlanItem(
          livingItemId,
        ))?.revision,
        4,
      );
      await expectLater(
        restoredLivingApplication.completeLivingPlanItem(
          const CompleteConstructionLivingPlanItemCommand(
            itemId: livingItemId,
            eventId: noOpEventId,
            expectedRevision: 4,
          ),
        ),
        throwsA(
          isA<ConstructionLivingPlanFailure>().having(
            (failure) => failure.code,
            'code',
            'living_plan_event_id_conflict',
          ),
        ),
      );
      await expectLater(
        reopened.database.insert('project_living_plan_items', {
          ...restoredItem,
          'id': '77777777-7777-4777-8777-777777777777',
          'reference_snapshot_id': sourceSnapshotB.metadata.snapshotId,
          'created_at': '2026-07-19T09:34:00Z',
          'updated_at': '2026-07-19T09:34:00Z',
          'status_changed_at': '2026-07-19T09:34:00Z',
        }),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        reopened.database.insert('project_living_plan_items', {
          ...restoredItem,
          'id': '88888888-8888-4888-8888-888888888888',
          'reference_snapshot_id': sourceSnapshotB.metadata.snapshotId,
          'activity_instance_id': 'MISSING@PROJECT',
          'activity_id': 'MISSING',
          'created_at': '2026-07-19T09:34:00Z',
          'updated_at': '2026-07-19T09:34:00Z',
          'status_changed_at': '2026-07-19T09:34:00Z',
        }),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        await reopened.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      expect(
        (await reopened.database.rawQuery(
          'PRAGMA integrity_check',
        )).single['integrity_check'],
        'ok',
      );
      await reopened.close();
    },
  );

  test(
    'format 1 schema 16 backup migrates through current without dependency backfill',
    () async {
      final oldRoot = await Directory.systemTemp.createTemp('cse_schema16_');
      addTearDown(() async {
        if (await oldRoot.exists()) await oldRoot.delete(recursive: true);
      });
      final oldFile = path.join(oldRoot.path, 'schema16.sqlite3');
      final oldDatabase = AppDatabase(
        path: oldFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.parse(_now),
      );
      await oldDatabase.open();
      await SmokeRecordRepository(
        database: oldDatabase,
        clock: () => DateTime.parse(_now),
      ).ensureFoundationRecord();
      final legacyScenario = _backupScheduleScenario();
      await oldDatabase.database.insert('projects', {
        'id': legacyScenario.profile.projectId,
        'name': 'Schema 16 project',
        'created_at': _now,
        'updated_at': _now,
      });
      final legacySnapshot =
          await ConstructionScheduleSnapshotRepository(
            database: oldDatabase,
            clock: () => DateTime.parse(_now),
            idFactory: () => 'schema16-snapshot',
          ).persistCurrentSnapshot(
            schedule: legacyScenario.schedule,
            profile: legacyScenario.profile,
            graph: legacyScenario.graph,
            seedCatalog: legacyScenario.catalog,
          );
      const legacyItemId = '99999999-9999-4999-8999-999999999999';
      final legacyLivingApplication = ConstructionLivingPlanApplication(
        database: oldDatabase,
        snapshotRepository: ConstructionScheduleSnapshotRepository(
          database: oldDatabase,
          clock: () => DateTime.parse(_now),
        ),
        clock: () => DateTime.parse(_now),
        graphLoader: (_) async => legacyScenario.graph,
        corpusLoader: () async => legacyScenario.corpus,
      );
      await legacyLivingApplication.createLivingPlanItem(
        CreateConstructionLivingPlanItemCommand(
          itemId: legacyItemId,
          eventId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          projectId: legacyScenario.profile.projectId,
          expectedReferenceSnapshotId: legacySnapshot.metadata.snapshotId,
          activityInstanceId: 'ACT-BACKUP@PROJECT',
          plannedDate: parseCanonicalConstructionDate('2026-09-04'),
        ),
      );
      await legacyLivingApplication.startLivingPlanItem(
        const StartConstructionLivingPlanItemCommand(
          itemId: legacyItemId,
          eventId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          expectedRevision: 1,
        ),
      );
      final legacyProgress = await legacyLivingApplication
          .updateLivingPlanProgress(
            const UpdateConstructionLivingPlanProgressCommand(
              itemId: legacyItemId,
              eventId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
              expectedRevision: 2,
              progressPercent: 37,
            ),
          );
      expect(legacyProgress.revision, 3);
      expect(legacyProgress.progressPercent, 37);
      await oldDatabase.close();
      final legacyRaw = await databaseFactoryFfi.openDatabase(
        oldFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await legacyRaw.execute('PRAGMA foreign_keys = OFF');
      await legacyRaw.execute(
        'DROP TRIGGER agenda_phone_call_contexts_source_category_update',
      );
      for (final table in const [
        'inventory_events',
        'inventory_command_receipts',
        'inventory_asset_attachment_links',
        'inventory_asset_placements',
        'inventory_sketch_revisions',
        'inventory_assets',
        'inventory_sketches',
        'agenda_phone_call_contexts',
        'material_request_events',
        'material_requests',
        'project_schedule_snapshot_dependencies',
        'project_schedule_snapshot_dependency_manifests',
      ]) {
        await legacyRaw.execute('DROP TABLE $table');
      }
      await legacyRaw.delete(
        'schema_versions',
        where: 'version >= ?',
        whereArgs: [17],
      );
      await legacyRaw.execute('PRAGMA user_version = 16');
      await legacyRaw.close();
      final databaseBytes = await File(oldFile).readAsBytes();
      final archive = const CseBackupArchiveCodec().encode(
        manifest: _manifest(databaseBytes, schemaVersion: 16),
        databaseBytes: databaseBytes,
        attachments: const {},
      );
      final package = File(path.join(oldRoot.path, 'schema16.csebackup'));
      await package.writeAsBytes(
        await _testEncryptionCodec().encrypt(archive, _password),
        flush: true,
      );
      final imported = await _stageIncomingPackage(directories, package);
      final application = _application(directories, gateway: gateway);
      final preflight = await application.preflightBackup(imported, _password);
      final restored = await application.restoreBackup(
        RestoreMobileBackupCommand(
          package: imported,
          password: _password,
          expectedPackageSha256: preflight.packageSha256,
        ),
      );

      expect(preflight.manifest.formatVersion, 1);
      expect(preflight.manifest.mobileSchemaVersion, 16);
      expect(preflight.migratedSchemaVersion, AppDatabase.schemaVersion);
      expect(restored.activeSchemaVersion, AppDatabase.schemaVersion);
      final reopened = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.parse(_now),
      );
      await reopened.open();
      expect(
        (await reopened.database.query(
          'projects',
          where: 'id = ?',
          whereArgs: [legacyScenario.profile.projectId],
        )).single['name'],
        'Schema 16 project',
      );
      expect(
        await reopened.database.query('project_schedule_snapshots'),
        hasLength(1),
      );
      expect(
        await reopened.database.query('project_schedule_snapshot_activities'),
        hasLength(2),
      );
      final restoredRepository = ConstructionScheduleSnapshotRepository(
        database: reopened,
        clock: () => DateTime.parse(_now),
      );
      final restoredLegacy = await restoredRepository.loadCurrentSnapshot(
        legacyScenario.profile.projectId,
      );
      expect(
        restoredLegacy?.metadata.projectionSha256,
        legacySnapshot.metadata.projectionSha256,
      );
      expect(
        await reopened.database.query(
          'project_schedule_snapshot_dependency_manifests',
        ),
        isEmpty,
      );
      expect(
        await reopened.database.query('project_schedule_snapshot_dependencies'),
        isEmpty,
      );
      await expectLater(
        restoredRepository.loadDependencyGraphBySnapshotId(
          legacySnapshot.metadata.snapshotId,
        ),
        throwsA(
          isA<ConstructionScheduleSnapshotFailure>().having(
            (failure) => failure.code,
            'code',
            'schedule_snapshot_dependency_graph_unavailable',
          ),
        ),
      );
      expect(
        (await reopened.database.query(
          'project_living_plan_items',
          where: 'id = ?',
          whereArgs: [legacyItemId],
        )).single,
        containsPair('progress_percent', 37),
      );
      expect(
        (await reopened.database.query(
          'project_living_plan_items',
          where: 'id = ?',
          whereArgs: [legacyItemId],
        )).single,
        allOf(
          containsPair('status', 'STARTED'),
          containsPair('revision', 3),
          containsPair(
            'reference_snapshot_id',
            legacySnapshot.metadata.snapshotId,
          ),
        ),
      );
      expect(
        (await reopened.database.query(
          'project_living_plan_events',
          where: 'living_plan_item_id = ?',
          whereArgs: [legacyItemId],
          orderBy: 'sequence ASC',
        )).map((row) => row['event_type']),
        orderedEquals(const ['CREATED', 'STARTED', 'PROGRESS_UPDATED']),
      );
      expect(
        await reopened.database.query(
          'project_living_plan_command_receipts',
          where: 'living_plan_item_id = ?',
          whereArgs: [legacyItemId],
        ),
        hasLength(3),
      );
      expect(
        await reopened.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      await reopened.close();
    },
  );

  test(
    'stable picker import survives source loss wrong password retry and restore',
    () async {
      final creator = _application(directories, gateway: gateway);
      final created = await creator.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );
      final pickerSource = File(created.absolutePath);
      final sourceSize = await pickerSource.length();
      final deviceGateway = DeviceMobileBackupFileGateway(
        directories: directories,
        picker: () async => PlatformFile(
          name: 'gercek-cihaz-yedegi.csebackup',
          size: sourceSize,
          path: pickerSource.path,
          readStream: pickerSource.openRead(),
        ),
        clock: () => DateTime.parse(_now),
        importIdFactory: (_) => 'stable-picker-import',
      );
      final application = _application(directories, gateway: deviceGateway);

      final imported = (await application.pickBackupPackage())!;
      await pickerSource.delete();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await expectLater(
        application.preflightBackup(imported, 'yanlis-parola'),
        _failureCode('wrong_password_or_tampered'),
      );
      expect(await File(imported.stablePath).exists(), isTrue);
      final preflight = await application.preflightBackup(imported, _password);
      await application.restoreBackup(
        RestoreMobileBackupCommand(
          package: preflight.package,
          password: _password,
          expectedPackageSha256: preflight.packageSha256,
        ),
      );

      expect(await File(imported.stablePath).exists(), isFalse);
      expect(await directories.incomingBackups.exists(), isFalse);
    },
  );

  test(
    'same package reselect cleans old import while picker cancel keeps current',
    () async {
      final selections = <PlatformFile?>[
        PlatformFile(
          name: 'same.csebackup',
          size: 3,
          readStream: Stream.value([1, 2, 3]),
        ),
        PlatformFile(
          name: 'same.csebackup',
          size: 3,
          readStream: Stream.value([1, 2, 3]),
        ),
        null,
      ];
      final ids = ['replacement-first', 'replacement-second'];
      final deviceGateway = DeviceMobileBackupFileGateway(
        directories: directories,
        picker: () async => selections.removeAt(0),
        clock: () => DateTime.parse(_now),
        importIdFactory: (_) => ids.removeAt(0),
      );
      final application = _application(directories, gateway: deviceGateway);

      final first = (await application.pickBackupPackage())!;
      final second = (await application.pickBackupPackage(first))!;
      expect(await File(first.stablePath).exists(), isFalse);
      expect(await File(second.stablePath).exists(), isTrue);

      final cancelled = await application.pickBackupPackage(second);
      expect(cancelled, isNull);
      expect(await File(second.stablePath).exists(), isTrue);
      await application.discardBackupPackage(second);
    },
  );

  test(
    'restore failure retains stable import and active SQLite truth',
    () async {
      final creator = _application(directories, gateway: gateway);
      final created = await creator.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );
      final source = File(created.absolutePath);
      final deviceGateway = DeviceMobileBackupFileGateway(
        directories: directories,
        picker: () async => PlatformFile(
          name: 'retry.csebackup',
          size: created.summary.packageByteSize,
          readStream: source.openRead(),
        ),
        clock: () => DateTime.parse(_now),
        importIdFactory: (_) => 'restore-failure-retry',
      );
      final failing = _application(
        directories,
        gateway: deviceGateway,
        hooks: MobileRestoreHooks(
          beforeSwap: () async => throw StateError('injected restore failure'),
        ),
      );
      final imported = (await failing.pickBackupPackage())!;
      final preflight = await failing.preflightBackup(imported, _password);
      final before = await _fixtureSnapshot(directories);

      await expectLater(
        failing.restoreBackup(
          RestoreMobileBackupCommand(
            package: preflight.package,
            password: _password,
            expectedPackageSha256: preflight.packageSha256,
          ),
        ),
        throwsStateError,
      );

      expect(await File(imported.stablePath).exists(), isTrue);
      expect(await _fixtureSnapshot(directories), before);
      await failing.discardBackupPackage(imported);
    },
  );

  test('backup exclusive section blocks a real Agenda mutation', () async {
    final coordinator = MobileOperationCoordinator();
    final encryption = _BlockingEncryptionCodec();
    final application = _application(
      directories,
      gateway: gateway,
      coordinator: coordinator,
      encryptionCodec: encryption,
    );
    final agenda = SqliteAgendaApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      clock: () => DateTime.parse(_now),
      notificationGateway: const UnavailableReminderNotificationGateway(),
      coordinator: coordinator,
    );
    final backupFuture = application.createBackup(
      const CreateMobileBackupCommand(
        password: _password,
        passwordConfirmation: _password,
      ),
    );
    await encryption.entered.future;
    var mutationCompleted = false;
    final mutation = agenda
        .createProject(
          const CreateProjectCommand(
            id: '99999999-9999-4999-8999-999999999999',
            name: 'Yedek sırasında bekleyen proje',
          ),
        )
        .then((_) => mutationCompleted = true);
    await Future<void>.delayed(Duration.zero);
    expect(mutationCompleted, isFalse);

    encryption.release.complete();
    await Future.wait([backupFuture, mutation]);
    expect(mutationCompleted, isTrue);
  });

  test(
    'schema 13 full fixture preserves profiles IDs events links and attachments',
    () async {
      final expectedBytes = <int>[0, 1, 2, 127, 128, 255];
      await _seedFullFixture(directories, expectedBytes);
      final before = await _fixtureSnapshot(directories);
      final application = _application(
        directories,
        gateway: gateway,
        reconcile: () async => notificationReconciliations += 1,
      );
      final created = await application.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );

      final active = await _openRaw(directories);
      await active.update(
        'projects',
        {'name': 'Restore ile silinecek değişiklik'},
        where: 'id = ?',
        whereArgs: ['project-1'],
      );
      await active.insert('projects', {
        'id': 'project-extra',
        'name': 'Paket sonrası kayıt',
        'created_at': _now,
        'updated_at': _now,
        'revision': 1,
      });
      final changedAttachmentBytes = <int>[9, 9, 9];
      await active.update(
        'managed_attachments',
        {
          'byte_size': changedAttachmentBytes.length,
          'sha256': sha256.convert(changedAttachmentBytes).toString(),
        },
        where: 'id = ?',
        whereArgs: ['attachment-1'],
      );
      await active.close();
      final attachment = File(
        path.join(directories.attachments.path, 'concrete/pour-1/evidence.bin'),
      );
      await attachment.writeAsBytes(changedAttachmentBytes, flush: true);

      final preflight = await application.preflightBackup(
        created.package,
        _password,
      );
      expect(preflight.manifest.attachments, hasLength(2));
      expect(
        preflight.manifest.attachments
            .singleWhere(
              (item) => item.logicalPath == 'concrete/pour-1/evidence.bin',
            )
            .byteSize,
        expectedBytes.length,
      );
      await application.restoreBackup(
        RestoreMobileBackupCommand(
          package: created.package,
          password: _password,
          expectedPackageSha256: preflight.packageSha256,
        ),
      );

      expect(await _fixtureSnapshot(directories), before);
      await _expectV21LocationFixture(directories);
      final restoredProfiles = await _openRaw(directories);
      final restoredSubcontractor = (await restoredProfiles.query(
        'subcontractors',
        where: 'id = ?',
        whereArgs: ['subcontractor-1'],
      )).single;
      final restoredMember = (await restoredProfiles.query(
        'workforce_members',
        where: 'id = ?',
        whereArgs: ['worker-1'],
      )).single;
      expect(restoredSubcontractor['address'], 'Şantiye firma adresi');
      expect(restoredSubcontractor['specialty'], 'Kalıp ve beton');
      expect(restoredSubcontractor['started_on'], '2026-07-01');
      expect(restoredSubcontractor['ended_on'], '2026-12-31');
      expect(restoredMember['address'], 'Personel saha adresi');
      expect(restoredMember['started_on'], '2026-07-02');
      expect(
        (await restoredProfiles.query(
          'attendance_entries',
        )).single['workforce_member_id'],
        restoredMember['id'],
      );
      await restoredProfiles.close();
      expect(await attachment.readAsBytes(), expectedBytes);
      expect(
        await File(
          path.join(
            directories.attachments.path,
            'agenda/observation-1/site-photo.jpg',
          ),
        ).readAsBytes(),
        const [0xff, 0xd8, 0xff, 0xd9],
      );
      expect(notificationReconciliations, 1);
      expect(
        (await application.lastSuccessfulBackup())?.fileName,
        created.summary.fileName,
      );
    },
  );

  test(
    'schema 13 attachment graph restores to a clean root and survives reopen',
    () async {
      const expectedBytes = <int>[0xff, 0xd8, 0xff, 0xd9];
      final expectedDigest = sha256.convert(expectedBytes).toString();
      await _seedAttachmentClosureFixture(directories, expectedBytes);
      final sourceApplication = _application(directories, gateway: gateway);
      final created = await sourceApplication.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );
      expect(created.summary.attachmentCount, 2);

      final targetDirectories = AppDirectories.fromSupportRoot(
        Directory(path.join(temporaryRoot.path, 'clean-restore-target')),
        AppEnvironment.debug,
      );
      await targetDirectories.ensureCreated();
      await _bootstrapDatabase(targetDirectories);
      final packageFile = File(created.absolutePath);
      final targetGateway = DeviceMobileBackupFileGateway(
        directories: targetDirectories,
        picker: () async => PlatformFile(
          name: 'v2-3-closure.csebackup',
          size: created.summary.packageByteSize,
          readStream: packageFile.openRead(),
        ),
        clock: () => DateTime.parse(_now),
        importIdFactory: (_) => 'v2-3-clean-target',
      );
      final targetApplication = _application(
        targetDirectories,
        gateway: targetGateway,
      );

      final imported = (await targetApplication.pickBackupPackage())!;
      final preflight = await targetApplication.preflightBackup(
        imported,
        _password,
      );
      expect(preflight.manifest.formatVersion, 1);
      expect(preflight.manifest.mobileSchemaVersion, AppDatabase.schemaVersion);
      expect(preflight.manifest.attachments.map((item) => item.logicalPath), [
        _closureLegacyPath,
        _closureManagedPath,
      ]);
      final restored = await targetApplication.restoreBackup(
        RestoreMobileBackupCommand(
          package: preflight.package,
          password: _password,
          expectedPackageSha256: preflight.packageSha256,
        ),
      );
      expect(restored.restoredManifest.formatVersion, 1);
      expect(restored.activeSchemaVersion, AppDatabase.schemaVersion);
      expect(await File(imported.stablePath).exists(), isFalse);
      expect(await targetDirectories.incomingBackups.exists(), isFalse);

      final reopened = AppDatabase(
        path: targetDirectories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.parse(_now),
      );
      await reopened.open();
      final database = reopened.database;
      expect(
        Sqflite.firstIntValue(
          await database.rawQuery('SELECT max(version) FROM schema_versions'),
        ),
        AppDatabase.schemaVersion,
      );
      expect(
        await database.rawQuery('''
          SELECT id, relative_path, mime_type, byte_size, sha256
          FROM managed_attachments
          ORDER BY id
        '''),
        [
          {
            'id': _closureManagedAttachmentId,
            'relative_path': _closureManagedPath,
            'mime_type': 'image/jpeg',
            'byte_size': expectedBytes.length,
            'sha256': expectedDigest,
          },
          {
            'id': _closureLegacyAttachmentId,
            'relative_path': _closureLegacyPath,
            'mime_type': 'image/jpeg',
            'byte_size': expectedBytes.length,
            'sha256': expectedDigest,
          },
        ],
      );
      expect(
        await database.rawQuery('''
          SELECT id, attachment_id, project_id, source_type, source_id, role,
                 original_file_name, captured_at
          FROM attachment_links
          ORDER BY id
        '''),
        [
          {
            'id': 'closure-link-agenda-shared',
            'attachment_id': _closureManagedAttachmentId,
            'project_id': 'closure-project',
            'source_type': 'agenda_observation',
            'source_id': 'closure-observation-shared',
            'role': 'site_photo',
            'original_file_name': 'paylasilan-saha.jpg',
            'captured_at': _now,
          },
          {
            'id': 'closure-link-concrete-shared',
            'attachment_id': _closureManagedAttachmentId,
            'project_id': 'closure-project',
            'source_type': 'concrete_pour',
            'source_id': 'closure-pour',
            'role': 'site_photo',
            'original_file_name': 'paylasilan-beton.jpg',
            'captured_at': _now,
          },
          {
            'id': 'closure-link-legacy',
            'attachment_id': _closureLegacyAttachmentId,
            'project_id': 'closure-project',
            'source_type': 'agenda_observation',
            'source_id': 'closure-observation-legacy',
            'role': 'site_photo',
            'original_file_name': 'legacy-saha.jpg',
            'captured_at': _now,
          },
        ],
      );
      expect(
        Sqflite.firstIntValue(
          await database.rawQuery(
            '''
            SELECT count(*) FROM attachment_links
            WHERE attachment_id = ?
          ''',
            [_closureManagedAttachmentId],
          ),
        ),
        2,
      );
      expect(
        await database.rawQuery(
          '''
          SELECT source_type, source_id
          FROM attachment_links
          WHERE attachment_id = ?
          ORDER BY source_type
        ''',
          [_closureManagedAttachmentId],
        ),
        [
          {
            'source_type': 'agenda_observation',
            'source_id': 'closure-observation-shared',
          },
          {'source_type': 'concrete_pour', 'source_id': 'closure-pour'},
        ],
      );
      expect(
        await database.rawQuery('''
          SELECT attachment_link_id, sequence, event_type
          FROM attachment_link_events
          ORDER BY attachment_link_id
        '''),
        [
          {
            'attachment_link_id': 'closure-link-agenda-shared',
            'sequence': 1,
            'event_type': 'link.created',
          },
          {
            'attachment_link_id': 'closure-link-concrete-shared',
            'sequence': 1,
            'event_type': 'link.created',
          },
          {
            'attachment_link_id': 'closure-link-legacy',
            'sequence': 1,
            'event_type': 'link.created',
          },
        ],
      );
      expect(
        await database.query(
          'field_observations',
          columns: ['id'],
          orderBy: 'id',
        ),
        [
          {'id': 'closure-observation-legacy'},
          {'id': 'closure-observation-shared'},
        ],
      );
      expect((await database.query('concrete_pours', columns: ['id'])).single, {
        'id': 'closure-pour',
      });
      expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await reopened.close();

      final store = DeviceManagedAttachmentStore(
        directories: targetDirectories,
      );
      for (final relativePath in [_closureManagedPath, _closureLegacyPath]) {
        expect(
          await store.inspect(
            relativePath: relativePath,
            expectedSha256: expectedDigest,
            expectedMimeType: 'image/jpeg',
            expectedByteSize: expectedBytes.length,
          ),
          ManagedAttachmentIntegrity.healthy,
        );
        expect(
          await File(
            path.join(targetDirectories.attachments.path, relativePath),
          ).readAsBytes(),
          expectedBytes,
        );
      }
      final restoredFiles = await targetDirectories.attachments
          .list(recursive: true)
          .where((entity) => entity is File)
          .map(
            (entity) => path
                .relative(entity.path, from: targetDirectories.attachments.path)
                .replaceAll('\\', '/'),
          )
          .toList();
      restoredFiles.sort();
      expect(restoredFiles, [_closureLegacyPath, _closureManagedPath]);
    },
  );

  test(
    'wrong password stays generic and stable package tamper fails closed',
    () async {
      final application = _application(directories, gateway: gateway);
      final created = await application.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );

      await expectLater(
        application.preflightBackup(created.package, 'yanlis-parola'),
        _failureCode('wrong_password_or_tampered'),
      );
      final package = File(created.absolutePath);
      final bytes = await package.readAsBytes();
      bytes[bytes.length - 1] ^= 0xff;
      await package.writeAsBytes(bytes, flush: true);
      await expectLater(
        application.preflightBackup(created.package, _password),
        _failureCode('package_changed_after_import'),
      );
    },
  );

  test(
    'changed package after preflight is rejected before active mutation',
    () async {
      final application = _application(directories, gateway: gateway);
      final created = await application.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );
      final preflight = await application.preflightBackup(
        created.package,
        _password,
      );
      final package = File(created.absolutePath);
      final original = await package.readAsBytes();
      original[original.length - 1] ^= 0xff;
      await package.writeAsBytes(original, flush: true);

      await expectLater(
        application.restoreBackup(
          RestoreMobileBackupCommand(
            package: created.package,
            password: _password,
            expectedPackageSha256: preflight.packageSha256,
          ),
        ),
        _failureCode('package_changed_after_import'),
      );
      expect(await _projectCount(directories), 0);
    },
  );

  test('preflight refuses a package path outside approved app roots', () async {
    final application = _application(directories, gateway: gateway);
    final created = await application.createBackup(
      const CreateMobileBackupCommand(
        password: _password,
        passwordConfirmation: _password,
      ),
    );
    final outside = File(path.join(temporaryRoot.path, 'outside.csebackup'));
    await File(created.absolutePath).copy(outside.path);
    final unsafe = PickedBackupPackage(
      stablePath: outside.path,
      originalFileName: 'outside.csebackup',
      byteSize: created.summary.packageByteSize,
      sha256: created.packageSha256,
      importOperationId: 'outside-import',
    );

    await expectLater(
      application.preflightBackup(unsafe, _password),
      _failureCode('unsafe_package_source'),
    );
    expect(await outside.exists(), isTrue);
  });

  test(
    'post-swap failure rolls the prior database and attachments back',
    () async {
      await _seedFullFixture(directories, [3, 1, 4, 1, 5]);
      final before = await _fixtureSnapshot(directories);
      final creator = _application(directories, gateway: gateway);
      final created = await creator.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );
      final active = await _openRaw(directories);
      await active.update(
        'projects',
        {'name': 'Rollbackta korunacak aktif değer'},
        where: 'id = ?',
        whereArgs: ['project-1'],
      );
      await active.close();
      final afterBackup = await _fixtureSnapshot(directories);
      expect(afterBackup, isNot(before));
      final failing = _application(
        directories,
        gateway: gateway,
        hooks: MobileRestoreHooks(
          afterSwapBeforeSmoke: () async => throw StateError('injected'),
        ),
      );
      final preflight = await failing.preflightBackup(
        created.package,
        _password,
      );

      await expectLater(
        failing.restoreBackup(
          RestoreMobileBackupCommand(
            package: created.package,
            password: _password,
            expectedPackageSha256: preflight.packageSha256,
          ),
        ),
        _failureCode('restore_activation_failed'),
      );

      expect(await _fixtureSnapshot(directories), afterBackup);
      expect(
        await directories.staging.list().toList(),
        isEmpty,
        reason: 'successful rollback must clean staging',
      );
    },
  );

  for (final schemaVersion in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) {
    test(
      'schema v$schemaVersion package migrates to current schema without count loss',
      () async {
        final oldRoot = await Directory.systemTemp.createTemp(
          'cse_schema${schemaVersion}_',
        );
        addTearDown(() async {
          if (await oldRoot.exists()) await oldRoot.delete(recursive: true);
        });
        final oldFile = path.join(oldRoot.path, 'old.sqlite3');
        final oldDatabase = AppDatabase(
          path: oldFile,
          factory: databaseFactoryFfi,
          clock: () => DateTime.parse(_now),
          migrations: AppDatabase.foundationMigrations
              .take(schemaVersion)
              .toList(),
        );
        await oldDatabase.open();
        await SmokeRecordRepository(
          database: oldDatabase,
          clock: () => DateTime.parse(_now),
        ).ensureFoundationRecord();
        await _seedLegacySchema(oldDatabase.database, schemaVersion);
        if (schemaVersion == 12) {
          await oldDatabase.database.insert('concrete_attachments', {
            'id': 'legacy-archived-concrete-attachment',
            'concrete_pour_id': 'legacy-pour',
            'evidence_type': 'site_photo',
            'original_file_name': 'archived-missing.bin',
            'mime_type': 'application/octet-stream',
            'byte_size': 3,
            'sha256': sha256.convert(const <int>[3, 2, 1]).toString(),
            'relative_path': 'concrete/archived-missing.bin',
            'captured_at': _now,
            'created_at': _now,
            'archived_at': _now,
          });
        }
        await oldDatabase.close();
        final databaseBytes = await File(oldFile).readAsBytes();
        const legacyAgendaBytes = <int>[0xff, 0xd8, 0xff, 0xd9];
        const legacyConcreteBytes = <int>[7, 8, 9];
        final attachmentBytes = schemaVersion >= 10
            ? <String, List<int>>{
                'agenda/legacy.jpg': legacyAgendaBytes,
                'concrete/legacy.bin': legacyConcreteBytes,
              }
            : const <String, List<int>>{};
        final attachmentManifest = attachmentBytes.entries
            .map(
              (entry) => BackupManifestFile(
                logicalPath: entry.key,
                byteSize: entry.value.length,
                sha256: sha256.convert(entry.value).toString(),
              ),
            )
            .toList();
        final archive = const CseBackupArchiveCodec().encode(
          manifest: _manifest(
            databaseBytes,
            schemaVersion: schemaVersion,
            attachments: attachmentManifest,
          ),
          databaseBytes: databaseBytes,
          attachments: attachmentBytes,
        );
        final package = File(path.join(oldRoot.path, 'old.csebackup'));
        await package.writeAsBytes(
          await _testEncryptionCodec().encrypt(archive, _password),
          flush: true,
        );
        final imported = await _stageIncomingPackage(directories, package);
        final application = _application(directories, gateway: gateway);
        final preflight = await application.preflightBackup(
          imported,
          _password,
        );

        await application.restoreBackup(
          RestoreMobileBackupCommand(
            package: imported,
            password: _password,
            expectedPackageSha256: preflight.packageSha256,
          ),
        );

        expect(preflight.manifest.mobileSchemaVersion, schemaVersion);
        expect(preflight.migratedSchemaVersion, AppDatabase.schemaVersion);
        final counts = await _tableCounts(directories);
        final hasAgenda = schemaVersion >= 2 ? 1 : 0;
        final hasAttendance = schemaVersion >= 4 ? 1 : 0;
        expect(counts['projects'], hasAgenda);
        expect(counts['field_observations'], hasAgenda);
        expect(counts['observation_events'], hasAgenda);
        expect(counts['follow_up_items'], hasAgenda);
        expect(
          counts['follow_up_events'],
          hasAgenda + (schemaVersion == 7 ? 1 : 0),
        );
        expect(counts['reminder_notification_bindings'], hasAgenda);
        expect(counts['subcontractors'], hasAttendance);
        expect(counts['workforce_teams'], hasAttendance);
        expect(counts['workforce_members'], hasAttendance);
        expect(counts['workforce_compliance_records'], 0);
        expect(counts['workforce_ppe_assignments'], 0);
        expect(counts['attendance_days'], hasAttendance);
        expect(counts['attendance_entries'], hasAttendance);
        expect(counts['attendance_events'], hasAttendance);
        final hasConcrete = schemaVersion >= 10 ? 1 : 0;
        expect(counts['concrete_pours'], hasConcrete);
        expect(counts['project_concrete_classes'], hasConcrete);
        expect(counts['project_concrete_class_events'], hasConcrete);
        expect(counts['concrete_pour_context_links'], hasConcrete);
        expect(counts['concrete_pour_events'], hasConcrete);
        final attachmentCount = hasConcrete * 2 + (schemaVersion == 12 ? 1 : 0);
        expect(counts['managed_attachments'], attachmentCount);
        expect(counts['attachment_links'], attachmentCount);
        expect(counts['attachment_link_events'], attachmentCount);
        expect(counts['project_locations'], 0);
        expect(counts['project_events'], 0);
        expect(counts['project_location_events'], 0);
        if (schemaVersion == 11) {
          final restored = await _openRaw(directories);
          final subcontractor = (await restored.query('subcontractors')).single;
          final member = (await restored.query('workforce_members')).single;
          expect([
            subcontractor['address'],
            subcontractor['specialty'],
            subcontractor['started_on'],
            subcontractor['ended_on'],
            member['address'],
            member['started_on'],
          ], everyElement(isNull));
          expect(subcontractor['id'], 'legacy-subcontractor');
          expect(member['id'], 'legacy-worker');
          expect(
            (await restored.query(
              'attendance_entries',
            )).single['workforce_member_id'],
            member['id'],
          );
          await restored.close();
        }
        if (schemaVersion == 12) {
          final restored = await _openRaw(directories);
          final archived = (await restored.query(
            'attachment_links',
            where: 'legacy_id = ?',
            whereArgs: ['legacy-archived-concrete-attachment'],
          )).single;
          expect(archived['legacy_source'], 'concrete_attachments');
          expect(archived['archived_at'], _now);
          await restored.close();
        }
        if (schemaVersion == 7) {
          final restored = await _openRaw(directories);
          final legacyReminder = (await restored.query(
            'follow_up_items',
            where: 'id = ?',
            whereArgs: ['legacy-reminder'],
          )).single;
          expect(legacyReminder['item_type'], 'action');
          expect(legacyReminder['status'], 'active');
          expect(legacyReminder['next_attention_at'], '2026-07-20T06:00:00Z');
          expect(legacyReminder['revision'], 1);
          expect(legacyReminder['all_day_local_date'], isNull);
          expect(
            await restored.query(
              'follow_up_events',
              where: "event_type = 'legacy_waiting_normalized'",
            ),
            hasLength(1),
          );
          final binding = (await restored.query(
            'reminder_notification_bindings',
            where: 'reminder_id = ?',
            whereArgs: ['legacy-reminder'],
          )).single;
          expect(binding['platform_notification_id'], 191);
          expect(binding['scheduled_for'], '2026-07-20T06:00:00Z');
          await restored.close();
        }
        if (schemaVersion == 8) {
          final restored = await _openRaw(directories);
          expect(
            (await restored.query(
              'follow_up_items',
              where: 'id = ?',
              whereArgs: ['legacy-reminder'],
            )).single['trashed_at'],
            isNull,
          );
          await restored.close();
        }
        if (schemaVersion >= 10) {
          final restored = await _openRaw(directories);
          final observation = (await restored.query(
            'field_observations',
            where: 'id = ?',
            whereArgs: ['legacy-observation'],
          )).single;
          final reminder = (await restored.query(
            'follow_up_items',
            where: 'id = ?',
            whereArgs: ['legacy-reminder'],
          )).single;
          final pour = (await restored.query(
            'concrete_pours',
            where: 'id = ?',
            whereArgs: ['legacy-pour'],
          )).single;
          expect(observation['location'], ' Eski Mahal / 3. Kat ');
          expect(reminder['location'], 'Hatırlatıcı Mahal');
          expect(pour['element_location'], 'Eski temel elemanı');
          expect(pour['block_name'], 'Eski Blok');
          expect(pour['floor_name'], 'Eski Kat');
          expect(pour['axis_name'], 'A/1');
          expect(observation['location_id'], isNull);
          expect(reminder['location_id'], isNull);
          expect(pour['location_id'], isNull);
          expect(
            await File(
              path.join(directories.attachments.path, 'agenda/legacy.jpg'),
            ).readAsBytes(),
            legacyAgendaBytes,
          );
          expect(
            await File(
              path.join(directories.attachments.path, 'concrete/legacy.bin'),
            ).readAsBytes(),
            legacyConcreteBytes,
          );
          expect(await restored.rawQuery('PRAGMA foreign_key_check'), isEmpty);
          await restored.close();
        }
        expect(await directories.staging.list().toList(), isEmpty);
      },
    );
  }

  test('unknown newer schema is rejected before active mutation', () async {
    final activeProjectCount = await _projectCount(directories);
    final packageRoot = await Directory.systemTemp.createTemp(
      'cse_future_schema_',
    );
    addTearDown(() async {
      if (await packageRoot.exists()) {
        await packageRoot.delete(recursive: true);
      }
    });
    final databaseBytes = await File(directories.databaseFile).readAsBytes();
    final archive = const CseBackupArchiveCodec().encode(
      manifest: _manifest(
        databaseBytes,
        schemaVersion: AppDatabase.schemaVersion + 1,
      ),
      databaseBytes: databaseBytes,
      attachments: const {},
    );
    final package = File(path.join(packageRoot.path, 'future.csebackup'));
    await package.writeAsBytes(
      await _testEncryptionCodec().encrypt(archive, _password),
      flush: true,
    );
    final imported = await _stageIncomingPackage(directories, package);

    await expectLater(
      _application(
        directories,
        gateway: gateway,
      ).preflightBackup(imported, _password),
      _failureCode('unsupported_schema'),
    );

    expect(await _projectCount(directories), activeProjectCount);
    expect(await File(imported.stablePath).exists(), isTrue);
    expect(
      await directories.staging
          .list()
          .where(
            (entity) =>
                path.normalize(entity.path) !=
                path.normalize(directories.incomingBackups.path),
          )
          .toList(),
      isEmpty,
      reason: 'Başarısız preflight yalnız stable incoming paketi korur.',
    );
  });

  test('archive rejects traversal, absolute, duplicate and extra entries', () {
    final codec = const CseBackupArchiveCodec();
    for (final name in [
      'attachments/../escape.bin',
      'attachments/C:\\escape.bin',
      '/absolute.bin',
      'unexpected.txt',
    ]) {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('manifest.json', [123, 125]))
        ..addFile(ArchiveFile.bytes('database.sqlite3', [1]))
        ..addFile(ArchiveFile.bytes(name, [2]));
      expect(
        () => codec.decode(ZipEncoder().encode(archive)),
        throwsA(isA<MobileBackupFailure>()),
        reason: name,
      );
    }
    final duplicateSource = Archive()
      ..addFile(ArchiveFile.bytes('manifest.json', [123, 125]))
      ..addFile(ArchiveFile.bytes('database.sqlite3', [1]))
      ..addFile(ArchiveFile.bytes('duplicate.txt', [2]));
    final duplicate = ZipEncoder().encode(duplicateSource);
    final oldCentralName = utf8.encode('duplicate.txt');
    final centralNameOffset = _lastIndexOf(duplicate, oldCentralName);
    expect(centralNameOffset, greaterThan(0));
    duplicate.setRange(
      centralNameOffset,
      centralNameOffset + oldCentralName.length,
      utf8.encode('manifest.json'),
    );
    expect(() => codec.decode(duplicate), _failureCode('duplicate_entry'));
    final portableCollision = Archive()
      ..addFile(ArchiveFile.bytes('manifest.json', [123, 125]))
      ..addFile(ArchiveFile.bytes('MANIFEST.JSON', [123, 125]))
      ..addFile(ArchiveFile.bytes('database.sqlite3', [1]));
    expect(
      () => codec.decode(ZipEncoder().encode(portableCollision)),
      _failureCode('duplicate_entry'),
    );
  });

  test('manifest hash and duplicate logical attachment fail closed', () {
    const databaseBytes = <int>[1, 2, 3];
    final wrongHashManifest = MobileBackupManifest(
      formatVersion: 1,
      appVersion: '0.1.0',
      buildNumber: '1',
      mobileSchemaVersion: 6,
      createdAtUtc: _now,
      database: const BackupManifestFile(
        logicalPath: 'database.sqlite3',
        byteSize: 3,
        sha256:
            '0000000000000000000000000000000000000000000000000000000000000000',
      ),
      attachments: const [],
    );
    final codec = const CseBackupArchiveCodec();
    expect(
      () => codec.decode(
        codec.encode(
          manifest: wrongHashManifest,
          databaseBytes: databaseBytes,
          attachments: const {},
        ),
      ),
      _failureCode('hash_mismatch'),
    );

    final attachmentBytes = <int>[4, 5, 6];
    final attachment = BackupManifestFile(
      logicalPath: 'concrete/pour/evidence.bin',
      byteSize: attachmentBytes.length,
      sha256: sha256.convert(attachmentBytes).toString(),
    );
    final duplicateManifest = MobileBackupManifest(
      formatVersion: 1,
      appVersion: '0.1.0',
      buildNumber: '1',
      mobileSchemaVersion: 6,
      createdAtUtc: _now,
      database: BackupManifestFile(
        logicalPath: 'database.sqlite3',
        byteSize: databaseBytes.length,
        sha256: sha256.convert(databaseBytes).toString(),
      ),
      attachments: [attachment, attachment],
    );
    expect(
      () => codec.decode(
        codec.encode(
          manifest: duplicateManifest,
          databaseBytes: databaseBytes,
          attachments: {'concrete/pour/evidence.bin': attachmentBytes},
        ),
      ),
      _failureCode('duplicate_entry'),
    );
  });

  test('entry and total expanded size ceilings fail closed', () {
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('manifest.json', [123, 125]))
      ..addFile(ArchiveFile.bytes('database.sqlite3', [1, 2, 3]));
    final encoded = ZipEncoder().encode(archive);

    expect(
      () => const CseBackupArchiveCodec(maximumEntryBytes: 2).decode(encoded),
      _failureCode('oversize_entry'),
    );
    expect(
      () =>
          const CseBackupArchiveCodec(maximumExpandedBytes: 3).decode(encoded),
      _failureCode('oversize_package'),
    );
  });

  test(
    'corrupt SQLite and foreign-key violations fail during preflight',
    () async {
      final packageRoot = await Directory.systemTemp.createTemp('cse_bad_db_');
      addTearDown(() async {
        if (await packageRoot.exists()) {
          await packageRoot.delete(recursive: true);
        }
      });
      final corruptPackage = File(
        path.join(packageRoot.path, 'corrupt.csebackup'),
      );
      await _writePackage(corruptPackage, [1, 2, 3, 4]);
      final application = _application(directories, gateway: gateway);
      final importedCorrupt = await _stageIncomingPackage(
        directories,
        corruptPackage,
      );
      await expectLater(
        application.preflightBackup(importedCorrupt, _password),
        _failureCode('corrupt_database'),
      );

      final brokenDatabase = File(path.join(packageRoot.path, 'fk.sqlite3'));
      await File(directories.databaseFile).copy(brokenDatabase.path);
      final raw = await databaseFactoryFfi.openDatabase(
        brokenDatabase.path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await raw.execute('PRAGMA foreign_keys = OFF');
      await raw.insert('field_observations', {
        'id': 'orphan-observation',
        'project_id': 'missing-project',
        'observed_at': _now,
        'created_at': _now,
        'updated_at': _now,
        'category': 'general_note',
        'description': 'Yetim kayıt',
        'revision': 1,
      });
      await raw.close();
      final foreignKeyPackage = File(
        path.join(packageRoot.path, 'foreign-key.csebackup'),
      );
      await _writePackage(
        foreignKeyPackage,
        await brokenDatabase.readAsBytes(),
      );
      final importedForeignKey = await _stageIncomingPackage(
        directories,
        foreignKeyPackage,
      );
      await expectLater(
        application.preflightBackup(importedForeignKey, _password),
        _failureCode('foreign_key_violation'),
      );
    },
  );

  test('missing active attachment prevents partial backup output', () async {
    await _seedFullFixture(directories, [8, 6, 7, 5, 3, 0, 9]);
    final attachment = File(
      path.join(directories.attachments.path, 'concrete/pour-1/evidence.bin'),
    );
    await attachment.delete();
    final application = _application(directories, gateway: gateway);

    await expectLater(
      application.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      ),
      _failureCode('attachment_missing'),
    );
    expect(await directories.exportsBackups.list().toList(), isEmpty);
    expect(await directories.staging.list().toList(), isEmpty);
  });

  test(
    'notification reconciliation failure restores the prior active state',
    () async {
      await _seedFullFixture(directories, [1, 8, 9]);
      final creator = _application(directories, gateway: gateway);
      final created = await creator.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );
      final active = await _openRaw(directories);
      await active.update(
        'projects',
        {'name': 'Uzlaştırma hatasında korunacak'},
        where: 'id = ?',
        whereArgs: ['project-1'],
      );
      await active.close();
      final prior = await _fixtureSnapshot(directories);
      final failing = _application(
        directories,
        gateway: gateway,
        reconcile: () async => throw StateError('notification plugin failure'),
      );
      final preflight = await failing.preflightBackup(
        created.package,
        _password,
      );

      await expectLater(
        failing.restoreBackup(
          RestoreMobileBackupCommand(
            package: created.package,
            password: _password,
            expectedPackageSha256: preflight.packageSha256,
          ),
        ),
        _failureCode('restore_activation_failed'),
      );
      expect(await _fixtureSnapshot(directories), prior);
    },
  );

  test(
    'backup summary never persists password or absolute package path',
    () async {
      final application = _application(directories, gateway: gateway);
      final created = await application.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );

      final state = await File(directories.backupStateFile).readAsString();
      expect(state, isNot(contains(_password)));
      expect(state, isNot(contains(directories.root.path)));
      expect(state, contains(created.summary.fileName));
      expect(created.summary.fileName, isNot(contains('\\')));
      final encrypted = await File(created.absolutePath).readAsBytes();
      final decoded = const CseBackupArchiveCodec().decode(
        await _testEncryptionCodec().decrypt(encrypted, _password),
      );
      final manifestText = decoded.manifest.toJson().toString();
      expect(manifestText, isNot(contains(_password)));
      expect(manifestText, isNot(contains(directories.root.path)));
      expect(decoded.manifest.database.logicalPath, 'database.sqlite3');
    },
  );

  test(
    'password confirmation is validated without creating partial files',
    () async {
      final application = _application(directories, gateway: gateway);

      await expectLater(
        application.createBackup(
          const CreateMobileBackupCommand(
            password: _password,
            passwordConfirmation: 'baska-parola',
          ),
        ),
        _failureCode('password_confirmation_mismatch'),
      );
      expect(await directories.exportsBackups.list().toList(), isEmpty);
      expect(await directories.staging.list().toList(), isEmpty);
    },
  );
}

var _stagedPackageSequence = 0;

Future<PickedBackupPackage> _stageIncomingPackage(
  AppDirectories directories,
  File source,
) async {
  final bytes = await source.readAsBytes();
  final digest = sha256.convert(bytes).toString();
  final operationId =
      'fixture-${_stagedPackageSequence++}-${digest.substring(0, 12)}';
  await directories.incomingBackups.create(recursive: true);
  final destination = File(
    path.join(directories.incomingBackups.path, '$operationId.csebackup'),
  );
  await destination.writeAsBytes(bytes, flush: true);
  return PickedBackupPackage(
    stablePath: destination.path,
    originalFileName: path.basename(source.path),
    byteSize: bytes.length,
    sha256: digest,
    importOperationId: operationId,
  );
}

Future<void> _writePackage(File destination, List<int> databaseBytes) async {
  final archive = const CseBackupArchiveCodec().encode(
    manifest: _manifest(
      databaseBytes,
      schemaVersion: AppDatabase.schemaVersion,
    ),
    databaseBytes: databaseBytes,
    attachments: const {},
  );
  await destination.writeAsBytes(
    await _testEncryptionCodec().encrypt(archive, _password),
    flush: true,
  );
}

SqliteMobileBackupApplication _application(
  AppDirectories directories, {
  required MobileBackupFileGateway gateway,
  Future<void> Function()? reconcile,
  MobileRestoreHooks hooks = const MobileRestoreHooks(),
  MobileOperationCoordinator? coordinator,
  CseBackupCodec? encryptionCodec,
}) => SqliteMobileBackupApplication(
  directories: directories,
  databaseFactory: databaseFactoryFfi,
  clock: () => DateTime.parse(_now),
  coordinator: coordinator ?? MobileOperationCoordinator(),
  fileGateway: gateway,
  notificationReconciler: reconcile ?? () async {},
  encryptionCodec: encryptionCodec ?? _testEncryptionCodec(),
  restoreHooks: hooks,
);

CseBackupCodec _testEncryptionCodec() => CseBackupCodec(
  kdfIterations: 1000,
  minimumAcceptedKdfIterations: 1,
  randomBytes: (length) => Uint8List.fromList(
    List<int>.generate(length, (index) => (index * 17 + length) % 256),
  ),
);

Future<void> _bootstrapDatabase(AppDirectories directories) async {
  final database = AppDatabase(
    path: directories.databaseFile,
    factory: databaseFactoryFfi,
    clock: () => DateTime.parse(_now),
  );
  await database.open();
  await SmokeRecordRepository(
    database: database,
    clock: () => DateTime.parse(_now),
  ).ensureFoundationRecord();
  await database.close();
}

Future<void> _seedAttachmentClosureFixture(
  AppDirectories directories,
  List<int> attachmentBytes,
) async {
  final database = await _openRaw(directories);
  final digest = sha256.convert(attachmentBytes).toString();
  await database.transaction((transaction) async {
    await transaction.insert('projects', {
      'id': 'closure-project',
      'name': 'V2.3 Kapanış Projesi',
      'created_at': _now,
      'updated_at': _now,
      'revision': 1,
    });
    for (final observation in const [
      ('closure-observation-shared', 'Paylaşılan fiziksel dosya'),
      ('closure-observation-legacy', 'Legacy okunabilir dosya'),
    ]) {
      await transaction.insert('field_observations', {
        'id': observation.$1,
        'project_id': 'closure-project',
        'observed_at': _now,
        'created_at': _now,
        'updated_at': _now,
        'category': 'inspection',
        'description': observation.$2,
        'revision': 1,
      });
    }
    await transaction.insert('concrete_pours', {
      'id': 'closure-pour',
      'project_id': 'closure-project',
      'pour_code': 'V23-CLOSURE',
      'element_location': 'Kapanış temel betonu',
      'planned_at': _now,
      'concrete_class': 'C30/37',
      'planned_volume_m3': 10.0,
      'status': 'draft',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    for (final attachment in [
      (_closureManagedAttachmentId, _closureManagedPath),
      (_closureLegacyAttachmentId, _closureLegacyPath),
    ]) {
      await transaction.insert('managed_attachments', {
        'id': attachment.$1,
        'relative_path': attachment.$2,
        'mime_type': 'image/jpeg',
        'byte_size': attachmentBytes.length,
        'sha256': digest,
        'created_at': _now,
      });
    }
    for (final link in const [
      (
        'closure-link-agenda-shared',
        _closureManagedAttachmentId,
        'agenda_observation',
        'closure-observation-shared',
        'paylasilan-saha.jpg',
      ),
      (
        'closure-link-concrete-shared',
        _closureManagedAttachmentId,
        'concrete_pour',
        'closure-pour',
        'paylasilan-beton.jpg',
      ),
      (
        'closure-link-legacy',
        _closureLegacyAttachmentId,
        'agenda_observation',
        'closure-observation-legacy',
        'legacy-saha.jpg',
      ),
    ]) {
      await transaction.insert('attachment_links', {
        'id': link.$1,
        'attachment_id': link.$2,
        'project_id': 'closure-project',
        'source_type': link.$3,
        'source_id': link.$4,
        'role': 'site_photo',
        'original_file_name': link.$5,
        'captured_at': _now,
        'revision': 1,
        'created_at': _now,
        'updated_at': _now,
      });
      await transaction.insert('attachment_link_events', {
        'id': '${link.$1}-event',
        'attachment_link_id': link.$1,
        'sequence': 1,
        'event_type': 'link.created',
        'occurred_at': _now,
        'payload_json': '{}',
      });
    }
  });
  await database.close();
  for (final relativePath in [_closureManagedPath, _closureLegacyPath]) {
    final file = File(path.join(directories.attachments.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(attachmentBytes, flush: true);
  }
}

Future<void> _seedFullFixture(
  AppDirectories directories,
  List<int> attachmentBytes,
) async {
  final database = await _openRaw(directories);
  final attachmentDigest = sha256.convert(attachmentBytes).toString();
  const agendaPhotoBytes = <int>[0xff, 0xd8, 0xff, 0xd9];
  final agendaPhotoDigest = sha256.convert(agendaPhotoBytes).toString();
  await database.transaction((tx) async {
    await tx.insert('projects', {
      'id': 'project-1',
      'name': 'Köprü Şantiyesi',
      'created_at': _now,
      'updated_at': _now,
      'revision': 4,
      'archived_at': _now,
    });
    await tx.insert('project_locations', {
      'id': 'location-parent',
      'project_id': 'project-1',
      'display_name': 'A Blok',
      'normalized_name': 'a blok',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('project_locations', {
      'id': 'location-1',
      'project_id': 'project-1',
      'display_name': 'Güncel Mahal Adı',
      'normalized_name': 'güncel mahal adı',
      'parent_location_id': 'location-parent',
      'revision': 4,
      'created_at': _now,
      'updated_at': _now,
      'archived_at': _now,
    });
    await tx.insert('project_events', {
      'id': 'project-event-1',
      'project_id': 'project-1',
      'sequence': 1,
      'event_type': 'project.renamed',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('project_location_events', {
      'id': 'location-parent-event-1',
      'location_id': 'location-parent',
      'sequence': 1,
      'event_type': 'location.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('project_location_events', {
      'id': 'location-event-1',
      'location_id': 'location-1',
      'sequence': 1,
      'event_type': 'location.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('project_location_events', {
      'id': 'location-event-2',
      'location_id': 'location-1',
      'sequence': 2,
      'event_type': 'location.renamed',
      'occurred_at': _now,
      'payload_json':
          '{"before":{"display_name":"Eski Mahal Adı"},'
          '"after":{"display_name":"Güncel Mahal Adı"}}',
    });
    await tx.insert('project_location_events', {
      'id': 'location-event-3',
      'location_id': 'location-1',
      'sequence': 3,
      'event_type': 'location.archived',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('field_observations', {
      'id': 'observation-1',
      'project_id': 'project-1',
      'observed_at': '2026-07-18T07:00:00Z',
      'created_at': _now,
      'updated_at': _now,
      'category': 'inspection',
      'description': 'Donatı kontrolü tamamlandı.',
      'location': 'A Blok / 1. Kat',
      'location_id': 'location-1',
      'revision': 3,
      'archived_at': _now,
    });
    await tx.insert('observation_events', {
      'id': 'observation-event-1',
      'observation_id': 'observation-1',
      'project_id': 'project-1',
      'event_type': 'observation.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('observation_events', {
      'id': 'observation-event-2',
      'observation_id': 'observation-1',
      'project_id': 'project-1',
      'event_type': 'agenda_log.updated',
      'occurred_at': _now,
      'payload_json':
          '{"before":{"description":"Donatı kontrolü"},'
          '"after":{"description":"Donatı kontrolü tamamlandı."}}',
    });
    await tx.insert('observation_events', {
      'id': 'observation-event-3',
      'observation_id': 'observation-1',
      'project_id': 'project-1',
      'event_type': 'agenda_log.archived',
      'occurred_at': _now,
      'payload_json': '{"linked_reminders_unchanged":true}',
    });
    await tx.insert('field_observations', {
      'id': 'legacy-observation-1',
      'project_id': 'project-1',
      'observed_at': '2026-07-18T08:00:00Z',
      'created_at': _now,
      'updated_at': _now,
      'category': 'inspection',
      'description': 'Legacy text-only gözlem',
      'location': ' Legacy Serbest Mahal ',
      'revision': 1,
    });
    await tx.insert('managed_attachments', {
      'id': 'agenda-attachment-1',
      'relative_path': 'agenda/observation-1/site-photo.jpg',
      'mime_type': 'image/jpeg',
      'byte_size': agendaPhotoBytes.length,
      'sha256': agendaPhotoDigest,
      'created_at': _now,
    });
    await tx.insert('attachment_links', {
      'id': 'agenda-link-1',
      'attachment_id': 'agenda-attachment-1',
      'project_id': 'project-1',
      'source_type': 'agenda_observation',
      'source_id': 'observation-1',
      'role': 'site_photo',
      'original_file_name': 'saha-fotografi.jpg',
      'description': 'Donatı saha fotoğrafı',
      'captured_at': _now,
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('attachment_link_events', {
      'id': 'agenda-link-event-1',
      'attachment_link_id': 'agenda-link-1',
      'sequence': 1,
      'event_type': 'link.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('follow_up_items', {
      'id': 'reminder-1',
      'capture_text': 'Kalıp ekibini ara',
      'title': 'Kalıp ekibini ara',
      'item_type': 'action',
      'status': 'active',
      'project_id': 'project-1',
      'observation_id': 'observation-1',
      'location': 'A Blok / 1. Kat',
      'location_id': 'location-1',
      'is_important': 1,
      'next_attention_at': '2026-07-20T06:00:00Z',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('follow_up_events', {
      'id': 'reminder-event-1',
      'follow_up_id': 'reminder-1',
      'sequence': 1,
      'project_id': 'project-1',
      'source_observation_id': 'observation-1',
      'event_type': 'created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('follow_up_items', {
      'id': 'legacy-reminder-1',
      'capture_text': 'Legacy reminder',
      'title': 'Legacy reminder',
      'item_type': 'action',
      'status': 'inbox',
      'project_id': 'project-1',
      'location': 'Legacy Hatırlatıcı Mahal',
      'is_important': 0,
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('reminder_notification_bindings', {
      'reminder_id': 'reminder-1',
      'platform_notification_id': 189,
      'scheduled_for': '2026-07-20T06:00:00Z',
      'sync_state': 'scheduled',
      'last_synced_at': _now,
    });
    await tx.insert('subcontractors', {
      'id': 'subcontractor-1',
      'project_id': 'project-1',
      'name': 'Ana yüklenici',
      'name_normalized': 'ana yüklenici',
      'address': 'Şantiye firma adresi',
      'specialty': 'Kalıp ve beton',
      'started_on': '2026-07-01',
      'ended_on': '2026-12-31',
      'status': 'active',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('workforce_teams', {
      'id': 'team-1',
      'project_id': 'project-1',
      'subcontractor_id': 'subcontractor-1',
      'name': 'Kalıp',
      'name_normalized': 'kalıp',
      'status': 'active',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('workforce_members', {
      'id': 'worker-1',
      'project_id': 'project-1',
      'subcontractor_id': 'subcontractor-1',
      'team_id': 'team-1',
      'full_name': 'Ayşe Usta',
      'team_name': 'Kalıp',
      'role_name': 'Usta',
      'address': 'Personel saha adresi',
      'started_on': '2026-07-02',
      'is_active': 1,
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('workforce_events', {
      'id': 'workforce-event-1',
      'aggregate_type': 'person',
      'aggregate_id': 'worker-1',
      'project_id': 'project-1',
      'sequence': 1,
      'event_type': 'person.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('workforce_compliance_records', {
      'id': 'compliance-1',
      'workforce_member_id': 'worker-1',
      'document_type': 'health_report',
      'document_number': 'RAPOR-1',
      'issued_date': '2026-07-01',
      'expiry_date': '2027-07-01',
      'source_status': 'valid',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('workforce_ppe_assignments', {
      'id': 'ppe-1',
      'workforce_member_id': 'worker-1',
      'ppe_type': 'Baret',
      'brand_model': 'CSE-01',
      'quantity': 1,
      'assigned_date': '2026-07-19',
      'status': 'assigned',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('attendance_days', {
      'id': 'attendance-1',
      'project_id': 'project-1',
      'local_date': '2026-07-19',
      'status': 'draft',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('attendance_entries', {
      'id': 'attendance-entry-1',
      'attendance_day_id': 'attendance-1',
      'workforce_member_id': 'worker-1',
      'result': 'full_day',
      'overtime_minutes': 60,
      'short_note': 'Gece betonu',
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('attendance_events', {
      'id': 'attendance-event-1',
      'attendance_day_id': 'attendance-1',
      'sequence': 1,
      'event_type': 'attendance_day.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('project_concrete_classes', {
      'id': 'concrete-class-1',
      'project_id': 'project-1',
      'display_name': 'C30/37',
      'normalized_name': 'c30/37',
      'default_target_slump': 'S3',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('project_concrete_class_events', {
      'id': 'concrete-class-event-1',
      'concrete_class_id': 'concrete-class-1',
      'sequence': 1,
      'event_type': 'class.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('concrete_pours', {
      'id': 'pour-1',
      'project_id': 'project-1',
      'pour_code': 'BT-189',
      'element_location': 'A Blok temel',
      'location_id': 'location-1',
      'planned_at': '2026-07-20T05:00:00Z',
      'concrete_class': 'C30/37',
      'planned_volume_m3': 25.0,
      'status': 'draft',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('concrete_pour_context_links', {
      'concrete_pour_id': 'pour-1',
      'project_id': 'project-1',
      'concrete_class_id': 'concrete-class-1',
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('concrete_pour_events', {
      'id': 'pour-event-1',
      'concrete_pour_id': 'pour-1',
      'sequence': 1,
      'event_type': 'pour.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('concrete_pours', {
      'id': 'legacy-pour-1',
      'project_id': 'project-1',
      'pour_code': 'BT-LEGACY',
      'element_location': 'Legacy Beton Elemanı',
      'block_name': 'Legacy Blok',
      'floor_name': 'Legacy Kat',
      'axis_name': 'L/1',
      'planned_at': '2026-07-21T05:00:00Z',
      'concrete_class': 'C25/30',
      'planned_volume_m3': 12.0,
      'status': 'draft',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('managed_attachments', {
      'id': 'attachment-1',
      'relative_path': 'concrete/pour-1/evidence.bin',
      'mime_type': 'application/octet-stream',
      'byte_size': attachmentBytes.length,
      'sha256': attachmentDigest,
      'created_at': _now,
    });
    await tx.insert('attachment_links', {
      'id': 'attachment-link-1',
      'attachment_id': 'attachment-1',
      'project_id': 'project-1',
      'source_type': 'concrete_pour',
      'source_id': 'pour-1',
      'role': 'site_photo',
      'original_file_name': 'kanıt.bin',
      'captured_at': _now,
      'description': 'Taşınabilir ikili kanıt',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('attachment_link_events', {
      'id': 'attachment-link-event-1',
      'attachment_link_id': 'attachment-link-1',
      'sequence': 1,
      'event_type': 'link.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    await tx.insert('attachment_links', {
      'id': 'attachment-link-2',
      'attachment_id': 'attachment-1',
      'project_id': 'project-1',
      'source_type': 'concrete_pour',
      'source_id': 'legacy-pour-1',
      'role': 'site_photo',
      'original_file_name': 'paylaşılan-kanıt.bin',
      'captured_at': _now,
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('attachment_link_events', {
      'id': 'attachment-link-event-2',
      'attachment_link_id': 'attachment-link-2',
      'sequence': 1,
      'event_type': 'link.created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
  });
  await database.close();
  final attachment = File(
    path.join(directories.attachments.path, 'concrete/pour-1/evidence.bin'),
  );
  await attachment.parent.create(recursive: true);
  await attachment.writeAsBytes(attachmentBytes, flush: true);
  final agendaPhoto = File(
    path.join(
      directories.attachments.path,
      'agenda/observation-1/site-photo.jpg',
    ),
  );
  await agendaPhoto.parent.create(recursive: true);
  await agendaPhoto.writeAsBytes(agendaPhotoBytes, flush: true);
}

Future<void> _seedLegacySchema(Database database, int schemaVersion) async {
  if (schemaVersion < 2) return;
  await database.insert('projects', {
    'id': 'legacy-project',
    'name': 'Legacy proje',
    'created_at': _now,
    'updated_at': _now,
    'revision': 1,
  });
  await database.insert('field_observations', {
    'id': 'legacy-observation',
    'project_id': 'legacy-project',
    'observed_at': '2026-07-18T07:00:00Z',
    'created_at': _now,
    'updated_at': _now,
    'category': 'inspection',
    'description': 'Legacy gözlem',
    'location': ' Eski Mahal / 3. Kat ',
    'revision': 1,
  });
  await database.insert('observation_events', {
    'id': 'legacy-observation-event',
    'observation_id': 'legacy-observation',
    'project_id': 'legacy-project',
    'event_type': 'observation.created',
    'occurred_at': _now,
    'payload_json': '{}',
  });
  if (schemaVersion == 2) {
    await database.insert('follow_up_items', {
      'id': 'legacy-reminder',
      'project_id': 'legacy-project',
      'observation_id': 'legacy-observation',
      'title': 'Legacy reminder',
      'item_type': 'action',
      'status': 'active',
      'next_attention_at': '2026-07-20T06:00:00Z',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await database.insert('follow_up_events', {
      'id': 'legacy-reminder-event',
      'follow_up_id': 'legacy-reminder',
      'project_id': 'legacy-project',
      'source_observation_id': 'legacy-observation',
      'event_type': 'created',
      'occurred_at': _now,
      'payload_json': '{}',
    });
    return;
  }
  await database.insert('follow_up_items', {
    'id': 'legacy-reminder',
    'capture_text': 'Legacy reminder',
    'title': 'Legacy reminder',
    'item_type': schemaVersion == 7 ? 'waiting' : 'action',
    'status': schemaVersion == 7 ? 'waiting' : 'active',
    'project_id': 'legacy-project',
    'observation_id': 'legacy-observation',
    'location': 'Hatırlatıcı Mahal',
    'is_important': 1,
    'next_attention_at': '2026-07-20T06:00:00Z',
    'revision': 1,
    'created_at': _now,
    'updated_at': _now,
  });
  await database.insert('follow_up_events', {
    'id': 'legacy-reminder-event',
    'follow_up_id': 'legacy-reminder',
    'sequence': 1,
    'project_id': 'legacy-project',
    'source_observation_id': 'legacy-observation',
    'event_type': 'created',
    'occurred_at': _now,
    'payload_json': '{}',
  });
  await database.insert('reminder_notification_bindings', {
    'reminder_id': 'legacy-reminder',
    'platform_notification_id': 191,
    'scheduled_for': '2026-07-20T06:00:00Z',
    'sync_state': 'scheduled',
    'last_synced_at': _now,
  });
  if (schemaVersion < 4) return;
  if (schemaVersion >= 6) {
    await database.insert('subcontractors', {
      'id': 'legacy-subcontractor',
      'project_id': 'legacy-project',
      'name': 'Legacy taşeron',
      'name_normalized': 'legacy taşeron',
      'status': 'active',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await database.insert('workforce_teams', {
      'id': 'legacy-team',
      'project_id': 'legacy-project',
      'subcontractor_id': 'legacy-subcontractor',
      'name': 'Legacy ekip',
      'name_normalized': 'legacy ekip',
      'status': 'active',
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
  }
  await database.insert('workforce_members', {
    'id': 'legacy-worker',
    'project_id': 'legacy-project',
    if (schemaVersion >= 6) ...{
      'subcontractor_id': 'legacy-subcontractor',
      'team_id': 'legacy-team',
    },
    'full_name': 'Legacy çalışan',
    'team_name': 'Legacy ekip',
    'role_name': 'Usta',
    'is_active': 1,
    'revision': 1,
    'created_at': _now,
    'updated_at': _now,
  });
  await database.insert('attendance_days', {
    'id': 'legacy-attendance',
    'project_id': 'legacy-project',
    'local_date': '2026-07-19',
    'status': 'draft',
    'revision': 1,
    'created_at': _now,
    'updated_at': _now,
  });
  await database.insert('attendance_entries', {
    'id': 'legacy-attendance-entry',
    'attendance_day_id': 'legacy-attendance',
    'workforce_member_id': 'legacy-worker',
    'result': 'full_day',
    'overtime_minutes': 30,
    'created_at': _now,
    'updated_at': _now,
  });
  await database.insert('attendance_events', {
    'id': 'legacy-attendance-event',
    'attendance_day_id': 'legacy-attendance',
    'sequence': 1,
    'event_type': 'attendance_day.created',
    'occurred_at': _now,
    'payload_json': '{}',
  });
  if (schemaVersion < 10) return;

  const legacyAgendaBytes = <int>[0xff, 0xd8, 0xff, 0xd9];
  const legacyConcreteBytes = <int>[7, 8, 9];
  await database.insert('project_concrete_classes', {
    'id': 'legacy-concrete-class',
    'project_id': 'legacy-project',
    'display_name': 'C30/37',
    'normalized_name': 'c30/37',
    'revision': 1,
    'created_at': _now,
    'updated_at': _now,
  });
  await database.insert('project_concrete_class_events', {
    'id': 'legacy-concrete-class-event',
    'concrete_class_id': 'legacy-concrete-class',
    'sequence': 1,
    'event_type': 'class.created',
    'occurred_at': _now,
    'payload_json': '{}',
  });
  await database.insert('concrete_pours', {
    'id': 'legacy-pour',
    'project_id': 'legacy-project',
    'pour_code': 'BT-LEGACY',
    'element_location': 'Eski temel elemanı',
    'block_name': 'Eski Blok',
    'floor_name': 'Eski Kat',
    'axis_name': 'A/1',
    'planned_at': '2026-07-20T05:00:00Z',
    'concrete_class': 'C30/37',
    'planned_volume_m3': 12.0,
    'status': 'draft',
    'revision': 3,
    'created_at': _now,
    'updated_at': _now,
  });
  await database.insert('concrete_pour_context_links', {
    'concrete_pour_id': 'legacy-pour',
    'project_id': 'legacy-project',
    'concrete_class_id': 'legacy-concrete-class',
    'created_at': _now,
    'updated_at': _now,
  });
  await database.insert('concrete_pour_events', {
    'id': 'legacy-pour-event',
    'concrete_pour_id': 'legacy-pour',
    'sequence': 1,
    'event_type': 'pour.created',
    'occurred_at': _now,
    'payload_json': '{}',
  });
  await database.insert('agenda_log_attachments', {
    'id': 'legacy-agenda-attachment',
    'observation_id': 'legacy-observation',
    'project_id': 'legacy-project',
    'attachment_type': 'site_photo',
    'original_file_name': 'legacy.jpg',
    'mime_type': 'image/jpeg',
    'byte_size': legacyAgendaBytes.length,
    'sha256': sha256.convert(legacyAgendaBytes).toString(),
    'relative_path': 'agenda/legacy.jpg',
    'revision': 1,
    'created_at': _now,
    'updated_at': _now,
  });
  await database.insert('concrete_attachments', {
    'id': 'legacy-concrete-attachment',
    'concrete_pour_id': 'legacy-pour',
    'evidence_type': 'site_photo',
    'original_file_name': 'legacy.bin',
    'mime_type': 'application/octet-stream',
    'byte_size': legacyConcreteBytes.length,
    'sha256': sha256.convert(legacyConcreteBytes).toString(),
    'relative_path': 'concrete/legacy.bin',
    'captured_at': _now,
    'created_at': _now,
  });
}

Future<Map<String, int>> _tableCounts(AppDirectories directories) async {
  final database = await _openRaw(directories);
  final counts = <String, int>{};
  for (final table in const [
    'projects',
    'project_locations',
    'project_events',
    'project_location_events',
    'field_observations',
    'observation_events',
    'follow_up_items',
    'follow_up_events',
    'reminder_notification_bindings',
    'subcontractors',
    'workforce_teams',
    'workforce_members',
    'workforce_events',
    'workforce_compliance_records',
    'workforce_ppe_assignments',
    'attendance_days',
    'attendance_entries',
    'attendance_events',
    'concrete_pours',
    'project_concrete_classes',
    'project_concrete_class_events',
    'concrete_pour_context_links',
    'concrete_pour_events',
    'managed_attachments',
    'attachment_links',
    'attachment_link_events',
  ]) {
    counts[table] = Sqflite.firstIntValue(
      await database.rawQuery('SELECT count(*) FROM $table'),
    )!;
  }
  await database.close();
  return counts;
}

Future<Map<String, Object?>> _fixtureSnapshot(
  AppDirectories directories,
) async {
  final database = await _openRaw(directories);
  final result = <String, Object?>{};
  for (final table in const [
    'projects',
    'project_locations',
    'project_events',
    'project_location_events',
    'field_observations',
    'observation_events',
    'follow_up_items',
    'follow_up_events',
    'reminder_notification_bindings',
    'subcontractors',
    'workforce_teams',
    'workforce_members',
    'workforce_events',
    'workforce_compliance_records',
    'workforce_ppe_assignments',
    'attendance_days',
    'attendance_entries',
    'attendance_events',
    'concrete_pours',
    'project_concrete_classes',
    'project_concrete_class_events',
    'concrete_pour_context_links',
    'concrete_pour_events',
    'managed_attachments',
    'attachment_links',
    'attachment_link_events',
  ]) {
    result[table] = await database.query(table, orderBy: 'rowid ASC');
  }
  await database.close();
  return result;
}

Future<void> _expectV21LocationFixture(AppDirectories directories) async {
  final database = await _openRaw(directories);
  final project = (await database.query(
    'projects',
    where: 'id = ?',
    whereArgs: ['project-1'],
  )).single;
  expect(project['revision'], 4);
  expect(project['archived_at'], _now);

  final parent = (await database.query(
    'project_locations',
    where: 'id = ?',
    whereArgs: ['location-parent'],
  )).single;
  expect(parent['project_id'], 'project-1');
  expect(parent['parent_location_id'], isNull);
  expect(parent['display_name'], 'A Blok');

  final location = (await database.query(
    'project_locations',
    where: 'id = ?',
    whereArgs: ['location-1'],
  )).single;
  expect(location['project_id'], 'project-1');
  expect(location['parent_location_id'], 'location-parent');
  expect(location['display_name'], 'Güncel Mahal Adı');
  expect(location['normalized_name'], 'güncel mahal adı');
  expect(location['revision'], 4);
  expect(location['archived_at'], _now);
  expect(
    await database.query(
      'project_location_events',
      where: 'location_id = ?',
      whereArgs: ['location-1'],
      orderBy: 'sequence ASC',
    ),
    hasLength(3),
  );

  for (final expected in const [
    ('field_observations', 'observation-1', 'location', 'A Blok / 1. Kat'),
    ('follow_up_items', 'reminder-1', 'location', 'A Blok / 1. Kat'),
    ('concrete_pours', 'pour-1', 'element_location', 'A Blok temel'),
  ]) {
    final row = (await database.query(
      expected.$1,
      where: 'id = ?',
      whereArgs: [expected.$2],
    )).single;
    expect(row['location_id'], 'location-1', reason: expected.$1);
    expect(row[expected.$3], expected.$4, reason: expected.$1);
  }

  for (final expected in const [
    (
      'field_observations',
      'legacy-observation-1',
      'location',
      ' Legacy Serbest Mahal ',
    ),
    (
      'follow_up_items',
      'legacy-reminder-1',
      'location',
      'Legacy Hatırlatıcı Mahal',
    ),
    (
      'concrete_pours',
      'legacy-pour-1',
      'element_location',
      'Legacy Beton Elemanı',
    ),
  ]) {
    final row = (await database.query(
      expected.$1,
      where: 'id = ?',
      whereArgs: [expected.$2],
    )).single;
    expect(row['location_id'], isNull, reason: expected.$1);
    expect(row[expected.$3], expected.$4, reason: expected.$1);
  }
  final legacyPour = (await database.query(
    'concrete_pours',
    where: 'id = ?',
    whereArgs: ['legacy-pour-1'],
  )).single;
  expect(legacyPour['block_name'], 'Legacy Blok');
  expect(legacyPour['floor_name'], 'Legacy Kat');
  expect(legacyPour['axis_name'], 'L/1');
  expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  await database.close();
}

Future<Database> _openRaw(AppDirectories directories) =>
    databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: OpenDatabaseOptions(
        singleInstance: false,
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    );

Future<int> _projectCount(AppDirectories directories) async {
  final database = await _openRaw(directories);
  final count = Sqflite.firstIntValue(
    await database.rawQuery('SELECT count(*) FROM projects'),
  )!;
  await database.close();
  return count;
}

_BackupScheduleScenario _backupScheduleScenario() {
  final profile = validConstructionProjectProfile(
    overrides: {
      'project_id': 'PRJ-BACKUP-SCHEDULE',
      'calendar': <String, Object?>{
        'start_date': '2026-09-04',
        'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
        'holidays': <Object?>['2026-09-07'],
        'workday_hours': 8,
      },
    },
  );
  const activityId = 'ACT-BACKUP';
  const instanceId = '$activityId@PROJECT';
  const nextActivityId = 'ACT-BACKUP-NEXT';
  const nextInstanceId = '$nextActivityId@PROJECT';
  final activity = ConstructionActivity(
    activityId: activityId,
    wbsCode: 'TEST',
    packageId: 'TEST',
    activityNameTr: 'Backup milestone',
    aliasesTr: const ['backup'],
    applicability: const ConstructionAlwaysRule(),
    repeatDimension: ConstructionActivityRepeatDimension.project,
    naturalUnit: 'TEST',
    durationStatus: 'UNKNOWN',
    durationConfidence: 'E_UNKNOWN',
    testSeedDurationDays: 0,
    sequenceConfidence: 'TEST',
    sequenceIndex: 1,
  );
  final nextActivity = ConstructionActivity(
    activityId: nextActivityId,
    wbsCode: 'TEST',
    packageId: 'TEST',
    activityNameTr: 'Backup follow-up',
    aliasesTr: const ['backup follow-up'],
    applicability: const ConstructionAlwaysRule(),
    repeatDimension: ConstructionActivityRepeatDimension.project,
    naturalUnit: 'TEST',
    durationStatus: 'SOURCE_BACKED',
    durationConfidence: 'A_AUTHORITATIVE',
    testSeedDurationDays: 2,
    sequenceConfidence: 'TEST',
    sequenceIndex: 2,
  );
  final corpus = ConstructionCorpus(
    metadata: const ConstructionCorpusMetadata(
      name: 'BACKUP LIVING PLAN TEST CORPUS',
      corpusVersion: '0.3-yfk-resource-seed',
      sourcePublicationStatus: 'RESEARCH_RESOURCE_SEED',
      sourceProductionStatus: 'NOT_FOR_PRODUCTION',
      warning: 'test',
      runtimeScope: 'ACTIVITY_CATALOG_READ_ONLY_NO_YFK_RESOURCE_COEFFICIENTS',
      wbsCount: 1,
      activityCount: 2,
    ),
    profileFields: const <String>[],
    wbsPackages: const [
      ConstructionWbsPackage(
        wbsCode: 'TEST',
        packageId: 'TEST',
        packageNameTr: 'Test',
        packageNameEn: 'Test',
        frequencyClass: 'TEST',
      ),
    ],
    activities: [activity, nextActivity],
  );
  final graph = ConstructionProjectActivityGraph(
    projectId: profile.projectId,
    activityInstances: const [
      ConstructionProjectActivityInstance(
        instanceId: instanceId,
        activityId: activityId,
        wbsCode: 'TEST',
        packageId: 'TEST',
        activityNameTr: 'Backup milestone',
        repeatDimension: ConstructionActivityRepeatDimension.project,
        context: ConstructionProjectActivityContext(),
        naturalUnit: 'TEST',
        durationStatus: 'UNKNOWN',
        durationConfidence: 'E_UNKNOWN',
        testSeedDurationDays: 0,
      ),
      ConstructionProjectActivityInstance(
        instanceId: nextInstanceId,
        activityId: nextActivityId,
        wbsCode: 'TEST',
        packageId: 'TEST',
        activityNameTr: 'Backup follow-up',
        repeatDimension: ConstructionActivityRepeatDimension.project,
        context: ConstructionProjectActivityContext(),
        naturalUnit: 'TEST',
        durationStatus: 'SOURCE_BACKED',
        durationConfidence: 'A_AUTHORITATIVE',
        testSeedDurationDays: 2,
      ),
    ],
    dependencyEdges: const [
      ConstructionResolvedDependencyEdge(
        edgeKey: 'EDGE-BACKUP-0',
        templateDependencyId: 'DEP-BACKUP-0',
        predecessorInstanceId: instanceId,
        successorInstanceId: nextInstanceId,
        relationshipType: ConstructionDependencyRelationshipType.finishToStart,
        lagValue: 0,
        lagUnit: ConstructionDependencyLagUnit.workingDay,
        scopeRule: ConstructionDependencyScopeRule.project,
        isMandatory: true,
        confidence: ConstructionDependencyConfidence.supportedInference,
        reviewStatus: ConstructionDependencyReviewStatus.reviewRequired,
      ),
    ],
    isolatedInstanceIds: const [],
    corpusVersion: '0.3-yfk-resource-seed',
    selectedActivityTemplateCount: 2,
    selectedDependencyTemplateCount: 1,
  );
  final catalog = ConstructionScheduleSeedCatalog(
    metadata: const ConstructionScheduleSeedCatalogMetadata(
      name: 'BACKUP SNAPSHOT TEST SEEDS',
      corpusVersion: '0.3-yfk-resource-seed',
      sourcePublicationStatus: 'RESEARCH_RESOURCE_SEED',
      sourceProductionStatus: 'NOT_FOR_PRODUCTION',
      sourceZipSha256: 'test',
      warning: 'test',
      runtimeScope: 'SCHEDULE_SEED_CATALOG_READ_ONLY_NOT_A_BASELINE',
      activityCount: 2,
      workingDayCount: 2,
      calendarDayCount: 0,
      milestoneCount: 1,
      authoritativeCount: 1,
      aiSeedCount: 0,
      unknownConfidenceCount: 1,
      sourceBackedCount: 1,
      aiSeedEstimateCount: 0,
      unknownStatusCount: 1,
    ),
    seeds: [
      ConstructionScheduleSeed(
        activityId: activityId,
        durationDays: 0,
        durationCalendarType:
            ConstructionActivityDurationCalendarType.workingDay,
        durationStatus: ConstructionScheduleDurationStatus.unknown,
        durationConfidence: ConstructionScheduleDurationConfidence.unknown,
      ),
      ConstructionScheduleSeed(
        activityId: nextActivityId,
        durationDays: 2,
        durationCalendarType:
            ConstructionActivityDurationCalendarType.workingDay,
        durationStatus: ConstructionScheduleDurationStatus.sourceBacked,
        durationConfidence:
            ConstructionScheduleDurationConfidence.authoritative,
      ),
    ],
  );
  final schedule = ConstructionScheduleDateEngine().build(
    profile: profile,
    graph: graph,
    seedCatalog: catalog,
  );
  return _BackupScheduleScenario(profile, corpus, graph, catalog, schedule);
}

List<Map<String, Object?>> _backupActivityProjection(
  Iterable<ConstructionScheduledActivity> activities,
) => [
  for (final item in activities)
    {
      'instance_id': item.instanceId,
      'activity_id': item.activityId,
      'start_date': formatCanonicalConstructionDate(item.startDate),
      'finish_date': formatCanonicalConstructionDate(item.finishDate),
      'duration_days': item.durationDays,
      'rounded_scheduling_days': item.roundedSchedulingDays,
      'duration_calendar_type': item.durationCalendarType.jsonValue,
      'duration_status': item.durationStatus.jsonValue,
      'duration_confidence': item.durationConfidence.jsonValue,
      'is_milestone': item.isMilestone,
      'is_isolated': item.isIsolated,
    },
];

class _BackupScheduleScenario {
  const _BackupScheduleScenario(
    this.profile,
    this.corpus,
    this.graph,
    this.catalog,
    this.schedule,
  );

  final ConstructionProjectProfile profile;
  final ConstructionCorpus corpus;
  final ConstructionProjectActivityGraph graph;
  final ConstructionScheduleSeedCatalog catalog;
  final ConstructionProjectReferenceSchedule schedule;
}

MobileBackupManifest _manifest(
  List<int> databaseBytes, {
  required int schemaVersion,
  List<BackupManifestFile> attachments = const [],
}) => MobileBackupManifest(
  formatVersion: 1,
  appVersion: '0.1.0',
  buildNumber: '1',
  mobileSchemaVersion: schemaVersion,
  createdAtUtc: _now,
  database: BackupManifestFile(
    logicalPath: 'database.sqlite3',
    byteSize: databaseBytes.length,
    sha256: sha256.convert(databaseBytes).toString(),
  ),
  attachments: attachments,
);

Matcher _failureCode(String code) => throwsA(
  isA<MobileBackupFailure>().having((failure) => failure.code, 'code', code),
);

int _lastIndexOf(List<int> bytes, List<int> needle) {
  for (var start = bytes.length - needle.length; start >= 0; start -= 1) {
    var matches = true;
    for (var index = 0; index < needle.length; index += 1) {
      if (bytes[start + index] != needle[index]) {
        matches = false;
        break;
      }
    }
    if (matches) return start;
  }
  return -1;
}

class _FakeFileGateway implements MobileBackupFileGateway {
  _FakeFileGateway(this.directories);

  final AppDirectories directories;
  PickedBackupPackage? pickedPackage;
  String? sharedPath;

  @override
  Future<PickedBackupPackage?> pickPackage() async => pickedPackage;

  @override
  Future<void> cleanupPickedPackage(PickedBackupPackage package) async {
    final incomingRoot = path.normalize(
      path.absolute(directories.incomingBackups.path),
    );
    final candidate = path.normalize(path.absolute(package.stablePath));
    if (path.dirname(candidate) != incomingRoot) return;
    final file = File(candidate);
    if (await file.exists()) await file.delete();
    if (await directories.incomingBackups.exists() &&
        await directories.incomingBackups.list().isEmpty) {
      await directories.incomingBackups.delete();
    }
  }

  @override
  Future<void> reconcileIncomingPackages() async {}

  @override
  Future<void> sharePackage(String absolutePath) async {
    sharedPath = absolutePath;
  }
}

class _BlockingEncryptionCodec extends CseBackupCodec {
  _BlockingEncryptionCodec()
    : super(
        kdfIterations: 1000,
        minimumAcceptedKdfIterations: 1,
        randomBytes: (length) => Uint8List(length),
      );

  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<Uint8List> encrypt(List<int> clearBytes, String password) async {
    entered.complete();
    await release.future;
    return super.encrypt(clearBytes, password);
  }
}
