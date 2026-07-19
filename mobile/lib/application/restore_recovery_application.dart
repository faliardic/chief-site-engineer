import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

enum RestoreJournalPhase {
  prepared,
  oldStateMoved,
  newStateActivated,
  validated,
}

enum RestoreRecoveryOutcome { noJournal, rolledBack, completedNewState }

class RestoreRecoveryFailure implements Exception {
  const RestoreRecoveryFailure(this.code);

  final String code;

  @override
  String toString() => 'RestoreRecoveryFailure: $code';
}

class RestoreJournalEntry {
  const RestoreJournalEntry({
    required this.operationId,
    required this.phase,
    required this.preparedDirectoryName,
    required this.rollbackDirectoryName,
    required this.sequence,
    required this.updatedAtUtc,
  });

  static const formatVersion = 1;

  final String operationId;
  final RestoreJournalPhase phase;
  final String preparedDirectoryName;
  final String rollbackDirectoryName;
  final int sequence;
  final String updatedAtUtc;

  Map<String, Object?> toJson() => {
    'format_version': formatVersion,
    'operation_id': operationId,
    'phase': switch (phase) {
      RestoreJournalPhase.prepared => 'prepared',
      RestoreJournalPhase.oldStateMoved => 'old_state_moved',
      RestoreJournalPhase.newStateActivated => 'new_state_activated',
      RestoreJournalPhase.validated => 'validated',
    },
    'prepared_directory': preparedDirectoryName,
    'rollback_directory': rollbackDirectoryName,
    'sequence': sequence,
    'updated_at_utc': updatedAtUtc,
  };

  factory RestoreJournalEntry.fromJson(Map<String, Object?> json) {
    if (json['format_version'] != formatVersion ||
        json['operation_id'] is! String ||
        json['phase'] is! String ||
        json['prepared_directory'] is! String ||
        json['rollback_directory'] is! String ||
        json['sequence'] is! int ||
        json['updated_at_utc'] is! String) {
      throw const FormatException('invalid restore journal');
    }
    final operationId = json['operation_id']! as String;
    final prepared = json['prepared_directory']! as String;
    final rollback = json['rollback_directory']! as String;
    final phase = switch (json['phase']) {
      'prepared' => RestoreJournalPhase.prepared,
      'old_state_moved' => RestoreJournalPhase.oldStateMoved,
      'new_state_activated' => RestoreJournalPhase.newStateActivated,
      'validated' => RestoreJournalPhase.validated,
      _ => throw const FormatException('unknown restore phase'),
    };
    final sequence = json['sequence']! as int;
    final expectedSequence = phase.index + 1;
    if (!RegExp(r'^[0-9]+-[0-9a-f]{12}$').hasMatch(operationId) ||
        prepared != 'restore-$operationId' ||
        rollback != 'rollback-$operationId' ||
        path.basename(prepared) != prepared ||
        path.basename(rollback) != rollback ||
        sequence != expectedSequence) {
      throw const FormatException('unsafe restore journal');
    }
    CseTimeCodec.decodeCanonicalUtc(json['updated_at_utc']! as String);
    return RestoreJournalEntry(
      operationId: operationId,
      phase: phase,
      preparedDirectoryName: prepared,
      rollbackDirectoryName: rollback,
      sequence: sequence,
      updatedAtUtc: json['updated_at_utc']! as String,
    );
  }
}

class MobileRestoreRecoveryApplication {
  MobileRestoreRecoveryApplication({
    required this.directories,
    required this.databaseFactory,
    required this.clock,
  });

  final AppDirectories directories;
  final DatabaseFactory databaseFactory;
  final UtcClock clock;

  Future<RestoreJournalEntry> begin({
    required String operationId,
    required Directory preparedDirectory,
    required Directory rollbackDirectory,
  }) async {
    final entry = RestoreJournalEntry(
      operationId: operationId,
      phase: RestoreJournalPhase.prepared,
      preparedDirectoryName: _stagingName(preparedDirectory),
      rollbackDirectoryName: _stagingName(rollbackDirectory),
      sequence: 1,
      updatedAtUtc: CseTimeCodec.encodeUtc(clock()),
    );
    if (entry.preparedDirectoryName != 'restore-$operationId' ||
        entry.rollbackDirectoryName != 'rollback-$operationId') {
      throw const RestoreRecoveryFailure('restore_journal_path_mismatch');
    }
    await _write(entry);
    return entry;
  }

  Future<RestoreJournalEntry> advance(
    RestoreJournalEntry current,
    RestoreJournalPhase phase,
  ) async {
    if (phase.index != current.phase.index + 1) {
      throw const RestoreRecoveryFailure('restore_journal_phase_order');
    }
    final entry = RestoreJournalEntry(
      operationId: current.operationId,
      phase: phase,
      preparedDirectoryName: current.preparedDirectoryName,
      rollbackDirectoryName: current.rollbackDirectoryName,
      sequence: phase.index + 1,
      updatedAtUtc: CseTimeCodec.encodeUtc(clock()),
    );
    await _write(entry);
    return entry;
  }

