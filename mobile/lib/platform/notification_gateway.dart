import 'dart:async';
import 'dart:convert';

import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart' as hashes;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

enum StartupPhase {
  directories,
  recoveryRoots,
  restoreRecovery,
  incomingReconciliation,
  databaseOpen,
  foundationSmoke,
  databaseClose,
  notificationInitialize,
  rollingOccurrences,
  finalNotificationReconciliation,
  bootstrap,
  pluginInitialize,
  launchDetails,
  permissionStatus,
  pendingInitial,
  pendingVerification,
  cancel,
  schedule,
  inexactFallback,
}

enum StartupPhaseOutcome {
  started,
  succeeded,
  failed,
  timedOut,
  deadlineExhausted,
  deferredInFlight,
}

enum StartupDiagnosticOrigin {
  bootstrap,
  rollingOccurrences,
  finalReconciliation,
  restoreReconciliation,
  backgroundReconciliation,
}

enum StartupSafeErrorCode {
  none,
  startupFailure,
  recoveryFailure,
  platformFailure,
  platformTimeout,
  notificationDeadline,
  platformCallInFlight,
}

class StartupPhaseEvent {
  const StartupPhaseEvent({
    required this.phase,
    required this.outcome,
    required this.origin,
    required this.elapsed,
    required this.safeErrorCode,
  });

  final StartupPhase phase;
  final StartupPhaseOutcome outcome;
  final StartupDiagnosticOrigin origin;
  final Duration elapsed;
  final StartupSafeErrorCode safeErrorCode;

  String get safeLogLine =>
      'cse.startup phase=${phase.name} outcome=${outcome.name} '
      'origin=${origin.name} elapsed_ms=${elapsed.inMilliseconds} '
      'error=${safeErrorCode.name}';
}

typedef StartupPhaseSink = void Function(StartupPhaseEvent event);
typedef MonotonicElapsed = Duration Function();

class StartupPhaseDiagnostics {
  StartupPhaseDiagnostics({StartupPhaseSink? sink, MonotonicElapsed? elapsed})
    : _sink = sink ?? _defaultSink,
      _elapsed = elapsed ?? _newStopwatchElapsed();

  final StartupPhaseSink _sink;
  final MonotonicElapsed _elapsed;

  Duration get elapsed => _elapsed();

  void record(
    StartupPhase phase,
    StartupPhaseOutcome outcome, {
    StartupDiagnosticOrigin origin = StartupDiagnosticOrigin.bootstrap,
    StartupSafeErrorCode safeErrorCode = StartupSafeErrorCode.none,
  }) {
    try {
      _sink(
        StartupPhaseEvent(
          phase: phase,
          outcome: outcome,
          origin: origin,
          elapsed: _elapsed(),
          safeErrorCode: safeErrorCode,
        ),
      );
    } on Object {
      // Evidence must never become a startup dependency.
    }
  }

  static MonotonicElapsed _newStopwatchElapsed() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  static void _defaultSink(StartupPhaseEvent event) {
    debugPrint(event.safeLogLine);
  }
}

class NotificationPlatformBoundaryException implements Exception {
  const NotificationPlatformBoundaryException(this.safeErrorCode);

  final StartupSafeErrorCode safeErrorCode;
}

class NotificationPlatformAttemptRegistry {
  final Map<String, _NotificationPlatformAttempt<Object?>> _attempts = {};
  var _sourceEpoch = 0;

  int get sourceEpoch => _sourceEpoch;

  void invalidateSource() {
    _sourceEpoch += 1;
  }

  _NotificationPlatformAttempt<T> _obtain<T>(
    String targetKey,
    String requestKey,
    Future<T> Function() operation,
  ) {
    final existing = _attempts[targetKey];
    if (existing != null) {
      if (existing.requestKey != requestKey) {
        throw const NotificationPlatformBoundaryException(
          StartupSafeErrorCode.platformCallInFlight,
        );
      }
      return existing as _NotificationPlatformAttempt<T>;
    }
    final attempt = _NotificationPlatformAttempt<T>(requestKey, operation);
    _attempts[targetKey] = attempt as _NotificationPlatformAttempt<Object?>;
    attempt.future.then<void>(
      (_) => _remove(targetKey, attempt),
      onError: (Object error, StackTrace _) => _remove(targetKey, attempt),
    );
    return attempt;
  }

  void _remove<T>(String key, _NotificationPlatformAttempt<T> attempt) {
    if (identical(_attempts[key], attempt)) {
      _attempts.remove(key);
    }
  }
}

class _NotificationPlatformAttempt<T> {
  _NotificationPlatformAttempt(this.requestKey, Future<T> Function() operation)
    : future = Future<T>.sync(operation);

  final String requestKey;
  final Future<T> future;
}

Duration _boundedDuration(Duration requested, Duration maximum) {
  if (requested <= Duration.zero) return Duration.zero;
  return requested < maximum ? requested : maximum;
}

class NotificationExecutionBudget {
  NotificationExecutionBudget({
    required this.diagnostics,
    NotificationPlatformAttemptRegistry? attempts,
    Duration perAwaitLimit = const Duration(seconds: 2),
    Duration totalLimit = const Duration(seconds: 8),
  }) : attempts = attempts ?? NotificationPlatformAttemptRegistry(),
       perAwaitLimit = _boundedDuration(
         perAwaitLimit,
         const Duration(seconds: 2),
       ),
       totalLimit = _boundedDuration(totalLimit, const Duration(seconds: 8)),
       _startedAt = diagnostics.elapsed;

  final StartupPhaseDiagnostics diagnostics;
  final NotificationPlatformAttemptRegistry attempts;
  final Duration perAwaitLimit;
  final Duration totalLimit;
  final Duration _startedAt;
  var _terminated = false;

