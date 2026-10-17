package com.thientech.tmovie.core.player

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.annotation.OptIn
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.PlayerView

/**
 * A live TV channel, full screen, with media3's stock controls: no episodes, resume or history.
 * Channels from IPTV playlists may need their own User-Agent / Referer.
 */
@OptIn(UnstableApi::class)
class LiveActivity : ComponentActivity() {
    private lateinit var exo: ExoPlayer
    private var error by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val url = intent.getStringExtra(EXTRA_URL) ?: return finish()
        val name = intent.getStringExtra(EXTRA_NAME).orEmpty()

        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).apply {
            hide(WindowInsetsCompat.Type.systemBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
        val http = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setUserAgent(intent.getStringExtra(EXTRA_USER_AGENT) ?: USER_AGENT)
            .setDefaultRequestProperties(listOfNotNull(intent.getStringExtra(EXTRA_REFERRER)?.let { "Referer" to it }).toMap())
        exo = ExoPlayer.Builder(this).setMediaSourceFactory(DefaultMediaSourceFactory(http)).build()
        val uri = android.net.Uri.parse(url)
        // Playlist URLs often hide the .m3u8 (`/live/kgtv`, `chunklist`): anything not obviously a file is HLS.
        val hls = Util.inferContentType(uri) == C.CONTENT_TYPE_HLS ||
            uri.path.orEmpty().substringAfterLast('/').substringAfterLast('.', "").lowercase() !in setOf("mp4", "mkv", "ts", "webm", "mp3", "aac")
        exo.setMediaItem(MediaItem.Builder().setUri(uri).apply { if (hls) setMimeType(MimeTypes.APPLICATION_M3U8) }.build())
        exo.addListener(object : androidx.media3.common.Player.Listener {
            override fun onPlayerError(e: PlaybackException) {
                // Fell behind the live window (a stall): jump back to the live edge.
                if (e.errorCode == PlaybackException.ERROR_CODE_BEHIND_LIVE_WINDOW) { exo.seekToDefaultPosition(); exo.prepare() } else error = true
            }
        })
        exo.prepare()
        exo.play()

        setContent {
            Box(Modifier.fillMaxSize().background(Color.Black)) {
                AndroidView({ PlayerView(it).apply { player = exo; keepScreenOn = true; setShowNextButton(false); setShowPreviousButton(false) } }, Modifier.fillMaxSize())
                Text(name, color = Color.White.copy(alpha = 0.8f), modifier = Modifier.align(Alignment.TopStart).padding(24.dp))
                if (error) Text("Kênh này hiện không phát được", color = Color.White, modifier = Modifier.align(Alignment.Center))
            }
        }
    }

    override fun onStart() { super.onStart(); exo.play() }

    override fun onStop() { super.onStop(); exo.pause() }

    override fun onDestroy() {
        if (::exo.isInitialized) exo.release()
        super.onDestroy()
    }

    companion object {
        const val EXTRA_URL = "url"
        const val EXTRA_NAME = "name"
        const val EXTRA_USER_AGENT = "userAgent"
        const val EXTRA_REFERRER = "referrer"
        private const val USER_AGENT = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36 TMovie"
    }
}
