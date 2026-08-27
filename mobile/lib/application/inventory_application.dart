import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:crypto/crypto.dart' as hashes;
import 'package:sqflite/sqflite.dart';

typedef InventoryWriteBoundaryHook = Future<void> Function();

abstract interface class InventoryApplicationPort {
  Future<InventoryMutationResult> createSketch(
    CreateInventorySketchCommand command,
  );
  Future<InventoryMutationResult> autosaveSketchDraft(
    AutosaveInventorySketchDraftCommand command,
  );
  Future<InventoryMutationResult> startSketchEdit(
    StartInventorySketchEditCommand command,
  );
  Future<InventoryMutationResult> finalizeSketch(
    FinalizeInventorySketchCommand command,
  );
  Future<InventoryMutationResult> abandonSketchDraft(
    AbandonInventorySketchDraftCommand command,
  );
  Future<InventoryMutationResult> archiveSketch(
    ArchiveInventorySketchCommand command,
  );
  Future<InventoryMutationResult> unarchiveSketch(
    UnarchiveInventorySketchCommand command,
  );
  Future<InventoryMutationResult> createAsset(
    CreateInventoryAssetCommand command,
  );
  Future<InventoryMutationResult> updateAsset(
    UpdateInventoryAssetCommand command,
  );
  Future<InventoryMutationResult> changeAssetStatus(
    ChangeInventoryAssetStatusCommand command,
  );
  Future<InventoryMutationResult> changeAssetQuantity(
    ChangeInventoryAssetQuantityCommand command,
  );
  Future<InventoryMutationResult> archiveAsset(
    ArchiveInventoryAssetCommand command,
  );
  Future<InventoryMutationResult> unarchiveAsset(
    UnarchiveInventoryAssetCommand command,
  );
  Future<InventoryMutationResult> movePlacement(
    MoveInventoryPlacementCommand command,
  );

  Future<InventoryAvailability> loadAvailability(String projectId);
  Future<InventoryPrimarySketchProjection?> loadPrimarySketch(String projectId);
  Future<InventoryAssetProjection> loadAsset({
    required String projectId,
    required String assetId,
  });
  Future<List<InventoryAssetProjection>> listAssets({
    required String projectId,
    bool includeArchived = false,
  });
  Future<List<InventoryPlacementRecord>> listPlacementVersions({
    required String projectId,
    required String assetId,
    required String placementKey,
  });
  Future<List<InventoryEventRecord>> listAssetHistory({
    required String projectId,
    required String assetId,
  });
}

/// Opens the active SQLite database for one complete operation and closes it
/// afterwards so backup/restore replacement cannot leave a stale handle.
class SqliteInventoryApplication implements InventoryApplicationPort {
  SqliteInventoryApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.clock,
    RecordIdFactory? idFactory,
  }) : idFactory = idFactory ?? RecordId.randomUuid;

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;
  final RecordIdFactory idFactory;
  Future<void> _operationTail = Future<void>.value();

  Future<T> _withApplication<T>(
    Future<T> Function(InventoryApplication application) operation,
  ) {
    final completer = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await _runOperation(operation));
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<T> _runOperation<T>(
    Future<T> Function(InventoryApplication application) operation,
  ) async {
    final database = AppDatabase(
      path: databasePath,
      factory: databaseFactory,
      clock: clock,
    );
    await database.open();
    try {
      return await operation(
        InventoryApplication(
          database: database,
          clock: clock,
          idFactory: idFactory,
        ),
      );
    } finally {
      await database.close();
    }
  }

  @override
  Future<InventoryMutationResult> createSketch(
    CreateInventorySketchCommand command,
  ) => _withApplication((app) => app.createSketch(command));
  @override
  Future<InventoryMutationResult> autosaveSketchDraft(
    AutosaveInventorySketchDraftCommand command,
  ) => _withApplication((app) => app.autosaveSketchDraft(command));
  @override
  Future<InventoryMutationResult> startSketchEdit(
    StartInventorySketchEditCommand command,
  ) => _withApplication((app) => app.startSketchEdit(command));
  @override
  Future<InventoryMutationResult> finalizeSketch(
    FinalizeInventorySketchCommand command,
  ) => _withApplication((app) => app.finalizeSketch(command));
  @override
  Future<InventoryMutationResult> abandonSketchDraft(
    AbandonInventorySketchDraftCommand command,
  ) => _withApplication((app) => app.abandonSketchDraft(command));
  @override
  Future<InventoryMutationResult> archiveSketch(
    ArchiveInventorySketchCommand command,
  ) => _withApplication((app) => app.archiveSketch(command));
  @override
  Future<InventoryMutationResult> unarchiveSketch(
    UnarchiveInventorySketchCommand command,
  ) => _withApplication((app) => app.unarchiveSketch(command));
  @override
  Future<InventoryMutationResult> createAsset(
    CreateInventoryAssetCommand command,
  ) => _withApplication((app) => app.createAsset(command));
  @override
  Future<InventoryMutationResult> updateAsset(
    UpdateInventoryAssetCommand command,
  ) => _withApplication((app) => app.updateAsset(command));
  @override
  Future<InventoryMutationResult> changeAssetStatus(
    ChangeInventoryAssetStatusCommand command,
  ) => _withApplication((app) => app.changeAssetStatus(command));
  @override
  Future<InventoryMutationResult> changeAssetQuantity(
    ChangeInventoryAssetQuantityCommand command,
  ) => _withApplication((app) => app.changeAssetQuantity(command));
  @override
  Future<InventoryMutationResult> archiveAsset(
    ArchiveInventoryAssetCommand command,
  ) => _withApplication((app) => app.archiveAsset(command));
  @override
  Future<InventoryMutationResult> unarchiveAsset(
    UnarchiveInventoryAssetCommand command,
  ) => _withApplication((app) => app.unarchiveAsset(command));
  @override
  Future<InventoryMutationResult> movePlacement(
    MoveInventoryPlacementCommand command,
  ) => _withApplication((app) => app.movePlacement(command));
  @override
  Future<InventoryAvailability> loadAvailability(String projectId) =>
      _withApplication((app) => app.loadAvailability(projectId));
  @override
  Future<InventoryPrimarySketchProjection?> loadPrimarySketch(
    String projectId,
  ) => _withApplication((app) => app.loadPrimarySketch(projectId));
  @override
  Future<InventoryAssetProjection> loadAsset({
    required String projectId,
    required String assetId,
  }) => _withApplication(
    (app) => app.loadAsset(projectId: projectId, assetId: assetId),
  );
  @override
  Future<List<InventoryAssetProjection>> listAssets({
    required String projectId,
    bool includeArchived = false,
  }) => _withApplication(
    (app) =>
        app.listAssets(projectId: projectId, includeArchived: includeArchived),
  );
  @override
  Future<List<InventoryPlacementRecord>> listPlacementVersions({
    required String projectId,
    required String assetId,
    required String placementKey,
  }) => _withApplication(
    (app) => app.listPlacementVersions(
      projectId: projectId,
      assetId: assetId,
      placementKey: placementKey,
    ),
  );
  @override
  Future<List<InventoryEventRecord>> listAssetHistory({
    required String projectId,
    required String assetId,
  }) => _withApplication(
    (app) => app.listAssetHistory(projectId: projectId, assetId: assetId),
  );
}

class InventoryApplication implements InventoryApplicationPort {
  InventoryApplication({
    required this.database,
    required this.clock,
    RecordIdFactory? idFactory,
    this.afterSourceWritesBeforeHistory,
  }) : idFactory = idFactory ?? RecordId.randomUuid;

  final AppDatabase database;
  final UtcClock clock;
  final RecordIdFactory idFactory;
  final InventoryWriteBoundaryHook? afterSourceWritesBeforeHistory;

