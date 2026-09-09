import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/application/attachment_reconciliation_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_intelligence_application.dart';
import 'package:chief_site_engineer/application/context_suggestion_application.dart';
import 'package:chief_site_engineer/application/daily_log_application.dart';
import 'package:chief_site_engineer/application/inventory_application.dart';
import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/application/mobile_backup_application.dart';
import 'package:chief_site_engineer/application/work_chain_application.dart';
import 'package:chief_site_engineer/application/restore_recovery_application.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/platform/attendance_export_gateway.dart';
import 'package:chief_site_engineer/platform/agenda_attachment_gateway.dart';
import 'package:chief_site_engineer/platform/agenda_photo_export_gateway.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:chief_site_engineer/platform/concrete_attachment_gateway.dart';
import 'package:chief_site_engineer/platform/concrete_export_gateway.dart';
import 'package:chief_site_engineer/platform/export_gateway.dart';
import 'package:chief_site_engineer/platform/inventory_attachment_gateway.dart';
import 'package:chief_site_engineer/platform/managed_attachment_store.dart';
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
    this.inventory = const UnavailableInventoryApplication(),
    this.livingPlan = const UnavailableConstructionLivingPlanApplication(),
    this.livingPlanIntelligence =
        const UnavailableConstructionLivingPlanIntelligenceApplication(),
    this.dailyLog,
    this.workChain,
    this.materialRequests,
    this.contextSuggestions,
    this.projectLocations,
    this.attendance,
    this.concrete,
    this.concreteAttachments,
    this.backup,
    this.attachmentCatalog,
    this.attachmentReconciliation,
  });

  final String environmentLabel;
  final String smokeRecordId;
  final String smokeRecordCreatedAt;
  final AgendaApplication agenda;
  final InventoryApplicationPort inventory;
  final ConstructionLivingPlanApplicationPort livingPlan;
  final ConstructionLivingPlanIntelligenceApplicationPort
  livingPlanIntelligence;
  final DailyLogApplicationPort? dailyLog;
  final WorkChainApplicationPort? workChain;
  final MaterialRequestApplicationPort? materialRequests;
  final ContextSuggestionApplication? contextSuggestions;
  final ProjectLocationApplication? projectLocations;
  final AttendanceApplication? attendance;
  final ConcreteApplication? concrete;
  final SafeAttachmentPicker? concreteAttachments;
  final MobileBackupApplication? backup;
  final AttachmentCatalogApplication? attachmentCatalog;
  final AttachmentReconciliationApplication? attachmentReconciliation;
}

class BootstrapFailure extends BootstrapResult {
  const BootstrapFailure({this.code = 'startup_failed'});

  final String code;
}

