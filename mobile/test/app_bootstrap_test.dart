import 'dart:io';

import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryRoot;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_bootstrap_');
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test(
    'restart returns the original persisted smoke record timestamp',
    () async {
      final directories = AppDirectories.fromSupportRoot(
        temporaryRoot,
        AppEnvironment.debug,
      );
      final first = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 8),
      ).start();
      final restarted = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      ).start();

      expect(first, isA<BootstrapSuccess>());
      expect(restarted, isA<BootstrapSuccess>());
      expect(
        (restarted as BootstrapSuccess).smokeRecordCreatedAt,
        (first as BootstrapSuccess).smokeRecordCreatedAt,
      );
    },
  );

  test('path or database failure returns no implementation detail', () async {
    final result = await AppBootstrap(
      environment: AppEnvironment.debug,
      directoriesProvider: () async => throw StateError('sensitive path'),
      databaseFactory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 8),
    ).start();

    expect(result, const TypeMatcher<BootstrapFailure>());
    expect(result.toString(), isNot(contains('sensitive path')));
  });
}
