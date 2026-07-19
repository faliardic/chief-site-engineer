import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:sqflite/sqflite.dart';

typedef UtcClock = DateTime Function();

class DatabaseOpenFailure implements Exception {
  const DatabaseOpenFailure();

  @override
  String toString() => 'DatabaseOpenFailure';
}

class DatabaseMigration {
  const DatabaseMigration({required this.version, required this.apply});

  final int version;
  final Future<void> Function(Transaction transaction) apply;
}

class AppDatabase {
  AppDatabase({
    required this.path,
    required this.factory,
    required this.clock,
    List<DatabaseMigration>? migrations,
  }) : migrations = migrations ?? foundationMigrations;

  static const schemaVersion = 1;

  static final List<DatabaseMigration> foundationMigrations = [
    DatabaseMigration(
      version: 1,
      apply: (transaction) async {
        await transaction.execute('''
          CREATE TABLE schema_versions (
            version INTEGER PRIMARY KEY,
            applied_at TEXT NOT NULL
          )
        ''');
        await transaction.execute('''
          CREATE TABLE smoke_records (
            id TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    ),
  ];

  final String path;
  final DatabaseFactory factory;
  final UtcClock clock;
  final List<DatabaseMigration> migrations;
  Database? _database;

  Database get database {
    final openDatabase = _database;
    if (openDatabase == null || !openDatabase.isOpen) {
      throw StateError('database is not open');
    }
    return openDatabase;
  }

  Future<void> open() async {
    if (_database?.isOpen ?? false) {
      return;
    }
    Database? candidate;
    try {
      _validateMigrationChain();
      candidate = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await candidate.execute('PRAGMA foreign_keys = ON');
      await candidate.transaction((transaction) async {
        final versionRows = await transaction.rawQuery('PRAGMA user_version');
        final currentVersion = Sqflite.firstIntValue(versionRows) ?? 0;
        final latestVersion = migrations.last.version;
        if (currentVersion < 0 || currentVersion > latestVersion) {
          throw StateError('unsupported database schema version');
        }
        for (final migration in migrations.where(
          (item) => item.version > currentVersion,
        )) {
          await migration.apply(transaction);
          await transaction.insert('schema_versions', {
            'version': migration.version,
            'applied_at': CseTimeCodec.encodeUtc(clock()),
          });
          await transaction.execute(
            'PRAGMA user_version = ${migration.version}',
          );
        }
      });
      await _validateSchema(candidate);
      _database = candidate;
    } on Object {
      await candidate?.close();
      _database = null;
      throw const DatabaseOpenFailure();
    }
  }

  Future<void> close() async {
    final openDatabase = _database;
    _database = null;
    await openDatabase?.close();
  }

  void _validateMigrationChain() {
    if (migrations.isEmpty) {
      throw StateError('at least one database migration is required');
    }
    for (var index = 0; index < migrations.length; index += 1) {
      if (migrations[index].version != index + 1) {
        throw StateError(
          'database migrations must be contiguous from version 1',
        );
      }
    }
  }

  Future<void> _validateSchema(Database candidate) async {
    final versionRows = await candidate.rawQuery('PRAGMA user_version');
    final userVersion = Sqflite.firstIntValue(versionRows) ?? 0;
    if (userVersion != migrations.last.version) {
      throw StateError('database schema version mismatch');
    }
    final history = await candidate.query(
      'schema_versions',
      columns: ['version', 'applied_at'],
      orderBy: 'version ASC',
    );
    if (history.length != migrations.length) {
      throw StateError('database migration history mismatch');
    }
    for (var index = 0; index < history.length; index += 1) {
      if (history[index]['version'] != index + 1) {
        throw StateError('database migration history is not contiguous');
      }
      CseTimeCodec.decodeCanonicalUtc(history[index]['applied_at']! as String);
    }
  }
}
