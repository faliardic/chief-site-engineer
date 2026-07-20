import 'dart:io';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class ConcreteAttachmentFailure implements Exception {
  const ConcreteAttachmentFailure(this.code);
  final String code;

  @override
  String toString() => code;
}

class StagedConcreteAttachment {
  const StagedConcreteAttachment({
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

abstract interface class ConcreteAttachmentStore {
  Future<StagedConcreteAttachment> stage({
    required String pourId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  });

  Future<ConcreteAttachmentIntegrity> inspect(
    String relativePath,
    String expectedSha256, [
    String? expectedMimeType,
  ]);

  Future<StoredAttachmentContent> read(
    String relativePath,
    String originalFileName,
    String expectedSha256,
    String expectedMimeType,
  );

  Future<void> open(String relativePath, String expectedMimeType);

  Future<void> cleanup(String relativePath);
}

class DeviceConcreteAttachmentStore implements ConcreteAttachmentStore {
  const DeviceConcreteAttachmentStore({
    required this.directories,
    this.maximumBytes = 20 * 1024 * 1024,
  });

  final AppDirectories directories;
  final int maximumBytes;

  @override
  Future<StagedConcreteAttachment> stage({
    required String pourId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) async {
    validateUuid(pourId, 'Beton paketi kimliği');
    validateUuid(attachmentId, 'Kanıt kimliği');
    final safeName = path.basename(originalFileName.trim());
    if (safeName.isEmpty || safeName != originalFileName.trim()) {
      throw const ConcreteAttachmentFailure('invalid_file_name');
    }
    if (bytes.isEmpty || bytes.length > maximumBytes) {
      throw const ConcreteAttachmentFailure('invalid_file_size');
    }
    final mime = _sniffMime(bytes);
    final extension = switch (mime) {
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      'image/heic' => '.heic',
      'application/pdf' => '.pdf',
      _ => throw const ConcreteAttachmentFailure('unsupported_mime'),
    };
    directories.validate();
    await directories.ensureCreated();
    final relative = path.join('concrete', pourId, '$attachmentId$extension');
    final destination = _resolve(relative);
    final temporary = File(
      path.join(directories.staging.path, 'concrete-$attachmentId.part'),
    );
    if (await destination.exists() || await temporary.exists()) {
      throw const ConcreteAttachmentFailure('attachment_destination_exists');
    }
    await destination.parent.create(recursive: true);
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(destination.path);
    } on Object {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
    return StagedConcreteAttachment(
      relativePath: path.posix.join(
        'concrete',
        pourId,
        '$attachmentId$extension',
      ),
      mimeType: mime,
      byteSize: bytes.length,
      sha256Value: sha256.convert(bytes).toString(),
    );
  }

  @override
  Future<ConcreteAttachmentIntegrity> inspect(
    String relativePath,
    String expectedSha256, [
    String? expectedMimeType,
  ]) async {
    final file = _resolve(relativePath);
    if (!await file.exists()) return ConcreteAttachmentIntegrity.missing;
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    if (digest != expectedSha256) return ConcreteAttachmentIntegrity.tampered;
    if (expectedMimeType != null) {
      try {
        if (_sniffMime(bytes) != expectedMimeType) {
          return ConcreteAttachmentIntegrity.tampered;
        }
      } on ConcreteAttachmentFailure {
        return ConcreteAttachmentIntegrity.tampered;
      }
    }
    return ConcreteAttachmentIntegrity.ok;
  }

  @override
  Future<StoredAttachmentContent> read(
    String relativePath,
    String originalFileName,
    String expectedSha256,
    String expectedMimeType,
  ) async {
    if (await inspect(relativePath, expectedSha256, expectedMimeType) !=
        ConcreteAttachmentIntegrity.ok) {
      throw const ConcreteAttachmentFailure('attachment_integrity_failed');
    }
    return StoredAttachmentContent(
      fileName: path.basename(originalFileName),
      mimeType: expectedMimeType,
      bytes: await _resolve(relativePath).readAsBytes(),
    );
  }

  @override
  Future<void> open(String relativePath, String expectedMimeType) async {
    final file = _resolve(relativePath);
    if (!await file.exists()) {
      throw const ConcreteAttachmentFailure('attachment_missing');
    }
    final bytes = await file.readAsBytes();
    if (_sniffMime(bytes) != expectedMimeType) {
      throw const ConcreteAttachmentFailure('attachment_mime_mismatch');
    }
    final result = await OpenFilex.open(file.path, type: expectedMimeType);
    if (result.type != ResultType.done) {
      throw ConcreteAttachmentFailure('viewer_${result.type.name}');
    }
  }

  @override
  Future<void> cleanup(String relativePath) async {
    final file = _resolve(relativePath);
    if (await file.exists()) await file.delete();
  }

  File _resolve(String relativePath) {
    directories.validate();
    if (relativePath.trim().isEmpty || path.isAbsolute(relativePath)) {
      throw const ConcreteAttachmentFailure('invalid_relative_path');
    }
    final root = path.normalize(path.absolute(directories.attachments.path));
    final candidate = path.normalize(
      path.absolute(path.join(root, path.normalize(relativePath))),
    );
    if (!path.isWithin(root, candidate)) {
      throw const ConcreteAttachmentFailure('attachment_path_escaped_root');
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
    if (bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-') {
      return 'application/pdf';
    }
    if (bytes.length >= 12) {
      final brand = String.fromCharCodes(bytes.sublist(4, 12));
      if (brand.startsWith('ftyp') &&
          const {
            'heic',
            'heix',
            'hevc',
            'hevx',
            'mif1',
          }.contains(brand.substring(4))) {
        return 'image/heic';
      }
    }
    throw const ConcreteAttachmentFailure('unsupported_mime');
  }
}

class DevicePermissionGateway implements PermissionGateway {
  const DevicePermissionGateway();

  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async {
    if (capability == DeviceCapability.filePicker ||
        capability == DeviceCapability.export) {
      return CapabilityStatus.granted;
    }
    if (capability == DeviceCapability.photoLibrary && Platform.isAndroid) {
      return CapabilityStatus.granted;
    }
    final permission = switch (capability) {
      DeviceCapability.camera => Permission.camera,
      DeviceCapability.photoLibrary => Permission.photos,
      DeviceCapability.notification => Permission.notification,
      DeviceCapability.filePicker || DeviceCapability.export => null,
    };
    if (permission == null) return CapabilityStatus.granted;
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return CapabilityStatus.granted;
    if (status.isDenied || status.isPermanentlyDenied) {
      return CapabilityStatus.denied;
    }
    return CapabilityStatus.unavailable;
  }
}

class FlutterAttachmentPickerPort implements AttachmentPickerPort {
  FlutterAttachmentPickerPort({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async {
    switch (source) {
      case AttachmentSource.camera:
      case AttachmentSource.photoLibrary:
        final file = await _imagePicker.pickImage(
          source: source == AttachmentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 92,
        );
        if (file == null) return null;
        return SelectedAttachment(
          name: path.basename(file.name),
          bytes: await file.readAsBytes(),
          source: source,
        );
      case AttachmentSource.filePicker:
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          withData: true,
          type: FileType.custom,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'heic', 'pdf'],
        );
        if (result == null || result.files.isEmpty) return null;
        final selected = result.files.single;
        final data =
            selected.bytes ??
            (selected.path == null
                ? null
                : await File(selected.path!).readAsBytes());
        if (data == null) return null;
        return SelectedAttachment(
          name: path.basename(selected.name),
          bytes: data,
          source: source,
        );
    }
  }
}
