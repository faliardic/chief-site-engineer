import 'dart:io';

import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;

typedef ManagedAttachmentStageHook =
    Future<void> Function(File stagingFile, File destinationFile);

abstract interface class ManagedAttachmentStore {
  Future<ManagedAttachmentWrite> stage({
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  });

  Future<ManagedAttachmentIntegrity> inspect({
    required String relativePath,
    required String expectedSha256,
    required String? expectedMimeType,
    int? expectedByteSize,
  });

  Future<ManagedAttachmentContent> read({
    required String relativePath,
    required String originalFileName,
    required String expectedSha256,
    required String expectedMimeType,
    int? expectedByteSize,
  });

  Future<void> open({
    required String relativePath,
    required String expectedMimeType,
  });

  Future<void> cleanup(String relativePath);
}

class DeviceManagedAttachmentStore implements ManagedAttachmentStore {
  const DeviceManagedAttachmentStore({
    required this.directories,
    this.maximumBytes = 20 * 1024 * 1024,
    this.afterStageWrite,
  });

  static final managedFinalPathPattern = RegExp(
    r'^managed/[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|png|heic|pdf|mp4|mp3|m4a|wav)$',
  );
  static final managedStagingNamePattern = RegExp(
    r'^managed-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.part$',
  );

  final AppDirectories directories;
  final int maximumBytes;
  final ManagedAttachmentStageHook? afterStageWrite;

