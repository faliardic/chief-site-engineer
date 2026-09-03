import 'dart:io';

import 'package:chief_site_engineer/application/restore_recovery_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:chief_site_engineer/storage/smoke_record.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _operationId = '123456789-abcdef123456';
DateTime _clock() => DateTime.utc(2026, 7, 19, 18);

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_restore_recovery_',
    );
    directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    await directories.ensureCreated();
    await _createDatabase(directories.databaseFile, 'old-project');
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  for (final phase in RestoreJournalPhase.values) {
    test('bootstrap recovers process death after ${phase.name}', () async {
      await _arrangeInterruptedRestore(directories, phase);

      final result = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactoryFfi,
        clock: _clock,
      ).start();

      expect(result, isA<BootstrapSuccess>());
      expect(
        await _projectNames(directories.databaseFile),
        phase.index < RestoreJournalPhase.newStateActivated.index
            ? contains('old-project')
            : contains('new-project'),
      );
      expect(await File(directories.restoreJournalFile).exists(), isFalse);
      expect(await File(directories.restoreJournalNextFile).exists(), isFalse);
      expect(await directories.staging.list().toList(), isEmpty);
    });
  }

  test('ambiguous recovery preserves journal and recovery area', () async {
    final arranged = await _arrangeInterruptedRestore(
      directories,
      RestoreJournalPhase.oldStateMoved,
    );
    await arranged.rollbackAttachments.delete(recursive: true);

    final result = await AppBootstrap(
      environment: AppEnvironment.debug,
      directoriesProvider: () async => directories,
      databaseFactory: databaseFactoryFfi,
      clock: _clock,
    ).start();

    expect(result, isA<BootstrapFailure>());
    expect((result as BootstrapFailure).code, 'restore_recovery_failed');
    expect(await File(directories.restoreJournalFile).exists(), isTrue);
    expect(await arranged.rollbackRoot.exists(), isTrue);
    expect(await directories.database.exists(), isTrue);
    expect(await File(directories.databaseFile).exists(), isFalse);
  });

  test('prepared phase restores a database moved before attachments', () async {
    final preparedRoot = Directory(
      path.join(directories.staging.path, 'restore-$_operationId'),
    );
    final rollbackRoot = Directory(
      path.join(directories.staging.path, 'rollback-$_operationId'),
    );
    await preparedRoot.create();
    await rollbackRoot.create();
    await _createDatabase(
      path.join(preparedRoot.path, 'database.sqlite3'),
      'new-project',
    );
    await Directory(path.join(preparedRoot.path, 'attachments')).create();
    final recovery = MobileRestoreRecoveryApplication(
      directories: directories,
      databaseFactory: databaseFactoryFfi,
      clock: _clock,
    );
    await recovery.begin(
      operationId: _operationId,
      preparedDirectory: preparedRoot,
      rollbackDirectory: rollbackRoot,
    );
    await File(
      directories.databaseFile,
    ).rename(path.join(rollbackRoot.path, 'database.sqlite3'));

    final result = await AppBootstrap(
      environment: AppEnvironment.debug,
      directoriesProvider: () async => directories,
      databaseFactory: databaseFactoryFfi,
      clock: _clock,
    ).start();

    expect(result, isA<BootstrapSuccess>());
    expect(
      await _projectNames(directories.databaseFile),
      contains('old-project'),
    );
    expect(await directories.attachments.exists(), isTrue);
    expect(await File(directories.restoreJournalFile).exists(), isFalse);
    expect(await directories.staging.list().toList(), isEmpty);
  });

  test('journal never stores an absolute path or package secret', () async {
    await _arrangeInterruptedRestore(directories, RestoreJournalPhase.prepared);

    final journal = await File(directories.restoreJournalFile).readAsString();

    expect(journal, contains('"phase": "prepared"'));
    expect(journal, contains('restore-$_operationId'));
    expect(journal, isNot(contains(temporaryRoot.path)));
    expect(journal, isNot(contains('password')));
    expect(journal, isNot(contains('.csebackup')));
  });

  test(
    'active recovery audits canonical graph and required physical file',
    () async {
      const bytes = <int>[0xff, 0xd8, 0xff, 0xd9];
      await _insertAgendaAttachmentGraph(
        directories,
        relativePath: 'agenda/recovery/photo.jpg',
        digest: sha256.convert(bytes).toString(),
      );
      final recovery = MobileRestoreRecoveryApplication(
        directories: directories,
        databaseFactory: databaseFactoryFfi,
        clock: _clock,
      );

      await expectLater(
        recovery.validateActiveState(),
        throwsA(
          isA<RestoreRecoveryFailure>().having(
            (failure) => failure.code,
            'code',
            'active_attachment_missing',
          ),
        ),
      );

      final file = File(
        path.join(directories.attachments.path, 'agenda/recovery/photo.jpg'),
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      await expectLater(recovery.validateActiveState(), completes);

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await raw.execute('DROP TRIGGER attachment_links_target_project_insert');
      await raw.insert('managed_attachments', {
        'id': 'broken-physical',
        'relative_path': 'agenda/recovery/broken.jpg',
        'mime_type': 'image/jpeg',
        'byte_size': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
        'created_at': '2026-07-19T18:00:00Z',
      });
      await raw.insert('attachment_links', {
        'id': 'broken-link',
        'attachment_id': 'broken-physical',
        'project_id': 'old-project',
        'source_type': 'agenda_observation',
        'source_id': 'missing-observation',
        'role': 'site_photo',
        'original_file_name': 'broken.jpg',
        'revision': 1,
        'created_at': '2026-07-19T18:00:00Z',
        'updated_at': '2026-07-19T18:00:00Z',
      });
      await raw.insert('attachment_link_events', {
        'id': 'broken-event',
        'attachment_link_id': 'broken-link',
        'sequence': 1,
        'event_type': 'link.created',
        'occurred_at': '2026-07-19T18:00:00Z',
        'payload_json': '{}',
      });
      await raw.close();

      await expectLater(
        recovery.validateActiveState(),
        throwsA(
          isA<RestoreRecoveryFailure>().having(
            (failure) => failure.code,
            'code',
            'active_attachment_graph_invalid',
          ),
        ),
      );
    },
  );

  test(
    'Inventory-only recovery requires its managed file with exact size and hash',
    () async {
      const bytes = <int>[0xff, 0xd8, 0xff, 0xd9];
      const relativePath = 'managed/60400000-0000-4000-8000-000000000001.jpg';
      await _insertInventoryAttachmentGraph(
        directories,
        relativePath: relativePath,
        bytes: bytes,
      );
      final recovery = MobileRestoreRecoveryApplication(
        directories: directories,
        databaseFactory: databaseFactoryFfi,
        clock: _clock,
      );
      Matcher failure(String code) => throwsA(
        isA<RestoreRecoveryFailure>().having(
          (failure) => failure.code,
          'code',
          code,
        ),
      );
      await expectLater(
        recovery.validateActiveState(),
        failure('active_attachment_missing'),
      );
      final file = File(path.join(directories.attachments.path, relativePath));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      await expectLater(recovery.validateActiveState(), completes);

      await file.writeAsBytes(bytes.sublist(0, 3), flush: true);
      await expectLater(
        recovery.validateActiveState(),
        failure('active_attachment_corrupt'),
      );
      await file.writeAsBytes(const [1, 2, 3, 4], flush: true);
      await expectLater(
        recovery.validateActiveState(),
        failure('active_attachment_corrupt'),
      );
      await file.writeAsBytes(bytes, flush: true);
      await expectLater(recovery.validateActiveState(), completes);

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      expect(await raw.query('attachment_links'), isEmpty);
      expect(await raw.query('inventory_asset_attachment_links'), hasLength(1));
      await raw.close();
    },
  );

  test('migrated archived Concrete physical file remains optional', () async {
    final database = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: _clock,
    );
    await database.open();
    await database.database.insert('concrete_pours', {
      'id': 'archived-pour',
      'project_id': 'old-project',
      'pour_code': 'ARCHIVED-1',
      'element_location': 'Arşiv elemanı',
      'planned_at': '2026-07-19T18:00:00Z',
      'concrete_class': 'C30/37',
      'planned_volume_m3': 1.0,
      'status': 'draft',
      'revision': 1,
      'created_at': '2026-07-19T18:00:00Z',
      'updated_at': '2026-07-19T18:00:00Z',
    });
    await database.database.insert('managed_attachments', {
      'id': 'archived-physical',
      'relative_path': 'concrete/archived/missing.bin',
      'mime_type': 'application/octet-stream',
      'byte_size': 3,
      'sha256': sha256.convert(const <int>[1, 2, 3]).toString(),
      'created_at': '2026-07-19T18:00:00Z',
    });
    await database.database.insert('attachment_links', {
      'id': 'archived-link',
      'attachment_id': 'archived-physical',
      'project_id': 'old-project',
      'source_type': 'concrete_pour',
      'source_id': 'archived-pour',
      'role': 'site_photo',
      'original_file_name': 'missing.bin',
      'captured_at': '2026-07-19T18:00:00Z',
      'revision': 1,
      'created_at': '2026-07-19T18:00:00Z',
      'updated_at': '2026-07-19T18:00:00Z',
      'archived_at': '2026-07-19T19:00:00Z',
      'legacy_source': 'concrete_attachments',
      'legacy_id': 'legacy-archived-attachment',
    });
    await database.database.insert('attachment_link_events', {
      'id': 'archived-link-event',
      'attachment_link_id': 'archived-link',
      'sequence': 1,
      'event_type': 'link.created',
      'occurred_at': '2026-07-19T18:00:00Z',
      'payload_json': '{}',
    });
    await database.close();

    final recovery = MobileRestoreRecoveryApplication(
      directories: directories,
      databaseFactory: databaseFactoryFfi,
      clock: _clock,
    );
    await expectLater(recovery.validateActiveState(), completes);
  });
}

