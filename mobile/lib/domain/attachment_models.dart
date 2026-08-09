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
}
