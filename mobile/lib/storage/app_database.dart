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

  static const schemaVersion = 20;

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
          CREATE TRIGGER project_locations_project_immutable
          BEFORE UPDATE OF project_id ON project_locations
          WHEN NEW.project_id != OLD.project_id
          BEGIN
            SELECT RAISE(ABORT, 'location project is immutable');
          END
        ''');
        await transaction.execute('''
          CREATE TRIGGER project_locations_no_physical_delete
          BEFORE DELETE ON project_locations
          BEGIN
            SELECT RAISE(ABORT, 'physical delete is not allowed');
          END
        ''');
      },
    ),
    DatabaseMigration(
      version: 12,
      apply: (transaction) async {
        for (final column in [
          'address TEXT',
          'specialty TEXT',
          'started_on TEXT',
          'ended_on TEXT',
        ]) {
          await transaction.execute(
            'ALTER TABLE subcontractors ADD COLUMN $column',
          );
        }
        for (final column in ['address TEXT', 'started_on TEXT']) {
          await transaction.execute(
            'ALTER TABLE workforce_members ADD COLUMN $column',
          );
        }
      },
    ),
    DatabaseMigration(version: 13, apply: _applyAttachmentFoundationMigration),
    DatabaseMigration(
      version: 14,
      apply: _applyConstructionScheduleSnapshotMigration,
    ),
    DatabaseMigration(
      version: 15,
      apply: _applyConstructionLivingPlanMigration,
    ),
    DatabaseMigration(
      version: 16,
      apply: _applyConstructionLivingPlanProgressMigration,
    ),
    DatabaseMigration(
      version: 17,
      apply: _applyConstructionScheduleSnapshotDependencyMigration,
    ),
    DatabaseMigration(version: 18, apply: _applyMaterialRequestMigration),
    DatabaseMigration(version: 19, apply: _applyAgendaPhoneCallMigration),
    DatabaseMigration(version: 20, apply: _applyInventoryFoundationMigration),
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

Future<void> _applyConstructionScheduleSnapshotMigration(
  Transaction transaction,
) async {
  await transaction.execute('''
    CREATE TABLE project_schedule_snapshots (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      project_id TEXT NOT NULL REFERENCES projects(id),
      profile_json TEXT NOT NULL CHECK (length(profile_json) > 0),
      corpus_version TEXT NOT NULL CHECK (
        length(corpus_version) > 0 AND corpus_version = trim(corpus_version)
      ),
      schedule_seed_version TEXT NOT NULL CHECK (
        length(schedule_seed_version) > 0
        AND schedule_seed_version = trim(schedule_seed_version)
      ),
      schedule_seed_provenance TEXT NOT NULL CHECK (
        length(schedule_seed_provenance) > 0
        AND schedule_seed_provenance = trim(schedule_seed_provenance)
      ),
      production_status TEXT NOT NULL CHECK (
        production_status = 'NOT_FOR_PRODUCTION'
      ),
      duration_source TEXT NOT NULL CHECK (
        duration_source = 'TEST_SEED_ONLY'
      ),
      baseline_status TEXT NOT NULL CHECK (
        baseline_status = 'NOT_A_BASELINE'
      ),
      schedule_start TEXT NOT NULL CHECK (
        length(schedule_start) = 10
        AND schedule_start GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
        AND date(schedule_start) IS NOT NULL
        AND date(schedule_start) = schedule_start
      ),
      schedule_finish TEXT NOT NULL CHECK (
        length(schedule_finish) = 10
        AND schedule_finish GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
        AND date(schedule_finish) IS NOT NULL
        AND date(schedule_finish) = schedule_finish
        AND schedule_finish >= schedule_start
      ),
      activity_count INTEGER NOT NULL CHECK (activity_count > 0),
      root_count INTEGER NOT NULL CHECK (root_count >= 0),
      leaf_count INTEGER NOT NULL CHECK (leaf_count >= 0),
      isolated_count INTEGER NOT NULL CHECK (isolated_count >= 0),
      milestone_count INTEGER NOT NULL CHECK (milestone_count >= 0),
      projection_sha256 TEXT NOT NULL CHECK (
        length(projection_sha256) = 64
        AND projection_sha256 NOT GLOB '*[^0-9a-f]*'
      ),
      generated_at TEXT NOT NULL CHECK (
        length(generated_at) = 20
        AND generated_at GLOB
          '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
        AND strftime(
          '%Y-%m-%dT%H:%M:%SZ', generated_at, '+0 seconds'
        ) IS NOT NULL
        AND strftime(
          '%Y-%m-%dT%H:%M:%SZ', generated_at, '+0 seconds'
        ) = generated_at
      ),
      superseded_at TEXT CHECK (
        superseded_at IS NULL OR (
          length(superseded_at) = 20
          AND superseded_at GLOB
            '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
          AND strftime(
            '%Y-%m-%dT%H:%M:%SZ', superseded_at, '+0 seconds'
          ) IS NOT NULL
          AND strftime(
            '%Y-%m-%dT%H:%M:%SZ', superseded_at, '+0 seconds'
          ) = superseded_at
          AND superseded_at >= generated_at
        )
      ),
      UNIQUE (id, project_id)
    )
  ''');
  await transaction.execute('''
    CREATE TABLE project_schedule_snapshot_activities (
      snapshot_id TEXT NOT NULL,
      project_id TEXT NOT NULL REFERENCES projects(id),
      instance_id TEXT NOT NULL CHECK (
        length(instance_id) > 0 AND instance_id = trim(instance_id)
      ),
      activity_id TEXT NOT NULL CHECK (
        length(activity_id) > 0 AND activity_id = trim(activity_id)
      ),
      start_date TEXT NOT NULL CHECK (
        length(start_date) = 10
        AND start_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
        AND date(start_date) IS NOT NULL
        AND date(start_date) = start_date
      ),
      finish_date TEXT NOT NULL CHECK (
        length(finish_date) = 10
        AND finish_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
        AND date(finish_date) IS NOT NULL
        AND date(finish_date) = finish_date
        AND finish_date >= start_date
      ),
      duration_days REAL NOT NULL CHECK (duration_days >= 0),
      rounded_scheduling_days INTEGER NOT NULL CHECK (
        rounded_scheduling_days >= 0
      ),
      duration_calendar_type TEXT NOT NULL CHECK (
        duration_calendar_type IN ('WORKING_DAY', 'CALENDAR_DAY')
      ),
      duration_status TEXT NOT NULL CHECK (
        duration_status IN ('SOURCE_BACKED', 'AI_SEED_ESTIMATE', 'UNKNOWN')
      ),
      duration_confidence TEXT NOT NULL CHECK (
        duration_confidence IN (
          'A_AUTHORITATIVE', 'D_AI_SEED', 'E_UNKNOWN'
        )
      ),
      is_milestone INTEGER NOT NULL CHECK (is_milestone IN (0, 1)),
      is_isolated INTEGER NOT NULL CHECK (is_isolated IN (0, 1)),
      row_sha256 TEXT NOT NULL CHECK (
        length(row_sha256) = 64
        AND row_sha256 NOT GLOB '*[^0-9a-f]*'
      ),
      PRIMARY KEY (snapshot_id, instance_id),
      FOREIGN KEY (snapshot_id, project_id)
        REFERENCES project_schedule_snapshots(id, project_id),
      CHECK (is_milestone = 0 OR start_date = finish_date)
    )
  ''');

  await transaction.execute('''
    CREATE UNIQUE INDEX project_schedule_snapshots_one_current
    ON project_schedule_snapshots(project_id)
    WHERE superseded_at IS NULL
  ''');
  await transaction.execute('''
    CREATE INDEX project_schedule_snapshots_history
    ON project_schedule_snapshots(project_id, generated_at DESC, id DESC)
  ''');
  await transaction.execute('''
    CREATE INDEX project_schedule_snapshot_activities_window
    ON project_schedule_snapshot_activities(
      project_id, snapshot_id, start_date, finish_date, instance_id
    )
  ''');

  await transaction.execute('''
    CREATE TRIGGER project_schedule_snapshot_activities_immutable_update
    BEFORE UPDATE ON project_schedule_snapshot_activities
    BEGIN
      SELECT RAISE(ABORT, 'schedule snapshot activities are immutable');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER project_schedule_snapshot_activities_immutable_delete
    BEFORE DELETE ON project_schedule_snapshot_activities
    BEGIN
      SELECT RAISE(ABORT, 'schedule snapshot activities are immutable');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER project_schedule_snapshots_no_physical_delete
    BEFORE DELETE ON project_schedule_snapshots
    BEGIN
      SELECT RAISE(ABORT, 'schedule snapshots cannot be deleted');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER project_schedule_snapshots_supersede_only
    BEFORE UPDATE ON project_schedule_snapshots
    WHEN NOT (
      OLD.superseded_at IS NULL
      AND NEW.superseded_at IS NOT NULL
      AND length(NEW.superseded_at) = 20
      AND NEW.superseded_at GLOB
        '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
      AND strftime(
        '%Y-%m-%dT%H:%M:%SZ', NEW.superseded_at, '+0 seconds'
      ) IS NOT NULL
      AND strftime(
        '%Y-%m-%dT%H:%M:%SZ', NEW.superseded_at, '+0 seconds'
      ) = NEW.superseded_at
      AND NEW.superseded_at >= OLD.generated_at
      AND NEW.id IS OLD.id
      AND NEW.project_id IS OLD.project_id
      AND NEW.profile_json IS OLD.profile_json
      AND NEW.corpus_version IS OLD.corpus_version
      AND NEW.schedule_seed_version IS OLD.schedule_seed_version
      AND NEW.schedule_seed_provenance IS OLD.schedule_seed_provenance
      AND NEW.production_status IS OLD.production_status
      AND NEW.duration_source IS OLD.duration_source
      AND NEW.baseline_status IS OLD.baseline_status
      AND NEW.schedule_start IS OLD.schedule_start
      AND NEW.schedule_finish IS OLD.schedule_finish
      AND NEW.activity_count IS OLD.activity_count
      AND NEW.root_count IS OLD.root_count
      AND NEW.leaf_count IS OLD.leaf_count
      AND NEW.isolated_count IS OLD.isolated_count
      AND NEW.milestone_count IS OLD.milestone_count
      AND NEW.projection_sha256 IS OLD.projection_sha256
      AND NEW.generated_at IS OLD.generated_at
    )
    BEGIN
      SELECT RAISE(ABORT, 'schedule snapshot metadata is immutable');
    END
  ''');
}

Future<void> _applyConstructionLivingPlanMigration(
  Transaction transaction,
) async {
  await transaction.execute('''
    CREATE UNIQUE INDEX project_schedule_snapshot_activities_living_plan_ref
    ON project_schedule_snapshot_activities(
      snapshot_id, project_id, instance_id, activity_id
    )
  ''');

  await transaction.execute('''
    CREATE TABLE project_living_plan_items (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      project_id TEXT NOT NULL REFERENCES projects(id),
      reference_snapshot_id TEXT NOT NULL,
      activity_instance_id TEXT NOT NULL CHECK (
        length(activity_instance_id) > 0
        AND activity_instance_id = trim(activity_instance_id)
      ),
      activity_id TEXT NOT NULL CHECK (
        length(activity_id) > 0 AND activity_id = trim(activity_id)
      ),
      activity_name_snapshot TEXT NOT NULL CHECK (
        length(activity_name_snapshot) > 0
        AND activity_name_snapshot = trim(activity_name_snapshot)
      ),
      activity_context_json TEXT NOT NULL CHECK (
        length(activity_context_json) > 0
        AND json_valid(activity_context_json) = 1
        AND json_type(activity_context_json) = 'object'
      ),
      natural_unit_snapshot TEXT NOT NULL CHECK (
        length(natural_unit_snapshot) > 0
        AND natural_unit_snapshot = trim(natural_unit_snapshot)
      ),
      planned_date TEXT NOT NULL CHECK (
        length(planned_date) = 10
        AND planned_date GLOB
          '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
        AND date(planned_date) IS NOT NULL
        AND date(planned_date) = planned_date
      ),
      status TEXT NOT NULL CHECK (
        status IN ('PLANNED', 'STARTED', 'COMPLETED', 'DEFERRED')
      ),
      note TEXT CHECK (
        note IS NULL OR (
          length(note) BETWEEN 1 AND 1000
          AND note = trim(note)
        )
      ),
      revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
      created_at TEXT NOT NULL CHECK (
        length(created_at) = 20
        AND created_at GLOB
          '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
        AND strftime('%Y-%m-%dT%H:%M:%SZ', created_at, '+0 seconds')
          IS NOT NULL
        AND strftime('%Y-%m-%dT%H:%M:%SZ', created_at, '+0 seconds')
          = created_at
      ),
      updated_at TEXT NOT NULL CHECK (
        length(updated_at) = 20
        AND updated_at GLOB
          '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
        AND strftime('%Y-%m-%dT%H:%M:%SZ', updated_at, '+0 seconds')
          IS NOT NULL
        AND strftime('%Y-%m-%dT%H:%M:%SZ', updated_at, '+0 seconds')
          = updated_at
        AND updated_at >= created_at
      ),
      status_changed_at TEXT NOT NULL CHECK (
        length(status_changed_at) = 20
        AND status_changed_at GLOB
          '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
        AND strftime(
          '%Y-%m-%dT%H:%M:%SZ', status_changed_at, '+0 seconds'
        ) IS NOT NULL
        AND strftime(
          '%Y-%m-%dT%H:%M:%SZ', status_changed_at, '+0 seconds'
        ) = status_changed_at
        AND status_changed_at <= updated_at
      ),
      UNIQUE (id, project_id),
      UNIQUE (project_id, activity_instance_id),
      FOREIGN KEY (
        reference_snapshot_id,
        project_id,
        activity_instance_id,
        activity_id
      ) REFERENCES project_schedule_snapshot_activities(
        snapshot_id,
        project_id,
        instance_id,
        activity_id
      )
    )
  ''');

  await transaction.execute('''
    CREATE TABLE project_living_plan_command_receipts (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      living_plan_item_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      event_type TEXT NOT NULL CHECK (
        event_type IN (
          'CREATED', 'STARTED', 'COMPLETED',
          'DEFERRED', 'REOPENED', 'NOTE_UPDATED'
        )
      ),
      intent_json TEXT NOT NULL CHECK (
        length(intent_json) > 0
        AND json_valid(intent_json) = 1
        AND json_type(intent_json) = 'object'
      ),
      result_json TEXT NOT NULL CHECK (
        length(result_json) > 0
        AND json_valid(result_json) = 1
        AND json_type(result_json) = 'object'
      ),
      result_revision INTEGER NOT NULL CHECK (result_revision >= 1),
      is_no_op INTEGER NOT NULL CHECK (is_no_op IN (0, 1)),
      event_sequence INTEGER CHECK (
        event_sequence IS NULL OR event_sequence >= 1
      ),
      CHECK (
        (
          is_no_op = 1
          AND event_sequence IS NULL
        ) OR (
          is_no_op = 0
          AND event_sequence = result_revision
        )
      ),
      UNIQUE (
        id,
        living_plan_item_id,
        project_id,
        event_type,
        event_sequence
      ),
      FOREIGN KEY (living_plan_item_id, project_id)
        REFERENCES project_living_plan_items(id, project_id)
    )
  ''');

  await transaction.execute('''
    CREATE TABLE project_living_plan_events (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      living_plan_item_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      sequence INTEGER NOT NULL CHECK (sequence >= 1),
      event_type TEXT NOT NULL CHECK (
        event_type IN (
          'CREATED', 'STARTED', 'COMPLETED',
          'DEFERRED', 'REOPENED', 'NOTE_UPDATED'
        )
      ),
      occurred_at TEXT NOT NULL CHECK (
        length(occurred_at) = 20
        AND occurred_at GLOB
          '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
        AND strftime('%Y-%m-%dT%H:%M:%SZ', occurred_at, '+0 seconds')
          IS NOT NULL
        AND strftime('%Y-%m-%dT%H:%M:%SZ', occurred_at, '+0 seconds')
          = occurred_at
      ),
      payload_json TEXT NOT NULL CHECK (
        length(payload_json) > 0
        AND json_valid(payload_json) = 1
        AND json_type(payload_json) = 'object'
      ),
      UNIQUE (living_plan_item_id, sequence),
      FOREIGN KEY (living_plan_item_id, project_id)
        REFERENCES project_living_plan_items(id, project_id),
      FOREIGN KEY (
        id,
        living_plan_item_id,
        project_id,
        event_type,
        sequence
      ) REFERENCES project_living_plan_command_receipts(
        id,
        living_plan_item_id,
        project_id,
        event_type,
        event_sequence
      )
    )
  ''');

  await transaction.execute('''
    CREATE INDEX project_living_plan_items_window
    ON project_living_plan_items(
      project_id, planned_date, status, activity_name_snapshot, id
    )
  ''');
  await transaction.execute('''
    CREATE INDEX project_living_plan_items_reference
    ON project_living_plan_items(
      reference_snapshot_id, project_id, activity_instance_id, activity_id
    )
  ''');
  await transaction.execute('''
    CREATE INDEX project_living_plan_command_receipts_item
    ON project_living_plan_command_receipts(
      living_plan_item_id, result_revision, id
    )
  ''');
  await transaction.execute('''
    CREATE INDEX project_living_plan_events_history
    ON project_living_plan_events(living_plan_item_id, sequence)
  ''');

  await transaction.execute('''
    CREATE TRIGGER project_living_plan_command_receipts_result_match
    BEFORE INSERT ON project_living_plan_command_receipts
    WHEN NOT EXISTS (
      SELECT 1
      FROM project_living_plan_items item
      WHERE item.id = NEW.living_plan_item_id
        AND item.project_id = NEW.project_id
        AND item.revision = NEW.result_revision
        AND json_extract(NEW.result_json, '\$.id') IS item.id
        AND json_extract(NEW.result_json, '\$.project_id') IS item.project_id
        AND json_extract(
          NEW.result_json, '\$.reference_snapshot_id'
        ) IS item.reference_snapshot_id
        AND json_extract(
          NEW.result_json, '\$.activity_instance_id'
        ) IS item.activity_instance_id
        AND json_extract(
          NEW.result_json, '\$.activity_id'
        ) IS item.activity_id
        AND json_extract(
          NEW.result_json, '\$.activity_name_snapshot'
        ) IS item.activity_name_snapshot
        AND json_extract(
          NEW.result_json, '\$.activity_context_json'
        ) IS item.activity_context_json
        AND json_extract(
          NEW.result_json, '\$.natural_unit_snapshot'
        ) IS item.natural_unit_snapshot
        AND json_extract(
          NEW.result_json, '\$.planned_date'
        ) IS item.planned_date
        AND json_extract(NEW.result_json, '\$.status') IS item.status
        AND json_extract(NEW.result_json, '\$.note') IS item.note
        AND json_extract(
          NEW.result_json, '\$.revision'
        ) IS item.revision
        AND json_extract(
          NEW.result_json, '\$.created_at'
        ) IS item.created_at
        AND json_extract(
          NEW.result_json, '\$.updated_at'
        ) IS item.updated_at
        AND json_extract(
          NEW.result_json, '\$.status_changed_at'
        ) IS item.status_changed_at
    )
    BEGIN
      SELECT RAISE(ABORT, 'living plan receipt result mismatch');
    END
  ''');
  for (final operation in ['update', 'delete']) {
    await transaction.execute('''
      CREATE TRIGGER project_living_plan_command_receipts_append_only_$operation
      BEFORE ${operation.toUpperCase()}
      ON project_living_plan_command_receipts
      BEGIN
        SELECT RAISE(ABORT, 'living plan command receipts are append-only');
      END
    ''');
  }

  await transaction.execute('''
    CREATE TRIGGER project_living_plan_items_guarded_update
    BEFORE UPDATE ON project_living_plan_items
    WHEN NOT (
      NEW.id IS OLD.id
      AND NEW.project_id IS OLD.project_id
      AND NEW.reference_snapshot_id IS OLD.reference_snapshot_id
      AND NEW.activity_instance_id IS OLD.activity_instance_id
      AND NEW.activity_id IS OLD.activity_id
      AND NEW.activity_name_snapshot IS OLD.activity_name_snapshot
      AND NEW.activity_context_json IS OLD.activity_context_json
      AND NEW.natural_unit_snapshot IS OLD.natural_unit_snapshot
      AND NEW.created_at IS OLD.created_at
      AND NEW.revision = OLD.revision + 1
      AND NEW.updated_at >= OLD.updated_at
      AND (
        (
          NEW.status IS OLD.status
          AND NEW.status_changed_at IS OLD.status_changed_at
        ) OR (
          NEW.status IS NOT OLD.status
          AND NEW.status_changed_at IS NEW.updated_at
        )
      )
    )
    BEGIN
      SELECT RAISE(ABORT, 'living plan item update contract violated');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER project_living_plan_items_no_physical_delete
    BEFORE DELETE ON project_living_plan_items
    BEGIN
      SELECT RAISE(ABORT, 'living plan items cannot be deleted');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER project_living_plan_events_revision_match
    BEFORE INSERT ON project_living_plan_events
    WHEN NOT EXISTS (
      SELECT 1
      FROM project_living_plan_items item
      WHERE item.id = NEW.living_plan_item_id
        AND item.project_id = NEW.project_id
        AND item.revision = NEW.sequence
        AND item.updated_at = NEW.occurred_at
    )
    BEGIN
      SELECT RAISE(ABORT, 'living plan event revision mismatch');
    END
  ''');
  for (final operation in ['update', 'delete']) {
    await transaction.execute('''
      CREATE TRIGGER project_living_plan_events_append_only_$operation
      BEFORE ${operation.toUpperCase()} ON project_living_plan_events
      BEGIN
        SELECT RAISE(ABORT, 'living plan events are append-only');
      END
    ''');
  }
}

Future<void> _applyConstructionLivingPlanProgressMigration(
  Transaction transaction,
) async {
  await transaction.execute('''
    ALTER TABLE project_living_plan_items
    ADD COLUMN progress_percent INTEGER CHECK (
      progress_percent IS NULL OR progress_percent BETWEEN 0 AND 100
    )
  ''');
  await transaction.execute(
    'DROP TRIGGER project_living_plan_items_guarded_update',
  );
  await transaction.execute('''
    UPDATE project_living_plan_items
    SET progress_percent = 100
    WHERE status = 'COMPLETED'
  ''');

  await transaction.execute('''
    CREATE TABLE project_living_plan_command_receipts_v16 (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      living_plan_item_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      event_type TEXT NOT NULL CHECK (
        event_type IN (
          'CREATED', 'STARTED', 'COMPLETED',
          'DEFERRED', 'REOPENED', 'NOTE_UPDATED', 'PROGRESS_UPDATED'
        )
      ),
      intent_json TEXT NOT NULL CHECK (
        length(intent_json) > 0
        AND json_valid(intent_json) = 1
        AND json_type(intent_json) = 'object'
      ),
      result_json TEXT NOT NULL CHECK (
        length(result_json) > 0
        AND json_valid(result_json) = 1
        AND json_type(result_json) = 'object'
      ),
      result_revision INTEGER NOT NULL CHECK (result_revision >= 1),
      is_no_op INTEGER NOT NULL CHECK (is_no_op IN (0, 1)),
      event_sequence INTEGER CHECK (
        event_sequence IS NULL OR event_sequence >= 1
      ),
      CHECK (
        (
          is_no_op = 1
          AND event_sequence IS NULL
        ) OR (
          is_no_op = 0
          AND event_sequence = result_revision
        )
      ),
      UNIQUE (
        id,
        living_plan_item_id,
        project_id,
        event_type,
        event_sequence
      ),
      FOREIGN KEY (living_plan_item_id, project_id)
        REFERENCES project_living_plan_items(id, project_id)
    )
  ''');
  await transaction.execute('''
    INSERT INTO project_living_plan_command_receipts_v16 (
      id,
      living_plan_item_id,
      project_id,
      event_type,
      intent_json,
      result_json,
      result_revision,
      is_no_op,
      event_sequence
    )
    SELECT
      id,
      living_plan_item_id,
      project_id,
      event_type,
      intent_json,
      result_json,
      result_revision,
      is_no_op,
      event_sequence
    FROM project_living_plan_command_receipts
  ''');

  await transaction.execute('''
    CREATE TABLE project_living_plan_events_v16 (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      living_plan_item_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      sequence INTEGER NOT NULL CHECK (sequence >= 1),
      event_type TEXT NOT NULL CHECK (
        event_type IN (
          'CREATED', 'STARTED', 'COMPLETED',
          'DEFERRED', 'REOPENED', 'NOTE_UPDATED', 'PROGRESS_UPDATED'
        )
      ),
      occurred_at TEXT NOT NULL CHECK (
        length(occurred_at) = 20
        AND occurred_at GLOB
          '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
        AND strftime('%Y-%m-%dT%H:%M:%SZ', occurred_at, '+0 seconds')
          IS NOT NULL
        AND strftime('%Y-%m-%dT%H:%M:%SZ', occurred_at, '+0 seconds')
          = occurred_at
      ),
      payload_json TEXT NOT NULL CHECK (
        length(payload_json) > 0
        AND json_valid(payload_json) = 1
        AND json_type(payload_json) = 'object'
      ),
      UNIQUE (living_plan_item_id, sequence),
      FOREIGN KEY (living_plan_item_id, project_id)
        REFERENCES project_living_plan_items(id, project_id),
      FOREIGN KEY (
        id,
        living_plan_item_id,
        project_id,
        event_type,
        sequence
      ) REFERENCES project_living_plan_command_receipts_v16(
        id,
        living_plan_item_id,
        project_id,
        event_type,
        event_sequence
      )
    )
  ''');
  await transaction.execute('''
    INSERT INTO project_living_plan_events_v16 (
      id,
      living_plan_item_id,
      project_id,
      sequence,
      event_type,
      occurred_at,
      payload_json
    )
    SELECT
      id,
      living_plan_item_id,
      project_id,
      sequence,
      event_type,
      occurred_at,
      payload_json
    FROM project_living_plan_events
  ''');

  for (final trigger in [
    'project_living_plan_command_receipts_result_match',
    'project_living_plan_command_receipts_append_only_update',
    'project_living_plan_command_receipts_append_only_delete',
    'project_living_plan_events_revision_match',
    'project_living_plan_events_append_only_update',
    'project_living_plan_events_append_only_delete',
  ]) {
    await transaction.execute('DROP TRIGGER $trigger');
  }
  await transaction.execute('DROP TABLE project_living_plan_events');
  await transaction.execute('DROP TABLE project_living_plan_command_receipts');
  await transaction.execute('''
    ALTER TABLE project_living_plan_command_receipts_v16
    RENAME TO project_living_plan_command_receipts
  ''');
  await transaction.execute('''
    ALTER TABLE project_living_plan_events_v16
    RENAME TO project_living_plan_events
  ''');

  await transaction.execute('''
    CREATE INDEX project_living_plan_command_receipts_item
    ON project_living_plan_command_receipts(
      living_plan_item_id, result_revision, id
    )
  ''');
  await transaction.execute('''
    CREATE INDEX project_living_plan_events_history
    ON project_living_plan_events(living_plan_item_id, sequence)
  ''');

  await transaction.execute('''
    CREATE TRIGGER project_living_plan_command_receipts_result_match
    BEFORE INSERT ON project_living_plan_command_receipts
    WHEN NOT EXISTS (
      SELECT 1
      FROM project_living_plan_items item
      WHERE item.id = NEW.living_plan_item_id
        AND item.project_id = NEW.project_id
        AND item.revision = NEW.result_revision
        AND json_extract(NEW.result_json, '\$.id') IS item.id
        AND json_extract(NEW.result_json, '\$.project_id') IS item.project_id
        AND json_extract(
          NEW.result_json, '\$.reference_snapshot_id'
        ) IS item.reference_snapshot_id
        AND json_extract(
          NEW.result_json, '\$.activity_instance_id'
        ) IS item.activity_instance_id
        AND json_extract(
          NEW.result_json, '\$.activity_id'
        ) IS item.activity_id
        AND json_extract(
          NEW.result_json, '\$.activity_name_snapshot'
        ) IS item.activity_name_snapshot
        AND json_extract(
          NEW.result_json, '\$.activity_context_json'
        ) IS item.activity_context_json
        AND json_extract(
          NEW.result_json, '\$.natural_unit_snapshot'
        ) IS item.natural_unit_snapshot
        AND json_extract(
          NEW.result_json, '\$.planned_date'
        ) IS item.planned_date
        AND json_extract(NEW.result_json, '\$.status') IS item.status
        AND json_type(
          NEW.result_json, '\$.progress_percent'
        ) IS NOT NULL
        AND json_extract(
          NEW.result_json, '\$.progress_percent'
        ) IS item.progress_percent
        AND json_extract(NEW.result_json, '\$.note') IS item.note
        AND json_extract(
          NEW.result_json, '\$.revision'
        ) IS item.revision
        AND json_extract(
          NEW.result_json, '\$.created_at'
        ) IS item.created_at
        AND json_extract(
          NEW.result_json, '\$.updated_at'
        ) IS item.updated_at
        AND json_extract(
          NEW.result_json, '\$.status_changed_at'
        ) IS item.status_changed_at
    )
    BEGIN
      SELECT RAISE(ABORT, 'living plan receipt result mismatch');
    END
  ''');
  for (final operation in ['update', 'delete']) {
    await transaction.execute('''
      CREATE TRIGGER project_living_plan_command_receipts_append_only_$operation
      BEFORE ${operation.toUpperCase()}
      ON project_living_plan_command_receipts
      BEGIN
        SELECT RAISE(ABORT, 'living plan command receipts are append-only');
      END
    ''');
  }

  await transaction.execute('''
    CREATE TRIGGER project_living_plan_items_guarded_update
    BEFORE UPDATE ON project_living_plan_items
    WHEN NOT (
      NEW.id IS OLD.id
      AND NEW.project_id IS OLD.project_id
      AND NEW.reference_snapshot_id IS OLD.reference_snapshot_id
      AND NEW.activity_instance_id IS OLD.activity_instance_id
      AND NEW.activity_id IS OLD.activity_id
      AND NEW.activity_name_snapshot IS OLD.activity_name_snapshot
      AND NEW.activity_context_json IS OLD.activity_context_json
      AND NEW.natural_unit_snapshot IS OLD.natural_unit_snapshot
      AND NEW.created_at IS OLD.created_at
      AND NEW.revision = OLD.revision + 1
      AND NEW.updated_at >= OLD.updated_at
      AND (
        (
          NEW.status IS OLD.status
          AND NEW.status_changed_at IS OLD.status_changed_at
        ) OR (
          NEW.status IS NOT OLD.status
          AND NEW.status_changed_at IS NEW.updated_at
        )
      )
    )
    BEGIN
      SELECT RAISE(ABORT, 'living plan item update contract violated');
    END
  ''');
  for (final operation in ['insert', 'update']) {
    await transaction.execute('''
      CREATE TRIGGER project_living_plan_items_progress_consistency_$operation
      BEFORE ${operation.toUpperCase()} ON project_living_plan_items
      WHEN (
        (
          NEW.status = 'COMPLETED'
          AND NEW.progress_percent IS NOT 100
        ) OR (
          NEW.status != 'COMPLETED'
          AND NEW.progress_percent IS 100
        )
      )
      BEGIN
        SELECT RAISE(ABORT, 'living plan progress consistency violated');
      END
    ''');
  }
  await transaction.execute('''
    CREATE TRIGGER project_living_plan_events_revision_match
    BEFORE INSERT ON project_living_plan_events
    WHEN NOT EXISTS (
      SELECT 1
      FROM project_living_plan_items item
      WHERE item.id = NEW.living_plan_item_id
        AND item.project_id = NEW.project_id
        AND item.revision = NEW.sequence
        AND item.updated_at = NEW.occurred_at
    )
    BEGIN
      SELECT RAISE(ABORT, 'living plan event revision mismatch');
    END
  ''');
  for (final operation in ['update', 'delete']) {
    await transaction.execute('''
      CREATE TRIGGER project_living_plan_events_append_only_$operation
      BEFORE ${operation.toUpperCase()} ON project_living_plan_events
      BEGIN
        SELECT RAISE(ABORT, 'living plan events are append-only');
      END
    ''');
  }
}

Future<void> _applyConstructionScheduleSnapshotDependencyMigration(
  Transaction transaction,
) async {
  await transaction.execute('''
    CREATE TABLE project_schedule_snapshot_dependency_manifests (
      snapshot_id TEXT PRIMARY KEY CHECK (
        length(snapshot_id) > 0 AND snapshot_id = trim(snapshot_id)
      ),
      project_id TEXT NOT NULL REFERENCES projects(id),
      dependency_count INTEGER NOT NULL CHECK (dependency_count >= 0),
      projection_sha256 TEXT NOT NULL CHECK (
        length(projection_sha256) = 64
        AND projection_sha256 NOT GLOB '*[^0-9a-f]*'
      ),
      UNIQUE (snapshot_id, project_id),
      FOREIGN KEY (snapshot_id, project_id)
        REFERENCES project_schedule_snapshots(id, project_id)
    )
  ''');
  await transaction.execute('''
    CREATE TABLE project_schedule_snapshot_dependencies (
      snapshot_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      edge_key TEXT NOT NULL CHECK (
        length(edge_key) > 0 AND edge_key = trim(edge_key)
      ),
      template_dependency_id TEXT NOT NULL CHECK (
        length(template_dependency_id) > 0
        AND template_dependency_id = trim(template_dependency_id)
      ),
      predecessor_instance_id TEXT NOT NULL CHECK (
        length(predecessor_instance_id) > 0
        AND predecessor_instance_id = trim(predecessor_instance_id)
      ),
      successor_instance_id TEXT NOT NULL CHECK (
        length(successor_instance_id) > 0
        AND successor_instance_id = trim(successor_instance_id)
      ),
      relationship_type TEXT NOT NULL CHECK (
        relationship_type IN ('FS', 'SS')
      ),
      lag_value INTEGER NOT NULL,
      lag_unit TEXT NOT NULL CHECK (lag_unit = 'WORKING_DAY'),
      scope_rule TEXT NOT NULL CHECK (
        scope_rule IN (
          'ALL_TO_BLOCK',
          'ALL_TO_PROJECT',
          'ANY_ZONE_TO_PROJECT',
          'AUTO',
          'BLOCK_TO_FIRST_BASEMENT',
          'BLOCK_TO_FIRST_FLOOR',
          'BLOCK_TO_FIRST_FLOOR_IF_NO_BASEMENT',
          'FLOOR_THRESHOLD_TO_FACADE',
          'LAST_BASEMENT_TO_FIRST_FLOOR',
          'NEXT_BASEMENT',
          'NEXT_FLOOR',
          'PROJECT',
          'PROJECT_TO_ALL',
          'SAME_BASEMENT',
          'SAME_BLOCK',
          'SAME_FACADE',
          'SAME_FLOOR',
          'SAME_ROOF',
          'SAME_SYSTEM',
          'TOP_FLOOR_TO_ROOF'
        )
      ),
      is_mandatory INTEGER NOT NULL CHECK (is_mandatory IN (0, 1)),
      confidence TEXT NOT NULL CHECK (confidence = 'C_SUPPORTED_INFERENCE'),
      review_status TEXT NOT NULL CHECK (review_status = 'REVIEW_REQUIRED'),
      row_sha256 TEXT NOT NULL CHECK (
        length(row_sha256) = 64
        AND row_sha256 NOT GLOB '*[^0-9a-f]*'
      ),
      PRIMARY KEY (snapshot_id, edge_key),
      FOREIGN KEY (snapshot_id, project_id)
        REFERENCES project_schedule_snapshot_dependency_manifests(
          snapshot_id, project_id
        ),
      FOREIGN KEY (snapshot_id, predecessor_instance_id)
        REFERENCES project_schedule_snapshot_activities(snapshot_id, instance_id),
      FOREIGN KEY (snapshot_id, successor_instance_id)
        REFERENCES project_schedule_snapshot_activities(snapshot_id, instance_id),
      CHECK (predecessor_instance_id != successor_instance_id)
    )
  ''');

  await transaction.execute('''
    CREATE INDEX project_schedule_snapshot_dependency_manifests_project
    ON project_schedule_snapshot_dependency_manifests(project_id, snapshot_id)
  ''');
  await transaction.execute('''
    CREATE INDEX project_schedule_snapshot_dependencies_predecessor
    ON project_schedule_snapshot_dependencies(
      snapshot_id, predecessor_instance_id, edge_key
    )
  ''');
  await transaction.execute('''
    CREATE INDEX project_schedule_snapshot_dependencies_successor
    ON project_schedule_snapshot_dependencies(
      snapshot_id, successor_instance_id, edge_key
    )
  ''');

  for (final table in [
    'project_schedule_snapshot_dependency_manifests',
    'project_schedule_snapshot_dependencies',
  ]) {
    await transaction.execute('''
      CREATE TRIGGER ${table}_immutable_update
      BEFORE UPDATE ON $table
      BEGIN
        SELECT RAISE(ABORT, 'schedule snapshot dependency graph is immutable');
      END
    ''');
    await transaction.execute('''
      CREATE TRIGGER ${table}_immutable_delete
      BEFORE DELETE ON $table
      BEGIN
        SELECT RAISE(ABORT, 'schedule snapshot dependency graph is immutable');
      END
    ''');
  }
}

Future<void> _applyMaterialRequestMigration(Transaction transaction) async {
  await transaction.execute('''
    CREATE TABLE material_requests (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      project_id TEXT NOT NULL REFERENCES projects(id),
      location_id TEXT,
      living_plan_item_id TEXT,
      material_name TEXT NOT NULL CHECK (
        length(material_name) > 0 AND material_name = trim(material_name)
      ),
      quantity REAL CHECK (
        quantity IS NULL OR (
          quantity > 0 AND quantity <= 1.7976931348623157e308
        )
      ),
      unit TEXT CHECK (
        unit IS NULL OR (length(unit) > 0 AND unit = trim(unit))
      ),
      needed_on TEXT CHECK (
        needed_on IS NULL OR (
          length(needed_on) = 10
          AND needed_on GLOB
            '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
          AND date(needed_on) = needed_on
        )
      ),
      priority TEXT NOT NULL CHECK (
        priority IN ('normal', 'high', 'urgent')
      ),
      description TEXT CHECK (
        description IS NULL OR (
          length(description) > 0 AND description = trim(description)
        )
      ),
      status TEXT NOT NULL CHECK (
        status IN ('needed', 'requested', 'received', 'cancelled')
      ),
      revision INTEGER NOT NULL CHECK (revision >= 1),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      status_changed_at TEXT NOT NULL,
      requested_at TEXT,
      received_at TEXT,
      cancelled_at TEXT,
      UNIQUE (id, project_id),
      FOREIGN KEY (location_id, project_id)
        REFERENCES project_locations(id, project_id),
      FOREIGN KEY (living_plan_item_id, project_id)
        REFERENCES project_living_plan_items(id, project_id),
      CHECK (
        (quantity IS NULL AND unit IS NULL)
        OR (quantity IS NOT NULL AND unit IS NOT NULL)
      ),
      CHECK (
        updated_at >= created_at
        AND status_changed_at >= created_at
        AND status_changed_at <= updated_at
      ),
      CHECK (
        status != 'needed'
        OR (
          requested_at IS NULL
          AND received_at IS NULL
          AND cancelled_at IS NULL
        )
      ),
      CHECK (
        status != 'requested'
        OR (
          requested_at IS NOT NULL
          AND requested_at = status_changed_at
          AND received_at IS NULL
          AND cancelled_at IS NULL
        )
      ),
      CHECK (
        status != 'received'
        OR (
          requested_at IS NOT NULL
          AND received_at IS NOT NULL
          AND received_at = status_changed_at
          AND cancelled_at IS NULL
        )
      ),
      CHECK (
        status != 'cancelled'
        OR (
          received_at IS NULL
          AND cancelled_at IS NOT NULL
          AND cancelled_at = status_changed_at
        )
      )
    )
  ''');
  await transaction.execute('''
    CREATE TABLE material_request_events (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      material_request_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      sequence INTEGER NOT NULL CHECK (sequence >= 1),
      event_type TEXT NOT NULL CHECK (
        event_type IN (
          'material_request.created',
          'material_request.updated',
          'material_request.requested',
          'material_request.received',
          'material_request.cancelled',
          'material_request.reopened'
        )
      ),
      occurred_at TEXT NOT NULL,
      payload_json TEXT NOT NULL CHECK (
        json_valid(payload_json)
        AND json_type(payload_json) = 'object'
      ),
      UNIQUE (material_request_id, sequence),
      FOREIGN KEY (material_request_id, project_id)
        REFERENCES material_requests(id, project_id)
    )
  ''');

  for (final columnName in [
    'created_at',
    'updated_at',
    'status_changed_at',
    'requested_at',
    'received_at',
    'cancelled_at',
  ]) {
    await transaction.execute('''
      CREATE TRIGGER material_requests_${columnName}_canonical_insert
      BEFORE INSERT ON material_requests
      WHEN NEW.$columnName IS NOT NULL AND (
        length(NEW.$columnName) != 20
        OR NEW.$columnName NOT GLOB
          '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
        OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.$columnName, '+0 seconds')
          IS NULL
        OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.$columnName, '+0 seconds')
          != NEW.$columnName
      )
      BEGIN
        SELECT RAISE(ABORT, 'material request timestamp must be canonical UTC');
      END
    ''');
    await transaction.execute('''
      CREATE TRIGGER material_requests_${columnName}_canonical_update
      BEFORE UPDATE OF $columnName ON material_requests
      WHEN NEW.$columnName IS NOT NULL AND (
        length(NEW.$columnName) != 20
        OR NEW.$columnName NOT GLOB
          '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
        OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.$columnName, '+0 seconds')
          IS NULL
        OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.$columnName, '+0 seconds')
          != NEW.$columnName
      )
      BEGIN
        SELECT RAISE(ABORT, 'material request timestamp must be canonical UTC');
      END
    ''');
  }
  await transaction.execute('''
    CREATE TRIGGER material_request_events_timestamp_canonical
    BEFORE INSERT ON material_request_events
    WHEN length(NEW.occurred_at) != 20
      OR NEW.occurred_at NOT GLOB
        '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
      OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.occurred_at, '+0 seconds')
        IS NULL
      OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.occurred_at, '+0 seconds')
        != NEW.occurred_at
    BEGIN
      SELECT RAISE(ABORT, 'material request event timestamp must be canonical UTC');
    END
  ''');

  await transaction.execute('''
    CREATE INDEX material_requests_project_open
    ON material_requests(project_id, status, priority, needed_on, id)
  ''');
  await transaction.execute('''
    CREATE INDEX material_requests_project_history
    ON material_requests(project_id, status_changed_at DESC, id)
  ''');
  await transaction.execute('''
    CREATE INDEX material_requests_location
    ON material_requests(project_id, location_id, status)
  ''');
  await transaction.execute('''
    CREATE INDEX material_requests_living_plan_item
    ON material_requests(project_id, living_plan_item_id, status)
  ''');
  await transaction.execute('''
    CREATE INDEX material_request_events_history
    ON material_request_events(material_request_id, sequence)
  ''');

  await transaction.execute('''
    CREATE TRIGGER material_requests_no_delete
    BEFORE DELETE ON material_requests
    BEGIN
      SELECT RAISE(ABORT, 'material requests cannot be deleted');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER material_requests_guarded_update
    BEFORE UPDATE ON material_requests
    BEGIN
      SELECT CASE
        WHEN NEW.id != OLD.id
          OR NEW.project_id != OLD.project_id
          OR NEW.created_at != OLD.created_at
        THEN RAISE(ABORT, 'material request identity is immutable')
      END;
      SELECT CASE
        WHEN NEW.revision != OLD.revision + 1
        THEN RAISE(ABORT, 'material request revision mismatch')
      END;
      SELECT CASE
        WHEN NEW.updated_at < OLD.updated_at
          OR NEW.status_changed_at < OLD.status_changed_at
        THEN RAISE(ABORT, 'material request timestamp regression')
      END;
      SELECT CASE
        WHEN NEW.status = OLD.status
          AND NEW.status_changed_at != OLD.status_changed_at
        THEN RAISE(ABORT, 'material request status timestamp mismatch')
      END;
      SELECT CASE
        WHEN NEW.status != OLD.status
          AND NEW.status_changed_at != NEW.updated_at
        THEN RAISE(ABORT, 'material request status timestamp mismatch')
      END;
      SELECT CASE
        WHEN NEW.status != OLD.status
          AND NOT (
            (OLD.status = 'needed'
              AND NEW.status IN ('requested', 'cancelled'))
            OR (OLD.status = 'requested'
              AND NEW.status IN ('received', 'cancelled'))
            OR (OLD.status IN ('received', 'cancelled')
              AND NEW.status = 'needed')
          )
        THEN RAISE(ABORT, 'material request transition not allowed')
      END;
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER material_request_events_revision_match
    BEFORE INSERT ON material_request_events
    BEGIN
      SELECT CASE
        WHEN NEW.sequence != (
          SELECT revision
          FROM material_requests
          WHERE id = NEW.material_request_id
            AND project_id = NEW.project_id
        )
        THEN RAISE(ABORT, 'material request event revision mismatch')
      END;
    END
  ''');
  for (final operation in ['update', 'delete']) {
    await transaction.execute('''
      CREATE TRIGGER material_request_events_append_only_$operation
      BEFORE ${operation.toUpperCase()} ON material_request_events
      BEGIN
        SELECT RAISE(ABORT, 'material request events are append-only');
      END
    ''');
  }
}

Future<void> _applyAgendaPhoneCallMigration(Transaction transaction) async {
  await transaction.execute('''
    CREATE TABLE agenda_phone_call_contexts (
      agenda_log_id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL,
      party_kind TEXT NOT NULL CHECK (
        party_kind IN ('person', 'company', 'free_text')
      ),
      workforce_member_id TEXT,
      subcontractor_id TEXT,
      party_display_text TEXT NOT NULL CHECK (
        length(trim(party_display_text)) > 0
        AND party_display_text = trim(party_display_text)
      ),
      created_at TEXT NOT NULL,
      FOREIGN KEY (agenda_log_id, project_id)
        REFERENCES field_observations(id, project_id),
      FOREIGN KEY (workforce_member_id, project_id)
        REFERENCES workforce_members(id, project_id),
      FOREIGN KEY (subcontractor_id, project_id)
        REFERENCES subcontractors(id, project_id),
      CHECK (
        (
          party_kind = 'person'
          AND workforce_member_id IS NOT NULL
          AND subcontractor_id IS NULL
        )
        OR (
          party_kind = 'company'
          AND workforce_member_id IS NULL
          AND subcontractor_id IS NOT NULL
        )
        OR (
          party_kind = 'free_text'
          AND workforce_member_id IS NULL
          AND subcontractor_id IS NULL
        )
      )
    )
  ''');
  await transaction.execute('''
    CREATE INDEX ix_agenda_phone_call_contexts_project
    ON agenda_phone_call_contexts(project_id, created_at DESC, agenda_log_id)
  ''');
  await transaction.execute('''
    CREATE INDEX ix_agenda_phone_call_contexts_workforce
    ON agenda_phone_call_contexts(
      project_id, workforce_member_id, created_at DESC
    )
    WHERE workforce_member_id IS NOT NULL
  ''');
  await transaction.execute('''
    CREATE INDEX ix_agenda_phone_call_contexts_subcontractor
    ON agenda_phone_call_contexts(
      project_id, subcontractor_id, created_at DESC
    )
    WHERE subcontractor_id IS NOT NULL
  ''');
  await transaction.execute('''
    CREATE TRIGGER agenda_phone_call_contexts_source_insert
    BEFORE INSERT ON agenda_phone_call_contexts
    WHEN NOT EXISTS (
      SELECT 1
      FROM field_observations observation
      WHERE observation.id = NEW.agenda_log_id
        AND observation.project_id = NEW.project_id
        AND observation.category = 'meeting_decision'
    )
    BEGIN
      SELECT RAISE(
        ABORT,
        'phone call context requires meeting decision agenda source'
      );
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER agenda_phone_call_contexts_source_category_update
    BEFORE UPDATE OF category ON field_observations
    WHEN NEW.category != 'meeting_decision'
      AND EXISTS (
        SELECT 1
        FROM agenda_phone_call_contexts context
        WHERE context.agenda_log_id = OLD.id
          AND context.project_id = OLD.project_id
      )
    BEGIN
      SELECT RAISE(
        ABORT,
        'phone call agenda category must remain meeting decision'
      );
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER agenda_phone_call_contexts_timestamp_insert
    BEFORE INSERT ON agenda_phone_call_contexts
    WHEN length(NEW.created_at) != 20
      OR NEW.created_at NOT GLOB
        '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
      OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.created_at, '+0 seconds')
        IS NULL
      OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.created_at, '+0 seconds')
        != NEW.created_at
    BEGIN
      SELECT RAISE(
        ABORT,
        'phone call context timestamp must be canonical UTC'
      );
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER agenda_phone_call_contexts_immutable_update
    BEFORE UPDATE ON agenda_phone_call_contexts
    BEGIN
      SELECT RAISE(ABORT, 'phone call context is immutable');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER agenda_phone_call_contexts_immutable_delete
    BEFORE DELETE ON agenda_phone_call_contexts
    BEGIN
      SELECT RAISE(ABORT, 'phone call context cannot be deleted');
    END
  ''');
}

Future<void> _applyInventoryFoundationMigration(Transaction transaction) async {
  await transaction.execute('''
    CREATE TABLE inventory_sketches (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      project_id TEXT NOT NULL REFERENCES projects(id),
      display_name TEXT NOT NULL CHECK (
        length(display_name) BETWEEN 1 AND 80
        AND display_name = trim(display_name)
      ),
      is_primary INTEGER NOT NULL CHECK (is_primary IN (0, 1)),
      active_revision_id TEXT,
      draft_revision_id TEXT,
      revision INTEGER NOT NULL CHECK (revision >= 1),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      archived_at TEXT,
      UNIQUE (id, project_id),
      FOREIGN KEY (active_revision_id, project_id, id)
        REFERENCES inventory_sketch_revisions(id, project_id, sketch_id)
        DEFERRABLE INITIALLY DEFERRED,
      FOREIGN KEY (draft_revision_id, project_id, id)
        REFERENCES inventory_sketch_revisions(id, project_id, sketch_id)
        DEFERRABLE INITIALLY DEFERRED,
      CHECK (
        active_revision_id IS NULL
        OR draft_revision_id IS NULL
        OR active_revision_id != draft_revision_id
      ),
      CHECK (updated_at >= created_at),
      CHECK (archived_at IS NULL OR archived_at = updated_at),
      CHECK (archived_at IS NULL OR is_primary = 0)
    )
  ''');
  await transaction.execute('''
    CREATE TABLE inventory_sketch_revisions (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      sketch_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      revision_number INTEGER NOT NULL CHECK (revision_number >= 1),
      base_revision_id TEXT,
      state TEXT NOT NULL CHECK (
        state IN ('DRAFT', 'ACTIVE', 'SUPERSEDED', 'ABANDONED')
      ),
      geometry_version INTEGER NOT NULL CHECK (geometry_version = 1),
      canvas_width INTEGER NOT NULL CHECK (canvas_width = 4096),
      canvas_height INTEGER NOT NULL CHECK (canvas_height = 3072),
      geometry_json TEXT NOT NULL CHECK (
        length(geometry_json) > 0
        AND json_valid(geometry_json)
        AND json_type(geometry_json) = 'object'
      ),
      geometry_sha256 TEXT NOT NULL CHECK (
        length(geometry_sha256) = 64
        AND geometry_sha256 = lower(geometry_sha256)
        AND geometry_sha256 NOT GLOB '*[^0-9a-f]*'
      ),
      content_revision INTEGER NOT NULL CHECK (content_revision >= 1),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      finalized_at TEXT,
      superseded_at TEXT,
      abandoned_at TEXT,
      UNIQUE (id, project_id, sketch_id),
      UNIQUE (sketch_id, revision_number),
      FOREIGN KEY (sketch_id, project_id)
        REFERENCES inventory_sketches(id, project_id)
        DEFERRABLE INITIALLY DEFERRED,
      FOREIGN KEY (base_revision_id, project_id, sketch_id)
        REFERENCES inventory_sketch_revisions(id, project_id, sketch_id)
        DEFERRABLE INITIALLY DEFERRED,
      CHECK (base_revision_id IS NULL OR base_revision_id != id),
      CHECK (updated_at >= created_at),
      CHECK (
        (
          state = 'DRAFT'
          AND finalized_at IS NULL
          AND superseded_at IS NULL
          AND abandoned_at IS NULL
        )
        OR (
          state = 'ACTIVE'
          AND finalized_at = updated_at
          AND superseded_at IS NULL
          AND abandoned_at IS NULL
        )
        OR (
          state = 'SUPERSEDED'
          AND finalized_at IS NOT NULL
          AND superseded_at = updated_at
          AND superseded_at >= finalized_at
          AND abandoned_at IS NULL
        )
        OR (
          state = 'ABANDONED'
          AND finalized_at IS NULL
          AND superseded_at IS NULL
          AND abandoned_at = updated_at
        )
      )
    )
  ''');
  await transaction.execute('''
    CREATE TABLE inventory_assets (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      project_id TEXT NOT NULL REFERENCES projects(id),
      display_name TEXT NOT NULL CHECK (
        length(display_name) BETWEEN 1 AND 120
        AND display_name = trim(display_name)
      ),
      normalized_name TEXT NOT NULL CHECK (
        length(normalized_name) BETWEEN 1 AND 120
        AND normalized_name = trim(normalized_name)
      ),
      category_code TEXT NOT NULL CHECK (
        category_code IN (
          'EQUIPMENT', 'POWER_TOOL', 'HAND_TOOL', 'MEASUREMENT_DEVICE',
          'SAFETY_EQUIPMENT', 'TEMPORARY_WORKS', 'SITE_FACILITY', 'OTHER'
        )
      ),
      other_category_label TEXT CHECK (
        other_category_label IS NULL OR (
          length(other_category_label) BETWEEN 1 AND 80
          AND other_category_label = trim(other_category_label)
        )
      ),
      total_quantity INTEGER NOT NULL CHECK (
        total_quantity BETWEEN 1 AND 1000000
      ),
      status TEXT NOT NULL CHECK (
        status IN ('AVAILABLE', 'IN_USE', 'OUT_OF_SERVICE', 'MISSING')
      ),
      note TEXT CHECK (
        note IS NULL OR (
          length(note) BETWEEN 1 AND 1000
          AND note = trim(note)
        )
      ),
      revision INTEGER NOT NULL CHECK (revision >= 1),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      status_changed_at TEXT NOT NULL,
      archived_at TEXT,
      UNIQUE (id, project_id),
      CHECK (
        (category_code = 'OTHER' AND other_category_label IS NOT NULL)
        OR (category_code != 'OTHER' AND other_category_label IS NULL)
      ),
      CHECK (
        updated_at >= created_at
        AND status_changed_at >= created_at
        AND status_changed_at <= updated_at
      ),
      CHECK (archived_at IS NULL OR archived_at = updated_at)
    )
  ''');
  await transaction.execute('''
    CREATE TABLE inventory_asset_placements (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      placement_key TEXT NOT NULL CHECK (
        length(placement_key) > 0 AND placement_key = trim(placement_key)
      ),
      project_id TEXT NOT NULL,
      asset_id TEXT NOT NULL,
      sketch_id TEXT NOT NULL,
      provenance_revision_id TEXT NOT NULL,
      sequence INTEGER NOT NULL CHECK (sequence >= 1),
      x INTEGER NOT NULL CHECK (x BETWEEN 0 AND 4096 AND x % 4 = 0),
      y INTEGER NOT NULL CHECK (y BETWEEN 0 AND 3072 AND y % 4 = 0),
      quantity INTEGER NOT NULL CHECK (quantity BETWEEN 1 AND 1000000),
      created_at TEXT NOT NULL,
      ended_at TEXT,
      end_reason TEXT CHECK (
        end_reason IS NULL
        OR end_reason IN ('MOVED', 'QUANTITY_CHANGED', 'ASSET_ARCHIVED')
      ),
      supersedes_placement_id TEXT UNIQUE,
      UNIQUE (id, project_id),
      UNIQUE (placement_key, sequence),
      FOREIGN KEY (asset_id, project_id)
        REFERENCES inventory_assets(id, project_id)
        DEFERRABLE INITIALLY DEFERRED,
      FOREIGN KEY (sketch_id, project_id)
        REFERENCES inventory_sketches(id, project_id)
        DEFERRABLE INITIALLY DEFERRED,
      FOREIGN KEY (provenance_revision_id, project_id, sketch_id)
        REFERENCES inventory_sketch_revisions(id, project_id, sketch_id)
        DEFERRABLE INITIALLY DEFERRED,
      FOREIGN KEY (supersedes_placement_id, project_id)
        REFERENCES inventory_asset_placements(id, project_id)
        DEFERRABLE INITIALLY DEFERRED,
      CHECK (
        (ended_at IS NULL AND end_reason IS NULL)
        OR (
          ended_at IS NOT NULL
          AND end_reason IS NOT NULL
          AND ended_at >= created_at
        )
      ),
      CHECK (supersedes_placement_id IS NULL OR supersedes_placement_id != id)
    )
  ''');
  await transaction.execute('''
    CREATE TABLE inventory_command_receipts (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      project_id TEXT NOT NULL REFERENCES projects(id),
      command_type TEXT NOT NULL CHECK (
        command_type IN (
          'sketch_create',
          'sketch_draft_autosave',
          'sketch_edit_start',
          'sketch_finalize',
          'sketch_draft_abandon',
          'sketch_archive',
          'sketch_unarchive',
          'asset_create_with_placement',
          'asset_update',
          'asset_status_change',
          'asset_quantity_change',
          'asset_archive',
          'asset_unarchive_with_placement',
          'placement_move',
          'photo_link',
          'photo_archive',
          'photo_restore'
        )
      ),
      primary_aggregate_type TEXT NOT NULL CHECK (
        primary_aggregate_type IN (
          'sketch', 'asset', 'placement', 'attachment_link'
        )
      ),
      primary_aggregate_id TEXT NOT NULL CHECK (
        length(primary_aggregate_id) > 0
        AND primary_aggregate_id = trim(primary_aggregate_id)
      ),
      intent_sha256 TEXT NOT NULL CHECK (
        length(intent_sha256) = 64
        AND intent_sha256 = lower(intent_sha256)
        AND intent_sha256 NOT GLOB '*[^0-9a-f]*'
      ),
      result_json TEXT NOT NULL CHECK (
        length(result_json) > 0
        AND json_valid(result_json)
        AND json_type(result_json) = 'object'
      ),
      result_sha256 TEXT NOT NULL CHECK (
        length(result_sha256) = 64
        AND result_sha256 = lower(result_sha256)
        AND result_sha256 NOT GLOB '*[^0-9a-f]*'
      ),
      is_no_op INTEGER NOT NULL CHECK (is_no_op IN (0, 1)),
      event_count INTEGER NOT NULL CHECK (event_count >= 0),
      created_at TEXT NOT NULL,
      UNIQUE (id, project_id),
      CHECK (
        (is_no_op = 1 AND event_count = 0)
        OR (is_no_op = 0 AND event_count >= 1)
      )
    )
  ''');
  await transaction.execute('''
    CREATE TABLE inventory_events (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      operation_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      aggregate_type TEXT NOT NULL CHECK (
        aggregate_type IN ('sketch', 'asset', 'placement', 'attachment_link')
      ),
      aggregate_id TEXT NOT NULL CHECK (
        length(aggregate_id) > 0 AND aggregate_id = trim(aggregate_id)
      ),
      sequence INTEGER NOT NULL CHECK (sequence >= 1),
      event_type TEXT NOT NULL CHECK (
        event_type IN (
          'inventory.sketch_created',
          'inventory.sketch_draft_autosaved',
          'inventory.sketch_edit_started',
          'inventory.sketch_finalized',
          'inventory.sketch_draft_abandoned',
          'inventory.sketch_archived',
          'inventory.sketch_unarchived',
          'inventory.asset_created',
          'inventory.asset_updated',
          'inventory.asset_status_changed',
          'inventory.asset_archived',
          'inventory.asset_unarchived',
          'inventory.placement_created',
          'inventory.placement_moved',
          'inventory.placement_quantity_changed',
          'inventory.placement_retired',
          'inventory.photo_linked',
          'inventory.photo_archived',
          'inventory.photo_restored'
        )
      ),
      occurred_at TEXT NOT NULL,
      payload_json TEXT NOT NULL CHECK (
        length(payload_json) > 0
        AND json_valid(payload_json)
        AND json_type(payload_json) = 'object'
      ),
      payload_sha256 TEXT NOT NULL CHECK (
        length(payload_sha256) = 64
        AND payload_sha256 = lower(payload_sha256)
        AND payload_sha256 NOT GLOB '*[^0-9a-f]*'
      ),
      UNIQUE (aggregate_type, aggregate_id, sequence),
      UNIQUE (operation_id, aggregate_type, aggregate_id),
      FOREIGN KEY (operation_id, project_id)
        REFERENCES inventory_command_receipts(id, project_id)
        DEFERRABLE INITIALLY DEFERRED,
      CHECK (
        (aggregate_type = 'sketch'
          AND event_type LIKE 'inventory.sketch_%')
        OR (aggregate_type = 'asset'
          AND event_type LIKE 'inventory.asset_%')
        OR (aggregate_type = 'placement'
          AND event_type LIKE 'inventory.placement_%')
        OR (aggregate_type = 'attachment_link'
          AND event_type LIKE 'inventory.photo_%')
      )
    )
  ''');
  await transaction.execute('''
    CREATE TABLE inventory_asset_attachment_links (
      id TEXT PRIMARY KEY CHECK (length(id) > 0 AND id = trim(id)),
      attachment_id TEXT NOT NULL REFERENCES managed_attachments(id),
      asset_id TEXT NOT NULL,
      project_id TEXT NOT NULL,
      role TEXT NOT NULL CHECK (role = 'inventory_photo'),
      original_file_name TEXT NOT NULL CHECK (
        length(original_file_name) BETWEEN 1 AND 255
        AND original_file_name = trim(original_file_name)
      ),
      description TEXT CHECK (
        description IS NULL OR (
          length(description) BETWEEN 1 AND 1000
          AND description = trim(description)
        )
      ),
      revision INTEGER NOT NULL CHECK (revision >= 1),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      archived_at TEXT,
      UNIQUE (id, project_id),
      FOREIGN KEY (asset_id, project_id)
        REFERENCES inventory_assets(id, project_id)
        DEFERRABLE INITIALLY DEFERRED,
      CHECK (updated_at >= created_at),
      CHECK (archived_at IS NULL OR archived_at = updated_at)
    )
  ''');

  await transaction.execute('''
    CREATE UNIQUE INDEX uq_inventory_sketches_primary
    ON inventory_sketches(project_id)
    WHERE is_primary = 1 AND archived_at IS NULL
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_sketches_project
    ON inventory_sketches(project_id, archived_at, is_primary, id)
  ''');
  await transaction.execute('''
    CREATE UNIQUE INDEX uq_inventory_sketch_revisions_draft
    ON inventory_sketch_revisions(sketch_id)
    WHERE state = 'DRAFT'
  ''');
  await transaction.execute('''
    CREATE UNIQUE INDEX uq_inventory_sketch_revisions_active
    ON inventory_sketch_revisions(sketch_id)
    WHERE state = 'ACTIVE'
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_sketch_revisions_history
    ON inventory_sketch_revisions(
      project_id, sketch_id, revision_number DESC, id
    )
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_assets_project_name
    ON inventory_assets(project_id, normalized_name, id)
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_assets_project_filter
    ON inventory_assets(project_id, archived_at, category_code, status, id)
  ''');
  await transaction.execute('''
    CREATE UNIQUE INDEX uq_inventory_asset_placements_active_key
    ON inventory_asset_placements(placement_key)
    WHERE ended_at IS NULL
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_asset_placements_map
    ON inventory_asset_placements(project_id, sketch_id, ended_at, y, x, id)
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_asset_placements_asset
    ON inventory_asset_placements(project_id, asset_id, ended_at, id)
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_command_receipts_aggregate
    ON inventory_command_receipts(
      project_id, primary_aggregate_type, primary_aggregate_id, created_at, id
    )
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_events_history
    ON inventory_events(aggregate_type, aggregate_id, sequence, id)
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_events_operation
    ON inventory_events(operation_id, project_id, id)
  ''');
  await transaction.execute('''
    CREATE UNIQUE INDEX uq_inventory_asset_attachment_links_active
    ON inventory_asset_attachment_links(attachment_id, asset_id, role)
    WHERE archived_at IS NULL
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_asset_attachment_links_asset
    ON inventory_asset_attachment_links(
      project_id, asset_id, archived_at, created_at, id
    )
  ''');
  await transaction.execute('''
    CREATE INDEX ix_inventory_asset_attachment_links_attachment
    ON inventory_asset_attachment_links(
      attachment_id, archived_at, created_at, id
    )
  ''');

  await _addInventoryTimestampGuards(transaction, 'inventory_sketches', const [
    'created_at',
    'updated_at',
    'archived_at',
  ]);
  await _addInventoryTimestampGuards(
    transaction,
    'inventory_sketch_revisions',
    const [
      'created_at',
      'updated_at',
      'finalized_at',
      'superseded_at',
      'abandoned_at',
    ],
  );
  await _addInventoryTimestampGuards(transaction, 'inventory_assets', const [
    'created_at',
    'updated_at',
    'status_changed_at',
    'archived_at',
  ]);
  await _addInventoryTimestampGuards(
    transaction,
    'inventory_asset_placements',
    const ['created_at', 'ended_at'],
  );
  await _addInventoryTimestampGuards(
    transaction,
    'inventory_command_receipts',
    const ['created_at'],
  );
  await _addInventoryTimestampGuards(transaction, 'inventory_events', const [
    'occurred_at',
  ]);
  await _addInventoryTimestampGuards(
    transaction,
    'inventory_asset_attachment_links',
    const ['created_at', 'updated_at', 'archived_at'],
  );

  await _addInventoryInvariantTriggers(transaction);
}

Future<void> _addInventoryTimestampGuards(
  Transaction transaction,
  String table,
  List<String> columns,
) async {
  for (final column in columns) {
    for (final operation in ['insert', 'update']) {
      final action = operation == 'insert' ? 'INSERT' : 'UPDATE OF $column';
      await transaction.execute('''
        CREATE TRIGGER ${table}_${column}_canonical_$operation
        BEFORE $action ON $table
        WHEN NEW.$column IS NOT NULL AND (
          length(NEW.$column) != 20
          OR NEW.$column NOT GLOB
            '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z'
          OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.$column, '+0 seconds')
            IS NULL
          OR strftime('%Y-%m-%dT%H:%M:%SZ', NEW.$column, '+0 seconds')
            != NEW.$column
        )
        BEGIN
          SELECT RAISE(ABORT, 'inventory timestamp must be canonical UTC');
        END
      ''');
    }
  }
}

Future<void> _addInventoryInvariantTriggers(Transaction transaction) async {
  for (final table in const [
    'inventory_sketches',
    'inventory_sketch_revisions',
    'inventory_assets',
    'inventory_asset_placements',
    'inventory_command_receipts',
    'inventory_events',
    'inventory_asset_attachment_links',
  ]) {
    await transaction.execute('''
      CREATE TRIGGER ${table}_project_available_insert
      BEFORE INSERT ON $table
      WHEN NOT EXISTS (
        SELECT 1
        FROM projects project
        WHERE project.id = NEW.project_id
          AND project.archived_at IS NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'inventory project is unavailable');
      END
    ''');
  }
  for (final table in const [
    'inventory_sketches',
    'inventory_sketch_revisions',
    'inventory_assets',
    'inventory_asset_placements',
    'inventory_asset_attachment_links',
  ]) {
    await transaction.execute('''
      CREATE TRIGGER ${table}_project_available_update
      BEFORE UPDATE ON $table
      WHEN NOT EXISTS (
        SELECT 1
        FROM projects project
        WHERE project.id = NEW.project_id
          AND project.archived_at IS NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'inventory project is unavailable');
      END
    ''');
  }

  for (final operation in ['insert', 'update']) {
    final action = operation == 'insert'
        ? 'INSERT'
        : 'UPDATE OF active_revision_id, draft_revision_id, project_id';
    await transaction.execute('''
      CREATE TRIGGER inventory_sketches_pointer_state_$operation
      BEFORE $action ON inventory_sketches
      BEGIN
        SELECT CASE
          WHEN NEW.active_revision_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM inventory_sketch_revisions revision
              WHERE revision.id = NEW.active_revision_id
                AND revision.project_id = NEW.project_id
                AND revision.sketch_id = NEW.id
                AND revision.state = 'ACTIVE'
            )
          THEN RAISE(ABORT, 'inventory active revision pointer is invalid')
        END;
        SELECT CASE
          WHEN NEW.draft_revision_id IS NOT NULL
            AND NOT EXISTS (
              SELECT 1
              FROM inventory_sketch_revisions revision
              WHERE revision.id = NEW.draft_revision_id
                AND revision.project_id = NEW.project_id
                AND revision.sketch_id = NEW.id
                AND revision.state = 'DRAFT'
            )
          THEN RAISE(ABORT, 'inventory draft revision pointer is invalid')
        END;
      END
    ''');
  }
  await transaction.execute('''
    CREATE TRIGGER inventory_sketches_guarded_update
    BEFORE UPDATE ON inventory_sketches
    BEGIN
      SELECT CASE
        WHEN NEW.id != OLD.id
          OR NEW.project_id != OLD.project_id
          OR NEW.created_at != OLD.created_at
        THEN RAISE(ABORT, 'inventory sketch identity is immutable')
      END;
      SELECT CASE
        WHEN NEW.revision != OLD.revision + 1
        THEN RAISE(ABORT, 'inventory sketch revision mismatch')
      END;
      SELECT CASE
        WHEN NEW.updated_at < OLD.updated_at
        THEN RAISE(ABORT, 'inventory sketch timestamp regression')
      END;
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_sketches_archive_without_placements
    BEFORE UPDATE OF archived_at ON inventory_sketches
    WHEN OLD.archived_at IS NULL
      AND NEW.archived_at IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM inventory_asset_placements placement
        WHERE placement.project_id = OLD.project_id
          AND placement.sketch_id = OLD.id
          AND placement.ended_at IS NULL
      )
    BEGIN
      SELECT RAISE(ABORT, 'inventory sketch has active placements');
    END
  ''');

  await transaction.execute('''
    CREATE TRIGGER inventory_sketch_revisions_insert_state
    BEFORE INSERT ON inventory_sketch_revisions
    BEGIN
      SELECT CASE
        WHEN NEW.state != 'DRAFT'
        THEN RAISE(ABORT, 'inventory revision must start as draft')
      END;
      SELECT CASE
        WHEN NEW.revision_number != (
          SELECT COALESCE(MAX(existing.revision_number), 0) + 1
          FROM inventory_sketch_revisions existing
          WHERE existing.sketch_id = NEW.sketch_id
        )
        THEN RAISE(ABORT, 'inventory revision number is not contiguous')
      END;
      SELECT CASE
        WHEN NEW.base_revision_id IS NOT NULL
          AND NOT EXISTS (
            SELECT 1
            FROM inventory_sketch_revisions base
            WHERE base.id = NEW.base_revision_id
              AND base.project_id = NEW.project_id
              AND base.sketch_id = NEW.sketch_id
              AND base.revision_number < NEW.revision_number
              AND base.state IN ('ACTIVE', 'SUPERSEDED')
          )
        THEN RAISE(ABORT, 'inventory base revision is invalid')
      END;
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_sketch_revisions_guarded_update
    BEFORE UPDATE ON inventory_sketch_revisions
    BEGIN
      SELECT CASE
        WHEN NEW.id != OLD.id
          OR NEW.sketch_id != OLD.sketch_id
          OR NEW.project_id != OLD.project_id
          OR NEW.revision_number != OLD.revision_number
          OR NEW.base_revision_id IS NOT OLD.base_revision_id
          OR NEW.geometry_version != OLD.geometry_version
          OR NEW.canvas_width != OLD.canvas_width
          OR NEW.canvas_height != OLD.canvas_height
          OR NEW.created_at != OLD.created_at
        THEN RAISE(ABORT, 'inventory revision identity is immutable')
      END;
      SELECT CASE
        WHEN NEW.updated_at < OLD.updated_at
        THEN RAISE(ABORT, 'inventory revision timestamp regression')
      END;
      SELECT CASE
        WHEN NOT (
          (
            OLD.state = 'DRAFT'
            AND NEW.state = 'DRAFT'
            AND NEW.content_revision = OLD.content_revision + 1
            AND (
              NEW.geometry_json != OLD.geometry_json
              OR NEW.geometry_sha256 != OLD.geometry_sha256
            )
            AND NEW.finalized_at IS OLD.finalized_at
            AND NEW.superseded_at IS OLD.superseded_at
            AND NEW.abandoned_at IS OLD.abandoned_at
          )
          OR (
            OLD.state = 'DRAFT'
            AND NEW.state IN ('ACTIVE', 'ABANDONED')
            AND NEW.content_revision = OLD.content_revision
            AND NEW.geometry_json = OLD.geometry_json
            AND NEW.geometry_sha256 = OLD.geometry_sha256
          )
          OR (
            OLD.state = 'ACTIVE'
            AND NEW.state = 'SUPERSEDED'
            AND NEW.content_revision = OLD.content_revision
            AND NEW.geometry_json = OLD.geometry_json
            AND NEW.geometry_sha256 = OLD.geometry_sha256
            AND NEW.finalized_at = OLD.finalized_at
            AND NEW.abandoned_at IS OLD.abandoned_at
          )
        )
        THEN RAISE(ABORT, 'inventory revision transition is not allowed')
      END;
    END
  ''');

  await transaction.execute('''
    CREATE TRIGGER inventory_assets_guarded_update
    BEFORE UPDATE ON inventory_assets
    BEGIN
      SELECT CASE
        WHEN NEW.id != OLD.id
          OR NEW.project_id != OLD.project_id
          OR NEW.created_at != OLD.created_at
        THEN RAISE(ABORT, 'inventory asset identity is immutable')
      END;
      SELECT CASE
        WHEN NEW.revision != OLD.revision + 1
        THEN RAISE(ABORT, 'inventory asset revision mismatch')
      END;
      SELECT CASE
        WHEN NEW.updated_at < OLD.updated_at
          OR NEW.status_changed_at < OLD.status_changed_at
        THEN RAISE(ABORT, 'inventory asset timestamp regression')
      END;
      SELECT CASE
        WHEN NEW.status = OLD.status
          AND NEW.status_changed_at != OLD.status_changed_at
        THEN RAISE(ABORT, 'inventory asset status timestamp mismatch')
      END;
      SELECT CASE
        WHEN NEW.status != OLD.status
          AND NEW.status_changed_at != NEW.updated_at
        THEN RAISE(ABORT, 'inventory asset status timestamp mismatch')
      END;
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_assets_quantity_sum_update
    BEFORE UPDATE OF total_quantity ON inventory_assets
    WHEN NEW.total_quantity < (
      SELECT COALESCE(SUM(placement.quantity), 0)
      FROM inventory_asset_placements placement
      WHERE placement.project_id = OLD.project_id
        AND placement.asset_id = OLD.id
        AND placement.ended_at IS NULL
    )
    BEGIN
      SELECT RAISE(ABORT, 'inventory active placement quantity exceeds asset');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_assets_archive_without_active_placements
    BEFORE UPDATE OF archived_at ON inventory_assets
    WHEN OLD.archived_at IS NULL
      AND NEW.archived_at IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM inventory_asset_placements placement
        WHERE placement.project_id = OLD.project_id
          AND placement.asset_id = OLD.id
          AND placement.ended_at IS NULL
      )
    BEGIN
      SELECT RAISE(ABORT, 'inventory asset has active placements');
    END
  ''');

  await transaction.execute('''
    CREATE TRIGGER inventory_asset_placements_source_insert
    BEFORE INSERT ON inventory_asset_placements
    BEGIN
      SELECT CASE
        WHEN NOT EXISTS (
          SELECT 1
          FROM inventory_sketches sketch
          JOIN inventory_sketch_revisions revision
            ON revision.id = NEW.provenance_revision_id
            AND revision.project_id = NEW.project_id
            AND revision.sketch_id = NEW.sketch_id
          WHERE sketch.id = NEW.sketch_id
            AND sketch.project_id = NEW.project_id
            AND sketch.active_revision_id = NEW.provenance_revision_id
            AND sketch.archived_at IS NULL
            AND revision.state = 'ACTIVE'
        )
        THEN RAISE(ABORT, 'inventory placement revision source is invalid')
      END;
      SELECT CASE
        WHEN NEW.ended_at IS NULL
          AND NOT EXISTS (
            SELECT 1
            FROM inventory_assets asset
            WHERE asset.id = NEW.asset_id
              AND asset.project_id = NEW.project_id
              AND asset.archived_at IS NULL
          )
        THEN RAISE(ABORT, 'inventory placement asset is unavailable')
      END;
      SELECT CASE
        WHEN NEW.supersedes_placement_id IS NULL AND NEW.sequence != 1
        THEN RAISE(ABORT, 'inventory placement initial sequence is invalid')
      END;
      SELECT CASE
        WHEN NEW.supersedes_placement_id IS NOT NULL
          AND NOT EXISTS (
            SELECT 1
            FROM inventory_asset_placements predecessor
            WHERE predecessor.id = NEW.supersedes_placement_id
              AND predecessor.project_id = NEW.project_id
              AND predecessor.placement_key = NEW.placement_key
              AND predecessor.asset_id = NEW.asset_id
              AND predecessor.sketch_id = NEW.sketch_id
              AND predecessor.sequence + 1 = NEW.sequence
              AND predecessor.ended_at IS NOT NULL
          )
        THEN RAISE(ABORT, 'inventory placement predecessor is invalid')
      END;
      SELECT CASE
        WHEN NEW.ended_at IS NULL
          AND NEW.quantity + (
            SELECT COALESCE(SUM(placement.quantity), 0)
            FROM inventory_asset_placements placement
            WHERE placement.project_id = NEW.project_id
              AND placement.asset_id = NEW.asset_id
              AND placement.ended_at IS NULL
          ) > (
            SELECT asset.total_quantity
            FROM inventory_assets asset
            WHERE asset.id = NEW.asset_id
              AND asset.project_id = NEW.project_id
          )
        THEN RAISE(ABORT, 'inventory active placement quantity exceeds asset')
      END;
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_asset_placements_terminal_update
    BEFORE UPDATE ON inventory_asset_placements
    BEGIN
      SELECT CASE
        WHEN NEW.id != OLD.id
          OR NEW.placement_key != OLD.placement_key
          OR NEW.project_id != OLD.project_id
          OR NEW.asset_id != OLD.asset_id
          OR NEW.sketch_id != OLD.sketch_id
          OR NEW.provenance_revision_id != OLD.provenance_revision_id
          OR NEW.sequence != OLD.sequence
          OR NEW.x != OLD.x
          OR NEW.y != OLD.y
          OR NEW.quantity != OLD.quantity
          OR NEW.created_at != OLD.created_at
          OR NEW.supersedes_placement_id IS NOT OLD.supersedes_placement_id
        THEN RAISE(ABORT, 'inventory placement source is immutable')
      END;
      SELECT CASE
        WHEN OLD.ended_at IS NOT NULL
          OR OLD.end_reason IS NOT NULL
          OR NEW.ended_at IS NULL
          OR NEW.end_reason IS NULL
        THEN RAISE(ABORT, 'inventory placement terminal transition is invalid')
      END;
    END
  ''');

  for (final table in const [
    'inventory_sketches',
    'inventory_sketch_revisions',
    'inventory_assets',
    'inventory_asset_placements',
    'inventory_asset_attachment_links',
  ]) {
    await transaction.execute('''
      CREATE TRIGGER ${table}_no_physical_delete
      BEFORE DELETE ON $table
      BEGIN
        SELECT RAISE(ABORT, 'inventory source cannot be physically deleted');
      END
    ''');
  }

  await transaction.execute('''
    CREATE TRIGGER inventory_command_receipts_aggregate_insert
    BEFORE INSERT ON inventory_command_receipts
    WHEN (
      NEW.primary_aggregate_type = 'sketch'
      AND NOT EXISTS (
        SELECT 1 FROM inventory_sketches source
        WHERE source.id = NEW.primary_aggregate_id
          AND source.project_id = NEW.project_id
      )
    ) OR (
      NEW.primary_aggregate_type = 'asset'
      AND NOT EXISTS (
        SELECT 1 FROM inventory_assets source
        WHERE source.id = NEW.primary_aggregate_id
          AND source.project_id = NEW.project_id
      )
    ) OR (
      NEW.primary_aggregate_type = 'placement'
      AND NOT EXISTS (
        SELECT 1 FROM inventory_asset_placements source
        WHERE source.placement_key = NEW.primary_aggregate_id
          AND source.project_id = NEW.project_id
      )
    ) OR (
      NEW.primary_aggregate_type = 'attachment_link'
      AND NOT EXISTS (
        SELECT 1 FROM inventory_asset_attachment_links source
        WHERE source.id = NEW.primary_aggregate_id
          AND source.project_id = NEW.project_id
      )
    )
    BEGIN
      SELECT RAISE(ABORT, 'inventory receipt aggregate is invalid');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_events_aggregate_insert
    BEFORE INSERT ON inventory_events
    WHEN (
      NEW.aggregate_type = 'sketch'
      AND NOT EXISTS (
        SELECT 1 FROM inventory_sketches source
        WHERE source.id = NEW.aggregate_id
          AND source.project_id = NEW.project_id
      )
    ) OR (
      NEW.aggregate_type = 'asset'
      AND NOT EXISTS (
        SELECT 1 FROM inventory_assets source
        WHERE source.id = NEW.aggregate_id
          AND source.project_id = NEW.project_id
      )
    ) OR (
      NEW.aggregate_type = 'placement'
      AND NOT EXISTS (
        SELECT 1 FROM inventory_asset_placements source
        WHERE source.placement_key = NEW.aggregate_id
          AND source.project_id = NEW.project_id
      )
    ) OR (
      NEW.aggregate_type = 'attachment_link'
      AND NOT EXISTS (
        SELECT 1 FROM inventory_asset_attachment_links source
        WHERE source.id = NEW.aggregate_id
          AND source.project_id = NEW.project_id
      )
    )
    BEGIN
      SELECT RAISE(ABORT, 'inventory event aggregate is invalid');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER inventory_events_contiguous_sequence
    BEFORE INSERT ON inventory_events
    WHEN NEW.sequence != (
      SELECT COALESCE(MAX(event.sequence), 0) + 1
      FROM inventory_events event
      WHERE event.aggregate_type = NEW.aggregate_type
        AND event.aggregate_id = NEW.aggregate_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'inventory event sequence is not contiguous');
    END
  ''');
  for (final table in const [
    'inventory_command_receipts',
    'inventory_events',
  ]) {
    for (final operation in ['update', 'delete']) {
      await transaction.execute('''
        CREATE TRIGGER ${table}_append_only_$operation
        BEFORE ${operation.toUpperCase()} ON $table
        BEGIN
          SELECT RAISE(ABORT, 'inventory history is append-only');
        END
      ''');
    }
  }

  await transaction.execute('''
    CREATE TRIGGER inventory_asset_attachment_links_guarded_update
    BEFORE UPDATE ON inventory_asset_attachment_links
    BEGIN
      SELECT CASE
        WHEN NEW.id != OLD.id
          OR NEW.attachment_id != OLD.attachment_id
          OR NEW.asset_id != OLD.asset_id
          OR NEW.project_id != OLD.project_id
          OR NEW.role != OLD.role
          OR NEW.created_at != OLD.created_at
        THEN RAISE(ABORT, 'inventory photo link identity is immutable')
      END;
      SELECT CASE
        WHEN NEW.revision != OLD.revision + 1
        THEN RAISE(ABORT, 'inventory photo link revision mismatch')
      END;
      SELECT CASE
        WHEN NEW.updated_at < OLD.updated_at
        THEN RAISE(ABORT, 'inventory photo link timestamp regression')
      END;
      SELECT CASE
        WHEN NEW.original_file_name = OLD.original_file_name
          AND NEW.description IS OLD.description
          AND NEW.archived_at IS OLD.archived_at
        THEN RAISE(ABORT, 'inventory photo link no-op update')
      END;
    END
  ''');
}

Future<void> _applyAttachmentFoundationMigration(
  Transaction transaction,
) async {
  await transaction.execute('''
    CREATE TABLE managed_attachments (
      id TEXT PRIMARY KEY,
      relative_path TEXT NOT NULL UNIQUE CHECK (
        length(relative_path) > 0
        AND relative_path = trim(relative_path)
        AND substr(relative_path, 1, 1) != '/'
        AND instr(relative_path, char(92)) = 0
        AND instr(relative_path, ':') = 0
        AND instr(relative_path, '//') = 0
        AND relative_path != '..'
        AND relative_path NOT LIKE '../%'
        AND relative_path NOT LIKE '%/../%'
        AND relative_path NOT LIKE '%/..'
      ),
      mime_type TEXT NOT NULL CHECK (
        length(trim(mime_type)) > 0 AND mime_type = trim(mime_type)
      ),
      byte_size INTEGER NOT NULL CHECK (byte_size > 0),
      sha256 TEXT NOT NULL CHECK (
        length(sha256) = 64
        AND sha256 = lower(sha256)
        AND sha256 NOT GLOB '*[^0-9a-f]*'
      ),
      created_at TEXT NOT NULL
    )
  ''');
  await transaction.execute('''
    CREATE INDEX ix_managed_attachments_content_candidate
    ON managed_attachments(sha256, byte_size, mime_type)
  ''');

  await transaction.execute('''
    CREATE TABLE attachment_links (
      id TEXT PRIMARY KEY,
      attachment_id TEXT NOT NULL REFERENCES managed_attachments(id),
      project_id TEXT NOT NULL REFERENCES projects(id),
      source_type TEXT NOT NULL CHECK (
        source_type IN ('agenda_observation', 'concrete_pour')
      ),
      source_id TEXT NOT NULL,
      context_type TEXT CHECK (
        context_type IS NULL OR context_type IN (
          'concrete_truck', 'concrete_sample_set', 'concrete_check_item'
        )
      ),
      context_id TEXT,
      role TEXT NOT NULL CHECK (role IN (
        'site_photo', 'delivery_receipt_scan', 'delivery_note_scan',
        'mixer_photo', 'sample_photo', 'laboratory_delivery_document',
        'result_document', 'other'
      )),
      original_file_name TEXT NOT NULL CHECK (
        length(trim(original_file_name)) > 0
      ),
      description TEXT,
      captured_at TEXT,
      revision INTEGER NOT NULL DEFAULT 1 CHECK (revision >= 1),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      archived_at TEXT,
      legacy_source TEXT CHECK (
        legacy_source IS NULL OR legacy_source IN (
          'agenda_log_attachments', 'concrete_attachments'
        )
      ),
      legacy_id TEXT,
      UNIQUE (legacy_source, legacy_id),
      CHECK (
        (context_type IS NULL AND context_id IS NULL)
        OR (context_type IS NOT NULL AND context_id IS NOT NULL)
      ),
      CHECK (
        (legacy_source IS NULL AND legacy_id IS NULL)
        OR (legacy_source IS NOT NULL AND legacy_id IS NOT NULL)
      ),
      CHECK (source_type = 'concrete_pour' OR context_type IS NULL),
      CHECK (source_type = 'concrete_pour' OR role = 'site_photo'),
      CHECK (source_type = 'agenda_observation' OR captured_at IS NOT NULL)
    )
  ''');
  await transaction.execute('''
    CREATE INDEX ix_attachment_links_source
    ON attachment_links(
      source_type, source_id, archived_at, created_at, id
    )
  ''');
  await transaction.execute('''
    CREATE INDEX ix_attachment_links_attachment
    ON attachment_links(attachment_id, archived_at, created_at, id)
  ''');
  await transaction.execute('''
    CREATE UNIQUE INDEX uq_attachment_links_active_relation
    ON attachment_links(
      attachment_id,
      source_type,
      source_id,
      COALESCE(context_type, ''),
      COALESCE(context_id, ''),
      role
    )
    WHERE archived_at IS NULL
  ''');
  await transaction.execute('''
    CREATE UNIQUE INDEX uq_attachment_links_source_public_id
    ON attachment_links(source_type, COALESCE(legacy_id, id))
  ''');

  await transaction.execute('''
    CREATE TABLE attachment_link_events (
      id TEXT PRIMARY KEY,
      attachment_link_id TEXT NOT NULL REFERENCES attachment_links(id),
      sequence INTEGER NOT NULL CHECK (sequence >= 1),
      event_type TEXT NOT NULL CHECK (event_type IN (
        'link.created', 'link.archived', 'link.restored', 'link.unlinked'
      )),
      occurred_at TEXT NOT NULL,
      payload_json TEXT NOT NULL,
      UNIQUE (attachment_link_id, sequence)
    )
  ''');
  await transaction.execute('''
    CREATE INDEX ix_attachment_link_events_link
    ON attachment_link_events(attachment_link_id, sequence, id)
  ''');

  for (final suffix in ['insert', 'update']) {
    final action = suffix == 'insert' ? 'INSERT' : 'UPDATE';
    final updateFields = suffix == 'insert'
        ? ''
        : ' OF project_id, source_type, source_id, context_type, context_id';
    await transaction.execute('''
      CREATE TRIGGER attachment_links_target_project_$suffix
      BEFORE $action$updateFields ON attachment_links
      WHEN (
        NEW.source_type = 'agenda_observation'
        AND NOT EXISTS (
          SELECT 1 FROM field_observations o
          WHERE o.id = NEW.source_id AND o.project_id = NEW.project_id
        )
      ) OR (
        NEW.source_type = 'concrete_pour'
        AND NOT EXISTS (
          SELECT 1 FROM concrete_pours p
          WHERE p.id = NEW.source_id AND p.project_id = NEW.project_id
        )
      ) OR (
        NEW.context_type = 'concrete_truck'
        AND NOT EXISTS (
          SELECT 1 FROM concrete_trucks t
          WHERE t.id = NEW.context_id
            AND t.concrete_pour_id = NEW.source_id
        )
      ) OR (
        NEW.context_type = 'concrete_sample_set'
        AND NOT EXISTS (
          SELECT 1 FROM concrete_sample_sets s
          WHERE s.id = NEW.context_id
            AND s.concrete_pour_id = NEW.source_id
        )
      ) OR (
        NEW.context_type = 'concrete_check_item'
        AND NOT EXISTS (
          SELECT 1 FROM concrete_check_items c
          WHERE c.id = NEW.context_id
            AND c.concrete_pour_id = NEW.source_id
        )
      )
      BEGIN
        SELECT RAISE(ABORT, 'attachment target must exist in link project');
      END
    ''');
  }

  await transaction.execute('''
    CREATE TRIGGER attachment_links_source_digest_unique
    BEFORE INSERT ON attachment_links
    WHEN EXISTS (
      SELECT 1
      FROM managed_attachments incoming
      JOIN attachment_links existing
        ON existing.source_type = NEW.source_type
        AND existing.source_id = NEW.source_id
      JOIN managed_attachments stored
        ON stored.id = existing.attachment_id
      WHERE incoming.id = NEW.attachment_id
        AND stored.sha256 = incoming.sha256
    )
    BEGIN
      SELECT RAISE(ABORT, 'attachment digest already linked to source');
    END
  ''');
  await transaction.execute('''
    CREATE TRIGGER attachment_links_identity_immutable
    BEFORE UPDATE OF attachment_id, project_id, source_type, source_id,
      context_type, context_id ON attachment_links
    WHEN NEW.attachment_id != OLD.attachment_id
      OR NEW.project_id != OLD.project_id
      OR NEW.source_type != OLD.source_type
      OR NEW.source_id != OLD.source_id
      OR NEW.context_type IS NOT OLD.context_type
      OR NEW.context_id IS NOT OLD.context_id
    BEGIN
      SELECT RAISE(ABORT, 'attachment link identity is immutable');
    END
  ''');
  for (final table in ['managed_attachments', 'attachment_links']) {
    await transaction.execute('''
      CREATE TRIGGER ${table}_no_physical_delete
      BEFORE DELETE ON $table
      BEGIN
        SELECT RAISE(ABORT, 'physical delete is not allowed');
      END
    ''');
  }
  for (final operation in ['update', 'delete']) {
    await transaction.execute('''
      CREATE TRIGGER attachment_link_events_append_only_$operation
      BEFORE ${operation.toUpperCase()} ON attachment_link_events
      BEGIN
        SELECT RAISE(ABORT, 'append-only event history');
      END
    ''');
  }

  final agendaRows = await transaction.query(
    'agenda_log_attachments',
    orderBy: 'id ASC',
  );
  for (final row in agendaRows) {
    final legacyId = row['id']! as String;
    final physicalId = _migrationStableUuid('agenda_binary:$legacyId');
    final linkId = _migrationStableUuid('agenda_log_attachments:$legacyId');
    await transaction.insert('managed_attachments', {
      'id': physicalId,
      'relative_path': row['relative_path'],
      'mime_type': row['mime_type'],
      'byte_size': row['byte_size'],
      'sha256': row['sha256'],
      'created_at': row['created_at'],
    });
    await transaction.insert('attachment_links', {
      'id': linkId,
      'attachment_id': physicalId,
      'project_id': row['project_id'],
      'source_type': 'agenda_observation',
      'source_id': row['observation_id'],
      'role': row['attachment_type'],
      'original_file_name': row['original_file_name'],
      'description': row['description'],
      'captured_at': row['captured_at'],
      'revision': row['revision'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      'archived_at': row['archived_at'],
      'legacy_source': 'agenda_log_attachments',
      'legacy_id': legacyId,
    });
    await transaction.insert('attachment_link_events', {
      'id': _migrationStableUuid('attachment_link_event:$linkId:created'),
      'attachment_link_id': linkId,
      'sequence': 1,
      'event_type': 'link.created',
      'occurred_at': row['created_at'],
      'payload_json': jsonEncode({
        'legacy_source': 'agenda_log_attachments',
        'legacy_id': legacyId,
      }),
    });
  }

  final concreteRows = await transaction.rawQuery('''
    SELECT a.*, p.project_id AS link_project_id
    FROM concrete_attachments a
    JOIN concrete_pours p ON p.id = a.concrete_pour_id
    ORDER BY a.id ASC
  ''');
  for (final row in concreteRows) {
    final legacyId = row['id']! as String;
    final physicalId = _migrationStableUuid('concrete_binary:$legacyId');
    final linkId = _migrationStableUuid('concrete_attachments:$legacyId');
    final truckId = row['truck_id'] as String?;
    final sampleSetId = row['sample_set_id'] as String?;
    final checkItemId = row['check_item_id'] as String?;
    final contextType = truckId != null
        ? 'concrete_truck'
        : sampleSetId != null
        ? 'concrete_sample_set'
        : checkItemId != null
        ? 'concrete_check_item'
        : null;
    final contextId = truckId ?? sampleSetId ?? checkItemId;
    await transaction.insert('managed_attachments', {
      'id': physicalId,
      'relative_path': row['relative_path'],
      'mime_type': row['mime_type'],
      'byte_size': row['byte_size'],
      'sha256': row['sha256'],
      'created_at': row['created_at'],
    });
    await transaction.insert('attachment_links', {
      'id': linkId,
      'attachment_id': physicalId,
      'project_id': row['link_project_id'],
      'source_type': 'concrete_pour',
      'source_id': row['concrete_pour_id'],
      'context_type': contextType,
      'context_id': contextId,
      'role': row['evidence_type'],
      'original_file_name': row['original_file_name'],
      'description': row['description'],
      'captured_at': row['captured_at'],
      'revision': 1,
      'created_at': row['created_at'],
      'updated_at': row['created_at'],
      'archived_at': row['archived_at'],
      'legacy_source': 'concrete_attachments',
      'legacy_id': legacyId,
    });
    await transaction.insert('attachment_link_events', {
      'id': _migrationStableUuid('attachment_link_event:$linkId:created'),
      'attachment_link_id': linkId,
      'sequence': 1,
      'event_type': 'link.created',
      'occurred_at': row['created_at'],
      'payload_json': jsonEncode({
        'legacy_source': 'concrete_attachments',
        'legacy_id': legacyId,
      }),
    });
  }

  final agendaMappings = Sqflite.firstIntValue(
    await transaction.rawQuery('''
      SELECT count(*) FROM attachment_links
      WHERE legacy_source = 'agenda_log_attachments'
    '''),
  );
  final concreteMappings = Sqflite.firstIntValue(
    await transaction.rawQuery('''
      SELECT count(*) FROM attachment_links
      WHERE legacy_source = 'concrete_attachments'
    '''),
  );
  if (agendaMappings != agendaRows.length ||
      concreteMappings != concreteRows.length) {
    throw StateError('legacy attachment mapping count mismatch');
  }

  await transaction.execute(
    'DROP TRIGGER IF EXISTS agenda_log_attachments_no_physical_delete',
  );
  await transaction.execute(
    'DROP TRIGGER IF EXISTS concrete_attachments_no_physical_delete',
  );
  await transaction.execute('DROP TABLE agenda_log_attachments');
  await transaction.execute('DROP TABLE concrete_attachments');
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
