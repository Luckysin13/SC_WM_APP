package io.github.ossc

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BG_CHANNEL = "ossc/bg_notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BG_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showServiceNotification" -> {
                    showServiceNotification()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showServiceNotification() {
        val channelId = "ossc_bg"

        // Ensure the notification channel exists
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Persistent notification for background monitoring."
                setSound(null, null)
                enableVibration(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }

        // Build a PendingIntent that fires the StopServiceReceiver
        val stopIntent = Intent(this, StopServiceReceiver::class.java)
        val stopPendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("OSSC Monitoring")
            .setContentText("Monitoring your smoker in the background...")
            .setSmallIcon(R.mipmap.launcher_icon)
            .setOngoing(true)
            .setSilent(true)
            .addAction(0, "Stop Monitoring", stopPendingIntent)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(888, notification)
    }
}
