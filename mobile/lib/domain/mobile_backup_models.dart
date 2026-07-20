class MobileBackupFailure implements Exception {
  const MobileBackupFailure(this.code, this.userMessage);

  final String code;
  final String userMessage;

  @override
  String toString() => 'MobileBackupFailure($code)';
}

class BackupManifestFile {
  const BackupManifestFile({
    required this.logicalPath,
    required this.byteSize,
    required this.sha256,
  });

  final String logicalPath;
  final int byteSize;
  final String sha256;

  Map<String, Object?> toJson() => {
    'logical_path': logicalPath,
    'byte_size': byteSize,
    'sha256': sha256,
  };

  factory BackupManifestFile.fromJson(Map<String, Object?> value) {
    final logicalPath = value['logical_path'];
    final byteSize = value['byte_size'];
    final digest = value['sha256'];
    if (logicalPath is! String || byteSize is! int || digest is! String) {
      throw const MobileBackupFailure(
        'invalid_manifest',
        'Yedek manifesti geçersiz.',
      );
    }
    return BackupManifestFile(
      logicalPath: logicalPath,
      byteSize: byteSize,
      sha256: digest,
    );
  }
}

class MobileBackupManifest {
  const MobileBackupManifest({
    required this.formatVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.mobileSchemaVersion,
    required this.createdAtUtc,
    required this.database,
    required this.attachments,
  });

  final int formatVersion;
  final String appVersion;
  final String buildNumber;
  final int mobileSchemaVersion;
  final String createdAtUtc;
  final BackupManifestFile database;
  final List<BackupManifestFile> attachments;

  Map<String, Object?> toJson() => {
    'format_version': formatVersion,
    'app_version': appVersion,
    'build_number': buildNumber,
    'mobile_schema_version': mobileSchemaVersion,
    'created_at_utc': createdAtUtc,
    'database': database.toJson(),
    'attachments': attachments.map((item) => item.toJson()).toList(),
  };

  factory MobileBackupManifest.fromJson(Map<String, Object?> value) {
    final formatVersion = value['format_version'];
    final appVersion = value['app_version'];
    final buildNumber = value['build_number'];
    final schema = value['mobile_schema_version'];
    final createdAt = value['created_at_utc'];
    final database = value['database'];
    final attachments = value['attachments'];
    if (formatVersion is! int ||
        appVersion is! String ||
        buildNumber is! String ||
        schema is! int ||
        createdAt is! String ||
        database is! Map ||
        attachments is! List) {
      throw const MobileBackupFailure(
        'invalid_manifest',
        'Yedek manifesti geçersiz.',
      );
    }
    return MobileBackupManifest(
      formatVersion: formatVersion,
      appVersion: appVersion,
      buildNumber: buildNumber,
      mobileSchemaVersion: schema,
      createdAtUtc: createdAt,
      database: BackupManifestFile.fromJson(
        Map<String, Object?>.from(database),
      ),
      attachments: List<BackupManifestFile>.unmodifiable(
        attachments.map((item) {
          if (item is! Map) {
            throw const MobileBackupFailure(
              'invalid_manifest',
              'Yedek manifesti geçersiz.',
            );
          }
          return BackupManifestFile.fromJson(Map<String, Object?>.from(item));
        }),
      ),
    );
  }
}

class CreateMobileBackupCommand {
  const CreateMobileBackupCommand({
    required this.password,
    required this.passwordConfirmation,
  });

  final String password;
  final String passwordConfirmation;
}

class PickedBackupPackage {
  const PickedBackupPackage({
    required this.stablePath,
    required this.originalFileName,
    required this.byteSize,
    required this.sha256,
    required this.importOperationId,
  });

  final String stablePath;
  final String originalFileName;
  final int byteSize;
  final String sha256;
  final String importOperationId;
}

class RestoreMobileBackupCommand {
  const RestoreMobileBackupCommand({
    required this.package,
    required this.password,
    required this.expectedPackageSha256,
  });

  final PickedBackupPackage package;
  final String password;
  final String expectedPackageSha256;
}

class MobileBackupSummary {
  const MobileBackupSummary({
    required this.createdAtUtc,
    required this.fileName,
    required this.packageByteSize,
    required this.databaseByteSize,
    required this.attachmentCount,
    required this.attachmentByteSize,
    required this.mobileSchemaVersion,
  });

  final String createdAtUtc;
  final String fileName;
  final int packageByteSize;
  final int databaseByteSize;
  final int attachmentCount;
  final int attachmentByteSize;
  final int mobileSchemaVersion;

  Map<String, Object?> toJson() => {
    'created_at_utc': createdAtUtc,
    'file_name': fileName,
    'package_byte_size': packageByteSize,
    'database_byte_size': databaseByteSize,
    'attachment_count': attachmentCount,
    'attachment_byte_size': attachmentByteSize,
    'mobile_schema_version': mobileSchemaVersion,
  };

  factory MobileBackupSummary.fromJson(Map<String, Object?> value) {
    final createdAt = value['created_at_utc'];
    final fileName = value['file_name'];
    final packageSize = value['package_byte_size'];
    final databaseSize = value['database_byte_size'];
    final attachmentCount = value['attachment_count'];
    final attachmentSize = value['attachment_byte_size'];
    final schema = value['mobile_schema_version'];
    if (createdAt is! String ||
        fileName is! String ||
        packageSize is! int ||
        databaseSize is! int ||
        attachmentCount is! int ||
        attachmentSize is! int ||
        schema is! int) {
      throw const MobileBackupFailure(
        'invalid_backup_state',
        'Son yedek özeti okunamadı.',
      );
    }
    return MobileBackupSummary(
      createdAtUtc: createdAt,
      fileName: fileName,
      packageByteSize: packageSize,
      databaseByteSize: databaseSize,
      attachmentCount: attachmentCount,
      attachmentByteSize: attachmentSize,
      mobileSchemaVersion: schema,
    );
  }
}

class MobileBackupCreationResult {
  const MobileBackupCreationResult({
    required this.absolutePath,
    required this.packageSha256,
    required this.summary,
  });

  final String absolutePath;
  final String packageSha256;
  final MobileBackupSummary summary;

  PickedBackupPackage get package => PickedBackupPackage(
    stablePath: absolutePath,
    originalFileName: summary.fileName,
    byteSize: summary.packageByteSize,
    sha256: packageSha256,
    importOperationId: 'generated-${packageSha256.substring(0, 16)}',
  );
}

class MobileBackupPreflight {
  const MobileBackupPreflight({
    required this.package,
    required this.manifest,
    required this.migratedSchemaVersion,
  });

  final PickedBackupPackage package;
  final MobileBackupManifest manifest;
  final int migratedSchemaVersion;

  String get packagePath => package.stablePath;
  String get packageSha256 => package.sha256;
  int get packageByteSize => package.byteSize;
}

class MobileRestoreResult {
  const MobileRestoreResult({
    required this.restoredManifest,
    required this.safetyBackupPath,
    required this.activeSchemaVersion,
  });

  final MobileBackupManifest restoredManifest;
  final String safetyBackupPath;
  final int activeSchemaVersion;
}
