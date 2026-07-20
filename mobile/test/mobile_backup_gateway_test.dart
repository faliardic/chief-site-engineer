import 'dart:async';
import 'dart:io';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/mobile_backup_models.dart';
import 'package:chief_site_engineer/platform/mobile_backup_gateway.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_backup_gateway_',
    );
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

  test(
    'stream import survives picker source deletion with exact metadata',
    () async {
      final source = File(
        path.join(temporaryRoot.path, 'picker-cache.csebackup'),
      );
      final bytes = List<int>.generate(8193, (index) => index % 251);
      await source.writeAsBytes(bytes, flush: true);
      final gateway = _gateway(
        directories,
        id: 'import-stream-1',
        picker: () async => PlatformFile(
          name: 'saha-yedegi.csebackup',
          size: bytes.length,
          path: source.path,
          readStream: source.openRead(),
        ),
      );

      final imported = await gateway.pickPackage();
      await source.delete();

      expect(imported, isNotNull);
      expect(await File(imported!.stablePath).readAsBytes(), bytes);
      expect(imported.originalFileName, 'saha-yedegi.csebackup');
      expect(imported.byteSize, bytes.length);
      expect(imported.sha256, sha256.convert(bytes).toString());
      expect(imported.importOperationId, 'import-stream-1');
      expect(
        path.dirname(imported.stablePath),
        path.normalize(path.absolute(directories.incomingBackups.path)),
      );
    },
  );

  test('same original name imports to collision-free stable files', () async {
    final selections = <PlatformFile>[
      _memorySelection('same.csebackup', [1, 2, 3]),
      _memorySelection('same.csebackup', [4, 5, 6]),
    ];
    final ids = ['collision-a', 'collision-b'];
    final gateway = DeviceMobileBackupFileGateway(
      directories: directories,
      picker: () async => selections.removeAt(0),
      clock: () => DateTime.utc(2026, 7, 20, 12),
      importIdFactory: (_) => ids.removeAt(0),
    );

    final first = await gateway.pickPackage();
    final second = await gateway.pickPackage();

    expect(first!.stablePath, isNot(second!.stablePath));
    expect(first.originalFileName, second.originalFileName);
    expect(await File(first.stablePath).readAsBytes(), [1, 2, 3]);
    expect(await File(second.stablePath).readAsBytes(), [4, 5, 6]);
  });

  test(
    'picker cancel creates nothing and leaves an existing import intact',
    () async {
      final existing = File(
        path.join(directories.incomingBackups.path, 'existing.csebackup'),
      );
      await existing.parent.create(recursive: true);
      await existing.writeAsBytes([1], flush: true);
      final gateway = _gateway(
        directories,
        id: 'cancelled',
        picker: () async => null,
      );

      expect(await gateway.pickPackage(), isNull);
      expect(await existing.readAsBytes(), [1]);
      expect(await directories.incomingBackups.list().toList(), [isA<File>()]);
    },
  );

  test('oversize stream leaves neither partial nor final package', () async {
    final gateway = DeviceMobileBackupFileGateway(
      directories: directories,
      picker: () async => PlatformFile(
        name: 'large.csebackup',
        size: 0,
        readStream: Stream.fromIterable(const [
          [1, 2],
          [3, 4],
        ]),
      ),
      clock: () => DateTime.utc(2026, 7, 20, 12),
      importIdFactory: (_) => 'oversize',
      maximumPackageBytes: 3,
    );

    await expectLater(gateway.pickPackage(), _failureCode('oversize_package'));
    expect(await directories.incomingBackups.exists(), isFalse);
  });

  test('copy stream failure cleans exact incoming paths', () async {
    final controller = StreamController<List<int>>();
    final gateway = _gateway(
      directories,
      id: 'copy-failure',
      picker: () async => PlatformFile(
        name: 'copy.csebackup',
        size: 0,
        readStream: controller.stream,
      ),
    );
    scheduleMicrotask(() {
      controller.add([1, 2, 3]);
      controller.addError(StateError('injected stream failure'));
      controller.close();
    });

    await expectLater(
      gateway.pickPackage(),
      _failureCode('package_import_failed'),
    );
    expect(await directories.incomingBackups.exists(), isFalse);
  });

  test('hash verification failure cleans partial and final paths', () async {
    final gateway = DeviceMobileBackupFileGateway(
      directories: directories,
      picker: () async => _memorySelection('hash.csebackup', [1, 2, 3]),
      clock: () => DateTime.utc(2026, 7, 20, 12),
      importIdFactory: (_) => 'hash-failure',
      importHooks: MobileBackupImportHooks(
        afterCopyBeforeVerification: (partial) async {
          await partial.writeAsBytes([9, 9, 9], flush: true);
        },
      ),
    );

    await expectLater(
      gateway.pickPackage(),
      _failureCode('package_import_verification_failed'),
    );
    expect(await directories.incomingBackups.exists(), isFalse);
  });

  test('rename failure cleans partial and never creates final', () async {
    final gateway = DeviceMobileBackupFileGateway(
      directories: directories,
      picker: () async => _memorySelection('rename.csebackup', [1, 2, 3]),
      clock: () => DateTime.utc(2026, 7, 20, 12),
      importIdFactory: (_) => 'rename-failure',
      importHooks: MobileBackupImportHooks(
        beforeAtomicRename: (_, _) async => throw StateError('rename failed'),
      ),
    );

    await expectLater(
      gateway.pickPackage(),
      _failureCode('package_import_failed'),
    );
    expect(await directories.incomingBackups.exists(), isFalse);
  });

  test('cleanup deletes only the exact validated incoming package', () async {
    final gateway = _gateway(
      directories,
      id: 'safe-cleanup',
      picker: () async => _memorySelection('safe.csebackup', [1, 2, 3]),
    );
    final imported = (await gateway.pickPackage())!;
    final outside = File(path.join(temporaryRoot.path, 'outside.csebackup'));
    await outside.writeAsBytes([7, 8, 9], flush: true);

    await gateway.cleanupPickedPackage(
      PickedBackupPackage(
        stablePath: outside.path,
        originalFileName: imported.originalFileName,
        byteSize: imported.byteSize,
        sha256: imported.sha256,
        importOperationId: imported.importOperationId,
      ),
    );
    expect(await outside.exists(), isTrue);
    expect(await File(imported.stablePath).exists(), isTrue);

    await gateway.cleanupPickedPackage(imported);
    expect(await File(imported.stablePath).exists(), isFalse);
    expect(await directories.incomingBackups.exists(), isFalse);
  });

  test(
    'reconciliation removes parts and expired finals only inside root',
    () async {
      final now = DateTime.utc(2026, 7, 20, 12);
      await directories.incomingBackups.create(recursive: true);
      final oldPart = await _writeIncoming(directories, 'old.part');
      final freshPart = await _writeIncoming(directories, 'fresh.part');
      final oldFinal = await _writeIncoming(directories, 'old.csebackup');
      final freshFinal = await _writeIncoming(directories, 'fresh.csebackup');
      final unknown = await _writeIncoming(directories, 'keep.txt');
      final outside = File(path.join(temporaryRoot.path, 'outside.part'));
      await outside.writeAsBytes([1], flush: true);
      await oldPart.setLastModified(now.subtract(const Duration(days: 2)));
      await freshPart.setLastModified(now);
      await oldFinal.setLastModified(now.subtract(const Duration(days: 2)));
      await freshFinal.setLastModified(now);
      final gateway = DeviceMobileBackupFileGateway(
        directories: directories,
        picker: () async => null,
        clock: () => now,
      );

      await gateway.reconcileIncomingPackages();

      expect(await oldPart.exists(), isFalse);
      expect(await freshPart.exists(), isFalse);
      expect(await oldFinal.exists(), isFalse);
      expect(await freshFinal.exists(), isTrue);
      expect(await unknown.exists(), isTrue);
      expect(await outside.exists(), isTrue);
    },
  );
}

DeviceMobileBackupFileGateway _gateway(
  AppDirectories directories, {
  required String id,
  required BackupPackagePicker picker,
}) => DeviceMobileBackupFileGateway(
  directories: directories,
  picker: picker,
  clock: () => DateTime.utc(2026, 7, 20, 12),
  importIdFactory: (_) => id,
);

PlatformFile _memorySelection(String name, List<int> bytes) => PlatformFile(
  name: name,
  size: bytes.length,
  readStream: Stream.value(List<int>.unmodifiable(bytes)),
);

Future<File> _writeIncoming(AppDirectories directories, String fileName) async {
  final file = File(path.join(directories.incomingBackups.path, fileName));
  await file.writeAsBytes([1, 2, 3], flush: true);
  return file;
}

Matcher _failureCode(String code) => throwsA(
  isA<MobileBackupFailure>().having((failure) => failure.code, 'code', code),
);
