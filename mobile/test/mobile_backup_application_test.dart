import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/mobile_backup_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/mobile_backup_models.dart';
import 'package:chief_site_engineer/platform/mobile_backup_gateway.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:chief_site_engineer/storage/smoke_record.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _password = 'guvenli-parola';
const _now = '2026-07-19T09:30:00Z';

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
    gateway = _FakeFileGateway();
    notificationReconciliations = 0;
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
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
      created.absolutePath,
      _password,
    );
    final restored = await application.restoreBackup(
      RestoreMobileBackupCommand(
        packagePath: created.absolutePath,
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
    'full fixture preserves rows, append-only events, links and attachment bytes',
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
        'concrete_attachments',
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
        created.absolutePath,
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
          packagePath: created.absolutePath,
          password: _password,
          expectedPackageSha256: preflight.packageSha256,
        ),
      );

      expect(await _fixtureSnapshot(directories), before);
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
    'wrong password and encrypted package tampering are indistinguishable',
    () async {
      final application = _application(directories, gateway: gateway);
      final created = await application.createBackup(
        const CreateMobileBackupCommand(
          password: _password,
          passwordConfirmation: _password,
        ),
      );

      await expectLater(
        application.preflightBackup(created.absolutePath, 'yanlis-parola'),
        _failureCode('wrong_password_or_tampered'),
      );
      final package = File(created.absolutePath);
      final bytes = await package.readAsBytes();
      bytes[bytes.length - 1] ^= 0xff;
      await package.writeAsBytes(bytes, flush: true);
      await expectLater(
        application.preflightBackup(created.absolutePath, _password),
        _failureCode('wrong_password_or_tampered'),
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
        created.absolutePath,
        _password,
      );
      final package = File(created.absolutePath);
      final original = await package.readAsBytes();
      original[original.length - 1] ^= 0xff;
      await package.writeAsBytes(original, flush: true);

      await expectLater(
        application.restoreBackup(
          RestoreMobileBackupCommand(
            packagePath: created.absolutePath,
            password: _password,
            expectedPackageSha256: preflight.packageSha256,
          ),
        ),
        _failureCode('wrong_password_or_tampered'),
      );
      expect(await _projectCount(directories), 0);
    },
  );

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
        created.absolutePath,
        _password,
      );

      await expectLater(
        failing.restoreBackup(
          RestoreMobileBackupCommand(
            packagePath: created.absolutePath,
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

  for (final schemaVersion in [1, 2, 3, 4, 5, 6, 7]) {
    test(
      'schema v$schemaVersion package migrates to v7 without count loss',
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
        await oldDatabase.close();
        final databaseBytes = await File(oldFile).readAsBytes();
        final archive = const CseBackupArchiveCodec().encode(
          manifest: _manifest(databaseBytes, schemaVersion: schemaVersion),
          databaseBytes: databaseBytes,
          attachments: const {},
        );
        final package = File(path.join(oldRoot.path, 'old.csebackup'));
        await package.writeAsBytes(
          await _testEncryptionCodec().encrypt(archive, _password),
          flush: true,
        );
        final application = _application(directories, gateway: gateway);
        final preflight = await application.preflightBackup(
          package.path,
          _password,
        );

        await application.restoreBackup(
          RestoreMobileBackupCommand(
            packagePath: package.path,
            password: _password,
            expectedPackageSha256: preflight.packageSha256,
          ),
        );

        expect(preflight.manifest.mobileSchemaVersion, schemaVersion);
        expect(preflight.migratedSchemaVersion, 7);
        final counts = await _tableCounts(directories);
        final hasAgenda = schemaVersion >= 2 ? 1 : 0;
        final hasAttendance = schemaVersion >= 4 ? 1 : 0;
        expect(counts['projects'], hasAgenda);
        expect(counts['field_observations'], hasAgenda);
        expect(counts['observation_events'], hasAgenda);
        expect(counts['follow_up_items'], hasAgenda);
        expect(counts['follow_up_events'], hasAgenda);
        expect(counts['reminder_notification_bindings'], hasAgenda);
        expect(counts['subcontractors'], hasAttendance);
        expect(counts['workforce_teams'], hasAttendance);
        expect(counts['workforce_members'], hasAttendance);
        expect(counts['workforce_compliance_records'], 0);
        expect(counts['workforce_ppe_assignments'], 0);
        expect(counts['attendance_days'], hasAttendance);
        expect(counts['attendance_entries'], hasAttendance);
        expect(counts['attendance_events'], hasAttendance);
        expect(counts['concrete_pours'], 0);
        expect(counts['concrete_pour_events'], 0);
        expect(counts['concrete_attachments'], 0);
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
      manifest: _manifest(databaseBytes, schemaVersion: 8),
      databaseBytes: databaseBytes,
      attachments: const {},
    );
    final package = File(path.join(packageRoot.path, 'future.csebackup'));
    await package.writeAsBytes(
      await _testEncryptionCodec().encrypt(archive, _password),
      flush: true,
    );

    await expectLater(
      _application(
        directories,
        gateway: gateway,
      ).preflightBackup(package.path, _password),
      _failureCode('unsupported_schema'),
    );

    expect(await _projectCount(directories), activeProjectCount);
    expect(await directories.staging.list().toList(), isEmpty);
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
      await expectLater(
        application.preflightBackup(corruptPackage.path, _password),
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
      await expectLater(
        application.preflightBackup(foreignKeyPackage.path, _password),
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
        created.absolutePath,
        _password,
      );

      await expectLater(
        failing.restoreBackup(
          RestoreMobileBackupCommand(
            packagePath: created.absolutePath,
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

Future<void> _writePackage(File destination, List<int> databaseBytes) async {
  final archive = const CseBackupArchiveCodec().encode(
    manifest: _manifest(databaseBytes, schemaVersion: 7),
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
  required _FakeFileGateway gateway,
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
      'revision': 1,
    });
    await tx.insert('field_observations', {
      'id': 'observation-1',
      'project_id': 'project-1',
      'observed_at': '2026-07-18T07:00:00Z',
      'created_at': _now,
      'updated_at': _now,
      'category': 'inspection',
      'description': 'Donatı kontrolü tamamlandı.',
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
    await tx.insert('agenda_log_attachments', {
      'id': 'agenda-attachment-1',
      'observation_id': 'observation-1',
      'project_id': 'project-1',
      'attachment_type': 'site_photo',
      'original_file_name': 'saha-fotografi.jpg',
      'mime_type': 'image/jpeg',
      'byte_size': agendaPhotoBytes.length,
      'sha256': agendaPhotoDigest,
      'relative_path': 'agenda/observation-1/site-photo.jpg',
      'description': 'Donatı saha fotoğrafı',
      'captured_at': _now,
      'revision': 1,
      'created_at': _now,
      'updated_at': _now,
    });
    await tx.insert('follow_up_items', {
      'id': 'reminder-1',
      'capture_text': 'Kalıp ekibini ara',
      'title': 'Kalıp ekibini ara',
      'item_type': 'action',
      'status': 'active',
      'project_id': 'project-1',
      'observation_id': 'observation-1',
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
    await tx.insert('concrete_pours', {
      'id': 'pour-1',
      'project_id': 'project-1',
      'pour_code': 'BT-189',
      'element_location': 'A Blok temel',
      'planned_at': '2026-07-20T05:00:00Z',
      'concrete_class': 'C30/37',
      'planned_volume_m3': 25.0,
      'status': 'draft',
      'revision': 1,
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
    await tx.insert('concrete_attachments', {
      'id': 'attachment-1',
      'concrete_pour_id': 'pour-1',
      'evidence_type': 'site_photo',
      'original_file_name': 'kanıt.bin',
      'mime_type': 'application/octet-stream',
      'byte_size': attachmentBytes.length,
      'sha256': attachmentDigest,
      'relative_path': 'concrete/pour-1/evidence.bin',
      'captured_at': _now,
      'description': 'Taşınabilir ikili kanıt',
      'created_at': _now,
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
    'item_type': 'action',
    'status': 'active',
    'project_id': 'legacy-project',
    'observation_id': 'legacy-observation',
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
}

Future<Map<String, int>> _tableCounts(AppDirectories directories) async {
  final database = await _openRaw(directories);
  final counts = <String, int>{};
  for (final table in const [
    'projects',
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
    'concrete_pour_events',
    'concrete_attachments',
    'agenda_log_attachments',
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
    'concrete_pour_events',
    'concrete_attachments',
    'agenda_log_attachments',
  ]) {
    result[table] = await database.query(table, orderBy: 'rowid ASC');
  }
  await database.close();
  return result;
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

MobileBackupManifest _manifest(
  List<int> databaseBytes, {
  required int schemaVersion,
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
  attachments: const [],
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
  String? pickedPath;
  String? sharedPath;

  @override
  Future<String?> pickPackage() async => pickedPath;

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
