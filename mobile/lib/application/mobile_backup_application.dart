import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:chief_site_engineer/application/restore_recovery_application.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/mobile_backup_models.dart';
import 'package:chief_site_engineer/platform/mobile_backup_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

enum MobileBackupCreationStage { preparing, packaging, verifying, saving }

typedef MobileBackupCreationProgress =
    void Function(MobileBackupCreationStage stage);

void _reportBackupStage(
  MobileBackupCreationProgress? observer,
  MobileBackupCreationStage stage,
) {
  try {
    observer?.call(stage);
  } on Object {
    // Progress visibility must never invalidate backup truth.
  }
}

abstract interface class MobileBackupApplication {
  Future<MobileBackupCreationResult> createBackup(
    CreateMobileBackupCommand command, {
    MobileBackupCreationProgress? onProgress,
  });

  Future<void> shareBackup(String absolutePath);

  Future<PickedBackupPackage?> pickBackupPackage([
    PickedBackupPackage? currentPackage,
  ]);

  Future<void> discardBackupPackage(PickedBackupPackage package);

  Future<MobileBackupPreflight> preflightBackup(
    PickedBackupPackage package,
    String password,
  );

  Future<MobileRestoreResult> restoreBackup(RestoreMobileBackupCommand command);

  Future<MobileBackupSummary?> lastSuccessfulBackup();
}

abstract interface class MobileSafetyBackupRecoveryApplication {
  Future<List<MobileSafetyBackupMetadata>> listSafetyBackups();

  Future<void> shareSafetyBackup(MobileSafetyBackupMetadata backup);
}

class MobileRestoreHooks {
  const MobileRestoreHooks({
    this.beforeSwap,
    this.afterSwapBeforeSmoke,
    this.beforeNotificationReconcile,
  });

  final Future<void> Function()? beforeSwap;
  final Future<void> Function()? afterSwapBeforeSmoke;
  final Future<void> Function()? beforeNotificationReconcile;
}

typedef SecureRandomBytes = Uint8List Function(int length);

class CseBackupCodec {
  CseBackupCodec({
    this.kdfIterations = 210000,
    this.minimumAcceptedKdfIterations = 100000,
    this.maximumAcceptedKdfIterations = 1000000,
    SecureRandomBytes? randomBytes,
  }) : randomBytes = randomBytes ?? _secureRandomBytes;

  static const formatVersion = 1;
  static const _cipherName = 'aes-256-gcm';
  static const _kdfName = 'pbkdf2-hmac-sha256';
  static final Uint8List _magic = Uint8List.fromList(utf8.encode('CSEBKP1\n'));
  static const _maximumHeaderBytes = 4096;

  final int kdfIterations;
  final int minimumAcceptedKdfIterations;
  final int maximumAcceptedKdfIterations;
  final SecureRandomBytes randomBytes;

  Future<Uint8List> encrypt(List<int> clearBytes, String password) async {
    if (password.isEmpty) {
      throw const MobileBackupFailure(
        'invalid_password',
        'Yedek parolası boş olamaz.',
      );
    }
    final salt = randomBytes(16);
    final cipher = AesGcm.with256bits();
    final nonce = randomBytes(cipher.nonceLength);
    final header = <String, Object?>{
      'format_version': formatVersion,
      'cipher': _cipherName,
      'kdf': _kdfName,
      'kdf_iterations': kdfIterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext_length': clearBytes.length,
      'mac_length': cipher.macAlgorithm.macLength,
    };
    final headerBytes = Uint8List.fromList(utf8.encode(jsonEncode(header)));
    final headerLength = _uint32(headerBytes.length);
    final aad = Uint8List.fromList([
      ..._magic,
      ...headerLength,
      ...headerBytes,
    ]);
    final key = await Pbkdf2.hmacSha256(
      iterations: kdfIterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
    final box = await cipher.encrypt(
      clearBytes,
      secretKey: key,
      nonce: nonce,
      aad: aad,
    );
    final cipherText = box.cipherText;
    final macBytes = box.mac.bytes;
    final packageBytes = Uint8List(
      aad.length + cipherText.length + macBytes.length,
    );
    var offset = 0;
    packageBytes.setRange(offset, offset + aad.length, aad);
    offset += aad.length;
    packageBytes.setRange(offset, offset + cipherText.length, cipherText);
    offset += cipherText.length;
    packageBytes.setRange(offset, offset + macBytes.length, macBytes);
    return packageBytes;
  }

  Future<Uint8List> decrypt(List<int> packageBytes, String password) async {
    try {
      if (packageBytes.length < _magic.length + 4) {
        throw const MobileBackupFailure(
          'invalid_header',
          'Yedek başlığı geçersiz.',
        );
      }
      for (var index = 0; index < _magic.length; index += 1) {
        if (packageBytes[index] != _magic[index]) {
          throw const MobileBackupFailure(
            'invalid_header',
            'Bu dosya desteklenen bir CSE yedeği değil.',
          );
        }
      }
      final headerLength = _readUint32(packageBytes, _magic.length);
      if (headerLength < 2 || headerLength > _maximumHeaderBytes) {
        throw const MobileBackupFailure(
          'invalid_header',
          'Yedek başlığı geçersiz.',
        );
      }
      final headerStart = _magic.length + 4;
      final payloadStart = headerStart + headerLength;
      if (payloadStart > packageBytes.length) {
        throw const MobileBackupFailure(
          'invalid_header',
          'Yedek başlığı eksik.',
        );
      }
      final headerBytes = Uint8List.fromList(
        packageBytes.sublist(headerStart, payloadStart),
      );
      final decoded = jsonDecode(
        utf8.decode(headerBytes, allowMalformed: false),
      );
      if (decoded is! Map) {
        throw const MobileBackupFailure(
          'invalid_header',
          'Yedek başlığı geçersiz.',
        );
      }
      final header = Map<String, Object?>.from(decoded);
      final version = header['format_version'];
      final cipherName = header['cipher'];
      final kdfName = header['kdf'];
      final iterations = header['kdf_iterations'];
      final saltText = header['salt'];
      final nonceText = header['nonce'];
      final encryptedLength = header['ciphertext_length'];
      final macLength = header['mac_length'];
      if (version != formatVersion) {
        throw const MobileBackupFailure(
          'unsupported_format',
          'Yedek format sürümü desteklenmiyor.',
        );
      }
      if (cipherName != _cipherName || kdfName != _kdfName) {
        throw const MobileBackupFailure(
          'unsupported_crypto',
          'Yedek şifreleme yöntemi desteklenmiyor.',
        );
      }
      if (iterations is! int ||
          iterations < minimumAcceptedKdfIterations ||
          iterations > maximumAcceptedKdfIterations ||
          saltText is! String ||
          nonceText is! String ||
          encryptedLength is! int ||
          encryptedLength < 0 ||
          macLength is! int ||
          macLength != 16) {
        throw const MobileBackupFailure(
          'invalid_header',
          'Yedek başlığı geçersiz.',
        );
      }
      final salt = base64Decode(saltText);
      final nonce = base64Decode(nonceText);
      final cipher = AesGcm.with256bits();
      if (salt.length != 16 || nonce.length != cipher.nonceLength) {
        throw const MobileBackupFailure(
          'invalid_header',
          'Yedek başlığı geçersiz.',
        );
      }
      final expectedLength = payloadStart + encryptedLength + macLength;
      if (expectedLength != packageBytes.length) {
        throw const MobileBackupFailure(
          'invalid_header',
          'Yedek dosya uzunluğu geçersiz.',
        );
      }
      final cipherText = packageBytes.sublist(
        payloadStart,
        payloadStart + encryptedLength,
      );
      final macBytes = packageBytes.sublist(payloadStart + encryptedLength);
      final aad = packageBytes.sublist(0, payloadStart);
      final key = await Pbkdf2.hmacSha256(
        iterations: iterations,
        bits: 256,
      ).deriveKeyFromPassword(password: password, nonce: salt);
      final clear = await cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
        secretKey: key,
        aad: aad,
      );
      return Uint8List.fromList(clear);
    } on MobileBackupFailure {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const MobileBackupFailure(
        'wrong_password_or_tampered',
        'Parola yanlış veya yedek değiştirilmiş.',
      );
    } on FormatException {
      throw const MobileBackupFailure(
        'invalid_header',
        'Yedek başlığı geçersiz.',
      );
    } on Object {
      throw const MobileBackupFailure(
        'wrong_password_or_tampered',
        'Parola yanlış veya yedek değiştirilmiş.',
      );
    }
  }

