import 'dart:io';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/platform/concrete_attachment_gateway.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';

const pourId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const attachmentId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const nonJpegAttachmentId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

void main() {
  late Directory root;
  late AppDirectories directories;
  late DeviceConcreteAttachmentStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cse_concrete_attachment_');
    directories = AppDirectories.fromSupportRoot(root, AppEnvironment.debug);
    store = DeviceConcreteAttachmentStore(
      directories: directories,
      maximumBytes: 32,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'sniffs MIME hashes and atomically stores only a relative logical path',
    () async {
      final staged = await store.stage(
        pourId: pourId,
        attachmentId: attachmentId,
        originalFileName: 'kanıt.jpg',
        bytes: const [0xff, 0xd8, 0xff, 1, 2, 3],
      );
      expect(staged.mimeType, 'image/jpeg');
      expect(staged.relativePath, 'managed/$attachmentId.jpg');
      expect(staged.relativePath, isNot(contains(root.path)));
      expect(await directories.staging.list().isEmpty, isTrue);
      expect(
        await store.inspect(staged.relativePath, staged.sha256Value),
        ConcreteAttachmentIntegrity.ok,
      );

      final file = File(
        '${directories.attachments.path}${Platform.pathSeparator}managed'
        '${Platform.pathSeparator}$attachmentId.jpg',
      );
      await file.writeAsBytes(const [0xff, 0xd8, 0xff, 9]);
      expect(
        await store.inspect(staged.relativePath, staged.sha256Value),
        ConcreteAttachmentIntegrity.tampered,
      );
      await store.cleanup(staged.relativePath);
      expect(await file.exists(), isFalse);
    },
  );

  test(
    'keeps non-JPEG integrity ok when MIME expectation is omitted',
    () async {
      final staged = await store.stage(
        pourId: pourId,
        attachmentId: nonJpegAttachmentId,
        originalFileName: 'rapor.pdf',
        bytes: const [0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x37],
      );

      expect(staged.mimeType, 'application/pdf');
      expect(
        await store.inspect(staged.relativePath, staged.sha256Value),
        ConcreteAttachmentIntegrity.ok,
      );
    },
  );

  test(
    'rejects spoofed MIME traversal oversize and duplicate destination',
    () async {
      await expectLater(
        store.stage(
          pourId: pourId,
          attachmentId: attachmentId,
          originalFileName: 'fake.jpg',
          bytes: const [1, 2, 3, 4],
        ),
        throwsA(isA<ConcreteAttachmentFailure>()),
      );
      await expectLater(
        store.stage(
          pourId: pourId,
          attachmentId: attachmentId,
          originalFileName: '../escape.jpg',
          bytes: const [0xff, 0xd8, 0xff, 1],
        ),
        throwsA(isA<ConcreteAttachmentFailure>()),
      );
      await expectLater(
        store.stage(
          pourId: pourId,
          attachmentId: attachmentId,
          originalFileName: 'huge.jpg',
          bytes: List<int>.filled(33, 0xff),
        ),
        throwsA(isA<ConcreteAttachmentFailure>()),
      );
      await store.stage(
        pourId: pourId,
        attachmentId: attachmentId,
        originalFileName: 'first.jpg',
        bytes: const [0xff, 0xd8, 0xff, 1],
      );
      await expectLater(
        store.stage(
          pourId: pourId,
          attachmentId: attachmentId,
          originalFileName: 'second.jpg',
          bytes: const [0xff, 0xd8, 0xff, 2],
        ),
        throwsA(isA<ConcreteAttachmentFailure>()),
      );
    },
  );
}
