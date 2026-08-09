import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/platform/agenda_attachment_gateway.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

class ReminderTodayOverview {
  const ReminderTodayOverview({
    required this.istanbulDay,
    required this.overdue,
    required this.timedToday,
    required this.allDayToday,
    required this.inboxCount,
  });

  final String istanbulDay;
  final List<MobileReminder> overdue;
  final List<MobileReminder> timedToday;
  final List<MobileReminder> allDayToday;
  final int inboxCount;

  bool get isEmpty =>
      overdue.isEmpty && timedToday.isEmpty && allDayToday.isEmpty;
}

ReminderTodayOverview buildReminderTodayOverview(
  Iterable<MobileReminder> reminders, {
  required DateTime asOfUtc,
}) {
  final asOf = CseTimeCodec.encodeUtc(asOfUtc);
  final today = CseTimeCodec.istanbulDayKey(asOf);
  final localNow = CseTimeCodec.toIstanbul(asOf);
  final allDayCutoffReached = localNow.hour >= 18;
  final unique = <String, MobileReminder>{};
  for (final reminder in reminders) {
    if (reminder.trashedAt != null) continue;
    unique.putIfAbsent(reminder.id, () => reminder);
  }

  final overdue = <MobileReminder>[];
  final timedToday = <MobileReminder>[];
  final allDayToday = <MobileReminder>[];
  var inboxCount = 0;
  for (final reminder in unique.values) {
    if (reminder.status == ReminderStatus.inbox) {
      inboxCount += 1;
      continue;
    }
    if (reminder.status != ReminderStatus.active) continue;

    final nextAttentionAt = reminder.nextAttentionAt;
    if (nextAttentionAt != null) {
      final due = CseTimeCodec.decodeCanonicalUtc(nextAttentionAt);
      if (due.isBefore(asOfUtc)) {
        overdue.add(reminder);
      } else if (CseTimeCodec.istanbulDayKey(nextAttentionAt) == today) {
        timedToday.add(reminder);
      }
      continue;
    }

    final allDayLocalDate = reminder.allDayLocalDate;
    if (allDayLocalDate == null) continue;
    CseTimeCodec.validateIstanbulDay(allDayLocalDate);
    if (allDayLocalDate.compareTo(today) < 0 ||
        (allDayLocalDate == today && allDayCutoffReached)) {
      overdue.add(reminder);
    } else if (allDayLocalDate == today) {
      allDayToday.add(reminder);
    }
  }

  overdue.sort(_compareOverdueReminders);
  timedToday.sort(_compareTimedReminders);
  allDayToday.sort(_compareAllDayReminders);
  return ReminderTodayOverview(
    istanbulDay: today,
    overdue: List.unmodifiable(overdue),
    timedToday: List.unmodifiable(timedToday),
    allDayToday: List.unmodifiable(allDayToday),
    inboxCount: inboxCount,
  );
}

int _compareOverdueReminders(MobileReminder left, MobileReminder right) {
  final leftKey =
      left.nextAttentionAt ??
      CseTimeCodec.istanbulDayBounds(left.allDayLocalDate!).start;
  final rightKey =
      right.nextAttentionAt ??
      CseTimeCodec.istanbulDayBounds(right.allDayLocalDate!).start;
  final scheduleOrder = leftKey.compareTo(rightKey);
  if (scheduleOrder != 0) return scheduleOrder;
  return _compareImportanceCreatedAndId(left, right);
}

int _compareTimedReminders(MobileReminder left, MobileReminder right) {
  final scheduleOrder = left.nextAttentionAt!.compareTo(right.nextAttentionAt!);
  if (scheduleOrder != 0) return scheduleOrder;
  return _compareImportanceCreatedAndId(left, right);
}

int _compareAllDayReminders(MobileReminder left, MobileReminder right) =>
    _compareImportanceCreatedAndId(left, right);

int _compareImportanceCreatedAndId(MobileReminder left, MobileReminder right) {
  final importanceOrder = (right.isImportant ? 1 : 0).compareTo(
    left.isImportant ? 1 : 0,
  );
  if (importanceOrder != 0) return importanceOrder;
  final createdOrder = left.createdAt.compareTo(right.createdAt);
  if (createdOrder != 0) return createdOrder;
  return left.id.compareTo(right.id);
}

abstract interface class AgendaApplication {
  Stream<void> get projectChanges;

  Future<List<MobileProject>> listProjects();

  Future<MobileProject> createProject(CreateProjectCommand command);

  Future<List<AgendaLog>> listAgenda(AgendaQuery query);

  Future<AgendaLog> createAgendaLog(CreateAgendaLogCommand command);

  Future<AgendaLog> updateAgendaLog(UpdateAgendaLogCommand command);

  Future<AgendaLogDetail> mutateAgendaLogArchive(
    MutateAgendaLogArchiveCommand command,
  );

  Future<AgendaLogDetail> attachAgendaPhoto(AttachAgendaPhotoCommand command);

  Future<AgendaLogDetail> archiveAgendaPhoto(ArchiveAgendaPhotoCommand command);

  Future<StoredAttachmentContent> readAgendaPhoto(String photoId);

  Future<AgendaLogDetail> getAgendaLogDetail(String logId);

  Future<MobileReminder> createReminder(CreateReminderCommand command);

  Future<List<MobileReminder>> listReminders(ReminderViewGroup group);

  Future<MobileReminder> getReminderDetail(String reminderId);

  Future<ReminderDetail> getReminderLifecycleDetail(String reminderId);

  Future<MobileReminder> mutateReminder(MutateReminderCommand command);

  Future<void> reconcileNotifications({bool requestPermission = false});

  String? get initialNotificationReminderId;

  Stream<String> get notificationTaps;

  Future<List<AppendOnlyEvent>> listObservationEvents(String logId);

  Future<List<AppendOnlyEvent>> listReminderEvents(String reminderId);
}

abstract interface class ReminderTodayApplication {
  Future<ReminderTodayOverview> getReminderTodayOverview();
}

abstract interface class ProjectLocationApplication {
  Stream<void> get projectChanges;

  Stream<void> get projectLocationChanges;

  Future<List<MobileProject>> listProjects();

  Future<MobileProject> createProject(CreateProjectCommand command);

  Future<List<MobileProjectLocation>> listProjectLocations(
    ProjectLocationQuery query,
  );

  Future<MobileProjectLocation> getProjectLocation(String locationId);

  Future<MobileProjectLocation> createProjectLocation(
    CreateProjectLocationCommand command,
  );

  Future<MobileProjectLocation> renameProjectLocation(
    RenameProjectLocationCommand command,
  );

  Future<MobileProjectLocation> reparentProjectLocation(
    ReparentProjectLocationCommand command,
  );

  Future<MobileProjectLocation> mutateProjectLocationArchive(
    MutateProjectLocationArchiveCommand command,
  );

  Future<List<ProjectLocationEvent>> listProjectLocationEvents(
    String locationId,
  );
}

abstract interface class ProjectLifecycleApplication {
  Stream<void> get projectChanges;

  Future<MobileProject> getProject(String projectId);

  Future<List<MobileProject>> listProjectRecords(ProjectArchiveFilter filter);

  Future<MobileProject> renameProject(RenameProjectCommand command);

  Future<MobileProject> mutateProjectArchive(
    MutateProjectArchiveCommand command,
  );

  Future<List<ProjectEvent>> listProjectEvents(String projectId);
}

abstract interface class ReminderSourceAgendaMediaApplication {
  Future<ReminderSourceAgendaMedia> getReminderSourceAgendaMedia(
    String sourceLogId,
  );
}

abstract interface class ReminderDeliveryApplication {
  Future<ReminderDeliveryDiagnostic> getReminderDeliveryDiagnostic(
    String reminderId,
  );

  Future<void> retryReminderDelivery(String reminderId);

  Future<void> openReminderNotificationSettings();

  Future<void> openReminderBatteryOptimizationSettings();
}

typedef ReminderTransactionHook =
    Future<void> Function(Transaction transaction);

