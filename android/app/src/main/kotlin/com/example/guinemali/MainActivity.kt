package com.example.guinemali

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.stealth").setMethodCallHandler { call, result ->
            when (call.method) {
                "setStealth" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    try {
                        if (enabled) {
                            // Activer alias calculatrice, désactiver alias normal
                            setAliasEnabled("com.example.guinemali.CalculatorAlias", true)
                            setAliasEnabled("com.example.guinemali.LauncherAlias", false)
                        } else {
                            setAliasEnabled("com.example.guinemali.CalculatorAlias", false)
                            setAliasEnabled("com.example.guinemali.LauncherAlias", true)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun toggleLauncherIcon(show: Boolean) {
        val pm: PackageManager = applicationContext.packageManager
        val componentName = ComponentName(applicationContext, "com.example.guinemali.LauncherAlias")
        pm.setComponentEnabledSetting(
            componentName,
            if (show) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
    }

    private fun setAliasEnabled(aliasName: String, enable: Boolean) {
        val pm: PackageManager = applicationContext.packageManager
        val component = ComponentName(applicationContext, aliasName)
        pm.setComponentEnabledSetting(
            component,
            if (enable) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
    }
}
