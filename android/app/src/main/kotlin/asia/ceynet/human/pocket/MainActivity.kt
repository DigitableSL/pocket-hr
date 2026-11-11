package asia.ceynet.human.pocket

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val SECURITY_CHANNEL = "asia.ceynet.pocket/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDevModeEnabled" -> {
                    result.success(isDevModeEnabled())
                }
                "isMockLocation" -> {
                    result.success(isMockLocation())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Checks if Developer Options or USB Debugging (ADB) is enabled on Android.
     */
    private fun isDevModeEnabled(): Boolean {
        return try {
            val devMode = Settings.Global.getInt(
                contentResolver,
                Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
            ) != 0

            val adb = Settings.Global.getInt(
                contentResolver,
                Settings.Global.ADB_ENABLED, 0
            ) != 0

            devMode || adb
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Checks if the device's last known location is from a mock provider.
     */
    private fun isMockLocation(): Boolean {
        return try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
            val providers = locationManager.getProviders(true)
            for (provider in providers) {
                try {
                    val location = locationManager.getLastKnownLocation(provider) ?: continue
                    if (isLocationMocked(location)) {
                        return true
                    }
                } catch (se: SecurityException) {
                    // Location permission might not be granted yet
                }
            }
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun isLocationMocked(location: Location): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            location.isMock
        } else {
            @Suppress("DEPRECATION")
            location.isFromMockProvider
        }
    }
}
