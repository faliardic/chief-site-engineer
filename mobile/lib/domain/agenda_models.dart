import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';

class AgendaValidationFailure implements Exception {
  const AgendaValidationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReminderPastAttentionConfirmationRequired
    extends AgendaValidationFailure {
  const ReminderPastAttentionConfirmationRequired({
    required this.earlierFromAttentionAt,
    required this.selectedAttentionAt,
  }) : super(
         'Seçilen zaman işlem anında geçmişte kalıyor; kaydetmek için açık onay gereklidir.',
       );

  final String earlierFromAttentionAt;
  final String selectedAttentionAt;
}

enum AgendaCategory {
  generalNote('general_note', 'Genel not'),
  manufacturing('manufacturing', 'İmalat'),
  inspection('inspection', 'Kontrol'),
  meetingDecision('meeting_decision', 'Görüşme/karar'),
  delivery('delivery', 'Teslimat'),
  safety('safety', 'İş güvenliği'),
  concrete('concrete', 'Beton'),
  issueDelay('issue_delay', 'Sorun/gecikme');

  const AgendaCategory(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static AgendaCategory fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () =>
        throw const AgendaValidationFailure('Kayıt türü desteklenmiyor.'),
  );
}

enum ReminderKind {
  action('action', 'Aksiyon'),
  recheck('recheck', 'Tekrar kontrol');

  const ReminderKind(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ReminderKind fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () =>
        throw const AgendaValidationFailure('Hatırlatıcı türü desteklenmiyor.'),
  );
}

enum ReminderStatus {
  inbox('inbox', 'Unutma Kutusu'),
  active('active', 'Aktif'),
  completed('completed', 'Tamamlandı'),
  cancelled('cancelled', 'İptal edildi');

  const ReminderStatus(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ReminderStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'Hatırlatıcı durumu desteklenmiyor.',
    ),
  );
}

enum ReminderScheduleKind {
  inbox('Sadece Unutma Kutusu'),
  in15Minutes('15 dakika'),
  in1Hour('1 saat'),
  in2Hours('2 saat'),
  in3Hours('3 saat'),
  todayEnd('Bugün çıkmadan'),
  tomorrowMorning('Yarın sabah'),
  nextWeekStart('Hafta başına ertele'),
  custom('Özel tarih/saat');

  const ReminderScheduleKind(this.label);

  final String label;
}

String resolveReminderTomorrowMorningAt(DateTime nowUtc) {
  final today = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(nowUtc));
  final tomorrow = CseTimeCodec.shiftIstanbulDay(today, 1).split('-');
  return CseTimeCodec.canonicalFromIstanbulComponents(
    year: int.parse(tomorrow[0]),
    month: int.parse(tomorrow[1]),
    day: int.parse(tomorrow[2]),
    hour: 8,
    minute: 0,
  );
}

String resolveReminderNextWeekStartAt(DateTime nowUtc) {
  final nowValue = CseTimeCodec.encodeUtc(nowUtc);
  final local = CseTimeCodec.toIstanbul(nowValue);
  final today = CseTimeCodec.istanbulDayKey(nowValue);
  final nextMonday = CseTimeCodec.shiftIstanbulDay(
    today,
    8 - local.weekday,
  ).split('-');
  return CseTimeCodec.canonicalFromIstanbulComponents(
    year: int.parse(nextMonday[0]),
    month: int.parse(nextMonday[1]),
    day: int.parse(nextMonday[2]),
    hour: 8,
    minute: 0,
  );
}

String? resolveReminderExactQuickScheduleAt(
  ReminderScheduleKind schedule,
  DateTime nowUtc,
) => switch (schedule) {
  ReminderScheduleKind.tomorrowMorning => resolveReminderTomorrowMorningAt(
    nowUtc,
  ),
  ReminderScheduleKind.nextWeekStart => resolveReminderNextWeekStartAt(nowUtc),
  _ => null,
};

