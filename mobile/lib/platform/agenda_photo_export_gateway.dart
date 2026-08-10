import 'dart:io';
import 'dart:typed_data';

import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class AgendaPhotoExportFailure implements Exception {
  const AgendaPhotoExportFailure(this.code);

  final String code;

  @override
  String toString() => code;
}

class AgendaPhotoExportRequest {
  const AgendaPhotoExportRequest({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final List<int> bytes;
}

abstract interface class AgendaPhotoExportGateway {
  Future<bool> save(AgendaPhotoExportRequest request);

  Future<void> share(AgendaPhotoExportRequest request);
}

class UnavailableAgendaPhotoExportGateway implements AgendaPhotoExportGateway {
  const UnavailableAgendaPhotoExportGateway();

  @override
  Future<bool> save(AgendaPhotoExportRequest request) {
    throw const AgendaPhotoExportFailure('photo_save_unavailable');
  }

  @override
  Future<void> share(AgendaPhotoExportRequest request) {
    throw const AgendaPhotoExportFailure('photo_share_unavailable');
  }
}

abstract interface class AgendaPhotoSavePort {
  Future<bool> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  });
}

class FlutterAgendaPhotoSavePort implements AgendaPhotoSavePort {
  const FlutterAgendaPhotoSavePort();

  @override
  Future<bool> save({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final extension = path.extension(fileName).replaceFirst('.', '');
    final selected = await FilePicker.platform.saveFile(
      dialogTitle: 'Ajanda fotoğrafını cihaza kaydet',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );
    return selected != null && selected.trim().isNotEmpty;
  }
}

abstract interface class AgendaPhotoSharePort {
  Future<void> share({
    required String absolutePath,
    required String fileName,
    required String mimeType,
  });
}

class FlutterAgendaPhotoSharePort implements AgendaPhotoSharePort {
  const FlutterAgendaPhotoSharePort();

  @override
  Future<void> share({
    required String absolutePath,
    required String fileName,
    required String mimeType,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Ajanda fotoğrafı',
        subject: 'Ajanda fotoğrafı',
        files: [XFile(absolutePath, name: fileName, mimeType: mimeType)],
      ),
    );
  }
}

class DeviceAgendaPhotoExportGateway implements AgendaPhotoExportGateway {
  DeviceAgendaPhotoExportGateway({
    required this.directories,
    this.savePort = const FlutterAgendaPhotoSavePort(),
    this.sharePort = const FlutterAgendaPhotoSharePort(),
    String Function()? operationIdProvider,
  }) : operationIdProvider = operationIdProvider ?? RecordId.randomUuid;

  final AppDirectories directories;
  final AgendaPhotoSavePort savePort;
  final AgendaPhotoSharePort sharePort;
  final String Function() operationIdProvider;

  @override
  Future<bool> save(AgendaPhotoExportRequest request) async {
    final prepared = _prepare(request);
    return savePort.save(
      fileName: prepared.fileName,
      mimeType: prepared.mimeType,
      bytes: prepared.bytes,
    );
  }

  @override
  Future<void> share(AgendaPhotoExportRequest request) async {
    final prepared = _prepare(request);
    final staged = await _stageShareFile(prepared);
    try {
      await sharePort.share(
        absolutePath: staged.path,
        fileName: prepared.fileName,
        mimeType: prepared.mimeType,
      );
    } finally {
      await _cleanupStagedFile(staged.path);
    }
  }

