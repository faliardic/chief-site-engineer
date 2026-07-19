import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/platform/concrete_attachment_gateway.dart';
import 'package:chief_site_engineer/platform/concrete_export_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class ConcreteApplication {
  Future<List<ConcretePour>> listPours(ConcretePourQuery query);
  Future<ConcretePourDetail> createPour(CreateConcretePourCommand command);
  Future<ConcretePourDetail> getPourDetail(String pourId);
  Future<ConcretePourDetail> updatePour(UpdateConcretePourCommand command);
  Future<ConcretePourDetail> updateCheck(UpdateConcreteCheckCommand command);
  Future<ConcretePourDetail> transitionPour(
    TransitionConcretePourCommand command,
  );
  Future<ConcretePourDetail> saveTruck(SaveConcreteTruckCommand command);
  Future<ConcretePourDetail> saveSampleSet(
    SaveConcreteSampleSetCommand command,
  );
  Future<ConcretePourDetail> updateFollowUp(
    UpdateConcreteFollowUpCommand command,
  );
  Future<ConcretePourDetail> attachEvidence(
    AttachConcreteEvidenceCommand command,
  );
  Future<ConcreteExportResult> exportPackage(
    ExportConcretePackageCommand command, {
    bool share = false,
  });
}

ConcretePour _pourFromRow(Map<String, Object?> row) {
  final plannedAt = row['planned_at']! as String;
  final startedAt = row['actual_started_at'] as String?;
  final endedAt = row['actual_ended_at'] as String?;
  final inspectionAt = row['inspection_notified_at'] as String?;
  final labAt = row['laboratory_appointment'] as String?;
  final createdAt = row['created_at']! as String;
  final updatedAt = row['updated_at']! as String;
  final closedAt = row['closed_at'] as String?;
  final cancelledAt = row['cancelled_at'] as String?;
  for (final value in [
    plannedAt,
    startedAt,
    endedAt,
    inspectionAt,
    labAt,
    createdAt,
    updatedAt,
    closedAt,
    cancelledAt,
  ]) {
    if (value != null) validateCanonicalTimestamp(value, 'Beton paketi zamanı');
  }
  return ConcretePour(
    id: row['id']! as String,
    projectId: row['project_id']! as String,
    projectName: row['project_name']! as String,
    pourCode: row['pour_code']! as String,
    elementLocation: row['element_location']! as String,
    blockName: row['block_name'] as String?,
    floorName: row['floor_name'] as String?,
    axisName: row['axis_name'] as String?,
    plannedAt: plannedAt,
    actualStartedAt: startedAt,
    actualEndedAt: endedAt,
    concreteClass: row['concrete_class']! as String,
    targetSlump: row['target_slump'] as String?,
    plannedVolumeM3: (row['planned_volume_m3']! as num).toDouble(),
    orderedVolumeM3: (row['ordered_volume_m3'] as num?)?.toDouble(),
    plantName: row['plant_name'] as String?,
    plantBranch: row['plant_branch'] as String?,
    plantContact: row['plant_contact'] as String?,
    plantAppointmentReference: row['plant_appointment_reference'] as String?,
    pumpEquipment: row['pump_equipment'] as String?,
    laboratoryName: row['laboratory_name'] as String?,
    laboratoryContact: row['laboratory_contact'] as String?,
    laboratoryAppointment: labAt,
    inspectionNotifiedAt: inspectionAt,
    inspectionNotifiedPerson: row['inspection_notified_person'] as String?,
    status: ConcretePourStatus.fromStorage(row['status']! as String),
    generalNote: row['general_note'] as String?,
    sampleExceptionReason: row['sample_exception_reason'] as String?,
    varianceNote: row['variance_note'] as String?,
    revision: row['revision']! as int,
    createdAt: createdAt,
    updatedAt: updatedAt,
    closedAt: closedAt,
    cancelledAt: cancelledAt,
    pendingCheckCount: row['pending_check_count'] as int? ?? 0,
    missingEvidenceTruckCount: row['missing_evidence_truck_count'] as int? ?? 0,
    openFollowUpCount: row['open_follow_up_count'] as int? ?? 0,
  );
}

ConcreteCheckItem _checkFromRow(Map<String, Object?> row) => ConcreteCheckItem(
  id: row['id']! as String,
  pourId: row['concrete_pour_id']! as String,
  itemKey: row['item_key']! as String,
  label: row['label']! as String,
  sortOrder: row['sort_order']! as int,
  isRequired: row['is_required'] == 1,
  status: ConcreteCheckStatus.fromStorage(row['status']! as String),
  note: row['note'] as String?,
  reason: row['reason'] as String?,
  revision: row['revision']! as int,
  updatedAt: row['updated_at']! as String,
);

ConcreteTruck _truckFromRow(Map<String, Object?> row) => ConcreteTruck(
  id: row['id']! as String,
  pourId: row['concrete_pour_id']! as String,
  sequenceNo: row['sequence_no']! as int,
  vehiclePlate: row['vehicle_plate']! as String,
  deliveryNoteNumber: row['delivery_note_number']! as String,
  plantSnapshot: row['plant_snapshot'] as String?,
  batchTime: row['batch_time'] as String?,
  arrivedAt: row['arrived_at'] as String?,
  unloadingStartedAt: row['unloading_started_at'] as String?,
  unloadingEndedAt: row['unloading_ended_at'] as String?,
  volumeM3: (row['volume_m3']! as num).toDouble(),
  measuredSlump: (row['measured_slump'] as num?)?.toDouble(),
  concreteTemperature: (row['concrete_temperature'] as num?)?.toDouble(),
  result: ConcreteTruckResult.fromStorage(row['result']! as String),
  reason: row['reason'] as String?,
  evidenceExceptionReason: row['evidence_exception_reason'] as String?,
  revision: row['revision']! as int,
  createdAt: row['created_at']! as String,
  updatedAt: row['updated_at']! as String,
);

ConcreteSampleSet _sampleFromRow(Map<String, Object?> row) => ConcreteSampleSet(
  id: row['id']! as String,
  pourId: row['concrete_pour_id']! as String,
  sourceTruckId: row['source_truck_id'] as String?,
  sampleCode: row['sample_code']! as String,
  sampleCount: row['sample_count']! as int,
  sampleLabels: List<String>.from(
    jsonDecode(row['sample_labels_json']! as String) as List,
  ),
  sampledAt: row['sampled_at'] as String?,
  sampledBy: row['sampled_by'] as String?,
  laboratoryAppointmentAt: row['laboratory_appointment_at'] as String?,
  deliveredAt: row['delivered_at'] as String?,
  deliveredTo: row['delivered_to'] as String?,
  expectedResultDates: List<String>.from(
    jsonDecode(row['expected_result_dates_json']! as String) as List,
  ),
  status: ConcreteSampleStatus.fromStorage(row['status']! as String),
  note: row['note'] as String?,
  reason: row['reason'] as String?,
  revision: row['revision']! as int,
  createdAt: row['created_at']! as String,
  updatedAt: row['updated_at']! as String,
);

ConcreteFollowUp _followUpFromRow(Map<String, Object?> row) => ConcreteFollowUp(
  id: row['id']! as String,
  pourId: row['concrete_pour_id']! as String,
  sourceSampleSetId: row['source_sample_set_id'] as String?,
  itemKey: row['item_key']! as String,
  label: row['label']! as String,
  dueAt: row['due_at'] as String?,
  status: ConcreteFollowUpStatus.fromStorage(row['status']! as String),
  reminderId: row['reminder_id'] as String?,
  note: row['note'] as String?,
  reason: row['reason'] as String?,
  revision: row['revision']! as int,
  createdAt: row['created_at']! as String,
  updatedAt: row['updated_at']! as String,
  completedAt: row['completed_at'] as String?,
);

ConcreteAttachment _attachmentFromRow(Map<String, Object?> row) =>
    ConcreteAttachment(
      id: row['id']! as String,
      pourId: row['concrete_pour_id']! as String,
      truckId: row['truck_id'] as String?,
      sampleSetId: row['sample_set_id'] as String?,
      checkItemId: row['check_item_id'] as String?,
      evidenceType: ConcreteEvidenceType.fromStorage(
        row['evidence_type']! as String,
      ),
      originalFileName: row['original_file_name']! as String,
      mimeType: row['mime_type']! as String,
      byteSize: row['byte_size']! as int,
      sha256: row['sha256']! as String,
      relativePath: row['relative_path']! as String,
      capturedAt: row['captured_at']! as String,
      description: row['description'] as String?,
      createdAt: row['created_at']! as String,
      integrity: ConcreteAttachmentIntegrity.ok,
    );

ConcreteAttachment _withIntegrity(
  ConcreteAttachment item,
  ConcreteAttachmentIntegrity value,
) => ConcreteAttachment(
  id: item.id,
  pourId: item.pourId,
  truckId: item.truckId,
  sampleSetId: item.sampleSetId,
  checkItemId: item.checkItemId,
  evidenceType: item.evidenceType,
  originalFileName: item.originalFileName,
  mimeType: item.mimeType,
  byteSize: item.byteSize,
  sha256: item.sha256,
  relativePath: item.relativePath,
  capturedAt: item.capturedAt,
  description: item.description,
  createdAt: item.createdAt,
  integrity: value,
);

ConcretePourEvent _eventFromRow(Map<String, Object?> row) => ConcretePourEvent(
  id: row['id']! as String,
  pourId: row['concrete_pour_id']! as String,
  sequence: row['sequence']! as int,
  eventType: row['event_type']! as String,
  occurredAt: row['occurred_at']! as String,
  payloadJson: row['payload_json']! as String,
);

MobileReminder _reminderFromRow(Map<String, Object?> row) {
  final outcome = row['outcome_type'] as String?;
  return MobileReminder(
    id: row['id']! as String,
    projectId: row['project_id'] as String?,
    projectName: row['project_name'] as String?,
    sourceLogId: row['observation_id'] as String?,
    attendanceDayId: row['attendance_day_id'] as String?,
    concretePourId: row['concrete_pour_id'] as String?,
    captureText: row['capture_text']! as String,
    title: row['title']! as String,
    description: row['description'] as String?,
    kind: ReminderKind.fromStorage(row['item_type']! as String),
    status: ReminderStatus.fromStorage(row['status']! as String),
    location: row['location'] as String?,
    relatedPerson: row['related_person'] as String?,
    isImportant: row['is_important'] == 1,
    nextAttentionAt: row['next_attention_at'] as String?,
    deadlineAt: row['deadline_at'] as String?,
    conditionText: row['condition_text'] as String?,
    outcomeType: outcome == null
        ? null
        : ReminderOutcomeType.fromStorage(outcome),
    outcomeNote: row['outcome_note'] as String?,
    createdAt: row['created_at']! as String,
    updatedAt: row['updated_at']! as String,
    completedAt: row['completed_at'] as String?,
    cancelledAt: row['cancelled_at'] as String?,
    revision: row['revision']! as int,
  );
}

String _stableUuid(String seed) {
  int hash(String value, int salt) {
    var result = (2166136261 ^ salt) & 0xffffffff;
    for (final unit in value.codeUnits) {
      result ^= unit;
      result = (result * 16777619) & 0xffffffff;
    }
    return result;
  }

  final raw = List.generate(
    4,
    (index) =>
        hash(seed, 0x9e3779b9 * (index + 1)).toRadixString(16).padLeft(8, '0'),
  ).join();
  final chars = raw.split('');
  chars[12] = '4';
  chars[16] = '8';
  final value = chars.join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-${value.substring(12, 16)}-${value.substring(16, 20)}-${value.substring(20)}';
}

typedef ConcreteTransactionHook = Future<void> Function(Transaction value);

