import 'dart:io';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:chief_site_engineer/platform/inventory_attachment_gateway.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

const _assetId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _attachmentId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';

void main() {
  test(
    'camera and library pick map exact source while cancel is a no-op',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'cse_inv_gateway_pick',
      );
      addTearDown(() => root.delete(recursive: true));
      final pickerPort = _Picker();
      final gateway = _gateway(root, picker: pickerPort);

      pickerPort.next = null;
      final cancelled = await gateway.pick(InventoryPhotoSource.camera);
      expect(cancelled.outcome, InventoryPhotoPickOutcome.cancelled);
      expect(cancelled.selection, isNull);

      pickerPort.nextBytes = _jpeg(1);
      final camera = await gateway.pick(InventoryPhotoSource.camera);
      expect(camera.outcome, InventoryPhotoPickOutcome.selected);
      expect(camera.selection?.source, InventoryPhotoSource.camera);
      expect(pickerPort.lastSource, AttachmentSource.camera);

      pickerPort.nextBytes = _png(2);
      final library = await gateway.pick(InventoryPhotoSource.photoLibrary);
      expect(library.outcome, InventoryPhotoPickOutcome.selected);
      expect(library.selection?.source, InventoryPhotoSource.photoLibrary);
      expect(pickerPort.lastSource, AttachmentSource.photoLibrary);
    },
  );

  test(
    'managed image stage read integrity and cleanup stay path safe',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'cse_inv_gateway_store',
      );
      addTearDown(() => root.delete(recursive: true));
      final directories = AppDirectories.fromSupportRoot(
        root,
        AppEnvironment.debug,
      );
      final gateway = _gateway(root, directories: directories);
      final bytes = _png(3);

      final staged = await gateway.stage(
        assetId: _assetId,
        attachmentId: _attachmentId,
        originalFileName: 'asset.png',
        bytes: bytes,
      );
      expect(staged.mimeType, 'image/png');
      expect(staged.byteSize, bytes.length);
      expect(
        await gateway.inspect(
          relativePath: staged.relativePath,
          expectedSha256: staged.sha256Value,
          expectedMimeType: staged.mimeType,
          expectedByteSize: staged.byteSize,
        ),
        InventoryPhotoIntegrity.healthy,
      );
      expect(
        (await gateway.read(
          relativePath: staged.relativePath,
          originalFileName: 'asset.png',
          expectedSha256: staged.sha256Value,
          expectedMimeType: staged.mimeType,
          expectedByteSize: staged.byteSize,
        )).bytes,
        bytes,
      );

      final file = File(
        path.joinAll([
          directories.attachments.path,
          ...staged.relativePath.split('/'),
        ]),
      );
      await file.writeAsBytes(_png(4), flush: true);
      expect(
        await gateway.inspect(
          relativePath: staged.relativePath,
          expectedSha256: staged.sha256Value,
          expectedMimeType: staged.mimeType,
          expectedByteSize: staged.byteSize,
        ),
        InventoryPhotoIntegrity.hashMismatch,
      );
      expect(
        await gateway.inspect(
          relativePath: '../outside.png',
          expectedSha256: staged.sha256Value,
          expectedMimeType: staged.mimeType,
          expectedByteSize: staged.byteSize,
        ),
        InventoryPhotoIntegrity.unsafePath,
      );
      await gateway.cleanup(staged.relativePath);
      expect(await file.exists(), isFalse);
    },
  );

  test(
    'non-image managed result is rejected and operation file is cleaned',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'cse_inv_gateway_mime',
      );
      addTearDown(() => root.delete(recursive: true));
      final directories = AppDirectories.fromSupportRoot(
        root,
        AppEnvironment.debug,
      );
      final gateway = _gateway(root, directories: directories);

      await expectLater(
        gateway.stage(
          assetId: _assetId,
          attachmentId: _attachmentId,
          originalFileName: 'asset.pdf',
          bytes: '%PDF-1.4'.codeUnits,
        ),
        throwsA(
          isA<InventoryFailure>().having(
            (failure) => failure.code,
            'code',
            'inventory_photo_invalid_mime',
          ),
        ),
      );
      final managed = Directory(
        path.join(directories.attachments.path, 'managed'),
      );
      expect(
        await managed.exists() ? await managed.list().toList() : const [],
        isEmpty,
      );
    },
  );
}

DeviceInventoryAttachmentGateway _gateway(
  Directory root, {
  _Picker? picker,
  AppDirectories? directories,
}) {
  final resolvedDirectories =
      directories ?? AppDirectories.fromSupportRoot(root, AppEnvironment.debug);
  return DeviceInventoryAttachmentGateway(
    picker: SafeAttachmentPicker(
      permissions: const SafeCapabilityService(_Permission()),
      picker: picker ?? _Picker(),
    ),
    managedStore: DeviceManagedAttachmentStore(
      directories: resolvedDirectories,
    ),
  );
}

List<int> _jpeg(int suffix) => <int>[0xff, 0xd8, 0xff, suffix];

List<int> _png(int suffix) => <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  suffix,
];

class _Permission implements PermissionGateway {
  const _Permission();

  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.granted;
}

class _Picker implements AttachmentPickerPort {
  SelectedAttachment? next;
  List<int>? nextBytes;
  AttachmentSource? lastSource;

  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async {
    lastSource = source;
    final explicit = next;
    next = null;
    if (explicit != null) return explicit;
    final bytes = nextBytes;
    nextBytes = null;
    if (bytes == null) return null;
    return SelectedAttachment(
      name: source == AttachmentSource.camera ? 'camera.jpg' : 'library.png',
      bytes: bytes,
      source: source,
    );
  }
}
