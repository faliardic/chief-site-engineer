import 'dart:io';

import 'package:chief_site_engineer/core/environment.dart';
import 'package:path/path.dart' as path;

class PathContractViolation implements Exception {
  const PathContractViolation(this.message);

  final String message;

  @override
  String toString() => 'PathContractViolation: $message';
}

class AppDirectories {
  AppDirectories._({
    required this.environment,
    required this.root,
    required this.database,
    required this.attachments,
    required this.exportsBackups,
    required this.state,
    required this.staging,
  });

  factory AppDirectories.fromSupportRoot(
    Directory supportRoot,
    AppEnvironment environment,
  ) {
    if (!path.isAbsolute(supportRoot.path)) {
      throw const PathContractViolation('support root must be absolute');
    }
    final root = Directory(
      path.normalize(
        path.join(supportRoot.path, 'cse_mobile', environment.storageSegment),
      ),
    );
    final directories = AppDirectories._(
      environment: environment,
      root: root,
      database: Directory(path.join(root.path, 'database')),
      attachments: Directory(path.join(root.path, 'attachments')),
      exportsBackups: Directory(path.join(root.path, 'exports_backups')),
      state: Directory(path.join(root.path, 'state')),
      staging: Directory(path.join(root.path, 'temp_staging')),
    );
    directories.validate();
    return directories;
  }

  final AppEnvironment environment;
  final Directory root;
  final Directory database;
  final Directory attachments;
  final Directory exportsBackups;
  final Directory state;
  final Directory staging;

  String get databaseFile => path.join(database.path, 'cse_mobile.sqlite3');
  String get backupStateFile =>
      path.join(state.path, 'mobile_backup_state.json');
  String get restoreJournalFile => path.join(root.path, 'restore_journal.json');
  String get restoreJournalNextFile => '$restoreJournalFile.next';
  Directory get incomingBackups =>
      Directory(path.join(staging.path, 'incoming_backups'));

  void validate() {
    final normalizedRoot = path.normalize(path.absolute(root.path));
    for (final directory in [
      database,
      attachments,
      exportsBackups,
      state,
      staging,
      incomingBackups,
    ]) {
      final candidate = path.normalize(path.absolute(directory.path));
      if (!path.isWithin(normalizedRoot, candidate)) {
        throw const PathContractViolation(
          'application directory escaped its environment root',
        );
      }
    }
    final databasePath = path.normalize(path.absolute(databaseFile));
    if (!path.isWithin(normalizedRoot, databasePath)) {
      throw const PathContractViolation(
        'database escaped its environment root',
      );
    }
    final backupStatePath = path.normalize(path.absolute(backupStateFile));
    if (!path.isWithin(normalizedRoot, backupStatePath)) {
      throw const PathContractViolation(
        'backup state escaped its environment root',
      );
    }
    for (final journalPath in [restoreJournalFile, restoreJournalNextFile]) {
      final candidate = path.normalize(path.absolute(journalPath));
      if (!path.isWithin(normalizedRoot, candidate)) {
        throw const PathContractViolation(
          'restore journal escaped its environment root',
        );
      }
    }
  }

  Future<void> ensureRecoveryRootsCreated() async {
    validate();
    for (final directory in [root, exportsBackups, state, staging]) {
      await directory.create(recursive: true);
    }
  }

  Future<void> ensureCreated() async {
    validate();
    for (final directory in [
      root,
      database,
      attachments,
      exportsBackups,
      state,
      staging,
    ]) {
      await directory.create(recursive: true);
    }
  }
}