  Duration get elapsed {
    final value = diagnostics.elapsed - _startedAt;
    return value < Duration.zero ? Duration.zero : value;
  }

  Duration get remaining => totalLimit - elapsed;
  bool get exhausted => _terminated || remaining <= Duration.zero;

  Future<T> awaitPlatform<T>({
    required StartupPhase phase,
    required StartupDiagnosticOrigin origin,
    required String operationKey,
    required Future<T> Function() operation,
    String? targetKey,
    String? requestKey,
  }) async {
    if (exhausted) {
      _terminated = true;
      diagnostics.record(
        phase,
        StartupPhaseOutcome.deadlineExhausted,
        origin: origin,
        safeErrorCode: StartupSafeErrorCode.notificationDeadline,
      );
      throw const NotificationPlatformBoundaryException(
        StartupSafeErrorCode.notificationDeadline,
      );
    }
    final limit = remaining < perAwaitLimit ? remaining : perAwaitLimit;
    if (limit <= Duration.zero) {
      diagnostics.record(
        phase,
        StartupPhaseOutcome.deadlineExhausted,
        origin: origin,
        safeErrorCode: StartupSafeErrorCode.notificationDeadline,
      );
      throw const NotificationPlatformBoundaryException(
        StartupSafeErrorCode.notificationDeadline,
      );
    }

    diagnostics.record(phase, StartupPhaseOutcome.started, origin: origin);
    final startedAt = diagnostics.elapsed;
    late final _NotificationPlatformAttempt<T> attempt;
    try {
      attempt = attempts._obtain<T>(
        targetKey ?? operationKey,
        requestKey ?? operationKey,
        operation,
      );
    } on NotificationPlatformBoundaryException {
      _terminated = true;
      diagnostics.record(
        phase,
        StartupPhaseOutcome.deferredInFlight,
        origin: origin,
        safeErrorCode: StartupSafeErrorCode.platformCallInFlight,
      );
      rethrow;
    }
    final completer = Completer<T>();
    var decided = false;
    final timer = Timer(limit, () {
      if (decided) return;
      decided = true;
      _terminated = true;
      diagnostics.record(
        phase,
        StartupPhaseOutcome.timedOut,
        origin: origin,
        safeErrorCode: StartupSafeErrorCode.platformTimeout,
      );
      completer.completeError(
        const NotificationPlatformBoundaryException(
          StartupSafeErrorCode.platformTimeout,
        ),
      );
    });
    attempt.future.then<void>(
      (value) {
        if (decided) return;
        decided = true;
        timer.cancel();
        final callElapsed = diagnostics.elapsed - startedAt;
        if (callElapsed > limit || remaining < Duration.zero) {
          _terminated = true;
          diagnostics.record(
            phase,
            StartupPhaseOutcome.timedOut,
            origin: origin,
            safeErrorCode: StartupSafeErrorCode.platformTimeout,
          );
          completer.completeError(
            const NotificationPlatformBoundaryException(
              StartupSafeErrorCode.platformTimeout,
            ),
          );
          return;
        }
        diagnostics.record(
          phase,
          StartupPhaseOutcome.succeeded,
          origin: origin,
        );
        completer.complete(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (decided) return;
        decided = true;
        timer.cancel();
        diagnostics.record(
          phase,
          StartupPhaseOutcome.failed,
          origin: origin,
          safeErrorCode: StartupSafeErrorCode.platformFailure,
        );
        completer.completeError(error, stackTrace);
      },
    );
    return completer.future;
  }
}

class NotificationExecutionContext {
  const NotificationExecutionContext({
    required this.budget,
    required this.origin,
    this.platformPhase,
    this.operationScope,
  });

  final NotificationExecutionBudget budget;
  final StartupDiagnosticOrigin origin;
  final StartupPhase? platformPhase;
  final String? operationScope;

  NotificationExecutionContext forPlatformCall(
    StartupPhase phase,
    String scope,
  ) => NotificationExecutionContext(
    budget: budget,
    origin: origin,
    platformPhase: phase,
    operationScope: scope,
  );
}

final Object _notificationExecutionContextKey = Object();

NotificationExecutionContext? get currentNotificationExecutionContext =>
    Zone.current[_notificationExecutionContextKey]
        as NotificationExecutionContext?;

Future<T> runWithNotificationExecution<T>(
  NotificationExecutionContext context,
  Future<T> Function() action,
) {
  return runZoned(
    action,
    zoneValues: {_notificationExecutionContextKey: context},
  );
}

Future<T> runWithoutNotificationExecution<T>(Future<T> Function() action) {
  return runZoned(action, zoneValues: {_notificationExecutionContextKey: null});
}

/// Marks gateways whose individual native awaits cooperate with the current
/// notification execution context. Other implementations are bounded as one
/// opaque platform call by the application layer.
abstract interface class DeadlineAwareReminderNotificationGateway {}

class LocalNotificationRequest {
  LocalNotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAtUtc,
  }) {
    if (id.trim().isEmpty || title.trim().isEmpty || body.trim().isEmpty) {
      throw const TimeContractViolation(
        'notification fields must not be empty',
      );
    }
    CseTimeCodec.decodeCanonicalUtc(scheduledAtUtc);
  }

  final String id;
  final String title;
  final String body;
  final String scheduledAtUtc;
}

abstract interface class LocalNotificationPort {
  Future<void> schedule(LocalNotificationRequest request);
}

enum NotificationScheduleOutcome { scheduled, denied, invalid, unavailable }

