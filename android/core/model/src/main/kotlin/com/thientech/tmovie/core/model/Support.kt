package com.thientech.tmovie.core.model

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull

/**
 * Whether 18+ titles and the "Phim 18+" genre are shown. Off by default; turned on per account
 * by the `allowAdult` flag on the signed-in user's Firestore profile.
 */
object ContentPolicy {
    @Volatile var allowAdult: Boolean = false

    fun visible(film: FilmItem) = allowAdult || !film.isAdult
    fun visible(genre: FilmCategory) = allowAdult || genre.slug !in FilmCategory.adultSlugs
}

/** PhimAPI sends some values as either a string or a number (`episode_total`, `tmdb.id`). */
object LooseStringSerializer : KSerializer<String?> {
    override val descriptor = PrimitiveSerialDescriptor("LooseString", PrimitiveKind.STRING)

    override fun deserialize(decoder: Decoder): String? {
        val element = (decoder as? JsonDecoder)?.decodeJsonElement() ?: return decoder.decodeString()
        return (element as? JsonPrimitive)?.contentOrNull
    }

    override fun serialize(encoder: Encoder, value: String?) {
        if (value == null) encoder.encodeNull() else encoder.encodeString(value)
    }
}

/**
 * PhimAPI mixes absolute URLs, `upload/vod/...`, `uploads/movies/...` and bare file names.
 * (The Dart helper prefixed `uploads/movies/` onto `upload/vod/...`, which 404s.)
 */
fun phimImageUrl(raw: String?): String? {
    if (raw.isNullOrBlank()) return null
    if (raw.startsWith("http")) return raw
    val path = raw.removePrefix("/")
    return "https://phimimg.com/" + if ('/' in path) path else "uploads/movies/$path"
}

fun tmdbImageUrl(path: String?, size: String): String? =
    if (path.isNullOrBlank()) null else "https://image.tmdb.org/t/p/$size$path"

/** "★ 8.4 · 2026 · FHD · Phụ đề · Tập 12" */
fun FilmItem.metaLine(): String = listOfNotNull(
    rating?.let { "★ " + String.format(java.util.Locale.US, "%.1f", it) },
    year?.toString(),
    quality,
    if (lang.orEmpty().contains("vietsub", ignoreCase = true)) "Phụ đề" else null,
    episodeCurrent,
).filter { it.isNotBlank() }.joinToString(" · ")

/** "Tình cảm • Cổ trang • Chính kịch" */
fun FilmItem.genreLine(): String = category.orEmpty().take(3).mapNotNull { it.name }.joinToString(" • ")