  static Uint8List _secureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _uint32(int value) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

  static int _readUint32(List<int> bytes, int offset) => Uint8List.fromList(
    bytes.sublist(offset, offset + 4),
  ).buffer.asByteData().getUint32(0, Endian.big);
}

class DecodedCseBackupArchive {
  const DecodedCseBackupArchive({
    required this.manifest,
    required this.databaseBytes,
    required this.attachmentBytes,
  });

  final MobileBackupManifest manifest;
  final Uint8List databaseBytes;
  final Map<String, Uint8List> attachmentBytes;
}

class CseBackupArchiveCodec {
  const CseBackupArchiveCodec({
    this.maximumEntryBytes = 128 * 1024 * 1024,
    this.maximumExpandedBytes = 768 * 1024 * 1024,
  });

  static const manifestPath = 'manifest.json';
  static const databasePath = 'database.sqlite3';

  final int maximumEntryBytes;
  final int maximumExpandedBytes;

  Uint8List encode({
    required MobileBackupManifest manifest,
    required List<int> databaseBytes,
    required Map<String, List<int>> attachments,
  }) {
    final archive = Archive();
    archive.addFile(
      ArchiveFile.string(
        manifestPath,
        const JsonEncoder.withIndent(' ').convert(manifest.toJson()),
      ),
    );
    archive.addFile(ArchiveFile.bytes(databasePath, databaseBytes));
    final names = attachments.keys.toList()..sort();
    for (final relativePath in names) {
      _validateLogicalPath(relativePath);
      archive.addFile(
        ArchiveFile.bytes(
          'attachments/$relativePath',
          attachments[relativePath]!,
        ),
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  DecodedCseBackupArchive decode(List<int> archiveBytes) {
    try {
      final rawNames = _centralDirectoryNames(archiveBytes);
      if (rawNames.length != rawNames.toSet().length ||
          rawNames.length !=
              rawNames.map((item) => item.toLowerCase()).toSet().length) {
        throw const MobileBackupFailure(
          'duplicate_entry',
          'Yedekte aynı isimli birden fazla dosya var.',
        );
      }
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(archiveBytes, verify: true);
      var expandedBytes = 0;
      final entries = <String, Uint8List>{};
      for (final item in archive.files) {
        if (!item.isFile || item.isSymbolicLink) {
          throw const MobileBackupFailure(
            'unsupported_entry',
            'Yedekte desteklenmeyen bir kayıt var.',
          );
        }
        _validateArchivePath(item.name);
        if (item.size < 0 || item.size > maximumEntryBytes) {
          throw const MobileBackupFailure(
            'oversize_entry',
            'Yedekte boyut sınırını aşan bir dosya var.',
          );
        }
        expandedBytes += item.size;
        if (expandedBytes > maximumExpandedBytes) {
          throw const MobileBackupFailure(
            'oversize_package',
            'Yedek açılmış boyut sınırını aşıyor.',
          );
        }
        final content = item.content;
        if (content.length != item.size) {
          throw const MobileBackupFailure(
            'invalid_entry_size',
            'Yedek dosya boyutu doğrulanamadı.',
          );
        }
        entries[item.name] = Uint8List.fromList(content);
      }
      final manifestBytes = entries[manifestPath];
      final databaseBytes = entries[databasePath];
      if (manifestBytes == null || databaseBytes == null) {
        throw const MobileBackupFailure(
          'missing_entry',
          'Yedek manifesti veya veritabanı eksik.',
        );
      }
      final decodedManifest = jsonDecode(
        utf8.decode(manifestBytes, allowMalformed: false),
      );
      if (decodedManifest is! Map) {
        throw const MobileBackupFailure(
          'invalid_manifest',
          'Yedek manifesti geçersiz.',
        );
      }
      final manifest = MobileBackupManifest.fromJson(
        Map<String, Object?>.from(decodedManifest),
      );
      if (manifest.formatVersion != CseBackupCodec.formatVersion ||
          manifest.database.logicalPath != databasePath) {
        throw const MobileBackupFailure(
          'unsupported_format',
          'Yedek format sürümü desteklenmiyor.',
        );
      }
      _verifyFile(manifest.database, databaseBytes);
      final expectedNames = <String>{manifestPath, databasePath};
      final attachmentBytes = <String, Uint8List>{};
      final logicalNames = <String>{};
      final portableLogicalNames = <String>{};
      for (final attachment in manifest.attachments) {
        _validateLogicalPath(attachment.logicalPath);
        if (!logicalNames.add(attachment.logicalPath) ||
            !portableLogicalNames.add(attachment.logicalPath.toLowerCase())) {
          throw const MobileBackupFailure(
            'duplicate_entry',
            'Manifestte yinelenen attachment kaydı var.',
          );
        }
        final archivePath = 'attachments/${attachment.logicalPath}';
        expectedNames.add(archivePath);
        final bytes = entries[archivePath];
        if (bytes == null) {
          throw const MobileBackupFailure(
            'missing_entry',
            'Manifestteki attachment dosyası eksik.',
          );
        }
        _verifyFile(attachment, bytes);
        attachmentBytes[attachment.logicalPath] = bytes;
      }
      if (entries.keys.toSet().difference(expectedNames).isNotEmpty ||
          expectedNames.difference(entries.keys.toSet()).isNotEmpty) {
        throw const MobileBackupFailure(
          'unsupported_entry',
          'Yedekte manifest dışında bir dosya var.',
        );
      }
      return DecodedCseBackupArchive(
        manifest: manifest,
        databaseBytes: databaseBytes,
        attachmentBytes: Map.unmodifiable(attachmentBytes),
      );
    } on MobileBackupFailure {
      rethrow;
    } on Object {
      throw const MobileBackupFailure(
        'invalid_archive',
        'Yedek arşivi açılamadı.',
      );
    }
  }

  static void _verifyFile(BackupManifestFile expected, List<int> bytes) {
    if (expected.byteSize != bytes.length ||
        expected.byteSize < 0 ||
        expected.sha256.length != 64 ||
        hashes.sha256.convert(bytes).toString() != expected.sha256) {
      throw const MobileBackupFailure(
        'hash_mismatch',
        'Yedek dosya bütünlüğü doğrulanamadı.',
      );
    }
  }

  static void _validateArchivePath(String value) {
    if (value == manifestPath || value == databasePath) return;
    if (!value.startsWith('attachments/')) {
      throw const MobileBackupFailure(
        'unsupported_entry',
        'Yedekte desteklenmeyen bir dosya var.',
      );
    }
    _validateLogicalPath(value.substring('attachments/'.length));
  }

  static void _validateLogicalPath(String value) {
    if (value.isEmpty ||
        value.startsWith('/') ||
        value.contains('\\') ||
        value.contains(':') ||
        value.codeUnits.any((item) => item < 32 || item == 127) ||
        path.posix.isAbsolute(value)) {
      throw const MobileBackupFailure(
        'unsafe_path',
        'Yedekte güvenli olmayan bir dosya yolu var.',
      );
    }
    final parts = value.split('/');
    if (parts.any((item) => item.isEmpty || item == '.' || item == '..') ||
        path.posix.normalize(value) != value) {
      throw const MobileBackupFailure(
        'unsafe_path',
        'Yedekte güvenli olmayan bir dosya yolu var.',
      );
    }
  }

  List<String> _centralDirectoryNames(List<int> bytes) {
    const endSignature = 0x06054b50;
    const centralSignature = 0x02014b50;
    const minimumEndSize = 22;
    if (bytes.length < minimumEndSize) {
      throw const MobileBackupFailure(
        'invalid_archive',
        'Yedek arşivi açılamadı.',
      );
    }
    final data = Uint8List.fromList(bytes);
    final view = data.buffer.asByteData();
    final earliestEnd = max(0, data.length - minimumEndSize - 0xffff);
    var endOffset = -1;
    for (
      var offset = data.length - minimumEndSize;
      offset >= earliestEnd;
      offset -= 1
    ) {
      if (view.getUint32(offset, Endian.little) == endSignature) {
        endOffset = offset;
        break;
      }
    }
    if (endOffset < 0 || endOffset + minimumEndSize > data.length) {
      throw const MobileBackupFailure(
        'invalid_archive',
        'Yedek arşivi açılamadı.',
      );
    }
    final diskNumber = view.getUint16(endOffset + 4, Endian.little);
    final centralDisk = view.getUint16(endOffset + 6, Endian.little);
    final entriesOnDisk = view.getUint16(endOffset + 8, Endian.little);
    final entryCount = view.getUint16(endOffset + 10, Endian.little);
    final centralSize = view.getUint32(endOffset + 12, Endian.little);
    final centralOffset = view.getUint32(endOffset + 16, Endian.little);
    final archiveCommentLength = view.getUint16(endOffset + 20, Endian.little);
    if (diskNumber != 0 ||
        centralDisk != 0 ||
        entriesOnDisk != entryCount ||
        entryCount == 0xffff ||
        centralSize == 0xffffffff ||
        centralOffset == 0xffffffff ||
        centralOffset + centralSize != endOffset ||
        endOffset + minimumEndSize + archiveCommentLength != data.length) {
      throw const MobileBackupFailure(
        'unsupported_archive',
        'Yedek ZIP yapısı desteklenmiyor.',
      );
    }
    var offset = centralOffset;
    var expandedBytes = 0;
    final names = <String>[];
    for (var index = 0; index < entryCount; index += 1) {
      if (offset + 46 > endOffset ||
          view.getUint32(offset, Endian.little) != centralSignature) {
        throw const MobileBackupFailure(
          'invalid_archive',
          'Yedek ZIP merkezi dizini geçersiz.',
        );
      }
      final nameLength = view.getUint16(offset + 28, Endian.little);
      final extraLength = view.getUint16(offset + 30, Endian.little);
      final commentLength = view.getUint16(offset + 32, Endian.little);
      final compressedSize = view.getUint32(offset + 20, Endian.little);
      final expandedSize = view.getUint32(offset + 24, Endian.little);
      if (compressedSize == 0xffffffff || expandedSize == 0xffffffff) {
        throw const MobileBackupFailure(
          'unsupported_archive',
          'Yedek ZIP64 kaydı desteklenmiyor.',
        );
      }
      if (expandedSize > maximumEntryBytes) {
        throw const MobileBackupFailure(
          'oversize_entry',
          'Yedekte boyut sınırını aşan bir dosya var.',
        );
      }
      expandedBytes += expandedSize;
      if (expandedBytes > maximumExpandedBytes) {
        throw const MobileBackupFailure(
          'oversize_package',
          'Yedek açılmış boyut sınırını aşıyor.',
        );
      }
      final nameStart = offset + 46;
      final next = nameStart + nameLength + extraLength + commentLength;
      if (next > endOffset) {
        throw const MobileBackupFailure(
          'invalid_archive',
          'Yedek ZIP merkezi dizini geçersiz.',
        );
      }
      names.add(
        utf8.decode(
          data.sublist(nameStart, nameStart + nameLength),
          allowMalformed: false,
        ),
      );
      offset = next;
    }
    if (offset != centralOffset + centralSize) {
      throw const MobileBackupFailure(
        'invalid_archive',
        'Yedek ZIP merkezi dizini geçersiz.',
      );
    }
    return names;
  }
}

class SqliteMobileBackupApplication
    implements MobileBackupApplication, MobileSafetyBackupRecoveryApplication {
  SqliteMobileBackupApplication({
    required this.directories,
    required this.databaseFactory,
    required this.clock,
    required this.coordinator,
    required this.fileGateway,
    required this.notificationReconciler,
    this.appVersion = '0.1.0',
    this.buildNumber = '1',
    CseBackupCodec? encryptionCodec,
    CseBackupArchiveCodec? archiveCodec,
    this.restoreHooks = const MobileRestoreHooks(),
    this.maximumPackageBytes = 512 * 1024 * 1024,
  }) : encryptionCodec = encryptionCodec ?? CseBackupCodec(),
       archiveCodec = archiveCodec ?? const CseBackupArchiveCodec();

  final AppDirectories directories;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;
  final MobileOperationCoordinator coordinator;
  final MobileBackupFileGateway fileGateway;
  final Future<void> Function() notificationReconciler;
  final String appVersion;
  final String buildNumber;
  final CseBackupCodec encryptionCodec;
  final CseBackupArchiveCodec archiveCodec;
  final MobileRestoreHooks restoreHooks;
  final int maximumPackageBytes;

  @override
  Future<MobileBackupCreationResult> createBackup(
    CreateMobileBackupCommand command, {
    MobileBackupCreationProgress? onProgress,
  }) async {
    _validateNewPassword(command.password, command.passwordConfirmation);
    final operationTime = _readClockOnce();
    return coordinator.runExclusive(
      () => _createBackupInside(
        password: command.password,
        operationTime: operationTime,
        filePrefix: 'cse_mobile_backup',
        recordSummary: true,
        onProgress: onProgress,
      ),
    );
  }

  @override
  Future<void> shareBackup(String absolutePath) =>
      fileGateway.sharePackage(absolutePath);

  @override
  Future<List<MobileSafetyBackupMetadata>> listSafetyBackups() async {
    try {
      final root = await _resolvedSafetyBackupRootOrNull();
      if (root == null) return const [];
      final backups = <MobileSafetyBackupMetadata>[];
      await for (final entity in directories.exportsBackups.list(
        followLinks: false,
      )) {
        final type = await FileSystemEntity.type(
          entity.path,
          followLinks: false,
        );
        if (type != FileSystemEntityType.file) {
          throw const MobileBackupFailure(
            'unsupported_safety_backup_object',
            'Kurtarma yedekleri güvenli biçimde okunamadı.',
          );
        }
        final fileName = path.basename(entity.path);
        if (!fileName.startsWith('safety_before_restore_') ||
            path.extension(fileName).toLowerCase() != '.csebackup') {
          continue;
        }
        if (_parseSafetyBackupTimestamp(fileName) == null) {
          throw const MobileBackupFailure(
            'invalid_safety_backup_identity',
            'Kurtarma yedeği kimliği güvenli değil.',
          );
        }
        backups.add(await _inspectSafetyBackup(root, fileName));
      }
      backups.sort((left, right) {
        final byCreated = right.createdAtUtc.compareTo(left.createdAtUtc);
        if (byCreated != 0) return byCreated;
        return left.fileName.compareTo(right.fileName);
      });
      return List<MobileSafetyBackupMetadata>.unmodifiable(backups);
    } on MobileBackupFailure {
      rethrow;
    } on Object {
      throw const MobileBackupFailure(
        'safety_backup_list_failed',
        'Kurtarma yedekleri güvenli biçimde okunamadı.',
      );
    }
  }

  @override
  Future<void> shareSafetyBackup(MobileSafetyBackupMetadata backup) async {
    try {
      final root = await _resolvedSafetyBackupRootOrNull();
      if (root == null) {
        throw const MobileBackupFailure(
          'safety_backup_unavailable',
          'Kurtarma yedeği artık kullanılamıyor.',
        );
      }
      final inspected = await _inspectSafetyBackup(root, backup.fileName);
      if (inspected.byteSize != backup.byteSize ||
          inspected.sha256 != backup.sha256 ||
          inspected.createdAtUtc != backup.createdAtUtc) {
        throw const MobileBackupFailure(
          'safety_backup_changed',
          'Kurtarma yedeği listelendikten sonra değişti; paylaşım durduruldu.',
        );
      }
      final candidate = File(path.join(root, inspected.fileName));
      await _requireResolvedSafetyBackupFile(root, candidate);
      await fileGateway.sharePackage(candidate.path);
    } on MobileBackupFailure {
      rethrow;
    } on Object {
      throw const MobileBackupFailure(
        'safety_backup_share_failed',
        'Kurtarma yedeği güvenli biçimde paylaşılamadı.',
      );
    }
  }

  @override
  Future<PickedBackupPackage?> pickBackupPackage([
    PickedBackupPackage? currentPackage,
  ]) async {
    final selected = await fileGateway.pickPackage();
    if (selected == null) return null;
    if (currentPackage != null &&
        currentPackage.stablePath != selected.stablePath) {
      try {
        await fileGateway.cleanupPickedPackage(currentPackage);
      } on Object {
        await fileGateway.cleanupPickedPackage(selected);
        rethrow;
      }
    }
    return selected;
  }

  @override
  Future<void> discardBackupPackage(PickedBackupPackage package) =>
      fileGateway.cleanupPickedPackage(package);

  @override
  Future<MobileBackupPreflight> preflightBackup(
    PickedBackupPackage package,
    String password,
  ) {
    _validateExistingPassword(password);
    final operationTime = _readClockOnce();
    return coordinator.runExclusive(() async {
      final prepared = await _prepareIncoming(
        package: package,
        password: password,
        operationTime: operationTime,
        purpose: 'preflight',
      );
      try {
        return MobileBackupPreflight(
          package: package,
          manifest: prepared.archive.manifest,
          migratedSchemaVersion: AppDatabase.schemaVersion,
        );
      } finally {
        await _deleteStagingDirectory(prepared.root);
      }
    });
  }

  @override
  Future<MobileRestoreResult> restoreBackup(
    RestoreMobileBackupCommand command,
  ) {
    _validateExistingPassword(command.password);
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(command.expectedPackageSha256)) {
      throw const MobileBackupFailure(
        'invalid_preflight_token',
        'Restore ön inceleme bilgisi geçersiz.',
      );
    }
    final operationTime = _readClockOnce();
    return coordinator.runExclusive(() async {
      final prepared = await _prepareIncoming(
        package: command.package,
        password: command.password,
        operationTime: operationTime,
        purpose: 'restore',
      );
      if (prepared.packageSha256 != command.expectedPackageSha256) {
        await _deleteStagingDirectory(prepared.root);
        throw const MobileBackupFailure(
          'package_changed_after_preflight',
          'Yedek ön incelemeden sonra değişti; restore durduruldu.',
        );
      }
      final safety = await _createBackupInside(
        password: command.password,
        operationTime: operationTime,
        filePrefix: 'safety_before_restore',
        recordSummary: false,
      );
      late MobileRestoreResult result;
      try {
        await restoreHooks.beforeSwap?.call();
        await _activatePreparedRestore(prepared, operationTime);
        result = MobileRestoreResult(
          restoredManifest: prepared.archive.manifest,
          safetyBackupPath: safety.absolutePath,
          activeSchemaVersion: AppDatabase.schemaVersion,
        );
      } finally {
        await _deleteStagingDirectory(prepared.root);
      }
      try {
        await fileGateway.cleanupPickedPackage(command.package);
      } on Object {
        // Restore is already complete. Bootstrap reconciliation retries cleanup.
      }
      return result;
    });
  }

  @override
  Future<MobileBackupSummary?> lastSuccessfulBackup() async {
    directories.validate();
    final file = File(directories.backupStateFile);
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final summary = MobileBackupSummary.fromJson(
        Map<String, Object?>.from(decoded),
      );
      CseTimeCodec.decodeCanonicalUtc(summary.createdAtUtc);
      if (path.basename(summary.fileName) != summary.fileName) return null;
      return summary;
    } on Object {
      return null;
    }
  }

  Future<MobileBackupCreationResult> _createBackupInside({
    required String password,
    required DateTime operationTime,
    required String filePrefix,
    required bool recordSummary,
    MobileBackupCreationProgress? onProgress,
  }) async {
    _reportBackupStage(onProgress, MobileBackupCreationStage.preparing);
    directories.validate();
    await directories.ensureCreated();
    final operationId = _operationId(operationTime);
    final workingRoot = Directory(
      path.join(directories.staging.path, 'backup-$operationId'),
    );
    final partial = File(path.join(workingRoot.path, 'package.part'));
    File? destination;
    try {
      await workingRoot.create(recursive: false);
      final snapshotFile = File(
        path.join(workingRoot.path, CseBackupArchiveCodec.databasePath),
      );
      final active = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactory,
        clock: () => operationTime,
      );
      late List<Map<String, Object?>> attachmentRows;
      try {
        await active.open();
        await _requireDatabaseIntegrity(active.database);
        attachmentRows = await _activeAttachmentRows(active.database);
        final escaped = snapshotFile.path.replaceAll("'", "''");
        await active.database.execute("VACUUM INTO '$escaped'");
      } finally {
        await active.close();
      }
      await _validateDatabaseFile(
        snapshotFile,
        expectedSchema: AppDatabase.schemaVersion,
        operationTime: operationTime,
        allowMigration: false,
      );
      final databaseBytes = await snapshotFile.readAsBytes();
      final attachments = <String, List<int>>{};
      final attachmentManifest = <BackupManifestFile>[];
      for (final row in attachmentRows) {
        final relativePath = row['relative_path']! as String;
        final expectedSize = row['byte_size']! as int;
        final expectedDigest = row['sha256']! as String;
        CseBackupArchiveCodec._validateLogicalPath(relativePath);
        final file = _resolveAttachment(relativePath);
        if (!await file.exists()) {
          throw const MobileBackupFailure(
            'attachment_missing',
            'Aktif attachment dosyası eksik; yedek oluşturulmadı.',
          );
        }
        final bytes = await file.readAsBytes();
        final digest = hashes.sha256.convert(bytes).toString();
        if (bytes.length != expectedSize || digest != expectedDigest) {
          throw const MobileBackupFailure(
            'attachment_integrity_failed',
            'Aktif attachment bütünlüğü doğrulanamadı.',
          );
        }
        attachments[relativePath] = bytes;
        attachmentManifest.add(
          BackupManifestFile(
            logicalPath: relativePath,
            byteSize: bytes.length,
            sha256: digest,
          ),
        );
      }
      attachmentManifest.sort(
        (left, right) => left.logicalPath.compareTo(right.logicalPath),
      );
      _reportBackupStage(onProgress, MobileBackupCreationStage.packaging);
      final timestamp = CseTimeCodec.encodeUtc(operationTime);
      final manifest = MobileBackupManifest(
        formatVersion: CseBackupCodec.formatVersion,
        appVersion: appVersion,
        buildNumber: buildNumber,
        mobileSchemaVersion: AppDatabase.schemaVersion,
        createdAtUtc: timestamp,
        database: BackupManifestFile(
          logicalPath: CseBackupArchiveCodec.databasePath,
          byteSize: databaseBytes.length,
          sha256: hashes.sha256.convert(databaseBytes).toString(),
        ),
        attachments: List.unmodifiable(attachmentManifest),
      );
      final archiveBytes = archiveCodec.encode(
        manifest: manifest,
        databaseBytes: databaseBytes,
        attachments: attachments,
      );
      final packageBytes = await encryptionCodec.encrypt(
        archiveBytes,
        password,
      );
      if (packageBytes.length > maximumPackageBytes) {
        throw const MobileBackupFailure(
          'oversize_package',
          'Yedek paket boyutu güvenli sınırı aşıyor.',
        );
      }
      _reportBackupStage(onProgress, MobileBackupCreationStage.verifying);
      final verifiedArchive = archiveCodec.decode(
        await encryptionCodec.decrypt(packageBytes, password),
      );
      if (verifiedArchive.manifest.database.sha256 !=
          manifest.database.sha256) {
        throw const MobileBackupFailure(
          'package_verification_failed',
          'Yedek paket doğrulaması başarısız.',
        );
      }
      _reportBackupStage(onProgress, MobileBackupCreationStage.saving);
      await partial.writeAsBytes(packageBytes, flush: true);
      final safeTimestamp = timestamp
          .replaceAll('-', '')
          .replaceAll(':', '')
          .replaceAll('T', '_')
          .replaceAll('Z', '');
      final fileName = '${filePrefix}_${safeTimestamp}_$operationId.csebackup';
      destination = File(path.join(directories.exportsBackups.path, fileName));
      if (await destination.exists()) {
        throw const MobileBackupFailure(
          'backup_destination_exists',
          'Yedek hedefi zaten var.',
        );
      }
      await partial.rename(destination.path);
      final summary = MobileBackupSummary(
        createdAtUtc: timestamp,
        fileName: fileName,
        packageByteSize: packageBytes.length,
        databaseByteSize: databaseBytes.length,
        attachmentCount: attachmentManifest.length,
        attachmentByteSize: attachmentManifest.fold(
          0,
          (sum, item) => sum + item.byteSize,
        ),
        mobileSchemaVersion: AppDatabase.schemaVersion,
      );
      if (recordSummary) await _writeBackupSummary(summary);
      return MobileBackupCreationResult(
        absolutePath: destination.path,
        packageSha256: hashes.sha256.convert(packageBytes).toString(),
        summary: summary,
      );
    } on Object {
      if (await partial.exists()) await partial.delete();
      if (destination != null && await destination.exists() && recordSummary) {
        await destination.delete();
      }
      rethrow;
    } finally {
      await _deleteStagingDirectory(workingRoot);
    }
  }

