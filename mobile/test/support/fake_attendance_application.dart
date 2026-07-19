import 'dart:async';

import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';

class FakeAttendanceApplication implements AttendanceApplication {
  FakeAttendanceApplication({
    this.members = const [],
    this.detail,
    this.setting,
  });

  List<WorkforceMember> members;
  AttendanceDayDetail? detail;
  AttendanceReminderSetting? setting;
  Object? saveFailure;
  Object? createMemberFailure;
  Completer<AttendanceDayDetail>? saveCompleter;
  SaveAttendanceRosterCommand? lastRosterCommand;
  int saveCalls = 0;

  @override
  Future<WorkforceMember> archiveMember(
    ArchiveWorkforceMemberCommand command,
  ) async {
    final index = members.indexWhere((item) => item.id == command.id);
    final current = members[index];
    final archived = WorkforceMember(
      id: current.id,
      projectId: current.projectId,
      fullName: current.fullName,
      teamName: current.teamName,
      roleName: current.roleName,
      personnelCode: current.personnelCode,
      isActive: false,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: '2026-07-19T08:01:00Z',
    );
    members = [...members]..[index] = archived;
    return archived;
  }

  @override
  Future<WorkforceMember> createMember(
    CreateWorkforceMemberCommand command,
  ) async {
    if (createMemberFailure case final failure?) throw failure;
    final member = WorkforceMember(
      id: command.id,
      projectId: command.projectId,
      fullName: command.fullName.trim(),
      teamName: command.teamName.trim(),
      roleName: command.roleName.trim(),
      personnelCode: command.personnelCode?.trim(),
      isActive: true,
      revision: 1,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      archivedAt: null,
    );
    members = [...members, member];
    return member;
  }

  @override
  Future<AttendanceDay> ensureDay(EnsureAttendanceDayCommand command) async {
    if (detail case final value?) return value.day;
    final day = AttendanceDay(
      id: command.id,
      projectId: command.projectId,
      projectName: 'Test Projesi',
      localDate: command.localDate,
      status: AttendanceDayStatus.draft,
      generalNote: null,
      revision: 1,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      completedAt: null,
    );
    detail = _emptyDetail(day);
    return day;
  }

  @override
  Future<void> ensureRollingOccurrences() async {}

  @override
  Future<AttendanceExportResult> exportDay(
    ExportAttendanceDayCommand command, {
    bool share = false,
  }) async => const AttendanceExportResult(
    fileName: 'puantaj.csv',
    absolutePath: 'V:/safe/puantaj.csv',
    humanSummary: 'Puantaj özeti',
  );

  @override
  Future<AttendanceDayDetail> getDayDetail(String dayId) async => detail!;

  @override
  Future<AttendanceReminderSetting> getReminderSetting(
    String projectId,
  ) async =>
      setting ??
      AttendanceReminderSetting(
        projectId: projectId,
        isEnabled: false,
        localTime: '17:00',
        selectedWeekdays: const {1, 2, 3, 4, 5, 6},
        timezoneName: 'Europe/Istanbul',
        revision: 0,
        createdAt: '',
        updatedAt: '',
      );

