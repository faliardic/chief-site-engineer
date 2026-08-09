import 'dart:io';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

const _attachmentJpeg = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _attachmentPng = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _attachmentHeic = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _attachmentPdf = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _attachmentMp4 = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _attachmentMp3 = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
const _attachmentM4a = '11111111-1111-4111-8111-111111111111';
const _attachmentWav = '22222222-2222-4222-8222-222222222222';

const _jpeg = <int>[0xff, 0xd8, 0xff, 0x01];
const _png = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x01];
const _heic = <int>[
  0x00,
  0x00,
  0x00,
  0x18,
  0x66,
  0x74,
  0x79,
  0x70,
  0x68,
  0x65,
  0x69,
  0x63,
];
const _pdf = <int>[0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x37];
const _mp4 = <int>[
  0x00,
  0x00,
  0x00,
  0x18,
  0x66,
  0x74,
  0x79,
  0x70,
  0x6d,
  0x70,
  0x34,
  0x32,
];
const _mp3 = <int>[0x49, 0x44, 0x33, 0x04];
const _m4a = <int>[
  0x00,
  0x00,
  0x00,
  0x18,
  0x66,
  0x74,
  0x79,
  0x70,
  0x4d,
  0x34,
  0x41,
  0x20,
];
const _wav = <int>[
  0x52,
  0x49,
  0x46,
  0x46,
  0x04,
  0x00,
  0x00,
  0x00,
  0x57,
  0x41,
  0x56,
  0x45,
];

