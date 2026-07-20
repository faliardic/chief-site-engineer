import 'dart:io';

import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

class AgendaAttachmentFailure implements Exception {
  const AgendaAttachmentFailure(this.code);

  final String code;

  @override
  String toString() => code;
}

class StagedAgendaPhoto {
  const StagedAgendaPhoto({
    required this.relativePath,
    required this.mimeType,
    required this.byteSize,
    required this.sha256Value,
  });

  final String relativePath;
  final String mimeType;
  final int byteSize;
  final String sha256Value;
}

abstract interface class AgendaAttachmentStore {
  Future<StagedAgendaPhoto> stage({
    required String logId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  });

  Future<AgendaAttachmentIntegrity> inspect(
    String relativePath,
    String expectedSha256,
    String expectedMimeType,
  );

  Future<StoredAttachmentContent> read(
    String relativePath,
    String originalFileName,
    String expectedSha256,
    String expectedMimeType,
  );

  Future<void> cleanup(String relativePath);
}

class UnavailableAgendaAttachmentStore implements AgendaAttachmentStore {
  const UnavailableAgendaAttachmentStore();

  @override
  Future<void> cleanup(String relativePath) async {}

  @override
  Future<AgendaAttachmentIntegrity> inspect(
    String relativePath,
    String expectedSha256,
    String expectedMimeType,
  ) async => AgendaAttachmentIntegrity.missing;

  @override
  Future<StoredAttachmentContent> read(
    String relativePath,
    String originalFileName,
    String expectedSha256,
    String expectedMimeType,
  ) => throw const AgendaAttachmentFailure('attachment_unavailable');

  @override
  Future<StagedAgendaPhoto> stage({
    required String logId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) => throw const AgendaAttachmentFailure('attachment_unavailable');
}

class DeviceAgendaAttachmentStore implements AgendaAttachmentStore {
  const DeviceAgendaAttachmentStore({
    required this.directories,
    this.maximumBytes = 20 * 1024 * 1024,
  });

  final AppDirectories directories;
  final int maximumBytes;

  @override
  Future<StagedAgendaPhoto> stage({
    required String logId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) async {
    validateUuid(logId, 'Log kimliği');
    validateUuid(attachmentId, 'Fotoğraf kimliği');
    final safeName = path.basename(originalFileName.trim());
    if (safeName.isEmpty || safeName != originalFileName.trim()) {
      throw const AgendaAttachmentFailure('invalid_file_name');
    }
    if (bytes.isEmpty || bytes.length > maximumBytes) {
      throw const AgendaAttachmentFailure('invalid_file_size');
    }
    final mime = _sniffMime(bytes);
    final extension = mime == 'image/jpeg' ? '.jpg' : '.png';
    directories.validate();
    await directories.ensureCreated();
    final relative = path.posix.join(
      'agenda',
      logId,
      '$attachmentId$extension',
    );
    final destination = _resolve(relative);
    final temporary = File(
      path.join(directories.staging.path, 'agenda-$attachmentId.part'),
    );
    if (await destination.exists() || await temporary.exists()) {
      throw const AgendaAttachmentFailure('attachment_destination_exists');
    }
    await destination.parent.create(recursive: true);
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      final stagedDigest = sha256.convert(await temporary.readAsBytes());
      final expectedDigest = sha256.convert(bytes);
      if (stagedDigest != expectedDigest) {
        throw const AgendaAttachmentFailure('staging_hash_mismatch');
      }
      await temporary.rename(destination.path);
      return StagedAgendaPhoto(
        relativePath: relative,
        mimeType: mime,
        byteSize: bytes.length,
        sha256Value: expectedDigest.toString(),
      );
    } on Object {
      if (await temporary.exists()) await temporary.delete();
      if (await destination.exists()) await destination.delete();
      rethrow;
    }
  }

  @override
  Future<AgendaAttachmentIntegrity> inspect(
    String relativePath,
    String expectedSha256,
    String expectedMimeType,
  ) async {
    final file = _resolve(relativePath);
    if (!await file.exists()) return AgendaAttachmentIntegrity.missing;
    final bytes = await file.readAsBytes();
    if (sha256.convert(bytes).toString() != expectedSha256) {
      return AgendaAttachmentIntegrity.tampered;
    }
    try {
      if (_sniffMime(bytes) != expectedMimeType) {
        return AgendaAttachmentIntegrity.invalidMime;
      }
    } on AgendaAttachmentFailure {
      return AgendaAttachmentIntegrity.invalidMime;
    }
    return AgendaAttachmentIntegrity.ok;
  }

  @override
  Future<StoredAttachmentContent> read(
    String relativePath,
    String originalFileName,
    String expectedSha256,
    String expectedMimeType,
  ) async {
    final integrity = await inspect(
      relativePath,
      expectedSha256,
      expectedMimeType,
    );
    if (integrity != AgendaAttachmentIntegrity.ok) {
      throw AgendaAttachmentFailure('attachment_${integrity.name}');
    }
    return StoredAttachmentContent(
      fileName: path.basename(originalFileName),
      mimeType: expectedMimeType,
      bytes: await _resolve(relativePath).readAsBytes(),
    );
  }

  @override
  Future<void> cleanup(String relativePath) async {
    final file = _resolve(relativePath);
    if (await file.exists()) await file.delete();
  }

  File _resolve(String relativePath) {
    directories.validate();
    if (relativePath.trim().isEmpty || path.isAbsolute(relativePath)) {
      throw const AgendaAttachmentFailure('invalid_relative_path');
    }
    final root = path.normalize(path.absolute(directories.attachments.path));
    final candidate = path.normalize(
      path.absolute(path.join(root, path.normalize(relativePath))),
    );
    if (!path.isWithin(root, candidate)) {
      throw const AgendaAttachmentFailure('attachment_path_escaped_root');
    }
    return File(candidate);
  }

  String _sniffMime(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    throw const AgendaAttachmentFailure('unsupported_mime');
  }
}
