import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/application/construction_schedule_snapshot_repository.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'support/living_plan_acceptance_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Issue 464 Living Plan survives a bootstrap restart', (
    tester,
  ) async {
    CseTimeCodec.initialize();
    final environment = AppEnvironment.current();
    final directories = AppDirectories.fromSupportRoot(
      await getApplicationSupportDirectory(),
      environment,
    );
    DateTime clock() => DateTime.now().toUtc();
    final fixture = await ensureLivingPlanAcceptanceFixture(
      directories: directories,
      databaseFactory: sqflite.databaseFactory,
      clock: clock,
    );
    final repeatedFixture = await ensureLivingPlanAcceptanceFixture(
      directories: directories,
      databaseFactory: sqflite.databaseFactory,
      clock: clock,
    );
    expect(repeatedFixture.projectId, fixture.projectId);
    expect(
      repeatedFixture.addCandidate.activityInstanceId,
      fixture.addCandidate.activityInstanceId,
    );
    final livingPlan = SqliteConstructionLivingPlanApplication(
      databasePath: directories.databaseFile,
      databaseFactory: sqflite.databaseFactory,
      clock: clock,
    );
    await _expectTrustedSyntheticSnapshot(directories, clock);

    await _pumpApp(tester);
    await _openLivingPlan(tester);
    expect(find.text(fixture.projectName), findsOneWidget);
    expect(find.text('Geciken'), findsOneWidget);
    expect(
      find.text(
        'Önerilen tarihler tahmin niteliğindedir; resmî iş programı değildir.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('living-plan-item-${fixture.plannedItemId}')),
      findsOneWidget,
    );

    await _openAddSheet(tester);
    await tester.enterText(
      find.byKey(const Key('living-plan-search')),
      livingPlanAcceptanceSearchAlias,
    );
    await tester.tap(find.byKey(const Key('living-plan-search-submit')));
    await tester.pumpAndSettle();
    final candidateKey = Key(
      'living-plan-candidate-${fixture.addCandidate.activityInstanceId}',
    );
    final addKey = Key(
      'add-candidate-${fixture.addCandidate.activityInstanceId}',
    );
    expect(find.byKey(candidateKey), findsOneWidget);
    if (fixture.addCandidate.existingLivingPlanItemId == null) {
      await tester.tap(find.byKey(addKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('select-candidate-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tamam').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('candidate-note-field')),
        'Acceptance persistence notu',
      );
      await tester.tap(find.byKey(const Key('confirm-add-candidate')));
      await tester.pumpAndSettle();
      expect(find.text('İmalat plana eklendi.'), findsOneWidget);
    }
    final addButton = tester.widget<FilledButton>(find.byKey(addKey));
    expect(addButton.onPressed, isNull);
    expect(
      find.descendant(
        of: find.byKey(candidateKey),
        matching: find.text('Planda'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();

    final addedCandidate = await _loadAddCandidate(livingPlan);
    final itemId = addedCandidate.existingLivingPlanItemId;
    expect(itemId, isNotNull);
    await _expectSingleCreatePersistence(
      directories,
      clock,
      fixture.addCandidate.activityInstanceId,
      itemId!,
    );
    await _scrollLivingPlanTo(
      tester,
      find.byKey(Key('living-plan-item-$itemId')),
    );
    expect(find.byKey(Key('living-plan-item-$itemId')), findsOneWidget);

    await _openAddSheet(tester);
    await tester.enterText(
      find.byKey(const Key('living-plan-search')),
      livingPlanAcceptanceSearchAlias,
    );
    await tester.tap(find.byKey(const Key('living-plan-search-submit')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(candidateKey),
        matching: find.text('Planda'),
      ),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(find.byKey(addKey)).onPressed, isNull);
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();

    await _normalizeToPlanned(tester, livingPlan, itemId);

    await _tapItemAction(tester, 'start-living-plan-$itemId');
    expect(find.text('İmalat başlatıldı.'), findsOneWidget);

    await _tapItemAction(tester, 'note-living-plan-$itemId');
    await tester.enterText(
      find.byKey(const Key('living-plan-note-field')),
      'Acceptance persistence notu',
    );
    await tester.tap(find.byKey(const Key('save-living-plan-note')));
    await tester.pumpAndSettle();
    expect(find.text('Not kaydedildi.'), findsOneWidget);

    await _tapItemAction(tester, 'defer-living-plan-$itemId');
    await tester.tap(find.text('Tamam').last);
    await tester.pumpAndSettle();
    expect(find.text('İmalat ertelendi.'), findsOneWidget);

    await _tapItemAction(tester, 'complete-living-plan-$itemId');
    expect(find.text('İmalat tamamlandı.'), findsOneWidget);

    await _tapItemAction(tester, 'reopen-living-plan-$itemId');
    await tester.tap(find.text('Tamam').last);
    await tester.pumpAndSettle();
    expect(find.text('İmalat yeniden açıldı.'), findsOneWidget);

    final beforeRestart = await livingPlan.loadLivingPlanItem(itemId);
    expect(beforeRestart, isNotNull);
    expect(beforeRestart!.status, ConstructionLivingPlanStatus.planned);
    expect(beforeRestart.note, 'Acceptance persistence notu');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _pumpApp(tester);
    await _openLivingPlan(tester);
    await _scrollLivingPlanTo(
      tester,
      find.byKey(Key('living-plan-item-$itemId')),
    );
    expect(find.byKey(Key('living-plan-item-$itemId')), findsOneWidget);
    expect(find.byKey(Key('living-plan-note-$itemId')), findsOneWidget);

    final afterRestart = await livingPlan.loadLivingPlanItem(itemId);
    expect(afterRestart, isNotNull);
    expect(afterRestart!.status, ConstructionLivingPlanStatus.planned);
    expect(afterRestart.note, 'Acceptance persistence notu');
    expect(await livingPlan.listLivingPlanEventHistory(itemId), isNotEmpty);
  });
}

Future<void> _expectTrustedSyntheticSnapshot(
  AppDirectories directories,
  DateTime Function() clock,
) async {
  final database = AppDatabase(
    path: directories.databaseFile,
    factory: sqflite.databaseFactory,
    clock: clock,
  );
  await database.open();
  try {
    final snapshot = await ConstructionScheduleSnapshotRepository(
      database: database,
      clock: clock,
    ).loadCurrentSnapshot(livingPlanAcceptanceProjectId);
    expect(snapshot, isNotNull);
    expect(
      snapshot!.metadata.productionStatus,
      ConstructionScheduleDateEngine.productionStatus,
    );
    expect(
      snapshot.metadata.durationSource,
      ConstructionScheduleDateEngine.durationSource,
    );
    expect(
      snapshot.metadata.baselineStatus,
      ConstructionScheduleDateEngine.baselineStatus,
    );
  } finally {
    await database.close();
  }
}

Future<void> _expectSingleCreatePersistence(
  AppDirectories directories,
  DateTime Function() clock,
  String activityInstanceId,
  String itemId,
) async {
  final database = AppDatabase(
    path: directories.databaseFile,
    factory: sqflite.databaseFactory,
    clock: clock,
  );
  await database.open();
  try {
    final items = await database.database.query(
      'project_living_plan_items',
      columns: const ['id', 'status', 'revision'],
      where: 'project_id = ? AND activity_instance_id = ?',
      whereArgs: [livingPlanAcceptanceProjectId, activityInstanceId],
    );
    expect(items, hasLength(1));
    expect(items.single['id'], itemId);

    final receipts = await database.database.query(
      'project_living_plan_command_receipts',
      columns: const [
        'event_type',
        'result_revision',
        'is_no_op',
        'event_sequence',
      ],
      where: 'living_plan_item_id = ? AND event_type = ?',
      whereArgs: [itemId, 'CREATED'],
    );
    expect(receipts, hasLength(1));
    expect(receipts.single['result_revision'], 1);
    expect(receipts.single['is_no_op'], 0);
    expect(receipts.single['event_sequence'], 1);

    final events = await database.database.query(
      'project_living_plan_events',
      columns: const ['event_type', 'sequence'],
      where: 'living_plan_item_id = ? AND event_type = ?',
      whereArgs: [itemId, 'CREATED'],
    );
    expect(events, hasLength(1));
    expect(events.single['sequence'], 1);
  } finally {
    await database.close();
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(CseApp(bootstrap: AppBootstrap.production().start()));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('bootstrap-safe-panel')), findsNothing);
}

Future<void> _openLivingPlan(WidgetTester tester) async {
  final entry = find.byKey(const Key('open-living-plan'));
  await tester.ensureVisible(entry);
  await tester.tap(entry);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('living-plan-project-selector')), findsOneWidget);
}

