import 'package:chief_site_engineer/domain/agenda_models.dart';

enum ConcretePourStatus {
  draft('draft', 'Taslak'),
  prepared('prepared', 'Hazır'),
  pouring('pouring', 'Dökülüyor'),
  poured('poured', 'Döküm bitti'),
  followUp('follow_up', 'Takipte'),
  closed('closed', 'Kapalı'),
  cancelled('cancelled', 'İptal');

  const ConcretePourStatus(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static ConcretePourStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'Beton paketi durumu desteklenmiyor.',
    ),
  );
}

enum ConcreteCheckStatus {
  pending('pending', 'Bekliyor'),
  completed('completed', 'Tamamlandı'),
  notApplicable('not_applicable', 'Uygulanamaz'),
  exception('exception', 'İstisna');

  const ConcreteCheckStatus(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static ConcreteCheckStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'Kontrol kalemi durumu desteklenmiyor.',
    ),
  );
}

enum ConcreteTruckResult {
  received('received', 'Teslim alındı'),
  held('held', 'Bekletildi'),
  returned('returned', 'İade edildi'),
  partial('partial', 'Kısmi');

  const ConcreteTruckResult(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static ConcreteTruckResult fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () =>
        throw const AgendaValidationFailure('Mikser sonucu desteklenmiyor.'),
  );
}

enum ConcreteSampleStatus {
  planned('planned', 'Planlandı'),
  sampled('sampled', 'Numune alındı'),
  delivered('delivered', 'Laboratuvara teslim'),
  waitingResult('waiting_result', 'Sonuç bekleniyor'),
  completed('completed', 'Tamamlandı'),
  exception('exception', 'İstisna');

  const ConcreteSampleStatus(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static ConcreteSampleStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () =>
        throw const AgendaValidationFailure('Numune durumu desteklenmiyor.'),
  );
}

enum ConcreteFollowUpStatus {
  pending('pending', 'Açık'),
  completed('completed', 'Tamamlandı'),
  exception('exception', 'İstisna');

  const ConcreteFollowUpStatus(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static ConcreteFollowUpStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'Beton takip durumu desteklenmiyor.',
    ),
  );
}

enum ConcreteEvidenceType {
  deliveryReceiptScan('delivery_receipt_scan', 'İrsaliye taraması'),
  mixerPhoto('mixer_photo', 'Mikser fotoğrafı'),
  sitePhoto('site_photo', 'Saha fotoğrafı'),
  samplePhoto('sample_photo', 'Numune fotoğrafı'),
  laboratoryDeliveryDocument(
    'laboratory_delivery_document',
    'Laboratuvar teslim belgesi',
  ),
  resultDocument('result_document', 'Sonuç belgesi'),
  other('other', 'Diğer');

  const ConcreteEvidenceType(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static ConcreteEvidenceType fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () =>
        throw const AgendaValidationFailure('Kanıt türü desteklenmiyor.'),
  );
}

enum ConcreteAttachmentIntegrity {
  ok('Dosya doğrulandı'),
  missing('Dosya eksik'),
  tampered('Dosya bütünlüğü bozuk');

  const ConcreteAttachmentIntegrity(this.label);
  final String label;
}

enum ConcretePourGroup { today, upcoming, inProgress, followUp, closed }

class ConcretePourQuery {
  const ConcretePourQuery({
    required this.group,
    this.projectId,
    this.istanbulDay,
    this.literalSearch = '',
  });

  final ConcretePourGroup group;
  final String? projectId;
  final String? istanbulDay;
  final String literalSearch;
}