  Future<_PreparedRestore> _prepareIncoming({
    required PickedBackupPackage package,
    required String password,
    required DateTime operationTime,
    required String purpose,
  }) async {
    final source = await _requireAllowedPackage(package);
    if (path.extension(source.path).toLowerCase() != '.csebackup' ||
        !await source.exists()) {
      throw const MobileBackupFailure(
        'package_not_found',
        'Seçilen yedek dosyası bulunamadı.',
      );
    }
    final packageSize = await source.length();
    if (packageSize <= 0 ||
        packageSize > maximumPackageBytes ||
        packageSize != package.byteSize) {
      throw const MobileBackupFailure(
        'package_changed_after_import',
        'Yedek güvenli alana alındıktan sonra değişti.',
      );
    }
    final verifiedDigest = await _sha256File(source);
    if (verifiedDigest != package.sha256) {
      throw const MobileBackupFailure(
        'package_changed_after_import',
        'Yedek güvenli alana alındıktan sonra değişti.',
      );
    }
    final packageBytes = await source.readAsBytes();
    final packageDigest = hashes.sha256.convert(packageBytes).toString();
    if (packageBytes.length != packageSize || packageDigest != package.sha256) {
      throw const MobileBackupFailure(
        'package_changed_after_import',
        'Yedek güvenli alana alındıktan sonra değişti.',
      );
    }
    final archive = archiveCodec.decode(
      await encryptionCodec.decrypt(packageBytes, password),
    );
    _validateManifest(archive.manifest);
    final root = Directory(
      path.join(
        directories.staging.path,
        '$purpose-${_operationId(operationTime)}',
      ),
    );
    try {
      await root.create(recursive: false);
      final databaseFile = File(
        path.join(root.path, CseBackupArchiveCodec.databasePath),
      );
      await databaseFile.writeAsBytes(archive.databaseBytes, flush: true);
      final attachmentsRoot = Directory(path.join(root.path, 'attachments'));
      await attachmentsRoot.create();
      final logicalPaths = archive.attachmentBytes.keys.toList()..sort();
      for (final relativePath in logicalPaths) {
        final destination = _resolveWithin(attachmentsRoot, relativePath);
        await destination.parent.create(recursive: true);
        await destination.writeAsBytes(
          archive.attachmentBytes[relativePath]!,
          flush: true,
        );
      }
      await _validateDatabaseFile(
        databaseFile,
        expectedSchema: archive.manifest.mobileSchemaVersion,
        operationTime: operationTime,
        allowMigration: true,
      );
      await _requireAttachmentManifestMatchesDatabase(
        databaseFile,
        attachmentsRoot,
        archive.manifest.attachments,
        sourceSchemaVersion: archive.manifest.mobileSchemaVersion,
      );
      return _PreparedRestore(
        root: root,
        databaseFile: databaseFile,
        attachmentsRoot: attachmentsRoot,
        archive: archive,
        packageSha256: packageDigest,
      );
    } on Object {
      await _deleteStagingDirectory(root);
      rethrow;
    }
  }