class _InterruptedRestore {
  const _InterruptedRestore({
    required this.rollbackRoot,
    required this.rollbackAttachments,
  });

  final Directory rollbackRoot;
  final Directory rollbackAttachments;
}

Future<_InterruptedRestore> _arrangeInterruptedRestore(
  AppDirectories directories,
  RestoreJournalPhase phase,
) async {
  final preparedRoot = Directory(
    path.join(directories.staging.path, 'restore-$_operationId'),
  );
  final rollbackRoot = Directory(
    path.join(directories.staging.path, 'rollback-$_operationId'),
  );
  await preparedRoot.create();
  await rollbackRoot.create();
  await _createDatabase(
    path.join(preparedRoot.path, 'database.sqlite3'),
    'new-project',
  );
  final preparedAttachments = Directory(
    path.join(preparedRoot.path, 'attachments'),
  );
  await preparedAttachments.create();
  final rollbackDatabase = File(
    path.join(rollbackRoot.path, 'database.sqlite3'),
  );
  final rollbackAttachments = Directory(
    path.join(rollbackRoot.path, 'attachments'),
  );
  final recovery = MobileRestoreRecoveryApplication(
    directories: directories,
    databaseFactory: databaseFactoryFfi,
    clock: _clock,
  );
  var entry = await recovery.begin(
    operationId: _operationId,
    preparedDirectory: preparedRoot,
    rollbackDirectory: rollbackRoot,
  );
  if (phase.index >= RestoreJournalPhase.oldStateMoved.index) {
    await File(directories.databaseFile).rename(rollbackDatabase.path);
    await directories.attachments.rename(rollbackAttachments.path);
    entry = await recovery.advance(entry, RestoreJournalPhase.oldStateMoved);
  }
  if (phase.index >= RestoreJournalPhase.newStateActivated.index) {
    await File(
      path.join(preparedRoot.path, 'database.sqlite3'),
    ).rename(directories.databaseFile);
    await preparedAttachments.rename(directories.attachments.path);
    entry = await recovery.advance(
      entry,
      RestoreJournalPhase.newStateActivated,
    );
  }
  if (phase == RestoreJournalPhase.validated) {
    await recovery.validateActiveState();
    await recovery.advance(entry, RestoreJournalPhase.validated);
  }
  return _InterruptedRestore(
    rollbackRoot: rollbackRoot,
    rollbackAttachments: rollbackAttachments,
  );
}

