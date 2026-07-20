import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chief_site_engineer/domain/mobile_backup_models.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart' as hashes;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

typedef BackupPackagePicker = Future<PlatformFile?> Function();
typedef BackupImportClock = DateTime Function();
typedef BackupImportIdFactory = String Function(DateTime operationTime);

abstract interface class MobileBackupFileGateway {
  Future<PickedBackupPackage?> pickPackage();
  Future<void> cleanupPickedPackage(PickedBackupPackage package);
  Future<void> reconcileIncomingPackages();
  Future<void> sharePackage(String absolutePath);
}

class MobileBackupImportHooks {
  const MobileBackupImportHooks({
    this.afterCopyBeforeVerification,
    this.beforeAtomicRename,
  });

  final Future<void> Function(File partial)? afterCopyBeforeVerification;
  final Future<void> Function(File partial, File destination)?
  beforeAtomicRename;
}

class DeviceMobileBackupFileGateway implements MobileBackupFileGateway {
  DeviceMobileBackupFileGateway({
    required this.directories,
    BackupPackagePicker? picker,
    BackupImportClock? clock,
    BackupImportIdFactory? importIdFactory,
    this.maximumPackageBytes = 512 * 1024 * 1024,
    this.incomingRetention = const Duration(hours: 24),
    this.importHooks = const MobileBackupImportHooks(),
  }) : picker = picker ?? _pickBackupPlatformFile,
       clock = clock ?? _utcNow,
       importIdFactory = importIdFactory ?? _secureImportId;

  final AppDirectories directories;
  final BackupPackagePicker picker;
  final BackupImportClock clock;
  final BackupImportIdFactory importIdFactory;
  final int maximumPackageBytes;
  final Duration incomingRetention;
  final MobileBackupImportHooks importHooks;

  @override
  Future<PickedBackupPackage?> pickPackage() async {
    final selected = await picker();
    if (selected == null) return null;
    _validateSafeFileName(selected.name);
    if (selected.size > maximumPackageBytes) {
      throw const MobileBackupFailure(
        'oversize_package',
        'Yedek paket boyutu güvenli sınırı aşıyor.',
      );
    }
    final sourceStream = selected.readStream ?? _pathStream(selected.path);
    if (sourceStream == null) {
      throw const MobileBackupFailure(
        'package_import_unavailable',
        'Seçilen yedek güvenli alana alınamadı.',
      );
    }

    directories.validate();
    final incomingRoot = directories.incomingBackups;
    await incomingRoot.create(recursive: true);
    final operationTime = clock().toUtc();
    final operationId = importIdFactory(operationTime);
    _validateOperationId(operationId);
    final partial = _resolveIncomingChild('$operationId.part');
    final destination = _resolveIncomingChild('$operationId.csebackup');
    if (await partial.exists() || await destination.exists()) {
      throw const MobileBackupFailure(
        'package_import_collision',
        'Yedek güvenli alana alınamadı.',
      );
    }

    var partialCreated = false;
    var destinationCreated = false;
    IOSink? output;
    ByteConversionSink? digestInput;
    try {
      await partial.create(exclusive: true);
      partialCreated = true;
      output = partial.openWrite();
      final digestOutput = _DigestSink();
      digestInput = hashes.sha256.startChunkedConversion(digestOutput);
      var copiedBytes = 0;
      await for (final chunk in sourceStream) {
        if (chunk.isEmpty) continue;
        copiedBytes += chunk.length;
        if (copiedBytes > maximumPackageBytes) {
          throw const MobileBackupFailure(
            'oversize_package',
            'Yedek paket boyutu güvenli sınırı aşıyor.',
          );
        }
        digestInput.add(chunk);
        output.add(chunk);
      }
      digestInput.close();
      digestInput = null;
      await output.flush();
      await output.close();
      output = null;
      if (copiedBytes <= 0 ||
          (selected.size > 0 && selected.size != copiedBytes)) {
        throw const MobileBackupFailure(
          'package_import_size_mismatch',
          'Seçilen yedek güvenli alana alınamadı.',
        );
      }
      final copiedDigest = digestOutput.value?.toString();
      if (copiedDigest == null) {
        throw const MobileBackupFailure(
          'package_import_verification_failed',
          'Seçilen yedek güvenli alana alınamadı.',
        );
      }

      await importHooks.afterCopyBeforeVerification?.call(partial);
      final partialInspection = await _inspectFile(partial);
      if (partialInspection.byteSize != copiedBytes ||
          partialInspection.sha256 != copiedDigest) {
        throw const MobileBackupFailure(
          'package_import_verification_failed',
          'Seçilen yedek güvenli alana alınamadı.',
        );
      }
      await importHooks.beforeAtomicRename?.call(partial, destination);
      await partial.rename(destination.path);
      partialCreated = false;
      destinationCreated = true;
      final finalInspection = await _inspectFile(destination);
      if (finalInspection.byteSize != copiedBytes ||
          finalInspection.sha256 != copiedDigest) {
        throw const MobileBackupFailure(
          'package_import_verification_failed',
          'Seçilen yedek güvenli alana alınamadı.',
        );
      }
      final imported = PickedBackupPackage(
        stablePath: destination.path,
        originalFileName: selected.name,
        byteSize: copiedBytes,
        sha256: copiedDigest,
        importOperationId: operationId,
      );
      destinationCreated = false;
      return imported;
    } on MobileBackupFailure {
      rethrow;
    } on Object {
      throw const MobileBackupFailure(
        'package_import_failed',
        'Seçilen yedek güvenli alana alınamadı.',
      );
    } finally {
      try {
        digestInput?.close();
      } on Object {
        // The import failure below remains the only user-facing diagnostic.
      }
      try {
        await output?.close();
      } on Object {
        // The exact partial path is cleaned below.
      }
      if (partialCreated) await _deleteExactIncomingFile(partial);
      if (destinationCreated) await _deleteExactIncomingFile(destination);
    }
  }

