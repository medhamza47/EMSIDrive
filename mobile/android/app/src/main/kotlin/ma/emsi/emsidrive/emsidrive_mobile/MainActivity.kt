package ma.emsi.emsidrive.emsidrive_mobile

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build

class MainActivity : FlutterFragmentActivity() {
    private var permissionResult: MethodChannel.Result? = null
    private var localScheduleOcr: LocalScheduleOcr? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        localScheduleOcr = LocalScheduleOcr(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "emsidrive/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method != "requestPermission") result.notImplemented()
                else if (Build.VERSION.SDK_INT < 33 || checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
                    result.success(true)
                else if (permissionResult != null) result.success(false)
                else {
                    permissionResult = result
                    requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 3021)
                }
            }
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        localScheduleOcr?.close()
        localScheduleOcr = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 3021) {
            permissionResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
            permissionResult = null
        }
    }
}
