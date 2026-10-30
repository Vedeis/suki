package app.moneyflow

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Context
import android.os.Bundle
import org.json.JSONArray
import org.json.JSONObject
import java.util.Date

class MoneyFlowNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return
        if (packageName == this.packageName) return
        val extras: Bundle = sbn.notification.extras ?: return
        val title = extras.getCharSequence("android.title")?.toString().orEmpty()
        val text = extras.getCharSequence("android.text")?.toString().orEmpty()
        val big = extras.getCharSequence("android.bigText")?.toString().orEmpty()
        val combined = listOf(title, text, big).filter { it.isNotBlank() }.distinct().joinToString(" — ")
        if (combined.isBlank()) return
        // Capture only likely financial transaction alerts, not every notification.
        val lower = combined.lowercase()
        val transactionWords = listOf(
            "rp", "idr", "debit", "kredit", "transfer", "pembayaran",
            "payment", "berhasil", "transaksi", "uang masuk", "top up",
            "saldo", "mutasi", "purchase", "refund", "cashback"
        )
        if (transactionWords.none { lower.contains(it) }) return

        val prefs = getSharedPreferences("moneyflow_notifications", Context.MODE_PRIVATE)
        val existing = try { JSONArray(prefs.getString("pending", "[]")) } catch (_: Exception) { JSONArray() }
        // Keep a bounded local queue. No notification content is sent to a server.
        if (existing.length() >= 100) return
        val item = JSONObject()
        item.put("package", packageName)
        item.put("text", combined)
        item.put("time", Date(sbn.postTime).toInstant().toString())
        existing.put(item)
        prefs.edit().putString("pending", existing.toString()).apply()
    }
}
