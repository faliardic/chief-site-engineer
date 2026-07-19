import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
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
  });

  final String environmentLabel;
  final String smokeRecordId;
  final String smokeRecordCreatedAt;
  final AgendaApplication agenda;
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
      final agenda = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
        clock: clock,
        notificationGateway: notificationGateway,
      );
      try {
        await notificationGateway.initialize();
      } on Object {
        // SQLite remains source-of-truth when the platform plugin is absent.
      }
      await agenda.reconcileNotifications();
      return BootstrapSuccess(
        environmentLabel: environment.label,
        smokeRecordId: smoke.id,
        smokeRecordCreatedAt: smoke.createdAt,
        agenda: agenda,
      );
    } on Object {
      return const BootstrapFailure();
    } finally {
      await database?.close();
    }
  }
}
