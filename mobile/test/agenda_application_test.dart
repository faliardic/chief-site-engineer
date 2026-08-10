import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/platform/agenda_attachment_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const project1 = '11111111-1111-4111-8111-111111111111';
const project2 = '22222222-2222-4222-8222-222222222222';
const log1 = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const log2 = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const log3 = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3';
const log4 = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4';
const reminder1 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const reminder2 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2';
const reminder3 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3';
const reminder4 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4';
const reminder5 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb5';
const reminder6 = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb6';

String eventId(int value) =>
    'eeeeeeee-eeee-4eee-8eee-${value.toString().padLeft(12, '0')}';

void main() {
  late Directory temporaryRoot;
  late AppDirectories directories;
  late DateTime now;
  late SqliteAgendaApplication agenda;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_agenda_');
    directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    await directories.ensureCreated();
    now = DateTime.utc(2026, 7, 20, 8);
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
      attachmentStore: DeviceAgendaAttachmentStore(directories: directories),
    );
    await agenda.createProject(
      const CreateProjectCommand(id: project1, name: 'Kuzey Şantiyesi'),
    );
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  Future<AgendaLog> createLog({
    required String id,
    required int event,
    required String observedAt,
    String projectId = project1,
    AgendaCategory category = AgendaCategory.generalNote,
    String description = 'Saha kontrolü yapıldı',
    String? location = 'A Blok 1. Kat',
    String? notes,
  }) {
    return agenda.createAgendaLog(
      CreateAgendaLogCommand(
        id: id,
        eventId: eventId(event),
        projectId: projectId,
        observedAt: observedAt,
        category: category,
        description: description,
        location: location,
        notes: notes,
      ),
    );
  }

  test(
    'Issue 268 baseline: default AgendaQuery returns newest log first',
    () async {
      await createLog(
        id: log1,
        event: 1,
        observedAt: '2026-07-19T06:00:00Z',
        description: 'Erken kayıt',
      );
      await createLog(
        id: log2,
        event: 2,
        observedAt: '2026-07-19T09:00:00Z',
        description: 'Geç kayıt',
      );

      final logs = await agenda.listAgenda(
        const AgendaQuery(istanbulDay: '2026-07-19'),
      );

      expect(logs.map((item) => item.id), [log2, log1]);
    },
  );

  test('Agenda sort contract is typed and exposes exact Turkish labels', () {
    expect(AgendaSortOrder.values, [
      AgendaSortOrder.newestFirst,
      AgendaSortOrder.oldestFirst,
    ]);
    expect(AgendaSortOrder.newestFirst.label, 'En yeni üstte');
    expect(AgendaSortOrder.oldestFirst.label, 'En eski üstte');
    expect(
      const AgendaQuery(istanbulDay: '2026-07-19').sortOrder,
      AgendaSortOrder.newestFirst,
    );
  });

  test(
    'Istanbul day bounds and deterministic tie-break ordering are exact',
    () async {
      now = DateTime.utc(2026, 7, 21, 8);
      await createLog(
        id: log3,
        event: 3,
        observedAt: '2026-07-18T21:00:00Z',
        description: 'Gün başlangıcı',
      );
      await createLog(
        id: log2,
        event: 2,
        observedAt: '2026-07-19T07:30:00Z',
        description: 'Aynı saat ikinci kimlik',
      );
      await createLog(
        id: log1,
        event: 1,
        observedAt: '2026-07-19T07:30:00Z',
        description: 'Aynı saat ilk kimlik',
      );
      await createLog(
        id: log4,
        event: 4,
        observedAt: '2026-07-19T21:00:00Z',
        description: 'Sonraki gün başlangıcı',
      );

      final july19 = await agenda.listAgenda(
        const AgendaQuery(istanbulDay: '2026-07-19'),
      );
      final july20 = await agenda.listAgenda(
        const AgendaQuery(istanbulDay: '2026-07-20'),
      );
      final july19Oldest = await agenda.listAgenda(
        const AgendaQuery(
          istanbulDay: '2026-07-19',
          sortOrder: AgendaSortOrder.oldestFirst,
        ),
      );

      expect(july19.map((item) => item.id), [log2, log1, log3]);
      expect(july19Oldest.map((item) => item.id), [log3, log1, log2]);
      expect(july20.map((item) => item.id), [log4]);
    },
  );

  test(
    'created and id tie-breaks are deterministic and updates do not reorder',
    () async {
      const observedAt = '2026-07-19T07:30:00Z';
      now = DateTime.utc(2026, 7, 20, 8);
      final first = await createLog(
        id: log1,
        event: 1,
        observedAt: observedAt,
        description: 'İlk oluşturulan',
      );
      now = DateTime.utc(2026, 7, 20, 9);
      await createLog(
        id: log2,
        event: 2,
        observedAt: observedAt,
        description: 'Sonra oluşturulan',
      );
      now = DateTime.utc(2026, 7, 20, 10);
      await createLog(
        id: log3,
        event: 3,
        observedAt: observedAt,
        description: 'Aynı created_at küçük id',
      );
      await createLog(
        id: log4,
        event: 4,
        observedAt: observedAt,
        description: 'Aynı created_at büyük id',
      );

      expect(
        (await agenda.listAgenda(
          const AgendaQuery(istanbulDay: '2026-07-19'),
        )).map((item) => item.id),
        [log4, log3, log2, log1],
      );
      expect(
        (await agenda.listAgenda(
          const AgendaQuery(
            istanbulDay: '2026-07-19',
            sortOrder: AgendaSortOrder.oldestFirst,
          ),
        )).map((item) => item.id),
        [log1, log2, log3, log4],
      );

      now = DateTime.utc(2026, 7, 20, 11);
      await agenda.updateAgendaLog(
        UpdateAgendaLogCommand(
          id: first.id,
          eventId: eventId(10),
          expectedRevision: first.revision,
          projectId: first.projectId,
          observedAt: first.observedAt,
          category: first.category,
          description: 'Updated_at değişti ama sıra değişmedi',
          location: first.location,
          notes: first.notes,
        ),
      );
      expect(
        (await agenda.listAgenda(
          const AgendaQuery(istanbulDay: '2026-07-19'),
        )).map((item) => item.id),
        [log4, log3, log2, log1],
      );

      await agenda.mutateAgendaLogArchive(
        MutateAgendaLogArchiveCommand(
          id: log3,
          eventId: eventId(11),
          expectedRevision: 1,
          archive: true,
        ),
      );
      await agenda.mutateAgendaLogArchive(
        MutateAgendaLogArchiveCommand(
          id: log4,
          eventId: eventId(12),
          expectedRevision: 1,
          archive: true,
        ),
      );
      expect(
        (await agenda.listAgenda(
          const AgendaQuery(istanbulDay: '2026-07-19'),
        )).map((item) => item.id),
        [log2, log1],
      );
      expect(
        (await agenda.listAgenda(
          const AgendaQuery(
            istanbulDay: '2026-07-19',
            archiveFilter: AgendaArchiveFilter.archived,
          ),
        )).map((item) => item.id),
        [log4, log3],
      );
      expect(
        (await agenda.listAgenda(
          const AgendaQuery(
            istanbulDay: '2026-07-19',
            archiveFilter: AgendaArchiveFilter.archived,
            sortOrder: AgendaSortOrder.oldestFirst,
          ),
        )).map((item) => item.id),
        [log3, log4],
      );
    },
  );

  test(
    'Agenda sort composes with filters and empty or single results',
    () async {
      expect(
        await agenda.listAgenda(const AgendaQuery(istanbulDay: '2026-07-19')),
        isEmpty,
      );
      await createLog(
        id: log1,
        event: 1,
        observedAt: '2026-07-19T06:00:00Z',
        category: AgendaCategory.inspection,
        description: 'CSE268 literal erken',
      );
      expect(
        (await agenda.listAgenda(
          const AgendaQuery(istanbulDay: '2026-07-19'),
        )).single.id,
        log1,
      );
      await agenda.createProject(
        const CreateProjectCommand(id: project2, name: 'Güney Şantiyesi'),
      );
      await createLog(
        id: log2,
        event: 2,
        projectId: project2,
        observedAt: '2026-07-19T07:00:00Z',
        category: AgendaCategory.delivery,
        description: 'CSE268 literal diğer proje',
      );
      await createLog(
        id: log3,
        event: 3,
        observedAt: '2026-07-19T08:00:00Z',
        category: AgendaCategory.inspection,
        description: 'CSE268 literal geç',
      );

      expect(
        (await agenda.listAgenda(
          const AgendaQuery(
            istanbulDay: '2026-07-19',
            projectId: project1,
            category: AgendaCategory.inspection,
            literalSearch: 'CSE268 literal',
          ),
        )).map((item) => item.id),
        [log3, log1],
      );
      expect(
        (await agenda.listAgenda(
          const AgendaQuery(
            istanbulDay: '2026-07-19',
            projectId: project1,
            category: AgendaCategory.inspection,
            literalSearch: 'CSE268 literal',
            sortOrder: AgendaSortOrder.oldestFirst,
          ),
        )).map((item) => item.id),
        [log1, log3],
      );
      expect(
        await agenda.listAgenda(
          const AgendaQuery(
            istanbulDay: '2026-07-19',
            literalSearch: 'olmayan exact metin',
          ),
        ),
        isEmpty,
      );
    },
  );

  test(
    'project catalog publishes live changes and rejects normalized duplicate',
    () async {
      final changed = agenda.projectChanges.first;
      final project = await agenda.createProject(
        const CreateProjectCommand(id: project2, name: '  Güney   Şantiyesi  '),
      );
      await changed;
      expect(project.name, 'Güney   Şantiyesi');
      expect(
        (await agenda.listProjects()).map((item) => item.id),
        contains(project2),
      );
      await expectLater(
        agenda.createProject(
          const CreateProjectCommand(
            id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
            name: 'güney şantiyesi',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      final restarted = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
      );
      expect(
        (await restarted.listProjects()).map((item) => item.id),
        contains(project2),
      );
    },
  );

  test(
    'past log keeps observed and created times separate and filters literally',
    () async {
      await agenda.createProject(
        const CreateProjectCommand(id: project2, name: 'Güney Projesi'),
      );
      now = DateTime.utc(2026, 7, 20, 9);
      final past = await createLog(
        id: log1,
        event: 1,
        observedAt: '2026-07-19T06:15:00Z',
        category: AgendaCategory.inspection,
        description: 'C30 % beton kontrolü',
        notes: 'Numune [A] kalıbında.',
      );
      await createLog(
        id: log2,
        event: 2,
        projectId: project2,
        observedAt: '2026-07-19T07:00:00Z',
        category: AgendaCategory.delivery,
        description: 'Demir teslimatı',
      );

      expect(past.observedAt, '2026-07-19T06:15:00Z');
      expect(past.createdAt, '2026-07-20T09:00:00Z');
      expect(
        (await agenda.listAgenda(
          const AgendaQuery(
            istanbulDay: '2026-07-19',
            projectId: project1,
            category: AgendaCategory.inspection,
            literalSearch: '% beton',
          ),
        )).map((item) => item.id),
        [log1],
      );
      expect(
        await agenda.listAgenda(
          const AgendaQuery(
            istanbulDay: '2026-07-19',
            literalSearch: '%_missing',
          ),
        ),
        isEmpty,
      );
    },
  );

  test(
    'future invalid and naive event times fail before database mutation',
    () async {
      now = DateTime.utc(2026, 7, 20, 8);
      for (final timestamp in [
        '2026-07-20T08:00:01Z',
        '2026-07-20T08:00:00',
        '2026-02-30T08:00:00Z',
        '2026-07-20T11:00:00+03:00',
      ]) {
        await expectLater(
          createLog(id: log1, event: 1, observedAt: timestamp),
          throwsA(isA<AgendaValidationFailure>()),
          reason: timestamp,
        );
      }
      expect(
        await _countRows(directories.databaseFile, 'field_observations'),
        0,
      );
      expect(
        await _countRows(directories.databaseFile, 'observation_events'),
        0,
      );
    },
  );

  test(
    'create reads clock once and retry with the same command is idempotent',
    () async {
      var reads = 0;
      agenda = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () {
          reads += 1;
          return DateTime.utc(2026, 7, 20, 8);
        },
      );
      final command = CreateAgendaLogCommand(
        id: log1,
        eventId: eventId(1),
        projectId: project1,
        observedAt: '2026-07-19T08:00:00Z',
        category: AgendaCategory.manufacturing,
        description: 'Duvar imalatı',
      );

      final first = await agenda.createAgendaLog(command);
      expect(reads, 1);
      final retried = await agenda.createAgendaLog(command);

      expect(retried.id, first.id);
      expect(reads, 2);
      expect(
        await _countRows(directories.databaseFile, 'field_observations'),
        1,
      );
      expect(
        await _countRows(directories.databaseFile, 'observation_events'),
        1,
      );
    },
  );

  test(
    'inbox timed all-day recheck and multiple reminders preserve source',
    () async {
      now = DateTime.utc(2026, 7, 19, 8);
      final source = await createLog(
        id: log1,
        event: 1,
        observedAt: '2026-07-19T07:00:00Z',
        description: 'Kalıp ölçüsünü doğrula',
      );
      final commands = [
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(11),
          projectId: project1,
          sourceLogId: log1,
          title: 'Unutma kutusu kaydı',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
        CreateReminderCommand(
          id: reminder2,
          eventId: eventId(12),
          projectId: project1,
          sourceLogId: log1,
          title: '15 dakika sonra aksiyon',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
        CreateReminderCommand(
          id: reminder3,
          eventId: eventId(13),
          projectId: project1,
          sourceLogId: log1,
          title: 'Bugün tam gün kontrol',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          allDayLocalDate: '2026-07-19',
        ),
        CreateReminderCommand(
          id: reminder4,
          eventId: eventId(14),
          projectId: project1,
          sourceLogId: log1,
          title: 'Özel tekrar kontrol',
          kind: ReminderKind.recheck,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: '2026-07-19T10:00:00Z',
        ),
        CreateReminderCommand(
          id: reminder5,
          eventId: eventId(15),
          projectId: project1,
          sourceLogId: log1,
          title: 'Yarın sabah kontrol',
          kind: ReminderKind.recheck,
          schedule: ReminderScheduleKind.tomorrowMorning,
        ),
        CreateReminderCommand(
          id: reminder6,
          eventId: eventId(16),
          projectId: project1,
          sourceLogId: log1,
          title: 'Bugün çıkmadan kontrol',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.todayEnd,
        ),
      ];

      final created = <MobileReminder>[];
      for (final command in commands) {
        created.add(await agenda.createReminder(command));
      }

      expect(created[0].status, ReminderStatus.inbox);
      expect(created[0].nextAttentionAt, isNull);
      expect(created[1].nextAttentionAt, '2026-07-19T08:15:00Z');
      expect(created[2].status, ReminderStatus.active);
      expect(created[2].nextAttentionAt, isNull);
      expect(created[2].allDayLocalDate, '2026-07-19');
      expect(created[3].kind, ReminderKind.recheck);
      expect(created[5].nextAttentionAt, '2026-07-19T15:00:00Z');
      expect(created.every((item) => item.sourceLogId == log1), isTrue);
      expect((await agenda.listReminders(ReminderViewGroup.inbox)).length, 1);
      expect((await agenda.listReminders(ReminderViewGroup.today)).length, 4);
      expect(
        (await agenda.listReminders(ReminderViewGroup.upcoming)).length,
        1,
      );

      final detail = await agenda.getAgendaLogDetail(log1);
      expect(detail.reminders.length, 6);
      expect(detail.log.updatedAt, source.updatedAt);
      expect(detail.log.revision, source.revision);
      final events = await agenda.listReminderEvents(reminder2);
      expect(events.single.sourceLogId, log1);
      expect(
        jsonDecode(events.single.payloadJson),
        containsPair('source_observation_id', log1),
      );
    },
  );

  test(
    'tomorrow view uses Istanbul half-open bounds and open statuses only',
    () async {
      now = DateTime.utc(2026, 7, 22, 19);
      String reminderId(int value) =>
          'cccccccc-cccc-4ccc-8ccc-${value.toString().padLeft(12, '0')}';

      Future<MobileReminder> createAt(int value, String dueAt) =>
          agenda.createReminder(
            CreateReminderCommand(
              id: reminderId(value),
              eventId: eventId(100 + value),
              projectId: project1,
              title: 'Sınır kaydı $value',
              kind: ReminderKind.action,
              schedule: ReminderScheduleKind.custom,
              customAttentionAt: dueAt,
            ),
          );

      final overdue = await createAt(1, '2026-07-22T19:30:00Z');
      final today2359 = await createAt(2, '2026-07-22T20:59:00Z');
      final tomorrow0000 = await createAt(3, '2026-07-22T21:00:00Z');
      final utcDateDiffers = await createAt(4, '2026-07-22T21:30:00Z');
      final allDayTomorrow = await agenda.createReminder(
        CreateReminderCommand(
          id: reminderId(5),
          eventId: eventId(105),
          projectId: project1,
          title: 'Yarın tam gün',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          allDayLocalDate: '2026-07-23',
        ),
      );
      final tomorrow2359 = await createAt(6, '2026-07-23T20:59:00Z');
      final dayAfter0000 = await createAt(7, '2026-07-23T21:00:00Z');
      var completed = await createAt(8, '2026-07-23T08:00:00Z');
      var cancelled = await createAt(9, '2026-07-23T09:00:00Z');
      final inbox = await agenda.createReminder(
        CreateReminderCommand(
          id: reminderId(10),
          eventId: eventId(110),
          projectId: project1,
          title: 'Due değeri olmayan kayıt',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      completed = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: completed.id,
          eventId: eventId(112),
          expectedRevision: completed.revision,
          action: ReminderMutationAction.complete,
        ),
      );
      cancelled = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: cancelled.id,
          eventId: eventId(113),
          expectedRevision: cancelled.revision,
          action: ReminderMutationAction.cancel,
        ),
      );
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await raw.update(
        'follow_up_items',
        {'next_attention_at': '2026-07-23T08:00:00Z'},
        where: 'id = ?',
        whereArgs: [completed.id],
      );
      await raw.update(
        'follow_up_items',
        {'next_attention_at': '2026-07-23T09:00:00Z'},
        where: 'id = ?',
        whereArgs: [cancelled.id],
      );
      await raw.close();

      now = DateTime.utc(2026, 7, 22, 20, 30);
      final tomorrow = await agenda.listReminders(ReminderViewGroup.tomorrow);

      expect(tomorrow.map((item) => item.id), [
        tomorrow0000.id,
        utcDateDiffers.id,
        tomorrow2359.id,
        allDayTomorrow.id,
      ]);
      expect(tomorrow.map((item) => item.status), [
        ReminderStatus.active,
        ReminderStatus.active,
        ReminderStatus.active,
        ReminderStatus.active,
      ]);
      final excluded = {
        overdue.id,
        today2359.id,
        dayAfter0000.id,
        completed.id,
        cancelled.id,
        inbox.id,
      };
      expect(tomorrow.every((item) => !excluded.contains(item.id)), isTrue);
      expect(
        (await agenda.getReminderDetail(tomorrow0000.id)).revision,
        tomorrow0000.revision,
      );
      expect(await agenda.listReminderEvents(tomorrow0000.id), hasLength(1));
    },
  );

  test(
    'unified Today uses Istanbul 18:00 cutoff and deterministic sections',
    () async {
      String id(int value) =>
          'dddddddd-dddd-4ddd-8ddd-${value.toString().padLeft(12, '0')}';

      now = DateTime.utc(2026, 12, 30, 6);
      Future<MobileReminder> createTimed(
        int value,
        String dueAt, {
        bool important = false,
      }) => agenda.createReminder(
        CreateReminderCommand(
          id: id(value),
          eventId: eventId(200 + value),
          projectId: project1,
          title: 'Saatli $value',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          customAttentionAt: dueAt,
          isImportant: important,
        ),
      );
      Future<MobileReminder> createAllDay(
        int value,
        String day, {
        bool important = false,
      }) => agenda.createReminder(
        CreateReminderCommand(
          id: id(value),
          eventId: eventId(200 + value),
          projectId: project1,
          title: 'Tam gün $value',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.custom,
          allDayLocalDate: day,
          isImportant: important,
        ),
      );

      final pastAllDay = await createAllDay(1, '2026-12-30');
      final overdueTimed = await createTimed(2, '2026-12-31T14:00:00Z');
      final laterTimed = await createTimed(3, '2026-12-31T16:00:00Z');
      final importantTimed = await createTimed(
        4,
        '2026-12-31T16:00:00Z',
        important: true,
      );
      final todayAllDay = await createAllDay(5, '2026-12-31');
      final importantAllDay = await createAllDay(
        6,
        '2026-12-31',
        important: true,
      );
      final tomorrowTimed = await createTimed(7, '2026-12-31T21:30:00Z');
      final tomorrowAllDay = await createAllDay(8, '2027-01-01');
      final inbox = await agenda.createReminder(
        CreateReminderCommand(
          id: id(9),
          eventId: eventId(209),
          projectId: project1,
          title: 'Plansız',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      var completed = await createTimed(10, '2026-12-31T16:30:00Z');
      completed = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: completed.id,
          eventId: eventId(310),
          expectedRevision: completed.revision,
          action: ReminderMutationAction.complete,
        ),
      );
      var cancelled = await createTimed(11, '2026-12-31T17:00:00Z');
      cancelled = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: cancelled.id,
          eventId: eventId(311),
          expectedRevision: cancelled.revision,
          action: ReminderMutationAction.cancel,
        ),
      );

      now = DateTime.utc(2026, 12, 31, 14, 59, 59);
      final beforeCutoff = await agenda.getReminderTodayOverview();
      expect(beforeCutoff.istanbulDay, '2026-12-31');
      expect(beforeCutoff.overdue.map((item) => item.id), [
        pastAllDay.id,
        overdueTimed.id,
      ]);
      expect(beforeCutoff.timedToday.map((item) => item.id), [
        importantTimed.id,
        laterTimed.id,
      ]);
      expect(beforeCutoff.allDayToday.map((item) => item.id), [
        importantAllDay.id,
        todayAllDay.id,
      ]);
      expect(beforeCutoff.inboxCount, 1);
      final visibleIds = [
        ...beforeCutoff.overdue,
        ...beforeCutoff.timedToday,
        ...beforeCutoff.allDayToday,
      ].map((item) => item.id).toList();
      expect(visibleIds.toSet(), hasLength(visibleIds.length));
      expect(visibleIds, isNot(contains(tomorrowTimed.id)));
      expect(visibleIds, isNot(contains(tomorrowAllDay.id)));
      expect(visibleIds, isNot(contains(inbox.id)));
      expect(visibleIds, isNot(contains(completed.id)));
      expect(visibleIds, isNot(contains(cancelled.id)));

      now = DateTime.utc(2026, 12, 31, 15);
      final atCutoff = await agenda.getReminderTodayOverview();
      expect(
        atCutoff.overdue.map((item) => item.id),
        containsAll([todayAllDay.id, importantAllDay.id]),
      );
      expect(atCutoff.allDayToday, isEmpty);
      expect(
        (await agenda.listReminders(
          ReminderViewGroup.tomorrow,
        )).map((item) => item.id),
        containsAll([tomorrowTimed.id, tomorrowAllDay.id]),
      );
    },
  );

  test('Today classifier deduplicates Puantaj and Beton source reminders', () {
    MobileReminder sourceReminder({
      required String id,
      String? attendanceDayId,
      String? concretePourId,
      String? nextAttentionAt,
      String? allDayLocalDate,
    }) => MobileReminder(
      id: id,
      projectId: project1,
      projectName: 'Kuzey Şantiyesi',
      sourceLogId: null,
      attendanceDayId: attendanceDayId,
      concretePourId: concretePourId,
      title: 'Kaynak reminder',
      kind: ReminderKind.action,
      status: ReminderStatus.active,
      nextAttentionAt: nextAttentionAt,
      allDayLocalDate: allDayLocalDate,
      createdAt: '2026-12-30T06:00:00Z',
      updatedAt: '2026-12-30T06:00:00Z',
      revision: 1,
    );

    final attendance = sourceReminder(
      id: reminder1,
      attendanceDayId: log1,
      nextAttentionAt: '2026-12-31T16:00:00Z',
    );
    final concrete = sourceReminder(
      id: reminder2,
      concretePourId: log2,
      allDayLocalDate: '2026-12-31',
    );
    final overview = buildReminderTodayOverview([
      attendance,
      attendance,
      concrete,
      concrete,
    ], asOfUtc: DateTime.utc(2026, 12, 31, 14));

    expect(overview.timedToday.single.id, attendance.id);
    expect(overview.timedToday.single.attendanceDayId, log1);
    expect(overview.allDayToday.single.id, concrete.id);
    expect(overview.allDayToday.single.concretePourId, log2);
    expect(
      [
        ...overview.timedToday,
        ...overview.allDayToday,
      ].map((item) => item.id).toSet(),
      hasLength(2),
    );
  });

  test('source project mismatch fails before reminder insert', () async {
    await agenda.createProject(
      const CreateProjectCommand(id: project2, name: 'Başka Proje'),
    );
    await createLog(id: log1, event: 1, observedAt: '2026-07-19T07:00:00Z');

    await expectLater(
      agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(11),
          projectId: project2,
          sourceLogId: log1,
          title: 'Yanlış proje bağlantısı',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
      ),
      throwsA(isA<AgendaValidationFailure>()),
    );
    expect(await _countRows(directories.databaseFile, 'follow_up_items'), 0);
    expect(await _countRows(directories.databaseFile, 'follow_up_events'), 0);
  });

  test('invalid or past custom reminder time fails before mutation', () async {
    now = DateTime.utc(2026, 7, 19, 8);
    await createLog(id: log1, event: 1, observedAt: '2026-07-19T07:00:00Z');
    for (final attention in [
      '2026-07-19T08:00:00Z',
      '2026-07-19T11:00:00+03:00',
      '2026-07-19T11:00:00',
    ]) {
      await expectLater(
        agenda.createReminder(
          CreateReminderCommand(
            id: reminder1,
            eventId: eventId(11),
            projectId: project1,
            sourceLogId: log1,
            title: 'Geçersiz zaman',
            kind: ReminderKind.action,
            schedule: ReminderScheduleKind.custom,
            customAttentionAt: attention,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
    }
    expect(await _countRows(directories.databaseFile, 'follow_up_items'), 0);
    expect(await _countRows(directories.databaseFile, 'follow_up_events'), 0);
  });

  test('transaction failure leaves no partial reminder or event', () async {
    now = DateTime.utc(2026, 7, 19, 8);
    await createLog(id: log1, event: 1, observedAt: '2026-07-19T07:00:00Z');
    final failing = SqliteAgendaApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
      beforeReminderEventInsert: (_) async {
        throw StateError('forced event failure');
      },
    );

    await expectLater(
      failing.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(11),
          projectId: project1,
          sourceLogId: log1,
          title: 'Rollback kanıtı',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
      ),
      throwsStateError,
    );
    expect(await _countRows(directories.databaseFile, 'follow_up_items'), 0);
    expect(await _countRows(directories.databaseFile, 'follow_up_events'), 0);
  });

  test(
    'log edit no-op stale rollback archive restore and reminder link are safe',
    () async {
      await agenda.createProject(
        const CreateProjectCommand(id: project2, name: 'Güney Şantiyesi'),
      );
      final created = await createLog(
        id: log1,
        event: 1,
        observedAt: '2026-07-19T07:00:00Z',
        description: 'İlk açıklama',
      );
      await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(70),
          projectId: project1,
          sourceLogId: log1,
          title: 'Kaynak reminder',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.in15Minutes,
        ),
      );
      final updated = await agenda.updateAgendaLog(
        UpdateAgendaLogCommand(
          id: log1,
          eventId: eventId(71),
          expectedRevision: created.revision,
          projectId: project1,
          observedAt: '2026-07-18T06:15:00Z',
          category: AgendaCategory.inspection,
          description: 'Güncellenen açıklama',
          location: 'B Blok',
          notes: 'Güvenli before/after',
        ),
      );
      expect(updated.revision, 2);
      expect(updated.observedAt, '2026-07-18T06:15:00Z');
      final updatePayload =
          jsonDecode(
                (await agenda.listObservationEvents(log1)).last.payloadJson,
              )
              as Map<String, dynamic>;
      expect(updatePayload['before']['description'], 'İlk açıklama');
      expect(updatePayload['after']['description'], 'Güncellenen açıklama');

      final noOp = await agenda.updateAgendaLog(
        UpdateAgendaLogCommand(
          id: log1,
          eventId: eventId(72),
          expectedRevision: updated.revision,
          projectId: updated.projectId,
          observedAt: updated.observedAt,
          category: updated.category,
          description: updated.description,
          location: updated.location,
          notes: updated.notes,
        ),
      );
      expect(noOp.revision, 2);
      expect(
        (await agenda.listObservationEvents(log1)).map((item) => item.id),
        isNot(contains(eventId(72))),
      );
      await expectLater(
        agenda.updateAgendaLog(
          UpdateAgendaLogCommand(
            id: log1,
            eventId: eventId(73),
            expectedRevision: 1,
            projectId: project1,
            observedAt: updated.observedAt,
            category: updated.category,
            description: 'Stale değişiklik',
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      await expectLater(
        agenda.updateAgendaLog(
          UpdateAgendaLogCommand(
            id: log1,
            eventId: eventId(74),
            expectedRevision: updated.revision,
            projectId: project2,
            observedAt: updated.observedAt,
            category: updated.category,
            description: updated.description,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect((await agenda.getReminderDetail(reminder1)).projectId, project1);

      final archived = await agenda.mutateAgendaLogArchive(
        MutateAgendaLogArchiveCommand(
          id: log1,
          eventId: eventId(75),
          expectedRevision: updated.revision,
          archive: true,
        ),
      );
      expect(archived.log.archivedAt, isNotNull);
      expect(
        await agenda.listAgenda(const AgendaQuery(istanbulDay: '2026-07-18')),
        isEmpty,
      );
      expect(
        (await agenda.listAgenda(
          const AgendaQuery(
            istanbulDay: '2026-07-18',
            archiveFilter: AgendaArchiveFilter.archived,
          ),
        )).single.id,
        log1,
      );
      expect(archived.reminders.single.id, reminder1);
      final restored = await agenda.mutateAgendaLogArchive(
        MutateAgendaLogArchiveCommand(
          id: log1,
          eventId: eventId(76),
          expectedRevision: archived.log.revision,
          archive: false,
        ),
      );
      expect(restored.log.archivedAt, isNull);
      expect(
        restored.events.map((item) => item.eventType),
        containsAll([
          'agenda_log.updated',
          'agenda_log.archived',
          'agenda_log.restored',
        ]),
      );
      expect((await agenda.getReminderDetail(reminder1)).revision, 1);

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await raw.execute('''
        CREATE TRIGGER fail_agenda_update_event
        BEFORE INSERT ON observation_events
        WHEN NEW.event_type = 'agenda_log.updated'
        BEGIN
          SELECT RAISE(ABORT, 'forced agenda event failure');
        END
      ''');
      await raw.close();
      await expectLater(
        agenda.updateAgendaLog(
          UpdateAgendaLogCommand(
            id: log1,
            eventId: eventId(77),
            expectedRevision: restored.log.revision,
            projectId: project1,
            observedAt: restored.log.observedAt,
            category: restored.log.category,
            description: 'Rollback olmamalı',
          ),
        ),
        throwsA(anything),
      );
      expect(
        (await agenda.getAgendaLogDetail(log1)).log.description,
        'Güncellenen açıklama',
      );
    },
  );

  test(
    'agenda photos stage attach diagnose archive and restart without partials',
    () async {
      final created = await agenda.createAgendaLog(
        CreateAgendaLogCommand(
          id: log1,
          eventId: eventId(80),
          projectId: project1,
          observedAt: '2026-07-19T07:00:00Z',
          category: AgendaCategory.generalNote,
          description: 'Fotoğraflı log',
          photos: [
            AgendaPhotoDraft(
              id: log2,
              eventId: eventId(81),
              originalFileName: 'saha.jpg',
              bytes: const [0xff, 0xd8, 0xff, 1],
              capturedAt: '2026-07-19T07:00:00Z',
            ),
          ],
        ),
      );
      var detail = await agenda.getAgendaLogDetail(log1);
      expect(detail.photos.single.id, log2);
      expect(detail.photos.single.integrity, AgendaAttachmentIntegrity.ok);
      expect((await agenda.readAgendaPhoto(log2)).bytes, [0xff, 0xd8, 0xff, 1]);

      detail = await agenda.attachAgendaPhoto(
        AttachAgendaPhotoCommand(
          logId: log1,
          id: log3,
          eventId: eventId(82),
          expectedLogRevision: created.revision,
          originalFileName: 'detay.jpg',
          bytes: const [0xff, 0xd8, 0xff, 2],
          capturedAt: '2026-07-19T07:05:00Z',
        ),
      );
      expect(detail.photos.map((item) => item.id), [log2, log3]);
      await expectLater(
        agenda.attachAgendaPhoto(
          AttachAgendaPhotoCommand(
            logId: log1,
            id: log4,
            eventId: eventId(83),
            expectedLogRevision: detail.log.revision,
            originalFileName: 'duplicate.jpg',
            bytes: const [0xff, 0xd8, 0xff, 2],
            capturedAt: '2026-07-19T07:06:00Z',
          ),
        ),
        throwsA(anything),
      );
      expect(
        await File(
          '${directories.attachments.path}${Platform.pathSeparator}'
          'managed${Platform.pathSeparator}$log4.jpg',
        ).exists(),
        isFalse,
      );
      detail = await agenda.archiveAgendaPhoto(
        ArchiveAgendaPhotoCommand(
          logId: log1,
          photoId: log3,
          eventId: eventId(84),
          expectedLogRevision: detail.log.revision,
          expectedPhotoRevision: 1,
        ),
      );
      expect(detail.photos.map((item) => item.id), [log2]);
      final archivedFile = File(
        '${directories.attachments.path}${Platform.pathSeparator}'
        'managed${Platform.pathSeparator}$log3.jpg',
      );
      expect(await archivedFile.exists(), isTrue);

      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        await raw.query(
          'attachment_links',
          where: "source_type = 'agenda_observation' AND source_id = ?",
          whereArgs: [log1],
        ),
        hasLength(2),
      );
      expect(
        await raw.query(
          'attachment_link_events',
          where: 'attachment_link_id = ?',
          whereArgs: [log3],
          orderBy: 'sequence ASC',
        ),
        hasLength(2),
      );
      await expectLater(
        raw.delete('attachment_links', where: 'id = ?', whereArgs: [log3]),
        throwsA(anything),
      );
      await raw.close();
      final activeFile = File(
        '${directories.attachments.path}${Platform.pathSeparator}'
        'managed${Platform.pathSeparator}$log2.jpg',
      );
      await activeFile.writeAsBytes(const [0xff, 0xd8, 0xff, 9]);
      final restarted = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        attachmentStore: DeviceAgendaAttachmentStore(directories: directories),
      );
      expect(
        (await restarted.getAgendaLogDetail(log1)).photos.single.integrity,
        AgendaAttachmentIntegrity.tampered,
      );
      expect(
        (await restarted.listObservationEvents(
          log1,
        )).map((item) => item.eventType),
        containsAll(['agenda_log.photo_attached', 'agenda_log.photo_archived']),
      );
    },
  );

  test(
    'Agenda photo batches are ordered atomic and restricted to image MIME',
    () async {
      final created = await createLog(
        id: log1,
        event: 110,
        observedAt: '2026-07-19T07:00:00Z',
      );
      final detail = await agenda.attachAgendaPhotos(
        AttachAgendaPhotosCommand(
          logId: log1,
          expectedLogRevision: created.revision,
          photos: [
            AgendaPhotoDraft(
              id: log2,
              eventId: eventId(111),
              originalFileName: 'bir.jpg',
              bytes: const [0xff, 0xd8, 0xff, 1],
              capturedAt: '2026-07-19T07:01:00Z',
            ),
            AgendaPhotoDraft(
              id: log3,
              eventId: eventId(112),
              originalFileName: 'iki.png',
              bytes: const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 2],
              capturedAt: '2026-07-19T07:02:00Z',
            ),
          ],
        ),
      );
      expect(detail.log.revision, created.revision + 1);
      expect(detail.photos.map((item) => item.id), [log2, log3]);
      final attachedEvents = (await agenda.listObservationEvents(log1))
          .where((item) => item.eventType == 'agenda_log.photo_attached')
          .toList(growable: false);
      expect(attachedEvents.map((item) => item.id), [
        eventId(111),
        eventId(112),
      ]);
      expect(jsonDecode(attachedEvents.first.payloadJson)['batch_index'], 0);
      expect(jsonDecode(attachedEvents.last.payloadJson)['batch_index'], 1);

      await expectLater(
        agenda.attachAgendaPhotos(
          AttachAgendaPhotosCommand(
            logId: log1,
            expectedLogRevision: detail.log.revision,
            photos: [
              AgendaPhotoDraft(
                id: log4,
                eventId: eventId(113),
                originalFileName: 'duplicate-a.jpg',
                bytes: const [0xff, 0xd8, 0xff, 9],
                capturedAt: '2026-07-19T07:03:00Z',
              ),
              AgendaPhotoDraft(
                id: reminder1,
                eventId: eventId(114),
                originalFileName: 'duplicate-b.jpg',
                bytes: const [0xff, 0xd8, 0xff, 9],
                capturedAt: '2026-07-19T07:04:00Z',
              ),
            ],
          ),
        ),
        throwsA(anything),
      );
      expect((await agenda.getAgendaLogDetail(log1)).photos, hasLength(2));
      for (final id in [log4, reminder1]) {
        expect(
          await File(
            '${directories.attachments.path}${Platform.pathSeparator}'
            'managed${Platform.pathSeparator}$id.jpg',
          ).exists(),
          isFalse,
        );
      }

      await expectLater(
        agenda.createAgendaLog(
          CreateAgendaLogCommand(
            id: reminder2,
            eventId: eventId(115),
            projectId: project1,
            observedAt: '2026-07-19T08:00:00Z',
            category: AgendaCategory.generalNote,
            description: 'PDF kabul edilmemeli',
            photos: [
              AgendaPhotoDraft(
                id: reminder3,
                eventId: eventId(116),
                originalFileName: 'valid.jpg',
                bytes: const [0xff, 0xd8, 0xff, 3],
                capturedAt: '2026-07-19T08:01:00Z',
              ),
              AgendaPhotoDraft(
                id: reminder4,
                eventId: eventId(117),
                originalFileName: 'not-a-photo.pdf',
                bytes: const [0x25, 0x50, 0x44, 0x46, 0x2d, 0x31],
                capturedAt: '2026-07-19T08:02:00Z',
              ),
            ],
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect(
        await agenda.listAgenda(const AgendaQuery(istanbulDay: '2026-07-19')),
        hasLength(1),
      );
    },
  );

  test(
    'existing project photo links without byte copy and archive preserves shared physical',
    () async {
      final source = await agenda.createAgendaLog(
        CreateAgendaLogCommand(
          id: log1,
          eventId: eventId(180),
          projectId: project1,
          observedAt: '2026-07-19T07:00:00Z',
          category: AgendaCategory.generalNote,
          description: 'Kaynak fotoğraf',
          photos: [
            AgendaPhotoDraft(
              id: log3,
              eventId: eventId(181),
              originalFileName: 'ortak.jpg',
              bytes: const [0xff, 0xd8, 0xff, 4],
              capturedAt: '2026-07-19T07:00:00Z',
            ),
          ],
        ),
      );
      expect(source.revision, 1);
      final target = await createLog(
        id: log2,
        event: 182,
        observedAt: '2026-07-19T08:00:00Z',
      );
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final physicalBefore = Sqflite.firstIntValue(
        await raw.rawQuery('SELECT count(*) FROM managed_attachments'),
      );
      await raw.close();

      var linked = await agenda.linkExistingAgendaPhoto(
        LinkExistingAgendaPhotoCommand(
          logId: target.id,
          physicalAttachmentId: log3,
          linkId: reminder1,
          eventId: eventId(183),
          expectedLogRevision: target.revision,
        ),
      );

      expect(linked.log.revision, target.revision + 1);
      expect(linked.photos.single.id, reminder1);
      expect(linked.photos.single.relativePath, contains(log3));
      final verified = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      expect(
        Sqflite.firstIntValue(
          await verified.rawQuery('SELECT count(*) FROM managed_attachments'),
        ),
        physicalBefore,
      );
      expect(
        await verified.query(
          'attachment_links',
          columns: ['source_id', 'attachment_id'],
          where: 'attachment_id = ?',
          whereArgs: [log3],
          orderBy: 'source_id ASC',
        ),
        hasLength(2),
      );
      expect(
        await verified.query(
          'attachment_link_events',
          where: 'attachment_link_id = ?',
          whereArgs: [reminder1],
        ),
        hasLength(1),
      );
      await verified.close();

      await expectLater(
        agenda.linkExistingAgendaPhoto(
          LinkExistingAgendaPhotoCommand(
            logId: target.id,
            physicalAttachmentId: log3,
            linkId: reminder2,
            eventId: eventId(184),
            expectedLogRevision: linked.log.revision,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );
      expect((await agenda.getAgendaLogDetail(target.id)).log.revision, 2);

      await agenda.createProject(
        const CreateProjectCommand(id: project2, name: 'Güney Şantiyesi'),
      );
      final otherProjectLog = await createLog(
        id: log4,
        event: 185,
        projectId: project2,
        observedAt: '2026-07-19T09:00:00Z',
      );
      await expectLater(
        agenda.linkExistingAgendaPhoto(
          LinkExistingAgendaPhotoCommand(
            logId: otherProjectLog.id,
            physicalAttachmentId: log3,
            linkId: reminder3,
            eventId: eventId(186),
            expectedLogRevision: otherProjectLog.revision,
          ),
        ),
        throwsA(isA<AgendaValidationFailure>()),
      );

      linked = await agenda.archiveAgendaPhoto(
        ArchiveAgendaPhotoCommand(
          logId: target.id,
          photoId: reminder1,
          eventId: eventId(187),
          expectedLogRevision: linked.log.revision,
          expectedPhotoRevision: 1,
        ),
      );
      expect(linked.photos, isEmpty);
      expect((await agenda.getAgendaLogDetail(log1)).photos.single.id, log3);
      expect(
        await File(
          '${directories.attachments.path}${Platform.pathSeparator}'
          'managed${Platform.pathSeparator}$log3.jpg',
        ).exists(),
        isTrue,
      );
    },
  );

  test(
    'reminder source media is ordered read-only across archive and trash',
    () async {
      var log = await agenda.createAgendaLog(
        CreateAgendaLogCommand(
          id: log1,
          eventId: eventId(90),
          projectId: project1,
          observedAt: '2026-07-19T07:00:00Z',
          category: AgendaCategory.generalNote,
          description: 'Kaynak fotoğraflı log',
          photos: [
            AgendaPhotoDraft(
              id: log3,
              eventId: eventId(91),
              originalFileName: 'ikinci.jpg',
              bytes: const [0xff, 0xd8, 0xff, 2],
              capturedAt: '2026-07-19T07:02:00Z',
            ),
            AgendaPhotoDraft(
              id: log2,
              eventId: eventId(92),
              originalFileName: 'birinci.jpg',
              bytes: const [0xff, 0xd8, 0xff, 1],
              capturedAt: '2026-07-19T07:01:00Z',
              description: 'Kaynak açıklaması',
            ),
          ],
        ),
      );
      var reminder = await agenda.createReminder(
        CreateReminderCommand(
          id: reminder1,
          eventId: eventId(93),
          projectId: project1,
          sourceLogId: log1,
          title: 'Kaynak fotoğrafları kontrol et',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );

      var media = await agenda.getReminderSourceAgendaMedia(log1);
      expect(media.isAvailable, isTrue);
      expect(media.sourceLogArchivedAt, isNull);
      expect(media.photos.map((item) => item.id), [log2, log3]);
      expect(media.photos.first.description, 'Kaynak açıklaması');
      expect(
        media.photos.map((item) => item.integrity),
        everyElement(AgendaAttachmentIntegrity.ok),
      );

      final detailBeforeArchive = await agenda.getAgendaLogDetail(log1);
      await agenda.archiveAgendaPhoto(
        ArchiveAgendaPhotoCommand(
          logId: log1,
          photoId: log2,
          eventId: eventId(94),
          expectedLogRevision: detailBeforeArchive.log.revision,
          expectedPhotoRevision: detailBeforeArchive.photos.first.revision,
        ),
      );
      media = await agenda.getReminderSourceAgendaMedia(log1);
      expect(media.photos.map((item) => item.id), [log3]);

      log = (await agenda.mutateAgendaLogArchive(
        MutateAgendaLogArchiveCommand(
          id: log1,
          eventId: eventId(95),
          expectedRevision: log.revision + 1,
          archive: true,
        ),
      )).log;
      media = await agenda.getReminderSourceAgendaMedia(log1);
      expect(media.sourceLogArchivedAt, log.archivedAt);
      expect(media.photos.map((item) => item.id), [log3]);

      reminder = await agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: eventId(96),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.moveToTrash,
        ),
      );
      expect(reminder.trashedAt, isNotNull);
      final sourceBeforeRead = await agenda.getAgendaLogDetail(log1);
      final eventsBeforeRead = await agenda.listObservationEvents(log1);
      media = await agenda.getReminderSourceAgendaMedia(log1);
      final sourceAfterRead = await agenda.getAgendaLogDetail(log1);
      final eventsAfterRead = await agenda.listObservationEvents(log1);
      expect(media.photos.map((item) => item.id), [log3]);
      expect(sourceAfterRead.log.revision, sourceBeforeRead.log.revision);
      expect(sourceAfterRead.log.updatedAt, sourceBeforeRead.log.updatedAt);
      expect(eventsAfterRead.length, eventsBeforeRead.length);

      await createLog(
        id: log4,
        event: 97,
        observedAt: '2026-07-19T08:00:00Z',
        description: 'Fotoğrafsız kaynak',
      );
      expect((await agenda.getReminderSourceAgendaMedia(log4)).photos, isEmpty);
      final unavailable = await agenda.getReminderSourceAgendaMedia(reminder6);
      expect(unavailable.isAvailable, isFalse);
      expect(unavailable.photos, isEmpty);
      expect(unavailable.safeErrorCode, 'source_agenda_media_unavailable');
    },
  );

  test(
    'source media preserves every integrity state and deduplicates photo ids',
    () async {
      await agenda.createAgendaLog(
        CreateAgendaLogCommand(
          id: log1,
          eventId: eventId(100),
          projectId: project1,
          observedAt: '2026-07-19T07:00:00Z',
          category: AgendaCategory.generalNote,
          description: 'Integrity matrisi',
          photos: [
            AgendaPhotoDraft(
              id: log2,
              eventId: eventId(101),
              originalFileName: 'ok.jpg',
              bytes: const [0xff, 0xd8, 0xff, 1],
              capturedAt: '2026-07-19T07:01:00Z',
            ),
            AgendaPhotoDraft(
              id: log3,
              eventId: eventId(102),
              originalFileName: 'missing.jpg',
              bytes: const [0xff, 0xd8, 0xff, 2],
              capturedAt: '2026-07-19T07:02:00Z',
            ),
            AgendaPhotoDraft(
              id: log4,
              eventId: eventId(103),
              originalFileName: 'tampered.jpg',
              bytes: const [0xff, 0xd8, 0xff, 3],
              capturedAt: '2026-07-19T07:03:00Z',
            ),
            AgendaPhotoDraft(
              id: reminder1,
              eventId: eventId(104),
              originalFileName: 'invalid-mime.jpg',
              bytes: const [0xff, 0xd8, 0xff, 4],
              capturedAt: '2026-07-19T07:04:00Z',
            ),
          ],
        ),
      );
      final controlled = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
        attachmentStore: _IntegrityAgendaAttachmentStore({
          log2: AgendaAttachmentIntegrity.ok,
          log3: AgendaAttachmentIntegrity.missing,
          log4: AgendaAttachmentIntegrity.tampered,
          reminder1: AgendaAttachmentIntegrity.invalidMime,
        }),
      );

      final media = await controlled.getReminderSourceAgendaMedia(log1);

      expect(media.isAvailable, isTrue);
      expect(media.photos.map((item) => item.id), [
        log2,
        log3,
        log4,
        reminder1,
      ]);
      expect(media.photos.map((item) => item.integrity), [
        AgendaAttachmentIntegrity.ok,
        AgendaAttachmentIntegrity.missing,
        AgendaAttachmentIntegrity.tampered,
        AgendaAttachmentIntegrity.invalidMime,
      ]);
      final duplicated = ReminderSourceAgendaMedia.loaded(
        sourceLogId: log1,
        sourceLogArchivedAt: null,
        photos: [media.photos.first, media.photos.first],
      );
      expect(duplicated.photos, hasLength(1));
      expect(duplicated.photos.single.id, log2);
    },
  );

  test(
    'foreign keys and append-only histories are enforced by SQLite',
    () async {
      await createLog(id: log1, event: 1, observedAt: '2026-07-19T07:00:00Z');
      final raw = await databaseFactoryFfi.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await raw.execute('PRAGMA foreign_keys = ON');

      await expectLater(
        raw.insert('follow_up_items', {
          'id': reminder1,
          'project_id': project1,
          'observation_id': log2,
          'title': 'Orphan',
          'item_type': 'action',
          'status': 'inbox',
          'revision': 1,
          'created_at': '2026-07-20T08:00:00Z',
          'updated_at': '2026-07-20T08:00:00Z',
        }),
        throwsA(anything),
      );
      await expectLater(
        raw.update('observation_events', {'event_type': 'changed'}),
        throwsA(anything),
      );
      await expectLater(raw.delete('observation_events'), throwsA(anything));
      await expectLater(
        raw.delete('field_observations', where: 'id = ?', whereArgs: [log1]),
        throwsA(anything),
      );
      await raw.close();
    },
  );

  test(
    'records survive application restart without internet or Python runtime',
    () async {
      await createLog(
        id: log1,
        event: 1,
        observedAt: '2026-07-19T07:00:00Z',
        description: 'Restart kalıcılığı',
      );
      now = DateTime.utc(2026, 7, 20, 9);
      final restarted = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
      );

      final detail = await restarted.getAgendaLogDetail(log1);

      expect(detail.log.description, 'Restart kalıcılığı');
      expect(detail.log.observedAt, '2026-07-19T07:00:00Z');
    },
  );
}

Future<int> _countRows(String path, String table) async {
  final raw = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  final count = Sqflite.firstIntValue(
    await raw.rawQuery('SELECT COUNT(*) FROM $table'),
  );
  await raw.close();
  return count ?? 0;
}

class _IntegrityAgendaAttachmentStore implements AgendaAttachmentStore {
  const _IntegrityAgendaAttachmentStore(this.values);

  final Map<String, AgendaAttachmentIntegrity> values;

  @override
  Future<void> cleanup(String relativePath) async {}

  @override
  Future<AgendaAttachmentIntegrity> inspect(
    String relativePath,
    String expectedSha256,
    String expectedMimeType,
  ) async {
    for (final entry in values.entries) {
      if (relativePath.contains(entry.key)) return entry.value;
    }
    return AgendaAttachmentIntegrity.missing;
  }

  @override
  Future<StoredAttachmentContent> read(
    String relativePath,
    String originalFileName,
    String expectedSha256,
    String expectedMimeType,
  ) => throw const AgendaAttachmentFailure('test_read_unavailable');

  @override
  Future<StagedAgendaPhoto> stage({
    required String logId,
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) => throw const AgendaAttachmentFailure('test_stage_unavailable');
}
