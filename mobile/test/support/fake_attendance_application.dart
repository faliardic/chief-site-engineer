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
  List<Subcontractor> subcontractors = [];
  List<WorkforceTeam> teams = [];
  List<WorkforceComplianceRecord> compliance = [];
  List<WorkforcePpeAssignment> ppeAssignments = [];
  AttendanceDayDetail? detail;
  AttendanceReminderSetting? setting;
  Object? saveFailure;
  Object? createMemberFailure;
  Completer<WorkforceMember>? createMemberCompleter;
  int createMemberCalls = 0;
  CreateWorkforceMemberCommand? lastCreateMemberCommand;
  Completer<AttendanceDayDetail>? saveCompleter;
  SaveAttendanceRosterCommand? lastRosterCommand;
  int saveCalls = 0;

  @override
  Future<List<Subcontractor>> listSubcontractors(
    String projectId, {
    bool includeArchived = false,
  }) async => subcontractors
      .where(
        (item) =>
            item.projectId == projectId && (includeArchived || item.isActive),
      )
      .map(
        (item) => Subcontractor(
          id: item.id,
          projectId: item.projectId,
          name: item.name,
          contactName: item.contactName,
          phone: item.phone,
          note: item.note,
          status: item.status,
          activeTeamCount: teams
              .where((team) => team.subcontractorId == item.id && team.isActive)
              .length,
          activePersonCount: members
              .where(
                (member) =>
                    member.subcontractorId == item.id && member.isActive,
              )
              .length,
          revision: item.revision,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          archivedAt: item.archivedAt,
        ),
      )
      .toList(growable: false);

  @override
  Future<Subcontractor> createSubcontractor(
    CreateSubcontractorCommand command,
  ) async {
    final value = Subcontractor(
      id: command.id,
      projectId: command.projectId,
      name: command.name.trim(),
      contactName: command.contactName?.trim(),
      phone: command.phone?.trim(),
      note: command.note?.trim(),
      status: WorkforceRecordStatus.active,
      activeTeamCount: 0,
      activePersonCount: 0,
      revision: 1,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      archivedAt: null,
    );
    subcontractors = [...subcontractors, value];
    return value;
  }

  @override
  Future<Subcontractor> updateSubcontractor(
    UpdateSubcontractorCommand command,
  ) async {
    final index = subcontractors.indexWhere((item) => item.id == command.id);
    final current = subcontractors[index];
    final value = Subcontractor(
      id: current.id,
      projectId: current.projectId,
      name: command.name.trim(),
      contactName: command.contactName?.trim(),
      phone: command.phone?.trim(),
      note: command.note?.trim(),
      status: current.status,
      activeTeamCount: current.activeTeamCount,
      activePersonCount: current.activePersonCount,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: current.archivedAt,
    );
    subcontractors = [...subcontractors]..[index] = value;
    return value;
  }

  @override
  Future<Subcontractor> transitionSubcontractor(
    TransitionSubcontractorCommand command,
  ) async {
    final index = subcontractors.indexWhere((item) => item.id == command.id);
    final current = subcontractors[index];
    final value = Subcontractor(
      id: current.id,
      projectId: current.projectId,
      name: current.name,
      contactName: current.contactName,
      phone: current.phone,
      note: current.note,
      status: command.archive
          ? WorkforceRecordStatus.archived
          : WorkforceRecordStatus.active,
      activeTeamCount: current.activeTeamCount,
      activePersonCount: current.activePersonCount,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: command.archive ? '2026-07-19T08:01:00Z' : null,
    );
    subcontractors = [...subcontractors]..[index] = value;
    return value;
  }

  @override
  Future<List<WorkforceTeam>> listTeams(
    String projectId, {
    String? subcontractorId,
    bool includeArchived = false,
  }) async => teams
      .where(
        (item) =>
            item.projectId == projectId &&
            (subcontractorId == null ||
                item.subcontractorId == subcontractorId) &&
            (includeArchived || item.isActive),
      )
      .map(
        (item) => WorkforceTeam(
          id: item.id,
          projectId: item.projectId,
          subcontractorId: item.subcontractorId,
          subcontractorName: item.subcontractorName,
          name: item.name,
          leadName: item.leadName,
          note: item.note,
          status: item.status,
          activePersonCount: members
              .where((member) => member.teamId == item.id && member.isActive)
              .length,
          revision: item.revision,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          archivedAt: item.archivedAt,
        ),
      )
      .toList(growable: false);

  @override
  Future<WorkforceTeam> createTeam(CreateWorkforceTeamCommand command) async {
    final subcontractor = subcontractors.firstWhere(
      (item) => item.id == command.subcontractorId,
    );
    final value = WorkforceTeam(
      id: command.id,
      projectId: command.projectId,
      subcontractorId: command.subcontractorId,
      subcontractorName: subcontractor.name,
      name: command.name.trim(),
      leadName: command.leadName?.trim(),
      note: command.note?.trim(),
      status: WorkforceRecordStatus.active,
      activePersonCount: 0,
      revision: 1,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      archivedAt: null,
    );
    teams = [...teams, value];
    return value;
  }

  @override
  Future<WorkforceTeam> updateTeam(UpdateWorkforceTeamCommand command) async {
    final index = teams.indexWhere((item) => item.id == command.id);
    final current = teams[index];
    final value = WorkforceTeam(
      id: current.id,
      projectId: current.projectId,
      subcontractorId: current.subcontractorId,
      subcontractorName: current.subcontractorName,
      name: command.name.trim(),
      leadName: command.leadName?.trim(),
      note: command.note?.trim(),
      status: current.status,
      activePersonCount: current.activePersonCount,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: current.archivedAt,
    );
    teams = [...teams]..[index] = value;
    return value;
  }

  @override
  Future<WorkforceTeam> transitionTeam(
    TransitionWorkforceTeamCommand command,
  ) async {
    final index = teams.indexWhere((item) => item.id == command.id);
    final current = teams[index];
    final value = WorkforceTeam(
      id: current.id,
      projectId: current.projectId,
      subcontractorId: current.subcontractorId,
      subcontractorName: current.subcontractorName,
      name: current.name,
      leadName: current.leadName,
      note: current.note,
      status: command.archive
          ? WorkforceRecordStatus.archived
          : WorkforceRecordStatus.active,
      activePersonCount: current.activePersonCount,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: command.archive ? '2026-07-19T08:01:00Z' : null,
    );
    teams = [...teams]..[index] = value;
    return value;
  }

  @override
  Future<List<ActiveTeamCount>> listActiveTeamCounts(String projectId) async =>
      teams
          .where((item) => item.projectId == projectId && item.isActive)
          .map(
            (item) => ActiveTeamCount(
              teamId: item.id,
              teamName: item.name,
              subcontractorName: item.subcontractorName,
              activePersonCount: members
                  .where(
                    (member) => member.teamId == item.id && member.isActive,
                  )
                  .length,
            ),
          )
          .toList(growable: false);

  @override
  Future<WorkforcePersonDetail> getPersonDetail(String memberId) async {
    final member = members.firstWhere((item) => item.id == memberId);
    final memberCompliance = compliance
        .where((item) => item.memberId == memberId)
        .toList();
    final memberPpe = ppeAssignments
        .where((item) => item.memberId == memberId)
        .toList();
    return WorkforcePersonDetail(
      member: member,
      compliance: memberCompliance,
      ppeAssignments: memberPpe,
      missingComplianceCount: memberCompliance
          .where((item) => item.readStatus == ComplianceReadStatus.missing)
          .length,
      validComplianceCount: memberCompliance
          .where((item) => item.readStatus == ComplianceReadStatus.valid)
          .length,
      expiringComplianceCount: memberCompliance
          .where((item) => item.readStatus == ComplianceReadStatus.expiring)
          .length,
      expiredComplianceCount: memberCompliance
          .where((item) => item.readStatus == ComplianceReadStatus.expired)
          .length,
      activePpeCount: memberPpe
          .where((item) => item.status == PpeAssignmentStatus.assigned)
          .length,
    );
  }

  @override
  Future<WorkforceComplianceRecord> saveComplianceRecord(
    SaveComplianceRecordCommand command,
  ) async {
    final value = WorkforceComplianceRecord(
      id: command.id,
      memberId: command.memberId,
      documentType: command.documentType,
      documentNumber: command.documentNumber,
      issuedDate: command.issuedDate,
      expiryDate: command.expiryDate,
      sourceStatus: command.sourceStatus,
      readStatus: command.sourceStatus == ComplianceSourceStatus.missing
          ? ComplianceReadStatus.missing
          : command.sourceStatus == ComplianceSourceStatus.valid
          ? ComplianceReadStatus.valid
          : ComplianceReadStatus.exception,
      note: command.note,
      reason: command.reason,
      revision: command.expectedRevision + 1,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: null,
    );
    compliance = [...compliance.where((item) => item.id != value.id), value];
    return value;
  }

  @override
  Future<WorkforceComplianceRecord> archiveComplianceRecord(
    ArchiveComplianceRecordCommand command,
  ) async {
    final current = compliance.firstWhere((item) => item.id == command.id);
    final value = WorkforceComplianceRecord(
      id: current.id,
      memberId: current.memberId,
      documentType: current.documentType,
      documentNumber: current.documentNumber,
      issuedDate: current.issuedDate,
      expiryDate: current.expiryDate,
      sourceStatus: current.sourceStatus,
      readStatus: current.readStatus,
      note: current.note,
      reason: current.reason,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: '2026-07-19T08:01:00Z',
    );
    compliance = [...compliance.where((item) => item.id != value.id), value];
    return value;
  }

  @override
  Future<WorkforcePpeAssignment> savePpeAssignment(
    SavePpeAssignmentCommand command,
  ) async {
    final value = WorkforcePpeAssignment(
      id: command.id,
      memberId: command.memberId,
      ppeType: command.ppeType,
      brandModel: command.brandModel,
      size: command.size,
      serialTag: command.serialTag,
      quantity: command.quantity,
      assignedDate: command.assignedDate,
      status: command.status,
      returnedDate: command.returnedDate,
      note: command.note,
      revision: command.expectedRevision + 1,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: command.status == PpeAssignmentStatus.archived
          ? '2026-07-19T08:01:00Z'
          : null,
    );
    ppeAssignments = [
      ...ppeAssignments.where((item) => item.id != value.id),
      value,
    ];
    return value;
  }

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
      subcontractorId: current.subcontractorId,
      subcontractorName: current.subcontractorName,
      teamId: current.teamId,
      phone: current.phone,
      note: current.note,
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
    createMemberCalls += 1;
    lastCreateMemberCommand = command;
    if (createMemberFailure case final failure?) throw failure;
    final member = WorkforceMember(
      id: command.id,
      projectId: command.projectId,
      fullName: command.fullName.trim(),
      teamName: command.teamName.trim(),
      roleName: command.roleName.trim(),
      personnelCode: command.personnelCode?.trim(),
      subcontractorId: command.subcontractorId,
      subcontractorName: subcontractors
          .where((item) => item.id == command.subcontractorId)
          .firstOrNull
          ?.name,
      teamId: command.teamId,
      phone: command.phone?.trim(),
      note: command.note?.trim(),
      isActive: true,
      revision: 1,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      archivedAt: null,
    );
    if (createMemberCompleter case final completer?) return completer.future;
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
          (command.teamId != null
              ? item.teamId == command.teamId
              : command.teamName == null || item.teamName == command.teamName),
    );
    final entries = selected
        .map(
          (member) => AttendanceEntry(
            id: command.entryIdsByMember[member.id]!,
            attendanceDayId: current.day.id,
            memberId: member.id,
            memberName: member.fullName,
            teamName: member.teamName,
            teamId: member.teamId,
            subcontractorName: member.subcontractorName,
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
            teamId: member.teamId,
            subcontractorName: member.subcontractorName,
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
      subcontractorId: command.subcontractorId ?? current.subcontractorId,
      subcontractorName:
          subcontractors
              .where(
                (item) =>
                    item.id ==
                    (command.subcontractorId ?? current.subcontractorId),
              )
              .firstOrNull
              ?.name ??
          current.subcontractorName,
      teamId: command.teamId ?? current.teamId,
      phone: command.phone?.trim(),
      note: command.note?.trim(),
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
