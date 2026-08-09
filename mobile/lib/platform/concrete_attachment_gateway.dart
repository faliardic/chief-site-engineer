import 'dart:io';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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
  DeviceConcreteAttachmentStore({
    required AppDirectories directories,
    int maximumBytes = 20 * 1024 * 1024,
  }) : managedStore = DeviceManagedAttachmentStore(
         directories: directories,
         maximumBytes: maximumBytes,
       );

  const DeviceConcreteAttachmentStore.shared({required this.managedStore});

  final ManagedAttachmentStore managedStore;

  @override
  Future<StagedConcreteAttachment> stage({
    required String pourId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) async {
    validateUuid(pourId, 'Beton paketi kimliği');
    validateUuid(attachmentId, 'Kanıt kimliği');
    try {
      final staged = await managedStore.stage(
        attachmentId: attachmentId,
        originalFileName: originalFileName,
        bytes: bytes,
      );
      return StagedConcreteAttachment(
        relativePath: staged.relativePath,
        mimeType: staged.mimeType,
        byteSize: staged.byteSize,
        sha256Value: staged.sha256Value,
      );
    } on ManagedAttachmentFailure catch (error) {
      throw ConcreteAttachmentFailure(error.code);
    }
  }

  @override
  Future<ConcreteAttachmentIntegrity> inspect(
    String relativePath,
    String expectedSha256, [
    String? expectedMimeType,
  ]) async {
    try {
      final result = await managedStore.inspect(
        relativePath: relativePath,
        expectedSha256: expectedSha256,
        expectedMimeType: expectedMimeType,
      );
      return switch (result) {
        ManagedAttachmentIntegrity.healthy => ConcreteAttachmentIntegrity.ok,
        ManagedAttachmentIntegrity.missingFile ||
        ManagedAttachmentIntegrity.unsafePath =>
          ConcreteAttachmentIntegrity.missing,
        ManagedAttachmentIntegrity.sizeMismatch ||
        ManagedAttachmentIntegrity.hashMismatch ||
        ManagedAttachmentIntegrity.mimeMismatch =>
          ConcreteAttachmentIntegrity.tampered,
      };
    } on ManagedAttachmentFailure catch (error) {
      throw ConcreteAttachmentFailure(error.code);
    }
  }

  @override
  Future<StoredAttachmentContent> read(
    String relativePath,
    String originalFileName,
    String expectedSha256,
    String expectedMimeType,
  ) async {
    try {
      final content = await managedStore.read(
        relativePath: relativePath,
        originalFileName: originalFileName,
        expectedSha256: expectedSha256,
        expectedMimeType: expectedMimeType,
      );
      return StoredAttachmentContent(
        fileName: content.fileName,
        mimeType: content.mimeType,
        bytes: content.bytes,
      );
    } on ManagedAttachmentFailure catch (error) {
      throw ConcreteAttachmentFailure(error.code);
    }
  }

  @override
  Future<void> open(String relativePath, String expectedMimeType) async {
    try {
      await managedStore.open(
        relativePath: relativePath,
        expectedMimeType: expectedMimeType,
      );
    } on ManagedAttachmentFailure catch (error) {
      throw ConcreteAttachmentFailure(error.code);
    }
  }

  @override
  Future<void> cleanup(String relativePath) async {
    try {
      await managedStore.cleanup(relativePath);
    } on ManagedAttachmentFailure catch (error) {
      throw ConcreteAttachmentFailure(error.code);
    }
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

class FlutterAttachmentPickerPort
    implements AttachmentPickerPort, MultipleAttachmentPickerPort {
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
          allowedExtensions: const [
            'jpg',
            'jpeg',
            'png',
            'heic',
            'pdf',
            'mp4',
            'mp3',
            'm4a',
            'wav',
          ],
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

  @override
  Future<List<SelectedAttachment>?> pickMany(AttachmentSource source) async {
    switch (source) {
      case AttachmentSource.camera:
        final selected = await pick(source);
        return selected == null ? null : [selected];
      case AttachmentSource.photoLibrary:
        final files = await _imagePicker.pickMultiImage(
          imageQuality: 92,
          limit: SafeAttachmentPicker.maximumBatchItems,
        );
        if (files.isEmpty) return null;
        final selected = <SelectedAttachment>[];
        for (final file in files) {
          selected.add(
            SelectedAttachment(
              name: path.basename(file.name),
              bytes: await file.readAsBytes(),
              source: source,
            ),
          );
        }
        return selected;
      case AttachmentSource.filePicker:
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          withData: true,
          type: FileType.custom,
          allowedExtensions: const [
            'jpg',
            'jpeg',
            'png',
            'heic',
            'pdf',
            'mp4',
            'mp3',
            'm4a',
            'wav',
          ],
        );
        if (result == null || result.files.isEmpty) return null;
        final selected = <SelectedAttachment>[];
        for (final file in result.files) {
          final data =
              file.bytes ??
              (file.path == null ? null : await File(file.path!).readAsBytes());
          if (data == null) return null;
          selected.add(
            SelectedAttachment(
              name: path.basename(file.name),
              bytes: data,
              source: source,
            ),
          );
        }
        return selected;
    }
  }
}
