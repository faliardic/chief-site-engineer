import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_destination_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_form_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const pourId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const truckId = 'ffffffff-ffff-4fff-8fff-fffffffffff1';
const attachmentId = 'ffffffff-ffff-4fff-8fff-fffffffffff2';
const concreteClassId = 'ffffffff-ffff-4fff-8fff-fffffffffff3';
const agendaLogId = 'ffffffff-ffff-4fff-8fff-fffffffffff4';
const project = MobileProject(
  id: projectId,
  name: 'Uzun Proje Adı',
  createdAt: '2026-07-19T07:00:00Z',
  updatedAt: '2026-07-19T07:00:00Z',
  revision: 1,
);
const secondProject = MobileProject(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaab',
  name: 'İkinci Proje',
  createdAt: '2026-07-19T07:00:00Z',
  updatedAt: '2026-07-19T07:00:00Z',
  revision: 1,
);
const concreteClass = ProjectConcreteClass(
  id: concreteClassId,
  projectId: projectId,
  displayName: 'C30/37',
  normalizedName: 'c30/37',
  defaultTargetSlump: 'S3',
  revision: 1,
  createdAt: '2026-07-19T07:00:00Z',
  updatedAt: '2026-07-19T07:00:00Z',
  archivedAt: null,
);

void main() {
  testWidgets(
    'Ajanda destination aynı proje ve İstanbul gününde Bugün grubunu açar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final concrete = _FakeConcrete();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: ConcreteDestinationPage(
              concrete: concrete,
              agenda: _FakeAgenda(),
              attachments: _picker(),
              initialProjectId: projectId,
              initialIstanbulDay: '2026-07-18',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beton paketleri'), findsOneWidget);
      expect(find.byKey(const Key('concrete-project-filter')), findsNothing);
      expect(find.byKey(const Key('concrete-day-filter')), findsOneWidget);
      expect(find.text('2026-07-18'), findsOneWidget);
      expect(concrete.lastListQuery?.projectId, projectId);
      expect(concrete.lastListQuery?.istanbulDay, '2026-07-18');
      expect(concrete.lastListQuery?.group, ConcretePourGroup.today);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Beton listesi 320 px ekranda filtreleri ve oluşturmayı gösterir',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final concrete = _FakeConcrete();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcretePage(
              concrete: concrete,
              agenda: _FakeAgenda(),
              attachments: _picker(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text('Yeni döküm'), findsOneWidget);
      expect(find.textContaining('BT-001'), findsOneWidget);
      expect(find.text('Bugün'), findsOneWidget);
      expect(find.byKey(const Key('concrete-project-filter')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('project command preserves date search and group filters', (
    tester,
  ) async {
    final concrete = _FakeConcrete();
    final selectedProjects = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConcretePage(
            concrete: concrete,
            agenda: _FakeAgenda(projects: const [project, secondProject]),
            attachments: _picker(),
            initialProjectId: project.id,
            initialIstanbulDay: '2026-07-19',
            onProjectSelected: selectedProjects.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Kod, mahal, blok, kat veya aks ara'),
      'KORUNAN ARAMA',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dökümde'));
    await tester.pumpAndSettle();
    final state = tester.state<ConcretePageState>(find.byType(ConcretePage));

    await state.selectProject(secondProject.id);
    await tester.pumpAndSettle();

    expect(selectedProjects, [secondProject.id]);
    expect(concrete.lastListQuery?.projectId, secondProject.id);
    expect(concrete.lastListQuery?.istanbulDay, '2026-07-19');
    expect(concrete.lastListQuery?.literalSearch, 'KORUNAN ARAMA');
    expect(concrete.lastListQuery?.group, ConcretePourGroup.inProgress);
    expect(find.byKey(const Key('concrete-project-filter')), findsNothing);
  });

  testWidgets(
    'Beton detail return keeps project group search and scroll with fresh card',
    (tester) async {
      tester.view.physicalSize = const Size(390, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pours = List.generate(24, _navigationPour);
      final concrete = _FakeConcrete(navigationPours: pours);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcretePage(
              concrete: concrete,
              agenda: _FakeAgenda(),
              attachments: _picker(),
              initialProjectId: projectId,
              initialIstanbulDay: '2026-07-19',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'CSE264 arama');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dökümde'));
      await tester.pumpAndSettle();

      final target = pours[18];
      final targetFinder = find.textContaining(target.pourCode);
      await tester.scrollUntilVisible(
        targetFinder,
        420,
        scrollable: _concreteScrollableFinder(),
      );
      final before = _concreteScrollOffset(tester);
      expect(before, greaterThan(300));

      await tester.tap(targetFinder);
      await tester.pumpAndSettle();
      concrete.navigationPours = [
        for (var index = 0; index < pours.length; index++)
          index == 18
              ? _navigationPour(index, pourCode: 'CSE264-GUNCEL')
              : pours[index],
      ];
      final delayedReload = Completer<List<ConcretePour>>();
      concrete.delayedListReload = delayedReload;
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 350));
      delayedReload.complete(concrete.navigationPours!);
      await tester.pumpAndSettle();

      expect(_concreteScrollOffset(tester), closeTo(before, 4));
      expect(concrete.lastListQuery?.projectId, projectId);
      expect(concrete.lastListQuery?.group, ConcretePourGroup.inProgress);
      expect(concrete.lastListQuery?.istanbulDay, '2026-07-19');
      expect(concrete.lastListQuery?.literalSearch, 'CSE264 arama');
      expect(find.textContaining('CSE264-GUNCEL'), findsOneWidget);
      tester
          .state<ScrollableState>(_concreteScrollableFinder())
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'CSE264 arama',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Beton detail double tap opens one route and controller disposes',
    (tester) async {
      final concrete = _FakeConcrete(navigationPours: [_navigationPour(18)]);
      final observer = _ConcretePushCountingObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Scaffold(
            body: ConcretePage(
              concrete: concrete,
              agenda: _FakeAgenda(),
              attachments: _picker(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      observer.pushes = 0;
      final card = find.textContaining('CSE264-BT-018');

      final onTap = tester
          .widget<ListTile>(
            find.ancestor(of: card, matching: find.byType(ListTile)),
          )
          .onTap!;
      onTap();
      onTap();
      await tester.pumpAndSettle();

      expect(observer.pushes, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'oluşturma formu validation girdisini korur ve çift dokunma tek komuttur',
    (tester) async {
      final concrete = _FakeConcrete(delayCreate: true);
      await tester.pumpWidget(
        MaterialApp(
          home: ConcretePourFormPage(
            concrete: concrete,
            projects: const [project],
          ),
        ),
      );
      final codeField = find.widgetWithText(
        TextFormField,
        'Döküm kodu (boşsa otomatik üretilir)',
      );
      await tester.enterText(codeField, 'BT-187');
      final createButton = find.widgetWithText(
        FilledButton,
        'Beton paketini oluştur',
      );
      final formScrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          )
          .first;
      await tester.scrollUntilVisible(
        createButton,
        300,
        scrollable: formScrollable,
      );
      tester.widget<FilledButton>(createButton).onPressed!();
      await tester.pump();
      await tester.scrollUntilVisible(
        codeField,
        -300,
        scrollable: formScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('BT-187'), findsOneWidget);
      expect(find.text('Eleman / yer tarifi zorunludur.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Eleman / yer tarifi'),
        -300,
        scrollable: formScrollable,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Eleman / yer tarifi'),
        'KOLON A1',
      );
      await tester.tap(find.byKey(const Key('concrete-class-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('C30/37').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Planlanan metraj (m³)'),
        '20',
      );
      tester.testTextInput.hide();
      await tester.pump();
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Beton paketini oluştur'),
      );
      saveButton.onPressed!();
      saveButton.onPressed!();
      await tester.pump();
      expect(concrete.createCalls, 1);
      expect(concrete.lastCreateCommand!.targetSlump, 'S3');
      concrete.completeCreate();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'detay ekranı checklist mikser kanıt numune takip ve timeline sunar',
    (tester) async {
      final concrete = _FakeConcrete();
      await tester.pumpWidget(
        MaterialApp(
          home: ConcretePourDetailPage(
            concrete: concrete,
            agenda: _FakeAgenda(),
            attachments: _picker(),
            pourId: pourId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Hedef: 20,00 m³'), findsOneWidget);
      expect(find.textContaining('Dökülen: 12,50 m³'), findsOneWidget);
      expect(find.textContaining('Kalan: 7,50 m³'), findsOneWidget);
      for (final text in [
        'Döküm öncesi checklist',
        'Manuel maddeleri tamamla',
        'Mikser / irsaliye',
        'Kanıtlar',
        'Numuneler',
        'Takipler / Hatırlatıcılar',
        'Zaman çizelgesi',
        'PDF paylaş',
        'Telefona kaydet',
      ]) {
        final finder = find.textContaining(text);
        await tester.scrollUntilVisible(finder, 300);
        expect(finder, findsOneWidget);
      }
      await tester.scrollUntilVisible(
        find.text('İrsaliye taraması'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      final attachmentTile = find.ancestor(
        of: find.text('İrsaliye taraması'),
        matching: find.byType(ListTile),
      );
      tester.widget<ListTile>(attachmentTile).onTap!();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('concrete-full-image')), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('form içinden yeni proje Beton sınıfı eklenip seçilir', (
    tester,
  ) async {
    final concrete = _FakeConcrete();
    await tester.pumpWidget(
      MaterialApp(
        home: ConcretePourFormPage(
          concrete: concrete,
          projects: const [project],
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<TextButton>(find.byKey(const Key('add-concrete-class')))
        .onPressed!();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('new-concrete-class-name')),
      'C35/45',
    );
    await tester.tap(find.byKey(const Key('save-concrete-class')));
    await tester.pumpAndSettle();
    expect(concrete.createClassCalls, 1);
    expect(concrete.lastCreateClassCommand!.projectId, projectId);
    expect(concrete.lastCreateClassCommand!.displayName, 'C35/45');
    expect(find.text('C35/45'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'three-stage timeline drives start finish and Agenda deep-link safely',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final concrete = _FakeConcrete(agendaLinked: true, checklistReady: true);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: ConcretePourDetailPage(
              concrete: concrete,
              agenda: _FakeAgenda(),
              attachments: _picker(),
              pourId: pourId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Planlandı'), findsOneWidget);
      final start = find.byKey(const Key('start-concrete-pour'));
      expect(tester.getSize(start).height, greaterThanOrEqualTo(44));
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.text('Devam ediyor'), findsOneWidget);
      expect(find.byKey(const Key('start-concrete-pour')), findsNothing);
      expect(find.byKey(const Key('finish-concrete-pour')), findsOneWidget);
      expect(find.byKey(const Key('concrete-actual-start')), findsOneWidget);

      await tester.tap(find.byKey(const Key('finish-concrete-pour')));
      await tester.pumpAndSettle();
      expect(find.text('Tamamlandı'), findsOneWidget);
      expect(find.byKey(const Key('finish-concrete-pour')), findsNothing);
      expect(find.byKey(const Key('concrete-actual-end')), findsOneWidget);
      expect(find.textContaining('30 dk'), findsOneWidget);
      tester
          .widget<OutlinedButton>(find.byKey(const Key('open-managed-agenda')))
          .onPressed!();
      await tester.pumpAndSettle();
      expect(find.byType(LogDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reopened started draft resumes without replacing its first timestamp',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final concrete = _FakeConcrete(
        started: true,
        status: ConcretePourStatus.draft,
        agendaLinked: true,
        checklistReady: true,
      );
      final firstStartedAt = concrete._currentDetail.pour.actualStartedAt;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: ConcretePourDetailPage(
              concrete: concrete,
              agenda: _FakeAgenda(),
              attachments: _picker(),
              pourId: pourId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Devam ediyor'), findsOneWidget);
      expect(find.byKey(const Key('start-concrete-pour')), findsNothing);
      final resume = find.byKey(const Key('resume-concrete-pour'));
      expect(resume, findsOneWidget);
      expect(tester.getSize(resume).height, greaterThanOrEqualTo(44));

      await tester.tap(resume);
      await tester.pumpAndSettle();
      expect(
        concrete.lastTransitionCommand!.targetStatus,
        ConcretePourStatus.pouring,
      );
      expect(concrete._currentDetail.pour.actualStartedAt, firstStartedAt);
      expect(find.byKey(const Key('resume-concrete-pour')), findsNothing);
      expect(find.byKey(const Key('finish-concrete-pour')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('historical reopened pour with an end never offers resume', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final concrete = _FakeConcrete(
      started: true,
      ended: true,
      status: ConcretePourStatus.draft,
      agendaLinked: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: ConcretePourDetailPage(
            concrete: concrete,
            agenda: _FakeAgenda(),
            attachments: _picker(),
            pourId: pourId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tamamlandı'), findsOneWidget);
    expect(find.byKey(const Key('resume-concrete-pour')), findsNothing);
    expect(find.byKey(const Key('start-concrete-pour')), findsNothing);
    expect(find.byKey(const Key('finish-concrete-pour')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'legacy null irsaliyeli mikser edit reverse animation boyunca güvenlidir',
    (tester) async {
      final concrete = _FakeConcrete();
      await _pumpDetail(tester, concrete);
      await _openExistingTruck(tester);

      final deliveryNote = tester.widget<TextField>(
        find.byKey(const Key('concrete-truck-delivery-note')),
      );
      expect(deliveryNote.controller!.text, isEmpty);
      await tester.enterText(
        find.byKey(const Key('concrete-truck-plate')),
        '34 CSE 200',
      );
      await tester.enterText(
        find.byKey(const Key('concrete-truck-delivery-note')),
        'IRS-200',
      );
      await tester.enterText(
        find.byKey(const Key('concrete-truck-volume')),
        '15,75',
      );
      await tester.enterText(
        find.byKey(const Key('concrete-truck-note')),
        'Lifecycle güvenli',
      );

      final save = find.byKey(const Key('save-concrete-truck'));
      final saveCallback = tester.widget<FilledButton>(save).onPressed!;
      saveCallback();
      saveCallback();
      await _pumpReverseTransition(tester);

      expect(tester.takeException(), isNull);
      expect(concrete.saveTruckCalls, 1);
      expect(concrete.lastTruckCommand!.deliveryNoteNumber, 'IRS-200');
      expect(concrete.lastTruckCommand!.arrivedAt, '2026-07-19T09:10:00Z');
      expect(
        concrete.lastTruckCommand!.unloadingStartedAt,
        '2026-07-19T09:15:00Z',
      );
      expect(
        concrete.lastTruckCommand!.unloadingEndedAt,
        '2026-07-19T09:30:00Z',
      );
      expect(find.textContaining('#1 34 CSE 200 • 15.75 m³'), findsOneWidget);
      expect(find.textContaining('Lifecycle güvenli'), findsOneWidget);
      expect(find.textContaining('Revizyon 2'), findsOneWidget);
    },
  );

  testWidgets(
    'yeni mikser reason toggle ve double tap tek güvenli mutation üretir',
    (tester) async {
      final concrete = _FakeConcrete();
      await _pumpDetail(tester, concrete);
      await tester.scrollUntilVisible(find.text('Mikser ekle'), 300);
      await tester.tap(find.text('Mikser ekle'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('concrete-truck-plate')),
        '34 NEW 200',
      );
      await tester.enterText(
        find.byKey(const Key('concrete-truck-volume')),
        '7.25',
      );
      await tester.tap(find.byKey(const Key('concrete-truck-result')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bekletildi').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('concrete-truck-reason')), findsOneWidget);
      await tester.tap(find.byKey(const Key('concrete-truck-result')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teslim alındı').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('concrete-truck-reason')), findsNothing);
      await tester.tap(find.byKey(const Key('concrete-truck-result')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bekletildi').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('concrete-truck-reason')),
        'Saha kontrolü bekleniyor',
      );

      final save = find.byKey(const Key('save-concrete-truck'));
      final saveCallback = tester.widget<FilledButton>(save).onPressed!;
      saveCallback();
      saveCallback();
      await _pumpReverseTransition(tester);

      expect(tester.takeException(), isNull);
      expect(concrete.saveTruckCalls, 1);
      expect(concrete.lastTruckCommand!.result, ConcreteTruckResult.held);
      expect(concrete.lastTruckCommand!.reason, 'Saha kontrolü bekleniyor');
      expect(concrete.lastTruckCommand!.arrivedAt, isNotNull);
      expect(find.textContaining('34 NEW 200 • 7.25 m³'), findsOneWidget);
    },
  );

  testWidgets(
    'mikser dialog cancel mutation çağırmaz ve lifecycle güvenlidir',
    (tester) async {
      final concrete = _FakeConcrete();
      await _pumpDetail(tester, concrete);
      await _openExistingTruck(tester);

      await tester.tap(find.text('Vazgeç'));
      await _pumpReverseTransition(tester);

      expect(concrete.saveTruckCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'save failure immutable mikser girdisini yeniden açılabilir tutar',
    (tester) async {
      final concrete = _FakeConcrete(failNextTruckSave: true);
      await _pumpDetail(tester, concrete);
      await _openExistingTruck(tester);
      await tester.enterText(
        find.byKey(const Key('concrete-truck-plate')),
        '34 RETRY 200',
      );
      await tester.tap(find.byKey(const Key('save-concrete-truck')));
      await _pumpReverseTransition(tester);

      expect(concrete.saveTruckCalls, 1);
      expect(
        find.byKey(const Key('reopen-concrete-truck-draft')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('reopen-concrete-truck-draft')));
      await tester.pumpAndSettle();
      final plate = tester.widget<TextField>(
        find.byKey(const Key('concrete-truck-plate')),
      );
      expect(plate.controller!.text, '34 RETRY 200');
      await tester.tap(find.text('Vazgeç'));
      await _pumpReverseTransition(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'synthetic checklist shows exact blockers then reloads zero and starts',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final concrete = _FakeConcrete(
        delayBulkComplete: true,
        delayFieldUpdate: true,
        agendaLinked: true,
      );

      Widget page() => MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: ConcretePourDetailPage(
            concrete: concrete,
            agenda: _FakeAgenda(),
            attachments: _picker(),
            pourId: pourId,
          ),
        ),
      );

      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      final detailScrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          )
          .first;
      await tester.tap(find.byKey(const Key('start-concrete-pour')));
      await tester.pumpAndSettle();
      for (final blocker in [
        'Döküm mahali hazır',
        'Yapı denetim bilgilendirildi',
        'Laboratuvar randevusu alındı',
      ]) {
        expect(find.textContaining(blocker), findsWidgets);
      }

      final threeOpen = find.text('Döküm öncesi checklist • 3 açık');
      await tester.scrollUntilVisible(
        threeOpen,
        300,
        scrollable: detailScrollable,
      );
      expect(threeOpen, findsOneWidget);
      final bulkComplete = find.byKey(const Key('bulk-complete-concrete'));
      await tester.ensureVisible(bulkComplete);
      await tester.pumpAndSettle();
      await tester.tap(bulkComplete);
      await tester.pumpAndSettle();
      expect(find.text('Manuel maddeleri tamamla'), findsNWidgets(3));
      expect(
        find.textContaining(
          'Laboratuvar randevusu ve yapı denetim bildirimi ayrıca',
        ),
        findsOneWidget,
      );

      final confirm = tester
          .widget<FilledButton>(find.byKey(const Key('confirm-bulk-complete')))
          .onPressed!;
      confirm();
      confirm();
      await tester.pump();
      expect(concrete.bulkCompleteCalls, 1);
      expect(find.text('Döküm öncesi checklist • 3 açık'), findsOneWidget);

      concrete.completeBulk();
      await tester.pumpAndSettle();
      expect(find.text('Döküm öncesi checklist • 2 açık'), findsOneWidget);
      for (final action in [
        'Laboratuvar randevusunu güncelle',
        'Yapı denetime bildirimi güncelle',
      ]) {
        final finder = find.text(action);
        await tester.scrollUntilVisible(
          finder,
          200,
          scrollable: detailScrollable,
        );
        expect(finder, findsOneWidget);
      }

      final laboratoryAction = find.text('Laboratuvar randevusunu güncelle');
      await tester.ensureVisible(laboratoryAction);
      await tester.drag(detailScrollable, const Offset(0, 120));
      await tester.pumpAndSettle();
      await tester.tap(laboratoryAction);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('laboratory-appointment-complete')),
      );
      await tester.tap(
        find.byKey(const Key('inspection-notification-complete')),
      );
      final save = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Kaydet'))
          .onPressed!;
      save();
      save();
      await tester.pump();
      expect(concrete.fieldUpdateCalls, 1);
      expect(find.text('Döküm öncesi checklist • 2 açık'), findsOneWidget);

      concrete.completeFieldUpdate();
      await tester.pumpAndSettle();
      expect(find.text('Döküm öncesi checklist • 0 açık'), findsOneWidget);

      final start = find.byKey(const Key('start-concrete-pour'));
      await tester.scrollUntilVisible(
        start,
        -300,
        scrollable: detailScrollable,
      );
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      final finish = find.byKey(const Key('finish-concrete-pour'));
      expect(finish, findsOneWidget);
      await tester.ensureVisible(finish);
      await tester.pumpAndSettle();
      await tester.tap(finish);
      await tester.pumpAndSettle();
      expect(find.text('Tamamlandı'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('concrete-actual-end')), findsOneWidget);
      expect(concrete._currentDetail.pendingRequiredCheckCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpDetail(WidgetTester tester, _FakeConcrete concrete) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ConcretePourDetailPage(
        concrete: concrete,
        agenda: _FakeAgenda(),
        attachments: _picker(),
        pourId: pourId,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openExistingTruck(WidgetTester tester) async {
  final truck = find.textContaining('#1 34 CSE 196');
  await tester.scrollUntilVisible(
    truck,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(truck);
  await tester.pump();
  await tester.tap(truck);
  await tester.pumpAndSettle();
  expect(find.text('Mikseri düzenle'), findsOneWidget);
}

Future<void> _pumpReverseTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

double _concreteScrollOffset(WidgetTester tester) {
  return tester
      .state<ScrollableState>(_concreteScrollableFinder())
      .position
      .pixels;
}

Finder _concreteScrollableFinder() => find
    .descendant(
      of: find.byKey(const Key('concrete-page')),
      matching: find.byType(Scrollable),
    )
    .first;

ConcretePour _navigationPour(int index, {String? pourCode}) => ConcretePour(
  id: index == 18
      ? pourId
      : 'bbbbbbbb-bbbb-4bbb-8bbb-${(index + 100).toString().padLeft(12, '0')}',
  projectId: projectId,
  projectName: project.name,
  pourCode: pourCode ?? 'CSE264-BT-${index.toString().padLeft(3, '0')}',
  elementLocation: 'CSE264 mahal ${index + 1}',
  blockName: 'A',
  floorName: '${index + 1}',
  axisName: 'A/${index + 1}',
  plannedAt: '2026-07-19T09:00:00Z',
  actualStartedAt: null,
  actualEndedAt: null,
  concreteClass: 'C30/37',
  targetSlump: null,
  plannedVolumeM3: 20,
  orderedVolumeM3: null,
  plantName: null,
  plantBranch: null,
  plantContact: null,
  plantAppointmentReference: null,
  pumpEquipment: null,
  laboratoryName: null,
  laboratoryContact: null,
  laboratoryAppointment: null,
  inspectionNotifiedAt: null,
  inspectionNotifiedPerson: null,
  status: ConcretePourStatus.draft,
  generalNote: null,
  sampleExceptionReason: null,
  varianceNote: null,
  revision: 1,
  createdAt: '2026-07-19T07:00:00Z',
  updatedAt: '2026-07-19T07:00:00Z',
  closedAt: null,
  cancelledAt: null,
);

class _ConcretePushCountingObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes += 1;
    super.didPush(route, previousRoute);
  }
}

SafeAttachmentPicker _picker() => SafeAttachmentPicker(
  permissions: SafeCapabilityService(_GrantedPermission()),
  picker: _EmptyPicker(),
);

class _GrantedPermission implements PermissionGateway {
  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.granted;
}

class _EmptyPicker implements AttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async => null;
}

class _FakeConcrete implements ConcreteApplication {
  _FakeConcrete({
    this.delayCreate = false,
    this.failNextTruckSave = false,
    this.delayBulkComplete = false,
    this.delayFieldUpdate = false,
    this.started = false,
    this.ended = false,
    this.navigationPours,
    bool checklistReady = false,
    ConcretePourStatus? status,
    this.agendaLinked = false,
  }) : manualCompleted = checklistReady,
       laboratoryComplete = checklistReady,
       inspectionComplete = checklistReady,
       status =
           status ??
           (ended
               ? ConcretePourStatus.poured
               : started
               ? ConcretePourStatus.pouring
               : ConcretePourStatus.draft);
  final bool delayCreate;
  final bool delayBulkComplete;
  final bool delayFieldUpdate;
  bool failNextTruckSave;
  bool started;
  bool ended;
  bool manualCompleted;
  bool laboratoryComplete;
  bool inspectionComplete;
  ConcretePourStatus status;
  final bool agendaLinked;
  List<ConcretePour>? navigationPours;
  Completer<List<ConcretePour>>? delayedListReload;
  final _completer = Completer<ConcretePourDetail>();
  Completer<void>? _bulkCompleter;
  Completer<void>? _fieldCompleter;
  int revision = 1;
  int createCalls = 0;
  int createClassCalls = 0;
  int saveTruckCalls = 0;
  int bulkCompleteCalls = 0;
  int fieldUpdateCalls = 0;
  CreateConcretePourCommand? lastCreateCommand;
  CreateProjectConcreteClassCommand? lastCreateClassCommand;
  SaveConcreteTruckCommand? lastTruckCommand;
  TransitionConcretePourCommand? lastTransitionCommand;
  ConcretePourQuery? lastListQuery;

  ConcretePourDetail get _currentDetail => _detail(
    lastTruckCommand,
    started: started,
    ended: ended,
    status: status,
    agendaLinked: agendaLinked,
    revision: revision,
    manualCompleted: manualCompleted,
    laboratoryComplete: laboratoryComplete,
    inspectionComplete: inspectionComplete,
  );

  void completeCreate() {
    if (!_completer.isCompleted) _completer.complete(_currentDetail);
  }

  void completeBulk() => _bulkCompleter?.complete();

  void completeFieldUpdate() => _fieldCompleter?.complete();

  @override
  Future<ConcretePourDetail> createPour(CreateConcretePourCommand command) {
    createCalls += 1;
    lastCreateCommand = command;
    return delayCreate ? _completer.future : Future.value(_currentDetail);
  }

  @override
  Future<List<ProjectConcreteClass>> listConcreteClasses(
    String projectId, {
    bool includeArchived = false,
  }) async => [
    ProjectConcreteClass(
      id: concreteClass.id,
      projectId: projectId,
      displayName: concreteClass.displayName,
      normalizedName: concreteClass.normalizedName,
      defaultTargetSlump: concreteClass.defaultTargetSlump,
      revision: concreteClass.revision,
      createdAt: concreteClass.createdAt,
      updatedAt: concreteClass.updatedAt,
      archivedAt: null,
    ),
  ];

  @override
  Future<ProjectConcreteClass> createConcreteClass(
    CreateProjectConcreteClassCommand command,
  ) async {
    createClassCalls += 1;
    lastCreateClassCommand = command;
    return ProjectConcreteClass(
      id: command.id,
      projectId: command.projectId,
      displayName: command.displayName,
      normalizedName: command.displayName.toLowerCase(),
      defaultTargetSlump: command.defaultTargetSlump,
      revision: 1,
      createdAt: '2026-07-19T07:00:00Z',
      updatedAt: '2026-07-19T07:00:00Z',
      archivedAt: null,
    );
  }

  @override
  Future<ProjectConcreteClass> mutateConcreteClassArchive(
    MutateProjectConcreteClassArchiveCommand command,
  ) => throw UnimplementedError();

  @override
  Future<ConcretePourDetail> getPourDetail(String pourId) async =>
      _currentDetail;

  @override
  Future<List<ConcretePour>> listPours(ConcretePourQuery query) async {
    lastListQuery = query;
    final delayed = delayedListReload;
    if (delayed != null) {
      delayedListReload = null;
      return delayed.future;
    }
    return navigationPours ?? [_currentDetail.pour];
  }

  @override
  Future<ConcretePourDetail> attachEvidence(
    AttachConcreteEvidenceCommand command,
  ) => throw UnimplementedError();
  @override
  Future<ConcretePourDetail> bulkComplete(
    BulkCompleteConcreteCommand command,
  ) async {
    bulkCompleteCalls += 1;
    if (delayBulkComplete) {
      _bulkCompleter ??= Completer<void>();
      await _bulkCompleter!.future;
    }
    manualCompleted = true;
    revision += 1;
    return _currentDetail;
  }

  @override
  Future<ConcreteExportResult> exportPackage(
    ExportConcretePackageCommand command, {
    bool share = false,
    bool save = false,
  }) => throw UnimplementedError();
  @override
  Future<StoredAttachmentContent> readAttachment(String attachmentId) =>
      Future.value(
        const StoredAttachmentContent(
          fileName: 'irsaliye.jpg',
          mimeType: 'image/jpeg',
          bytes: [0xff, 0xd8, 0xff, 0xd9],
        ),
      );
  @override
  Future<void> openAttachment(String attachmentId) =>
      throw UnimplementedError();
  @override
  Future<ConcretePourDetail> saveSampleSet(
    SaveConcreteSampleSetCommand command,
  ) => throw UnimplementedError();
  @override
  Future<ConcretePourDetail> saveTruck(SaveConcreteTruckCommand command) async {
    saveTruckCalls += 1;
    if (failNextTruckSave) {
      failNextTruckSave = false;
      throw const AgendaValidationFailure(
        'Mikser revision değişti; kaydı yeniden kontrol edin.',
      );
    }
    lastTruckCommand = command;
    return _currentDetail;
  }

  @override
  Future<ConcretePourDetail> transitionPour(
    TransitionConcretePourCommand command,
  ) async {
    lastTransitionCommand = command;
    if ((command.targetStatus == ConcretePourStatus.prepared ||
            command.targetStatus == ConcretePourStatus.pouring) &&
        _currentDetail.pendingRequiredChecks.isNotEmpty) {
      throw AgendaValidationFailure(
        'Dökümü başlatmak için açık zorunlu kalemler: '
        '${_currentDetail.pendingRequiredChecks.map((item) => item.label).join(', ')}.',
      );
    }
    status = command.targetStatus;
    if (command.targetStatus == ConcretePourStatus.pouring) {
      started = true;
    }
    if (command.targetStatus == ConcretePourStatus.poured) {
      ended = true;
    }
    revision += 1;
    return _currentDetail;
  }

  @override
  Future<ConcretePourDetail> repairManagedAgenda(
    RepairConcreteAgendaCommand command,
  ) => throw UnimplementedError();
  @override
  Future<ConcretePourDetail> updateCheck(UpdateConcreteCheckCommand command) =>
      throw UnimplementedError();
  @override
  Future<ConcretePourDetail> updateFollowUp(
    UpdateConcreteFollowUpCommand command,
  ) => throw UnimplementedError();
  @override
  Future<ConcretePourDetail> updatePour(
    UpdateConcretePourCommand command,
  ) async {
    fieldUpdateCalls += 1;
    if (delayFieldUpdate) {
      _fieldCompleter ??= Completer<void>();
      await _fieldCompleter!.future;
    }
    laboratoryComplete =
        command.laboratoryAppointment?.trim().isNotEmpty ?? false;
    inspectionComplete =
        command.inspectionNotifiedAt != null ||
        (command.inspectionNotifiedPerson?.trim().isNotEmpty ?? false);
    revision += 1;
    return _currentDetail;
  }
}

class _FakeAgenda implements AgendaApplication {
  _FakeAgenda({this.projects = const [project]});

  final List<MobileProject> projects;

  @override
  Stream<void> get projectChanges => const Stream<void>.empty();

  @override
  Future<List<MobileProject>> listProjects() async => projects;

  @override
  Future<AgendaLogDetail> getAgendaLogDetail(String logId) async =>
      AgendaLogDetail(
        log: AgendaLog(
          id: logId,
          projectId: projectId,
          projectName: project.name,
          observedAt: '2026-07-19T09:00:00Z',
          createdAt: '2026-07-19T09:00:00Z',
          updatedAt: '2026-07-19T09:00:00Z',
          category: AgendaCategory.concrete,
          description: 'BT-001 • KOLON A1 • C30/37',
          location: 'KOLON A1',
          notes: 'Beton paketi tarafından yönetiliyor.',
          revision: 1,
        ),
        reminders: const [],
        managedConcretePourId: pourId,
      );

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ConcretePourDetail _detail(
  SaveConcreteTruckCommand? savedTruck, {
  bool started = false,
  bool ended = false,
  ConcretePourStatus? status,
  bool agendaLinked = false,
  int revision = 1,
  bool manualCompleted = false,
  bool laboratoryComplete = false,
  bool inspectionComplete = false,
}) {
  final pour = ConcretePour(
    id: pourId,
    projectId: projectId,
    projectName: 'Uzun Proje Adı',
    pourCode: 'BT-001',
    elementLocation: 'KOLON A1',
    blockName: 'A',
    floorName: '1',
    axisName: 'A/1',
    plannedAt: '2026-07-19T09:00:00Z',
    actualStartedAt: started ? '2026-07-19T09:00:00Z' : null,
    actualEndedAt: ended ? '2026-07-19T09:30:00Z' : null,
    concreteClass: 'C30/37',
    targetSlump: null,
    plannedVolumeM3: 20,
    orderedVolumeM3: null,
    plantName: null,
    plantBranch: null,
    plantContact: null,
    plantAppointmentReference: null,
    pumpEquipment: null,
    laboratoryName: null,
    laboratoryContact: null,
    laboratoryAppointment: laboratoryComplete ? '2026-07-19T08:00:00Z' : null,
    inspectionNotifiedAt: inspectionComplete ? '2026-07-19T07:30:00Z' : null,
    inspectionNotifiedPerson: null,
    status:
        status ??
        (ended
            ? ConcretePourStatus.poured
            : started
            ? ConcretePourStatus.pouring
            : ConcretePourStatus.draft),
    generalNote: null,
    sampleExceptionReason: null,
    varianceNote: null,
    revision: savedTruck == null ? revision : revision + 1,
    createdAt: '2026-07-19T07:00:00Z',
    updatedAt: '2026-07-19T07:00:00Z',
    closedAt: null,
    cancelledAt: null,
  );
  final checks = [
    ConcreteCheckItem(
      id: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
      pourId: pourId,
      itemKey: 'location_ready',
      label: 'Döküm mahali hazır',
      sortOrder: 1,
      isRequired: true,
      status: manualCompleted
          ? ConcreteCheckStatus.completed
          : ConcreteCheckStatus.pending,
      note: null,
      reason: null,
      revision: manualCompleted ? 2 : 1,
      updatedAt: '2026-07-19T07:00:00Z',
    ),
    ConcreteCheckItem(
      id: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2',
      pourId: pourId,
      itemKey: concreteInspectionNotifiedCheckKey,
      label: 'Yapı denetim bilgilendirildi',
      sortOrder: 2,
      isRequired: true,
      status: inspectionComplete
          ? ConcreteCheckStatus.completed
          : ConcreteCheckStatus.pending,
      note: null,
      reason: null,
      revision: inspectionComplete ? 2 : 1,
      updatedAt: '2026-07-19T07:00:00Z',
    ),
    ConcreteCheckItem(
      id: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc3',
      pourId: pourId,
      itemKey: concreteLaboratoryAppointmentCheckKey,
      label: 'Laboratuvar randevusu alındı',
      sortOrder: 3,
      isRequired: true,
      status: laboratoryComplete
          ? ConcreteCheckStatus.completed
          : ConcreteCheckStatus.pending,
      note: null,
      reason: null,
      revision: laboratoryComplete ? 2 : 1,
      updatedAt: '2026-07-19T07:00:00Z',
    ),
  ];
  final follow = ConcreteFollowUp(
    id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    pourId: pourId,
    sourceSampleSetId: null,
    itemKey: 'curing_start',
    label: 'Kür başlangıcı',
    dueAt: '2026-07-19T11:00:00Z',
    status: manualCompleted
        ? ConcreteFollowUpStatus.completed
        : ConcreteFollowUpStatus.pending,
    reminderId: null,
    note: null,
    reason: null,
    revision: manualCompleted ? 2 : 1,
    createdAt: '2026-07-19T07:00:00Z',
    updatedAt: '2026-07-19T07:00:00Z',
    completedAt: manualCompleted ? '2026-07-19T07:00:00Z' : null,
  );
  const truck = ConcreteTruck(
    id: truckId,
    pourId: pourId,
    sequenceNo: 1,
    vehiclePlate: '34 CSE 196',
    deliveryNoteNumber: null,
    plantSnapshot: 'Güven Beton',
    batchTime: null,
    arrivedAt: '2026-07-19T09:10:00Z',
    unloadingStartedAt: '2026-07-19T09:15:00Z',
    unloadingEndedAt: '2026-07-19T09:30:00Z',
    volumeM3: 12.5,
    measuredSlump: null,
    concreteTemperature: null,
    result: ConcreteTruckResult.received,
    reason: null,
    note: 'İrsaliye numarası sonra girilecek.',
    evidenceExceptionReason: null,
    revision: 1,
    createdAt: '2026-07-19T09:10:00Z',
    updatedAt: '2026-07-19T09:10:00Z',
  );
  final savedTruckRecord = savedTruck == null
      ? null
      : ConcreteTruck(
          id: savedTruck.id,
          pourId: savedTruck.pourId,
          sequenceNo: savedTruck.sequenceNo,
          vehiclePlate: savedTruck.vehiclePlate,
          deliveryNoteNumber: savedTruck.deliveryNoteNumber,
          plantSnapshot: savedTruck.plantSnapshot,
          batchTime: savedTruck.batchTime,
          arrivedAt: savedTruck.arrivedAt,
          unloadingStartedAt: savedTruck.unloadingStartedAt,
          unloadingEndedAt: savedTruck.unloadingEndedAt,
          volumeM3: savedTruck.volumeM3,
          measuredSlump: savedTruck.measuredSlump,
          concreteTemperature: savedTruck.concreteTemperature,
          result: savedTruck.result,
          reason: savedTruck.reason,
          note: savedTruck.note,
          evidenceExceptionReason: savedTruck.evidenceExceptionReason,
          revision: savedTruck.expectedTruckRevision + 1,
          createdAt: '2026-07-19T09:10:00Z',
          updatedAt: '2026-07-20T13:00:00Z',
        );
  final trucks = savedTruckRecord == null
      ? const [truck]
      : savedTruckRecord.id == truck.id
      ? [savedTruckRecord]
      : [truck, savedTruckRecord];
  const attachment = ConcreteAttachment(
    id: attachmentId,
    pourId: pourId,
    truckId: truckId,
    sampleSetId: null,
    checkItemId: null,
    evidenceType: ConcreteEvidenceType.deliveryNoteScan,
    originalFileName: 'irsaliye.jpg',
    mimeType: 'image/jpeg',
    byteSize: 4,
    sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    relativePath: 'concrete/pour/truck/irsaliye.jpg',
    capturedAt: '2026-07-19T09:11:00Z',
    description: 'İrsaliye taraması',
    createdAt: '2026-07-19T09:11:00Z',
    integrity: ConcreteAttachmentIntegrity.ok,
  );
  const event = ConcretePourEvent(
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    pourId: pourId,
    sequence: 1,
    eventType: 'pour.created',
    occurredAt: '2026-07-19T07:00:00Z',
    payloadJson: '{}',
  );
  final delivered = trucks.fold<double>(
    0,
    (total, item) => total + item.volumeM3,
  );
  return ConcretePourDetail(
    pour: pour,
    concreteClassId: concreteClassId,
    agendaLogId: agendaLinked ? agendaLogId : null,
    checks: checks,
    trucks: trucks,
    sampleSets: const [],
    followUps: [follow],
    attachments: const [attachment],
    events: const [event],
    linkedReminders: const [],
    metrics: ConcreteMetrics(
      actualDeliveredM3: delivered,
      varianceM3: delivered - 20,
      variancePercent: ((delivered - 20) / 20) * 100,
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
      firstTruckAt: null,
      lastTruckAt: null,
      pourDurationMinutes: ended ? 30 : null,
      sampleSetCount: 0,
      sampleCount: 0,
      pendingCheckCount: pendingRequiredConcreteChecks(checks).length,
      missingEvidenceTruckCount: 0,
      openFollowUpCount: 1,
    ),
  );
}