String formatReminderExactSchedule(String canonicalUtc) {
  final local = CseTimeCodec.toIstanbul(canonicalUtc);
  final day = CseTimeCodec.istanbulDayKey(canonicalUtc);
  return '${CseTimeCodec.formatIstanbulDay(day)} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

enum ReminderViewGroup {
  now,
  overdue,
  today,
  tomorrow,
  recheck,
  upcoming,
  inbox,
  history,
  trash,
}

enum ReminderOutcomeType {
  completed('completed', 'Tamamlandı'),
  noLongerNeeded('no_longer_needed', 'Artık gerekli değil');

  const ReminderOutcomeType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ReminderOutcomeType fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'Hatırlatıcı sonuç türü desteklenmiyor.',
    ),
  );
}

enum ReminderMutationAction {
  updateDetails,
  schedule,
  snooze15Minutes,
  snooze1Hour,
  snooze2Hours,
  snooze3Hours,
  snoozeTomorrowMorning,
  moveToInbox,
  complete,
  cancel,
  reopen,
  moveToTrash,
  restoreFromTrash,
}

enum NotificationSyncState {
  scheduled('scheduled', 'Bildirim planlandı'),
  permissionDenied('permission_denied', 'Bildirim izni kapalı'),
  unavailable('unavailable', 'Bildirim kullanılamıyor'),
  failed('failed', 'Bildirim planlanamadı'),
  cancelled('cancelled', 'Bekleyen bildirim yok');

  const NotificationSyncState(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static NotificationSyncState fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'Bildirim eşitleme durumu desteklenmiyor.',
    ),
  );
}

class MobileProject {
  const MobileProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int revision;
  final String? archivedAt;

  bool get isArchived => archivedAt != null;
}

enum ProjectArchiveFilter { active, archived }

enum ProjectEventType {
  renamed('project.renamed'),
  archived('project.archived'),
  restored('project.restored');

  const ProjectEventType(this.storageValue);

  final String storageValue;
}

class ProjectEvent {
  const ProjectEvent({
    required this.id,
    required this.projectId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.payloadJson,
  });

  final String id;
  final String projectId;
  final int sequence;
  final ProjectEventType eventType;
  final String occurredAt;
  final String payloadJson;
}

enum ProjectProfileBuiltinField {
  totalFloors('total_floors', 'Toplam kat'),
  totalArea('total_area', 'Toplam alan'),
  yibfNumber('yibf_number', 'YİBF No');

  const ProjectProfileBuiltinField(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ProjectProfileBuiltinField fromStorage(String value) =>
      values.firstWhere(
        (item) => item.storageValue == value,
        orElse: () => throw const AgendaValidationFailure(
          'Proje profil alanı desteklenmiyor.',
        ),
      );
}

enum ProjectProfileEventType {
  fieldCreated('profile.field_created'),
  fieldUpdated('profile.field_updated'),
  fieldArchived('profile.field_archived'),
  fieldRestored('profile.field_restored'),
  fieldsReordered('profile.fields_reordered');

  const ProjectProfileEventType(this.storageValue);

  final String storageValue;
}

class ProjectProfileField {
  const ProjectProfileField({
    required this.id,
    required this.projectId,
    required this.label,
    required this.value,
    required this.sortOrder,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.builtinField,
    this.archivedAt,
  });

  final String id;
  final String projectId;
  final ProjectProfileBuiltinField? builtinField;
  final String label;
  final String value;
  final int sortOrder;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;

  bool get isBuiltIn => builtinField != null;
  bool get isArchived => archivedAt != null;
}

class ProjectProfile {
  const ProjectProfile({required this.project, required this.fields});

  final MobileProject project;
  final List<ProjectProfileField> fields;
}

class ProjectProfileEvent {
  const ProjectProfileEvent({
    required this.id,
    required this.projectId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.payloadJson,
    this.fieldId,
  });

