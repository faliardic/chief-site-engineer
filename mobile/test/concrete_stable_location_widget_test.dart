import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _projectB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _locationA = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _locationB = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _classA = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _classB = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

void main() {
  testWidgets(
    'project-scoped Mahal stays separate from required element detail',
    (tester) async {
      _configureView(tester);
      final concrete = _RecordingConcrete();
      final locations = _LocationApplication(
        locations: const [_Fixtures.locationA, _Fixtures.locationB],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConcretePourFormPage(
            concrete: concrete,
            projects: const [_Fixtures.projectA, _Fixtures.projectB],
            projectLocations: locations,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Katalog Mahali (opsiyonel)'), findsOneWidget);
      expect(find.text('Eleman / yer tarifi'), findsOneWidget);
      await _selectDropdownOption(
        tester,
        const Key('concrete-location-selector'),
        'Blok A',
      );

      final projectDropdown = find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<MobileProject>,
      );
      await _scrollTo(tester, projectDropdown);
      await tester.tap(projectDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Güney').last);
      await tester.pumpAndSettle();

      expect(locations.lastProjectId, _projectB);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const Key('concrete-location-selector')),
            )
            .initialValue,
        isNull,
      );
      await _selectDropdownOption(
        tester,
        const Key('concrete-location-selector'),
        'Saha B',
      );

      await tester.enterText(_textField('Eleman / yer tarifi'), 'Perde P2');
      await _selectDropdownOption(
        tester,
        const Key('concrete-class-selector'),
        'C35/45',
      );
      await tester.enterText(_textField('Planlanan metraj (m³)'), '18,5');
      final submit = find.widgetWithText(
        FilledButton,
        'Beton paketini oluştur',
      );
      await _scrollTo(tester, submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(concrete.lastCreateCommand?.projectId, _projectB);
      expect(concrete.lastCreateCommand?.locationId, _locationB);
      expect(concrete.lastCreateCommand?.elementLocation, 'Perde P2');
      expect(concrete.lastCreateCommand?.concreteClassId, _classB);
      expect(concrete.lastCreateCommand?.plannedVolumeM3, 18.5);
      expect(tester.takeException(), isNull);
    },
  );
}

void _configureView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _selectDropdownOption(
  WidgetTester tester,
  Key key,
  String label,
) async {
  final dropdown = find.byKey(key);
  await _scrollTo(tester, dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Finder _textField(String label) => find.widgetWithText(TextFormField, label);

abstract final class _Fixtures {
  static const projectA = MobileProject(
    id: _projectA,
    name: 'Kuzey',
    createdAt: '2026-08-09T06:00:00Z',
    updatedAt: '2026-08-09T06:00:00Z',
    revision: 1,
  );
  static const projectB = MobileProject(
    id: _projectB,
    name: 'Güney',
    createdAt: '2026-08-09T06:00:00Z',
    updatedAt: '2026-08-09T06:00:00Z',
    revision: 1,
  );
  static const locationA = MobileProjectLocation(
    id: _locationA,
    projectId: _projectA,
    displayName: 'Blok A',
    parentLocationId: null,
    revision: 1,
    createdAt: '2026-08-09T06:00:00Z',
    updatedAt: '2026-08-09T06:00:00Z',
    archivedAt: null,
  );
  static const locationB = MobileProjectLocation(
    id: _locationB,
    projectId: _projectB,
    displayName: 'Saha B',
    parentLocationId: null,
    revision: 1,
    createdAt: '2026-08-09T06:00:00Z',
    updatedAt: '2026-08-09T06:00:00Z',
    archivedAt: null,
  );
}

class _LocationApplication extends Fake implements ProjectLocationApplication {
  _LocationApplication({required this.locations});

  final List<MobileProjectLocation> locations;
  String? lastProjectId;

  @override
  Future<List<MobileProjectLocation>> listProjectLocations(
    ProjectLocationQuery query,
  ) async {
    lastProjectId = query.projectId;
    return locations
        .where(
          (item) =>
              item.projectId == query.projectId &&
              item.isArchived ==
                  (query.archiveFilter ==
                      ProjectLocationArchiveFilter.archived),
        )
        .toList(growable: false);
  }
}

class _RecordingConcrete extends Fake implements ConcreteApplication {
  CreateConcretePourCommand? lastCreateCommand;

  @override
  Future<List<ProjectConcreteClass>> listConcreteClasses(
    String projectId, {
    bool includeArchived = false,
  }) async => [
    ProjectConcreteClass(
      id: projectId == _projectA ? _classA : _classB,
      projectId: projectId,
      displayName: projectId == _projectA ? 'C30/37' : 'C35/45',
      normalizedName: projectId == _projectA ? 'c30/37' : 'c35/45',
      defaultTargetSlump: 'S3',
      revision: 1,
      createdAt: '2026-08-09T06:00:00Z',
      updatedAt: '2026-08-09T06:00:00Z',
      archivedAt: null,
    ),
  ];

  @override
  Future<ConcretePourDetail> createPour(
    CreateConcretePourCommand command,
  ) async {
    lastCreateCommand = command;
    throw const AgendaValidationFailure('Widget kayıt yakalayıcısı.');
  }
}