  Future<File> _requireAllowedPackage(PickedBackupPackage package) async {
    directories.validate();
    if (package.byteSize <= 0 || package.byteSize > maximumPackageBytes) {
      throw const MobileBackupFailure(
        'oversize_package',
        'Yedek paket boyutu güvenli sınırı aşıyor.',
      );
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(package.sha256) ||
        !RegExp(
          r'^[0-9A-Za-z][0-9A-Za-z_-]{0,127}$',
        ).hasMatch(package.importOperationId) ||
        !_isSafeBackupFileName(package.originalFileName)) {
      throw const MobileBackupFailure(
        'invalid_import_metadata',
        'Yedek içe aktarma bilgisi geçersiz.',
      );
    }
    final candidate = path.normalize(path.absolute(package.stablePath));
    if (path.extension(candidate).toLowerCase() != '.csebackup') {
      throw const MobileBackupFailure(
        'unsafe_package_source',
        'Yedek yalnız uygulamanın güvenli alanından okunabilir.',
      );
    }
    final incomingRoot = path.normalize(
      path.absolute(directories.incomingBackups.path),
    );
    final backupRoot = path.normalize(
      path.absolute(directories.exportsBackups.path),
    );
    final isIncoming =
        path.dirname(candidate) == incomingRoot &&
        path.basename(candidate) == '${package.importOperationId}.csebackup';
    final isInternalBackup =
        path.dirname(candidate) == backupRoot &&
        path.basename(candidate) == package.originalFileName;
    if (!isIncoming && !isInternalBackup) {
      throw const MobileBackupFailure(
        'unsafe_package_source',
        'Yedek yalnız uygulamanın güvenli alanından okunabilir.',
      );
    }
    final source = File(candidate);
    final type = await FileSystemEntity.type(candidate, followLinks: false);
    if (type != FileSystemEntityType.file) {
      throw const MobileBackupFailure(
        'package_not_found',
        'Seçilen yedek dosyası bulunamadı.',
      );
    }
    final allowedRoot = Directory(isIncoming ? incomingRoot : backupRoot);
    final resolvedRoot = path.normalize(
      path.absolute(await allowedRoot.resolveSymbolicLinks()),
    );
    final resolvedSource = path.normalize(
      path.absolute(await source.resolveSymbolicLinks()),
    );
    if (path.dirname(resolvedSource) != resolvedRoot) {
      throw const MobileBackupFailure(
        'unsafe_package_source',
        'Yedek yalnız uygulamanın güvenli alanından okunabilir.',
      );
    }
    return source;
  }

