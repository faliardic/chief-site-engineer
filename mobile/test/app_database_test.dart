import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:chief_site_engineer/storage/smoke_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;
  final firstClock = DateTime.utc(2026, 7, 19, 8);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_mobile_db_');
    directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    await directories.ensureCreated();
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('migration history and smoke record survive database restart', () async {
    final first = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
    );
    await first.open();
    final firstRecord = await SmokeRecordRepository(
      database: first,
      clock: () => firstClock,
    ).ensureFoundationRecord();
    await first.close();

    final restarted = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
    );
    await restarted.open();
    final restartedRecord = await SmokeRecordRepository(
      database: restarted,
      clock: () => DateTime.utc(2026, 7, 19, 9),
    ).ensureFoundationRecord();
    final history = await restarted.database.query('schema_versions');
    await restarted.close();

    expect(firstRecord.id, SmokeRecordRepository.foundationRecordId);
    expect(restartedRecord.createdAt, firstRecord.createdAt);
    expect(history, [
      {'version': 1, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 2, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 3, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 4, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 5, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 6, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 7, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 8, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 9, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 10, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 11, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 12, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 13, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 14, 'applied_at': '2026-07-19T08:00:00Z'},
      {'version': 15, 'applied_at': '2026-07-19T08:00:00Z'},
    ]);
  });

  test(
    'schema 13 to 14 is additive and enforces schedule snapshot integrity',
    () async {
      final schemaThirteen = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(13).toList(),
      );
      await schemaThirteen.open();
      await schemaThirteen.database.insert('projects', {
        'id': 'schedule-project',
        'name': 'Korunan proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await schemaThirteen.database.insert('projects', {
        'id': 'other-project',
        'name': 'Diğer proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      final existingSchema = await schemaThirteen.database.rawQuery('''
        SELECT type, name, tbl_name, sql
        FROM sqlite_master
        WHERE sql IS NOT NULL
        ORDER BY type, name
      ''');
      final existingProjects = await schemaThirteen.database.query(
        'projects',
        orderBy: 'id ASC',
      );
      await schemaThirteen.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
        migrations: AppDatabase.foundationMigrations.take(14).toList(),
      );
      await upgraded.open();
      final db = upgraded.database;
      final newNames = <String>{
        'project_schedule_snapshots',
        'project_schedule_snapshot_activities',
        'project_schedule_snapshots_one_current',
        'project_schedule_snapshots_history',
        'project_schedule_snapshot_activities_window',
        'project_schedule_snapshot_activities_immutable_update',
        'project_schedule_snapshot_activities_immutable_delete',
        'project_schedule_snapshots_no_physical_delete',
        'project_schedule_snapshots_supersede_only',
      };
      final afterSchema = await db.rawQuery('''
        SELECT type, name, tbl_name, sql
        FROM sqlite_master
        WHERE sql IS NOT NULL
        ORDER BY type, name
      ''');
      expect(
        afterSchema.where((row) => !newNames.contains(row['name'])).toList(),
        existingSchema,
      );
      expect(await db.query('projects', orderBy: 'id ASC'), existingProjects);
      expect(
        sqflite.Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')),
        14,
      );
      expect(
        afterSchema
            .where((row) => newNames.contains(row['name']))
            .map((row) => row['name'])
            .toSet(),
        newNames,
      );

      Map<String, Object?> snapshotRow(String id) => {
        'id': id,
        'project_id': 'schedule-project',
        'profile_json': '{}',
        'corpus_version': 'corpus-v1',
        'schedule_seed_version': 'seed-v1',
        'schedule_seed_provenance': 'seed-catalog',
        'production_status': 'NOT_FOR_PRODUCTION',
        'duration_source': 'TEST_SEED_ONLY',
        'baseline_status': 'NOT_A_BASELINE',
        'schedule_start': '2026-09-01',
        'schedule_finish': '2026-09-01',
        'activity_count': 1,
        'root_count': 1,
        'leaf_count': 1,
        'isolated_count': 1,
        'milestone_count': 1,
        'projection_sha256': '0' * 64,
        'generated_at': '2026-07-19T09:00:00Z',
      };

      await expectLater(
        db.insert('project_schedule_snapshots', {
          ...snapshotRow('snapshot-noncanonical-generated'),
          'generated_at': '2026-07-19T09:00:00.000Z',
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      for (final invalidGeneratedAt in const [
        '2026-13-19T09:00:00Z',
        '2026-07-19T25:00:00Z',
      ]) {
        await expectLater(
          db.insert('project_schedule_snapshots', {
            ...snapshotRow('snapshot-impossible-generated'),
            'generated_at': invalidGeneratedAt,
          }),
          throwsA(isA<sqflite.DatabaseException>()),
        );
      }
      await db.insert('project_schedule_snapshots', snapshotRow('snapshot-1'));
      await expectLater(
        db.insert('project_schedule_snapshots', snapshotRow('snapshot-2')),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await db.insert('project_schedule_snapshot_activities', {
        'snapshot_id': 'snapshot-1',
        'project_id': 'schedule-project',
        'instance_id': 'instance-1',
        'activity_id': 'activity-1',
        'start_date': '2026-09-01',
        'finish_date': '2026-09-01',
        'duration_days': 0.0,
        'rounded_scheduling_days': 0,
        'duration_calendar_type': 'WORKING_DAY',
        'duration_status': 'UNKNOWN',
        'duration_confidence': 'E_UNKNOWN',
        'is_milestone': 1,
        'is_isolated': 1,
        'row_sha256': '1' * 64,
      });
      await expectLater(
        db.insert('project_schedule_snapshot_activities', {
          'snapshot_id': 'snapshot-1',
          'project_id': 'schedule-project',
          'instance_id': 'invalid-row-seal',
          'activity_id': 'activity-1',
          'start_date': '2026-09-01',
          'finish_date': '2026-09-01',
          'duration_days': 0.0,
          'rounded_scheduling_days': 0,
          'duration_calendar_type': 'WORKING_DAY',
          'duration_status': 'UNKNOWN',
          'duration_confidence': 'E_UNKNOWN',
          'is_milestone': 1,
          'is_isolated': 1,
          'row_sha256': 'A' * 64,
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.update('project_schedule_snapshot_activities', {
          'activity_id': 'changed',
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.delete('project_schedule_snapshot_activities'),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.update(
          'project_schedule_snapshots',
          {'superseded_at': '2026-07-19T10:00:00.000Z'},
          where: 'id = ?',
          whereArgs: ['snapshot-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.update(
          'project_schedule_snapshots',
          {'superseded_at': '2026-07-19T08:59:59Z'},
          where: 'id = ?',
          whereArgs: ['snapshot-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      for (final invalidSupersededAt in const [
        '2026-13-19T10:00:00Z',
        '2026-07-19T25:00:00Z',
      ]) {
        await expectLater(
          db.update(
            'project_schedule_snapshots',
            {'superseded_at': invalidSupersededAt},
            where: 'id = ?',
            whereArgs: ['snapshot-1'],
          ),
          throwsA(isA<sqflite.DatabaseException>()),
        );
      }
      await expectLater(
        db.update(
          'project_schedule_snapshots',
          {'corpus_version': 'changed'},
          where: 'id = ?',
          whereArgs: ['snapshot-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      expect(
        await db.update(
          'project_schedule_snapshots',
          {'superseded_at': '2026-07-19T10:00:00Z'},
          where: 'id = ?',
          whereArgs: ['snapshot-1'],
        ),
        1,
      );
      await expectLater(
        db.update(
          'project_schedule_snapshots',
          {'superseded_at': null},
          where: 'id = ?',
          whereArgs: ['snapshot-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.delete(
          'project_schedule_snapshots',
          where: 'id = ?',
          whereArgs: ['snapshot-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await db.insert('project_schedule_snapshots', snapshotRow('snapshot-2'));
      await expectLater(
        db.insert('project_schedule_snapshot_activities', {
          'snapshot_id': 'snapshot-2',
          'project_id': 'other-project',
          'instance_id': 'cross-project',
          'activity_id': 'activity-1',
          'start_date': '2026-09-01',
          'finish_date': '2026-09-01',
          'duration_days': 0.0,
          'rounded_scheduling_days': 0,
          'duration_calendar_type': 'WORKING_DAY',
          'duration_status': 'UNKNOWN',
          'duration_confidence': 'E_UNKNOWN',
          'is_milestone': 1,
          'is_isolated': 1,
          'row_sha256': '2' * 64,
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect(
        (await db.rawQuery('PRAGMA integrity_check')).single['integrity_check'],
        'ok',
      );
      await upgraded.close();
    },
  );

  test(
    'schema 14 to 15 is additive and guards living plan projection history',
    () async {
      final schemaFourteen = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(14).toList(),
      );
      await schemaFourteen.open();
      final old = schemaFourteen.database;
      await old.insert('projects', {
        'id': 'living-project',
        'name': 'Korunan yaşayan plan projesi',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await old.insert('projects', {
        'id': 'other-living-project',
        'name': 'Diğer proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await old.insert('project_schedule_snapshots', {
        'id': 'living-snapshot-a',
        'project_id': 'living-project',
        'profile_json': '{}',
        'corpus_version': 'corpus-v1',
        'schedule_seed_version': 'seed-v1',
        'schedule_seed_provenance': 'seed-catalog',
        'production_status': 'NOT_FOR_PRODUCTION',
        'duration_source': 'TEST_SEED_ONLY',
        'baseline_status': 'NOT_A_BASELINE',
        'schedule_start': '2026-09-01',
        'schedule_finish': '2026-09-02',
        'activity_count': 7,
        'root_count': 1,
        'leaf_count': 1,
        'isolated_count': 1,
        'milestone_count': 0,
        'projection_sha256': '0' * 64,
        'generated_at': '2026-07-19T08:00:00Z',
      });
      await old.insert('project_schedule_snapshot_activities', {
        'snapshot_id': 'living-snapshot-a',
        'project_id': 'living-project',
        'instance_id': 'ACT-1@PROJECT',
        'activity_id': 'ACT-1',
        'start_date': '2026-09-01',
        'finish_date': '2026-09-02',
        'duration_days': 2.0,
        'rounded_scheduling_days': 2,
        'duration_calendar_type': 'WORKING_DAY',
        'duration_status': 'UNKNOWN',
        'duration_confidence': 'E_UNKNOWN',
        'is_milestone': 0,
        'is_isolated': 1,
        'row_sha256': '1' * 64,
      });
      for (var index = 0; index < 6; index += 1) {
        await old.insert('project_schedule_snapshot_activities', {
          'snapshot_id': 'living-snapshot-a',
          'project_id': 'living-project',
          'instance_id': 'ACT-INVALID-$index@PROJECT',
          'activity_id': 'ACT-INVALID-$index',
          'start_date': '2026-09-01',
          'finish_date': '2026-09-02',
          'duration_days': 2.0,
          'rounded_scheduling_days': 2,
          'duration_calendar_type': 'WORKING_DAY',
          'duration_status': 'UNKNOWN',
          'duration_confidence': 'E_UNKNOWN',
          'is_milestone': 0,
          'is_isolated': 1,
          'row_sha256': '${index + 2}' * 64,
        });
      }
      final oldSchema = await old.rawQuery('''
        SELECT type, name, tbl_name, sql
        FROM sqlite_master
        WHERE sql IS NOT NULL
        ORDER BY type, name
      ''');
      final oldProjects = await old.query('projects', orderBy: 'id ASC');
      final oldSnapshots = await old.query('project_schedule_snapshots');
      final oldActivities = await old.query(
        'project_schedule_snapshot_activities',
      );
      await schemaFourteen.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      final db = upgraded.database;
      const newNames = <String>{
        'project_schedule_snapshot_activities_living_plan_ref',
        'project_living_plan_items',
        'project_living_plan_command_receipts',
        'project_living_plan_events',
        'project_living_plan_items_window',
        'project_living_plan_items_reference',
        'project_living_plan_command_receipts_item',
        'project_living_plan_events_history',
        'project_living_plan_command_receipts_result_match',
        'project_living_plan_command_receipts_append_only_update',
        'project_living_plan_command_receipts_append_only_delete',
        'project_living_plan_items_guarded_update',
        'project_living_plan_items_no_physical_delete',
        'project_living_plan_events_revision_match',
        'project_living_plan_events_append_only_update',
        'project_living_plan_events_append_only_delete',
      };
      final newSchema = await db.rawQuery('''
        SELECT type, name, tbl_name, sql
        FROM sqlite_master
        WHERE sql IS NOT NULL
        ORDER BY type, name
      ''');
      expect(
        newSchema.where((row) => !newNames.contains(row['name'])).toList(),
        oldSchema,
      );
      expect(
        newSchema
            .where((row) => newNames.contains(row['name']))
            .map((row) => row['name'])
            .toSet(),
        newNames,
      );
      expect(await db.query('projects', orderBy: 'id ASC'), oldProjects);
      expect(await db.query('project_schedule_snapshots'), oldSnapshots);
      expect(
        await db.query('project_schedule_snapshot_activities'),
        oldActivities,
      );
      expect(
        sqflite.Sqflite.firstIntValue(await db.rawQuery('PRAGMA user_version')),
        15,
      );

      Map<String, Object?> livingRow({
        String id = 'living-item-1',
        String instanceId = 'ACT-1@PROJECT',
        String activityId = 'ACT-1',
        String projectId = 'living-project',
        String snapshotId = 'living-snapshot-a',
        String plannedDate = '2026-09-03',
        String status = 'PLANNED',
        String? note = 'Kalıp ekibi teyit edildi',
        String createdAt = '2026-07-19T09:00:00Z',
        String updatedAt = '2026-07-19T09:00:00Z',
        String statusChangedAt = '2026-07-19T09:00:00Z',
        int revision = 1,
      }) => <String, Object?>{
        'id': id,
        'project_id': projectId,
        'reference_snapshot_id': snapshotId,
        'activity_instance_id': instanceId,
        'activity_id': activityId,
        'activity_name_snapshot': 'Temel kalıbı',
        'activity_context_json': '{}',
        'natural_unit_snapshot': 'm²',
        'planned_date': plannedDate,
        'status': status,
        'note': note,
        'revision': revision,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'status_changed_at': statusChangedAt,
      };

      String receiptResult(Map<String, Object?> item) => jsonEncode({
        'activity_context_json': item['activity_context_json'],
        'activity_id': item['activity_id'],
        'activity_instance_id': item['activity_instance_id'],
        'activity_name_snapshot': item['activity_name_snapshot'],
        'created_at': item['created_at'],
        'id': item['id'],
        'natural_unit_snapshot': item['natural_unit_snapshot'],
        'note': item['note'],
        'planned_date': item['planned_date'],
        'project_id': item['project_id'],
        'reference_snapshot_id': item['reference_snapshot_id'],
        'revision': item['revision'],
        'status': item['status'],
        'status_changed_at': item['status_changed_at'],
        'updated_at': item['updated_at'],
      });

      Map<String, Object?> receiptRow({
        required String id,
        required Map<String, Object?> item,
        required String eventType,
        required bool isNoOp,
        int? eventSequence,
        Map<String, Object?> intent = const {'operation': 'TEST'},
      }) => <String, Object?>{
        'id': id,
        'living_plan_item_id': item['id'],
        'project_id': item['project_id'],
        'event_type': eventType,
        'intent_json': jsonEncode(intent),
        'result_json': receiptResult(item),
        'result_revision': item['revision'],
        'is_no_op': isNoOp ? 1 : 0,
        'event_sequence': eventSequence,
      };

      final initialLiving = livingRow();
      await db.insert('project_living_plan_items', initialLiving);
      await db.insert(
        'project_living_plan_command_receipts',
        receiptRow(
          id: 'living-event-1',
          item: initialLiving,
          eventType: 'CREATED',
          isNoOp: false,
          eventSequence: 1,
        ),
      );
      await db.insert('project_living_plan_events', {
        'id': 'living-event-1',
        'living_plan_item_id': 'living-item-1',
        'project_id': 'living-project',
        'sequence': 1,
        'event_type': 'CREATED',
        'occurred_at': '2026-07-19T09:00:00Z',
        'payload_json': '{}',
      });
      await db.insert(
        'project_living_plan_command_receipts',
        receiptRow(
          id: 'living-no-op-1',
          item: initialLiving,
          eventType: 'STARTED',
          isNoOp: true,
          intent: const {'expected_revision': 1, 'operation': 'STARTED'},
        ),
      );

      for (final invalid in <Map<String, Object?>>[
        livingRow(
          id: 'invalid-date',
          instanceId: 'ACT-INVALID-0@PROJECT',
          activityId: 'ACT-INVALID-0',
          plannedDate: '2026-02-30',
        ),
        livingRow(
          id: 'invalid-status',
          instanceId: 'ACT-INVALID-1@PROJECT',
          activityId: 'ACT-INVALID-1',
          status: 'ACTIVE',
        ),
        livingRow(
          id: 'invalid-note',
          instanceId: 'ACT-INVALID-2@PROJECT',
          activityId: 'ACT-INVALID-2',
          note: ' note ',
        ),
        livingRow(
          id: 'invalid-created',
          instanceId: 'ACT-INVALID-3@PROJECT',
          activityId: 'ACT-INVALID-3',
          createdAt: '2026-13-19T09:00:00Z',
        ),
        livingRow(
          id: 'invalid-order',
          instanceId: 'ACT-INVALID-4@PROJECT',
          activityId: 'ACT-INVALID-4',
          createdAt: '2026-07-19T09:00:01Z',
          updatedAt: '2026-07-19T09:00:00Z',
        ),
        livingRow(
          id: 'invalid-status-time',
          instanceId: 'ACT-INVALID-5@PROJECT',
          activityId: 'ACT-INVALID-5',
          statusChangedAt: '2026-07-19T09:00:01Z',
        ),
        livingRow(id: 'invalid-reference', snapshotId: 'missing-snapshot'),
        livingRow(
          id: 'cross-project-reference',
          projectId: 'other-living-project',
        ),
      ]) {
        await expectLater(
          db.insert('project_living_plan_items', invalid),
          throwsA(isA<sqflite.DatabaseException>()),
        );
      }
      await expectLater(
        db.insert(
          'project_living_plan_items',
          livingRow(id: 'duplicate-instance'),
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.update(
          'project_living_plan_items',
          {
            'activity_name_snapshot': 'Değiştirilemez',
            'revision': 2,
            'updated_at': '2026-07-19T09:00:01Z',
          },
          where: 'id = ?',
          whereArgs: ['living-item-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.update(
          'project_living_plan_items',
          {'planned_date': '2026-09-04'},
          where: 'id = ?',
          whereArgs: ['living-item-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.delete(
          'project_living_plan_items',
          where: 'id = ?',
          whereArgs: ['living-item-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.update(
          'project_living_plan_command_receipts',
          {'intent_json': '{"operation":"CHANGED"}'},
          where: 'id = ?',
          whereArgs: ['living-no-op-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.delete(
          'project_living_plan_command_receipts',
          where: 'id = ?',
          whereArgs: ['living-no-op-1'],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      final mismatchedReceipt =
          receiptRow(
              id: 'living-receipt-result-mismatch',
              item: initialLiving,
              eventType: 'STARTED',
              isNoOp: true,
            )
            ..['result_json'] = receiptResult({
              ...initialLiving,
              'status': 'STARTED',
            });
      await expectLater(
        db.insert('project_living_plan_command_receipts', mismatchedReceipt),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.insert('project_living_plan_events', {
          'id': 'living-event-sequence-mismatch',
          'living_plan_item_id': 'living-item-1',
          'project_id': 'living-project',
          'sequence': 2,
          'event_type': 'STARTED',
          'occurred_at': '2026-07-19T09:00:01Z',
          'payload_json': '{}',
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      expect(
        await db.update(
          'project_living_plan_items',
          {
            'planned_date': '2026-09-03',
            'status': 'STARTED',
            'note': 'Kalıp ekibi teyit edildi',
            'revision': 2,
            'updated_at': '2026-07-19T09:00:01Z',
            'status_changed_at': '2026-07-19T09:00:01Z',
          },
          where: 'id = ? AND revision = 1',
          whereArgs: ['living-item-1'],
        ),
        1,
      );
      final startedLiving = livingRow(
        status: 'STARTED',
        revision: 2,
        updatedAt: '2026-07-19T09:00:01Z',
        statusChangedAt: '2026-07-19T09:00:01Z',
      );
      await db.insert(
        'project_living_plan_command_receipts',
        receiptRow(
          id: 'living-event-2',
          item: startedLiving,
          eventType: 'STARTED',
          isNoOp: false,
          eventSequence: 2,
          intent: const {'expected_revision': 1, 'operation': 'STARTED'},
        ),
      );
      await db.insert('project_living_plan_events', {
        'id': 'living-event-2',
        'living_plan_item_id': 'living-item-1',
        'project_id': 'living-project',
        'sequence': 2,
        'event_type': 'STARTED',
        'occurred_at': '2026-07-19T09:00:01Z',
        'payload_json': '{}',
      });

      final secondInitial = livingRow(
        id: 'living-item-2',
        instanceId: 'ACT-INVALID-0@PROJECT',
        activityId: 'ACT-INVALID-0',
      );
      await db.insert('project_living_plan_items', secondInitial);
      await db.insert(
        'project_living_plan_command_receipts',
        receiptRow(
          id: 'living-item-2-event-1',
          item: secondInitial,
          eventType: 'CREATED',
          isNoOp: false,
          eventSequence: 1,
        ),
      );
      await db.insert('project_living_plan_events', {
        'id': 'living-item-2-event-1',
        'living_plan_item_id': 'living-item-2',
        'project_id': 'living-project',
        'sequence': 1,
        'event_type': 'CREATED',
        'occurred_at': '2026-07-19T09:00:00Z',
        'payload_json': '{}',
      });
      expect(
        await db.update(
          'project_living_plan_items',
          {
            'planned_date': '2026-09-03',
            'status': 'STARTED',
            'note': 'Kalıp ekibi teyit edildi',
            'revision': 2,
            'updated_at': '2026-07-19T09:00:02Z',
            'status_changed_at': '2026-07-19T09:00:02Z',
          },
          where: 'id = ? AND revision = 1',
          whereArgs: ['living-item-2'],
        ),
        1,
      );
      final secondStarted = livingRow(
        id: 'living-item-2',
        instanceId: 'ACT-INVALID-0@PROJECT',
        activityId: 'ACT-INVALID-0',
        status: 'STARTED',
        revision: 2,
        updatedAt: '2026-07-19T09:00:02Z',
        statusChangedAt: '2026-07-19T09:00:02Z',
      );
      await expectLater(
        db.insert('project_living_plan_events', {
          'id': 'living-no-op-1',
          'living_plan_item_id': 'living-item-2',
          'project_id': 'living-project',
          'sequence': 2,
          'event_type': 'STARTED',
          'occurred_at': '2026-07-19T09:00:02Z',
          'payload_json': '{}',
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.insert(
          'project_living_plan_command_receipts',
          receiptRow(
            id: 'living-event-1',
            item: secondStarted,
            eventType: 'STARTED',
            isNoOp: true,
          ),
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await db.insert(
        'project_living_plan_command_receipts',
        receiptRow(
          id: 'living-item-2-event-2',
          item: secondStarted,
          eventType: 'STARTED',
          isNoOp: false,
          eventSequence: 2,
        ),
      );
      await db.insert('project_living_plan_events', {
        'id': 'living-item-2-event-2',
        'living_plan_item_id': 'living-item-2',
        'project_id': 'living-project',
        'sequence': 2,
        'event_type': 'STARTED',
        'occurred_at': '2026-07-19T09:00:02Z',
        'payload_json': '{}',
      });
      expect(
        await db.query(
          'project_living_plan_command_receipts',
          where: 'id = ? AND is_no_op = 1 AND event_sequence IS NULL',
          whereArgs: ['living-no-op-1'],
        ),
        hasLength(1),
      );
      await expectLater(
        db.update('project_living_plan_events', {
          'payload_json': '{"changed":true}',
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        db.delete('project_living_plan_events'),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect(
        (await db.rawQuery('PRAGMA integrity_check')).single['integrity_check'],
        'ok',
      );
      await upgraded.close();
    },
  );

  test(
    'schema 11 to 12 is additive atomic and preserves registry identity graph',
    () async {
      final schemaEleven = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(11).toList(),
      );
      await schemaEleven.open();
      final database = schemaEleven.database;
      await database.insert('projects', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Kimliği korunan proje',
        'revision': 3,
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('subcontractors', {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Korunan taşeron',
        'name_normalized': 'korunan taşeron',
        'status': 'active',
        'revision': 4,
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('workforce_teams', {
        'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'subcontractor_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'name': 'Korunan ekip',
        'name_normalized': 'korunan ekip',
        'status': 'active',
        'revision': 2,
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('workforce_members', {
        'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'subcontractor_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'team_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'full_name': 'Korunan kişi',
        'team_name': 'Korunan ekip',
        'role_name': 'Usta',
        'is_active': 0,
        'revision': 5,
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T09:00:00Z',
        'archived_at': '2026-07-19T09:00:00Z',
      });
      await database.insert('workforce_events', {
        'id': 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        'aggregate_type': 'person',
        'aggregate_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'sequence': 1,
        'event_type': 'person.archived',
        'occurred_at': '2026-07-19T09:00:00Z',
        'payload_json': '{}',
      });
      await database.insert('workforce_compliance_records', {
        'id': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        'workforce_member_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'document_type': 'employment_entry',
        'document_number': 'SGK-1',
        'issued_date': '2026-07-01',
        'source_status': 'valid',
        'revision': 2,
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('workforce_ppe_assignments', {
        'id': '11111111-1111-4111-8111-111111111111',
        'workforce_member_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'ppe_type': 'Baret',
        'quantity': 1,
        'assigned_date': '2026-07-01',
        'status': 'assigned',
        'revision': 3,
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_days', {
        'id': '22222222-2222-4222-8222-222222222222',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'local_date': '2026-07-18',
        'status': 'draft',
        'revision': 2,
        'created_at': '2026-07-18T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_entries', {
        'id': '33333333-3333-4333-8333-333333333333',
        'attendance_day_id': '22222222-2222-4222-8222-222222222222',
        'workforce_member_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'result': 'full_day',
        'overtime_minutes': 60,
        'created_at': '2026-07-18T08:00:00Z',
        'updated_at': '2026-07-18T08:00:00Z',
      });
      await database.insert('attendance_events', {
        'id': '44444444-4444-4444-8444-444444444444',
        'attendance_day_id': '22222222-2222-4222-8222-222222222222',
        'sequence': 1,
        'event_type': 'attendance_day.created',
        'occurred_at': '2026-07-18T08:00:00Z',
        'payload_json': '{}',
      });
      await schemaEleven.close();

      final failing = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 10),
        migrations: [
          ...AppDatabase.foundationMigrations.take(11),
          DatabaseMigration(
            version: 12,
            apply: (transaction) async {
              await AppDatabase.foundationMigrations[11].apply(transaction);
              throw StateError('intentional schema 12 failure');
            },
          ),
        ],
      );
      await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
      final afterFailure = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: sqflite.OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await afterFailure.rawQuery('PRAGMA user_version'),
        ),
        11,
      );
      expect(
        (await afterFailure.rawQuery(
          'PRAGMA table_info(subcontractors)',
        )).where((row) => row['name'] == 'address'),
        isEmpty,
      );
      expect(
        (await afterFailure.query('workforce_members')).single['revision'],
        5,
      );
      await afterFailure.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 10),
      );
      await upgraded.open();
      final upgradedDatabase = upgraded.database;
      final subcontractor = (await upgradedDatabase.query(
        'subcontractors',
      )).single;
      final member = (await upgradedDatabase.query('workforce_members')).single;
      expect([
        subcontractor['address'],
        subcontractor['specialty'],
        subcontractor['started_on'],
        subcontractor['ended_on'],
        member['address'],
        member['started_on'],
      ], everyElement(isNull));
      expect(subcontractor['id'], 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
      expect(subcontractor['revision'], 4);
      expect(member['id'], 'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
      expect(member['revision'], 5);
      expect(member['archived_at'], '2026-07-19T09:00:00Z');
      expect(
        (await upgradedDatabase.query(
          'attendance_entries',
        )).single['workforce_member_id'],
        member['id'],
      );
      expect(
        (await upgradedDatabase.query(
          'workforce_compliance_records',
        )).single['workforce_member_id'],
        member['id'],
      );
      expect(
        (await upgradedDatabase.query(
          'workforce_ppe_assignments',
        )).single['workforce_member_id'],
        member['id'],
      );
      expect(await upgradedDatabase.query('workforce_events'), hasLength(1));
      expect(await upgradedDatabase.query('attendance_events'), hasLength(1));
      expect(
        await upgradedDatabase.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      final upgradedSubcontractorColumns = await upgradedDatabase.rawQuery(
        'PRAGMA table_info(subcontractors)',
      );
      final upgradedMemberColumns = await upgradedDatabase.rawQuery(
        'PRAGMA table_info(workforce_members)',
      );
      await upgraded.close();

      final freshPath = '${directories.databaseFile}.fresh';
      final fresh = AppDatabase(
        path: freshPath,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 10),
      );
      await fresh.open();
      expect(
        await fresh.database.rawQuery('PRAGMA table_info(subcontractors)'),
        upgradedSubcontractorColumns,
      );
      expect(
        await fresh.database.rawQuery('PRAGMA table_info(workforce_members)'),
        upgradedMemberColumns,
      );
      await fresh.close();
    },
  );

  test('schema 1 upgrades atomically and preserves its smoke record', () async {
    final versionOne = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: [AppDatabase.foundationMigrations.first],
    );
    await versionOne.open();
    final original = await SmokeRecordRepository(
      database: versionOne,
      clock: () => firstClock,
    ).ensureFoundationRecord();
    await versionOne.close();

    final upgraded = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
    );
    await upgraded.open();
    final persisted = await SmokeRecordRepository(
      database: upgraded,
      clock: () => DateTime.utc(2026, 7, 19, 9),
    ).ensureFoundationRecord();
    final version = sqflite.Sqflite.firstIntValue(
      await upgraded.database.rawQuery('PRAGMA user_version'),
    );
    final tables = await upgraded.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    await upgraded.close();

    expect(version, AppDatabase.schemaVersion);
    expect(persisted.createdAt, original.createdAt);
    expect(
      tables.map((row) => row['name']),
      containsAll([
        'projects',
        'project_events',
        'project_locations',
        'project_location_events',
        'field_observations',
        'observation_events',
        'follow_up_items',
        'follow_up_events',
        'workforce_members',
        'attendance_days',
        'attendance_entries',
        'attendance_events',
        'attendance_reminder_settings',
        'attendance_day_reminder_links',
        'concrete_pours',
        'project_concrete_classes',
        'project_concrete_class_events',
        'concrete_pour_context_links',
        'concrete_check_items',
        'concrete_trucks',
        'concrete_sample_sets',
        'concrete_follow_up_items',
        'managed_attachments',
        'attachment_links',
        'attachment_link_events',
        'concrete_pour_events',
        'subcontractors',
        'workforce_teams',
        'workforce_events',
        'workforce_compliance_records',
        'workforce_ppe_assignments',
      ]),
    );
  });

  test(
    'failed schema 2 upgrade rolls back and preserves schema 1 data',
    () async {
      final versionOne = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: [AppDatabase.foundationMigrations.first],
      );
      await versionOne.open();
      await SmokeRecordRepository(
        database: versionOne,
        clock: () => firstClock,
      ).ensureFoundationRecord();
      await versionOne.close();

      final failing = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
        migrations: [
          AppDatabase.foundationMigrations.first,
          DatabaseMigration(
            version: 2,
            apply: (transaction) async {
              await transaction.execute('CREATE TABLE partial_v2 (id TEXT)');
              throw StateError('intentional v2 failure');
            },
          ),
        ],
      );
      await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final version = sqflite.Sqflite.firstIntValue(
        await raw.rawQuery('PRAGMA user_version'),
      );
      final smokeCount = sqflite.Sqflite.firstIntValue(
        await raw.rawQuery('SELECT COUNT(*) FROM smoke_records'),
      );
      final partialCount = sqflite.Sqflite.firstIntValue(
        await raw.rawQuery(
          "SELECT COUNT(*) FROM sqlite_master WHERE name = 'partial_v2'",
        ),
      );
      await raw.close();

      expect(version, 1);
      expect(smokeCount, 1);
      expect(partialCount, 0);
    },
  );

  test('a failed migration rolls back every partial schema write', () async {
    final database = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: [
        AppDatabase.foundationMigrations.first,
        DatabaseMigration(
          version: 2,
          apply: (transaction) async {
            await transaction.execute(
              'CREATE TABLE partial_write (id INTEGER)',
            );
            throw StateError('intentional migration failure');
          },
        ),
      ],
    );

    await expectLater(database.open(), throwsA(isA<DatabaseOpenFailure>()));

    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    final tables = await raw.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    final version = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('PRAGMA user_version'),
    );
    await raw.close();

    expect(version, 0);
    expect(tables, isEmpty);
  });

  test(
    'schema 2 to 3 upgrade preserves agenda linked reminder and events',
    () async {
      final versionTwo = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(2).toList(),
      );
      await versionTwo.open();
      final database = versionTwo.database;
      await database.insert('projects', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Korunan proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('field_observations', {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'observed_at': '2026-07-19T07:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
        'category': 'general_note',
        'description': 'Korunan Ajanda kaydı',
      });
      await database.insert('follow_up_items', {
        'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'observation_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'title': 'Korunan hatırlatıcı',
        'item_type': 'action',
        'status': 'active',
        'next_attention_at': '2026-07-20T06:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('follow_up_events', {
        'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'follow_up_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'source_observation_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'event_type': 'created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await versionTwo.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      final reminder = (await upgraded.database.query(
        'follow_up_items',
      )).single;
      final event = (await upgraded.database.query('follow_up_events')).single;
      final binding = (await upgraded.database.query(
        'reminder_notification_bindings',
      )).single;
      final observationCount = sqflite.Sqflite.firstIntValue(
        await upgraded.database.rawQuery(
          'SELECT COUNT(*) FROM field_observations',
        ),
      );
      await upgraded.close();

      expect(observationCount, 1);
      expect(reminder['capture_text'], 'Korunan hatırlatıcı');
      expect(
        reminder['observation_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(event['sequence'], 1);
      expect(binding['scheduled_for'], '2026-07-20T06:00:00Z');
      expect(binding['sync_state'], 'unavailable');
      expect(binding['safe_error_code'], 'reconciliation_required');
    },
  );

  test('failed schema 3 upgrade rolls back intact schema 2 data', () async {
    final versionTwo = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(2).toList(),
    );
    await versionTwo.open();
    await versionTwo.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Korunan proje',
      'created_at': '2026-07-19T08:00:00Z',
      'updated_at': '2026-07-19T08:00:00Z',
    });
    await versionTwo.close();

    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(2),
        DatabaseMigration(
          version: 3,
          apply: (transaction) async {
            await transaction.execute('CREATE TABLE partial_v3 (id TEXT)');
            throw StateError('intentional v3 failure');
          },
        ),
      ],
    );
    await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));

    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    final version = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('PRAGMA user_version'),
    );
    final projectCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('SELECT COUNT(*) FROM projects'),
    );
    final partialCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery(
        "SELECT COUNT(*) FROM sqlite_master WHERE name = 'partial_v3'",
      ),
    );
    await raw.close();

    expect(version, 2);
    expect(projectCount, 1);
    expect(partialCount, 0);
  });

  test(
    'schema 3 to 4 preserves agenda reminder notification and events',
    () async {
      final versionThree = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(3).toList(),
      );
      await versionThree.open();
      final database = versionThree.database;
      await database.insert('projects', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Korunan proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('field_observations', {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'observed_at': '2026-07-19T07:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
        'category': 'general_note',
        'description': 'Korunan Ajanda kaydı',
      });
      await database.insert('follow_up_items', {
        'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'capture_text': 'Korunan reminder',
        'title': 'Korunan reminder',
        'item_type': 'action',
        'status': 'active',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'observation_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'next_attention_at': '2026-07-20T06:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('follow_up_events', {
        'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'follow_up_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'sequence': 1,
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'source_observation_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'event_type': 'created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await database.insert('reminder_notification_bindings', {
        'reminder_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'platform_notification_id': 42,
        'scheduled_for': '2026-07-20T06:00:00Z',
        'sync_state': 'scheduled',
        'last_synced_at': '2026-07-19T08:00:00Z',
      });
      await versionThree.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      final reminder = (await upgraded.database.query(
        'follow_up_items',
      )).single;
      final event = (await upgraded.database.query('follow_up_events')).single;
      final binding = (await upgraded.database.query(
        'reminder_notification_bindings',
      )).single;
      final tables = await upgraded.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
      );
      await upgraded.close();

      expect(
        reminder['observation_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(reminder['attendance_day_id'], isNull);
      expect(
        event['source_observation_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(event['source_attendance_day_id'], isNull);
      expect(binding['platform_notification_id'], 42);
      expect(
        tables.map((row) => row['name']),
        containsAll([
          'workforce_members',
          'attendance_days',
          'attendance_entries',
          'attendance_events',
          'attendance_reminder_settings',
          'attendance_day_reminder_links',
        ]),
      );
    },
  );

  test('failed schema 4 upgrade rolls back intact schema 3 data', () async {
    final versionThree = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(3).toList(),
    );
    await versionThree.open();
    await versionThree.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Korunan proje',
      'created_at': '2026-07-19T08:00:00Z',
      'updated_at': '2026-07-19T08:00:00Z',
    });
    await versionThree.close();

    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(3),
        DatabaseMigration(
          version: 4,
          apply: (transaction) async {
            await transaction.execute('CREATE TABLE partial_v4 (id TEXT)');
            throw StateError('intentional v4 failure');
          },
        ),
      ],
    );
    await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));

    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    final version = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('PRAGMA user_version'),
    );
    final projectCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('SELECT COUNT(*) FROM projects'),
    );
    final partialCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery(
        "SELECT COUNT(*) FROM sqlite_master WHERE name = 'partial_v4'",
      ),
    );
    await raw.close();

    expect(version, 3);
    expect(projectCount, 1);
    expect(partialCount, 0);
  });

  test(
    'schema 4 to 5 preserves agenda attendance reminders notifications and events',
    () async {
      final versionFour = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(4).toList(),
      );
      await versionFour.open();
      final database = versionFour.database;
      await database.insert('projects', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Korunan proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_days', {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'local_date': '2026-07-19',
        'status': 'draft',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_events', {
        'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'attendance_day_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'sequence': 1,
        'event_type': 'attendance_day.created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await database.insert('follow_up_items', {
        'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'capture_text': 'Korunan Puantaj reminder',
        'title': 'Korunan Puantaj reminder',
        'item_type': 'action',
        'status': 'active',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'attendance_day_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'next_attention_at': '2026-07-19T14:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('follow_up_events', {
        'id': 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        'follow_up_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'sequence': 1,
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'source_attendance_day_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'event_type': 'created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await database.insert('reminder_notification_bindings', {
        'reminder_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'platform_notification_id': 187,
        'scheduled_for': '2026-07-19T14:00:00Z',
        'sync_state': 'scheduled',
        'last_synced_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_day_reminder_links', {
        'attendance_day_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'reminder_id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'due_at': '2026-07-19T14:00:00Z',
        'created_at': '2026-07-19T08:00:00Z',
      });
      await versionFour.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      final reminder = (await upgraded.database.query(
        'follow_up_items',
      )).single;
      final event = (await upgraded.database.query('follow_up_events')).single;
      final binding = (await upgraded.database.query(
        'reminder_notification_bindings',
      )).single;
      final link = (await upgraded.database.query(
        'attendance_day_reminder_links',
      )).single;
      final foreignKeys = await upgraded.database.rawQuery(
        "PRAGMA foreign_key_list('concrete_follow_up_items')",
      );
      await upgraded.close();

      expect(
        reminder['attendance_day_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(reminder['concrete_pour_id'], isNull);
      expect(
        event['source_attendance_day_id'],
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(event['source_concrete_pour_id'], isNull);
      expect(binding['platform_notification_id'], 187);
      expect(link['reminder_id'], 'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
      expect(
        foreignKeys.map((row) => row['table']),
        contains('follow_up_items'),
      );
    },
  );

  test('failed schema 5 upgrade rolls back intact schema 4 data', () async {
    final versionFour = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(4).toList(),
    );
    await versionFour.open();
    await versionFour.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Korunan proje',
      'created_at': '2026-07-19T08:00:00Z',
      'updated_at': '2026-07-19T08:00:00Z',
    });
    await versionFour.close();

    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(4),
        DatabaseMigration(
          version: 5,
          apply: (transaction) async {
            await transaction.execute('CREATE TABLE partial_v5 (id TEXT)');
            throw StateError('intentional v5 failure');
          },
        ),
      ],
    );
    await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));

    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    final version = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('PRAGMA user_version'),
    );
    final projectCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery('SELECT count(*) FROM projects'),
    );
    final partialCount = sqflite.Sqflite.firstIntValue(
      await raw.rawQuery(
        "SELECT count(*) FROM sqlite_master WHERE name = 'partial_v5'",
      ),
    );
    await raw.close();
    expect(version, 4);
    expect(projectCount, 1);
    expect(partialCount, 0);
  });

  test(
    'schema 5 to 6 maps legacy teams atomically and preserves exact history',
    () async {
      final versionFive = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(5).toList(),
      );
      await versionFive.open();
      final database = versionFive.database;
      await database.insert('projects', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Korunan proje',
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      for (final value in const [
        ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1', ' Kalıp '),
        ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2', 'kalıp'),
        ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3', ''),
      ]) {
        await database.insert('workforce_members', {
          'id': value.$1,
          'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'full_name': 'Korunan ${value.$1.substring(value.$1.length - 1)}',
          'team_name': value.$2,
          'role_name': 'Usta',
          'is_active': 1,
          'revision': 1,
          'created_at': '2026-07-19T08:00:00Z',
          'updated_at': '2026-07-19T08:00:00Z',
        });
      }
      await database.insert('attendance_days', {
        'id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'local_date': '2026-07-18',
        'status': 'draft',
        'revision': 1,
        'created_at': '2026-07-18T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await database.insert('attendance_entries', {
        'id': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        'attendance_day_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'workforce_member_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
        'result': 'full_day',
        'overtime_minutes': 60,
        'created_at': '2026-07-18T08:00:00Z',
        'updated_at': '2026-07-18T08:00:00Z',
      });
      await database.update(
        'attendance_days',
        {
          'status': 'completed',
          'revision': 2,
          'updated_at': '2026-07-19T08:00:00Z',
          'completed_at': '2026-07-19T08:00:00Z',
        },
        where: 'id = ?',
        whereArgs: ['cccccccc-cccc-4ccc-8ccc-cccccccccccc'],
      );
      await database.insert('attendance_events', {
        'id': 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
        'attendance_day_id': 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        'sequence': 1,
        'event_type': 'attendance_day.created',
        'occurred_at': '2026-07-18T08:00:00Z',
        'payload_json': '{}',
      });
      await versionFive.close();

      final failing = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
        migrations: [
          ...AppDatabase.foundationMigrations.take(5),
          DatabaseMigration(
            version: 6,
            apply: (transaction) async {
              await AppDatabase.foundationMigrations[5].apply(transaction);
              throw StateError('intentional schema 6 failure');
            },
          ),
        ],
      );
      await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
      final afterFailure = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await afterFailure.rawQuery('PRAGMA user_version'),
        ),
        5,
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await afterFailure.rawQuery(
            "SELECT count(*) FROM sqlite_master WHERE name = 'subcontractors'",
          ),
        ),
        0,
      );
      expect(await afterFailure.query('workforce_members'), hasLength(3));
      await afterFailure.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      final subcontractors = await upgraded.database.query(
        'subcontractors',
        orderBy: 'name_normalized ASC',
      );
      final teams = await upgraded.database.query(
        'workforce_teams',
        orderBy: 'name_normalized ASC',
      );
      final members = await upgraded.database.query(
        'workforce_members',
        orderBy: 'id ASC',
      );
      final entry = (await upgraded.database.query(
        'attendance_entries',
      )).single;
      final attendanceEvent = (await upgraded.database.query(
        'attendance_events',
      )).single;
      final workforceEvents = await upgraded.database.query('workforce_events');

      expect(subcontractors, hasLength(2));
      expect(teams, hasLength(2));
      expect(
        subcontractors.map((row) => row['name']),
        containsAll(['Kalıp', 'Tanımsız ekip']),
      );
      expect(members.map((row) => row['id']), [
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3',
      ]);
      expect(members.every((row) => row['team_id'] != null), isTrue);
      expect(members[0]['team_id'], members[1]['team_id']);
      expect(entry['workforce_member_id'], members.first['id']);
      expect(entry['overtime_minutes'], 60);
      expect(attendanceEvent['id'], 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee');
      expect(workforceEvents, hasLength(7));

      await expectLater(
        upgraded.database.update(
          'workforce_events',
          {'payload_json': '{"changed":true}'},
          where: 'id = ?',
          whereArgs: [workforceEvents.first['id']],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        upgraded.database.delete(
          'subcontractors',
          where: 'id = ?',
          whereArgs: [subcontractors.first['id']],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        upgraded.database.insert('subcontractors', {
          'id': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
          'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'name': 'KALIP',
          'name_normalized': 'kalıp',
          'status': 'active',
          'revision': 1,
          'created_at': '2026-07-19T09:00:00Z',
          'updated_at': '2026-07-19T09:00:00Z',
        }),
        throwsA(isA<DatabaseException>()),
      );
      await upgraded.close();
    },
  );

  test(
    'schema 6 to 7 preserves agenda concrete truck child graph and nullable notes',
    () async {
      final versionSix = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(6).toList(),
      );
      await versionSix.open();
      final db = versionSix.database;
      const project = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      const observation = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
      const pour = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
      const truck = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
      const sample = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
      const attachment = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
      const timestamp = '2026-07-19T08:00:00Z';
      await db.insert('projects', {
        'id': project,
        'name': 'Schema 6 Projesi',
        'created_at': timestamp,
        'updated_at': timestamp,
        'revision': 1,
      });
      await db.insert('field_observations', {
        'id': observation,
        'project_id': project,
        'observed_at': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
        'category': 'concrete',
        'description': 'Korunacak log',
        'revision': 1,
      });
      await db.insert('concrete_pours', {
        'id': pour,
        'project_id': project,
        'pour_code': 'BT-V6',
        'element_location': 'A Blok',
        'planned_at': timestamp,
        'concrete_class': 'C30/37',
        'planned_volume_m3': 12.5,
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_trucks', {
        'id': truck,
        'concrete_pour_id': pour,
        'sequence_no': 1,
        'vehicle_plate': '34 TEST 1',
        'delivery_note_number': 'IRS-V6',
        'volume_m3': 7.5,
        'result': 'received',
        'revision': 2,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_sample_sets', {
        'id': sample,
        'concrete_pour_id': pour,
        'source_truck_id': truck,
        'sample_code': 'N-V6',
        'sample_count': 0,
        'sample_labels_json': '[]',
        'expected_result_dates_json': '[]',
        'status': 'planned',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_attachments', {
        'id': attachment,
        'concrete_pour_id': pour,
        'truck_id': truck,
        'evidence_type': 'delivery_receipt_scan',
        'original_file_name': 'irsaliye.jpg',
        'mime_type': 'image/jpeg',
        'byte_size': 4,
        'sha256': 'a'.padLeft(64, 'a'),
        'relative_path': 'concrete/$pour/$attachment.jpg',
        'captured_at': timestamp,
        'created_at': timestamp,
      });
      await versionSix.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      expect(
        sqflite.Sqflite.firstIntValue(
          await upgraded.database.rawQuery('PRAGMA user_version'),
        ),
        AppDatabase.schemaVersion,
      );
      expect(
        (await upgraded.database.query(
          'field_observations',
        )).single['description'],
        'Korunacak log',
      );
      final preservedTruck = (await upgraded.database.query(
        'concrete_trucks',
        where: 'id = ?',
        whereArgs: [truck],
      )).single;
      expect(preservedTruck['delivery_note_number'], 'IRS-V6');
      expect(preservedTruck['revision'], 2);
      expect(preservedTruck['note'], isNull);
      expect(
        (await upgraded.database.query(
          'concrete_sample_sets',
        )).single['source_truck_id'],
        truck,
      );
      final migratedAttachment = (await upgraded.database.rawQuery('''
        SELECT l.context_type, l.context_id, l.legacy_id, m.relative_path
        FROM attachment_links l
        JOIN managed_attachments m ON m.id = l.attachment_id
        WHERE l.source_type = 'concrete_pour'
        ''')).single;
      expect(migratedAttachment['context_type'], 'concrete_truck');
      expect(migratedAttachment['context_id'], truck);
      expect(migratedAttachment['legacy_id'], attachment);
      expect(
        migratedAttachment['relative_path'],
        'concrete/$pour/$attachment.jpg',
      );
      final truckColumns = await upgraded.database.rawQuery(
        'PRAGMA table_info(concrete_trucks)',
      );
      expect(
        truckColumns.singleWhere(
          (row) => row['name'] == 'delivery_note_number',
        )['notnull'],
        0,
      );
      for (final (id, sequence) in [
        ('11111111-1111-4111-8111-111111111111', 2),
        ('22222222-2222-4222-8222-222222222222', 3),
      ]) {
        await upgraded.database.insert('concrete_trucks', {
          'id': id,
          'concrete_pour_id': pour,
          'sequence_no': sequence,
          'vehicle_plate': '34 NULL $sequence',
          'delivery_note_number': null,
          'volume_m3': 1.0,
          'result': 'received',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
      }
      await expectLater(
        upgraded.database.insert('concrete_trucks', {
          'id': '33333333-3333-4333-8333-333333333333',
          'concrete_pour_id': pour,
          'sequence_no': 4,
          'vehicle_plate': '34 DUP',
          'delivery_note_number': 'IRS-V6',
          'volume_m3': 1.0,
          'result': 'received',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        upgraded.database.delete(
          'concrete_trucks',
          where: 'id = ?',
          whereArgs: ['11111111-1111-4111-8111-111111111111'],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await upgraded.database.insert('managed_attachments', {
        'id': '44444444-4444-4444-8444-444444444444',
        'relative_path': 'agenda/$observation/photo.jpg',
        'mime_type': 'image/jpeg',
        'byte_size': 4,
        'sha256': 'b'.padLeft(64, 'b'),
        'created_at': timestamp,
      });
      await upgraded.database.insert('attachment_links', {
        'id': '55555555-5555-4555-8555-555555555555',
        'attachment_id': '44444444-4444-4444-8444-444444444444',
        'project_id': project,
        'source_type': 'agenda_observation',
        'source_id': observation,
        'role': 'site_photo',
        'original_file_name': 'saha.jpg',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await upgraded.database.insert('attachment_link_events', {
        'id': '66666666-6666-4666-8666-666666666666',
        'attachment_link_id': '55555555-5555-4555-8555-555555555555',
        'sequence': 1,
        'event_type': 'link.created',
        'occurred_at': timestamp,
        'payload_json': '{}',
      });
      await expectLater(
        upgraded.database.delete(
          'attachment_links',
          where: 'id = ?',
          whereArgs: ['55555555-5555-4555-8555-555555555555'],
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      await upgraded.close();
    },
  );

  test(
    'schema 7 to 8 normalizes waiting and preserves schedules sources and audit',
    () async {
      final versionSeven = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(7).toList(),
      );
      await versionSeven.open();
      final db = versionSeven.database;
      const project = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      const observation = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
      const attendance = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
      const pour = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
      const timestamp = '2026-07-19T08:00:00Z';
      const due = '2026-07-20T06:00:00Z';
      await db.insert('projects', {
        'id': project,
        'name': 'Schema 8 Projesi',
        'created_at': timestamp,
        'updated_at': timestamp,
        'revision': 1,
      });
      await db.insert('field_observations', {
        'id': observation,
        'project_id': project,
        'observed_at': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
        'category': 'inspection',
        'description': 'Korunan Ajanda kaynağı',
        'revision': 1,
      });
      await db.insert('attendance_days', {
        'id': attendance,
        'project_id': project,
        'local_date': '2026-07-19',
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_pours', {
        'id': pour,
        'project_id': project,
        'pour_code': 'BT-V8',
        'element_location': 'A Blok',
        'planned_at': due,
        'concrete_class': 'C30/37',
        'planned_volume_m3': 8.0,
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      Future<void> insertReminder({
        required String id,
        required int platformId,
        required String itemType,
        required String status,
        String? sourceObservation,
        String? sourceAttendance,
        String? sourceConcrete,
        int revision = 1,
      }) async {
        await db.insert('follow_up_items', {
          'id': id,
          'capture_text': 'Legacy $id',
          'title': 'Legacy $id',
          'item_type': itemType,
          'status': status,
          'project_id':
              sourceObservation != null ||
                  sourceAttendance != null ||
                  sourceConcrete != null
              ? project
              : null,
          'observation_id': sourceObservation,
          'attendance_day_id': sourceAttendance,
          'concrete_pour_id': sourceConcrete,
          'is_important': 1,
          'next_attention_at': status == 'inbox' ? null : due,
          'outcome_type': status == 'completed'
              ? 'completed'
              : status == 'cancelled'
              ? 'no_longer_needed'
              : null,
          'revision': revision,
          'created_at': timestamp,
          'updated_at': timestamp,
          'completed_at': status == 'completed' ? timestamp : null,
          'cancelled_at': status == 'cancelled' ? timestamp : null,
        });
        await db.insert('follow_up_events', {
          'id':
              'eeeeeeee-eeee-4eee-8eee-'
              '${platformId.toString().padLeft(12, '0')}',
          'follow_up_id': id,
          'sequence': 1,
          'project_id':
              sourceObservation != null ||
                  sourceAttendance != null ||
                  sourceConcrete != null
              ? project
              : null,
          'source_observation_id': sourceObservation,
          'source_attendance_day_id': sourceAttendance,
          'source_concrete_pour_id': sourceConcrete,
          'event_type': 'created',
          'occurred_at': timestamp,
          'payload_json': '{}',
        });
        await db.insert('reminder_notification_bindings', {
          'reminder_id': id,
          'platform_notification_id': platformId,
          'scheduled_for': status == 'inbox' ? null : due,
          'sync_state': status == 'inbox' ? 'cancelled' : 'scheduled',
          'last_synced_at': timestamp,
          'repeat_interval_minutes': platformId == 101 ? 60 : null,
        });
      }

      const bothWaiting = '11111111-1111-4111-8111-111111111111';
      const kindWaiting = '22222222-2222-4222-8222-222222222222';
      const statusWaiting = '33333333-3333-4333-8333-333333333333';
      await insertReminder(
        id: bothWaiting,
        platformId: 101,
        itemType: 'waiting',
        status: 'waiting',
        sourceObservation: observation,
        revision: 7,
      );
      await db.insert('follow_up_events', {
        'id': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
        'follow_up_id': bothWaiting,
        'sequence': 2,
        'project_id': project,
        'source_observation_id': observation,
        'event_type': 'waiting_started',
        'occurred_at': timestamp,
        'payload_json': '{"legacy":true}',
      });
      await insertReminder(
        id: kindWaiting,
        platformId: 102,
        itemType: 'waiting',
        status: 'active',
        sourceAttendance: attendance,
        revision: 5,
      );
      await insertReminder(
        id: statusWaiting,
        platformId: 103,
        itemType: 'action',
        status: 'waiting',
        sourceConcrete: pour,
        revision: 4,
      );
      await insertReminder(
        id: '44444444-4444-4444-8444-444444444444',
        platformId: 104,
        itemType: 'action',
        status: 'active',
      );
      await insertReminder(
        id: '55555555-5555-4555-8555-555555555555',
        platformId: 105,
        itemType: 'action',
        status: 'inbox',
      );
      await insertReminder(
        id: '66666666-6666-4666-8666-666666666666',
        platformId: 106,
        itemType: 'recheck',
        status: 'completed',
      );
      await insertReminder(
        id: '77777777-7777-4777-8777-777777777777',
        platformId: 107,
        itemType: 'action',
        status: 'cancelled',
      );
      await versionSeven.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      );
      await upgraded.open();
      expect(
        sqflite.Sqflite.firstIntValue(
          await upgraded.database.rawQuery('PRAGMA user_version'),
        ),
        AppDatabase.schemaVersion,
      );
      final rows = await upgraded.database.query(
        'follow_up_items',
        orderBy: 'id ASC',
      );
      expect(rows, hasLength(7));
      final normalizedBoth = rows.singleWhere(
        (row) => row['id'] == bothWaiting,
      );
      expect(normalizedBoth['item_type'], 'action');
      expect(normalizedBoth['status'], 'active');
      expect(normalizedBoth['next_attention_at'], due);
      expect(normalizedBoth['revision'], 7);
      expect(normalizedBoth['observation_id'], observation);
      expect(normalizedBoth['all_day_local_date'], isNull);
      expect(
        rows.singleWhere((row) => row['id'] == kindWaiting)['item_type'],
        'action',
      );
      expect(
        rows.singleWhere(
          (row) => row['id'] == kindWaiting,
        )['attendance_day_id'],
        attendance,
      );
      expect(
        rows.singleWhere((row) => row['id'] == statusWaiting)['status'],
        'active',
      );
      expect(
        rows.singleWhere(
          (row) => row['id'] == statusWaiting,
        )['concrete_pour_id'],
        pour,
      );
      final binding = (await upgraded.database.query(
        'reminder_notification_bindings',
        where: 'reminder_id = ?',
        whereArgs: [bothWaiting],
      )).single;
      expect(binding['platform_notification_id'], 101);
      expect(binding['scheduled_for'], due);
      expect(binding['sync_state'], 'scheduled');
      expect(binding['repeat_interval_minutes'], 60);
      final normalizationEvents = await upgraded.database.query(
        'follow_up_events',
        where: "event_type = 'legacy_waiting_normalized'",
        orderBy: 'follow_up_id ASC',
      );
      expect(normalizationEvents, hasLength(3));
      expect(
        (await upgraded.database.query(
          'follow_up_events',
          where: 'follow_up_id = ?',
          whereArgs: [bothWaiting],
          orderBy: 'sequence ASC',
        )).map((row) => row['sequence']),
        [1, 2, 3],
      );
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      await expectLater(
        upgraded.database.insert('follow_up_items', {
          'id': '88888888-8888-4888-8888-888888888888',
          'capture_text': 'Yasak waiting',
          'title': 'Yasak waiting',
          'item_type': 'waiting',
          'status': 'active',
          'next_attention_at': due,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        upgraded.database.insert('follow_up_items', {
          'id': '99999999-9999-4999-8999-999999999999',
          'capture_text': 'Çift schedule',
          'title': 'Çift schedule',
          'item_type': 'action',
          'status': 'active',
          'next_attention_at': due,
          'all_day_local_date': '2026-07-20',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await upgraded.close();

      final restarted = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 10),
      );
      await restarted.open();
      expect(
        await restarted.database.query(
          'follow_up_events',
          where: "event_type = 'legacy_waiting_normalized'",
        ),
        hasLength(3),
      );
      await restarted.close();
    },
  );

  test('empty schema 8 migrates atomically through schema 10', () async {
    final versionEight = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(8).toList(),
    );
    await versionEight.open();
    await versionEight.close();

    final upgraded = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 20, 9),
    );
    await upgraded.open();
    expect(
      sqflite.Sqflite.firstIntValue(
        await upgraded.database.rawQuery('PRAGMA user_version'),
      ),
      AppDatabase.schemaVersion,
    );
    expect(
      (await upgraded.database.rawQuery(
        'PRAGMA table_info(follow_up_items)',
      )).map((row) => row['name']),
      contains('trashed_at'),
    );
    expect(
      await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
      isEmpty,
    );
    expect(await upgraded.database.query('project_concrete_classes'), isEmpty);
    await upgraded.close();
  });

  test(
    'schema 8 to 9 preserves reminder variants sources bindings and history',
    () async {
      final versionEight = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(8).toList(),
      );
      await versionEight.open();
      final db = versionEight.database;
      const project = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      const observation = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
      const attendance = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
      const pour = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
      const timestamp = '2026-07-20T08:00:00Z';
      const due = '2026-07-21T06:00:00Z';
      await db.insert('projects', {
        'id': project,
        'name': 'Schema 9 Projesi',
        'created_at': timestamp,
        'updated_at': timestamp,
        'revision': 1,
      });
      await db.insert('field_observations', {
        'id': observation,
        'project_id': project,
        'observed_at': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
        'category': 'inspection',
        'description': 'Korunan Ajanda kaynağı',
        'revision': 1,
      });
      await db.insert('attendance_days', {
        'id': attendance,
        'project_id': project,
        'local_date': '2026-07-20',
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_pours', {
        'id': pour,
        'project_id': project,
        'pour_code': 'BT-V9',
        'element_location': 'A Blok',
        'planned_at': due,
        'concrete_class': 'C30/37',
        'planned_volume_m3': 8.0,
        'status': 'draft',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });

      Future<void> insertReminder({
        required String id,
        required int platformId,
        required String status,
        String? nextAttentionAt,
        String? allDayLocalDate,
        String? sourceObservation,
        String? sourceAttendance,
        String? sourceConcrete,
      }) async {
        final terminal = status == 'completed' || status == 'cancelled';
        await db.insert('follow_up_items', {
          'id': id,
          'capture_text': 'Schema 9 $id',
          'title': 'Schema 9 $id',
          'item_type': 'action',
          'status': status,
          'project_id':
              sourceObservation != null ||
                  sourceAttendance != null ||
                  sourceConcrete != null
              ? project
              : null,
          'observation_id': sourceObservation,
          'attendance_day_id': sourceAttendance,
          'concrete_pour_id': sourceConcrete,
          'is_important': 0,
          'next_attention_at': nextAttentionAt,
          'all_day_local_date': allDayLocalDate,
          'outcome_type': status == 'completed'
              ? 'completed'
              : status == 'cancelled'
              ? 'no_longer_needed'
              : null,
          'revision': 3,
          'created_at': timestamp,
          'updated_at': timestamp,
          'completed_at': status == 'completed' ? timestamp : null,
          'cancelled_at': status == 'cancelled' ? timestamp : null,
        });
        await db.insert('follow_up_events', {
          'id':
              'eeeeeeee-eeee-4eee-8eee-'
              '${platformId.toString().padLeft(12, '0')}',
          'follow_up_id': id,
          'sequence': 1,
          'project_id':
              sourceObservation != null ||
                  sourceAttendance != null ||
                  sourceConcrete != null
              ? project
              : null,
          'source_observation_id': sourceObservation,
          'source_attendance_day_id': sourceAttendance,
          'source_concrete_pour_id': sourceConcrete,
          'event_type': 'created',
          'occurred_at': timestamp,
          'payload_json': '{}',
        });
        await db.insert('reminder_notification_bindings', {
          'reminder_id': id,
          'platform_notification_id': platformId,
          'scheduled_for': terminal ? null : nextAttentionAt,
          'sync_state': nextAttentionAt == null || terminal
              ? 'cancelled'
              : 'scheduled',
          'last_synced_at': timestamp,
        });
      }

      await insertReminder(
        id: '11111111-1111-4111-8111-111111111111',
        platformId: 201,
        status: 'active',
        nextAttentionAt: due,
        sourceObservation: observation,
      );
      await insertReminder(
        id: '22222222-2222-4222-8222-222222222222',
        platformId: 202,
        status: 'active',
        allDayLocalDate: '2026-07-21',
        sourceAttendance: attendance,
      );
      await insertReminder(
        id: '33333333-3333-4333-8333-333333333333',
        platformId: 203,
        status: 'inbox',
        sourceConcrete: pour,
      );
      await insertReminder(
        id: '44444444-4444-4444-8444-444444444444',
        platformId: 204,
        status: 'completed',
      );
      await insertReminder(
        id: '55555555-5555-4555-8555-555555555555',
        platformId: 205,
        status: 'cancelled',
      );
      await versionEight.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 20, 9),
      );
      await upgraded.open();
      final rows = await upgraded.database.query(
        'follow_up_items',
        orderBy: 'id ASC',
      );
      expect(rows, hasLength(5));
      expect(rows.every((row) => row['trashed_at'] == null), isTrue);
      expect(rows.map((row) => row['status']), [
        'active',
        'active',
        'inbox',
        'completed',
        'cancelled',
      ]);
      expect(rows[0]['observation_id'], observation);
      expect(rows[1]['attendance_day_id'], attendance);
      expect(rows[2]['concrete_pour_id'], pour);
      expect(
        (await upgraded.database.query(
          'reminder_notification_bindings',
          orderBy: 'platform_notification_id ASC',
        )).map((row) => row['platform_notification_id']),
        [201, 202, 203, 204, 205],
      );
      expect(await upgraded.database.query('follow_up_events'), hasLength(5));
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      await upgraded.database.update(
        'follow_up_items',
        {'trashed_at': '2026-07-20T09:00:00Z'},
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
      await expectLater(
        upgraded.database.update(
          'follow_up_items',
          {'trashed_at': '2026-07-20 09:00:00'},
          where: 'id = ?',
          whereArgs: [rows[1]['id']],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await upgraded.database.insert('follow_up_events', {
        'id': 'ffffffff-ffff-4fff-8fff-fffffffffff1',
        'follow_up_id': rows.first['id'],
        'sequence': 2,
        'project_id': project,
        'source_observation_id': observation,
        'event_type': 'trashed',
        'occurred_at': '2026-07-20T09:00:00Z',
        'payload_json': '{}',
      });
      await upgraded.database.insert('follow_up_events', {
        'id': 'ffffffff-ffff-4fff-8fff-fffffffffff2',
        'follow_up_id': rows.first['id'],
        'sequence': 3,
        'project_id': project,
        'source_observation_id': observation,
        'event_type': 'restored_from_trash',
        'occurred_at': '2026-07-20T09:01:00Z',
        'payload_json': '{}',
      });
      await expectLater(
        upgraded.database.delete(
          'follow_up_items',
          where: 'id = ?',
          whereArgs: [rows.first['id']],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await upgraded.close();
    },
  );

  test(
    'schema 9 to 10 seeds project concrete classes and links legacy snapshots',
    () async {
      final versionNine = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(9).toList(),
      );
      await versionNine.open();
      final db = versionNine.database;
      const projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
      const projectB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
      const pourA1 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
      const pourA2 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
      const pourB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3';
      const timestamp = '2026-07-20T08:00:00Z';
      for (final value in const [
        (projectA, 'Proje A'),
        (projectB, 'Proje B'),
      ]) {
        await db.insert('projects', {
          'id': value.$1,
          'name': value.$2,
          'created_at': timestamp,
          'updated_at': timestamp,
          'revision': 1,
        });
      }
      for (final value in const [
        (pourA1, projectA, 'BT-A1', ' C30/37 ', null, null),
        (
          pourA2,
          projectA,
          'BT-A2',
          'c30/37',
          '2026-07-20T08:10:00Z',
          '2026-07-20T08:40:00Z',
        ),
        (pourB, projectB, 'BT-B1', 'C30/37', null, null),
      ]) {
        await db.insert('concrete_pours', {
          'id': value.$1,
          'project_id': value.$2,
          'pour_code': value.$3,
          'element_location': 'Temel',
          'planned_at': '2026-07-20T09:00:00Z',
          'actual_started_at': value.$5,
          'actual_ended_at': value.$6,
          'concrete_class': value.$4,
          'target_slump': value.$1 == pourA1 ? 'S3' : null,
          'planned_volume_m3': 20.0,
          'status': value.$6 != null
              ? 'poured'
              : value.$5 != null
              ? 'pouring'
              : 'draft',
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
      }
      await db.insert('concrete_trucks', {
        'id': 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
        'concrete_pour_id': pourA2,
        'sequence_no': 1,
        'vehicle_plate': '34 CSE 234',
        'volume_m3': 8.0,
        'result': 'received',
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      await db.insert('concrete_pour_events', {
        'id': 'dddddddd-dddd-4ddd-8ddd-ddddddddddd1',
        'concrete_pour_id': pourA2,
        'sequence': 1,
        'event_type': 'pour.started',
        'occurred_at': '2026-07-20T08:10:00Z',
        'payload_json': '{}',
      });
      await versionNine.close();

      final upgraded = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 20, 10),
      );
      await upgraded.open();
      final classes = await upgraded.database.query(
        'project_concrete_classes',
        orderBy: 'project_id ASC',
      );
      final links = await upgraded.database.query(
        'concrete_pour_context_links',
        orderBy: 'concrete_pour_id ASC',
      );
      final pours = await upgraded.database.query(
        'concrete_pours',
        orderBy: 'id ASC',
      );
      expect(classes, hasLength(2));
      expect(classes.map((row) => row['normalized_name']), [
        'c30/37',
        'c30/37',
      ]);
      expect(classes.first['default_target_slump'], 'S3');
      expect(links, hasLength(3));
      expect(links[0]['concrete_class_id'], links[1]['concrete_class_id']);
      expect(
        links[2]['concrete_class_id'],
        isNot(links[0]['concrete_class_id']),
      );
      expect(pours.map((row) => row['concrete_class']), [
        ' C30/37 ',
        'c30/37',
        'C30/37',
      ]);
      expect(pours[1]['actual_started_at'], '2026-07-20T08:10:00Z');
      expect(pours[1]['actual_ended_at'], '2026-07-20T08:40:00Z');
      expect(await upgraded.database.query('concrete_trucks'), hasLength(1));
      expect(
        (await upgraded.database.query('concrete_pour_events')).single['id'],
        'dddddddd-dddd-4ddd-8ddd-ddddddddddd1',
      );
      expect(
        await upgraded.database.rawQuery('PRAGMA foreign_key_check'),
        isEmpty,
      );
      const managedAgendaId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1';
      await upgraded.database.insert('field_observations', {
        'id': managedAgendaId,
        'project_id': projectA,
        'observed_at': timestamp,
        'created_at': timestamp,
        'updated_at': timestamp,
        'category': 'concrete',
        'description': 'Managed legacy concrete projection',
        'revision': 1,
      });
      await upgraded.database.update(
        'concrete_pour_context_links',
        {'agenda_log_id': managedAgendaId},
        where: 'concrete_pour_id = ?',
        whereArgs: [pourA1],
      );
      await expectLater(
        upgraded.database.update(
          'concrete_pour_context_links',
          {'agenda_log_id': managedAgendaId},
          where: 'concrete_pour_id = ?',
          whereArgs: [pourA2],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        upgraded.database.update(
          'concrete_pour_context_links',
          {'concrete_class_id': classes.last['id']},
          where: 'concrete_pour_id = ?',
          whereArgs: [pourA1],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        upgraded.database.delete(
          'project_concrete_classes',
          where: 'id = ?',
          whereArgs: [classes.first['id']],
        ),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await expectLater(
        upgraded.database.update('project_concrete_class_events', {
          'payload_json': '{"changed":true}',
        }),
        throwsA(isA<sqflite.DatabaseException>()),
      );
      await upgraded.close();
    },
  );

  test('schema 10 migration rolls back on an invalid legacy class', () async {
    final versionNine = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(9).toList(),
    );
    await versionNine.open();
    await versionNine.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Rollback V10',
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T08:00:00Z',
      'revision': 1,
    });
    await versionNine.database.insert('concrete_pours', {
      'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'project_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'pour_code': 'BT-BAD',
      'element_location': 'Temel',
      'planned_at': '2026-07-20T09:00:00Z',
      'concrete_class': '   ',
      'planned_volume_m3': 5.0,
      'status': 'draft',
      'revision': 1,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T08:00:00Z',
    });
    await versionNine.close();

    final upgraded = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 20, 10),
    );
    await expectLater(upgraded.open(), throwsA(isA<DatabaseOpenFailure>()));
    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: sqflite.OpenDatabaseOptions(singleInstance: false),
    );
    expect(
      sqflite.Sqflite.firstIntValue(await raw.rawQuery('PRAGMA user_version')),
      9,
    );
    expect(
      await raw.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE name = 'project_concrete_classes'",
      ),
      isEmpty,
    );
    expect((await raw.query('concrete_pours')).single['concrete_class'], '   ');
    await raw.close();
  });

  test('failed schema 9 migration rolls back intact schema 8 data', () async {
    final versionEight = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(8).toList(),
    );
    await versionEight.open();
    await versionEight.database.insert('follow_up_items', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'capture_text': 'Rollback schema 9',
      'title': 'Rollback schema 9',
      'item_type': 'action',
      'status': 'inbox',
      'is_important': 0,
      'revision': 1,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T08:00:00Z',
    });
    await versionEight.close();

    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 20, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(8),
        DatabaseMigration(
          version: 9,
          apply: (transaction) async {
            await AppDatabase.foundationMigrations[8].apply(transaction);
            throw StateError('forced schema 9 failure');
          },
        ),
      ],
    );
    await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: sqflite.OpenDatabaseOptions(singleInstance: false),
    );
    expect(
      sqflite.Sqflite.firstIntValue(await raw.rawQuery('PRAGMA user_version')),
      8,
    );
    expect(
      (await raw.query('follow_up_items')).single['title'],
      'Rollback schema 9',
    );
    expect(
      (await raw.rawQuery(
        'PRAGMA table_info(follow_up_items)',
      )).where((row) => row['name'] == 'trashed_at'),
      isEmpty,
    );
    expect(
      await raw.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'follow_up_events_v8'",
      ),
      isEmpty,
    );
    await raw.close();
  });

  test('failed schema 7 migration rolls back intact schema 6 data', () async {
    final versionSix = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => firstClock,
      migrations: AppDatabase.foundationMigrations.take(6).toList(),
    );
    await versionSix.open();
    await versionSix.database.insert('projects', {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'name': 'Rollback V6',
      'created_at': '2026-07-19T08:00:00Z',
      'updated_at': '2026-07-19T08:00:00Z',
      'revision': 1,
    });
    await versionSix.close();
    final failing = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 9),
      migrations: [
        ...AppDatabase.foundationMigrations.take(6),
        DatabaseMigration(
          version: 7,
          apply: (transaction) async {
            await transaction.execute('CREATE TABLE partial_v7 (id TEXT)');
            throw StateError('forced schema 7 failure');
          },
        ),
      ],
    );
    await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: sqflite.OpenDatabaseOptions(singleInstance: false),
    );
    expect(
      sqflite.Sqflite.firstIntValue(await raw.rawQuery('PRAGMA user_version')),
      6,
    );
    expect((await raw.query('projects')).single['name'], 'Rollback V6');
    expect(
      await raw.rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'partial_v7'",
      ),
      isEmpty,
    );
    await raw.close();
  });

  test(
    'failed schema 8 migration rolls back intact schema 7 waiting data',
    () async {
      final versionSeven = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => firstClock,
        migrations: AppDatabase.foundationMigrations.take(7).toList(),
      );
      await versionSeven.open();
      await versionSeven.database.insert('follow_up_items', {
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'capture_text': 'Rollback waiting',
        'title': 'Rollback waiting',
        'item_type': 'waiting',
        'status': 'waiting',
        'is_important': 0,
        'next_attention_at': '2026-07-20T06:00:00Z',
        'revision': 3,
        'created_at': '2026-07-19T08:00:00Z',
        'updated_at': '2026-07-19T08:00:00Z',
      });
      await versionSeven.database.insert('follow_up_events', {
        'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        'follow_up_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'sequence': 1,
        'event_type': 'created',
        'occurred_at': '2026-07-19T08:00:00Z',
        'payload_json': '{}',
      });
      await versionSeven.database.insert('reminder_notification_bindings', {
        'reminder_id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'platform_notification_id': 501,
        'scheduled_for': '2026-07-20T06:00:00Z',
        'sync_state': 'scheduled',
        'last_synced_at': '2026-07-19T08:00:00Z',
      });
      await versionSeven.close();

      final failing = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
        migrations: [
          ...AppDatabase.foundationMigrations.take(7),
          DatabaseMigration(
            version: 8,
            apply: (transaction) async {
              await AppDatabase.foundationMigrations[7].apply(transaction);
              throw StateError('forced schema 8 failure');
            },
          ),
        ],
      );
      await expectLater(failing.open(), throwsA(isA<DatabaseOpenFailure>()));
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: sqflite.OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        sqflite.Sqflite.firstIntValue(
          await raw.rawQuery('PRAGMA user_version'),
        ),
        7,
      );
      final waiting = (await raw.query('follow_up_items')).single;
      expect(waiting['item_type'], 'waiting');
      expect(waiting['status'], 'waiting');
      expect(
        (await raw.rawQuery(
          'PRAGMA table_info(follow_up_items)',
        )).where((row) => row['name'] == 'all_day_local_date'),
        isEmpty,
      );
      expect(
        await raw.rawQuery(
          "SELECT name FROM sqlite_master WHERE name LIKE '%_v7'",
        ),
        isEmpty,
      );
      await raw.close();
    },
  );
}
