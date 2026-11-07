package com.example.flow_expense

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Dart bridge for the home screen widgets and the notification shortcut. */
object ShortcutsChannel {
    private const val CHANNEL = "com.example.flow_expense/android_shortcuts"
    const val NOTIFICATION_PERMISSION_REQUEST = 4101

    fun register(engine: FlutterEngine, activity: Activity) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgets" -> {
                    SpendWidgetData.save(
                        activity,
                        today = call.argument<String>("today") ?: "",
                        month = call.argument<String>("month") ?: "",
                    )
                    result.success(true)
                }
                "setNotificationEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (!enabled) {
                        QuickAddNotification.hide(activity)
                        result.success(true)
                    } else if (needsNotificationPermission(activity)) {
                        // MainActivity shows the notification once the user allows it.
                        activity.requestPermissions(
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            NOTIFICATION_PERMISSION_REQUEST,
                        )
                        result.success(false)
                    } else {
                        QuickAddNotification.show(activity)
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun needsNotificationPermission(activity: Activity): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
}
