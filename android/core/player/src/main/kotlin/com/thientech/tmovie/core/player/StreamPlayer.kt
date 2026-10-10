package com.thientech.tmovie.core.player

import android.content.Context
import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.ByteArrayDataSource
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSourceUtil
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.TransferListener
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.upstream.DefaultLoadErrorHandlingPolicy
import com.thientech.tmovie.core.network.HlsAdFilter

/**
 * ExoPlayer tuned for the aggregator's HLS streams: ads spliced into media playlists are
 * stripped (see [HlsAdFilter]), redirects across http/https are followed, segment loads retry
 * more, and buffers are deeper so brief CDN hiccups don't stall playback.
 */
@OptIn(UnstableApi::class)
object StreamPlayer {
    private const val USER_AGENT =
        "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36 TMovie"

    fun create(context: Context, preview: Boolean = false): ExoPlayer {
        val http = DefaultHttpDataSource.Factory()
            .setUserAgent(USER_AGENT)
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(15_000)
            .setReadTimeoutMs(20_000)
        val mediaSource = HlsMediaSource.Factory(AdStrippingDataSource.Factory(http))
            .setAllowChunklessPreparation(true)
            .setLoadErrorHandlingPolicy(DefaultLoadErrorHandlingPolicy(6))
        val loadControl = if (preview) {
            DefaultLoadControl.Builder().setBufferDurationsMs(10_000, 30_000, 1_500, 3_000).build()
        } else {
            DefaultLoadControl.Builder().setBufferDurationsMs(30_000, 120_000, 2_000, 4_000).build()
        }
        return ExoPlayer.Builder(context)
            .setMediaSourceFactory(mediaSource)
            .setLoadControl(loadControl)
            .setSeekBackIncrementMs(10_000)
            .setSeekForwardIncrementMs(10_000)
            .apply {
                if (!preview) {
                    setAudioAttributes(AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MOVIE).build(), true)
                    setHandleAudioBecomingNoisy(true)
                    setWakeMode(C.WAKE_MODE_NETWORK)
                }
            }
            .build()
    }
}

/** Reads `.m3u8` responses fully and serves them through [HlsAdFilter]; everything else streams through. */
@OptIn(UnstableApi::class)
private class AdStrippingDataSource(private val upstream: DataSource) : DataSource {
    private var playlist: ByteArrayDataSource? = null
    private var uri: Uri? = null

    class Factory(private val upstream: DataSource.Factory) : DataSource.Factory {
        override fun createDataSource(): DataSource = AdStrippingDataSource(upstream.createDataSource())
    }

    override fun addTransferListener(transferListener: TransferListener) = upstream.addTransferListener(transferListener)

    override fun open(dataSpec: DataSpec): Long {
        if (!dataSpec.uri.path.orEmpty().endsWith(".m3u8")) {
            playlist = null
            return upstream.open(dataSpec).also { uri = upstream.uri }
        }
        upstream.open(dataSpec)
        val bytes = try {
            uri = upstream.uri ?: dataSpec.uri
            DataSourceUtil.readToEnd(upstream)
        } finally {
            upstream.close()
        }
        val cleaned = HlsAdFilter.clean(String(bytes, Charsets.UTF_8)).toByteArray(Charsets.UTF_8)
        return ByteArrayDataSource(cleaned).also { playlist = it }.open(DataSpec(dataSpec.uri))
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int =
        playlist?.read(buffer, offset, length) ?: upstream.read(buffer, offset, length)

    override fun getUri(): Uri? = uri

    override fun getResponseHeaders(): Map<String, List<String>> = if (playlist != null) emptyMap() else upstream.responseHeaders

    override fun close() {
        playlist?.close() ?: upstream.close()
        playlist = null
    }
}
