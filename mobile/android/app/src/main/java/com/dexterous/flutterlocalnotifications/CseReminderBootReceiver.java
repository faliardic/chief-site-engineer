package com.dexterous.flutterlocalnotifications;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import androidx.annotation.Keep;

import java.time.Instant;

/** Reschedules plugin alarms and records only privacy-safe boot evidence. */
@Keep
public final class CseReminderBootReceiver extends BroadcastReceiver {
  private static final String PREFS = "cse_reminder_boot_audit";
  private static final String SCHEDULED_BOOT_RECEIVER_CLASS =
      "com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver";

  @Override
  public void onReceive(Context context, Intent intent) {
    String action = intent.getAction();
    if (!isSupported(action)) {
      return;
    }
    String state;
    try {
      Class<? extends BroadcastReceiver> receiverClass =
          Class.forName(SCHEDULED_BOOT_RECEIVER_CLASS)
              .asSubclass(BroadcastReceiver.class);
      BroadcastReceiver receiver =
          receiverClass.getDeclaredConstructor().newInstance();
      receiver.onReceive(context, intent);
      state = "completed";
    } catch (ReflectiveOperationException | RuntimeException error) {
      state = "failed";
    }
    SharedPreferences preferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    preferences
        .edit()
        .putString("state", state)
        .putString("at_utc", Instant.now().toString())
        .apply();
  }

  private static boolean isSupported(String action) {
    return Intent.ACTION_BOOT_COMPLETED.equals(action)
        || Intent.ACTION_MY_PACKAGE_REPLACED.equals(action)
        || "android.intent.action.QUICKBOOT_POWERON".equals(action)
        || "com.htc.intent.action.QUICKBOOT_POWERON".equals(action);
  }
}