  Future<String> _sha256File(File source) async =>
      (await hashes.sha256.bind(source.openRead()).first).toString();

  Future<String?> _resolvedSafetyBackupRootOrNull() async {
    directories.validate();
    final applicationRoot = directories.root;
    final backupRoot = directories.exportsBackups;
    final applicationRootType = await FileSystemEntity.type(
      applicationRoot.path,
      followLinks: false,
    );
    final backupRootType = await FileSystemEntity.type(
      backupRoot.path,
      followLinks: false,
    );
    if (backupRootType == FileSystemEntityType.notFound) return null;
    if (applicationRootType != FileSystemEntityType.directory ||
        backupRootType != FileSystemEntityType.directory) {
      throw const MobileBackupFailure(
        'unsafe_safety_backup_root',
        'Kurtarma yedeği alanı güvenli değil.',
      );
    }
    final resolvedApplicationRoot = path.normalize(
      path.absolute(await applicationRoot.resolveSymbolicLinks()),
    );
    final resolvedBackupRoot = path.normalize(
      path.absolute(await backupRoot.resolveSymbolicLinks()),
    );
    if (!path.equals(
          path.dirname(resolvedBackupRoot),
          resolvedApplicationRoot,
        ) ||
        path.basename(resolvedBackupRoot) !=
            path.basename(directories.exportsBackups.path)) {
      throw const MobileBackupFailure(
        'unsafe_safety_backup_root',
        'Kurtarma yedeği alanı güvenli değil.',
      );
    }
    return resolvedBackupRoot;
  }