Future<void> _createDatabase(String databasePath, String projectName) async {
  await Directory(path.dirname(databasePath)).create(recursive: true);
  final database = AppDatabase(
    path: databasePath,
    factory: databaseFactoryFfi,
    clock: _clock,
  );
  await database.open();
  await SmokeRecordRepository(
    database: database,
    clock: _clock,
  ).ensureFoundationRecord();
  await database.database.insert('projects', {
    'id': projectName,
    'name': projectName,
    'created_at': '2026-07-19T18:00:00Z',
    'updated_at': '2026-07-19T18:00:00Z',
    'revision': 1,
  });
  await database.close();
}

Future<List<String>> _projectNames(String databasePath) async {
  final database = await databaseFactoryFfi.openDatabase(databasePath);
  try {
    final rows = await database.query('projects', orderBy: 'id ASC');
    return rows.map((row) => row['name']! as String).toList();
  } finally {
    await database.close();
  }
}

Future<void> _insertInventoryAttachmentGraph(
  AppDirectories directories, {
  required String relativePath,
  required List<int> bytes,
}) async {
  final database = AppDatabase(
    path: directories.databaseFile,
    factory: databaseFactoryFfi,
    clock: _clock,
  );
  await database.open();
  try {
    await database.database.transaction((transaction) async {
      await transaction.insert('inventory_assets', {
        'id': 'inventory-recovery-asset',
        'project_id': 'old-project',
        'display_name': 'Recovery asset',
        'normalized_name': 'recovery asset',
        'category_code': 'EQUIPMENT',
        'total_quantity': 1,
        'status': 'AVAILABLE',
        'revision': 1,
        'created_at': '2026-07-19T18:00:00Z',
        'updated_at': '2026-07-19T18:00:00Z',
        'status_changed_at': '2026-07-19T18:00:00Z',
      });
      await transaction.insert('managed_attachments', {
        'id': '60400000-0000-4000-8000-000000000001',
        'relative_path': relativePath,
        'mime_type': 'image/jpeg',
        'byte_size': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
        'created_at': '2026-07-19T18:00:00Z',
      });
      await transaction.insert('inventory_asset_attachment_links', {
        'id': 'inventory-recovery-link',
        'attachment_id': '60400000-0000-4000-8000-000000000001',
        'asset_id': 'inventory-recovery-asset',
        'project_id': 'old-project',
        'role': 'inventory_photo',
        'original_file_name': 'photo.jpg',
        'revision': 1,
        'created_at': '2026-07-19T18:00:00Z',
        'updated_at': '2026-07-19T18:00:00Z',
      });
    });
  } finally {
    await database.close();
  }
}

