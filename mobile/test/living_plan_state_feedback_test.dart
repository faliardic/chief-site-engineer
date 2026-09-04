import 'dart:async';
import 'dart:collection';

import 'package:chief_site_engineer/application/construction_living_plan_intelligence_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_intelligence_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/features/living_plan/living_plan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_living_plan_application.dart';

void main() {
  testWidgets('initial read is full loading without stale content or retry', (
    tester,
  ) async {
    final gate = Completer<List<ConstructionLivingPlanWindowItem>>();
    final livingPlan = _ControlledLivingPlanApplication()
      ..enqueue(() => gate.future);

    await _pumpPage(tester, livingPlan: livingPlan);

    expect(find.bySemanticsLabel('7 günlük plan yükleniyor'), findsOneWidget);
    expect(
      find.byKey(const Key('living-plan-preserving-reload')),
      findsNothing,
    );
    expect(find.byKey(const Key('living-plan-read-error-retry')), findsNothing);
    gate.complete([_item('initial', 'İlk plan')]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('living-plan-item-initial')), findsOneWidget);
  });

  testWidgets(
    'primary read error exposes one accessible retry and can recover',
    (tester) async {
      final livingPlan = _ControlledLivingPlanApplication()
        ..enqueue(() async => throw StateError('initial read failed'));
      await _pumpAndSettle(tester, livingPlan: livingPlan);

      final retry = find.byKey(const Key('living-plan-read-error-retry'));
      expect(retry, findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(
        find.bySemanticsLabel('7 günlük planı yeniden yükle'),
        findsOneWidget,
      );
      final size = tester.getSize(retry);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      livingPlan.enqueue(() async => [_item('recovered', 'Kurtarılan plan')]);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('living-plan-item-recovered')),
        findsOneWidget,
      );
      expect(retry, findsNothing);
    },
  );

  testWidgets('failed retry returns to the same primary read-error state', (
    tester,
  ) async {
    final livingPlan = _ControlledLivingPlanApplication()
      ..enqueue(() async => throw StateError('first failure'))
      ..enqueue(() async => throw StateError('retry failure'));
    await _pumpAndSettle(tester, livingPlan: livingPlan);

    await tester.tap(find.byKey(const Key('living-plan-read-error-retry')));
    await tester.pumpAndSettle();

    expect(
      find.text('Plan güvenli biçimde okunamadı. Kayıtlar değiştirilmedi.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('living-plan-read-error-retry')),
      findsOneWidget,
    );
    expect(livingPlan.reads, hasLength(2));
  });

  testWidgets('duplicate retry starts exactly one additional primary read', (
    tester,
  ) async {
    final livingPlan = _ControlledLivingPlanApplication()
      ..enqueue(() async => throw StateError('initial failure'));
    await _pumpAndSettle(tester, livingPlan: livingPlan);
    final gate = Completer<List<ConstructionLivingPlanWindowItem>>();
    livingPlan.enqueue(() => gate.future);
    final callback = tester
        .widget<FilledButton>(
          find.byKey(const Key('living-plan-read-error-retry')),
        )
        .onPressed!;

    callback();
    callback();
    await tester.pump();

    expect(livingPlan.reads, hasLength(2));
    expect(find.bySemanticsLabel('7 günlük plan yükleniyor'), findsOneWidget);
    expect(find.byKey(const Key('living-plan-read-error-retry')), findsNothing);
    gate.complete([_item('retry-once', 'Tek okuma')]);
    await tester.pumpAndSettle();
  });

  testWidgets('same-context refresh preserves last-good plan and replaces it', (
    tester,
  ) async {
    final livingPlan = _ControlledLivingPlanApplication(
      items: [_item('old', 'Mevcut plan')],
    );
    await _pumpAndSettle(tester, livingPlan: livingPlan);
    final gate = Completer<List<ConstructionLivingPlanWindowItem>>();
    livingPlan.enqueue(() => gate.future);
    final refresh = tester
        .widget<IconButton>(find.byKey(const Key('living-plan-refresh')))
        .onPressed!;

    refresh();
    refresh();
    await tester.pump();

    expect(livingPlan.reads, hasLength(2));
    expect(find.byKey(const Key('living-plan-item-old')), findsOneWidget);
    expect(
      find.byKey(const Key('living-plan-preserving-reload')),
      findsOneWidget,
    );
    gate.complete([_item('new', 'Güncel plan')]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('living-plan-item-old')), findsNothing);
    expect(find.byKey(const Key('living-plan-item-new')), findsOneWidget);
  });

  testWidgets(
    'preserving failure keeps content and retry keeps exact context',
    (tester) async {
      final livingPlan = _ControlledLivingPlanApplication(
        items: [_item('last-good', 'Son sağlam plan')],
      );
      await _pumpAndSettle(tester, livingPlan: livingPlan);
      livingPlan.enqueue(() async => throw StateError('refresh failed'));

      await tester.tap(find.byKey(const Key('living-plan-refresh')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('living-plan-item-last-good')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('living-plan-read-error-retry')),
        findsOneWidget,
      );
      livingPlan.enqueue(() async => [_item('after-retry', 'Yenilenen plan')]);
      await tester.tap(find.byKey(const Key('living-plan-read-error-retry')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('living-plan-item-after-retry')),
        findsOneWidget,
      );
      expect(
        livingPlan.reads,
        everyElement(_ReadContext('PRJ-A', DateTime.utc(2026, 8, 16))),
      );
    },
  );

  testWidgets('project change uses full loading and never shows old content', (
    tester,
  ) async {
    final livingPlan = _ControlledLivingPlanApplication(
      items: [_item('project-a', 'A projesi işi')],
    );
    await _pumpAndSettle(
      tester,
      livingPlan: livingPlan,
      projects: [_project('PRJ-A', 'A Blok'), _project('PRJ-B', 'B Blok')],
    );
    final gate = Completer<List<ConstructionLivingPlanWindowItem>>();
    livingPlan.enqueue(() => gate.future);

    tester
        .widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .onChanged!('PRJ-B');
    await tester.pump();

    expect(find.byKey(const Key('living-plan-item-project-a')), findsNothing);
    expect(find.bySemanticsLabel('7 günlük plan yükleniyor'), findsOneWidget);
    expect(
      find.byKey(const Key('living-plan-preserving-reload')),
      findsNothing,
    );
    expect(livingPlan.reads.last.projectId, 'PRJ-B');
    gate.complete([_item('project-b', 'B projesi işi', projectId: 'PRJ-B')]);
    await tester.pumpAndSettle();
  });

  testWidgets('window change uses canonical full loading without stale plan', (
    tester,
  ) async {
    final livingPlan = _ControlledLivingPlanApplication(
      items: [_item('old-window', 'Eski pencere işi')],
    );
    await _pumpAndSettle(tester, livingPlan: livingPlan);
    final gate = Completer<List<ConstructionLivingPlanWindowItem>>();
    livingPlan.enqueue(() => gate.future);

    tester
        .widget<IconButton>(find.byKey(const Key('living-plan-next-window')))
        .onPressed!();
    await tester.pump();

    expect(find.byKey(const Key('living-plan-item-old-window')), findsNothing);
    expect(find.bySemanticsLabel('7 günlük plan yükleniyor'), findsOneWidget);
    expect(livingPlan.reads.last.windowStart, DateTime.utc(2026, 8, 23));
    gate.complete([
      _item('next-window', 'Yeni pencere işi', date: DateTime.utc(2026, 8, 23)),
    ]);
    await tester.pumpAndSettle();
  });

  testWidgets('all mutation controls stay disabled during a preserving read', (
    tester,
  ) async {
    final livingPlan = _ControlledLivingPlanApplication(
      items: [
        _item(
          'busy',
          'Okuma sırasında korunan iş',
          status: ConstructionLivingPlanStatus.started,
          progressPercent: 30,
        ),
      ],
    );
    await _pumpAndSettle(tester, livingPlan: livingPlan);
    final gate = Completer<List<ConstructionLivingPlanWindowItem>>();
    livingPlan.enqueue(() => gate.future);

    tester
        .widget<IconButton>(find.byKey(const Key('living-plan-refresh')))
        .onPressed!();
    await tester.pump();

    expect(
      tester
          .widget<FloatingActionButton>(
            find.byKey(const Key('add-living-plan-item')),
          )
          .onPressed,
      isNull,
    );
    for (final key in [
      'complete-living-plan-busy',
      'defer-living-plan-busy',
      'progress-living-plan-busy',
      'note-living-plan-busy',
    ]) {
      expect(
        tester.widget<ButtonStyleButton>(find.byKey(Key(key))).onPressed,
        isNull,
      );
    }
    expect(livingPlan.mutationCalls, 0);
    gate.complete(livingPlan.items);
    await tester.pumpAndSettle();
  });

  testWidgets('mutation failure remains operation-specific Snackbar feedback', (
    tester,
  ) async {
    final livingPlan =
        _ControlledLivingPlanApplication(
            items: [_item('mutation', 'Mutasyon işi')],
          )
          ..nextMutationFailure = const ConstructionLivingPlanFailure(
            'living_plan_invalid_transition',
          );
    await _pumpAndSettle(tester, livingPlan: livingPlan);

    await tester.tap(find.byKey(const Key('start-living-plan-mutation')));
    await tester.pumpAndSettle();

    expect(
      find.text('Bu işlem kaydın mevcut durumunda uygulanamaz.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('living-plan-read-error-retry')), findsNothing);
    expect(livingPlan.mutationCalls, 1);
  });

  testWidgets(
    'degradation remains distinct and compact no-project empty grouped states survive',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpAndSettle(
        tester,
        livingPlan: _ControlledLivingPlanApplication(snapshotAvailable: false),
        textScaler: const TextScaler.linear(1.6),
        intelligence: const _FailingIntelligence(),
      );
      expect(
        find.text('Bu proje için güvenilir öneri programı henüz hazırlanmadı.'),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const Key('living-plan-scroll')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Bu pencerede planlanmış imalat yok. İmalat ekleyebilirsiniz.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('living-plan-read-error-retry')),
        findsNothing,
      );

      await _pumpAndSettle(
        tester,
        livingPlan: _ControlledLivingPlanApplication(
          items: [
            _item('overdue', 'Geciken iş', overdue: true),
            _item('today', 'Bugünkü iş'),
          ],
        ),
        textScaler: const TextScaler.linear(1.6),
        intelligence: const _FailingIntelligence(),
      );
      expect(
        find.byKey(const Key('living-plan-section-overdue')),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const Key('living-plan-scroll')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('living-plan-section-day-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('living-plan-read-error-retry')),
        findsNothing,
      );

      await _pumpAndSettle(
        tester,
        livingPlan: _ControlledLivingPlanApplication(),
        projects: const [],
        textScaler: const TextScaler.linear(1.6),
      );
      expect(find.text('Önce bir proje oluşturun.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required _ControlledLivingPlanApplication livingPlan,
  List<MobileProject>? projects,
  TextScaler textScaler = TextScaler.noScaling,
  ConstructionLivingPlanIntelligenceApplicationPort intelligence =
      const UnavailableConstructionLivingPlanIntelligenceApplication(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: LivingPlanPage(
        key: UniqueKey(),
        agenda: FakeAgendaApplication(
          projects: projects ?? [_project('PRJ-A', 'A Blok')],
        ),
        livingPlan: livingPlan,
        intelligence: intelligence,
        initialProjectId: (projects?.isEmpty ?? false) ? null : 'PRJ-A',
        clock: () => DateTime.utc(2026, 8, 16, 6),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpAndSettle(
  WidgetTester tester, {
  required _ControlledLivingPlanApplication livingPlan,
  List<MobileProject>? projects,
  TextScaler textScaler = TextScaler.noScaling,
  ConstructionLivingPlanIntelligenceApplicationPort intelligence =
      const UnavailableConstructionLivingPlanIntelligenceApplication(),
}) async {
  await _pumpPage(
    tester,
    livingPlan: livingPlan,
    projects: projects,
    textScaler: textScaler,
    intelligence: intelligence,
  );
  await tester.pumpAndSettle();
}

class _ControlledLivingPlanApplication extends FakeLivingPlanApplication {
  _ControlledLivingPlanApplication({super.items, super.snapshotAvailable});

  final Queue<Future<List<ConstructionLivingPlanWindowItem>> Function()>
  _responses = Queue();
  final List<_ReadContext> reads = [];

  void enqueue(
    Future<List<ConstructionLivingPlanWindowItem>> Function() response,
  ) {
    _responses.add(response);
  }

  @override
  Future<List<ConstructionLivingPlanWindowItem>> loadSevenDayPlan({
    required String projectId,
    required DateTime windowStart,
  }) {
    reads.add(_ReadContext(projectId, windowStart));
    if (_responses.isNotEmpty) return _responses.removeFirst()();
    return super.loadSevenDayPlan(
      projectId: projectId,
      windowStart: windowStart,
    );
  }
}

class _ReadContext {
  const _ReadContext(this.projectId, this.windowStart);

  final String projectId;
  final DateTime windowStart;

  @override
  bool operator ==(Object other) =>
      other is _ReadContext &&
      other.projectId == projectId &&
      other.windowStart == windowStart;

  @override
  int get hashCode => Object.hash(projectId, windowStart);
}

class _FailingIntelligence
    implements ConstructionLivingPlanIntelligenceApplicationPort {
  const _FailingIntelligence();

  @override
  Future<Map<String, ConstructionLivingPlanIntelligence>> loadForItems({
    required Iterable<ConstructionLivingPlanItem> items,
    required DateTime asOfDate,
  }) => throw StateError('synthetic intelligence degradation');
}

MobileProject _project(String id, String name) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-08-16T06:00:00Z',
  updatedAt: '2026-08-16T06:00:00Z',
  revision: 1,
);

ConstructionLivingPlanWindowItem _item(
  String id,
  String name, {
  String projectId = 'PRJ-A',
  DateTime? date,
  ConstructionLivingPlanStatus status = ConstructionLivingPlanStatus.planned,
  int? progressPercent,
  bool overdue = false,
}) {
  final now = DateTime.utc(2026, 8, 16, 6);
  return ConstructionLivingPlanWindowItem(
    item: ConstructionLivingPlanItem(
      id: id,
      projectId: projectId,
      referenceSnapshotId: 'snapshot-$projectId',
      activityInstanceId: 'instance-$id',
      activityId: 'activity-$id',
      activityNameSnapshot: name,
      activityContext: const ConstructionProjectActivityContext(
        blockId: 'A',
        floorIndex: 2,
      ),
      naturalUnitSnapshot: 'm²',
      plannedDate: date ?? DateTime.utc(2026, 8, 16),
      status: status,
      progressPercent: progressPercent,
      note: null,
      revision: 1,
      createdAt: now,
      updatedAt: now,
      statusChangedAt: now,
    ),
    isOverdue: overdue,
    originSnapshotIsCurrent: true,
  );
}
