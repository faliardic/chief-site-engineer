import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('zero projects clears selection and one project auto-selects', () {
    final session = ActiveProjectSession();
    addTearDown(session.dispose);

    expect(session.reconcile(const []), isFalse);
    expect(session.selectedProjectId, isNull);

    expect(session.reconcile([_project('a', 'Kuzey')]), isTrue);
    expect(session.selectedProjectId, 'a');

    expect(session.reconcile(const []), isTrue);
    expect(session.selectedProjectId, isNull);
  });

  test('multiple projects require an explicit valid selection', () {
    final session = ActiveProjectSession();
    addTearDown(session.dispose);
    final projects = [_project('a', 'Kuzey'), _project('b', 'Güney')];

    session.reconcile(projects);
    expect(session.selectedProjectId, isNull);
    expect(session.select('missing', projects), isFalse);
    expect(session.selectedProjectId, isNull);

    expect(session.select('b', projects), isTrue);
    expect(session.selectedProjectId, 'b');
    expect(session.selectedProject(projects)?.name, 'Güney');
  });

  test('latest active list invalidates stale or archived selection', () {
    final session = ActiveProjectSession();
    addTearDown(session.dispose);
    final projects = [_project('a', 'Kuzey'), _project('b', 'Güney')];
    session.reconcile(projects);
    session.select('a', projects);

    session.reconcile([
      _project('a', 'Kuzey', archivedAt: '2026-08-30T08:00:00Z'),
      _project('b', 'Güney'),
      _project('c', 'Doğu'),
    ]);

    expect(session.selectedProjectId, isNull);
  });
}

MobileProject _project(String id, String name, {String? archivedAt}) =>
    MobileProject(
      id: id,
      name: name,
      createdAt: '2026-08-30T06:00:00Z',
      updatedAt: '2026-08-30T06:00:00Z',
      revision: 1,
      archivedAt: archivedAt,
    );