  Future<MobileSafetyBackupMetadata> _inspectSafetyBackup(
    String resolvedRoot,
    String fileName,
  ) async {
    final createdAt = _parseSafetyBackupTimestamp(fileName);
    if (createdAt == null || path.basename(fileName) != fileName) {
      throw const MobileBackupFailure(
        'invalid_safety_backup_identity',
        'Kurtarma yedeği kimliği güvenli değil.',
      );
    }
    final candidate = File(path.join(resolvedRoot, fileName));
    await _requireResolvedSafetyBackupFile(resolvedRoot, candidate);
    final before = await candidate.stat();
    if (before.type != FileSystemEntityType.file ||
        before.size <= 0 ||
        before.size > maximumPackageBytes) {
      throw const MobileBackupFailure(
        'invalid_safety_backup_file',
        'Kurtarma yedeği güvenli biçimde okunamadı.',
      );
    }
    var streamedBytes = 0;
    final digest =
        (await hashes.sha256
                .bind(
                  candidate.openRead().map((chunk) {
                    streamedBytes += chunk.length;
                    if (streamedBytes > maximumPackageBytes) {
                      throw const MobileBackupFailure(
                        'invalid_safety_backup_file',
                        'Kurtarma yedeği güvenli biçimde okunamadı.',
                      );
                    }
                    return chunk;
                  }),
                )
                .first)
            .toString();
    await _requireResolvedSafetyBackupFile(resolvedRoot, candidate);
    final after = await candidate.stat();
    if (after.type != FileSystemEntityType.file ||
        after.size != before.size ||
        after.size != streamedBytes ||
        after.modified != before.modified) {
      throw const MobileBackupFailure(
        'safety_backup_changed',
        'Kurtarma yedeği okunurken değişti; işlem durduruldu.',
      );
    }
    return MobileSafetyBackupMetadata(
      fileName: fileName,
      byteSize: after.size,
      sha256: digest,
      createdAtUtc: createdAt,
    );
  }

  Future<void> _requireResolvedSafetyBackupFile(
    String resolvedRoot,
    File candidate,
  ) async {
    final normalizedCandidate = path.normalize(path.absolute(candidate.path));
    if (!path.equals(path.dirname(normalizedCandidate), resolvedRoot) ||
        !path.isWithin(resolvedRoot, normalizedCandidate) ||
        path.basename(normalizedCandidate) != path.basename(candidate.path)) {
      throw const MobileBackupFailure(
        'unsafe_safety_backup_path',
        'Kurtarma yedeği yolu güvenli değil.',
      );
    }
    final type = await FileSystemEntity.type(
      normalizedCandidate,
      followLinks: false,
    );
    if (type != FileSystemEntityType.file) {
      throw const MobileBackupFailure(
        'safety_backup_unavailable',
        'Kurtarma yedeği artık kullanılamıyor.',
      );
    }
    final resolvedCandidate = path.normalize(
      path.absolute(await candidate.resolveSymbolicLinks()),
    );
    if (!path.equals(path.dirname(resolvedCandidate), resolvedRoot) ||
        !path.isWithin(resolvedRoot, resolvedCandidate) ||
        path.basename(resolvedCandidate) !=
            path.basename(normalizedCandidate)) {
      throw const MobileBackupFailure(
        'unsafe_safety_backup_path',
        'Kurtarma yedeği yolu güvenli değil.',
      );
    }
  }

