import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _projectB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _parentA = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _childA = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _locationB = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
const _logId = 'ffffffff-ffff-4fff-8fff-ffffffffffff';

void main() {
  testWidgets('project switch reloads and submits the selected stable Mahal', (
    tester,
  ) async {
    _configureView(tester);
    final agenda = FakeAgendaApplication(
      projects: const [_ProjectFixtures.projectA, _ProjectFixtures.projectB],
    );
    final locations = _LocationApplication(
      locations: const [
        _ProjectFixtures.parentA,
        _ProjectFixtures.childA,
        _ProjectFixtures.locationB,
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReminderFormPage(agenda: agenda, projectLocations: locations),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-title')),
      'Kalıp kontrolünü hatırlat',
    );

    await _selectDropdownOption(tester, const Key('reminder-project'), 'Kuzey');
    await _openOptionalDetails(tester);
    await _selectDropdownOption(
      tester,
      const Key('reminder-location-selector'),
      'Blok A › Kat 1',
    );

    await _scrollTo(tester, find.byKey(const Key('reminder-project')));
    await _selectDropdownOption(tester, const Key('reminder-project'), 'Güney');
    expect(locations.lastProjectId, _projectB);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('reminder-location-selector')),
          )
          .initialValue,
      isNull,
    );

    await _selectDropdownOption(
      tester,
      const Key('reminder-location-selector'),
      'Saha B',
    );
    await _scrollTo(tester, find.byKey(const Key('submit-reminder')));
    await tester.tap(find.byKey(const Key('submit-reminder')));
    await tester.pumpAndSettle();

    expect(agenda.lastReminderCommand?.projectId, _projectB);
    expect(agenda.lastReminderCommand?.locationId, _locationB);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy source context remains visible without stable adoption', (
    tester,
  ) async {
    _configureView(tester);
    final agenda = FakeAgendaApplication(
      projects: const [_ProjectFixtures.projectA],
    );
    final locations = _LocationApplication(
      locations: const [_ProjectFixtures.parentA, _ProjectFixtures.childA],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReminderFormPage(
          agenda: agenda,
          projectLocations: locations,
          log: _sourceLog(location: 'Eski saha tarifi'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openOptionalDetails(tester);

    expect(
      find.byKey(const Key('reminder-legacy-location-context')),
      findsOneWidget,
    );
    expect(find.text('Eski serbest mahal: Eski saha tarifi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('linked archived source Mahal is retained in the selector', (
    tester,
  ) async {
    _configureView(tester);
    final agenda = FakeAgendaApplication(
      projects: const [_ProjectFixtures.projectA],
    );
    final locations = _LocationApplication(locations: const []);

    await tester.pumpWidget(
      MaterialApp(
        home: ReminderFormPage(
          agenda: agenda,
          projectLocations: locations,
          log: _sourceLog(
            locationId: _childA,
            location: 'Eski Kat 1',
            stableLocationName: 'Kat 1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openOptionalDetails(tester);

    expect(
      find.byKey(const Key('reminder-archived-location-context')),
      findsOneWidget,
    );
    expect(find.text('Kat 1 (Arşivli)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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

Future<void> _openOptionalDetails(WidgetTester tester) async {
  final details = find.byKey(const Key('reminder-optional-details'));
  await _scrollTo(tester, details);
  await tester.tap(details);
  await tester.pumpAndSettle();
  await _scrollTo(tester, find.byKey(const Key('reminder-location-selector')));
}

AgendaLog _sourceLog({
  String? locationId,
  String? location,
  String? stableLocationName,
}) => AgendaLog(
  id: _logId,
  projectId: _projectA,
  projectName: 'Kuzey',
  observedAt: '2026-08-09T07:00:00Z',
  createdAt: '2026-08-09T07:00:00Z',
  updatedAt: '2026-08-09T07:00:00Z',
  category: AgendaCategory.inspection,
  description: 'Kontrol kaydı',
  location: location,
  notes: null,
  revision: 1,
  locationId: locationId,
  stableLocationName: stableLocationName,
  stableLocationArchivedAt: locationId == null ? null : '2026-08-09T08:00:00Z',
);

abstract final class _ProjectFixtures {
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
  static const parentA = MobileProjectLocation(
    id: _parentA,
    projectId: _projectA,
    displayName: 'Blok A',
    parentLocationId: null,
    revision: 1,
    createdAt: '2026-08-09T06:00:00Z',
    updatedAt: '2026-08-09T06:00:00Z',
    archivedAt: null,
  );
  static const childA = MobileProjectLocation(
    id: _childA,
    projectId: _projectA,
    displayName: 'Kat 1',
    parentLocationId: _parentA,
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
