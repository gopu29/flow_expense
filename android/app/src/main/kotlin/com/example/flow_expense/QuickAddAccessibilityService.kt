package com.example.flow_expense

import android.accessibilityservice.AccessibilityButtonController
import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.view.accessibility.AccessibilityEvent

/**
 * Lets the accessibility button or gesture open quick add.
 *
 * It reads no screen content and performs no actions; it only listens for
 * the accessibility button.
 */
class QuickAddAccessibilityService : AccessibilityService() {
    private var buttonCallback: AccessibilityButtonController.AccessibilityButtonCallback? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val callback = object : AccessibilityButtonController.AccessibilityButtonCallback() {
                override fun onClicked(controller: AccessibilityButtonController) {
                    startActivity(QuickAddActivity.intent(this@QuickAddAccessibilityService))
                }
            }
            accessibilityButtonController.registerAccessibilityButtonCallback(callback)
            buttonCallback = callback
        }
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            buttonCallback?.let { accessibilityButtonController.unregisterAccessibilityButtonCallback(it) }
        }
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) = Unit

    override fun onInterrupt() = Unit
}
