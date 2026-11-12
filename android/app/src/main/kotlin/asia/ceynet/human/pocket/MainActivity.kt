package asia.ceynet.human.pocket

import android.content.Context
import android.content.pm.ApplicationInfo
import android.location.Location
import android.location.LocationManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
                "isAutoTimeEnabled" -> {
                    result.success(isAutoTimeEnabled())
                }
                "playScanTone" -> {
                    val success = call.argument<Boolean>("success") ?: true
                    playScanTone(success)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun playScanTone(success: Boolean) {
        try {
            val toneGen = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 90)
            val toneType = if (success) ToneGenerator.TONE_PROP_ACK else ToneGenerator.TONE_PROP_NACK
            val durationMs = if (success) 180 else 320
            toneGen.startTone(toneType, durationMs)
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    toneGen.release()
                } catch (_: Exception) {}
            }, (durationMs + 100).toLong())
        } catch (_: Exception) {}
    }

    /**
     * Checks if Developer Options or USB Debugging (ADB) is enabled on Android.
     * Bypassed automatically in debug builds to prevent developer lockout.
     */
    private fun isDevModeEnabled(): Boolean {
        val isDebuggable = 0 != (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE)
        if (isDebuggable) {
            return false
        }

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
     * Only considers recent fixes (within 15 minutes) to avoid false positives
     * from historical stale cached locations.
     */
    private fun isMockLocation(): Boolean {
        return try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
            val providers = locationManager.getProviders(true)
            for (provider in providers) {
                try {
                    val location = locationManager.getLastKnownLocation(provider) ?: continue
                    val age = System.currentTimeMillis() - location.time
                    if (age > 15 * 60 * 1000) {
                        continue
                    }
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

    /**
     * Checks if Automatic Date & Time and Automatic Time Zone are enabled on Android.
     * Prevents users from manually altering device clock to tamper with attendance punches.
     */
    private fun isAutoTimeEnabled(): Boolean {
        return try {
            val autoTime = Settings.Global.getInt(
                contentResolver,
                Settings.Global.AUTO_TIME, 0
            ) != 0

            val autoTimeZone = try {
                Settings.Global.getInt(
                    contentResolver,
                    Settings.Global.AUTO_TIME_ZONE, 1
                ) != 0
            } catch (e: Exception) {
                true
            }

            autoTime && autoTimeZone
        } catch (e: Exception) {
            true
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