  DateTime? _parseSafetyBackupTimestamp(String fileName) {
    final match = _safetyBackupFileName.firstMatch(fileName);
    if (match == null) return null;
    final values = [
      for (var index = 1; index <= 6; index++) int.parse(match[index]!),
    ];
    final timestamp = DateTime.utc(
      values[0],
      values[1],
      values[2],
      values[3],
      values[4],
      values[5],
    );
    if (timestamp.year != values[0] ||
        timestamp.month != values[1] ||
        timestamp.day != values[2] ||
        timestamp.hour != values[3] ||
        timestamp.minute != values[4] ||
        timestamp.second != values[5]) {
      return null;
    }
    final operationMicros = int.tryParse(match[7]!);
    if (operationMicros == null) return null;
    final operationTime = DateTime.fromMicrosecondsSinceEpoch(
      operationMicros,
      isUtc: true,
    );
    return operationTime == timestamp ? timestamp : null;
  }

  bool _isSafeBackupFileName(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= 255 &&
        path.basename(trimmed) == trimmed &&
        !RegExp(r'[\x00-\x1f\x7f/\\]').hasMatch(trimmed) &&
        path.extension(trimmed).toLowerCase() == '.csebackup';
  }

  static final RegExp _safetyBackupFileName = RegExp(
    r'^safety_before_restore_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})_(\d+)-([0-9a-f]{12})\.csebackup$',
  );

  Future<void> _activatePreparedRestore(
    _PreparedRestore prepared,
    DateTime operationTime,
  ) async {
    final preparedName = path.basename(prepared.root.path);
    if (!preparedName.startsWith('restore-')) {
      throw const MobileBackupFailure(
        'restore_activation_failed',
        'Restore hazırlık alanı doğrulanamadı.',
      );
    }
    final operationId = preparedName.substring('restore-'.length);
    final rollbackRoot = Directory(
      path.join(directories.staging.path, 'rollback-$operationId'),
    );
    final rollbackDatabase = File(
      path.join(rollbackRoot.path, 'database.sqlite3'),
    );
    final rollbackAttachments = Directory(
      path.join(rollbackRoot.path, 'attachments'),
    );
    final recovery = MobileRestoreRecoveryApplication(
      directories: directories,
      databaseFactory: databaseFactory,
      clock: () => operationTime,
    );
    await rollbackRoot.create(recursive: false);
    var journal = await recovery.begin(
      operationId: operationId,
      preparedDirectory: prepared.root,
      rollbackDirectory: rollbackRoot,
    );
    try {
      final activeDatabase = File(directories.databaseFile);
      if (!await activeDatabase.exists() ||
          !await directories.attachments.exists()) {
        throw const MobileBackupFailure(
          'active_state_missing',
          'Mevcut mobil veri alanı eksik; restore durduruldu.',
        );
      }
      await activeDatabase.rename(rollbackDatabase.path);
      await directories.attachments.rename(rollbackAttachments.path);
      journal = await recovery.advance(
        journal,
        RestoreJournalPhase.oldStateMoved,
      );
      await prepared.databaseFile.rename(directories.databaseFile);
      await prepared.attachmentsRoot.rename(directories.attachments.path);
      journal = await recovery.advance(
        journal,
        RestoreJournalPhase.newStateActivated,
      );
      await restoreHooks.afterSwapBeforeSmoke?.call();
      await _validateDatabaseFile(
        File(directories.databaseFile),
        expectedSchema: AppDatabase.schemaVersion,
        operationTime: operationTime,
        allowMigration: false,
      );
      await _requireAttachmentManifestMatchesDatabase(
        File(directories.databaseFile),
        directories.attachments,
        prepared.archive.manifest.attachments,
        sourceSchemaVersion: prepared.archive.manifest.mobileSchemaVersion,
      );
      journal = await recovery.advance(journal, RestoreJournalPhase.validated);
      await restoreHooks.beforeNotificationReconcile?.call();
      await notificationReconciler();
      await recovery.completeValidated(journal);
    } on Object catch (error, stackTrace) {
      try {
        await recovery.rollbackToOld(journal);
      } on Object {
        throw const MobileBackupFailure(
          'restore_rollback_failed',
          'Restore geri alma işlemi tamamlanamadı; safety backup korunuyor.',
        );
      }
      Error.throwWithStackTrace(
        error is MobileBackupFailure
            ? error
            : const MobileBackupFailure(
                'restore_activation_failed',
                'Restore tamamlanamadı; eski mobil hafıza geri getirildi.',
              ),
        stackTrace,
      );
    }
  }

  void _validateManifest(MobileBackupManifest manifest) {
    if (manifest.formatVersion != CseBackupCodec.formatVersion ||
        manifest.appVersion.trim().isEmpty ||
        manifest.buildNumber.trim().isEmpty ||
        manifest.mobileSchemaVersion < 1 ||
        manifest.mobileSchemaVersion > AppDatabase.schemaVersion) {
      throw const MobileBackupFailure(
        'unsupported_schema',
        'Yedek mobil schema sürümü desteklenmiyor.',
      );
    }
    CseTimeCodec.decodeCanonicalUtc(manifest.createdAtUtc);
  }

  Future<void> _validateDatabaseFile(
    File databaseFile, {
    required int expectedSchema,
    required DateTime operationTime,
    required bool allowMigration,
  }) async {
    try {
      await _validateDatabaseFileUnchecked(
        databaseFile,
        expectedSchema: expectedSchema,
        operationTime: operationTime,
        allowMigration: allowMigration,
      );
    } on MobileBackupFailure {
      rethrow;
    } on Object {
      throw const MobileBackupFailure(
        'corrupt_database',
        'Yedek SQLite veritabanı güvenle açılamadı.',
      );
    }
  }

  Future<void> _validateDatabaseFileUnchecked(
    File databaseFile, {
    required int expectedSchema,
    required DateTime operationTime,
    required bool allowMigration,
  }) async {
    if (!await databaseFile.exists()) {
      throw const MobileBackupFailure(
        'database_missing',
        'Yedek veritabanı eksik.',
      );
    }
    Database? raw;
    try {
      raw = await databaseFactory.openDatabase(
        databaseFile.path,
        options: OpenDatabaseOptions(
          singleInstance: false,
          readOnly: !allowMigration,
        ),
      );
      await raw.execute('PRAGMA foreign_keys = ON');
      final version =
          Sqflite.firstIntValue(await raw.rawQuery('PRAGMA user_version')) ?? 0;
      if (version != expectedSchema ||
          version < 1 ||
          version > AppDatabase.schemaVersion) {
        throw const MobileBackupFailure(
          'unsupported_schema',
          'Yedek mobil schema sürümü desteklenmiyor.',
        );
      }
      await _requireDatabaseIntegrity(raw);
    } finally {
      await raw?.close();
    }
    if (allowMigration && expectedSchema < AppDatabase.schemaVersion) {
      final migrated = AppDatabase(
        path: databaseFile.path,
        factory: databaseFactory,
        clock: () => operationTime,
      );
      try {
        await migrated.open();
      } on Object {
        throw const MobileBackupFailure(
          'migration_failed',
          'Yedek schema yükseltmesi güvenli biçimde tamamlanamadı.',
        );
      } finally {
        await migrated.close();
      }
    }
    final current = AppDatabase(
      path: databaseFile.path,
      factory: databaseFactory,
      clock: () => operationTime,
    );
    try {
      await current.open();
      await _requireDatabaseIntegrity(current.database);
      final smoke = await current.database.query('smoke_records', limit: 1);
      if (smoke.isEmpty) {
        throw const MobileBackupFailure(
          'bootstrap_smoke_failed',
          'Yedek başlangıç kaydı doğrulanamadı.',
        );
      }
      for (final table in const [
        'projects',
        'field_observations',
        'observation_events',
        'follow_up_items',
        'follow_up_events',
        'reminder_notification_bindings',
        'subcontractors',
        'workforce_teams',
        'workforce_members',
        'workforce_compliance_records',
        'workforce_ppe_assignments',
        'workforce_events',
        'attendance_days',
        'attendance_entries',
        'attendance_events',
        'concrete_pours',
        'project_concrete_classes',
        'project_concrete_class_events',
        'concrete_pour_context_links',
        'concrete_pour_events',
        'managed_attachments',
        'attachment_links',
        'attachment_link_events',
      ]) {
        await current.database.rawQuery('SELECT count(*) FROM $table');
      }
    } finally {
      await current.close();
    }
  }

