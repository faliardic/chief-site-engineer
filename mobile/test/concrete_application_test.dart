import 'dart:io';
import 'dart:typed_data';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/platform/concrete_attachment_gateway.dart';
import 'package:chief_site_engineer/platform/concrete_export_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const pourId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const createEventId = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';

void main() {
  late Directory root;
  late AppDirectories directories;
  late SqliteAgendaApplication agenda;
  late SqliteConcreteApplication concrete;
  late _MemoryAttachmentStore attachments;
  late _MemoryExportGateway exports;
  var now = DateTime.utc(2026, 7, 19, 7);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cse_concrete_');
    directories = AppDirectories.fromSupportRoot(root, AppEnvironment.debug);
    await directories.ensureCreated();
    final database = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => now,
    );
    await database.open();
    await database.close();
    agenda = SqliteAgendaApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
    );
    await agenda.createProject(
      const CreateProjectCommand(id: projectId, name: 'Şantiye A'),
    );
    attachments = _MemoryAttachmentStore();
    exports = _MemoryExportGateway();
    concrete = _application(
      agenda: agenda,
      attachments: attachments,
      exports: exports,
      directories: directories,
      clock: () => now,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'create is idempotent and links checks follow-ups reminders and events',
    () async {
      final created = await concrete.createPour(_createCommand());
      expect(created.pour.revision, 1);
      expect(created.checks, hasLength(11));
      expect(
        created.checks.map((item) => item.itemKey),
        containsAll([
          'plant_appointment',
          'location_ready',
          'planned_volume_verified',
          'formwork_ready',
          'reinforcement_ready',
          'embedded_items_ready',
          'inspection_notified',
          'laboratory_appointment',
          'pump_equipment_ready',
          'access_route_ready',
          'safety_ready',
        ]),
      );
      expect(created.followUps, hasLength(8));
      expect(created.linkedReminders, hasLength(8));
      expect(
        created.linkedReminders.every(
          (item) =>
              item.concretePourId == pourId &&
              item.projectId == projectId &&
              item.sourceLogId == null &&
              item.attendanceDayId == null,
        ),
        isTrue,
      );
      expect(created.events.first.eventType, 'pour.created');
      expect(
        created.events
            .skip(1)
            .every((item) => item.eventType == 'follow_up.linked'),
        isTrue,
      );

      final retried = await concrete.createPour(_createCommand());
      expect(retried.events, hasLength(created.events.length));
      expect(await _count(directories.databaseFile, 'concrete_pours'), 1);
      expect(await _count(directories.databaseFile, 'follow_up_items'), 8);
      expect(
        await _count(
          directories.databaseFile,
          'reminder_notification_bindings',
        ),
        8,
      );
    },
  );

  test(
    'field tasks repeat hourly and completion or clearing closes and reopens',
    () async {
      var detail = await concrete.createPour(_createCommand());
      var fieldTasks = detail.followUps
          .where(
            (item) =>
                item.itemKey == 'inspection_notification_task' ||
                item.itemKey == 'laboratory_appointment_task',
          )
          .toList(growable: false);
      expect(
        fieldTasks.map((item) => item.label),
        containsAll([
          'Laboratuvar randevusunu al/doğrula',
          'Yapı denetime haber ver',
        ]),
      );
      expect(
        fieldTasks.every((item) => item.dueAt == '2026-07-19T08:00:00Z'),
        isTrue,
      );
      final database = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      var bindings = await database.rawQuery(
        '''
        SELECT b.repeat_interval_minutes
        FROM reminder_notification_bindings b
        JOIN concrete_follow_up_items c ON c.reminder_id = b.reminder_id
        WHERE c.concrete_pour_id = ?
          AND c.item_key IN (
            'inspection_notification_task', 'laboratory_appointment_task'
          )
        ORDER BY c.item_key ASC
      ''',
        [pourId],
      );
      expect(bindings.map((row) => row['repeat_interval_minutes']), [60, 60]);
      await database.close();

      detail = await concrete.updatePour(
        _updatePourCommand(
          detail,
          eventId: _uuid(170),
          laboratoryAppointment: '2026-07-19T08:00:00Z',
          inspectionNotifiedAt: '2026-07-19T07:30:00Z',
        ),
      );
      fieldTasks = detail.followUps
          .where((item) => item.itemKey.endsWith('_task'))
          .toList(growable: false);
      expect(
        fieldTasks.every(
          (item) =>
              item.status == ConcreteFollowUpStatus.completed &&
              item.dueAt == null,
        ),
        isTrue,
      );
      expect(
        detail.linkedReminders
            .where(
              (item) => fieldTasks.any((task) => task.reminderId == item.id),
            )
            .every((item) => item.status == ReminderStatus.completed),
        isTrue,
      );

      now = DateTime.utc(2026, 7, 19, 7, 10);
      detail = await concrete.updatePour(
        _updatePourCommand(detail, eventId: _uuid(171)),
      );
      fieldTasks = detail.followUps
          .where((item) => item.itemKey.endsWith('_task'))
          .toList(growable: false);
      expect(
        fieldTasks.every(
          (item) =>
              item.status == ConcreteFollowUpStatus.pending &&
              item.dueAt == '2026-07-19T08:10:00Z',
        ),
        isTrue,
      );
      final reopenedDatabase = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      bindings = await reopenedDatabase.rawQuery(
        '''
        SELECT b.repeat_interval_minutes
        FROM reminder_notification_bindings b
        JOIN concrete_follow_up_items c ON c.reminder_id = b.reminder_id
        WHERE c.concrete_pour_id = ? AND c.item_key LIKE '%_task'
      ''',
        [pourId],
      );
      await reopenedDatabase.close();
      expect(bindings.map((row) => row['repeat_interval_minutes']), [60, 60]);
      expect(await _count(directories.databaseFile, 'follow_up_items'), 8);
    },
  );

  test(
    'sample sets need no manual code and keep generated identity on update',
    () async {
      var detail = await concrete.createPour(_createCommand());
      detail = await concrete.saveSampleSet(
        SaveConcreteSampleSetCommand(
          id: _uuid(180),
          pourId: pourId,
          eventId: _uuid(181),
          expectedPourRevision: detail.pour.revision,
          expectedSampleRevision: 0,
          sampleCount: 1,
          sampleLabels: const ['Küp 1'],
          sampledAt: '2026-07-19T07:00:00Z',
          expectedResultDates: const [],
          status: ConcreteSampleStatus.sampled,
        ),
      );
      expect(detail.sampleSets.single.sampleCode, 'Numune seti 1');
      final first = detail.sampleSets.single;
      detail = await concrete.saveSampleSet(
        SaveConcreteSampleSetCommand(
          id: first.id,
          pourId: pourId,
          eventId: _uuid(182),
          expectedPourRevision: detail.pour.revision,
          expectedSampleRevision: first.revision,
          sampleCount: 1,
          sampleLabels: const ['Küp 1'],
          sampledAt: '2026-07-19T07:00:00Z',
          expectedResultDates: const [],
          status: ConcreteSampleStatus.sampled,
          note: 'Kod görünmeden güncellendi',
        ),
      );
      expect(detail.sampleSets.single.sampleCode, 'Numune seti 1');
      detail = await concrete.saveSampleSet(
        SaveConcreteSampleSetCommand(
          id: _uuid(183),
          pourId: pourId,
          eventId: _uuid(184),
          expectedPourRevision: detail.pour.revision,
          expectedSampleRevision: 0,
          sampleCount: 1,
          sampleLabels: const ['Küp 2'],
          sampledAt: '2026-07-19T07:05:00Z',
          expectedResultDates: const [],
          status: ConcreteSampleStatus.sampled,
        ),
      );
      expect(detail.sampleSets.map((item) => item.sampleCode), [
        'Numune seti 1',
        'Numune seti 2',
      ]);
      final restarted = _application(
        agenda: agenda,
        attachments: attachments,
        exports: exports,
        directories: directories,
        clock: () => now,
      );
      expect(
        (await restarted.getPourDetail(
          pourId,
        )).sampleSets.map((item) => item.sampleCode),
        ['Numune seti 1', 'Numune seti 2'],
      );
    },
  );

  test(
    'list grouping literal filters deterministic order and restart persistence',
    () async {
      await concrete.createPour(_createCommand());
      final values = await concrete.listPours(
        const ConcretePourQuery(
          group: ConcretePourGroup.today,
          projectId: projectId,
          istanbulDay: '2026-07-19',
          literalSearch: 'KOLON',
        ),
      );
      expect(values.single.id, pourId);
      expect(values.single.pendingCheckCount, 11);
      expect(values.single.openFollowUpCount, 8);
      expect(values.single.missingEvidenceTruckCount, 0);
      expect(
        (await concrete.listPours(
          const ConcretePourQuery(
            group: ConcretePourGroup.today,
            projectId: projectId,
            istanbulDay: '2026-07-19',
            literalSearch: 'kolon',
          ),
        )),
        isEmpty,
        reason: 'Arama literal ve büyük/küçük harf duyarlıdır.',
      );

      now = DateTime.utc(2026, 7, 19, 8);
      final restarted = _application(
        agenda: agenda,
        attachments: attachments,
        exports: exports,
        directories: directories,
        clock: () => now,
      );
      final detail = await restarted.getPourDetail(pourId);
      expect(detail.pour.pourCode, 'BT-001');
      expect(detail.checks, hasLength(11));
      expect(detail.linkedReminders.first.concretePourId, pourId);
    },
  );

  test(
    'validation and event failure leave no partial package or reminder',
    () async {
      await expectLater(
        concrete.createPour(_createCommand(plannedVolume: 0)),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect(await _count(directories.databaseFile, 'concrete_pours'), 0);

      final failing = _application(
        agenda: agenda,
        attachments: attachments,
        exports: exports,
        directories: directories,
        clock: () => now,
        beforeEvent: (_) async => throw StateError('intentional event failure'),
      );
      await expectLater(failing.createPour(_createCommand()), throwsStateError);
      expect(await _count(directories.databaseFile, 'concrete_pours'), 0);
      expect(await _count(directories.databaseFile, 'follow_up_items'), 0);
      expect(await _count(directories.databaseFile, 'concrete_pour_events'), 0);
    },
  );

  test(
    'database guards append-only history physical delete and source invariant',
    () async {
      final detail = await concrete.createPour(_createCommand());
      final database = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(
          singleInstance: false,
          onConfigure: (value) => value.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      await expectLater(
        database.update(
          'concrete_pour_events',
          {'payload_json': '{"changed":true}'},
          where: 'id = ?',
          whereArgs: [detail.events.first.id],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        database.delete('concrete_pours', where: 'id = ?', whereArgs: [pourId]),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        database.update(
          'follow_up_items',
          {'observation_id': _uuid(98)},
          where: 'concrete_pour_id = ?',
          whereArgs: [pourId],
        ),
        throwsA(isA<DatabaseException>()),
      );
      await database.close();
    },
  );

  test(
    'checklist optimistic revisions and prepared transition fail closed',
    () async {
      var detail = await concrete.createPour(_createCommand());
      await expectLater(
        concrete.transitionPour(
          TransitionConcretePourCommand(
            pourId: pourId,
            eventId: _uuid(10),
            expectedRevision: detail.pour.revision,
            targetStatus: ConcretePourStatus.prepared,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      for (var index = 0; index < detail.checks.length; index += 1) {
        final item = detail.checks[index];
        detail = await concrete.updateCheck(
          UpdateConcreteCheckCommand(
            pourId: pourId,
            checkId: item.id,
            eventId: _uuid(20 + index),
            expectedPourRevision: detail.pour.revision,
            expectedCheckRevision: item.revision,
            status: index == 0
                ? ConcreteCheckStatus.exception
                : ConcreteCheckStatus.completed,
            reason: index == 0 ? 'Sözleşme kapsamı dışında' : null,
          ),
        );
      }
      final prepared = await concrete.transitionPour(
        TransitionConcretePourCommand(
          pourId: pourId,
          eventId: _uuid(40),
          expectedRevision: detail.pour.revision,
          targetStatus: ConcretePourStatus.prepared,
        ),
      );
      expect(prepared.pour.status, ConcretePourStatus.prepared);
      await expectLater(
        concrete.updateCheck(
          UpdateConcreteCheckCommand(
            pourId: pourId,
            checkId: detail.checks.first.id,
            eventId: _uuid(41),
            expectedPourRevision: 1,
            expectedCheckRevision: 1,
            status: ConcreteCheckStatus.completed,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
    },
  );

  test(
    'truck sample attachment metrics exact links and source safety work',
    () async {
      var detail = await concrete.createPour(_createCommand());
      detail = await concrete.saveTruck(
        SaveConcreteTruckCommand(
          id: _uuid(50),
          pourId: pourId,
          eventId: _uuid(51),
          expectedPourRevision: detail.pour.revision,
          expectedTruckRevision: 0,
          sequenceNo: 1,
          vehiclePlate: '34 abc 123',
          deliveryNoteNumber: '=RISK',
          volumeM3: 12.5,
          result: ConcreteTruckResult.received,
          arrivedAt: '2026-07-19T08:00:00Z',
        ),
      );
      final truck = detail.trucks.single;
      expect(truck.vehiclePlate, '34 ABC 123');
      expect(detail.metrics.actualDeliveredM3, 12.5);

      detail = await concrete.attachEvidence(
        AttachConcreteEvidenceCommand(
          id: _uuid(52),
          pourId: pourId,
          eventId: _uuid(53),
          expectedPourRevision: detail.pour.revision,
          evidenceType: ConcreteEvidenceType.deliveryReceiptScan,
          originalFileName: 'receipt.jpg',
          bytes: const [0xff, 0xd8, 0xff, 1],
          capturedAt: '2026-07-19T08:01:00Z',
          truckId: truck.id,
        ),
      );
      detail = await concrete.attachEvidence(
        AttachConcreteEvidenceCommand(
          id: _uuid(54),
          pourId: pourId,
          eventId: _uuid(55),
          expectedPourRevision: detail.pour.revision,
          evidenceType: ConcreteEvidenceType.mixerPhoto,
          originalFileName: 'mixer.jpg',
          bytes: const [0xff, 0xd8, 0xff, 2],
          capturedAt: '2026-07-19T08:02:00Z',
          truckId: truck.id,
        ),
      );
      expect(detail.metrics.missingEvidenceTruckCount, 0);
      expect(
        detail.attachments.every((item) => item.truckId == truck.id),
        isTrue,
      );

      detail = await concrete.saveSampleSet(
        SaveConcreteSampleSetCommand(
          id: _uuid(56),
          pourId: pourId,
          eventId: _uuid(57),
          expectedPourRevision: detail.pour.revision,
          expectedSampleRevision: 0,
          sourceTruckId: truck.id,
          sampleCode: 'N-01',
          sampleCount: 2,
          sampleLabels: const ['N-01-A', 'N-01-B'],
          sampledAt: '2026-07-19T08:03:00Z',
          sampledBy: 'Fatih',
          expectedResultDates: const ['2026-07-26T06:00:00Z'],
          status: ConcreteSampleStatus.sampled,
        ),
      );
      expect(detail.sampleSets.single.sourceTruckId, truck.id);
      expect(
        detail.followUps.where((item) => item.sourceSampleSetId == _uuid(56)),
        hasLength(2),
      );
      expect(
        detail.linkedReminders.where((item) => item.concretePourId == pourId),
        hasLength(10),
      );

      await expectLater(
        concrete.attachEvidence(
          AttachConcreteEvidenceCommand(
            id: _uuid(58),
            pourId: pourId,
            eventId: _uuid(59),
            expectedPourRevision: detail.pour.revision,
            evidenceType: ConcreteEvidenceType.mixerPhoto,
            originalFileName: 'wrong.jpg',
            bytes: const [0xff, 0xd8, 0xff, 3],
            capturedAt: '2026-07-19T08:04:00Z',
            truckId: _uuid(99),
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect(
        attachments.values,
        hasLength(2),
        reason: 'Kaynak validation staging öncesidir.',
      );
    },
  );

  test(
    'attachment duplicate and database failure cleanup staged files',
    () async {
      var detail = await concrete.createPour(_createCommand());
      final first = AttachConcreteEvidenceCommand(
        id: _uuid(60),
        pourId: pourId,
        eventId: _uuid(61),
        expectedPourRevision: detail.pour.revision,
        evidenceType: ConcreteEvidenceType.sitePhoto,
        originalFileName: 'site.jpg',
        bytes: const [0xff, 0xd8, 0xff, 7],
        capturedAt: '2026-07-19T08:00:00Z',
      );
      detail = await concrete.attachEvidence(first);
      await expectLater(
        concrete.attachEvidence(
          AttachConcreteEvidenceCommand(
            id: _uuid(62),
            pourId: pourId,
            eventId: _uuid(63),
            expectedPourRevision: detail.pour.revision,
            evidenceType: ConcreteEvidenceType.sitePhoto,
            originalFileName: 'same.jpg',
            bytes: first.bytes,
            capturedAt: '2026-07-19T08:01:00Z',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect(attachments.values, hasLength(1));

      final failing = _application(
        agenda: agenda,
        attachments: attachments,
        exports: exports,
        directories: directories,
        clock: () => now,
        beforeEvent: (_) async => throw StateError('event fail'),
      );
      await expectLater(
        failing.attachEvidence(
          AttachConcreteEvidenceCommand(
            id: _uuid(64),
            pourId: pourId,
            eventId: _uuid(65),
            expectedPourRevision: detail.pour.revision,
            evidenceType: ConcreteEvidenceType.sitePhoto,
            originalFileName: 'new.jpg',
            bytes: const [0xff, 0xd8, 0xff, 8],
            capturedAt: '2026-07-19T08:02:00Z',
          ),
        ),
        throwsStateError,
      );
      expect(attachments.values, hasLength(1));
      expect((await concrete.getPourDetail(pourId)).attachments, hasLength(1));
    },
  );

  test(
    'source reminder mutation does not mutate concrete and follow-up closes reminder',
    () async {
      var detail = await concrete.createPour(_createCommand());
      final follow = detail.followUps.first;
      final reminder = detail.linkedReminders.firstWhere(
        (item) => item.id == follow.reminderId,
      );
      final revision = detail.pour.revision;
      await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: _uuid(70),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.updateDetails,
          title: 'Kullanıcı tarafından düzenlenen başlık',
        ),
      );
      detail = await concrete.getPourDetail(pourId);
      expect(detail.pour.revision, revision);

      detail = await concrete.updateFollowUp(
        UpdateConcreteFollowUpCommand(
          pourId: pourId,
          followUpId: follow.id,
          eventId: _uuid(71),
          reminderEventId: _uuid(72),
          expectedPourRevision: detail.pour.revision,
          expectedFollowUpRevision: follow.revision,
          status: ConcreteFollowUpStatus.completed,
          dueAt: follow.dueAt,
        ),
      );
      final linked = detail.linkedReminders.firstWhere(
        (item) => item.id == reminder.id,
      );
      expect(linked.status, ReminderStatus.completed);
      expect(linked.concretePourId, pourId);
      expect(
        (await agenda.getReminderLifecycleDetail(
          reminder.id,
        )).events.last.sourceConcretePourId,
        pourId,
      );
    },
  );

  test(
    'full pour follow-up close and reasoned reopen is append-only',
    () async {
      var detail = await concrete.createPour(_createCommand());
      for (var index = 0; index < detail.checks.length; index += 1) {
        final check = detail.checks[index];
        detail = await concrete.updateCheck(
          UpdateConcreteCheckCommand(
            pourId: pourId,
            checkId: check.id,
            eventId: _uuid(100 + index),
            expectedPourRevision: detail.pour.revision,
            expectedCheckRevision: check.revision,
            status: ConcreteCheckStatus.completed,
          ),
        );
      }
      detail = await concrete.transitionPour(
        TransitionConcretePourCommand(
          pourId: pourId,
          eventId: _uuid(120),
          expectedRevision: detail.pour.revision,
          targetStatus: ConcretePourStatus.prepared,
        ),
      );
      detail = await concrete.transitionPour(
        TransitionConcretePourCommand(
          pourId: pourId,
          eventId: _uuid(121),
          expectedRevision: detail.pour.revision,
          targetStatus: ConcretePourStatus.pouring,
        ),
      );
      detail = await concrete.saveTruck(
        SaveConcreteTruckCommand(
          id: _uuid(122),
          pourId: pourId,
          eventId: _uuid(123),
          expectedPourRevision: detail.pour.revision,
          expectedTruckRevision: 0,
          sequenceNo: 1,
          vehiclePlate: '34 CSE 187',
          deliveryNoteNumber: 'IRS-187',
          volumeM3: 20,
          result: ConcreteTruckResult.received,
          evidenceExceptionReason: 'Kamera arızası kayıt altına alındı.',
        ),
      );
      detail = await concrete.transitionPour(
        TransitionConcretePourCommand(
          pourId: pourId,
          eventId: _uuid(124),
          expectedRevision: detail.pour.revision,
          targetStatus: ConcretePourStatus.poured,
        ),
      );
      detail = await concrete.updatePour(
        UpdateConcretePourCommand(
          id: pourId,
          eventId: _uuid(125),
          expectedRevision: detail.pour.revision,
          elementLocation: detail.pour.elementLocation,
          plannedAt: detail.pour.plannedAt,
          concreteClass: detail.pour.concreteClass,
          plannedVolumeM3: detail.pour.plannedVolumeM3,
          plantName: detail.pour.plantName,
          laboratoryName: detail.pour.laboratoryName,
          sampleExceptionReason: 'Bu özel dökümde numune uygulanmadı.',
        ),
      );
      detail = await concrete.transitionPour(
        TransitionConcretePourCommand(
          pourId: pourId,
          eventId: _uuid(126),
          expectedRevision: detail.pour.revision,
          targetStatus: ConcretePourStatus.followUp,
        ),
      );
      for (var index = 0; index < detail.followUps.length; index += 1) {
        final follow = detail.followUps[index];
        detail = await concrete.updateFollowUp(
          UpdateConcreteFollowUpCommand(
            pourId: pourId,
            followUpId: follow.id,
            eventId: _uuid(130 + index * 2),
            reminderEventId: _uuid(131 + index * 2),
            expectedPourRevision: detail.pour.revision,
            expectedFollowUpRevision: follow.revision,
            status: ConcreteFollowUpStatus.completed,
            dueAt: follow.dueAt,
          ),
        );
      }
      final closed = await concrete.transitionPour(
        TransitionConcretePourCommand(
          pourId: pourId,
          eventId: _uuid(160),
          expectedRevision: detail.pour.revision,
          targetStatus: ConcretePourStatus.closed,
        ),
      );
      expect(closed.pour.status, ConcretePourStatus.closed);
      expect(closed.pour.closedAt, isNotNull);
      expect(
        closed.linkedReminders.every(
          (item) => item.status == ReminderStatus.completed,
        ),
        isTrue,
      );
      expect(
        closed.events.map((item) => item.sequence),
        orderedEquals(
          List.generate(closed.events.length, (index) => index + 1),
        ),
      );

      final reopened = await concrete.transitionPour(
        TransitionConcretePourCommand(
          pourId: pourId,
          eventId: _uuid(161),
          expectedRevision: closed.pour.revision,
          targetStatus: ConcretePourStatus.draft,
          reason: 'Kontrollü geçmiş kayıt düzeltmesi.',
        ),
      );
      expect(reopened.pour.status, ConcretePourStatus.draft);
      expect(reopened.pour.closedAt, isNull);
      expect(reopened.events.last.eventType, 'pour.reopened');
    },
  );

  test(
    'UTF-8 deterministic export is formula safe and event is post-success',
    () async {
      var detail = await concrete.createPour(_createCommand(code: '=BT-001'));
      detail = await concrete.saveTruck(
        SaveConcreteTruckCommand(
          id: _uuid(80),
          pourId: pourId,
          eventId: _uuid(81),
          expectedPourRevision: detail.pour.revision,
          expectedTruckRevision: 0,
          sequenceNo: 1,
          vehiclePlate: '+34',
          deliveryNoteNumber: '=CMD',
          volumeM3: 20,
          result: ConcreteTruckResult.received,
        ),
      );
      final result = await concrete.exportPackage(
        ExportConcretePackageCommand(
          pourId: pourId,
          eventId: _uuid(82),
          expectedRevision: detail.pour.revision,
        ),
      );
      expect(result.fileName, startsWith('beton_paketi_BT-001_'));
      expect(exports.bytes!.take(3), [0xef, 0xbb, 0xbf]);
      final refreshed = await concrete.getPourDetail(pourId);
      expect(refreshed.events.last.eventType, 'report.exported');
      expect(
        ConcretePackageReportFormatter.truckCsv(refreshed),
        contains("'=CMD"),
      );

      exports.failStage = true;
      await expectLater(
        concrete.exportPackage(
          ExportConcretePackageCommand(
            pourId: pourId,
            eventId: _uuid(83),
            expectedRevision: refreshed.pour.revision,
          ),
        ),
        throwsStateError,
      );
      expect(
        (await concrete.getPourDetail(
          pourId,
        )).events.where((item) => item.id == _uuid(83)),
        isEmpty,
      );
    },
  );
}

SqliteConcreteApplication _application({
  required AgendaApplication agenda,
  required _MemoryAttachmentStore attachments,
  required _MemoryExportGateway exports,
  required AppDirectories directories,
  required DateTime Function() clock,
  ConcreteTransactionHook? beforeEvent,
}) => SqliteConcreteApplication(
  databasePath: directories.databaseFile,
  databaseFactory: databaseFactoryFfi,
  clock: clock,
  agenda: agenda,
  attachmentStore: attachments,
  exportGateway: exports,
  beforeConcreteEventInsert: beforeEvent,
);

UpdateConcretePourCommand _updatePourCommand(
  ConcretePourDetail detail, {
  required String eventId,
  String? laboratoryAppointment,
  String? inspectionNotifiedAt,
}) => UpdateConcretePourCommand(
  id: detail.pour.id,
  eventId: eventId,
  expectedRevision: detail.pour.revision,
  elementLocation: detail.pour.elementLocation,
  plannedAt: detail.pour.plannedAt,
  concreteClass: detail.pour.concreteClass,
  plannedVolumeM3: detail.pour.plannedVolumeM3,
  plantName: detail.pour.plantName,
  laboratoryName: detail.pour.laboratoryName,
  laboratoryAppointment: laboratoryAppointment,
  inspectionNotifiedAt: inspectionNotifiedAt,
);

CreateConcretePourCommand _createCommand({
  double plannedVolume = 20,
  String code = 'BT-001',
}) => CreateConcretePourCommand(
  id: pourId,
  eventId: createEventId,
  projectId: projectId,
  pourCode: code,
  elementLocation: 'KOLON A1',
  plannedAt: '2026-07-19T09:00:00Z',
  concreteClass: 'C30/37',
  plannedVolumeM3: plannedVolume,
  plantName: 'Güven Beton',
  laboratoryName: 'Saha Lab',
);

String _uuid(int value) {
  final suffix = value.toString().padLeft(12, '0');
  return 'dddddddd-dddd-4ddd-8ddd-$suffix';
}

Future<int> _count(String databasePath, String table) async {
  final database = await databaseFactoryFfi.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  final value = Sqflite.firstIntValue(
    await database.rawQuery('SELECT count(*) FROM $table'),
  )!;
  await database.close();
  return value;
}

class _MemoryAttachmentStore implements ConcreteAttachmentStore {
  final values = <String, List<int>>{};

  @override
  Future<void> cleanup(String relativePath) async =>
      values.remove(relativePath);

  @override
  Future<ConcreteAttachmentIntegrity> inspect(
    String relativePath,
    String expectedSha256,
  ) async {
    final bytes = values[relativePath];
    if (bytes == null) return ConcreteAttachmentIntegrity.missing;
    return sha256.convert(bytes).toString() == expectedSha256
        ? ConcreteAttachmentIntegrity.ok
        : ConcreteAttachmentIntegrity.tampered;
  }

  @override
  Future<StagedConcreteAttachment> stage({
    required String pourId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) async {
    final relative = 'concrete/$pourId/$attachmentId.jpg';
    values[relative] = List.of(bytes);
    return StagedConcreteAttachment(
      relativePath: relative,
      mimeType: 'image/jpeg',
      byteSize: bytes.length,
      sha256Value: sha256.convert(bytes).toString(),
    );
  }
}

class _MemoryExportGateway implements ConcreteExportGateway {
  Uint8List? bytes;
  bool failStage = false;
  bool cleaned = false;
  bool shared = false;

  @override
  Future<void> cleanup(String absolutePath) async => cleaned = true;

  @override
  Future<void> share(String absolutePath, String summary) async =>
      shared = true;

  @override
  Future<String> stage(String fileName, Uint8List bytes) async {
    if (failStage) throw StateError('stage failed');
    this.bytes = bytes;
    return 'V:/safe/$fileName';
  }
}