  Future<void> completeValidated(RestoreJournalEntry entry) async {
    if (entry.phase != RestoreJournalPhase.validated) {
      throw const RestoreRecoveryFailure('restore_not_validated');
    }
    await validateActiveState();
    await _cleanupOperation(entry);
    await _clearJournal();
  }

  Future<void> rollbackToOld(RestoreJournalEntry entry) async {
    await _restoreAvailableOldComponents(
      entry,
      requireRollback: entry.phase != RestoreJournalPhase.prepared,
    );
    await validateActiveState();
    await _cleanupOperation(entry);
    await _clearJournal();
  }

  Future<RestoreRecoveryOutcome> recoverBeforeBootstrap() async {
    final entry = await _read();
    if (entry == null) return RestoreRecoveryOutcome.noJournal;
    try {
      switch (entry.phase) {
        case RestoreJournalPhase.prepared:
          await _restoreAvailableOldComponents(entry, requireRollback: false);
          await validateActiveState();
          await _cleanupOperation(entry);
          await _clearJournal();
          return RestoreRecoveryOutcome.rolledBack;
        case RestoreJournalPhase.oldStateMoved:
          await _restoreAvailableOldComponents(entry, requireRollback: true);
          await validateActiveState();
          await _cleanupOperation(entry);
          await _clearJournal();
          return RestoreRecoveryOutcome.rolledBack;
        case RestoreJournalPhase.newStateActivated:
        case RestoreJournalPhase.validated:
          try {
            await validateActiveState();
          } on Object {
            await _restoreAvailableOldComponents(entry, requireRollback: true);
            await validateActiveState();
            await _cleanupOperation(entry);
            await _clearJournal();
            return RestoreRecoveryOutcome.rolledBack;
          }
          await _cleanupOperation(entry);
          await _clearJournal();
          return RestoreRecoveryOutcome.completedNewState;
      }
    } on RestoreRecoveryFailure {
      rethrow;
    } on Object {
      throw const RestoreRecoveryFailure('restore_recovery_ambiguous');
    }
  }

  Future<void> validateActiveState() async {
    final databaseFile = File(directories.databaseFile);
    if (!await databaseFile.exists() ||
        !await directories.attachments.exists()) {
      throw const RestoreRecoveryFailure('active_state_missing');
    }
    AppDatabase? database;
    try {
      database = AppDatabase(
        path: databaseFile.path,
        factory: databaseFactory,
        clock: clock,
      );
      await database.open();
      final integrity = await database.database.rawQuery(
        'PRAGMA integrity_check',
      );
      if (integrity.length != 1 || integrity.single.values.single != 'ok') {
        throw const RestoreRecoveryFailure('active_database_corrupt');
      }
      if ((await database.database.rawQuery(
        'PRAGMA foreign_key_check',
      )).isNotEmpty) {
        throw const RestoreRecoveryFailure('active_foreign_key_violation');
      }
      final rows = await database.database.query(
        'concrete_attachments',
        columns: ['relative_path', 'byte_size', 'sha256'],
        where: 'archived_at IS NULL',
        orderBy: 'relative_path ASC',
      );
      for (final row in rows) {
        final relative = row['relative_path']! as String;
        final attachment = await _resolveAttachment(relative);
        if (!await attachment.exists()) {
          throw const RestoreRecoveryFailure('active_attachment_missing');
        }
        final bytes = await attachment.readAsBytes();
        if (bytes.length != row['byte_size'] ||
            sha256.convert(bytes).toString() != row['sha256']) {
          throw const RestoreRecoveryFailure('active_attachment_corrupt');
        }
      }
    } on RestoreRecoveryFailure {
      rethrow;
    } on Object {
      throw const RestoreRecoveryFailure('active_state_invalid');
    } finally {
      await database?.close();
    }
  }

  Future<void> _restoreAvailableOldComponents(
    RestoreJournalEntry entry, {
    required bool requireRollback,
  }) async {
    final rollbackRoot = _stagingDirectory(entry.rollbackDirectoryName);
    final rollbackDatabase = File(
      path.join(rollbackRoot.path, 'database.sqlite3'),
    );
    final rollbackAttachments = Directory(
      path.join(rollbackRoot.path, 'attachments'),
    );
    final activeDatabase = File(directories.databaseFile);
    final activeAttachments = directories.attachments;
    final hasRollbackDatabase = await rollbackDatabase.exists();
    final hasRollbackAttachments = await rollbackAttachments.exists();
    if (requireRollback && (!hasRollbackDatabase || !hasRollbackAttachments)) {
      throw const RestoreRecoveryFailure('restore_recovery_ambiguous');
    }
    if (hasRollbackDatabase) {
      if (await activeDatabase.exists()) {
        await _preserveFailedFile(activeDatabase, rollbackRoot, 'database');
      }
      await activeDatabase.parent.create(recursive: true);
      await rollbackDatabase.rename(activeDatabase.path);
    } else if (!await activeDatabase.exists()) {
      throw const RestoreRecoveryFailure('restore_recovery_ambiguous');
    }
    if (hasRollbackAttachments) {
      if (await activeAttachments.exists()) {
        await _preserveFailedDirectory(
          activeAttachments,
          rollbackRoot,
          'attachments',
        );
      }
      await rollbackAttachments.rename(activeAttachments.path);
    } else if (!await activeAttachments.exists()) {
      throw const RestoreRecoveryFailure('restore_recovery_ambiguous');
    }
  }