  @override
  Future<ManagedAttachmentWrite> stage({
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) async {
    final safeName = path.basename(originalFileName.trim());
    if (safeName.isEmpty || safeName != originalFileName.trim()) {
      throw const ManagedAttachmentFailure('invalid_file_name');
    }
    if (bytes.isEmpty || bytes.length > maximumBytes) {
      throw const ManagedAttachmentFailure('invalid_file_size');
    }
    final mimeType = sniffMime(bytes);
    final extension = extensionForMime(mimeType);
    final normalizedId = attachmentId.toLowerCase();
    final relativePath = path.posix.join('managed', '$normalizedId$extension');
    if (!managedFinalPathPattern.hasMatch(relativePath)) {
      throw const ManagedAttachmentFailure('invalid_attachment_id');
    }

    directories.validate();
    await directories.ensureCreated();
    await _requireSafeDirectory(directories.attachments);
    await _requireSafeDirectory(directories.staging);
    final managedDirectory = Directory(
      path.join(directories.attachments.path, 'managed'),
    );
    final managedType = await FileSystemEntity.type(
      managedDirectory.path,
      followLinks: false,
    );
    if (managedType == FileSystemEntityType.notFound) {
      await managedDirectory.create();
    }
    await _requireSafeDirectory(managedDirectory);

    final destination = await _resolveFile(
      relativePath,
      allowMissingLeaf: true,
    );
    final temporary = File(
      path.join(directories.staging.path, 'managed-$normalizedId.part'),
    );
    final temporaryType = await FileSystemEntity.type(
      temporary.path,
      followLinks: false,
    );
    final destinationType = await FileSystemEntity.type(
      destination.path,
      followLinks: false,
    );
    if (temporaryType != FileSystemEntityType.notFound ||
        destinationType != FileSystemEntityType.notFound) {
      throw const ManagedAttachmentFailure('attachment_destination_exists');
    }

    var temporaryCreated = false;
    var finalizedByOperation = false;
    try {
      temporaryCreated = true;
      await temporary.writeAsBytes(bytes, flush: true);
      await afterStageWrite?.call(temporary, destination);
      final stagedType = await FileSystemEntity.type(
        temporary.path,
        followLinks: false,
      );
      if (stagedType != FileSystemEntityType.file) {
        throw const ManagedAttachmentFailure('staging_file_unsafe');
      }
      final stagedBytes = await temporary.readAsBytes();
      final expectedDigest = sha256.convert(bytes).toString();
      if (stagedBytes.length != bytes.length) {
        throw const ManagedAttachmentFailure('staging_size_mismatch');
      }
      if (sha256.convert(stagedBytes).toString() != expectedDigest) {
        throw const ManagedAttachmentFailure('staging_hash_mismatch');
      }
      if (sniffMime(stagedBytes) != mimeType) {
        throw const ManagedAttachmentFailure('staging_mime_mismatch');
      }
      if (await FileSystemEntity.type(destination.path, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw const ManagedAttachmentFailure('attachment_destination_exists');
      }
      await temporary.rename(destination.path);
      temporaryCreated = false;
      finalizedByOperation = true;
      return ManagedAttachmentWrite(
        relativePath: relativePath,
        mimeType: mimeType,
        byteSize: stagedBytes.length,
        sha256Value: expectedDigest,
      );
    } on Object {
      if (temporaryCreated &&
          await FileSystemEntity.type(temporary.path, followLinks: false) ==
              FileSystemEntityType.file) {
        await temporary.delete();
      }
      if (finalizedByOperation &&
          await FileSystemEntity.type(destination.path, followLinks: false) ==
              FileSystemEntityType.file) {
        await destination.delete();
      }
      rethrow;
    }
  }

  @override
  Future<ManagedAttachmentIntegrity> inspect({
    required String relativePath,
    required String expectedSha256,
    required String? expectedMimeType,
    int? expectedByteSize,
  }) async {
    File file;
    try {
      file = await _resolveFile(relativePath, allowMissingLeaf: true);
    } on ManagedAttachmentFailure {
      return ManagedAttachmentIntegrity.unsafePath;
    }
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      return ManagedAttachmentIntegrity.missingFile;
    }
    if (type != FileSystemEntityType.file) {
      return ManagedAttachmentIntegrity.unsafePath;
    }
    final bytes = await file.readAsBytes();
    if (expectedByteSize != null && bytes.length != expectedByteSize) {
      return ManagedAttachmentIntegrity.sizeMismatch;
    }
    if (sha256.convert(bytes).toString() != expectedSha256) {
      return ManagedAttachmentIntegrity.hashMismatch;
    }
    if (expectedMimeType != null) {
      try {
        if (sniffMime(bytes) != expectedMimeType) {
          return ManagedAttachmentIntegrity.mimeMismatch;
        }
      } on ManagedAttachmentFailure {
        return ManagedAttachmentIntegrity.mimeMismatch;
      }
    }
    return ManagedAttachmentIntegrity.healthy;
  }

  @override
  Future<ManagedAttachmentContent> read({
    required String relativePath,
    required String originalFileName,
    required String expectedSha256,
    required String expectedMimeType,
    int? expectedByteSize,
  }) async {
    final integrity = await inspect(
      relativePath: relativePath,
      expectedSha256: expectedSha256,
      expectedMimeType: expectedMimeType,
      expectedByteSize: expectedByteSize,
    );
    if (integrity != ManagedAttachmentIntegrity.healthy) {
      throw ManagedAttachmentFailure('attachment_${integrity.code}');
    }
    final file = await _resolveFile(relativePath, allowMissingLeaf: false);
    return ManagedAttachmentContent(
      fileName: path.basename(originalFileName),
      mimeType: expectedMimeType,
      bytes: await file.readAsBytes(),
    );
  }

  @override
  Future<void> open({
    required String relativePath,
    required String expectedMimeType,
  }) async {
    final file = await _resolveFile(relativePath, allowMissingLeaf: false);
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      throw const ManagedAttachmentFailure('attachment_missing_file');
    }
    if (type != FileSystemEntityType.file) {
      throw const ManagedAttachmentFailure('attachment_unsafe_path');
    }
    final bytes = await file.readAsBytes();
    if (sniffMime(bytes) != expectedMimeType) {
      throw const ManagedAttachmentFailure('attachment_mime_mismatch');
    }
    final result = await OpenFilex.open(file.path, type: expectedMimeType);
    if (result.type != ResultType.done) {
      throw ManagedAttachmentFailure('viewer_${result.type.name}');
    }
  }

  @override
  Future<void> cleanup(String relativePath) async {
    if (!managedFinalPathPattern.hasMatch(relativePath)) {
      throw const ManagedAttachmentFailure('cleanup_path_not_managed');
    }
    final file = await _resolveFile(relativePath, allowMissingLeaf: true);
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return;
    if (type != FileSystemEntityType.file) {
      throw const ManagedAttachmentFailure('cleanup_path_unsafe');
    }
    await file.delete();
  }

