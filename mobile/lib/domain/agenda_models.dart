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
  custom('Özel tarih/saat');

  const ReminderScheduleKind(this.label);

  final String label;
}

enum ReminderViewGroup { inbox, today, upcoming }

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
    required this.title,
    required this.kind,
    required this.status,
    required this.nextAttentionAt,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String sourceLogId;
  final String title;
  final ReminderKind kind;
  final ReminderStatus status;
  final String? nextAttentionAt;
  final String createdAt;
  final String updatedAt;
  final int revision;
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
    required this.projectId,
    required this.sourceLogId,
    required this.title,
    required this.kind,
    required this.schedule,
    this.customAttentionAt,
  });

  final String id;
  final String eventId;
  final String projectId;
  final String sourceLogId;
  final String title;
  final ReminderKind kind;
  final ReminderScheduleKind schedule;
  final String? customAttentionAt;
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
    this.sourceLogId,
  });

  final String id;
  final String recordId;
  final String projectId;
  final String? sourceLogId;
  final String eventType;
  final String occurredAt;
  final String payloadJson;
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
