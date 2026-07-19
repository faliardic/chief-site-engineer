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

class WorkforceMember {
  const WorkforceMember({
    required this.id,
    required this.projectId,
    required this.fullName,
    required this.teamName,
    required this.roleName,
    required this.personnelCode,
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
  final bool isActive;
  final int revision;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;
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
  const AttendanceTeamSummary({required this.teamName, required this.totals});

  final String teamName;
  final AttendanceTotals totals;
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
  });

  final String id;
  final String projectId;
  final String fullName;
  final String teamName;
  final String roleName;
  final String? personnelCode;
}

class UpdateWorkforceMemberCommand {
  const UpdateWorkforceMemberCommand({
    required this.id,
    required this.expectedRevision,
    required this.fullName,
    required this.teamName,
    required this.roleName,
    this.personnelCode,
  });

  final String id;
  final int expectedRevision;
  final String fullName;
  final String teamName;
  final String roleName;
  final String? personnelCode;
}

class ArchiveWorkforceMemberCommand {
  const ArchiveWorkforceMemberCommand({
    required this.id,
    required this.expectedRevision,
  });

  final String id;
  final int expectedRevision;
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
  });

  final String dayId;
  final String eventId;
  final int expectedRevision;
  final Map<String, String> entryIdsByMember;
  final String? teamName;
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
