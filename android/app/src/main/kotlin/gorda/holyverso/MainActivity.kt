package gorda.holyverso

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.urllauncher.UrlLauncherPlugin

class MainActivity : FlutterActivity() {
    private val VERSE_CHANNEL = "bible_widget/shared_verse"
    private val AUTH_CHANNEL = "bible_widget/auth"
    private val DEVOTIONALS_NOTIFICATION_CHANNEL_ID = "devotionals"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()
        if (!flutterEngine.plugins.has(UrlLauncherPlugin::class.java)) {
            flutterEngine.plugins.add(UrlLauncherPlugin())
        }
        
        // Channel para sincronizar versos con el widget
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VERSE_CHANNEL).setMethodCallHandler(
            WidgetMethodChannel(applicationContext)
        )
        
        // Channel para guardar JWT token y API URL para uso nativo
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTH_CHANNEL).setMethodCallHandler { 
            call, result ->
            when (call.method) {
                "saveJwtToken" -> {
                    val token = call.arguments as? String
                    if (token != null) {
                        saveJwtToken(token)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Expected JWT token string", null)
                    }
                }
                "clearJwtToken" -> {
                    clearJwtToken()
                    result.success(null)
                }
                "setApiUrl" -> {
                    val apiUrl = call.arguments as? String
                    if (apiUrl != null) {
                        saveApiUrl(apiUrl)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Expected API URL string", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun saveJwtToken(token: String) {
        val prefs = getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE)
        prefs.edit().putString("jwt_token", token).apply()
    }
    
    private fun clearJwtToken() {
        val prefs = getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE)
        prefs.edit().remove("jwt_token").apply()
    }
    
    private fun saveApiUrl(apiUrl: String) {
        val prefs = getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE)
        prefs.edit().putString("api_url", apiUrl).apply()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val notificationManager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            DEVOTIONALS_NOTIFICATION_CHANNEL_ID,
            getString(R.string.devotionals_notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.devotionals_notification_channel_description)
        }

        notificationManager.createNotificationChannel(channel)
    }
}
