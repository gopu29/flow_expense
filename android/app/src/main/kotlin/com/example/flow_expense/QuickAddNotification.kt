package com.example.flow_expense

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build

/** Quiet, ongoing notification with an "Add expense" button. */
object QuickAddNotification {
    private const val CHANNEL_ID = "quick_add"
    private const val NOTIFICATION_ID = 7001

    fun show(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Quick add",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shortcut to add an expense from the notification shade"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }

        val openQuickAdd = PendingIntent.getActivity(
            context,
            0,
            QuickAddActivity.intent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_quick_add)
            .setContentTitle("Flow Expense")
            .setContentText("Tap to add an expense")
            .setContentIntent(openQuickAdd)
            .setOngoing(true)
            .setShowWhen(false)
            .addAction(
                Notification.Action.Builder(null, "Add expense", openQuickAdd).build(),
            )
            .build()
        manager.notify(NOTIFICATION_ID, notification)
    }

    fun hide(context: Context) {
        context.getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
    }
}
