import 'dart:io';

import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AttachmentReconciliationApplication {
  AttachmentReconciliationApplication({
    required this.directories,
    required this.databaseFactory,
    ManagedAttachmentStore? managedStore,
  }) : managedStore =
           managedStore ??
           DeviceManagedAttachmentStore(directories: directories);

  final AppDirectories directories;
  final DatabaseFactory databaseFactory;
  final ManagedAttachmentStore managedStore;

  Future<AttachmentReconciliationReport> inspect() async {
    directories.validate();
    Database? database;
    try {
      database = await databaseFactory.openDatabase(
        directories.databaseFile,
        options: OpenDatabaseOptions(singleInstance: false, readOnly: true),
      );
      final version = await database.getVersion();
      if (version != AppDatabase.schemaVersion) {
        throw const AttachmentReconciliationFailure('unsupported_schema');
      }
      final physicalRows = await database.query(
        'managed_attachments',
        orderBy: 'id ASC',
      );
      final linkRows = await database.query(
        'attachment_links',
        orderBy: 'id ASC',
      );
      final findings = <AttachmentReconciliationFinding>[];
      final metadataPaths = <String>{};
      final physicalIds = <String>{};

      for (final row in physicalRows) {
        final id = row['id']! as String;
        final relativePath = row['relative_path']! as String;
        physicalIds.add(id);
        metadataPaths.add(relativePath);
        final integrity = await managedStore.inspect(
          relativePath: relativePath,
          expectedSha256: row['sha256']! as String,
          expectedMimeType: row['mime_type']! as String,
          expectedByteSize: row['byte_size']! as int,
        );
        findings.add(
          AttachmentReconciliationFinding(
            type: _findingType(integrity),
            attachmentId: id,
            relativePath: relativePath,
          ),
        );
      }

      await _inspectLinks(
        database,
        linkRows,
        physicalIds: physicalIds,
        findings: findings,
      );
      _findDuplicateLegacyCandidates(physicalRows, findings);
      await _findManagedRootEntries(metadataPaths, findings);
      await _findManagedStagingEntries(findings);

      findings.sort((left, right) {
        final byType = left.type.code.compareTo(right.type.code);
        if (byType != 0) return byType;
        final byPath = (left.relativePath ?? '').compareTo(
          right.relativePath ?? '',
        );
        if (byPath != 0) return byPath;
        final byAttachment = (left.attachmentId ?? '').compareTo(
          right.attachmentId ?? '',
        );
        if (byAttachment != 0) return byAttachment;
        return (left.linkId ?? '').compareTo(right.linkId ?? '');
      });
      return AttachmentReconciliationReport(findings);
    } on AttachmentReconciliationFailure {
      rethrow;
    } on Object {
      throw const AttachmentReconciliationFailure('reconciliation_failed');
    } finally {
      await database?.close();
    }
  }

  Future<void> _inspectLinks(
    Database database,
    List<Map<String, Object?>> linkRows, {
    required Set<String> physicalIds,
    required List<AttachmentReconciliationFinding> findings,
  }) async {
    for (final row in linkRows) {
      final linkId = row['id']! as String;
      final attachmentId = row['attachment_id']! as String;
      final projectId = row['project_id']! as String;
      final sourceType = row['source_type']! as String;
      final sourceId = row['source_id']! as String;
      var broken = !physicalIds.contains(attachmentId);
      var crossProject = false;

      if (sourceType == 'agenda_observation') {
        final source = await database.query(
          'field_observations',
          columns: ['project_id'],
          where: 'id = ?',
          whereArgs: [sourceId],
          limit: 1,
        );
        broken = broken || source.isEmpty;
        crossProject =
            source.isNotEmpty && source.single['project_id'] != projectId;
      } else if (sourceType == 'concrete_pour') {
        final source = await database.query(
          'concrete_pours',
          columns: ['project_id'],
          where: 'id = ?',
          whereArgs: [sourceId],
          limit: 1,
        );
        broken = broken || source.isEmpty;
        crossProject =
            source.isNotEmpty && source.single['project_id'] != projectId;
      } else {
        broken = true;
      }

      final contextType = row['context_type'] as String?;
      final contextId = row['context_id'] as String?;
      if (contextType != null && contextId != null) {
        final table = switch (contextType) {
          'concrete_truck' => 'concrete_trucks',
          'concrete_sample_set' => 'concrete_sample_sets',
          'concrete_check_item' => 'concrete_check_items',
          _ => null,
        };
        if (table == null) {
          broken = true;
        } else {
          final context = await database.query(
            table,
            columns: ['concrete_pour_id'],
            where: 'id = ?',
            whereArgs: [contextId],
            limit: 1,
          );
          broken =
              broken ||
              context.isEmpty ||
              context.single['concrete_pour_id'] != sourceId;
        }
      } else if (contextType != null || contextId != null) {
        broken = true;
      }

      if (broken) {
        findings.add(
          AttachmentReconciliationFinding(
            type: AttachmentReconciliationFindingType.brokenTarget,
            attachmentId: attachmentId,
            linkId: linkId,
          ),
        );
      }
      if (crossProject) {
        findings.add(
          AttachmentReconciliationFinding(
            type: AttachmentReconciliationFindingType.crossProjectTarget,
            attachmentId: attachmentId,
            linkId: linkId,
          ),
        );
      }
    }
  }

  void _findDuplicateLegacyCandidates(
    List<Map<String, Object?>> physicalRows,
    List<AttachmentReconciliationFinding> findings,
  ) {
    final groups = <String, List<Map<String, Object?>>>{};
    for (final row in physicalRows) {
      final relativePath = row['relative_path']! as String;
      if (!relativePath.startsWith('agenda/') &&
          !relativePath.startsWith('concrete/')) {
        continue;
      }
      final key = '${row['sha256']}|${row['byte_size']}|${row['mime_type']}';
      groups.putIfAbsent(key, () => <Map<String, Object?>>[]).add(row);
    }
    for (final group in groups.values.where((values) => values.length > 1)) {
      final ids = group.map((row) => row['id']! as String).toList()..sort();
      for (final row in group) {
        final id = row['id']! as String;
        findings.add(
          AttachmentReconciliationFinding(
            type: AttachmentReconciliationFindingType.duplicateLegacyCandidate,
            attachmentId: id,
            relativePath: row['relative_path']! as String,
            relatedAttachmentIds: List.unmodifiable(
              ids.where((candidate) => candidate != id),
            ),
          ),
        );
      }
    }
  }

  Future<void> _findManagedRootEntries(
    Set<String> metadataPaths,
    List<AttachmentReconciliationFinding> findings,
  ) async {
    final managedDirectory = Directory(
      path.join(directories.attachments.path, 'managed'),
    );
    final type = await FileSystemEntity.type(
      managedDirectory.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) return;
    if (type != FileSystemEntityType.directory) {
      findings.add(
        const AttachmentReconciliationFinding(
          type: AttachmentReconciliationFindingType.unsafePath,
          relativePath: 'managed',
        ),
      );
      return;
    }
    await for (final entity in managedDirectory.list(
      recursive: true,
      followLinks: false,
    )) {
      final relative = path
          .relative(entity.path, from: directories.attachments.path)
          .split(path.separator)
          .join('/');
      final entityType = await FileSystemEntity.type(
        entity.path,
        followLinks: false,
      );
      if (entityType == FileSystemEntityType.link ||
          entityType == FileSystemEntityType.directory) {
        findings.add(
          AttachmentReconciliationFinding(
            type: AttachmentReconciliationFindingType.unsafePath,
            relativePath: relative,
          ),
        );
        continue;
      }
      if (entityType == FileSystemEntityType.file &&
          DeviceManagedAttachmentStore.managedFinalPathPattern.hasMatch(
            relative,
          ) &&
          !metadataPaths.contains(relative)) {
        findings.add(
          AttachmentReconciliationFinding(
            type: AttachmentReconciliationFindingType.orphanFinalizedFile,
            relativePath: relative,
          ),
        );
      }
    }
  }

  Future<void> _findManagedStagingEntries(
    List<AttachmentReconciliationFinding> findings,
  ) async {
    final type = await FileSystemEntity.type(
      directories.staging.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) return;
    if (type != FileSystemEntityType.directory) {
      findings.add(
        const AttachmentReconciliationFinding(
          type: AttachmentReconciliationFindingType.unsafePath,
          relativePath: 'temp_staging',
        ),
      );
      return;
    }
    await for (final entity in directories.staging.list(followLinks: false)) {
      final name = path.basename(entity.path);
      if (!DeviceManagedAttachmentStore.managedStagingNamePattern.hasMatch(
        name,
      )) {
        continue;
      }
      final entityType = await FileSystemEntity.type(
        entity.path,
        followLinks: false,
      );
      findings.add(
        AttachmentReconciliationFinding(
          type: entityType == FileSystemEntityType.file
              ? AttachmentReconciliationFindingType.staleStagingFile
              : AttachmentReconciliationFindingType.unsafePath,
          relativePath: 'temp_staging/$name',
        ),
      );
    }
  }

  AttachmentReconciliationFindingType _findingType(
    ManagedAttachmentIntegrity integrity,
  ) => switch (integrity) {
    ManagedAttachmentIntegrity.healthy =>
      AttachmentReconciliationFindingType.healthy,
    ManagedAttachmentIntegrity.missingFile =>
      AttachmentReconciliationFindingType.missingFile,
    ManagedAttachmentIntegrity.sizeMismatch =>
      AttachmentReconciliationFindingType.sizeMismatch,
    ManagedAttachmentIntegrity.hashMismatch =>
      AttachmentReconciliationFindingType.hashMismatch,
    ManagedAttachmentIntegrity.mimeMismatch =>
      AttachmentReconciliationFindingType.mimeMismatch,
    ManagedAttachmentIntegrity.unsafePath =>
      AttachmentReconciliationFindingType.unsafePath,
  };
}
