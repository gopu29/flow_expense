package com.example.flow_expense

import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine

/**
 * See-through screen that shows only the add-expense sheet on top of
 * whatever app the user is in. It runs the Dart `quickAddMain` entry point.
 *
 * Every Android shortcut (icon shortcut, Quick Settings tile, notification,
 * widgets, accessibility button, Samsung RegiStar back tap) opens this.
 */
class QuickAddActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String = "quickAddMain"

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ShortcutsChannel.register(flutterEngine, this)
    }

    companion object {
        const val ACTION_QUICK_ADD = "com.example.flow_expense.QUICK_ADD"

        fun intent(context: Context): Intent =
            Intent(context, QuickAddActivity::class.java).apply {
                action = ACTION_QUICK_ADD
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }
    }
}
