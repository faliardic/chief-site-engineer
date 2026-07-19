import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';

class FakeAgendaApplication implements AgendaApplication {
  FakeAgendaApplication({
    this.projects = const [],
    this.logs = const [],
    this.reminders = const [],
    this.logDetail,
    this.reminderDetail,
  });

  List<MobileProject> projects;
  List<AgendaLog> logs;
  List<MobileReminder> reminders;
  AgendaLogDetail? logDetail;
  MobileReminder? reminderDetail;
  Object? createLogFailure;
  Completer<AgendaLog>? createLogCompleter;
  CreateAgendaLogCommand? lastLogCommand;
  CreateReminderCommand? lastReminderCommand;
  int createLogCalls = 0;
  int createReminderCalls = 0;

  @override
  Future<MobileProject> createProject(CreateProjectCommand command) async {
    final project = MobileProject(
      id: command.id,
      name: command.name.trim(),
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      revision: 1,
    );
    projects = [...projects, project];
    return project;
  }

  @override
  Future<AgendaLog> createAgendaLog(CreateAgendaLogCommand command) async {
    createLogCalls += 1;
    lastLogCommand = command;
    if (createLogFailure case final failure?) {
      throw failure;
    }
    final project = projects.firstWhere((item) => item.id == command.projectId);
    final log = AgendaLog(
      id: command.id,
      projectId: command.projectId,
      projectName: project.name,
      observedAt: command.observedAt,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      category: command.category,
      description: command.description.trim(),
      location: command.location?.trim(),
      notes: command.notes?.trim(),
      revision: 1,
    );
    if (createLogCompleter case final completer?) {
      return completer.future;
    }
    logs = [...logs, log];
    return log;
  }

  @override
  Future<MobileReminder> createReminder(CreateReminderCommand command) async {
    createReminderCalls += 1;
    lastReminderCommand = command;
    final project = projects.firstWhere((item) => item.id == command.projectId);
    final reminder = MobileReminder(
      id: command.id,
      projectId: command.projectId,
      projectName: project.name,
      sourceLogId: command.sourceLogId,
      title: command.title.trim(),
      kind: command.kind,
      status: command.schedule == ReminderScheduleKind.inbox
          ? ReminderStatus.inbox
          : command.kind == ReminderKind.waiting
          ? ReminderStatus.waiting
          : ReminderStatus.active,
      nextAttentionAt: command.schedule == ReminderScheduleKind.inbox
          ? null
          : command.customAttentionAt ?? '2026-07-19T09:00:00Z',
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      revision: 1,
    );
    reminders = [...reminders, reminder];
    return reminder;
  }

  @override
  Future<AgendaLogDetail> getAgendaLogDetail(String logId) async {
    if (logDetail case final detail?) return detail;
    final log = logs.firstWhere((item) => item.id == logId);
    return AgendaLogDetail(
      log: log,
      reminders: reminders.where((item) => item.sourceLogId == logId).toList(),
    );
  }

  @override
  Future<MobileReminder> getReminderDetail(String reminderId) async {
    return reminderDetail ??
        reminders.firstWhere((item) => item.id == reminderId);
  }

  @override
  Future<List<AgendaLog>> listAgenda(AgendaQuery query) async => logs;

  @override
  Future<List<AppendOnlyEvent>> listObservationEvents(String logId) async =>
      const [];

  @override
  Future<List<MobileProject>> listProjects() async => projects;

  @override
  Future<List<AppendOnlyEvent>> listReminderEvents(String reminderId) async =>
      const [];

  @override
  Future<List<MobileReminder>> listReminders(ReminderViewGroup group) async =>
      reminders;
}