  Future<File> _resolveFile(
    String relativePath, {
    required bool allowMissingLeaf,
  }) async {
    directories.validate();
    if (!_isSafeRelativePath(relativePath)) {
      throw const ManagedAttachmentFailure('invalid_relative_path');
    }
    final root = path.normalize(path.absolute(directories.attachments.path));
    final parts = relativePath.split('/');
    final candidate = path.normalize(
      path.absolute(path.joinAll([root, ...parts])),
    );
    if (!path.isWithin(root, candidate)) {
      throw const ManagedAttachmentFailure('attachment_path_escaped_root');
    }

    final rootType = await FileSystemEntity.type(root, followLinks: false);
    if (rootType == FileSystemEntityType.link ||
        (rootType != FileSystemEntityType.directory &&
            rootType != FileSystemEntityType.notFound)) {
      throw const ManagedAttachmentFailure('attachment_root_unsafe');
    }
    var current = root;
    for (var index = 0; index < parts.length; index += 1) {
      current = path.join(current, parts[index]);
      final type = await FileSystemEntity.type(current, followLinks: false);
      final isLeaf = index == parts.length - 1;
      if (type == FileSystemEntityType.link) {
        throw const ManagedAttachmentFailure('attachment_path_symlink');
      }
      if (!isLeaf &&
          type != FileSystemEntityType.directory &&
          type != FileSystemEntityType.notFound) {
        throw const ManagedAttachmentFailure('attachment_path_non_directory');
      }
      if (isLeaf &&
          type != FileSystemEntityType.file &&
          type != FileSystemEntityType.notFound) {
        throw const ManagedAttachmentFailure('attachment_path_non_regular');
      }
      if (isLeaf &&
          !allowMissingLeaf &&
          type == FileSystemEntityType.notFound) {
        throw const ManagedAttachmentFailure('attachment_missing_file');
      }
    }
    return File(candidate);
  }

  Future<void> _requireSafeDirectory(Directory directory) async {
    final type = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (type != FileSystemEntityType.directory) {
      throw const ManagedAttachmentFailure('attachment_directory_unsafe');
    }
  }

  bool _isSafeRelativePath(String value) {
    if (value.isEmpty ||
        value != value.trim() ||
        path.isAbsolute(value) ||
        path.posix.isAbsolute(value) ||
        value.contains('\\') ||
        value.contains(':') ||
        value.contains('\u0000')) {
      return false;
    }
    final parts = value.split('/');
    return parts.every(
      (part) => part.isNotEmpty && part != '.' && part != '..',
    );
  }

  static String extensionForMime(String mimeType) => switch (mimeType) {
    'image/jpeg' => '.jpg',
    'image/png' => '.png',
    'image/heic' => '.heic',
    'application/pdf' => '.pdf',
    'video/mp4' => '.mp4',
    'audio/mpeg' => '.mp3',
    'audio/mp4' => '.m4a',
    'audio/wav' => '.wav',
    _ => throw const ManagedAttachmentFailure('unsupported_mime'),
  };

  static String sniffMime(List<int> bytes) {
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
    if (bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-') {
      return 'application/pdf';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE') {
      return 'audio/wav';
    }
    if (bytes.length >= 3 && String.fromCharCodes(bytes.take(3)) == 'ID3') {
      return 'audio/mpeg';
    }
    if (bytes.length >= 2 &&
        bytes[0] == 0xff &&
        (bytes[1] & 0xe0) == 0xe0 &&
        (bytes[1] & 0x06) != 0) {
      return 'audio/mpeg';
    }
    if (bytes.length >= 12) {
      final brand = String.fromCharCodes(bytes.sublist(4, 12));
      if (brand.startsWith('ftyp')) {
        final majorBrand = brand.substring(4);
        if (const {
          'heic',
          'heix',
          'hevc',
          'hevx',
          'mif1',
          'msf1',
        }.contains(majorBrand)) {
          return 'image/heic';
        }
        if (majorBrand == 'M4A ') return 'audio/mp4';
        if (const {
          'isom',
          'iso2',
          'mp41',
          'mp42',
          'avc1',
          'dash',
        }.contains(majorBrand)) {
          return 'video/mp4';
        }
      }
    }
    throw const ManagedAttachmentFailure('unsupported_mime');
  }
}
