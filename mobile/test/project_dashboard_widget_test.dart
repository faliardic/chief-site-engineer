import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/project_information_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets('zero projects keeps the existing New Project entry', (
    tester,
  ) async {
    final fixture = _Fixture(projects: const []);
    addTearDown(fixture.dispose);
    var createCalls = 0;

    await tester.pumpWidget(
      fixture.app(onCreateProject: () => createCalls += 1),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dashboard-create-project')));
    expect(createCalls, 1);
  });

  testWidgets(
    'Home hierarchy is Active Project then five quick values then all info',
    (tester) async {
      final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final fixture = _Fixture(projects: [project]);
      addTearDown(fixture.dispose);
      fixture.source.metadataByProject[project.id] = _metadata(
        project.id,
        address: 'İnönü Caddesi 12',
      );
      fixture.agenda.projectProfileFields[project.id] = _profile(
        project,
        totalFloors: '12',
        totalArea: '2400 m²',
        yibf: 'Y-42',
      ).fields;
      String? openedProjectId;

      await tester.pumpWidget(
        fixture.app(
          onOpenProjectInformation: (projectId) => openedProjectId = projectId,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktif Proje'), findsOneWidget);
      expect(find.text('Hızlı Bilgiler'), findsOneWidget);
      expect(find.text('Kuzey'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('dashboard-quick-information')),
          matching: find.byType(Card),
        ),
        findsNWidgets(5),
      );
      expect(find.text('İnönü Caddesi 12'), findsOneWidget);
      expect(find.text('2400 m²'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Y-42'), findsOneWidget);

      final allInfo = find.byKey(
        const Key('dashboard-open-project-information'),
      );
      expect(allInfo, findsOneWidget);
      expect(allInfo.hitTestable(), findsOneWidget);
      await tester.tap(allInfo);
      expect(openedProjectId, project.id);
    },
  );

  testWidgets('secondary profile editor preserves edit add and archive', (
    tester,
  ) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project]);
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
    await tester.pumpAndSettle();
    await _openProfileEditor(tester);

    final totalFloors = fixture.agenda.projectProfileFields[project.id]!
        .singleWhere(
          (field) =>
              field.builtinField == ProjectProfileBuiltinField.totalFloors,
        );
    final totalFloorsCell = find.byKey(
      ValueKey('project-profile-field-${totalFloors.id}'),
    );
    await tester.scrollUntilVisible(
      totalFloorsCell,
      150,
      scrollable: _dashboardScrollable(),
    );
    await tester.tap(totalFloorsCell);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-profile-edit-value')),
      '12',
    );
    await tester.tap(find.byKey(const Key('project-profile-save-field')));
    await tester.pumpAndSettle();
    expect(
      fixture.agenda.projectProfileFields[project.id]!
          .singleWhere((field) => field.id == totalFloors.id)
          .value,
      '12',
    );

    final add = find.byKey(const Key('project-profile-add-field'));
    await tester.scrollUntilVisible(
      add,
      150,
      scrollable: _dashboardScrollable(),
    );
    expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-profile-new-label')),
      'Yapı sınıfı',
    );
    await tester.enterText(
      find.byKey(const Key('project-profile-new-value')),
      '4A',
    );
    await tester.tap(find.byKey(const Key('project-profile-create-field')));
    await tester.pumpAndSettle();
    final custom = fixture.agenda.projectProfileFields[project.id]!.singleWhere(
      (field) => !field.isBuiltIn,
    );
    expect(custom.label, 'Yapı sınıfı');
    expect(custom.value, '4A');

    final customCell = find.byKey(
      ValueKey('project-profile-field-${custom.id}'),
    );
    await tester.scrollUntilVisible(
      customCell,
      150,
      scrollable: _dashboardScrollable(),
    );
    await tester.tap(customCell);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('project-profile-archive-${custom.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('project-profile-confirm-archive')));
    await tester.pumpAndSettle();
    expect(
      fixture.agenda.projectProfileFields[project.id]!
          .singleWhere((field) => field.id == custom.id)
          .isArchived,
      isTrue,
    );
    expect(customCell, findsNothing);
    expect(
      fixture.agenda.projectProfileEvents.map((event) => event.eventType),
      containsAllInOrder([
        ProjectProfileEventType.fieldUpdated,
        ProjectProfileEventType.fieldCreated,
        ProjectProfileEventType.fieldArchived,
      ]),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory failure does not look like empty quick information', (
    tester,
  ) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project])
      ..source.inventoryFailure = StateError('inventory unavailable');
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
    await tester.pumpAndSettle();

    for (final key in const ['total-area', 'block-count', 'total-floors']) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('dashboard-quick-$key')),
          matching: find.text('Okunamadı'),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('secondary profile editor drag reorder persists exact order', (
    tester,
  ) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project]);
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
    await tester.pumpAndSettle();
    await _openProfileEditor(tester);
    final fields = List.of(fixture.agenda.projectProfileFields[project.id]!);
    final firstDrag = find.byKey(
      ValueKey('project-profile-drag-${fields.first.id}'),
    );
    final lastCell = find.byKey(
      ValueKey('project-profile-field-${fields.last.id}'),
    );
    await tester.scrollUntilVisible(
      lastCell,
      150,
      scrollable: _dashboardScrollable(),
    );
    expect(tester.getSize(firstDrag), const Size(48, 48));
    final gesture = await tester.startGesture(tester.getCenter(firstDrag));
    await gesture.moveTo(tester.getCenter(lastCell));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      fixture.agenda.projectProfileFields[project.id]!
          .where((field) => !field.isArchived)
          .map((field) => field.label),
      ['Toplam alan', 'YİBF No', 'Toplam kat'],
    );
    expect(
      fixture.agenda.projectProfileEvents.last.eventType,
      ProjectProfileEventType.fieldsReordered,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'secondary editor drag scrolls to later fields and survives reload',
    (tester) async {
      tester.view.physicalSize = const Size(320, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final fixture = _Fixture(projects: [project]);
      addTearDown(fixture.dispose);
      final fields = [
        ..._profile(project, totalFloors: '12').fields,
        for (var index = 0; index < 15; index += 1)
          ProjectProfileField(
            id: 'custom-$index',
            projectId: project.id,
            label: 'Alan $index',
            value: 'Değer $index',
            sortOrder: index + 3,
            revision: 1,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt,
          ),
      ];
      fixture.agenda.projectProfileFields[project.id] = fields;
      await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
      await tester.pumpAndSettle();
      await _openProfileEditor(tester);
      final firstDrag = find.byKey(
        ValueKey('project-profile-drag-${fields.first.id}'),
      );
      final scroll = tester.state<ScrollableState>(_dashboardScrollable());
      scroll.position.jumpTo(scroll.position.minScrollExtent);
      await tester.pump();
      await tester.scrollUntilVisible(
        firstDrag,
        100,
        scrollable: _dashboardScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(firstDrag);
      await tester.pumpAndSettle();
      final viewport = tester.getRect(_dashboardScrollable());
      expect(firstDrag.hitTestable(), findsOneWidget);
      final startingOffset = scroll.position.pixels;
      expect(scroll.position.maxScrollExtent, greaterThan(startingOffset));
      final gesture = await tester.startGesture(tester.getCenter(firstDrag));
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      for (var index = 0; index < 20; index += 1) {
        await gesture.moveTo(
          Offset(viewport.center.dx, viewport.bottom - (index.isEven ? 2 : 1)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(scroll.position.pixels, greaterThan(startingOffset));
      final target = find.byKey(
        ValueKey('project-profile-field-${fields[10].id}'),
      );
      await tester.ensureVisible(target);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      final expected = fields.map((field) => field.id).toList();
      expected.insert(10, expected.removeAt(0));
      expect(
        fixture.agenda.projectProfileFields[project.id]!.map(
          (field) => field.id,
        ),
        expected,
      );
      expect(
        fixture.agenda.projectProfileEvents.last.eventType,
        ProjectProfileEventType.fieldsReordered,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
      await tester.pumpAndSettle();
      await _openProfileEditor(tester);
      final grid = tester.widget<Wrap>(
        find.byKey(const Key('project-profile-fields')),
      );
      expect(
        grid.children.take(fields.length).map((child) => child.key),
        expected.map((id) => ValueKey('project-profile-field-$id')),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 600.0, 840.0]) {
    testWidgets('compact hierarchy fits $width width and large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = _project(
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'Çok uzun proje adı ' * 6,
      );
      final fixture = _Fixture(projects: [project]);
      addTearDown(fixture.dispose);
      fixture.source.metadataByProject[project.id] = _metadata(
        project.id,
        address: 'Çok uzun güvenli proje adresi ' * 8,
      );

      await tester.pumpWidget(
        fixture.app(textScale: 1.8, onOpenProjectInformation: (_) {}),
      );
      await tester.pumpAndSettle();

      final header = find.byKey(const Key('project-profile-header'));
      final create = find.byKey(const Key('project-profile-create-project'));
      final tools = find.byKey(const Key('project-profile-tools'));
      expect(find.descendant(of: header, matching: create), findsOneWidget);
      expect(find.descendant(of: header, matching: tools), findsOneWidget);
      for (final action in [create, tools]) {
        expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      }
      expect(
        find.descendant(
          of: find.byKey(const Key('dashboard-quick-information')),
          matching: find.byType(Card),
        ),
        findsNWidgets(5),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'project name rename uses canonical revision and reloads information',
    (tester) async {
      final project = _project(
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'Kuzey',
        revision: 7,
      );
      final agenda = _RenamingAgenda(projects: [project]);
      final fixture = _Fixture(projects: agenda.projects, agenda: agenda);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
      await tester.pumpAndSettle();
      await _renameVisibleProject(tester, '  Yeni Kuzey  ');

      expect(find.text('Yeni Kuzey'), findsOneWidget);
      expect(agenda.projects.single.revision, 8);
      expect(agenda.renameCommands.single.expectedRevision, 7);
      expect(fixture.session.selectedProjectId, project.id);
      expect(tester.takeException(), isNull);
    },
  );

  for (final stale in [true, false]) {
    testWidgets(
      'project name ${stale ? 'stale revision' : 'failure'} preserves state',
      (tester) async {
        final project = _project(
          'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'Kuzey',
        );
        final agenda = _RenamingAgenda(projects: [project]);
        final fixture = _Fixture(projects: agenda.projects, agenda: agenda);
        addTearDown(fixture.dispose);
        await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
        await tester.pumpAndSettle();
        final fieldsBefore = List.of(agenda.projectProfileFields[project.id]!);
        await tester.tap(find.byKey(const Key('project-profile-name')));
        await tester.pumpAndSettle();
        if (stale) {
          agenda.projects = [_project(project.id, project.name, revision: 2)];
        } else {
          agenda.renameFailure = StateError('synthetic rename failure');
        }
        await tester.enterText(
          find.byKey(const Key('project-profile-edit-name')),
          'Kaydedilmemeli',
        );
        await tester.tap(find.byKey(const Key('project-profile-save-name')));
        await tester.pumpAndSettle();

        expect(find.text('Kuzey'), findsOneWidget);
        expect(find.text('Kaydedilmemeli'), findsNothing);
        expect(agenda.projects.single.name, 'Kuzey');
        expect(fixture.session.selectedProjectId, project.id);
        expect(agenda.appliedRenames, 0);
        expect(agenda.projectProfileFields, {project.id: fieldsBefore});
        expect(
          find.text(
            stale
                ? 'Proje başka bir işlem tarafından değiştirilmiş.'
                : 'Proje bilgileri güncellenemedi. Kayıtlar korunuyor.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('pending rename never retargets a newly selected project', (
    tester,
  ) async {
    final first = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final second = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
    final gate = Completer<void>();
    final agenda = _RenamingAgenda(projects: [first, second])
      ..renameGate = gate;
    final fixture = _Fixture(projects: agenda.projects, agenda: agenda);
    addTearDown(fixture.dispose);
    fixture.session.select(first.id, agenda.projects);
    await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('project-profile-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-profile-edit-name')),
      'Yeni Kuzey',
    );
    await tester.tap(find.byKey(const Key('project-profile-save-name')));
    await tester.pump();
    expect(agenda.renameCommands.single.projectId, first.id);
    expect(fixture.session.select(second.id, agenda.projects), isTrue);
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();

    expect(fixture.session.selectedProjectId, second.id);
    expect(find.text('Güney'), findsOneWidget);
    expect(find.text('Yeni Kuzey'), findsNothing);
    expect(agenda.projects.first.name, 'Yeni Kuzey');
    expect(agenda.projects.last, same(second));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending profile mutation cannot supersede a project switch', (
    tester,
  ) async {
    final first = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final second = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
    final gate = Completer<void>();
    final agenda = _PendingProfileAgenda(projects: [first, second])
      ..updateGate = gate;
    final fixture = _Fixture(projects: agenda.projects, agenda: agenda);
    addTearDown(fixture.dispose);
    fixture.source.metadataByProject[second.id] = _metadata(
      second.id,
      address: 'Güney adresi',
    );
    fixture.session.select(first.id, agenda.projects);
    await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
    await tester.pumpAndSettle();
    await _openProfileEditor(tester);
    final field = agenda.projectProfileFields[first.id]!.first;
    final fieldCell = find.byKey(ValueKey('project-profile-field-${field.id}'));
    await tester.scrollUntilVisible(
      fieldCell,
      150,
      scrollable: _dashboardScrollable(),
    );
    await tester.tap(fieldCell);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-profile-edit-value')),
      'Eski projeye ait yeni değer',
    );
    await tester.tap(find.byKey(const Key('project-profile-save-field')));
    await tester.pump();

    expect(fixture.session.select(second.id, agenda.projects), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Güney'), findsOneWidget);
    expect(find.text('Güney adresi'), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();

    expect(fixture.session.selectedProjectId, second.id);
    expect(find.text('Güney'), findsOneWidget);
    expect(find.text('Güney adresi'), findsOneWidget);
    expect(find.text('Eski projeye ait yeni değer'), findsNothing);
    expect(
      agenda.projectProfileFields[first.id]!
          .singleWhere((item) => item.id == field.id)
          .value,
      'Eski projeye ait yeni değer',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact tools preserves exact project actions', (tester) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project]);
    addTearDown(fixture.dispose);
    String? openedProject;

    await tester.pumpWidget(
      fixture.app(
        onOpenPlan: (projectId) => openedProject = projectId,
        onOpenProjectInformation: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('project-profile-tools')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('project-profile-tools-sheet')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('dashboard-open-plan')));
    await tester.pumpAndSettle();
    expect(openedProject, project.id);
  });

  for (final width in [320.0, 390.0, 600.0, 840.0]) {
    testWidgets(
      'project files group stays accessible and exact at $width width',
      (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final project = _project(
          'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'Kuzey',
        );
        final fixture = _Fixture(projects: [project]);
        addTearDown(fixture.dispose);
        String? albumProjectId;
        String? catalogProjectId;

        try {
          await tester.pumpWidget(
            fixture.app(
              textScale: 1.6,
              onOpenProjectInformation: (_) {},
              onOpenProjectAlbum: (projectId) => albumProjectId = projectId,
              onOpenCatalog: (projectId) => catalogProjectId = projectId,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('project-profile-tools')));
          await tester.pumpAndSettle();
          final sheet = find.byKey(const Key('project-profile-tools-sheet'));
          final scrollable = find.descendant(
            of: sheet,
            matching: find.byType(Scrollable),
          );
          expect(
            find.byKey(const Key('dashboard-memory-backup')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('dashboard-attachment-health')),
            findsNothing,
          );
          final section = find.byKey(
            const Key('dashboard-project-files-section'),
          );
          await tester.scrollUntilVisible(section, 300, scrollable: scrollable);
          expect(
            tester
                .getSemantics(find.bySemanticsLabel('Proje dosyaları'))
                .getSemanticsData()
                .flagsCollection
                .isHeader,
            isTrue,
          );
          final album = find.byKey(const Key('dashboard-project-album'));
          await tester.scrollUntilVisible(album, 200, scrollable: scrollable);
          await Scrollable.ensureVisible(
            tester.element(album),
            alignment: 0.5,
            duration: Duration.zero,
          );
          await tester.pumpAndSettle();
          _expectAccessibleTool(tester, album);
          await tester.tap(album);
          await tester.pumpAndSettle();
          expect(albumProjectId, project.id);

          await tester.tap(find.byKey(const Key('project-profile-tools')));
          await tester.pumpAndSettle();
          final reopened = find.byKey(const Key('project-profile-tools-sheet'));
          final reopenedScrollable = find.descendant(
            of: reopened,
            matching: find.byType(Scrollable),
          );
          final catalog = find.byKey(const Key('dashboard-attachment-catalog'));
          await tester.scrollUntilVisible(
            catalog,
            300,
            scrollable: reopenedScrollable,
          );
          await Scrollable.ensureVisible(
            tester.element(catalog),
            alignment: 0.5,
            duration: Duration.zero,
          );
          await tester.pumpAndSettle();
          _expectAccessibleTool(tester, catalog);
          await tester.tap(catalog);
          await tester.pumpAndSettle();
          expect(catalogProjectId, project.id);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('active project switch rejects stale information result', (
    tester,
  ) async {
    final first = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final second = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
    final fixture = _Fixture(projects: [first, second]);
    addTearDown(fixture.dispose);
    final stale = Completer<MobileProject>();
    fixture.source.projectReads[first.id] = [stale.future];
    fixture.source.metadataByProject[first.id] = _metadata(
      first.id,
      address: 'ESKİ ADRES',
    );
    fixture.source.metadataByProject[second.id] = _metadata(
      second.id,
      address: 'Güney adresi',
    );

    await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_) {}));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('dashboard-project-selection-required')),
      findsOneWidget,
    );

    expect(fixture.session.select(first.id, [first, second]), isTrue);
    await tester.pump();
    expect(fixture.session.select(second.id, [first, second]), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Güney'), findsOneWidget);
    expect(find.text('Güney adresi'), findsOneWidget);

    stale.complete(first);
    await tester.pumpAndSettle();
    expect(find.text('Güney'), findsOneWidget);
    expect(find.text('Güney adresi'), findsOneWidget);
    expect(find.text('ESKİ ADRES'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _Fixture {
  _Fixture({
    required List<MobileProject> projects,
    FakeAgendaApplication? agenda,
  }) : agenda = agenda ?? FakeAgendaApplication(projects: projects) {
    source = _DashboardInformationSource(this.agenda);
  }

  final FakeAgendaApplication agenda;
  late final _DashboardInformationSource source;
  final ActiveProjectSession session = ActiveProjectSession();

  Widget app({
    VoidCallback? onCreateProject,
    DashboardProjectAction? onOpenPlan,
    DashboardProjectAction? onOpenProjectAlbum,
    DashboardProjectAction? onOpenCatalog,
    DashboardProjectAction? onOpenProjectInformation,
    double textScale = 1,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    locale: CseApp.locale,
    supportedLocales: CseApp.supportedLocales,
    localizationsDelegates: CseApp.localizationsDelegates,
    home: Scaffold(
      body: ProjectDashboardPage(
        agenda: agenda,
        projectInformation: ProjectInformationApplication(source: source),
        livingPlan: const UnavailableConstructionLivingPlanApplication(),
        session: session,
        onCreateProject: onCreateProject ?? () {},
        onOpenPlan: onOpenPlan,
        onOpenProjectAlbum: onOpenProjectAlbum,
        onOpenCatalog: onOpenCatalog,
        onOpenProjectInformation: onOpenProjectInformation,
        clock: () => DateTime.utc(2026, 9, 4, 9),
      ),
    ),
  );

  void dispose() => session.dispose();
}

class _DashboardInformationSource implements ProjectInformationReadSource {
  _DashboardInformationSource(this.agenda);

  final FakeAgendaApplication agenda;
  final Map<String, List<Future<MobileProject>>> projectReads = {};
  final Map<String, ProjectMetadata> metadataByProject = {};
  Object? inventoryFailure;

  @override
  Future<MobileProject> getProject(String projectId) async {
    final reads = projectReads[projectId];
    if (reads != null && reads.isNotEmpty) return reads.removeAt(0);
    return agenda.projects.singleWhere((project) => project.id == projectId);
  }

  @override
  Future<ProjectMetadata> getProjectMetadata(String projectId) async =>
      metadataByProject[projectId] ?? _metadata(projectId);

  @override
  Future<ProjectProfile> getProjectProfile(String projectId) async {
    return agenda.getProjectProfile(projectId);
  }

  @override
  Future<List<ProjectProfileEvent>> listProjectProfileEvents(
    String projectId,
  ) async => const [];

  @override
  Future<List<ProjectPartyAssignment>> listProjectPartyAssignments(
    String projectId,
  ) async => const [];

  @override
  Future<List<Subcontractor>> listCompanies(String projectId) async => const [];

  @override
  Future<List<WorkforceMember>> listWorkforceMembers(String projectId) async =>
      const [];

  @override
  Future<InventoryPrimarySketchProjection?> loadInventory(
    String projectId,
  ) async {
    if (inventoryFailure != null) throw inventoryFailure!;
    return null;
  }

  @override
  Future<InventoryBlockMetadataRecord> loadBlockMetadata({
    required String projectId,
    required String blockId,
  }) => throw StateError('No block metadata read expected');

  @override
  Future<List<MobileProjectLocation>> listLocations(String projectId) async =>
      const [];

  @override
  Future<List<ProjectFloorLocationRelation>> listFloorLocations(
    String projectId,
  ) async => const [];
}

void _expectAccessibleTool(WidgetTester tester, Finder finder) {
  expect(finder.hitTestable(), findsOneWidget);
  expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.hasAction(SemanticsAction.tap), isTrue);
}

Finder _dashboardScrollable() => find
    .descendant(
      of: find.byKey(const Key('project-profile-home')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _openProfileEditor(WidgetTester tester) async {
  final editor = find.byKey(const Key('project-profile-editor'));
  await tester.scrollUntilVisible(
    editor,
    250,
    scrollable: _dashboardScrollable(),
  );
  await tester.tap(find.text('Profil alanlarını düzenle'));
  await tester.pumpAndSettle();
}

Future<void> _renameVisibleProject(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('project-profile-name')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('project-profile-edit-name')),
    name,
  );
  await tester.tap(find.byKey(const Key('project-profile-save-name')));
  await tester.pumpAndSettle();
}

class _RenamingAgenda extends FakeAgendaApplication
    implements ProjectLifecycleApplication {
  _RenamingAgenda({required super.projects});

  final List<RenameProjectCommand> renameCommands = [];
  Object? renameFailure;
  Completer<void>? renameGate;
  int appliedRenames = 0;

  @override
  Future<MobileProject> renameProject(RenameProjectCommand command) async {
    renameCommands.add(command);
    final gate = renameGate;
    if (gate != null) await gate.future;
    final failure = renameFailure;
    if (failure != null) throw failure;
    final project = projects.singleWhere(
      (item) => item.id == command.projectId,
    );
    if (project.revision != command.expectedRevision) {
      throw const AgendaValidationFailure(
        'Proje başka bir işlem tarafından değiştirilmiş.',
      );
    }
    final renamed = MobileProject(
      id: project.id,
      name: command.name,
      createdAt: project.createdAt,
      updatedAt: '2026-09-05T04:00:00Z',
      revision: project.revision + 1,
      archivedAt: project.archivedAt,
    );
    projects = [
      for (final item in projects)
        if (item.id == project.id) renamed else item,
    ];
    appliedRenames += 1;
    return renamed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected lifecycle call: ${invocation.memberName}');
}

class _PendingProfileAgenda extends FakeAgendaApplication {
  _PendingProfileAgenda({required super.projects});

  Completer<void>? updateGate;

  @override
  Future<ProjectProfileField> updateProjectProfileField(
    UpdateProjectProfileFieldCommand command,
  ) async {
    final gate = updateGate;
    if (gate != null) await gate.future;
    return super.updateProjectProfileField(command);
  }
}

MobileProject _project(String id, String name, {int revision = 1}) =>
    MobileProject(
      id: id,
      name: name,
      createdAt: '2026-09-04T06:00:00Z',
      updatedAt: '2026-09-04T06:00:00Z',
      revision: revision,
    );

ProjectMetadata _metadata(String projectId, {String? address}) =>
    ProjectMetadata(
      projectId: projectId,
      revision: address == null ? 0 : 1,
      createdAt: '2026-09-04T06:00:00Z',
      updatedAt: '2026-09-04T06:00:00Z',
      address: address,
    );

ProjectProfile _profile(
  MobileProject project, {
  String totalFloors = '',
  String totalArea = '',
  String yibf = '',
}) {
  final values = [totalFloors, totalArea, yibf];
  return ProjectProfile(
    project: project,
    fields: [
      for (
        var index = 0;
        index < ProjectProfileBuiltinField.values.length;
        index++
      )
        ProjectProfileField(
          id:
              'profile-${project.id}-'
              '${ProjectProfileBuiltinField.values[index].storageValue}',
          projectId: project.id,
          builtinField: ProjectProfileBuiltinField.values[index],
          label: ProjectProfileBuiltinField.values[index].label,
          value: values[index],
          sortOrder: index,
          revision: values[index].isEmpty ? 0 : 1,
          createdAt: project.createdAt,
          updatedAt: project.updatedAt,
        ),
    ],
  );
}
