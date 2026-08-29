import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

typedef InventoryOriginalImagePick =
    Future<XFile?> Function({required ImageSource source});

class FlutterInventoryAttachmentPickerPort implements AttachmentPickerPort {
  FlutterInventoryAttachmentPickerPort({InventoryOriginalImagePick? pickImage})
    : _pickImage = pickImage ?? _pickOriginalImage;

  final InventoryOriginalImagePick _pickImage;

  static Future<XFile?> _pickOriginalImage({required ImageSource source}) =>
      ImagePicker().pickImage(source: source);

  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async {
    final imageSource = switch (source) {
      AttachmentSource.camera => ImageSource.camera,
      AttachmentSource.photoLibrary => ImageSource.gallery,
      AttachmentSource.filePicker => throw UnsupportedError(
        'inventory_file_picker_not_supported',
      ),
    };
    final selected = await _pickImage(source: imageSource);
    if (selected == null) return null;
    return SelectedAttachment(
      name: path.basename(selected.name),
      bytes: await selected.readAsBytes(),
      source: source,
    );
  }
}

class DeviceInventoryAttachmentGateway implements InventoryAttachmentGateway {
  const DeviceInventoryAttachmentGateway({
    required this.picker,
    required this.managedStore,
  });

  static const supportedImageMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/heic',
  };

  final SafeAttachmentPicker picker;
  final ManagedAttachmentStore managedStore;

  @override
  Future<InventoryPhotoPickResult> pick(InventoryPhotoSource source) async {
    final attachmentSource = switch (source) {
      InventoryPhotoSource.camera => AttachmentSource.camera,
      InventoryPhotoSource.photoLibrary => AttachmentSource.photoLibrary,
    };
    final (outcome, selected) = await picker.pick(attachmentSource);
    final mappedOutcome = switch (outcome) {
      AttachmentPickOutcome.selected => InventoryPhotoPickOutcome.selected,
      AttachmentPickOutcome.denied => InventoryPhotoPickOutcome.denied,
      AttachmentPickOutcome.cancelled => InventoryPhotoPickOutcome.cancelled,
      AttachmentPickOutcome.unavailable =>
        InventoryPhotoPickOutcome.unavailable,
    };
    if (mappedOutcome != InventoryPhotoPickOutcome.selected) {
      return InventoryPhotoPickResult(outcome: mappedOutcome);
    }
    if (selected == null || selected.source != attachmentSource) {
      return const InventoryPhotoPickResult(
        outcome: InventoryPhotoPickOutcome.unavailable,
      );
    }
    return InventoryPhotoPickResult(
      outcome: InventoryPhotoPickOutcome.selected,
      selection: InventoryPhotoSelection(
        originalFileName: selected.name,
        bytes: selected.bytes,
        source: source,
      ),
    );
  }

  @override
  Future<StagedInventoryPhoto> stage({
    required String assetId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) async {
    if (!RecordId.isUuid(assetId)) {
      throw const InventoryFailure('inventory_invalid_asset_id');
    }
    if (!RecordId.isUuid(attachmentId)) {
      throw const InventoryFailure('inventory_invalid_attachment_id');
    }
    ManagedAttachmentWrite staged;
    try {
      staged = await managedStore.stage(
        attachmentId: attachmentId,
        originalFileName: originalFileName,
        bytes: bytes,
      );
    } on ManagedAttachmentFailure catch (error) {
      throw InventoryFailure('inventory_photo_${error.code}');
    }
    if (!supportedImageMimeTypes.contains(staged.mimeType)) {
      try {
        await managedStore.cleanup(staged.relativePath);
      } on ManagedAttachmentFailure {
        throw const InventoryFailure('inventory_photo_cleanup_failed');
      }
      throw const InventoryFailure('inventory_photo_invalid_mime');
    }
    return StagedInventoryPhoto(
      relativePath: staged.relativePath,
      mimeType: staged.mimeType,
      byteSize: staged.byteSize,
      sha256Value: staged.sha256Value,
    );
  }

  @override
  Future<InventoryPhotoIntegrity> inspect({
    required String relativePath,
    required String expectedSha256,
    required String expectedMimeType,
    required int expectedByteSize,
  }) async {
    if (!supportedImageMimeTypes.contains(expectedMimeType)) {
      return InventoryPhotoIntegrity.mimeMismatch;
    }
    try {
      final result = await managedStore.inspect(
        relativePath: relativePath,
        expectedSha256: expectedSha256,
        expectedMimeType: expectedMimeType,
        expectedByteSize: expectedByteSize,
      );
      return switch (result) {
        ManagedAttachmentIntegrity.healthy => InventoryPhotoIntegrity.healthy,
        ManagedAttachmentIntegrity.missingFile =>
          InventoryPhotoIntegrity.missingFile,
        ManagedAttachmentIntegrity.sizeMismatch =>
          InventoryPhotoIntegrity.sizeMismatch,
        ManagedAttachmentIntegrity.hashMismatch =>
          InventoryPhotoIntegrity.hashMismatch,
        ManagedAttachmentIntegrity.mimeMismatch =>
          InventoryPhotoIntegrity.mimeMismatch,
        ManagedAttachmentIntegrity.unsafePath =>
          InventoryPhotoIntegrity.unsafePath,
      };
    } on ManagedAttachmentFailure {
      return InventoryPhotoIntegrity.unsafePath;
    }
  }

  @override
  Future<InventoryPhotoContent> read({
    required String relativePath,
    required String originalFileName,
    required String expectedSha256,
    required String expectedMimeType,
    required int expectedByteSize,
  }) async {
    if (!supportedImageMimeTypes.contains(expectedMimeType)) {
      throw const InventoryFailure('inventory_photo_invalid_mime');
    }
    try {
      final content = await managedStore.read(
        relativePath: relativePath,
        originalFileName: originalFileName,
        expectedSha256: expectedSha256,
        expectedMimeType: expectedMimeType,
        expectedByteSize: expectedByteSize,
      );
      return InventoryPhotoContent(
        fileName: content.fileName,
        mimeType: content.mimeType,
        bytes: content.bytes,
      );
    } on ManagedAttachmentFailure catch (error) {
      throw InventoryFailure('inventory_photo_${error.code}');
    }
  }

  @override
  Future<void> cleanup(String relativePath) async {
    try {
      await managedStore.cleanup(relativePath);
    } on ManagedAttachmentFailure catch (error) {
      throw InventoryFailure('inventory_photo_${error.code}');
    }
  }
}
