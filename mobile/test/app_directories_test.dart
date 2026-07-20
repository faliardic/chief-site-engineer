import 'dart:io';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryRoot;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_mobile_paths_');
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test(
    'creates validated local directories under one environment root',
    () async {
      final directories = AppDirectories.fromSupportRoot(
        temporaryRoot,
        AppEnvironment.debug,
      );

      await directories.ensureCreated();

      for (final directory in [
        directories.database,
        directories.attachments,
        directories.exportsBackups,
        directories.state,
        directories.staging,
      ]) {
        expect(await directory.exists(), isTrue);
        expect(path.isWithin(directories.root.path, directory.path), isTrue);
      }
      expect(
        path.isWithin(directories.root.path, directories.databaseFile),
        isTrue,
      );
      expect(
        path.isWithin(directories.root.path, directories.backupStateFile),
        isTrue,
      );
      expect(
        path.isWithin(
          directories.staging.path,
          directories.incomingBackups.path,
        ),
        isTrue,
      );
      expect(
        path.isWithin(directories.root.path, directories.restoreJournalFile),
        isTrue,
      );
      expect(
        path.isWithin(
          directories.root.path,
          directories.restoreJournalNextFile,
        ),
        isTrue,
      );
    },
  );

  test('recovery roots do not recreate active state directories', () async {
    final directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );

    await directories.ensureRecoveryRootsCreated();

    expect(await directories.root.exists(), isTrue);
    expect(await directories.staging.exists(), isTrue);
    expect(await directories.database.exists(), isFalse);
    expect(await directories.attachments.exists(), isFalse);
  });

  test('debug and release roots are physically distinct', () {
    final debug = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    final release = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.release,
    );

    expect(debug.root.path, isNot(release.root.path));
    expect(debug.databaseFile, isNot(release.databaseFile));
  });

  test('rejects a relative platform support path', () {
    expect(
      () => AppDirectories.fromSupportRoot(
        Directory('relative-support'),
        AppEnvironment.debug,
      ),
      throwsA(isA<PathContractViolation>()),
    );
  });
}
