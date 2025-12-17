package gorda.holyverso

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val VERSE_CHANNEL = "bible_widget/shared_verse"
    private val AUTH_CHANNEL = "bible_widget/auth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
}
