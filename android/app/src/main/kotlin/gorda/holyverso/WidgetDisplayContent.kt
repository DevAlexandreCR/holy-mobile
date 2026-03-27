package gorda.holyverso

import kotlin.random.Random

internal const val WIDGET_DISPLAY_VARIANT_VERSE_ONLY = "verse_only"
internal const val WIDGET_DISPLAY_VARIANT_CONTINUATION = "continuation"
internal const val WIDGET_DISPLAY_VARIANT_PRESENCE_HINT = "presence_hint"
internal const val WIDGET_DEVOTIONALS_DEEP_LINK =
    "holyverso://app/devotionals?tab=for_you"
internal const val WIDGET_FALLBACK_SECONDARY_LINE = "Descubre el mensaje de hoy"

internal data class WidgetDisplayContent(
    val displayVariant: String,
    val secondaryLine: String? = null,
)

internal fun pickWidgetDisplayContent(random: Random = Random.Default): WidgetDisplayContent {
    val roll = random.nextInt(100)
    return when {
        roll < 65 -> WidgetDisplayContent(
            displayVariant = WIDGET_DISPLAY_VARIANT_CONTINUATION,
            secondaryLine = continuationLines.random(random),
        )

        else -> WidgetDisplayContent(
            displayVariant = WIDGET_DISPLAY_VARIANT_PRESENCE_HINT,
            secondaryLine = presenceHintLines.random(random),
        )
    }
}

private val continuationLines = listOf(
    "Descubre el mensaje de hoy",
    "Hoy hay más para ti",
)

private val presenceHintLines = listOf(
    "Nuevos devocionales hoy",
    "Otros están leyendo hoy",
)