  final String id;
  final String projectId;
  final String? fieldId;
  final int sequence;
  final ProjectProfileEventType eventType;
  final String occurredAt;
  final String payloadJson;
}

class AgendaLog {
  const AgendaLog({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.observedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.description,
    required this.location,
    required this.notes,
    required this.revision,
    this.locationId,
    this.stableLocationName,
    this.stableLocationArchivedAt,
    this.archivedAt,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String observedAt;
  final String createdAt;
  final String updatedAt;
  final AgendaCategory category;
  final String description;
  final String? location;
  final String? notes;
  final int revision;
  final String? locationId;
  final String? stableLocationName;
  final String? stableLocationArchivedAt;
  final String? archivedAt;

  String? get displayLocation => stableLocationName ?? location;
}

enum AgendaPhoneCallPartyKind {
  person('person', 'Kişi'),
  company('company', 'Firma'),
  freeText('free_text', 'Serbest metin');

  const AgendaPhoneCallPartyKind(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static AgendaPhoneCallPartyKind fromStorage(String value) =>
      values.firstWhere(
        (item) => item.storageValue == value,
        orElse: () => throw const AgendaValidationFailure(
          'Görüşme tarafı türü desteklenmiyor.',
        ),
      );
}

class AgendaPhoneCallContext {
  const AgendaPhoneCallContext({
    required this.agendaLogId,
    required this.projectId,
    required this.partyKind,
    required this.partyDisplayText,
    required this.createdAt,
    this.workforceMemberId,
    this.subcontractorId,
  });

  final String agendaLogId;
  final String projectId;
  final AgendaPhoneCallPartyKind partyKind;
  final String? workforceMemberId;
  final String? subcontractorId;
  final String partyDisplayText;
  final String createdAt;
}

enum AgendaArchiveFilter { active, archived }

enum AgendaSortOrder {
  newestFirst('En yeni üstte'),
  oldestFirst('En eski üstte');

  const AgendaSortOrder(this.label);

  final String label;
}

enum AgendaAttachmentIntegrity {
  ok('Dosya doğrulandı'),
  missing('Dosya eksik'),
  tampered('Dosya bütünlüğü bozuk'),
  invalidMime('Dosya türü geçersiz');

  const AgendaAttachmentIntegrity(this.label);
  final String label;
}

class AgendaLogPhoto {
  const AgendaLogPhoto({
    required this.id,
    required this.logId,
    required this.projectId,
    required this.originalFileName,
    required this.mimeType,
    required this.byteSize,
    required this.sha256,
    required this.relativePath,
    required this.description,
    required this.capturedAt,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
    required this.integrity,
  });

  final String id;
  final String logId;
  final String projectId;
  final String originalFileName;
  final String mimeType;
  final int byteSize;
  final String sha256;
  final String relativePath;
  final String? description;
  final String? capturedAt;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;
  final AgendaAttachmentIntegrity integrity;
}

class ReminderSourceAgendaMedia {
  ReminderSourceAgendaMedia._({
    required this.sourceLogId,
    required this.sourceLogArchivedAt,
    required this.photos,
    required this.safeErrorCode,
  });

  factory ReminderSourceAgendaMedia.loaded({
    required String sourceLogId,
    required String? sourceLogArchivedAt,
    required Iterable<AgendaLogPhoto> photos,
  }) {
    final uniquePhotos = <String, AgendaLogPhoto>{};
    for (final photo in photos) {
      uniquePhotos.putIfAbsent(photo.id, () => photo);
    }
    return ReminderSourceAgendaMedia._(
      sourceLogId: sourceLogId,
      sourceLogArchivedAt: sourceLogArchivedAt,
      photos: List.unmodifiable(uniquePhotos.values),
      safeErrorCode: null,
    );
  }

  factory ReminderSourceAgendaMedia.unavailable({
    required String sourceLogId,
    String safeErrorCode = 'source_agenda_media_unavailable',
  }) => ReminderSourceAgendaMedia._(
    sourceLogId: sourceLogId,
    sourceLogArchivedAt: null,
    photos: const [],
    safeErrorCode: safeErrorCode,
  );

  final String sourceLogId;
  final String? sourceLogArchivedAt;
  final List<AgendaLogPhoto> photos;
  final String? safeErrorCode;

  bool get isAvailable => safeErrorCode == null;
}

class StoredAttachmentContent {
  const StoredAttachmentContent({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final List<int> bytes;
}

class MobileReminder {
  const MobileReminder({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.sourceLogId,
    this.attendanceDayId,
    this.concretePourId,
    this.captureText = '',
    required this.title,
    this.description,
    required this.kind,
    required this.status,
    this.locationId,
    this.stableLocationName,
    this.stableLocationArchivedAt,
    this.location,
    this.relatedPerson,
    this.isImportant = false,
    required this.nextAttentionAt,
    this.allDayLocalDate,
    this.deadlineAt,
    this.conditionText,
    this.outcomeType,
    this.outcomeNote,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.trashedAt,
    required this.revision,
  });

  final String id;
  final String? projectId;
  final String? projectName;
  final String? sourceLogId;
  final String? attendanceDayId;
  final String? concretePourId;
  final String captureText;
  final String title;
  final String? description;
  final ReminderKind kind;
  final ReminderStatus status;
  final String? locationId;
  final String? stableLocationName;
  final String? stableLocationArchivedAt;
  final String? location;
  final String? relatedPerson;
  final bool isImportant;
  final String? nextAttentionAt;
  final String? allDayLocalDate;
  final String? deadlineAt;
  final ReminderOutcomeType? outcomeType;
  final String? outcomeNote;
  final String? conditionText;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? trashedAt;
  final int revision;

  String? get displayLocation => stableLocationName ?? location;
}

bool isReminderEligibleForTomorrowSnooze(
  MobileReminder reminder, {
  required String istanbulToday,
}) {
  if (reminder.status != ReminderStatus.active ||
      reminder.trashedAt != null ||
      reminder.attendanceDayId != null) {
    return false;
  }
  final timedAt = reminder.nextAttentionAt;
  final allDayDate = reminder.allDayLocalDate;
  if ((timedAt == null) == (allDayDate == null)) {
    return false;
  }
  try {
    CseTimeCodec.validateIstanbulDay(istanbulToday);
    final dueDay = timedAt == null
        ? allDayDate!
        : CseTimeCodec.istanbulDayKey(timedAt);
    if (allDayDate != null) {
      CseTimeCodec.validateIstanbulDay(allDayDate);
    }
    return dueDay.compareTo(istanbulToday) <= 0;
  } on TimeContractViolation {
    return false;
  }
}

bool isReminderEligibleForQuickEarlier(MobileReminder reminder) {
  if (reminder.status != ReminderStatus.active ||
      reminder.trashedAt != null ||
      reminder.attendanceDayId != null ||
      reminder.allDayLocalDate != null ||
      reminder.nextAttentionAt == null) {
    return false;
  }
  try {
    CseTimeCodec.decodeCanonicalUtc(reminder.nextAttentionAt!);
    return true;
  } on TimeContractViolation {
    return false;
  }
}

class NotificationBinding {
  const NotificationBinding({
    required this.reminderId,
    required this.platformNotificationId,
    required this.scheduledFor,
    required this.syncState,
    required this.lastSyncedAt,
    required this.safeErrorCode,
    this.repeatIntervalMinutes,
  });

  final String reminderId;
  final int platformNotificationId;
  final String? scheduledFor;
  final NotificationSyncState syncState;
  final String lastSyncedAt;
  final String? safeErrorCode;
  final int? repeatIntervalMinutes;
}

enum ReminderDeliveryDelayClass {
  pending('Teslimat zamanı bekleniyor'),
  onTime('Zamanında teslim edildi'),
  delayed('Gecikmeli teslim edildi'),
  severelyDelayed('Ciddi gecikmeyle teslim edildi'),
  overdue('Gecikti'),
  nativeScheduleMissing('Native plan bulunamadı'),
  deliveryUnknown('Teslimat sonucu bilinmiyor');

  const ReminderDeliveryDelayClass(this.label);

  final String label;
}

class ReminderDeliveryDiagnostic {
  const ReminderDeliveryDiagnostic({
    required this.safeReminderId,
    required this.scheduleKind,
    required this.canonicalDueAt,
    required this.nativeSchedulePresent,
    required this.lastReconciledAt,
    required this.permissionState,
    required this.channelState,
    required this.exactAlarmState,
    required this.batteryOptimizationState,
    required this.backgroundRestrictionState,
    required this.standbyBucket,
    required this.bootRescheduleState,
    required this.bootRescheduledAt,
    required this.deliveredAt,
    required this.delayClass,
    required this.safeErrorCode,
  });

  final String safeReminderId;
  final String scheduleKind;
  final String? canonicalDueAt;
  final bool nativeSchedulePresent;
  final String lastReconciledAt;
  final String permissionState;
  final String channelState;
  final String exactAlarmState;
  final String batteryOptimizationState;
  final String backgroundRestrictionState;
  final String standbyBucket;
  final String bootRescheduleState;
  final String? bootRescheduledAt;
  final String? deliveredAt;
  final ReminderDeliveryDelayClass delayClass;
  final String? safeErrorCode;

  bool get deliveryGuaranteed =>
      (nativeSchedulePresent || deliveredAt != null) &&
      permissionState == 'granted' &&
      channelState != 'disabled' &&
      exactAlarmState != 'denied';
}

class ReminderDetail {
  const ReminderDetail({
    required this.reminder,
    required this.events,
    required this.notification,
  });

  final MobileReminder reminder;
  final List<AppendOnlyEvent> events;
  final NotificationBinding notification;
}

class AgendaLogDetail {
  const AgendaLogDetail({
    required this.log,
    required this.reminders,
    this.trashedReminders = const [],
    this.photos = const [],
    this.events = const [],
    this.managedConcretePourId,
    this.phoneCallContext,
    this.isPhoneCallResult = false,
  });

  final AgendaLog log;
  final List<MobileReminder> reminders;
  final List<MobileReminder> trashedReminders;
  final List<AgendaLogPhoto> photos;
  final List<AppendOnlyEvent> events;
  final String? managedConcretePourId;
  final AgendaPhoneCallContext? phoneCallContext;
  final bool isPhoneCallResult;
}

class AgendaPhotoDraft {
  const AgendaPhotoDraft({
    required this.id,
    required this.eventId,
    required this.originalFileName,
    required this.bytes,
    required this.capturedAt,
    this.description,
  });

  final String id;
  final String eventId;
  final String originalFileName;
  final List<int> bytes;
  final String capturedAt;
  final String? description;
}

class CreateProjectCommand {
  const CreateProjectCommand({required this.id, required this.name});

  final String id;
  final String name;
}

class RenameProjectCommand {
  const RenameProjectCommand({
    required this.projectId,
    required this.eventId,
    required this.expectedRevision,
    required this.name,
  });

  final String projectId;
  final String eventId;
  final int expectedRevision;
  final String name;
}

class MutateProjectArchiveCommand {
  const MutateProjectArchiveCommand({
    required this.projectId,
    required this.eventId,
    required this.expectedRevision,
    required this.archive,
  });

  final String projectId;
  final String eventId;
  final int expectedRevision;
  final bool archive;
}

class CreateProjectProfileFieldCommand {
  const CreateProjectProfileFieldCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.label,
    required this.value,
  });

  final String id;
  final String eventId;
  final String projectId;
  final String label;
  final String value;
}

class UpdateProjectProfileFieldCommand {
  const UpdateProjectProfileFieldCommand({
    required this.fieldId,
    required this.eventId,
    required this.projectId,
    required this.expectedRevision,
    required this.label,
    required this.value,
  });

  final String fieldId;
  final String eventId;
  final String projectId;
  final int expectedRevision;
  final String label;
  final String value;
}

class MutateProjectProfileFieldArchiveCommand {
  const MutateProjectProfileFieldArchiveCommand({
    required this.fieldId,
    required this.eventId,
    required this.projectId,
    required this.expectedRevision,
    required this.archive,
  });

  final String fieldId;
  final String eventId;
  final String projectId;
  final int expectedRevision;
  final bool archive;
}

class ProjectProfileFieldOrder {
  const ProjectProfileFieldOrder({
    required this.fieldId,
    required this.expectedRevision,
  });

  final String fieldId;
  final int expectedRevision;
}

class ReorderProjectProfileFieldsCommand {
  const ReorderProjectProfileFieldsCommand({
    required this.eventId,
    required this.projectId,
    required this.fields,
  });

  final String eventId;
  final String projectId;
  final List<ProjectProfileFieldOrder> fields;
}

class CreateAgendaLogCommand {
  const CreateAgendaLogCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.observedAt,
    required this.category,
    required this.description,
    this.location,
    this.locationId,
    this.notes,
    this.photos = const [],
  });

  final String id;
  final String eventId;
  final String projectId;
  final String observedAt;
  final AgendaCategory category;
  final String description;
  final String? location;
  final String? locationId;
  final String? notes;
  final List<AgendaPhotoDraft> photos;
}

class CreatePhoneCallAgendaLogCommand {
  const CreatePhoneCallAgendaLogCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.result,
    this.location,
    this.locationId,
    this.notes,
    this.partyKind,
    this.partySourceId,
    this.partyDisplayText,
  });

