import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class AttachmentCatalogHost {
  AttachmentCatalogApplication? get attachmentCatalog;
}

abstract interface class AttachmentCatalogApplication {
  Future<List<AttachmentCatalogProject>> listProjects();

  Future<List<ProjectAttachmentCatalogItem>> listProjectAttachments(
    String projectId,
  );
}

class SqliteAttachmentCatalogApplication
    implements AttachmentCatalogApplication {
  const SqliteAttachmentCatalogApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.managedStore,
  });

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final ManagedAttachmentStore managedStore;

  @override
  Future<List<AttachmentCatalogProject>> listProjects() async {
    return _read((database) async {
      final rows = await database.query(
        'projects',
        columns: ['id', 'name'],
        where: 'archived_at IS NULL',
        orderBy: 'name COLLATE NOCASE ASC, id ASC',
      );
      return rows
          .map(
            (row) => AttachmentCatalogProject(
              id: row['id']! as String,
              name: row['name']! as String,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<List<ProjectAttachmentCatalogItem>> listProjectAttachments(
    String projectId,
  ) async {
    validateUuid(projectId, 'Proje kimliği');
    return _read((database) async {
      final project = await database.query(
        'projects',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [projectId],
        limit: 1,
      );
      if (project.isEmpty) {
        throw const AttachmentCatalogFailure('project_not_found');
      }
      final physicalRows = await database.rawQuery(
        '''
        SELECT DISTINCT m.*
        FROM managed_attachments m
        JOIN attachment_links l ON l.attachment_id = m.id
        WHERE l.project_id = ?
        ORDER BY m.created_at DESC, m.id ASC
        ''',
        [projectId],
      );
      final linkRows = await database.rawQuery(
        '''
        SELECT l.*,
          CASE l.source_type
            WHEN 'agenda_observation' THEN
              'Ajanda • ' || COALESCE(o.description, l.source_id)
            WHEN 'concrete_pour' THEN
              'Beton • ' || COALESCE(c.pour_code, l.source_id)
          END AS source_label
        FROM attachment_links l
        LEFT JOIN field_observations o
          ON l.source_type = 'agenda_observation' AND o.id = l.source_id
        LEFT JOIN concrete_pours c
          ON l.source_type = 'concrete_pour' AND c.id = l.source_id
        WHERE l.project_id = ?
        ORDER BY l.created_at ASC, l.id ASC
        ''',
        [projectId],
      );
      final linksByPhysical = <String, List<AttachmentCatalogLink>>{};
      for (final row in linkRows) {
        final link = AttachmentCatalogLink(
          id: row['id']! as String,
          sourceType: AttachmentCatalogSourceType.fromStorage(
            row['source_type']! as String,
          ),
          sourceId: row['source_id']! as String,
          sourceLabel: row['source_label']! as String,
          role: row['role']! as String,
          originalFileName: row['original_file_name']! as String,
          contextType: row['context_type'] as String?,
          contextId: row['context_id'] as String?,
          createdAt: row['created_at']! as String,
          archivedAt: row['archived_at'] as String?,
        );
        linksByPhysical
            .putIfAbsent(
              row['attachment_id']! as String,
              () => <AttachmentCatalogLink>[],
            )
            .add(link);
      }
      final result = <ProjectAttachmentCatalogItem>[];
      for (final row in physicalRows) {
        final physicalId = row['id']! as String;
        final links = linksByPhysical[physicalId];
        if (links == null || links.isEmpty) {
          throw const AttachmentCatalogFailure('catalog_projection_failed');
        }
        final integrity = await managedStore.inspect(
          relativePath: row['relative_path']! as String,
          expectedSha256: row['sha256']! as String,
          expectedMimeType: row['mime_type']! as String,
          expectedByteSize: row['byte_size']! as int,
        );
        result.add(
          ProjectAttachmentCatalogItem(
            physicalAttachmentId: physicalId,
            relativePath: row['relative_path']! as String,
            mimeType: row['mime_type']! as String,
            byteSize: row['byte_size']! as int,
            sha256Value: row['sha256']! as String,
            createdAt: row['created_at']! as String,
            integrity: integrity,
            links: links,
          ),
        );
      }
      return List.unmodifiable(result);
    });
  }

  Future<T> _read<T>(Future<T> Function(Database database) action) async {
    Database? database;
    try {
      database = await databaseFactory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(singleInstance: false, readOnly: true),
      );
      if (await database.getVersion() != AppDatabase.schemaVersion) {
        throw const AttachmentCatalogFailure('unsupported_schema');
      }
      return await action(database);
    } on AttachmentCatalogFailure {
      rethrow;
    } on Object {
      throw const AttachmentCatalogFailure('catalog_failed');
    } finally {
      await database?.close();
    }
  }
}
