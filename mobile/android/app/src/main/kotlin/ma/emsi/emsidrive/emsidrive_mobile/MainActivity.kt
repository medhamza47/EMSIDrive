package ma.emsi.emsidrive.emsidrive_mobile

import io.flutter.embedding.android.FlutterFragmentActivity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle

// local_auth shows the system biometric prompt, which needs a FragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("emsidrive_rides", "Trajets et messages", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Acceptations, messages et changements de trajet EMSIDrive"
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