  @override
  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  }) async => members
      .where(
        (item) =>
            item.projectId == projectId && (includeInactive || item.isActive),
      )
      .toList(growable: false);

  @override
  Future<AttendanceDayDetail> markFullDay(
    MarkAttendanceFullCommand command,
  ) async {
    final current = detail!;
    final selected = members.where(
      (item) =>
          item.isActive &&
          (command.teamName == null || item.teamName == command.teamName),
    );
    final entries = selected
        .map(
          (member) => AttendanceEntry(
            id: command.entryIdsByMember[member.id]!,
            attendanceDayId: current.day.id,
            memberId: member.id,
            memberName: member.fullName,
            teamName: member.teamName,
            roleName: member.roleName,
            personnelCode: member.personnelCode,
            memberIsActive: true,
            result: AttendanceResult.fullDay,
            overtimeMinutes: 0,
            shortNote: null,
            createdAt: '2026-07-19T08:00:00Z',
            updatedAt: '2026-07-19T08:01:00Z',
          ),
        )
        .toList(growable: false);
    detail = _copyDetail(
      current,
      day: _copyDay(current.day, revision: current.day.revision + 1),
      entries: entries,
    );
    return detail!;
  }

  @override
  Future<AttendanceDayDetail> removeEntry(
    RemoveAttendanceEntryCommand command,
  ) async {
    final current = detail!;
    detail = _copyDetail(
      current,
      day: _copyDay(current.day, revision: current.day.revision + 1),
      entries: current.entries
          .where((item) => item.id != command.entryId)
          .toList(growable: false),
    );
    return detail!;
  }

  @override
  Future<AttendanceDayDetail> saveRoster(
    SaveAttendanceRosterCommand command,
  ) async {
    saveCalls += 1;
    lastRosterCommand = command;
    if (saveCompleter case final completer?) return completer.future;
    if (saveFailure case final failure?) throw failure;
    final current = detail!;
    final entries = command.values
        .map((value) {
          final member = members.firstWhere(
            (item) => item.id == value.memberId,
          );
          return AttendanceEntry(
            id: value.entryId,
            attendanceDayId: current.day.id,
            memberId: member.id,
            memberName: member.fullName,
            teamName: member.teamName,
            roleName: member.roleName,
            personnelCode: member.personnelCode,
            memberIsActive: member.isActive,
            result: value.result,
            overtimeMinutes: value.overtimeMinutes,
            shortNote: value.shortNote,
            createdAt: '2026-07-19T08:00:00Z',
            updatedAt: '2026-07-19T08:01:00Z',
          );
        })
        .toList(growable: false);
    detail = _copyDetail(
      current,
      day: _copyDay(
        current.day,
        revision: current.day.revision + 1,
        generalNote: command.replaceGeneralNote
            ? command.generalNote
            : current.day.generalNote,
      ),
      entries: entries,
    );
    return detail!;
  }

  @override
  Future<AttendanceReminderSetting> saveReminderSetting(
    SaveAttendanceReminderSettingCommand command,
  ) async {
    setting = AttendanceReminderSetting(
      projectId: command.projectId,
      isEnabled: command.isEnabled,
      localTime: command.localTime,
      selectedWeekdays: command.selectedWeekdays,
      timezoneName: 'Europe/Istanbul',
      revision: command.expectedRevision + 1,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:01:00Z',
    );
    return setting!;
  }

  @override
  Future<AttendanceDayDetail> transitionDay(
    TransitionAttendanceDayCommand command,
  ) async {
    final current = detail!;
    final status = switch (command.transition) {
      AttendanceTransition.complete => AttendanceDayStatus.completed,
      AttendanceTransition.noWork => AttendanceDayStatus.noWork,
      AttendanceTransition.reopen => AttendanceDayStatus.draft,
    };
    detail = _copyDetail(
      current,
      day: _copyDay(
        current.day,
        status: status,
        revision: current.day.revision + 1,
      ),
      entries: status == AttendanceDayStatus.noWork
          ? const []
          : current.entries,
    );
    return detail!;
  }

  @override
  Future<AttendanceDayDetail> updateNote(
    UpdateAttendanceNoteCommand command,
  ) async {
    final current = detail!;
    detail = _copyDetail(
      current,
      day: _copyDay(
        current.day,
        generalNote: command.generalNote,
        revision: current.day.revision + 1,
      ),
    );
    return detail!;
  }

  @override
  Future<WorkforceMember> updateMember(
    UpdateWorkforceMemberCommand command,
  ) async {
    final index = members.indexWhere((item) => item.id == command.id);
    final current = members[index];
    final updated = WorkforceMember(
      id: current.id,
      projectId: current.projectId,
      fullName: command.fullName.trim(),
      teamName: command.teamName.trim(),
      roleName: command.roleName.trim(),
      personnelCode: command.personnelCode?.trim(),
      isActive: current.isActive,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: current.archivedAt,
    );
    members = [...members]..[index] = updated;
    return updated;
  }
}

AttendanceDayDetail _emptyDetail(AttendanceDay day) => AttendanceDayDetail(
  day: day,
  entries: const [],
  events: const [],
  totals: const AttendanceTotals.zero(),
  teamSummaries: const [],
  linkedReminder: null,
);

AttendanceDay _copyDay(
  AttendanceDay value, {
  AttendanceDayStatus? status,
  int? revision,
  String? generalNote,
}) => AttendanceDay(
  id: value.id,
  projectId: value.projectId,
  projectName: value.projectName,
  localDate: value.localDate,
  status: status ?? value.status,
  generalNote: generalNote ?? value.generalNote,
  revision: revision ?? value.revision,
  createdAt: value.createdAt,
  updatedAt: '2026-07-19T08:01:00Z',
  completedAt: (status ?? value.status) == AttendanceDayStatus.draft
      ? null
      : '2026-07-19T08:01:00Z',
);

AttendanceDayDetail _copyDetail(
  AttendanceDayDetail value, {
  AttendanceDay? day,
  List<AttendanceEntry>? entries,
}) {
  final nextEntries = entries ?? value.entries;
  var full = 0;
  var half = 0;
  var absent = 0;
  var leave = 0;
  var overtime = 0;
  for (final entry in nextEntries) {
    if (entry.result == AttendanceResult.fullDay) full += 1;
    if (entry.result == AttendanceResult.halfDay) half += 1;
    if (entry.result == AttendanceResult.absent) absent += 1;
    if (entry.result == AttendanceResult.leave) leave += 1;
    overtime += entry.overtimeMinutes;
  }
  return AttendanceDayDetail(
    day: day ?? value.day,
    entries: nextEntries,
    events: value.events,
    totals: AttendanceTotals(
      fullDayCount: full,
      halfDayCount: half,
      absentCount: absent,
      leaveCount: leave,
      presentCount: full + half,
      personDayEquivalent: full + half * 0.5,
      overtimeMinutes: overtime,
    ),
    teamSummaries: value.teamSummaries,
    linkedReminder: value.linkedReminder,
  );
}