class SqliteAgendaApplication
    implements
        AgendaApplication,
        ProjectLifecycleApplication,
        ProjectLocationApplication,
        ReminderTodayApplication,
        ReminderSourceAgendaMediaApplication,
        ReminderDeliveryApplication {
  SqliteAgendaApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.clock,
    MobileOperationCoordinator? coordinator,
    ReminderNotificationGateway? notificationGateway,
    AgendaAttachmentStore? attachmentStore,
    this.beforeReminderEventInsert,
  }) : coordinator = coordinator ?? MobileOperationCoordinator(),
       notificationGateway =
           notificationGateway ??
           const UnavailableReminderNotificationGateway(),
       attachmentStore =
           attachmentStore ?? const UnavailableAgendaAttachmentStore();

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;
  final MobileOperationCoordinator coordinator;
  final ReminderNotificationGateway notificationGateway;
  final AgendaAttachmentStore attachmentStore;
  final ReminderTransactionHook? beforeReminderEventInsert;
  final StreamController<void> _projectChanges =
      StreamController<void>.broadcast();
  final StreamController<void> _projectLocationChanges =
      StreamController<void>.broadcast();

  @override
  Stream<void> get projectChanges => _projectChanges.stream;

  @override
  Stream<void> get projectLocationChanges => _projectLocationChanges.stream;

  @override
  String? get initialNotificationReminderId =>
      notificationGateway.initialTapReminderId;

  @override
  Stream<String> get notificationTaps => notificationGateway.notificationTaps;

  @override
  Future<List<MobileProject>> listProjects() async {
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.query(
        'projects',
        where: 'archived_at IS NULL',
        orderBy: 'name COLLATE NOCASE ASC, id ASC',
      );
      return rows.map(_projectFromRow).toList(growable: false);
    });
  }

  @override
  Future<MobileProject> createProject(CreateProjectCommand command) async {
    validateUuid(command.id, 'Proje kimliği');
    final name = requiredTrimmed(command.name, 'Proje adı', maxLength: 160);
    final now = _readClockOnce();
    final createdAt = CseTimeCodec.encodeUtc(now);
    final result = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final existing = await transaction.query(
          'projects',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final project = _projectFromRow(existing.single);
          if (project.name != name) {
            throw const AgendaValidationFailure(
              'Proje kimliği başka bir içerikle kullanılıyor.',
            );
          }
          return (project: project, changed: false);
        }
        final activeProjects = await transaction.query(
          'projects',
          columns: ['id', 'name'],
          where: 'archived_at IS NULL',
        );
        final normalizedName = _normalizeProjectName(name);
        if (activeProjects.any(
          (row) =>
              _normalizeProjectName(row['name']! as String) == normalizedName,
        )) {
          throw const AgendaValidationFailure(
            'Aynı adlı aktif proje zaten bulunuyor.',
          );
        }
        await transaction.insert('projects', {
          'id': command.id,
          'name': name,
          'created_at': createdAt,
          'updated_at': createdAt,
          'revision': 1,
        });
        return (
          project: MobileProject(
            id: command.id,
            name: name,
            createdAt: createdAt,
            updatedAt: createdAt,
            revision: 1,
          ),
          changed: true,
        );
      });
    });
    if (result.changed) _projectChanges.add(null);
    return result.project;
  }

  @override
  Future<MobileProject> getProject(String projectId) async {
    validateUuid(projectId, 'Proje kimliği');
    final now = _readClockOnce();
    return _withDatabase(
      now,
      (database) => _requireProjectRecord(database, projectId),
    );
  }

  @override
  Future<List<MobileProject>> listProjectRecords(
    ProjectArchiveFilter filter,
  ) async {
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.query(
        'projects',
        where: filter == ProjectArchiveFilter.active
            ? 'archived_at IS NULL'
            : 'archived_at IS NOT NULL',
      );
      final projects = rows.map(_projectFromRow).toList(growable: true)
        ..sort((left, right) {
          final nameOrder = _normalizeProjectName(
            left.name,
          ).compareTo(_normalizeProjectName(right.name));
          if (nameOrder != 0) return nameOrder;
          return left.id.compareTo(right.id);
        });
      return List.unmodifiable(projects);
    });
  }

  @override
  Future<MobileProject> renameProject(RenameProjectCommand command) async {
    validateUuid(command.projectId, 'Proje kimliği');
    validateUuid(command.eventId, 'Proje event kimliği');
    _validateProjectRevision(command.expectedRevision);
    final name = requiredTrimmed(command.name, 'Proje adı', maxLength: 160);
    final now = _readClockOnce();
    final occurredAt = CseTimeCodec.encodeUtc(now);
    final result = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final current = await _requireProjectRecord(
          transaction,
          command.projectId,
        );
        _requireActiveProjectRecord(current);
        _requireProjectRevision(current, command.expectedRevision);
        if (current.name == name) {
          return (project: current, changed: false);
        }
        await _rejectActiveProjectDuplicate(
          transaction,
          normalizedName: _normalizeProjectName(name),
          excludingProjectId: current.id,
        );
        await _updateProject(
          transaction,
          projectId: current.id,
          expectedRevision: current.revision,
          values: {
            'name': name,
            'updated_at': occurredAt,
            'revision': current.revision + 1,
          },
        );
        await _insertProjectEvent(
          transaction,
          id: command.eventId,
          projectId: current.id,
          eventType: ProjectEventType.renamed,
          occurredAt: occurredAt,
          payload: {'old_name': current.name, 'new_name': name},
        );
        return (
          project: await _requireProjectRecord(transaction, current.id),
          changed: true,
        );
      });
    });
    if (result.changed) _projectChanges.add(null);
    return result.project;
  }

  @override
  Future<MobileProject> mutateProjectArchive(
    MutateProjectArchiveCommand command,
  ) async {
    validateUuid(command.projectId, 'Proje kimliği');
    validateUuid(command.eventId, 'Proje event kimliği');
    _validateProjectRevision(command.expectedRevision);
    final now = _readClockOnce();
    final occurredAt = CseTimeCodec.encodeUtc(now);
    final result = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final current = await _requireProjectRecord(
          transaction,
          command.projectId,
        );
        if (current.isArchived == command.archive) {
          return (project: current, changed: false);
        }
        _requireProjectRevision(current, command.expectedRevision);
        if (!command.archive) {
          await _rejectActiveProjectDuplicate(
            transaction,
            normalizedName: _normalizeProjectName(current.name),
            excludingProjectId: current.id,
          );
        }
        await _updateProject(
          transaction,
          projectId: current.id,
          expectedRevision: current.revision,
          values: {
            'archived_at': command.archive ? occurredAt : null,
            'updated_at': occurredAt,
            'revision': current.revision + 1,
          },
        );
        await _insertProjectEvent(
          transaction,
          id: command.eventId,
          projectId: current.id,
          eventType: command.archive
              ? ProjectEventType.archived
              : ProjectEventType.restored,
          occurredAt: occurredAt,
          payload: {
            'was_archived': current.isArchived,
            'is_archived': command.archive,
          },
        );
        return (
          project: await _requireProjectRecord(transaction, current.id),
          changed: true,
        );
      });
    });
    if (result.changed) _projectChanges.add(null);
    return result.project;
  }

  @override
  Future<List<ProjectEvent>> listProjectEvents(String projectId) async {
    validateUuid(projectId, 'Proje kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      await _requireProjectRecord(database, projectId);
      final rows = await database.query(
        'project_events',
        where: 'project_id = ?',
        whereArgs: [projectId],
        orderBy: 'sequence ASC, id ASC',
      );
      return rows.map(_projectEventFromRow).toList(growable: false);
    });
  }

  @override
  Future<List<MobileProjectLocation>> listProjectLocations(
    ProjectLocationQuery query,
  ) async {
    validateUuid(query.projectId, 'Proje kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      await _requireProjectExists(database, query.projectId);
      final rows = await database.query(
        'project_locations',
        where:
            'project_id = ? AND '
            '${query.archiveFilter == ProjectLocationArchiveFilter.active ? 'archived_at IS NULL' : 'archived_at IS NOT NULL'}',
        whereArgs: [query.projectId],
        orderBy: 'normalized_name ASC, id ASC',
      );
      return rows.map(_projectLocationFromRow).toList(growable: false);
    });
  }

  @override
  Future<MobileProjectLocation> getProjectLocation(String locationId) async {
    validateUuid(locationId, 'Mahal kimliği');
    final now = _readClockOnce();
    return _withDatabase(
      now,
      (database) => _requireProjectLocation(database, locationId),
    );
  }

  @override
  Future<MobileProjectLocation> createProjectLocation(
    CreateProjectLocationCommand command,
  ) async {
    validateUuid(command.id, 'Mahal kimliği');
    validateUuid(command.eventId, 'Mahal event kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    final parentLocationId = command.parentLocationId;
    if (parentLocationId != null) {
      validateUuid(parentLocationId, 'Üst mahal kimliği');
    }
    final displayName = _locationDisplayName(command.displayName);
    final normalizedName = _normalizeLocationName(displayName);
    final now = _readClockOnce();
    final occurredAt = CseTimeCodec.encodeUtc(now);
    final result = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        await _requireActiveProject(transaction, command.projectId);
        final existingRows = await transaction.query(
          'project_locations',
          where: 'id = ?',
          whereArgs: [command.id],
          limit: 1,
        );
        if (existingRows.isNotEmpty) {
          final existing = _projectLocationFromRow(existingRows.single);
          if (existing.projectId != command.projectId ||
              existing.displayName != displayName ||
              existing.parentLocationId != parentLocationId ||
              existing.isArchived) {
            throw const AgendaValidationFailure(
              'Mahal kimliği başka bir içerikle kullanılıyor.',
            );
          }
          return (location: existing, changed: false);
        }
        if (parentLocationId != null) {
          await _requireActiveLocationInProject(
            transaction,
            parentLocationId,
            command.projectId,
          );
        }
        await _rejectActiveSiblingDuplicate(
          transaction,
          projectId: command.projectId,
          parentLocationId: parentLocationId,
          normalizedName: normalizedName,
        );
        await transaction.insert('project_locations', {
          'id': command.id,
          'project_id': command.projectId,
          'display_name': displayName,
          'normalized_name': normalizedName,
          'parent_location_id': parentLocationId,
          'revision': 1,
          'created_at': occurredAt,
          'updated_at': occurredAt,
        });
        await _insertProjectLocationEvent(
          transaction,
          id: command.eventId,
          locationId: command.id,
          eventType: ProjectLocationEventType.created,
          occurredAt: occurredAt,
          payload: {
            'display_name': displayName,
            'parent_location_id': parentLocationId,
          },
        );
        return (
          location: MobileProjectLocation(
            id: command.id,
            projectId: command.projectId,
            displayName: displayName,
            parentLocationId: parentLocationId,
            revision: 1,
            createdAt: occurredAt,
            updatedAt: occurredAt,
            archivedAt: null,
          ),
          changed: true,
        );
      });
    });
    if (result.changed) _projectLocationChanges.add(null);
    return result.location;
  }

  @override
  Future<MobileProjectLocation> renameProjectLocation(
    RenameProjectLocationCommand command,
  ) async {
    validateUuid(command.locationId, 'Mahal kimliği');
    validateUuid(command.eventId, 'Mahal event kimliği');
    _validateLocationRevision(command.expectedRevision);
    final displayName = _locationDisplayName(command.displayName);
    final normalizedName = _normalizeLocationName(displayName);
    final now = _readClockOnce();
    final occurredAt = CseTimeCodec.encodeUtc(now);
    final result = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final current = await _requireProjectLocation(
          transaction,
          command.locationId,
        );
        _requireActiveLocation(current);
        _requireLocationRevision(current, command.expectedRevision);
        if (current.displayName == displayName) {
          return (location: current, changed: false);
        }
        await _rejectActiveSiblingDuplicate(
          transaction,
          projectId: current.projectId,
          parentLocationId: current.parentLocationId,
          normalizedName: normalizedName,
          excludingLocationId: current.id,
        );
        await _updateProjectLocation(
          transaction,
          locationId: current.id,
          expectedRevision: current.revision,
          values: {
            'display_name': displayName,
            'normalized_name': normalizedName,
            'updated_at': occurredAt,
            'revision': current.revision + 1,
          },
        );
        await _insertProjectLocationEvent(
          transaction,
          id: command.eventId,
          locationId: current.id,
          eventType: ProjectLocationEventType.renamed,
          occurredAt: occurredAt,
          payload: {
            'old_display_name': current.displayName,
            'new_display_name': displayName,
          },
        );
        return (
          location: await _requireProjectLocation(transaction, current.id),
          changed: true,
        );
      });
    });
    if (result.changed) _projectLocationChanges.add(null);
    return result.location;
  }

  @override
  Future<MobileProjectLocation> reparentProjectLocation(
    ReparentProjectLocationCommand command,
  ) async {
    validateUuid(command.locationId, 'Mahal kimliği');
    validateUuid(command.eventId, 'Mahal event kimliği');
    _validateLocationRevision(command.expectedRevision);
    final parentLocationId = command.parentLocationId;
    if (parentLocationId != null) {
      validateUuid(parentLocationId, 'Üst mahal kimliği');
    }
    final now = _readClockOnce();
    final occurredAt = CseTimeCodec.encodeUtc(now);
    final result = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final current = await _requireProjectLocation(
          transaction,
          command.locationId,
        );
        _requireActiveLocation(current);
        _requireLocationRevision(current, command.expectedRevision);
        if (current.parentLocationId == parentLocationId) {
          return (location: current, changed: false);
        }
        if (parentLocationId != null) {
          if (parentLocationId == current.id) {
            throw const AgendaValidationFailure(
              'Mahal kendi üst mahali olamaz.',
            );
          }
          await _requireActiveLocationInProject(
            transaction,
            parentLocationId,
            current.projectId,
          );
          await _rejectDescendantParent(
            transaction,
            locationId: current.id,
            parentLocationId: parentLocationId,
          );
        }
        await _rejectActiveSiblingDuplicate(
          transaction,
          projectId: current.projectId,
          parentLocationId: parentLocationId,
          normalizedName: _normalizeLocationName(current.displayName),
          excludingLocationId: current.id,
        );
        await _updateProjectLocation(
          transaction,
          locationId: current.id,
          expectedRevision: current.revision,
          values: {
            'parent_location_id': parentLocationId,
            'updated_at': occurredAt,
            'revision': current.revision + 1,
          },
        );
        await _insertProjectLocationEvent(
          transaction,
          id: command.eventId,
          locationId: current.id,
          eventType: ProjectLocationEventType.reparented,
          occurredAt: occurredAt,
          payload: {
            'old_parent_location_id': current.parentLocationId,
            'new_parent_location_id': parentLocationId,
          },
        );
        return (
          location: await _requireProjectLocation(transaction, current.id),
          changed: true,
        );
      });
    });
    if (result.changed) _projectLocationChanges.add(null);
    return result.location;
  }

  @override
  Future<MobileProjectLocation> mutateProjectLocationArchive(
    MutateProjectLocationArchiveCommand command,
  ) async {
    validateUuid(command.locationId, 'Mahal kimliği');
    validateUuid(command.eventId, 'Mahal event kimliği');
    _validateLocationRevision(command.expectedRevision);
    final now = _readClockOnce();
    final occurredAt = CseTimeCodec.encodeUtc(now);
    final result = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final current = await _requireProjectLocation(
          transaction,
          command.locationId,
        );
        if (current.isArchived == command.archive) {
          return (location: current, changed: false);
        }
        _requireLocationRevision(current, command.expectedRevision);
        if (command.archive) {
          await _rejectActiveDescendants(transaction, current.id);
        } else {
          final parentLocationId = current.parentLocationId;
          if (parentLocationId != null) {
            await _requireActiveLocationInProject(
              transaction,
              parentLocationId,
              current.projectId,
            );
          }
          await _rejectActiveSiblingDuplicate(
            transaction,
            projectId: current.projectId,
            parentLocationId: parentLocationId,
            normalizedName: _normalizeLocationName(current.displayName),
            excludingLocationId: current.id,
          );
        }
        await _updateProjectLocation(
          transaction,
          locationId: current.id,
          expectedRevision: current.revision,
          values: {
            'archived_at': command.archive ? occurredAt : null,
            'updated_at': occurredAt,
            'revision': current.revision + 1,
          },
        );
        final eventType = command.archive
            ? ProjectLocationEventType.archived
            : ProjectLocationEventType.restored;
        await _insertProjectLocationEvent(
          transaction,
          id: command.eventId,
          locationId: current.id,
          eventType: eventType,
          occurredAt: occurredAt,
          payload: {
            'was_archived': current.isArchived,
            'is_archived': command.archive,
          },
        );
        return (
          location: await _requireProjectLocation(transaction, current.id),
          changed: true,
        );
      });
    });
    if (result.changed) _projectLocationChanges.add(null);
    return result.location;
  }

  @override
  Future<List<ProjectLocationEvent>> listProjectLocationEvents(
    String locationId,
  ) async {
    validateUuid(locationId, 'Mahal kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      await _requireProjectLocation(database, locationId);
      final rows = await database.query(
        'project_location_events',
        where: 'location_id = ?',
        whereArgs: [locationId],
        orderBy: 'sequence ASC, id ASC',
      );
      return rows.map(_projectLocationEventFromRow).toList(growable: false);
    });
  }

  @override
  Future<List<AgendaLog>> listAgenda(AgendaQuery query) async {
    final bounds = CseTimeCodec.istanbulDayBounds(query.istanbulDay);
    final projectId = query.projectId;
    if (projectId != null) {
      validateUuid(projectId, 'Proje kimliği');
    }
    final search = query.literalSearch.trim();
    final where = <String>[
      query.archiveFilter == AgendaArchiveFilter.active
          ? 'o.archived_at IS NULL'
          : 'o.archived_at IS NOT NULL',
      'o.observed_at >= ?',
      'o.observed_at < ?',
    ];
    final arguments = <Object?>[bounds.start, bounds.endExclusive];
    if (projectId != null) {
      where.add('o.project_id = ?');
      arguments.add(projectId);
    }
    if (query.category != null) {
      where.add('o.category = ?');
      arguments.add(query.category!.storageValue);
    }
    if (search.isNotEmpty) {
      where.add('''
        instr(
          lower(o.description || ' ' || coalesce(o.location, '') || ' ' ||
            coalesce(l.display_name, '') || ' ' || coalesce(o.notes, '') ||
            ' ' || p.name),
          lower(?)
        ) > 0
      ''');
      arguments.add(search);
    }
    final orderBy = switch (query.sortOrder) {
      AgendaSortOrder.newestFirst =>
        'o.observed_at DESC, o.created_at DESC, o.id DESC',
      AgendaSortOrder.oldestFirst =>
        'o.observed_at ASC, o.created_at ASC, o.id ASC',
    };
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.rawQuery('''
        SELECT o.*, p.name AS project_name,
          l.display_name AS stable_location_name,
          l.archived_at AS stable_location_archived_at
        FROM field_observations o
        JOIN projects p ON p.id = o.project_id
        LEFT JOIN project_locations l
          ON l.id = o.location_id AND l.project_id = o.project_id
        WHERE ${where.join(' AND ')}
        ORDER BY $orderBy
      ''', arguments);
      return rows.map(_logFromRow).toList(growable: false);
    });
  }

  @override
  Future<AgendaLog> createAgendaLog(CreateAgendaLogCommand command) async {
    validateUuid(command.id, 'Log kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    final locationId = command.locationId;
    if (locationId != null) validateUuid(locationId, 'Mahal kimliği');
    validateCanonicalTimestamp(command.observedAt, 'Olay zamanı');
    final description = requiredTrimmed(
      command.description,
      'Kısa açıklama',
      maxLength: 500,
    );
    final location = optionalTrimmed(command.location, 'Mahál', maxLength: 200);
    final notes = optionalTrimmed(command.notes, 'Ayrıntılı not');
    final now = _readClockOnce();
    final observed = CseTimeCodec.decodeCanonicalUtc(command.observedAt);
    if (observed.isAfter(now)) {
      throw const AgendaValidationFailure('Gelecek tarihli olay kaydedilemez.');
    }
    final createdAt = CseTimeCodec.encodeUtc(now);
    for (final photo in command.photos) {
      validateUuid(photo.id, 'Fotoğraf kimliği');
      validateUuid(photo.eventId, 'Fotoğraf event kimliği');
      validateCanonicalTimestamp(photo.capturedAt, 'Fotoğraf çekim zamanı');
      optionalTrimmed(photo.description, 'Fotoğraf açıklaması', maxLength: 500);
    }
    final existing = await _withDatabase(now, (database) async {
      final rows = await database.rawQuery(
        '''
        SELECT o.*, p.name AS project_name,
          l.display_name AS stable_location_name,
          l.archived_at AS stable_location_archived_at
        FROM field_observations o
        JOIN projects p ON p.id = o.project_id
        LEFT JOIN project_locations l
          ON l.id = o.location_id AND l.project_id = o.project_id
        WHERE o.id = ? LIMIT 1
        ''',
        [command.id],
      );
      return rows.isEmpty ? null : _logFromRow(rows.single);
    });
    if (existing != null) {
      if (!_sameLogCommand(existing, command, description, location, notes)) {
        throw const AgendaValidationFailure(
          'Log kimliği başka bir içerikle kullanılıyor.',
        );
      }
      return existing;
    }
    final staged = <(AgendaPhotoDraft, StagedAgendaPhoto)>[];
    try {
      for (final photo in command.photos) {
        staged.add((
          photo,
          await attachmentStore.stage(
            logId: command.id,
            attachmentId: photo.id,
            originalFileName: photo.originalFileName,
            bytes: photo.bytes,
          ),
        ));
      }
      return await _withDatabase(now, (database) {
        return database.transaction((transaction) async {
          final projects = await transaction.query(
            'projects',
            where: 'id = ? AND archived_at IS NULL',
            whereArgs: [command.projectId],
            limit: 1,
          );
          if (projects.isEmpty) {
            throw const AgendaValidationFailure('Seçilen proje bulunamadı.');
          }
          final project = _projectFromRow(projects.single);
          final stableLocation = locationId == null
              ? null
              : await _requireActiveAgendaLocation(
                  transaction,
                  projectId: command.projectId,
                  locationId: locationId,
                );
          final storedLocation = stableLocation?.displayName ?? location;
          await transaction.insert('field_observations', {
            'id': command.id,
            'project_id': command.projectId,
            'observed_at': command.observedAt,
            'created_at': createdAt,
            'updated_at': createdAt,
            'category': command.category.storageValue,
            'description': description,
            'location': storedLocation,
            'location_id': locationId,
            'notes': notes,
            'revision': 1,
          });
          await transaction.insert('observation_events', {
            'id': command.eventId,
            'observation_id': command.id,
            'project_id': command.projectId,
            'event_type': 'created',
            'occurred_at': createdAt,
            'payload_json': jsonEncode({
              'category': command.category.storageValue,
              'description': description,
              'observed_at': command.observedAt,
            }),
          });
          for (final item in staged) {
            final photo = item.$1;
            final file = item.$2;
            await transaction.insert('agenda_log_attachments', {
              'id': photo.id,
              'observation_id': command.id,
              'project_id': command.projectId,
              'attachment_type': 'site_photo',
              'original_file_name': photo.originalFileName.trim(),
              'mime_type': file.mimeType,
              'byte_size': file.byteSize,
              'sha256': file.sha256Value,
              'relative_path': file.relativePath,
              'description': optionalTrimmed(
                photo.description,
                'Fotoğraf açıklaması',
                maxLength: 500,
              ),
              'captured_at': photo.capturedAt,
              'revision': 1,
              'created_at': createdAt,
              'updated_at': createdAt,
            });
            await transaction.insert('observation_events', {
              'id': photo.eventId,
              'observation_id': command.id,
              'project_id': command.projectId,
              'event_type': 'agenda_log.photo_attached',
              'occurred_at': createdAt,
              'payload_json': jsonEncode({
                'photo_id': photo.id,
                'mime_type': file.mimeType,
                'byte_size': file.byteSize,
                'sha256': file.sha256Value,
              }),
            });
          }
          return AgendaLog(
            id: command.id,
            projectId: command.projectId,
            projectName: project.name,
            observedAt: command.observedAt,
            createdAt: createdAt,
            updatedAt: createdAt,
            category: command.category,
            description: description,
            location: storedLocation,
            notes: notes,
            revision: 1,
            locationId: locationId,
            stableLocationName: stableLocation?.displayName,
            stableLocationArchivedAt: stableLocation?.archivedAt,
            archivedAt: null,
          );
        });
      });
    } on Object {
      for (final item in staged.reversed) {
        try {
          await attachmentStore.cleanup(item.$2.relativePath);
        } on Object {
          // The source transaction still fails closed; next diagnostics can
          // identify an unexpected orphan without creating a DB source row.
        }
      }
      rethrow;
    }
  }

  @override
  Future<AgendaLog> updateAgendaLog(UpdateAgendaLogCommand command) async {
    validateUuid(command.id, 'Log kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    final requestedLocationId = command.locationId;
    if (requestedLocationId != null) {
      validateUuid(requestedLocationId, 'Mahal kimliği');
    }
    validateCanonicalTimestamp(command.observedAt, 'Olay zamanı');
    if (command.expectedRevision < 1) {
      throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
    }
    final description = requiredTrimmed(
      command.description,
      'Kısa açıklama',
      maxLength: 500,
    );
    final location = optionalTrimmed(command.location, 'Mahal', maxLength: 200);
    final notes = optionalTrimmed(command.notes, 'Ayrıntılı not');
    final now = _readClockOnce();
    if (CseTimeCodec.decodeCanonicalUtc(command.observedAt).isAfter(now)) {
      throw const AgendaValidationFailure('Gelecek tarihli olay kaydedilemez.');
    }
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final current = await _requireAgendaLog(transaction, command.id);
        await _requireAgendaNotManagedByConcrete(transaction, command.id);
        if (current.archivedAt != null) {
          throw const AgendaValidationFailure(
            'Arşivlenen kayıt geri getirilmeden düzenlenemez.',
          );
        }
        if (current.revision != command.expectedRevision) {
          throw const AgendaValidationFailure(
            'Ajanda kaydı başka bir işlemde değişti; yeniden açın.',
          );
        }
        final priorEvent = await transaction.query(
          'observation_events',
          where: 'id = ?',
          whereArgs: [command.eventId],
          limit: 1,
        );
        if (priorEvent.isNotEmpty) {
          if (priorEvent.single['observation_id'] != current.id) {
            throw const AgendaValidationFailure(
              'Event kimliği başka bir Ajanda kaydında kullanılıyor.',
            );
          }
          return current;
        }
        final projects = await transaction.query(
          'projects',
          where: 'id = ? AND archived_at IS NULL',
          whereArgs: [command.projectId],
          limit: 1,
        );
        if (projects.isEmpty) {
          throw const AgendaValidationFailure('Seçilen proje bulunamadı.');
        }
        if (current.projectId != command.projectId) {
          final linked =
              Sqflite.firstIntValue(
                await transaction.rawQuery(
                  'SELECT count(*) FROM follow_up_items '
                  'WHERE observation_id = ?',
                  [command.id],
                ),
              ) ??
              0;
          if (linked > 0) {
            throw const AgendaValidationFailure(
              'Bağlı hatırlatıcı varken log projesi değiştirilemez.',
            );
          }
        }
        final preservesStableLocation =
            requestedLocationId != null &&
            requestedLocationId == current.locationId &&
            command.projectId == current.projectId;
        final stableLocation =
            requestedLocationId == null || preservesStableLocation
            ? null
            : await _requireActiveAgendaLocation(
                transaction,
                projectId: command.projectId,
                locationId: requestedLocationId,
              );
        final storedLocation = preservesStableLocation
            ? current.location
            : stableLocation?.displayName ?? location;
        final before = _agendaEventSnapshot(current);
        final after = <String, Object?>{
          'project_id': command.projectId,
          'observed_at': command.observedAt,
          'category': command.category.storageValue,
          'description': description,
          'location': storedLocation,
          'location_id': requestedLocationId,
          'notes': notes,
        };
        if (_mapsEqual(before, after)) return current;
        final changed = await transaction.update(
          'field_observations',
          {...after, 'updated_at': timestamp, 'revision': current.revision + 1},
          where: 'id = ? AND revision = ?',
          whereArgs: [command.id, current.revision],
        );
        if (changed != 1) {
          throw const AgendaValidationFailure(
            'Ajanda kaydı başka bir işlemde değişti; yeniden açın.',
          );
        }
        await transaction.insert('observation_events', {
          'id': command.eventId,
          'observation_id': command.id,
          'project_id': command.projectId,
          'event_type': 'agenda_log.updated',
          'occurred_at': timestamp,
          'payload_json': jsonEncode({'before': before, 'after': after}),
        });
        return _requireAgendaLog(transaction, command.id);
      });
    });
  }

  @override
  Future<AgendaLogDetail> mutateAgendaLogArchive(
    MutateAgendaLogArchiveCommand command,
  ) async {
    validateUuid(command.id, 'Log kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    if (command.expectedRevision < 1) {
      throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
    }
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final current = await _requireAgendaLog(transaction, command.id);
        await _requireAgendaNotManagedByConcrete(transaction, command.id);
        if (current.revision != command.expectedRevision) {
          throw const AgendaValidationFailure(
            'Ajanda kaydı başka bir işlemde değişti; yeniden açın.',
          );
        }
        final alreadyTarget = command.archive
            ? current.archivedAt != null
            : current.archivedAt == null;
        if (alreadyTarget) return;
        final priorEvent = await transaction.query(
          'observation_events',
          where: 'id = ?',
          whereArgs: [command.eventId],
          limit: 1,
        );
        if (priorEvent.isNotEmpty) {
          if (priorEvent.single['observation_id'] != current.id) {
            throw const AgendaValidationFailure(
              'Event kimliği başka bir Ajanda kaydında kullanılıyor.',
            );
          }
          return;
        }
        final changed = await transaction.update(
          'field_observations',
          {
            'archived_at': command.archive ? timestamp : null,
            'updated_at': timestamp,
            'revision': current.revision + 1,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [command.id, current.revision],
        );
        if (changed != 1) {
          throw const AgendaValidationFailure(
            'Ajanda kaydı başka bir işlemde değişti; yeniden açın.',
          );
        }
        await transaction.insert('observation_events', {
          'id': command.eventId,
          'observation_id': command.id,
          'project_id': current.projectId,
          'event_type': command.archive
              ? 'agenda_log.archived'
              : 'agenda_log.restored',
          'occurred_at': timestamp,
          'payload_json': jsonEncode({
            'archived_at': command.archive ? timestamp : null,
            'linked_reminders_unchanged': true,
          }),
        });
      });
    });
    return getAgendaLogDetail(command.id);
  }

  @override
  Future<AgendaLogDetail> attachAgendaPhoto(
    AttachAgendaPhotoCommand command,
  ) async {
    validateUuid(command.logId, 'Log kimliği');
    validateUuid(command.id, 'Fotoğraf kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateCanonicalTimestamp(command.capturedAt, 'Fotoğraf çekim zamanı');
    if (command.expectedLogRevision < 1) {
      throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
    }
    final description = optionalTrimmed(
      command.description,
      'Fotoğraf açıklaması',
      maxLength: 500,
    );
    final staged = await attachmentStore.stage(
      logId: command.logId,
      attachmentId: command.id,
      originalFileName: command.originalFileName,
      bytes: command.bytes,
    );
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    try {
      await _withDatabase(now, (database) {
        return database.transaction((transaction) async {
          final current = await _requireAgendaLog(transaction, command.logId);
          if (current.archivedAt != null) {
            throw const AgendaValidationFailure(
              'Arşivlenen kayda fotoğraf eklenemez.',
            );
          }
          if (current.revision != command.expectedLogRevision) {
            throw const AgendaValidationFailure(
              'Ajanda kaydı başka bir işlemde değişti; yeniden açın.',
            );
          }
          await transaction.insert('agenda_log_attachments', {
            'id': command.id,
            'observation_id': command.logId,
            'project_id': current.projectId,
            'attachment_type': 'site_photo',
            'original_file_name': command.originalFileName.trim(),
            'mime_type': staged.mimeType,
            'byte_size': staged.byteSize,
            'sha256': staged.sha256Value,
            'relative_path': staged.relativePath,
            'description': description,
            'captured_at': command.capturedAt,
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
          });
          final changed = await transaction.update(
            'field_observations',
            {'revision': current.revision + 1, 'updated_at': timestamp},
            where: 'id = ? AND revision = ?',
            whereArgs: [current.id, current.revision],
          );
          if (changed != 1) {
            throw const AgendaValidationFailure(
              'Ajanda kaydı başka bir işlemde değişti; yeniden açın.',
            );
          }
          await transaction.insert('observation_events', {
            'id': command.eventId,
            'observation_id': current.id,
            'project_id': current.projectId,
            'event_type': 'agenda_log.photo_attached',
            'occurred_at': timestamp,
            'payload_json': jsonEncode({
              'photo_id': command.id,
              'mime_type': staged.mimeType,
              'byte_size': staged.byteSize,
              'sha256': staged.sha256Value,
            }),
          });
        });
      });
    } on Object {
      await attachmentStore.cleanup(staged.relativePath);
      rethrow;
    }
    return getAgendaLogDetail(command.logId);
  }

  @override
  Future<AgendaLogDetail> archiveAgendaPhoto(
    ArchiveAgendaPhotoCommand command,
  ) async {
    validateUuid(command.logId, 'Log kimliği');
    validateUuid(command.photoId, 'Fotoğraf kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final current = await _requireAgendaLog(transaction, command.logId);
        if (current.revision != command.expectedLogRevision) {
          throw const AgendaValidationFailure(
            'Ajanda kaydı başka bir işlemde değişti; yeniden açın.',
          );
        }
        final rows = await transaction.query(
          'agenda_log_attachments',
          where: 'id = ? AND observation_id = ?',
          whereArgs: [command.photoId, command.logId],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw const AgendaValidationFailure('Fotoğraf bulunamadı.');
        }
        final photo = _agendaPhotoFromRow(rows.single);
        if (photo.revision != command.expectedPhotoRevision) {
          throw const AgendaValidationFailure(
            'Fotoğraf başka bir işlemde değişti; yeniden açın.',
          );
        }
        if (photo.archivedAt != null) return;
        await transaction.update(
          'agenda_log_attachments',
          {
            'archived_at': timestamp,
            'updated_at': timestamp,
            'revision': photo.revision + 1,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [photo.id, photo.revision],
        );
        await transaction.update(
          'field_observations',
          {'revision': current.revision + 1, 'updated_at': timestamp},
          where: 'id = ? AND revision = ?',
          whereArgs: [current.id, current.revision],
        );
        await transaction.insert('observation_events', {
          'id': command.eventId,
          'observation_id': current.id,
          'project_id': current.projectId,
          'event_type': 'agenda_log.photo_archived',
          'occurred_at': timestamp,
          'payload_json': jsonEncode({'photo_id': photo.id}),
        });
      });
    });
    return getAgendaLogDetail(command.logId);
  }

  @override
  Future<StoredAttachmentContent> readAgendaPhoto(String photoId) async {
    validateUuid(photoId, 'Fotoğraf kimliği');
    final now = _readClockOnce();
    final photo = await _withDatabase(now, (database) async {
      final rows = await database.query(
        'agenda_log_attachments',
        where: 'id = ? AND archived_at IS NULL',
        whereArgs: [photoId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const AgendaValidationFailure('Fotoğraf bulunamadı.');
      }
      return _agendaPhotoFromRow(rows.single);
    });
    return attachmentStore.read(
      photo.relativePath,
      photo.originalFileName,
      photo.sha256,
      photo.mimeType,
    );
  }

  @override
  Future<AgendaLogDetail> getAgendaLogDetail(String logId) async {
    validateUuid(logId, 'Log kimliği');
    final now = _readClockOnce();
    final detail = await _withDatabase(
      now,
      (database) => _loadAgendaDetail(database, logId),
    );
    return _withAgendaPhotoIntegrity(detail);
  }

  @override
  Future<ReminderSourceAgendaMedia> getReminderSourceAgendaMedia(
    String sourceLogId,
  ) async {
    validateUuid(sourceLogId, 'Kaynak log kimliği');
    final now = _readClockOnce();
    try {
      final raw = await _withDatabase(now, (database) async {
        final sourceRows = await database.query(
          'field_observations',
          columns: ['archived_at'],
          where: 'id = ?',
          whereArgs: [sourceLogId],
          limit: 1,
        );
        if (sourceRows.isEmpty) {
          throw const AgendaValidationFailure('Ajanda kaydı bulunamadı.');
        }
        final photos = await database.query(
          'agenda_log_attachments',
          where: 'observation_id = ? AND archived_at IS NULL',
          whereArgs: [sourceLogId],
          orderBy: 'created_at ASC, id ASC',
        );
        return (
          sourceLogArchivedAt: sourceRows.single['archived_at'] as String?,
          photos: photos.map(_agendaPhotoFromRow).toList(growable: false),
        );
      });
      return ReminderSourceAgendaMedia.loaded(
        sourceLogId: sourceLogId,
        sourceLogArchivedAt: raw.sourceLogArchivedAt,
        photos: await _inspectAgendaPhotos(raw.photos),
      );
    } on Object {
      return ReminderSourceAgendaMedia.unavailable(sourceLogId: sourceLogId);
    }
  }

  @override
  Future<MobileReminder> createReminder(CreateReminderCommand command) async {
    validateUuid(command.id, 'Hatırlatıcı kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    if (command.projectId case final projectId?) {
      validateUuid(projectId, 'Proje kimliği');
    }
    if (command.locationId case final locationId?) {
      validateUuid(locationId, 'Mahal kimliği');
      if (command.projectId == null) {
        throw const AgendaValidationFailure(
          'Stable mahal seçimi için proje zorunludur.',
        );
      }
    }
    if (command.sourceLogId case final sourceLogId?) {
      validateUuid(sourceLogId, 'Kaynak log kimliği');
      if (command.projectId == null) {
        throw const AgendaValidationFailure(
          'Kaynak Ajanda kaydı için proje zorunludur.',
        );
      }
    }
    final title = requiredTrimmed(
      command.title,
      'Hatırlatıcı metni',
      maxLength: 500,
    );
    final captureText = requiredTrimmed(
      command.captureText ?? title,
      'Hızlı yakalama metni',
      maxLength: 500,
    );
    final description = optionalTrimmed(command.description, 'Açıklama');
    final legacyLocation = optionalTrimmed(
      command.location,
      'Mahál',
      maxLength: 200,
    );
    final relatedPerson = optionalTrimmed(
      command.relatedPerson,
      'İlgili kişi',
      maxLength: 200,
    );
    final conditionText = optionalTrimmed(command.conditionText, 'Koşul/not');
    if (command.deadlineAt case final deadline?) {
      validateCanonicalTimestamp(deadline, 'Gerçek son tarih');
    }
    final now = _readClockOnce();
    final schedule = _resolveSchedule(command, now);
    final createdAt = CseTimeCodec.encodeUtc(now);
    final reminder = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        String? projectName;
        String? effectiveLocationId = command.locationId;
        String? location = legacyLocation;
        String? stableLocationName;
        String? stableLocationArchivedAt;
        if (command.projectId case final projectId?) {
          final projects = await transaction.query(
            'projects',
            where: 'id = ? AND archived_at IS NULL',
            whereArgs: [projectId],
            limit: 1,
          );
          if (projects.isEmpty) {
            throw const AgendaValidationFailure('Seçilen proje bulunamadı.');
          }
          projectName = _projectFromRow(projects.single).name;
        }
        if (command.sourceLogId case final sourceLogId?) {
          final sources = await transaction.query(
            'field_observations',
            columns: ['id', 'location_id'],
            where: 'id = ? AND project_id = ? AND archived_at IS NULL',
            whereArgs: [sourceLogId, command.projectId],
            limit: 1,
          );
          if (sources.isEmpty) {
            throw const AgendaValidationFailure(
              'Kaynak Ajanda kaydı proje ile eşleşmiyor.',
            );
          }
          effectiveLocationId ??= sources.single['location_id'] as String?;
        }
        if (effectiveLocationId case final locationId?) {
          final stable = command.locationId == null
              ? await _requireProjectLocation(transaction, locationId)
              : await _requireActiveAgendaLocation(
                  transaction,
                  projectId: command.projectId!,
                  locationId: locationId,
                );
          if (stable.projectId != command.projectId) {
            throw const AgendaValidationFailure(
              'Seçilen mahal aynı projeye ait olmalıdır.',
            );
          }
          location = stable.displayName;
          stableLocationName = stable.displayName;
          stableLocationArchivedAt = stable.archivedAt;
        }
        final existing = await transaction.rawQuery(
          '''
          SELECT f.*, p.name AS project_name,
            l.display_name AS stable_location_name,
            l.archived_at AS stable_location_archived_at
          FROM follow_up_items f
          LEFT JOIN projects p ON p.id = f.project_id
          LEFT JOIN project_locations l ON l.id = f.location_id
          WHERE f.id = ?
          LIMIT 1
        ''',
          [command.id],
        );
        if (existing.isNotEmpty) {
          final reminder = _reminderFromRow(existing.single);
          if (!_sameReminderCommand(
            reminder,
            command,
            captureText,
            title,
            description,
            location,
            relatedPerson,
            conditionText,
            schedule,
            effectiveLocationId,
          )) {
            throw const AgendaValidationFailure(
              'Hatırlatıcı kimliği başka bir içerikle kullanılıyor.',
            );
          }
          return reminder;
        }
        await transaction.insert('follow_up_items', {
          'id': command.id,
          'capture_text': captureText,
          'title': title,
          'description': description,
          'item_type': command.kind.storageValue,
          'status': schedule.status.storageValue,
          'project_id': command.projectId,
          'observation_id': command.sourceLogId,
          'location_id': effectiveLocationId,
          'location': location,
          'related_person': relatedPerson,
          'is_important': command.isImportant ? 1 : 0,
          'next_attention_at': schedule.nextAttentionAt,
          'all_day_local_date': schedule.allDayLocalDate,
          'deadline_at': command.deadlineAt,
          'condition_text': conditionText,
          'revision': 1,
          'created_at': createdAt,
          'updated_at': createdAt,
        });
        await beforeReminderEventInsert?.call(transaction);
        await transaction.insert('follow_up_events', {
          'id': command.eventId,
          'follow_up_id': command.id,
          'sequence': 1,
          'project_id': command.projectId,
          'source_observation_id': command.sourceLogId,
          'event_type': 'created',
          'occurred_at': createdAt,
          'payload_json': jsonEncode({
            'item_type': command.kind.storageValue,
            'next_attention_at': schedule.nextAttentionAt,
            'all_day_local_date': schedule.allDayLocalDate,
            'source_observation_id': command.sourceLogId,
            'location_id': effectiveLocationId,
            'status': schedule.status.storageValue,
          }),
        });
        final platformId = await _allocatePlatformNotificationId(
          transaction,
          command.id,
        );
        await transaction.insert('reminder_notification_bindings', {
          'reminder_id': command.id,
          'platform_notification_id': platformId,
          'scheduled_for': schedule.nextAttentionAt,
          'sync_state': schedule.nextAttentionAt == null
              ? NotificationSyncState.cancelled.storageValue
              : NotificationSyncState.unavailable.storageValue,
          'last_synced_at': createdAt,
          'safe_error_code': schedule.nextAttentionAt == null
              ? null
              : 'pending_sync',
        });
        return MobileReminder(
          id: command.id,
          projectId: command.projectId,
          projectName: projectName,
          sourceLogId: command.sourceLogId,
          captureText: captureText,
          title: title,
          description: description,
          kind: command.kind,
          status: schedule.status,
          locationId: effectiveLocationId,
          stableLocationName: stableLocationName,
          stableLocationArchivedAt: stableLocationArchivedAt,
          location: location,
          relatedPerson: relatedPerson,
          isImportant: command.isImportant,
          nextAttentionAt: schedule.nextAttentionAt,
          allDayLocalDate: schedule.allDayLocalDate,
          deadlineAt: command.deadlineAt,
          conditionText: conditionText,
          outcomeType: null,
          outcomeNote: null,
          createdAt: createdAt,
          updatedAt: createdAt,
          completedAt: null,
          cancelledAt: null,
          trashedAt: null,
          revision: 1,
        );
      });
    });
    await _reconcileNotificationsAt(
      now,
      requestPermission: schedule.nextAttentionAt != null,
    );
    return reminder;
  }

  @override
  Future<ReminderTodayOverview> getReminderTodayOverview() async {
    final now = _readClockOnce();
    final nowValue = CseTimeCodec.encodeUtc(now);
    final today = CseTimeCodec.istanbulDayKey(nowValue);
    final bounds = CseTimeCodec.istanbulDayBounds(today);
    return _withDatabase(now, (database) async {
      final rows = await database.rawQuery(
        '''
        SELECT f.*, p.name AS project_name,
          l.display_name AS stable_location_name,
          l.archived_at AS stable_location_archived_at
        FROM follow_up_items f
        LEFT JOIN projects p ON p.id = f.project_id
        LEFT JOIN project_locations l ON l.id = f.location_id
        WHERE f.trashed_at IS NULL
          AND (
            f.status = 'inbox'
            OR (
              f.status = 'active'
              AND (
                (f.next_attention_at IS NOT NULL
                  AND f.next_attention_at < ?)
                OR (f.all_day_local_date IS NOT NULL
                  AND f.all_day_local_date <= ?)
              )
            )
          )
        ORDER BY f.id ASC
        ''',
        [bounds.endExclusive, today],
      );
      return buildReminderTodayOverview(
        rows.map(_reminderFromRow),
        asOfUtc: now,
      );
    });
  }

  @override
  Future<List<MobileReminder>> listReminders(ReminderViewGroup group) async {
    final now = _readClockOnce();
    final today = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
    final bounds = CseTimeCodec.istanbulDayBounds(today);
    final tomorrow = CseTimeCodec.shiftIstanbulDay(today, 1);
    final tomorrowBounds = CseTimeCodec.istanbulDayBounds(tomorrow);
    final nowValue = CseTimeCodec.encodeUtc(now);
    final (where, arguments) = switch (group) {
      ReminderViewGroup.now => (
        "f.status = 'active' AND f.next_attention_at <= ?",
        <Object?>[nowValue],
      ),
      ReminderViewGroup.overdue => (
        "f.status = 'active' AND ("
            '(f.next_attention_at IS NOT NULL AND f.next_attention_at < ?) '
            'OR (f.all_day_local_date IS NOT NULL '
            'AND f.all_day_local_date < ?))',
        <Object?>[bounds.start, today],
      ),
      ReminderViewGroup.today => (
        "f.status = 'active' AND ("
            '(f.next_attention_at >= ? AND f.next_attention_at < ?) '
            'OR f.all_day_local_date = ?)',
        <Object?>[bounds.start, bounds.endExclusive, today],
      ),
      ReminderViewGroup.tomorrow => (
        "f.status = 'active' AND ("
            '(f.next_attention_at >= ? AND f.next_attention_at < ?) '
            'OR f.all_day_local_date = ?)',
        <Object?>[tomorrowBounds.start, tomorrowBounds.endExclusive, tomorrow],
      ),
      ReminderViewGroup.recheck => (
        "f.status = 'active' AND f.item_type = 'recheck'",
        <Object?>[],
      ),
      ReminderViewGroup.upcoming => (
        "f.status = 'active' AND ("
            'f.next_attention_at >= ? OR f.all_day_local_date > ?)',
        <Object?>[bounds.endExclusive, today],
      ),
      ReminderViewGroup.inbox => ('f.status = ?', <Object?>['inbox']),
      ReminderViewGroup.history => (
        "f.status IN ('completed', 'cancelled')",
        <Object?>[],
      ),
      ReminderViewGroup.trash => ('f.trashed_at IS NOT NULL', <Object?>[]),
    };
    return _withDatabase(now, (database) async {
      final visibilityWhere = group == ReminderViewGroup.trash
          ? where
          : 'f.trashed_at IS NULL AND ($where)';
      final orderBy = group == ReminderViewGroup.trash
          ? 'f.trashed_at DESC, f.updated_at DESC, f.id ASC'
          : '''
            CASE WHEN f.next_attention_at IS NULL THEN 1 ELSE 0 END,
            f.next_attention_at ASC,
            f.all_day_local_date ASC,
            f.is_important DESC,
            f.created_at ASC,
            f.id ASC
            ''';
      final rows = await database.rawQuery('''
        SELECT f.*, p.name AS project_name,
          l.display_name AS stable_location_name,
          l.archived_at AS stable_location_archived_at
        FROM follow_up_items f
        LEFT JOIN projects p ON p.id = f.project_id
        LEFT JOIN project_locations l ON l.id = f.location_id
        WHERE $visibilityWhere
        ORDER BY $orderBy
      ''', arguments);
      final reminders = rows.map(_reminderFromRow).toList(growable: false);
      return group == ReminderViewGroup.upcoming ||
              group == ReminderViewGroup.tomorrow
          ? _collapseAttendanceRemindersByProject(reminders)
          : reminders;
    });
  }

  @override
  Future<MobileReminder> getReminderDetail(String reminderId) async {
    validateUuid(reminderId, 'Hatırlatıcı kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.rawQuery(
        '''
        SELECT f.*, p.name AS project_name,
          l.display_name AS stable_location_name,
          l.archived_at AS stable_location_archived_at
        FROM follow_up_items f
        LEFT JOIN projects p ON p.id = f.project_id
        LEFT JOIN project_locations l ON l.id = f.location_id
        WHERE f.id = ?
        LIMIT 1
      ''',
        [reminderId],
      );
      if (rows.isEmpty) {
        throw const AgendaValidationFailure('Hatırlatıcı bulunamadı.');
      }
      return _reminderFromRow(rows.single);
    });
  }

  @override
  Future<ReminderDetail> getReminderLifecycleDetail(String reminderId) async {
    validateUuid(reminderId, 'Hatırlatıcı kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.rawQuery(
        '''
        SELECT f.*, p.name AS project_name,
          l.display_name AS stable_location_name,
          l.archived_at AS stable_location_archived_at
        FROM follow_up_items f
        LEFT JOIN projects p ON p.id = f.project_id
        LEFT JOIN project_locations l ON l.id = f.location_id
        WHERE f.id = ?
        LIMIT 1
        ''',
        [reminderId],
      );
      if (rows.isEmpty) {
        throw const AgendaValidationFailure('Hatırlatıcı bulunamadı.');
      }
      final eventRows = await database.query(
        'follow_up_events',
        where: 'follow_up_id = ?',
        whereArgs: [reminderId],
        orderBy: 'sequence ASC, id ASC',
      );
      final bindingRows = await database.query(
        'reminder_notification_bindings',
        where: 'reminder_id = ?',
        whereArgs: [reminderId],
        limit: 1,
      );
      if (bindingRows.isEmpty) {
        throw const AgendaValidationFailure(
          'Hatırlatıcı bildirim bağlantısı bulunamadı.',
        );
      }
      return ReminderDetail(
        reminder: _reminderFromRow(rows.single),
        events: eventRows.map(_reminderEventFromRow).toList(growable: false),
        notification: _notificationBindingFromRow(bindingRows.single),
      );
    });
  }

  @override
  Future<ReminderDeliveryDiagnostic> getReminderDeliveryDiagnostic(
    String reminderId,
  ) async {
    final now = _readClockOnce();
    final detail = await getReminderLifecycleDetail(reminderId);
    ReminderPlatformDiagnostic platform =
        const ReminderPlatformDiagnostic.unavailable();
    var nativePresent = false;
    try {
      final pending = await notificationGateway.pendingNotifications();
      nativePresent = pending.any(
        (item) =>
            item.platformId == detail.notification.platformNotificationId &&
            item.reminderId == reminderId &&
            item.scheduleComplete,
      );
      final gateway = notificationGateway;
      if (gateway is ReminderDeliveryControl) {
        platform = await (gateway as ReminderDeliveryControl)
            .deliveryDiagnostic(detail.notification.platformNotificationId);
      }
    } on Object {
      nativePresent = false;
    }
    final dueAt = detail.reminder.nextAttentionAt;
    final deliveredAt = _canonicalPlatformTime(
      platform.activeNotificationPostedAtUtc,
    );
    return ReminderDeliveryDiagnostic(
      safeReminderId: reminderId.substring(0, 8),
      scheduleKind: detail.notification.repeatIntervalMinutes == 60
          ? 'hourly'
          : 'one_shot',
      canonicalDueAt: dueAt,
      nativeSchedulePresent: nativePresent,
      lastReconciledAt: detail.notification.lastSyncedAt,
      permissionState: platform.permissionState,
      channelState: platform.channelState,
      exactAlarmState: platform.exactAlarmState,
      batteryOptimizationState: platform.batteryOptimizationState,
      backgroundRestrictionState: platform.backgroundRestrictionState,
      standbyBucket: platform.standbyBucket,
      bootRescheduleState: platform.bootRescheduleState,
      bootRescheduledAt: _canonicalPlatformTime(platform.bootRescheduledAtUtc),
      deliveredAt: deliveredAt,
      delayClass: _deliveryDelayClass(
        dueAt: dueAt,
        deliveredAt: deliveredAt,
        nativePresent: nativePresent,
        now: now,
      ),
      safeErrorCode: detail.notification.safeErrorCode,
    );
  }

  @override
  Future<void> retryReminderDelivery(String reminderId) async {
    validateUuid(reminderId, 'Hatırlatıcı kimliği');
    await getReminderDetail(reminderId);
    await reconcileNotifications(requestPermission: true);
  }

  @override
  Future<void> openReminderNotificationSettings() async {
    final gateway = notificationGateway;
    if (gateway is! ReminderDeliveryControl) {
      throw StateError('notification settings unavailable');
    }
    await (gateway as ReminderDeliveryControl).openNotificationSettings();
  }

  @override
  Future<void> openReminderBatteryOptimizationSettings() async {
    final gateway = notificationGateway;
    if (gateway is! ReminderDeliveryControl) {
      throw StateError('battery optimization settings unavailable');
    }
    await (gateway as ReminderDeliveryControl)
        .openBatteryOptimizationSettings();
  }

  @override
  Future<MobileReminder> mutateReminder(MutateReminderCommand command) async {
    validateUuid(command.reminderId, 'Hatırlatıcı kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    if (command.locationId case final locationId?) {
      validateUuid(locationId, 'Mahal kimliği');
    }
    if (command.expectedRevision < 1) {
      throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
    }
    final now = _readClockOnce();
    final result = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final rows = await transaction.rawQuery(
          '''
          SELECT f.*, p.name AS project_name,
            l.display_name AS stable_location_name,
            l.archived_at AS stable_location_archived_at
          FROM follow_up_items f
          LEFT JOIN projects p ON p.id = f.project_id
          LEFT JOIN project_locations l ON l.id = f.location_id
          WHERE f.id = ?
          LIMIT 1
          ''',
          [command.reminderId],
        );
        if (rows.isEmpty) {
          throw const AgendaValidationFailure('Hatırlatıcı bulunamadı.');
        }
        final current = _reminderFromRow(rows.single);
        if (command.action == ReminderMutationAction.schedule &&
            command.allDayLocalDate != null &&
            current.attendanceDayId != null) {
          throw const AgendaValidationFailure(
            'Puantaj tarafından yönetilen hatırlatıcı doğrudan tam gün planlanamaz.',
          );
        }
        if (command.expectedEarlierFromAttentionAt != null) {
          final priorEvents = await transaction.query(
            'follow_up_events',
            columns: ['follow_up_id', 'event_type', 'payload_json'],
            where: 'id = ?',
            whereArgs: [command.eventId],
            limit: 1,
          );
          if (priorEvents.isNotEmpty) {
            final prior = priorEvents.single;
            Object? decodedPayload;
            try {
              decodedPayload = jsonDecode(prior['payload_json']! as String);
            } on FormatException {
              decodedPayload = null;
            }
            final payload = decodedPayload is Map<String, dynamic>
                ? decodedPayload
                : null;
            if (prior['follow_up_id'] == current.id &&
                prior['event_type'] == 'rescheduled' &&
                payload?['earlier_from_attention_at'] ==
                    command.expectedEarlierFromAttentionAt &&
                payload?['next_attention_at'] == command.customAttentionAt &&
                payload?['confirmed_past_attention_at'] ==
                    command.confirmedPastAttentionAt) {
              return (reminder: current, changed: false);
            }
            throw const AgendaValidationFailure(
              'Event kimliği başka bir hatırlatıcı işlemi için kullanılmış.',
            );
          }
        }
        if (command.action == ReminderMutationAction.snoozeTomorrowMorning) {
          final priorEvents = await transaction.query(
            'follow_up_events',
            columns: ['follow_up_id', 'event_type'],
            where: 'id = ?',
            whereArgs: [command.eventId],
            limit: 1,
          );
          if (priorEvents.isNotEmpty) {
            final prior = priorEvents.single;
            if (prior['follow_up_id'] == current.id &&
                prior['event_type'] == 'snoozed') {
              return (reminder: current, changed: false);
            }
            throw const AgendaValidationFailure(
              'Event kimliği başka bir hatırlatıcı işlemi için kullanılmış.',
            );
          }
        }
        if (command.action == ReminderMutationAction.schedule &&
            command.expectedEarlierFromAttentionAt == null &&
            command.allDayLocalDate != null) {
          final priorEvents = await transaction.query(
            'follow_up_events',
            columns: ['follow_up_id', 'event_type', 'payload_json'],
            where: 'id = ?',
            whereArgs: [command.eventId],
            limit: 1,
          );
          if (priorEvents.isNotEmpty) {
            final prior = priorEvents.single;
            Object? decodedPayload;
            try {
              decodedPayload = jsonDecode(prior['payload_json']! as String);
            } on FormatException {
              decodedPayload = null;
            }
            final payload = decodedPayload is Map<String, dynamic>
                ? decodedPayload
                : null;
            if (prior['follow_up_id'] == current.id &&
                (prior['event_type'] == 'scheduled' ||
                    prior['event_type'] == 'rescheduled') &&
                payload?['next_attention_at'] == null &&
                payload?['all_day_local_date'] == command.allDayLocalDate &&
                payload?['status'] == ReminderStatus.active.storageValue &&
                payload?['revision'] == current.revision &&
                current.status == ReminderStatus.active &&
                current.nextAttentionAt == null &&
                current.allDayLocalDate == command.allDayLocalDate) {
              return (reminder: current, changed: false);
            }
            throw const AgendaValidationFailure(
              'Event kimliği başka bir hatırlatıcı işlemi için kullanılmış.',
            );
          }
        }
        if (current.revision != command.expectedRevision) {
          throw const AgendaValidationFailure(
            'Hatırlatıcı başka bir işlemle değişti. Ekranı yenileyin.',
          );
        }
        final values = <String, Object?>{
          'title': current.title,
          'description': current.description,
          'item_type': current.kind.storageValue,
          'status': current.status.storageValue,
          'project_id': current.projectId,
          'location_id': current.locationId,
          'location': current.location,
          'related_person': current.relatedPerson,
          'is_important': current.isImportant ? 1 : 0,
          'next_attention_at': current.nextAttentionAt,
          'all_day_local_date': current.allDayLocalDate,
          'deadline_at': current.deadlineAt,
          'condition_text': current.conditionText,
          'outcome_type': current.outcomeType?.storageValue,
          'outcome_note': current.outcomeNote,
          'completed_at': current.completedAt,
          'cancelled_at': current.cancelledAt,
          'trashed_at': current.trashedAt,
        };
        final eventType = _applyReminderMutation(
          values: values,
          current: current,
          command: command,
          now: now,
        );
        if (_sameReminderValues(current, values)) {
          return (reminder: current, changed: false);
        }
        if ((current.sourceLogId != null ||
                current.attendanceDayId != null ||
                current.concretePourId != null) &&
            values['project_id'] != current.projectId) {
          throw const AgendaValidationFailure(
            'Kaynak kaydın projesi değiştirilemez.',
          );
        }
        if (values['project_id'] case final String projectId) {
          validateUuid(projectId, 'Proje kimliği');
          final projects = await transaction.query(
            'projects',
            where: 'id = ? AND archived_at IS NULL',
            whereArgs: [projectId],
            limit: 1,
          );
          if (projects.isEmpty) {
            throw const AgendaValidationFailure('Seçilen proje bulunamadı.');
          }
        }
        if (command.action == ReminderMutationAction.updateDetails) {
          if (values['location_id'] case final String locationId) {
            final projectId = values['project_id'] as String?;
            if (projectId == null) {
              throw const AgendaValidationFailure(
                'Stable mahal seçimi için proje zorunludur.',
              );
            }
            final preservesExisting =
                locationId == current.locationId &&
                projectId == current.projectId;
            if (preservesExisting) {
              values['location'] = current.location;
            } else {
              final stable = await _requireActiveAgendaLocation(
                transaction,
                projectId: projectId,
                locationId: locationId,
              );
              values['location'] = stable.displayName;
            }
          }
        }
        final updatedAt = CseTimeCodec.encodeUtc(now);
        final nextRevision = current.revision + 1;
        final updated = await transaction.update(
          'follow_up_items',
          {...values, 'updated_at': updatedAt, 'revision': nextRevision},
          where: 'id = ? AND revision = ?',
          whereArgs: [current.id, current.revision],
        );
        if (updated != 1) {
          throw const AgendaValidationFailure(
            'Hatırlatıcı başka bir işlemle değişti. Ekranı yenileyin.',
          );
        }
        final sequenceRows = await transaction.rawQuery(
          '''
          SELECT COALESCE(MAX(sequence), 0) + 1 AS next_sequence
          FROM follow_up_events
          WHERE follow_up_id = ?
          ''',
          [current.id],
        );
        final sequence = sequenceRows.single['next_sequence']! as int;
        await beforeReminderEventInsert?.call(transaction);
        await transaction.insert('follow_up_events', {
          'id': command.eventId,
          'follow_up_id': current.id,
          'sequence': sequence,
          'project_id': values['project_id'],
          'source_observation_id': current.sourceLogId,
          'source_attendance_day_id': current.attendanceDayId,
          'source_concrete_pour_id': current.concretePourId,
          'event_type': eventType,
          'occurred_at': updatedAt,
          'payload_json': jsonEncode({
            'next_attention_at': values['next_attention_at'],
            'all_day_local_date': values['all_day_local_date'],
            'location_id': values['location_id'],
            if (eventType == 'details_updated')
              'before': {'location_id': current.locationId},
            if (eventType == 'details_updated')
              'after': {'location_id': values['location_id']},
            'trashed_at': values['trashed_at'],
            if (command.expectedEarlierFromAttentionAt != null)
              'earlier_from_attention_at':
                  command.expectedEarlierFromAttentionAt,
            if (command.expectedEarlierFromAttentionAt != null)
              'confirmed_past_attention_at': command.confirmedPastAttentionAt,
            if (eventType == 'restored_from_trash') 'restored_at': updatedAt,
            'outcome_type': values['outcome_type'],
            'revision': nextRevision,
            'status': values['status'],
            'source_observation_id': current.sourceLogId,
            'source_attendance_day_id': current.attendanceDayId,
            'source_concrete_pour_id': current.concretePourId,
          }),
        });
        final refreshed = await transaction.rawQuery(
          '''
          SELECT f.*, p.name AS project_name,
            l.display_name AS stable_location_name,
            l.archived_at AS stable_location_archived_at
          FROM follow_up_items f
          LEFT JOIN projects p ON p.id = f.project_id
          LEFT JOIN project_locations l ON l.id = f.location_id
          WHERE f.id = ?
          LIMIT 1
          ''',
          [current.id],
        );
        return (reminder: _reminderFromRow(refreshed.single), changed: true);
      });
    });
    if (result.changed) {
      final shouldRequest = command.action == ReminderMutationAction.schedule
          ? result.reminder.nextAttentionAt != null &&
                CseTimeCodec.decodeCanonicalUtc(
                  result.reminder.nextAttentionAt!,
                ).isAfter(now)
          : switch (command.action) {
              ReminderMutationAction.snooze15Minutes ||
              ReminderMutationAction.snooze1Hour ||
              ReminderMutationAction.snooze2Hours ||
              ReminderMutationAction.snooze3Hours ||
              ReminderMutationAction.snoozeTomorrowMorning => true,
              ReminderMutationAction.restoreFromTrash
                  when result.reminder.status == ReminderStatus.active &&
                      result.reminder.nextAttentionAt != null &&
                      CseTimeCodec.decodeCanonicalUtc(
                        result.reminder.nextAttentionAt!,
                      ).isAfter(now) =>
                true,
              _ => false,
            };
      await _reconcileNotificationsAt(now, requestPermission: shouldRequest);
    }
    return result.reminder;
  }

  @override
  Future<void> reconcileNotifications({bool requestPermission = false}) async {
    await _reconcileNotificationsAt(
      _readClockOnce(),
      requestPermission: requestPermission,
    );
  }

  @override
  Future<List<AppendOnlyEvent>> listObservationEvents(String logId) async {
    validateUuid(logId, 'Log kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.query(
        'observation_events',
        where: 'observation_id = ?',
        whereArgs: [logId],
        orderBy: 'occurred_at ASC, id ASC',
      );
      return rows
          .map(
            (row) => AppendOnlyEvent(
              id: row['id']! as String,
              recordId: row['observation_id']! as String,
              projectId: row['project_id']! as String,
              eventType: row['event_type']! as String,
              occurredAt: row['occurred_at']! as String,
              payloadJson: row['payload_json']! as String,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<List<AppendOnlyEvent>> listReminderEvents(String reminderId) async {
    validateUuid(reminderId, 'Hatırlatıcı kimliği');
    final now = _readClockOnce();
    return _withDatabase(now, (database) async {
      final rows = await database.query(
        'follow_up_events',
        where: 'follow_up_id = ?',
        whereArgs: [reminderId],
        orderBy: 'sequence ASC, id ASC',
      );
      return rows.map(_reminderEventFromRow).toList(growable: false);
    });
  }

  String _applyReminderMutation({
    required Map<String, Object?> values,
    required MobileReminder current,
    required MutateReminderCommand command,
    required DateTime now,
  }) {
    final nowValue = CseTimeCodec.encodeUtc(now);
    if (command.action != ReminderMutationAction.schedule &&
        (command.expectedEarlierFromAttentionAt != null ||
            command.confirmedPastAttentionAt != null)) {
      throw const AgendaValidationFailure(
        'Erkene alma intent’i yalnız planlama işleminde kullanılabilir.',
      );
    }
    if (command.action == ReminderMutationAction.snoozeTomorrowMorning) {
      final today = CseTimeCodec.istanbulDayKey(nowValue);
      if (!isReminderEligibleForTomorrowSnooze(current, istanbulToday: today)) {
        throw const AgendaValidationFailure(
          'Bu hatırlatıcı yarına ertelenemez. Tarihi veya kaynak akışı kontrol edin.',
        );
      }
    }
    void requireOpen() {
      if (current.status == ReminderStatus.completed ||
          current.status == ReminderStatus.cancelled) {
        throw const AgendaValidationFailure(
          'Terminal hatırlatıcı önce yeniden açılmalıdır.',
        );
      }
    }

    if (current.trashedAt != null &&
        command.action != ReminderMutationAction.restoreFromTrash &&
        command.action != ReminderMutationAction.moveToTrash) {
      throw const AgendaValidationFailure(
        'Geri dönüşüm kutusundaki kayıt önce geri yüklenmelidir.',
      );
    }

    switch (command.action) {
      case ReminderMutationAction.updateDetails:
        values['title'] = requiredTrimmed(
          command.title ?? current.title,
          'Başlık',
          maxLength: 500,
        );
        values['description'] = optionalTrimmed(
          command.description,
          'Açıklama',
        );
        values['item_type'] = (command.kind ?? current.kind).storageValue;
        values['project_id'] = command.projectId ?? current.projectId;
        values['location_id'] = command.locationId;
        values['location'] = optionalTrimmed(
          command.location,
          'Mahál',
          maxLength: 200,
        );
        values['related_person'] = optionalTrimmed(
          command.relatedPerson,
          'İlgili kişi',
          maxLength: 200,
        );
        values['is_important'] = (command.isImportant ?? current.isImportant)
            ? 1
            : 0;
        if (command.deadlineAt case final deadline?) {
          validateCanonicalTimestamp(deadline, 'Gerçek son tarih');
        }
        values['deadline_at'] = command.deadlineAt;
        values['condition_text'] = optionalTrimmed(
          command.conditionText,
          'Koşul/not',
        );
        return 'details_updated';
      case ReminderMutationAction.schedule:
        requireOpen();
        if (command.expectedEarlierFromAttentionAt != null) {
          return _applyQuickEarlierSchedule(
            values: values,
            current: current,
            command: command,
            now: now,
          );
        }
        if (command.confirmedPastAttentionAt != null) {
          throw const AgendaValidationFailure(
            'Geçmiş zaman onayı yalnız doğrulanmış erkene alma intent’iyle kullanılabilir.',
          );
        }
        final scheduleKind = command.schedule;
        if (scheduleKind == null ||
            scheduleKind == ReminderScheduleKind.inbox) {
          throw const AgendaValidationFailure(
            'Planlama için gelecek bir tarih/saat seçilmelidir.',
          );
        }
        final resolved = _resolveScheduleValues(
          scheduleKind,
          command.customAttentionAt,
          command.allDayLocalDate,
          now,
        );
        values['status'] = resolved.status.storageValue;
        values['next_attention_at'] = resolved.nextAttentionAt;
        values['all_day_local_date'] = resolved.allDayLocalDate;
        values['completed_at'] = null;
        values['cancelled_at'] = null;
        values['outcome_type'] = null;
        values['outcome_note'] = null;
        return current.nextAttentionAt == null &&
                current.allDayLocalDate == null
            ? 'scheduled'
            : 'rescheduled';
      case ReminderMutationAction.snooze15Minutes:
        requireOpen();
        values['status'] = ReminderStatus.active.storageValue;
        values['next_attention_at'] = CseTimeCodec.encodeUtc(
          now.add(const Duration(minutes: 15)),
        );
        values['all_day_local_date'] = null;
        return 'snoozed';
      case ReminderMutationAction.snooze1Hour:
        requireOpen();
        values['status'] = ReminderStatus.active.storageValue;
        values['next_attention_at'] = CseTimeCodec.encodeUtc(
          now.add(const Duration(hours: 1)),
        );
        values['all_day_local_date'] = null;
        return 'snoozed';
      case ReminderMutationAction.snooze2Hours:
        requireOpen();
        values['status'] = ReminderStatus.active.storageValue;
        values['next_attention_at'] = CseTimeCodec.encodeUtc(
          now.add(const Duration(hours: 2)),
        );
        values['all_day_local_date'] = null;
        return 'snoozed';
      case ReminderMutationAction.snooze3Hours:
        requireOpen();
        values['status'] = ReminderStatus.active.storageValue;
        values['next_attention_at'] = CseTimeCodec.encodeUtc(
          now.add(const Duration(hours: 3)),
        );
        values['all_day_local_date'] = null;
        return 'snoozed';
      case ReminderMutationAction.snoozeTomorrowMorning:
        requireOpen();
        values['status'] = ReminderStatus.active.storageValue;
        if (current.allDayLocalDate != null) {
          final today = CseTimeCodec.istanbulDayKey(
            CseTimeCodec.encodeUtc(now),
          );
          values['next_attention_at'] = null;
          values['all_day_local_date'] = CseTimeCodec.shiftIstanbulDay(
            today,
            1,
          );
        } else {
          values['next_attention_at'] = resolveReminderTomorrowMorningAt(now);
          values['all_day_local_date'] = null;
        }
        return 'snoozed';
      case ReminderMutationAction.moveToInbox:
        requireOpen();
        values['status'] = ReminderStatus.inbox.storageValue;
        values['next_attention_at'] = null;
        values['all_day_local_date'] = null;
        return 'moved_to_inbox';
      case ReminderMutationAction.complete:
        requireOpen();
        values['status'] = ReminderStatus.completed.storageValue;
        values['completed_at'] = nowValue;
        values['cancelled_at'] = null;
        values['outcome_type'] =
            (command.outcomeType ?? ReminderOutcomeType.completed).storageValue;
        values['outcome_note'] = optionalTrimmed(
          command.outcomeNote,
          'Sonuç notu',
        );
        return 'completed';
      case ReminderMutationAction.cancel:
        requireOpen();
        values['status'] = ReminderStatus.cancelled.storageValue;
        values['completed_at'] = null;
        values['cancelled_at'] = nowValue;
        values['outcome_type'] =
            ReminderOutcomeType.noLongerNeeded.storageValue;
        values['outcome_note'] = optionalTrimmed(
          command.outcomeNote,
          'İptal notu',
        );
        return 'cancelled';
      case ReminderMutationAction.reopen:
        if (current.status != ReminderStatus.completed &&
            current.status != ReminderStatus.cancelled) {
          return 'reopened';
        }
        values['status'] =
            current.nextAttentionAt == null && current.allDayLocalDate == null
            ? ReminderStatus.inbox.storageValue
            : ReminderStatus.active.storageValue;
        values['completed_at'] = null;
        values['cancelled_at'] = null;
        values['outcome_type'] = null;
        values['outcome_note'] = null;
        return 'reopened';
      case ReminderMutationAction.moveToTrash:
        if (current.trashedAt != null) return 'trashed';
        values['trashed_at'] = nowValue;
        return 'trashed';
      case ReminderMutationAction.restoreFromTrash:
        if (current.trashedAt == null) return 'restored_from_trash';
        values['trashed_at'] = null;
        return 'restored_from_trash';
    }
  }

  String _applyQuickEarlierSchedule({
    required Map<String, Object?> values,
    required MobileReminder current,
    required MutateReminderCommand command,
    required DateTime now,
  }) {
    final earlierFrom = command.expectedEarlierFromAttentionAt!;
    final selectedAt = command.customAttentionAt;
    if (command.schedule != ReminderScheduleKind.custom ||
        selectedAt == null ||
        command.allDayLocalDate != null ||
        !isReminderEligibleForQuickEarlier(current)) {
      throw const AgendaValidationFailure(
        'Bu hatırlatıcı hızlı biçimde erkene alınamaz.',
      );
    }
    validateCanonicalTimestamp(earlierFrom, 'Mevcut hatırlatıcı zamanı');
    validateCanonicalTimestamp(selectedAt, 'Yeni hatırlatıcı zamanı');
    if (current.nextAttentionAt != earlierFrom) {
      throw const AgendaValidationFailure(
        'Gösterilen mevcut zaman artık geçerli değil. Ekranı yenileyin.',
      );
    }
    final currentAt = CseTimeCodec.decodeCanonicalUtc(earlierFrom);
    final candidateAt = CseTimeCodec.decodeCanonicalUtc(selectedAt);
    if (!candidateAt.isBefore(currentAt)) {
      throw const AgendaValidationFailure(
        'Yeni zaman mevcut zamandan daha erken olmalıdır.',
      );
    }
    final confirmedPast = command.confirmedPastAttentionAt;
    if (confirmedPast != null) {
      validateCanonicalTimestamp(confirmedPast, 'Onaylanan geçmiş zaman');
      if (confirmedPast != selectedAt) {
        throw const AgendaValidationFailure(
          'Geçmiş zaman onayı seçilen exact zamanla eşleşmiyor.',
        );
      }
    }
    if (!candidateAt.isAfter(now)) {
      if (confirmedPast != selectedAt) {
        throw ReminderPastAttentionConfirmationRequired(
          earlierFromAttentionAt: earlierFrom,
          selectedAttentionAt: selectedAt,
        );
      }
    } else if (confirmedPast != null) {
      throw const AgendaValidationFailure(
        'Gelecek zaman için geçmiş zaman onayı kullanılamaz.',
      );
    }
    values['status'] = ReminderStatus.active.storageValue;
    values['next_attention_at'] = selectedAt;
    values['all_day_local_date'] = null;
    values['completed_at'] = null;
    values['cancelled_at'] = null;
    values['outcome_type'] = null;
    values['outcome_note'] = null;
    return 'rescheduled';
  }

  bool _sameReminderValues(
    MobileReminder current,
    Map<String, Object?> values,
  ) {
    return values['title'] == current.title &&
        values['description'] == current.description &&
        values['item_type'] == current.kind.storageValue &&
        values['status'] == current.status.storageValue &&
        values['project_id'] == current.projectId &&
        values['location_id'] == current.locationId &&
        values['location'] == current.location &&
        values['related_person'] == current.relatedPerson &&
        values['is_important'] == (current.isImportant ? 1 : 0) &&
        values['next_attention_at'] == current.nextAttentionAt &&
        values['all_day_local_date'] == current.allDayLocalDate &&
        values['deadline_at'] == current.deadlineAt &&
        values['condition_text'] == current.conditionText &&
        values['outcome_type'] == current.outcomeType?.storageValue &&
        values['outcome_note'] == current.outcomeNote &&
        values['completed_at'] == current.completedAt &&
        values['cancelled_at'] == current.cancelledAt &&
        values['trashed_at'] == current.trashedAt;
  }

  Future<void> _reconcileNotificationsAt(
    DateTime now, {
    required bool requestPermission,
  }) async {
    final work = await _withDatabase(now, (database) async {
      final rows = await database.rawQuery('''
        SELECT
          f.*, p.name AS project_name,
          l.display_name AS stable_location_name,
          l.archived_at AS stable_location_archived_at,
          b.platform_notification_id,
          b.scheduled_for AS binding_scheduled_for,
          b.sync_state,
          b.last_synced_at,
          b.safe_error_code,
          b.repeat_interval_minutes
        FROM follow_up_items f
        LEFT JOIN projects p ON p.id = f.project_id
        LEFT JOIN project_locations l ON l.id = f.location_id
        JOIN reminder_notification_bindings b ON b.reminder_id = f.id
        ORDER BY
          CASE WHEN f.next_attention_at IS NULL THEN 1 ELSE 0 END,
          f.next_attention_at ASC,
          f.is_important DESC,
          f.created_at ASC,
          f.id ASC
      ''');
      return rows
          .map(
            (row) => _NotificationWorkItem(
              reminder: _reminderFromRow(row),
              binding: _notificationBindingFromJoinedRow(row),
            ),
          )
          .toList(growable: false);
    });
    if (work.isEmpty) return;
    final dispositions = {
      for (final item in work) item: _notificationDisposition(item, now),
    };
    final eligible = work
        .where(
          (item) => dispositions[item] == _NotificationDisposition.schedulable,
        )
        .toList(growable: false);
    final preservedDeliveredOneTime = work
        .where(
          (item) =>
              dispositions[item] ==
              _NotificationDisposition.preserveDeliveredOneTime,
        )
        .toList(growable: false);
    final terminalToClean = work
        .where(
          (item) =>
              dispositions[item] == _NotificationDisposition.terminal &&
              _terminalNotificationNeedsCleanup(item),
        )
        .toList(growable: false);
    NotificationPermissionState permission;
    try {
      await notificationGateway.initialize();
      permission = requestPermission
          ? await notificationGateway.requestPermission()
          : await notificationGateway.permissionStatus();
    } on Object {
      await _writeBindingUpdates(now, [
        ...eligible.map(
          (item) => _BindingUpdate(
            reminderId: item.reminder.id,
            scheduledFor: item.reminder.nextAttentionAt,
            state: NotificationSyncState.unavailable,
            safeErrorCode: 'plugin_unavailable',
          ),
        ),
        ...terminalToClean.map(
          (item) => _BindingUpdate(
            reminderId: item.reminder.id,
            state: NotificationSyncState.cancelled,
          ),
        ),
      ]);
      return;
    }
    if (permission != NotificationPermissionState.granted) {
      if (permission == NotificationPermissionState.exactAlarmDenied) {
        await _preserveInexactFallbacks(
          now,
          eligible,
          preservedDeliveredOneTime,
          terminalToClean,
        );
        return;
      }
      for (final item in terminalToClean) {
        try {
          await notificationGateway.cancel(item.binding.platformNotificationId);
        } on Object {
          // A terminal reminder remains visible and a later retry cleans up.
        }
      }
      final safeCode = switch (permission) {
        NotificationPermissionState.denied => 'permission_denied',
        NotificationPermissionState.channelDisabled =>
          'notification_channel_disabled',
        NotificationPermissionState.unavailable => 'platform_unavailable',
        NotificationPermissionState.exactAlarmDenied =>
          'exact_alarm_permission_required',
        NotificationPermissionState.granted => null,
      };
      await _writeBindingUpdates(now, [
        ...eligible.map(
          (item) => _BindingUpdate(
            reminderId: item.reminder.id,
            scheduledFor: item.reminder.nextAttentionAt,
            state:
                permission == NotificationPermissionState.denied ||
                    permission == NotificationPermissionState.channelDisabled
                ? NotificationSyncState.permissionDenied
                : NotificationSyncState.unavailable,
            safeErrorCode: safeCode,
          ),
        ),
        ...terminalToClean.map(
          (item) => _BindingUpdate(
            reminderId: item.reminder.id,
            state: NotificationSyncState.cancelled,
          ),
        ),
      ]);
      return;
    }
    List<PendingReminderNotification> pending;
    try {
      pending = await notificationGateway.pendingNotifications();
    } on Object {
      await _writeBindingUpdates(now, [
        ...eligible.map(
          (item) => _BindingUpdate(
            reminderId: item.reminder.id,
            scheduledFor: item.reminder.nextAttentionAt,
            state: NotificationSyncState.failed,
            safeErrorCode: 'pending_query_failed',
          ),
        ),
        ...terminalToClean.map(
          (item) => _BindingUpdate(
            reminderId: item.reminder.id,
            state: NotificationSyncState.cancelled,
          ),
        ),
      ]);
      return;
    }
    final capacity = notificationGateway.maximumPendingNotifications;
    final desired = <_NotificationWorkItem>[];
    final capacityLimited = <_NotificationWorkItem>[];
    var usedSlots = 0;
    for (final item in eligible) {
      final slotCost = notificationGateway.pendingNotificationSlotCost(
        item.binding.repeatIntervalMinutes,
      );
      if (slotCost < 1 || usedSlots + slotCost > capacity) {
        capacityLimited.add(item);
        continue;
      }
      desired.add(item);
      usedSlots += slotCost;
    }
    final desiredByPlatformId = {
      for (final item in desired) item.binding.platformNotificationId: item,
    };
    final preservedByPlatformId = {
      for (final item in preservedDeliveredOneTime)
        item.binding.platformNotificationId: item,
    };
    final validPendingIds = <int>{};
    final cancelledPendingIds = <int>{};
    for (final item in pending) {
      final expected = desiredByPlatformId[item.platformId];
      if (expected != null &&
          expected.reminder.id == item.reminderId &&
          item.scheduleComplete &&
          validPendingIds.add(item.platformId)) {
        continue;
      }
      final preserved = preservedByPlatformId[item.platformId];
      if (preserved != null &&
          preserved.reminder.id == item.reminderId &&
          item.scheduleComplete) {
        continue;
      }
      try {
        await notificationGateway.cancel(item.platformId);
        cancelledPendingIds.add(item.platformId);
      } on Object {
        // A later bootstrap retries orphan cleanup.
      }
    }
    final updates = <_BindingUpdate>[];
    for (final item in desired) {
      final reminder = item.reminder;
      final binding = item.binding;
      final scheduledFor = reminder.nextAttentionAt!;
      final pendingIsCurrent =
          validPendingIds.contains(binding.platformNotificationId) &&
          binding.scheduledFor == scheduledFor &&
          binding.safeErrorCode == null;
      if (pendingIsCurrent) {
        updates.add(
          _BindingUpdate(
            reminderId: reminder.id,
            scheduledFor: scheduledFor,
            state: NotificationSyncState.scheduled,
          ),
        );
        continue;
      }
      try {
        await notificationGateway.cancel(binding.platformNotificationId);
        await notificationGateway.schedule(
          ReminderNotificationRequest(
            platformId: binding.platformNotificationId,
            reminderId: reminder.id,
            title: reminder.title,
            body: reminder.description ?? reminder.captureText,
            scheduledAtUtc: scheduledFor,
            repeatIntervalMinutes: binding.repeatIntervalMinutes,
          ),
        );
        final verified = await notificationGateway.pendingNotifications();
        final nativeSchedulePresent = verified.any(
          (pending) =>
              pending.platformId == binding.platformNotificationId &&
              pending.reminderId == reminder.id &&
              pending.scheduleComplete,
        );
        if (!nativeSchedulePresent) {
          throw StateError('native schedule missing after schedule');
        }
        updates.add(
          _BindingUpdate(
            reminderId: reminder.id,
            scheduledFor: scheduledFor,
            state: NotificationSyncState.scheduled,
          ),
        );
      } on Object {
        updates.add(
          _BindingUpdate(
            reminderId: reminder.id,
            scheduledFor: scheduledFor,
            state: NotificationSyncState.failed,
            safeErrorCode: 'native_schedule_failed',
          ),
        );
      }
    }
    for (final item in capacityLimited) {
      try {
        await notificationGateway.cancel(item.binding.platformNotificationId);
      } on Object {
        // Capacity state remains visible and next bootstrap retries cleanup.
      }
      updates.add(
        _BindingUpdate(
          reminderId: item.reminder.id,
          scheduledFor: item.reminder.nextAttentionAt,
          state: NotificationSyncState.unavailable,
          safeErrorCode: 'platform_capacity',
        ),
      );
    }
    for (final item in terminalToClean) {
      try {
        if (!cancelledPendingIds.contains(
          item.binding.platformNotificationId,
        )) {
          await notificationGateway.cancel(item.binding.platformNotificationId);
        }
        updates.add(
          _BindingUpdate(
            reminderId: item.reminder.id,
            state: NotificationSyncState.cancelled,
          ),
        );
      } on Object {
        updates.add(
          _BindingUpdate(
            reminderId: item.reminder.id,
            state: NotificationSyncState.failed,
            safeErrorCode: 'cancel_failed',
          ),
        );
      }
    }
    await _writeBindingUpdates(now, updates);
  }

  _NotificationDisposition _notificationDisposition(
    _NotificationWorkItem item,
    DateTime now,
  ) {
    final reminder = item.reminder;
    if (reminder.trashedAt != null ||
        reminder.status != ReminderStatus.active ||
        reminder.nextAttentionAt == null) {
      return _NotificationDisposition.terminal;
    }
    final dueAt = CseTimeCodec.decodeCanonicalUtc(reminder.nextAttentionAt!);
    if (dueAt.isAfter(now)) return _NotificationDisposition.schedulable;

    // Trash cancellation clears scheduledFor. An overdue repeat may keep an
    // existing native chain, but a cancelled chain must not restart later.
    if (item.binding.repeatIntervalMinutes != null) {
      return item.binding.scheduledFor == reminder.nextAttentionAt
          ? _NotificationDisposition.schedulable
          : _NotificationDisposition.terminal;
    }
    return item.binding.scheduledFor == reminder.nextAttentionAt
        ? _NotificationDisposition.preserveDeliveredOneTime
        : _NotificationDisposition.terminal;
  }

  bool _terminalNotificationNeedsCleanup(_NotificationWorkItem item) {
    return item.binding.scheduledFor != null ||
        item.binding.syncState != NotificationSyncState.cancelled ||
        item.binding.safeErrorCode != null;
  }

  Future<void> _preserveInexactFallbacks(
    DateTime now,
    List<_NotificationWorkItem> eligible,
    List<_NotificationWorkItem> preservedDeliveredOneTime,
    List<_NotificationWorkItem> terminalToClean,
  ) async {
    List<PendingReminderNotification> pending;
    try {
      pending = await notificationGateway.pendingNotifications();
    } on Object {
      pending = const [];
    }
    final eligibleByPlatformId = {
      for (final item in eligible) item.binding.platformNotificationId: item,
    };
    final preservedByPlatformId = {
      for (final item in preservedDeliveredOneTime)
        item.binding.platformNotificationId: item,
    };
    final valid = <int>{};
    final cancelledPendingIds = <int>{};
    for (final item in pending) {
      final expected = eligibleByPlatformId[item.platformId];
      if (expected != null &&
          expected.reminder.id == item.reminderId &&
          item.scheduleComplete &&
          expected.binding.scheduledFor == expected.reminder.nextAttentionAt &&
          valid.add(item.platformId)) {
        continue;
      }
      final preserved = preservedByPlatformId[item.platformId];
      if (preserved != null &&
          preserved.reminder.id == item.reminderId &&
          item.scheduleComplete) {
        continue;
      }
      try {
        await notificationGateway.cancel(item.platformId);
        cancelledPendingIds.add(item.platformId);
      } on Object {
        // A later reconciliation retries privacy-safe orphan cleanup.
      }
    }
    final updates = <_BindingUpdate>[];
    for (final item in eligible) {
      var safeCode = 'exact_alarm_permission_required';
      if (!valid.contains(item.binding.platformNotificationId)) {
        final gateway = notificationGateway;
        try {
          await notificationGateway.cancel(item.binding.platformNotificationId);
          if (gateway is! ReminderDeliveryControl) {
            throw StateError('fallback unavailable');
          }
          await (gateway as ReminderDeliveryControl).scheduleInexactFallback(
            ReminderNotificationRequest(
              platformId: item.binding.platformNotificationId,
              reminderId: item.reminder.id,
              title: item.reminder.title,
              body: item.reminder.description ?? item.reminder.captureText,
              scheduledAtUtc: item.reminder.nextAttentionAt!,
              repeatIntervalMinutes: item.binding.repeatIntervalMinutes,
            ),
          );
          final verified = await notificationGateway.pendingNotifications();
          if (!verified.any(
            (pending) =>
                pending.platformId == item.binding.platformNotificationId &&
                pending.reminderId == item.reminder.id &&
                pending.scheduleComplete,
          )) {
            throw StateError('fallback schedule missing');
          }
        } on Object {
          safeCode = 'exact_alarm_and_fallback_unavailable';
        }
      }
      updates.add(
        _BindingUpdate(
          reminderId: item.reminder.id,
          scheduledFor: item.reminder.nextAttentionAt,
          state: NotificationSyncState.unavailable,
          safeErrorCode: safeCode,
        ),
      );
    }
    for (final item in terminalToClean) {
      try {
        if (!cancelledPendingIds.contains(
          item.binding.platformNotificationId,
        )) {
          await notificationGateway.cancel(item.binding.platformNotificationId);
        }
      } on Object {
        // A later reconciliation retries terminal cleanup.
      }
      updates.add(
        _BindingUpdate(
          reminderId: item.reminder.id,
          state: NotificationSyncState.cancelled,
        ),
      );
    }
    await _writeBindingUpdates(now, updates);
  }

  Future<void> _writeBindingUpdates(
    DateTime now,
    Iterable<_BindingUpdate> updates,
  ) async {
    final values = updates.toList(growable: false);
    if (values.isEmpty) return;
    final syncedAt = CseTimeCodec.encodeUtc(now);
    await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        for (final update in values) {
          final previousRows = await transaction.rawQuery(
            '''
            SELECT
              b.sync_state, b.scheduled_for,
              f.project_id, f.observation_id, f.attendance_day_id,
              f.concrete_pour_id
            FROM reminder_notification_bindings b
            JOIN follow_up_items f ON f.id = b.reminder_id
            WHERE b.reminder_id = ?
            LIMIT 1
            ''',
            [update.reminderId],
          );
          if (previousRows.isEmpty) continue;
          final previous = previousRows.single;
          await transaction.update(
            'reminder_notification_bindings',
            {
              'scheduled_for': update.scheduledFor,
              'sync_state': update.state.storageValue,
              'last_synced_at': syncedAt,
              'safe_error_code': update.safeErrorCode,
            },
            where: 'reminder_id = ?',
            whereArgs: [update.reminderId],
          );
          final stateChanged =
              previous['sync_state'] != update.state.storageValue ||
              previous['scheduled_for'] != update.scheduledFor;
          final eventType = switch (update.state) {
            NotificationSyncState.scheduled when stateChanged =>
              'notification_scheduled',
            NotificationSyncState.cancelled when stateChanged =>
              'notification_cancelled',
            _ => null,
          };
          if (eventType == null) continue;
          final sequenceRows = await transaction.rawQuery(
            '''
            SELECT COALESCE(MAX(sequence), 0) + 1 AS next_sequence
            FROM follow_up_events
            WHERE follow_up_id = ?
            ''',
            [update.reminderId],
          );
          await transaction.insert('follow_up_events', {
            'id': RecordId.randomUuid(),
            'follow_up_id': update.reminderId,
            'sequence': sequenceRows.single['next_sequence']! as int,
            'project_id': previous['project_id'],
            'source_observation_id': previous['observation_id'],
            'source_attendance_day_id': previous['attendance_day_id'],
            'source_concrete_pour_id': previous['concrete_pour_id'],
            'event_type': eventType,
            'occurred_at': syncedAt,
            'payload_json': jsonEncode({'scheduled_for': update.scheduledFor}),
          });
        }
      });
    });
  }

  Future<int> _allocatePlatformNotificationId(
    Transaction transaction,
    String reminderId,
  ) async {
    var candidate = 2166136261;
    for (final value in reminderId.codeUnits) {
      candidate ^= value;
      candidate = (candidate * 16777619) & 0x7fffffff;
    }
    if (candidate == 0) candidate = 1;
    for (var attempts = 0; attempts < 2147483647; attempts += 1) {
      final collision = await transaction.query(
        'reminder_notification_bindings',
        columns: ['reminder_id'],
        where: 'platform_notification_id = ?',
        whereArgs: [candidate],
        limit: 1,
      );
      if (collision.isEmpty || collision.single['reminder_id'] == reminderId) {
        return candidate;
      }
      candidate = candidate == 2147483647 ? 1 : candidate + 1;
    }
    throw const AgendaValidationFailure(
      'Bildirim kimliği güvenli biçimde ayrılamadı.',
    );
  }

  Future<AgendaLog> _requireAgendaLog(
    DatabaseExecutor database,
    String logId,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT o.*, p.name AS project_name,
        l.display_name AS stable_location_name,
        l.archived_at AS stable_location_archived_at
      FROM field_observations o
      JOIN projects p ON p.id = o.project_id
      LEFT JOIN project_locations l
        ON l.id = o.location_id AND l.project_id = o.project_id
      WHERE o.id = ? LIMIT 1
      ''',
      [logId],
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Ajanda kaydı bulunamadı.');
    }
    return _logFromRow(rows.single);
  }

  Future<AgendaLogDetail> _loadAgendaDetail(
    DatabaseExecutor database,
    String logId,
  ) async {
    final log = await _requireAgendaLog(database, logId);
    final reminders = await database.rawQuery(
      '''
      SELECT f.*, p.name AS project_name,
        l.display_name AS stable_location_name,
        l.archived_at AS stable_location_archived_at
      FROM follow_up_items f
      LEFT JOIN projects p ON p.id = f.project_id
      LEFT JOIN project_locations l ON l.id = f.location_id
      WHERE f.observation_id = ? AND f.trashed_at IS NULL
      ORDER BY f.created_at ASC, f.id ASC
      ''',
      [logId],
    );
    final photos = await database.query(
      'agenda_log_attachments',
      where: 'observation_id = ? AND archived_at IS NULL',
      whereArgs: [logId],
      orderBy: 'created_at ASC, id ASC',
    );
    final events = await database.query(
      'observation_events',
      where: 'observation_id = ?',
      whereArgs: [logId],
      orderBy: 'occurred_at ASC, id ASC',
    );
    final managedLinks = await database.query(
      'concrete_pour_context_links',
      columns: ['concrete_pour_id'],
      where: 'agenda_log_id = ?',
      whereArgs: [logId],
      limit: 1,
    );
    return AgendaLogDetail(
      log: log,
      reminders: reminders.map(_reminderFromRow).toList(growable: false),
      photos: photos.map(_agendaPhotoFromRow).toList(growable: false),
      events: events.map(_observationEventFromRow).toList(growable: false),
      managedConcretePourId: managedLinks.isEmpty
          ? null
          : managedLinks.single['concrete_pour_id']! as String,
    );
  }

  Future<AgendaLogDetail> _withAgendaPhotoIntegrity(
    AgendaLogDetail detail,
  ) async {
    final photos = await _inspectAgendaPhotos(detail.photos);
    return AgendaLogDetail(
      log: detail.log,
      reminders: detail.reminders,
      photos: photos,
      events: detail.events,
      managedConcretePourId: detail.managedConcretePourId,
    );
  }

  Future<void> _requireAgendaNotManagedByConcrete(
    DatabaseExecutor database,
    String logId,
  ) async {
    final links = await database.query(
      'concrete_pour_context_links',
      columns: ['concrete_pour_id'],
      where: 'agenda_log_id = ?',
      whereArgs: [logId],
      limit: 1,
    );
    if (links.isNotEmpty) {
      throw const AgendaValidationFailure(
        'Bu Ajanda kaydı Beton paketi tarafından yönetiliyor; '
        'ana kayıt Beton paketinden değiştirilmelidir.',
      );
    }
  }

  Future<List<AgendaLogPhoto>> _inspectAgendaPhotos(
    Iterable<AgendaLogPhoto> values,
  ) async {
    final photos = <AgendaLogPhoto>[];
    for (final photo in values) {
      AgendaAttachmentIntegrity integrity;
      try {
        integrity = await attachmentStore.inspect(
          photo.relativePath,
          photo.sha256,
          photo.mimeType,
        );
      } on Object {
        integrity = AgendaAttachmentIntegrity.missing;
      }
      photos.add(_agendaPhotoWithIntegrity(photo, integrity));
    }
    return List.unmodifiable(photos);
  }

  DateTime _readClockOnce() {
    final value = clock();
    CseTimeCodec.encodeUtc(value);
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    );
  }

  Future<T> _withDatabase<T>(
    DateTime operationTime,
    Future<T> Function(Database database) action,
  ) => coordinator.run(() async {
    final appDatabase = AppDatabase(
      path: databasePath,
      factory: databaseFactory,
      clock: () => operationTime,
    );
    try {
      await appDatabase.open();
      return await action(appDatabase.database);
    } finally {
      await appDatabase.close();
    }
  });

  _ResolvedReminderSchedule _resolveSchedule(
    CreateReminderCommand command,
    DateTime now,
  ) => _resolveScheduleValues(
    command.schedule,
    command.customAttentionAt,
    command.allDayLocalDate,
    now,
  );

  _ResolvedReminderSchedule _resolveScheduleValues(
    ReminderScheduleKind schedule,
    String? customAttentionAt,
    String? allDayLocalDate,
    DateTime now,
  ) {
    if (allDayLocalDate != null) {
      if (customAttentionAt != null) {
        throw const AgendaValidationFailure(
          'Tam gün kayıtta saatli hatırlatma zamanı verilmemelidir.',
        );
      }
      if (schedule == ReminderScheduleKind.inbox ||
          schedule == ReminderScheduleKind.in15Minutes ||
          schedule == ReminderScheduleKind.in1Hour ||
          schedule == ReminderScheduleKind.in2Hours ||
          schedule == ReminderScheduleKind.in3Hours) {
        throw const AgendaValidationFailure(
          'Tam gün kayıt için bir takvim günü seçilmelidir.',
        );
      }
      try {
        CseTimeCodec.validateIstanbulDay(allDayLocalDate);
      } on TimeContractViolation {
        throw const AgendaValidationFailure(
          'Tam gün tarihi geçerli bir Europe/Istanbul günü olmalıdır.',
        );
      }
      final today = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
      if (allDayLocalDate.compareTo(today) < 0) {
        throw const AgendaValidationFailure(
          'Tam gün tarihi bugün veya gelecekte olmalıdır.',
        );
      }
      return _ResolvedReminderSchedule(
        status: ReminderStatus.active,
        nextAttentionAt: null,
        allDayLocalDate: allDayLocalDate,
      );
    }
    String? nextAttentionAt;
    switch (schedule) {
      case ReminderScheduleKind.inbox:
        if (customAttentionAt != null) {
          throw const AgendaValidationFailure(
            'Unutma Kutusu için tarih/saat verilmemelidir.',
          );
        }
      case ReminderScheduleKind.in15Minutes:
        nextAttentionAt = CseTimeCodec.encodeUtc(
          now.add(const Duration(minutes: 15)),
        );
      case ReminderScheduleKind.in1Hour:
        nextAttentionAt = CseTimeCodec.encodeUtc(
          now.add(const Duration(hours: 1)),
        );
      case ReminderScheduleKind.in2Hours:
        nextAttentionAt = CseTimeCodec.encodeUtc(
          now.add(const Duration(hours: 2)),
        );
      case ReminderScheduleKind.in3Hours:
        nextAttentionAt = CseTimeCodec.encodeUtc(
          now.add(const Duration(hours: 3)),
        );
      case ReminderScheduleKind.todayEnd:
        final local = CseTimeCodec.toIstanbul(CseTimeCodec.encodeUtc(now));
        nextAttentionAt = CseTimeCodec.canonicalFromIstanbulComponents(
          year: local.year,
          month: local.month,
          day: local.day,
          hour: 18,
          minute: 0,
        );
      case ReminderScheduleKind.tomorrowMorning:
        nextAttentionAt = resolveReminderTomorrowMorningAt(now);
        _validateExactQuickSchedulePreview(customAttentionAt, nextAttentionAt);
      case ReminderScheduleKind.nextWeekStart:
        nextAttentionAt = resolveReminderNextWeekStartAt(now);
        _validateExactQuickSchedulePreview(customAttentionAt, nextAttentionAt);
      case ReminderScheduleKind.custom:
        final custom = customAttentionAt;
        if (custom == null) {
          throw const AgendaValidationFailure(
            'Özel hatırlatıcı tarih/saat zorunludur.',
          );
        }
        validateCanonicalTimestamp(custom, 'Hatırlatıcı zamanı');
        nextAttentionAt = custom;
    }
    if (nextAttentionAt != null &&
        !CseTimeCodec.decodeCanonicalUtc(nextAttentionAt).isAfter(now)) {
      throw const AgendaValidationFailure(
        'Hatırlatıcı zamanı gelecekte olmalıdır.',
      );
    }
    final status = nextAttentionAt == null
        ? ReminderStatus.inbox
        : ReminderStatus.active;
    return _ResolvedReminderSchedule(
      status: status,
      nextAttentionAt: nextAttentionAt,
      allDayLocalDate: null,
    );
  }

  void _validateExactQuickSchedulePreview(
    String? previewAttentionAt,
    String resolvedAttentionAt,
  ) {
    if (previewAttentionAt == null) return;
    validateCanonicalTimestamp(
      previewAttentionAt,
      'Gösterilen hızlı planlama zamanı',
    );
    if (previewAttentionAt != resolvedAttentionAt) {
      throw const AgendaValidationFailure(
        'Gösterilen hızlı planlama zamanı artık geçerli değil. Yeniden seçin.',
      );
    }
  }

  bool _sameLogCommand(
    AgendaLog log,
    CreateAgendaLogCommand command,
    String description,
    String? location,
    String? notes,
  ) {
    return log.projectId == command.projectId &&
        log.observedAt == command.observedAt &&
        log.category == command.category &&
        log.description == description &&
        log.locationId == command.locationId &&
        (command.locationId != null || log.location == location) &&
        log.notes == notes;
  }

  bool _sameReminderCommand(
    MobileReminder reminder,
    CreateReminderCommand command,
    String captureText,
    String title,
    String? description,
    String? location,
    String? relatedPerson,
    String? conditionText,
    _ResolvedReminderSchedule _,
    String? locationId,
  ) {
    final originalSchedule = _resolveScheduleValues(
      command.schedule,
      command.customAttentionAt,
      command.allDayLocalDate,
      CseTimeCodec.decodeCanonicalUtc(reminder.createdAt),
    );
    return reminder.projectId == command.projectId &&
        reminder.sourceLogId == command.sourceLogId &&
        reminder.attendanceDayId == null &&
        reminder.concretePourId == null &&
        reminder.captureText == captureText &&
        reminder.title == title &&
        reminder.description == description &&
        reminder.kind == command.kind &&
        reminder.status == originalSchedule.status &&
        reminder.locationId == locationId &&
        reminder.location == location &&
        reminder.relatedPerson == relatedPerson &&
        reminder.isImportant == command.isImportant &&
        reminder.nextAttentionAt == originalSchedule.nextAttentionAt &&
        reminder.allDayLocalDate == originalSchedule.allDayLocalDate &&
        reminder.deadlineAt == command.deadlineAt &&
        reminder.conditionText == conditionText;
  }
}

Future<void> _requireProjectExists(
  DatabaseExecutor database,
  String projectId,
) async {
  final rows = await database.query(
    'projects',
    columns: ['id'],
    where: 'id = ?',
    whereArgs: [projectId],
    limit: 1,
  );
  if (rows.isEmpty) {
    throw const AgendaValidationFailure('Seçilen proje bulunamadı.');
  }
}

Future<MobileProject> _requireProjectRecord(
  DatabaseExecutor database,
  String projectId,
) async {
  final rows = await database.query(
    'projects',
    where: 'id = ?',
    whereArgs: [projectId],
    limit: 1,
  );
  if (rows.isEmpty) {
    throw const AgendaValidationFailure('Proje bulunamadı.');
  }
  return _projectFromRow(rows.single);
}

void _requireActiveProjectRecord(MobileProject project) {
  if (project.isArchived) {
    throw const AgendaValidationFailure('Arşivli proje değiştirilemez.');
  }
}

void _validateProjectRevision(int revision) {
  if (revision < 1) {
    throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
  }
}

void _requireProjectRevision(MobileProject project, int expectedRevision) {
  if (project.revision != expectedRevision) {
    throw const AgendaValidationFailure(
      'Proje başka bir işlem tarafından değiştirilmiş.',
    );
  }
}

Future<void> _rejectActiveProjectDuplicate(
  DatabaseExecutor database, {
  required String normalizedName,
  String? excludingProjectId,
}) async {
  final rows = await database.query(
    'projects',
    columns: ['id', 'name'],
    where: 'archived_at IS NULL',
  );
  if (rows.any(
    (row) =>
        row['id'] != excludingProjectId &&
        _normalizeProjectName(row['name']! as String) == normalizedName,
  )) {
    throw const AgendaValidationFailure(
      'Aynı adlı aktif proje zaten bulunuyor.',
    );
  }
}

Future<void> _updateProject(
  DatabaseExecutor database, {
  required String projectId,
  required int expectedRevision,
  required Map<String, Object?> values,
}) async {
  final changed = await database.update(
    'projects',
    values,
    where: 'id = ? AND revision = ?',
    whereArgs: [projectId, expectedRevision],
  );
  if (changed != 1) {
    throw const AgendaValidationFailure(
      'Proje başka bir işlem tarafından değiştirilmiş.',
    );
  }
}

Future<void> _insertProjectEvent(
  DatabaseExecutor database, {
  required String id,
  required String projectId,
  required ProjectEventType eventType,
  required String occurredAt,
  required Map<String, Object?> payload,
}) async {
  final sequence =
      Sqflite.firstIntValue(
        await database.rawQuery(
          '''
            SELECT COALESCE(MAX(sequence), 0) + 1
            FROM project_events
            WHERE project_id = ?
          ''',
          [projectId],
        ),
      ) ??
      1;
  await database.insert('project_events', {
    'id': id,
    'project_id': projectId,
    'sequence': sequence,
    'event_type': eventType.storageValue,
    'occurred_at': occurredAt,
    'payload_json': jsonEncode(payload),
  });
}

Future<void> _requireActiveProject(
  DatabaseExecutor database,
  String projectId,
) async {
  final rows = await database.query(
    'projects',
    columns: ['id'],
    where: 'id = ? AND archived_at IS NULL',
    whereArgs: [projectId],
    limit: 1,
  );
  if (rows.isEmpty) {
    throw const AgendaValidationFailure('Aktif proje bulunamadı.');
  }
}

Future<MobileProjectLocation> _requireProjectLocation(
  DatabaseExecutor database,
  String locationId,
) async {
  final rows = await database.query(
    'project_locations',
    where: 'id = ?',
    whereArgs: [locationId],
    limit: 1,
  );
  if (rows.isEmpty) {
    throw const AgendaValidationFailure('Mahal bulunamadı.');
  }
  return _projectLocationFromRow(rows.single);
}

Future<MobileProjectLocation> _requireActiveAgendaLocation(
  DatabaseExecutor database, {
  required String projectId,
  required String locationId,
}) async {
  final location = await _requireProjectLocation(database, locationId);
  if (location.projectId != projectId || location.isArchived) {
    throw const AgendaValidationFailure(
      'Seçilen mahal aktif ve aynı projeye ait olmalıdır.',
    );
  }
  return location;
}

Future<MobileProjectLocation> _requireActiveLocationInProject(
  DatabaseExecutor database,
  String locationId,
  String projectId,
) async {
  final location = await _requireProjectLocation(database, locationId);
  if (location.projectId != projectId || location.isArchived) {
    throw const AgendaValidationFailure(
      'Üst mahal aynı aktif projeye ait olmalıdır.',
    );
  }
  return location;
}

void _requireActiveLocation(MobileProjectLocation location) {
  if (location.isArchived) {
    throw const AgendaValidationFailure('Arşivli mahal değiştirilemez.');
  }
}

void _validateLocationRevision(int revision) {
  if (revision < 1) {
    throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
  }
}

void _requireLocationRevision(
  MobileProjectLocation location,
  int expectedRevision,
) {
  if (location.revision != expectedRevision) {
    throw const AgendaValidationFailure(
      'Mahal başka bir işlem tarafından değiştirilmiş.',
    );
  }
}

Future<void> _rejectActiveSiblingDuplicate(
  DatabaseExecutor database, {
  required String projectId,
  required String? parentLocationId,
  required String normalizedName,
  String? excludingLocationId,
}) async {
  final where = <String>[
    'project_id = ?',
    'normalized_name = ?',
    'archived_at IS NULL',
    parentLocationId == null
        ? 'parent_location_id IS NULL'
        : 'parent_location_id = ?',
  ];
  final arguments = <Object?>[projectId, normalizedName];
  if (parentLocationId != null) arguments.add(parentLocationId);
  if (excludingLocationId != null) {
    where.add('id != ?');
    arguments.add(excludingLocationId);
  }
  final rows = await database.query(
    'project_locations',
    columns: ['id'],
    where: where.join(' AND '),
    whereArgs: arguments,
    limit: 1,
  );
  if (rows.isNotEmpty) {
    throw const AgendaValidationFailure(
      'Aynı adlı aktif kardeş mahal zaten bulunuyor.',
    );
  }
}

Future<void> _rejectDescendantParent(
  DatabaseExecutor database, {
  required String locationId,
  required String parentLocationId,
}) async {
  String? currentId = parentLocationId;
  final visited = <String>{};
  while (currentId != null) {
    if (currentId == locationId) {
      throw const AgendaValidationFailure(
        'Mahal kendi alt mahali altına taşınamaz.',
      );
    }
    if (!visited.add(currentId)) {
      throw const AgendaValidationFailure('Mahal hiyerarşisi döngülüdür.');
    }
    final rows = await database.query(
      'project_locations',
      columns: ['parent_location_id'],
      where: 'id = ?',
      whereArgs: [currentId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Üst mahal bulunamadı.');
    }
    currentId = rows.single['parent_location_id'] as String?;
  }
}

Future<void> _rejectActiveDescendants(
  DatabaseExecutor database,
  String locationId,
) async {
  final rows = await database.rawQuery(
    '''
      WITH RECURSIVE descendants(id) AS (
        SELECT id
        FROM project_locations
        WHERE parent_location_id = ?
        UNION
        SELECT child.id
        FROM project_locations child
        JOIN descendants parent ON child.parent_location_id = parent.id
      )
      SELECT 1
      FROM project_locations location
      JOIN descendants ON descendants.id = location.id
      WHERE location.archived_at IS NULL
      LIMIT 1
    ''',
    [locationId],
  );
  if (rows.isNotEmpty) {
    throw const AgendaValidationFailure(
      'Aktif alt mahali bulunan mahal arşivlenemez.',
    );
  }
}

Future<void> _updateProjectLocation(
  DatabaseExecutor database, {
  required String locationId,
  required int expectedRevision,
  required Map<String, Object?> values,
}) async {
  final changed = await database.update(
    'project_locations',
    values,
    where: 'id = ? AND revision = ?',
    whereArgs: [locationId, expectedRevision],
  );
  if (changed != 1) {
    throw const AgendaValidationFailure(
      'Mahal başka bir işlem tarafından değiştirilmiş.',
    );
  }
}

Future<void> _insertProjectLocationEvent(
  DatabaseExecutor database, {
  required String id,
  required String locationId,
  required ProjectLocationEventType eventType,
  required String occurredAt,
  required Map<String, Object?> payload,
}) async {
  final sequence =
      Sqflite.firstIntValue(
        await database.rawQuery(
          '''
            SELECT COALESCE(MAX(sequence), 0) + 1
            FROM project_location_events
            WHERE location_id = ?
          ''',
          [locationId],
        ),
      ) ??
      1;
  await database.insert('project_location_events', {
    'id': id,
    'location_id': locationId,
    'sequence': sequence,
    'event_type': eventType.storageValue,
    'occurred_at': occurredAt,
    'payload_json': jsonEncode(payload),
  });
}

Map<String, Object?> _agendaEventSnapshot(AgendaLog log) => {
  'project_id': log.projectId,
  'observed_at': log.observedAt,
  'category': log.category.storageValue,
  'description': log.description,
  'location': log.location,
  'location_id': log.locationId,
  'notes': log.notes,
};

bool _mapsEqual(Map<String, Object?> first, Map<String, Object?> second) =>
    jsonEncode(first) == jsonEncode(second);

String _normalizeProjectName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

String _locationDisplayName(String value) => requiredTrimmed(
  value,
  'Mahal adı',
  maxLength: 160,
).replaceAll(RegExp(r'\s+'), ' ');

String _normalizeLocationName(String value) =>
    _locationDisplayName(value).toLowerCase();

class _ResolvedReminderSchedule {
  const _ResolvedReminderSchedule({
    required this.status,
    required this.nextAttentionAt,
    required this.allDayLocalDate,
  });

  final ReminderStatus status;
  final String? nextAttentionAt;
  final String? allDayLocalDate;
}

MobileProject _projectFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final archivedAt = row['archived_at'] as String?;
  final revision = row['revision']! as int;
  validateUuid(id, 'Proje kimliği');
  validateCanonicalTimestamp(createdAt, 'Proje oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Proje güncelleme zamanı');
  if (archivedAt != null) {
    validateCanonicalTimestamp(archivedAt, 'Proje arşivleme zamanı');
  }
  if (revision < 1) {
    throw const AgendaValidationFailure('Proje revision geçersizdir.');
  }
  return MobileProject(
    id: id,
    name: requiredTrimmed(row['name']! as String, 'Proje adı', maxLength: 160),
    createdAt: createdAt,
    updatedAt: updatedAt,
    revision: revision,
    archivedAt: archivedAt,
  );
}

ProjectEvent _projectEventFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final projectId = row['project_id']! as String;
  final occurredAt = row['occurred_at']! as String;
  final sequence = row['sequence']! as int;
  validateUuid(id, 'Proje event kimliği');
  validateUuid(projectId, 'Proje kimliği');
  validateCanonicalTimestamp(occurredAt, 'Proje event zamanı');
  if (sequence < 1) {
    throw const AgendaValidationFailure('Proje event sırası geçersizdir.');
  }
  final storageType = row['event_type']! as String;
  final eventType = ProjectEventType.values.where(
    (item) => item.storageValue == storageType,
  );
  if (eventType.isEmpty) {
    throw const AgendaValidationFailure('Proje event türü desteklenmiyor.');
  }
  return ProjectEvent(
    id: id,
    projectId: projectId,
    sequence: sequence,
    eventType: eventType.single,
    occurredAt: occurredAt,
    payloadJson: row['payload_json']! as String,
  );
}

MobileProjectLocation _projectLocationFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final projectId = row['project_id']! as String;
  final parentLocationId = row['parent_location_id'] as String?;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final archivedAt = row['archived_at'] as String?;
  final revision = row['revision']! as int;
  validateUuid(id, 'Mahal kimliği');
  validateUuid(projectId, 'Proje kimliği');
  if (parentLocationId != null) {
    validateUuid(parentLocationId, 'Üst mahal kimliği');
  }
  validateCanonicalTimestamp(createdAt, 'Mahal oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Mahal güncelleme zamanı');
  if (archivedAt != null) {
    validateCanonicalTimestamp(archivedAt, 'Mahal arşivleme zamanı');
  }
  if (revision < 1) {
    throw const AgendaValidationFailure('Mahal revision geçersizdir.');
  }
  return MobileProjectLocation(
    id: id,
    projectId: projectId,
    displayName: requiredTrimmed(
      row['display_name']! as String,
      'Mahal adı',
      maxLength: 160,
    ),
    parentLocationId: parentLocationId,
    revision: revision,
    createdAt: createdAt,
    updatedAt: updatedAt,
    archivedAt: archivedAt,
  );
}

ProjectLocationEvent _projectLocationEventFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final locationId = row['location_id']! as String;
  final occurredAt = row['occurred_at']! as String;
  final sequence = row['sequence']! as int;
  validateUuid(id, 'Mahal event kimliği');
  validateUuid(locationId, 'Mahal kimliği');
  validateCanonicalTimestamp(occurredAt, 'Mahal event zamanı');
  if (sequence < 1) {
    throw const AgendaValidationFailure('Mahal event sırası geçersizdir.');
  }
  final storageType = row['event_type']! as String;
  final eventType = ProjectLocationEventType.values.where(
    (item) => item.storageValue == storageType,
  );
  if (eventType.isEmpty) {
    throw const AgendaValidationFailure('Mahal event türü desteklenmiyor.');
  }
  return ProjectLocationEvent(
    id: id,
    locationId: locationId,
    sequence: sequence,
    eventType: eventType.single,
    occurredAt: occurredAt,
    payloadJson: row['payload_json']! as String,
  );
}

AgendaLog _logFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final projectId = row['project_id']! as String;
  final observedAt = row['observed_at']! as String;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final archivedAt = row['archived_at'] as String?;
  final locationId = row['location_id'] as String?;
  final stableLocationName = row['stable_location_name'] as String?;
  final stableLocationArchivedAt =
      row['stable_location_archived_at'] as String?;
  validateUuid(id, 'Log kimliği');
  validateUuid(projectId, 'Proje kimliği');
  validateCanonicalTimestamp(observedAt, 'Olay zamanı');
  validateCanonicalTimestamp(createdAt, 'Log oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Log güncelleme zamanı');
  if (archivedAt != null) {
    validateCanonicalTimestamp(archivedAt, 'Log arşivleme zamanı');
  }
  if (locationId != null) {
    validateUuid(locationId, 'Mahal kimliği');
    if (stableLocationName == null) {
      throw const AgendaValidationFailure(
        'Bağlı mahal güvenli biçimde okunamadı.',
      );
    }
  }
  if (stableLocationArchivedAt != null) {
    validateCanonicalTimestamp(
      stableLocationArchivedAt,
      'Mahal arşivleme zamanı',
    );
  }
  return AgendaLog(
    id: id,
    projectId: projectId,
    projectName: requiredTrimmed(row['project_name']! as String, 'Proje adı'),
    observedAt: observedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    category: AgendaCategory.fromStorage(row['category']! as String),
    description: requiredTrimmed(
      row['description']! as String,
      'Kısa açıklama',
    ),
    location: row['location'] as String?,
    notes: row['notes'] as String?,
    revision: row['revision']! as int,
    locationId: locationId,
    stableLocationName: stableLocationName,
    stableLocationArchivedAt: stableLocationArchivedAt,
    archivedAt: archivedAt,
  );
}

AgendaLogPhoto _agendaPhotoFromRow(Map<String, Object?> row) {
  final capturedAt = row['captured_at'] as String?;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final archivedAt = row['archived_at'] as String?;
  if (capturedAt != null) {
    validateCanonicalTimestamp(capturedAt, 'Fotoğraf çekim zamanı');
  }
  validateCanonicalTimestamp(createdAt, 'Fotoğraf oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Fotoğraf güncelleme zamanı');
  if (archivedAt != null) {
    validateCanonicalTimestamp(archivedAt, 'Fotoğraf arşivleme zamanı');
  }
  return AgendaLogPhoto(
    id: row['id']! as String,
    logId: row['observation_id']! as String,
    projectId: row['project_id']! as String,
    originalFileName: row['original_file_name']! as String,
    mimeType: row['mime_type']! as String,
    byteSize: row['byte_size']! as int,
    sha256: row['sha256']! as String,
    relativePath: row['relative_path']! as String,
    description: row['description'] as String?,
    capturedAt: capturedAt,
    revision: row['revision']! as int,
    createdAt: createdAt,
    updatedAt: updatedAt,
    archivedAt: archivedAt,
    integrity: AgendaAttachmentIntegrity.ok,
  );
}

AgendaLogPhoto _agendaPhotoWithIntegrity(
  AgendaLogPhoto photo,
  AgendaAttachmentIntegrity integrity,
) => AgendaLogPhoto(
  id: photo.id,
  logId: photo.logId,
  projectId: photo.projectId,
  originalFileName: photo.originalFileName,
  mimeType: photo.mimeType,
  byteSize: photo.byteSize,
  sha256: photo.sha256,
  relativePath: photo.relativePath,
  description: photo.description,
  capturedAt: photo.capturedAt,
  revision: photo.revision,
  createdAt: photo.createdAt,
  updatedAt: photo.updatedAt,
  archivedAt: photo.archivedAt,
  integrity: integrity,
);

AppendOnlyEvent _observationEventFromRow(Map<String, Object?> row) =>
    AppendOnlyEvent(
      id: row['id']! as String,
      recordId: row['observation_id']! as String,
      projectId: row['project_id']! as String,
      eventType: row['event_type']! as String,
      occurredAt: row['occurred_at']! as String,
      payloadJson: row['payload_json']! as String,
    );

MobileReminder _reminderFromRow(Map<String, Object?> row) {
  final id = row['id']! as String;
  final projectId = row['project_id'] as String?;
  final sourceLogId = row['observation_id'] as String?;
  final locationId = row['location_id'] as String?;
  final attendanceDayId = row['attendance_day_id'] as String?;
  final concretePourId = row['concrete_pour_id'] as String?;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final nextAttentionAt = row['next_attention_at'] as String?;
  final allDayLocalDate = row['all_day_local_date'] as String?;
  final deadlineAt = row['deadline_at'] as String?;
  final completedAt = row['completed_at'] as String?;
  final cancelledAt = row['cancelled_at'] as String?;
  final trashedAt = row['trashed_at'] as String?;
  validateUuid(id, 'Hatırlatıcı kimliği');
  if (projectId != null) validateUuid(projectId, 'Proje kimliği');
  if (sourceLogId != null) validateUuid(sourceLogId, 'Kaynak log kimliği');
  if (locationId != null) validateUuid(locationId, 'Mahal kimliği');
  if (attendanceDayId != null) {
    validateUuid(attendanceDayId, 'Kaynak Puantaj günü kimliği');
  }
  if (concretePourId != null) {
    validateUuid(concretePourId, 'Kaynak Beton paketi kimliği');
  }
  validateCanonicalTimestamp(createdAt, 'Hatırlatıcı oluşturma zamanı');
  validateCanonicalTimestamp(updatedAt, 'Hatırlatıcı güncelleme zamanı');
  if (nextAttentionAt != null) {
    validateCanonicalTimestamp(nextAttentionAt, 'Hatırlatıcı zamanı');
  }
  if (allDayLocalDate != null) {
    try {
      CseTimeCodec.validateIstanbulDay(allDayLocalDate);
    } on TimeContractViolation {
      throw const AgendaValidationFailure(
        'Tam gün tarihi geçerli bir Europe/Istanbul günü olmalıdır.',
      );
    }
  }
  if (deadlineAt != null) {
    validateCanonicalTimestamp(deadlineAt, 'Gerçek son tarih');
  }
  if (completedAt != null) {
    validateCanonicalTimestamp(completedAt, 'Tamamlanma zamanı');
  }
  if (cancelledAt != null) {
    validateCanonicalTimestamp(cancelledAt, 'İptal zamanı');
  }
  if (trashedAt != null) {
    validateCanonicalTimestamp(trashedAt, 'Geri dönüşüm kutusu zamanı');
  }
  final outcomeValue = row['outcome_type'] as String?;
  return MobileReminder(
    id: id,
    projectId: projectId,
    projectName: row['project_name'] == null
        ? null
        : requiredTrimmed(row['project_name']! as String, 'Proje adı'),
    sourceLogId: sourceLogId,
    attendanceDayId: attendanceDayId,
    concretePourId: concretePourId,
    captureText: requiredTrimmed(
      row['capture_text']! as String,
      'Hızlı yakalama metni',
    ),
    title: requiredTrimmed(row['title']! as String, 'Hatırlatıcı metni'),
    description: row['description'] as String?,
    kind: ReminderKind.fromStorage(row['item_type']! as String),
    status: ReminderStatus.fromStorage(row['status']! as String),
    locationId: locationId,
    stableLocationName: row['stable_location_name'] as String?,
    stableLocationArchivedAt: row['stable_location_archived_at'] as String?,
    location: row['location'] as String?,
    relatedPerson: row['related_person'] as String?,
    isImportant: row['is_important'] == 1,
    nextAttentionAt: nextAttentionAt,
    allDayLocalDate: allDayLocalDate,
    deadlineAt: deadlineAt,
    conditionText: row['condition_text'] as String?,
    outcomeType: outcomeValue == null
        ? null
        : ReminderOutcomeType.fromStorage(outcomeValue),
    outcomeNote: row['outcome_note'] as String?,
    createdAt: createdAt,
    updatedAt: updatedAt,
    completedAt: completedAt,
    cancelledAt: cancelledAt,
    trashedAt: trashedAt,
    revision: row['revision']! as int,
  );
}

AppendOnlyEvent _reminderEventFromRow(Map<String, Object?> row) {
  final projectId = row['project_id'] as String?;
  final sourceLogId = row['source_observation_id'] as String?;
  final attendanceDayId = row['source_attendance_day_id'] as String?;
  final concretePourId = row['source_concrete_pour_id'] as String?;
  if (projectId != null) validateUuid(projectId, 'Proje kimliği');
  if (sourceLogId != null) validateUuid(sourceLogId, 'Kaynak log kimliği');
  if (attendanceDayId != null) {
    validateUuid(attendanceDayId, 'Kaynak Puantaj günü kimliği');
  }
  if (concretePourId != null) {
    validateUuid(concretePourId, 'Kaynak Beton paketi kimliği');
  }
  return AppendOnlyEvent(
    id: row['id']! as String,
    recordId: row['follow_up_id']! as String,
    projectId: projectId,
    sourceLogId: sourceLogId,
    sourceAttendanceDayId: attendanceDayId,
    sourceConcretePourId: concretePourId,
    eventType: row['event_type']! as String,
    occurredAt: row['occurred_at']! as String,
    payloadJson: row['payload_json']! as String,
    sequence: row['sequence']! as int,
  );
}

NotificationBinding _notificationBindingFromRow(Map<String, Object?> row) {
  final scheduledFor = row['scheduled_for'] as String?;
  final lastSyncedAt = row['last_synced_at']! as String;
  if (scheduledFor != null) {
    validateCanonicalTimestamp(scheduledFor, 'Planlanan bildirim zamanı');
  }
  validateCanonicalTimestamp(lastSyncedAt, 'Bildirim eşitleme zamanı');
  return NotificationBinding(
    reminderId: row['reminder_id']! as String,
    platformNotificationId: row['platform_notification_id']! as int,
    scheduledFor: scheduledFor,
    syncState: NotificationSyncState.fromStorage(row['sync_state']! as String),
    lastSyncedAt: lastSyncedAt,
    safeErrorCode: row['safe_error_code'] as String?,
    repeatIntervalMinutes: row['repeat_interval_minutes'] as int?,
  );
}

NotificationBinding _notificationBindingFromJoinedRow(
  Map<String, Object?> row,
) {
  return _notificationBindingFromRow({
    'reminder_id': row['id'],
    'platform_notification_id': row['platform_notification_id'],
    'scheduled_for': row['binding_scheduled_for'],
    'sync_state': row['sync_state'],
    'last_synced_at': row['last_synced_at'],
    'safe_error_code': row['safe_error_code'],
    'repeat_interval_minutes': row['repeat_interval_minutes'],
  });
}

enum _NotificationDisposition {
  schedulable,
  preserveDeliveredOneTime,
  terminal,
}

class _NotificationWorkItem {
  const _NotificationWorkItem({required this.reminder, required this.binding});

  final MobileReminder reminder;
  final NotificationBinding binding;
}

class _BindingUpdate {
  const _BindingUpdate({
    required this.reminderId,
    required this.state,
    this.scheduledFor,
    this.safeErrorCode,
  });

  final String reminderId;
  final String? scheduledFor;
  final NotificationSyncState state;
  final String? safeErrorCode;
}

String? _canonicalPlatformTime(String? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value)?.toUtc();
  if (parsed == null) return null;
  return CseTimeCodec.encodeUtc(
    DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    ),
  );
}

ReminderDeliveryDelayClass _deliveryDelayClass({
  required String? dueAt,
  required String? deliveredAt,
  required bool nativePresent,
  required DateTime now,
}) {
  if (dueAt == null) return ReminderDeliveryDelayClass.deliveryUnknown;
  final due = CseTimeCodec.decodeCanonicalUtc(dueAt);
  if (deliveredAt != null) {
    final delivered = CseTimeCodec.decodeCanonicalUtc(deliveredAt);
    final delay = delivered.difference(due);
    if (delay <= const Duration(minutes: 1)) {
      return ReminderDeliveryDelayClass.onTime;
    }
    if (delay <= const Duration(minutes: 5)) {
      return ReminderDeliveryDelayClass.delayed;
    }
    return ReminderDeliveryDelayClass.severelyDelayed;
  }
  if (!due.isAfter(now)) return ReminderDeliveryDelayClass.overdue;
  if (nativePresent) return ReminderDeliveryDelayClass.pending;
  return ReminderDeliveryDelayClass.nativeScheduleMissing;
}

List<MobileReminder> _collapseAttendanceRemindersByProject(
  List<MobileReminder> reminders,
) {
  final visible = <MobileReminder>[];
  final attendanceProjects = <String>{};
  for (final reminder in reminders) {
    if (reminder.attendanceDayId == null || reminder.projectId == null) {
      visible.add(reminder);
      continue;
    }
    if (attendanceProjects.add(reminder.projectId!)) {
      visible.add(reminder);
    }
  }
  return List.unmodifiable(visible);
}
