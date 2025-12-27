package gorda.holyverso

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject

class BibleWidgetProvider : AppWidgetProvider() {
    
    companion object {
        private const val PREFS_NAME = "bible_widget_prefs"
        private const val KEY_WIDGET_VERSE = "widgetVerse"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Verificar si necesitamos actualizar el verso
        checkAndScheduleUpdate(context)
        WidgetUpdateWorker.schedule(context)
        
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Widget añadido por primera vez - iniciar actualizaciones periódicas
        super.onEnabled(context)
        WidgetUpdateWorker.schedule(context)
    }

    override fun onDisabled(context: Context) {
        // Último widget removido - cancelar actualizaciones
        super.onDisabled(context)
        WidgetUpdateWorker.cancel(context)
    }

    private fun checkAndScheduleUpdate(context: Context) {
        val verse = readWidgetVerse(context)
        val currentHour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)
        
        // Si es antes de las 5am, esperar hasta las 5am
        if (currentHour < 5) {
            return
        }
        
        // Si después de las 5am y no hay verso del día, solicitar actualización inmediata
        if (verse == null || !isVerseFromToday(verse)) {
            WidgetUpdateWorker.scheduleOneTimeUpdate(context, 0)
        }
    }
    
    private fun isVerseFromToday(verse: WidgetVerse): Boolean {
        return try {
            val today = java.time.LocalDate.now().toString()
            verse.date == today
        } catch (e: Exception) {
            false
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.bible_widget)
        
        // Leer el verso guardado
        val verse = readWidgetVerse(context)
        android.util.Log.d("BibleWidgetProvider", "Updating widget $appWidgetId, verse: ${verse?.reference ?: "null"}")
        
        // Mostrar el verso si existe, sin importar la fecha
        if (verse != null) {
            android.util.Log.d("BibleWidgetProvider", "Showing verse: ${verse.text}")
            views.setTextViewText(R.id.widget_verse_text, verse.text)
            views.setTextViewText(R.id.widget_reference, verse.reference)
            views.setTextViewText(R.id.widget_version, verse.versionName)
            
            // Aplicar tamaño de fuente dinámico
            views.setFloat(R.id.widget_verse_text, "setTextSize", verse.fontSize)
        } else {
            android.util.Log.d("BibleWidgetProvider", "No verse found, showing placeholder")
            views.setTextViewText(R.id.widget_verse_text, "Abre HolyVerso para actualizar el versículo")
            views.setTextViewText(R.id.widget_reference, "")
            views.setTextViewText(R.id.widget_version, "")
        }

        // Intent para abrir la app al tocar el widget
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        // Actualizar el widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun readWidgetVerse(context: Context): WidgetVerse? {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val verseJson = prefs.getString(KEY_WIDGET_VERSE, null) ?: return null
            android.util.Log.d("BibleWidgetProvider", "Read verse from prefs: $verseJson")
            parseWidgetVerse(verseJson)
        } catch (e: Exception) {
            android.util.Log.e("BibleWidgetProvider", "Error reading verse", e)
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

data class WidgetVerse(
    val date: String,
    val versionCode: String,
    val versionName: String,
    val reference: String,
    val text: String,
    val fontSize: Float = 16f
)
