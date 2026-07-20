import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
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

      expect(july19.map((item) => item.id), [log3, log1, log2]);
      expect(july20.map((item) => item.id), [log4]);
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
    'inbox action waiting recheck and multiple reminders preserve source',
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
          title: 'Bir saat dönüş bekle',
          kind: ReminderKind.waiting,
          schedule: ReminderScheduleKind.in1Hour,
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
      expect(created[2].status, ReminderStatus.waiting);
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
