import 'dart:convert';

import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/material_request_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class MaterialRequestApplicationPort {
  Future<List<MaterialRequestProject>> listProjects();
  Future<List<MaterialRequestLocationOption>> listLocations(String projectId);
  Future<List<MaterialRequestLivingPlanOption>> listLivingPlanItems(
    String projectId,
  );
  Future<List<MaterialRequest>> listMaterialRequests({
    required String projectId,
    required MaterialRequestListKind kind,
  });
  Future<MaterialRequestDetail> getMaterialRequestDetail(String requestId);
  Future<List<MaterialRequestEvent>> listMaterialRequestEvents(
    String requestId,
  );
  Future<MaterialRequest> createMaterialRequest(
    CreateMaterialRequestCommand command,
  );
  Future<MaterialRequest> updateMaterialRequest(
    UpdateMaterialRequestCommand command,
  );
  Future<MaterialRequest> transitionMaterialRequest(
    TransitionMaterialRequestCommand command,
  );
}

class SqliteMaterialRequestApplication
    implements MaterialRequestApplicationPort {
  const SqliteMaterialRequestApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.clock,
    required this.coordinator,
  });

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;
  final MobileOperationCoordinator coordinator;

  @override
  Future<List<MaterialRequestProject>> listProjects() =>
      _read((database) async {
        final rows = await database.query(
          'projects',
          columns: ['id', 'name'],
          where: 'archived_at IS NULL',
          orderBy: 'name COLLATE NOCASE ASC, id ASC',
        );
        return List.unmodifiable(
          rows.map(
            (row) => MaterialRequestProject(
              id: _text(row, 'id'),
              name: _text(row, 'name'),
            ),
          ),
        );
      });

  @override
  Future<List<MaterialRequestLocationOption>> listLocations(String projectId) {
    final project = _uuid(projectId, 'material_request_invalid_project');
    return _read((database) async {
      await _requireProject(database, project);
      final rows = await database.query(
        'project_locations',
        columns: ['id', 'display_name'],
        where: 'project_id = ? AND archived_at IS NULL',
        whereArgs: [project],
        orderBy: 'display_name COLLATE NOCASE ASC, id ASC',
      );
      return List.unmodifiable(
        rows.map(
          (row) => MaterialRequestLocationOption(
            id: _text(row, 'id'),
            displayName: _text(row, 'display_name'),
          ),
        ),
      );
    });
  }

  @override
  Future<List<MaterialRequestLivingPlanOption>> listLivingPlanItems(
    String projectId,
  ) {
    final project = _uuid(projectId, 'material_request_invalid_project');
    return _read((database) async {
      await _requireProject(database, project);
      final rows = await database.query(
        'project_living_plan_items',
        columns: ['id', 'activity_name_snapshot', 'planned_date', 'status'],
        where: 'project_id = ?',
        whereArgs: [project],
        orderBy:
            'planned_date ASC, activity_name_snapshot COLLATE NOCASE ASC, id ASC',
      );
      return List.unmodifiable(
        rows.map(
          (row) => MaterialRequestLivingPlanOption(
            id: _text(row, 'id'),
            activityName: _text(row, 'activity_name_snapshot'),
            plannedDate: _day(row, 'planned_date')!,
            status: _text(row, 'status'),
          ),
        ),
      );
    });
  }

  @override
  Future<List<MaterialRequest>> listMaterialRequests({
    required String projectId,
    required MaterialRequestListKind kind,
  }) {
    final project = _uuid(projectId, 'material_request_invalid_project');
    final filter = kind == MaterialRequestListKind.open
        ? "mr.status IN ('needed', 'requested')"
        : "mr.status IN ('received', 'cancelled')";
    final order = kind == MaterialRequestListKind.open
        ? '''
          CASE mr.priority
            WHEN 'urgent' THEN 0
            WHEN 'high' THEN 1
            ELSE 2
          END,
          mr.needed_on IS NULL ASC,
          mr.needed_on ASC,
          mr.created_at ASC,
          mr.id ASC
        '''
        : 'mr.status_changed_at DESC, mr.id ASC';
    return _read((database) async {
      await _requireProject(database, project);
      final rows = await database.rawQuery(
        '''
        SELECT mr.*,
          location.display_name AS location_name,
          living.activity_name_snapshot AS living_plan_activity_name
        FROM material_requests AS mr
        LEFT JOIN project_locations AS location
          ON location.id = mr.location_id
          AND location.project_id = mr.project_id
        LEFT JOIN project_living_plan_items AS living
          ON living.id = mr.living_plan_item_id
          AND living.project_id = mr.project_id
        WHERE mr.project_id = ? AND $filter
        ORDER BY $order
        ''',
        [project],
      );
      return List.unmodifiable(rows.map(_mapRequest));
    });
  }

  @override
  Future<List<MaterialRequestEvent>> listMaterialRequestEvents(
    String requestId,
  ) {
    final id = _uuid(requestId, 'material_request_invalid_request');
    return _read((database) async {
      await _loadRequest(database, id);
      return _loadEvents(database, id);
    });
  }

  @override
  Future<MaterialRequestDetail> getMaterialRequestDetail(String requestId) {
    final id = _uuid(requestId, 'material_request_invalid_request');
    return _read((database) async {
      final request = await _loadRequest(database, id);
      final events = await _loadEvents(database, id);
      if (events.length != request.revision) {
        throw const MaterialRequestFailure(
          'material_request_history_integrity_failed',
        );
      }
      for (var index = 0; index < events.length; index += 1) {
        if (events[index].sequence != index + 1) {
          throw const MaterialRequestFailure(
            'material_request_history_integrity_failed',
          );
        }
      }
      return MaterialRequestDetail(request: request, events: events);
    });
  }

  @override
  Future<MaterialRequest> createMaterialRequest(
    CreateMaterialRequestCommand command,
  ) {
    final id = _uuid(command.requestId, 'material_request_invalid_request');
    final eventId = _uuid(command.eventId, 'material_request_invalid_event');
    final project = _uuid(
      command.projectId,
      'material_request_invalid_project',
    );
    final fields = _fields(
      materialName: command.materialName,
      locationId: command.locationId,
      livingPlanItemId: command.livingPlanItemId,
      quantity: command.quantity,
      unit: command.unit,
      neededOn: command.neededOn,
      priority: command.priority,
      description: command.description,
    );
    final intent = {
      'operation': 'create',
      'request_id': id,
      'project_id': project,
      ...fields.intent,
    };
    return _write(
      (database) => database.transaction((transaction) async {
        final replay = await _replay(
          transaction,
          eventId: eventId,
          requestId: id,
          eventType: MaterialRequestEventType.created,
          intent: intent,
        );
        if (replay != null) return replay;
        await _requireProject(transaction, project);
        await _requireBindings(
          transaction,
          projectId: project,
          locationId: fields.locationId,
          livingPlanItemId: fields.livingPlanItemId,
          currentLocationId: null,
        );
        if (await _exists(transaction, id)) {
          throw const MaterialRequestFailure('material_request_id_conflict');
        }
        final now = _now();
        await transaction.insert('material_requests', {
          'id': id,
          'project_id': project,
          'location_id': fields.locationId,
          'living_plan_item_id': fields.livingPlanItemId,
          'material_name': fields.materialName,
          'quantity': fields.quantity,
          'unit': fields.unit,
          'needed_on': fields.neededOn,
          'priority': fields.priority.storageValue,
          'description': fields.description,
          'status': MaterialRequestStatus.needed.storageValue,
          'revision': 1,
          'created_at': now,
          'updated_at': now,
          'status_changed_at': now,
          'requested_at': null,
          'received_at': null,
          'cancelled_at': null,
        });
        await _insertEvent(
          transaction,
          eventId: eventId,
          requestId: id,
          projectId: project,
          sequence: 1,
          type: MaterialRequestEventType.created,
          occurredAtUtc: now,
          intent: intent,
        );
        return _loadRequest(transaction, id);
      }),
    );
  }

  @override
  Future<MaterialRequest> updateMaterialRequest(
    UpdateMaterialRequestCommand command,
  ) {
    final id = _uuid(command.requestId, 'material_request_invalid_request');
    final eventId = _uuid(command.eventId, 'material_request_invalid_event');
    final revision = _validRevision(command.expectedRevision);
    final fields = _fields(
      materialName: command.materialName,
      locationId: command.locationId,
      livingPlanItemId: command.livingPlanItemId,
      quantity: command.quantity,
      unit: command.unit,
      neededOn: command.neededOn,
      priority: command.priority,
      description: command.description,
    );
    final intent = {
      'operation': 'update',
      'request_id': id,
      'expected_revision': revision,
      ...fields.intent,
    };
    return _write(
      (database) => database.transaction((transaction) async {
        final replay = await _replay(
          transaction,
          eventId: eventId,
          requestId: id,
          eventType: MaterialRequestEventType.detailsUpdated,
          intent: intent,
        );
        if (replay != null) return replay;
        final current = await _loadRequest(transaction, id);
        if (current.revision != revision) {
          throw const MaterialRequestFailure(
            'material_request_revision_conflict',
          );
        }
        await _requireBindings(
          transaction,
          projectId: current.projectId,
          locationId: fields.locationId,
          livingPlanItemId: fields.livingPlanItemId,
          currentLocationId: current.locationId,
        );
        if (_sameFields(current, fields)) return current;
        final now = _now();
        final next = revision + 1;
        final count = await transaction.update(
          'material_requests',
          {
            'location_id': fields.locationId,
            'living_plan_item_id': fields.livingPlanItemId,
            'material_name': fields.materialName,
            'quantity': fields.quantity,
            'unit': fields.unit,
            'needed_on': fields.neededOn,
            'priority': fields.priority.storageValue,
            'description': fields.description,
            'revision': next,
            'updated_at': now,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [id, revision],
        );
        if (count != 1) {
          throw const MaterialRequestFailure(
            'material_request_revision_conflict',
          );
        }
        await _insertEvent(
          transaction,
          eventId: eventId,
          requestId: id,
          projectId: current.projectId,
          sequence: next,
          type: MaterialRequestEventType.detailsUpdated,
          occurredAtUtc: now,
          intent: intent,
        );
        return _loadRequest(transaction, id);
      }),
    );
  }

  @override
  Future<MaterialRequest> transitionMaterialRequest(
    TransitionMaterialRequestCommand command,
  ) {
    final id = _uuid(command.requestId, 'material_request_invalid_request');
    final eventId = _uuid(command.eventId, 'material_request_invalid_event');
    final revision = _validRevision(command.expectedRevision);
    final eventType = switch (command.targetStatus) {
      MaterialRequestStatus.requested => MaterialRequestEventType.requested,
      MaterialRequestStatus.received => MaterialRequestEventType.received,
      MaterialRequestStatus.cancelled => MaterialRequestEventType.cancelled,
      MaterialRequestStatus.needed => MaterialRequestEventType.reopened,
    };
    final intent = <String, Object?>{
      'operation': 'transition',
      'request_id': id,
      'expected_revision': revision,
      'target_status': command.targetStatus.storageValue,
    };
    return _write(
      (database) => database.transaction((transaction) async {
        final replay = await _replay(
          transaction,
          eventId: eventId,
          requestId: id,
          eventType: eventType,
          intent: intent,
        );
        if (replay != null) return replay;
        final current = await _loadRequest(transaction, id);
        if (current.revision != revision) {
          throw const MaterialRequestFailure(
            'material_request_revision_conflict',
          );
        }
        if (current.status == command.targetStatus) return current;
        if (!_transitionAllowed(current.status, command.targetStatus)) {
          throw const MaterialRequestFailure(
            'material_request_transition_not_allowed',
          );
        }
        final now = _now();
        final next = revision + 1;
        final count = await transaction.update(
          'material_requests',
          {
            'status': command.targetStatus.storageValue,
            'revision': next,
            'updated_at': now,
            'status_changed_at': now,
            ..._transitionTimestamps(current, command.targetStatus, now),
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [id, revision],
        );
        if (count != 1) {
          throw const MaterialRequestFailure(
            'material_request_revision_conflict',
          );
        }
        await _insertEvent(
          transaction,
          eventId: eventId,
          requestId: id,
          projectId: current.projectId,
          sequence: next,
          type: eventType,
          occurredAtUtc: now,
          intent: intent,
        );
        return _loadRequest(transaction, id);
      }),
    );
  }

  Future<T> _read<T>(Future<T> Function(Database database) action) =>
      _database(action, readOnly: true);

  Future<T> _write<T>(Future<T> Function(Database database) action) =>
      _database(action, readOnly: false);

  Future<T> _database<T>(
    Future<T> Function(Database database) action, {
    required bool readOnly,
  }) => coordinator.run(() async {
    Database? database;
    try {
      database = await databaseFactory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          singleInstance: false,
          readOnly: readOnly,
          onConfigure: (value) => value.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      if (await database.getVersion() != AppDatabase.schemaVersion) {
        throw const MaterialRequestFailure(
          'material_request_unsupported_schema',
        );
      }
      return await action(database);
    } on MaterialRequestFailure {
      rethrow;
    } on Object {
      throw const MaterialRequestFailure('material_request_operation_failed');
    } finally {
      await database?.close();
    }
  });

  String _now() {
    final value = clock();
    if (!value.isUtc) {
      throw const MaterialRequestFailure('material_request_clock_not_utc');
    }
    return CseTimeCodec.encodeUtc(value);
  }
}

class _Fields {
  const _Fields({
    required this.materialName,
    required this.locationId,
    required this.livingPlanItemId,
    required this.quantity,
    required this.unit,
    required this.neededOn,
    required this.priority,
    required this.description,
  });

  final String materialName;
  final String? locationId;
  final String? livingPlanItemId;
  final double? quantity;
  final String? unit;
  final String? neededOn;
  final MaterialRequestPriority priority;
  final String? description;

  Map<String, Object?> get intent => {
    'material_name': materialName,
    'location_id': locationId,
    'living_plan_item_id': livingPlanItemId,
    'quantity': quantity,
    'unit': unit,
    'needed_on': neededOn,
    'priority': priority.storageValue,
    'description': description,
  };
}

_Fields _fields({
  required String materialName,
  required String? locationId,
  required String? livingPlanItemId,
  required double? quantity,
  required String? unit,
  required String? neededOn,
  required MaterialRequestPriority priority,
  required String? description,
}) {
  final name = materialName.trim();
  if (name.isEmpty || name.length > 200) {
    throw const MaterialRequestFailure('material_request_invalid_name');
  }
  final location = _optionalUuid(
    locationId,
    'material_request_invalid_location',
  );
  final livingPlan = _optionalUuid(
    livingPlanItemId,
    'material_request_invalid_living_plan_item',
  );
  if (quantity != null && (!quantity.isFinite || quantity <= 0)) {
    throw const MaterialRequestFailure('material_request_invalid_quantity');
  }
  final exactUnit = _optionalText(unit, 40);
  if ((quantity == null) != (exactUnit == null)) {
    throw const MaterialRequestFailure(
      'material_request_quantity_unit_pair_required',
    );
  }
  String? day;
  if (neededOn != null) {
    try {
      day = CseTimeCodec.validateIstanbulDay(neededOn);
    } on Object {
      throw const MaterialRequestFailure('material_request_invalid_needed_on');
    }
  }
  return _Fields(
    materialName: name,
    locationId: location,
    livingPlanItemId: livingPlan,
    quantity: quantity,
    unit: exactUnit,
    neededOn: day,
    priority: priority,
    description: _optionalText(description, 1000),
  );
}

Future<void> _requireProject(
  DatabaseExecutor database,
  String projectId,
) async {
  final rows = await database.query(
    'projects',
    columns: ['id'],
    where: 'id = ? AND archived_at IS NULL',
    whereArgs: [projectId],
    limit: 2,
  );
  if (rows.length != 1) {
    throw const MaterialRequestFailure('material_request_project_unavailable');
  }
}

Future<void> _requireBindings(
  DatabaseExecutor database, {
  required String projectId,
  required String? locationId,
  required String? livingPlanItemId,
  required String? currentLocationId,
}) async {
  if (locationId != null) {
    final allowArchived = locationId == currentLocationId;
    final where =
        'id = ? AND project_id = ?${allowArchived ? '' : ' AND archived_at IS NULL'}';
    final rows = await database.query(
      'project_locations',
      columns: ['id'],
      where: where,
      whereArgs: [locationId, projectId],
      limit: 2,
    );
    if (rows.length != 1) {
      throw const MaterialRequestFailure(
        'material_request_location_project_mismatch',
      );
    }
  }
  if (livingPlanItemId != null) {
    final rows = await database.query(
      'project_living_plan_items',
      columns: ['id'],
      where: 'id = ? AND project_id = ?',
      whereArgs: [livingPlanItemId, projectId],
      limit: 2,
    );
    if (rows.length != 1) {
      throw const MaterialRequestFailure(
        'material_request_living_plan_project_mismatch',
      );
    }
  }
}

Future<bool> _exists(DatabaseExecutor database, String id) async {
  final rows = await database.query(
    'material_requests',
    columns: ['id'],
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  return rows.isNotEmpty;
}

Future<MaterialRequest?> _replay(
  DatabaseExecutor database, {
  required String eventId,
  required String requestId,
  required MaterialRequestEventType eventType,
  required Map<String, Object?> intent,
}) async {
  final rows = await database.query(
    'material_request_events',
    columns: ['material_request_id', 'event_type', 'payload_json'],
    where: 'id = ?',
    whereArgs: [eventId],
    limit: 2,
  );
  if (rows.isEmpty) return null;
  if (rows.length != 1) {
    throw const MaterialRequestFailure('material_request_event_id_conflict');
  }
  final row = rows.single;
  final payload = _jsonObject(_text(row, 'payload_json'));
  final storedIntent = payload['intent'];
  if (_text(row, 'material_request_id') != requestId ||
      _text(row, 'event_type') != eventType.storageValue ||
      storedIntent is! Map<String, Object?> ||
      jsonEncode(storedIntent) != jsonEncode(intent)) {
    throw const MaterialRequestFailure('material_request_event_id_conflict');
  }
  return _loadRequest(database, requestId);
}

Future<void> _insertEvent(
  DatabaseExecutor database, {
  required String eventId,
  required String requestId,
  required String projectId,
  required int sequence,
  required MaterialRequestEventType type,
  required String occurredAtUtc,
  required Map<String, Object?> intent,
}) {
  return database
      .insert('material_request_events', {
        'id': eventId,
        'material_request_id': requestId,
        'project_id': projectId,
        'sequence': sequence,
        'event_type': type.storageValue,
        'occurred_at': occurredAtUtc,
        'payload_json': jsonEncode({
          'intent': intent,
          'result_revision': sequence,
        }),
      })
      .then((_) {});
}

Future<MaterialRequest> _loadRequest(
  DatabaseExecutor database,
  String id,
) async {
  final rows = await database.rawQuery(
    '''
    SELECT mr.*,
      location.display_name AS location_name,
      living.activity_name_snapshot AS living_plan_activity_name
    FROM material_requests AS mr
    LEFT JOIN project_locations AS location
      ON location.id = mr.location_id
      AND location.project_id = mr.project_id
    LEFT JOIN project_living_plan_items AS living
      ON living.id = mr.living_plan_item_id
      AND living.project_id = mr.project_id
    WHERE mr.id = ?
    LIMIT 2
    ''',
    [id],
  );
  if (rows.length != 1) {
    throw const MaterialRequestFailure('material_request_not_found');
  }
  return _mapRequest(rows.single);
}

Future<List<MaterialRequestEvent>> _loadEvents(
  DatabaseExecutor database,
  String id,
) async {
  final rows = await database.query(
    'material_request_events',
    where: 'material_request_id = ?',
    whereArgs: [id],
    orderBy: 'sequence ASC',
  );
  return List.unmodifiable(
    rows.map(
      (row) => MaterialRequestEvent(
        id: _text(row, 'id'),
        materialRequestId: _text(row, 'material_request_id'),
        projectId: _text(row, 'project_id'),
        sequence: _integer(row, 'sequence'),
        type: MaterialRequestEventType.fromStorage(_text(row, 'event_type')),
        occurredAtUtc: _timestamp(row, 'occurred_at')!,
      ),
    ),
  );
}

MaterialRequest _mapRequest(Map<String, Object?> row) => MaterialRequest(
  id: _text(row, 'id'),
  projectId: _text(row, 'project_id'),
  locationId: _optionalDatabaseText(row, 'location_id'),
  locationName: _optionalDatabaseText(row, 'location_name'),
  livingPlanItemId: _optionalDatabaseText(row, 'living_plan_item_id'),
  livingPlanActivityName: _optionalDatabaseText(
    row,
    'living_plan_activity_name',
  ),
  materialName: _text(row, 'material_name'),
  quantity: _number(row, 'quantity'),
  unit: _optionalDatabaseText(row, 'unit'),
  neededOn: _day(row, 'needed_on'),
  priority: MaterialRequestPriority.fromStorage(_text(row, 'priority')),
  description: _optionalDatabaseText(row, 'description'),
  status: MaterialRequestStatus.fromStorage(_text(row, 'status')),
  revision: _integer(row, 'revision'),
  createdAtUtc: _timestamp(row, 'created_at')!,
  updatedAtUtc: _timestamp(row, 'updated_at')!,
  statusChangedAtUtc: _timestamp(row, 'status_changed_at')!,
  requestedAtUtc: _timestamp(row, 'requested_at'),
  receivedAtUtc: _timestamp(row, 'received_at'),
  cancelledAtUtc: _timestamp(row, 'cancelled_at'),
);

bool _sameFields(MaterialRequest current, _Fields fields) =>
    current.materialName == fields.materialName &&
    current.locationId == fields.locationId &&
    current.livingPlanItemId == fields.livingPlanItemId &&
    current.quantity == fields.quantity &&
    current.unit == fields.unit &&
    current.neededOn == fields.neededOn &&
    current.priority == fields.priority &&
    current.description == fields.description;

bool _transitionAllowed(
  MaterialRequestStatus current,
  MaterialRequestStatus target,
) => switch (current) {
  MaterialRequestStatus.needed =>
    target == MaterialRequestStatus.requested ||
        target == MaterialRequestStatus.cancelled,
  MaterialRequestStatus.requested =>
    target == MaterialRequestStatus.received ||
        target == MaterialRequestStatus.cancelled,
  MaterialRequestStatus.received ||
  MaterialRequestStatus.cancelled => target == MaterialRequestStatus.needed,
};

Map<String, Object?> _transitionTimestamps(
  MaterialRequest current,
  MaterialRequestStatus target,
  String now,
) => switch (target) {
  MaterialRequestStatus.needed => {
    'requested_at': null,
    'received_at': null,
    'cancelled_at': null,
  },
  MaterialRequestStatus.requested => {
    'requested_at': now,
    'received_at': null,
    'cancelled_at': null,
  },
  MaterialRequestStatus.received => {
    'requested_at': current.requestedAtUtc,
    'received_at': now,
    'cancelled_at': null,
  },
  MaterialRequestStatus.cancelled => {
    'requested_at': current.requestedAtUtc,
    'received_at': null,
    'cancelled_at': now,
  },
};

String _uuid(String value, String code) {
  if (!RecordId.isUuid(value)) throw MaterialRequestFailure(code);
  return value;
}

String? _optionalUuid(String? value, String code) =>
    value == null ? null : _uuid(value, code);

int _validRevision(int value) {
  if (value < 1) {
    throw const MaterialRequestFailure('material_request_invalid_revision');
  }
  return value;
}

String? _optionalText(String? value, int maxLength) {
  if (value == null) return null;
  final exact = value.trim();
  if (exact.isEmpty || exact.length > maxLength) {
    throw const MaterialRequestFailure('material_request_invalid_text');
  }
  return exact;
}

String _text(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! String || value.isEmpty || value != value.trim()) {
    throw const MaterialRequestFailure('material_request_corrupt_row');
  }
  return value;
}

String? _optionalDatabaseText(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String || value.isEmpty || value != value.trim()) {
    throw const MaterialRequestFailure('material_request_corrupt_row');
  }
  return value;
}

int _integer(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is! int || value < 1) {
    throw const MaterialRequestFailure('material_request_corrupt_row');
  }
  return value;
}

double? _number(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite || value <= 0) {
    throw const MaterialRequestFailure('material_request_corrupt_row');
  }
  return value.toDouble();
}

String? _day(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String) {
    throw const MaterialRequestFailure('material_request_corrupt_row');
  }
  try {
    return CseTimeCodec.validateIstanbulDay(value);
  } on Object {
    throw const MaterialRequestFailure('material_request_corrupt_row');
  }
}

String? _timestamp(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is! String) {
    throw const MaterialRequestFailure('material_request_corrupt_row');
  }
  try {
    CseTimeCodec.decodeCanonicalUtc(value);
    return value;
  } on Object {
    throw const MaterialRequestFailure('material_request_corrupt_row');
  }
}

Map<String, Object?> _jsonObject(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, Object?>) return decoded;
  } on Object {
    // Converted to a typed fail-closed result below.
  }
  throw const MaterialRequestFailure('material_request_corrupt_event');
}
