package com.thientech.tmovie.tv

import android.content.Context
import android.util.Log
import android.net.Uri
import android.os.Build
import androidx.tvprovider.media.tv.TvContractCompat
import androidx.tvprovider.media.tv.TvContractCompat.WatchNextPrograms
import androidx.tvprovider.media.tv.WatchNextProgram
import com.thientech.tmovie.core.data.WatchRecord
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/** Deep link a launcher card opens: the film's page. */
fun filmLink(slug: String): Uri = Uri.parse("tmovie://film/$slug")

/**
 * "Xem tiếp" on the TV's own home screen: one Watch Next row per film being watched, kept by slug.
 * Launchers read only searchable rows with landscape art.
 */
object WatchNext {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    fun publish(context: Context, record: WatchRecord) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val art = record.film.thumbImage ?: return
        val app = context.applicationContext
        scope.launch {
            runCatching {
                val slug = record.lastEpisodeSlug
                val program = WatchNextProgram.Builder()
                    .setWatchNextType(WatchNextPrograms.WATCH_NEXT_TYPE_CONTINUE)
                    .setType(if (record.film.type == "single") TvContractCompat.PreviewPrograms.TYPE_MOVIE else TvContractCompat.PreviewPrograms.TYPE_TV_EPISODE)
                    .setTitle(record.film.name)
                    .setEpisodeTitle(record.episodeName.ifBlank { null })
                    .setPosterArtUri(Uri.parse(art))
                    .setPosterArtAspectRatio(TvContractCompat.PreviewPrograms.ASPECT_RATIO_16_9)
                    .setIntentUri(filmLink(record.film.slug))
                    .setInternalProviderId(record.film.slug)
                    .setLastEngagementTimeUtcMillis(record.updatedAt)
                    .setLastPlaybackPositionMillis(((record.positions[slug] ?: 0.0) * 1000).toInt())
                    .setDurationMillis(((record.durations[slug] ?: 0.0) * 1000).toInt())
                    .setSearchable(true)
                    .build()
                val existing = app.contentResolver.query(WatchNextPrograms.CONTENT_URI, arrayOf(WatchNextPrograms._ID, WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID), null, null, null)?.use { c ->
                    generateSequence { if (c.moveToNext()) c else null }.firstOrNull { it.getString(1) == record.film.slug }?.getLong(0)
                }
                if (existing == null) app.contentResolver.insert(WatchNextPrograms.CONTENT_URI, program.toContentValues())
                else app.contentResolver.update(TvContractCompat.buildWatchNextProgramUri(existing), program.toContentValues(), null, null)
            }.onFailure { Log.w("WatchNext", "publish failed", it) }
        }
    }
}