class SafeNotificationScheduler {
  const SafeNotificationScheduler({
    required this.permissions,
    required this.notifications,
    required this.clock,
  });

  final SafeCapabilityService permissions;
  final LocalNotificationPort notifications;
  final DateTime Function() clock;

  Future<NotificationScheduleOutcome> schedule(
    LocalNotificationRequest request,
  ) async {
    final scheduledAt = CseTimeCodec.decodeCanonicalUtc(request.scheduledAtUtc);
    final now = clock();
    if (!now.isUtc || !scheduledAt.isAfter(now)) {
      return NotificationScheduleOutcome.invalid;
    }
    final permission = await permissions.request(DeviceCapability.notification);
    if (permission == CapabilityStatus.denied) {
      return NotificationScheduleOutcome.denied;
    }
    if (permission == CapabilityStatus.unavailable) {
      return NotificationScheduleOutcome.unavailable;
    }
    try {
      await notifications.schedule(request);
      return NotificationScheduleOutcome.scheduled;
    } on Object {
      return NotificationScheduleOutcome.unavailable;
    }
  }
}

enum NotificationPermissionState {
  granted,
  denied,
  channelDisabled,
  exactAlarmDenied,
  unavailable,
}

class ReminderPlatformDiagnostic {
  const ReminderPlatformDiagnostic({
    required this.permissionState,
    required this.channelState,
    required this.exactAlarmState,
    required this.batteryOptimizationState,
    required this.backgroundRestrictionState,
    required this.standbyBucket,
    required this.bootRescheduleState,
    required this.bootRescheduledAtUtc,
    required this.activeNotificationPostedAtUtc,
  });

  const ReminderPlatformDiagnostic.unavailable()
    : permissionState = 'unavailable',
      channelState = 'unavailable',
      exactAlarmState = 'unavailable',
      batteryOptimizationState = 'unavailable',
      backgroundRestrictionState = 'unavailable',
      standbyBucket = 'unavailable',
      bootRescheduleState = 'unavailable',
      bootRescheduledAtUtc = null,
      activeNotificationPostedAtUtc = null;

  final String permissionState;
  final String channelState;
  final String exactAlarmState;
  final String batteryOptimizationState;
  final String backgroundRestrictionState;
  final String standbyBucket;
  final String bootRescheduleState;
  final String? bootRescheduledAtUtc;
  final String? activeNotificationPostedAtUtc;
}

abstract interface class ReminderDeliveryControl {
  Future<void> scheduleInexactFallback(ReminderNotificationRequest request);

  Future<ReminderPlatformDiagnostic> deliveryDiagnostic(int platformId);

  Future<void> openNotificationSettings();

  Future<void> openBatteryOptimizationSettings();
}

class ReminderNotificationRequest {
  ReminderNotificationRequest({
    required this.platformId,
    required this.reminderId,
    required this.title,
    required this.body,
    required this.scheduledAtUtc,
    this.repeatIntervalMinutes,
  }) {
    if (platformId < 1 || platformId > 2147483647) {
      throw const TimeContractViolation('invalid platform notification id');
    }
    if (!RecordId.isUuid(reminderId) ||
        title.trim().isEmpty ||
        body.trim().isEmpty) {
      throw const TimeContractViolation('invalid reminder notification');
    }
    CseTimeCodec.decodeCanonicalUtc(scheduledAtUtc);
    if (repeatIntervalMinutes != null && repeatIntervalMinutes != 60) {
      throw const TimeContractViolation('invalid reminder repeat interval');
    }
  }

  final int platformId;
  final String reminderId;
  final String title;
  final String body;
  final String scheduledAtUtc;
  final int? repeatIntervalMinutes;
}

String reminderNotificationRequestFingerprint(
  ReminderNotificationRequest request, {
  required bool exact,
}) {
  String part(String value) => '${value.length}:$value';
  final canonical =
      'schedule:${exact ? 'exact' : 'inexact'}:'
      '${part(request.reminderId)}:${part(request.scheduledAtUtc)}:'
      '${request.repeatIntervalMinutes ?? 0}:${part(request.title)}:'
      '${part(request.body)}';
  return hashes.sha256.convert(utf8.encode(canonical)).toString();
}

class PendingReminderNotification {
  const PendingReminderNotification({
    required this.platformId,
    required this.reminderId,
    this.scheduleComplete = true,
    this.resumeSupported = false,
    this.requestFingerprint,
  });

  final int platformId;
  final String? reminderId;
  final bool scheduleComplete;
  final bool resumeSupported;
  final String? requestFingerprint;
}

abstract interface class FingerprintedReminderNotificationGateway {}

enum ReminderNotificationAction { openDetail, snooze }

class ReminderNotificationIntent {
  const ReminderNotificationIntent({
    required this.reminderId,
    this.action = ReminderNotificationAction.openDetail,
  });

  final String reminderId;
  final ReminderNotificationAction action;
}

/// Optional foreground navigation capability; never performs a mutation.
abstract interface class ReminderNotificationIntentSource {
  ReminderNotificationIntent? takeInitialNotificationIntent();

  Stream<ReminderNotificationIntent> get notificationIntents;
}

abstract interface class ReminderNotificationGateway {
  int get maximumPendingNotifications;

  int pendingNotificationSlotCost(int? repeatIntervalMinutes);

  String? get initialTapReminderId;

  Stream<String> get notificationTaps;

  Future<void> initialize();

  Future<NotificationPermissionState> permissionStatus();

  Future<NotificationPermissionState> requestPermission();

  Future<List<PendingReminderNotification>> pendingNotifications();

  Future<void> schedule(ReminderNotificationRequest request);

  Future<void> cancel(int platformId);
}

