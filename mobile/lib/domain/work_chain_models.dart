enum WorkChainFollowUpKind {
  action('action', 'Aksiyon'),
  recheck('recheck', 'Tekrar kontrol');

  const WorkChainFollowUpKind(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static WorkChainFollowUpKind fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const FormatException('work_chain_invalid_kind'),
  );
}

enum WorkChainFollowUpStatus {
  inbox('inbox', 'Unutma Kutusu'),
  active('active', 'Aktif'),
  completed('completed', 'Tamamlandı'),
  cancelled('cancelled', 'İptal edildi');

  const WorkChainFollowUpStatus(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static WorkChainFollowUpStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const FormatException('work_chain_invalid_status'),
  );
}

enum WorkChainOutcomeType {
  completed('completed', 'Tamamlandı'),
  noLongerNeeded('no_longer_needed', 'Artık gerekli değil');

  const WorkChainOutcomeType(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static WorkChainOutcomeType fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const FormatException('work_chain_invalid_outcome'),
  );
}

enum WorkChainDiagnosticCode {
  agendaMissing('work_chain_agenda_missing', 'Kaynak Ajanda kaydı bulunamadı.'),
  followUpMissing(
    'work_chain_follow_up_missing',
    'Bağlı takip kaydı bulunamadı.',
  ),
  projectMismatch(
    'work_chain_project_mismatch',
    'Kaynak ile takip kaydının proje bağı uyuşmuyor.',
  ),
  sourceObservationMismatch(
    'work_chain_source_observation_mismatch',
    'Takip kaydının kaynak Ajanda bağı uyuşmuyor.',
  ),
  duplicateRelation(
    'work_chain_duplicate_relation',
    'Aynı ilişki birden fazla kez bulundu.',
  ),
  eventOrderIntegrity(
    'work_chain_event_order_integrity',
    'Takip olay sırası bütünlük kontrolünü geçemedi.',
  ),
  projectionContradiction(
    'work_chain_projection_contradiction',
    'Son olay ile güncel takip durumu çelişiyor.',
  );

  const WorkChainDiagnosticCode(this.code, this.message);
  final String code;
  final String message;
}

class WorkChainFailure implements Exception {
  const WorkChainFailure(this.code);
  final String code;

  @override
  String toString() => code;
}

class WorkChainRoot {
  const WorkChainRoot({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.observedAt,
    required this.category,
    required this.description,
    required this.location,
    required this.notes,
    required this.archivedAt,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String observedAt;
  final String category;
  final String description;
  final String? location;
  final String? notes;
  final String? archivedAt;
}

class WorkChainEvent {
  const WorkChainEvent({
    required this.id,
    required this.followUpId,
    required this.projectId,
    required this.sourceObservationId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.payload,
  });

  final String id;
  final String followUpId;
  final String? projectId;
  final String? sourceObservationId;
  final int sequence;
  final String eventType;
  final String occurredAt;
  final Map<String, Object?> payload;
}

class WorkChainResult {
  const WorkChainResult({
    required this.status,
    required this.outcomeType,
    required this.note,
    required this.completedAt,
    required this.cancelledAt,
  });

  final WorkChainFollowUpStatus status;
  final WorkChainOutcomeType? outcomeType;
  final String? note;
  final String? completedAt;
  final String? cancelledAt;
}

class WorkChainFollowUp {
  const WorkChainFollowUp({
    required this.id,
    required this.projectId,
    required this.sourceObservationId,
    required this.kind,
    required this.status,
    required this.title,
    required this.description,
    required this.nextAttentionAt,
    required this.allDayLocalDate,
    required this.deadlineAt,
    required this.conditionText,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.trashedAt,
    required this.events,
    required this.result,
  });

  final String id;
  final String? projectId;
  final String? sourceObservationId;
  final WorkChainFollowUpKind kind;
  final WorkChainFollowUpStatus status;
  final String title;
  final String? description;
  final String? nextAttentionAt;
  final String? allDayLocalDate;
  final String? deadlineAt;
  final String? conditionText;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? trashedAt;
  final List<WorkChainEvent> events;
  final WorkChainResult result;
}

class WorkChainDiagnostic {
  const WorkChainDiagnostic({
    required this.code,
    this.followUpId,
    this.eventId,
  });

  final WorkChainDiagnosticCode code;
  final String? followUpId;
  final String? eventId;
}

class WorkChainDetail {
  const WorkChainDetail({
    required this.root,
    required this.followUps,
    required this.diagnostics,
  });

  final WorkChainRoot? root;
  final List<WorkChainFollowUp> followUps;
  final List<WorkChainDiagnostic> diagnostics;
}
