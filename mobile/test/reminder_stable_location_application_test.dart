import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = '11111111-1111-4111-8111-111111111111';
const _projectB = '22222222-2222-4222-8222-222222222222';
const _locationA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _locationB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _locationOther = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3';

String _reminderId(int value) =>
    'bbbbbbbb-bbbb-4bbb-8bbb-${value.toString().padLeft(12, '0')}';
String _eventId(int value) =>
    'eeeeeeee-eeee-4eee-8eee-${value.toString().padLeft(12, '0')}';

void main() {
  late Directory root;
  late String databasePath;
  late DateTime now;
  late SqliteAgendaApplication application;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cse_reminder_location_');
    databasePath = path.join(root.path, 'cse.sqlite3');
    now = DateTime.utc(2026, 8, 9, 12);
    final database = AppDatabase(
      path: databasePath,
      factory: databaseFactoryFfi,
      clock: () => now,
    );
    await database.open();
    await database.close();
    application = SqliteAgendaApplication(
      databasePath: databasePath,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
    );
    await application.createProject(
      const CreateProjectCommand(id: _projectA, name: 'Kuzey'),
    );
    await application.createProject(
      const CreateProjectCommand(id: _projectB, name: 'Güney'),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<MobileProjectLocation> createLocation({
    required String id,
    required int event,
    required String name,
    String projectId = _projectA,
  }) => application.createProjectLocation(
    CreateProjectLocationCommand(
      id: id,
      eventId: _eventId(event),
      projectId: projectId,
      displayName: name,
    ),
  );

  CreateReminderCommand createCommand({
    required int reminder,
    required int event,
    String? projectId = _projectA,
    String? locationId,
    String? location = 'Serbest mahal',
  }) => CreateReminderCommand(
    id: _reminderId(reminder),
    eventId: _eventId(event),
    projectId: projectId,
    title: 'Takip et',
    kind: ReminderKind.action,
    schedule: ReminderScheduleKind.inbox,
    locationId: locationId,
    location: location,
  );

  test('legacy and stable create preserve their exact contracts', () async {
    await createLocation(id: _locationA, event: 1, name: 'A Blok');

    final legacy = await application.createReminder(
      createCommand(reminder: 1, event: 11, location: 'Eski serbest'),
    );
    final stable = await application.createReminder(
      createCommand(
        reminder: 2,
        event: 12,
        locationId: _locationA,
        location: 'Caller snapshot',
      ),
    );

    expect(legacy.locationId, isNull);
    expect(legacy.displayLocation, 'Eski serbest');
    expect(stable.locationId, _locationA);
    expect(stable.location, 'A Blok');
    expect(stable.stableLocationName, 'A Blok');
    final retried = await application.createReminder(
      createCommand(
        reminder: 2,
        event: 12,
        locationId: _locationA,
        location: 'Caller snapshot',
      ),
    );
    expect(retried.revision, 1);
  });

  test(
    'invalid missing archived cross-project and projectless links reject',
    () async {
      final archived = await createLocation(
        id: _locationA,
        event: 1,
        name: 'Arşivli',
      );
      await createLocation(
        id: _locationOther,
        event: 2,
        name: 'Güney',
        projectId: _projectB,
      );
      await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: archived.id,
          eventId: _eventId(3),
          expectedRevision: archived.revision,
          archive: true,
        ),
      );

      for (final command in [
        createCommand(reminder: 1, event: 11, locationId: 'bad'),
        createCommand(reminder: 2, event: 12, locationId: _locationB),
        createCommand(reminder: 3, event: 13, locationId: _locationA),
        createCommand(reminder: 4, event: 14, locationId: _locationOther),
        createCommand(
          reminder: 5,
          event: 15,
          projectId: null,
          locationId: _locationA,
        ),
      ]) {
        await expectLater(
          application.createReminder(command),
          throwsA(isA<AgendaValidationFailure>()),
        );
      }
    },
  );

  test(
    'rename archive update preserve unlink and event snapshots work',
    () async {
      final first = await createLocation(
        id: _locationA,
        event: 1,
        name: 'Eski Mahal',
      );
      await createLocation(id: _locationB, event: 2, name: 'B Blok');
      var reminder = await application.createReminder(
        createCommand(reminder: 1, event: 11, locationId: first.id),
      );
      await application.renameProjectLocation(
        RenameProjectLocationCommand(
          locationId: first.id,
          eventId: _eventId(12),
          expectedRevision: first.revision,
          displayName: 'Yeni Mahal',
        ),
      );
      var read = await application.getReminderDetail(reminder.id);
      expect(read.location, 'Eski Mahal');
      expect(read.stableLocationName, 'Yeni Mahal');

      reminder = await application.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: _eventId(13),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.updateDetails,
          title: reminder.title,
          projectId: reminder.projectId,
          locationId: _locationB,
        ),
      );
      expect(reminder.locationId, _locationB);
      expect(reminder.location, 'B Blok');
      final payload =
          jsonDecode(
                (await application.listReminderEvents(
                  reminder.id,
                )).last.payloadJson,
              )
              as Map<String, Object?>;
      expect(
        (payload['before']! as Map<String, Object?>)['location_id'],
        _locationA,
      );
      expect(
        (payload['after']! as Map<String, Object?>)['location_id'],
        _locationB,
      );

      final second = (await application.listProjectLocations(
        const ProjectLocationQuery(projectId: _projectA),
      )).singleWhere((item) => item.id == _locationB);
      now = DateTime.utc(2026, 8, 9, 13);
      await application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: second.id,
          eventId: _eventId(14),
          expectedRevision: second.revision,
          archive: true,
        ),
      );
      reminder = await application.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: _eventId(15),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.updateDetails,
          title: 'Başlık değişti',
          projectId: reminder.projectId,
          locationId: reminder.locationId,
          location: reminder.location,
        ),
      );
      expect(reminder.locationId, _locationB);
      expect(reminder.stableLocationArchivedAt, '2026-08-09T13:00:00Z');

      final unlinked = await application.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: _eventId(16),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.updateDetails,
          title: reminder.title,
          projectId: reminder.projectId,
          location: 'Yeniden serbest',
        ),
      );
      expect(unlinked.locationId, isNull);
      expect(unlinked.location, 'Yeniden serbest');
      read = await application.getReminderDetail(unlinked.id);
      expect(read.displayLocation, 'Yeniden serbest');
    },
  );
}
