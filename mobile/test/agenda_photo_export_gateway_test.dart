import 'dart:io';
import 'dart:typed_data';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/platform/agenda_photo_export_gateway.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_agenda_photo_export_',
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
    'save sends exact bytes MIME and a fail-safe basename to the system',
    () async {
      final savePort = _RecordingSavePort();
      final gateway = DeviceAgendaPhotoExportGateway(
        directories: directories,
        savePort: savePort,
        sharePort: _RecordingSharePort(),
      );

      final saved = await gateway.save(
        const AgendaPhotoExportRequest(
          fileName: r'..\Kalıp<>:"|?*.jpeg',
          mimeType: 'image/jpeg',
          bytes: [0xff, 0xd8, 0xff, 1],
        ),
      );

      expect(saved, isTrue);
      expect(savePort.calls, 1);
      expect(savePort.mimeType, 'image/jpeg');
      expect(savePort.bytes, [0xff, 0xd8, 0xff, 1]);
      expect(path.basename(savePort.fileName!), savePort.fileName);
      expect(savePort.fileName, endsWith('.jpeg'));
      expect(savePort.fileName, isNot(contains(RegExp(r'[\\/:*?"<>|]'))));
    },
  );

  test('save cancellation is a normal false result', () async {
    final savePort = _RecordingSavePort(result: false);
    final gateway = DeviceAgendaPhotoExportGateway(
      directories: directories,
      savePort: savePort,
      sharePort: _RecordingSharePort(),
    );

    final saved = await gateway.save(
      const AgendaPhotoExportRequest(
        fileName: 'saha.png',
        mimeType: 'image/png',
        bytes: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
      ),
    );

    expect(saved, isFalse);
    expect(savePort.calls, 1);
  });

  test(
    'share uses an operation export copy and removes it afterwards',
    () async {
      final sharePort = _RecordingSharePort();
      final gateway = DeviceAgendaPhotoExportGateway(
        directories: directories,
        savePort: _RecordingSavePort(),
        sharePort: sharePort,
        operationIdProvider: () => 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      );

      await gateway.share(
        const AgendaPhotoExportRequest(
          fileName: 'saha.jpg',
          mimeType: 'image/jpeg',
          bytes: [0xff, 0xd8, 0xff, 7],
        ),
      );

      expect(sharePort.calls, 1);
      expect(sharePort.fileName, 'saha.jpg');
      expect(sharePort.mimeType, 'image/jpeg');
      expect(path.basename(sharePort.absolutePath!), 'saha.jpg');
      expect(sharePort.bytesDuringShare, [0xff, 0xd8, 0xff, 7]);
      expect(sharePort.absolutePath, isNotNull);
      expect(await File(sharePort.absolutePath!).exists(), isFalse);
      expect(await directories.staging.list().toList(), isEmpty);
    },
  );

  test('share failure still removes the operation export copy', () async {
    final sharePort = _RecordingSharePort(failure: StateError('share failed'));
    final gateway = DeviceAgendaPhotoExportGateway(
      directories: directories,
      savePort: _RecordingSavePort(),
      sharePort: sharePort,
      operationIdProvider: () => 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    );

    await expectLater(
      gateway.share(
        const AgendaPhotoExportRequest(
          fileName: 'saha.jpg',
          mimeType: 'image/jpeg',
          bytes: [0xff, 0xd8, 0xff, 8],
        ),
      ),
      throwsA(isA<StateError>()),
    );

    expect(sharePort.absolutePath, isNotNull);
    expect(await File(sharePort.absolutePath!).exists(), isFalse);
  });

  test('MIME mismatch fails before save or share platform calls', () async {
    final savePort = _RecordingSavePort();
    final sharePort = _RecordingSharePort();
    final gateway = DeviceAgendaPhotoExportGateway(
      directories: directories,
      savePort: savePort,
      sharePort: sharePort,
    );
    const request = AgendaPhotoExportRequest(
      fileName: 'yanlis.png',
      mimeType: 'image/png',
      bytes: [0xff, 0xd8, 0xff, 1],
    );

    await expectLater(
      gateway.save(request),
      throwsA(
        isA<AgendaPhotoExportFailure>().having(
          (error) => error.code,
          'code',
          'photo_mime_mismatch',
        ),
      ),
    );
    await expectLater(gateway.share(request), throwsA(anything));
    expect(savePort.calls, 0);
    expect(sharePort.calls, 0);
  });
}

class _RecordingSavePort implements AgendaPhotoSavePort {
  _RecordingSavePort({this.result = true});

  final bool result;
  int calls = 0;
  String? fileName;
  String? mimeType;
  Uint8List? bytes;

  @override
  Future<bool> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    calls += 1;
    this.fileName = fileName;
    this.mimeType = mimeType;
    this.bytes = Uint8List.fromList(bytes);
    return result;
  }
}

class _RecordingSharePort implements AgendaPhotoSharePort {
  _RecordingSharePort({this.failure});

  final Object? failure;
  int calls = 0;
  String? absolutePath;
  String? fileName;
  String? mimeType;
  Uint8List? bytesDuringShare;

  @override
  Future<void> share({
    required String absolutePath,
    required String fileName,
    required String mimeType,
  }) async {
    calls += 1;
    this.absolutePath = absolutePath;
    this.fileName = fileName;
    this.mimeType = mimeType;
    bytesDuringShare = await File(absolutePath).readAsBytes();
    if (failure case final error?) throw error;
  }
}