  Future<File> _stageShareFile(_PreparedAgendaPhoto prepared) async {
    final operationId = operationIdProvider();
    if (!RecordId.isUuid(operationId)) {
      throw const AgendaPhotoExportFailure('invalid_share_operation_id');
    }
    directories.validate();
    await directories.ensureCreated();
    final stagingRoot = path.normalize(path.absolute(directories.staging.path));
    final operationDirectory = Directory(
      path.join(stagingRoot, 'agenda-photo-share-$operationId'),
    );
    final operationPath = path.normalize(
      path.absolute(operationDirectory.path),
    );
    if (!path.isWithin(stagingRoot, operationPath)) {
      throw const PathContractViolation(
        'photo share operation escaped staging',
      );
    }
    if (await FileSystemEntity.type(operationPath, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw const AgendaPhotoExportFailure('share_operation_exists');
    }
    await operationDirectory.create();
    final staged = File(path.join(operationPath, prepared.fileName));
    try {
      await staged.writeAsBytes(prepared.bytes, flush: true);
      if (await FileSystemEntity.type(staged.path, followLinks: false) !=
          FileSystemEntityType.file) {
        throw const AgendaPhotoExportFailure('share_stage_not_file');
      }
      return staged;
    } on Object {
      if (await FileSystemEntity.type(staged.path, followLinks: false) ==
          FileSystemEntityType.file) {
        await staged.delete();
      }
      if (await FileSystemEntity.type(operationPath, followLinks: false) ==
          FileSystemEntityType.directory) {
        await operationDirectory.delete();
      }
      rethrow;
    }
  }

  _PreparedAgendaPhoto _prepare(AgendaPhotoExportRequest request) {
    switch (request.mimeType) {
      case 'image/jpeg':
      case 'image/png':
        break;
      default:
        throw const AgendaPhotoExportFailure('unsupported_photo_mime');
    }
    final bytes = Uint8List.fromList(request.bytes);
    if (bytes.isEmpty) {
      throw const AgendaPhotoExportFailure('empty_photo_bytes');
    }
    try {
      if (DeviceManagedAttachmentStore.sniffMime(bytes) != request.mimeType) {
        throw const AgendaPhotoExportFailure('photo_mime_mismatch');
      }
    } on ManagedAttachmentFailure {
      throw const AgendaPhotoExportFailure('photo_mime_mismatch');
    }
    return _PreparedAgendaPhoto(
      fileName: safeFileName(request.fileName, request.mimeType),
      mimeType: request.mimeType,
      bytes: bytes,
    );
  }

  Future<void> _cleanupStagedFile(String absolutePath) async {
    directories.validate();
    final stagingRoot = path.normalize(path.absolute(directories.staging.path));
    final candidate = path.normalize(path.absolute(absolutePath));
    final operationPath = path.dirname(candidate);
    final operationName = path.basename(operationPath);
    final operationId = operationName.replaceFirst('agenda-photo-share-', '');
    if (!path.isWithin(stagingRoot, candidate) ||
        !operationName.startsWith('agenda-photo-share-') ||
        !RecordId.isUuid(operationId)) {
      throw const PathContractViolation('photo share path escaped staging');
    }
    final type = await FileSystemEntity.type(candidate, followLinks: false);
    if (type != FileSystemEntityType.file &&
        type != FileSystemEntityType.notFound) {
      throw const PathContractViolation('photo share path is not a file');
    }
    if (type == FileSystemEntityType.file) await File(candidate).delete();
    final operationType = await FileSystemEntity.type(
      operationPath,
      followLinks: false,
    );
    if (operationType == FileSystemEntityType.directory) {
      await Directory(operationPath).delete();
    } else if (operationType != FileSystemEntityType.notFound) {
      throw const PathContractViolation(
        'photo share operation path is not a directory',
      );
    }
  }

  static String safeFileName(String originalFileName, String mimeType) {
    final canonicalExtension = switch (mimeType) {
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      _ => throw const AgendaPhotoExportFailure('unsupported_photo_mime'),
    };
    final normalized = originalFileName.trim().replaceAll('\\', '/');
    var leaf = normalized.split('/').last;
    leaf = leaf
        .replaceAll(RegExp(r'[\x00-\x1f\x7f<>:"|?*]'), '_')
        .replaceAll(RegExp(r'[ .]+$'), '')
        .trim();
    final originalExtension = path.posix.extension(leaf).toLowerCase();
    final allowedExtensions = mimeType == 'image/jpeg'
        ? const {'.jpg', '.jpeg'}
        : const {'.png'};
    final extension = allowedExtensions.contains(originalExtension)
        ? originalExtension
        : canonicalExtension;
    var stem = originalExtension.isEmpty
        ? leaf
        : leaf.substring(0, leaf.length - originalExtension.length);
    stem = stem
        .replaceFirst(RegExp(r'^[. ]+'), '')
        .replaceAll(RegExp(r'[ .]+$'), '')
        .trim();
    if (stem.isEmpty || stem == '.' || stem == '..') {
      stem = 'ajanda-fotografi';
    }
    if (_windowsReservedNames.contains(stem.toUpperCase())) {
      stem = '_$stem';
    }
    if (stem.length > 100) stem = stem.substring(0, 100);
    return '$stem$extension';
  }

  static const _windowsReservedNames = {
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  };
}

class _PreparedAgendaPhoto {
  const _PreparedAgendaPhoto({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}