  Future<void> _preserveFailedFile(
    File source,
    Directory rollbackRoot,
    String name,
  ) async {
    final failed = Directory(path.join(rollbackRoot.path, 'failed_new'));
    await failed.create(recursive: true);
    final destination = File(path.join(failed.path, '$name.sqlite3'));
    if (await destination.exists()) {
      throw const RestoreRecoveryFailure('restore_recovery_ambiguous');
    }
    await source.rename(destination.path);
  }

  Future<void> _preserveFailedDirectory(
    Directory source,
    Directory rollbackRoot,
    String name,
  ) async {
    final failed = Directory(path.join(rollbackRoot.path, 'failed_new'));
    await failed.create(recursive: true);
    final destination = Directory(path.join(failed.path, name));
    if (await destination.exists()) {
      throw const RestoreRecoveryFailure('restore_recovery_ambiguous');
    }
    await source.rename(destination.path);
  }

  Future<File> _resolveAttachment(String relative) async {
    if (relative.trim().isEmpty ||
        path.isAbsolute(relative) ||
        relative.contains('\\') ||
        relative
            .split('/')
            .any((segment) => segment.isEmpty || segment == '..')) {
      throw const RestoreRecoveryFailure('active_attachment_path_invalid');
    }
    final root = path.normalize(path.absolute(directories.attachments.path));
    final candidate = path.normalize(
      path.absolute(path.joinAll([root, ...relative.split('/')])),
    );
    if (!path.isWithin(root, candidate)) {
      throw const RestoreRecoveryFailure('active_attachment_path_invalid');
    }
    final type = await FileSystemEntity.type(candidate, followLinks: false);
    if (type == FileSystemEntityType.link) {
      throw const RestoreRecoveryFailure('active_attachment_path_invalid');
    }
    return File(candidate);
  }

  Future<RestoreJournalEntry?> _read() async {
    final candidates = <RestoreJournalEntry>[];
    var journalFileFound = false;
    for (final file in [
      File(directories.restoreJournalFile),
      File(directories.restoreJournalNextFile),
    ]) {
      if (!await file.exists()) continue;
      journalFileFound = true;
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is! Map) throw const FormatException('journal map');
        candidates.add(
          RestoreJournalEntry.fromJson(Map<String, Object?>.from(decoded)),
        );
      } on Object {
        // A valid peer slot can recover an interrupted atomic replacement.
      }
    }
    if (candidates.isEmpty) {
      if (journalFileFound) {
        throw const RestoreRecoveryFailure('restore_journal_invalid');
      }
      return null;
    }
    candidates.sort((left, right) => right.sequence.compareTo(left.sequence));
    final selected = candidates.first;
    if (candidates.any((item) => item.operationId != selected.operationId)) {
      throw const RestoreRecoveryFailure('restore_journal_conflict');
    }
    return selected;
  }

  Future<void> _write(RestoreJournalEntry entry) async {
    directories.validate();
    await directories.root.create(recursive: true);
    final destination = File(directories.restoreJournalFile);
    final next = File(directories.restoreJournalNextFile);
    if (await next.exists()) await next.delete();
    await next.writeAsString(
      '${const JsonEncoder.withIndent(' ').convert(entry.toJson())}\n',
      flush: true,
    );
    if (await destination.exists()) await destination.delete();
    await next.rename(destination.path);
  }

  Future<void> _clearJournal() async {
    for (final file in [
      File(directories.restoreJournalFile),
      File(directories.restoreJournalNextFile),
    ]) {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _cleanupOperation(RestoreJournalEntry entry) async {
    for (final directory in [
      _stagingDirectory(entry.preparedDirectoryName),
      _stagingDirectory(entry.rollbackDirectoryName),
    ]) {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }

  Directory _stagingDirectory(String name) {
    if (path.basename(name) != name) {
      throw const RestoreRecoveryFailure('restore_journal_path_mismatch');
    }
    final stagingRoot = path.normalize(path.absolute(directories.staging.path));
    final candidate = path.normalize(
      path.absolute(path.join(stagingRoot, name)),
    );
    if (!path.isWithin(stagingRoot, candidate)) {
      throw const RestoreRecoveryFailure('restore_journal_path_mismatch');
    }
    return Directory(candidate);
  }

  String _stagingName(Directory directory) {
    final stagingRoot = path.normalize(path.absolute(directories.staging.path));
    final candidate = path.normalize(path.absolute(directory.path));
    if (path.dirname(candidate) != stagingRoot ||
        !path.isWithin(stagingRoot, candidate)) {
      throw const RestoreRecoveryFailure('restore_journal_path_mismatch');
    }
    return path.basename(candidate);
  }
}
