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
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun saveVerse(verseJson: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_WIDGET_VERSE, verseJson).apply()
    }

    private fun readVerse(): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_WIDGET_VERSE, null)
    }

    private fun refreshWidgets() {
        val intent = Intent(context, BibleWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        val widgetManager = AppWidgetManager.getInstance(context)
        val widgetIds = widgetManager.getAppWidgetIds(
            ComponentName(context, BibleWidgetProvider::class.java)
        )
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
        context.sendBroadcast(intent)
    }
}
