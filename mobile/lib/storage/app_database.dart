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

  static const schemaVersion = 3;

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
    DatabaseMigration(
      version: 2,
      apply: (transaction) async {
        await transaction.execute('''
          CREATE TABLE projects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            archived_at TEXT
          )
        ''');
        await transaction.execute('''
          CREATE TABLE field_observations (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            observed_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            category TEXT NOT NULL CHECK (category IN (
              'general_note', 'manufacturing', 'inspection',
              'meeting_decision', 'delivery', 'safety', 'concrete',
              'issue_delay'
            )),
            description TEXT NOT NULL,
            location TEXT,
            notes TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            archived_at TEXT,
            UNIQUE (id, project_id)
          )
        ''');
        await transaction.execute('''
          CREATE TABLE observation_events (
            id TEXT PRIMARY KEY,
            observation_id TEXT NOT NULL,
            project_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            FOREIGN KEY (observation_id, project_id)
              REFERENCES field_observations(id, project_id)
          )
        ''');
        await transaction.execute('''
          CREATE TABLE follow_up_items (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            observation_id TEXT NOT NULL,
            title TEXT NOT NULL,
            item_type TEXT NOT NULL CHECK (
              item_type IN ('action', 'waiting', 'recheck')
            ),
            status TEXT NOT NULL CHECK (
              status IN ('inbox', 'active', 'waiting', 'completed', 'cancelled')
            ),
            next_attention_at TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            completed_at TEXT,
            cancelled_at TEXT,
            FOREIGN KEY (observation_id, project_id)
              REFERENCES field_observations(id, project_id),
            CHECK (
              (status = 'inbox' AND next_attention_at IS NULL)
              OR (status IN ('active', 'waiting') AND next_attention_at IS NOT NULL)
              OR status IN ('completed', 'cancelled')
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE follow_up_events (
            id TEXT PRIMARY KEY,
            follow_up_id TEXT NOT NULL REFERENCES follow_up_items(id),
            project_id TEXT NOT NULL,
            source_observation_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            FOREIGN KEY (source_observation_id, project_id)
              REFERENCES field_observations(id, project_id)
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_observations_agenda_day
          ON field_observations(observed_at, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_observations_project_category
          ON field_observations(project_id, category, observed_at)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_attention
          ON follow_up_items(status, next_attention_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_observation
          ON follow_up_items(observation_id, created_at, id)
        ''');
        for (final table in ['observation_events', 'follow_up_events']) {
          await transaction.execute('''
            CREATE TRIGGER ${table}_append_only_update
            BEFORE UPDATE ON $table
            BEGIN
              SELECT RAISE(ABORT, 'append-only event history');
            END
          ''');
          await transaction.execute('''
            CREATE TRIGGER ${table}_append_only_delete
            BEFORE DELETE ON $table
            BEGIN
              SELECT RAISE(ABORT, 'append-only event history');
            END
          ''');
        }
        for (final table in [
          'projects',
          'field_observations',
          'follow_up_items',
        ]) {
          await transaction.execute('''
            CREATE TRIGGER ${table}_no_physical_delete
            BEFORE DELETE ON $table
            BEGIN
              SELECT RAISE(ABORT, 'physical delete is not allowed');
            END
          ''');
        }
      },
    ),
    DatabaseMigration(
      version: 3,
      apply: (transaction) async {
        await transaction.execute(
          'DROP TRIGGER follow_up_events_append_only_update',
        );
        await transaction.execute(
          'DROP TRIGGER follow_up_events_append_only_delete',
        );
        await transaction.execute(
          'DROP TRIGGER follow_up_items_no_physical_delete',
        );
        await transaction.execute(
          'ALTER TABLE follow_up_events RENAME TO follow_up_events_v2',
        );
        await transaction.execute(
          'ALTER TABLE follow_up_items RENAME TO follow_up_items_v2',
        );
        await transaction.execute('''
          CREATE TABLE follow_up_items (
            id TEXT PRIMARY KEY,
            capture_text TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            item_type TEXT NOT NULL CHECK (
              item_type IN ('action', 'waiting', 'recheck')
            ),
            status TEXT NOT NULL CHECK (
              status IN ('inbox', 'active', 'waiting', 'completed', 'cancelled')
            ),
            project_id TEXT REFERENCES projects(id),
            observation_id TEXT,
            location TEXT,
            related_person TEXT,
            is_important INTEGER NOT NULL DEFAULT 0 CHECK (
              is_important IN (0, 1)
            ),
            next_attention_at TEXT,
            deadline_at TEXT,
            condition_text TEXT,
            outcome_type TEXT CHECK (
              outcome_type IS NULL OR outcome_type IN (
                'completed', 'no_longer_needed'
              )
            ),
            outcome_note TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            completed_at TEXT,
            cancelled_at TEXT,
            FOREIGN KEY (observation_id, project_id)
              REFERENCES field_observations(id, project_id),
            CHECK (observation_id IS NULL OR project_id IS NOT NULL),
            CHECK (
              (status = 'inbox' AND next_attention_at IS NULL)
              OR (status IN ('active', 'waiting') AND next_attention_at IS NOT NULL)
              OR status IN ('completed', 'cancelled')
            ),
            CHECK (
              (status = 'completed' AND completed_at IS NOT NULL
                AND cancelled_at IS NULL AND outcome_type IS NOT NULL)
              OR (status = 'cancelled' AND cancelled_at IS NOT NULL
                AND completed_at IS NULL AND outcome_type IS NOT NULL)
              OR (status IN ('inbox', 'active', 'waiting')
                AND completed_at IS NULL AND cancelled_at IS NULL
                AND outcome_type IS NULL AND outcome_note IS NULL)
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO follow_up_items (
            id, capture_text, title, description, item_type, status,
            project_id, observation_id, location, related_person,
            is_important, next_attention_at, deadline_at, condition_text,
            outcome_type, outcome_note, revision, created_at, updated_at,
            completed_at, cancelled_at
          )
          SELECT
            id, title, title, NULL, item_type, status,
            project_id, observation_id, NULL, NULL,
            0, next_attention_at, NULL, NULL,
            CASE
              WHEN status = 'completed' THEN 'completed'
              WHEN status = 'cancelled' THEN 'no_longer_needed'
              ELSE NULL
            END,
            NULL, revision, created_at, updated_at,
            completed_at, cancelled_at
          FROM follow_up_items_v2
        ''');
        await transaction.execute('''
          CREATE TABLE follow_up_events (
            id TEXT PRIMARY KEY,
            follow_up_id TEXT NOT NULL REFERENCES follow_up_items(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            project_id TEXT REFERENCES projects(id),
            source_observation_id TEXT,
            event_type TEXT NOT NULL CHECK (event_type IN (
              'created', 'scheduled', 'rescheduled', 'details_updated',
              'waiting_started', 'snoozed', 'completed', 'cancelled',
              'reopened', 'moved_to_inbox', 'notification_scheduled',
              'notification_cancelled'
            )),
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            FOREIGN KEY (source_observation_id, project_id)
              REFERENCES field_observations(id, project_id),
            UNIQUE (follow_up_id, sequence),
            CHECK (source_observation_id IS NULL OR project_id IS NOT NULL)
          )
        ''');
        await transaction.execute('''
          INSERT INTO follow_up_events (
            id, follow_up_id, sequence, project_id, source_observation_id,
            event_type, occurred_at, payload_json
          )
          SELECT
            event.id,
            event.follow_up_id,
            (
              SELECT COUNT(*)
              FROM follow_up_events_v2 previous
              WHERE previous.follow_up_id = event.follow_up_id
                AND (
                  previous.occurred_at < event.occurred_at
                  OR (previous.occurred_at = event.occurred_at
                    AND previous.id <= event.id)
                )
            ),
            event.project_id,
            event.source_observation_id,
            event.event_type,
            event.occurred_at,
            event.payload_json
          FROM follow_up_events_v2 event
          ORDER BY event.follow_up_id, event.occurred_at, event.id
        ''');
        await transaction.execute('DROP TABLE follow_up_events_v2');
        await transaction.execute('DROP TABLE follow_up_items_v2');
        await transaction.execute('''
          CREATE TABLE reminder_notification_bindings (
            reminder_id TEXT PRIMARY KEY REFERENCES follow_up_items(id),
            platform_notification_id INTEGER NOT NULL UNIQUE CHECK (
              platform_notification_id BETWEEN 1 AND 2147483647
            ),
            scheduled_for TEXT,
            sync_state TEXT NOT NULL CHECK (sync_state IN (
              'scheduled', 'permission_denied', 'unavailable',
              'failed', 'cancelled'
            )),
            last_synced_at TEXT NOT NULL,
            safe_error_code TEXT
          )
        ''');
        await transaction.execute('''
          INSERT INTO reminder_notification_bindings (
            reminder_id, platform_notification_id, scheduled_for,
            sync_state, last_synced_at, safe_error_code
          )
          SELECT
            id,
            ROW_NUMBER() OVER (ORDER BY id),
            next_attention_at,
            CASE
              WHEN status IN ('completed', 'cancelled')
                OR next_attention_at IS NULL THEN 'cancelled'
              ELSE 'unavailable'
            END,
            updated_at,
            CASE
              WHEN status IN ('active', 'waiting')
                AND next_attention_at IS NOT NULL
                THEN 'reconciliation_required'
              ELSE NULL
            END
          FROM follow_up_items
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_attention_v3
          ON follow_up_items(
            status, next_attention_at, is_important, created_at, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_observation_v3
          ON follow_up_items(observation_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_notification_bindings_schedule
          ON reminder_notification_bindings(sync_state, scheduled_for)
        ''');
        await transaction.execute('''
          CREATE TRIGGER follow_up_events_append_only_update
          BEFORE UPDATE ON follow_up_events
          BEGIN
            SELECT RAISE(ABORT, 'append-only event history');
          END
        ''');
        await transaction.execute('''
          CREATE TRIGGER follow_up_events_append_only_delete
          BEFORE DELETE ON follow_up_events
          BEGIN
            SELECT RAISE(ABORT, 'append-only event history');
          END
        ''');
        await transaction.execute('''
          CREATE TRIGGER follow_up_items_no_physical_delete
          BEFORE DELETE ON follow_up_items
          BEGIN
            SELECT RAISE(ABORT, 'physical delete is not allowed');
          END
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