void main() {
  late Directory root;
  late AppDirectories directories;
  late DeviceManagedAttachmentStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cse_managed_attachment_');
    directories = AppDirectories.fromSupportRoot(root, AppEnvironment.debug);
    store = DeviceManagedAttachmentStore(
      directories: directories,
      maximumBytes: 32,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'writes every supported type to feature-neutral managed paths',
    () async {
      final fixtures = <(String, String, List<int>, String)>[
        (_attachmentJpeg, 'photo.jpeg', _jpeg, 'image/jpeg'),
        (_attachmentPng, 'drawing.png', _png, 'image/png'),
        (_attachmentHeic, 'camera.heic', _heic, 'image/heic'),
        (_attachmentPdf, 'report.pdf', _pdf, 'application/pdf'),
        (_attachmentMp4, 'walkthrough.mp4', _mp4, 'video/mp4'),
        (_attachmentMp3, 'note.mp3', _mp3, 'audio/mpeg'),
        (_attachmentM4a, 'note.m4a', _m4a, 'audio/mp4'),
        (_attachmentWav, 'note.wav', _wav, 'audio/wav'),
      ];

      for (final fixture in fixtures) {
        final staged = await store.stage(
          attachmentId: fixture.$1,
          originalFileName: fixture.$2,
          bytes: fixture.$3,
        );
        final extension = DeviceManagedAttachmentStore.extensionForMime(
          fixture.$4,
        );
        expect(staged.relativePath, 'managed/${fixture.$1}$extension');
        expect(staged.mimeType, fixture.$4);
        expect(staged.byteSize, fixture.$3.length);
        expect(staged.sha256Value, sha256.convert(fixture.$3).toString());
        expect(
          await store.inspect(
            relativePath: staged.relativePath,
            expectedSha256: staged.sha256Value,
            expectedMimeType: staged.mimeType,
            expectedByteSize: staged.byteSize,
          ),
          ManagedAttachmentIntegrity.healthy,
        );
      }
      expect(await directories.staging.list().isEmpty, isTrue);
    },
  );

  test('keeps legacy Agenda and Concrete paths readable in place', () async {
    await directories.ensureCreated();
    final agenda = File(
      path.join(directories.attachments.path, 'agenda', 'old', 'photo.jpg'),
    );
    final concrete = File(
      path.join(directories.attachments.path, 'concrete', 'old', 'report.pdf'),
    );
    await agenda.parent.create(recursive: true);
    await concrete.parent.create(recursive: true);
    await agenda.writeAsBytes(_jpeg, flush: true);
    await concrete.writeAsBytes(_pdf, flush: true);

    expect(
      await store.inspect(
        relativePath: 'agenda/old/photo.jpg',
        expectedSha256: sha256.convert(_jpeg).toString(),
        expectedMimeType: 'image/jpeg',
        expectedByteSize: _jpeg.length,
      ),
      ManagedAttachmentIntegrity.healthy,
    );
    expect(
      (await store.read(
        relativePath: 'concrete/old/report.pdf',
        originalFileName: 'legacy.pdf',
        expectedSha256: sha256.convert(_pdf).toString(),
        expectedMimeType: 'application/pdf',
        expectedByteSize: _pdf.length,
      )).bytes,
      _pdf,
    );
    await expectLater(
      store.cleanup('agenda/old/photo.jpg'),
      throwsA(
        isA<ManagedAttachmentFailure>().having(
          (error) => error.code,
          'code',
          'cleanup_path_not_managed',
        ),
      ),
    );
    expect(await agenda.exists(), isTrue);
  });

  test(
    're-read verification cleans only the current staging artifact',
    () async {
      final corruptingStore = DeviceManagedAttachmentStore(
        directories: directories,
        afterStageWrite: (staging, _) =>
            staging.writeAsBytes(const [0xff, 0xd8, 0xff, 0x09], flush: true),
      );

      await expectLater(
        corruptingStore.stage(
          attachmentId: _attachmentJpeg,
          originalFileName: 'photo.jpg',
          bytes: _jpeg,
        ),
        throwsA(
          isA<ManagedAttachmentFailure>().having(
            (error) => error.code,
            'code',
            'staging_hash_mismatch',
          ),
        ),
      );
      expect(await directories.staging.list().isEmpty, isTrue);
      expect(
        await File(
          path.join(
            directories.attachments.path,
            'managed',
            '$_attachmentJpeg.jpg',
          ),
        ).exists(),
        isFalse,
      );

      final existing = File(
        path.join(
          directories.attachments.path,
          'managed',
          '$_attachmentJpeg.jpg',
        ),
      );
      await existing.parent.create(recursive: true);
      await existing.writeAsBytes(const [7, 7, 7], flush: true);
      await expectLater(
        store.stage(
          attachmentId: _attachmentJpeg,
          originalFileName: 'collision.jpg',
          bytes: _jpeg,
        ),
        throwsA(isA<ManagedAttachmentFailure>()),
      );
      expect(await existing.readAsBytes(), [7, 7, 7]);
    },
  );

  test('reports missing size hash MIME and unsafe path separately', () async {
    final staged = await store.stage(
      attachmentId: _attachmentJpeg,
      originalFileName: 'photo.jpg',
      bytes: _jpeg,
    );
    final file = File(
      path.joinAll([
        directories.attachments.path,
        ...staged.relativePath.split('/'),
      ]),
    );
    await file.delete();
    expect(
      await _inspect(store, staged),
      ManagedAttachmentIntegrity.missingFile,
    );

    await file.writeAsBytes(const [0xff, 0xd8, 0xff, 1, 2], flush: true);
    expect(
      await _inspect(store, staged),
      ManagedAttachmentIntegrity.sizeMismatch,
    );

    await file.writeAsBytes(const [0xff, 0xd8, 0xff, 9], flush: true);
    expect(
      await _inspect(store, staged),
      ManagedAttachmentIntegrity.hashMismatch,
    );

    expect(
      await store.inspect(
        relativePath: staged.relativePath,
        expectedSha256: sha256.convert(const [0xff, 0xd8, 0xff, 9]).toString(),
        expectedMimeType: 'image/png',
        expectedByteSize: 4,
      ),
      ManagedAttachmentIntegrity.mimeMismatch,
    );
    expect(
      await store.inspect(
        relativePath: '../outside.jpg',
        expectedSha256: staged.sha256Value,
        expectedMimeType: staged.mimeType,
      ),
      ManagedAttachmentIntegrity.unsafePath,
    );
  });

  test(
    'rejects unsafe names sizes MIME paths and non-regular entries',
    () async {
      for (final name in ['../escape.jpg', r'C:\escape.jpg', '']) {
        await expectLater(
          store.stage(
            attachmentId: _attachmentJpeg,
            originalFileName: name,
            bytes: _jpeg,
          ),
          throwsA(isA<ManagedAttachmentFailure>()),
        );
      }
      await expectLater(
        store.stage(
          attachmentId: _attachmentJpeg,
          originalFileName: 'empty.jpg',
          bytes: const [],
        ),
        throwsA(isA<ManagedAttachmentFailure>()),
      );
      await expectLater(
        store.stage(
          attachmentId: _attachmentJpeg,
          originalFileName: 'large.jpg',
          bytes: List<int>.filled(33, 1),
        ),
        throwsA(isA<ManagedAttachmentFailure>()),
      );
      await expectLater(
        store.stage(
          attachmentId: _attachmentJpeg,
          originalFileName: 'spoof.jpg',
          bytes: const [1, 2, 3, 4],
        ),
        throwsA(isA<ManagedAttachmentFailure>()),
      );

      await directories.ensureCreated();
      final nonRegular = Directory(
        path.join(
          directories.attachments.path,
          'managed',
          '$_attachmentJpeg.jpg',
        ),
      );
      await nonRegular.create(recursive: true);
      expect(
        await store.inspect(
          relativePath: 'managed/$_attachmentJpeg.jpg',
          expectedSha256: sha256.convert(_jpeg).toString(),
          expectedMimeType: 'image/jpeg',
        ),
        ManagedAttachmentIntegrity.unsafePath,
      );

      final external = await Directory.systemTemp.createTemp(
        'cse_managed_link_target_',
      );
      try {
        final link = Link(
          path.join(directories.attachments.path, 'legacy-link'),
        );
        var linkCreated = false;
        try {
          await link.create(external.path);
          linkCreated = true;
        } on FileSystemException {
          // Some Windows policies disallow creating test symlinks. The same
          // fail-closed branch is still exercised by the non-regular fixture.
        }
        if (linkCreated) {
          expect(
            await store.inspect(
              relativePath: 'legacy-link/photo.jpg',
              expectedSha256: sha256.convert(_jpeg).toString(),
              expectedMimeType: 'image/jpeg',
            ),
            ManagedAttachmentIntegrity.unsafePath,
          );
        }
      } finally {
        if (await external.exists()) await external.delete(recursive: true);
      }
    },
  );
}

Future<ManagedAttachmentIntegrity> _inspect(
  DeviceManagedAttachmentStore store,
  ManagedAttachmentWrite staged,
) => store.inspect(
  relativePath: staged.relativePath,
  expectedSha256: staged.sha256Value,
  expectedMimeType: staged.mimeType,
  expectedByteSize: staged.byteSize,
);
