package gorda.holyverso

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WidgetMethodChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val PREFS_NAME = "bible_widget_prefs"
        private const val KEY_WIDGET_VERSE = "widgetVerse"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveVerse" -> {
                val verseJson = call.arguments as? String
                if (verseJson != null) {
                    saveVerse(verseJson)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Expected a JSON string", null)
                }
            }
            "readVerse" -> {
                val verse = readVerse()
                result.success(verse)
            }
            "refreshWidgets" -> {
                refreshWidgets()
                result.success(null)
            }
            "requestImmediateUpdate" -> {
                requestImmediateUpdate()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun saveVerse(verseJson: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_WIDGET_VERSE, verseJson).apply()
        android.util.Log.d("WidgetMethodChannel", "Verse saved: $verseJson")
    }

    private fun readVerse(): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_WIDGET_VERSE, null)
    }

    private fun refreshWidgets() {
        // Refresh home screen widgets
        val homeIntent = Intent(context, BibleWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        val widgetManager = AppWidgetManager.getInstance(context)
        val homeWidgetIds = widgetManager.getAppWidgetIds(
            ComponentName(context, BibleWidgetProvider::class.java)
        )
        homeIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, homeWidgetIds)
        context.sendBroadcast(homeIntent)
        
        // Refresh lock screen widgets
        val lockIntent = Intent(context, LockScreenWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        val lockWidgetIds = widgetManager.getAppWidgetIds(
            ComponentName(context, LockScreenWidgetProvider::class.java)
        )
        lockIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, lockWidgetIds)
        context.sendBroadcast(lockIntent)
        
        android.util.Log.d("WidgetMethodChannel", "Refreshing ${homeWidgetIds.size} home widgets and ${lockWidgetIds.size} lock screen widgets")
    }

    private fun requestImmediateUpdate() {
        // Programar una actualización inmediata del WidgetUpdateWorker
        WidgetUpdateWorker.scheduleOneTimeUpdate(context, 0) // 0 horas = inmediato
    }
}
