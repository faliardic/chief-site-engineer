import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';

class FakeAgendaApplication
    implements
        AgendaApplication,
        ReminderTodayApplication,
        ReminderSourceAgendaMediaApplication {
  FakeAgendaApplication({
    this.projects = const [],
    this.logs = const [],
    this.reminders = const [],
    this.todayOverview,
    this.logDetail,
    this.reminderDetail,
    this.sourceAgendaMedia,
    this.sourceAgendaMediaFailure,
    this.agendaPhotoContents = const {},
    this.initialNotificationReminderId,
    this.notificationTapStream = const Stream<String>.empty(),
    DateTime? asOfUtc,
  }) : asOfUtc = asOfUtc ?? DateTime.utc(2026, 7, 20, 5);

  List<MobileProject> projects;
  List<AgendaLog> logs;
  List<MobileReminder> reminders;
  ReminderTodayOverview? todayOverview;
  final DateTime asOfUtc;
  AgendaLogDetail? logDetail;
  MobileReminder? reminderDetail;
  ReminderSourceAgendaMedia? sourceAgendaMedia;
  Object? sourceAgendaMediaFailure;
  final Map<String, StoredAttachmentContent> agendaPhotoContents;
  @override
  final String? initialNotificationReminderId;
  final Stream<String> notificationTapStream;
  Object? createLogFailure;
  Completer<AgendaLog>? createLogCompleter;
  CreateAgendaLogCommand? lastLogCommand;
  CreateReminderCommand? lastReminderCommand;
  Object? createReminderFailure;
  Object? mutateReminderFailure;
  ReminderViewGroup? lastReminderGroup;
  Completer<MobileReminder>? createReminderCompleter;
  Completer<MobileReminder>? mutateReminderCompleter;
  int createLogCalls = 0;
  int createReminderCalls = 0;
  int todayOverviewCalls = 0;
  int sourceAgendaMediaCalls = 0;
  int mutateReminderCalls = 0;
  MutateReminderCommand? lastMutationCommand;
  final StreamController<void> _projectChanges =
      StreamController<void>.broadcast();

  @override
  Stream<void> get projectChanges => _projectChanges.stream;

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
    _projectChanges.add(null);
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
  Future<AgendaLog> updateAgendaLog(UpdateAgendaLogCommand command) async {
    final index = logs.indexWhere((item) => item.id == command.id);
    final current = logs[index];
    final project = projects.firstWhere((item) => item.id == command.projectId);
    final updated = AgendaLog(
      id: current.id,
      projectId: command.projectId,
      projectName: project.name,
      observedAt: command.observedAt,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      category: command.category,
      description: command.description.trim(),
      location: command.location?.trim(),
      notes: command.notes?.trim(),
      revision: current.revision + 1,
      archivedAt: current.archivedAt,
    );
    logs = [...logs]..[index] = updated;
    return updated;
  }

  @override
  Future<AgendaLogDetail> mutateAgendaLogArchive(
    MutateAgendaLogArchiveCommand command,
  ) async {
    final index = logs.indexWhere((item) => item.id == command.id);
    final current = logs[index];
    final updated = AgendaLog(
      id: current.id,
      projectId: current.projectId,
      projectName: current.projectName,
      observedAt: current.observedAt,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      category: current.category,
      description: current.description,
      location: current.location,
      notes: current.notes,
      revision: current.revision + 1,
      archivedAt: command.archive ? '2026-07-19T08:01:00Z' : null,
    );
    logs = [...logs]..[index] = updated;
    return AgendaLogDetail(log: updated, reminders: reminders);
  }

  @override
  Future<AgendaLogDetail> attachAgendaPhoto(
    AttachAgendaPhotoCommand command,
  ) async => getAgendaLogDetail(command.logId);

  @override
  Future<AgendaLogDetail> archiveAgendaPhoto(
    ArchiveAgendaPhotoCommand command,
  ) async => getAgendaLogDetail(command.logId);

  @override
  Future<StoredAttachmentContent> readAgendaPhoto(String photoId) async {
    final content = agendaPhotoContents[photoId];
    if (content == null) throw StateError('photo unavailable in fake');
    return content;
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
          : ReminderStatus.active,
      location: command.location?.trim(),
      relatedPerson: command.relatedPerson?.trim(),
      isImportant: command.isImportant,
      nextAttentionAt:
          command.schedule == ReminderScheduleKind.inbox ||
              command.allDayLocalDate != null
          ? null
          : command.customAttentionAt ?? '2026-07-19T09:00:00Z',
      allDayLocalDate: command.allDayLocalDate,
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
      reminders: reminders
          .where((item) => item.sourceLogId == logId && item.trashedAt == null)
          .toList(),
    );
  }

  @override
  Future<ReminderSourceAgendaMedia> getReminderSourceAgendaMedia(
    String sourceLogId,
  ) async {
    sourceAgendaMediaCalls += 1;
    if (sourceAgendaMediaFailure case final failure?) throw failure;
    if (sourceAgendaMedia case final value?) return value;
    final detail = logDetail;
    if (detail != null && detail.log.id == sourceLogId) {
      return ReminderSourceAgendaMedia.loaded(
        sourceLogId: sourceLogId,
        sourceLogArchivedAt: detail.log.archivedAt,
        photos: detail.photos,
      );
    }
    return ReminderSourceAgendaMedia.unavailable(sourceLogId: sourceLogId);
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
        scheduledFor: reminder.trashedAt == null
            ? reminder.nextAttentionAt
            : null,
        syncState:
            reminder.nextAttentionAt == null || reminder.trashedAt != null
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
  Future<ReminderTodayOverview> getReminderTodayOverview() async {
    todayOverviewCalls += 1;
    return todayOverview ??
        buildReminderTodayOverview(reminders, asOfUtc: asOfUtc);
  }

  @override
  Future<List<AppendOnlyEvent>> listReminderEvents(String reminderId) async =>
      const [];

  @override
  Future<List<MobileReminder>> listReminders(ReminderViewGroup group) async {
    lastReminderGroup = group;
    return reminders
        .where(
          (item) => group == ReminderViewGroup.trash
              ? item.trashedAt != null
              : item.trashedAt == null,
        )
        .toList();
  }

  @override
  Future<MobileReminder> mutateReminder(MutateReminderCommand command) async {
    mutateReminderCalls += 1;
    lastMutationCommand = command;
    if (mutateReminderFailure case final failure?) throw failure;
    if (mutateReminderCompleter case final completer?) {
      return completer.future;
    }
    final index = reminders.indexWhere((item) => item.id == command.reminderId);
    if (index < 0) throw StateError('missing reminder');
    final current = reminders[index];
    if (current.revision != command.expectedRevision) {
      throw const AgendaValidationFailure('stale revision');
    }
    final status = switch (command.action) {
      ReminderMutationAction.complete => ReminderStatus.completed,
      ReminderMutationAction.cancel => ReminderStatus.cancelled,
      ReminderMutationAction.moveToInbox => ReminderStatus.inbox,
      ReminderMutationAction.reopen =>
        current.nextAttentionAt == null && current.allDayLocalDate == null
            ? ReminderStatus.inbox
            : ReminderStatus.active,
      _ => current.status,
    };
    final clearsSchedule = command.action == ReminderMutationAction.moveToInbox;
    final scheduledAllDay = command.action == ReminderMutationAction.schedule
        ? command.allDayLocalDate
        : current.allDayLocalDate;
    final scheduledAt = command.action == ReminderMutationAction.schedule
        ? command.customAttentionAt
        : current.nextAttentionAt;
    final trashedAt = switch (command.action) {
      ReminderMutationAction.moveToTrash => '2026-07-19T08:01:00Z',
      ReminderMutationAction.restoreFromTrash => null,
      _ => current.trashedAt,
    };
    final outcomeType = switch (command.action) {
      ReminderMutationAction.complete =>
        command.outcomeType ?? ReminderOutcomeType.completed,
      ReminderMutationAction.cancel => ReminderOutcomeType.noLongerNeeded,
      ReminderMutationAction.reopen => null,
      _ => current.outcomeType,
    };
    final outcomeNote = switch (command.action) {
      ReminderMutationAction.complete ||
      ReminderMutationAction.cancel => command.outcomeNote,
      ReminderMutationAction.reopen => null,
      _ => current.outcomeNote,
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
      nextAttentionAt: clearsSchedule ? null : scheduledAt,
      allDayLocalDate: clearsSchedule ? null : scheduledAllDay,
      deadlineAt: current.deadlineAt,
      conditionText: current.conditionText,
      outcomeType: outcomeType,
      outcomeNote: outcomeNote,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      completedAt: switch (command.action) {
        ReminderMutationAction.complete => '2026-07-19T08:01:00Z',
        ReminderMutationAction.reopen => null,
        _ => current.completedAt,
      },
      cancelledAt: switch (command.action) {
        ReminderMutationAction.cancel => '2026-07-19T08:01:00Z',
        ReminderMutationAction.reopen => null,
        _ => current.cancelledAt,
      },
      trashedAt: trashedAt,
      revision: current.revision + 1,
    );
    reminders = [...reminders]..[index] = updated;
    reminderDetail = updated;
    return updated;
  }

  @override
  Future<void> reconcileNotifications({bool requestPermission = false}) async {}
}
