package gorda.holyverso

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Lock Screen Widget Provider for Android 4.2+
 * Supports both lock screen (keyguard) and home screen placement
 */
class LockScreenWidgetProvider : AppWidgetProvider() {
    
    companion object {
        private const val PREFS_NAME = "bible_widget_prefs"
        private const val KEY_WIDGET_VERSE = "widgetVerse"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Schedule updates if not already scheduled
        WidgetUpdateWorker.schedule(context)
        
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetUpdateWorker.schedule(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Don't cancel updates here - home screen widget might still be active
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.lockscreen_widget)
        
        val verse = readWidgetVerse(context)
        android.util.Log.d("LockScreenWidget", "Updating widget $appWidgetId, verse: ${verse?.reference ?: "null"}")
        
        if (verse != null) {
            views.setTextViewText(R.id.lockscreen_widget_reference, verse.reference)
            views.setTextViewText(R.id.lockscreen_widget_text, verse.text)
            views.setTextViewText(R.id.lockscreen_widget_version, verse.versionName)
            
            // Apply font size (default 14sp for lock screen - smaller than home screen)
            val lockScreenFontSize = (verse.fontSize * 0.85f).coerceIn(10f, 18f)
            views.setFloat(R.id.lockscreen_widget_text, "setTextSize", lockScreenFontSize)
        } else {
            views.setTextViewText(R.id.lockscreen_widget_reference, "")
            views.setTextViewText(R.id.lockscreen_widget_text, "Abre HolyVerso")
            views.setTextViewText(R.id.lockscreen_widget_version, "")
        }

        // Deep link to app when clicked
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.lockscreen_widget_container, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun readWidgetVerse(context: Context): WidgetVerse? {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val verseJson = prefs.getString(KEY_WIDGET_VERSE, null) ?: return null
            parseWidgetVerse(verseJson)
        } catch (e: Exception) {
            android.util.Log.e("LockScreenWidget", "Error reading verse", e)
            null
        }
    }

    private fun parseWidgetVerse(json: String): WidgetVerse? {
        return try {
            val obj = JSONObject(json)
            WidgetVerse(
                date = obj.getString("date"),
                versionCode = obj.getString("version_code"),
                versionName = obj.getString("version_name"),
                reference = obj.getString("reference"),
                text = obj.getString("text"),
                fontSize = obj.optDouble("font_size", 16.0).toFloat()
            )
        } catch (e: Exception) {
            null
        }
    }
}