class ConcretePour {
  const ConcretePour({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.pourCode,
    required this.elementLocation,
    required this.blockName,
    required this.floorName,
    required this.axisName,
    required this.plannedAt,
    required this.actualStartedAt,
    required this.actualEndedAt,
    required this.concreteClass,
    required this.targetSlump,
    required this.plannedVolumeM3,
    required this.orderedVolumeM3,
    required this.plantName,
    required this.plantBranch,
    required this.plantContact,
    required this.plantAppointmentReference,
    required this.pumpEquipment,
    required this.laboratoryName,
    required this.laboratoryContact,
    required this.laboratoryAppointment,
    required this.inspectionNotifiedAt,
    required this.inspectionNotifiedPerson,
    required this.status,
    required this.generalNote,
    required this.sampleExceptionReason,
    required this.varianceNote,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
    required this.cancelledAt,
    this.pendingCheckCount = 0,
    this.missingEvidenceTruckCount = 0,
    this.openFollowUpCount = 0,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String pourCode;
  final String elementLocation;
  final String? blockName;
  final String? floorName;
  final String? axisName;
  final String plannedAt;
  final String? actualStartedAt;
  final String? actualEndedAt;
  final String concreteClass;
  final String? targetSlump;
  final double plannedVolumeM3;
  final double? orderedVolumeM3;
  final String? plantName;
  final String? plantBranch;
  final String? plantContact;
  final String? plantAppointmentReference;
  final String? pumpEquipment;
  final String? laboratoryName;
  final String? laboratoryContact;
  final String? laboratoryAppointment;
  final String? inspectionNotifiedAt;
  final String? inspectionNotifiedPerson;
  final ConcretePourStatus status;
  final String? generalNote;
  final String? sampleExceptionReason;
  final String? varianceNote;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? closedAt;
  final String? cancelledAt;
  final int pendingCheckCount;
  final int missingEvidenceTruckCount;
  final int openFollowUpCount;
}

class ConcreteCheckItem {
  const ConcreteCheckItem({
    required this.id,
    required this.pourId,
    required this.itemKey,
    required this.label,
    required this.sortOrder,
    required this.isRequired,
    required this.status,
    required this.note,
    required this.reason,
    required this.revision,
    required this.updatedAt,
  });

  final String id;
  final String pourId;
  final String itemKey;
  final String label;
  final int sortOrder;
  final bool isRequired;
  final ConcreteCheckStatus status;
  final String? note;
  final String? reason;
  final int revision;
  final String updatedAt;
}

class ConcreteTruck {
  const ConcreteTruck({
    required this.id,
    required this.pourId,
    required this.sequenceNo,
    required this.vehiclePlate,
    required this.deliveryNoteNumber,
    required this.plantSnapshot,
    required this.batchTime,
    required this.arrivedAt,
    required this.unloadingStartedAt,
    required this.unloadingEndedAt,
    required this.volumeM3,
    required this.measuredSlump,
    required this.concreteTemperature,
    required this.result,
    required this.reason,
    required this.evidenceExceptionReason,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String pourId;
  final int sequenceNo;
  final String vehiclePlate;
  final String deliveryNoteNumber;
  final String? plantSnapshot;
  final String? batchTime;
  final String? arrivedAt;
  final String? unloadingStartedAt;
  final String? unloadingEndedAt;
  final double volumeM3;
  final double? measuredSlump;
  final double? concreteTemperature;
  final ConcreteTruckResult result;
  final String? reason;
  final String? evidenceExceptionReason;
  final int revision;
  final String createdAt;
  final String updatedAt;
}

class ConcreteSampleSet {
  const ConcreteSampleSet({
    required this.id,
    required this.pourId,
    required this.sourceTruckId,
    required this.sampleCode,
    required this.sampleCount,
    required this.sampleLabels,
    required this.sampledAt,
    required this.sampledBy,
    required this.laboratoryAppointmentAt,
    required this.deliveredAt,
    required this.deliveredTo,
    required this.expectedResultDates,
    required this.status,
    required this.note,
    required this.reason,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String pourId;
  final String? sourceTruckId;
  final String sampleCode;
  final int sampleCount;
  final List<String> sampleLabels;
  final String? sampledAt;
  final String? sampledBy;
  final String? laboratoryAppointmentAt;
  final String? deliveredAt;
  final String? deliveredTo;
  final List<String> expectedResultDates;
  final ConcreteSampleStatus status;
  final String? note;
  final String? reason;
  final int revision;
  final String createdAt;
  final String updatedAt;
}

class ConcreteFollowUp {
  const ConcreteFollowUp({
    required this.id,
    required this.pourId,
    required this.sourceSampleSetId,
    required this.itemKey,
    required this.label,
    required this.dueAt,
    required this.status,
    required this.reminderId,
    required this.note,
    required this.reason,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
  });

  final String id;
  final String pourId;
  final String? sourceSampleSetId;
  final String itemKey;
  final String label;
  final String? dueAt;
  final ConcreteFollowUpStatus status;
  final String? reminderId;
  final String? note;
  final String? reason;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
}

class ConcreteAttachment {
  const ConcreteAttachment({
    required this.id,
    required this.pourId,
    required this.truckId,
    required this.sampleSetId,
    required this.checkItemId,
    required this.evidenceType,
    required this.originalFileName,
    required this.mimeType,
    required this.byteSize,
    required this.sha256,
    required this.relativePath,
    required this.capturedAt,
    required this.description,
    required this.createdAt,
    required this.integrity,
  });

  final String id;
  final String pourId;
  final String? truckId;
  final String? sampleSetId;
  final String? checkItemId;
  final ConcreteEvidenceType evidenceType;
  final String originalFileName;
  final String mimeType;
  final int byteSize;
  final String sha256;
  final String relativePath;
  final String capturedAt;
  final String? description;
  final String createdAt;
  final ConcreteAttachmentIntegrity integrity;
}

class ConcretePourEvent {
  const ConcretePourEvent({
    required this.id,
    required this.pourId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.payloadJson,
  });

  final String id;
  final String pourId;
  final int sequence;
  final String eventType;
  final String occurredAt;
  final String payloadJson;
}

class ConcreteMetrics {
  const ConcreteMetrics({
    required this.actualDeliveredM3,
    required this.varianceM3,
    required this.variancePercent,
    required this.receivedTruckCount,
    required this.heldTruckCount,
    required this.returnedTruckCount,
    required this.partialTruckCount,
    required this.firstTruckAt,
    required this.lastTruckAt,
    required this.pourDurationMinutes,
    required this.sampleSetCount,
    required this.sampleCount,
    required this.pendingCheckCount,
    required this.missingEvidenceTruckCount,
    required this.openFollowUpCount,
  });

  final double actualDeliveredM3;
  final double varianceM3;
  final double? variancePercent;
  final int receivedTruckCount;
  final int heldTruckCount;
  final int returnedTruckCount;
  final int partialTruckCount;
  final String? firstTruckAt;
  final String? lastTruckAt;
  final int? pourDurationMinutes;
  final int sampleSetCount;
  final int sampleCount;
  final int pendingCheckCount;
  final int missingEvidenceTruckCount;
  final int openFollowUpCount;
}

class ConcretePourDetail {
  const ConcretePourDetail({
    required this.pour,
    required this.checks,
    required this.trucks,
    required this.sampleSets,
    required this.followUps,
    required this.attachments,
    required this.events,
    required this.linkedReminders,
    required this.metrics,
  });

  final ConcretePour pour;
  final List<ConcreteCheckItem> checks;
  final List<ConcreteTruck> trucks;
  final List<ConcreteSampleSet> sampleSets;
  final List<ConcreteFollowUp> followUps;
  final List<ConcreteAttachment> attachments;
  final List<ConcretePourEvent> events;
  final List<MobileReminder> linkedReminders;
  final ConcreteMetrics metrics;
}

class CreateConcretePourCommand {
  const CreateConcretePourCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.pourCode,
    required this.elementLocation,
    required this.plannedAt,
    required this.concreteClass,
    required this.plannedVolumeM3,
    this.blockName,
    this.floorName,
    this.axisName,
    this.targetSlump,
    this.orderedVolumeM3,
    this.plantName,
    this.plantBranch,
    this.plantContact,
    this.plantAppointmentReference,
    this.pumpEquipment,
    this.laboratoryName,
    this.laboratoryContact,
    this.laboratoryAppointment,
    this.inspectionNotifiedAt,
    this.inspectionNotifiedPerson,
    this.generalNote,
  });

  final String id;
  final String eventId;
  final String projectId;
  final String pourCode;
  final String elementLocation;
  final String plannedAt;
  final String concreteClass;
  final double plannedVolumeM3;
  final String? blockName;
  final String? floorName;
  final String? axisName;
  final String? targetSlump;
  final double? orderedVolumeM3;
  final String? plantName;
  final String? plantBranch;
  final String? plantContact;
  final String? plantAppointmentReference;
  final String? pumpEquipment;
  final String? laboratoryName;
  final String? laboratoryContact;
  final String? laboratoryAppointment;
  final String? inspectionNotifiedAt;
  final String? inspectionNotifiedPerson;
  final String? generalNote;
}

class UpdateConcretePourCommand {
  const UpdateConcretePourCommand({
    required this.id,
    required this.eventId,
    required this.expectedRevision,
    required this.elementLocation,
    required this.plannedAt,
    required this.concreteClass,
    required this.plannedVolumeM3,
    this.blockName,
    this.floorName,
    this.axisName,
    this.targetSlump,
    this.orderedVolumeM3,
    this.plantName,
    this.plantBranch,
    this.plantContact,
    this.plantAppointmentReference,
    this.pumpEquipment,
    this.laboratoryName,
    this.laboratoryContact,
    this.laboratoryAppointment,
    this.inspectionNotifiedAt,
    this.inspectionNotifiedPerson,
    this.generalNote,
    this.sampleExceptionReason,
    this.varianceNote,
  });

  final String id;
  final String eventId;
  final int expectedRevision;
  final String elementLocation;
  final String plannedAt;
  final String concreteClass;
  final double plannedVolumeM3;
  final String? blockName;
  final String? floorName;
  final String? axisName;
  final String? targetSlump;
  final double? orderedVolumeM3;
  final String? plantName;
  final String? plantBranch;
  final String? plantContact;
  final String? plantAppointmentReference;
  final String? pumpEquipment;
  final String? laboratoryName;
  final String? laboratoryContact;
  final String? laboratoryAppointment;
  final String? inspectionNotifiedAt;
  final String? inspectionNotifiedPerson;
  final String? generalNote;
  final String? sampleExceptionReason;
  final String? varianceNote;
}

class UpdateConcreteCheckCommand {
  const UpdateConcreteCheckCommand({
    required this.pourId,
    required this.checkId,
    required this.eventId,
    required this.expectedPourRevision,
    required this.expectedCheckRevision,
    required this.status,
    this.note,
    this.reason,
  });

  final String pourId;
  final String checkId;
  final String eventId;
  final int expectedPourRevision;
  final int expectedCheckRevision;
  final ConcreteCheckStatus status;
  final String? note;
  final String? reason;
}

class TransitionConcretePourCommand {
  const TransitionConcretePourCommand({
    required this.pourId,
    required this.eventId,
    required this.expectedRevision,
    required this.targetStatus,
    this.reason,
  });

  final String pourId;
  final String eventId;
  final int expectedRevision;
  final ConcretePourStatus targetStatus;
  final String? reason;
}

class SaveConcreteTruckCommand {
  const SaveConcreteTruckCommand({
    required this.id,
    required this.pourId,
    required this.eventId,
    required this.expectedPourRevision,
    required this.expectedTruckRevision,
    required this.sequenceNo,
    required this.vehiclePlate,
    required this.deliveryNoteNumber,
    required this.volumeM3,
    required this.result,
    this.plantSnapshot,
    this.batchTime,
    this.arrivedAt,
    this.unloadingStartedAt,
    this.unloadingEndedAt,
    this.measuredSlump,
    this.concreteTemperature,
    this.reason,
    this.evidenceExceptionReason,
  });

  final String id;
  final String pourId;
  final String eventId;
  final int expectedPourRevision;
  final int expectedTruckRevision;
  final int sequenceNo;
  final String vehiclePlate;
  final String deliveryNoteNumber;
  final double volumeM3;
  final ConcreteTruckResult result;
  final String? plantSnapshot;
  final String? batchTime;
  final String? arrivedAt;
  final String? unloadingStartedAt;
  final String? unloadingEndedAt;
  final double? measuredSlump;
  final double? concreteTemperature;
  final String? reason;
  final String? evidenceExceptionReason;
}

class SaveConcreteSampleSetCommand {
  const SaveConcreteSampleSetCommand({
    required this.id,
    required this.pourId,
    required this.eventId,
    required this.expectedPourRevision,
    required this.expectedSampleRevision,
    this.sampleCode,
    required this.sampleCount,
    required this.sampleLabels,
    required this.expectedResultDates,
    required this.status,
    this.sourceTruckId,
    this.sampledAt,
    this.sampledBy,
    this.laboratoryAppointmentAt,
    this.deliveredAt,
    this.deliveredTo,
    this.note,
    this.reason,
  });

  final String id;
  final String pourId;
  final String eventId;
  final int expectedPourRevision;
  final int expectedSampleRevision;
  final String? sourceTruckId;
  final String? sampleCode;
  final int sampleCount;
  final List<String> sampleLabels;
  final String? sampledAt;
  final String? sampledBy;
  final String? laboratoryAppointmentAt;
  final String? deliveredAt;
  final String? deliveredTo;
  final List<String> expectedResultDates;
  final ConcreteSampleStatus status;
  final String? note;
  final String? reason;
}

class UpdateConcreteFollowUpCommand {
  const UpdateConcreteFollowUpCommand({
    required this.pourId,
    required this.followUpId,
    required this.eventId,
    required this.reminderEventId,
    required this.expectedPourRevision,
    required this.expectedFollowUpRevision,
    required this.status,
    this.dueAt,
    this.note,
    this.reason,
  });

  final String pourId;
  final String followUpId;
  final String eventId;
  final String reminderEventId;
  final int expectedPourRevision;
  final int expectedFollowUpRevision;
  final ConcreteFollowUpStatus status;
  final String? dueAt;
  final String? note;
  final String? reason;
}

class AttachConcreteEvidenceCommand {
  const AttachConcreteEvidenceCommand({
    required this.id,
    required this.pourId,
    required this.eventId,
    required this.expectedPourRevision,
    required this.evidenceType,
    required this.originalFileName,
    required this.bytes,
    required this.capturedAt,
    this.truckId,
    this.sampleSetId,
    this.checkItemId,
    this.description,
  });

  final String id;
  final String pourId;
  final String eventId;
  final int expectedPourRevision;
  final ConcreteEvidenceType evidenceType;
  final String originalFileName;
  final List<int> bytes;
  final String capturedAt;
  final String? truckId;
  final String? sampleSetId;
  final String? checkItemId;
  final String? description;
}

class ExportConcretePackageCommand {
  const ExportConcretePackageCommand({
    required this.pourId,
    required this.eventId,
    required this.expectedRevision,
  });

  final String pourId;
  final String eventId;
  final int expectedRevision;
}

class ConcreteExportResult {
  const ConcreteExportResult({
    required this.absolutePath,
    required this.fileName,
    required this.humanSummary,
  });

  final String absolutePath;
  final String fileName;
  final String humanSummary;
}