Future<void> _insertAgendaAttachmentGraph(
  AppDirectories directories, {
  required String relativePath,
  required String digest,
}) async {
  final database = AppDatabase(
    path: directories.databaseFile,
    factory: databaseFactoryFfi,
    clock: _clock,
  );
  await database.open();
  await database.database.insert('field_observations', {
    'id': 'recovery-observation',
    'project_id': 'old-project',
    'observed_at': '2026-07-19T18:00:00Z',
    'created_at': '2026-07-19T18:00:00Z',
    'updated_at': '2026-07-19T18:00:00Z',
    'category': 'inspection',
    'description': 'Recovery attachment source',
    'revision': 1,
  });
  await database.database.insert('managed_attachments', {
    'id': 'recovery-physical',
    'relative_path': relativePath,
    'mime_type': 'image/jpeg',
    'byte_size': 4,
    'sha256': digest,
    'created_at': '2026-07-19T18:00:00Z',
  });
  await database.database.insert('attachment_links', {
    'id': 'recovery-link',
    'attachment_id': 'recovery-physical',
    'project_id': 'old-project',
    'source_type': 'agenda_observation',
    'source_id': 'recovery-observation',
    'role': 'site_photo',
    'original_file_name': 'photo.jpg',
    'revision': 1,
    'created_at': '2026-07-19T18:00:00Z',
    'updated_at': '2026-07-19T18:00:00Z',
  });
  await database.database.insert('attachment_link_events', {
    'id': 'recovery-link-event',
    'attachment_link_id': 'recovery-link',
    'sequence': 1,
    'event_type': 'link.created',
    'occurred_at': '2026-07-19T18:00:00Z',
    'payload_json': '{}',
  });
  await database.close();
}
