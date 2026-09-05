import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/construction_living_plan_intelligence_application.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_dependency_impact_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_forecast_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_intelligence_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:chief_site_engineer/features/living_plan/living_plan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_living_plan_application.dart';

void main() {
  testWidgets('Profile tools open the project-local seven-day plan', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication(
      projects: [_project('PRJ-A', 'A Blok')],
    );
    final livingPlan = FakeLivingPlanApplication(suggestions: [_candidate()]);
    await tester.pumpWidget(
      CseApp(
        bootstrap: Future.value(
          BootstrapSuccess(
            environmentLabel: 'Kabul',
            smokeRecordId: 'smoke',
            smokeRecordCreatedAt: '2026-08-16T06:00:00Z',
            agenda: agenda,
            livingPlan: livingPlan,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tools = find.byKey(const Key('project-profile-tools'));
    await tester.ensureVisible(tools);
    await tester.pumpAndSettle();
    expect(tools.hitTestable(), findsOneWidget);
    await tester.tap(tools.hitTestable());
    await tester.pumpAndSettle();
    final entry = find.byKey(const Key('dashboard-open-plan'));
    expect(entry, findsOneWidget);
    final dashboardScrollable = find.ancestor(
      of: entry,
      matching: find.byType(Scrollable),
    );
    expect(dashboardScrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      entry,
      240,
      scrollable: dashboardScrollable,
    );
    await tester.pumpAndSettle();
    final hitTestableEntry = entry.hitTestable();
    if (hitTestableEntry.evaluate().isEmpty) {
      await tester.drag(dashboardScrollable, const Offset(0, -80));
      await tester.pumpAndSettle();
    }
    expect(hitTestableEntry, findsOneWidget);
    await tester.tap(hitTestableEntry);
    await tester.pumpAndSettle();

    expect(find.text('7 Günlük Plan'), findsWidgets);
    expect(
      find.byKey(const Key('living-plan-project-selector')),
      findsOneWidget,
    );
    expect(find.text('A Blok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no project and missing snapshot stay fail-closed', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      agenda: FakeAgendaApplication(),
      livingPlan: FakeLivingPlanApplication(),
    );
    expect(find.text('Önce bir proje oluşturun.'), findsOneWidget);
    expect(
      tester
          .widget<FloatingActionButton>(
            find.byKey(const Key('add-living-plan-item')),
          )
          .onPressed,
      isNull,
    );

    await _pumpPage(
      tester,
      agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
      livingPlan: FakeLivingPlanApplication(snapshotAvailable: false),
    );
    expect(
      find.text('Bu proje için güvenilir öneri programı henüz hazırlanmadı.'),
      findsOneWidget,
    );
    expect(find.textContaining('generic'), findsNothing);
    expect(
      tester
          .widget<FloatingActionButton>(
            find.byKey(const Key('add-living-plan-item')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'local calendar source and window navigation stay canonical UTC midnight',
    (tester) async {
      final localSource = DateTime(2026, 8, 16, 12);
      final fake = _StrictDateLivingPlanApplication(
        suggestions: [_candidate()],
      );

      expect(localSource.isUtc, isFalse);
      await _pumpPage(
        tester,
        agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
        livingPlan: fake,
        clock: () => localSource,
      );

      expect(fake.planWindowStarts, [DateTime.utc(2026, 8, 16)]);
      expect(fake.suggestionWindowStarts, [DateTime.utc(2026, 8, 16)]);
      expect(
        find.text('Plan güvenli biçimde okunamadı. Kayıtlar değiştirilmedi.'),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('living-plan-next-window')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('living-plan-previous-window')));
      await tester.pumpAndSettle();

      expect(fake.planWindowStarts, [
        DateTime.utc(2026, 8, 16),
        DateTime.utc(2026, 8, 23),
        DateTime.utc(2026, 8, 16),
      ]);
      expect(fake.suggestionWindowStarts, [
        DateTime.utc(2026, 8, 16),
        DateTime.utc(2026, 8, 23),
        DateTime.utc(2026, 8, 16),
      ]);
    },
  );

  for (final width in [320.0, 360.0]) {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'header controls fit ${width.toInt()} px in ${themeMode.name} at 1.6x',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await _pumpPage(
            tester,
            agenda: FakeAgendaApplication(
              projects: [
                _project(
                  'PRJ-A',
                  'CSE Çok Uzun Sentetik Şantiye Projesi A Blok Etabı',
                ),
              ],
            ),
            livingPlan: FakeLivingPlanApplication(
              suggestions: [_candidate()],
              items: [
                _windowItem(
                  id: 'layout-progress',
                  name: 'Uzun ilerleme kartı',
                  date: DateTime.utc(2026, 8, 16),
                  status: ConstructionLivingPlanStatus.started,
                  progressPercent: 47,
                ),
              ],
            ),
            themeMode: themeMode,
            textScaler: const TextScaler.linear(1.6),
          );

          for (final key in const [
            'living-plan-project-selector',
            'living-plan-previous-window',
            'living-plan-pick-window-start',
            'living-plan-next-window',
            'living-plan-refresh',
            'add-living-plan-item',
          ]) {
            final finder = find.byKey(Key(key));
            expect(finder, findsOneWidget);
            expect(
              tester.getRect(finder).overlaps(Rect.fromLTWH(0, 0, width, 900)),
              isTrue,
              reason: '$key must remain on-screen at $width px.',
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'grouped projection shows overdue, statuses, typed context and old source',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final fake = FakeLivingPlanApplication(
          suggestions: [_candidate()],
          items: [
            _windowItem(
              id: 'overdue',
              name: 'Temel Kalıbı',
              date: DateTime.utc(2026, 8, 15),
              status: ConstructionLivingPlanStatus.planned,
              overdue: true,
            ),
            _windowItem(
              id: 'today',
              name: 'Beton Dökümü',
              date: DateTime.utc(2026, 8, 16),
              status: ConstructionLivingPlanStatus.started,
              note: 'Pompa yolu hazır',
            ),
            _windowItem(
              id: 'completed',
              name: 'Duvar İmalatı',
              date: DateTime.utc(2026, 8, 17),
              status: ConstructionLivingPlanStatus.completed,
              currentOrigin: false,
            ),
            _windowItem(
              id: 'outside',
              name: 'Sekizinci Gün',
              date: DateTime.utc(2026, 8, 23),
              status: ConstructionLivingPlanStatus.planned,
            ),
          ],
        );
        await _pumpPage(
          tester,
          agenda: FakeAgendaApplication(
            projects: [_project('PRJ-A', 'Dar Ekran Projesi')],
          ),
          livingPlan: fake,
          themeMode: ThemeMode.dark,
          textScaler: const TextScaler.linear(1.6),
        );

        expect(
          find.textContaining('resmî iş programı değildir'),
          findsOneWidget,
        );

        await _scrollLivingPlanTo(
          tester,
          find.byKey(const Key('living-plan-section-overdue')),
        );
        expect(find.text('Geciken'), findsOneWidget);
        await _scrollLivingPlanTo(
          tester,
          find.byKey(const Key('living-plan-item-overdue')),
        );
        final overdueCard = find.byKey(const Key('living-plan-item-overdue'));
        expect(overdueCard, findsOneWidget);
        expect(
          find.descendant(of: overdueCard, matching: find.text('Temel Kalıbı')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: overdueCard, matching: find.text('Planlandı')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: overdueCard,
            matching: find.text('Blok A • 2. kat • Kuzey cephe'),
          ),
          findsOneWidget,
        );

        await _scrollLivingPlanTo(
          tester,
          find.byKey(const Key('living-plan-section-day-0')),
        );
        expect(find.textContaining('Bugün'), findsOneWidget);
        await _scrollLivingPlanTo(
          tester,
          find.byKey(const Key('living-plan-item-today')),
        );
        final todayCard = find.byKey(const Key('living-plan-item-today'));
        expect(todayCard, findsOneWidget);
        expect(
          find.descendant(of: todayCard, matching: find.text('Beton Dökümü')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: todayCard, matching: find.text('Başladı')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: todayCard,
            matching: find.text('Pompa yolu hazır'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: todayCard,
            matching: find.text('Blok A • 2. kat • Kuzey cephe'),
          ),
          findsOneWidget,
        );

        await _scrollLivingPlanTo(
          tester,
          find.byKey(const Key('living-plan-item-completed')),
        );
        expect(find.text('Tamamlandı'), findsOneWidget);
        expect(find.text('Eski öneri kaynağı'), findsOneWidget);
        expect(find.text('Duvar İmalatı'), findsOneWidget);
        expect(find.text('Sekizinci Gün'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'exact intelligence renders forecast and read-only impact detail',
    (tester) async {
      final source = _windowItem(
        id: 'intelligence-source',
        name: 'Radye demiri',
        date: DateTime.utc(2026, 8, 16),
        status: ConstructionLivingPlanStatus.started,
        progressPercent: 47,
        revision: 9,
      );
      final legacy = _windowItem(
        id: 'intelligence-legacy',
        name: 'Eski snapshot işi',
        date: DateTime.utc(2026, 8, 16),
        status: ConstructionLivingPlanStatus.started,
        progressPercent: 20,
      );
      final livingPlan = FakeLivingPlanApplication(
        suggestions: [_candidate()],
        items: [source, legacy],
      );
      final intelligence = _FakeIntelligenceApplication({
        source.item.id: _intelligenceFor(source.item),
        legacy.item.id: _intelligenceFor(
          legacy.item,
          dependencyGraphUnavailable: true,
        ),
      });

      await _pumpPage(
        tester,
        agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
        livingPlan: livingPlan,
        intelligence: intelligence,
      );

      expect(intelligence.asOfDates, [DateTime.utc(2026, 8, 16)]);
      expect(intelligence.itemIds.single, [
        'intelligence-source',
        'intelligence-legacy',
      ]);
      final sourceCard = find.byKey(
        const Key('living-plan-item-intelligence-source'),
      );
      await _scrollLivingPlanTo(tester, sourceCard);
      for (final text in const [
        'İlerleme %47',
        'Tahmini kalan: 6 iş günü',
        'Tahmini bitiş: 24.08.2026',
        'Referansa göre: +3 gün',
        '1 sonraki iş etkilenebilir',
      ]) {
        expect(
          find.descendant(of: sourceCard, matching: find.text(text)),
          findsOneWidget,
        );
      }

      await tester.tap(
        find.byKey(const Key('living-plan-impact-intelligence-source')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tahmini etki'), findsOneWidget);
      expect(
        find.text('Bu bir önizlemedir; plan tarihleri değişmedi.'),
        findsOneWidget,
      );
      expect(find.text('Radye kalıbı'), findsOneWidget);
      expect(
        find.textContaining('Tahmini başlangıç: 25.08.2026'),
        findsOneWidget,
      );
      expect(find.textContaining('Tahmini bitiş: 27.08.2026'), findsOneWidget);
      expect(find.text('+3 gün'), findsOneWidget);
      expect(livingPlan.mutationCalls, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(livingPlan.mutationCalls, 0);

      final legacyCard = find.byKey(
        const Key('living-plan-item-intelligence-legacy'),
      );
      await _scrollLivingPlanTo(tester, legacyCard);
      expect(
        find.descendant(
          of: legacyCard,
          matching: find.text('Tahmini kalan: 6 iş günü'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('living-plan-impact-intelligence-legacy')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('intelligence read failure cannot block lifecycle mutations', (
    tester,
  ) async {
    final livingPlan = FakeLivingPlanApplication(
      suggestions: [_candidate()],
      items: [
        _windowItem(
          id: 'intelligence-failure',
          name: 'Güvenli lifecycle',
          date: DateTime.utc(2026, 8, 16),
          status: ConstructionLivingPlanStatus.planned,
        ),
      ],
    );
    await _pumpPage(
      tester,
      agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
      livingPlan: livingPlan,
      intelligence: _FakeIntelligenceApplication.failure(),
    );

    expect(
      find.text('Plan güvenli biçimde okunamadı. Kayıtlar değiştirilmedi.'),
      findsNothing,
    );
    await _scrollLivingPlanTo(
      tester,
      find.byKey(const Key('start-living-plan-intelligence-failure')),
    );
    await tester.tap(
      find.byKey(const Key('start-living-plan-intelligence-failure')),
    );
    await tester.pumpAndSettle();
    expect(livingPlan.mutationCalls, 1);
    expect(find.text('İmalat başlatıldı.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress presentation actions and semantics are status-scoped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      final fake = FakeLivingPlanApplication(
        suggestions: [_candidate()],
        items: [
          _windowItem(
            id: 'progress-planned',
            name: 'Planlanan imalat',
            date: DateTime.utc(2026, 8, 16),
            status: ConstructionLivingPlanStatus.planned,
          ),
          _windowItem(
            id: 'progress-started',
            name: 'Başlayan imalat',
            date: DateTime.utc(2026, 8, 16),
            status: ConstructionLivingPlanStatus.started,
            progressPercent: 47,
          ),
          _windowItem(
            id: 'progress-deferred',
            name: 'Ertelenen imalat',
            date: DateTime.utc(2026, 8, 16),
            status: ConstructionLivingPlanStatus.deferred,
            progressPercent: 0,
          ),
          _windowItem(
            id: 'progress-completed',
            name: 'Tamamlanan imalat',
            date: DateTime.utc(2026, 8, 16),
            status: ConstructionLivingPlanStatus.completed,
            progressPercent: 100,
          ),
        ],
      );
      await _pumpPage(
        tester,
        agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
        livingPlan: fake,
      );

      const contextLabel = 'Blok A • 2. kat • Kuzey cephe';
      for (final expectation in const [
        (
          id: 'progress-planned',
          name: 'Planlanan imalat',
          text: 'İlerleme girilmedi',
          semanticsValue: 'Raporlanmadı',
          action: false,
        ),
        (
          id: 'progress-started',
          name: 'Başlayan imalat',
          text: 'İlerleme %47',
          semanticsValue: '%47',
          action: true,
        ),
        (
          id: 'progress-deferred',
          name: 'Ertelenen imalat',
          text: 'İlerleme %0',
          semanticsValue: '%0',
          action: true,
        ),
        (
          id: 'progress-completed',
          name: 'Tamamlanan imalat',
          text: 'İlerleme %100',
          semanticsValue: '%100',
          action: false,
        ),
      ]) {
        final card = find.byKey(Key('living-plan-item-${expectation.id}'));
        await _scrollLivingPlanTo(tester, card);
        expect(
          find.descendant(of: card, matching: find.text(expectation.text)),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('living-plan-progress-${expectation.id}')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            'Yaşayan plan öğesi · ${expectation.name} · $contextLabel · '
            '${expectation.id} · İlerleme · ${expectation.semanticsValue}',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(Key('progress-living-plan-${expectation.id}')),
          expectation.action ? findsOneWidget : findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'progress dialog is fail-closed and saves 0 middle and 99 with revision',
    (tester) async {
      final fake = FakeLivingPlanApplication(
        suggestions: [_candidate()],
        items: [
          _windowItem(
            id: 'progress-edit',
            name: 'Beton Dökümü',
            date: DateTime.utc(2026, 8, 16),
            status: ConstructionLivingPlanStatus.started,
            progressPercent: 47,
            revision: 7,
          ),
        ],
      );
      await _pumpPage(
        tester,
        agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
        livingPlan: fake,
      );

      Future<void> openDialog() async {
        await tester.tap(
          find.byKey(const Key('progress-living-plan-progress-edit')),
        );
        await tester.pumpAndSettle();
        expect(find.text('İlerlemeyi güncelle'), findsOneWidget);
      }

      FilledButton saveButton() => tester.widget<FilledButton>(
        find.byKey(const Key('save-living-plan-progress')),
      );

      await openDialog();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('living-plan-progress-field')),
            )
            .controller!
            .text,
        '47',
      );
      expect(saveButton().onPressed, isNull);
      for (final invalid in ['', '-1', '47.5', 'letters', '100']) {
        await tester.enterText(
          find.byKey(const Key('living-plan-progress-field')),
          invalid,
        );
        await tester.pump();
        expect(
          saveButton().onPressed,
          isNull,
          reason: '$invalid must not create a progress command.',
        );
      }
      expect(fake.mutationCalls, 0);
      await tester.tap(find.byKey(const Key('cancel-living-plan-progress')));
      await tester.pumpAndSettle();
      expect(fake.mutationCalls, 0);

      await openDialog();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(fake.mutationCalls, 0);

      for (final expectation in const [
        (value: '0', expectedRevision: 7),
        (value: '47', expectedRevision: 8),
        (value: '99', expectedRevision: 9),
      ]) {
        await openDialog();
        await tester.enterText(
          find.byKey(const Key('living-plan-progress-field')),
          expectation.value,
        );
        await tester.pump();
        expect(saveButton().onPressed, isNotNull);
        await tester.tap(find.byKey(const Key('save-living-plan-progress')));
        await tester.pumpAndSettle();

        final command =
            fake.lastMutationCommand!
                as UpdateConstructionLivingPlanProgressCommand;
        expect(command.itemId, 'progress-edit');
        expect(command.expectedRevision, expectation.expectedRevision);
        expect(command.progressPercent, int.parse(expectation.value));
        expect(
          command.eventId,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(
          find.text('İlerleme %${expectation.value} olarak kaydedildi.'),
          findsOneWidget,
        );
        expect(find.text('İlerleme %${expectation.value}'), findsOneWidget);
      }
      expect(fake.mutationCalls, 3);

      await openDialog();
      expect(saveButton().onPressed, isNull);
      await tester.tap(find.byKey(const Key('cancel-living-plan-progress')));
      await tester.pumpAndSettle();
      expect(fake.mutationCalls, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('note defer complete and reopen preserve progress lifecycle', (
    tester,
  ) async {
    final fake = _StrictDateLivingPlanApplication(
      suggestions: [_candidate()],
      items: [
        _windowItem(
          id: 'progress-lifecycle',
          name: 'Beton Dökümü',
          date: DateTime.utc(2026, 8, 16),
          status: ConstructionLivingPlanStatus.started,
          progressPercent: 47,
          note: 'İlk not',
        ),
      ],
    );
    await _pumpPage(
      tester,
      agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
      livingPlan: fake,
    );

    await _scrollLivingPlanTo(
      tester,
      find.byKey(const Key('note-living-plan-progress-lifecycle')),
    );
    await tester.tap(
      find.byKey(const Key('note-living-plan-progress-lifecycle')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('living-plan-note-field')),
      'Progress korunmalı',
    );
    await tester.tap(find.byKey(const Key('save-living-plan-note')));
    await tester.pumpAndSettle();
    expect(find.text('İlerleme %47'), findsOneWidget);

    await _scrollLivingPlanTo(
      tester,
      find.byKey(const Key('defer-living-plan-progress-lifecycle')),
    );
    await tester.tap(
      find.byKey(const Key('defer-living-plan-progress-lifecycle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Ertelendi'), findsOneWidget);
    expect(find.text('İlerleme %47'), findsOneWidget);

    await _scrollLivingPlanTo(
      tester,
      find.byKey(const Key('complete-living-plan-progress-lifecycle')),
    );
    await tester.tap(
      find.byKey(const Key('complete-living-plan-progress-lifecycle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('İlerleme %100'), findsOneWidget);
    expect(
      find.byKey(const Key('progress-living-plan-progress-lifecycle')),
      findsNothing,
    );

    await _scrollLivingPlanTo(
      tester,
      find.byKey(const Key('reopen-living-plan-progress-lifecycle')),
    );
    await tester.tap(
      find.byKey(const Key('reopen-living-plan-progress-lifecycle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    final reopenedEntries = fake.items
        .where((entry) => entry.item.id == 'progress-lifecycle')
        .toList(growable: false);
    expect(reopenedEntries, hasLength(1));
    final reopenedItem = reopenedEntries.single.item;
    expect(reopenedItem.status, ConstructionLivingPlanStatus.planned);
    expect(reopenedItem.progressPercent, isNull);
    expect(reopenedItem.plannedDate, DateTime.utc(2026, 8, 16));
    expect(reopenedItem.revision, 5);

    final reopenedCard = find.byKey(
      const Key('living-plan-item-progress-lifecycle'),
    );
    await _scrollLivingPlanTo(tester, reopenedCard);
    expect(reopenedCard, findsOneWidget);
    expect(
      find.descendant(of: reopenedCard, matching: find.text('Planlandı')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reopenedCard,
        matching: find.text('İlerleme girilmedi'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reopenedCard,
        matching: find.byKey(
          const Key('living-plan-progress-progress-lifecycle'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reopenedCard,
        matching: find.text('Progress korunmalı'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reopenedCard,
        matching: find.byKey(
          const Key('progress-living-plan-progress-lifecycle'),
        ),
      ),
      findsNothing,
    );
    expect(fake.mutationCalls, 4);
  });

  testWidgets(
    'system back after create reloads the parent and preserves Planda',
    (tester) async {
      final candidate = _candidate();
      final fake = _StrictDateLivingPlanApplication(
        suggestions: [candidate],
        searchResults: [candidate],
      );
      await _pumpPage(
        tester,
        agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
        livingPlan: fake,
      );

      await tester.tap(find.byKey(const Key('add-living-plan-item')));
      await tester.pumpAndSettle();
      expect(find.text('Bu haftaya önerilenler'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('living-plan-search')),
        'BETONAJ',
      );
      await tester.tap(find.byKey(const Key('living-plan-search-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Arama sonuçları'), findsOneWidget);
      expect(find.text('Beton Dökümü'), findsOneWidget);
      expect(find.text('Düşük güvenli test-seed önerisi'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-candidate-ACT-B@B-A')));
      await tester.pumpAndSettle();
      expect(find.text('Plan gününü belirle'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('confirm-add-candidate')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('select-candidate-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('18'));
      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('candidate-note-field')),
        'Kalıp kontrolünden sonra',
      );
      await tester.tap(find.byKey(const Key('confirm-add-candidate')));
      await tester.pumpAndSettle();

      expect(fake.createCalls, 1);
      expect(fake.lastCreateCommand?.note, 'Kalıp kontrolünden sonra');
      expect(fake.lastCreateCommand?.plannedDate, DateTime.utc(2026, 8, 18));
      expect(find.text('Planda'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('add-candidate-ACT-B@B-A')),
            )
            .onPressed,
        isNull,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final createdItemId = fake.lastCreateCommand!.itemId;
      await _scrollLivingPlanTo(
        tester,
        find.byKey(Key('living-plan-item-$createdItemId')),
      );
      expect(
        find.byKey(Key('living-plan-item-$createdItemId')),
        findsOneWidget,
      );

      await _scrollLivingPlanTo(
        tester,
        find.byKey(const Key('add-living-plan-item')),
      );
      await tester.tap(find.byKey(const Key('add-living-plan-item')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('living-plan-search')),
        'BETONAJ',
      );
      await tester.tap(find.byKey(const Key('living-plan-search-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Planda'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('add-candidate-ACT-B@B-A')),
            )
            .onPressed,
        isNull,
      );
      expect(fake.createCalls, 1);
    },
  );

  testWidgets(
    'post-create candidate refresh failure keeps durable success truthful',
    (tester) async {
      final candidate = _candidate();
      final fake = _PostCreateRefreshFailureLivingPlanApplication(
        suggestions: [candidate],
        searchResults: [candidate],
      );
      await _pumpPage(
        tester,
        agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
        livingPlan: fake,
      );

      await tester.tap(find.byKey(const Key('add-living-plan-item')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('living-plan-search')),
        'BETONAJ',
      );
      await tester.tap(find.byKey(const Key('living-plan-search-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-candidate-ACT-B@B-A')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('select-candidate-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('18'));
      await tester.tap(find.text('Tamam'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-add-candidate')));
      await tester.pumpAndSettle();

      expect(fake.createCalls, 1);
      expect(fake.postCreateRefreshFailures, 1);
      expect(
        find.text('İmalat plana eklendi; aday listesi yenilenemedi.'),
        findsOneWidget,
      );
      expect(find.text('İmalat eklenemedi; plan değişmedi.'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final createdItemId = fake.lastCreateCommand!.itemId;
      await _scrollLivingPlanTo(
        tester,
        find.byKey(Key('living-plan-item-$createdItemId')),
      );
      expect(
        find.byKey(Key('living-plan-item-$createdItemId')),
        findsOneWidget,
      );
      expect(fake.createCalls, 1);
    },
  );

  testWidgets('quick actions use revision commands and persist safe feedback', (
    tester,
  ) async {
    final fake = _StrictDateLivingPlanApplication(
      suggestions: [_candidate()],
      items: [
        _windowItem(
          id: 'planned',
          name: 'Beton Dökümü',
          date: DateTime.utc(2026, 8, 16),
          status: ConstructionLivingPlanStatus.planned,
        ),
        _windowItem(
          id: 'completed',
          name: 'Duvar İmalatı',
          date: DateTime.utc(2026, 8, 17),
          status: ConstructionLivingPlanStatus.completed,
        ),
      ],
    );
    await _pumpPage(
      tester,
      agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
      livingPlan: fake,
    );

    await tester.tap(find.byKey(const Key('start-living-plan-planned')));
    await tester.pumpAndSettle();
    expect(find.text('İmalat başlatıldı.'), findsOneWidget);
    expect(find.text('Başladı'), findsOneWidget);

    await tester.tap(find.byKey(const Key('note-living-plan-planned')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('living-plan-note-field')),
      'Vardiya teyit edildi',
    );
    await tester.tap(find.byKey(const Key('save-living-plan-note')));
    await tester.pumpAndSettle();
    expect(find.text('Vardiya teyit edildi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('complete-living-plan-planned')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reopen-living-plan-planned')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reopen-living-plan-planned')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('İmalat yeniden açıldı.'), findsOneWidget);
    expect(fake.reopenDates, [DateTime.utc(2026, 8, 16)]);

    await tester.tap(find.byKey(const Key('defer-living-plan-planned')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('İmalat ertelendi.'), findsOneWidget);
    expect(find.text('Ertelendi'), findsOneWidget);
    expect(fake.deferDates, [DateTime.utc(2026, 8, 17)]);
    expect(fake.mutationCalls, 5);
  });

  testWidgets('adjacent cards expose unique human-readable lifecycle semantics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      final fake = FakeLivingPlanApplication(
        suggestions: [_candidate()],
        items: [
          _windowItem(
            id: 'target-a',
            name: 'Mobilizasyon planı',
            date: DateTime.utc(2026, 8, 16),
            status: ConstructionLivingPlanStatus.planned,
          ),
          _windowItem(
            id: 'target-b',
            name: 'Mobilizasyon planı',
            date: DateTime.utc(2026, 8, 16),
            status: ConstructionLivingPlanStatus.planned,
          ),
        ],
      );
      await _pumpPage(
        tester,
        agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
        livingPlan: fake,
      );

      const contextLabel = 'Blok A • 2. kat • Kuzey cephe';
      const identityA =
          'Yaşayan plan öğesi · Mobilizasyon planı · $contextLabel · target-a';
      const identityB =
          'Yaşayan plan öğesi · Mobilizasyon planı · $contextLabel · target-b';
      final cardA = find.byKey(const Key('living-plan-item-target-a'));
      final cardB = find.byKey(const Key('living-plan-item-target-b'));
      final startA = find.bySemanticsLabel('$identityA · Eylem · Başlat');
      final startB = find.bySemanticsLabel('$identityB · Eylem · Başlat');

      expect(find.text('Başlat'), findsNWidgets(2));
      expect(startA, findsOneWidget);
      expect(startB, findsOneWidget);
      expect(find.descendant(of: cardA, matching: startA), findsOneWidget);
      expect(find.descendant(of: cardB, matching: startA), findsNothing);
      expect(find.descendant(of: cardB, matching: startB), findsOneWidget);
      expect(find.descendant(of: cardA, matching: startB), findsNothing);
      expect(
        find.bySemanticsLabel('$identityA · İlerleme · Raporlanmadı'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('$identityB · İlerleme · Raporlanmadı'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('living-plan-progress-target-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('living-plan-progress-target-b')),
        findsOneWidget,
      );

      await tester.tap(startA);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          '$identityA · Durum · Başladı · Kayıt sürümü · 2',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          '$identityB · Durum · Planlandı · Kayıt sürümü · 1',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('$identityA · Eylem · Başlat'),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('$identityB · Eylem · Başlat'),
        findsOneWidget,
      );
      expect(fake.mutationCalls, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'note dialog cancel back keyboard remove and double submit are safe',
    (tester) async {
      final fake = FakeLivingPlanApplication(
        suggestions: [_candidate()],
        items: [
          _windowItem(
            id: 'note-safe',
            name: 'Beton Dökümü',
            date: DateTime.utc(2026, 8, 16),
            status: ConstructionLivingPlanStatus.planned,
            note: 'Mevcut not',
          ),
        ],
      );
      await _pumpPage(
        tester,
        agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
        livingPlan: fake,
      );

      final noteAction = find.byKey(const Key('note-living-plan-note-safe'));
      await tester.tap(noteAction);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('living-plan-note-field')),
        'Kaydedilmemeli',
      );
      await tester.tap(find.byKey(const Key('cancel-living-plan-note')));
      await tester.pumpAndSettle();
      expect(fake.mutationCalls, 0);

      await tester.tap(noteAction);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(fake.mutationCalls, 0);

      await tester.tap(noteAction);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('living-plan-note-field')),
        '',
      );
      tester.testTextInput.hide();
      await tester.pump();
      final save = find.byKey(const Key('save-living-plan-note'));
      await tester.tap(save);
      await tester.tap(save, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(fake.mutationCalls, 1);
      expect(find.text('Not silindi.'), findsOneWidget);
      expect(find.text('Mevcut not'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stale revision reloads safely and duplicate taps stay guarded', (
    tester,
  ) async {
    final gate = Completer<void>();
    final fake = FakeLivingPlanApplication(
      suggestions: [_candidate()],
      items: [
        _windowItem(
          id: 'guarded',
          name: 'Beton Dökümü',
          date: DateTime.utc(2026, 8, 16),
          status: ConstructionLivingPlanStatus.planned,
        ),
      ],
    )..mutationGate = gate;
    await _pumpPage(
      tester,
      agenda: FakeAgendaApplication(projects: [_project('PRJ-A', 'A Blok')]),
      livingPlan: fake,
    );

    final start = find.byKey(const Key('start-living-plan-guarded'));
    await tester.tap(start);
    await tester.pump();
    await tester.tap(start, warnIfMissed: false);
    expect(fake.mutationCalls, 1);
    gate.complete();
    await tester.pumpAndSettle();

    fake.nextMutationFailure = const ConstructionLivingPlanFailure(
      'living_plan_stale_revision',
    );
    await tester.tap(find.byKey(const Key('complete-living-plan-guarded')));
    await tester.pumpAndSettle();
    expect(
      find.text('Kayıt başka bir işlemde değişti; plan yenilendi.'),
      findsOneWidget,
    );
    expect(find.textContaining('living_plan_stale_revision'), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required FakeAgendaApplication agenda,
  required FakeLivingPlanApplication livingPlan,
  ConstructionLivingPlanIntelligenceApplicationPort? intelligence,
  ThemeMode themeMode = ThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
  DateTime Function()? clock,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: CseApp.locale,
      supportedLocales: CseApp.supportedLocales,
      localizationsDelegates: CseApp.localizationsDelegates,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: LivingPlanPage(
        key: UniqueKey(),
        agenda: agenda,
        livingPlan: livingPlan,
        intelligence:
            intelligence ??
            const UnavailableConstructionLivingPlanIntelligenceApplication(),
        clock: clock ?? () => DateTime.utc(2026, 8, 16, 6),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeIntelligenceApplication
    implements ConstructionLivingPlanIntelligenceApplicationPort {
  _FakeIntelligenceApplication(this.values) : _failure = null;

  _FakeIntelligenceApplication.failure()
    : values = const {},
      _failure = StateError('synthetic intelligence read failure');

  final Map<String, ConstructionLivingPlanIntelligence> values;
  final Object? _failure;
  final List<DateTime> asOfDates = [];
  final List<List<String>> itemIds = [];

  @override
  Future<Map<String, ConstructionLivingPlanIntelligence>> loadForItems({
    required Iterable<ConstructionLivingPlanItem> items,
    required DateTime asOfDate,
  }) async {
    final source = items.toList(growable: false);
    asOfDates.add(asOfDate);
    itemIds.add(source.map((item) => item.id).toList(growable: false));
    if (_failure case final failure?) throw failure;
    final result = <String, ConstructionLivingPlanIntelligence>{};
    for (final item in source) {
      final intelligence = values[item.id];
      if (intelligence != null) result[item.id] = intelligence;
    }
    return Map.unmodifiable(result);
  }
}

ConstructionLivingPlanIntelligence _intelligenceFor(
  ConstructionLivingPlanItem item, {
  bool dependencyGraphUnavailable = false,
}) {
  final forecast = ConstructionLivingPlanForecast(
    itemId: item.id,
    projectId: item.projectId,
    referenceSnapshotId: item.referenceSnapshotId,
    activityInstanceId: item.activityInstanceId,
    status: item.status,
    progressPercent: item.progressPercent,
    asOfDate: DateTime.utc(2026, 8, 16),
    referenceStartDate: DateTime.utc(2026, 8, 10),
    referenceFinishDate: DateTime.utc(2026, 8, 21),
    referenceDurationDays: 10,
    referenceRoundedSchedulingDays: 10,
    referenceDurationCalendarType:
        ConstructionActivityDurationCalendarType.workingDay,
    referenceDurationStatus: ConstructionScheduleDurationStatus.aiSeedEstimate,
    referenceDurationConfidence: ConstructionScheduleDurationConfidence.aiSeed,
    referenceCorpusVersion: 'corpus-a',
    referenceScheduleSeedVersion: 'seed-a',
    referenceScheduleSeedProvenance: 'TEST',
    referenceProductionStatus: 'NOT_FOR_PRODUCTION',
    referenceDurationSource: 'TEST_SEED_ONLY',
    referenceBaselineStatus: 'NOT_A_BASELINE',
    referenceProjectionSha256: 'snapshot-sha',
    remainingDurationDays: 5.3,
    remainingRoundedSchedulingDays: 6,
    forecastFinishDate: DateTime.utc(2026, 8, 24),
    varianceCalendarDays: 3,
    basis: ConstructionLivingPlanForecastBasis.startedReferenceRemaining,
  );
  if (dependencyGraphUnavailable) {
    return ConstructionLivingPlanIntelligence(
      itemId: item.id,
      forecast: forecast,
      impactAvailability: ConstructionLivingPlanIntelligenceImpactAvailability
          .dependencyGraphUnavailable,
      dependencyImpact: null,
      impactedActivities: const [],
    );
  }
  final impact = ConstructionLivingPlanDependencyImpact(
    itemId: item.id,
    projectId: item.projectId,
    referenceSnapshotId: item.referenceSnapshotId,
    sourceActivityInstanceId: item.activityInstanceId,
    asOfDate: forecast.asOfDate,
    sourceReferenceStartDate: forecast.referenceStartDate,
    sourceReferenceFinishDate: forecast.referenceFinishDate,
    sourceForecastFinishDate: forecast.forecastFinishDate,
    sourceVarianceCalendarDays: forecast.varianceCalendarDays,
    propagatedPositiveSourceDelayCalendarDays: 3,
    dependencyProjectionSha256:
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    basis: ConstructionLivingPlanDependencyImpactBasis.downstreamDelayProjected,
    impactedActivities: [
      ConstructionLivingPlanDependencyImpactItem(
        activityInstanceId: 'successor@PRJ-A',
        activityId: 'successor',
        referenceStartDate: DateTime.utc(2026, 8, 22),
        referenceFinishDate: DateTime.utc(2026, 8, 24),
        projectedStartDate: DateTime.utc(2026, 8, 25),
        projectedFinishDate: DateTime.utc(2026, 8, 27),
        startShiftCalendarDays: 3,
        finishShiftCalendarDays: 3,
      ),
    ],
  );
  return ConstructionLivingPlanIntelligence(
    itemId: item.id,
    forecast: forecast,
    impactAvailability:
        ConstructionLivingPlanIntelligenceImpactAvailability.available,
    dependencyImpact: impact,
    impactedActivities: [
      ConstructionLivingPlanIntelligenceImpactActivity(
        activityInstanceId: 'successor@PRJ-A',
        activityId: 'successor',
        displayName: 'Radye kalıbı',
        projectedStartDate: DateTime.utc(2026, 8, 25),
        projectedFinishDate: DateTime.utc(2026, 8, 27),
        finishShiftCalendarDays: 3,
      ),
    ],
  );
}

class _StrictDateLivingPlanApplication extends FakeLivingPlanApplication {
  _StrictDateLivingPlanApplication({
    super.suggestions,
    super.searchResults,
    super.items,
  });

  final List<DateTime> planWindowStarts = [];
  final List<DateTime> suggestionWindowStarts = [];
  final List<DateTime> deferDates = [];
  final List<DateTime> reopenDates = [];

  @override
  Future<List<ConstructionLivingPlanWindowItem>> loadSevenDayPlan({
    required String projectId,
    required DateTime windowStart,
  }) {
    planWindowStarts.add(_requireCanonicalDate(windowStart));
    return super.loadSevenDayPlan(
      projectId: projectId,
      windowStart: windowStart,
    );
  }

  @override
  Future<List<ConstructionLivingPlanReferenceCandidate>>
  loadSevenDayReferenceSuggestions({
    required String projectId,
    required DateTime windowStart,
  }) {
    suggestionWindowStarts.add(_requireCanonicalDate(windowStart));
    return super.loadSevenDayReferenceSuggestions(
      projectId: projectId,
      windowStart: windowStart,
    );
  }

  @override
  Future<ConstructionLivingPlanItem> createLivingPlanItem(
    CreateConstructionLivingPlanItemCommand command,
  ) {
    _requireCanonicalDate(command.plannedDate);
    return super.createLivingPlanItem(command);
  }

  @override
  Future<ConstructionLivingPlanItem> deferLivingPlanItem(
    DeferConstructionLivingPlanItemCommand command,
  ) {
    deferDates.add(_requireCanonicalDate(command.plannedDate));
    return super.deferLivingPlanItem(command);
  }

  @override
  Future<ConstructionLivingPlanItem> reopenLivingPlanItem(
    ReopenConstructionLivingPlanItemCommand command,
  ) {
    reopenDates.add(_requireCanonicalDate(command.plannedDate));
    return super.reopenLivingPlanItem(command);
  }
}

class _PostCreateRefreshFailureLivingPlanApplication
    extends _StrictDateLivingPlanApplication {
  _PostCreateRefreshFailureLivingPlanApplication({
    super.suggestions,
    super.searchResults,
  });

  bool _failNextSearchRefresh = false;
  int postCreateRefreshFailures = 0;

  @override
  Future<ConstructionLivingPlanItem> createLivingPlanItem(
    CreateConstructionLivingPlanItemCommand command,
  ) async {
    final item = await super.createLivingPlanItem(command);
    _failNextSearchRefresh = true;
    return item;
  }

  @override
  Future<List<ConstructionLivingPlanReferenceCandidate>>
  searchCurrentReferenceCandidates({
    required String projectId,
    required String query,
    int limit = 50,
  }) {
    if (_failNextSearchRefresh) {
      _failNextSearchRefresh = false;
      postCreateRefreshFailures += 1;
      throw StateError('one-shot post-create candidate refresh failure');
    }
    return super.searchCurrentReferenceCandidates(
      projectId: projectId,
      query: query,
      limit: limit,
    );
  }
}

DateTime _requireCanonicalDate(DateTime value) {
  if (!value.isUtc ||
      value.hour != 0 ||
      value.minute != 0 ||
      value.second != 0 ||
      value.millisecond != 0 ||
      value.microsecond != 0) {
    throw const ConstructionLivingPlanFailure('living_plan_invalid_date');
  }
  return value;
}

Future<void> _scrollLivingPlanTo(WidgetTester tester, Finder target) async {
  final scrollable = find.descendant(
    of: find.byKey(const Key('living-plan-scroll')),
    matching: find.byType(Scrollable),
  );
  expect(scrollable, findsOneWidget);
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.minScrollExtent);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: scrollable,
    maxScrolls: 50,
  );
  await tester.pumpAndSettle();
}

MobileProject _project(String id, String name) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-08-16T06:00:00Z',
  updatedAt: '2026-08-16T06:00:00Z',
  revision: 1,
);

ConstructionLivingPlanReferenceCandidate _candidate() =>
    ConstructionLivingPlanReferenceCandidate(
      referenceSnapshotId: 'snapshot-a',
      projectId: 'PRJ-A',
      activityInstanceId: 'ACT-B@B-A',
      activityId: 'ACT-B',
      activityName: 'Beton Dökümü',
      activityContext: const ConstructionProjectActivityContext(
        blockId: 'A',
        floorIndex: 2,
        facadeElevation: 'NORTH',
      ),
      naturalUnit: 'm³',
      suggestedStartDate: DateTime.utc(2026, 8, 16),
      suggestedFinishDate: DateTime.utc(2026, 8, 17),
      durationStatus: ConstructionScheduleDurationStatus.aiSeedEstimate,
      durationConfidence: ConstructionScheduleDurationConfidence.aiSeed,
      activitySequence: 2,
      existingLivingPlanItemId: null,
      existingLivingPlanStatus: null,
    );

ConstructionLivingPlanWindowItem _windowItem({
  required String id,
  required String name,
  required DateTime date,
  required ConstructionLivingPlanStatus status,
  bool overdue = false,
  bool currentOrigin = true,
  String? note,
  int? progressPercent,
  int revision = 1,
}) {
  final now = DateTime.utc(2026, 8, 16, 6);
  return ConstructionLivingPlanWindowItem(
    item: ConstructionLivingPlanItem(
      id: id,
      projectId: 'PRJ-A',
      referenceSnapshotId: 'snapshot-a',
      activityInstanceId: 'instance-$id',
      activityId: 'activity-$id',
      activityNameSnapshot: name,
      activityContext: const ConstructionProjectActivityContext(
        blockId: 'A',
        floorIndex: 2,
        facadeElevation: 'NORTH',
      ),
      naturalUnitSnapshot: 'm²',
      plannedDate: date,
      status: status,
      progressPercent: progressPercent,
      note: note,
      revision: revision,
      createdAt: now,
      updatedAt: now,
      statusChangedAt: now,
    ),
    isOverdue: overdue,
    originSnapshotIsCurrent: currentOrigin,
  );
}