class UnavailableReminderNotificationGateway
    implements ReminderNotificationGateway {
  const UnavailableReminderNotificationGateway();

  @override
  int get maximumPendingNotifications => 0;

  @override
  int pendingNotificationSlotCost(int? repeatIntervalMinutes) => 1;

  @override
  String? get initialTapReminderId => null;

  @override
  Stream<String> get notificationTaps => const Stream<String>.empty();

  @override
  Future<void> cancel(int platformId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<List<PendingReminderNotification>> pendingNotifications() async =>
      const [];

  @override
  Future<NotificationPermissionState> permissionStatus() async =>
      NotificationPermissionState.unavailable;

  @override
  Future<NotificationPermissionState> requestPermission() async =>
      NotificationPermissionState.unavailable;

  @override
  Future<void> schedule(ReminderNotificationRequest request) async {
    throw StateError('notifications unavailable');
  }
}

class FlutterReminderNotificationGateway
    implements
        ReminderNotificationGateway,
        ReminderDeliveryControl,
        ReminderNotificationIntentSource,
        DeadlineAwareReminderNotificationGateway,
        FingerprintedReminderNotificationGateway {
  FlutterReminderNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    MethodChannel? deliveryChannel,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _deliveryChannel =
           deliveryChannel ??
           const MethodChannel(
             'com.faliardic.chiefsiteengineer/reminder_delivery',
           );

  static const _payloadPrefix = 'reminder:';
  static const _channelId = 'cse_reminders';
  static const _channelName = 'Hatırlatıcılar';
  static const _channelDescription =
      'Chief Site Engineer tek seferlik hatırlatıcıları';
  static const rollingRepeatOccurrenceCount = 24;
  static const snoozeActionId = 'cse_reminder_snooze';

  final FlutterLocalNotificationsPlugin _plugin;
  final MethodChannel _deliveryChannel;
  final StreamController<String> _taps = StreamController<String>.broadcast();
  final _intents = StreamController<ReminderNotificationIntent>.broadcast();
  ReminderNotificationIntent? _initialIntent;
  final Map<int, _IosRollingProgress> _iosRollingProgress = {};
  bool _pluginInitialized = false;
  bool _initialized = false;
  String? _initialTapReminderId;
  Future<bool?>? _initializeAttempt;
  Future<NotificationAppLaunchDetails?>? _launchDetailsAttempt;
  int? _launchDetailsIntentSequence;
  var _intentSequence = 0;
  var _launchIntentHandled = false;
  final NotificationPlatformAttemptRegistry _standaloneAttempts =
      NotificationPlatformAttemptRegistry();

  Future<T> _nativeAwait<T>(
    StartupPhase phase,
    String operationKey,
    Future<T> Function() operation, {
    String? targetKey,
    String? requestKey,
    bool usePlatformPhase = false,
    bool includeOperationScope = false,
  }) {
    final inherited = currentNotificationExecutionContext;
    if (inherited != null) {
      final effectivePhase = usePlatformPhase
          ? inherited.platformPhase ?? phase
          : phase;
      final gatewayPrefix = 'flutter:${identityHashCode(this)}:';
      return inherited.budget.awaitPlatform<T>(
        phase: effectivePhase,
        origin: inherited.origin,
        operationKey: '$gatewayPrefix$operationKey',
        targetKey: '$gatewayPrefix${targetKey ?? operationKey}',
        requestKey:
            '$gatewayPrefix${requestKey ?? operationKey}'
            '${includeOperationScope ? ':${inherited.operationScope ?? 'direct'}' : ''}',
        operation: operation,
      );
    }
    final diagnostics = StartupPhaseDiagnostics();
    final context = NotificationExecutionContext(
      budget: NotificationExecutionBudget(
        diagnostics: diagnostics,
        attempts: _standaloneAttempts,
      ),
      origin: StartupDiagnosticOrigin.backgroundReconciliation,
    );
    return runWithNotificationExecution(
      context,
      () => _nativeAwait<T>(
        phase,
        operationKey,
        operation,
        targetKey: targetKey,
        requestKey: requestKey,
        usePlatformPhase: usePlatformPhase,
        includeOperationScope: includeOperationScope,
      ),
    );
  }

  @override
  int get maximumPendingNotifications =>
      defaultTargetPlatform == TargetPlatform.iOS ? 60 : 256;

  @override
  int pendingNotificationSlotCost(int? repeatIntervalMinutes) =>
      defaultTargetPlatform == TargetPlatform.iOS &&
          repeatIntervalMinutes != null
      ? rollingRepeatOccurrenceCount
      : 1;

  @override
  String? get initialTapReminderId => _initialTapReminderId;

  @override
  Stream<String> get notificationTaps => _taps.stream;

  @override
  Stream<ReminderNotificationIntent> get notificationIntents => _intents.stream;

  @override
  ReminderNotificationIntent? takeInitialNotificationIntent() {
    final initial = _initialIntent;
    _initialIntent = null;
    _initialTapReminderId = null;
    return initial;
  }

  void _deliverIntent(ReminderNotificationIntent intent) {
    _intentSequence += 1;
    if (_intents.hasListener) {
      _intents.add(intent);
      _initialIntent = null;
      _initialTapReminderId = null;
    } else {
      _initialIntent = intent;
      _initialTapReminderId =
          intent.action == ReminderNotificationAction.openDetail
          ? intent.reminderId
          : null;
    }
    if (intent.action == ReminderNotificationAction.openDetail) {
      _taps.add(intent.reminderId);
    }
  }

  ReminderNotificationIntent? _parseResponse(NotificationResponse? response) {
    if (response == null) return null;
    final reminderId = _parsePayload(response.payload);
    if (reminderId == null) return null;
    final action = switch (response.notificationResponseType) {
      NotificationResponseType.selectedNotification =>
        ReminderNotificationAction.openDetail,
      NotificationResponseType.selectedNotificationAction
          when defaultTargetPlatform == TargetPlatform.android &&
              response.actionId == snoozeActionId =>
        ReminderNotificationAction.snooze,
      _ => null,
    };
    return action == null
        ? null
        : ReminderNotificationIntent(reminderId: reminderId, action: action);
  }

  Future<NotificationAppLaunchDetails?> _launchDetailsFuture() {
    final existing = _launchDetailsAttempt;
    if (existing != null) return existing;
    _launchDetailsIntentSequence = _intentSequence;
    _launchIntentHandled = false;
    final attempt = _plugin.getNotificationAppLaunchDetails();
    _launchDetailsAttempt = attempt;
    attempt.then<void>(
      _handleLaunchDetails,
      onError: (Object _, StackTrace _) {
        if (identical(_launchDetailsAttempt, attempt)) {
          _launchDetailsAttempt = null;
          _launchDetailsIntentSequence = null;
        }
      },
    );
    return attempt;
  }

  void _handleLaunchDetails(NotificationAppLaunchDetails? launch) {
    if (_launchIntentHandled) return;
    _launchIntentHandled = true;
    final intent = (launch?.didNotificationLaunchApp ?? false)
        ? _parseResponse(launch?.notificationResponse)
        : null;
    if (intent != null && _intentSequence == _launchDetailsIntentSequence) {
      _deliverIntent(intent);
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Europe/Istanbul'));
    if (!_pluginInitialized) {
      bool? initialized;
      try {
        initialized = await _nativeAwait<bool?>(
          StartupPhase.pluginInitialize,
          'initialize',
          () => _initializeAttempt ??= _plugin.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
            ),
            onDidReceiveNotificationResponse: (response) {
              final intent = _parseResponse(response);
              if (intent == null) return;
              _deliverIntent(intent);
            },
          ),
        );
      } on NotificationPlatformBoundaryException {
        rethrow;
      } on Object {
        _initializeAttempt = null;
        rethrow;
      }
      _initializeAttempt = null;
      if (initialized != true) {
        throw StateError('notification initialization failed');
      }
      _pluginInitialized = true;
    }
    try {
      await _nativeAwait<NotificationAppLaunchDetails?>(
        StartupPhase.launchDetails,
        'launch-details',
        _launchDetailsFuture,
      );
    } on NotificationPlatformBoundaryException {
      rethrow;
    } on Object {
      _launchDetailsAttempt = null;
      rethrow;
    }
    _initialized = true;
  }

  @override
  Future<NotificationPermissionState> permissionStatus() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await _nativeAwait(
        StartupPhase.permissionStatus,
        'notifications-enabled',
        () async => android?.areNotificationsEnabled(),
      );
      if (enabled != true) return NotificationPermissionState.denied;
      final channels = await _nativeAwait(
        StartupPhase.permissionStatus,
        'notification-channels',
        () async => android?.getNotificationChannels(),
      );
      final channel = channels
          ?.where((item) => item.id == _channelId)
          .firstOrNull;
      if (channel?.importance == Importance.none) {
        return NotificationPermissionState.channelDisabled;
      }
      final exact = await _nativeAwait(
        StartupPhase.permissionStatus,
        'exact-notification-status',
        () async => android?.canScheduleExactNotifications(),
      );
      if (exact != true) return NotificationPermissionState.exactAlarmDenied;
      return NotificationPermissionState.granted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final options = await _nativeAwait(
        StartupPhase.permissionStatus,
        'ios-permission-status',
        () async => ios?.checkPermissions(),
      );
      if (options == null) return NotificationPermissionState.unavailable;
      return options.isEnabled
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    return NotificationPermissionState.unavailable;
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      if (granted != true) return NotificationPermissionState.denied;
      final channels = await _nativeAwait(
        StartupPhase.permissionStatus,
        'notification-channels',
        () async => android?.getNotificationChannels(),
      );
      final channel = channels
          ?.where((item) => item.id == _channelId)
          .firstOrNull;
      if (channel?.importance == Importance.none) {
        return NotificationPermissionState.channelDisabled;
      }
      final exact = await _nativeAwait(
        StartupPhase.permissionStatus,
        'exact-notification-status',
        () async => android?.canScheduleExactNotifications(),
      );
      if (exact != true) {
        final requested = await android?.requestExactAlarmsPermission();
        if (requested != true) {
          return NotificationPermissionState.exactAlarmDenied;
        }
      }
      return NotificationPermissionState.granted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    return NotificationPermissionState.unavailable;
  }

  @override
  Future<List<PendingReminderNotification>> pendingNotifications() async {
    await initialize();
    final pending = await _nativeAwait(
      StartupPhase.pendingInitial,
      'pending',
      _plugin.pendingNotificationRequests,
      targetKey: 'pending-state',
      requestKey: 'pending',
      usePlatformPhase: true,
      includeOperationScope: true,
    );
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return pending
          .map(
            (item) => PendingReminderNotification(
              platformId: item.id,
              reminderId: _parsePayload(item.payload),
              requestFingerprint: _parseRequestFingerprint(item.payload),
            ),
          )
          .toList(growable: false);
    }
    final logical = <PendingReminderNotification>[];
    final rolling = <int, _RollingPendingGroup>{};
    for (final item in pending) {
      final metadata = _parseRollingPayload(item.payload);
      if (metadata == null) {
        logical.add(
          PendingReminderNotification(
            platformId: item.id,
            reminderId: _parsePayload(item.payload),
            requestFingerprint: _parseRequestFingerprint(item.payload),
          ),
        );
        continue;
      }
      rolling
          .putIfAbsent(
            metadata.rootPlatformId,
            () => _RollingPendingGroup(metadata.rootPlatformId),
          )
          .add(metadata);
    }
    for (final group in rolling.values) {
      final progress = _iosRollingProgress[group.rootPlatformId];
      progress?.refreshFrom(group);
      final item = group.toPending(
        resumeSupported: group.valid && group.requestFingerprint != null,
      );
      if (item.scheduleComplete) {
        _iosRollingProgress.remove(group.rootPlatformId);
      }
      logical.add(item);
    }
    logical.sort((left, right) => left.platformId.compareTo(right.platformId));
    return logical;
  }

  @override
  Future<void> schedule(ReminderNotificationRequest request) async {
    await _schedule(request, exact: true);
  }

  @override
  Future<void> scheduleInexactFallback(
    ReminderNotificationRequest request,
  ) async {
    await _schedule(request, exact: false);
  }

  String _scheduleRequestKey(
    ReminderNotificationRequest request, {
    required bool exact,
  }) => reminderNotificationRequestFingerprint(request, exact: exact);

  Future<void> _schedule(
    ReminderNotificationRequest request, {
    required bool exact,
  }) async {
    await initialize();
    final instant = CseTimeCodec.decodeCanonicalUtc(request.scheduledAtUtc);
    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction(
            snoozeActionId,
            'Ertele',
            showsUserInterface: true,
            cancelNotification: false,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(),
    );
    if (request.repeatIntervalMinutes case final minutes?) {
      final interval = Duration(minutes: minutes);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _scheduleIosRolling(
          request,
          instant,
          interval,
          details,
          exact: exact,
        );
        return;
      }
      await _nativeAwait<void>(
        exact ? StartupPhase.schedule : StartupPhase.inexactFallback,
        'repeat:${request.platformId}',
        () => withClock(
          Clock.fixed(instant),
          () => _plugin.periodicallyShowWithDuration(
            id: request.platformId,
            title: request.title,
            body: request.body,
            repeatDurationInterval: interval,
            notificationDetails: details,
            androidScheduleMode: exact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
            payload: _requestPayload(request, exact: exact),
          ),
        ),
        targetKey: 'notification:${request.platformId}',
        requestKey: _scheduleRequestKey(request, exact: exact),
        usePlatformPhase: true,
      );
      return;
    }
    await _nativeAwait<void>(
      exact ? StartupPhase.schedule : StartupPhase.inexactFallback,
      'one-time:${request.platformId}',
      () => _plugin.zonedSchedule(
        id: request.platformId,
        title: request.title,
        body: request.body,
        scheduledDate: timezone.TZDateTime.from(instant, timezone.local),
        notificationDetails: details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: _requestPayload(request, exact: exact),
      ),
      targetKey: 'notification:${request.platformId}',
      requestKey: _scheduleRequestKey(request, exact: exact),
      usePlatformPhase: true,
    );
  }

  @override
  Future<void> cancel(int platformId) async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _cancelIosRollingGroup(platformId);
    }
    await _nativeAwait<void>(
      StartupPhase.cancel,
      'root:$platformId',
      () => _plugin.cancel(id: platformId),
      targetKey: 'notification:$platformId',
      requestKey: 'cancel',
      usePlatformPhase: true,
    );
  }

  @override
  Future<ReminderPlatformDiagnostic> deliveryDiagnostic(int platformId) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      final permission = await permissionStatus();
      return ReminderPlatformDiagnostic(
        permissionState: permission.name,
        channelState: 'not_applicable',
        exactAlarmState: 'not_applicable',
        batteryOptimizationState: 'not_applicable',
        backgroundRestrictionState: 'not_applicable',
        standbyBucket: 'not_applicable',
        bootRescheduleState: 'not_applicable',
        bootRescheduledAtUtc: null,
        activeNotificationPostedAtUtc: null,
      );
    }
    try {
      final raw = await _nativeAwait(
        StartupPhase.permissionStatus,
        'delivery-diagnostic:$platformId',
        () => _deliveryChannel.invokeMapMethod<String, Object?>(
          'getPlatformStatus',
          {'platformId': platformId},
        ),
        targetKey: 'delivery-diagnostic:$platformId',
        requestKey: 'status:$platformId',
      );
      if (raw == null) return const ReminderPlatformDiagnostic.unavailable();
      return ReminderPlatformDiagnostic(
        permissionState: raw['permissionState'] as String? ?? 'unavailable',
        channelState: raw['channelState'] as String? ?? 'unavailable',
        exactAlarmState: raw['exactAlarmState'] as String? ?? 'unavailable',
        batteryOptimizationState:
            raw['batteryOptimizationState'] as String? ?? 'unavailable',
        backgroundRestrictionState:
            raw['backgroundRestrictionState'] as String? ?? 'unavailable',
        standbyBucket: raw['standbyBucket'] as String? ?? 'unavailable',
        bootRescheduleState:
            raw['bootRescheduleState'] as String? ?? 'unavailable',
        bootRescheduledAtUtc: raw['bootRescheduledAtUtc'] as String?,
        activeNotificationPostedAtUtc:
            raw['activeNotificationPostedAtUtc'] as String?,
      );
    } on Object {
      return const ReminderPlatformDiagnostic.unavailable();
    }
  }

  @override
  Future<void> openNotificationSettings() async {
    await _deliveryChannel.invokeMethod<void>('openNotificationSettings');
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {
    await _deliveryChannel.invokeMethod<void>(
      'openBatteryOptimizationSettings',
    );
  }

  Future<void> _scheduleIosRolling(
    ReminderNotificationRequest request,
    DateTime dueAt,
    Duration interval,
    NotificationDetails details, {
    required bool exact,
  }) async {
    final requestKey = _scheduleRequestKey(request, exact: exact);
    var pending = await _nativeAwait(
      StartupPhase.pendingInitial,
      'pending',
      _plugin.pendingNotificationRequests,
      targetKey: 'pending-state',
      requestKey: 'ios-rolling:${request.platformId}:$requestKey',
    );
    final observedSlots = <int>{};
    DateTime? observedFirstOccurrence;
    var hasRollingEntries = false;
    var nativePrefixMatches = true;
    for (final item in pending) {
      final metadata = _parseRollingPayload(item.payload);
      if (metadata?.rootPlatformId != request.platformId) continue;
      hasRollingEntries = true;
      observedFirstOccurrence ??= metadata!.firstOccurrence;
      if (metadata!.reminderId != request.reminderId ||
          metadata.requestFingerprint != requestKey ||
          metadata.firstOccurrence != observedFirstOccurrence ||
          metadata.count != rollingRepeatOccurrenceCount ||
          metadata.slot >= metadata.count ||
          item.id != _rollingPlatformId(request.platformId, metadata.slot) ||
          !observedSlots.add(metadata.slot)) {
        nativePrefixMatches = false;
      }
    }
    nativePrefixMatches = hasRollingEntries && nativePrefixMatches;
    var progress = _iosRollingProgress[request.platformId];
    if (nativePrefixMatches) {
      progress = _IosRollingProgress(
        requestKey: requestKey,
        reminderId: request.reminderId,
        firstOccurrence: observedFirstOccurrence!,
      )..slots.addAll(observedSlots);
      _iosRollingProgress[request.platformId] = progress;
    } else if (progress == null ||
        progress.requestKey != requestKey ||
        hasRollingEntries) {
      if (hasRollingEntries) {
        await _cancelIosRollingGroup(request.platformId);
        pending = pending
            .where(
              (item) =>
                  _parseRollingPayload(item.payload)?.rootPlatformId !=
                  request.platformId,
            )
            .toList(growable: false);
      }
      await _nativeAwait<void>(
        StartupPhase.cancel,
        'ios-root:${request.platformId}',
        () => _plugin.cancel(id: request.platformId),
        targetKey: 'notification:${request.platformId}',
        requestKey: 'cancel',
        usePlatformPhase: true,
      );
      progress = _IosRollingProgress(
        requestKey: requestKey,
        reminderId: request.reminderId,
        firstOccurrence: _firstFutureOccurrence(
          dueAt,
          interval,
          clock.now().toUtc(),
        ),
      );
      _iosRollingProgress[request.platformId] = progress;
    } else {
      progress.slots.clear();
    }
    final currentProgress = progress;
    final occupiedIds = pending.map((item) => item.id).toSet();
    final scheduledIds = <int>[];
    try {
      for (var slot = 0; slot < rollingRepeatOccurrenceCount; slot += 1) {
        final physicalId = _rollingPlatformId(request.platformId, slot);
        if (currentProgress.slots.contains(slot)) continue;
        if (occupiedIds.contains(physicalId)) {
          throw StateError('rolling notification id collision');
        }
        final scheduledAt = currentProgress.firstOccurrence.add(
          interval * slot,
        );
        await _nativeAwait<void>(
          exact ? StartupPhase.schedule : StartupPhase.inexactFallback,
          'ios-slot:$physicalId',
          () => _plugin.zonedSchedule(
            id: physicalId,
            title: request.title,
            body: request.body,
            scheduledDate: timezone.TZDateTime.from(
              scheduledAt,
              timezone.local,
            ),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: _rollingPayload(
              request,
              slot,
              requestKey,
              currentProgress.firstOccurrence,
            ),
          ),
          targetKey: 'notification:$physicalId',
          requestKey: '$requestKey:slot:$slot:${scheduledAt.toIso8601String()}',
          usePlatformPhase: true,
        );
        scheduledIds.add(physicalId);
        currentProgress.slots.add(slot);
      }
      _iosRollingProgress.remove(request.platformId);
    } on NotificationPlatformBoundaryException {
      // The verified prefix remains visible; a later bounded reconciliation
      // inspects native truth before continuing or rolling it back.
      rethrow;
    } on Object {
      for (final physicalId in scheduledIds) {
        await _nativeAwait<void>(
          StartupPhase.cancel,
          'ios-rollback:$physicalId',
          () => _plugin.cancel(id: physicalId),
          targetKey: 'notification:$physicalId',
          requestKey: 'cancel',
          usePlatformPhase: true,
        );
        currentProgress.slots.removeWhere(
          (slot) => _rollingPlatformId(request.platformId, slot) == physicalId,
        );
      }
      rethrow;
    }
  }

  Future<void> _cancelIosRollingGroup(int rootPlatformId) async {
    final pending = await _nativeAwait(
      StartupPhase.pendingInitial,
      'pending',
      _plugin.pendingNotificationRequests,
    );
    final physicalIds = pending
        .where(
          (item) =>
              _parseRollingPayload(item.payload)?.rootPlatformId ==
              rootPlatformId,
        )
        .map((item) => item.id)
        .toList(growable: false);
    for (final physicalId in physicalIds) {
      await _nativeAwait<void>(
        StartupPhase.cancel,
        'ios-physical:$physicalId',
        () => _plugin.cancel(id: physicalId),
        targetKey: 'notification:$physicalId',
        requestKey: 'cancel',
        usePlatformPhase: true,
      );
    }
    _iosRollingProgress.remove(rootPlatformId);
  }

  DateTime _firstFutureOccurrence(
    DateTime dueAt,
    Duration interval,
    DateTime now,
  ) {
    if (dueAt.isAfter(now)) return dueAt;
    final elapsedIntervals =
        now.difference(dueAt).inMilliseconds ~/ interval.inMilliseconds;
    return dueAt.add(interval * (elapsedIntervals + 1));
  }

  int _rollingPlatformId(int rootPlatformId, int slot) {
    const maximumPositiveId = 0x7fffffff;
    const slotStride = 104729;
    final positive =
        ((rootPlatformId - 1 + slot * slotStride) % maximumPositiveId) + 1;
    return -positive;
  }

  String _requestPayload(
    ReminderNotificationRequest request, {
    required bool exact,
  }) =>
      '$_payloadPrefix${request.reminderId}'
      '|request:${_scheduleRequestKey(request, exact: exact)}';

  String _rollingPayload(
    ReminderNotificationRequest request,
    int slot,
    String requestFingerprint,
    DateTime firstOccurrence,
  ) =>
      '$_payloadPrefix${request.reminderId}'
      '|rolling:${request.platformId}:$slot:$rollingRepeatOccurrenceCount'
      '|first:${CseTimeCodec.encodeUtc(firstOccurrence)}'
      '|request:$requestFingerprint';

  String? _parsePayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    final reminderId = payload
        .substring(_payloadPrefix.length)
        .split('|')
        .first;
    return RecordId.isUuid(reminderId) ? reminderId : null;
  }

  String? _parseRequestFingerprint(String? payload) {
    if (payload == null) return null;
    for (final part in payload.split('|')) {
      if (!part.startsWith('request:')) continue;
      final value = part.substring('request:'.length);
      return RegExp(r'^[0-9a-f]{64}$').hasMatch(value) ? value : null;
    }
    return null;
  }

  _RollingPayload? _parseRollingPayload(String? payload) {
    final reminderId = _parsePayload(payload);
    if (reminderId == null || payload == null) return null;
    final parts = payload.split('|');
    if (parts.length != 4 ||
        !parts[1].startsWith('rolling:') ||
        !parts[2].startsWith('first:') ||
        !parts[3].startsWith('request:')) {
      return null;
    }
    final values = parts[1].substring('rolling:'.length).split(':');
    if (values.length != 3) return null;
    final rootPlatformId = int.tryParse(values[0]);
    final slot = int.tryParse(values[1]);
    final count = int.tryParse(values[2]);
    final requestFingerprint = _parseRequestFingerprint(payload);
    final firstOccurrence = DateTime.tryParse(
      parts[2].substring('first:'.length),
    )?.toUtc();
    if (rootPlatformId == null ||
        rootPlatformId < 1 ||
        rootPlatformId > 0x7fffffff ||
        slot == null ||
        slot < 0 ||
        count == null ||
        count < 1 ||
        firstOccurrence == null ||
        requestFingerprint == null) {
      return null;
    }
    return _RollingPayload(
      reminderId: reminderId,
      rootPlatformId: rootPlatformId,
      slot: slot,
      count: count,
      firstOccurrence: firstOccurrence,
      requestFingerprint: requestFingerprint,
    );
  }
}

