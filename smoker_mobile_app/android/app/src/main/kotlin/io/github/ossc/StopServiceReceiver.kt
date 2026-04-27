package io.github.ossc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat

class StopServiceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Stop the flutter_background_service foreground service
        val serviceIntent = Intent(context, Class.forName("id.flutter.flutter_background_service.BackgroundService"))
        context.stopService(serviceIntent)

        // Cancel the persistent notification
        NotificationManagerCompat.from(context).cancel(888)
    }
}