  final String id;
  final String eventId;
  final String projectId;
  final String result;
  final String? location;
  final String? locationId;
  final String? notes;
  final AgendaPhoneCallPartyKind? partyKind;
  final String? partySourceId;
  final String? partyDisplayText;
}

class UpdateAgendaLogCommand {
  const UpdateAgendaLogCommand({
    required this.id,
    required this.eventId,
    required this.expectedRevision,
    required this.projectId,
    required this.observedAt,
    required this.category,
    required this.description,
    this.location,
    this.locationId,
    this.notes,
  });

  final String id;
  final String eventId;
  final int expectedRevision;
  final String projectId;
  final String observedAt;
  final AgendaCategory category;
  final String description;
  final String? location;
  final String? locationId;
  final String? notes;
}

enum AgendaReminderSyncField {
  title('title'),
  description('description'),
  location('location');

  const AgendaReminderSyncField(this.storageValue);

  final String storageValue;

  static AgendaReminderSyncField fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'Ajanda-Hatırlatıcı sync alanı desteklenmiyor.',
    ),
  );
}

class SyncAgendaToReminderCommand {
  const SyncAgendaToReminderCommand({
    required this.operationId,
    required this.sourceEventId,
    required this.targetEventId,
    required this.sourceLogId,
    required this.reminderId,
    required this.expectedSourceRevision,
    required this.expectedTargetRevision,
    required this.selectedFields,
  });

