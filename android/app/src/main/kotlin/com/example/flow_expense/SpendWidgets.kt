package com.example.flow_expense

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/** Spend totals the Flutter app hands to the widgets. */
object SpendWidgetData {
    private const val PREFS = "flow_expense_widgets"

    fun save(context: Context, today: String, month: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("today", today)
            .putString("month", month)
            .apply()
        refreshAll(context)
    }

    fun today(context: Context): String =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("today", null) ?: "—"

    fun month(context: Context): String =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("month", null) ?: "—"

    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        listOf(QuickAddWidget::class.java, SpendSummaryWidget::class.java).forEach { cls ->
            val ids = manager.getAppWidgetIds(ComponentName(context, cls))
            if (ids.isNotEmpty()) {
                context.sendBroadcast(
                    Intent(context, cls)
                        .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                        .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
                )
            }
        }
    }

    fun quickAddPendingIntent(context: Context): PendingIntent =
        PendingIntent.getActivity(
            context,
            2,
            QuickAddActivity.intent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    fun openAppPendingIntent(context: Context): PendingIntent =
        PendingIntent.getActivity(
            context,
            3,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}

/** Small widget: one "+ Add expense" button. */
class QuickAddWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val views = RemoteViews(context.packageName, R.layout.widget_quick_add).apply {
            setOnClickPendingIntent(R.id.widget_root, SpendWidgetData.quickAddPendingIntent(context))
        }
        ids.forEach { manager.updateAppWidget(it, views) }
    }
}

/** Medium widget: this month's and today's spend, plus an add button. */
class SpendSummaryWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val views = RemoteViews(context.packageName, R.layout.widget_spend_summary).apply {
            setTextViewText(R.id.widget_month_amount, SpendWidgetData.month(context))
            setTextViewText(R.id.widget_today_amount, "Today  ${SpendWidgetData.today(context)}")
            setOnClickPendingIntent(R.id.widget_root, SpendWidgetData.openAppPendingIntent(context))
            setOnClickPendingIntent(R.id.widget_add_button, SpendWidgetData.quickAddPendingIntent(context))
        }
        ids.forEach { manager.updateAppWidget(it, views) }
    }
}
