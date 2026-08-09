import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/platform/concrete_attachment_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = '11111111-1111-4111-8111-111111111111';
const _projectB = '22222222-2222-4222-8222-222222222222';
const _locationA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _locationB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _locationOther = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3';
const _pourId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1';
const _classId = 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1';

String _eventId(int value) =>
    'eeeeeeee-eeee-4eee-8eee-${value.toString().padLeft(12, '0')}';

void main() {
  late Directory root;
  late String databasePath;
  late DateTime now;
  late SqliteAgendaApplication agenda;
  late SqliteConcreteApplication concrete;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cse_concrete_location_');
    databasePath = path.join(root.path, 'cse.sqlite3');
    now = DateTime.utc(2026, 8, 9, 12);
    final database = AppDatabase(
      path: databasePath,
      factory: databaseFactoryFfi,
      clock: () => now,
    );
    await database.open();
    await database.close();
    agenda = SqliteAgendaApplication(
      databasePath: databasePath,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
    );
    await agenda.createProject(
      const CreateProjectCommand(id: _projectA, name: 'Kuzey'),
    );
    await agenda.createProject(
      const CreateProjectCommand(id: _projectB, name: 'Güney'),
    );
    concrete = SqliteConcreteApplication(
      databasePath: databasePath,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
      agenda: agenda,
      attachmentStore: _AttachmentStore(),
    );
    await concrete.createConcreteClass(
      CreateProjectConcreteClassCommand(
        id: _classId,
        eventId: _eventId(1),
        projectId: _projectA,
        displayName: 'C30/37',
      ),
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
  }) => agenda.createProjectLocation(
    CreateProjectLocationCommand(
      id: id,
      eventId: _eventId(event),
      projectId: projectId,
      displayName: name,
    ),
  );

  CreateConcretePourCommand createCommand({String? locationId}) =>
      CreateConcretePourCommand(
        id: _pourId,
        eventId: _eventId(10),
        projectId: _projectA,
        pourCode: 'BT-402',
        elementLocation: 'K12-K18 kolonları',
        locationId: locationId,
        plannedAt: '2026-08-09T14:00:00Z',
        concreteClassId: _classId,
        plannedVolumeM3: 20,
      );

  UpdateConcretePourCommand updateCommand(
    ConcretePourDetail detail, {
    required int event,
    String? locationId,
    String? laboratoryAppointment,
    String? inspectionNotifiedAt,
  }) => UpdateConcretePourCommand(
    id: detail.pour.id,
    eventId: _eventId(event),
    expectedRevision: detail.pour.revision,
    elementLocation: detail.pour.elementLocation,
    locationId: locationId,
    plannedAt: detail.pour.plannedAt,
    concreteClass: detail.pour.concreteClass,
    plannedVolumeM3: detail.pour.plannedVolumeM3,
    laboratoryAppointment: laboratoryAppointment,
    inspectionNotifiedAt: inspectionNotifiedAt,
  );

  test(
    'stable create preserves element detail and propagates reminders',
    () async {
      await createLocation(id: _locationA, event: 2, name: 'A Blok');

      final detail = await concrete.createPour(
        createCommand(locationId: _locationA),
      );
      expect(detail.pour.locationId, _locationA);
      expect(detail.pour.stableLocationName, 'A Blok');
      expect(detail.pour.elementLocation, 'K12-K18 kolonları');
      expect(detail.linkedReminders, isNotEmpty);
      expect(
        detail.linkedReminders.every(
          (item) =>
              item.locationId == _locationA &&
              item.location == 'A Blok' &&
              item.stableLocationName == 'A Blok',
        ),
        isTrue,
      );
      final retried = await concrete.createPour(
        createCommand(locationId: _locationA),
      );
      expect(retried.pour.revision, 1);
    },
  );

  test(
    'invalid missing archived and cross-project create reject atomically',
    () async {
      final archived = await createLocation(
        id: _locationA,
        event: 2,
        name: 'Arşivli',
      );
      await createLocation(
        id: _locationOther,
        event: 3,
        name: 'Güney',
        projectId: _projectB,
      );
      await agenda.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: archived.id,
          eventId: _eventId(4),
          expectedRevision: archived.revision,
          archive: true,
        ),
      );
      for (final locationId in [
        'bad',
        _locationB,
        _locationA,
        _locationOther,
      ]) {
        await expectLater(
          concrete.createPour(createCommand(locationId: locationId)),
          throwsA(isA<AgendaValidationFailure>()),
        );
      }
      final database = await databaseFactoryFfi.openDatabase(databasePath);
      expect(
        Sqflite.firstIntValue(
          await database.rawQuery('SELECT count(*) FROM concrete_pours'),
        ),
        0,
      );
      await database.close();
    },
  );

  test(
    'rename search archived preserve unlink and managed Agenda propagate',
    () async {
      final location = await createLocation(
        id: _locationA,
        event: 2,
        name: 'Eski Mahal',
      );
      var detail = await concrete.createPour(
        createCommand(locationId: location.id),
      );
      await agenda.renameProjectLocation(
        RenameProjectLocationCommand(
          locationId: location.id,
          eventId: _eventId(11),
          expectedRevision: location.revision,
          displayName: 'Yeni Mahal',
        ),
      );
      detail = await concrete.getPourDetail(_pourId);
      expect(detail.pour.stableLocationName, 'Yeni Mahal');
      for (final search in ['Yeni Mahal', 'K12-K18']) {
        final found = await concrete.listPours(
          ConcretePourQuery(
            group: ConcretePourGroup.today,
            projectId: _projectA,
            literalSearch: search,
          ),
        );
        expect(found.map((item) => item.id), contains(_pourId));
      }

      final currentLocation = (await agenda.listProjectLocations(
        const ProjectLocationQuery(projectId: _projectA),
      )).single;
      await agenda.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: currentLocation.id,
          eventId: _eventId(12),
          expectedRevision: currentLocation.revision,
          archive: true,
        ),
      );
      detail = await concrete.updatePour(
        updateCommand(detail, event: 13, locationId: detail.pour.locationId),
      );
      expect(detail.pour.locationId, _locationA);
      expect(detail.pour.stableLocationArchivedAt, isNotNull);

      for (final check in detail.checks.where((item) => item.isManual)) {
        detail = await concrete.updateCheck(
          UpdateConcreteCheckCommand(
            pourId: detail.pour.id,
            checkId: check.id,
            eventId: _eventId(100 + check.sortOrder),
            expectedPourRevision: detail.pour.revision,
            expectedCheckRevision: check.revision,
            status: ConcreteCheckStatus.completed,
          ),
        );
      }
      detail = await concrete.updatePour(
        updateCommand(
          detail,
          event: 130,
          locationId: detail.pour.locationId,
          laboratoryAppointment: '2026-08-09T13:00:00Z',
          inspectionNotifiedAt: '2026-08-09T12:30:00Z',
        ),
      );
      detail = await concrete.transitionPour(
        TransitionConcretePourCommand(
          pourId: detail.pour.id,
          eventId: _eventId(131),
          expectedRevision: detail.pour.revision,
          targetStatus: ConcretePourStatus.pouring,
        ),
      );
      final managed = await agenda.getAgendaLogDetail(detail.agendaLogId!);
      expect(managed.log.locationId, _locationA);
      expect(managed.log.location, 'K12-K18 kolonları');

      final unlinked = await concrete.updatePour(
        updateCommand(detail, event: 132),
      );
      expect(unlinked.pour.locationId, isNull);
      expect(
        unlinked.linkedReminders.every((item) => item.locationId == null),
        isTrue,
      );
      final refreshedManaged = await agenda.getAgendaLogDetail(
        unlinked.agendaLogId!,
      );
      expect(refreshedManaged.log.locationId, isNull);
      expect(refreshedManaged.log.location, 'K12-K18 kolonları');
    },
  );
}

class _AttachmentStore extends Fake implements ConcreteAttachmentStore {}
