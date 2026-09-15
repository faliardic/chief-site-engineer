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
import 'package:chief_site_engineer/domain/project_information_models.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:chief_site_engineer/features/projects/project_information_page.dart';
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
      ProjectInformationPresentationSeed? openedSeed;

      await tester.pumpWidget(
        fixture.app(
          onOpenProjectInformation: (projectId, seed) {
            openedProjectId = projectId;
            openedSeed = seed;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktif Proje'), findsOneWidget);
      expect(find.text('Hızlı Bilgiler'), findsOneWidget);
      expect(find.text('+ Ekle'), findsOneWidget);
      expect(find.text('Düzenle'), findsOneWidget);
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

      // Q05 S6C1: the Dashboard hands over its already-loaded, exact-project
      // presentation state as a seed so the pushed page can paint
      // immediately instead of duplicating the full read.
      expect(openedSeed, isNotNull);
      expect(openedSeed!.projectId, project.id);
      expect(openedSeed!.snapshot.projectId, project.id);
      expect(openedSeed!.snapshot.metadata?.address, 'İnönü Caddesi 12');
    },
  );

  testWidgets('no exact-project presentation seed is offered when Dashboard '
      'information for the project is not ready', (tester) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project])
      ..source.projectReads[project.id] = [Completer<MobileProject>().future];
    addTearDown(fixture.dispose);
    String? openedProjectId;
    var openedSeedCalls = 0;
    Object? openedSeed = 'unset';

    await tester.pumpWidget(
      fixture.app(
        onOpenProjectInformation: (projectId, seed) {
          openedProjectId = projectId;
          openedSeed = seed;
          openedSeedCalls += 1;
        },
      ),
    );
    await tester.pump();

    final allInfo = find.byKey(const Key('dashboard-open-project-information'));
    expect(allInfo, findsOneWidget);
    final button = tester.widget<OutlinedButton>(allInfo);
    expect(button.onPressed, isNull);
    expect(openedSeedCalls, 0);
    expect(openedProjectId, isNull);
    expect(openedSeed, 'unset');
  });

  testWidgets('inventory failure does not look like empty quick information', (
    tester,
  ) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project])
      ..source.inventoryFailure = StateError('inventory unavailable');
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_, _) {}));
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
        fixture.app(textScale: 1.8, onOpenProjectInformation: (_, _) {}),
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
      final quickAdd = find.byKey(const Key('dashboard-quick-info-add'));
      final quickEdit = find.byKey(
        const Key('dashboard-quick-info-edit-toggle'),
      );
      expect(find.text('+ Ekle'), findsOneWidget);
      expect(find.text('Düzenle'), findsOneWidget);
      for (final action in [quickAdd, quickEdit]) {
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

      await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_, _) {}));
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
        await tester.pumpWidget(
          fixture.app(onOpenProjectInformation: (_, _) {}),
        );
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
    await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_, _) {}));
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

  testWidgets('compact tools preserves exact project actions', (tester) async {
    final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final fixture = _Fixture(projects: [project]);
    addTearDown(fixture.dispose);
    String? openedProject;

    await tester.pumpWidget(
      fixture.app(
        onOpenPlan: (projectId) => openedProject = projectId,
        onOpenProjectInformation: (_, _) {},
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
              onOpenProjectInformation: (_, _) {},
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

    await tester.pumpWidget(fixture.app(onOpenProjectInformation: (_, _) {}));
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

  testWidgets(
    'durable pins keep order, cap six and never rebind unavailable keys',
    (tester) async {
      final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final mutations = _DashboardMutations();
      for (var index = 0; index < 7; index += 1) {
        mutations.entries.add(_dashboardUserEntry(project.id, index));
        mutations.pins.add(
          _dashboardPin(
            project.id,
            'pin-$index',
            ProjectInformationKey(
              space: ProjectInformationKeySpace.userEntry,
              id: 'entry-$index',
            ),
            index,
          ),
        );
      }
      mutations.pins.insert(
        0,
        _dashboardPin(
          project.id,
          'missing-pin',
          const ProjectInformationKey(
            space: ProjectInformationKeySpace.userEntry,
            id: 'removed-entry',
          ),
          -1,
          sourceAvailable: false,
        ),
      );
      final fixture = _Fixture(projects: [project], mutations: mutations);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dashboard-pinned-information-unavailable')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('dashboard-quick-information')),
          matching: find.byType(Card),
        ),
        findsNWidgets(6),
      );
      for (var index = 0; index < 6; index += 1) {
        expect(find.text('Pin $index'), findsOneWidget);
      }
      expect(find.text('Pin 6'), findsNothing);
      expect(find.text('Aktif blok'), findsNothing);
    },
  );

  testWidgets(
    'Issue #823: Hızlı Bilgiler middle-pin Undo restores exact prior order '
    'without full-page loading or deleting source entries',
    (tester) async {
      final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final mutations = _DashboardMutations();
      for (var index = 0; index < 3; index += 1) {
        mutations.entries.add(_dashboardUserEntry(project.id, index));
        mutations.pins.add(
          _dashboardPin(
            project.id,
            'pin-$index',
            ProjectInformationKey(
              space: ProjectInformationKeySpace.userEntry,
              id: 'entry-$index',
            ),
            index,
          ),
        );
      }
      final fixture = _Fixture(projects: [project], mutations: mutations);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      expect(mutations.pins.map((pin) => pin.id).toList(), [
        'pin-0',
        'pin-1',
        'pin-2',
      ]);

      await tester.tap(
        find.byKey(const Key('dashboard-quick-info-edit-toggle')),
      );
      await tester.pumpAndSettle();
      final remove = find.byKey(const Key('dashboard-quick-remove-pin-pin-1'));
      final drag = find.byKey(const Key('dashboard-quick-drag-pin-pin-1'));
      expect(remove, findsOneWidget);
      expect(drag, findsOneWidget);
      for (final control in [remove, drag]) {
        expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      }

      await tester.tap(remove);
      await tester.pump();
      expect(find.byKey(const Key('dashboard-loading-projects')), findsNothing);
      expect(
        find.byKey(const Key('dashboard-project-information-loading')),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(mutations.unpinned.single.id, 'pin-1');
      expect(mutations.pins.map((pin) => pin.id).toList(), ['pin-0', 'pin-2']);
      expect(find.text('Pin 1 Hızlı Bilgilerden kaldırıldı.'), findsOneWidget);
      expect(mutations.entries.map((entry) => entry.id).toList(), [
        'entry-0',
        'entry-1',
        'entry-2',
      ]);

      await tester.tap(find.text('Geri al'));
      await tester.pump();
      expect(
        find.byKey(const Key('dashboard-project-information-loading')),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(mutations.pinned.single.key.id, 'entry-1');
      expect(mutations.pins.map((pin) => pin.id).toList(), [
        'pin-0',
        'pin-1',
        'pin-2',
      ]);
      expect(mutations.reordered, hasLength(1));
      expect(mutations.reordered.single.orderedPinIds, [
        'pin-0',
        'pin-1',
        'pin-2',
      ]);
      expect(find.text('Pin 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Issue #823: Undo never overwrites a legitimate concurrent reorder of '
    'the remaining pins',
    (tester) async {
      final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final mutations = _DashboardMutations();
      for (var index = 0; index < 3; index += 1) {
        mutations.entries.add(_dashboardUserEntry(project.id, index));
        mutations.pins.add(
          _dashboardPin(
            project.id,
            'pin-$index',
            ProjectInformationKey(
              space: ProjectInformationKeySpace.userEntry,
              id: 'entry-$index',
            ),
            index,
          ),
        );
      }
      final fixture = _Fixture(projects: [project], mutations: mutations);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('dashboard-quick-info-edit-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('dashboard-quick-remove-pin-pin-1')),
      );
      await tester.pumpAndSettle();
      expect(mutations.pins.map((pin) => pin.id).toList(), ['pin-0', 'pin-2']);

      // A legitimate concurrent action reorders the two remaining pins
      // while the Undo snackbar is still showing — this must survive.
      final beforeReorder = {
        for (final pin in mutations.pins) pin.id: pin.revision,
      };
      await mutations.reorderPins(
        ReorderProjectInformationPinsCommand(
          eventId: 'concurrent-reorder',
          projectId: project.id,
          orderedPinIds: ['pin-2', 'pin-0'],
          expectedRevisions: beforeReorder,
        ),
      );
      expect(mutations.reordered, hasLength(1));

      await tester.tap(find.text('Geri al'));
      await tester.pump();
      await tester.pumpAndSettle();

      // setPin (stage 1) still succeeds — the pin itself is restored.
      expect(mutations.pinned.single.key.id, 'entry-1');
      expect(mutations.pins.map((pin) => pin.id).toSet(), {
        'pin-0',
        'pin-1',
        'pin-2',
      });
      // Stage 2 must NOT have issued a second, order-restoring reorderPins
      // call that would have overwritten the concurrent ['pin-2', 'pin-0']
      // reorder — only the one concurrent call above exists.
      expect(mutations.reordered, hasLength(1));
      // The concurrent reorder's relative order survives; the restored pin
      // is appended, not spliced back into its old middle position.
      expect(mutations.pins.map((pin) => pin.id).toList(), [
        'pin-2',
        'pin-0',
        'pin-1',
      ]);
      expect(
        find.text(
          'Bilgi geri eklendi; eşzamanlı değişiklik nedeniyle sıra korunamadı.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Issue #823: a post-restore order-fix failure is reported as partial '
    'success, not total Undo failure, and still revalidates',
    (tester) async {
      final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final mutations = _DashboardMutations();
      for (var index = 0; index < 3; index += 1) {
        mutations.entries.add(_dashboardUserEntry(project.id, index));
        mutations.pins.add(
          _dashboardPin(
            project.id,
            'pin-$index',
            ProjectInformationKey(
              space: ProjectInformationKeySpace.userEntry,
              id: 'entry-$index',
            ),
            index,
          ),
        );
      }
      final fixture = _Fixture(projects: [project], mutations: mutations);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('dashboard-quick-info-edit-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('dashboard-quick-remove-pin-pin-1')),
      );
      await tester.pumpAndSettle();

      // The concurrent state is unchanged (safe to restore order), but the
      // order-restoring reorderPins call itself fails transiently.
      mutations.reorderFailure = const ProjectInformationFailure(
        'synthetic_reorder_failure',
      );

      await tester.tap(find.text('Geri al'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Stage 1 (setPin) succeeded: the pin is genuinely restored — this
      // must never be reported as if Undo failed entirely.
      expect(mutations.pinned.single.key.id, 'entry-1');
      expect(mutations.pins.map((pin) => pin.id).toSet(), {
        'pin-0',
        'pin-1',
        'pin-2',
      });
      expect(mutations.reordered, hasLength(1));
      expect(find.text('Bilgi geri eklendi; sıra korunamadı.'), findsOneWidget);
      expect(find.text('Geri alma tamamlanamadı.'), findsNothing);
      // Nonblocking revalidation still ran: the restored pin is visible on
      // Hızlı Bilgiler, not stuck showing the pre-Undo two-pin state.
      expect(find.text('Pin 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Issue #823: a stale Undo snackbar after a real project switch is a '
    'safe no-op — it never mutates the newly active project',
    (tester) async {
      final first = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final second = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
      final mutations = _DashboardMutations();
      mutations.entries.add(_dashboardUserEntry(first.id, 0));
      mutations.pins.add(
        _dashboardPin(
          first.id,
          'pin-0',
          const ProjectInformationKey(
            space: ProjectInformationKeySpace.userEntry,
            id: 'entry-0',
          ),
          0,
        ),
      );
      final fixture = _Fixture(projects: [first, second], mutations: mutations);
      addTearDown(fixture.dispose);
      fixture.session.select(first.id, [first, second]);

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('dashboard-quick-info-edit-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('dashboard-quick-remove-pin-pin-0')),
      );
      await tester.pumpAndSettle();
      expect(mutations.unpinned.single.id, 'pin-0');
      final undo = find.text('Geri al');
      expect(undo, findsOneWidget);

      // A real project switch happens while the Undo snackbar is still up.
      expect(fixture.session.select(second.id, [first, second]), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Güney'), findsOneWidget);

      await tester.tap(undo, warnIfMissed: false);
      await tester.pump();
      await tester.pumpAndSettle();

      // The stale Undo must be a safe no-op: no setPin call at all, and
      // project A's removed pin stays removed.
      expect(mutations.pinned, isEmpty);
      expect(mutations.pins.map((pin) => pin.id).toList(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Issue #823: a pin added through the shared application from another '
    'page appears in Hızlı Bilgiler without full-page loading, and a pin '
    'change for a different, non-selected project never leaks in',
    (tester) async {
      final first = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final second = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
      final mutations = _DashboardMutations();
      mutations.entries.add(_dashboardUserEntry(first.id, 0));
      mutations.entries.add(_dashboardUserEntry(second.id, 1));
      final fixture = _Fixture(projects: [first, second], mutations: mutations);
      addTearDown(fixture.dispose);
      fixture.session.select(first.id, [first, second]);

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();

      // No pins yet: Hızlı Bilgiler shows the computed fallback set.
      expect(find.text('Pin 0'), findsNothing);

      // Simulated: the pin is added from "Tüm proje bilgileri" — a
      // different page instance that shares this exact same
      // ProjectInformationApplication in production — never through any
      // Dashboard-owned mutation call.
      await fixture.projectInformation.setPin(
        const SetProjectInformationPinCommand(
          id: 'pin-0',
          eventId: 'evt-pin-0',
          projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          key: ProjectInformationKey(
            space: ProjectInformationKeySpace.userEntry,
            id: 'entry-0',
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('dashboard-project-information-loading')),
        findsNothing,
      );
      expect(find.text('Pin 0'), findsOneWidget);

      // A pin change for the *other*, non-selected project must never leak
      // into the currently active project's Hızlı Bilgiler.
      await fixture.projectInformation.setPin(
        const SetProjectInformationPinCommand(
          id: 'pin-1',
          eventId: 'evt-pin-1',
          projectId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          key: ProjectInformationKey(
            space: ProjectInformationKeySpace.userEntry,
            id: 'entry-1',
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Pin 1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Issue #823: a Dashboard-owned pin mutation revalidates exactly once, '
    'even though the shared informationChanges broadcast is active',
    (tester) async {
      final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final mutations = _DashboardMutations();
      for (var index = 0; index < 3; index += 1) {
        mutations.entries.add(_dashboardUserEntry(project.id, index));
        mutations.pins.add(
          _dashboardPin(
            project.id,
            'pin-$index',
            ProjectInformationKey(
              space: ProjectInformationKeySpace.userEntry,
              id: 'entry-$index',
            ),
            index,
          ),
        );
      }
      final fixture = _Fixture(projects: [project], mutations: mutations);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('dashboard-quick-info-edit-toggle')),
      );
      await tester.pumpAndSettle();

      // Dashboard-owned remove: the broadcast is the single revalidation
      // trigger, so the explicit reload that used to run alongside it must be
      // gone — exactly one nonblocking companion-read turn, no full-page
      // loading.
      final beforeRemove = mutations.companionReads;
      await tester.tap(
        find.byKey(const Key('dashboard-quick-remove-pin-pin-1')),
      );
      await tester.pump();
      expect(
        find.byKey(const Key('dashboard-project-information-loading')),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(mutations.unpinned.single.id, 'pin-1');
      expect(mutations.companionReads - beforeRemove, 1);

      // Dashboard-owned drag reorder: exactly one further revalidation.
      final beforeReorder = mutations.companionReads;
      final drag = find.byKey(const Key('dashboard-quick-drag-pin-pin-0'));
      final target = find.byKey(const Key('dashboard-quick-pin-pin-2'));
      final gesture = await tester.startGesture(tester.getCenter(drag));
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(
        find.byKey(const Key('dashboard-project-information-loading')),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(mutations.reordered, hasLength(1));
      expect(mutations.reordered.single.orderedPinIds, ['pin-2', 'pin-0']);
      expect(mutations.companionReads - beforeReorder, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Issue #823: editing a pinned user entry through the shared application '
    'refreshes Hızlı Bilgiler immediately, exactly once, without a blocking '
    'loading surface and without leaking another project',
    (tester) async {
      final first = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final second = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
      final mutations = _DashboardMutations();
      mutations.entries.add(
        ProjectInformationEntry(
          id: 'entry-0',
          projectId: first.id,
          category: ProjectInformationCategory.technical,
          label: 'Pin 0',
          value: const ProjectInformationEntryValue.text('ESKI'),
          revision: 1,
          createdAt: '2026-09-13T09:00:00.000Z',
          updatedAt: '2026-09-13T09:00:00.000Z',
        ),
      );
      mutations.entries.add(_dashboardUserEntry(second.id, 1));
      mutations.pins.add(
        _dashboardPin(
          first.id,
          'pin-0',
          const ProjectInformationKey(
            space: ProjectInformationKeySpace.userEntry,
            id: 'entry-0',
          ),
          0,
        ),
      );
      final fixture = _Fixture(projects: [first, second], mutations: mutations);
      addTearDown(fixture.dispose);
      fixture.session.select(first.id, [first, second]);

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      expect(find.text('ESKI'), findsOneWidget);

      // Simulated: the value is edited from "Tüm proje bilgileri" — a separate
      // page instance sharing this exact same application in production.
      final before = mutations.companionReads;
      await fixture.projectInformation.updateUserEntry(
        const UpdateProjectInformationEntryCommand(
          id: 'entry-0',
          eventId: 'evt-update-0',
          projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          expectedRevision: 1,
          category: ProjectInformationCategory.technical,
          label: 'Pin 0',
          value: ProjectInformationEntryValue.text('YENI'),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const Key('dashboard-project-information-loading')),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(find.text('YENI'), findsOneWidget);
      expect(find.text('ESKI'), findsNothing);
      expect(mutations.companionReads - before, 1);

      // A change for the other, non-selected project never leaks in and never
      // revalidates the visible project.
      final afterUpdate = mutations.companionReads;
      await fixture.projectInformation.updateUserEntry(
        const UpdateProjectInformationEntryCommand(
          id: 'entry-1',
          eventId: 'evt-update-1',
          projectId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          expectedRevision: 1,
          category: ProjectInformationCategory.technical,
          label: 'Pin 1',
          value: ProjectInformationEntryValue.text('SIZINTI'),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(mutations.companionReads - afterUpdate, 0);
      expect(find.text('SIZINTI'), findsNothing);
      expect(find.text('YENI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Issue #823: drag reorder covers the full active set beyond the six '
    'visible cards and includes an unavailable pin',
    (tester) async {
      final project = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
      final mutations = _DashboardMutations();
      for (var index = 0; index < 7; index += 1) {
        mutations.entries.add(_dashboardUserEntry(project.id, index));
        mutations.pins.add(
          _dashboardPin(
            project.id,
            'pin-$index',
            ProjectInformationKey(
              space: ProjectInformationKeySpace.userEntry,
              id: 'entry-$index',
            ),
            index,
          ),
        );
      }
      mutations.pins.add(
        _dashboardPin(
          project.id,
          'missing-pin',
          const ProjectInformationKey(
            space: ProjectInformationKeySpace.userEntry,
            id: 'removed-entry',
          ),
          7,
          sourceAvailable: false,
        ),
      );
      final fixture = _Fixture(projects: [project], mutations: mutations);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('dashboard-quick-info-edit-toggle')),
      );
      await tester.pumpAndSettle();

      final firstDrag = find.byKey(const Key('dashboard-quick-drag-pin-pin-0'));
      final secondCard = find.byKey(const Key('dashboard-quick-pin-pin-1'));
      final gesture = await tester.startGesture(tester.getCenter(firstDrag));
      await gesture.moveTo(tester.getCenter(secondCard));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(
        find.byKey(const Key('dashboard-project-information-loading')),
        findsNothing,
      );
      await tester.pumpAndSettle();

      expect(mutations.reordered, hasLength(1));
      expect(mutations.reordered.single.orderedPinIds, [
        'pin-1',
        'pin-0',
        'pin-2',
        'pin-3',
        'pin-4',
        'pin-5',
        'pin-6',
        'missing-pin',
      ]);
      expect(mutations.reordered.single.expectedRevisions.keys.toSet(), {
        'pin-0',
        'pin-1',
        'pin-2',
        'pin-3',
        'pin-4',
        'pin-5',
        'pin-6',
        'missing-pin',
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('project switch rejects delayed user entries and pins', (
    tester,
  ) async {
    final first = _project('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Kuzey');
    final second = _project('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Güney');
    final staleEntries = Completer<List<ProjectInformationEntry>>();
    final mutations = _DashboardMutations();
    final firstEntry = _dashboardUserEntry(first.id, 1);
    final secondEntry = _dashboardUserEntry(second.id, 2);
    mutations.entries.addAll([firstEntry, secondEntry]);
    mutations.entryReads[first.id] = [staleEntries.future];
    mutations.pins.addAll([
      _dashboardPin(
        first.id,
        'first-pin',
        const ProjectInformationKey(
          space: ProjectInformationKeySpace.userEntry,
          id: 'entry-1',
        ),
        0,
      ),
      _dashboardPin(
        second.id,
        'second-pin',
        const ProjectInformationKey(
          space: ProjectInformationKeySpace.userEntry,
          id: 'entry-2',
        ),
        0,
      ),
    ]);
    final fixture = _Fixture(projects: [first, second], mutations: mutations);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();
    expect(fixture.session.select(first.id, [first, second]), isTrue);
    await tester.pump();
    await tester.pump();
    expect(fixture.session.select(second.id, [first, second]), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Pin 2'), findsOneWidget);

    staleEntries.complete([firstEntry]);
    await tester.pumpAndSettle();
    expect(find.text('Güney'), findsOneWidget);
    expect(find.text('Pin 2'), findsOneWidget);
    expect(find.text('Pin 1'), findsNothing);
  });

  testWidgets(
    'Konum/Paylaş are hidden without a canonical site location and never '
    'fall back to postal address',
    (tester) async {
      final project = _project('33333333-3333-4333-8333-333333333333', 'Kuzey');
      final fixture = _Fixture(projects: [project]);
      addTearDown(fixture.dispose);
      // A postal address exists, but no canonical site location — Konum
      // must not invent one from it.
      fixture.source.metadataByProject[project.id] = _metadata(
        project.id,
        address: 'İnönü Caddesi 12',
      );

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard-action-location')), findsNothing);
      expect(
        find.byKey(const Key('dashboard-action-share-location')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Konum opens the exact canonical site location and Paylaş shares a safe '
    'payload with no internal identifiers',
    (tester) async {
      final project = _project('44444444-4444-4444-8444-444444444444', 'Kuzey');
      final mutations = _DashboardMutations()
        ..siteLocation = ProjectSiteLocation(
          projectId: project.id,
          latitude: 41.015137,
          longitude: 28.97953,
          revision: 1,
          createdAt: '2026-09-13T09:00:00.000Z',
          updatedAt: '2026-09-13T09:00:00.000Z',
        );
      final fixture = _Fixture(projects: [project], mutations: mutations);
      addTearDown(fixture.dispose);
      final launches = <Uri>[];
      final shared = <String>[];

      await tester.pumpWidget(
        fixture.app(
          launchUri: (uri) async {
            launches.add(uri);
            return true;
          },
          shareText: (text) async => shared.add(text),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard-action-location')));
      await tester.pumpAndSettle();
      expect(launches, hasLength(1));
      expect(launches.single.queryParameters['query'], '41.015137,28.97953');

      await tester.tap(
        find.byKey(const Key('dashboard-action-share-location')),
      );
      await tester.pumpAndSettle();
      expect(shared.single, contains('Kuzey'));
      expect(shared.single, contains('41.015137'));
      expect(shared.single, isNot(contains(project.id)));
    },
  );

  testWidgets('failed map launch reports safe feedback without mutation', (
    tester,
  ) async {
    final project = _project('55555555-5555-4555-8555-555555555555', 'Kuzey');
    final mutations = _DashboardMutations()
      ..siteLocation = ProjectSiteLocation(
        projectId: project.id,
        latitude: 41.015137,
        longitude: 28.97953,
        revision: 1,
        createdAt: '2026-09-13T09:00:00.000Z',
        updatedAt: '2026-09-13T09:00:00.000Z',
      );
    final fixture = _Fixture(projects: [project], mutations: mutations);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app(launchUri: (uri) async => false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboard-action-location')));
    await tester.pumpAndSettle();

    expect(find.text('Harita açılamadı.'), findsOneWidget);
    // No mutation — the location remains exactly as set.
    expect(mutations.siteLocation?.projectId, project.id);
  });

  testWidgets(
    'project switch never carries the previous project stale site location',
    (tester) async {
      final first = _project('66666666-6666-4666-8666-666666666666', 'Kuzey');
      final second = _project('77777777-7777-4777-8777-777777777777', 'Güney');
      final mutations = _DashboardMutations()
        ..siteLocation = ProjectSiteLocation(
          projectId: first.id,
          latitude: 41.015137,
          longitude: 28.97953,
          revision: 1,
          createdAt: '2026-09-13T09:00:00.000Z',
          updatedAt: '2026-09-13T09:00:00.000Z',
        );
      final fixture = _Fixture(projects: [first, second], mutations: mutations);
      addTearDown(fixture.dispose);
      final launches = <Uri>[];

      await tester.pumpWidget(
        fixture.app(
          launchUri: (uri) async {
            launches.add(uri);
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(fixture.session.select(first.id, [first, second]), isTrue);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dashboard-action-location')),
        findsOneWidget,
      );

      fixture.session.select(second.id, [first, second]);
      await tester.pumpAndSettle();

      // Second project has no site location of its own — Konum must hide,
      // never showing/using the first project's stale point.
      expect(find.byKey(const Key('dashboard-action-location')), findsNothing);
      expect(launches, isEmpty);
    },
  );
}

ProjectInformationEntry _dashboardUserEntry(String projectId, int index) =>
    ProjectInformationEntry(
      id: 'entry-$index',
      projectId: projectId,
      category: ProjectInformationCategory.technical,
      label: 'Pin $index',
      value: ProjectInformationEntryValue.number(index.toDouble()),
      unit: 'm',
      revision: 1,
      createdAt: '2026-09-13T09:00:00.000Z',
      updatedAt: '2026-09-13T09:00:00.000Z',
    );

ProjectInformationPin _dashboardPin(
  String projectId,
  String id,
  ProjectInformationKey key,
  int sortOrder, {
  bool sourceAvailable = true,
}) => ProjectInformationPin(
  id: id,
  projectId: projectId,
  key: key,
  sortOrder: sortOrder,
  revision: 1,
  createdAt: '2026-09-13T09:00:00.000Z',
  updatedAt: '2026-09-13T09:00:00.000Z',
  sourceAvailable: sourceAvailable,
);

class _DashboardMutations implements ProjectInformationMutationApplication {
  final List<ProjectInformationEntry> entries = [];
  final List<ProjectInformationPin> pins = [];
  final Map<String, List<Future<List<ProjectInformationEntry>>>> entryReads =
      {};

  @override
  Future<List<ProjectInformationEntry>> listUserEntries(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter =
        ProjectInformationArchiveFilter.active,
  }) async {
    final queued = entryReads[projectId];
    if (queued != null && queued.isNotEmpty) return queued.removeAt(0);
    return entries
        .where((entry) => entry.projectId == projectId && !entry.isArchived)
        .toList(growable: false);
  }

  @override
  Future<List<ProjectInformationPin>> listPins(String projectId) async {
    final selected = pins
        .where((pin) => pin.projectId == projectId)
        .toList(growable: false);
    selected.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return selected;
  }

  ProjectSiteLocation? siteLocation;

  /// Counts Dashboard information revalidation turns (entries into the shared
  /// companion-read boundary). Used to prove a Dashboard-owned pin mutation is
  /// revalidated exactly once by the shared `pinChanges` broadcast.
  int companionReads = 0;

  @override
  Future<ProjectSiteLocation?> getSiteLocation(String projectId) async =>
      siteLocation?.projectId == projectId ? siteLocation : null;

  @override
  Future<ProjectInformationCompanionReads> listCompanionReads(
    String projectId, {
    ProjectInformationArchiveFilter archiveFilter =
        ProjectInformationArchiveFilter.active,
  }) async {
    companionReads += 1;
    return ProjectInformationCompanionReads(
      userEntries: await listUserEntries(
        projectId,
        archiveFilter: archiveFilter,
      ),
      pins: await listPins(projectId),
      siteLocation: await getSiteLocation(projectId),
    );
  }

  final List<UpdateProjectInformationEntryCommand> updatedEntries = [];

  @override
  Future<ProjectInformationEntry> updateUserEntry(
    UpdateProjectInformationEntryCommand command,
  ) async {
    updatedEntries.add(command);
    final index = entries.indexWhere((entry) => entry.id == command.id);
    if (index < 0) {
      throw const ProjectInformationFailure('entry_not_found');
    }
    final current = entries[index];
    if (current.revision != command.expectedRevision) {
      throw const ProjectInformationRevisionConflict();
    }
    final next = ProjectInformationEntry(
      id: current.id,
      projectId: current.projectId,
      category: command.category,
      label: command.label,
      value: command.value,
      unit: command.unit,
      note: command.note,
      revision: current.revision + 1,
      createdAt: current.createdAt,
      updatedAt: '2026-09-14T11:00:00.000Z',
      archivedAt: current.archivedAt,
    );
    entries[index] = next;
    return next;
  }

  final List<ReorderProjectInformationPinsCommand> reordered = [];
  Object? reorderFailure;

  @override
  Future<List<ProjectInformationPin>> reorderPins(
    ReorderProjectInformationPinsCommand command,
  ) async {
    reordered.add(command);
    final failure = reorderFailure;
    if (failure != null) {
      reorderFailure = null;
      throw failure;
    }
    final active = pins
        .where((pin) => pin.projectId == command.projectId)
        .toList(growable: false);
    final activeIds = {for (final pin in active) pin.id};
    final orderedIds = command.orderedPinIds.toSet();
    if (command.orderedPinIds.length != active.length ||
        orderedIds.length != activeIds.length ||
        !orderedIds.containsAll(activeIds)) {
      throw const ProjectInformationFailure('pin_order_must_cover_active_set');
    }
    if (command.expectedRevisions.keys.toSet().length != activeIds.length ||
        !command.expectedRevisions.keys.toSet().containsAll(activeIds)) {
      throw const ProjectInformationFailure('pin_revision_set_mismatch');
    }
    for (final pin in active) {
      if (command.expectedRevisions[pin.id] != pin.revision) {
        throw const ProjectInformationRevisionConflict();
      }
    }
    final byId = {for (final pin in active) pin.id: pin};
    pins.removeWhere((pin) => pin.projectId == command.projectId);
    pins.addAll([
      for (var index = 0; index < command.orderedPinIds.length; index += 1)
        ProjectInformationPin(
          id: byId[command.orderedPinIds[index]]!.id,
          projectId: byId[command.orderedPinIds[index]]!.projectId,
          key: byId[command.orderedPinIds[index]]!.key,
          sortOrder: index,
          revision: byId[command.orderedPinIds[index]]!.revision + 1,
          createdAt: byId[command.orderedPinIds[index]]!.createdAt,
          updatedAt: '2026-09-14T10:00:00.000Z',
          sourceAvailable: byId[command.orderedPinIds[index]]!.sourceAvailable,
        ),
    ]);
    return listPins(command.projectId);
  }

  final List<SetProjectInformationPinCommand> pinned = [];
  final List<RemoveProjectInformationPinCommand> unpinned = [];

  final Map<String, String> _archivedPinIdsByKey = {};

  String _pinKeyString(ProjectInformationKey key) => '${key.space}:${key.id}';

  @override
  Future<ProjectInformationPin> setPin(
    SetProjectInformationPinCommand command,
  ) async {
    pinned.add(command);
    final activeMatch = pins.where(
      (existing) =>
          existing.key.space == command.key.space &&
          existing.key.id == command.key.id,
    );
    if (activeMatch.isNotEmpty) {
      if (activeMatch.single.id != command.id) {
        throw const ProjectInformationFailure('duplicate_active_pin');
      }
      return activeMatch.single;
    }
    final keyString = _pinKeyString(command.key);
    final archivedId = _archivedPinIdsByKey[keyString];
    if (archivedId != null && archivedId != command.id) {
      throw const ProjectInformationFailure('pin_identity_mismatch');
    }
    _archivedPinIdsByKey.remove(keyString);
    final projectPins = pins.where((pin) => pin.projectId == command.projectId);
    final pin = ProjectInformationPin(
      id: command.id,
      projectId: command.projectId,
      key: command.key,
      sortOrder: projectPins.length,
      revision: 1,
      createdAt: '2026-09-14T10:00:00.000Z',
      updatedAt: '2026-09-14T10:00:00.000Z',
      sourceAvailable: true,
    );
    pins.add(pin);
    return pin;
  }

  @override
  Future<void> removePin(RemoveProjectInformationPinCommand command) async {
    unpinned.add(command);
    final removed = pins.where((pin) => pin.id == command.id);
    if (removed.isNotEmpty) {
      _archivedPinIdsByKey[_pinKeyString(removed.single.key)] =
          removed.single.id;
    }
    pins.removeWhere((pin) => pin.id == command.id);
  }

  @override
  Future<ProjectSiteLocation> setSiteLocation(
    SetProjectSiteLocationCommand command,
  ) async {
    final saved = ProjectSiteLocation(
      projectId: command.projectId,
      latitude: command.latitude,
      longitude: command.longitude,
      revision: (siteLocation?.revision ?? 0) + 1,
      createdAt: '2026-09-13T10:00:00.000Z',
      updatedAt: '2026-09-13T10:00:00.000Z',
    );
    siteLocation = saved;
    return saved;
  }

  @override
  Future<void> clearSiteLocation(
    ClearProjectSiteLocationCommand command,
  ) async {
    siteLocation = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Fixture {
  _Fixture({
    required List<MobileProject> projects,
    FakeAgendaApplication? agenda,
    this.mutations,
  }) : agenda = agenda ?? FakeAgendaApplication(projects: projects) {
    source = _DashboardInformationSource(this.agenda);
  }

  final FakeAgendaApplication agenda;
  late final _DashboardInformationSource source;
  final ProjectInformationMutationApplication? mutations;
  final ActiveProjectSession session = ActiveProjectSession();
  // The exact same shared application instance the built Dashboard widget
  // receives — exposed so a test can call setPin/removePin/reorderPins on
  // it directly, simulating a mutation made by another page (e.g. "Tüm
  // proje bilgileri") that shares this same instance in production.
  late final ProjectInformationApplication projectInformation =
      ProjectInformationApplication(source: source, mutations: mutations);

  Widget app({
    VoidCallback? onCreateProject,
    DashboardProjectAction? onOpenPlan,
    DashboardProjectAction? onOpenProjectAlbum,
    DashboardProjectAction? onOpenCatalog,
    DashboardOpenProjectInformationAction? onOpenProjectInformation,
    DashboardTextAction? shareText,
    DashboardUriAction? launchUri,
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
        projectInformation: projectInformation,
        livingPlan: const UnavailableConstructionLivingPlanApplication(),
        session: session,
        onCreateProject: onCreateProject ?? () {},
        onOpenPlan: onOpenPlan,
        onOpenProjectAlbum: onOpenProjectAlbum,
        onOpenCatalog: onOpenCatalog,
        onOpenProjectInformation: onOpenProjectInformation,
        shareText: shareText,
        launchUri: launchUri,
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
