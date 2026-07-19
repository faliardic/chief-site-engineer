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
    this.initialNotificationReminderId,
    this.notificationTapStream = const Stream<String>.empty(),
  });

  List<MobileProject> projects;
  List<AgendaLog> logs;
  List<MobileReminder> reminders;
  AgendaLogDetail? logDetail;
  MobileReminder? reminderDetail;
  @override
  final String? initialNotificationReminderId;
  final Stream<String> notificationTapStream;
  Object? createLogFailure;
  Completer<AgendaLog>? createLogCompleter;
  CreateAgendaLogCommand? lastLogCommand;
  CreateReminderCommand? lastReminderCommand;
  Object? createReminderFailure;
  Completer<MobileReminder>? createReminderCompleter;
  int createLogCalls = 0;
  int createReminderCalls = 0;

  @override
  Stream<String> get notificationTaps => notificationTapStream;

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
    if (createReminderFailure case final failure?) throw failure;
    final project = command.projectId == null
        ? null
        : projects.firstWhere((item) => item.id == command.projectId);
    final reminder = MobileReminder(
      id: command.id,
      projectId: command.projectId,
      projectName: project?.name,
      sourceLogId: command.sourceLogId,
      captureText: (command.captureText ?? command.title).trim(),
      title: command.title.trim(),
      description: command.description?.trim(),
      kind: command.kind,
      status: command.schedule == ReminderScheduleKind.inbox
          ? ReminderStatus.inbox
          : command.kind == ReminderKind.waiting
          ? ReminderStatus.waiting
          : ReminderStatus.active,
      location: command.location?.trim(),
      relatedPerson: command.relatedPerson?.trim(),
      isImportant: command.isImportant,
      nextAttentionAt: command.schedule == ReminderScheduleKind.inbox
          ? null
          : command.customAttentionAt ?? '2026-07-19T09:00:00Z',
      deadlineAt: command.deadlineAt,
      conditionText: command.conditionText?.trim(),
      outcomeType: null,
      outcomeNote: null,
      createdAt: '2026-07-19T08:00:00Z',
      updatedAt: '2026-07-19T08:00:00Z',
      completedAt: null,
      cancelledAt: null,
      revision: 1,
    );
    if (createReminderCompleter case final completer?) {
      return completer.future;
    }
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
  Future<ReminderDetail> getReminderLifecycleDetail(String reminderId) async {
    final reminder = await getReminderDetail(reminderId);
    return ReminderDetail(
      reminder: reminder,
      events: const [],
      notification: NotificationBinding(
        reminderId: reminder.id,
        platformNotificationId: 1,
        scheduledFor: reminder.nextAttentionAt,
        syncState: reminder.nextAttentionAt == null
            ? NotificationSyncState.cancelled
            : NotificationSyncState.scheduled,
        lastSyncedAt: reminder.updatedAt,
        safeErrorCode: null,
      ),
    );
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

  @override
  Future<MobileReminder> mutateReminder(MutateReminderCommand command) async {
    final index = reminders.indexWhere((item) => item.id == command.reminderId);
    if (index < 0) throw StateError('missing reminder');
    final current = reminders[index];
    if (current.revision != command.expectedRevision) {
      throw const AgendaValidationFailure('stale revision');
    }
    final status = switch (command.action) {
      ReminderMutationAction.complete => ReminderStatus.completed,
      ReminderMutationAction.cancel => ReminderStatus.cancelled,
      ReminderMutationAction.reopen ||
      ReminderMutationAction.moveToInbox => ReminderStatus.inbox,
      ReminderMutationAction.startWaiting => ReminderStatus.waiting,
      _ => current.status,
    };
    final updated = MobileReminder(
      id: current.id,
      projectId: current.projectId,
      projectName: current.projectName,
      sourceLogId: current.sourceLogId,
      captureText: current.captureText,
      title: command.title?.trim() ?? current.title,
      description: command.action == ReminderMutationAction.updateDetails
          ? command.description?.trim()
          : current.description,
      kind: command.kind ?? current.kind,
      status: status,
      location: current.location,
      relatedPerson: current.relatedPerson,
      isImportant: command.isImportant ?? current.isImportant,
      nextAttentionAt:
          status == ReminderStatus.inbox ||
              status == ReminderStatus.completed ||
              status == ReminderStatus.cancelled
          ? null
          : current.nextAttentionAt,
      deadlineAt: current.deadlineAt,
      conditionText: current.conditionText,
      outcomeType: command.outcomeType,
      outcomeNote: command.outcomeNote,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      completedAt: status == ReminderStatus.completed
          ? '2026-07-19T08:01:00Z'
          : null,
      cancelledAt: status == ReminderStatus.cancelled
          ? '2026-07-19T08:01:00Z'
          : null,
      revision: current.revision + 1,
    );
    reminders = [...reminders]..[index] = updated;
    reminderDetail = updated;
    return updated;
  }

  @override
  Future<void> reconcileNotifications({bool requestPermission = false}) async {}
}
