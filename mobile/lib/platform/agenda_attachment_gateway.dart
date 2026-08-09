import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';

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
  DeviceAgendaAttachmentStore({
    required AppDirectories directories,
    int maximumBytes = 20 * 1024 * 1024,
  }) : managedStore = DeviceManagedAttachmentStore(
         directories: directories,
         maximumBytes: maximumBytes,
       );

  const DeviceAgendaAttachmentStore.shared({required this.managedStore});

  final ManagedAttachmentStore managedStore;

  @override
  Future<StagedAgendaPhoto> stage({
    required String logId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) async {
    validateUuid(logId, 'Log kimliği');
    validateUuid(attachmentId, 'Fotoğraf kimliği');
    try {
      final staged = await managedStore.stage(
        attachmentId: attachmentId,
        originalFileName: originalFileName,
        bytes: bytes,
      );
      return StagedAgendaPhoto(
        relativePath: staged.relativePath,
        mimeType: staged.mimeType,
        byteSize: staged.byteSize,
        sha256Value: staged.sha256Value,
      );
    } on ManagedAttachmentFailure catch (error) {
      throw AgendaAttachmentFailure(error.code);
    }
  }

  @override
  Future<AgendaAttachmentIntegrity> inspect(
    String relativePath,
    String expectedSha256,
    String expectedMimeType,
  ) async {
    try {
      final result = await managedStore.inspect(
        relativePath: relativePath,
        expectedSha256: expectedSha256,
        expectedMimeType: expectedMimeType,
      );
      return switch (result) {
        ManagedAttachmentIntegrity.healthy => AgendaAttachmentIntegrity.ok,
        ManagedAttachmentIntegrity.missingFile ||
        ManagedAttachmentIntegrity.unsafePath =>
          AgendaAttachmentIntegrity.missing,
        ManagedAttachmentIntegrity.mimeMismatch =>
          AgendaAttachmentIntegrity.invalidMime,
        ManagedAttachmentIntegrity.sizeMismatch ||
        ManagedAttachmentIntegrity.hashMismatch =>
          AgendaAttachmentIntegrity.tampered,
      };
    } on ManagedAttachmentFailure catch (error) {
      throw AgendaAttachmentFailure(error.code);
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
      throw AgendaAttachmentFailure(error.code);
    }
  }

  @override
  Future<void> cleanup(String relativePath) async {
    try {
      await managedStore.cleanup(relativePath);
    } on ManagedAttachmentFailure catch (error) {
      throw AgendaAttachmentFailure(error.code);
    }
  }
}
