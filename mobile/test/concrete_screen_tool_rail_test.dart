import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/concrete/concrete_page.dart';
import 'package:chief_site_engineer/features/screen_tool_rail.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _project = MobileProject(
  id: 'project-a',
  name: 'Proje A',
  createdAt: '2026-07-19T07:00:00Z',
  updatedAt: '2026-07-19T07:00:00Z',
  revision: 1,
);
const _other = MobileProject(
  id: 'project-b',
  name: 'Proje B',
  createdAt: '2026-07-19T07:00:00Z',
  updatedAt: '2026-07-19T07:00:00Z',
  revision: 1,
);
Finder _key(String key) => find.byKey(Key(key));
Finder get _listScroll => find
    .descendant(of: _key('concrete-page'), matching: find.byType(Scrollable))
    .first;
Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  final sheet = _key('concrete-filter-sheet');
  if (sheet.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(
      target,
      100,
      scrollable: find
          .descendant(of: sheet, matching: find.byType(Scrollable))
          .first,
    );
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  _Concrete concrete, {
  _Agenda? agenda,
  double scale = 1,
  String initial = 'project-a',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: ConcretePage(
          concrete: concrete,
          agenda: agenda ?? _Agenda(),
          attachments: SafeAttachmentPicker(
            permissions: SafeCapabilityService(_Permission()),
            picker: _Picker(),
          ),
          initialProjectId: initial,
          initialIstanbulDay: '2026-07-19',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _query(
  _Concrete concrete,
  ConcretePourGroup group, {
  String text = 'literal %_[]',
  String day = '2026-07-19',
  String project = 'project-a',
}) {
  expect(concrete.queries.last.group, group);
  expect(concrete.queries.last.literalSearch, text);
  expect(concrete.queries.last.istanbulDay, day);
  expect(concrete.queries.last.projectId, project);
}

void main() {
  testWidgets(
    'search reveals same field without submit; drafts cancel no-op apply and clears preserve query context',
    (tester) async {
      final concrete = _Concrete();
      await _pump(tester, concrete);
      final search = tester.widget<TextField>(_key('concrete-search'));
      expect(search.decoration!.suffixIcon, isNull);
      expect(find.byType(SegmentedButton<ConcretePourGroup>), findsNothing);
      await tester.enterText(_key('concrete-search'), 'literal %_[]');
      expect(concrete.queries.length, 1);
      await _tap(tester, 'concrete-tool-search');
      expect(search.focusNode!.hasFocus, isTrue);
      expect(
        tester.widget<TextField>(_key('concrete-search')).controller,
        same(search.controller),
      );
      expect(search.controller!.text, 'literal %_[]');
      expect(concrete.queries.length, 1);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      _query(concrete, ConcretePourGroup.today);
      expect(concrete.queries.length, 2);
      await _tap(tester, 'concrete-tool-filters');
      await _tap(tester, 'concrete-group-closed');
      expect(concrete.queries.length, 2);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(concrete.queries.length, 2);
      expect(_key('concrete-group-summary'), findsNothing);
      await _tap(tester, 'concrete-tool-filters');
      await _tap(tester, 'concrete-apply-filters');
      expect(concrete.queries.length, 2);
      for (final group in ConcretePourGroup.values.where(
        (g) => g != ConcretePourGroup.today,
      )) {
        await _tap(tester, 'concrete-tool-filters');
        await _tap(tester, 'concrete-group-${group.name}');
        final before = concrete.queries.length;
        await _tap(tester, 'concrete-apply-filters');
        expect(concrete.queries.length, before + 1);
        _query(concrete, group);
        expect(_key('concrete-group-summary'), findsOneWidget);
        await tester.ensureVisible(_key('concrete-group-summary'));
        await tester.tap(
          find.descendant(
            of: _key('concrete-group-summary'),
            matching: find.byTooltip('Delete'),
          ),
        );
        await tester.pumpAndSettle();
        _query(concrete, ConcretePourGroup.today);
        expect(concrete.queries.length, before + 2);
        expect(_key('concrete-group-summary'), findsNothing);
      }
      await _tap(tester, 'concrete-tool-filters');
      await _tap(tester, 'concrete-group-inProgress');
      await _tap(tester, 'concrete-apply-filters');
      await _tap(tester, 'concrete-tool-filters');
      await _tap(tester, 'concrete-clear-filters');
      _query(concrete, ConcretePourGroup.inProgress);
      await _tap(tester, 'concrete-apply-filters');
      _query(concrete, ConcretePourGroup.today);
      expect(search.controller!.text, 'literal %_[]');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'date applies immediately and project selection retains day group and literal search',
    (tester) async {
      final concrete = _Concrete();
      await _pump(tester, concrete);
      await tester.enterText(_key('concrete-search'), 'literal %_[]');
      await _tap(tester, 'concrete-tool-filters');
      await _tap(tester, 'concrete-group-followUp');
      await _tap(tester, 'concrete-apply-filters');
      await _tap(tester, 'concrete-day-filter');
      await tester.tap(find.text('20').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      _query(concrete, ConcretePourGroup.followUp, day: '2026-07-20');
      await tester
          .state<ConcretePageState>(find.byType(ConcretePage))
          .selectProject('project-b');
      await tester.pumpAndSettle();
      _query(
        concrete,
        ConcretePourGroup.followUp,
        day: '2026-07-20',
        project: 'project-b',
      );
    },
  );

  for (final size in [
    const Size(320, 760),
    const Size(390, 760),
    const Size(320, 300),
    const Size(390, 240),
  ]) {
    testWidgets('rail and scrollable filter reachable at $size with 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final concrete = _Concrete()..pours = List.generate(24, _pour);
        await _pump(tester, concrete, scale: 2);
        final rail = tester.widget<ScreenToolRail>(find.byType(ScreenToolRail));
        expect(rail.actions.map((a) => a.label), ['Ara', 'Filtreler']);
        expect(
          tester.getRect(_key('concrete-page')).right,
          lessThanOrEqualTo(tester.getRect(find.byType(ScreenToolRail)).left),
        );
        for (final entry in [
          ('concrete-tool-search', 'Ara'),
          ('concrete-tool-filters', 'Filtreler'),
        ]) {
          await tester.ensureVisible(_key(entry.$1));
          await tester.pumpAndSettle();
          expect(_key(entry.$1).hitTestable(), findsOneWidget);
          expect(
            tester.getSize(_key(entry.$1)).width,
            greaterThanOrEqualTo(48),
          );
          expect(
            tester.getSize(_key(entry.$1)).height,
            greaterThanOrEqualTo(48),
          );
          expect(find.byTooltip(entry.$2), findsOneWidget);
          final node = tester.getSemantics(find.bySemanticsLabel(entry.$2));
          expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
        }
        expect(find.text('Yeni döküm').hitTestable(), findsOneWidget);
        expect(
          tester.getSize(_key('create-concrete-pour')).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          find.descendant(
            of: find.byType(ScreenToolRail),
            matching: _key('create-concrete-pour'),
          ),
          findsNothing,
        );
        await _tap(tester, 'concrete-tool-filters');
        await _tap(tester, 'concrete-group-closed');
        expect(concrete.queries.length, 1);
        await _tap(tester, 'concrete-apply-filters');
        expect(concrete.queries.last.group, ConcretePourGroup.closed);
        await tester.scrollUntilVisible(
          _key('concrete-group-summary'),
          100,
          scrollable: _listScroll,
        );
        expect(
          tester.getRect(_key('concrete-group-summary')).right,
          lessThan(tester.getRect(find.byType(ScreenToolRail)).left),
        );
        final lastCard = _key('concrete-pour-pour-23');
        await tester.scrollUntilVisible(
          lastCard,
          500,
          scrollable: _listScroll,
          maxScrolls: 100,
        );
        expect(
          tester.getRect(lastCard).right,
          lessThan(tester.getRect(find.byType(ScreenToolRail)).left),
        );
        await _tap(tester, 'concrete-tool-search');
        expect(
          tester.widget<TextField>(_key('concrete-search')).focusNode!.hasFocus,
          isTrue,
        );
        expect(_key('concrete-search').hitTestable(), findsOneWidget);
        expect(concrete.queries.length, 2);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
    'project discovery failure stays fail closed and retry restores empty list; query errors remain visible',
    (tester) async {
      final concrete = _Concrete();
      final agenda = _Agenda()..fail = true;
      await _pump(tester, concrete, agenda: agenda);
      expect(concrete.queries, isEmpty);
      expect(
        tester.widget<FilledButton>(_key('create-concrete-pour')).onPressed,
        isNull,
      );
      expect(find.text('Beton paketleri açılamadı.'), findsOneWidget);
      agenda.fail = false;
      await _tap(tester, 'concrete-project-retry');
      expect(concrete.queries.length, 1);
      expect(find.text('Bu görünümde Beton paketi yok.'), findsOneWidget);
      concrete.fail = true;
      await tester.enterText(_key('concrete-search'), 'failure');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Liste yenilenemedi.'), findsOneWidget);
      concrete.fail = false;
      concrete.pending = Completer<List<ConcretePour>>();
      await tester.showKeyboard(_key('concrete-search'));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      concrete.pending!.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('Liste yenilenemedi.'), findsNothing);
      expect(find.text('Bu görünümde Beton paketi yok.'), findsOneWidget);
      // Replace the route so initial project discovery runs for the unavailable ID.
      await tester.pumpWidget(const SizedBox.shrink());
      final unavailable = _Concrete();
      await _pump(tester, unavailable, initial: 'missing');
      expect(unavailable.queries, isEmpty);
      expect(_key('concrete-project-context-unavailable'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(_key('create-concrete-pour')).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _Concrete implements ConcreteApplication {
  final queries = <ConcretePourQuery>[];
  List<ConcretePour> pours = [];
  bool fail = false;
  Completer<List<ConcretePour>>? pending;
  @override
  Future<List<ConcretePour>> listPours(ConcretePourQuery query) async {
    queries.add(query);
    if (fail) throw StateError('list failed');
    return pending == null ? pours : pending!.future;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Agenda implements AgendaApplication {
  bool fail = false;
  @override
  Stream<void> get projectChanges => const Stream.empty();
  @override
  Future<List<MobileProject>> listProjects() async {
    if (fail) throw StateError('discovery failed');
    return [_project, _other];
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Permission implements PermissionGateway {
  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.granted;
}

class _Picker implements AttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async => null;
}

ConcretePour _pour(int index) => ConcretePour(
  id: 'pour-$index',
  projectId: _project.id,
  projectName: _project.name,
  pourCode: 'BT-$index',
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
