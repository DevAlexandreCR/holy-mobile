package gorda.holyverso

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.time.LocalDate
import java.util.concurrent.TimeUnit
import java.util.Calendar

class WidgetUpdateWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    companion object {
        private const val TAG = "WidgetUpdateWorker"
        private const val WORK_NAME = "bible_widget_daily_update"
        private const val PREFS_NAME = "bible_widget_prefs"
        private const val KEY_WIDGET_VERSE = "widgetVerse"
        private const val KEY_AUTH_TOKEN = "FlutterSecureStorage"
        private const val KEY_JWT_TOKEN = "jwt_token"

        fun schedule(context: Context) {
            // Calcular tiempo hasta las 6 AM del siguiente día
            val currentTime = Calendar.getInstance()
            val targetTime = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 6)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                
                // Si ya pasaron las 6 AM, programar para mañana
                if (before(currentTime)) {
                    add(Calendar.DAY_OF_MONTH, 1)
                }
            }
            
            val initialDelay = targetTime.timeInMillis - currentTime.timeInMillis

            // Crear trabajo periódico diario
            val updateRequest = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                1, TimeUnit.DAYS
            )
                .setInitialDelay(initialDelay, TimeUnit.MILLISECONDS)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                updateRequest
            )
            
            Log.d(TAG, "Widget daily update scheduled for 6:00 AM. Initial delay: ${initialDelay / 1000 / 60} minutes")
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }

    override suspend fun doWork(): Result {
        return try {
            Log.d(TAG, "Starting daily verse fetch...")
            fetchAndUpdateVerse()
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching daily verse", e)
            Result.retry()
        }
    }

    private suspend fun fetchAndUpdateVerse() = withContext(Dispatchers.IO) {
        try {
            // Obtener el token JWT de SharedPreferences
            val authPrefs = applicationContext.getSharedPreferences(KEY_AUTH_TOKEN, Context.MODE_PRIVATE)
            val jwtToken = authPrefs.getString(KEY_JWT_TOKEN, null)
            
            if (jwtToken.isNullOrEmpty()) {
                Log.w(TAG, "No JWT token found, skipping verse fetch")
                return@withContext
            }

            // Obtener la URL base de la API
            val apiUrl = getApiUrl()
            
            // Hacer petición HTTP al backend
            val client = OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(15, TimeUnit.SECONDS)
                .build()

            val request = Request.Builder()
                .url("$apiUrl/verse/today")
                .addHeader("Authorization", "Bearer $jwtToken")
                .build()

            val response = client.newCall(request).execute()
            
            if (!response.isSuccessful) {
                Log.e(TAG, "API request failed: ${response.code}")
                return@withContext
            }

            val responseBody = response.body?.string()
            if (responseBody.isNullOrEmpty()) {
                Log.e(TAG, "Empty response from API")
                return@withContext
            }

            // Parsear la respuesta
            val json = JSONObject(responseBody)
            val data = if (json.has("data")) json.getJSONObject("data") else json
            
            // Crear el objeto WidgetVerse
            val today = LocalDate.now().toString()
            val verseJson = JSONObject().apply {
                put("date", today)
                put("version_code", data.optString("version_code", ""))
                put("version_name", data.optString("version_name", ""))
                put("reference", data.optString("reference", ""))
                put("text", data.optString("text", ""))
                put("font_size", 16.0)
            }

            // Guardar en SharedPreferences
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString(KEY_WIDGET_VERSE, verseJson.toString()).apply()
            
            Log.d(TAG, "Verse fetched and saved successfully for $today")

            // Actualizar los widgets
            updateWidgets()
        } catch (e: Exception) {
            Log.e(TAG, "Error in fetchAndUpdateVerse", e)
            throw e
        }
    }

    private fun updateWidgets() {
        val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
        val componentName = ComponentName(applicationContext, BibleWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        
        if (appWidgetIds.isNotEmpty()) {
            BibleWidgetProvider().onUpdate(applicationContext, appWidgetManager, appWidgetIds)
            Log.d(TAG, "Widgets updated: ${appWidgetIds.size} widget(s)")
        }
    }

    private fun getApiUrl(): String {
        // Leer la API URL guardada desde Flutter
        val prefs = applicationContext.getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE)
        val savedUrl = prefs.getString("api_url", null)
        
        if (!savedUrl.isNullOrEmpty()) {
            return savedUrl
        }
        
        // Fallback: intentar leer de recursos
        return try {
            val resId = applicationContext.resources.getIdentifier("api_url", "string", applicationContext.packageName)
            if (resId != 0) {
                applicationContext.getString(resId)
            } else {
                "https://api.holyverso.com" // URL por defecto de producción
            }
        } catch (e: Exception) {
            "https://api.holyverso.com"
        }
    }
}
