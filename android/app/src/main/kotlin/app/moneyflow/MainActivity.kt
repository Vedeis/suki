package app.moneyflow

import android.content.Intent
import android.provider.Settings
import android.content.ComponentName
import android.service.notification.NotificationListenerService
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val channel = "app.moneyflow/notifications"
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasNotificationAccess" -> result.success(isNotificationAccessGranted())
                "openNotificationSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                    result.success(null)
                }
                "getPendingTransactions" -> {
                    val prefs = getSharedPreferences("moneyflow_notifications", Context.MODE_PRIVATE)
                    val raw = prefs.getString("pending", "[]") ?: "[]"
                    val array = JSONArray(raw)
                    val list = mutableListOf<Map<String, String>>()
                    for (i in 0 until array.length()) {
                        val item = array.getJSONObject(i)
                        list.add(mapOf(
                            "package" to item.optString("package"),
                            "text" to item.optString("text"),
                            "time" to item.optString("time")
                        ))
                    }
                    result.success(list)
                }
                "clearPendingTransactions" -> {
                    getSharedPreferences("moneyflow_notifications", Context.MODE_PRIVATE)
                        .edit().putString("pending", "[]").apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isNotificationAccessGranted(): Boolean {
        val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        return enabled.contains(packageName)
    }
}
