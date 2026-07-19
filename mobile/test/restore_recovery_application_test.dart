import 'dart:io';

import 'package:chief_site_engineer/application/restore_recovery_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:chief_site_engineer/storage/smoke_record.dart';
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
