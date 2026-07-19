import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/application/mobile_backup_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/platform/attendance_export_gateway.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:chief_site_engineer/platform/concrete_attachment_gateway.dart';
import 'package:chief_site_engineer/platform/concrete_export_gateway.dart';
import 'package:chief_site_engineer/platform/export_gateway.dart';
import 'package:chief_site_engineer/platform/mobile_backup_gateway.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:chief_site_engineer/storage/smoke_record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

sealed class BootstrapResult {
  const BootstrapResult();
}

class BootstrapSuccess extends BootstrapResult {
  const BootstrapSuccess({
    required this.environmentLabel,
    required this.smokeRecordId,
    required this.smokeRecordCreatedAt,
    required this.agenda,
    this.attendance,
    this.concrete,
    this.concreteAttachments,
    this.backup,
  });

  final String environmentLabel;
  final String smokeRecordId;
  final String smokeRecordCreatedAt;
  final AgendaApplication agenda;
  final AttendanceApplication? attendance;
  final ConcreteApplication? concrete;
  final SafeAttachmentPicker? concreteAttachments;
  final MobileBackupApplication? backup;
}

class BootstrapFailure extends BootstrapResult {
  const BootstrapFailure();
}

class AppBootstrap {
  AppBootstrap({
    required this.environment,
    required this.directoriesProvider,
    required this.databaseFactory,
    required this.clock,
    ReminderNotificationGateway? notificationGateway,
  }) : notificationGateway =
           notificationGateway ??
           const UnavailableReminderNotificationGateway();

  factory AppBootstrap.production() {
    final environment = AppEnvironment.current();
    return AppBootstrap(
      environment: environment,
      directoriesProvider: () async => AppDirectories.fromSupportRoot(
        await getApplicationSupportDirectory(),
        environment,
      ),
      databaseFactory: sqflite.databaseFactory,
      clock: () => DateTime.now().toUtc(),
      notificationGateway: FlutterReminderNotificationGateway(),
    );
  }

  final AppEnvironment environment;
  final Future<AppDirectories> Function() directoriesProvider;
  final sqflite.DatabaseFactory databaseFactory;
  final UtcClock clock;
  final ReminderNotificationGateway notificationGateway;

  Future<BootstrapResult> start() async {
    AppDatabase? database;
    try {
      final directories = await directoriesProvider();
      if (directories.environment != environment) {
        throw const PathContractViolation('environment directory mismatch');
      }
      await directories.ensureCreated();
      database = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactory,
        clock: clock,
      );
      await database.open();
      final smoke = await SmokeRecordRepository(
        database: database,
        clock: clock,
      ).ensureFoundationRecord();
      await database.close();
      database = null;
      final coordinator = MobileOperationCoordinator();
      final agenda = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
        clock: clock,
        notificationGateway: notificationGateway,
        coordinator: coordinator,
      );
      final attendance = SqliteAttendanceApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
        clock: clock,
        agenda: agenda,
        exportGateway: DeviceAttendanceExportGateway(
          stager: LocalExportStager(directories),
        ),
        coordinator: coordinator,
      );
      final concrete = SqliteConcreteApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
        clock: clock,
        agenda: agenda,
        attachmentStore: DeviceConcreteAttachmentStore(
          directories: directories,
        ),
        exportGateway: DeviceConcreteExportGateway(
          stager: LocalExportStager(directories),
        ),
        coordinator: coordinator,
      );
      final concreteAttachments = SafeAttachmentPicker(
        permissions: const SafeCapabilityService(DevicePermissionGateway()),
        picker: FlutterAttachmentPickerPort(),
      );
      try {
        await notificationGateway.initialize();
      } on Object {
        // SQLite remains source-of-truth when the platform plugin is absent.
      }
      await attendance.ensureRollingOccurrences();
      await agenda.reconcileNotifications();
      final backup = SqliteMobileBackupApplication(
        directories: directories,
        databaseFactory: databaseFactory,
        clock: clock,
        coordinator: coordinator,
        fileGateway: DeviceMobileBackupFileGateway(directories: directories),
        notificationReconciler: () async {
          // The restore already owns the application-wide coordinator. A fresh
          // reader reconciles the newly activated SQLite truth without nesting
          // another operation on the same serial queue.
          final restoredAgenda = SqliteAgendaApplication(
            databasePath: directories.databaseFile,
            databaseFactory: databaseFactory,
            clock: clock,
            notificationGateway: notificationGateway,
            coordinator: MobileOperationCoordinator(),
          );
          await restoredAgenda.reconcileNotifications();
        },
      );
      return BootstrapSuccess(
        environmentLabel: environment.label,
        smokeRecordId: smoke.id,
        smokeRecordCreatedAt: smoke.createdAt,
        agenda: agenda,
        attendance: attendance,
        concrete: concrete,
        concreteAttachments: concreteAttachments,
        backup: backup,
      );
    } on Object {
      return const BootstrapFailure();
    } finally {
      await database?.close();
    }
  }
}
