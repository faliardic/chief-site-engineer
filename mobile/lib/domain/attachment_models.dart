enum ManagedAttachmentIntegrity {
  healthy('healthy'),
  missingFile('missing_file'),
  sizeMismatch('size_mismatch'),
  hashMismatch('hash_mismatch'),
  mimeMismatch('mime_mismatch'),
  unsafePath('unsafe_path');

  const ManagedAttachmentIntegrity(this.code);

  final String code;
}

class ManagedAttachmentFailure implements Exception {
  const ManagedAttachmentFailure(this.code);

  final String code;

  @override
  String toString() => code;
}

class AttachmentReconciliationFailure implements Exception {
  const AttachmentReconciliationFailure(this.code);

  final String code;

  @override
  String toString() => code;
}

class AttachmentCatalogFailure implements Exception {
  const AttachmentCatalogFailure(this.code);

  final String code;

  @override
  String toString() => code;
}

class ManagedAttachmentWrite {
  const ManagedAttachmentWrite({
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

class ManagedAttachmentContent {
  const ManagedAttachmentContent({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final List<int> bytes;
}

class AttachmentCatalogProject {
  const AttachmentCatalogProject({required this.id, required this.name});

  final String id;
  final String name;
}

enum AttachmentCatalogSourceType {
  agendaObservation('agenda_observation', 'Ajanda'),
  concretePour('concrete_pour', 'Beton');

  const AttachmentCatalogSourceType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static AttachmentCatalogSourceType fromStorage(String value) =>
      values.firstWhere(
        (item) => item.storageValue == value,
        orElse: () =>
            throw const AttachmentCatalogFailure('unsupported_source_type'),
      );
}

class AttachmentCatalogLink {
  const AttachmentCatalogLink({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.sourceLabel,
    required this.role,
    required this.originalFileName,
    required this.createdAt,
    required this.archivedAt,
    this.contextType,
    this.contextId,
  });

  final String id;
  final AttachmentCatalogSourceType sourceType;
  final String sourceId;
  final String sourceLabel;
  final String role;
  final String originalFileName;
  final String? contextType;
  final String? contextId;
  final String createdAt;
  final String? archivedAt;

  bool get isActive => archivedAt == null;
}

class ProjectAttachmentCatalogItem {
  ProjectAttachmentCatalogItem({
    required this.physicalAttachmentId,
    required this.relativePath,
    required this.mimeType,
    required this.byteSize,
    required this.sha256Value,
    required this.createdAt,
    required this.integrity,
    required Iterable<AttachmentCatalogLink> links,
  }) : links = List.unmodifiable(links);

  final String physicalAttachmentId;
  final String relativePath;
  final String mimeType;
  final int byteSize;
  final String sha256Value;
  final String createdAt;
  final ManagedAttachmentIntegrity integrity;
  final List<AttachmentCatalogLink> links;

  String get displayFileName => links.first.originalFileName;

  bool get isImage =>
      const {'image/jpeg', 'image/png', 'image/heic'}.contains(mimeType);

  bool isActivelyLinkedTo(AttachmentCatalogSourceType type, String sourceId) =>
      links.any(
        (link) =>
            link.isActive &&
            link.sourceType == type &&
            link.sourceId == sourceId,
      );
}

enum AttachmentReconciliationFindingType {
  healthy('healthy'),
  missingFile('missing_file'),
  sizeMismatch('size_mismatch'),
  hashMismatch('hash_mismatch'),
  mimeMismatch('mime_mismatch'),
  unsafePath('unsafe_path'),
  brokenTarget('broken_target'),
  crossProjectTarget('cross_project_target'),
  orphanFinalizedFile('orphan_finalized_file'),
  staleStagingFile('stale_staging_file'),
  duplicateLegacyCandidate('duplicate_legacy_candidate');

  const AttachmentReconciliationFindingType(this.code);

  final String code;
}

class AttachmentReconciliationFinding {
  const AttachmentReconciliationFinding({
    required this.type,
    this.attachmentId,
    this.linkId,
    this.relativePath,
    this.relatedAttachmentIds = const <String>[],
  });

  final AttachmentReconciliationFindingType type;
  final String? attachmentId;
  final String? linkId;
  final String? relativePath;
  final List<String> relatedAttachmentIds;
}

class AttachmentReconciliationReport {
  AttachmentReconciliationReport(
    Iterable<AttachmentReconciliationFinding> values,
  ) : findings = List.unmodifiable(values);

  final List<AttachmentReconciliationFinding> findings;

  Iterable<AttachmentReconciliationFinding> ofType(
    AttachmentReconciliationFindingType type,
  ) => findings.where((finding) => finding.type == type);

  bool get hasProblems => findings.any(
    (finding) => finding.type != AttachmentReconciliationFindingType.healthy,
  );

  int get healthyCount =>
      ofType(AttachmentReconciliationFindingType.healthy).length;

  int get problemCount => findings.length - healthyCount;
}