  final String operationId;
  final String sourceEventId;
  final String targetEventId;
  final String sourceLogId;
  final String reminderId;
  final int expectedSourceRevision;
  final int expectedTargetRevision;
  final Set<AgendaReminderSyncField> selectedFields;
}

class AgendaReminderSyncResult {
  const AgendaReminderSyncResult({
    required this.operationId,
    required this.sourceLogId,
    required this.reminderId,
    required this.sourceRevision,
    required this.targetRevisionBefore,
    required this.targetRevisionAfter,
    required this.selectedFields,
    required this.copiedFields,
    required this.changes,
    required this.changed,
    required this.idempotent,
  });

  final String operationId;
  final String sourceLogId;
  final String reminderId;
  final int sourceRevision;
  final int targetRevisionBefore;
  final int targetRevisionAfter;
  final List<AgendaReminderSyncField> selectedFields;
  final List<AgendaReminderSyncField> copiedFields;
  final Map<String, Object?> changes;
  final bool changed;
  final bool idempotent;
}

class MutateAgendaLogArchiveCommand {
  const MutateAgendaLogArchiveCommand({
    required this.id,
    required this.eventId,
    required this.expectedRevision,
    required this.archive,
  });

  final String id;
  final String eventId;
  final int expectedRevision;
  final bool archive;
}

