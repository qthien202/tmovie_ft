package com.thientech.tmovie.tv

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.util.Log
import android.net.Uri
import android.os.Build
import androidx.tvprovider.media.tv.PreviewChannel
import androidx.tvprovider.media.tv.PreviewChannelHelper
import androidx.tvprovider.media.tv.PreviewProgram
import androidx.tvprovider.media.tv.TvContractCompat
import androidx.tvprovider.media.tv.TvContractCompat.WatchNextPrograms
import androidx.tvprovider.media.tv.WatchNextProgram
import com.thientech.tmovie.core.data.WatchRecord
import com.thientech.tmovie.core.model.FilmItem
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

/**
 * The home billboard's films as the app's channel on the TV home screen ("Phim nổi bật"), with
 * the same key art, so the launcher's top shelf shows what the app's billboard shows.
 * Refreshed each time Home loads the hot list.
 */
object Featured {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    fun publish(context: Context, films: List<FilmItem>, art: Map<String, String>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || films.isEmpty()) return
        val app = context.applicationContext
        scope.launch {
            runCatching {
                val helper = PreviewChannelHelper(app)
                val channel = helper.allChannels.firstOrNull { it.internalProviderId == "featured" }?.id ?: helper.publishDefaultChannel(
                    PreviewChannel.Builder()
                        .setDisplayName("Phim nổi bật")
                        .setAppLinkIntentUri(Uri.parse(Intent(app, TvActivity::class.java).toUri(Intent.URI_INTENT_SCHEME)))
                        .setLogo(BitmapFactory.decodeResource(app.resources, R.mipmap.ic_launcher_foreground))  // a PNG; ic_launcher is adaptive XML
                        .setInternalProviderId("featured")
                        .build(),
                )
                app.contentResolver.delete(TvContractCompat.buildPreviewProgramsUriForChannel(channel), null, null)
                films.forEachIndexed { i, f ->
                    val image = art[f.slug] ?: f.thumbImage ?: return@forEachIndexed
                    helper.publishPreviewProgram(
                        PreviewProgram.Builder()
                            .setChannelId(channel)
                            .setType(if (f.type == "single") TvContractCompat.PreviewPrograms.TYPE_MOVIE else TvContractCompat.PreviewPrograms.TYPE_TV_SERIES)
                            .setTitle(f.name)
                            .setDescription(f.metaLine())
                            .setPosterArtUri(Uri.parse(image))
                            .setPosterArtAspectRatio(TvContractCompat.PreviewPrograms.ASPECT_RATIO_16_9)
                            .setIntentUri(filmLink(f.slug))
                            .setInternalProviderId(f.slug)
                            .setWeight(films.size - i)
                            .setSearchable(true)
                            .build(),
                    )
                }
            }.onFailure { Log.w("Featured", "publish failed", it) }
        }
    }
}
