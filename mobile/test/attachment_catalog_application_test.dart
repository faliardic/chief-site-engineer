import 'dart:io';

import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = '11111111-1111-4111-8111-111111111111';
const _projectB = '22222222-2222-4222-8222-222222222222';

void main() {
  late Directory root;
  late AppDirectories directories;
  late _InspectOnlyStore store;
  late SqliteAttachmentCatalogApplication catalog;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cse_attachment_catalog_');
    directories = AppDirectories.fromSupportRoot(root, AppEnvironment.debug);
    await directories.ensureCreated();
    final database = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 8, 9, 12),
    );
    await database.open();
    final raw = database.database;
    await raw.insert('projects', _project(_projectA, 'Proje A'));
    await raw.insert('projects', _project(_projectB, 'Proje B'));
    for (var index = 1; index <= 4; index += 1) {
      await raw.insert(
        'field_observations',
        _observation(
          _observationId(index),
          index == 4 ? _projectB : _projectA,
          'Kayıt $index',
        ),
      );
    }
    await raw.insert(
      'managed_attachments',
      _physical(_physicalId(1), List.filled(64, 'a').join()),
    );
    await raw.insert(
      'managed_attachments',
      _physical(_physicalId(2), List.filled(64, 'a').join()),
    );
    await raw.insert(
      'managed_attachments',
      _physical(_physicalId(3), List.filled(64, 'b').join()),
    );
    await raw.insert(
      'attachment_links',
      _link(_linkId(1), _physicalId(1), _projectA, _observationId(1)),
    );
    await raw.insert(
      'attachment_links',
      _link(_linkId(2), _physicalId(1), _projectA, _observationId(2)),
    );
    await raw.insert(
      'attachment_links',
      _link(_linkId(3), _physicalId(2), _projectA, _observationId(3)),
    );
    await raw.insert(
      'attachment_links',
      _link(_linkId(4), _physicalId(3), _projectB, _observationId(4)),
    );
    await database.close();
    store = _InspectOnlyStore();
    catalog = SqliteAttachmentCatalogApplication(
      databasePath: directories.databaseFile,
      databaseFactory: databaseFactoryFfi,
      managedStore: store,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'catalog is project-scoped and preserves same physical multi-link truth',
    () async {
      store.integrityByPath['managed/${_physicalId(2)}.jpg'] =
          ManagedAttachmentIntegrity.hashMismatch;

      final projects = await catalog.listProjects();
      final projectA = await catalog.listProjectAttachments(_projectA);
      final projectB = await catalog.listProjectAttachments(_projectB);

      expect(projects.map((item) => item.id), [_projectA, _projectB]);
      expect(projectA, hasLength(2));
      expect(
        projectA.map((item) => item.physicalAttachmentId).toSet(),
        {_physicalId(1), _physicalId(2)},
        reason: 'Equal SHA values never merge physical identities.',
      );
      final shared = projectA.singleWhere(
        (item) => item.physicalAttachmentId == _physicalId(1),
      );
      expect(shared.links, hasLength(2));
      expect(shared.links.map((link) => link.sourceId), [
        _observationId(1),
        _observationId(2),
      ]);
      expect(shared.links.map((link) => link.sourceLabel), [
        'Ajanda • Kayıt 1',
        'Ajanda • Kayıt 2',
      ]);
      expect(
        projectA
            .singleWhere((item) => item.physicalAttachmentId == _physicalId(2))
            .integrity,
        ManagedAttachmentIntegrity.hashMismatch,
      );
      expect(projectB.map((item) => item.physicalAttachmentId), [
        _physicalId(3),
      ]);
      expect(
        projectA.expand((item) => item.links).map((link) => link.sourceId),
        isNot(contains(_observationId(4))),
      );
      expect(store.inspectedPaths, hasLength(3));
    },
  );

  test('unknown project fails closed', () async {
    await expectLater(
      catalog.listProjectAttachments('99999999-9999-4999-8999-999999999999'),
      throwsA(
        isA<AttachmentCatalogFailure>().having(
          (error) => error.code,
          'code',
          'project_not_found',
        ),
      ),
    );
  });
}

Map<String, Object?> _project(String id, String name) => {
  'id': id,
  'name': name,
  'created_at': '2026-08-09T12:00:00Z',
  'updated_at': '2026-08-09T12:00:00Z',
  'revision': 1,
};

Map<String, Object?> _observation(
  String id,
  String projectId,
  String description,
) => {
  'id': id,
  'project_id': projectId,
  'observed_at': '2026-08-09T12:00:00Z',
  'created_at': '2026-08-09T12:00:00Z',
  'updated_at': '2026-08-09T12:00:00Z',
  'category': 'general_note',
  'description': description,
  'revision': 1,
};

Map<String, Object?> _physical(String id, String digest) => {
  'id': id,
  'relative_path': 'managed/$id.jpg',
  'mime_type': 'image/jpeg',
  'byte_size': 4,
  'sha256': digest,
  'created_at': '2026-08-09T12:00:00Z',
};

Map<String, Object?> _link(
  String id,
  String attachmentId,
  String projectId,
  String sourceId,
) => {
  'id': id,
  'attachment_id': attachmentId,
  'project_id': projectId,
  'source_type': 'agenda_observation',
  'source_id': sourceId,
  'role': 'site_photo',
  'original_file_name': '$id.jpg',
  'revision': 1,
  'created_at': '2026-08-09T12:00:00Z',
  'updated_at': '2026-08-09T12:00:00Z',
};

String _physicalId(int value) =>
    'aaaaaaaa-aaaa-4aaa-8aaa-${value.toString().padLeft(12, '0')}';

String _linkId(int value) =>
    'bbbbbbbb-bbbb-4bbb-8bbb-${value.toString().padLeft(12, '0')}';

String _observationId(int value) =>
    'cccccccc-cccc-4ccc-8ccc-${value.toString().padLeft(12, '0')}';

class _InspectOnlyStore implements ManagedAttachmentStore {
  final Map<String, ManagedAttachmentIntegrity> integrityByPath = {};
  final List<String> inspectedPaths = [];

  @override
  Future<ManagedAttachmentIntegrity> inspect({
    required String relativePath,
    required String expectedSha256,
    required String? expectedMimeType,
    int? expectedByteSize,
  }) async {
    inspectedPaths.add(relativePath);
    return integrityByPath[relativePath] ?? ManagedAttachmentIntegrity.healthy;
  }

  @override
  Future<void> cleanup(String relativePath) => throw UnimplementedError();

  @override
  Future<void> open({
    required String relativePath,
    required String expectedMimeType,
  }) => throw UnimplementedError();

  @override
  Future<ManagedAttachmentContent> read({
    required String relativePath,
    required String originalFileName,
    required String expectedSha256,
    required String expectedMimeType,
    int? expectedByteSize,
  }) => throw UnimplementedError();

  @override
  Future<ManagedAttachmentWrite> stage({
    required String attachmentId,
    required String originalFileName,
    required List<int> bytes,
  }) => throw UnimplementedError();
}