  Future<void> _requireDatabaseIntegrity(Database database) async {
    final integrity = await database.rawQuery('PRAGMA integrity_check');
    if (integrity.length != 1 || integrity.single.values.single != 'ok') {
      throw const MobileBackupFailure(
        'corrupt_database',
        'SQLite bütünlük kontrolü başarısız.',
      );
    }
    final foreignKeys = await database.rawQuery('PRAGMA foreign_key_check');
    if (foreignKeys.isNotEmpty) {
      throw const MobileBackupFailure(
        'foreign_key_violation',
        'SQLite ilişki bütünlüğü başarısız.',
      );
    }
  }

  Future<List<Map<String, Object?>>> _activeAttachmentRows(Database database) =>
      database.rawQuery('''
        SELECT DISTINCT m.relative_path, m.byte_size, m.sha256
        FROM managed_attachments m
        JOIN attachment_links l ON l.attachment_id = m.id
        ORDER BY m.relative_path ASC
      ''');

  Future<List<Map<String, Object?>>> _manifestAttachmentRows(
    Database database,
    int sourceSchemaVersion,
  ) => database.rawQuery(
    '''
      SELECT DISTINCT m.relative_path, m.byte_size, m.sha256
      FROM managed_attachments m
      JOIN attachment_links l ON l.attachment_id = m.id
      WHERE ? >= 13
        OR l.legacy_source = 'agenda_log_attachments'
        OR (
          l.legacy_source = 'concrete_attachments'
          AND l.archived_at IS NULL
        )
      ORDER BY m.relative_path ASC
    ''',
    [sourceSchemaVersion],
  );

  Future<void> _requireAttachmentManifestMatchesDatabase(
    File databaseFile,
    Directory attachmentsRoot,
    List<BackupManifestFile> manifestAttachments, {
    required int sourceSchemaVersion,
  }) async {
    Database? database;
    try {
      database = await databaseFactory.openDatabase(
        databaseFile.path,
        options: OpenDatabaseOptions(singleInstance: false, readOnly: true),
      );
      final rows = await _manifestAttachmentRows(database, sourceSchemaVersion);
      final expected = {
        for (final item in manifestAttachments) item.logicalPath: item,
      };
      if (expected.length != manifestAttachments.length ||
          rows.length != expected.length) {
        throw const MobileBackupFailure(
          'attachment_manifest_mismatch',
          'Attachment manifesti SQLite kayıtlarıyla eşleşmiyor.',
        );
      }
      for (final row in rows) {
        final relative = row['relative_path']! as String;
        final manifest = expected[relative];
        if (manifest == null ||
            manifest.byteSize != row['byte_size'] ||
            manifest.sha256 != row['sha256']) {
          throw const MobileBackupFailure(
            'attachment_manifest_mismatch',
            'Attachment manifesti SQLite kayıtlarıyla eşleşmiyor.',
          );
        }
        final file = _resolveWithin(attachmentsRoot, relative);
        if (!await file.exists()) {
          throw const MobileBackupFailure(
            'attachment_missing',
            'Yedek attachment dosyası eksik.',
          );
        }
        final bytes = await file.readAsBytes();
        if (bytes.length != manifest.byteSize ||
            hashes.sha256.convert(bytes).toString() != manifest.sha256) {
          throw const MobileBackupFailure(
            'attachment_integrity_failed',
            'Yedek attachment bütünlüğü doğrulanamadı.',
          );
        }
      }
    } finally {
      await database?.close();
    }
  }

  File _resolveAttachment(String relativePath) =>
      _resolveWithin(directories.attachments, relativePath);

  File _resolveWithin(Directory rootDirectory, String relativePath) {
    CseBackupArchiveCodec._validateLogicalPath(relativePath);
    final root = path.normalize(path.absolute(rootDirectory.path));
    final candidate = path.normalize(
      path.absolute(path.joinAll([root, ...relativePath.split('/')])),
    );
    if (!path.isWithin(root, candidate)) {
      throw const MobileBackupFailure(
        'unsafe_path',
        'Attachment yolu uygulama kökünün dışına çıkıyor.',
      );
    }
    return File(candidate);
  }

  Future<void> _writeBackupSummary(MobileBackupSummary summary) async {
    await directories.state.create(recursive: true);
    final destination = File(directories.backupStateFile);
    final temporary = File('${directories.backupStateFile}.part');
    try {
      await temporary.writeAsString(
        '${const JsonEncoder.withIndent(' ').convert(summary.toJson())}\n',
        flush: true,
      );
      if (await destination.exists()) await destination.delete();
      await temporary.rename(destination.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _deleteStagingDirectory(Directory directory) async {
    directories.validate();
    final stagingRoot = path.normalize(path.absolute(directories.staging.path));
    final candidate = path.normalize(path.absolute(directory.path));
    if (!path.isWithin(stagingRoot, candidate)) {
      throw StateError('staging cleanup escaped its root');
    }
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  void _validateNewPassword(String password, String confirmation) {
    if (password.length < 8 || password.length > 256) {
      throw const MobileBackupFailure(
        'invalid_password',
        'Yedek parolası en az 8, en fazla 256 karakter olmalıdır.',
      );
    }
    if (password != confirmation) {
      throw const MobileBackupFailure(
        'password_confirmation_mismatch',
        'Parola doğrulaması eşleşmiyor.',
      );
    }
  }

  void _validateExistingPassword(String password) {
    if (password.length < 8 || password.length > 256) {
      throw const MobileBackupFailure(
        'invalid_password',
        'Yedek parolası geçersiz.',
      );
    }
  }

  DateTime _readClockOnce() {
    final value = clock();
    CseTimeCodec.encodeUtc(value);
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    );
  }

  String _operationId(DateTime operationTime) {
    final suffix = encryptionCodec
        .randomBytes(6)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${operationTime.microsecondsSinceEpoch}-$suffix';
  }
}

class _PreparedRestore {
  const _PreparedRestore({
    required this.root,
    required this.databaseFile,
    required this.attachmentsRoot,
    required this.archive,
    required this.packageSha256,
  });

  final Directory root;
  final File databaseFile;
  final Directory attachmentsRoot;
  final DecodedCseBackupArchive archive;
  final String packageSha256;
}
