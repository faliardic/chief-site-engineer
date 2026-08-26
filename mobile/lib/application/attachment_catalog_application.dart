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

abstract interface class AttachmentCatalogMediaAccess {
  Future<ManagedAttachmentContent> readAttachment(
    ProjectAttachmentCatalogItem item,
  );

  Future<void> openAttachment(ProjectAttachmentCatalogItem item);
}

class SqliteAttachmentCatalogApplication
    implements AttachmentCatalogApplication, AttachmentCatalogMediaAccess {
  const SqliteAttachmentCatalogApplication({
    required this.databasePath,
    required this.databaseFactory,
    required this.managedStore,
  });

  final String databasePath;
  final DatabaseFactory databaseFactory;
  final ManagedAttachmentStore managedStore;

  @override
  Future<ManagedAttachmentContent> readAttachment(
    ProjectAttachmentCatalogItem item,
  ) => managedStore.read(
    relativePath: item.relativePath,
    originalFileName: item.displayFileName,
    expectedSha256: item.sha256Value,
    expectedMimeType: item.mimeType,
    expectedByteSize: item.byteSize,
  );

  @override
  Future<void> openAttachment(ProjectAttachmentCatalogItem item) async {
    final integrity = await managedStore.inspect(
      relativePath: item.relativePath,
      expectedSha256: item.sha256Value,
      expectedMimeType: item.mimeType,
      expectedByteSize: item.byteSize,
    );
    if (integrity != ManagedAttachmentIntegrity.healthy) {
      throw AttachmentCatalogFailure('attachment_${integrity.code}');
    }
    await managedStore.open(
      relativePath: item.relativePath,
      expectedMimeType: item.mimeType,
    );
  }

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
          END AS source_label,
          CASE
            WHEN l.source_type = 'agenda_observation' AND o.id IS NOT NULL
              THEN 1
            WHEN l.source_type = 'concrete_pour' AND c.id IS NOT NULL
              THEN 1
            ELSE 0
          END AS source_available,
          CASE l.source_type
            WHEN 'agenda_observation' THEN o.archived_at
          END AS source_archived_at,
          COALESCE(ol.id, cl.id) AS stable_location_id,
          COALESCE(ol.display_name, cl.display_name) AS stable_location_name,
          CASE l.context_type
            WHEN 'concrete_truck' THEN
              'Mikser #' || t.sequence_no || ' • ' || t.vehicle_plate
            WHEN 'concrete_sample_set' THEN
              'Numune • ' || s.sample_code
            WHEN 'concrete_check_item' THEN
              'Checklist • ' || ci.label
          END AS context_label
        FROM attachment_links l
        LEFT JOIN field_observations o
          ON l.source_type = 'agenda_observation'
          AND o.id = l.source_id
          AND o.project_id = l.project_id
        LEFT JOIN concrete_pours c
          ON l.source_type = 'concrete_pour'
          AND c.id = l.source_id
          AND c.project_id = l.project_id
        LEFT JOIN project_locations ol
          ON ol.id = o.location_id AND ol.project_id = l.project_id
        LEFT JOIN project_locations cl
          ON cl.id = c.location_id AND cl.project_id = l.project_id
        LEFT JOIN concrete_trucks t
          ON l.context_type = 'concrete_truck'
          AND t.id = l.context_id
          AND t.concrete_pour_id = l.source_id
        LEFT JOIN concrete_sample_sets s
          ON l.context_type = 'concrete_sample_set'
          AND s.id = l.context_id
          AND s.concrete_pour_id = l.source_id
        LEFT JOIN concrete_check_items ci
          ON l.context_type = 'concrete_check_item'
          AND ci.id = l.context_id
          AND ci.concrete_pour_id = l.source_id
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
          description: row['description'] as String?,
          capturedAt: row['captured_at'] as String?,
          stableLocationId: row['stable_location_id'] as String?,
          stableLocationName: row['stable_location_name'] as String?,
          contextLabel: row['context_label'] as String?,
          createdAt: row['created_at']! as String,
          archivedAt: row['archived_at'] as String?,
          sourceArchivedAt: row['source_archived_at'] as String?,
          sourceAvailable: row['source_available'] == 1,
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
