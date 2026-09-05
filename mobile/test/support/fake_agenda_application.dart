import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';

class FakeAgendaApplication
    implements
        AgendaApplication,
        ProjectProfileApplication,
        ReminderTodayApplication,
        ReminderSourceAgendaMediaApplication {
  FakeAgendaApplication({
    this.projects = const [],
    this.logs = const [],
    this.reminders = const [],
    this.todayOverview,
    this.logDetail,
    this.agendaLogDetailFailure,
    this.reminderDetail,
    this.sourceAgendaMedia,
    this.sourceAgendaMediaFailure,
    this.syncAgendaToReminderFailure,
    this.agendaPhotoContents = const {},
    this.initialNotificationReminderId,
    this.notificationTapStream = const Stream<String>.empty(),
    Map<String, List<ProjectProfileField>> projectProfileFields = const {},
    DateTime? asOfUtc,
  }) : projectProfileFields = {
         for (final entry in projectProfileFields.entries)
           entry.key: [...entry.value],
       },
       asOfUtc = asOfUtc ?? DateTime.utc(2026, 7, 20, 5);

  List<MobileProject> projects;
  List<AgendaLog> logs;
  List<MobileReminder> reminders;
  final Map<String, List<ProjectProfileField>> projectProfileFields;
  final Map<String, List<Future<ProjectProfile>>> projectProfileResponses = {};
  final List<ProjectProfileEvent> projectProfileEvents = [];
  ReminderTodayOverview? todayOverview;
  final DateTime asOfUtc;
  AgendaLogDetail? logDetail;
  Object? agendaLogDetailFailure;
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
  Object? syncAgendaToReminderFailure;
  ReminderViewGroup? lastReminderGroup;
  Completer<MobileReminder>? createReminderCompleter;
  Completer<MobileReminder>? mutateReminderCompleter;
  Completer<AgendaReminderSyncResult>? syncAgendaToReminderCompleter;
  int createLogCalls = 0;
  int createReminderCalls = 0;
  int todayOverviewCalls = 0;
  int sourceAgendaMediaCalls = 0;
  int mutateReminderCalls = 0;
  int syncAgendaToReminderCalls = 0;
  int getAgendaLogDetailCalls = 0;
  int reminderLifecycleDetailCalls = 0;
  int listAgendaCalls = 0;
  int listProjectsCalls = 0;
  Completer<void>? listProjectsGate;
  final List<Future<List<MobileProject>>> listProjectsResponses = [];
  final List<AgendaQuery> agendaQueries = [];
  MutateReminderCommand? lastMutationCommand;
  SyncAgendaToReminderCommand? lastSyncAgendaToReminderCommand;
  AgendaQuery? lastAgendaQuery;
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
  Future<AgendaReminderSyncResult> syncAgendaToReminder(
    SyncAgendaToReminderCommand command,
  ) async {
    syncAgendaToReminderCalls += 1;
    lastSyncAgendaToReminderCommand = command;
    if (syncAgendaToReminderFailure case final failure?) throw failure;
    if (syncAgendaToReminderCompleter case final completer?) {
      return completer.future;
    }
    final log = logs.firstWhere((item) => item.id == command.sourceLogId);
    final index = reminders.indexWhere((item) => item.id == command.reminderId);
    if (index < 0) throw StateError('missing reminder');
    final current = reminders[index];
    if (log.revision != command.expectedSourceRevision ||
        current.revision != command.expectedTargetRevision) {
      throw const AgendaValidationFailure('stale revision');
    }
    if (log.archivedAt != null ||
        current.trashedAt != null ||
        current.status == ReminderStatus.completed ||
        current.status == ReminderStatus.cancelled ||
        current.sourceLogId != log.id ||
        current.projectId != log.projectId) {
      throw const AgendaValidationFailure('unsafe sync target');
    }
    final selectedFields = AgendaReminderSyncField.values
        .where(command.selectedFields.contains)
        .toList(growable: false);
    if (selectedFields.isEmpty) {
      throw const AgendaValidationFailure('missing sync fields');
    }
    final copiedFields = <AgendaReminderSyncField>[];
    final changes = <String, Object?>{};
    var title = current.title;
    var description = current.description;
    var locationId = current.locationId;
    var location = current.location;
    var stableLocationName = current.stableLocationName;
    var stableLocationArchivedAt = current.stableLocationArchivedAt;
    for (final field in selectedFields) {
      switch (field) {
        case AgendaReminderSyncField.title:
          if (title != log.description) {
            copiedFields.add(field);
            changes[field.storageValue] = {
              'before': title,
              'after': log.description,
            };
            title = log.description;
          }
        case AgendaReminderSyncField.description:
          if (description != log.notes) {
            copiedFields.add(field);
            changes[field.storageValue] = {
              'before': description,
              'after': log.notes,
            };
            description = log.notes;
          }
        case AgendaReminderSyncField.location:
          final nextLocation = log.locationId == null
              ? log.location
              : log.stableLocationName;
          if (locationId != log.locationId || location != nextLocation) {
            copiedFields.add(field);
            changes[field.storageValue] = {
              'before': {'location_id': locationId, 'location': location},
              'after': {
                'location_id': log.locationId,
                'location': nextLocation,
              },
            };
            locationId = log.locationId;
            location = nextLocation;
            stableLocationName = log.stableLocationName;
            stableLocationArchivedAt = log.stableLocationArchivedAt;
          }
      }
    }
    final changed = copiedFields.isNotEmpty;
    if (changed) {
      final updated = MobileReminder(
        id: current.id,
        projectId: current.projectId,
        projectName: current.projectName,
        sourceLogId: current.sourceLogId,
        attendanceDayId: current.attendanceDayId,
        concretePourId: current.concretePourId,
        captureText: current.captureText,
        title: title,
        description: description,
        kind: current.kind,
        status: current.status,
        locationId: locationId,
        stableLocationName: stableLocationName,
        stableLocationArchivedAt: stableLocationArchivedAt,
        location: location,
        relatedPerson: current.relatedPerson,
        isImportant: current.isImportant,
        nextAttentionAt: current.nextAttentionAt,
        allDayLocalDate: current.allDayLocalDate,
        deadlineAt: current.deadlineAt,
        conditionText: current.conditionText,
        outcomeType: current.outcomeType,
        outcomeNote: current.outcomeNote,
        createdAt: current.createdAt,
        updatedAt: '2026-07-19T08:01:00Z',
        completedAt: current.completedAt,
        cancelledAt: current.cancelledAt,
        trashedAt: current.trashedAt,
        revision: current.revision + 1,
      );
      reminders = [...reminders]..[index] = updated;
      reminderDetail = updated;
    }
    return AgendaReminderSyncResult(
      operationId: command.operationId,
      sourceLogId: log.id,
      reminderId: current.id,
      sourceRevision: log.revision,
      targetRevisionBefore: current.revision,
      targetRevisionAfter: current.revision + (changed ? 1 : 0),
      selectedFields: List.unmodifiable(selectedFields),
      copiedFields: List.unmodifiable(copiedFields),
      changes: Map.unmodifiable(changes),
      changed: changed,
      idempotent: false,
    );
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
    final linked = reminders.where((item) => item.sourceLogId == command.id);
    return AgendaLogDetail(
      log: updated,
      reminders: linked
          .where((item) => item.trashedAt == null)
          .toList(growable: false),
      trashedReminders: linked
          .where((item) => item.trashedAt != null)
          .toList(growable: false),
    );
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
          : command.customAttentionAt ??
                resolveReminderExactQuickScheduleAt(
                  command.schedule,
                  asOfUtc,
                ) ??
                '2026-07-19T09:00:00Z',
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
    getAgendaLogDetailCalls += 1;
    if (agendaLogDetailFailure case final failure?) throw failure;
    if (logDetail case final detail?) return detail;
    final log = logs.firstWhere((item) => item.id == logId);
    return AgendaLogDetail(
      log: log,
      reminders: reminders
          .where((item) => item.sourceLogId == logId && item.trashedAt == null)
          .toList(growable: false),
      trashedReminders: reminders
          .where((item) => item.sourceLogId == logId && item.trashedAt != null)
          .toList(growable: false),
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
    reminderLifecycleDetailCalls += 1;
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
  Future<List<AgendaLog>> listAgenda(AgendaQuery query) async {
    listAgendaCalls += 1;
    lastAgendaQuery = query;
    agendaQueries.add(query);
    final result = [...logs];
    result.sort(
      (left, right) => _compareAgendaLogs(left, right, query.sortOrder),
    );
    return List.unmodifiable(result);
  }

  @override
  Future<List<AppendOnlyEvent>> listObservationEvents(String logId) async =>
      const [];

  @override
  Future<List<MobileProject>> listProjects() async {
    listProjectsCalls += 1;
    if (listProjectsResponses.isNotEmpty) {
      return List.unmodifiable(await listProjectsResponses.removeAt(0));
    }
    final gate = listProjectsGate;
    if (gate != null) await gate.future;
    return List.unmodifiable(projects);
  }

  @override
  Future<ProjectProfile> getProjectProfile(String projectId) async {
    final responses = projectProfileResponses[projectId];
    if (responses != null && responses.isNotEmpty) {
      return responses.removeAt(0);
    }
    return _fakeProjectProfile(projectId);
  }

  @override
  Future<ProjectProfileField> createProjectProfileField(
    CreateProjectProfileFieldCommand command,
  ) async {
    final profile = _fakeProjectProfile(command.projectId);
    if (profile.fields.any((field) => field.id == command.id)) {
      throw const AgendaValidationFailure('duplicate profile field');
    }
    final now = '2026-07-19T08:01:00Z';
    final field = ProjectProfileField(
      id: command.id,
      projectId: command.projectId,
      label: command.label.trim(),
      value: command.value.trim(),
      sortOrder: profile.fields.length,
      revision: 1,
      createdAt: now,
      updatedAt: now,
    );
    projectProfileFields[command.projectId] = [...profile.fields, field];
    _appendFakeProfileEvent(
      id: command.eventId,
      projectId: command.projectId,
      fieldId: field.id,
      eventType: ProjectProfileEventType.fieldCreated,
    );
    _projectChanges.add(null);
    return field;
  }

  @override
  Future<ProjectProfileField> updateProjectProfileField(
    UpdateProjectProfileFieldCommand command,
  ) async {
    final profile = _fakeProjectProfile(command.projectId);
    final index = profile.fields.indexWhere(
      (field) => field.id == command.fieldId,
    );
    if (index < 0 ||
        profile.fields[index].revision != command.expectedRevision) {
      throw const AgendaValidationFailure('stale profile field');
    }
    final current = profile.fields[index];
    final updated = ProjectProfileField(
      id: current.id,
      projectId: current.projectId,
      builtinField: current.builtinField,
      label: current.isBuiltIn ? current.label : command.label.trim(),
      value: command.value.trim(),
      sortOrder: current.sortOrder,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: current.archivedAt,
    );
    projectProfileFields[command.projectId] = [...profile.fields]
      ..[index] = updated;
    _appendFakeProfileEvent(
      id: command.eventId,
      projectId: command.projectId,
      fieldId: updated.id,
      eventType: ProjectProfileEventType.fieldUpdated,
    );
    _projectChanges.add(null);
    return updated;
  }

  @override
  Future<ProjectProfileField> mutateProjectProfileFieldArchive(
    MutateProjectProfileFieldArchiveCommand command,
  ) async {
    final fields =
        projectProfileFields[command.projectId] ??
        _fakeProjectProfile(command.projectId).fields;
    final index = fields.indexWhere((field) => field.id == command.fieldId);
    if (index < 0 || fields[index].revision != command.expectedRevision) {
      throw const AgendaValidationFailure('stale profile field');
    }
    final current = fields[index];
    if (current.isBuiltIn) {
      throw const AgendaValidationFailure('builtin profile field');
    }
    final updated = ProjectProfileField(
      id: current.id,
      projectId: current.projectId,
      label: current.label,
      value: current.value,
      sortOrder: current.sortOrder,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-07-19T08:01:00Z',
      archivedAt: command.archive ? '2026-07-19T08:01:00Z' : null,
    );
    projectProfileFields[command.projectId] = [...fields]..[index] = updated;
    _appendFakeProfileEvent(
      id: command.eventId,
      projectId: command.projectId,
      fieldId: updated.id,
      eventType: command.archive
          ? ProjectProfileEventType.fieldArchived
          : ProjectProfileEventType.fieldRestored,
    );
    _projectChanges.add(null);
    return updated;
  }

  @override
  Future<ProjectProfile> reorderProjectProfileFields(
    ReorderProjectProfileFieldsCommand command,
  ) async {
    final profile = _fakeProjectProfile(command.projectId);
    final current = {for (final field in profile.fields) field.id: field};
    if (current.length != command.fields.length) {
      throw const AgendaValidationFailure('incomplete profile order');
    }
    final reordered = <ProjectProfileField>[];
    for (var index = 0; index < command.fields.length; index += 1) {
      final requested = command.fields[index];
      final field = current[requested.fieldId];
      if (field == null || field.revision != requested.expectedRevision) {
        throw const AgendaValidationFailure('stale profile order');
      }
      reordered.add(
        ProjectProfileField(
          id: field.id,
          projectId: field.projectId,
          builtinField: field.builtinField,
          label: field.label,
          value: field.value,
          sortOrder: index,
          revision: field.sortOrder == index
              ? field.revision
              : field.revision + 1,
          createdAt: field.createdAt,
          updatedAt: field.sortOrder == index
              ? field.updatedAt
              : '2026-07-19T08:01:00Z',
        ),
      );
    }
    projectProfileFields[command.projectId] = reordered;
    _appendFakeProfileEvent(
      id: command.eventId,
      projectId: command.projectId,
      eventType: ProjectProfileEventType.fieldsReordered,
    );
    _projectChanges.add(null);
    return _fakeProjectProfile(command.projectId);
  }

  @override
  Future<List<ProjectProfileEvent>> listProjectProfileEvents(
    String projectId,
  ) async => List.unmodifiable(
    projectProfileEvents.where((event) => event.projectId == projectId),
  );

  ProjectProfile _fakeProjectProfile(String projectId) {
    final project = projects.singleWhere((item) => item.id == projectId);
    final allFields = projectProfileFields.putIfAbsent(
      projectId,
      () => [
        for (
          var index = 0;
          index < ProjectProfileBuiltinField.values.length;
          index += 1
        )
          ProjectProfileField(
            id:
                'project-profile:$projectId:'
                '${ProjectProfileBuiltinField.values[index].storageValue}',
            projectId: projectId,
            builtinField: ProjectProfileBuiltinField.values[index],
            label: ProjectProfileBuiltinField.values[index].label,
            value: '',
            sortOrder: index,
            revision: 0,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt,
          ),
      ],
    );
    final active = allFields.where((field) => !field.isArchived).toList()
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return ProjectProfile(project: project, fields: List.unmodifiable(active));
  }

  void _appendFakeProfileEvent({
    required String id,
    required String projectId,
    required ProjectProfileEventType eventType,
    String? fieldId,
  }) {
    projectProfileEvents.add(
      ProjectProfileEvent(
        id: id,
        projectId: projectId,
        fieldId: fieldId,
        sequence:
            projectProfileEvents
                .where((event) => event.projectId == projectId)
                .length +
            1,
        eventType: eventType,
        occurredAt: '2026-07-19T08:01:00Z',
        payloadJson: '{}',
      ),
    );
  }

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
    if (command.action != ReminderMutationAction.schedule &&
        (command.expectedEarlierFromAttentionAt != null ||
            command.confirmedPastAttentionAt != null)) {
      throw const AgendaValidationFailure('invalid earlier intent');
    }
    if (command.expectedEarlierFromAttentionAt case final earlierFrom?) {
      final selectedAt = command.customAttentionAt;
      if (command.schedule != ReminderScheduleKind.custom ||
          selectedAt == null ||
          command.allDayLocalDate != null ||
          !isReminderEligibleForQuickEarlier(current) ||
          current.nextAttentionAt != earlierFrom) {
        throw const AgendaValidationFailure('invalid quick earlier reminder');
      }
      final candidate = CseTimeCodec.decodeCanonicalUtc(selectedAt);
      if (!candidate.isBefore(CseTimeCodec.decodeCanonicalUtc(earlierFrom))) {
        throw const AgendaValidationFailure(
          'Yeni zaman mevcut zamandan daha erken olmalıdır.',
        );
      }
      final confirmedPast = command.confirmedPastAttentionAt;
      if (confirmedPast != null && confirmedPast != selectedAt) {
        throw const AgendaValidationFailure('invalid past confirmation');
      }
      if (!candidate.isAfter(asOfUtc)) {
        if (confirmedPast != selectedAt) {
          throw ReminderPastAttentionConfirmationRequired(
            earlierFromAttentionAt: earlierFrom,
            selectedAttentionAt: selectedAt,
          );
        }
      } else if (confirmedPast != null) {
        throw const AgendaValidationFailure('unexpected past confirmation');
      }
    } else if (command.confirmedPastAttentionAt != null) {
      throw const AgendaValidationFailure('missing quick earlier intent');
    }
    final today = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(asOfUtc));
    if (command.action == ReminderMutationAction.snoozeTomorrowMorning &&
        !isReminderEligibleForTomorrowSnooze(current, istanbulToday: today)) {
      throw const AgendaValidationFailure(
        'Bu hatırlatıcı yarına ertelenemez. Tarihi veya kaynak akışı kontrol edin.',
      );
    }
    if (command.action == ReminderMutationAction.schedule &&
        command.allDayLocalDate != null &&
        current.attendanceDayId != null) {
      throw const AgendaValidationFailure(
        'Puantaj tarafından yönetilen hatırlatıcı doğrudan tam gün planlanamaz.',
      );
    }
    final status = switch (command.action) {
      ReminderMutationAction.complete => ReminderStatus.completed,
      ReminderMutationAction.cancel => ReminderStatus.cancelled,
      ReminderMutationAction.moveToInbox => ReminderStatus.inbox,
      ReminderMutationAction.schedule ||
      ReminderMutationAction.snooze15Minutes ||
      ReminderMutationAction.snooze1Hour ||
      ReminderMutationAction.snooze2Hours ||
      ReminderMutationAction.snooze3Hours ||
      ReminderMutationAction.snoozeTomorrowMorning => ReminderStatus.active,
      ReminderMutationAction.reopen =>
        current.nextAttentionAt == null && current.allDayLocalDate == null
            ? ReminderStatus.inbox
            : ReminderStatus.active,
      _ => current.status,
    };
    final clearsSchedule = command.action == ReminderMutationAction.moveToInbox;
    final scheduledAllDay = switch (command.action) {
      ReminderMutationAction.schedule => command.allDayLocalDate,
      ReminderMutationAction.snooze15Minutes ||
      ReminderMutationAction.snooze1Hour ||
      ReminderMutationAction.snooze2Hours ||
      ReminderMutationAction.snooze3Hours => null,
      ReminderMutationAction.snoozeTomorrowMorning
          when current.allDayLocalDate != null =>
        CseTimeCodec.shiftIstanbulDay(today, 1),
      _ => current.allDayLocalDate,
    };
    final scheduledAt = switch (command.action) {
      ReminderMutationAction.schedule when command.allDayLocalDate != null =>
        null,
      ReminderMutationAction.schedule =>
        command.customAttentionAt ??
            (command.schedule == null
                ? null
                : resolveReminderExactQuickScheduleAt(
                    command.schedule!,
                    asOfUtc,
                  )) ??
            current.nextAttentionAt,
      ReminderMutationAction.snooze15Minutes =>
        asOfUtc.add(const Duration(minutes: 15)).toIso8601String(),
      ReminderMutationAction.snooze1Hour =>
        asOfUtc.add(const Duration(hours: 1)).toIso8601String(),
      ReminderMutationAction.snooze2Hours =>
        asOfUtc.add(const Duration(hours: 2)).toIso8601String(),
      ReminderMutationAction.snooze3Hours =>
        asOfUtc.add(const Duration(hours: 3)).toIso8601String(),
      ReminderMutationAction.snoozeTomorrowMorning
          when current.allDayLocalDate != null =>
        null,
      ReminderMutationAction.snoozeTomorrowMorning =>
        resolveReminderTomorrowMorningAt(asOfUtc),
      _ => current.nextAttentionAt,
    };
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
      attendanceDayId: current.attendanceDayId,
      concretePourId: current.concretePourId,
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

int _compareAgendaLogs(
  AgendaLog left,
  AgendaLog right,
  AgendaSortOrder sortOrder,
) {
  var comparison = left.observedAt.compareTo(right.observedAt);
  if (comparison == 0) {
    comparison = left.createdAt.compareTo(right.createdAt);
  }
  if (comparison == 0) {
    comparison = left.id.compareTo(right.id);
  }
  return sortOrder == AgendaSortOrder.newestFirst ? -comparison : comparison;
}