  @override
  Future<void> cleanupPickedPackage(PickedBackupPackage package) async {
    final candidate = _incomingFileForPackage(package);
    if (candidate == null) return;
    await _deleteExactIncomingFile(candidate);
  }

  @override
  Future<void> reconcileIncomingPackages() async {
    directories.validate();
    final incomingRoot = directories.incomingBackups;
    if (!await incomingRoot.exists()) return;
    final cutoff = clock().toUtc().subtract(incomingRetention);
    await for (final entity in incomingRoot.list(followLinks: false)) {
      final candidate = path.normalize(path.absolute(entity.path));
      final root = path.normalize(path.absolute(incomingRoot.path));
      if (path.dirname(candidate) != root) continue;
      final type = await FileSystemEntity.type(candidate, followLinks: false);
      if (type != FileSystemEntityType.file) continue;
      final name = path.basename(candidate);
      if (_partialName.hasMatch(name)) {
        await File(candidate).delete();
        continue;
      }
      if (!_finalName.hasMatch(name)) continue;
      final modified = (await File(candidate).lastModified()).toUtc();
      if (!modified.isAfter(cutoff)) await File(candidate).delete();
    }
    if (await incomingRoot.list(followLinks: false).isEmpty) {
      await incomingRoot.delete();
    }
  }

  @override
  Future<void> sharePackage(String absolutePath) async {
    final file = File(path.normalize(path.absolute(absolutePath)));
    if (!await file.exists() ||
        path.extension(file.path).toLowerCase() != '.csebackup') {
      throw StateError('backup package is unavailable');
    }
    await SharePlus.instance.share(
      ShareParams(
        title: 'CSE Mobil Tam Yedek',
        subject: 'CSE Mobil Tam Yedek',
        text: 'Parola korumalı CSE mobil yedeği',
        files: [XFile(file.path, mimeType: 'application/vnd.cse.backup')],
      ),
    );
  }

  Stream<List<int>>? _pathStream(String? selectedPath) {
    if (selectedPath == null || selectedPath.trim().isEmpty) return null;
    return File(path.normalize(path.absolute(selectedPath))).openRead();
  }

