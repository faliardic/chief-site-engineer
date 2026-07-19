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
  final Directory staging;

  String get databaseFile => path.join(database.path, 'cse_mobile.sqlite3');

  void validate() {
    final normalizedRoot = path.normalize(path.absolute(root.path));
    for (final directory in [database, attachments, exportsBackups, staging]) {
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
  }

  Future<void> ensureCreated() async {
    validate();
    for (final directory in [
      root,
      database,
      attachments,
      exportsBackups,
      staging,
    ]) {
      await directory.create(recursive: true);
    }
  }
}
