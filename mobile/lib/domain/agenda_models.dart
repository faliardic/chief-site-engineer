import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';

class AgendaValidationFailure implements Exception {
  const AgendaValidationFailure(this.message);

  final String message;

  @override
  String toString() => message;
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
  waiting('waiting', 'Bekliyorum'),
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
  waiting('waiting', 'Bekliyor'),
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
  todayEnd('Bugün çıkmadan'),
  tomorrowMorning('Yarın sabah'),
  waiting('Bekliyorum'),
  custom('Özel tarih/saat');

  const ReminderScheduleKind(this.label);

  final String label;
}

enum ReminderViewGroup {
  now,
  overdue,
  today,
  waiting,
  recheck,
  upcoming,
  inbox,
  history,
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
  snoozeTomorrowMorning,
  startWaiting,
  moveToInbox,
  complete,
  cancel,
  reopen,
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
  });

  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int revision;
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
}

class MobileReminder {
  const MobileReminder({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.sourceLogId,
    this.attendanceDayId,
    this.captureText = '',
    required this.title,
    this.description,
    required this.kind,
    required this.status,
    this.location,
    this.relatedPerson,
    this.isImportant = false,
    required this.nextAttentionAt,
    this.deadlineAt,
    this.conditionText,
    this.outcomeType,
    this.outcomeNote,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    required this.revision,
  });

  final String id;
  final String? projectId;
  final String? projectName;
  final String? sourceLogId;
  final String? attendanceDayId;
  final String captureText;
  final String title;
  final String? description;
  final ReminderKind kind;
  final ReminderStatus status;
  final String? location;
  final String? relatedPerson;
  final bool isImportant;
  final String? nextAttentionAt;
  final String? deadlineAt;
  final ReminderOutcomeType? outcomeType;
  final String? outcomeNote;
  final String? conditionText;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  final String? cancelledAt;
  final int revision;
}

class NotificationBinding {
  const NotificationBinding({
    required this.reminderId,
    required this.platformNotificationId,
    required this.scheduledFor,
    required this.syncState,
    required this.lastSyncedAt,
    required this.safeErrorCode,
  });

  final String reminderId;
  final int platformNotificationId;
  final String? scheduledFor;
  final NotificationSyncState syncState;
  final String lastSyncedAt;
  final String? safeErrorCode;
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
  const AgendaLogDetail({required this.log, required this.reminders});

  final AgendaLog log;
  final List<MobileReminder> reminders;
}

class CreateProjectCommand {
  const CreateProjectCommand({required this.id, required this.name});

  final String id;
  final String name;
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
    this.notes,
  });

  final String id;
  final String eventId;
  final String projectId;
  final String observedAt;
  final AgendaCategory category;
  final String description;
  final String? location;
  final String? notes;
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
    this.location,
    this.relatedPerson,
    this.isImportant = false,
    this.deadlineAt,
    this.conditionText,
    this.customAttentionAt,
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
  final String? location;
  final String? relatedPerson;
  final bool isImportant;
  final String? deadlineAt;
  final String? conditionText;
  final String? customAttentionAt;
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
    this.location,
    this.relatedPerson,
    this.isImportant,
    this.deadlineAt,
    this.conditionText,
    this.schedule,
    this.customAttentionAt,
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
  final String? location;
  final String? relatedPerson;
  final bool? isImportant;
  final String? deadlineAt;
  final String? conditionText;
  final ReminderScheduleKind? schedule;
  final String? customAttentionAt;
  final ReminderOutcomeType? outcomeType;
  final String? outcomeNote;
}

class AgendaQuery {
  const AgendaQuery({
    required this.istanbulDay,
    this.projectId,
    this.category,
    this.literalSearch = '',
  });

  final String istanbulDay;
  final String? projectId;
  final AgendaCategory? category;
  final String literalSearch;
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
  });

  final String id;
  final String recordId;
  final String? projectId;
  final String? sourceLogId;
  final String? sourceAttendanceDayId;
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