Future<void> _openAddSheet(WidgetTester tester) async {
  await _scrollLivingPlanTo(
    tester,
    find.byKey(const Key('add-living-plan-item')),
  );
  await tester.tap(find.byKey(const Key('add-living-plan-item')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('living-plan-search')), findsOneWidget);
}

Future<ConstructionLivingPlanReferenceCandidate> _loadAddCandidate(
  ConstructionLivingPlanApplicationPort livingPlan,
) async {
  final candidates = await livingPlan.searchCurrentReferenceCandidates(
    projectId: livingPlanAcceptanceProjectId,
    query: livingPlanAcceptanceSearchAlias,
  );
  return candidates.singleWhere(
    (candidate) => candidate.activityId == 'TR-BLD-01-002-MOBILIZASYON-PLANI',
  );
}

Future<void> _normalizeToPlanned(
  WidgetTester tester,
  ConstructionLivingPlanApplicationPort livingPlan,
  String itemId,
) async {
  var item = await livingPlan.loadLivingPlanItem(itemId);
  if (item == null) throw StateError('living_plan_acceptance_item_missing');
  if (item.status == ConstructionLivingPlanStatus.completed) {
    await _tapItemAction(tester, 'reopen-living-plan-$itemId');
    await tester.tap(find.text('Tamam').last);
    await tester.pumpAndSettle();
    return;
  }
  if (item.status != ConstructionLivingPlanStatus.planned) {
    await _tapItemAction(tester, 'complete-living-plan-$itemId');
    item = await livingPlan.loadLivingPlanItem(itemId);
    expect(item!.status, ConstructionLivingPlanStatus.completed);
    await _tapItemAction(tester, 'reopen-living-plan-$itemId');
    await tester.tap(find.text('Tamam').last);
    await tester.pumpAndSettle();
  }
}

Future<void> _tapItemAction(WidgetTester tester, String key) async {
  final action = find.byKey(Key(key));
  await _scrollLivingPlanTo(tester, action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> _scrollLivingPlanTo(WidgetTester tester, Finder target) async {
  final scrollable = find.descendant(
    of: find.byKey(const Key('living-plan-scroll')),
    matching: find.byType(Scrollable),
  );
  expect(scrollable, findsOneWidget);
  await tester.scrollUntilVisible(target, 180, scrollable: scrollable);
  await tester.pumpAndSettle();
}