class AppBootstrap {
  AppBootstrap({
    required this.environment,
    required this.directoriesProvider,
    required this.databaseFactory,
    required this.clock,
    ReminderNotificationGateway? notificationGateway,
    this.diagnosticSink,
    this.monotonicElapsed,
    this.notificationPerAwaitLimit = const Duration(seconds: 2),
    this.startupNotificationLimit = const Duration(seconds: 8),
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
  final StartupPhaseSink? diagnosticSink;
  final MonotonicElapsed? monotonicElapsed;
  final Duration notificationPerAwaitLimit;
  final Duration startupNotificationLimit;

  Future<T> _phase<T>(
    StartupPhaseDiagnostics diagnostics,
    StartupPhase phase,
    Future<T> Function() action, {
    StartupDiagnosticOrigin origin = StartupDiagnosticOrigin.bootstrap,
    StartupSafeErrorCode failureCode = StartupSafeErrorCode.startupFailure,
  }) async {
    diagnostics.record(phase, StartupPhaseOutcome.started, origin: origin);
    try {
      final result = await action();
      diagnostics.record(phase, StartupPhaseOutcome.succeeded, origin: origin);
      return result;
    } on Object {
      diagnostics.record(
        phase,
        StartupPhaseOutcome.failed,
        origin: origin,
        safeErrorCode: failureCode,
      );
      rethrow;
    }
  }

  Future<T> _notificationAction<T>(
    NotificationExecutionContext context,
    StartupPhase phase,
    String operationKey,
    Future<T> Function() action,
  ) {
    return runWithNotificationExecution(context, () {
      if (notificationGateway is DeadlineAwareReminderNotificationGateway) {
        return action();
      }
      return context.budget.awaitPlatform<T>(
        phase: phase,
        origin: context.origin,
        operationKey: operationKey,
        operation: action,
      );
    });
  }

  Future<BootstrapResult> start() async {
    final diagnostics = StartupPhaseDiagnostics(
      sink: diagnosticSink,
      elapsed: monotonicElapsed,
    );
    diagnostics.record(StartupPhase.bootstrap, StartupPhaseOutcome.started);
    AppDatabase? database;
    try {
      final directories = await _phase(
        diagnostics,
        StartupPhase.directories,
        directoriesProvider,
      );
      if (directories.environment != environment) {
        throw const PathContractViolation('environment directory mismatch');
      }
      final backupFileGateway = DeviceMobileBackupFileGateway(
        directories: directories,
        clock: clock,
      );
      await _phase(
        diagnostics,
        StartupPhase.recoveryRoots,
        directories.ensureRecoveryRootsCreated,
      );
      try {
        await _phase(
          diagnostics,
          StartupPhase.restoreRecovery,
          () => MobileRestoreRecoveryApplication(
            directories: directories,
            databaseFactory: databaseFactory,
            clock: clock,
          ).recoverBeforeBootstrap(),
          failureCode: StartupSafeErrorCode.recoveryFailure,
        );
      } on RestoreRecoveryFailure {
        diagnostics.record(
          StartupPhase.bootstrap,
          StartupPhaseOutcome.failed,
          safeErrorCode: StartupSafeErrorCode.recoveryFailure,
        );
        return const BootstrapFailure(code: 'restore_recovery_failed');
      }
      try {
        await _phase(
          diagnostics,
          StartupPhase.incomingReconciliation,
          backupFileGateway.reconcileIncomingPackages,
        );
      } on Object {
        // Incoming cleanup never blocks access to the active SQLite truth.
      }
      await _phase(
        diagnostics,
        StartupPhase.directories,
        directories.ensureCreated,
      );
      database = AppDatabase(
        path: directories.databaseFile,
        factory: databaseFactory,
        clock: clock,
      );
      await _phase(diagnostics, StartupPhase.databaseOpen, database.open);
      final smoke = await _phase(
        diagnostics,
        StartupPhase.foundationSmoke,
        () => SmokeRecordRepository(
          database: database!,
          clock: clock,
        ).ensureFoundationRecord(),
      );
      await _phase(diagnostics, StartupPhase.databaseClose, database.close);
      database = null;
      final coordinator = MobileOperationCoordinator();
      final notificationAttempts = NotificationPlatformAttemptRegistry();
      final managedAttachmentStore = DeviceManagedAttachmentStore(
        directories: directories,
      );
      final safeAttachmentPicker = SafeAttachmentPicker(
        permissions: const SafeCapabilityService(DevicePermissionGateway()),
        picker: FlutterAttachmentPickerPort(),
      );
      final safeInventoryAttachmentPicker = SafeAttachmentPicker(
        permissions: const SafeCapabilityService(DevicePermissionGateway()),
        picker: FlutterInventoryAttachmentPickerPort(),
      );
      final attachmentCatalog = SqliteAttachmentCatalogApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
        managedStore: managedAttachmentStore,
      );
      final attachmentReconciliation = AttachmentReconciliationApplication(
        directories: directories,
        databaseFactory: databaseFactory,
        managedStore: managedAttachmentStore,
      );
      final agenda = SqliteAgendaApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
        clock: clock,
        notificationGateway: notificationGateway,
        notificationDiagnostics: diagnostics,
        notificationAttempts: notificationAttempts,
        notificationPerAwaitLimit: notificationPerAwaitLimit,
        notificationTotalLimit: startupNotificationLimit,
        coordinator: coordinator,
        attachmentStore: DeviceAgendaAttachmentStore.shared(
          managedStore: managedAttachmentStore,
        ),
        photoExportGateway: DeviceAgendaPhotoExportGateway(
          directories: directories,
        ),
        attachmentCatalog: attachmentCatalog,
      );
      final livingPlan = SqliteConstructionLivingPlanApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
        clock: clock,
      );
      final inventory = SqliteInventoryApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
        clock: clock,
        attachmentGateway: DeviceInventoryAttachmentGateway(
          picker: safeInventoryAttachmentPicker,
          managedStore: managedAttachmentStore,
        ),
      );
      final livingPlanIntelligence =
          SqliteConstructionLivingPlanIntelligenceApplication(
            databasePath: directories.databaseFile,
            databaseFactory: databaseFactory,
          );
      final dailyLog = SqliteDailyLogApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
      );
      final workChain = SqliteWorkChainApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
      );
      final materialRequests = SqliteMaterialRequestApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
        clock: clock,
        coordinator: coordinator,
      );
      final contextSuggestions = SqliteContextSuggestionApplication(
        databasePath: directories.databaseFile,
        databaseFactory: databaseFactory,
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
        attachmentStore: DeviceConcreteAttachmentStore.shared(
          managedStore: managedAttachmentStore,
        ),
        attachmentCatalog: attachmentCatalog,
        exportGateway: DeviceConcreteExportGateway(
          stager: LocalExportStager(directories),
        ),
        coordinator: coordinator,
      );
      final concreteAttachments = safeAttachmentPicker;
      final startupNotificationBudget = NotificationExecutionBudget(
        diagnostics: diagnostics,
        attempts: notificationAttempts,
        perAwaitLimit: notificationPerAwaitLimit,
        totalLimit: startupNotificationLimit,
      );
      try {
        final context = NotificationExecutionContext(
          budget: startupNotificationBudget,
          origin: StartupDiagnosticOrigin.bootstrap,
        );
        await _phase(
          diagnostics,
          StartupPhase.notificationInitialize,
          () => _notificationAction<void>(
            context,
            StartupPhase.notificationInitialize,
            'bootstrap-initialize',
            notificationGateway.initialize,
          ),
        );
      } on Object {
        // SQLite remains source-of-truth when the platform plugin is absent.
      }
      await _phase(
        diagnostics,
        StartupPhase.rollingOccurrences,
        () => runWithNotificationExecution(
          NotificationExecutionContext(
            budget: startupNotificationBudget,
            origin: StartupDiagnosticOrigin.rollingOccurrences,
          ),
          attendance.ensureRollingOccurrences,
        ),
        origin: StartupDiagnosticOrigin.rollingOccurrences,
      );
      await _phase(
        diagnostics,
        StartupPhase.finalNotificationReconciliation,
        () => runWithNotificationExecution(
          NotificationExecutionContext(
            budget: startupNotificationBudget,
            origin: StartupDiagnosticOrigin.finalReconciliation,
          ),
          agenda.reconcileNotifications,
        ),
        origin: StartupDiagnosticOrigin.finalReconciliation,
      );
      final backup = SqliteMobileBackupApplication(
        directories: directories,
        databaseFactory: databaseFactory,
        clock: clock,
        coordinator: coordinator,
        fileGateway: backupFileGateway,
        notificationReconciler: () async {
          notificationAttempts.invalidateSource();
          // The restore already owns the application-wide coordinator. A fresh
          // reader reconciles the newly activated SQLite truth without nesting
          // another operation on the same serial queue.
          final restoredAgenda = SqliteAgendaApplication(
            databasePath: directories.databaseFile,
            databaseFactory: databaseFactory,
            clock: clock,
            notificationGateway: notificationGateway,
            notificationDiagnostics: diagnostics,
            notificationAttempts: notificationAttempts,
            notificationPerAwaitLimit: notificationPerAwaitLimit,
            notificationTotalLimit: startupNotificationLimit,
            coordinator: MobileOperationCoordinator(),
          );
          final restoreBudget = NotificationExecutionBudget(
            diagnostics: diagnostics,
            attempts: notificationAttempts,
            perAwaitLimit: notificationPerAwaitLimit,
            totalLimit: startupNotificationLimit,
          );
          await runWithNotificationExecution(
            NotificationExecutionContext(
              budget: restoreBudget,
              origin: StartupDiagnosticOrigin.restoreReconciliation,
            ),
            restoredAgenda.reconcileNotifications,
          );
        },
      );
      final result = BootstrapSuccess(
        environmentLabel: environment.label,
        smokeRecordId: smoke.id,
        smokeRecordCreatedAt: smoke.createdAt,
        agenda: agenda,
        inventory: inventory,
        livingPlan: livingPlan,
        livingPlanIntelligence: livingPlanIntelligence,
        dailyLog: dailyLog,
        workChain: workChain,
        materialRequests: materialRequests,
        contextSuggestions: contextSuggestions,
        projectLocations: agenda,
        attendance: attendance,
        concrete: concrete,
        concreteAttachments: concreteAttachments,
        backup: backup,
        attachmentCatalog: attachmentCatalog,
        attachmentReconciliation: attachmentReconciliation,
      );
      // This marker means a complete BootstrapResult, not a rendered frame.
      diagnostics.record(StartupPhase.bootstrap, StartupPhaseOutcome.succeeded);
      return result;
    } on Object {
      diagnostics.record(
        StartupPhase.bootstrap,
        StartupPhaseOutcome.failed,
        safeErrorCode: StartupSafeErrorCode.startupFailure,
      );
      return const BootstrapFailure();
    } finally {
      if (database != null) {
        try {
          await _phase(diagnostics, StartupPhase.databaseClose, database.close);
        } on Object {
          // The returned bootstrap failure remains privacy-safe and stable.
        }
      }
    }
  }
}