class _RollingPayload {
  const _RollingPayload({
    required this.reminderId,
    required this.rootPlatformId,
    required this.slot,
    required this.count,
    required this.firstOccurrence,
    required this.requestFingerprint,
  });

  final String reminderId;
  final int rootPlatformId;
  final int slot;
  final int count;
  final DateTime firstOccurrence;
  final String requestFingerprint;
}

class _RollingPendingGroup {
  _RollingPendingGroup(this.rootPlatformId);

  final int rootPlatformId;
  final Set<int> slots = <int>{};
  String? reminderId;
  String? requestFingerprint;
  DateTime? firstOccurrence;
  var entryCount = 0;
  var valid = true;

  void add(_RollingPayload payload) {
    entryCount += 1;
    reminderId ??= payload.reminderId;
    requestFingerprint ??= payload.requestFingerprint;
    firstOccurrence ??= payload.firstOccurrence;
    if (reminderId != payload.reminderId ||
        requestFingerprint != payload.requestFingerprint ||
        firstOccurrence != payload.firstOccurrence ||
        payload.count !=
            FlutterReminderNotificationGateway.rollingRepeatOccurrenceCount ||
        payload.slot >= payload.count) {
      valid = false;
    }
    slots.add(payload.slot);
  }

  PendingReminderNotification toPending({bool resumeSupported = false}) {
    final expectedCount =
        FlutterReminderNotificationGateway.rollingRepeatOccurrenceCount;
    return PendingReminderNotification(
      platformId: rootPlatformId,
      reminderId: valid ? reminderId : null,
      scheduleComplete:
          valid && entryCount == expectedCount && slots.length == expectedCount,
      resumeSupported: resumeSupported,
      requestFingerprint: valid ? requestFingerprint : null,
    );
  }
}

class _IosRollingProgress {
  _IosRollingProgress({
    required this.requestKey,
    required this.reminderId,
    required this.firstOccurrence,
  });

  final String requestKey;
  final String reminderId;
  final DateTime firstOccurrence;
  final Set<int> slots = <int>{};

  void refreshFrom(_RollingPendingGroup group) {
    if (!matches(group)) return;
    slots
      ..clear()
      ..addAll(group.slots);
  }

  bool matches(_RollingPendingGroup group) =>
      group.valid &&
      group.reminderId == reminderId &&
      group.requestFingerprint == requestKey;
}
