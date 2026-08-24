import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_intelligence_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/platform/agenda_attachment_gateway.dart';
import 'package:chief_site_engineer/platform/agenda_photo_export_gateway.dart';
import 'package:chief_site_engineer/platform/concrete_attachment_gateway.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../integration_test/support/living_plan_acceptance_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryRoot;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_bootstrap_');
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test(
    'restart returns the original persisted smoke record timestamp',
    () async {
      final directories = AppDirectories.fromSupportRoot(
        temporaryRoot,
        AppEnvironment.debug,
      );
      final first = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 8),
      ).start();
      final restarted = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      ).start();

      expect(first, isA<BootstrapSuccess>());
      expect(restarted, isA<BootstrapSuccess>());
      expect(
        (restarted as BootstrapSuccess).smokeRecordCreatedAt,
        (first as BootstrapSuccess).smokeRecordCreatedAt,
      );
      expect(first.backup, isNotNull);
      expect(restarted.backup, isNotNull);
      expect(first.livingPlan, isA<SqliteConstructionLivingPlanApplication>());
      expect(
        restarted.livingPlan,
        isA<SqliteConstructionLivingPlanApplication>(),
      );
      expect(
        first.livingPlanIntelligence,
        isA<SqliteConstructionLivingPlanIntelligenceApplication>(),
      );
      expect(
        restarted.livingPlanIntelligence,
        isA<SqliteConstructionLivingPlanIntelligenceApplication>(),
      );
      expect(
        await first.livingPlanIntelligence.loadForItems(
          items: const [],
          asOfDate: DateTime.utc(2026, 7, 19),
        ),
        isEmpty,
      );
      expect(first.projectLocations, same(first.agenda));
      expect(restarted.projectLocations, same(restarted.agenda));
      final agendaStore =
          (first.agenda as SqliteAgendaApplication).attachmentStore
              as DeviceAgendaAttachmentStore;
      final concreteStore =
          (first.concrete! as SqliteConcreteApplication).attachmentStore
              as DeviceConcreteAttachmentStore;
      expect(agendaStore.managedStore, same(concreteStore.managedStore));
      expect(
        (first.agenda as SqliteAgendaApplication).photoExportGateway,
        isA<DeviceAgendaPhotoExportGateway>(),
      );
      expect(first.attachmentCatalog, isNotNull);
      expect(first.attachmentReconciliation, isNotNull);
      expect(
        (first.agenda as AttachmentCatalogHost).attachmentCatalog,
        same(first.attachmentCatalog),
      );
      expect(
        (first.concrete! as AttachmentCatalogHost).attachmentCatalog,
        same(first.attachmentCatalog),
      );
    },
  );

  test('path or database failure returns no implementation detail', () async {
    final result = await AppBootstrap(
      environment: AppEnvironment.debug,
      directoriesProvider: () async => throw StateError('sensitive path'),
      databaseFactory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 7, 19, 8),
    ).start();

    expect(result, const TypeMatcher<BootstrapFailure>());
    expect(result.toString(), isNot(contains('sensitive path')));
  });

  test(
    'acceptance fixture recovers the runner item at later revisions',
    () async {
      CseTimeCodec.initialize();
      final now = DateTime.utc(2026, 8, 23, 12);
      final directories = AppDirectories.fromSupportRoot(
        temporaryRoot,
        AppEnvironment.debug,
      );
      final fixture = await ensureLivingPlanAcceptanceFixture(
        directories: directories,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
      );
      final livingPlan = SqliteConstructionLivingPlanApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
      );
      var runnerItem = await livingPlan.createLivingPlanItem(
        CreateConstructionLivingPlanItemCommand(
          itemId: '47610000-0000-4000-8000-000000000001',
          eventId: '47610000-0000-4000-8000-000000000002',
          projectId: fixture.projectId,
          expectedReferenceSnapshotId:
              fixture.addCandidate.referenceSnapshotId,
          activityInstanceId: fixture.addCandidate.activityInstanceId,
          plannedDate: fixture.windowStart,
          note: 'Acceptance persistence notu',
        ),
      );
      runnerItem = await livingPlan.startLivingPlanItem(
        StartConstructionLivingPlanItemCommand(
          itemId: runnerItem.id,
          eventId: '47610000-0000-4000-8000-000000000003',
          expectedRevision: runnerItem.revision,
        ),
      );
      runnerItem = await livingPlan.updateLivingPlanProgress(
        UpdateConstructionLivingPlanProgressCommand(
          itemId: runnerItem.id,
          eventId: '47610000-0000-4000-8000-000000000004',
          expectedRevision: runnerItem.revision,
          progressPercent: 47,
        ),
      );

      await ensureLivingPlanAcceptanceFixture(
        directories: directories,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
      );
      runnerItem = (await livingPlan.loadLivingPlanItem(runnerItem.id))!;
      expect(runnerItem.status, ConstructionLivingPlanStatus.completed);
      expect(runnerItem.progressPercent, 100);

      runnerItem = await livingPlan.reopenLivingPlanItem(
        ReopenConstructionLivingPlanItemCommand(
          itemId: runnerItem.id,
          eventId: '47610000-0000-4000-8000-000000000005',
          expectedRevision: runnerItem.revision,
          plannedDate: fixture.windowStart,
        ),
      );
      runnerItem = await livingPlan.startLivingPlanItem(
        StartConstructionLivingPlanItemCommand(
          itemId: runnerItem.id,
          eventId: '47610000-0000-4000-8000-000000000006',
          expectedRevision: runnerItem.revision,
        ),
      );
      runnerItem = await livingPlan.updateLivingPlanProgress(
        UpdateConstructionLivingPlanProgressCommand(
          itemId: runnerItem.id,
          eventId: '47610000-0000-4000-8000-000000000007',
          expectedRevision: runnerItem.revision,
          progressPercent: 63,
        ),
      );

      await ensureLivingPlanAcceptanceFixture(
        directories: directories,
        databaseFactory: databaseFactoryFfi,
        clock: () => now,
      );
      final recovered = await livingPlan.loadLivingPlanItem(runnerItem.id);
      expect(recovered, isNotNull);
      expect(recovered!.status, ConstructionLivingPlanStatus.completed);
      expect(recovered.progressPercent, 100);
      expect(recovered.revision, runnerItem.revision + 1);
    },
  );

  test('bootstrap reconciles only verified incoming backup orphans', () async {
    final now = DateTime.utc(2026, 7, 20, 12);
    final directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    await directories.incomingBackups.create(recursive: true);
    final partial = File(
      path.join(directories.incomingBackups.path, 'orphan.part'),
    );
    final expired = File(
      path.join(directories.incomingBackups.path, 'expired.csebackup'),
    );
    final fresh = File(
      path.join(directories.incomingBackups.path, 'fresh.csebackup'),
    );
    final outside = File(path.join(temporaryRoot.path, 'outside.part'));
    final managedStaging = File(
      path.join(
        directories.staging.path,
        'managed-aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.part',
      ),
    );
    for (final file in [partial, expired, fresh, outside, managedStaging]) {
      await file.writeAsBytes([1, 2, 3], flush: true);
    }
    await expired.setLastModified(now.subtract(const Duration(days: 2)));
    await fresh.setLastModified(now);

    final result = await AppBootstrap(
      environment: AppEnvironment.debug,
      directoriesProvider: () async => directories,
      databaseFactory: databaseFactoryFfi,
      clock: () => now,
    ).start();

    expect(result, isA<BootstrapSuccess>());
    expect(await partial.exists(), isFalse);
    expect(await expired.exists(), isFalse);
    expect(await fresh.exists(), isTrue);
    expect(await outside.exists(), isTrue);
    expect(
      await managedStaging.exists(),
      isTrue,
      reason: 'Attachment reconciliation is never automatic at bootstrap.',
    );
  });
}
