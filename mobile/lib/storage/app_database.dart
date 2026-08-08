import 'dart:convert';

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

  static const schemaVersion = 11;

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
    DatabaseMigration(
      version: 4,
      apply: (transaction) async {
        await transaction.execute('''
          CREATE TABLE workforce_members (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            full_name TEXT NOT NULL,
            team_name TEXT NOT NULL,
            role_name TEXT NOT NULL,
            personnel_code TEXT,
            is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            archived_at TEXT,
            UNIQUE (project_id, personnel_code),
            UNIQUE (id, project_id),
            CHECK (
              (is_active = 1 AND archived_at IS NULL)
              OR (is_active = 0 AND archived_at IS NOT NULL)
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE attendance_days (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            local_date TEXT NOT NULL,
            status TEXT NOT NULL CHECK (
              status IN ('draft', 'completed', 'no_work')
            ),
            general_note TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            completed_at TEXT,
            UNIQUE (project_id, local_date),
            UNIQUE (id, project_id),
            CHECK (
              (status = 'draft' AND completed_at IS NULL)
              OR (status IN ('completed', 'no_work')
                AND completed_at IS NOT NULL)
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE attendance_entries (
            id TEXT PRIMARY KEY,
            attendance_day_id TEXT NOT NULL REFERENCES attendance_days(id),
            workforce_member_id TEXT NOT NULL REFERENCES workforce_members(id),
            result TEXT NOT NULL CHECK (
              result IN ('full_day', 'half_day', 'absent', 'leave')
            ),
            overtime_minutes INTEGER NOT NULL DEFAULT 0 CHECK (
              overtime_minutes >= 0
            ),
            short_note TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            removed_at TEXT,
            UNIQUE (attendance_day_id, workforce_member_id),
            CHECK (
              result NOT IN ('absent', 'leave') OR overtime_minutes = 0
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE attendance_events (
            id TEXT PRIMARY KEY,
            attendance_day_id TEXT NOT NULL REFERENCES attendance_days(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            event_type TEXT NOT NULL CHECK (event_type IN (
              'attendance_day.created',
              'attendance_entry.upserted',
              'attendance_entry.removed',
              'attendance_day.note_updated',
              'attendance_day.completed',
              'attendance_day.no_work',
              'attendance_day.reopened',
              'attendance_day.csv_exported',
              'attendance_day.reminder_linked'
            )),
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            UNIQUE (attendance_day_id, sequence)
          )
        ''');
        await transaction.execute('''
          CREATE TABLE attendance_reminder_settings (
            project_id TEXT PRIMARY KEY REFERENCES projects(id),
            is_enabled INTEGER NOT NULL DEFAULT 0 CHECK (
              is_enabled IN (0, 1)
            ),
            local_time TEXT NOT NULL,
            selected_weekdays TEXT NOT NULL,
            timezone_name TEXT NOT NULL CHECK (
              timezone_name = 'Europe/Istanbul'
            ),
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

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
          'ALTER TABLE reminder_notification_bindings '
          'RENAME TO reminder_notification_bindings_v3',
        );
        await transaction.execute(
          'ALTER TABLE follow_up_events RENAME TO follow_up_events_v3',
        );
        await transaction.execute(
          'ALTER TABLE follow_up_items RENAME TO follow_up_items_v3',
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
            attendance_day_id TEXT,
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
            FOREIGN KEY (attendance_day_id, project_id)
              REFERENCES attendance_days(id, project_id),
            CHECK (
              observation_id IS NULL OR attendance_day_id IS NULL
            ),
            CHECK (
              (observation_id IS NULL AND attendance_day_id IS NULL)
              OR project_id IS NOT NULL
            ),
            CHECK (
              (status = 'inbox' AND next_attention_at IS NULL)
              OR (status IN ('active', 'waiting')
                AND next_attention_at IS NOT NULL)
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
            project_id, observation_id, attendance_day_id, location,
            related_person, is_important, next_attention_at, deadline_at,
            condition_text, outcome_type, outcome_note, revision,
            created_at, updated_at, completed_at, cancelled_at
          )
          SELECT
            id, capture_text, title, description, item_type, status,
            project_id, observation_id, NULL, location,
            related_person, is_important, next_attention_at, deadline_at,
            condition_text, outcome_type, outcome_note, revision,
            created_at, updated_at, completed_at, cancelled_at
          FROM follow_up_items_v3
        ''');
        await transaction.execute('''
          CREATE TABLE follow_up_events (
            id TEXT PRIMARY KEY,
            follow_up_id TEXT NOT NULL REFERENCES follow_up_items(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            project_id TEXT REFERENCES projects(id),
            source_observation_id TEXT,
            source_attendance_day_id TEXT,
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
            FOREIGN KEY (source_attendance_day_id, project_id)
              REFERENCES attendance_days(id, project_id),
            UNIQUE (follow_up_id, sequence),
            CHECK (
              source_observation_id IS NULL
              OR source_attendance_day_id IS NULL
            ),
            CHECK (
              (source_observation_id IS NULL
                AND source_attendance_day_id IS NULL)
              OR project_id IS NOT NULL
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO follow_up_events (
            id, follow_up_id, sequence, project_id,
            source_observation_id, source_attendance_day_id,
            event_type, occurred_at, payload_json
          )
          SELECT
            id, follow_up_id, sequence, project_id,
            source_observation_id, NULL,
            event_type, occurred_at, payload_json
          FROM follow_up_events_v3
        ''');
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
            reminder_id, platform_notification_id, scheduled_for,
            sync_state, last_synced_at, safe_error_code
          FROM reminder_notification_bindings_v3
        ''');
        await transaction.execute(
          'DROP TABLE reminder_notification_bindings_v3',
        );
        await transaction.execute('DROP TABLE follow_up_events_v3');
        await transaction.execute('DROP TABLE follow_up_items_v3');

        await transaction.execute('''
          CREATE TABLE attendance_day_reminder_links (
            attendance_day_id TEXT PRIMARY KEY REFERENCES attendance_days(id),
            reminder_id TEXT NOT NULL UNIQUE REFERENCES follow_up_items(id),
            due_at TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_workforce_project_team
          ON workforce_members(
            project_id, is_active, team_name COLLATE NOCASE,
            full_name COLLATE NOCASE, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_attendance_days_project_date
          ON attendance_days(project_id, local_date, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_attendance_entries_day
          ON attendance_entries(attendance_day_id, removed_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_attention_v4
          ON follow_up_items(
            status, next_attention_at, is_important, created_at, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_observation_v4
          ON follow_up_items(observation_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_attendance_v4
          ON follow_up_items(attendance_day_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_notification_bindings_schedule_v4
          ON reminder_notification_bindings(sync_state, scheduled_for)
        ''');

        for (final table in ['attendance_events', 'follow_up_events']) {
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
          'workforce_members',
          'attendance_days',
          'attendance_entries',
          'attendance_reminder_settings',
          'attendance_day_reminder_links',
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
        await transaction.execute('''
          CREATE TRIGGER attendance_entries_draft_only_insert
          BEFORE INSERT ON attendance_entries
          WHEN (
            SELECT status FROM attendance_days
            WHERE id = NEW.attendance_day_id
          ) != 'draft'
          BEGIN
            SELECT RAISE(ABORT, 'attendance day must be draft');
          END
        ''');
        await transaction.execute('''
          CREATE TRIGGER attendance_entries_draft_only_update
          BEFORE UPDATE ON attendance_entries
          WHEN (
            SELECT status FROM attendance_days
            WHERE id = NEW.attendance_day_id
          ) != 'draft'
          BEGIN
            SELECT RAISE(ABORT, 'attendance day must be draft');
          END
        ''');
        await transaction.execute('''
          CREATE TRIGGER attendance_no_work_has_no_entries
          BEFORE UPDATE OF status ON attendance_days
          WHEN NEW.status = 'no_work' AND EXISTS (
            SELECT 1 FROM attendance_entries
            WHERE attendance_day_id = NEW.id AND removed_at IS NULL
          )
          BEGIN
            SELECT RAISE(ABORT, 'no-work day cannot have entries');
          END
        ''');
      },
    ),
    DatabaseMigration(
      version: 5,
      apply: (transaction) async {
        await transaction.execute('''
          CREATE TABLE concrete_pours (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            pour_code TEXT NOT NULL,
            element_location TEXT NOT NULL,
            block_name TEXT,
            floor_name TEXT,
            axis_name TEXT,
            planned_at TEXT NOT NULL,
            actual_started_at TEXT,
            actual_ended_at TEXT,
            concrete_class TEXT NOT NULL,
            target_slump TEXT,
            planned_volume_m3 REAL NOT NULL CHECK (planned_volume_m3 >= 0),
            ordered_volume_m3 REAL CHECK (
              ordered_volume_m3 IS NULL OR ordered_volume_m3 >= 0
            ),
            plant_name TEXT,
            plant_branch TEXT,
            plant_contact TEXT,
            plant_appointment_reference TEXT,
            pump_equipment TEXT,
            laboratory_name TEXT,
            laboratory_contact TEXT,
            laboratory_appointment TEXT,
            inspection_notified_at TEXT,
            inspection_notified_person TEXT,
            status TEXT NOT NULL CHECK (status IN (
              'draft', 'prepared', 'pouring', 'poured', 'follow_up',
              'closed', 'cancelled'
            )),
            general_note TEXT,
            sample_exception_reason TEXT,
            variance_note TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            closed_at TEXT,
            cancelled_at TEXT,
            UNIQUE (project_id, pour_code),
            UNIQUE (id, project_id),
            CHECK (
              actual_ended_at IS NULL OR actual_started_at IS NOT NULL
            ),
            CHECK (
              actual_ended_at IS NULL OR actual_ended_at >= actual_started_at
            ),
            CHECK (
              (status = 'closed' AND closed_at IS NOT NULL
                AND cancelled_at IS NULL)
              OR (status = 'cancelled' AND cancelled_at IS NOT NULL
                AND closed_at IS NULL)
              OR (status NOT IN ('closed', 'cancelled')
                AND closed_at IS NULL AND cancelled_at IS NULL)
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE concrete_check_items (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            item_key TEXT NOT NULL,
            label TEXT NOT NULL,
            sort_order INTEGER NOT NULL CHECK (sort_order >= 1),
            is_required INTEGER NOT NULL CHECK (is_required IN (0, 1)),
            status TEXT NOT NULL CHECK (status IN (
              'pending', 'completed', 'not_applicable', 'exception'
            )),
            note TEXT,
            reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE (concrete_pour_id, item_key),
            UNIQUE (id, concrete_pour_id),
            CHECK (
              status NOT IN ('not_applicable', 'exception')
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE concrete_trucks (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            sequence_no INTEGER NOT NULL CHECK (sequence_no >= 1),
            vehicle_plate TEXT NOT NULL,
            delivery_note_number TEXT NOT NULL,
            plant_snapshot TEXT,
            batch_time TEXT,
            arrived_at TEXT,
            unloading_started_at TEXT,
            unloading_ended_at TEXT,
            volume_m3 REAL NOT NULL CHECK (volume_m3 > 0),
            measured_slump REAL CHECK (
              measured_slump IS NULL OR measured_slump >= 0
            ),
            concrete_temperature REAL,
            result TEXT NOT NULL CHECK (result IN (
              'received', 'held', 'returned', 'partial'
            )),
            reason TEXT,
            evidence_exception_reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE (concrete_pour_id, sequence_no),
            UNIQUE (concrete_pour_id, delivery_note_number),
            UNIQUE (id, concrete_pour_id),
            CHECK (
              result = 'received'
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            ),
            CHECK (
              unloading_started_at IS NULL OR arrived_at IS NULL
              OR unloading_started_at >= arrived_at
            ),
            CHECK (
              unloading_ended_at IS NULL OR unloading_started_at IS NOT NULL
            ),
            CHECK (
              unloading_ended_at IS NULL
              OR unloading_ended_at >= unloading_started_at
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE concrete_sample_sets (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            source_truck_id TEXT,
            sample_code TEXT NOT NULL,
            sample_count INTEGER NOT NULL CHECK (sample_count >= 0),
            sample_labels_json TEXT NOT NULL,
            sampled_at TEXT,
            sampled_by TEXT,
            laboratory_appointment_at TEXT,
            delivered_at TEXT,
            delivered_to TEXT,
            expected_result_dates_json TEXT NOT NULL,
            status TEXT NOT NULL CHECK (status IN (
              'planned', 'sampled', 'delivered', 'waiting_result',
              'completed', 'exception'
            )),
            note TEXT,
            reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE (concrete_pour_id, sample_code),
            UNIQUE (id, concrete_pour_id),
            FOREIGN KEY (source_truck_id, concrete_pour_id)
              REFERENCES concrete_trucks(id, concrete_pour_id),
            CHECK (
              status NOT IN ('sampled', 'delivered', 'waiting_result',
                'completed')
              OR (sampled_at IS NOT NULL AND sample_count > 0)
            ),
            CHECK (
              status NOT IN ('delivered', 'waiting_result', 'completed')
              OR delivered_at IS NOT NULL
            ),
            CHECK (
              status != 'exception'
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE concrete_follow_up_items (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            source_sample_set_id TEXT,
            item_key TEXT NOT NULL,
            label TEXT NOT NULL,
            due_at TEXT,
            status TEXT NOT NULL CHECK (status IN (
              'pending', 'completed', 'exception'
            )),
            reminder_id TEXT UNIQUE,
            note TEXT,
            reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            completed_at TEXT,
            UNIQUE (concrete_pour_id, item_key),
            UNIQUE (id, concrete_pour_id),
            FOREIGN KEY (source_sample_set_id, concrete_pour_id)
              REFERENCES concrete_sample_sets(id, concrete_pour_id),
            CHECK (
              (status = 'pending' AND completed_at IS NULL)
              OR (status IN ('completed', 'exception')
                AND completed_at IS NOT NULL)
            ),
            CHECK (
              status != 'exception'
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE concrete_attachments (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            truck_id TEXT,
            sample_set_id TEXT,
            check_item_id TEXT,
            evidence_type TEXT NOT NULL CHECK (evidence_type IN (
              'delivery_receipt_scan', 'mixer_photo', 'site_photo',
              'sample_photo', 'laboratory_delivery_document',
              'result_document', 'other'
            )),
            original_file_name TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            byte_size INTEGER NOT NULL CHECK (byte_size > 0),
            sha256 TEXT NOT NULL CHECK (length(sha256) = 64),
            relative_path TEXT NOT NULL UNIQUE,
            captured_at TEXT NOT NULL,
            description TEXT,
            created_at TEXT NOT NULL,
            archived_at TEXT,
            UNIQUE (concrete_pour_id, sha256),
            FOREIGN KEY (truck_id, concrete_pour_id)
              REFERENCES concrete_trucks(id, concrete_pour_id),
            FOREIGN KEY (sample_set_id, concrete_pour_id)
              REFERENCES concrete_sample_sets(id, concrete_pour_id),
            FOREIGN KEY (check_item_id, concrete_pour_id)
              REFERENCES concrete_check_items(id, concrete_pour_id),
            CHECK (
              (truck_id IS NOT NULL) + (sample_set_id IS NOT NULL)
                + (check_item_id IS NOT NULL) <= 1
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE concrete_pour_events (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            event_type TEXT NOT NULL CHECK (event_type IN (
              'pour.created', 'pour.details_updated', 'check.updated',
              'pour.prepared', 'pour.started', 'truck.added',
              'truck.updated', 'evidence.attached', 'sample_set.added',
              'sample_set.updated', 'follow_up.linked', 'pour.finished',
              'pour.follow_up_started', 'pour.closed', 'pour.cancelled',
              'pour.reopened', 'report.exported'
            )),
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            UNIQUE (concrete_pour_id, sequence)
          )
        ''');

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
          'DROP TRIGGER attendance_day_reminder_links_no_physical_delete',
        );
        for (final index in [
          'ix_follow_ups_attention_v4',
          'ix_follow_ups_observation_v4',
          'ix_follow_ups_attendance_v4',
          'ix_notification_bindings_schedule_v4',
        ]) {
          await transaction.execute('DROP INDEX $index');
        }
        await transaction.execute(
          'ALTER TABLE attendance_day_reminder_links '
          'RENAME TO attendance_day_reminder_links_v4',
        );
        await transaction.execute(
          'ALTER TABLE reminder_notification_bindings '
          'RENAME TO reminder_notification_bindings_v4',
        );
        await transaction.execute(
          'ALTER TABLE follow_up_events RENAME TO follow_up_events_v4',
        );
        await transaction.execute(
          'ALTER TABLE follow_up_items RENAME TO follow_up_items_v4',
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
            attendance_day_id TEXT,
            concrete_pour_id TEXT,
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
            FOREIGN KEY (attendance_day_id, project_id)
              REFERENCES attendance_days(id, project_id),
            FOREIGN KEY (concrete_pour_id, project_id)
              REFERENCES concrete_pours(id, project_id),
            CHECK (
              (observation_id IS NOT NULL) + (attendance_day_id IS NOT NULL)
                + (concrete_pour_id IS NOT NULL) <= 1
            ),
            CHECK (
              (observation_id IS NULL AND attendance_day_id IS NULL
                AND concrete_pour_id IS NULL)
              OR project_id IS NOT NULL
            ),
            CHECK (
              (status = 'inbox' AND next_attention_at IS NULL)
              OR (status IN ('active', 'waiting')
                AND next_attention_at IS NOT NULL)
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
            project_id, observation_id, attendance_day_id, concrete_pour_id,
            location, related_person, is_important, next_attention_at,
            deadline_at, condition_text, outcome_type, outcome_note, revision,
            created_at, updated_at, completed_at, cancelled_at
          )
          SELECT
            id, capture_text, title, description, item_type, status,
            project_id, observation_id, attendance_day_id, NULL,
            location, related_person, is_important, next_attention_at,
            deadline_at, condition_text, outcome_type, outcome_note, revision,
            created_at, updated_at, completed_at, cancelled_at
          FROM follow_up_items_v4
        ''');
        await transaction.execute('''
          CREATE TABLE follow_up_events (
            id TEXT PRIMARY KEY,
            follow_up_id TEXT NOT NULL REFERENCES follow_up_items(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            project_id TEXT REFERENCES projects(id),
            source_observation_id TEXT,
            source_attendance_day_id TEXT,
            source_concrete_pour_id TEXT,
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
            FOREIGN KEY (source_attendance_day_id, project_id)
              REFERENCES attendance_days(id, project_id),
            FOREIGN KEY (source_concrete_pour_id, project_id)
              REFERENCES concrete_pours(id, project_id),
            UNIQUE (follow_up_id, sequence),
            CHECK (
              (source_observation_id IS NOT NULL)
                + (source_attendance_day_id IS NOT NULL)
                + (source_concrete_pour_id IS NOT NULL) <= 1
            ),
            CHECK (
              (source_observation_id IS NULL
                AND source_attendance_day_id IS NULL
                AND source_concrete_pour_id IS NULL)
              OR project_id IS NOT NULL
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO follow_up_events (
            id, follow_up_id, sequence, project_id,
            source_observation_id, source_attendance_day_id,
            source_concrete_pour_id, event_type, occurred_at, payload_json
          )
          SELECT
            id, follow_up_id, sequence, project_id,
            source_observation_id, source_attendance_day_id,
            NULL, event_type, occurred_at, payload_json
          FROM follow_up_events_v4
        ''');
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
          SELECT reminder_id, platform_notification_id, scheduled_for,
            sync_state, last_synced_at, safe_error_code
          FROM reminder_notification_bindings_v4
        ''');
        await transaction.execute('''
          CREATE TABLE attendance_day_reminder_links (
            attendance_day_id TEXT PRIMARY KEY REFERENCES attendance_days(id),
            reminder_id TEXT NOT NULL UNIQUE REFERENCES follow_up_items(id),
            due_at TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await transaction.execute('''
          INSERT INTO attendance_day_reminder_links (
            attendance_day_id, reminder_id, due_at, created_at
          )
          SELECT attendance_day_id, reminder_id, due_at, created_at
          FROM attendance_day_reminder_links_v4
        ''');
        await transaction.execute(
          'DROP TABLE attendance_day_reminder_links_v4',
        );
        await transaction.execute(
          'DROP TABLE reminder_notification_bindings_v4',
        );
        await transaction.execute('DROP TABLE follow_up_events_v4');
        await transaction.execute('DROP TABLE follow_up_items_v4');

        // The concrete follow-up table is created before the reminder table is
        // rebuilt so legacy reminders can be copied without disabling foreign
        // keys. Rebuild the still-empty v5 table now to make the source link a
        // real database invariant as well as an application invariant.
        await transaction.execute(
          'ALTER TABLE concrete_follow_up_items '
          'RENAME TO concrete_follow_up_items_unlinked',
        );
        await transaction.execute('''
          CREATE TABLE concrete_follow_up_items (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            source_sample_set_id TEXT,
            item_key TEXT NOT NULL,
            label TEXT NOT NULL,
            due_at TEXT,
            status TEXT NOT NULL CHECK (status IN (
              'pending', 'completed', 'exception'
            )),
            reminder_id TEXT UNIQUE REFERENCES follow_up_items(id),
            note TEXT,
            reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            completed_at TEXT,
            UNIQUE (concrete_pour_id, item_key),
            UNIQUE (id, concrete_pour_id),
            FOREIGN KEY (source_sample_set_id, concrete_pour_id)
              REFERENCES concrete_sample_sets(id, concrete_pour_id),
            CHECK (
              (status = 'pending' AND completed_at IS NULL)
              OR (status IN ('completed', 'exception')
                AND completed_at IS NOT NULL)
            ),
            CHECK (
              status != 'exception'
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO concrete_follow_up_items (
            id, concrete_pour_id, source_sample_set_id, item_key, label,
            due_at, status, reminder_id, note, reason, revision, created_at,
            updated_at, completed_at
          )
          SELECT
            id, concrete_pour_id, source_sample_set_id, item_key, label,
            due_at, status, reminder_id, note, reason, revision, created_at,
            updated_at, completed_at
          FROM concrete_follow_up_items_unlinked
        ''');
        await transaction.execute(
          'DROP TABLE concrete_follow_up_items_unlinked',
        );

        await transaction.execute('''
          CREATE INDEX ix_concrete_pours_project_planned
          ON concrete_pours(project_id, planned_at, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_concrete_checks_pour_order
          ON concrete_check_items(concrete_pour_id, sort_order, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_concrete_trucks_pour_sequence
          ON concrete_trucks(concrete_pour_id, sequence_no, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_concrete_samples_pour
          ON concrete_sample_sets(concrete_pour_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_concrete_followups_pour
          ON concrete_follow_up_items(concrete_pour_id, status, due_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_concrete_attachments_pour
          ON concrete_attachments(
            concrete_pour_id, archived_at, evidence_type, created_at, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_attention_v5
          ON follow_up_items(
            status, next_attention_at, is_important, created_at, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_observation_v5
          ON follow_up_items(observation_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_attendance_v5
          ON follow_up_items(attendance_day_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_concrete_v5
          ON follow_up_items(concrete_pour_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_notification_bindings_schedule_v5
          ON reminder_notification_bindings(sync_state, scheduled_for)
        ''');
        for (final table in ['concrete_pour_events', 'follow_up_events']) {
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
          'concrete_pours',
          'concrete_check_items',
          'concrete_trucks',
          'concrete_sample_sets',
          'concrete_follow_up_items',
          'concrete_attachments',
          'follow_up_items',
          'attendance_day_reminder_links',
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
      version: 6,
      apply: (transaction) async {
        await transaction.execute('''
          CREATE TABLE subcontractors (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            name TEXT NOT NULL,
            name_normalized TEXT NOT NULL,
            contact_name TEXT,
            phone TEXT,
            note TEXT,
            status TEXT NOT NULL CHECK (status IN ('active', 'archived')),
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            archived_at TEXT,
            UNIQUE (project_id, name_normalized),
            UNIQUE (id, project_id),
            CHECK (
              (status = 'active' AND archived_at IS NULL)
              OR (status = 'archived' AND archived_at IS NOT NULL)
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE workforce_teams (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            subcontractor_id TEXT NOT NULL,
            name TEXT NOT NULL,
            name_normalized TEXT NOT NULL,
            lead_name TEXT,
            note TEXT,
            status TEXT NOT NULL CHECK (status IN ('active', 'archived')),
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            archived_at TEXT,
            UNIQUE (subcontractor_id, name_normalized),
            UNIQUE (id, project_id),
            FOREIGN KEY (subcontractor_id, project_id)
              REFERENCES subcontractors(id, project_id),
            CHECK (
              (status = 'active' AND archived_at IS NULL)
              OR (status = 'archived' AND archived_at IS NOT NULL)
            )
          )
        ''');

        await transaction.execute(
          'ALTER TABLE workforce_members ADD COLUMN subcontractor_id TEXT '
          'REFERENCES subcontractors(id)',
        );
        await transaction.execute(
          'ALTER TABLE workforce_members ADD COLUMN team_id TEXT '
          'REFERENCES workforce_teams(id)',
        );
        await transaction.execute(
          'ALTER TABLE workforce_members ADD COLUMN phone TEXT',
        );
        await transaction.execute(
          'ALTER TABLE workforce_members ADD COLUMN note TEXT',
        );

        await transaction.execute('''
          CREATE TABLE workforce_events (
            id TEXT PRIMARY KEY,
            aggregate_type TEXT NOT NULL CHECK (aggregate_type IN (
              'subcontractor', 'team', 'person', 'compliance', 'ppe'
            )),
            aggregate_id TEXT NOT NULL,
            project_id TEXT NOT NULL REFERENCES projects(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            event_type TEXT NOT NULL,
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            UNIQUE (aggregate_type, aggregate_id, sequence)
          )
        ''');
        await transaction.execute('''
          CREATE TABLE workforce_compliance_records (
            id TEXT PRIMARY KEY,
            workforce_member_id TEXT NOT NULL REFERENCES workforce_members(id),
            document_type TEXT NOT NULL CHECK (document_type IN (
              'employment_entry', 'health_report', 'basic_safety_training',
              'vocational_certificate', 'other'
            )),
            document_number TEXT,
            issued_date TEXT,
            expiry_date TEXT,
            source_status TEXT NOT NULL CHECK (source_status IN (
              'valid', 'missing', 'not_applicable', 'exception'
            )),
            note TEXT,
            reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            archived_at TEXT,
            CHECK (
              source_status NOT IN ('not_applicable', 'exception')
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            )
          )
        ''');
        await transaction.execute('''
          CREATE TABLE workforce_ppe_assignments (
            id TEXT PRIMARY KEY,
            workforce_member_id TEXT NOT NULL REFERENCES workforce_members(id),
            ppe_type TEXT NOT NULL,
            brand_model TEXT,
            size TEXT,
            serial_tag TEXT,
            quantity INTEGER NOT NULL CHECK (quantity >= 1),
            assigned_date TEXT NOT NULL,
            status TEXT NOT NULL CHECK (status IN (
              'assigned', 'returned', 'lost', 'damaged', 'archived'
            )),
            returned_date TEXT,
            note TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            archived_at TEXT,
            CHECK (
              status != 'returned' OR returned_date IS NOT NULL
            ),
            CHECK (
              status != 'archived' OR archived_at IS NOT NULL
            )
          )
        ''');
        await transaction.execute(
          'ALTER TABLE reminder_notification_bindings '
          'ADD COLUMN repeat_interval_minutes INTEGER CHECK '
          '(repeat_interval_minutes IS NULL OR repeat_interval_minutes = 60)',
        );

        final legacyRows = await transaction.rawQuery('''
          SELECT project_id, team_name, min(created_at) AS created_at,
            max(updated_at) AS updated_at
          FROM workforce_members
          GROUP BY project_id, team_name
          ORDER BY project_id ASC, team_name COLLATE NOCASE ASC
        ''');
        for (final row in legacyRows) {
          final projectId = row['project_id']! as String;
          final rawName = (row['team_name']! as String).trim();
          final name = rawName.isEmpty ? 'Tanımsız ekip' : rawName;
          final normalized = _normalizeRegistryName(name);
          final subcontractorId = _migrationStableUuid(
            'legacy-subcontractor:$projectId:$normalized',
          );
          final teamId = _migrationStableUuid(
            'legacy-team:$projectId:$normalized',
          );
          final createdAt = row['created_at']! as String;
          final updatedAt = row['updated_at']! as String;
          await transaction.insert('subcontractors', {
            'id': subcontractorId,
            'project_id': projectId,
            'name': name,
            'name_normalized': normalized,
            'status': 'active',
            'revision': 1,
            'created_at': createdAt,
            'updated_at': updatedAt,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          await transaction.insert('workforce_teams', {
            'id': teamId,
            'project_id': projectId,
            'subcontractor_id': subcontractorId,
            'name': name,
            'name_normalized': normalized,
            'status': 'active',
            'revision': 1,
            'created_at': createdAt,
            'updated_at': updatedAt,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          await transaction.update(
            'workforce_members',
            {'subcontractor_id': subcontractorId, 'team_id': teamId},
            where: 'project_id = ? AND team_name = ?',
            whereArgs: [projectId, row['team_name']],
          );
          await transaction.insert('workforce_events', {
            'id': _migrationStableUuid(
              'legacy-subcontractor-event:$subcontractorId',
            ),
            'aggregate_type': 'subcontractor',
            'aggregate_id': subcontractorId,
            'project_id': projectId,
            'sequence': 1,
            'event_type': 'subcontractor.migrated',
            'occurred_at': updatedAt,
            'payload_json': '{}',
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          await transaction.insert('workforce_events', {
            'id': _migrationStableUuid('legacy-team-event:$teamId'),
            'aggregate_type': 'team',
            'aggregate_id': teamId,
            'project_id': projectId,
            'sequence': 1,
            'event_type': 'team.migrated',
            'occurred_at': updatedAt,
            'payload_json': '{}',
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        final migratedMembers = await transaction.query(
          'workforce_members',
          orderBy: 'project_id ASC, id ASC',
        );
        for (final member in migratedMembers) {
          await transaction.insert('workforce_events', {
            'id': _migrationStableUuid('legacy-person-event:${member['id']}'),
            'aggregate_type': 'person',
            'aggregate_id': member['id'],
            'project_id': member['project_id'],
            'sequence': 1,
            'event_type': 'person.migrated',
            'occurred_at': member['updated_at'],
            'payload_json': '{}',
          });
        }

        await transaction.execute('''
          CREATE TRIGGER workforce_members_registry_required_insert
          BEFORE INSERT ON workforce_members
          WHEN NEW.subcontractor_id IS NULL OR NEW.team_id IS NULL
          BEGIN
            SELECT RAISE(ABORT, 'workforce registry link is required');
          END
        ''');
        await transaction.execute('''
          CREATE TRIGGER workforce_members_registry_required_update
          BEFORE UPDATE OF project_id, subcontractor_id, team_id
          ON workforce_members
          WHEN NEW.subcontractor_id IS NULL OR NEW.team_id IS NULL
            OR NOT EXISTS (
              SELECT 1 FROM workforce_teams t
              WHERE t.id = NEW.team_id
                AND t.subcontractor_id = NEW.subcontractor_id
                AND t.project_id = NEW.project_id
            )
          BEGIN
            SELECT RAISE(ABORT, 'workforce registry link is invalid');
          END
        ''');
        await transaction.execute('''
          CREATE TRIGGER workforce_members_registry_valid_insert
          BEFORE INSERT ON workforce_members
          WHEN NOT EXISTS (
            SELECT 1 FROM workforce_teams t
            WHERE t.id = NEW.team_id
              AND t.subcontractor_id = NEW.subcontractor_id
              AND t.project_id = NEW.project_id
          )
          BEGIN
            SELECT RAISE(ABORT, 'workforce registry link is invalid');
          END
        ''');
        await transaction.execute('''
          CREATE INDEX ix_subcontractors_project_name
          ON subcontractors(project_id, status, name_normalized, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_workforce_teams_registry
          ON workforce_teams(
            project_id, subcontractor_id, status, name_normalized, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_workforce_members_registry
          ON workforce_members(
            project_id, subcontractor_id, team_id, is_active, full_name, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_workforce_compliance_member
          ON workforce_compliance_records(
            workforce_member_id, archived_at, document_type, expiry_date, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_workforce_ppe_member
          ON workforce_ppe_assignments(
            workforce_member_id, status, assigned_date, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_workforce_events_aggregate
          ON workforce_events(aggregate_type, aggregate_id, sequence, id)
        ''');
        for (final table in ['workforce_events']) {
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
          'subcontractors',
          'workforce_teams',
          'workforce_compliance_records',
          'workforce_ppe_assignments',
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
      version: 7,
      apply: (transaction) async {
        await transaction.execute('''
          CREATE TABLE agenda_log_attachments (
            id TEXT PRIMARY KEY,
            observation_id TEXT NOT NULL,
            project_id TEXT NOT NULL,
            attachment_type TEXT NOT NULL CHECK (
              attachment_type = 'site_photo'
            ),
            original_file_name TEXT NOT NULL,
            mime_type TEXT NOT NULL CHECK (
              mime_type IN ('image/jpeg', 'image/png')
            ),
            byte_size INTEGER NOT NULL CHECK (byte_size > 0),
            sha256 TEXT NOT NULL CHECK (length(sha256) = 64),
            relative_path TEXT NOT NULL UNIQUE,
            description TEXT,
            captured_at TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            archived_at TEXT,
            UNIQUE (observation_id, sha256),
            FOREIGN KEY (observation_id, project_id)
              REFERENCES field_observations(id, project_id)
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_agenda_log_attachments_log
          ON agenda_log_attachments(
            observation_id, archived_at, created_at, id
          )
        ''');
        await transaction.execute('''
          CREATE TRIGGER agenda_log_attachments_no_physical_delete
          BEFORE DELETE ON agenda_log_attachments
          BEGIN
            SELECT RAISE(ABORT, 'physical delete is not allowed');
          END
        ''');

        // SQLite cannot remove the v5 automatic UNIQUE index in place. Rebuild
        // the complete truck child graph inside this migration so an empty
        // delivery-note value is truly nullable without weakening any FK.
        for (final table in [
          'concrete_trucks',
          'concrete_sample_sets',
          'concrete_follow_up_items',
          'concrete_attachments',
        ]) {
          await transaction.execute('DROP TRIGGER ${table}_no_physical_delete');
        }
        for (final index in [
          'ix_concrete_trucks_pour_sequence',
          'ix_concrete_samples_pour',
          'ix_concrete_followups_pour',
          'ix_concrete_attachments_pour',
        ]) {
          await transaction.execute('DROP INDEX $index');
        }
        await transaction.execute(
          'ALTER TABLE concrete_trucks RENAME TO concrete_trucks_v6',
        );
        await transaction.execute(
          'ALTER TABLE concrete_sample_sets '
          'RENAME TO concrete_sample_sets_v6',
        );
        await transaction.execute(
          'ALTER TABLE concrete_follow_up_items '
          'RENAME TO concrete_follow_up_items_v6',
        );
        await transaction.execute(
          'ALTER TABLE concrete_attachments '
          'RENAME TO concrete_attachments_v6',
        );

        await transaction.execute('''
          CREATE TABLE concrete_trucks (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            sequence_no INTEGER NOT NULL CHECK (sequence_no >= 1),
            vehicle_plate TEXT NOT NULL,
            delivery_note_number TEXT,
            plant_snapshot TEXT,
            batch_time TEXT,
            arrived_at TEXT,
            unloading_started_at TEXT,
            unloading_ended_at TEXT,
            volume_m3 REAL NOT NULL CHECK (volume_m3 > 0),
            measured_slump REAL CHECK (
              measured_slump IS NULL OR measured_slump >= 0
            ),
            concrete_temperature REAL,
            result TEXT NOT NULL CHECK (result IN (
              'received', 'held', 'returned', 'partial'
            )),
            reason TEXT,
            note TEXT,
            evidence_exception_reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE (concrete_pour_id, sequence_no),
            UNIQUE (id, concrete_pour_id),
            CHECK (
              delivery_note_number IS NULL
              OR length(trim(delivery_note_number)) > 0
            ),
            CHECK (
              result = 'received'
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            ),
            CHECK (
              unloading_started_at IS NULL OR arrived_at IS NULL
              OR unloading_started_at >= arrived_at
            ),
            CHECK (
              unloading_ended_at IS NULL OR unloading_started_at IS NOT NULL
            ),
            CHECK (
              unloading_ended_at IS NULL
              OR unloading_ended_at >= unloading_started_at
            )
          )
        ''');
        await transaction.execute('''
          CREATE UNIQUE INDEX ux_concrete_trucks_delivery_note
          ON concrete_trucks(concrete_pour_id, delivery_note_number)
          WHERE delivery_note_number IS NOT NULL
        ''');
        await transaction.execute('''
          INSERT INTO concrete_trucks (
            id, concrete_pour_id, sequence_no, vehicle_plate,
            delivery_note_number, plant_snapshot, batch_time, arrived_at,
            unloading_started_at, unloading_ended_at, volume_m3,
            measured_slump, concrete_temperature, result, reason, note,
            evidence_exception_reason, revision, created_at, updated_at
          )
          SELECT
            id, concrete_pour_id, sequence_no, vehicle_plate,
            nullif(trim(delivery_note_number), ''), plant_snapshot, batch_time,
            arrived_at, unloading_started_at, unloading_ended_at, volume_m3,
            measured_slump, concrete_temperature, result, reason, NULL,
            evidence_exception_reason, revision, created_at, updated_at
          FROM concrete_trucks_v6
        ''');

        await transaction.execute('''
          CREATE TABLE concrete_sample_sets (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            source_truck_id TEXT,
            sample_code TEXT NOT NULL,
            sample_count INTEGER NOT NULL CHECK (sample_count >= 0),
            sample_labels_json TEXT NOT NULL,
            sampled_at TEXT,
            sampled_by TEXT,
            laboratory_appointment_at TEXT,
            delivered_at TEXT,
            delivered_to TEXT,
            expected_result_dates_json TEXT NOT NULL,
            status TEXT NOT NULL CHECK (status IN (
              'planned', 'sampled', 'delivered', 'waiting_result',
              'completed', 'exception'
            )),
            note TEXT,
            reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE (concrete_pour_id, sample_code),
            UNIQUE (id, concrete_pour_id),
            FOREIGN KEY (source_truck_id, concrete_pour_id)
              REFERENCES concrete_trucks(id, concrete_pour_id),
            CHECK (
              status NOT IN ('sampled', 'delivered', 'waiting_result',
                'completed')
              OR (sampled_at IS NOT NULL AND sample_count > 0)
            ),
            CHECK (
              status NOT IN ('delivered', 'waiting_result', 'completed')
              OR delivered_at IS NOT NULL
            ),
            CHECK (
              status != 'exception'
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO concrete_sample_sets
          SELECT * FROM concrete_sample_sets_v6
        ''');

        await transaction.execute('''
          CREATE TABLE concrete_follow_up_items (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            source_sample_set_id TEXT,
            item_key TEXT NOT NULL,
            label TEXT NOT NULL,
            due_at TEXT,
            status TEXT NOT NULL CHECK (status IN (
              'pending', 'completed', 'exception'
            )),
            reminder_id TEXT UNIQUE REFERENCES follow_up_items(id),
            note TEXT,
            reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            completed_at TEXT,
            UNIQUE (concrete_pour_id, item_key),
            UNIQUE (id, concrete_pour_id),
            FOREIGN KEY (source_sample_set_id, concrete_pour_id)
              REFERENCES concrete_sample_sets(id, concrete_pour_id),
            CHECK (
              (status = 'pending' AND completed_at IS NULL)
              OR (status IN ('completed', 'exception')
                AND completed_at IS NOT NULL)
            ),
            CHECK (
              status != 'exception'
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO concrete_follow_up_items
          SELECT * FROM concrete_follow_up_items_v6
        ''');

        await transaction.execute('''
          CREATE TABLE concrete_attachments (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            truck_id TEXT,
            sample_set_id TEXT,
            check_item_id TEXT,
            evidence_type TEXT NOT NULL CHECK (evidence_type IN (
              'delivery_receipt_scan', 'delivery_note_scan', 'mixer_photo',
              'site_photo', 'sample_photo',
              'laboratory_delivery_document', 'result_document', 'other'
            )),
            original_file_name TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            byte_size INTEGER NOT NULL CHECK (byte_size > 0),
            sha256 TEXT NOT NULL CHECK (length(sha256) = 64),
            relative_path TEXT NOT NULL UNIQUE,
            captured_at TEXT NOT NULL,
            description TEXT,
            created_at TEXT NOT NULL,
            archived_at TEXT,
            UNIQUE (concrete_pour_id, sha256),
            FOREIGN KEY (truck_id, concrete_pour_id)
              REFERENCES concrete_trucks(id, concrete_pour_id),
            FOREIGN KEY (sample_set_id, concrete_pour_id)
              REFERENCES concrete_sample_sets(id, concrete_pour_id),
            FOREIGN KEY (check_item_id, concrete_pour_id)
              REFERENCES concrete_check_items(id, concrete_pour_id),
            CHECK (
              (truck_id IS NOT NULL) + (sample_set_id IS NOT NULL)
                + (check_item_id IS NOT NULL) <= 1
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO concrete_attachments
          SELECT * FROM concrete_attachments_v6
        ''');

        await transaction.execute('DROP TABLE concrete_attachments_v6');
        await transaction.execute('DROP TABLE concrete_follow_up_items_v6');
        await transaction.execute('DROP TABLE concrete_sample_sets_v6');
        await transaction.execute('DROP TABLE concrete_trucks_v6');

        await transaction.execute('''
          CREATE INDEX ix_concrete_trucks_pour_sequence
          ON concrete_trucks(concrete_pour_id, sequence_no, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_concrete_samples_pour
          ON concrete_sample_sets(concrete_pour_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_concrete_followups_pour
          ON concrete_follow_up_items(concrete_pour_id, status, due_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_concrete_attachments_pour
          ON concrete_attachments(
            concrete_pour_id, archived_at, evidence_type, created_at, id
          )
        ''');
        for (final table in [
          'concrete_trucks',
          'concrete_sample_sets',
          'concrete_follow_up_items',
          'concrete_attachments',
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
      version: 8,
      apply: (transaction) async {
        for (final trigger in [
          'follow_up_events_append_only_update',
          'follow_up_events_append_only_delete',
          'follow_up_items_no_physical_delete',
          'attendance_day_reminder_links_no_physical_delete',
          'concrete_follow_up_items_no_physical_delete',
        ]) {
          await transaction.execute('DROP TRIGGER IF EXISTS $trigger');
        }
        for (final index in [
          'ix_follow_ups_attention_v5',
          'ix_follow_ups_observation_v5',
          'ix_follow_ups_attendance_v5',
          'ix_follow_ups_concrete_v5',
          'ix_notification_bindings_schedule_v5',
        ]) {
          await transaction.execute('DROP INDEX IF EXISTS $index');
        }

        await transaction.execute(
          'ALTER TABLE attendance_day_reminder_links '
          'RENAME TO attendance_day_reminder_links_v7',
        );
        await transaction.execute(
          'ALTER TABLE concrete_follow_up_items '
          'RENAME TO concrete_follow_up_items_v7',
        );
        await transaction.execute(
          'ALTER TABLE reminder_notification_bindings '
          'RENAME TO reminder_notification_bindings_v7',
        );
        await transaction.execute(
          'ALTER TABLE follow_up_events RENAME TO follow_up_events_v7',
        );
        await transaction.execute(
          'ALTER TABLE follow_up_items RENAME TO follow_up_items_v7',
        );

        await transaction.execute('''
          CREATE TABLE follow_up_items (
            id TEXT PRIMARY KEY,
            capture_text TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            item_type TEXT NOT NULL CHECK (
              item_type IN ('action', 'recheck')
            ),
            status TEXT NOT NULL CHECK (
              status IN ('inbox', 'active', 'completed', 'cancelled')
            ),
            project_id TEXT REFERENCES projects(id),
            observation_id TEXT,
            attendance_day_id TEXT,
            concrete_pour_id TEXT,
            location TEXT,
            related_person TEXT,
            is_important INTEGER NOT NULL DEFAULT 0 CHECK (
              is_important IN (0, 1)
            ),
            next_attention_at TEXT,
            all_day_local_date TEXT,
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
            FOREIGN KEY (attendance_day_id, project_id)
              REFERENCES attendance_days(id, project_id),
            FOREIGN KEY (concrete_pour_id, project_id)
              REFERENCES concrete_pours(id, project_id),
            CHECK (
              (observation_id IS NOT NULL) + (attendance_day_id IS NOT NULL)
                + (concrete_pour_id IS NOT NULL) <= 1
            ),
            CHECK (
              (observation_id IS NULL AND attendance_day_id IS NULL
                AND concrete_pour_id IS NULL)
              OR project_id IS NOT NULL
            ),
            CHECK (
              next_attention_at IS NULL OR all_day_local_date IS NULL
            ),
            CHECK (
              all_day_local_date IS NULL
              OR all_day_local_date GLOB
                '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
            ),
            CHECK (
              (status = 'inbox' AND next_attention_at IS NULL
                AND all_day_local_date IS NULL)
              OR (status = 'active' AND (
                (next_attention_at IS NOT NULL
                  AND all_day_local_date IS NULL)
                OR (next_attention_at IS NULL
                  AND all_day_local_date IS NOT NULL)
              ))
              OR status IN ('completed', 'cancelled')
            ),
            CHECK (
              (status = 'completed' AND completed_at IS NOT NULL
                AND cancelled_at IS NULL AND outcome_type IS NOT NULL)
              OR (status = 'cancelled' AND cancelled_at IS NOT NULL
                AND completed_at IS NULL AND outcome_type IS NOT NULL)
              OR (status IN ('inbox', 'active')
                AND completed_at IS NULL AND cancelled_at IS NULL
                AND outcome_type IS NULL AND outcome_note IS NULL)
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO follow_up_items (
            id, capture_text, title, description, item_type, status,
            project_id, observation_id, attendance_day_id, concrete_pour_id,
            location, related_person, is_important, next_attention_at,
            all_day_local_date, deadline_at, condition_text, outcome_type,
            outcome_note, revision, created_at, updated_at, completed_at,
            cancelled_at
          )
          SELECT
            id, capture_text, title, description,
            CASE WHEN item_type = 'waiting' THEN 'action' ELSE item_type END,
            CASE WHEN status = 'waiting' THEN 'active' ELSE status END,
            project_id, observation_id, attendance_day_id, concrete_pour_id,
            location, related_person, is_important, next_attention_at,
            NULL, deadline_at, condition_text, outcome_type, outcome_note,
            revision, created_at, updated_at, completed_at, cancelled_at
          FROM follow_up_items_v7
        ''');

        await transaction.execute('''
          CREATE TABLE follow_up_events (
            id TEXT PRIMARY KEY,
            follow_up_id TEXT NOT NULL REFERENCES follow_up_items(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            project_id TEXT REFERENCES projects(id),
            source_observation_id TEXT,
            source_attendance_day_id TEXT,
            source_concrete_pour_id TEXT,
            event_type TEXT NOT NULL CHECK (event_type IN (
              'created', 'scheduled', 'rescheduled', 'details_updated',
              'waiting_started', 'legacy_waiting_normalized', 'snoozed',
              'completed', 'cancelled', 'reopened', 'moved_to_inbox',
              'notification_scheduled', 'notification_cancelled'
            )),
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            FOREIGN KEY (source_observation_id, project_id)
              REFERENCES field_observations(id, project_id),
            FOREIGN KEY (source_attendance_day_id, project_id)
              REFERENCES attendance_days(id, project_id),
            FOREIGN KEY (source_concrete_pour_id, project_id)
              REFERENCES concrete_pours(id, project_id),
            UNIQUE (follow_up_id, sequence),
            CHECK (
              (source_observation_id IS NOT NULL)
                + (source_attendance_day_id IS NOT NULL)
                + (source_concrete_pour_id IS NOT NULL) <= 1
            ),
            CHECK (
              (source_observation_id IS NULL
                AND source_attendance_day_id IS NULL
                AND source_concrete_pour_id IS NULL)
              OR project_id IS NOT NULL
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO follow_up_events (
            id, follow_up_id, sequence, project_id,
            source_observation_id, source_attendance_day_id,
            source_concrete_pour_id, event_type, occurred_at, payload_json
          )
          SELECT
            id, follow_up_id, sequence, project_id,
            source_observation_id, source_attendance_day_id,
            source_concrete_pour_id, event_type, occurred_at, payload_json
          FROM follow_up_events_v7
        ''');

        final legacyWaiting = await transaction.query(
          'follow_up_items_v7',
          where: "item_type = 'waiting' OR status = 'waiting'",
          orderBy: 'id ASC',
        );
        for (final row in legacyWaiting) {
          final reminderId = row['id']! as String;
          final sequence = Sqflite.firstIntValue(
            await transaction.rawQuery(
              '''
              SELECT COALESCE(MAX(sequence), 0) + 1
              FROM follow_up_events
              WHERE follow_up_id = ?
              ''',
              [reminderId],
            ),
          )!;
          await transaction.insert('follow_up_events', {
            'id': _migrationStableUuid(
              'schema8-legacy-waiting-normalized:$reminderId',
            ),
            'follow_up_id': reminderId,
            'sequence': sequence,
            'project_id': row['project_id'],
            'source_observation_id': row['observation_id'],
            'source_attendance_day_id': row['attendance_day_id'],
            'source_concrete_pour_id': row['concrete_pour_id'],
            'event_type': 'legacy_waiting_normalized',
            'occurred_at': row['updated_at'],
            'payload_json': jsonEncode({
              'from_item_type': row['item_type'],
              'from_status': row['status'],
              'next_attention_at': row['next_attention_at'],
              'to_item_type': row['item_type'] == 'waiting'
                  ? 'action'
                  : row['item_type'],
              'to_status': row['status'] == 'waiting'
                  ? 'active'
                  : row['status'],
            }),
          });
        }

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
            safe_error_code TEXT,
            repeat_interval_minutes INTEGER CHECK (
              repeat_interval_minutes IS NULL
              OR repeat_interval_minutes = 60
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO reminder_notification_bindings (
            reminder_id, platform_notification_id, scheduled_for,
            sync_state, last_synced_at, safe_error_code,
            repeat_interval_minutes
          )
          SELECT
            reminder_id, platform_notification_id, scheduled_for,
            sync_state, last_synced_at, safe_error_code,
            repeat_interval_minutes
          FROM reminder_notification_bindings_v7
        ''');

        await transaction.execute('''
          CREATE TABLE attendance_day_reminder_links (
            attendance_day_id TEXT PRIMARY KEY REFERENCES attendance_days(id),
            reminder_id TEXT NOT NULL UNIQUE REFERENCES follow_up_items(id),
            due_at TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await transaction.execute('''
          INSERT INTO attendance_day_reminder_links (
            attendance_day_id, reminder_id, due_at, created_at
          )
          SELECT attendance_day_id, reminder_id, due_at, created_at
          FROM attendance_day_reminder_links_v7
        ''');

        await transaction.execute('''
          CREATE TABLE concrete_follow_up_items (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            source_sample_set_id TEXT,
            item_key TEXT NOT NULL,
            label TEXT NOT NULL,
            due_at TEXT,
            status TEXT NOT NULL CHECK (status IN (
              'pending', 'completed', 'exception'
            )),
            reminder_id TEXT UNIQUE REFERENCES follow_up_items(id),
            note TEXT,
            reason TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            completed_at TEXT,
            UNIQUE (concrete_pour_id, item_key),
            UNIQUE (id, concrete_pour_id),
            FOREIGN KEY (source_sample_set_id, concrete_pour_id)
              REFERENCES concrete_sample_sets(id, concrete_pour_id),
            CHECK (
              (status = 'pending' AND completed_at IS NULL)
              OR (status IN ('completed', 'exception')
                AND completed_at IS NOT NULL)
            ),
            CHECK (
              status != 'exception'
              OR (reason IS NOT NULL AND length(trim(reason)) > 0)
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO concrete_follow_up_items (
            id, concrete_pour_id, source_sample_set_id, item_key, label,
            due_at, status, reminder_id, note, reason, revision, created_at,
            updated_at, completed_at
          )
          SELECT
            id, concrete_pour_id, source_sample_set_id, item_key, label,
            due_at, status, reminder_id, note, reason, revision, created_at,
            updated_at, completed_at
          FROM concrete_follow_up_items_v7
        ''');

        await transaction.execute(
          'DROP TABLE attendance_day_reminder_links_v7',
        );
        await transaction.execute('DROP TABLE concrete_follow_up_items_v7');
        await transaction.execute(
          'DROP TABLE reminder_notification_bindings_v7',
        );
        await transaction.execute('DROP TABLE follow_up_events_v7');
        await transaction.execute('DROP TABLE follow_up_items_v7');

        await transaction.execute('''
          CREATE INDEX ix_follow_ups_attention_v8
          ON follow_up_items(
            status, all_day_local_date, next_attention_at,
            is_important, created_at, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_observation_v8
          ON follow_up_items(observation_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_attendance_v8
          ON follow_up_items(attendance_day_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_concrete_v8
          ON follow_up_items(concrete_pour_id, created_at, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_notification_bindings_schedule_v8
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
        for (final table in [
          'follow_up_items',
          'attendance_day_reminder_links',
          'concrete_follow_up_items',
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
      version: 9,
      apply: (transaction) async {
        await transaction.execute('''
          ALTER TABLE follow_up_items
          ADD COLUMN trashed_at TEXT CHECK (
            trashed_at IS NULL
            OR (
              length(trashed_at) = 20
              AND trashed_at GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
            )
          )
        ''');
        await transaction.execute(
          'DROP TRIGGER follow_up_events_append_only_update',
        );
        await transaction.execute(
          'DROP TRIGGER follow_up_events_append_only_delete',
        );
        await transaction.execute(
          'ALTER TABLE follow_up_events RENAME TO follow_up_events_v8',
        );
        await transaction.execute('''
          CREATE TABLE follow_up_events (
            id TEXT PRIMARY KEY,
            follow_up_id TEXT NOT NULL REFERENCES follow_up_items(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            project_id TEXT REFERENCES projects(id),
            source_observation_id TEXT,
            source_attendance_day_id TEXT,
            source_concrete_pour_id TEXT,
            event_type TEXT NOT NULL CHECK (event_type IN (
              'created', 'scheduled', 'rescheduled', 'details_updated',
              'waiting_started', 'legacy_waiting_normalized', 'snoozed',
              'completed', 'cancelled', 'reopened', 'moved_to_inbox',
              'trashed', 'restored_from_trash',
              'notification_scheduled', 'notification_cancelled'
            )),
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            FOREIGN KEY (source_observation_id, project_id)
              REFERENCES field_observations(id, project_id),
            FOREIGN KEY (source_attendance_day_id, project_id)
              REFERENCES attendance_days(id, project_id),
            FOREIGN KEY (source_concrete_pour_id, project_id)
              REFERENCES concrete_pours(id, project_id),
            UNIQUE (follow_up_id, sequence),
            CHECK (
              (source_observation_id IS NOT NULL)
                + (source_attendance_day_id IS NOT NULL)
                + (source_concrete_pour_id IS NOT NULL) <= 1
            ),
            CHECK (
              (source_observation_id IS NULL
                AND source_attendance_day_id IS NULL
                AND source_concrete_pour_id IS NULL)
              OR project_id IS NOT NULL
            )
          )
        ''');
        await transaction.execute('''
          INSERT INTO follow_up_events (
            id, follow_up_id, sequence, project_id,
            source_observation_id, source_attendance_day_id,
            source_concrete_pour_id, event_type, occurred_at, payload_json
          )
          SELECT
            id, follow_up_id, sequence, project_id,
            source_observation_id, source_attendance_day_id,
            source_concrete_pour_id, event_type, occurred_at, payload_json
          FROM follow_up_events_v8
        ''');
        await transaction.execute('DROP TABLE follow_up_events_v8');
        await transaction.execute('''
          CREATE INDEX ix_follow_ups_trash_v9
          ON follow_up_items(trashed_at DESC, updated_at DESC, id ASC)
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
      },
    ),
    DatabaseMigration(
      version: 10,
      apply: (transaction) async {
        await transaction.execute('''
          CREATE TABLE project_concrete_classes (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            display_name TEXT NOT NULL,
            normalized_name TEXT NOT NULL,
            default_target_slump TEXT,
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            archived_at TEXT,
            UNIQUE (project_id, normalized_name),
            UNIQUE (id, project_id)
          )
        ''');
        await transaction.execute('''
          CREATE TABLE project_concrete_class_events (
            id TEXT PRIMARY KEY,
            concrete_class_id TEXT NOT NULL
              REFERENCES project_concrete_classes(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            event_type TEXT NOT NULL CHECK (event_type IN (
              'class.created', 'class.migrated', 'class.archived',
              'class.restored'
            )),
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            UNIQUE (concrete_class_id, sequence)
          )
        ''');
        await transaction.execute('''
          CREATE TABLE concrete_pour_context_links (
            concrete_pour_id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            concrete_class_id TEXT NOT NULL,
            agenda_log_id TEXT UNIQUE,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (concrete_pour_id, project_id)
              REFERENCES concrete_pours(id, project_id),
            FOREIGN KEY (concrete_class_id, project_id)
              REFERENCES project_concrete_classes(id, project_id),
            FOREIGN KEY (agenda_log_id, project_id)
              REFERENCES field_observations(id, project_id)
          )
        ''');

        final legacyPours = await transaction.query(
          'concrete_pours',
          orderBy: 'project_id ASC, created_at ASC, id ASC',
        );
        final classesByProjectAndName = <String, String>{};
        for (final row in legacyPours) {
          final pourId = row['id']! as String;
          final projectId = row['project_id']! as String;
          final snapshot = row['concrete_class']! as String;
          final displayName = snapshot.trim().replaceAll(RegExp(r'\s+'), ' ');
          if (displayName.isEmpty) {
            throw StateError('legacy concrete class is empty for pour $pourId');
          }
          final normalizedName = displayName.toLowerCase();
          final lookupKey = '$projectId\u0000$normalizedName';
          final concreteClassId = classesByProjectAndName.putIfAbsent(
            lookupKey,
            () => _migrationStableUuid(
              'legacy-concrete-class:$projectId:$normalizedName',
            ),
          );
          final existingClass = await transaction.query(
            'project_concrete_classes',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [concreteClassId],
            limit: 1,
          );
          if (existingClass.isEmpty) {
            final createdAt = row['created_at']! as String;
            final updatedAt = row['updated_at']! as String;
            await transaction.insert('project_concrete_classes', {
              'id': concreteClassId,
              'project_id': projectId,
              'display_name': displayName,
              'normalized_name': normalizedName,
              'default_target_slump': row['target_slump'],
              'revision': 1,
              'created_at': createdAt,
              'updated_at': updatedAt,
            });
            await transaction.insert('project_concrete_class_events', {
              'id': _migrationStableUuid(
                'legacy-concrete-class-event:$concreteClassId',
              ),
              'concrete_class_id': concreteClassId,
              'sequence': 1,
              'event_type': 'class.migrated',
              'occurred_at': updatedAt,
              'payload_json': jsonEncode({
                'normalized_name': normalizedName,
                'source': 'legacy_concrete_class_snapshot',
              }),
            });
          }
          await transaction.insert('concrete_pour_context_links', {
            'concrete_pour_id': pourId,
            'project_id': projectId,
            'concrete_class_id': concreteClassId,
            'created_at': row['created_at'],
            'updated_at': row['updated_at'],
          });
        }

        await transaction.execute(
          'DROP TRIGGER concrete_pour_events_append_only_update',
        );
        await transaction.execute(
          'DROP TRIGGER concrete_pour_events_append_only_delete',
        );
        await transaction.execute(
          'ALTER TABLE concrete_pour_events '
          'RENAME TO concrete_pour_events_v9',
        );
        await transaction.execute('''
          CREATE TABLE concrete_pour_events (
            id TEXT PRIMARY KEY,
            concrete_pour_id TEXT NOT NULL REFERENCES concrete_pours(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            event_type TEXT NOT NULL CHECK (event_type IN (
              'pour.created', 'pour.details_updated', 'check.updated',
              'pour.prepared', 'pour.started', 'truck.added',
              'truck.updated', 'evidence.attached', 'sample_set.added',
              'sample_set.updated', 'follow_up.linked', 'pour.finished',
              'pour.follow_up_started', 'pour.closed', 'pour.cancelled',
              'pour.reopened', 'agenda.linked', 'report.exported'
            )),
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            UNIQUE (concrete_pour_id, sequence)
          )
        ''');
        await transaction.execute('''
          INSERT INTO concrete_pour_events (
            id, concrete_pour_id, sequence, event_type, occurred_at,
            payload_json
          )
          SELECT
            id, concrete_pour_id, sequence, event_type, occurred_at,
            payload_json
          FROM concrete_pour_events_v9
        ''');
        await transaction.execute('DROP TABLE concrete_pour_events_v9');

        await transaction.execute('''
          CREATE INDEX ix_project_concrete_classes_active
          ON project_concrete_classes(
            project_id, archived_at, normalized_name, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_concrete_pour_context_agenda
          ON concrete_pour_context_links(agenda_log_id, concrete_pour_id)
        ''');
        for (final table in [
          'project_concrete_class_events',
          'concrete_pour_events',
        ]) {
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
          'project_concrete_classes',
          'concrete_pour_context_links',
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
      version: 11,
      apply: (transaction) async {
        await transaction.execute('''
          CREATE TABLE project_locations (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            display_name TEXT NOT NULL,
            normalized_name TEXT NOT NULL,
            parent_location_id TEXT REFERENCES project_locations(id),
            revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            archived_at TEXT,
            UNIQUE (id, project_id),
            FOREIGN KEY (parent_location_id, project_id)
              REFERENCES project_locations(id, project_id),
            CHECK (parent_location_id IS NULL OR parent_location_id != id)
          )
        ''');
        await transaction.execute('''
          CREATE TABLE project_events (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL REFERENCES projects(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            event_type TEXT NOT NULL CHECK (event_type IN (
              'project.renamed', 'project.archived', 'project.restored'
            )),
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            UNIQUE (project_id, sequence)
          )
        ''');
        await transaction.execute('''
          CREATE TABLE project_location_events (
            id TEXT PRIMARY KEY,
            location_id TEXT NOT NULL REFERENCES project_locations(id),
            sequence INTEGER NOT NULL CHECK (sequence >= 1),
            event_type TEXT NOT NULL CHECK (event_type IN (
              'location.created', 'location.renamed',
              'location.reparented', 'location.archived',
              'location.restored'
            )),
            occurred_at TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            UNIQUE (location_id, sequence)
          )
        ''');

        for (final table in [
          'field_observations',
          'follow_up_items',
          'concrete_pours',
        ]) {
          await transaction.execute('''
            ALTER TABLE $table
            ADD COLUMN location_id TEXT REFERENCES project_locations(id)
          ''');
        }

        await transaction.execute('''
          CREATE UNIQUE INDEX uq_project_locations_active_sibling_name
          ON project_locations(
            project_id,
            COALESCE(parent_location_id, ''),
            normalized_name
          )
          WHERE archived_at IS NULL
        ''');
        await transaction.execute('''
          CREATE INDEX ix_project_locations_project_parent
          ON project_locations(
            project_id, parent_location_id, archived_at, display_name, id
          )
        ''');
        await transaction.execute('''
          CREATE INDEX ix_project_events_project
          ON project_events(project_id, sequence, id)
        ''');
        await transaction.execute('''
          CREATE INDEX ix_project_location_events_location
          ON project_location_events(location_id, sequence, id)
        ''');

        for (final table in [
          'field_observations',
          'follow_up_items',
          'concrete_pours',
        ]) {
          await transaction.execute('''
            CREATE TRIGGER ${table}_location_project_insert
            BEFORE INSERT ON $table
            WHEN NEW.location_id IS NOT NULL AND NOT EXISTS (
              SELECT 1
              FROM project_locations
              WHERE id = NEW.location_id AND project_id = NEW.project_id
            )
            BEGIN
              SELECT RAISE(ABORT, 'location must belong to record project');
            END
          ''');
          await transaction.execute('''
            CREATE TRIGGER ${table}_location_project_update
            BEFORE UPDATE OF location_id, project_id ON $table
            WHEN NEW.location_id IS NOT NULL AND NOT EXISTS (
              SELECT 1
              FROM project_locations
              WHERE id = NEW.location_id AND project_id = NEW.project_id
            )
            BEGIN
              SELECT RAISE(ABORT, 'location must belong to record project');
            END
          ''');
        }

        for (final table in ['project_events', 'project_location_events']) {
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
        await transaction.execute('''
          CREATE TRIGGER project_locations_no_physical_delete
          BEFORE DELETE ON project_locations
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

String _normalizeRegistryName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

String _migrationStableUuid(String seed) {
  int hash(String value, int salt) {
    var result = (2166136261 ^ salt) & 0xffffffff;
    for (final unit in value.codeUnits) {
      result ^= unit;
      result = (result * 16777619) & 0xffffffff;
    }
    return result;
  }

  final raw = List.generate(
    4,
    (index) =>
        hash(seed, 0x9e3779b9 * (index + 1)).toRadixString(16).padLeft(8, '0'),
  ).join();
  final chars = raw.split('');
  chars[12] = '4';
  chars[16] = '8';
  final value = chars.join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}