  Future<({int byteSize, String sha256})> _inspectFile(File file) async {
    final output = _DigestSink();
    final input = hashes.sha256.startChunkedConversion(output);
    var byteSize = 0;
    await for (final chunk in file.openRead()) {
      byteSize += chunk.length;
      if (byteSize > maximumPackageBytes) {
        input.close();
        throw const MobileBackupFailure(
          'oversize_package',
          'Yedek paket boyutu güvenli sınırı aşıyor.',
        );
      }
      input.add(chunk);
    }
    input.close();
    final digest = output.value;
    if (digest == null) {
      throw const MobileBackupFailure(
        'package_import_verification_failed',
        'Seçilen yedek güvenli alana alınamadı.',
      );
    }
    return (byteSize: byteSize, sha256: digest.toString());
  }

  File _resolveIncomingChild(String fileName) {
    final root = path.normalize(
      path.absolute(directories.incomingBackups.path),
    );
    final candidate = path.normalize(path.absolute(path.join(root, fileName)));
    if (path.dirname(candidate) != root || !path.isWithin(root, candidate)) {
      throw const MobileBackupFailure(
        'unsafe_incoming_path',
        'Yedek içe aktarma yolu güvenli değil.',
      );
    }
    return File(candidate);
  }

  File? _incomingFileForPackage(PickedBackupPackage package) {
    if (!_operationId.hasMatch(package.importOperationId)) return null;
    final expected = _resolveIncomingChild(
      '${package.importOperationId}.csebackup',
    );
    final candidate = path.normalize(path.absolute(package.stablePath));
    return candidate == expected.path ? expected : null;
  }

  Future<void> _deleteExactIncomingFile(File file) async {
    final root = path.normalize(
      path.absolute(directories.incomingBackups.path),
    );
    final candidate = path.normalize(path.absolute(file.path));
    if (path.dirname(candidate) != root || !path.isWithin(root, candidate)) {
      return;
    }
    final type = await FileSystemEntity.type(candidate, followLinks: false);
    if (type == FileSystemEntityType.file) await File(candidate).delete();
    final incomingRoot = directories.incomingBackups;
    if (await incomingRoot.exists() &&
        await incomingRoot.list(followLinks: false).isEmpty) {
      await incomingRoot.delete();
    }
  }

  void _validateSafeFileName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 255 ||
        path.basename(trimmed) != trimmed ||
        _unsafeFileName.hasMatch(trimmed) ||
        path.extension(trimmed).toLowerCase() != '.csebackup') {
      throw const MobileBackupFailure(
        'invalid_package_name',
        'Yalnız güvenli adlı .csebackup dosyaları seçilebilir.',
      );
    }
  }

  void _validateOperationId(String value) {
    if (!_operationId.hasMatch(value)) {
      throw const MobileBackupFailure(
        'invalid_import_operation',
        'Yedek içe aktarma işlemi başlatılamadı.',
      );
    }
  }

  static final RegExp _unsafeFileName = RegExp(r'[\x00-\x1f\x7f/\\]');
  static final RegExp _operationId = RegExp(
    r'^[0-9A-Za-z][0-9A-Za-z_-]{0,127}$',
  );
  static final RegExp _partialName = RegExp(
    r'^[0-9A-Za-z][0-9A-Za-z_-]{0,127}\.part$',
  );
  static final RegExp _finalName = RegExp(
    r'^[0-9A-Za-z][0-9A-Za-z_-]{0,127}\.csebackup$',
  );
}

class _DigestSink implements Sink<hashes.Digest> {
  hashes.Digest? value;

  @override
  void add(hashes.Digest data) => value = data;

  @override
  void close() {}
}

Future<PlatformFile?> _pickBackupPlatformFile() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    withData: false,
    withReadStream: true,
    type: FileType.custom,
    allowedExtensions: const ['csebackup'],
  );
  if (result == null || result.files.isEmpty) return null;
  return result.files.single;
}

DateTime _utcNow() => DateTime.now().toUtc();

String _secureImportId(DateTime operationTime) {
  final random = Random.secure();
  final suffix = List<int>.generate(
    8,
    (_) => random.nextInt(256),
  ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${operationTime.toUtc().microsecondsSinceEpoch}-$suffix';
}