class AttachAgendaPhotoCommand {
  const AttachAgendaPhotoCommand({
    required this.logId,
    required this.id,
    required this.eventId,
    required this.expectedLogRevision,
    required this.originalFileName,
    required this.bytes,
    required this.capturedAt,
    this.description,
  });

  final String logId;
  final String id;
  final String eventId;
  final int expectedLogRevision;
  final String originalFileName;
  final List<int> bytes;
  final String capturedAt;
  final String? description;
}

class AttachAgendaPhotosCommand {
  const AttachAgendaPhotosCommand({
    required this.logId,
    required this.expectedLogRevision,
    required this.photos,
  });

  final String logId;
  final int expectedLogRevision;
  final List<AgendaPhotoDraft> photos;
}

class LinkExistingAgendaPhotoCommand {
  const LinkExistingAgendaPhotoCommand({
    required this.logId,
    required this.physicalAttachmentId,
    required this.linkId,
    required this.eventId,
    required this.expectedLogRevision,
  });

  final String logId;
  final String physicalAttachmentId;
  final String linkId;
  final String eventId;
  final int expectedLogRevision;
}

class ArchiveAgendaPhotoCommand {
  const ArchiveAgendaPhotoCommand({
    required this.logId,
    required this.photoId,
    required this.eventId,
    required this.expectedLogRevision,
    required this.expectedPhotoRevision,
  });

