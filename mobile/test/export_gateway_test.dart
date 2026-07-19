import 'dart:io';
import 'dart:typed_data';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/platform/export_gateway.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_mobile_export_');
    directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('stages export atomically inside the app export directory', () async {
    final staged = await LocalExportStager(
      directories,
    ).stage('backup.cse', Uint8List.fromList([1, 2, 3]));

    expect(staged.parent.path, directories.exportsBackups.path);
    expect(await staged.readAsBytes(), [1, 2, 3]);
    expect(await directories.staging.list().isEmpty, isTrue);
  });

  test('rejects traversal and overwrite attempts', () async {
    final stager = LocalExportStager(directories);

    await expectLater(
      stager.stage('../backup.cse', Uint8List(0)),
      throwsA(isA<PathContractViolation>()),
    );
    await stager.stage('backup.cse', Uint8List.fromList([1]));
    await expectLater(
      stager.stage('backup.cse', Uint8List.fromList([2])),
      throwsA(isA<PathContractViolation>()),
    );
    expect(await directories.staging.list().isEmpty, isTrue);
  });
}