class SqliteConcreteApplication implements ConcreteApplication {
  SqliteConcreteApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.clock,
    required this.agenda,
    required this.attachmentStore,
    MobileOperationCoordinator? coordinator,
    ConcreteExportGateway? exportGateway,
    this.beforeConcreteEventInsert,
  }) : coordinator = coordinator ?? MobileOperationCoordinator(),
       exportGateway =
           exportGateway ?? const UnavailableConcreteExportGateway();

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;
  final AgendaApplication agenda;
  final ConcreteAttachmentStore attachmentStore;
  final MobileOperationCoordinator coordinator;
  final ConcreteExportGateway exportGateway;
  final ConcreteTransactionHook? beforeConcreteEventInsert;

  static const _checkDefinitions = <(String, String, bool)>[
    ('plant_appointment', 'Santral randevusu alındı', true),
    ('location_ready', 'Döküm mahali hazır', true),
    ('planned_volume_verified', 'Planlanan metraj doğrulandı', true),
    ('formwork_ready', 'Kalıp kontrol edildi', true),
    ('reinforcement_ready', 'Donatı kontrol edildi', true),
    (
      'embedded_items_ready',
      'Gömülü eleman ve rezervasyonlar kontrol edildi',
      true,
    ),
    ('inspection_notified', 'Yapı denetim bilgilendirildi', true),
    ('laboratory_appointment', 'Laboratuvar randevusu alındı', true),
    ('pump_equipment_ready', 'Pompa ve ekipman hazır', true),
    ('access_route_ready', 'Erişim ve mikser güzergâhı hazır', true),
    ('safety_ready', 'İş güvenliği tedbirleri hazır', true),
  ];

  static const _followUpDefinitions = <(String, String, int?)>[
    ('plant_confirmation', 'Santral teyidi', -120),
    ('inspection_notification_task', 'Yapı denetime haber ver', 60),
    ('laboratory_appointment_task', 'Laboratuvar randevusunu al/doğrula', 60),
    ('pour_start', 'Döküm başlangıcı', 0),
    ('curing_start', 'Kür başlangıcı', 120),
    ('first_curing_check', 'İlk kür / yüzey kontrolü', 360),
    ('form_removal_note', 'Kalıp alma notu', null),
    ('missing_evidence', 'Eksik kanıtları tamamla', null),
  ];

  @override
  Future<List<ConcretePour>> listPours(ConcretePourQuery query) async {
    final now = _readClockOnce();
    final today = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
    if (query.projectId != null) {
      validateUuid(query.projectId!, 'Proje kimliği');
    }
    if (query.istanbulDay != null) {
      CseTimeCodec.istanbulDayBounds(query.istanbulDay!);
    }
    final search = query.literalSearch.trim();
    return _withDatabase(now, (database) async {
      final where = <String>[];
      final args = <Object?>[];
      if (query.projectId != null) {
        where.add('c.project_id = ?');
        args.add(query.projectId);
      }
      final day = query.istanbulDay ?? today;
      final bounds = CseTimeCodec.istanbulDayBounds(day);
      switch (query.group) {
        case ConcretePourGroup.today:
          where.add('c.planned_at >= ? AND c.planned_at < ?');
          args.addAll([bounds.start, bounds.endExclusive]);
          where.add("c.status NOT IN ('closed', 'cancelled')");
        case ConcretePourGroup.upcoming:
          where.add('c.planned_at >= ?');
          args.add(bounds.endExclusive);
          where.add("c.status IN ('draft', 'prepared')");
        case ConcretePourGroup.inProgress:
          where.add("c.status IN ('pouring', 'poured')");
        case ConcretePourGroup.followUp:
          where.add("c.status = 'follow_up'");
        case ConcretePourGroup.closed:
          where.add("c.status IN ('closed', 'cancelled')");
      }
      if (search.isNotEmpty) {
        where.add('''(
          instr(c.pour_code, ?) > 0 OR instr(c.element_location, ?) > 0
          OR instr(coalesce(c.block_name, ''), ?) > 0
          OR instr(coalesce(c.floor_name, ''), ?) > 0
          OR instr(coalesce(c.axis_name, ''), ?) > 0
          OR instr(p.name, ?) > 0
        )''');
        args.addAll(List<Object?>.filled(6, search));
      }
      final rows = await database.rawQuery('''
        SELECT c.*, p.name AS project_name,
          (SELECT count(*) FROM concrete_check_items x
            WHERE x.concrete_pour_id = c.id AND x.status = 'pending')
            AS pending_check_count,
          (SELECT count(*) FROM concrete_follow_up_items x
            WHERE x.concrete_pour_id = c.id AND x.status = 'pending')
            AS open_follow_up_count,
          (SELECT count(*) FROM concrete_trucks t
            WHERE t.concrete_pour_id = c.id
              AND (t.evidence_exception_reason IS NULL
                OR length(trim(t.evidence_exception_reason)) = 0)
              AND (
                NOT EXISTS (SELECT 1 FROM concrete_attachments a
                  WHERE a.truck_id = t.id AND a.archived_at IS NULL
                    AND a.evidence_type = 'delivery_receipt_scan')
                OR NOT EXISTS (SELECT 1 FROM concrete_attachments a
                  WHERE a.truck_id = t.id AND a.archived_at IS NULL
                    AND a.evidence_type = 'mixer_photo')
              )) AS missing_evidence_truck_count
        FROM concrete_pours c
        JOIN projects p ON p.id = c.project_id
        ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
        ORDER BY c.planned_at ASC, c.created_at ASC, c.id ASC
        ''', args);
      return rows.map(_pourFromRow).toList(growable: false);
    });
  }

  @override
  Future<ConcretePourDetail> createPour(
    CreateConcretePourCommand command,
  ) async {
    _validateCreate(command);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    final normalized = _normalizedCreate(command);
    final detail = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final projectName = await _requireProject(
          transaction,
          normalized.projectId,
        );
        final existing = await transaction.query(
          'concrete_pours',
          where: 'id = ?',
          whereArgs: [normalized.id],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final value = _pourFromRow({
            ...existing.single,
            'project_name': projectName,
          });
          if (!_sameCreate(value, normalized)) {
            throw const AgendaValidationFailure(
              'Beton paketi kimliği başka içerikle kullanılıyor.',
            );
          }
          return _loadDetail(transaction, normalized.id);
        }
        final duplicate = await transaction.query(
          'concrete_pours',
          columns: ['id'],
          where: 'project_id = ? AND pour_code = ?',
          whereArgs: [normalized.projectId, normalized.pourCode],
          limit: 1,
        );
        if (duplicate.isNotEmpty) {
          throw const AgendaValidationFailure(
            'Döküm kodu bu projede zaten kullanılıyor.',
          );
        }
        await transaction.insert('concrete_pours', {
          'id': normalized.id,
          'project_id': normalized.projectId,
          'pour_code': normalized.pourCode,
          'element_location': normalized.elementLocation,
          'block_name': normalized.blockName,
          'floor_name': normalized.floorName,
          'axis_name': normalized.axisName,
          'planned_at': normalized.plannedAt,
          'concrete_class': normalized.concreteClass,
          'target_slump': normalized.targetSlump,
          'planned_volume_m3': normalized.plannedVolumeM3,
          'ordered_volume_m3': normalized.orderedVolumeM3,
          'plant_name': normalized.plantName,
          'plant_branch': normalized.plantBranch,
          'plant_contact': normalized.plantContact,
          'plant_appointment_reference': normalized.plantAppointmentReference,
          'pump_equipment': normalized.pumpEquipment,
          'laboratory_name': normalized.laboratoryName,
          'laboratory_contact': normalized.laboratoryContact,
          'laboratory_appointment': normalized.laboratoryAppointment,
          'inspection_notified_at': normalized.inspectionNotifiedAt,
          'inspection_notified_person': normalized.inspectionNotifiedPerson,
          'status': ConcretePourStatus.draft.storageValue,
          'general_note': normalized.generalNote,
          'revision': 1,
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        for (var index = 0; index < _checkDefinitions.length; index += 1) {
          final definition = _checkDefinitions[index];
          await transaction.insert('concrete_check_items', {
            'id': _stableUuid(
              'concrete-check:${normalized.id}:${definition.$1}',
            ),
            'concrete_pour_id': normalized.id,
            'item_key': definition.$1,
            'label': definition.$2,
            'sort_order': index + 1,
            'is_required': definition.$3 ? 1 : 0,
            'status': ConcreteCheckStatus.pending.storageValue,
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
          });
        }
        await _insertConcreteEvent(
          transaction,
          id: normalized.eventId,
          pourId: normalized.id,
          eventType: 'pour.created',
          occurredAt: timestamp,
          payload: {
            'project_id': normalized.projectId,
            'pour_code': normalized.pourCode,
            'planned_at': normalized.plannedAt,
          },
        );
        for (final definition in _followUpDefinitions) {
          final isHourlyFieldTask =
              definition.$1 == 'inspection_notification_task' ||
              definition.$1 == 'laboratory_appointment_task';
          final dueAt = definition.$3 == null
              ? null
              : isHourlyFieldTask
              ? CseTimeCodec.encodeUtc(now.add(const Duration(hours: 1)))
              : CseTimeCodec.encodeUtc(
                  CseTimeCodec.decodeCanonicalUtc(
                    normalized.plannedAt,
                  ).add(Duration(minutes: definition.$3!)),
                );
          await _insertFollowUpWithReminder(
            transaction,
            pourId: normalized.id,
            projectId: normalized.projectId,
            projectName: projectName,
            pourCode: normalized.pourCode,
            itemKey: definition.$1,
            label: definition.$2,
            dueAt: dueAt,
            occurredAt: timestamp,
            repeatIntervalMinutes: isHourlyFieldTask ? 60 : null,
          );
        }
        await _syncFieldReminderTasks(
          transaction,
          pourId: normalized.id,
          projectId: normalized.projectId,
          laboratoryComplete:
              normalized.laboratoryAppointment?.trim().isNotEmpty ?? false,
          inspectionComplete:
              normalized.inspectionNotifiedAt != null ||
              (normalized.inspectionNotifiedPerson?.trim().isNotEmpty ?? false),
          occurredAt: timestamp,
        );
        return _loadDetail(transaction, normalized.id);
      });
    });
    await _safeReconcileNotifications();
    return detail;
  }

  @override
  Future<ConcretePourDetail> saveTruck(SaveConcreteTruckCommand command) async {
    _validateTruck(command);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final pour = await _requirePour(transaction, command.pourId);
        _requireRevision(pour.revision, command.expectedPourRevision);
        _requireMutable(pour);
        if (await _isIdempotentEvent(
          transaction,
          command.eventId,
          command.pourId,
        )) {
          return _loadDetail(transaction, command.pourId);
        }
        final values = _normalizedTruck(command);
        final existing = await transaction.query(
          'concrete_trucks',
          where: 'id = ? AND concrete_pour_id = ?',
          whereArgs: [command.id, command.pourId],
          limit: 1,
        );
        late final String eventType;
        if (existing.isEmpty) {
          if (command.expectedTruckRevision != 0) throw _staleFailure();
          await _requireUniqueTruck(
            transaction,
            command.pourId,
            command.sequenceNo,
            values['delivery_note_number']! as String,
          );
          await transaction.insert('concrete_trucks', {
            'id': command.id,
            'concrete_pour_id': command.pourId,
            ...values,
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
          });
          eventType = 'truck.added';
        } else {
          final truck = _truckFromRow(existing.single);
          if (truck.revision != command.expectedTruckRevision) {
            throw _staleFailure();
          }
          await _requireUniqueTruck(
            transaction,
            command.pourId,
            command.sequenceNo,
            values['delivery_note_number']! as String,
            excludingId: command.id,
          );
          if (_truckMatches(truck, values)) {
            return _loadDetail(transaction, command.pourId);
          }
          final changed = await transaction.update(
            'concrete_trucks',
            {
              ...values,
              'revision': truck.revision + 1,
              'updated_at': timestamp,
            },
            where: 'id = ? AND revision = ?',
            whereArgs: [truck.id, truck.revision],
          );
          if (changed != 1) throw _staleFailure();
          eventType = 'truck.updated';
        }
        await _advancePour(transaction, pour, timestamp);
        await _insertConcreteEvent(
          transaction,
          id: command.eventId,
          pourId: command.pourId,
          eventType: eventType,
          occurredAt: timestamp,
          payload: {
            'truck_id': command.id,
            'sequence_no': command.sequenceNo,
            'delivery_note_number': values['delivery_note_number'],
            'volume_m3': command.volumeM3,
            'result': command.result.storageValue,
          },
        );
        return _loadDetail(transaction, command.pourId);
      });
    });
  }

  @override
  Future<ConcretePourDetail> saveSampleSet(
    SaveConcreteSampleSetCommand command,
  ) async {
    _validateSample(command);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    final detail = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final pour = await _requirePour(transaction, command.pourId);
        _requireRevision(pour.revision, command.expectedPourRevision);
        _requireMutable(pour);
        if (await _isIdempotentEvent(
          transaction,
          command.eventId,
          command.pourId,
        )) {
          return _loadDetail(transaction, command.pourId);
        }
        if (command.sourceTruckId != null) {
          await _requireSource(
            transaction,
            table: 'concrete_trucks',
            id: command.sourceTruckId!,
            pourId: command.pourId,
            label: 'Kaynak mikser',
          );
        }
        final values = _normalizedSample(command);
        final existing = await transaction.query(
          'concrete_sample_sets',
          where: 'id = ? AND concrete_pour_id = ?',
          whereArgs: [command.id, command.pourId],
          limit: 1,
        );
        values['sample_code'] ??= existing.isEmpty
            ? await _nextSampleCode(transaction, command.pourId)
            : existing.single['sample_code']! as String;
        late final String eventType;
        if (existing.isEmpty) {
          if (command.expectedSampleRevision != 0) throw _staleFailure();
          await _requireUniqueSample(
            transaction,
            command.pourId,
            values['sample_code']! as String,
          );
          await transaction.insert('concrete_sample_sets', {
            'id': command.id,
            'concrete_pour_id': command.pourId,
            ...values,
            'revision': 1,
            'created_at': timestamp,
            'updated_at': timestamp,
          });
          eventType = 'sample_set.added';
          await _insertFollowUpWithReminder(
            transaction,
            pourId: pour.id,
            projectId: pour.projectId,
            projectName: pour.projectName,
            pourCode: pour.pourCode,
            itemKey: 'sample_delivery:${command.id}',
            label: '${values['sample_code']} numunesini laboratuvara teslim et',
            dueAt: command.laboratoryAppointmentAt,
            occurredAt: timestamp,
            sourceSampleSetId: command.id,
          );
          final dates = command.expectedResultDates;
          for (var index = 0; index < dates.length; index += 1) {
            await _insertFollowUpWithReminder(
              transaction,
              pourId: pour.id,
              projectId: pour.projectId,
              projectName: pour.projectName,
              pourCode: pour.pourCode,
              itemKey: 'sample_result:${command.id}:$index',
              label: '${values['sample_code']} numune sonucu ${index + 1}',
              dueAt: dates[index],
              occurredAt: timestamp,
              sourceSampleSetId: command.id,
            );
          }
        } else {
          final sample = _sampleFromRow(existing.single);
          if (sample.revision != command.expectedSampleRevision) {
            throw _staleFailure();
          }
          await _requireUniqueSample(
            transaction,
            command.pourId,
            values['sample_code']! as String,
            excludingId: command.id,
          );
          if (_sampleMatches(sample, values)) {
            return _loadDetail(transaction, command.pourId);
          }
          final changed = await transaction.update(
            'concrete_sample_sets',
            {
              ...values,
              'revision': sample.revision + 1,
              'updated_at': timestamp,
            },
            where: 'id = ? AND revision = ?',
            whereArgs: [sample.id, sample.revision],
          );
          if (changed != 1) throw _staleFailure();
          eventType = 'sample_set.updated';
          if (command.status == ConcreteSampleStatus.delivered ||
              command.status == ConcreteSampleStatus.waitingResult ||
              command.status == ConcreteSampleStatus.completed) {
            await _completeSampleFollowUps(
              transaction,
              pour: pour,
              sampleId: command.id,
              occurredAt: timestamp,
              reason: command.reason,
              deliveryOnly: true,
            );
          }
          if (command.status == ConcreteSampleStatus.completed ||
              command.status == ConcreteSampleStatus.exception) {
            await _completeSampleFollowUps(
              transaction,
              pour: pour,
              sampleId: command.id,
              occurredAt: timestamp,
              reason: command.reason,
            );
          }
        }
        await _advancePour(transaction, pour, timestamp);
        await _insertConcreteEvent(
          transaction,
          id: command.eventId,
          pourId: command.pourId,
          eventType: eventType,
          occurredAt: timestamp,
          payload: {
            'sample_set_id': command.id,
            'sample_code': values['sample_code'],
            'sample_count': command.sampleCount,
            'status': command.status.storageValue,
          },
        );
        return _loadDetail(transaction, command.pourId);
      });
    });
    await _safeReconcileNotifications();
    return detail;
  }

  @override
  Future<ConcretePourDetail> updateFollowUp(
    UpdateConcreteFollowUpCommand command,
  ) async {
    validateUuid(command.pourId, 'Beton paketi kimliği');
    validateUuid(command.followUpId, 'Takip kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.reminderEventId, 'Hatırlatıcı event kimliği');
    _validateExpectedRevision(command.expectedPourRevision);
    _validateExpectedRevision(command.expectedFollowUpRevision);
    final dueAt = command.dueAt;
    if (dueAt != null) validateCanonicalTimestamp(dueAt, 'Takip zamanı');
    final note = optionalTrimmed(command.note, 'Takip notu', maxLength: 1000);
    final reason = optionalTrimmed(
      command.reason,
      'Takip nedeni',
      maxLength: 1000,
    );
    if (command.status == ConcreteFollowUpStatus.exception && reason == null) {
      throw const AgendaValidationFailure(
        'Takip istisnasında neden zorunludur.',
      );
    }
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    final detail = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final pour = await _requirePour(transaction, command.pourId);
        _requireRevision(pour.revision, command.expectedPourRevision);
        _requireMutable(pour);
        final rows = await transaction.query(
          'concrete_follow_up_items',
          where: 'id = ? AND concrete_pour_id = ?',
          whereArgs: [command.followUpId, command.pourId],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw const AgendaValidationFailure('Beton takibi bulunamadı.');
        }
        final followUp = _followUpFromRow(rows.single);
        if (followUp.revision != command.expectedFollowUpRevision) {
          throw _staleFailure();
        }
        if (await _isIdempotentEvent(
          transaction,
          command.eventId,
          command.pourId,
        )) {
          return _loadDetail(transaction, command.pourId);
        }
        if (followUp.status == command.status &&
            followUp.dueAt == dueAt &&
            followUp.note == note &&
            followUp.reason == reason) {
          return _loadDetail(transaction, command.pourId);
        }
        final completedAt = command.status == ConcreteFollowUpStatus.pending
            ? null
            : timestamp;
        final changed = await transaction.update(
          'concrete_follow_up_items',
          {
            'due_at': dueAt,
            'status': command.status.storageValue,
            'note': note,
            'reason': reason,
            'revision': followUp.revision + 1,
            'updated_at': timestamp,
            'completed_at': completedAt,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [followUp.id, followUp.revision],
        );
        if (changed != 1) throw _staleFailure();
        if (followUp.reminderId != null) {
          await _syncLinkedReminder(
            transaction,
            reminderId: followUp.reminderId!,
            eventId: command.reminderEventId,
            projectId: pour.projectId,
            pourId: pour.id,
            pending: command.status == ConcreteFollowUpStatus.pending,
            dueAt: dueAt,
            occurredAt: timestamp,
            outcomeNote: reason ?? note,
          );
        }
        await _advancePour(transaction, pour, timestamp);
        await _insertConcreteEvent(
          transaction,
          id: command.eventId,
          pourId: command.pourId,
          eventType: 'follow_up.linked',
          occurredAt: timestamp,
          payload: {
            'follow_up_id': followUp.id,
            'reminder_id': followUp.reminderId,
            'status': command.status.storageValue,
            'due_at': dueAt,
          },
        );
        return _loadDetail(transaction, command.pourId);
      });
    });
    await _safeReconcileNotifications();
    return detail;
  }

  @override
  Future<ConcretePourDetail> attachEvidence(
    AttachConcreteEvidenceCommand command,
  ) => coordinator.run(() => _attachEvidenceCoordinated(command));

  Future<ConcretePourDetail> _attachEvidenceCoordinated(
    AttachConcreteEvidenceCommand command,
  ) async {
    _validateAttachment(command);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    await _withDatabaseUnlocked(now, (database) {
      return _validateAttachmentSources(database, command);
    });
    final staged = await attachmentStore.stage(
      pourId: command.pourId,
      attachmentId: command.id,
      originalFileName: command.originalFileName,
      bytes: command.bytes,
    );
    try {
      return await _withDatabaseUnlocked(now, (database) {
        return database.transaction((transaction) async {
          final pour = await _requirePour(transaction, command.pourId);
          _requireRevision(pour.revision, command.expectedPourRevision);
          _requireMutable(pour);
          await _validateAttachmentSources(transaction, command);
          if (await _isIdempotentEvent(
            transaction,
            command.eventId,
            command.pourId,
          )) {
            final existing = await transaction.query(
              'concrete_attachments',
              where: 'id = ? AND concrete_pour_id = ?',
              whereArgs: [command.id, command.pourId],
              limit: 1,
            );
            if (existing.isEmpty ||
                existing.single['sha256'] != staged.sha256Value) {
              throw const AgendaValidationFailure(
                'Kanıt event kimliği başka içerikle kullanılıyor.',
              );
            }
            return _loadDetail(transaction, command.pourId);
          }
          final duplicate = await transaction.query(
            'concrete_attachments',
            columns: ['id'],
            where: 'concrete_pour_id = ? AND sha256 = ?',
            whereArgs: [command.pourId, staged.sha256Value],
            limit: 1,
          );
          if (duplicate.isNotEmpty) {
            throw const AgendaValidationFailure(
              'Bu kanıt dosyası pakete daha önce eklenmiş.',
            );
          }
          await transaction.insert('concrete_attachments', {
            'id': command.id,
            'concrete_pour_id': command.pourId,
            'truck_id': command.truckId,
            'sample_set_id': command.sampleSetId,
            'check_item_id': command.checkItemId,
            'evidence_type': command.evidenceType.storageValue,
            'original_file_name': command.originalFileName.trim(),
            'mime_type': staged.mimeType,
            'byte_size': staged.byteSize,
            'sha256': staged.sha256Value,
            'relative_path': staged.relativePath,
            'captured_at': command.capturedAt,
            'description': optionalTrimmed(
              command.description,
              'Kanıt açıklaması',
              maxLength: 1000,
            ),
            'created_at': timestamp,
          });
          await _advancePour(transaction, pour, timestamp);
          await _insertConcreteEvent(
            transaction,
            id: command.eventId,
            pourId: command.pourId,
            eventType: 'evidence.attached',
            occurredAt: timestamp,
            payload: {
              'attachment_id': command.id,
              'evidence_type': command.evidenceType.storageValue,
              'truck_id': command.truckId,
              'sample_set_id': command.sampleSetId,
              'check_item_id': command.checkItemId,
              'sha256': staged.sha256Value,
              'byte_size': staged.byteSize,
            },
          );
          return _loadDetail(transaction, command.pourId);
        });
      });
    } on Object {
      await attachmentStore.cleanup(staged.relativePath);
      rethrow;
    }
  }

  Future<void> _validateTransition(
    DatabaseExecutor database,
    ConcretePour pour,
    ConcretePourStatus target,
    String? reason,
  ) async {
    final allowed = switch (pour.status) {
      ConcretePourStatus.draft => {
        ConcretePourStatus.prepared,
        ConcretePourStatus.cancelled,
      },
      ConcretePourStatus.prepared => {
        ConcretePourStatus.draft,
        ConcretePourStatus.pouring,
        ConcretePourStatus.cancelled,
      },
      ConcretePourStatus.pouring => {
        ConcretePourStatus.poured,
        ConcretePourStatus.cancelled,
      },
      ConcretePourStatus.poured => {
        ConcretePourStatus.followUp,
        ConcretePourStatus.closed,
        ConcretePourStatus.cancelled,
      },
      ConcretePourStatus.followUp => {
        ConcretePourStatus.closed,
        ConcretePourStatus.cancelled,
      },
      ConcretePourStatus.closed ||
      ConcretePourStatus.cancelled => {ConcretePourStatus.draft},
    };
    if (!allowed.contains(target)) {
      throw AgendaValidationFailure(
        '${pour.status.label} durumundan ${target.label} durumuna geçilemez.',
      );
    }
    if (target == ConcretePourStatus.cancelled && reason == null) {
      throw const AgendaValidationFailure(
        'Beton paketi iptal nedeni zorunludur.',
      );
    }
    if (target == ConcretePourStatus.draft && reason == null) {
      throw const AgendaValidationFailure('Yeniden açma nedeni zorunludur.');
    }
    if (target == ConcretePourStatus.prepared) {
      final rows = await database.rawQuery(
        '''
        SELECT count(*) AS value FROM concrete_check_items
        WHERE concrete_pour_id = ? AND is_required = 1 AND status = 'pending'
        ''',
        [pour.id],
      );
      if ((rows.single['value']! as int) > 0) {
        throw const AgendaValidationFailure(
          'Hazır geçişi için zorunlu checklist kalemleri tamamlanmalıdır.',
        );
      }
    }
    if (target == ConcretePourStatus.poured) {
      final trucks = await database.query(
        'concrete_trucks',
        columns: ['id'],
        where: 'concrete_pour_id = ?',
        whereArgs: [pour.id],
        limit: 1,
      );
      if (trucks.isEmpty) {
        throw const AgendaValidationFailure(
          'Dökümü bitirmek için en az bir mikser kaydı gerekir.',
        );
      }
    }
    if (target == ConcretePourStatus.followUp) {
      final evidence = await _missingEvidenceTruckCount(database, pour.id);
      if (evidence > 0) {
        throw const AgendaValidationFailure(
          'Takibe geçmek için her mikserde irsaliye ve mikser kanıtı ya da açık istisna gerekir.',
        );
      }
      final actual = await _actualDelivered(database, pour.id);
      if (actual <= 0) {
        throw const AgendaValidationFailure(
          'Gerçek gelen beton metrajı sıfır olamaz.',
        );
      }
      final variance = (actual - pour.plannedVolumeM3).abs();
      if (variance > 0.005 &&
          (pour.varianceNote == null || pour.varianceNote!.trim().isEmpty)) {
        throw const AgendaValidationFailure(
          'Metraj farkı için açıklama zorunludur.',
        );
      }
      final sampleRows = await database.query(
        'concrete_sample_sets',
        columns: ['id'],
        where: 'concrete_pour_id = ?',
        whereArgs: [pour.id],
        limit: 1,
      );
      if (sampleRows.isEmpty && pour.sampleExceptionReason == null) {
        throw const AgendaValidationFailure(
          'Numune kaydı veya açık numune istisnası zorunludur.',
        );
      }
    }
    if (target == ConcretePourStatus.closed) {
      final checks = await database.rawQuery(
        '''SELECT count(*) AS value FROM concrete_check_items
        WHERE concrete_pour_id = ? AND status = 'pending' ''',
        [pour.id],
      );
      final followUps = await database.rawQuery(
        '''SELECT count(*) AS value FROM concrete_follow_up_items
        WHERE concrete_pour_id = ? AND status = 'pending' ''',
        [pour.id],
      );
      if ((checks.single['value']! as int) > 0 ||
          (followUps.single['value']! as int) > 0) {
        throw const AgendaValidationFailure(
          'Kapanış için checklist ve takip kalemleri tamamlanmalı veya gerekçeli istisna olmalıdır.',
        );
      }
      if (await _missingEvidenceTruckCount(database, pour.id) > 0) {
        throw const AgendaValidationFailure(
          'Eksik mikser kanıtı varken paket kapatılamaz.',
        );
      }
      final samples = await database.rawQuery(
        '''SELECT count(*) AS value FROM concrete_sample_sets
        WHERE concrete_pour_id = ? AND status NOT IN ('completed', 'exception')''',
        [pour.id],
      );
      if ((samples.single['value']! as int) > 0) {
        throw const AgendaValidationFailure(
          'Açık numune takibi varken paket kapatılamaz.',
        );
      }
    }
  }

  Future<void> _insertFollowUpWithReminder(
    Transaction transaction, {
    required String pourId,
    required String projectId,
    required String projectName,
    required String pourCode,
    required String itemKey,
    required String label,
    required String? dueAt,
    required String occurredAt,
    String? sourceSampleSetId,
    int? repeatIntervalMinutes,
  }) async {
    final followUpId = _stableUuid('concrete-follow-up:$pourId:$itemKey');
    final reminderId = _stableUuid('concrete-reminder:$pourId:$itemKey');
    final reminderEventId = _stableUuid(
      'concrete-reminder-created:$pourId:$itemKey',
    );
    final title = '$pourCode — $label';
    await transaction.insert('follow_up_items', {
      'id': reminderId,
      'capture_text': title,
      'title': title,
      'description': '$projectName beton paketi takibi',
      'item_type': ReminderKind.action.storageValue,
      'status': dueAt == null
          ? ReminderStatus.inbox.storageValue
          : ReminderStatus.active.storageValue,
      'project_id': projectId,
      'concrete_pour_id': pourId,
      'is_important': 0,
      'next_attention_at': dueAt,
      'revision': 1,
      'created_at': occurredAt,
      'updated_at': occurredAt,
    });
    await transaction.insert('follow_up_events', {
      'id': reminderEventId,
      'follow_up_id': reminderId,
      'sequence': 1,
      'project_id': projectId,
      'source_concrete_pour_id': pourId,
      'event_type': 'created',
      'occurred_at': occurredAt,
      'payload_json': jsonEncode({
        'source_concrete_pour_id': pourId,
        'next_attention_at': dueAt,
        'status': dueAt == null ? 'inbox' : 'active',
      }),
    });
    final platformId = await _allocatePlatformNotificationId(
      transaction,
      reminderId,
    );
    await transaction.insert('reminder_notification_bindings', {
      'reminder_id': reminderId,
      'platform_notification_id': platformId,
      'scheduled_for': dueAt,
      'sync_state': dueAt == null
          ? NotificationSyncState.cancelled.storageValue
          : NotificationSyncState.unavailable.storageValue,
      'last_synced_at': occurredAt,
      'safe_error_code': dueAt == null ? null : 'pending_sync',
      'repeat_interval_minutes': repeatIntervalMinutes,
    });
    await transaction.insert('concrete_follow_up_items', {
      'id': followUpId,
      'concrete_pour_id': pourId,
      'source_sample_set_id': sourceSampleSetId,
      'item_key': itemKey,
      'label': label,
      'due_at': dueAt,
      'status': ConcreteFollowUpStatus.pending.storageValue,
      'reminder_id': reminderId,
      'revision': 1,
      'created_at': occurredAt,
      'updated_at': occurredAt,
    });
    await _insertConcreteEvent(
      transaction,
      id: _stableUuid('concrete-follow-up-linked:$pourId:$itemKey'),
      pourId: pourId,
      eventType: 'follow_up.linked',
      occurredAt: occurredAt,
      payload: {
        'follow_up_id': followUpId,
        'reminder_id': reminderId,
        'source_sample_set_id': sourceSampleSetId,
        'due_at': dueAt,
      },
    );
  }

  Future<void> _syncFieldReminderTasks(
    DatabaseExecutor database, {
    required String pourId,
    required String projectId,
    required bool laboratoryComplete,
    required bool inspectionComplete,
    required String occurredAt,
  }) async {
    await _syncFieldReminderTask(
      database,
      pourId: pourId,
      projectId: projectId,
      itemKey: 'laboratory_appointment_task',
      complete: laboratoryComplete,
      occurredAt: occurredAt,
    );
    await _syncFieldReminderTask(
      database,
      pourId: pourId,
      projectId: projectId,
      itemKey: 'inspection_notification_task',
      complete: inspectionComplete,
      occurredAt: occurredAt,
    );
  }

  Future<void> _syncFieldReminderTask(
    DatabaseExecutor database, {
    required String pourId,
    required String projectId,
    required String itemKey,
    required bool complete,
    required String occurredAt,
  }) async {
    final rows = await database.query(
      'concrete_follow_up_items',
      where: 'concrete_pour_id = ? AND item_key = ?',
      whereArgs: [pourId, itemKey],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final followUp = _followUpFromRow(rows.single);
    if (followUp.reminderId == null) {
      throw const AgendaValidationFailure('Bağlı hatırlatıcı bulunamadı.');
    }
    final reminderRows = await database.query(
      'follow_up_items',
      columns: ['next_attention_at'],
      where: 'id = ?',
      whereArgs: [followUp.reminderId],
      limit: 1,
    );
    if (reminderRows.isEmpty) {
      throw const AgendaValidationFailure('Bağlı hatırlatıcı bulunamadı.');
    }
    final pending = !complete;
    final targetStatus = pending
        ? ConcreteFollowUpStatus.pending
        : ConcreteFollowUpStatus.completed;
    final dueAt = pending
        ? followUp.status == ConcreteFollowUpStatus.pending &&
                  reminderRows.single['next_attention_at'] != null
              ? reminderRows.single['next_attention_at']! as String
              : CseTimeCodec.encodeUtc(
                  CseTimeCodec.decodeCanonicalUtc(
                    occurredAt,
                  ).add(const Duration(hours: 1)),
                )
        : null;
    final changed = followUp.status != targetStatus || followUp.dueAt != dueAt;
    if (changed) {
      final count = await database.update(
        'concrete_follow_up_items',
        {
          'due_at': dueAt,
          'status': targetStatus.storageValue,
          'revision': followUp.revision + 1,
          'updated_at': occurredAt,
          'completed_at': pending ? null : occurredAt,
          'reason': null,
        },
        where: 'id = ? AND revision = ?',
        whereArgs: [followUp.id, followUp.revision],
      );
      if (count != 1) throw _staleFailure();
      await _syncLinkedReminder(
        database,
        reminderId: followUp.reminderId!,
        eventId: _stableUuid(
          'field-reminder-${pending ? 'reopened' : 'completed'}:'
          '${followUp.id}:${followUp.revision + 1}',
        ),
        projectId: projectId,
        pourId: pourId,
        pending: pending,
        dueAt: dueAt,
        occurredAt: occurredAt,
        outcomeNote: complete
            ? 'Beton paketindeki ilgili alan tamamlandı.'
            : null,
      );
      await _insertConcreteEvent(
        database,
        id: _stableUuid(
          'field-follow-up-${pending ? 'reopened' : 'completed'}:'
          '${followUp.id}:${followUp.revision + 1}',
        ),
        pourId: pourId,
        eventType: 'follow_up.linked',
        occurredAt: occurredAt,
        payload: {
          'follow_up_id': followUp.id,
          'reminder_id': followUp.reminderId,
          'status': targetStatus.storageValue,
          'due_at': dueAt,
          'automatic': true,
        },
      );
    }
    await database.update(
      'reminder_notification_bindings',
      {'repeat_interval_minutes': pending ? 60 : null},
      where: 'reminder_id = ?',
      whereArgs: [followUp.reminderId],
    );
  }

  Future<void> _syncLinkedReminder(
    DatabaseExecutor database, {
    required String reminderId,
    required String eventId,
    required String projectId,
    required String pourId,
    required bool pending,
    required String? dueAt,
    required String occurredAt,
    required String? outcomeNote,
  }) async {
    final rows = await database.query(
      'follow_up_items',
      where: 'id = ? AND concrete_pour_id = ? AND project_id = ?',
      whereArgs: [reminderId, pourId, projectId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Bağlı hatırlatıcı bulunamadı.');
    }
    final row = rows.single;
    final currentStatus = ReminderStatus.fromStorage(row['status']! as String);
    final targetStatus = pending
        ? (dueAt == null ? ReminderStatus.inbox : ReminderStatus.active)
        : ReminderStatus.completed;
    final same =
        currentStatus == targetStatus &&
        row['next_attention_at'] == (pending ? dueAt : null);
    if (same) return;
    final revision = row['revision']! as int;
    final changed = await database.update(
      'follow_up_items',
      {
        'status': targetStatus.storageValue,
        'next_attention_at': pending ? dueAt : null,
        'outcome_type': pending
            ? null
            : ReminderOutcomeType.completed.storageValue,
        'outcome_note': pending ? null : outcomeNote,
        'completed_at': pending ? null : occurredAt,
        'cancelled_at': null,
        'revision': revision + 1,
        'updated_at': occurredAt,
      },
      where: 'id = ? AND revision = ?',
      whereArgs: [reminderId, revision],
    );
    if (changed != 1) throw _staleFailure();
    final sequence = await _nextReminderSequence(database, reminderId);
    await database.insert('follow_up_events', {
      'id': eventId,
      'follow_up_id': reminderId,
      'sequence': sequence,
      'project_id': projectId,
      'source_concrete_pour_id': pourId,
      'event_type': pending ? 'reopened' : 'completed',
      'occurred_at': occurredAt,
      'payload_json': jsonEncode({
        'source_concrete_pour_id': pourId,
        'status': targetStatus.storageValue,
        'next_attention_at': pending ? dueAt : null,
      }),
    });
    await database.update(
      'reminder_notification_bindings',
      {
        'scheduled_for': pending ? dueAt : null,
        'sync_state': pending && dueAt != null
            ? NotificationSyncState.unavailable.storageValue
            : NotificationSyncState.cancelled.storageValue,
        'last_synced_at': occurredAt,
        'safe_error_code': pending && dueAt != null ? 'pending_sync' : null,
      },
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
    );
  }

  Future<void> _completeSampleFollowUps(
    DatabaseExecutor database, {
    required ConcretePour pour,
    required String sampleId,
    required String occurredAt,
    required String? reason,
    bool deliveryOnly = false,
  }) async {
    final rows = await database.query(
      'concrete_follow_up_items',
      where: deliveryOnly
          ? "source_sample_set_id = ? AND status = 'pending' "
                "AND item_key LIKE 'sample_delivery:%'"
          : "source_sample_set_id = ? AND status = 'pending'",
      whereArgs: [sampleId],
    );
    for (final row in rows) {
      final followUp = _followUpFromRow(row);
      await database.update(
        'concrete_follow_up_items',
        {
          'status': ConcreteFollowUpStatus.completed.storageValue,
          'completed_at': occurredAt,
          'note': 'Numune durumu ile kapatıldı.',
          'revision': followUp.revision + 1,
          'updated_at': occurredAt,
        },
        where: 'id = ? AND revision = ?',
        whereArgs: [followUp.id, followUp.revision],
      );
      if (followUp.reminderId != null) {
        await _syncLinkedReminder(
          database,
          reminderId: followUp.reminderId!,
          eventId: _stableUuid(
            'sample-reminder-completed:$sampleId:${followUp.id}:${followUp.revision}',
          ),
          projectId: pour.projectId,
          pourId: pour.id,
          pending: false,
          dueAt: null,
          occurredAt: occurredAt,
          outcomeNote: reason ?? 'Numune sonucu tamamlandı.',
        );
      }
    }
  }

  Future<void> _completeAllLinkedReminders(
    DatabaseExecutor database, {
    required String pourId,
    required String projectId,
    required String occurredAt,
    required String? outcomeNote,
  }) async {
    final rows = await database.query(
      'follow_up_items',
      columns: ['id'],
      where:
          "concrete_pour_id = ? AND status NOT IN ('completed', 'cancelled')",
      whereArgs: [pourId],
    );
    for (final row in rows) {
      final id = row['id']! as String;
      await _syncLinkedReminder(
        database,
        reminderId: id,
        eventId: _stableUuid(
          'concrete-reminder-terminal:$pourId:$id:$occurredAt',
        ),
        projectId: projectId,
        pourId: pourId,
        pending: false,
        dueAt: null,
        occurredAt: occurredAt,
        outcomeNote: outcomeNote ?? 'Beton paketi kapatıldı.',
      );
    }
  }

  Future<void> _reopenPendingLinkedReminders(
    DatabaseExecutor database, {
    required String pourId,
    required String projectId,
    required String occurredAt,
  }) async {
    final rows = await database.rawQuery(
      '''
      SELECT c.reminder_id, c.due_at
      FROM concrete_follow_up_items c
      JOIN follow_up_items f ON f.id = c.reminder_id
      WHERE c.concrete_pour_id = ? AND c.status = 'pending'
        AND f.status IN ('completed', 'cancelled')
      ''',
      [pourId],
    );
    for (final row in rows) {
      final id = row['reminder_id']! as String;
      await _syncLinkedReminder(
        database,
        reminderId: id,
        eventId: _stableUuid(
          'concrete-reminder-reopened:$pourId:$id:$occurredAt',
        ),
        projectId: projectId,
        pourId: pourId,
        pending: true,
        dueAt: row['due_at'] as String?,
        occurredAt: occurredAt,
        outcomeNote: null,
      );
    }
  }

  Future<ConcretePourDetail> _loadDetail(
    DatabaseExecutor database,
    String pourId,
  ) async {
    final pour = await _requirePour(database, pourId);
    final checks = (await database.query(
      'concrete_check_items',
      where: 'concrete_pour_id = ?',
      whereArgs: [pourId],
      orderBy: 'sort_order ASC, id ASC',
    )).map(_checkFromRow).toList(growable: false);
    final trucks = (await database.query(
      'concrete_trucks',
      where: 'concrete_pour_id = ?',
      whereArgs: [pourId],
      orderBy: 'sequence_no ASC, created_at ASC, id ASC',
    )).map(_truckFromRow).toList(growable: false);
    final samples = (await database.query(
      'concrete_sample_sets',
      where: 'concrete_pour_id = ?',
      whereArgs: [pourId],
      orderBy: 'created_at ASC, id ASC',
    )).map(_sampleFromRow).toList(growable: false);
    final followUps = (await database.query(
      'concrete_follow_up_items',
      where: 'concrete_pour_id = ?',
      whereArgs: [pourId],
      orderBy: 'due_at IS NULL ASC, due_at ASC, created_at ASC, id ASC',
    )).map(_followUpFromRow).toList(growable: false);
    final attachments = (await database.query(
      'concrete_attachments',
      where: 'concrete_pour_id = ? AND archived_at IS NULL',
      whereArgs: [pourId],
      orderBy: 'captured_at ASC, created_at ASC, id ASC',
    )).map(_attachmentFromRow).toList(growable: false);
    final events = (await database.query(
      'concrete_pour_events',
      where: 'concrete_pour_id = ?',
      whereArgs: [pourId],
      orderBy: 'sequence ASC',
    )).map(_eventFromRow).toList(growable: false);
    final reminderRows = await database.rawQuery(
      '''
      SELECT f.*, p.name AS project_name
      FROM follow_up_items f
      JOIN projects p ON p.id = f.project_id
      WHERE f.concrete_pour_id = ?
      ORDER BY f.created_at ASC, f.id ASC
      ''',
      [pourId],
    );
    final reminders = reminderRows
        .map(_reminderFromRow)
        .toList(growable: false);
    final actual = trucks
        .where(
          (item) =>
              item.result == ConcreteTruckResult.received ||
              item.result == ConcreteTruckResult.partial,
        )
        .fold<double>(0, (sum, item) => sum + item.volumeM3);
    final variance = actual - pour.plannedVolumeM3;
    String? firstTruckAt;
    String? lastTruckAt;
    for (final truck in trucks) {
      final value = truck.arrivedAt ?? truck.batchTime;
      if (value == null) continue;
      if (firstTruckAt == null || value.compareTo(firstTruckAt) < 0) {
        firstTruckAt = value;
      }
      if (lastTruckAt == null || value.compareTo(lastTruckAt) > 0) {
        lastTruckAt = value;
      }
    }
    int? duration;
    if (pour.actualStartedAt != null && pour.actualEndedAt != null) {
      duration = CseTimeCodec.decodeCanonicalUtc(pour.actualEndedAt!)
          .difference(CseTimeCodec.decodeCanonicalUtc(pour.actualStartedAt!))
          .inMinutes;
    }
    return ConcretePourDetail(
      pour: pour,
      checks: checks,
      trucks: trucks,
      sampleSets: samples,
      followUps: followUps,
      attachments: attachments,
      events: events,
      linkedReminders: reminders,
      metrics: ConcreteMetrics(
        actualDeliveredM3: actual,
        varianceM3: variance,
        variancePercent: pour.plannedVolumeM3 == 0
            ? null
            : variance / pour.plannedVolumeM3 * 100,
        receivedTruckCount: trucks
            .where((item) => item.result == ConcreteTruckResult.received)
            .length,
        heldTruckCount: trucks
            .where((item) => item.result == ConcreteTruckResult.held)
            .length,
        returnedTruckCount: trucks
            .where((item) => item.result == ConcreteTruckResult.returned)
            .length,
        partialTruckCount: trucks
            .where((item) => item.result == ConcreteTruckResult.partial)
            .length,
        firstTruckAt: firstTruckAt,
        lastTruckAt: lastTruckAt,
        pourDurationMinutes: duration,
        sampleSetCount: samples.length,
        sampleCount: samples.fold(0, (sum, item) => sum + item.sampleCount),
        pendingCheckCount: checks
            .where((item) => item.status == ConcreteCheckStatus.pending)
            .length,
        missingEvidenceTruckCount: await _missingEvidenceTruckCount(
          database,
          pourId,
        ),
        openFollowUpCount: followUps
            .where((item) => item.status == ConcreteFollowUpStatus.pending)
            .length,
      ),
    );
  }

  Future<ConcretePour> _requirePour(
    DatabaseExecutor database,
    String pourId,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT c.*, p.name AS project_name
      FROM concrete_pours c JOIN projects p ON p.id = c.project_id
      WHERE c.id = ? LIMIT 1
      ''',
      [pourId],
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Beton paketi bulunamadı.');
    }
    return _pourFromRow(rows.single);
  }

  Future<String> _requireProject(
    DatabaseExecutor database,
    String projectId,
  ) async {
    final rows = await database.query(
      'projects',
      columns: ['name'],
      where: 'id = ? AND archived_at IS NULL',
      whereArgs: [projectId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AgendaValidationFailure('Seçilen proje bulunamadı.');
    }
    return rows.single['name']! as String;
  }

  Future<void> _requireSource(
    DatabaseExecutor database, {
    required String table,
    required String id,
    required String pourId,
    required String label,
  }) async {
    final rows = await database.query(
      table,
      columns: ['id'],
      where: 'id = ? AND concrete_pour_id = ?',
      whereArgs: [id, pourId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw AgendaValidationFailure('$label bulunamadı veya başka pakete ait.');
    }
  }

  Future<void> _validateAttachmentSources(
    DatabaseExecutor database,
    AttachConcreteEvidenceCommand command,
  ) async {
    await _requirePour(database, command.pourId);
    if (command.truckId != null) {
      await _requireSource(
        database,
        table: 'concrete_trucks',
        id: command.truckId!,
        pourId: command.pourId,
        label: 'Kaynak mikser',
      );
    }
    if (command.sampleSetId != null) {
      await _requireSource(
        database,
        table: 'concrete_sample_sets',
        id: command.sampleSetId!,
        pourId: command.pourId,
        label: 'Kaynak numune',
      );
    }
    if (command.checkItemId != null) {
      await _requireSource(
        database,
        table: 'concrete_check_items',
        id: command.checkItemId!,
        pourId: command.pourId,
        label: 'Kaynak kontrol',
      );
    }
    if ((command.evidenceType == ConcreteEvidenceType.deliveryReceiptScan ||
            command.evidenceType == ConcreteEvidenceType.mixerPhoto) &&
        command.truckId == null) {
      throw const AgendaValidationFailure(
        'İrsaliye ve mikser kanıtı bir mikser kaydına bağlanmalıdır.',
      );
    }
    if ((command.evidenceType == ConcreteEvidenceType.samplePhoto ||
            command.evidenceType ==
                ConcreteEvidenceType.laboratoryDeliveryDocument ||
            command.evidenceType == ConcreteEvidenceType.resultDocument) &&
        command.sampleSetId == null) {
      throw const AgendaValidationFailure(
        'Numune kanıtı bir numune setine bağlanmalıdır.',
      );
    }
  }

  Future<void> _insertConcreteEvent(
    DatabaseExecutor database, {
    required String id,
    required String pourId,
    required String eventType,
    required String occurredAt,
    required Map<String, Object?> payload,
  }) async {
    final hook = beforeConcreteEventInsert;
    if (hook != null && database is Transaction) await hook(database);
    final rows = await database.rawQuery(
      'SELECT coalesce(max(sequence), 0) + 1 AS value FROM concrete_pour_events WHERE concrete_pour_id = ?',
      [pourId],
    );
    await database.insert('concrete_pour_events', {
      'id': id,
      'concrete_pour_id': pourId,
      'sequence': rows.single['value']! as int,
      'event_type': eventType,
      'occurred_at': occurredAt,
      'payload_json': jsonEncode(payload),
    });
  }

  Future<bool> _isIdempotentEvent(
    DatabaseExecutor database,
    String eventId,
    String pourId,
  ) async {
    final rows = await database.query(
      'concrete_pour_events',
      columns: ['concrete_pour_id'],
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    if (rows.single['concrete_pour_id'] != pourId) {
      throw const AgendaValidationFailure(
        'Event kimliği başka bir Beton paketi için kullanılıyor.',
      );
    }
    return true;
  }

  Future<void> _advancePour(
    DatabaseExecutor database,
    ConcretePour pour,
    String timestamp, [
    Map<String, Object?> values = const {},
  ]) async {
    final changed = await database.update(
      'concrete_pours',
      {...values, 'revision': pour.revision + 1, 'updated_at': timestamp},
      where: 'id = ? AND revision = ?',
      whereArgs: [pour.id, pour.revision],
    );
    if (changed != 1) throw _staleFailure();
  }

  Future<int> _missingEvidenceTruckCount(
    DatabaseExecutor database,
    String pourId,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT count(*) AS value FROM concrete_trucks t
      WHERE t.concrete_pour_id = ?
        AND (t.evidence_exception_reason IS NULL OR length(trim(t.evidence_exception_reason)) = 0)
        AND (
          NOT EXISTS (
            SELECT 1 FROM concrete_attachments a
            WHERE a.truck_id = t.id AND a.archived_at IS NULL
              AND a.evidence_type = 'delivery_receipt_scan'
          ) OR NOT EXISTS (
            SELECT 1 FROM concrete_attachments a
            WHERE a.truck_id = t.id AND a.archived_at IS NULL
              AND a.evidence_type = 'mixer_photo'
          )
        )
      ''',
      [pourId],
    );
    return rows.single['value']! as int;
  }

  Future<double> _actualDelivered(
    DatabaseExecutor database,
    String pourId,
  ) async {
    final rows = await database.rawQuery(
      '''SELECT coalesce(sum(volume_m3), 0.0) AS value FROM concrete_trucks
      WHERE concrete_pour_id = ? AND result IN ('received', 'partial')''',
      [pourId],
    );
    return (rows.single['value']! as num).toDouble();
  }

  Future<int> _nextReminderSequence(
    DatabaseExecutor database,
    String id,
  ) async {
    final rows = await database.rawQuery(
      'SELECT coalesce(max(sequence), 0) + 1 AS value FROM follow_up_events WHERE follow_up_id = ?',
      [id],
    );
    return rows.single['value']! as int;
  }

  Future<int> _allocatePlatformNotificationId(
    DatabaseExecutor database,
    String reminderId,
  ) async {
    var candidate = 2166136261;
    for (final value in reminderId.codeUnits) {
      candidate ^= value;
      candidate = (candidate * 16777619) & 0x7fffffff;
    }
    if (candidate == 0) candidate = 1;
    for (var attempts = 0; attempts < 2147483647; attempts += 1) {
      final collision = await database.query(
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

  void _validateCreate(CreateConcretePourCommand command) {
    validateUuid(command.id, 'Beton paketi kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    validateUuid(command.projectId, 'Proje kimliği');
    requiredTrimmed(command.pourCode, 'Döküm kodu', maxLength: 80);
    requiredTrimmed(command.elementLocation, 'Mahal/eleman', maxLength: 240);
    requiredTrimmed(command.concreteClass, 'Beton sınıfı', maxLength: 80);
    validateCanonicalTimestamp(command.plannedAt, 'Planlanan döküm zamanı');
    _validateVolume(command.plannedVolumeM3, 'Planlanan metraj');
    if (command.orderedVolumeM3 != null) {
      _validateVolume(command.orderedVolumeM3!, 'Sipariş metrajı');
    }
    if (command.laboratoryAppointment != null) {
      validateCanonicalTimestamp(
        command.laboratoryAppointment!,
        'Laboratuvar randevusu',
      );
    }
    if (command.inspectionNotifiedAt != null) {
      validateCanonicalTimestamp(
        command.inspectionNotifiedAt!,
        'Yapı denetim bildirim zamanı',
      );
    }
  }

  void _validateUpdate(UpdateConcretePourCommand command) {
    validateUuid(command.id, 'Beton paketi kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    requiredTrimmed(command.elementLocation, 'Mahal/eleman', maxLength: 240);
    requiredTrimmed(command.concreteClass, 'Beton sınıfı', maxLength: 80);
    validateCanonicalTimestamp(command.plannedAt, 'Planlanan döküm zamanı');
    _validateVolume(command.plannedVolumeM3, 'Planlanan metraj');
    if (command.orderedVolumeM3 != null) {
      _validateVolume(command.orderedVolumeM3!, 'Sipariş metrajı');
    }
    if (command.laboratoryAppointment != null) {
      validateCanonicalTimestamp(
        command.laboratoryAppointment!,
        'Laboratuvar randevusu',
      );
    }
    if (command.inspectionNotifiedAt != null) {
      validateCanonicalTimestamp(
        command.inspectionNotifiedAt!,
        'Yapı denetim bildirim zamanı',
      );
    }
  }

  CreateConcretePourCommand _normalizedCreate(
    CreateConcretePourCommand value,
  ) => CreateConcretePourCommand(
    id: value.id,
    eventId: value.eventId,
    projectId: value.projectId,
    pourCode: requiredTrimmed(value.pourCode, 'Döküm kodu', maxLength: 80),
    elementLocation: requiredTrimmed(
      value.elementLocation,
      'Mahal/eleman',
      maxLength: 240,
    ),
    plannedAt: value.plannedAt,
    concreteClass: requiredTrimmed(
      value.concreteClass,
      'Beton sınıfı',
      maxLength: 80,
    ),
    plannedVolumeM3: value.plannedVolumeM3,
    blockName: optionalTrimmed(value.blockName, 'Blok', maxLength: 80),
    floorName: optionalTrimmed(value.floorName, 'Kat', maxLength: 80),
    axisName: optionalTrimmed(value.axisName, 'Aks', maxLength: 120),
    targetSlump: optionalTrimmed(
      value.targetSlump,
      'Hedef slump',
      maxLength: 80,
    ),
    orderedVolumeM3: value.orderedVolumeM3,
    plantName: optionalTrimmed(value.plantName, 'Santral', maxLength: 160),
    plantBranch: optionalTrimmed(
      value.plantBranch,
      'Santral şubesi',
      maxLength: 160,
    ),
    plantContact: optionalTrimmed(
      value.plantContact,
      'Santral irtibatı',
      maxLength: 160,
    ),
    plantAppointmentReference: optionalTrimmed(
      value.plantAppointmentReference,
      'Santral randevu referansı',
      maxLength: 160,
    ),
    pumpEquipment: optionalTrimmed(
      value.pumpEquipment,
      'Pompa/ekipman',
      maxLength: 240,
    ),
    laboratoryName: optionalTrimmed(
      value.laboratoryName,
      'Laboratuvar',
      maxLength: 160,
    ),
    laboratoryContact: optionalTrimmed(
      value.laboratoryContact,
      'Laboratuvar irtibatı',
      maxLength: 160,
    ),
    laboratoryAppointment: value.laboratoryAppointment,
    inspectionNotifiedAt: value.inspectionNotifiedAt,
    inspectionNotifiedPerson: optionalTrimmed(
      value.inspectionNotifiedPerson,
      'Yapı denetim kişisi',
      maxLength: 160,
    ),
    generalNote: optionalTrimmed(
      value.generalNote,
      'Genel not',
      maxLength: 4000,
    ),
  );

  Map<String, Object?> _normalizedUpdate(UpdateConcretePourCommand value) => {
    'element_location': requiredTrimmed(
      value.elementLocation,
      'Mahal/eleman',
      maxLength: 240,
    ),
    'block_name': optionalTrimmed(value.blockName, 'Blok', maxLength: 80),
    'floor_name': optionalTrimmed(value.floorName, 'Kat', maxLength: 80),
    'axis_name': optionalTrimmed(value.axisName, 'Aks', maxLength: 120),
    'planned_at': value.plannedAt,
    'concrete_class': requiredTrimmed(
      value.concreteClass,
      'Beton sınıfı',
      maxLength: 80,
    ),
    'target_slump': optionalTrimmed(
      value.targetSlump,
      'Hedef slump',
      maxLength: 80,
    ),
    'planned_volume_m3': value.plannedVolumeM3,
    'ordered_volume_m3': value.orderedVolumeM3,
    'plant_name': optionalTrimmed(value.plantName, 'Santral', maxLength: 160),
    'plant_branch': optionalTrimmed(
      value.plantBranch,
      'Santral şubesi',
      maxLength: 160,
    ),
    'plant_contact': optionalTrimmed(
      value.plantContact,
      'Santral irtibatı',
      maxLength: 160,
    ),
    'plant_appointment_reference': optionalTrimmed(
      value.plantAppointmentReference,
      'Santral randevu referansı',
      maxLength: 160,
    ),
    'pump_equipment': optionalTrimmed(
      value.pumpEquipment,
      'Pompa/ekipman',
      maxLength: 240,
    ),
    'laboratory_name': optionalTrimmed(
      value.laboratoryName,
      'Laboratuvar',
      maxLength: 160,
    ),
    'laboratory_contact': optionalTrimmed(
      value.laboratoryContact,
      'Laboratuvar irtibatı',
      maxLength: 160,
    ),
    'laboratory_appointment': value.laboratoryAppointment,
    'inspection_notified_at': value.inspectionNotifiedAt,
    'inspection_notified_person': optionalTrimmed(
      value.inspectionNotifiedPerson,
      'Yapı denetim kişisi',
      maxLength: 160,
    ),
    'general_note': optionalTrimmed(
      value.generalNote,
      'Genel not',
      maxLength: 4000,
    ),
    'sample_exception_reason': optionalTrimmed(
      value.sampleExceptionReason,
      'Numune istisnası',
      maxLength: 1000,
    ),
    'variance_note': optionalTrimmed(
      value.varianceNote,
      'Metraj farkı notu',
      maxLength: 1000,
    ),
  };

  bool _sameCreate(ConcretePour current, CreateConcretePourCommand value) =>
      current.projectId == value.projectId &&
      current.pourCode == value.pourCode &&
      current.elementLocation == value.elementLocation &&
      current.plannedAt == value.plannedAt &&
      current.concreteClass == value.concreteClass &&
      current.plannedVolumeM3 == value.plannedVolumeM3;

  void _validateTruck(SaveConcreteTruckCommand command) {
    validateUuid(command.id, 'Mikser kimliği');
    validateUuid(command.pourId, 'Beton paketi kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedPourRevision);
    if (command.expectedTruckRevision < 0) {
      throw const AgendaValidationFailure('Mikser revision geçersizdir.');
    }
    if (command.sequenceNo < 1) {
      throw const AgendaValidationFailure('Mikser sırası en az 1 olmalıdır.');
    }
    requiredTrimmed(command.vehiclePlate, 'Mikser plakası', maxLength: 40);
    requiredTrimmed(
      command.deliveryNoteNumber,
      'İrsaliye numarası',
      maxLength: 120,
    );
    _validateVolume(command.volumeM3, 'Mikser metrajı');
    for (final value in [
      command.batchTime,
      command.arrivedAt,
      command.unloadingStartedAt,
      command.unloadingEndedAt,
    ]) {
      if (value != null) validateCanonicalTimestamp(value, 'Mikser zamanı');
    }
    final timeline = [
      command.batchTime,
      command.arrivedAt,
      command.unloadingStartedAt,
      command.unloadingEndedAt,
    ].whereType<String>().toList();
    for (var index = 1; index < timeline.length; index += 1) {
      if (timeline[index].compareTo(timeline[index - 1]) < 0) {
        throw const AgendaValidationFailure(
          'Mikser zamanları kronolojik olmalıdır.',
        );
      }
    }
    if (command.result != ConcreteTruckResult.received &&
        optionalTrimmed(command.reason, 'Mikser sonucu nedeni') == null) {
      throw const AgendaValidationFailure(
        'Teslim alınmayan mikser sonucunda neden zorunludur.',
      );
    }
  }

  Map<String, Object?> _normalizedTruck(SaveConcreteTruckCommand value) => {
    'sequence_no': value.sequenceNo,
    'vehicle_plate': requiredTrimmed(
      value.vehiclePlate,
      'Mikser plakası',
      maxLength: 40,
    ).toUpperCase(),
    'delivery_note_number': requiredTrimmed(
      value.deliveryNoteNumber,
      'İrsaliye numarası',
      maxLength: 120,
    ),
    'plant_snapshot': optionalTrimmed(
      value.plantSnapshot,
      'Santral snapshot',
      maxLength: 240,
    ),
    'batch_time': value.batchTime,
    'arrived_at': value.arrivedAt,
    'unloading_started_at': value.unloadingStartedAt,
    'unloading_ended_at': value.unloadingEndedAt,
    'volume_m3': value.volumeM3,
    'measured_slump': value.measuredSlump,
    'concrete_temperature': value.concreteTemperature,
    'result': value.result.storageValue,
    'reason': optionalTrimmed(
      value.reason,
      'Mikser sonucu nedeni',
      maxLength: 1000,
    ),
    'evidence_exception_reason': optionalTrimmed(
      value.evidenceExceptionReason,
      'Kanıt istisnası',
      maxLength: 1000,
    ),
  };

  void _validateSample(SaveConcreteSampleSetCommand command) {
    validateUuid(command.id, 'Numune kimliği');
    validateUuid(command.pourId, 'Beton paketi kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    if (command.sourceTruckId != null) {
      validateUuid(command.sourceTruckId!, 'Kaynak mikser kimliği');
    }
    _validateExpectedRevision(command.expectedPourRevision);
    if (command.expectedSampleRevision < 0) {
      throw const AgendaValidationFailure('Numune revision geçersizdir.');
    }
    if (command.sampleCode != null) {
      requiredTrimmed(command.sampleCode!, 'Numune kodu', maxLength: 120);
    }
    if (command.sampleCount < 0 ||
        command.sampleLabels.length > command.sampleCount) {
      throw const AgendaValidationFailure(
        'Numune adedi ve etiketleri tutarsızdır.',
      );
    }
    for (final label in command.sampleLabels) {
      requiredTrimmed(label, 'Numune etiketi', maxLength: 120);
    }
    for (final value in [
      command.sampledAt,
      command.laboratoryAppointmentAt,
      command.deliveredAt,
      ...command.expectedResultDates,
    ]) {
      if (value != null) validateCanonicalTimestamp(value, 'Numune zamanı');
    }
    if ({
          ConcreteSampleStatus.sampled,
          ConcreteSampleStatus.delivered,
          ConcreteSampleStatus.waitingResult,
          ConcreteSampleStatus.completed,
        }.contains(command.status) &&
        (command.sampledAt == null ||
            command.sampleCount < 1 ||
            command.sampleLabels.length != command.sampleCount)) {
      throw const AgendaValidationFailure(
        'Alınmış numunede zaman, adet ve tüm etiketler zorunludur.',
      );
    }
    if ({
          ConcreteSampleStatus.delivered,
          ConcreteSampleStatus.waitingResult,
          ConcreteSampleStatus.completed,
        }.contains(command.status) &&
        command.deliveredAt == null) {
      throw const AgendaValidationFailure(
        'Teslim edilmiş numunede teslim zamanı zorunludur.',
      );
    }
    if (command.status == ConcreteSampleStatus.exception &&
        optionalTrimmed(command.reason, 'Numune istisnası') == null) {
      throw const AgendaValidationFailure(
        'Numune istisnasında neden zorunludur.',
      );
    }
  }

  Map<String, Object?> _normalizedSample(
    SaveConcreteSampleSetCommand value,
  ) => {
    'source_truck_id': value.sourceTruckId,
    'sample_code': value.sampleCode == null
        ? null
        : requiredTrimmed(value.sampleCode!, 'Numune kodu', maxLength: 120),
    'sample_count': value.sampleCount,
    'sample_labels_json': jsonEncode(
      value.sampleLabels.map((item) => item.trim()).toList(),
    ),
    'sampled_at': value.sampledAt,
    'sampled_by': optionalTrimmed(
      value.sampledBy,
      'Numuneyi alan',
      maxLength: 160,
    ),
    'laboratory_appointment_at': value.laboratoryAppointmentAt,
    'delivered_at': value.deliveredAt,
    'delivered_to': optionalTrimmed(
      value.deliveredTo,
      'Teslim alan',
      maxLength: 160,
    ),
    'expected_result_dates_json': jsonEncode(
      [...value.expectedResultDates]..sort(),
    ),
    'status': value.status.storageValue,
    'note': optionalTrimmed(value.note, 'Numune notu', maxLength: 1000),
    'reason': optionalTrimmed(value.reason, 'Numune nedeni', maxLength: 1000),
  };

  void _validateAttachment(AttachConcreteEvidenceCommand command) {
    validateUuid(command.id, 'Kanıt kimliği');
    validateUuid(command.pourId, 'Beton paketi kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedPourRevision);
    if (command.truckId != null) {
      validateUuid(command.truckId!, 'Mikser kimliği');
    }
    if (command.sampleSetId != null) {
      validateUuid(command.sampleSetId!, 'Numune kimliği');
    }
    if (command.checkItemId != null) {
      validateUuid(command.checkItemId!, 'Kontrol kimliği');
    }
    final sourceCount = [
      command.truckId,
      command.sampleSetId,
      command.checkItemId,
    ].whereType<String>().length;
    if (sourceCount > 1) {
      throw const AgendaValidationFailure(
        'Kanıt yalnız bir kesin kaynak kayda bağlanabilir.',
      );
    }
    requiredTrimmed(command.originalFileName, 'Dosya adı', maxLength: 255);
    if (command.bytes.isEmpty) {
      throw const AgendaValidationFailure('Kanıt dosyası boş olamaz.');
    }
    validateCanonicalTimestamp(command.capturedAt, 'Kanıt zamanı');
  }

  Future<void> _requireUniqueTruck(
    DatabaseExecutor database,
    String pourId,
    int sequence,
    String note, {
    String? excludingId,
  }) async {
    final rows = await database.query(
      'concrete_trucks',
      columns: ['id'],
      where: excludingId == null
          ? 'concrete_pour_id = ? AND (sequence_no = ? OR delivery_note_number = ?)'
          : 'concrete_pour_id = ? AND (sequence_no = ? OR delivery_note_number = ?) AND id != ?',
      whereArgs: excludingId == null
          ? [pourId, sequence, note]
          : [pourId, sequence, note, excludingId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      throw const AgendaValidationFailure(
        'Mikser sırası veya irsaliye numarası zaten kullanılıyor.',
      );
    }
  }

  Future<void> _requireUniqueSample(
    DatabaseExecutor database,
    String pourId,
    String code, {
    String? excludingId,
  }) async {
    final rows = await database.query(
      'concrete_sample_sets',
      columns: ['id'],
      where: excludingId == null
          ? 'concrete_pour_id = ? AND sample_code = ?'
          : 'concrete_pour_id = ? AND sample_code = ? AND id != ?',
      whereArgs: excludingId == null
          ? [pourId, code]
          : [pourId, code, excludingId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      throw const AgendaValidationFailure(
        'Numune kodu bu pakette zaten kullanılıyor.',
      );
    }
  }

  bool _truckMatches(ConcreteTruck item, Map<String, Object?> values) =>
      _jsonEqual(values, {
        'sequence_no': item.sequenceNo,
        'vehicle_plate': item.vehiclePlate,
        'delivery_note_number': item.deliveryNoteNumber,
        'plant_snapshot': item.plantSnapshot,
        'batch_time': item.batchTime,
        'arrived_at': item.arrivedAt,
        'unloading_started_at': item.unloadingStartedAt,
        'unloading_ended_at': item.unloadingEndedAt,
        'volume_m3': item.volumeM3,
        'measured_slump': item.measuredSlump,
        'concrete_temperature': item.concreteTemperature,
        'result': item.result.storageValue,
        'reason': item.reason,
        'evidence_exception_reason': item.evidenceExceptionReason,
      });

  bool _sampleMatches(ConcreteSampleSet item, Map<String, Object?> values) =>
      _jsonEqual(values, {
        'source_truck_id': item.sourceTruckId,
        'sample_code': item.sampleCode,
        'sample_count': item.sampleCount,
        'sample_labels_json': jsonEncode(item.sampleLabels),
        'sampled_at': item.sampledAt,
        'sampled_by': item.sampledBy,
        'laboratory_appointment_at': item.laboratoryAppointmentAt,
        'delivered_at': item.deliveredAt,
        'delivered_to': item.deliveredTo,
        'expected_result_dates_json': jsonEncode(
          [...item.expectedResultDates]..sort(),
        ),
        'status': item.status.storageValue,
        'note': item.note,
        'reason': item.reason,
      });

  bool _jsonEqual(Object? left, Object? right) =>
      jsonEncode(left) == jsonEncode(right);

  void _validateVolume(double value, String field) {
    if (!value.isFinite || value <= 0) {
      throw AgendaValidationFailure('$field sıfırdan büyük olmalıdır.');
    }
  }

  void _validateExpectedRevision(int value) {
    if (value < 1) {
      throw const AgendaValidationFailure('Beklenen revision geçersizdir.');
    }
  }

  void _requireRevision(int current, int expected) {
    if (current != expected) throw _staleFailure();
  }

  void _requireMutable(ConcretePour pour) {
    if (pour.status == ConcretePourStatus.closed ||
        pour.status == ConcretePourStatus.cancelled) {
      throw const AgendaValidationFailure(
        'Kapalı veya iptal paket önce yeniden açılmalıdır.',
      );
    }
  }

  AgendaValidationFailure _staleFailure() => const AgendaValidationFailure(
    'Beton paketi başka bir işlemle değişti. Ekranı yenileyin.',
  );

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

  Future<void> _safeReconcileNotifications() async {
    try {
      await agenda.reconcileNotifications();
    } on Object {
      // SQLite is authoritative. Bootstrap and the next mutation retry sync.
    }
  }

  Future<T> _withDatabase<T>(
    DateTime operationTime,
    Future<T> Function(Database database) action,
  ) => coordinator.run(() => _withDatabaseUnlocked(operationTime, action));

  Future<T> _withDatabaseUnlocked<T>(
    DateTime operationTime,
    Future<T> Function(Database database) action,
  ) async {
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
  }

  @override
  Future<ConcreteExportResult> exportPackage(
    ExportConcretePackageCommand command, {
    bool share = false,
  }) async {
    validateUuid(command.pourId, 'Beton paketi kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final operationTime = _readClockOnce();
    final rawDetail = await _withDatabase(
      operationTime,
      (database) => _loadDetail(database, command.pourId),
    );
    final detail = await _withAttachmentIntegrity(rawDetail);
    _requireRevision(detail.pour.revision, command.expectedRevision);
    final timestamp = CseTimeCodec.encodeUtc(operationTime);
    final safeCode = detail.pour.pourCode
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final fileName =
        'beton_paketi_${safeCode.isEmpty ? command.pourId : safeCode}_${timestamp.replaceAll(':', '').replaceAll('-', '')}.md';
    final bytes = ConcretePackageReportFormatter.markdownBytes(detail);
    final absolutePath = await exportGateway.stage(fileName, bytes);
    try {
      final now = CseTimeCodec.decodeCanonicalUtc(timestamp);
      await _withDatabase(now, (database) {
        return database.transaction((transaction) async {
          final current = await _requirePour(transaction, command.pourId);
          _requireRevision(current.revision, command.expectedRevision);
          if (!await _isIdempotentEvent(
            transaction,
            command.eventId,
            command.pourId,
          )) {
            await _advancePour(transaction, current, timestamp);
            await _insertConcreteEvent(
              transaction,
              id: command.eventId,
              pourId: command.pourId,
              eventType: 'report.exported',
              occurredAt: timestamp,
              payload: {
                'file_name': fileName,
                'byte_size': bytes.length,
                'attachment_count': detail.attachments.length,
              },
            );
          }
        });
      });
      final result = ConcreteExportResult(
        absolutePath: absolutePath,
        fileName: fileName,
        humanSummary: ConcretePackageReportFormatter.humanSummary(detail),
      );
      if (share) await exportGateway.share(absolutePath, result.humanSummary);
      return result;
    } on Object {
      await exportGateway.cleanup(absolutePath);
      rethrow;
    }
  }

  @override
  Future<ConcretePourDetail> getPourDetail(String pourId) async {
    validateUuid(pourId, 'Beton paketi kimliği');
    final now = _readClockOnce();
    final detail = await _withDatabase(
      now,
      (database) => _loadDetail(database, pourId),
    );
    return _withAttachmentIntegrity(detail);
  }

  Future<ConcretePourDetail> _withAttachmentIntegrity(
    ConcretePourDetail detail,
  ) async {
    final inspected = <ConcreteAttachment>[];
    for (final item in detail.attachments) {
      ConcreteAttachmentIntegrity integrity;
      try {
        integrity = await attachmentStore.inspect(
          item.relativePath,
          item.sha256,
        );
      } on Object {
        integrity = ConcreteAttachmentIntegrity.missing;
      }
      inspected.add(_withIntegrity(item, integrity));
    }
    return ConcretePourDetail(
      pour: detail.pour,
      checks: detail.checks,
      trucks: detail.trucks,
      sampleSets: detail.sampleSets,
      followUps: detail.followUps,
      attachments: List.unmodifiable(inspected),
      events: detail.events,
      linkedReminders: detail.linkedReminders,
      metrics: detail.metrics,
    );
  }

  @override
  Future<ConcretePourDetail> updatePour(
    UpdateConcretePourCommand command,
  ) async {
    _validateUpdate(command);
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    final detail = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final current = await _requirePour(transaction, command.id);
        _requireRevision(current.revision, command.expectedRevision);
        _requireMutable(current);
        if (await _isIdempotentEvent(
          transaction,
          command.eventId,
          command.id,
        )) {
          return _loadDetail(transaction, command.id);
        }
        final values = _normalizedUpdate(command);
        final currentValues = <String, Object?>{
          'element_location': current.elementLocation,
          'block_name': current.blockName,
          'floor_name': current.floorName,
          'axis_name': current.axisName,
          'planned_at': current.plannedAt,
          'concrete_class': current.concreteClass,
          'target_slump': current.targetSlump,
          'planned_volume_m3': current.plannedVolumeM3,
          'ordered_volume_m3': current.orderedVolumeM3,
          'plant_name': current.plantName,
          'plant_branch': current.plantBranch,
          'plant_contact': current.plantContact,
          'plant_appointment_reference': current.plantAppointmentReference,
          'pump_equipment': current.pumpEquipment,
          'laboratory_name': current.laboratoryName,
          'laboratory_contact': current.laboratoryContact,
          'laboratory_appointment': current.laboratoryAppointment,
          'inspection_notified_at': current.inspectionNotifiedAt,
          'inspection_notified_person': current.inspectionNotifiedPerson,
          'general_note': current.generalNote,
          'sample_exception_reason': current.sampleExceptionReason,
          'variance_note': current.varianceNote,
        };
        if (_jsonEqual(currentValues, values)) {
          return _loadDetail(transaction, command.id);
        }
        await _advancePour(transaction, current, timestamp, values);
        await _insertConcreteEvent(
          transaction,
          id: command.eventId,
          pourId: command.id,
          eventType: 'pour.details_updated',
          occurredAt: timestamp,
          payload: values,
        );
        await _syncFieldReminderTasks(
          transaction,
          pourId: current.id,
          projectId: current.projectId,
          laboratoryComplete:
              ((values['laboratory_appointment'] as String?)?.isNotEmpty ??
              false),
          inspectionComplete:
              values['inspection_notified_at'] != null ||
              ((values['inspection_notified_person'] as String?)?.isNotEmpty ??
                  false),
          occurredAt: timestamp,
        );
        return _loadDetail(transaction, command.id);
      });
    });
    await _safeReconcileNotifications();
    return detail;
  }

  Future<String> _nextSampleCode(
    DatabaseExecutor database,
    String pourId,
  ) async {
    final countRows = await database.rawQuery(
      'SELECT count(*) AS value FROM concrete_sample_sets '
      'WHERE concrete_pour_id = ?',
      [pourId],
    );
    var sequence = (countRows.single['value']! as int) + 1;
    while (true) {
      final candidate = 'Numune seti $sequence';
      final existing = await database.query(
        'concrete_sample_sets',
        columns: ['id'],
        where: 'concrete_pour_id = ? AND sample_code = ?',
        whereArgs: [pourId, candidate],
        limit: 1,
      );
      if (existing.isEmpty) return candidate;
      sequence += 1;
    }
  }

  @override
  Future<ConcretePourDetail> updateCheck(
    UpdateConcreteCheckCommand command,
  ) async {
    validateUuid(command.pourId, 'Beton paketi kimliği');
    validateUuid(command.checkId, 'Kontrol kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedPourRevision);
    _validateExpectedRevision(command.expectedCheckRevision);
    final note = optionalTrimmed(command.note, 'Kontrol notu', maxLength: 1000);
    final reason = optionalTrimmed(
      command.reason,
      'Kontrol nedeni',
      maxLength: 1000,
    );
    if ((command.status == ConcreteCheckStatus.notApplicable ||
            command.status == ConcreteCheckStatus.exception) &&
        reason == null) {
      throw const AgendaValidationFailure(
        'Uygulanamaz veya istisna kontrolünde neden zorunludur.',
      );
    }
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    return _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final pour = await _requirePour(transaction, command.pourId);
        _requireRevision(pour.revision, command.expectedPourRevision);
        _requireMutable(pour);
        final rows = await transaction.query(
          'concrete_check_items',
          where: 'id = ? AND concrete_pour_id = ?',
          whereArgs: [command.checkId, command.pourId],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw const AgendaValidationFailure('Kontrol kalemi bulunamadı.');
        }
        final check = _checkFromRow(rows.single);
        if (check.revision != command.expectedCheckRevision) {
          throw _staleFailure();
        }
        if (await _isIdempotentEvent(
          transaction,
          command.eventId,
          command.pourId,
        )) {
          return _loadDetail(transaction, command.pourId);
        }
        if (check.status == command.status &&
            check.note == note &&
            check.reason == reason) {
          return _loadDetail(transaction, command.pourId);
        }
        final changed = await transaction.update(
          'concrete_check_items',
          {
            'status': command.status.storageValue,
            'note': note,
            'reason': reason,
            'revision': check.revision + 1,
            'updated_at': timestamp,
          },
          where: 'id = ? AND revision = ?',
          whereArgs: [check.id, check.revision],
        );
        if (changed != 1) throw _staleFailure();
        await _advancePour(transaction, pour, timestamp);
        await _insertConcreteEvent(
          transaction,
          id: command.eventId,
          pourId: command.pourId,
          eventType: 'check.updated',
          occurredAt: timestamp,
          payload: {
            'check_id': check.id,
            'item_key': check.itemKey,
            'status': command.status.storageValue,
            'reason': reason,
          },
        );
        return _loadDetail(transaction, command.pourId);
      });
    });
  }

  @override
  Future<ConcretePourDetail> transitionPour(
    TransitionConcretePourCommand command,
  ) async {
    validateUuid(command.pourId, 'Beton paketi kimliği');
    validateUuid(command.eventId, 'Event kimliği');
    _validateExpectedRevision(command.expectedRevision);
    final reason = optionalTrimmed(
      command.reason,
      'Geçiş nedeni',
      maxLength: 1000,
    );
    final now = _readClockOnce();
    final timestamp = CseTimeCodec.encodeUtc(now);
    final detail = await _withDatabase(now, (database) {
      return database.transaction((transaction) async {
        final pour = await _requirePour(transaction, command.pourId);
        _requireRevision(pour.revision, command.expectedRevision);
        if (await _isIdempotentEvent(
          transaction,
          command.eventId,
          command.pourId,
        )) {
          return _loadDetail(transaction, command.pourId);
        }
        if (pour.status == command.targetStatus) {
          return _loadDetail(transaction, command.pourId);
        }
        await _validateTransition(
          transaction,
          pour,
          command.targetStatus,
          reason,
        );
        final values = <String, Object?>{
          'status': command.targetStatus.storageValue,
        };
        late final String eventType;
        switch (command.targetStatus) {
          case ConcretePourStatus.prepared:
            eventType = 'pour.prepared';
          case ConcretePourStatus.pouring:
            eventType = 'pour.started';
            values['actual_started_at'] = pour.actualStartedAt ?? timestamp;
          case ConcretePourStatus.poured:
            eventType = 'pour.finished';
            values['actual_ended_at'] = pour.actualEndedAt ?? timestamp;
          case ConcretePourStatus.followUp:
            eventType = 'pour.follow_up_started';
          case ConcretePourStatus.closed:
            eventType = 'pour.closed';
            values['closed_at'] = timestamp;
            values['cancelled_at'] = null;
          case ConcretePourStatus.cancelled:
            eventType = 'pour.cancelled';
            values['cancelled_at'] = timestamp;
            values['closed_at'] = null;
          case ConcretePourStatus.draft:
            eventType = 'pour.reopened';
            values['closed_at'] = null;
            values['cancelled_at'] = null;
        }
        await _advancePour(transaction, pour, timestamp, values);
        await _insertConcreteEvent(
          transaction,
          id: command.eventId,
          pourId: command.pourId,
          eventType: eventType,
          occurredAt: timestamp,
          payload: {
            'from_status': pour.status.storageValue,
            'to_status': command.targetStatus.storageValue,
            'reason': reason,
          },
        );
        if (command.targetStatus == ConcretePourStatus.closed ||
            command.targetStatus == ConcretePourStatus.cancelled) {
          await _completeAllLinkedReminders(
            transaction,
            pourId: pour.id,
            projectId: pour.projectId,
            occurredAt: timestamp,
            outcomeNote: reason,
          );
        } else if (command.targetStatus == ConcretePourStatus.draft) {
          await _reopenPendingLinkedReminders(
            transaction,
            pourId: pour.id,
            projectId: pour.projectId,
            occurredAt: timestamp,
          );
        }
        return _loadDetail(transaction, command.pourId);
      });
    });
    await _safeReconcileNotifications();
    return detail;
  }
}