  final String logId;
  final String photoId;
  final String eventId;
  final int expectedLogRevision;
  final int expectedPhotoRevision;
}

class CreateReminderCommand {
  const CreateReminderCommand({
    required this.id,
    required this.eventId,
    required this.title,
    required this.kind,
    required this.schedule,
    this.projectId,
    this.sourceLogId,
    this.captureText,
    this.description,
    this.locationId,
    this.location,
    this.relatedPerson,
    this.isImportant = false,
    this.deadlineAt,
    this.conditionText,
    this.customAttentionAt,
    this.allDayLocalDate,
  });

  final String id;
  final String eventId;
  final String? projectId;
  final String? sourceLogId;
  final String? captureText;
  final String title;
  final String? description;
  final ReminderKind kind;
  final ReminderScheduleKind schedule;
  final String? locationId;
  final String? location;
  final String? relatedPerson;
  final bool isImportant;
  final String? deadlineAt;
  final String? conditionText;
  final String? customAttentionAt;
  final String? allDayLocalDate;
}

class MutateReminderCommand {
  const MutateReminderCommand({
    required this.reminderId,
    required this.eventId,
    required this.expectedRevision,
    required this.action,
    this.title,
    this.description,
    this.kind,
    this.projectId,
    this.locationId,
    this.location,
    this.relatedPerson,
    this.isImportant,
    this.deadlineAt,
    this.conditionText,
    this.schedule,
    this.customAttentionAt,
    this.allDayLocalDate,
    this.expectedEarlierFromAttentionAt,
    this.confirmedPastAttentionAt,
    this.outcomeType,
    this.outcomeNote,
  });

  final String reminderId;
  final String eventId;
  final int expectedRevision;
  final ReminderMutationAction action;
  final String? title;
  final String? description;
  final ReminderKind? kind;
  final String? projectId;
  final String? locationId;
  final String? location;
  final String? relatedPerson;
  final bool? isImportant;
  final String? deadlineAt;
  final String? conditionText;
  final ReminderScheduleKind? schedule;
  final String? customAttentionAt;
  final String? allDayLocalDate;
  final String? expectedEarlierFromAttentionAt;
  final String? confirmedPastAttentionAt;
  final ReminderOutcomeType? outcomeType;
  final String? outcomeNote;
}

class AgendaQuery {
  const AgendaQuery({
    required this.istanbulDay,
    this.projectId,
    this.category,
    this.literalSearch = '',
    this.archiveFilter = AgendaArchiveFilter.active,
    this.sortOrder = AgendaSortOrder.newestFirst,
  });

  final String istanbulDay;
  final String? projectId;
  final AgendaCategory? category;
  final String literalSearch;
  final AgendaArchiveFilter archiveFilter;
  final AgendaSortOrder sortOrder;
}

class AppendOnlyEvent {
  const AppendOnlyEvent({
    required this.id,
    required this.recordId,
    required this.projectId,
    required this.eventType,
    required this.occurredAt,
    required this.payloadJson,
    this.sequence,
    this.sourceLogId,
    this.sourceAttendanceDayId,
    this.sourceConcretePourId,
  });

  final String id;
  final String recordId;
  final String? projectId;
  final String? sourceLogId;
  final String? sourceAttendanceDayId;
  final String? sourceConcretePourId;
  final String eventType;
  final String occurredAt;
  final String payloadJson;
  final int? sequence;
}

void validateUuid(String value, String field) {
  if (!RecordId.isUuid(value)) {
    throw AgendaValidationFailure('$field geçerli bir UUID olmalıdır.');
  }
}

String requiredTrimmed(String value, String field, {int maxLength = 500}) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw AgendaValidationFailure('$field zorunludur.');
  }
  if (normalized.length > maxLength) {
    throw AgendaValidationFailure(
      '$field en fazla $maxLength karakter olabilir.',
    );
  }
  return normalized;
}

String? optionalTrimmed(String? value, String field, {int maxLength = 4000}) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return requiredTrimmed(value, field, maxLength: maxLength);
}

void validateCanonicalTimestamp(String value, String field) {
  try {
    CseTimeCodec.decodeCanonicalUtc(value);
  } on TimeContractViolation {
    throw AgendaValidationFailure('$field canonical UTC saniye olmalıdır.');
  }
}
