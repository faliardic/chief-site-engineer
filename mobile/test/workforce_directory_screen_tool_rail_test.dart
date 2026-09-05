import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_directory_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/screen_tool_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

const _stamp = '2026-09-05T06:00:00Z';
const _project = MobileProject(
  id: 'project-a',
  name: 'Proje A',
  createdAt: _stamp,
  updatedAt: _stamp,
  revision: 1,
);
const _other = MobileProject(
  id: 'project-b',
  name: 'Proje B',
  createdAt: _stamp,
  updatedAt: _stamp,
  revision: 1,
);

void main() {
  for (final size in [
    const Size(320, 760),
    const Size(390, 760),
    const Size(320, 300),
    const Size(390, 240),
  ]) {
    testWidgets('rail and filter surface fit $size at 2x text', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final attendance = _Attendance();
        await _pump(tester, attendance, size: size, scale: 2);
        final rail = find.byType(ScreenToolRail);
        final list = find.byKey(const Key('workforce-directory'));
        expect(
          tester.getRect(list).right,
          lessThanOrEqualTo(tester.getRect(rail).left),
        );
        final actions = tester.widget<ScreenToolRail>(rail).actions;
        expect(actions.map((action) => action.label), [
          'Ara',
          'Filtreler',
          'Sicili yönet',
        ]);
        expect(
          tester.getTopLeft(find.byKey(actions.first.key)).dy,
          lessThan(tester.getTopLeft(find.byKey(actions.last.key)).dy),
        );
        for (final action in actions) {
          final target = find.byKey(action.key);
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
          expect(tester.getSize(target), const Size.square(48));
          expect(tester.widget<IconButton>(target).tooltip, action.label);
          final data = tester
              .getSemantics(find.bySemanticsLabel(action.label))
              .getSemanticsData();
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
        }
        expect(
          find.byKey(const Key('workforce-directory-status')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('workforce-directory-subcontractor')),
          findsNothing,
        );
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        final manage = find.byKey(const Key('manage-workforce-directory'));
        expect(manage.hitTestable(), findsOneWidget);
        expect(tester.getSize(manage), const Size.square(48));
        expect(tester.widget<IconButton>(manage).tooltip, 'Sicili yönet');
        expect(find.descendant(of: rail, matching: manage), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        await tester.tap(
          find.byKey(const Key('workforce-directory-search-action')),
        );
        await tester.pumpAndSettle();
        final input = tester.widget<TextField>(
          find.byKey(const Key('workforce-directory-search')),
        );
        expect(input.focusNode!.hasFocus, isTrue);
        input.focusNode!.unfocus();
        await _openFilters(tester);
        await _choose(tester, 'workforce-directory-subcontractor', 'Taşeron A');
        await _choose(tester, 'workforce-directory-team-sub-a-null', 'Ekip A');
        await _closeFilters(tester, apply: true);
        final chip = find.byKey(const Key('workforce-directory-summary-team'));
        await _reveal(tester, chip);
        expect(chip.hitTestable(), findsOneWidget);
        expect(tester.getRect(chip).right, lessThan(tester.getRect(rail).left));
        await _reveal(
          tester,
          find.byKey(const Key('workforce-directory-member-a')),
        );
        expect(
          tester
              .getRect(find.byKey(const Key('workforce-directory-member-a')))
              .right,
          lessThan(tester.getRect(rail).left),
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
    'draft cancel no-op apply and independent clears retain search and project',
    (tester) async {
      final attendance = _Attendance();
      final selected = <String>[];
      await _pump(tester, attendance, onSelected: selected.add);
      await tester.enterText(
        find.byKey(const Key('workforce-directory-search')),
        'PERSONEL',
      );
      await tester.pumpAndSettle();
      final reads = attendance.reads;
      await _openFilters(tester);
      await _closeFilters(tester, apply: true);
      expect(attendance.reads, reads);
      await _openFilters(tester);
      await tester.tap(find.text('Arşiv'));
      await tester.pump();
      await _choose(tester, 'workforce-directory-subcontractor', 'Taşeron A');
      await _choose(tester, 'workforce-directory-team-sub-a-null', 'Ekip A');
      await _closeFilters(tester, apply: false);
      expect(
        find.byKey(const Key('workforce-directory-summary-status')),
        findsNothing,
      );
      expect(find.text('Personel A'), findsOneWidget);
      expect(find.text('Personel B'), findsOneWidget);
      await _openFilters(tester);
      await tester.tap(find.text('Arşiv'));
      await tester.pump();
      await _choose(tester, 'workforce-directory-subcontractor', 'Taşeron A');
      await _choose(tester, 'workforce-directory-team-sub-a-null', 'Ekip A');
      await _closeFilters(tester, apply: true);
      expect(find.text('Personel Arşiv'), findsOneWidget);
      expect(find.text('Personel A'), findsNothing);
      expect(find.text('Personel B'), findsNothing);
      for (final kind in ['status', 'subcontractor', 'team']) {
        final chip = find.byKey(Key('workforce-directory-summary-$kind'));
        await _reveal(tester, chip);
        await tester.tap(
          find.descendant(
            of: chip,
            matching: find.byTooltip(
              tester.widget<InputChip>(chip).deleteButtonTooltipMessage!,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(chip, findsNothing);
      }
      expect(find.text('Personel A'), findsOneWidget);
      expect(find.text('Personel B'), findsOneWidget);
      expect(
        find.byKey(const Key('workforce-directory-clear-filters')),
        findsNothing,
      );
      await _openFilters(tester);
      await _choose(tester, 'workforce-directory-subcontractor', 'Taşeron A');
      await _choose(tester, 'workforce-directory-team-sub-a-null', 'Ekip A');
      await _closeFilters(tester, apply: true);
      await _openFilters(tester);
      await _choose(tester, 'workforce-directory-subcontractor', 'Taşeron B');
      expect(
        find.byKey(const Key('workforce-directory-team-sub-b-null')),
        findsOneWidget,
      );
      await _closeFilters(tester, apply: false);
      expect(
        find.byKey(const Key('workforce-directory-summary-team')),
        findsOneWidget,
      );
      await _openFilters(tester);
      await _choose(tester, 'workforce-directory-subcontractor', 'Taşeron B');
      await _closeFilters(tester, apply: true);
      expect(
        find.byKey(const Key('workforce-directory-summary-team')),
        findsNothing,
      );
      expect(find.text('Personel B'), findsOneWidget);
      expect(find.text('Personel A'), findsNothing);
      await _reveal(
        tester,
        find.byKey(const Key('workforce-directory-clear-filters')),
      );
      await tester.tap(
        find.byKey(const Key('workforce-directory-clear-filters')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Personel A'), findsOneWidget);
      expect(find.text('Personel B'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('workforce-directory-search')),
            )
            .controller!
            .text,
        'PERSONEL',
      );
      expect(find.text('Görünen proje: Proje A'), findsOneWidget);
      expect(selected, isEmpty);
      expect(attendance.reads, reads);
      expect(attendance.createMemberCalls, 0);
      expect(attendance.saveCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search reveals existing controller and management return reloads exact project',
    (tester) async {
      final attendance = _Attendance();
      await _pump(tester, attendance, size: const Size(320, 400));
      await tester.tap(
        find.byKey(const Key('workforce-directory-search-action')),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('workforce-directory-search'));
      final controller = tester.widget<TextField>(field).controller;
      await tester.enterText(field, 'Personel A');
      await tester.pumpAndSettle();
      tester.widget<TextField>(field).focusNode!.unfocus();
      final list = tester.widget<ListView>(
        find.byKey(const Key('workforce-directory')),
      );
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final reads = attendance.reads;
      await tester.tap(
        find.byKey(const Key('workforce-directory-search-action')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller, same(controller));
      expect(controller!.text, 'Personel A');
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      expect(attendance.reads, reads);
      await tester.tap(find.byKey(const Key('manage-workforce-directory')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<WorkforcePage>(find.byType(WorkforcePage)).project.id,
        _project.id,
      );
      attendance.members = [_member('new', 'Personel A güncel')];
      final beforeReturn = attendance.reads;
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(attendance.reads, beforeReturn + 1);
      await _reveal(tester, find.text('Personel A güncel'));
      expect(find.text('Personel A güncel'), findsOneWidget);
      expect(controller.text, 'Personel A');
      expect(attendance.readProjects.toSet(), {_project.id});
      expect(attendance.createMemberCalls, 0);
      expect(attendance.saveCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'project switch rejects old filter draft and discovery failure disables rail',
    (tester) async {
      final attendance = _Attendance();
      final agenda = _Agenda();
      await _pump(tester, attendance, agenda: agenda);
      await _openFilters(tester);
      await tester.tap(find.text('Arşiv'));
      await tester.pump();
      final state = tester.state<WorkforceDirectoryPageState>(
        find.byType(WorkforceDirectoryPage, skipOffstage: false),
      );
      await state.selectProject(_other.id);
      await tester.pumpAndSettle();
      await _closeFilters(tester, apply: true);
      expect(
        find.byKey(const Key('workforce-directory-summary-status')),
        findsNothing,
      );
      expect(find.text('Görünen proje: Proje B'), findsOneWidget);
      expect(find.text('Başka proje'), findsOneWidget);
      expect(find.text('Personel A'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      agenda.fail = true;
      await _pump(
        tester,
        attendance,
        agenda: agenda,
        size: const Size(320, 320),
      );
      final reads = attendance.reads;
      for (final action
          in tester
              .widget<ScreenToolRail>(find.byType(ScreenToolRail))
              .actions) {
        expect(action.onPressed, isNull);
      }
      final retry = find.byKey(const Key('workforce-directory-project-retry'));
      await _reveal(tester, retry);
      expect(retry.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(retry).right,
        lessThan(tester.getRect(find.byType(ScreenToolRail)).left),
      );
      expect(attendance.reads, reads);
      agenda.fail = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(attendance.reads, reads + 1);
      expect(
        find.byKey(const Key('workforce-directory-project-error')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading, directory error and empty results remain in content column',
    (tester) async {
      final attendance = _Attendance()..gate = Completer<void>();
      await _pump(tester, attendance, settle: false);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('manage-workforce-directory')),
            )
            .onPressed,
        isNull,
      );
      attendance.gate!.complete();
      await tester.pumpAndSettle();
      attendance.fail = true;
      final state = tester.state<WorkforceDirectoryPageState>(
        find.byType(WorkforceDirectoryPage),
      );
      await state.selectProject(_other.id);
      await tester.pumpAndSettle();
      final error = find.byKey(const Key('workforce-directory-error'));
      await _reveal(tester, error);
      expect(
        tester.getRect(error).right,
        lessThan(tester.getRect(find.byType(ScreenToolRail)).left),
      );
      attendance.fail = false;
      attendance.members = [];
      await state.selectProject(_project.id);
      await tester.pumpAndSettle();
      final empty = find.byKey(const Key('workforce-directory-empty'));
      await _reveal(tester, empty);
      expect(
        tester.getRect(empty).right,
        lessThan(tester.getRect(find.byType(ScreenToolRail)).left),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  _Attendance attendance, {
  Size size = const Size(800, 800),
  double scale = 1,
  _Agenda? agenda,
  ValueChanged<String>? onSelected,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: WorkforceDirectoryPage(
          attendance: attendance,
          agenda: agenda ?? _Agenda(),
          initialProjectId: _project.id,
          onProjectSelected: onSelected,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _reveal(
  WidgetTester tester,
  Finder target, {
  bool sheet = false,
}) async {
  final list = find.byKey(
    Key(sheet ? 'workforce-directory-filter-sheet' : 'workforce-directory'),
  );
  final scrollable = find
      .descendant(of: list, matching: find.byType(Scrollable))
      .first;
  await tester.scrollUntilVisible(target, 100, scrollable: scrollable);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _openFilters(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('workforce-directory-filter-action')));
  await tester.pumpAndSettle();
}

Future<void> _closeFilters(WidgetTester tester, {required bool apply}) async {
  final button = find.byKey(
    Key('workforce-directory-filter-${apply ? 'apply' : 'cancel'}'),
  );
  await _reveal(tester, button, sheet: true);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String key, String label) async {
  final field = find.byKey(Key(key));
  await _reveal(tester, field, sheet: true);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

class _Agenda extends FakeAgendaApplication {
  _Agenda() : super(projects: [_project, _other]);
  bool fail = false;
  @override
  Future<List<MobileProject>> listProjects() async {
    if (fail) throw StateError('Synthetic discovery failure');
    return super.listProjects();
  }
}

class _Attendance extends FakeAttendanceApplication {
  _Attendance()
    : super(
        members: [
          _member('a', 'Personel A'),
          _member('b', 'Personel B', sub: 'b'),
          _member('c', 'Personel Arşiv', active: false),
          _member('other', 'Başka proje', projectId: _other.id),
        ],
      ) {
    subcontractors = [
      for (final suffix in ['a', 'b'])
        Subcontractor(
          id: 'sub-$suffix',
          projectId: _project.id,
          name: 'Taşeron ${suffix.toUpperCase()}',
          contactName: null,
          phone: null,
          note: null,
          status: WorkforceRecordStatus.active,
          activeTeamCount: 1,
          activePersonCount: 1,
          revision: 1,
          createdAt: _stamp,
          updatedAt: _stamp,
          archivedAt: null,
        ),
    ];
    teams = [
      for (final suffix in ['a', 'b'])
        WorkforceTeam(
          id: 'team-$suffix',
          projectId: _project.id,
          subcontractorId: 'sub-$suffix',
          subcontractorName: 'Taşeron ${suffix.toUpperCase()}',
          name: 'Ekip ${suffix.toUpperCase()}',
          leadName: null,
          note: null,
          status: WorkforceRecordStatus.active,
          activePersonCount: 1,
          revision: 1,
          createdAt: _stamp,
          updatedAt: _stamp,
          archivedAt: null,
        ),
    ];
  }
  int reads = 0;
  final readProjects = <String>[];
  Completer<void>? gate;
  bool fail = false;
  @override
  Future<List<WorkforceMember>> listMembers(
    String projectId, {
    bool includeInactive = false,
  }) async {
    reads++;
    readProjects.add(projectId);
    if (gate != null) await gate!.future;
    if (fail) throw StateError('Synthetic directory failure');
    return super.listMembers(projectId, includeInactive: includeInactive);
  }
}

WorkforceMember _member(
  String id,
  String name, {
  String sub = 'a',
  bool active = true,
  String projectId = 'project-a',
}) => WorkforceMember(
  id: id,
  projectId: projectId,
  fullName: name,
  teamName: 'Ekip ${sub.toUpperCase()}',
  roleName: 'Usta',
  personnelCode: null,
  subcontractorId: 'sub-$sub',
  subcontractorName: 'Taşeron ${sub.toUpperCase()}',
  teamId: 'team-$sub',
  phone: null,
  isActive: active,
  revision: 1,
  createdAt: _stamp,
  updatedAt: _stamp,
  archivedAt: active ? null : _stamp,
);