  @override
  Future<InventoryMutationResult> createSketch(
    CreateInventorySketchCommand command,
  ) {
    _requireUuid(command.sketchId, 'inventory_invalid_sketch_id');
    _requireUuid(command.draftRevisionId, 'inventory_invalid_revision_id');
    final displayName = _boundedText(
      command.displayName,
      maximum: 80,
      code: 'inventory_invalid_sketch_name',
    );
    final geometry = InventoryGeometry.emptyDraft();
    final intent = <String, Object?>{
      'display_name': displayName,
      'draft_revision_id': command.draftRevisionId,
      'geometry_sha256': geometry.sha256,
      'project_id': command.projectId,
      'sketch_id': command.sketchId,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final primary = await transaction.query(
        'inventory_sketches',
        columns: const ['id'],
        where: 'project_id = ? AND is_primary = 1 AND archived_at IS NULL',
        whereArgs: [command.projectId],
        limit: 2,
      );
      if (primary.isNotEmpty) {
        throw const InventoryFailure('inventory_primary_sketch_exists');
      }
      await _requireUnusedId(
        transaction,
        table: 'inventory_sketches',
        id: command.sketchId,
        code: 'inventory_sketch_id_conflict',
      );
      await _requireUnusedId(
        transaction,
        table: 'inventory_sketch_revisions',
        id: command.draftRevisionId,
        code: 'inventory_revision_id_conflict',
      );
      final occurredAt = _canonicalNow();
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      await transaction.insert('inventory_sketch_revisions', {
        'id': command.draftRevisionId,
        'sketch_id': command.sketchId,
        'project_id': command.projectId,
        'revision_number': 1,
        'base_revision_id': null,
        'state': InventorySketchRevisionState.draft.storageValue,
        'geometry_version': InventoryGeometryContract.geometryVersion,
        'canvas_width': InventoryGeometryContract.canvasWidth,
        'canvas_height': InventoryGeometryContract.canvasHeight,
        'geometry_json': geometry.canonicalJson,
        'geometry_sha256': geometry.sha256,
        'content_revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
        'finalized_at': null,
        'superseded_at': null,
        'abandoned_at': null,
      });
      await transaction.insert('inventory_sketches', {
        'id': command.sketchId,
        'project_id': command.projectId,
        'display_name': displayName,
        'is_primary': 1,
        'active_revision_id': null,
        'draft_revision_id': command.draftRevisionId,
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
        'archived_at': null,
      });
      final result = _result(
        command: command,
        sourceId: command.sketchId,
        sourceRevision: 1,
        supportingId: command.draftRevisionId,
        supportingRevision: 1,
        isNoOp: false,
        eventCount: 1,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.sketch,
            aggregateId: command.sketchId,
            eventType: InventoryEventType.sketchCreated,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'draft_revision_id': command.draftRevisionId,
                'geometry_sha256': geometry.sha256,
                'geometry_version': InventoryGeometryContract.geometryVersion,
                'point_count': 0,
                'polyline_count': 0,
                'segment_count': 0,
              },
            ),
          ),
        ],
      );
    });
  }

  String _requiredStoredString(
    Map<String, Object?> row,
    String key, {
    String corruptCode = 'inventory_projection_integrity_failed',
  }) {
    final value = row[key];
    if (value is! String || value.isEmpty || value != value.trim()) {
      throw InventoryFailure(corruptCode);
    }
    return value;
  }

  String? _optionalStoredString(
    Map<String, Object?> row,
    String key, {
    String corruptCode = 'inventory_projection_integrity_failed',
  }) {
    if (row[key] == null) return null;
    return _requiredStoredString(row, key, corruptCode: corruptCode);
  }

  String _requiredStoredUuid(
    Map<String, Object?> row,
    String key, {
    String corruptCode = 'inventory_projection_integrity_failed',
  }) {
    final value = _requiredStoredString(row, key, corruptCode: corruptCode);
    if (!RecordId.isUuid(value)) throw InventoryFailure(corruptCode);
    return value;
  }

  String? _optionalStoredUuid(
    Map<String, Object?> row,
    String key, {
    String corruptCode = 'inventory_projection_integrity_failed',
  }) {
    if (row[key] == null) return null;
    return _requiredStoredUuid(row, key, corruptCode: corruptCode);
  }

  int _requiredStoredInt(
    Map<String, Object?> row,
    String key, {
    String corruptCode = 'inventory_projection_integrity_failed',
  }) {
    final value = row[key];
    if (value is! int) throw InventoryFailure(corruptCode);
    return value;
  }

  int _requiredPositiveStoredInt(
    Map<String, Object?> row,
    String key, {
    String corruptCode = 'inventory_projection_integrity_failed',
  }) {
    final value = _requiredStoredInt(row, key, corruptCode: corruptCode);
    if (value < 1) throw InventoryFailure(corruptCode);
    return value;
  }

  String _requiredSha256(
    Map<String, Object?> row,
    String key, {
    String corruptCode = 'inventory_projection_integrity_failed',
  }) {
    final value = _requiredStoredString(row, key, corruptCode: corruptCode);
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
      throw InventoryFailure(corruptCode);
    }
    return value;
  }

  DateTime _storedTimestamp(
    Map<String, Object?> row,
    String key, {
    String corruptCode = 'inventory_projection_integrity_failed',
  }) => _decodeStoredTimestamp(
    _requiredStoredString(row, key, corruptCode: corruptCode),
    corruptCode: corruptCode,
  );

  DateTime? _optionalStoredTimestamp(
    Map<String, Object?> row,
    String key, {
    String corruptCode = 'inventory_projection_integrity_failed',
  }) {
    if (row[key] == null) return null;
    return _storedTimestamp(row, key, corruptCode: corruptCode);
  }

  DateTime _decodeStoredTimestamp(String value, {required String corruptCode}) {
    try {
      return CseTimeCodec.decodeCanonicalUtc(value);
    } on Object {
      throw InventoryFailure(corruptCode);
    }
  }

  String _requiredObjectString(Map<String, Object?> value, String key) {
    final item = value[key];
    if (item is! String || item.isEmpty || item != item.trim()) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    return item;
  }

  InventoryCommandType _receiptCommandType(Object? value) {
    for (final item in InventoryCommandType.values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_receipt_corrupt');
  }

  InventoryAggregateType _receiptAggregateType(Object? value) {
    for (final item in InventoryAggregateType.values) {
      if (item.storageValue == value) return item;
    }
    throw const InventoryFailure('inventory_receipt_corrupt');
  }

  Map<String, Object?> _decodeCanonicalObject(
    String value, {
    required String corruptCode,
  }) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
        throw InventoryFailure(corruptCode);
      }
      return decoded.cast<String, Object?>();
    } on InventoryFailure {
      rethrow;
    } on Object {
      throw InventoryFailure(corruptCode);
    }
  }

  String _canonicalJson(Map<String, Object?> value) =>
      jsonEncode(_canonicalJsonValue(value));

  Object? _canonicalJsonValue(Object? value) {
    if (value == null || value is String || value is bool || value is int) {
      return value;
    }
    if (value is double && value.isFinite) return value;
    if (value is List) {
      return value.map(_canonicalJsonValue).toList(growable: false);
    }
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        throw const InventoryFailure('inventory_canonical_json_invalid');
      }
      final keys = value.keys.cast<String>().toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _canonicalJsonValue(value[key]),
      };
    }
    throw const InventoryFailure('inventory_canonical_json_invalid');
  }

  String _sha256(String value) =>
      hashes.sha256.convert(utf8.encode(value)).toString();

  String _normalizeInventoryName(String value) => value
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _validRevisionStateTimestamps(
    InventorySketchRevisionState state, {
    required DateTime updatedAt,
    required DateTime? finalizedAt,
    required DateTime? supersededAt,
    required DateTime? abandonedAt,
  }) => switch (state) {
    InventorySketchRevisionState.draft =>
      finalizedAt == null && supersededAt == null && abandonedAt == null,
    InventorySketchRevisionState.active =>
      finalizedAt == updatedAt && supersededAt == null && abandonedAt == null,
    InventorySketchRevisionState.superseded =>
      finalizedAt != null &&
          supersededAt == updatedAt &&
          !supersededAt!.isBefore(finalizedAt) &&
          abandonedAt == null,
    InventorySketchRevisionState.abandoned =>
      finalizedAt == null && supersededAt == null && abandonedAt == updatedAt,
  };

  bool _eventMatchesAggregate(
    InventoryEventType eventType,
    InventoryAggregateType aggregateType,
  ) => switch (aggregateType) {
    InventoryAggregateType.sketch => eventType.storageValue.startsWith(
      'inventory.sketch_',
    ),
    InventoryAggregateType.asset => eventType.storageValue.startsWith(
      'inventory.asset_',
    ),
    InventoryAggregateType.placement => eventType.storageValue.startsWith(
      'inventory.placement_',
    ),
  };

  Future<InventoryMutationResult> _runMutation(
    InventoryMutationCommand command,
    Map<String, Object?> intent,
    Future<InventoryMutationResult> Function(
      Transaction transaction,
      String intentSha256,
    )
    body,
  ) async {
    _requireUuid(command.operationId, 'inventory_invalid_operation_id');
    _requireIdentity(command.projectId, 'inventory_invalid_project_id');
    _requireIdentity(
      command.primaryAggregateId,
      'inventory_invalid_aggregate_id',
    );
    final intentJson = _canonicalJson(intent);
    final intentSha256 = _sha256(intentJson);
    try {
      return await database.database.transaction((transaction) async {
        final replay = await _tryReplay(
          transaction,
          command: command,
          intentSha256: intentSha256,
        );
        if (replay != null) return replay;
        await _requireProjectAvailable(transaction, command.projectId);
        return body(transaction, intentSha256);
      });
    } on InventoryFailure {
      rethrow;
    } on InventoryGeometryFailure {
      throw const InventoryFailure(InventoryGeometryFailure.safeCode);
    } on DatabaseException {
      throw const InventoryFailure('inventory_persistence_failed');
    } on Object {
      throw const InventoryFailure('inventory_persistence_failed');
    }
  }

  Future<T> _guardRead<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on InventoryFailure {
      rethrow;
    } on InventoryGeometryFailure {
      throw const InventoryFailure(InventoryGeometryFailure.safeCode);
    } on DatabaseException {
      throw const InventoryFailure('inventory_persistence_failed');
    } on Object {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
  }

  Future<InventoryMutationResult> _finishMutation(
    Transaction transaction, {
    required InventoryMutationCommand command,
    required String intentSha256,
    required InventoryMutationResult result,
    required List<_PendingInventoryEvent> events,
  }) async {
    if (result.operationId != command.operationId ||
        result.commandType != command.commandType ||
        result.projectId != command.projectId ||
        result.primaryAggregateType != command.primaryAggregateType ||
        result.primaryAggregateId != command.primaryAggregateId ||
        result.eventCount != events.length ||
        result.isNoOp != events.isEmpty) {
      throw const InventoryFailure('inventory_result_integrity_failed');
    }
    final aggregateKeys = <String>{};
    for (final event in events) {
      final key = '${event.aggregateType.storageValue}:${event.aggregateId}';
      if (!aggregateKeys.add(key)) {
        throw const InventoryFailure('inventory_history_integrity_failed');
      }
    }
    if (events.isNotEmpty) {
      await afterSourceWritesBeforeHistory?.call();
    }
    final resultJson = _canonicalResultJson(result);
    await transaction.insert('inventory_command_receipts', {
      'id': command.operationId,
      'project_id': command.projectId,
      'command_type': command.commandType.storageValue,
      'primary_aggregate_type': command.primaryAggregateType.storageValue,
      'primary_aggregate_id': command.primaryAggregateId,
      'intent_sha256': intentSha256,
      'result_json': resultJson,
      'result_sha256': _sha256(resultJson),
      'is_no_op': result.isNoOp ? 1 : 0,
      'event_count': result.eventCount,
      'created_at': CseTimeCodec.encodeUtc(result.resultAt),
    });
    for (final event in events) {
      final eventId = idFactory();
      _requireUuid(eventId, 'inventory_invalid_event_id');
      final sequenceRows = await transaction.rawQuery(
        'SELECT COALESCE(MAX(sequence), 0) AS value '
        'FROM inventory_events WHERE aggregate_type = ? AND aggregate_id = ?',
        [event.aggregateType.storageValue, event.aggregateId],
      );
      if (sequenceRows.length != 1) {
        throw const InventoryFailure('inventory_history_integrity_failed');
      }
      final currentSequence = sequenceRows.single['value'];
      if (currentSequence is! int || currentSequence < 0) {
        throw const InventoryFailure('inventory_history_integrity_failed');
      }
      final payloadJson = _canonicalJson(event.payload);
      await transaction.insert('inventory_events', {
        'id': eventId,
        'operation_id': command.operationId,
        'project_id': command.projectId,
        'aggregate_type': event.aggregateType.storageValue,
        'aggregate_id': event.aggregateId,
        'sequence': currentSequence + 1,
        'event_type': event.eventType.storageValue,
        'occurred_at': CseTimeCodec.encodeUtc(result.resultAt),
        'payload_json': payloadJson,
        'payload_sha256': _sha256(payloadJson),
      });
    }
    final replay = await _tryReplay(
      transaction,
      command: command,
      intentSha256: intentSha256,
    );
    if (replay == null ||
        _canonicalResultJson(replay) != _canonicalResultJson(result)) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    return replay;
  }

  Future<InventoryMutationResult?> _tryReplay(
    Transaction transaction, {
    required InventoryMutationCommand command,
    required String intentSha256,
  }) async {
    final rows = await transaction.query(
      'inventory_command_receipts',
      where: 'id = ?',
      whereArgs: [command.operationId],
      limit: 2,
    );
    if (rows.isEmpty) return null;
    if (rows.length != 1) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    final row = rows.single;
    final storedProjectId = _requiredStoredString(
      row,
      'project_id',
      corruptCode: 'inventory_receipt_corrupt',
    );
    final storedCommandType = _receiptCommandType(row['command_type']);
    final storedAggregateType = _receiptAggregateType(
      row['primary_aggregate_type'],
    );
    final storedAggregateId = _requiredStoredString(
      row,
      'primary_aggregate_id',
      corruptCode: 'inventory_receipt_corrupt',
    );
    final storedIntentSha256 = _requiredSha256(
      row,
      'intent_sha256',
      corruptCode: 'inventory_receipt_corrupt',
    );
    final resultJson = _requiredStoredString(
      row,
      'result_json',
      corruptCode: 'inventory_receipt_corrupt',
    );
    final resultSha256 = _requiredSha256(
      row,
      'result_sha256',
      corruptCode: 'inventory_receipt_corrupt',
    );
    final isNoOpValue = row['is_no_op'];
    final eventCount = row['event_count'];
    final createdAt = _storedTimestamp(
      row,
      'created_at',
      corruptCode: 'inventory_receipt_corrupt',
    );
    if ((isNoOpValue != 0 && isNoOpValue != 1) ||
        eventCount is! int ||
        eventCount < 0 ||
        (isNoOpValue == 1 && eventCount != 0) ||
        (isNoOpValue == 0 && eventCount < 1) ||
        _sha256(resultJson) != resultSha256) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    final decoded = _decodeCanonicalObject(
      resultJson,
      corruptCode: 'inventory_receipt_corrupt',
    );
    if (_canonicalJson(decoded) != resultJson) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    final result = _resultFromObject(decoded);
    if (result.resultAt != createdAt ||
        result.operationId != command.operationId ||
        result.projectId != storedProjectId ||
        result.commandType != storedCommandType ||
        result.primaryAggregateType != storedAggregateType ||
        result.primaryAggregateId != storedAggregateId ||
        result.isNoOp != (isNoOpValue == 1) ||
        result.eventCount != eventCount) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    final eventRows = await transaction.query(
      'inventory_events',
      where: 'operation_id = ?',
      whereArgs: [command.operationId],
      orderBy: 'aggregate_type ASC, aggregate_id ASC',
    );
    if (eventRows.length != eventCount) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    for (final eventRow in eventRows) {
      final event = _eventFromRow(eventRow);
      if (event.operationId != command.operationId ||
          event.projectId != storedProjectId ||
          event.occurredAt != result.resultAt) {
        throw const InventoryFailure('inventory_receipt_corrupt');
      }
    }
    await _validateReplayIdentity(transaction, result);
    if (storedProjectId != command.projectId ||
        storedCommandType != command.commandType ||
        storedAggregateType != command.primaryAggregateType ||
        storedAggregateId != command.primaryAggregateId ||
        storedIntentSha256 != intentSha256) {
      throw const InventoryFailure('inventory_operation_id_conflict');
    }
    return result;
  }

  Future<void> _validateReplayIdentity(
    Transaction transaction,
    InventoryMutationResult result,
  ) async {
    final projectRows = await transaction.query(
      'projects',
      columns: const ['id'],
      where: 'id = ?',
      whereArgs: [result.projectId],
      limit: 2,
    );
    if (projectRows.length != 1) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    Future<bool> sourceExists(String table, String id) async {
      final rows = await transaction.query(
        table,
        columns: const ['id'],
        where: 'id = ? AND project_id = ?',
        whereArgs: [id, result.projectId],
        limit: 2,
      );
      return rows.length == 1;
    }

    final sketchCommand = switch (result.commandType) {
      InventoryCommandType.sketchCreate ||
      InventoryCommandType.sketchDraftAutosave ||
      InventoryCommandType.sketchEditStart ||
      InventoryCommandType.sketchFinalize ||
      InventoryCommandType.sketchDraftAbandon ||
      InventoryCommandType.sketchArchive ||
      InventoryCommandType.sketchUnarchive => true,
      _ => false,
    };
    final sourceExistsForCommand = await sourceExists(
      sketchCommand ? 'inventory_sketches' : 'inventory_assets',
      result.sourceId,
    );
    if (!sourceExistsForCommand) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    if (result.supportingId != null) {
      final supportingExists = await sourceExists(
        sketchCommand
            ? 'inventory_sketch_revisions'
            : 'inventory_asset_placements',
        result.supportingId!,
      );
      if (!supportingExists) {
        throw const InventoryFailure('inventory_receipt_corrupt');
      }
    }
    if (result.primaryAggregateType == InventoryAggregateType.placement) {
      final rows = await transaction.query(
        'inventory_asset_placements',
        columns: const ['id'],
        where: 'placement_key = ? AND project_id = ?',
        whereArgs: [result.primaryAggregateId, result.projectId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const InventoryFailure('inventory_receipt_corrupt');
      }
    }
  }

  String _canonicalResultJson(InventoryMutationResult result) =>
      _canonicalJson(<String, Object?>{
        'command_type': result.commandType.storageValue,
        'event_count': result.eventCount,
        'is_no_op': result.isNoOp,
        'operation_id': result.operationId,
        'primary_aggregate_id': result.primaryAggregateId,
        'primary_aggregate_type': result.primaryAggregateType.storageValue,
        'project_id': result.projectId,
        'result_at': CseTimeCodec.encodeUtc(result.resultAt),
        'source_id': result.sourceId,
        'source_revision': result.sourceRevision,
        'supporting_id': result.supportingId,
        'supporting_revision': result.supportingRevision,
      });

  InventoryMutationResult _resultFromObject(Map<String, Object?> value) {
    const keys = <String>{
      'command_type',
      'event_count',
      'is_no_op',
      'operation_id',
      'primary_aggregate_id',
      'primary_aggregate_type',
      'project_id',
      'result_at',
      'source_id',
      'source_revision',
      'supporting_id',
      'supporting_revision',
    };
    if (value.keys.toSet().length != keys.length ||
        !value.keys.toSet().containsAll(keys)) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    final supportingId = value['supporting_id'];
    final supportingRevision = value['supporting_revision'];
    final eventCount = value['event_count'];
    final isNoOp = value['is_no_op'];
    final sourceRevision = value['source_revision'];
    if ((supportingId != null && supportingId is! String) ||
        (supportingRevision != null && supportingRevision is! int) ||
        eventCount is! int ||
        eventCount < 0 ||
        isNoOp is! bool ||
        sourceRevision is! int ||
        sourceRevision < 1) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    final resultAtRaw = value['result_at'];
    if (resultAtRaw is! String) {
      throw const InventoryFailure('inventory_receipt_corrupt');
    }
    return InventoryMutationResult(
      operationId: _requiredObjectString(value, 'operation_id'),
      commandType: _receiptCommandType(value['command_type']),
      projectId: _requiredObjectString(value, 'project_id'),
      primaryAggregateType: _receiptAggregateType(
        value['primary_aggregate_type'],
      ),
      primaryAggregateId: _requiredObjectString(value, 'primary_aggregate_id'),
      sourceId: _requiredObjectString(value, 'source_id'),
      sourceRevision: sourceRevision,
      supportingId: supportingId as String?,
      supportingRevision: supportingRevision as int?,
      isNoOp: isNoOp,
      eventCount: eventCount,
      resultAt: _decodeStoredTimestamp(
        resultAtRaw,
        corruptCode: 'inventory_receipt_corrupt',
      ),
    );
  }

  Future<void> _requireProjectAvailable(
    Transaction transaction,
    String projectId,
  ) async {
    final rows = await transaction.query(
      'projects',
      columns: const ['id'],
      where: 'id = ? AND archived_at IS NULL',
      whereArgs: [projectId],
      limit: 2,
    );
    if (rows.length != 1) {
      throw const InventoryFailure('inventory_project_unavailable');
    }
  }

  Future<void> _requireUnusedId(
    Transaction transaction, {
    required String table,
    required String id,
    required String code,
  }) async {
    const allowedTables = <String>{
      'inventory_sketches',
      'inventory_sketch_revisions',
      'inventory_assets',
      'inventory_asset_placements',
    };
    if (!allowedTables.contains(table)) {
      throw const InventoryFailure('inventory_persistence_failed');
    }
    final rows = await transaction.query(
      table,
      columns: const ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) throw InventoryFailure(code);
  }

  Future<InventorySketchRecord> _requireSketch(
    Transaction transaction, {
    required String projectId,
    required String sketchId,
  }) async {
    final rows = await transaction.query(
      'inventory_sketches',
      where: 'id = ? AND project_id = ?',
      whereArgs: [sketchId, projectId],
      limit: 2,
    );
    if (rows.isEmpty) {
      throw const InventoryFailure('inventory_sketch_unavailable');
    }
    if (rows.length != 1) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    final sketch = _sketchFromRow(rows.single);
    if (sketch.id != sketchId || sketch.projectId != projectId) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    return sketch;
  }

  Future<InventorySketchRevisionRecord> _requireSketchRevision(
    Transaction transaction, {
    required String projectId,
    required String sketchId,
    required String revisionId,
  }) async {
    final rows = await transaction.query(
      'inventory_sketch_revisions',
      where: 'id = ? AND project_id = ? AND sketch_id = ?',
      whereArgs: [revisionId, projectId, sketchId],
      limit: 2,
    );
    if (rows.isEmpty) {
      throw const InventoryFailure('inventory_sketch_revision_unavailable');
    }
    if (rows.length != 1) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    final revision = _sketchRevisionFromRow(rows.single);
    if (revision.id != revisionId ||
        revision.sketchId != sketchId ||
        revision.projectId != projectId) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    return revision;
  }

  Future<int> _nextSketchRevisionNumber(
    Transaction transaction, {
    required String projectId,
    required String sketchId,
  }) async {
    final rows = await transaction.rawQuery(
      'SELECT COALESCE(MAX(revision_number), 0) AS value '
      'FROM inventory_sketch_revisions WHERE project_id = ? AND sketch_id = ?',
      [projectId, sketchId],
    );
    final value = rows.length == 1 ? rows.single['value'] : null;
    if (value is! int || value < 0) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    return value + 1;
  }

  Future<InventorySketchRecord> _requireActivePrimarySketch(
    Transaction transaction, {
    required String projectId,
    required String sketchId,
    required String activeRevisionId,
  }) async {
    final sketch = await _requireSketch(
      transaction,
      projectId: projectId,
      sketchId: sketchId,
    );
    if (!sketch.isPrimary ||
        sketch.archivedAt != null ||
        sketch.activeRevisionId != activeRevisionId) {
      throw const InventoryFailure('inventory_active_revision_unavailable');
    }
    final active = await _requireSketchRevision(
      transaction,
      projectId: projectId,
      sketchId: sketchId,
      revisionId: activeRevisionId,
    );
    if (active.state != InventorySketchRevisionState.active) {
      throw const InventoryFailure('inventory_active_revision_unavailable');
    }
    return sketch;
  }

  Future<InventorySketchRecord> _requireCurrentActiveSketch(
    Transaction transaction, {
    required String projectId,
    required String sketchId,
  }) async {
    final sketch = await _requireSketch(
      transaction,
      projectId: projectId,
      sketchId: sketchId,
    );
    final activeRevisionId = sketch.activeRevisionId;
    if (!sketch.isPrimary ||
        sketch.archivedAt != null ||
        activeRevisionId == null) {
      throw const InventoryFailure('inventory_active_revision_unavailable');
    }
    await _requireActivePrimarySketch(
      transaction,
      projectId: projectId,
      sketchId: sketchId,
      activeRevisionId: activeRevisionId,
    );
    return sketch;
  }

  Future<InventoryAssetRecord> _requireAsset(
    Transaction transaction, {
    required String projectId,
    required String assetId,
  }) async {
    final rows = await transaction.query(
      'inventory_assets',
      where: 'id = ? AND project_id = ?',
      whereArgs: [assetId, projectId],
      limit: 2,
    );
    if (rows.isEmpty) {
      throw const InventoryFailure('inventory_asset_unavailable');
    }
    if (rows.length != 1) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    final asset = _assetFromRow(rows.single);
    if (asset.id != assetId || asset.projectId != projectId) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    return asset;
  }

  Future<List<Map<String, Object?>>> _loadActivePlacementRows(
    Transaction transaction, {
    required String projectId,
    required String assetId,
  }) => transaction.query(
    'inventory_asset_placements',
    where: 'project_id = ? AND asset_id = ? AND ended_at IS NULL',
    whereArgs: [projectId, assetId],
    orderBy: 'placement_key ASC, sequence ASC, id ASC',
  );

  Future<InventoryPlacementRecord?> _loadSoleActivePlacementOrNull(
    Transaction transaction, {
    required String projectId,
    required String assetId,
  }) async {
    final rows = await _loadActivePlacementRows(
      transaction,
      projectId: projectId,
      assetId: assetId,
    );
    if (rows.length > 1) {
      throw const InventoryFailure(
        'inventory_multiple_placements_not_supported_in_v1',
      );
    }
    return rows.isEmpty ? null : _placementFromRow(rows.single);
  }

  Future<InventoryPlacementRecord> _requireSoleActivePlacement(
    Transaction transaction, {
    required String projectId,
    required String assetId,
  }) async {
    final placement = await _loadSoleActivePlacementOrNull(
      transaction,
      projectId: projectId,
      assetId: assetId,
    );
    if (placement == null) {
      throw const InventoryFailure('inventory_active_placement_unavailable');
    }
    return placement;
  }

  Future<InventoryAssetProjection> _loadAssetProjection(
    Transaction transaction, {
    required String projectId,
    required String assetId,
  }) async {
    final asset = await _requireAsset(
      transaction,
      projectId: projectId,
      assetId: assetId,
    );
    final placement = await _loadSoleActivePlacementOrNull(
      transaction,
      projectId: projectId,
      assetId: assetId,
    );
    if ((asset.archivedAt != null && placement != null) ||
        (asset.archivedAt == null && placement == null) ||
        (placement != null && placement.quantity != asset.totalQuantity)) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    return InventoryAssetProjection(asset: asset, activePlacement: placement);
  }

  Future<void> _insertPlacementSuccessor(
    Transaction transaction, {
    required String id,
    required InventoryPlacementRecord predecessor,
    String? sketchId,
    required String provenanceRevisionId,
    required int quantity,
    required int x,
    required int y,
    required String timestamp,
  }) async {
    await transaction.insert('inventory_asset_placements', {
      'id': id,
      'placement_key': predecessor.placementKey,
      'project_id': predecessor.projectId,
      'asset_id': predecessor.assetId,
      'sketch_id': sketchId ?? predecessor.sketchId,
      'provenance_revision_id': provenanceRevisionId,
      'sequence': predecessor.sequence + 1,
      'x': x,
      'y': y,
      'quantity': quantity,
      'created_at': timestamp,
      'ended_at': null,
      'end_reason': null,
      'supersedes_placement_id': predecessor.id,
    });
  }

  Future<List<InventoryEventRecord>> _loadAggregateEvents(
    Transaction transaction, {
    required String projectId,
    required InventoryAggregateType aggregateType,
    required String aggregateId,
  }) async {
    final rows = await transaction.query(
      'inventory_events',
      where: 'project_id = ? AND aggregate_type = ? AND aggregate_id = ?',
      whereArgs: [projectId, aggregateType.storageValue, aggregateId],
      orderBy: 'sequence ASC, id ASC',
    );
    final events = rows.map(_eventFromRow).toList(growable: false);
    for (var index = 0; index < events.length; index += 1) {
      final event = events[index];
      if (event.projectId != projectId ||
          event.aggregateType != aggregateType ||
          event.aggregateId != aggregateId ||
          event.sequence != index + 1) {
        throw const InventoryFailure('inventory_history_integrity_failed');
      }
    }
    return events;
  }

  InventorySketchRecord _sketchFromRow(Map<String, Object?> row) {
    final id = _requiredStoredUuid(row, 'id');
    final projectId = _requiredStoredString(row, 'project_id');
    final displayName = _requiredStoredString(row, 'display_name');
    final isPrimaryValue = row['is_primary'];
    final activeRevisionId = _optionalStoredUuid(row, 'active_revision_id');
    final draftRevisionId = _optionalStoredUuid(row, 'draft_revision_id');
    final revision = _requiredPositiveStoredInt(row, 'revision');
    final createdAt = _storedTimestamp(row, 'created_at');
    final updatedAt = _storedTimestamp(row, 'updated_at');
    final archivedAt = _optionalStoredTimestamp(row, 'archived_at');
    if ((isPrimaryValue != 0 && isPrimaryValue != 1) ||
        displayName != displayName.trim() ||
        displayName.isEmpty ||
        displayName.length > 80 ||
        (activeRevisionId == draftRevisionId && activeRevisionId != null) ||
        updatedAt.isBefore(createdAt) ||
        (archivedAt != null &&
            (archivedAt != updatedAt || isPrimaryValue != 0))) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    return InventorySketchRecord(
      id: id,
      projectId: projectId,
      displayName: displayName,
      isPrimary: isPrimaryValue == 1,
      activeRevisionId: activeRevisionId,
      draftRevisionId: draftRevisionId,
      revision: revision,
      createdAt: createdAt,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
    );
  }

  InventorySketchRevisionRecord _sketchRevisionFromRow(
    Map<String, Object?> row,
  ) {
    final id = _requiredStoredUuid(row, 'id');
    final sketchId = _requiredStoredUuid(row, 'sketch_id');
    final projectId = _requiredStoredString(row, 'project_id');
    final revisionNumber = _requiredPositiveStoredInt(row, 'revision_number');
    final baseRevisionId = _optionalStoredUuid(row, 'base_revision_id');
    final state = InventorySketchRevisionState.fromStorage(row['state']);
    final geometryVersion = row['geometry_version'];
    final canvasWidth = row['canvas_width'];
    final canvasHeight = row['canvas_height'];
    final geometryJson = _requiredStoredString(row, 'geometry_json');
    final geometrySha256 = _requiredSha256(row, 'geometry_sha256');
    final geometry = InventoryGeometry.decode(
      geometryJson,
      expectedSha256: geometrySha256,
    );
    final contentRevision = _requiredPositiveStoredInt(row, 'content_revision');
    final createdAt = _storedTimestamp(row, 'created_at');
    final updatedAt = _storedTimestamp(row, 'updated_at');
    final finalizedAt = _optionalStoredTimestamp(row, 'finalized_at');
    final supersededAt = _optionalStoredTimestamp(row, 'superseded_at');
    final abandonedAt = _optionalStoredTimestamp(row, 'abandoned_at');
    if (geometryVersion != InventoryGeometryContract.geometryVersion ||
        canvasWidth != InventoryGeometryContract.canvasWidth ||
        canvasHeight != InventoryGeometryContract.canvasHeight ||
        geometry.canonicalJson != geometryJson ||
        baseRevisionId == id ||
        updatedAt.isBefore(createdAt) ||
        !_validRevisionStateTimestamps(
          state,
          updatedAt: updatedAt,
          finalizedAt: finalizedAt,
          supersededAt: supersededAt,
          abandonedAt: abandonedAt,
        )) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    return InventorySketchRevisionRecord(
      id: id,
      sketchId: sketchId,
      projectId: projectId,
      revisionNumber: revisionNumber,
      baseRevisionId: baseRevisionId,
      state: state,
      geometry: geometry,
      geometrySha256: geometrySha256,
      contentRevision: contentRevision,
      createdAt: createdAt,
      updatedAt: updatedAt,
      finalizedAt: finalizedAt,
      supersededAt: supersededAt,
      abandonedAt: abandonedAt,
    );
  }

  InventoryAssetRecord _assetFromRow(Map<String, Object?> row) {
    final id = _requiredStoredUuid(row, 'id');
    final projectId = _requiredStoredString(row, 'project_id');
    final displayName = _requiredStoredString(row, 'display_name');
    final normalizedName = _requiredStoredString(row, 'normalized_name');
    final category = InventoryCategory.fromStorage(row['category_code']);
    final otherCategoryLabel = _optionalStoredString(
      row,
      'other_category_label',
    );
    final totalQuantity = _requiredPositiveStoredInt(row, 'total_quantity');
    final status = InventoryAssetStatus.fromStorage(row['status']);
    final note = _optionalStoredString(row, 'note');
    final revision = _requiredPositiveStoredInt(row, 'revision');
    final createdAt = _storedTimestamp(row, 'created_at');
    final updatedAt = _storedTimestamp(row, 'updated_at');
    final statusChangedAt = _storedTimestamp(row, 'status_changed_at');
    final archivedAt = _optionalStoredTimestamp(row, 'archived_at');
    final validated = _validatedAssetInput(
      displayName: displayName,
      category: category,
      otherCategoryLabel: otherCategoryLabel,
      note: note,
    );
    if (validated.displayName != displayName ||
        validated.normalizedName != normalizedName ||
        validated.otherCategoryLabel != otherCategoryLabel ||
        validated.note != note ||
        totalQuantity > 1000000 ||
        updatedAt.isBefore(createdAt) ||
        statusChangedAt.isBefore(createdAt) ||
        statusChangedAt.isAfter(updatedAt) ||
        (archivedAt != null && archivedAt != updatedAt)) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    return InventoryAssetRecord(
      id: id,
      projectId: projectId,
      displayName: displayName,
      normalizedName: normalizedName,
      category: category,
      otherCategoryLabel: otherCategoryLabel,
      totalQuantity: totalQuantity,
      status: status,
      note: note,
      revision: revision,
      createdAt: createdAt,
      updatedAt: updatedAt,
      statusChangedAt: statusChangedAt,
      archivedAt: archivedAt,
    );
  }

  InventoryPlacementRecord _placementFromRow(Map<String, Object?> row) {
    final id = _requiredStoredUuid(row, 'id');
    final placementKey = _requiredStoredUuid(row, 'placement_key');
    final projectId = _requiredStoredString(row, 'project_id');
    final assetId = _requiredStoredUuid(row, 'asset_id');
    final sketchId = _requiredStoredUuid(row, 'sketch_id');
    final provenanceRevisionId = _requiredStoredUuid(
      row,
      'provenance_revision_id',
    );
    final sequence = _requiredPositiveStoredInt(row, 'sequence');
    final x = _requiredStoredInt(row, 'x');
    final y = _requiredStoredInt(row, 'y');
    final quantity = _requiredPositiveStoredInt(row, 'quantity');
    final createdAt = _storedTimestamp(row, 'created_at');
    final endedAt = _optionalStoredTimestamp(row, 'ended_at');
    final endReason = InventoryPlacementEndReason.fromStorage(
      row['end_reason'],
    );
    final supersedesPlacementId = _optionalStoredUuid(
      row,
      'supersedes_placement_id',
    );
    try {
      InventoryGeometryContract.validatePlacementCoordinate(
        x,
        maximum: InventoryGeometryContract.canvasWidth,
      );
      InventoryGeometryContract.validatePlacementCoordinate(
        y,
        maximum: InventoryGeometryContract.canvasHeight,
      );
    } on InventoryGeometryFailure {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    if (quantity > 1000000 ||
        supersedesPlacementId == id ||
        ((endedAt == null) != (endReason == null)) ||
        (endedAt != null && endedAt.isBefore(createdAt)) ||
        (sequence == 1 && supersedesPlacementId != null) ||
        (sequence > 1 && supersedesPlacementId == null)) {
      throw const InventoryFailure('inventory_projection_integrity_failed');
    }
    return InventoryPlacementRecord(
      id: id,
      placementKey: placementKey,
      projectId: projectId,
      assetId: assetId,
      sketchId: sketchId,
      provenanceRevisionId: provenanceRevisionId,
      sequence: sequence,
      x: x,
      y: y,
      quantity: quantity,
      createdAt: createdAt,
      endedAt: endedAt,
      endReason: endReason,
      supersedesPlacementId: supersedesPlacementId,
    );
  }

  InventoryEventRecord _eventFromRow(Map<String, Object?> row) {
    final id = _requiredStoredUuid(
      row,
      'id',
      corruptCode: 'inventory_history_integrity_failed',
    );
    final operationId = _requiredStoredUuid(
      row,
      'operation_id',
      corruptCode: 'inventory_history_integrity_failed',
    );
    final projectId = _requiredStoredString(
      row,
      'project_id',
      corruptCode: 'inventory_history_integrity_failed',
    );
    final aggregateType = InventoryAggregateType.fromStorage(
      row['aggregate_type'],
    );
    final aggregateId = _requiredStoredString(
      row,
      'aggregate_id',
      corruptCode: 'inventory_history_integrity_failed',
    );
    final sequence = _requiredPositiveStoredInt(
      row,
      'sequence',
      corruptCode: 'inventory_history_integrity_failed',
    );
    final eventType = InventoryEventType.fromStorage(row['event_type']);
    final occurredAt = _storedTimestamp(
      row,
      'occurred_at',
      corruptCode: 'inventory_history_integrity_failed',
    );
    final payloadJson = _requiredStoredString(
      row,
      'payload_json',
      corruptCode: 'inventory_history_integrity_failed',
    );
    final payloadSha256 = _requiredSha256(
      row,
      'payload_sha256',
      corruptCode: 'inventory_history_integrity_failed',
    );
    final payload = _decodeCanonicalObject(
      payloadJson,
      corruptCode: 'inventory_history_integrity_failed',
    );
    if (_canonicalJson(payload) != payloadJson ||
        _sha256(payloadJson) != payloadSha256 ||
        !_eventMatchesAggregate(eventType, aggregateType)) {
      throw const InventoryFailure('inventory_history_integrity_failed');
    }
    return InventoryEventRecord(
      id: id,
      operationId: operationId,
      projectId: projectId,
      aggregateType: aggregateType,
      aggregateId: aggregateId,
      sequence: sequence,
      eventType: eventType,
      occurredAt: occurredAt,
      payload: payload,
      payloadJson: payloadJson,
      payloadSha256: payloadSha256,
    );
  }

  void _requireCurrentSketchRevision(
    InventorySketchRecord sketch,
    int expectedRevision,
  ) {
    if (sketch.revision != expectedRevision) {
      throw const InventoryFailure('inventory_stale_revision');
    }
  }

  void _requireCurrentAssetRevision(
    InventoryAssetRecord asset,
    int expectedRevision,
  ) {
    if (asset.revision != expectedRevision) {
      throw const InventoryFailure('inventory_stale_revision');
    }
  }

  void _requireUnarchivedAsset(InventoryAssetRecord asset) {
    if (asset.archivedAt != null) {
      throw const InventoryFailure('inventory_asset_archived');
    }
  }

  Future<InventoryMutationResult> _finishNoOpAsset(
    Transaction transaction, {
    required InventoryMutationCommand command,
    required String intentSha256,
    required InventoryAssetRecord asset,
    InventoryPlacementRecord? placement,
  }) {
    final result = _result(
      command: command,
      sourceId: asset.id,
      sourceRevision: asset.revision,
      supportingId: placement?.id,
      supportingRevision: placement?.sequence,
      isNoOp: true,
      eventCount: 0,
      resultAt: _canonicalNow(),
    );
    return _finishMutation(
      transaction,
      command: command,
      intentSha256: intentSha256,
      result: result,
      events: const [],
    );
  }

  InventoryMutationResult _result({
    required InventoryMutationCommand command,
    required String sourceId,
    required int sourceRevision,
    required String? supportingId,
    required int? supportingRevision,
    required bool isNoOp,
    required int eventCount,
    required DateTime resultAt,
  }) => InventoryMutationResult(
    operationId: command.operationId,
    commandType: command.commandType,
    projectId: command.projectId,
    primaryAggregateType: command.primaryAggregateType,
    primaryAggregateId: command.primaryAggregateId,
    sourceId: sourceId,
    sourceRevision: sourceRevision,
    supportingId: supportingId,
    supportingRevision: supportingRevision,
    isNoOp: isNoOp,
    eventCount: eventCount,
    resultAt: resultAt,
  );

  Map<String, Object?> _eventPayload(
    InventoryMutationResult result, {
    required Map<String, Object?> values,
  }) => <String, Object?>{
    'command_type': result.commandType.storageValue,
    'operation_id': result.operationId,
    'project_id': result.projectId,
    'source_id': result.sourceId,
    'source_revision': result.sourceRevision,
    'supporting_id': result.supportingId,
    'supporting_revision': result.supportingRevision,
    ...values,
  };

  _ValidatedAssetInput _validatedAssetInput({
    required String displayName,
    required InventoryCategory category,
    required String? otherCategoryLabel,
    required String? note,
  }) {
    final cleanDisplayName = _boundedText(
      displayName,
      maximum: 120,
      code: 'inventory_invalid_asset_name',
    );
    final cleanOther = _optionalBoundedText(
      otherCategoryLabel,
      maximum: 80,
      code: 'inventory_invalid_other_category_label',
    );
    if ((category == InventoryCategory.other) != (cleanOther != null)) {
      throw const InventoryFailure('inventory_invalid_other_category_label');
    }
    final cleanNote = _optionalBoundedText(
      note,
      maximum: 1000,
      code: 'inventory_invalid_asset_note',
    );
    return _ValidatedAssetInput(
      displayName: cleanDisplayName,
      normalizedName: _normalizeInventoryName(cleanDisplayName),
      category: category,
      otherCategoryLabel: cleanOther,
      note: cleanNote,
    );
  }

  int _validatedQuantity(int value) {
    if (value < 1 || value > 1000000) {
      throw const InventoryFailure('inventory_invalid_quantity');
    }
    return value;
  }

  int _quantizedPlacementX(int value) => _quantizedPlacementCoordinate(
    value,
    maximum: InventoryGeometryContract.canvasWidth,
  );

  int _quantizedPlacementY(int value) => _quantizedPlacementCoordinate(
    value,
    maximum: InventoryGeometryContract.canvasHeight,
  );

  int _quantizedPlacementCoordinate(int value, {required int maximum}) {
    try {
      return InventoryGeometryContract.snapPlacementCoordinate(
        value,
        maximum: maximum,
      );
    } on InventoryGeometryFailure {
      throw const InventoryFailure('inventory_invalid_placement_coordinate');
    }
  }

  DateTime _canonicalNow() {
    try {
      return CseTimeCodec.decodeCanonicalUtc(CseTimeCodec.encodeUtc(clock()));
    } on Object {
      throw const InventoryFailure('inventory_invalid_clock');
    }
  }

  DateTime _canonicalNowAfter(
    DateTime first, [
    DateTime? second,
    DateTime? third,
  ]) {
    var value = _canonicalNow();
    if (value.isBefore(first)) value = first;
    if (second != null && value.isBefore(second)) value = second;
    if (third != null && value.isBefore(third)) value = third;
    return value;
  }

  void _requireIdentity(String value, String code) {
    if (value.isEmpty || value != value.trim() || value.runes.length > 255) {
      throw InventoryFailure(code);
    }
  }

  void _requireUuid(String value, String code) {
    if (!RecordId.isUuid(value)) throw InventoryFailure(code);
  }

  void _requirePositiveRevision(int value) {
    if (value < 1) {
      throw const InventoryFailure('inventory_invalid_expected_revision');
    }
  }

  String _boundedText(
    String value, {
    required int maximum,
    required String code,
  }) {
    final clean = value.trim();
    if (clean.isEmpty || clean.runes.length > maximum) {
      throw InventoryFailure(code);
    }
    return clean;
  }

  String? _optionalBoundedText(
    String? value, {
    required int maximum,
    required String code,
  }) {
    if (value == null) return null;
    final clean = value.trim();
    if (clean.isEmpty || clean.runes.length > maximum) {
      throw InventoryFailure(code);
    }
    return clean;
  }

  @override
  Future<InventoryAvailability> loadAvailability(String projectId) {
    _requireIdentity(projectId, 'inventory_invalid_project_id');
    return _guardRead(() async {
      final projects = await database.database.query(
        'projects',
        columns: const ['id'],
        where: 'id = ? AND archived_at IS NULL',
        whereArgs: [projectId],
        limit: 2,
      );
      if (projects.length > 1) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
      if (projects.isEmpty) {
        return InventoryAvailability(
          projectId: projectId,
          projectAvailable: false,
          hasPrimarySketch: false,
        );
      }
      final sketches = await database.database.query(
        'inventory_sketches',
        columns: const ['id'],
        where: 'project_id = ? AND is_primary = 1 AND archived_at IS NULL',
        whereArgs: [projectId],
        limit: 2,
      );
      if (sketches.length > 1) {
        throw const InventoryFailure('inventory_projection_integrity_failed');
      }
      return InventoryAvailability(
        projectId: projectId,
        projectAvailable: true,
        hasPrimarySketch: sketches.isNotEmpty,
      );
    });
  }

  @override
  Future<InventoryPrimarySketchProjection?> loadPrimarySketch(
    String projectId,
  ) {
    _requireIdentity(projectId, 'inventory_invalid_project_id');
    return _guardRead(
      () => database.database.transaction((transaction) async {
        await _requireProjectAvailable(transaction, projectId);
        final rows = await transaction.query(
          'inventory_sketches',
          where: 'project_id = ? AND is_primary = 1 AND archived_at IS NULL',
          whereArgs: [projectId],
          limit: 2,
        );
        if (rows.isEmpty) return null;
        if (rows.length != 1) {
          throw const InventoryFailure('inventory_projection_integrity_failed');
        }
        final sketch = _sketchFromRow(rows.single);
        if (!sketch.isPrimary || sketch.archivedAt != null) {
          throw const InventoryFailure('inventory_projection_integrity_failed');
        }
        InventorySketchRevisionRecord? active;
        InventorySketchRevisionRecord? draft;
        if (sketch.activeRevisionId != null) {
          active = await _requireSketchRevision(
            transaction,
            projectId: projectId,
            sketchId: sketch.id,
            revisionId: sketch.activeRevisionId!,
          );
          if (active.state != InventorySketchRevisionState.active) {
            throw const InventoryFailure(
              'inventory_active_revision_unavailable',
            );
          }
        }
        if (sketch.draftRevisionId != null) {
          draft = await _requireSketchRevision(
            transaction,
            projectId: projectId,
            sketchId: sketch.id,
            revisionId: sketch.draftRevisionId!,
          );
          if (draft.state != InventorySketchRevisionState.draft) {
            throw const InventoryFailure('inventory_sketch_draft_unavailable');
          }
        }
        return InventoryPrimarySketchProjection(
          sketch: sketch,
          activeRevision: active,
          draftRevision: draft,
        );
      }),
    );
  }

  @override
  Future<InventoryAssetProjection> loadAsset({
    required String projectId,
    required String assetId,
  }) {
    _requireIdentity(projectId, 'inventory_invalid_project_id');
    _requireUuid(assetId, 'inventory_invalid_asset_id');
    return _guardRead(
      () => database.database.transaction((transaction) async {
        await _requireProjectAvailable(transaction, projectId);
        return _loadAssetProjection(
          transaction,
          projectId: projectId,
          assetId: assetId,
        );
      }),
    );
  }

  @override
  Future<List<InventoryAssetProjection>> listAssets({
    required String projectId,
    bool includeArchived = false,
  }) {
    _requireIdentity(projectId, 'inventory_invalid_project_id');
    return _guardRead(
      () => database.database.transaction((transaction) async {
        await _requireProjectAvailable(transaction, projectId);
        final rows = await transaction.query(
          'inventory_assets',
          where: includeArchived
              ? 'project_id = ?'
              : 'project_id = ? AND archived_at IS NULL',
          whereArgs: [projectId],
          orderBy: 'normalized_name ASC, id ASC',
        );
        final result = <InventoryAssetProjection>[];
        String? previousName;
        String? previousId;
        for (final row in rows) {
          final asset = _assetFromRow(row);
          if (asset.projectId != projectId ||
              (previousName != null &&
                  (asset.normalizedName.compareTo(previousName) < 0 ||
                      (asset.normalizedName == previousName &&
                          asset.id.compareTo(previousId!) <= 0)))) {
            throw const InventoryFailure(
              'inventory_projection_integrity_failed',
            );
          }
          final placement = await _loadSoleActivePlacementOrNull(
            transaction,
            projectId: projectId,
            assetId: asset.id,
          );
          if ((asset.archivedAt != null && placement != null) ||
              (asset.archivedAt == null && placement == null) ||
              (placement != null &&
                  placement.quantity != asset.totalQuantity)) {
            throw const InventoryFailure(
              'inventory_projection_integrity_failed',
            );
          }
          result.add(
            InventoryAssetProjection(asset: asset, activePlacement: placement),
          );
          previousName = asset.normalizedName;
          previousId = asset.id;
        }
        return List<InventoryAssetProjection>.unmodifiable(result);
      }),
    );
  }

  @override
  Future<List<InventoryPlacementRecord>> listPlacementVersions({
    required String projectId,
    required String assetId,
    required String placementKey,
  }) {
    _requireIdentity(projectId, 'inventory_invalid_project_id');
    _requireUuid(assetId, 'inventory_invalid_asset_id');
    _requireUuid(placementKey, 'inventory_invalid_placement_key');
    return _guardRead(
      () => database.database.transaction((transaction) async {
        await _requireProjectAvailable(transaction, projectId);
        await _requireAsset(
          transaction,
          projectId: projectId,
          assetId: assetId,
        );
        final rows = await transaction.query(
          'inventory_asset_placements',
          where: 'project_id = ? AND asset_id = ? AND placement_key = ?',
          whereArgs: [projectId, assetId, placementKey],
          orderBy: 'sequence ASC, id ASC',
        );
        if (rows.isEmpty) {
          throw const InventoryFailure(
            'inventory_placement_history_unavailable',
          );
        }
        final result = rows.map(_placementFromRow).toList(growable: false);
        for (var index = 0; index < result.length; index += 1) {
          final placement = result[index];
          if (placement.sequence != index + 1 ||
              placement.projectId != projectId ||
              placement.assetId != assetId ||
              placement.placementKey != placementKey ||
              (index == 0 && placement.supersedesPlacementId != null) ||
              (index > 0 &&
                  placement.supersedesPlacementId != result[index - 1].id)) {
            throw const InventoryFailure(
              'inventory_placement_history_integrity_failed',
            );
          }
        }
        return List<InventoryPlacementRecord>.unmodifiable(result);
      }),
    );
  }

  @override
  Future<List<InventoryEventRecord>> listAssetHistory({
    required String projectId,
    required String assetId,
  }) {
    _requireIdentity(projectId, 'inventory_invalid_project_id');
    _requireUuid(assetId, 'inventory_invalid_asset_id');
    return _guardRead(
      () => database.database.transaction((transaction) async {
        await _requireProjectAvailable(transaction, projectId);
        await _requireAsset(
          transaction,
          projectId: projectId,
          assetId: assetId,
        );
        final keyRows = await transaction.query(
          'inventory_asset_placements',
          distinct: true,
          columns: const ['placement_key'],
          where: 'project_id = ? AND asset_id = ?',
          whereArgs: [projectId, assetId],
          orderBy: 'placement_key ASC',
        );
        final result = <InventoryEventRecord>[
          ...await _loadAggregateEvents(
            transaction,
            projectId: projectId,
            aggregateType: InventoryAggregateType.asset,
            aggregateId: assetId,
          ),
        ];
        for (final row in keyRows) {
          final key = _requiredStoredString(row, 'placement_key');
          result.addAll(
            await _loadAggregateEvents(
              transaction,
              projectId: projectId,
              aggregateType: InventoryAggregateType.placement,
              aggregateId: key,
            ),
          );
        }
        result.sort((left, right) {
          final occurred = right.occurredAt.compareTo(left.occurredAt);
          if (occurred != 0) return occurred;
          return left.id.compareTo(right.id);
        });
        return List<InventoryEventRecord>.unmodifiable(result);
      }),
    );
  }

  @override
  Future<InventoryMutationResult> archiveAsset(
    ArchiveInventoryAssetCommand command,
  ) {
    _requireUuid(command.assetId, 'inventory_invalid_asset_id');
    _requirePositiveRevision(command.expectedAssetRevision);
    final intent = <String, Object?>{
      'asset_id': command.assetId,
      'expected_asset_revision': command.expectedAssetRevision,
      'project_id': command.projectId,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final asset = await _requireAsset(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      _requireCurrentAssetRevision(asset, command.expectedAssetRevision);
      final activeRows = await _loadActivePlacementRows(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      if (activeRows.length > 1) {
        throw const InventoryFailure(
          'inventory_multiple_placements_not_supported_in_v1',
        );
      }
      final placement = activeRows.isEmpty
          ? null
          : _placementFromRow(activeRows.single);
      if (asset.archivedAt != null) {
        if (placement != null) {
          throw const InventoryFailure('inventory_projection_integrity_failed');
        }
        return _finishNoOpAsset(
          transaction,
          command: command,
          intentSha256: intentSha256,
          asset: asset,
        );
      }
      final occurredAt = _canonicalNowAfter(
        asset.updatedAt,
        placement?.createdAt,
      );
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      if (placement != null) {
        final ended = await transaction.update(
          'inventory_asset_placements',
          {
            'ended_at': timestamp,
            'end_reason':
                InventoryPlacementEndReason.assetArchived.storageValue,
          },
          where:
              'id = ? AND project_id = ? AND asset_id = ? '
              'AND ended_at IS NULL',
          whereArgs: [placement.id, command.projectId, command.assetId],
        );
        if (ended != 1) {
          throw const InventoryFailure('inventory_stale_placement_sequence');
        }
      }
      final updated = await transaction.update(
        'inventory_assets',
        {
          'revision': asset.revision + 1,
          'updated_at': timestamp,
          'archived_at': timestamp,
        },
        where: 'id = ? AND project_id = ? AND revision = ?',
        whereArgs: [command.assetId, command.projectId, asset.revision],
      );
      if (updated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      final eventCount = placement == null ? 1 : 2;
      final result = _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: asset.revision + 1,
        supportingId: placement?.id,
        supportingRevision: placement?.sequence,
        isNoOp: false,
        eventCount: eventCount,
        resultAt: occurredAt,
      );
      final events = <_PendingInventoryEvent>[
        _PendingInventoryEvent(
          aggregateType: InventoryAggregateType.asset,
          aggregateId: command.assetId,
          eventType: InventoryEventType.assetArchived,
          payload: _eventPayload(
            result,
            values: <String, Object?>{
              'archived_at': timestamp,
              'retired_placement_key': placement?.placementKey,
            },
          ),
        ),
      ];
      if (placement != null) {
        events.add(
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.placement,
            aggregateId: placement.placementKey,
            eventType: InventoryEventType.placementRetired,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'asset_id': command.assetId,
                'end_reason':
                    InventoryPlacementEndReason.assetArchived.storageValue,
                'placement_id': placement.id,
                'sequence': placement.sequence,
              },
            ),
          ),
        );
      }
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: events,
      );
    });
  }

  @override
  Future<InventoryMutationResult> unarchiveAsset(
    UnarchiveInventoryAssetCommand command,
  ) {
    _requireUuid(command.assetId, 'inventory_invalid_asset_id');
    _requireUuid(command.placementKey, 'inventory_invalid_placement_key');
    _requireUuid(
      command.successorPlacementId,
      'inventory_invalid_placement_id',
    );
    _requireUuid(command.sketchId, 'inventory_invalid_sketch_id');
    _requireUuid(command.activeRevisionId, 'inventory_invalid_revision_id');
    _requirePositiveRevision(command.expectedAssetRevision);
    _requirePositiveRevision(command.expectedPreviousPlacementSequence);
    final x = _quantizedPlacementX(command.x);
    final y = _quantizedPlacementY(command.y);
    final intent = <String, Object?>{
      'active_revision_id': command.activeRevisionId,
      'asset_id': command.assetId,
      'expected_asset_revision': command.expectedAssetRevision,
      'expected_previous_placement_sequence':
          command.expectedPreviousPlacementSequence,
      'placement_key': command.placementKey,
      'project_id': command.projectId,
      'sketch_id': command.sketchId,
      'successor_placement_id': command.successorPlacementId,
      'x': x,
      'y': y,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final asset = await _requireAsset(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      _requireCurrentAssetRevision(asset, command.expectedAssetRevision);
      final activeRows = await _loadActivePlacementRows(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      if (activeRows.isNotEmpty) {
        if (activeRows.length > 1) {
          throw const InventoryFailure(
            'inventory_multiple_placements_not_supported_in_v1',
          );
        }
        if (asset.archivedAt == null) {
          final placement = _placementFromRow(activeRows.single);
          if (placement.placementKey == command.placementKey &&
              placement.sequence == command.expectedPreviousPlacementSequence &&
              placement.sketchId == command.sketchId &&
              placement.provenanceRevisionId == command.activeRevisionId &&
              placement.x == x &&
              placement.y == y) {
            return _finishNoOpAsset(
              transaction,
              command: command,
              intentSha256: intentSha256,
              asset: asset,
              placement: placement,
            );
          }
        }
        throw const InventoryFailure('inventory_asset_state_invalid');
      }
      if (asset.archivedAt == null) {
        throw const InventoryFailure('inventory_asset_state_invalid');
      }
      await _requireActivePrimarySketch(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
        activeRevisionId: command.activeRevisionId,
      );
      final previousRows = await transaction.query(
        'inventory_asset_placements',
        where: 'project_id = ? AND asset_id = ?',
        whereArgs: [command.projectId, command.assetId],
        orderBy: 'sequence DESC, id ASC',
      );
      if (previousRows.isEmpty) {
        throw const InventoryFailure('inventory_placement_history_unavailable');
      }
      final placementKeys = previousRows
          .map((row) => row['placement_key'])
          .toSet();
      if (placementKeys.length != 1 ||
          placementKeys.single != command.placementKey) {
        throw const InventoryFailure(
          'inventory_multiple_placements_not_supported_in_v1',
        );
      }
      final predecessor = _placementFromRow(previousRows.first);
      if (predecessor.endedAt == null ||
          predecessor.sequence != command.expectedPreviousPlacementSequence) {
        throw const InventoryFailure('inventory_stale_placement_sequence');
      }
      await _requireUnusedId(
        transaction,
        table: 'inventory_asset_placements',
        id: command.successorPlacementId,
        code: 'inventory_placement_id_conflict',
      );
      final occurredAt = _canonicalNowAfter(
        asset.updatedAt,
        predecessor.endedAt,
      );
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      final updated = await transaction.update(
        'inventory_assets',
        {
          'revision': asset.revision + 1,
          'updated_at': timestamp,
          'archived_at': null,
        },
        where:
            'id = ? AND project_id = ? AND revision = ? '
            'AND archived_at IS NOT NULL',
        whereArgs: [command.assetId, command.projectId, asset.revision],
      );
      if (updated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      await _insertPlacementSuccessor(
        transaction,
        id: command.successorPlacementId,
        predecessor: predecessor,
        sketchId: command.sketchId,
        provenanceRevisionId: command.activeRevisionId,
        quantity: asset.totalQuantity,
        x: x,
        y: y,
        timestamp: timestamp,
      );
      final result = _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: asset.revision + 1,
        supportingId: command.successorPlacementId,
        supportingRevision: predecessor.sequence + 1,
        isNoOp: false,
        eventCount: 2,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.asset,
            aggregateId: command.assetId,
            eventType: InventoryEventType.assetUnarchived,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'placement_key': command.placementKey,
                'unarchived_at': timestamp,
              },
            ),
          ),
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.placement,
            aggregateId: command.placementKey,
            eventType: InventoryEventType.placementCreated,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'asset_id': command.assetId,
                'placement_id': command.successorPlacementId,
                'predecessor_placement_id': predecessor.id,
                'provenance_revision_id': command.activeRevisionId,
                'quantity': asset.totalQuantity,
                'sequence': predecessor.sequence + 1,
                'sketch_id': command.sketchId,
                'x': x,
                'y': y,
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> changeAssetQuantity(
    ChangeInventoryAssetQuantityCommand command,
  ) {
    _requireUuid(command.assetId, 'inventory_invalid_asset_id');
    _requireUuid(command.placementKey, 'inventory_invalid_placement_key');
    _requireUuid(
      command.successorPlacementId,
      'inventory_invalid_placement_id',
    );
    _requirePositiveRevision(command.expectedAssetRevision);
    _requirePositiveRevision(command.expectedPlacementSequence);
    final quantity = _validatedQuantity(command.totalQuantity);
    final intent = <String, Object?>{
      'asset_id': command.assetId,
      'expected_asset_revision': command.expectedAssetRevision,
      'expected_placement_sequence': command.expectedPlacementSequence,
      'placement_key': command.placementKey,
      'project_id': command.projectId,
      'successor_placement_id': command.successorPlacementId,
      'total_quantity': quantity,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final asset = await _requireAsset(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      _requireCurrentAssetRevision(asset, command.expectedAssetRevision);
      _requireUnarchivedAsset(asset);
      final placement = await _requireSoleActivePlacement(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      if (placement.placementKey != command.placementKey ||
          placement.sequence != command.expectedPlacementSequence) {
        throw const InventoryFailure('inventory_stale_placement_sequence');
      }
      if (placement.quantity != asset.totalQuantity) {
        throw const InventoryFailure(
          'inventory_multiple_placements_not_supported_in_v1',
        );
      }
      if (quantity == asset.totalQuantity) {
        return _finishNoOpAsset(
          transaction,
          command: command,
          intentSha256: intentSha256,
          asset: asset,
          placement: placement,
        );
      }
      await _requireUnusedId(
        transaction,
        table: 'inventory_asset_placements',
        id: command.successorPlacementId,
        code: 'inventory_placement_id_conflict',
      );
      final currentSketch = await _requireCurrentActiveSketch(
        transaction,
        projectId: command.projectId,
        sketchId: placement.sketchId,
      );
      final occurredAt = _canonicalNowAfter(
        asset.updatedAt,
        placement.createdAt,
      );
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      final ended = await transaction.update(
        'inventory_asset_placements',
        {
          'ended_at': timestamp,
          'end_reason':
              InventoryPlacementEndReason.quantityChanged.storageValue,
        },
        where:
            'id = ? AND project_id = ? AND asset_id = ? '
            'AND placement_key = ? AND sequence = ? AND ended_at IS NULL',
        whereArgs: [
          placement.id,
          command.projectId,
          command.assetId,
          command.placementKey,
          command.expectedPlacementSequence,
        ],
      );
      final updated = await transaction.update(
        'inventory_assets',
        {
          'total_quantity': quantity,
          'revision': asset.revision + 1,
          'updated_at': timestamp,
        },
        where: 'id = ? AND project_id = ? AND revision = ?',
        whereArgs: [command.assetId, command.projectId, asset.revision],
      );
      if (ended != 1 || updated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      await _insertPlacementSuccessor(
        transaction,
        id: command.successorPlacementId,
        predecessor: placement,
        provenanceRevisionId: currentSketch.activeRevisionId!,
        quantity: quantity,
        x: placement.x,
        y: placement.y,
        timestamp: timestamp,
      );
      final result = _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: asset.revision + 1,
        supportingId: command.successorPlacementId,
        supportingRevision: placement.sequence + 1,
        isNoOp: false,
        eventCount: 2,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.asset,
            aggregateId: command.assetId,
            eventType: InventoryEventType.assetUpdated,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'after_total_quantity': quantity,
                'before_total_quantity': asset.totalQuantity,
              },
            ),
          ),
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.placement,
            aggregateId: command.placementKey,
            eventType: InventoryEventType.placementQuantityChanged,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'after_quantity': quantity,
                'before_quantity': placement.quantity,
                'placement_id': command.successorPlacementId,
                'predecessor_placement_id': placement.id,
                'sequence': placement.sequence + 1,
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> movePlacement(
    MoveInventoryPlacementCommand command,
  ) {
    _requireUuid(command.assetId, 'inventory_invalid_asset_id');
    _requireUuid(command.placementKey, 'inventory_invalid_placement_key');
    _requireUuid(
      command.successorPlacementId,
      'inventory_invalid_placement_id',
    );
    _requireUuid(command.sketchId, 'inventory_invalid_sketch_id');
    _requireUuid(command.activeRevisionId, 'inventory_invalid_revision_id');
    _requirePositiveRevision(command.expectedPlacementSequence);
    final x = _quantizedPlacementX(command.x);
    final y = _quantizedPlacementY(command.y);
    final intent = <String, Object?>{
      'active_revision_id': command.activeRevisionId,
      'asset_id': command.assetId,
      'expected_placement_sequence': command.expectedPlacementSequence,
      'placement_key': command.placementKey,
      'project_id': command.projectId,
      'sketch_id': command.sketchId,
      'successor_placement_id': command.successorPlacementId,
      'x': x,
      'y': y,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final asset = await _requireAsset(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      _requireUnarchivedAsset(asset);
      final placement = await _requireSoleActivePlacement(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      if (placement.placementKey != command.placementKey ||
          placement.sequence != command.expectedPlacementSequence ||
          placement.sketchId != command.sketchId) {
        throw const InventoryFailure('inventory_stale_placement_sequence');
      }
      await _requireActivePrimarySketch(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
        activeRevisionId: command.activeRevisionId,
      );
      if (placement.x == x && placement.y == y) {
        final result = _result(
          command: command,
          sourceId: command.assetId,
          sourceRevision: asset.revision,
          supportingId: placement.id,
          supportingRevision: placement.sequence,
          isNoOp: true,
          eventCount: 0,
          resultAt: _canonicalNow(),
        );
        return _finishMutation(
          transaction,
          command: command,
          intentSha256: intentSha256,
          result: result,
          events: const [],
        );
      }
      await _requireUnusedId(
        transaction,
        table: 'inventory_asset_placements',
        id: command.successorPlacementId,
        code: 'inventory_placement_id_conflict',
      );
      final occurredAt = _canonicalNowAfter(
        asset.updatedAt,
        placement.createdAt,
      );
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      final ended = await transaction.update(
        'inventory_asset_placements',
        {
          'ended_at': timestamp,
          'end_reason': InventoryPlacementEndReason.moved.storageValue,
        },
        where:
            'id = ? AND project_id = ? AND asset_id = ? '
            'AND placement_key = ? AND sequence = ? AND ended_at IS NULL',
        whereArgs: [
          placement.id,
          command.projectId,
          command.assetId,
          command.placementKey,
          command.expectedPlacementSequence,
        ],
      );
      if (ended != 1) {
        throw const InventoryFailure('inventory_stale_placement_sequence');
      }
      await _insertPlacementSuccessor(
        transaction,
        id: command.successorPlacementId,
        predecessor: placement,
        provenanceRevisionId: command.activeRevisionId,
        quantity: placement.quantity,
        x: x,
        y: y,
        timestamp: timestamp,
      );
      final result = _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: asset.revision,
        supportingId: command.successorPlacementId,
        supportingRevision: placement.sequence + 1,
        isNoOp: false,
        eventCount: 1,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.placement,
            aggregateId: command.placementKey,
            eventType: InventoryEventType.placementMoved,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'after_x': x,
                'after_y': y,
                'before_x': placement.x,
                'before_y': placement.y,
                'placement_id': command.successorPlacementId,
                'predecessor_placement_id': placement.id,
                'sequence': placement.sequence + 1,
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> abandonSketchDraft(
    AbandonInventorySketchDraftCommand command,
  ) {
    _requireUuid(command.sketchId, 'inventory_invalid_sketch_id');
    _requireUuid(command.draftRevisionId, 'inventory_invalid_revision_id');
    _requirePositiveRevision(command.expectedSketchRevision);
    final intent = <String, Object?>{
      'draft_revision_id': command.draftRevisionId,
      'expected_sketch_revision': command.expectedSketchRevision,
      'project_id': command.projectId,
      'sketch_id': command.sketchId,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final sketch = await _requireSketch(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
      );
      _requireCurrentSketchRevision(sketch, command.expectedSketchRevision);
      if (sketch.archivedAt != null ||
          sketch.draftRevisionId != command.draftRevisionId) {
        throw const InventoryFailure('inventory_sketch_draft_unavailable');
      }
      final draft = await _requireSketchRevision(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
        revisionId: command.draftRevisionId,
      );
      if (draft.state != InventorySketchRevisionState.draft) {
        throw const InventoryFailure('inventory_sketch_draft_unavailable');
      }
      final occurredAt = _canonicalNowAfter(sketch.updatedAt, draft.updatedAt);
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      final abandoned = await transaction.update(
        'inventory_sketch_revisions',
        {
          'state': InventorySketchRevisionState.abandoned.storageValue,
          'updated_at': timestamp,
          'abandoned_at': timestamp,
        },
        where: 'id = ? AND project_id = ? AND sketch_id = ? AND state = ?',
        whereArgs: [
          command.draftRevisionId,
          command.projectId,
          command.sketchId,
          InventorySketchRevisionState.draft.storageValue,
        ],
      );
      final updated = await transaction.update(
        'inventory_sketches',
        {
          'draft_revision_id': null,
          'revision': sketch.revision + 1,
          'updated_at': timestamp,
        },
        where: 'id = ? AND project_id = ? AND revision = ?',
        whereArgs: [command.sketchId, command.projectId, sketch.revision],
      );
      if (abandoned != 1 || updated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      final result = _result(
        command: command,
        sourceId: command.sketchId,
        sourceRevision: sketch.revision + 1,
        supportingId: command.draftRevisionId,
        supportingRevision: draft.contentRevision,
        isNoOp: false,
        eventCount: 1,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.sketch,
            aggregateId: command.sketchId,
            eventType: InventoryEventType.sketchDraftAbandoned,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'active_revision_id': sketch.activeRevisionId,
                'draft_revision_id': command.draftRevisionId,
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> archiveSketch(
    ArchiveInventorySketchCommand command,
  ) => _changeSketchArchiveState(command, archive: true);

  @override
  Future<InventoryMutationResult> unarchiveSketch(
    UnarchiveInventorySketchCommand command,
  ) => _changeSketchArchiveState(command, archive: false);

  Future<InventoryMutationResult> _changeSketchArchiveState(
    InventoryMutationCommand command, {
    required bool archive,
  }) {
    final sketchId = switch (command) {
      ArchiveInventorySketchCommand value => value.sketchId,
      UnarchiveInventorySketchCommand value => value.sketchId,
      _ => throw const InventoryFailure('inventory_invalid_command'),
    };
    final expectedRevision = switch (command) {
      ArchiveInventorySketchCommand value => value.expectedSketchRevision,
      UnarchiveInventorySketchCommand value => value.expectedSketchRevision,
      _ => 0,
    };
    _requireUuid(sketchId, 'inventory_invalid_sketch_id');
    _requirePositiveRevision(expectedRevision);
    final intent = <String, Object?>{
      'archive': archive,
      'expected_sketch_revision': expectedRevision,
      'project_id': command.projectId,
      'sketch_id': sketchId,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final sketch = await _requireSketch(
        transaction,
        projectId: command.projectId,
        sketchId: sketchId,
      );
      _requireCurrentSketchRevision(sketch, expectedRevision);
      if ((archive && sketch.archivedAt != null) ||
          (!archive && sketch.archivedAt == null && sketch.isPrimary)) {
        final result = _result(
          command: command,
          sourceId: sketchId,
          sourceRevision: sketch.revision,
          supportingId: sketch.activeRevisionId,
          supportingRevision: null,
          isNoOp: true,
          eventCount: 0,
          resultAt: _canonicalNow(),
        );
        return _finishMutation(
          transaction,
          command: command,
          intentSha256: intentSha256,
          result: result,
          events: const [],
        );
      }
      if (!archive && sketch.archivedAt == null) {
        throw const InventoryFailure('inventory_sketch_state_invalid');
      }
      if (archive) {
        final placements = await transaction.rawQuery(
          'SELECT count(*) AS value FROM inventory_asset_placements '
          'WHERE project_id = ? AND sketch_id = ? AND ended_at IS NULL',
          [command.projectId, sketchId],
        );
        if (placements.single['value'] != 0) {
          throw const InventoryFailure(
            'inventory_sketch_has_active_placements',
          );
        }
      } else {
        final otherPrimary = await transaction.query(
          'inventory_sketches',
          columns: const ['id'],
          where:
              'project_id = ? AND id != ? AND is_primary = 1 '
              'AND archived_at IS NULL',
          whereArgs: [command.projectId, sketchId],
          limit: 2,
        );
        if (otherPrimary.isNotEmpty) {
          throw const InventoryFailure('inventory_primary_sketch_exists');
        }
      }
      final occurredAt = _canonicalNowAfter(sketch.updatedAt);
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      final updated = await transaction.update(
        'inventory_sketches',
        {
          'is_primary': archive ? 0 : 1,
          'revision': sketch.revision + 1,
          'updated_at': timestamp,
          'archived_at': archive ? timestamp : null,
        },
        where: 'id = ? AND project_id = ? AND revision = ?',
        whereArgs: [sketchId, command.projectId, sketch.revision],
      );
      if (updated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      final result = _result(
        command: command,
        sourceId: sketchId,
        sourceRevision: sketch.revision + 1,
        supportingId: sketch.activeRevisionId,
        supportingRevision: null,
        isNoOp: false,
        eventCount: 1,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.sketch,
            aggregateId: sketchId,
            eventType: archive
                ? InventoryEventType.sketchArchived
                : InventoryEventType.sketchUnarchived,
            payload: _eventPayload(
              result,
              values: <String, Object?>{'archived': archive},
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> createAsset(
    CreateInventoryAssetCommand command,
  ) {
    _requireUuid(command.assetId, 'inventory_invalid_asset_id');
    _requireUuid(command.placementId, 'inventory_invalid_placement_id');
    _requireUuid(command.placementKey, 'inventory_invalid_placement_key');
    _requireUuid(command.sketchId, 'inventory_invalid_sketch_id');
    _requireUuid(command.activeRevisionId, 'inventory_invalid_revision_id');
    final input = _validatedAssetInput(
      displayName: command.displayName,
      category: command.category,
      otherCategoryLabel: command.otherCategoryLabel,
      note: command.note,
    );
    final quantity = _validatedQuantity(command.totalQuantity);
    final x = _quantizedPlacementX(command.x);
    final y = _quantizedPlacementY(command.y);
    final intent = <String, Object?>{
      'active_revision_id': command.activeRevisionId,
      'asset_id': command.assetId,
      'category_code': input.category.storageValue,
      'display_name': input.displayName,
      'normalized_name': input.normalizedName,
      'note': input.note,
      'other_category_label': input.otherCategoryLabel,
      'placement_id': command.placementId,
      'placement_key': command.placementKey,
      'project_id': command.projectId,
      'sketch_id': command.sketchId,
      'status': command.status.storageValue,
      'total_quantity': quantity,
      'x': x,
      'y': y,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      await _requireActivePrimarySketch(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
        activeRevisionId: command.activeRevisionId,
      );
      await _requireUnusedId(
        transaction,
        table: 'inventory_assets',
        id: command.assetId,
        code: 'inventory_asset_id_conflict',
      );
      await _requireUnusedId(
        transaction,
        table: 'inventory_asset_placements',
        id: command.placementId,
        code: 'inventory_placement_id_conflict',
      );
      final placementKeyRows = await transaction.query(
        'inventory_asset_placements',
        columns: const ['id'],
        where: 'placement_key = ?',
        whereArgs: [command.placementKey],
        limit: 1,
      );
      if (placementKeyRows.isNotEmpty) {
        throw const InventoryFailure('inventory_placement_key_conflict');
      }
      final occurredAt = _canonicalNow();
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      await transaction.insert('inventory_assets', {
        'id': command.assetId,
        'project_id': command.projectId,
        'display_name': input.displayName,
        'normalized_name': input.normalizedName,
        'category_code': input.category.storageValue,
        'other_category_label': input.otherCategoryLabel,
        'total_quantity': quantity,
        'status': command.status.storageValue,
        'note': input.note,
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
        'status_changed_at': timestamp,
        'archived_at': null,
      });
      await transaction.insert('inventory_asset_placements', {
        'id': command.placementId,
        'placement_key': command.placementKey,
        'project_id': command.projectId,
        'asset_id': command.assetId,
        'sketch_id': command.sketchId,
        'provenance_revision_id': command.activeRevisionId,
        'sequence': 1,
        'x': x,
        'y': y,
        'quantity': quantity,
        'created_at': timestamp,
        'ended_at': null,
        'end_reason': null,
        'supersedes_placement_id': null,
      });
      final result = _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: 1,
        supportingId: command.placementId,
        supportingRevision: 1,
        isNoOp: false,
        eventCount: 2,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.asset,
            aggregateId: command.assetId,
            eventType: InventoryEventType.assetCreated,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'category_code': input.category.storageValue,
                'normalized_name': input.normalizedName,
                'status': command.status.storageValue,
                'total_quantity': quantity,
              },
            ),
          ),
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.placement,
            aggregateId: command.placementKey,
            eventType: InventoryEventType.placementCreated,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'asset_id': command.assetId,
                'placement_id': command.placementId,
                'provenance_revision_id': command.activeRevisionId,
                'quantity': quantity,
                'sequence': 1,
                'sketch_id': command.sketchId,
                'x': x,
                'y': y,
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> updateAsset(
    UpdateInventoryAssetCommand command,
  ) {
    _requireUuid(command.assetId, 'inventory_invalid_asset_id');
    _requirePositiveRevision(command.expectedAssetRevision);
    final input = _validatedAssetInput(
      displayName: command.displayName,
      category: command.category,
      otherCategoryLabel: command.otherCategoryLabel,
      note: command.note,
    );
    final intent = <String, Object?>{
      'asset_id': command.assetId,
      'category_code': input.category.storageValue,
      'display_name': input.displayName,
      'expected_asset_revision': command.expectedAssetRevision,
      'normalized_name': input.normalizedName,
      'note': input.note,
      'other_category_label': input.otherCategoryLabel,
      'project_id': command.projectId,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final asset = await _requireAsset(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      _requireCurrentAssetRevision(asset, command.expectedAssetRevision);
      _requireUnarchivedAsset(asset);
      final unchanged =
          asset.displayName == input.displayName &&
          asset.normalizedName == input.normalizedName &&
          asset.category == input.category &&
          asset.otherCategoryLabel == input.otherCategoryLabel &&
          asset.note == input.note;
      if (unchanged) {
        return _finishNoOpAsset(
          transaction,
          command: command,
          intentSha256: intentSha256,
          asset: asset,
        );
      }
      final occurredAt = _canonicalNowAfter(asset.updatedAt);
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      final updated = await transaction.update(
        'inventory_assets',
        {
          'display_name': input.displayName,
          'normalized_name': input.normalizedName,
          'category_code': input.category.storageValue,
          'other_category_label': input.otherCategoryLabel,
          'note': input.note,
          'revision': asset.revision + 1,
          'updated_at': timestamp,
        },
        where: 'id = ? AND project_id = ? AND revision = ?',
        whereArgs: [command.assetId, command.projectId, asset.revision],
      );
      if (updated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      final result = _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: asset.revision + 1,
        supportingId: null,
        supportingRevision: null,
        isNoOp: false,
        eventCount: 1,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.asset,
            aggregateId: command.assetId,
            eventType: InventoryEventType.assetUpdated,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'after_category_code': input.category.storageValue,
                'after_normalized_name': input.normalizedName,
                'before_category_code': asset.category.storageValue,
                'before_normalized_name': asset.normalizedName,
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> changeAssetStatus(
    ChangeInventoryAssetStatusCommand command,
  ) {
    _requireUuid(command.assetId, 'inventory_invalid_asset_id');
    _requirePositiveRevision(command.expectedAssetRevision);
    final intent = <String, Object?>{
      'asset_id': command.assetId,
      'expected_asset_revision': command.expectedAssetRevision,
      'project_id': command.projectId,
      'status': command.status.storageValue,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final asset = await _requireAsset(
        transaction,
        projectId: command.projectId,
        assetId: command.assetId,
      );
      _requireCurrentAssetRevision(asset, command.expectedAssetRevision);
      _requireUnarchivedAsset(asset);
      if (asset.status == command.status) {
        return _finishNoOpAsset(
          transaction,
          command: command,
          intentSha256: intentSha256,
          asset: asset,
        );
      }
      final occurredAt = _canonicalNowAfter(
        asset.updatedAt,
        asset.statusChangedAt,
      );
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      final updated = await transaction.update(
        'inventory_assets',
        {
          'status': command.status.storageValue,
          'revision': asset.revision + 1,
          'updated_at': timestamp,
          'status_changed_at': timestamp,
        },
        where: 'id = ? AND project_id = ? AND revision = ?',
        whereArgs: [command.assetId, command.projectId, asset.revision],
      );
      if (updated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      final result = _result(
        command: command,
        sourceId: command.assetId,
        sourceRevision: asset.revision + 1,
        supportingId: null,
        supportingRevision: null,
        isNoOp: false,
        eventCount: 1,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.asset,
            aggregateId: command.assetId,
            eventType: InventoryEventType.assetStatusChanged,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'after_status': command.status.storageValue,
                'before_status': asset.status.storageValue,
                'status_changed_at': timestamp,
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> startSketchEdit(
    StartInventorySketchEditCommand command,
  ) {
    _requireUuid(command.sketchId, 'inventory_invalid_sketch_id');
    _requireUuid(command.activeRevisionId, 'inventory_invalid_revision_id');
    _requireUuid(command.newDraftRevisionId, 'inventory_invalid_revision_id');
    _requirePositiveRevision(command.expectedSketchRevision);
    final intent = <String, Object?>{
      'active_revision_id': command.activeRevisionId,
      'expected_sketch_revision': command.expectedSketchRevision,
      'new_draft_revision_id': command.newDraftRevisionId,
      'project_id': command.projectId,
      'sketch_id': command.sketchId,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final sketch = await _requireSketch(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
      );
      _requireCurrentSketchRevision(sketch, command.expectedSketchRevision);
      if (sketch.archivedAt != null ||
          sketch.activeRevisionId != command.activeRevisionId) {
        throw const InventoryFailure('inventory_active_revision_unavailable');
      }
      if (sketch.draftRevisionId != null) {
        throw const InventoryFailure('inventory_sketch_draft_exists');
      }
      final active = await _requireSketchRevision(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
        revisionId: command.activeRevisionId,
      );
      if (active.state != InventorySketchRevisionState.active) {
        throw const InventoryFailure('inventory_active_revision_unavailable');
      }
      await _requireUnusedId(
        transaction,
        table: 'inventory_sketch_revisions',
        id: command.newDraftRevisionId,
        code: 'inventory_revision_id_conflict',
      );
      final nextRevision = await _nextSketchRevisionNumber(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
      );
      final occurredAt = _canonicalNowAfter(sketch.updatedAt, active.updatedAt);
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      await transaction.insert('inventory_sketch_revisions', {
        'id': command.newDraftRevisionId,
        'sketch_id': command.sketchId,
        'project_id': command.projectId,
        'revision_number': nextRevision,
        'base_revision_id': command.activeRevisionId,
        'state': InventorySketchRevisionState.draft.storageValue,
        'geometry_version': InventoryGeometryContract.geometryVersion,
        'canvas_width': InventoryGeometryContract.canvasWidth,
        'canvas_height': InventoryGeometryContract.canvasHeight,
        'geometry_json': active.geometry.canonicalJson,
        'geometry_sha256': active.geometrySha256,
        'content_revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
        'finalized_at': null,
        'superseded_at': null,
        'abandoned_at': null,
      });
      final updated = await transaction.update(
        'inventory_sketches',
        {
          'draft_revision_id': command.newDraftRevisionId,
          'revision': sketch.revision + 1,
          'updated_at': timestamp,
        },
        where: 'id = ? AND project_id = ? AND revision = ?',
        whereArgs: [command.sketchId, command.projectId, sketch.revision],
      );
      if (updated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      final result = _result(
        command: command,
        sourceId: command.sketchId,
        sourceRevision: sketch.revision + 1,
        supportingId: command.newDraftRevisionId,
        supportingRevision: 1,
        isNoOp: false,
        eventCount: 1,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.sketch,
            aggregateId: command.sketchId,
            eventType: InventoryEventType.sketchEditStarted,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'active_revision_id': command.activeRevisionId,
                'draft_revision_id': command.newDraftRevisionId,
                'geometry_sha256': active.geometrySha256,
                'revision_number': nextRevision,
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> finalizeSketch(
    FinalizeInventorySketchCommand command,
  ) {
    _requireUuid(command.sketchId, 'inventory_invalid_sketch_id');
    _requireUuid(command.draftRevisionId, 'inventory_invalid_revision_id');
    _requirePositiveRevision(command.expectedSketchRevision);
    _requirePositiveRevision(command.expectedContentRevision);
    final intent = <String, Object?>{
      'draft_revision_id': command.draftRevisionId,
      'expected_content_revision': command.expectedContentRevision,
      'expected_sketch_revision': command.expectedSketchRevision,
      'project_id': command.projectId,
      'sketch_id': command.sketchId,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final sketch = await _requireSketch(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
      );
      _requireCurrentSketchRevision(sketch, command.expectedSketchRevision);
      if (sketch.archivedAt != null ||
          sketch.draftRevisionId != command.draftRevisionId) {
        throw const InventoryFailure('inventory_sketch_draft_unavailable');
      }
      final draft = await _requireSketchRevision(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
        revisionId: command.draftRevisionId,
      );
      if (draft.state != InventorySketchRevisionState.draft ||
          draft.contentRevision != command.expectedContentRevision) {
        throw const InventoryFailure('inventory_stale_content_revision');
      }
      draft.geometry.validateFinalizable();
      InventorySketchRevisionRecord? active;
      if (sketch.activeRevisionId != null) {
        active = await _requireSketchRevision(
          transaction,
          projectId: command.projectId,
          sketchId: command.sketchId,
          revisionId: sketch.activeRevisionId!,
        );
        if (active.state != InventorySketchRevisionState.active) {
          throw const InventoryFailure('inventory_active_revision_unavailable');
        }
      }
      final occurredAt = _canonicalNowAfter(
        sketch.updatedAt,
        draft.updatedAt,
        active?.updatedAt,
      );
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      if (active != null) {
        final superseded = await transaction.update(
          'inventory_sketch_revisions',
          {
            'state': InventorySketchRevisionState.superseded.storageValue,
            'updated_at': timestamp,
            'superseded_at': timestamp,
          },
          where: 'id = ? AND project_id = ? AND sketch_id = ? AND state = ?',
          whereArgs: [
            active.id,
            command.projectId,
            command.sketchId,
            InventorySketchRevisionState.active.storageValue,
          ],
        );
        if (superseded != 1) {
          throw const InventoryFailure('inventory_active_revision_unavailable');
        }
      }
      final activated = await transaction.update(
        'inventory_sketch_revisions',
        {
          'state': InventorySketchRevisionState.active.storageValue,
          'updated_at': timestamp,
          'finalized_at': timestamp,
        },
        where:
            'id = ? AND project_id = ? AND sketch_id = ? '
            'AND state = ? AND content_revision = ?',
        whereArgs: [
          command.draftRevisionId,
          command.projectId,
          command.sketchId,
          InventorySketchRevisionState.draft.storageValue,
          command.expectedContentRevision,
        ],
      );
      final sketchUpdated = await transaction.update(
        'inventory_sketches',
        {
          'active_revision_id': command.draftRevisionId,
          'draft_revision_id': null,
          'revision': sketch.revision + 1,
          'updated_at': timestamp,
        },
        where: 'id = ? AND project_id = ? AND revision = ?',
        whereArgs: [command.sketchId, command.projectId, sketch.revision],
      );
      if (activated != 1 || sketchUpdated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      final result = _result(
        command: command,
        sourceId: command.sketchId,
        sourceRevision: sketch.revision + 1,
        supportingId: command.draftRevisionId,
        supportingRevision: draft.contentRevision,
        isNoOp: false,
        eventCount: 1,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.sketch,
            aggregateId: command.sketchId,
            eventType: InventoryEventType.sketchFinalized,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'active_revision_id': command.draftRevisionId,
                'geometry_sha256': draft.geometrySha256,
                'geometry_version': InventoryGeometryContract.geometryVersion,
                'point_count': draft.geometry.pointCount,
                'polyline_count': draft.geometry.polylines.length,
                'segment_count': draft.geometry.segmentCount,
                'superseded_revision_id': active?.id,
              },
            ),
          ),
        ],
      );
    });
  }

  @override
  Future<InventoryMutationResult> autosaveSketchDraft(
    AutosaveInventorySketchDraftCommand command,
  ) {
    _requireUuid(command.sketchId, 'inventory_invalid_sketch_id');
    _requireUuid(command.draftRevisionId, 'inventory_invalid_revision_id');
    _requirePositiveRevision(command.expectedSketchRevision);
    _requirePositiveRevision(command.expectedContentRevision);
    final geometry = command.geometry;
    final intent = <String, Object?>{
      'draft_revision_id': command.draftRevisionId,
      'expected_content_revision': command.expectedContentRevision,
      'expected_sketch_revision': command.expectedSketchRevision,
      'geometry_json': geometry.canonicalJson,
      'geometry_sha256': geometry.sha256,
      'project_id': command.projectId,
      'sketch_id': command.sketchId,
    };
    return _runMutation(command, intent, (transaction, intentSha256) async {
      final sketch = await _requireSketch(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
      );
      _requireCurrentSketchRevision(sketch, command.expectedSketchRevision);
      if (sketch.archivedAt != null ||
          sketch.draftRevisionId != command.draftRevisionId) {
        throw const InventoryFailure('inventory_sketch_draft_unavailable');
      }
      final draft = await _requireSketchRevision(
        transaction,
        projectId: command.projectId,
        sketchId: command.sketchId,
        revisionId: command.draftRevisionId,
      );
      if (draft.state != InventorySketchRevisionState.draft) {
        throw const InventoryFailure('inventory_sketch_draft_unavailable');
      }
      if (draft.contentRevision != command.expectedContentRevision) {
        throw const InventoryFailure('inventory_stale_content_revision');
      }
      if (draft.geometry.canonicalJson == geometry.canonicalJson &&
          draft.geometrySha256 == geometry.sha256) {
        final result = _result(
          command: command,
          sourceId: command.sketchId,
          sourceRevision: sketch.revision,
          supportingId: command.draftRevisionId,
          supportingRevision: draft.contentRevision,
          isNoOp: true,
          eventCount: 0,
          resultAt: _canonicalNow(),
        );
        return _finishMutation(
          transaction,
          command: command,
          intentSha256: intentSha256,
          result: result,
          events: const [],
        );
      }
      final occurredAt = _canonicalNowAfter(sketch.updatedAt, draft.updatedAt);
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      final draftUpdated = await transaction.update(
        'inventory_sketch_revisions',
        {
          'geometry_json': geometry.canonicalJson,
          'geometry_sha256': geometry.sha256,
          'content_revision': draft.contentRevision + 1,
          'updated_at': timestamp,
        },
        where:
            'id = ? AND project_id = ? AND sketch_id = ? '
            'AND state = ? AND content_revision = ?',
        whereArgs: [
          command.draftRevisionId,
          command.projectId,
          command.sketchId,
          InventorySketchRevisionState.draft.storageValue,
          command.expectedContentRevision,
        ],
      );
      final sketchUpdated = await transaction.update(
        'inventory_sketches',
        {'revision': sketch.revision + 1, 'updated_at': timestamp},
        where: 'id = ? AND project_id = ? AND revision = ?',
        whereArgs: [command.sketchId, command.projectId, sketch.revision],
      );
      if (draftUpdated != 1 || sketchUpdated != 1) {
        throw const InventoryFailure('inventory_stale_revision');
      }
      final result = _result(
        command: command,
        sourceId: command.sketchId,
        sourceRevision: sketch.revision + 1,
        supportingId: command.draftRevisionId,
        supportingRevision: draft.contentRevision + 1,
        isNoOp: false,
        eventCount: 1,
        resultAt: occurredAt,
      );
      return _finishMutation(
        transaction,
        command: command,
        intentSha256: intentSha256,
        result: result,
        events: [
          _PendingInventoryEvent(
            aggregateType: InventoryAggregateType.sketch,
            aggregateId: command.sketchId,
            eventType: InventoryEventType.sketchDraftAutosaved,
            payload: _eventPayload(
              result,
              values: <String, Object?>{
                'draft_revision_id': command.draftRevisionId,
                'geometry_sha256': geometry.sha256,
                'geometry_version': InventoryGeometryContract.geometryVersion,
                'point_count': geometry.pointCount,
                'polyline_count': geometry.polylines.length,
                'segment_count': geometry.segmentCount,
              },
            ),
          ),
        ],
      );
    });
  }
}

class _PendingInventoryEvent {
  _PendingInventoryEvent({
    required this.aggregateType,
    required this.aggregateId,
    required this.eventType,
    required Map<String, Object?> payload,
  }) : payload = Map<String, Object?>.unmodifiable(payload);

  final InventoryAggregateType aggregateType;
  final String aggregateId;
  final InventoryEventType eventType;
  final Map<String, Object?> payload;
}

class _ValidatedAssetInput {
  const _ValidatedAssetInput({
    required this.displayName,
    required this.normalizedName,
    required this.category,
    required this.otherCategoryLabel,
    required this.note,
  });

  final String displayName;
  final String normalizedName;
  final InventoryCategory category;
  final String? otherCategoryLabel;
  final String? note;
}
