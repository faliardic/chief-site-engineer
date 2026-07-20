package com.faliardic.chiefsiteengineer

import android.app.ActivityManager
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.Instant

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL =
            "com.faliardic.chiefsiteengineer/reminder_delivery"
        private const val REMINDER_CHANNEL = "cse_reminders"
        private const val BOOT_PREFS = "cse_reminder_boot_audit"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPlatformStatus" -> {
                    val platformId = call.argument<Int>("platformId")
                    result.success(platformStatus(platformId))
                }
                "openNotificationSettings" -> {
                    openSettings(
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        },
                    )
                    result.success(null)
                }
                "openBatteryOptimizationSettings" -> {
                    openSettings(
                        Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun platformStatus(platformId: Int?): Map<String, Any?> {
        val notifications =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val alarms = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        val activity = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val usage = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val channel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notifications.getNotificationChannel(REMINDER_CHANNEL)
        } else {
            null
        }
        val channelState = when {
            Build.VERSION.SDK_INT < Build.VERSION_CODES.O -> "not_applicable"
            channel == null -> "not_created"
            channel.importance == NotificationManager.IMPORTANCE_NONE -> "disabled"
            else -> "enabled"
        }
        val exactState = if (
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarms.canScheduleExactAlarms()
        ) {
            "granted"
        } else {
            "denied"
        }
        val activePostedAt = if (
            platformId != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
        ) {
            notifications.activeNotifications
                .firstOrNull { it.id == platformId }
                ?.postTime
                ?.let { Instant.ofEpochMilli(it).toString() }
        } else {
            null
        }
        val boot = getSharedPreferences(BOOT_PREFS, Context.MODE_PRIVATE)
        return mapOf(
            "permissionState" to
                if (notifications.areNotificationsEnabled()) "granted" else "denied",
            "channelState" to channelState,
            "exactAlarmState" to exactState,
            "batteryOptimizationState" to
                if (power.isIgnoringBatteryOptimizations(packageName)) {
                    "unrestricted"
                } else {
                    "optimized"
                },
            "backgroundRestrictionState" to
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
                    activity.isBackgroundRestricted
                ) {
                    "restricted"
                } else {
                    "allowed"
                },
            "standbyBucket" to
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    standbyBucketLabel(usage.appStandbyBucket)
                } else {
                    "unavailable"
                },
            "bootRescheduleState" to
                (boot.getString("state", null) ?: "not_observed"),
            "bootRescheduledAtUtc" to boot.getString("at_utc", null),
            "activeNotificationPostedAtUtc" to activePostedAt,
        )
    }

    private fun standbyBucketLabel(bucket: Int): String = when (bucket) {
        UsageStatsManager.STANDBY_BUCKET_ACTIVE -> "active"
        UsageStatsManager.STANDBY_BUCKET_WORKING_SET -> "working_set"
        UsageStatsManager.STANDBY_BUCKET_FREQUENT -> "frequent"
        UsageStatsManager.STANDBY_BUCKET_RARE -> "rare"
        UsageStatsManager.STANDBY_BUCKET_RESTRICTED -> "restricted"
        else -> "unknown"
    }

    private fun openSettings(intent: Intent) {
        val safeIntent = intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (safeIntent.resolveActivity(packageManager) != null) {
            startActivity(safeIntent)
            return
        }
        startActivity(
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            ),
        )
    }
}
