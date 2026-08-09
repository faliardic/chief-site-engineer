import 'dart:io';

import 'package:chief_site_engineer/application/attachment_reconciliation_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _projectA = '11111111-1111-4111-8111-111111111111';
const _projectB = '22222222-2222-4222-8222-222222222222';
const _observationA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _observationB = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _jpeg = <int>[0xff, 0xd8, 0xff, 0x01];
const _changedJpeg = <int>[0xff, 0xd8, 0xff, 0x09];

void main() {
  late Directory root;
  late AppDirectories directories;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cse_attachment_reconcile_');
    directories = AppDirectories.fromSupportRoot(root, AppEnvironment.debug);
    await directories.ensureCreated();
    final database = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 8, 9, 12),
    );
    await database.open();
    await database.database.insert('projects', _project(_projectA, 'A'));
    await database.database.insert('projects', _project(_projectB, 'B'));
    await database.database.insert(
      'field_observations',
      _observation(_observationA, _projectA),
    );
    await database.database.insert(
      'field_observations',
      _observation(_observationB, _projectB),
    );
    await database.close();
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('reports the exact read-only reconciliation matrix', () async {
    final raw = await databaseFactoryFfi.openDatabase(
      directories.databaseFile,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await raw.execute('PRAGMA foreign_keys = ON');
    final fixtures = <_PhysicalFixture>[
      _PhysicalFixture(
        id: _uuid(1),
        relativePath: 'managed/${_uuid(1)}.jpg',
        metadataBytes: _jpeg,
        fileBytes: _jpeg,
      ),
      _PhysicalFixture(
        id: _uuid(2),
        relativePath: 'managed/${_uuid(2)}.jpg',
        metadataBytes: _jpeg,
      ),
      _PhysicalFixture(
        id: _uuid(3),
        relativePath: 'managed/${_uuid(3)}.jpg',
        metadataBytes: _jpeg,
        fileBytes: const [0xff, 0xd8, 0xff, 1, 2],
      ),
      _PhysicalFixture(
        id: _uuid(4),
        relativePath: 'managed/${_uuid(4)}.jpg',
        metadataBytes: _jpeg,
        fileBytes: _changedJpeg,
      ),
      _PhysicalFixture(
        id: _uuid(5),
        relativePath: 'managed/${_uuid(5)}.jpg',
        metadataBytes: _jpeg,
        fileBytes: _jpeg,
        mimeType: 'image/png',
      ),
      _PhysicalFixture(
        id: _uuid(6),
        relativePath: '../unsafe.jpg',
        metadataBytes: _jpeg,
      ),
      _PhysicalFixture(
        id: _uuid(7),
        relativePath: 'agenda/legacy/first.jpg',
        metadataBytes: _jpeg,
        fileBytes: _jpeg,
      ),
      _PhysicalFixture(
        id: _uuid(8),
        relativePath: 'concrete/legacy/second.jpg',
        metadataBytes: _jpeg,
        fileBytes: _jpeg,
      ),
    ];
    for (final fixture in fixtures) {
      if (fixture.id == _uuid(6)) {
        await raw.execute('PRAGMA ignore_check_constraints = ON');
      }
      await raw.insert('managed_attachments', fixture.row);
      if (fixture.id == _uuid(6)) {
        await raw.execute('PRAGMA ignore_check_constraints = OFF');
      }
      if (fixture.fileBytes != null) {
        final file = File(
          path.joinAll([
            directories.attachments.path,
            ...fixture.relativePath.split('/'),
          ]),
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(fixture.fileBytes!, flush: true);
      }
    }

    await raw.insert(
      'attachment_links',
      _link(_uuid(21), _uuid(1), _projectA, _observationA),
    );
    await raw.execute('DROP TRIGGER attachment_links_target_project_insert');
    await raw.insert(
      'attachment_links',
      _link(_uuid(22), _uuid(2), _projectA, _uuid(90)),
    );
    await raw.insert(
      'attachment_links',
      _link(_uuid(23), _uuid(3), _projectA, _observationB),
    );
    await raw.close();

    final orphanRelative = 'managed/${_uuid(31)}.jpg';
    final orphan = File(
      path.joinAll([
        directories.attachments.path,
        ...orphanRelative.split('/'),
      ]),
    );
    await orphan.parent.create(recursive: true);
    await orphan.writeAsBytes(_jpeg, flush: true);
    final stale = File(
      path.join(directories.staging.path, 'managed-${_uuid(32)}.part'),
    );
    final unrelated = File(
      path.join(directories.staging.path, 'unrelated-${_uuid(33)}.part'),
    );
    final incoming = File(
      path.join(directories.incomingBackups.path, 'managed-${_uuid(34)}.part'),
    );
    await directories.incomingBackups.create(recursive: true);
    for (final file in [stale, unrelated, incoming]) {
      await file.writeAsBytes(const [1, 2, 3], flush: true);
    }

    final beforeDatabase = await File(directories.databaseFile).readAsBytes();
    final beforeFiles = await _treeSnapshot(directories.root);
    final report = await AttachmentReconciliationApplication(
      directories: directories,
      databaseFactory: databaseFactoryFfi,
    ).inspect();
    final afterDatabase = await File(directories.databaseFile).readAsBytes();
    final afterFiles = await _treeSnapshot(directories.root);

    expect(
      report.findings.map((finding) => finding.type).toSet(),
      containsAll(<AttachmentReconciliationFindingType>{
        AttachmentReconciliationFindingType.healthy,
        AttachmentReconciliationFindingType.missingFile,
        AttachmentReconciliationFindingType.sizeMismatch,
        AttachmentReconciliationFindingType.hashMismatch,
        AttachmentReconciliationFindingType.mimeMismatch,
        AttachmentReconciliationFindingType.unsafePath,
        AttachmentReconciliationFindingType.brokenTarget,
        AttachmentReconciliationFindingType.crossProjectTarget,
        AttachmentReconciliationFindingType.orphanFinalizedFile,
        AttachmentReconciliationFindingType.staleStagingFile,
        AttachmentReconciliationFindingType.duplicateLegacyCandidate,
      }),
    );
    expect(
      report
          .ofType(AttachmentReconciliationFindingType.healthy)
          .map((finding) => finding.attachmentId),
      containsAll([_uuid(1), _uuid(7), _uuid(8)]),
    );
    expect(
      report
          .ofType(AttachmentReconciliationFindingType.brokenTarget)
          .single
          .linkId,
      _uuid(22),
    );
    expect(
      report
          .ofType(AttachmentReconciliationFindingType.crossProjectTarget)
          .single
          .linkId,
      _uuid(23),
    );
    expect(
      report
          .ofType(AttachmentReconciliationFindingType.orphanFinalizedFile)
          .single
          .relativePath,
      orphanRelative,
    );
    expect(
      report
          .ofType(AttachmentReconciliationFindingType.staleStagingFile)
          .single
          .relativePath,
      'temp_staging/${path.basename(stale.path)}',
    );
    expect(
      report.ofType(
        AttachmentReconciliationFindingType.duplicateLegacyCandidate,
      ),
      hasLength(2),
    );
    expect(
      report.findings.map((finding) => finding.relativePath),
      isNot(contains('temp_staging/${path.basename(unrelated.path)}')),
    );
    expect(
      report.findings.map((finding) => finding.relativePath),
      isNot(contains('temp_staging/${path.basename(incoming.path)}')),
    );
    expect(afterDatabase, beforeDatabase);
    expect(afterFiles, beforeFiles);
    expect(await orphan.exists(), isTrue);
    expect(await stale.exists(), isTrue);
    expect(await unrelated.exists(), isTrue);
    expect(await incoming.exists(), isTrue);
  });
}

Map<String, Object?> _project(String id, String name) => {
  'id': id,
  'name': name,
  'created_at': '2026-08-09T12:00:00Z',
  'updated_at': '2026-08-09T12:00:00Z',
  'revision': 1,
};

Map<String, Object?> _observation(String id, String projectId) => {
  'id': id,
  'project_id': projectId,
  'observed_at': '2026-08-09T12:00:00Z',
  'created_at': '2026-08-09T12:00:00Z',
  'updated_at': '2026-08-09T12:00:00Z',
  'category': 'general_note',
  'description': 'Synthetic reconciliation fixture',
  'revision': 1,
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

class _PhysicalFixture {
  const _PhysicalFixture({
    required this.id,
    required this.relativePath,
    required this.metadataBytes,
    this.fileBytes,
    this.mimeType = 'image/jpeg',
  });

  final String id;
  final String relativePath;
  final List<int> metadataBytes;
  final List<int>? fileBytes;
  final String mimeType;

  Map<String, Object?> get row => {
    'id': id,
    'relative_path': relativePath,
    'mime_type': mimeType,
    'byte_size': metadataBytes.length,
    'sha256': sha256.convert(metadataBytes).toString(),
    'created_at': '2026-08-09T12:00:00Z',
  };
}

Future<Map<String, String>> _treeSnapshot(Directory root) async {
  final result = <String, String>{};
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    final relative = path.relative(entity.path, from: root.path);
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    if (type == FileSystemEntityType.file) {
      result[relative] = sha256
          .convert(await File(entity.path).readAsBytes())
          .toString();
    } else {
      result[relative] = type.toString();
    }
  }
  return result;
}

String _uuid(int value) =>
    'eeeeeeee-eeee-4eee-8eee-${value.toString().padLeft(12, '0')}';
