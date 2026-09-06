import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';

enum AttendanceDayStatus {
  draft('draft', 'Taslak'),
  completed('completed', 'Tamamlandı'),
  noWork('no_work', 'Çalışma yok');

  const AttendanceDayStatus(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static AttendanceDayStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'Puantaj günü durumu desteklenmiyor.',
    ),
  );
}

enum AttendanceResult {
  fullDay('full_day', 'Tam gün', 1),
  halfDay('half_day', 'Yarım gün', 0.5),
  absent('absent', 'Gelmedi', 0),
  leave('leave', 'İzinli', 0);

  const AttendanceResult(this.storageValue, this.label, this.dayEquivalent);

  final String storageValue;
  final String label;
  final double dayEquivalent;

  static AttendanceResult fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () =>
        throw const AgendaValidationFailure('Puantaj sonucu desteklenmiyor.'),
  );
}

enum AttendanceTransition { complete, noWork, reopen }

enum WorkforceRecordStatus {
  active('active', 'Aktif'),
  archived('archived', 'Pasif');

  const WorkforceRecordStatus(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static WorkforceRecordStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'İş gücü kayıt durumu desteklenmiyor.',
    ),
  );
}

class Subcontractor {
  const Subcontractor({
    required this.id,
    required this.projectId,
    required this.name,
    required this.contactName,
    required this.phone,
    this.address,
    this.specialty,
    this.startedOn,
    this.endedOn,
    required this.note,
    required this.status,
    required this.activeTeamCount,
    required this.activePersonCount,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String projectId;
  final String name;
  final String? contactName;
  final String? phone;
  final String? address;
  final String? specialty;
  final String? startedOn;
  final String? endedOn;
  final String? note;
  final WorkforceRecordStatus status;
  final int activeTeamCount;
  final int activePersonCount;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;

  bool get isActive => status == WorkforceRecordStatus.active;
}

class WorkforceTeam {
  const WorkforceTeam({
    required this.id,
    required this.projectId,
    required this.subcontractorId,
    required this.subcontractorName,
    required this.name,
    required this.leadName,
    required this.note,
    required this.status,
    required this.activePersonCount,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String projectId;
  final String subcontractorId;
  final String subcontractorName;
  final String name;
  final String? leadName;
  final String? note;
  final WorkforceRecordStatus status;
  final int activePersonCount;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;

  bool get isActive => status == WorkforceRecordStatus.active;
}

class WorkforceMember {
  const WorkforceMember({
    required this.id,
    required this.projectId,
    required this.fullName,
    required this.teamName,
    required this.roleName,
    required this.personnelCode,
    this.subcontractorId,
    this.subcontractorName,
    this.teamId,
    this.phone,
    this.address,
    this.startedOn,
    this.note,
    required this.isActive,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String projectId;
  final String fullName;
  final String teamName;
  final String roleName;
  final String? personnelCode;
  final String? subcontractorId;
  final String? subcontractorName;
  final String? teamId;
  final String? phone;
  final String? address;
  final String? startedOn;
  final String? note;
  final bool isActive;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;
}

enum ComplianceDocumentType {
  employmentEntry('employment_entry', 'İşe giriş kaydı'),
  healthReport('health_report', 'Sağlık raporu'),
  basicSafetyTraining('basic_safety_training', 'Temel İSG eğitimi'),
  vocationalCertificate('vocational_certificate', 'Mesleki yeterlilik'),
  other('other', 'Diğer');

  const ComplianceDocumentType(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static ComplianceDocumentType fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () =>
        throw const AgendaValidationFailure('İSG belge türü desteklenmiyor.'),
  );
}

enum ComplianceSourceStatus {
  valid('valid', 'Geçerli'),
  missing('missing', 'Eksik'),
  notApplicable('not_applicable', 'Uygulanamaz'),
  exception('exception', 'İstisna');

  const ComplianceSourceStatus(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static ComplianceSourceStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'İSG belge kaynak durumu desteklenmiyor.',
    ),
  );
}

enum ComplianceReadStatus {
  valid('Geçerli'),
  expiring('Süresi yaklaşıyor'),
  expired('Süresi geçmiş'),
  missing('Eksik'),
  exception('İstisna');

  const ComplianceReadStatus(this.label);
  final String label;
}

class WorkforceComplianceRecord {
  const WorkforceComplianceRecord({
    required this.id,
    required this.memberId,
    required this.documentType,
    required this.documentNumber,
    required this.issuedDate,
    required this.expiryDate,
    required this.sourceStatus,
    required this.readStatus,
    required this.note,
    required this.reason,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String memberId;
  final ComplianceDocumentType documentType;
  final String? documentNumber;
  final String? issuedDate;
  final String? expiryDate;
  final ComplianceSourceStatus sourceStatus;
  final ComplianceReadStatus readStatus;
  final String? note;
  final String? reason;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;
}

enum PpeAssignmentStatus {
  assigned('assigned', 'Zimmetli'),
  returned('returned', 'İade edildi'),
  lost('lost', 'Kayıp'),
  damaged('damaged', 'Hasarlı'),
  archived('archived', 'Arşivlendi');

  const PpeAssignmentStatus(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static PpeAssignmentStatus fromStorage(String value) => values.firstWhere(
    (item) => item.storageValue == value,
    orElse: () => throw const AgendaValidationFailure(
      'KKD zimmet durumu desteklenmiyor.',
    ),
  );
}

class WorkforcePpeAssignment {
  const WorkforcePpeAssignment({
    required this.id,
    required this.memberId,
    required this.ppeType,
    required this.brandModel,
    required this.size,
    required this.serialTag,
    required this.quantity,
    required this.assignedDate,
    required this.status,
    required this.returnedDate,
    required this.note,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String memberId;
  final String ppeType;
  final String? brandModel;
  final String? size;
  final String? serialTag;
  final int quantity;
  final String assignedDate;
  final PpeAssignmentStatus status;
  final String? returnedDate;
  final String? note;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;
}

/// Read-only lifecycle facts. Sequence is authoritative within one record.
class WorkforceComplianceEvent {
  const WorkforceComplianceEvent({
    required this.id,
    required this.recordId,
    required this.memberId,
    required this.projectId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
  });

  final String id;
  final String recordId;
  final String memberId;
  final String projectId;
  final int sequence;
  final String eventType;
  final String occurredAt;
}

class WorkforcePersonDetail {
  const WorkforcePersonDetail({
    required this.member,
    required this.compliance,
    required this.ppeAssignments,
    required this.missingComplianceCount,
    required this.validComplianceCount,
    required this.expiringComplianceCount,
    required this.expiredComplianceCount,
    required this.activePpeCount,
    this.attendanceSummary = const WorkforceAttendanceSummary.empty(),
    this.archivedCompliance = const [],
    this.complianceEvents = const [],
  });

  final WorkforceMember member;
  final List<WorkforceComplianceRecord> compliance;
  final List<WorkforcePpeAssignment> ppeAssignments;
  final int missingComplianceCount;
  final int validComplianceCount;
  final int expiringComplianceCount;
  final int expiredComplianceCount;
  final int activePpeCount;
  final WorkforceAttendanceSummary attendanceSummary;
  final List<WorkforceComplianceRecord> archivedCompliance;
  final List<WorkforceComplianceEvent> complianceEvents;
}

class WorkforceAttendanceSummary {
  const WorkforceAttendanceSummary({
    required this.personDayEquivalentTotal,
    required this.recentDays,
  });

  const WorkforceAttendanceSummary.empty()
    : personDayEquivalentTotal = 0,
      recentDays = const [];

  final double personDayEquivalentTotal;
  final List<WorkforceAttendanceDay> recentDays;

  WorkforceAttendanceDay? get lastAttendance => recentDays.firstOrNull;
}

class WorkforceAttendanceDay {
  const WorkforceAttendanceDay({
    required this.attendanceDayId,
    required this.localDate,
    required this.dayStatus,
    required this.result,
  });

  final String attendanceDayId;
  final String localDate;
  final AttendanceDayStatus dayStatus;
  final AttendanceResult result;

  double get personDayEquivalent => result.dayEquivalent;
}

class AttendanceDay {
  const AttendanceDay({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.localDate,
    required this.status,
    required this.generalNote,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String localDate;
  final AttendanceDayStatus status;
  final String? generalNote;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
}

class AttendanceEntry {
  const AttendanceEntry({
    required this.id,
    required this.attendanceDayId,
    required this.memberId,
    required this.memberName,
    required this.teamName,
    this.teamId,
    this.subcontractorName,
    required this.roleName,
    required this.personnelCode,
    required this.memberIsActive,
    required this.result,
    required this.overtimeMinutes,
    required this.shortNote,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String attendanceDayId;
  final String memberId;
  final String memberName;
  final String teamName;
  final String? teamId;
  final String? subcontractorName;
  final String roleName;
  final String? personnelCode;
  final bool memberIsActive;
  final AttendanceResult result;
  final int overtimeMinutes;
  final String? shortNote;
  final String createdAt;
  final String updatedAt;
}

class AttendanceTotals {
  const AttendanceTotals({
    required this.fullDayCount,
    required this.halfDayCount,
    required this.absentCount,
    required this.leaveCount,
    required this.presentCount,
    required this.personDayEquivalent,
    required this.overtimeMinutes,
  });

  const AttendanceTotals.zero()
    : fullDayCount = 0,
      halfDayCount = 0,
      absentCount = 0,
      leaveCount = 0,
      presentCount = 0,
      personDayEquivalent = 0,
      overtimeMinutes = 0;

  final int fullDayCount;
  final int halfDayCount;
  final int absentCount;
  final int leaveCount;
  final int presentCount;
  final double personDayEquivalent;
  final int overtimeMinutes;
}

class AttendanceTeamSummary {
  const AttendanceTeamSummary({
    required this.teamName,
    this.teamId,
    this.subcontractorName,
    required this.totals,
  });

  final String teamName;
  final String? teamId;
  final String? subcontractorName;
  final AttendanceTotals totals;
}

class ActiveTeamCount {
  const ActiveTeamCount({
    required this.teamId,
    required this.teamName,
    required this.subcontractorName,
    required this.activePersonCount,
  });

  final String teamId;
  final String teamName;
  final String subcontractorName;
  final int activePersonCount;
}

class AttendanceEvent {
  const AttendanceEvent({
    required this.id,
    required this.attendanceDayId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.payloadJson,
  });

  final String id;
  final String attendanceDayId;
  final int sequence;
  final String eventType;
  final String occurredAt;
  final String payloadJson;
}

class AttendanceReminderSetting {
  const AttendanceReminderSetting({
    required this.projectId,
    required this.isEnabled,
    required this.localTime,
    required this.selectedWeekdays,
    required this.timezoneName,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });

  final String projectId;
  final bool isEnabled;
  final String localTime;
  final Set<int> selectedWeekdays;
  final String timezoneName;
  final int revision;
  final String createdAt;
  final String updatedAt;
}

class AttendanceDayDetail {
  const AttendanceDayDetail({
    required this.day,
    required this.entries,
    required this.events,
    required this.totals,
    required this.teamSummaries,
    required this.linkedReminder,
  });

  final AttendanceDay day;
  final List<AttendanceEntry> entries;
  final List<AttendanceEvent> events;
  final AttendanceTotals totals;
  final List<AttendanceTeamSummary> teamSummaries;
  final MobileReminder? linkedReminder;
}

class CreateWorkforceMemberCommand {
  const CreateWorkforceMemberCommand({
    required this.id,
    required this.projectId,
    required this.fullName,
    required this.teamName,
    required this.roleName,
    this.personnelCode,
    this.subcontractorId,
    this.teamId,
    this.phone,
    this.address,
    this.startedOn,
    this.note,
    this.eventId,
  });

  final String id;
  final String projectId;
  final String fullName;
  final String teamName;
  final String roleName;
  final String? personnelCode;
  final String? subcontractorId;
  final String? teamId;
  final String? phone;
  final String? address;
  final String? startedOn;
  final String? note;
  final String? eventId;
}

class UpdateWorkforceMemberCommand {
  const UpdateWorkforceMemberCommand({
    required this.id,
    required this.expectedRevision,
    required this.fullName,
    required this.teamName,
    required this.roleName,
    this.personnelCode,
    this.subcontractorId,
    this.teamId,
    this.phone,
    this.address,
    this.startedOn,
    this.replaceAddress = false,
    this.replaceStartedOn = false,
    this.note,
    this.eventId,
  });

  final String id;
  final int expectedRevision;
  final String fullName;
  final String teamName;
  final String roleName;
  final String? personnelCode;
  final String? subcontractorId;
  final String? teamId;
  final String? phone;
  final String? address;
  final String? startedOn;
  final bool replaceAddress;
  final bool replaceStartedOn;
  final String? note;
  final String? eventId;
}

class ArchiveWorkforceMemberCommand {
  const ArchiveWorkforceMemberCommand({
    required this.id,
    required this.expectedRevision,
    this.eventId,
    this.archive = true,
  });

  final String id;
  final int expectedRevision;
  final String? eventId;
  final bool archive;
}

class EnsureAttendanceDayCommand {
  const EnsureAttendanceDayCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.localDate,
  });

  final String id;
  final String eventId;
  final String projectId;
  final String localDate;
}

class AttendanceRosterValue {
  const AttendanceRosterValue({
    required this.entryId,
    required this.memberId,
    required this.result,
    required this.overtimeMinutes,
    this.shortNote,
  });

  final String entryId;
  final String memberId;
  final AttendanceResult result;
  final int overtimeMinutes;
  final String? shortNote;
}

class SaveAttendanceRosterCommand {
  const SaveAttendanceRosterCommand({
    required this.dayId,
    required this.eventId,
    required this.expectedRevision,
    required this.values,
    this.replaceGeneralNote = false,
    this.generalNote,
  });

  final String dayId;
  final String eventId;
  final int expectedRevision;
  final List<AttendanceRosterValue> values;
  final bool replaceGeneralNote;
  final String? generalNote;
}

class MarkAttendanceFullCommand {
  const MarkAttendanceFullCommand({
    required this.dayId,
    required this.eventId,
    required this.expectedRevision,
    required this.entryIdsByMember,
    this.teamName,
    this.teamId,
  });

  final String dayId;
  final String eventId;
  final int expectedRevision;
  final Map<String, String> entryIdsByMember;
  final String? teamName;
  final String? teamId;
}

class CreateSubcontractorCommand {
  const CreateSubcontractorCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.name,
    this.contactName,
    this.phone,
    this.address,
    this.specialty,
    this.startedOn,
    this.endedOn,
    this.note,
  });
  final String id;
  final String eventId;
  final String projectId;
  final String name;
  final String? contactName;
  final String? phone;
  final String? address;
  final String? specialty;
  final String? startedOn;
  final String? endedOn;
  final String? note;
}

class UpdateSubcontractorCommand {
  const UpdateSubcontractorCommand({
    required this.id,
    required this.eventId,
    required this.expectedRevision,
    required this.name,
    this.contactName,
    this.phone,
    this.address,
    this.specialty,
    this.startedOn,
    this.endedOn,
    this.replaceAddress = false,
    this.replaceSpecialty = false,
    this.replaceStartedOn = false,
    this.replaceEndedOn = false,
    this.note,
  });
  final String id;
  final String eventId;
  final int expectedRevision;
  final String name;
  final String? contactName;
  final String? phone;
  final String? address;
  final String? specialty;
  final String? startedOn;
  final String? endedOn;
  final bool replaceAddress;
  final bool replaceSpecialty;
  final bool replaceStartedOn;
  final bool replaceEndedOn;
  final String? note;
}

class TransitionSubcontractorCommand {
  const TransitionSubcontractorCommand({
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

class CreateWorkforceTeamCommand {
  const CreateWorkforceTeamCommand({
    required this.id,
    required this.eventId,
    required this.projectId,
    required this.subcontractorId,
    required this.name,
    this.leadName,
    this.note,
  });
  final String id;
  final String eventId;
  final String projectId;
  final String subcontractorId;
  final String name;
  final String? leadName;
  final String? note;
}

class UpdateWorkforceTeamCommand {
  const UpdateWorkforceTeamCommand({
    required this.id,
    required this.eventId,
    required this.expectedRevision,
    required this.name,
    this.leadName,
    this.note,
  });
  final String id;
  final String eventId;
  final int expectedRevision;
  final String name;
  final String? leadName;
  final String? note;
}

class TransitionWorkforceTeamCommand {
  const TransitionWorkforceTeamCommand({
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

class SaveComplianceRecordCommand {
  const SaveComplianceRecordCommand({
    required this.id,
    required this.eventId,
    required this.memberId,
    required this.expectedRevision,
    required this.documentType,
    required this.sourceStatus,
    this.documentNumber,
    this.issuedDate,
    this.expiryDate,
    this.note,
    this.reason,
  });
  final String id;
  final String eventId;
  final String memberId;
  final int expectedRevision;
  final ComplianceDocumentType documentType;
  final ComplianceSourceStatus sourceStatus;
  final String? documentNumber;
  final String? issuedDate;
  final String? expiryDate;
  final String? note;
  final String? reason;
}

class ArchiveComplianceRecordCommand {
  const ArchiveComplianceRecordCommand({
    required this.id,
    required this.eventId,
    required this.expectedRevision,
  });
  final String id;
  final String eventId;
  final int expectedRevision;
}

class RestoreComplianceRecordCommand {
  const RestoreComplianceRecordCommand({
    required this.id,
    required this.eventId,
    required this.memberId,
    required this.projectId,
    required this.expectedRevision,
  });

  final String id;
  final String eventId;
  final String memberId;
  final String projectId;
  final int expectedRevision;
}

class SavePpeAssignmentCommand {
  const SavePpeAssignmentCommand({
    required this.id,
    required this.eventId,
    required this.memberId,
    required this.expectedRevision,
    required this.ppeType,
    required this.quantity,
    required this.assignedDate,
    required this.status,
    this.brandModel,
    this.size,
    this.serialTag,
    this.returnedDate,
    this.note,
  });
  final String id;
  final String eventId;
  final String memberId;
  final int expectedRevision;
  final String ppeType;
  final int quantity;
  final String assignedDate;
  final PpeAssignmentStatus status;
  final String? brandModel;
  final String? size;
  final String? serialTag;
  final String? returnedDate;
  final String? note;
}

class RemoveAttendanceEntryCommand {
  const RemoveAttendanceEntryCommand({
    required this.dayId,
    required this.entryId,
    required this.eventId,
    required this.expectedRevision,
  });

  final String dayId;
  final String entryId;
  final String eventId;
  final int expectedRevision;
}

class UpdateAttendanceNoteCommand {
  const UpdateAttendanceNoteCommand({
    required this.dayId,
    required this.eventId,
    required this.expectedRevision,
    this.generalNote,
  });

  final String dayId;
  final String eventId;
  final int expectedRevision;
  final String? generalNote;
}

class TransitionAttendanceDayCommand {
  const TransitionAttendanceDayCommand({
    required this.dayId,
    required this.dayEventId,
    required this.reminderEventId,
    required this.expectedRevision,
    required this.transition,
  });

  final String dayId;
  final String dayEventId;
  final String reminderEventId;
  final int expectedRevision;
  final AttendanceTransition transition;
}

class SaveAttendanceReminderSettingCommand {
  const SaveAttendanceReminderSettingCommand({
    required this.projectId,
    required this.expectedRevision,
    required this.isEnabled,
    required this.localTime,
    required this.selectedWeekdays,
  });

  final String projectId;
  final int expectedRevision;
  final bool isEnabled;
  final String localTime;
  final Set<int> selectedWeekdays;
}

class ExportAttendanceDayCommand {
  const ExportAttendanceDayCommand({
    required this.dayId,
    required this.eventId,
    required this.expectedRevision,
  });

  final String dayId;
  final String eventId;
  final int expectedRevision;
}

class AttendanceExportResult {
  const AttendanceExportResult({
    required this.fileName,
    required this.absolutePath,
    required this.humanSummary,
  });

  final String fileName;
  final String absolutePath;
  final String humanSummary;
}

void validateAttendanceDayKey(String value) {
  try {
    CseTimeCodec.istanbulDayBounds(value);
  } on TimeContractViolation {
    throw const AgendaValidationFailure('Puantaj tarihi geçersizdir.');
  }
}

void validateAttendanceLocalTime(String value) {
  final match = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').firstMatch(value);
  if (match == null) {
    throw const AgendaValidationFailure(
      'Hatırlatma saati HH:mm biçiminde olmalıdır.',
    );
  }
}
