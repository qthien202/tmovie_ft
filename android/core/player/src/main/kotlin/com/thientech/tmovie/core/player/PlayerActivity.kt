package com.thientech.tmovie.core.player

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.Rational
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.annotation.OptIn
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.TMovieTheme
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.network.PhimApi
import kotlinx.coroutines.delay

private enum class Panel { None, Settings, Episodes }

/**
 * Full-screen landscape HLS player with custom Compose controls: gestures (double-tap seek,
 * scrub, brightness, volume, pinch zoom), lock, quality / audio / subtitle / speed / aspect,
 * sleep timer, next-episode countdown, in-player episode list, PiP and a
 * MediaSession for headset / PiP controls. Resumes at the saved second and saves every 10 s.
 */
@OptIn(UnstableApi::class)
class PlayerActivity : ComponentActivity() {
    private lateinit var exo: ExoPlayer
    private var session: MediaSession? = null
    private var inPip by mutableStateOf(false)
    private var saveNow: () -> Unit = {}

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val detail = PhimApi.json.decodeFromString(FilmDetail.serializer(), intent.getStringExtra(EXTRA_DETAIL) ?: return finish())
        val startServer = intent.getIntExtra(EXTRA_SERVER, 0)
        val startIndex = intent.getIntExtra(EXTRA_INDEX, 0)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).apply {
            hide(WindowInsetsCompat.Type.systemBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
        exo = StreamPlayer.create(this)
        session = MediaSession.Builder(this, exo).build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) setPictureInPictureParams(pipParams())

        setContent { TMovieTheme { PlayerScreen(detail, startServer, startIndex) } }
    }

    @Composable
    private fun PlayerScreen(detail: FilmDetail, startServer: Int, startIndex: Int) {
        val servers = detail.episodes.orEmpty().map { it.serverData.orEmpty() }
        val serverNames = detail.episodes.orEmpty().mapIndexed { i, e -> e.serverName ?: "Server ${i + 1}" }
        var server by remember { mutableIntStateOf(startServer) }
        var index by remember { mutableIntStateOf(startIndex) }
        val episodes = servers.getOrNull(server).orEmpty()
        val episode = episodes.getOrNull(index)
        val nextIndex = (index + 1 until episodes.size).firstOrNull { episodes[it].streamUrl != null }

        val playback = rememberPlaybackState(exo)
        val gestures = remember { PlayerGestures(this, playback) }
        var controlsVisible by remember { mutableStateOf(true) }
        var lastInteraction by remember { mutableLongStateOf(System.currentTimeMillis()) }
        var locked by remember { mutableStateOf(false) }
        var panel by remember { mutableStateOf(Panel.None) }
        var aspect by remember { mutableStateOf(AspectMode.Fit) }
        var sleepMinutes by remember { mutableIntStateOf(0) }
        var sleepAt by remember { mutableLongStateOf(0L) }
        fun interact() { lastInteraction = System.currentTimeMillis(); controlsVisible = true }

        fun save() {
            val ep = episode ?: return
            Library.save(
                film = detail.toItem(), server = server, episode = index, episodeName = ep.name.orEmpty(),
                episodeSlug = ep.slug.orEmpty(), position = exo.currentPosition / 1000.0,
                duration = exo.duration.takeIf { it > 0 }?.div(1000.0) ?: 0.0,
            )
        }
        saveNow = ::save

        fun switchTo(s: Int, i: Int) {
            save()
            server = s
            index = i
            panel = Panel.None
            if (sleepMinutes == -1) { exo.pause(); sleepMinutes = 0 }  // "end of this episode"
        }

        // Load the episode, resuming unless it was basically finished.
        LaunchedEffect(server, index) {
            val ep = episode ?: return@LaunchedEffect
            val url = ep.streamUrl ?: return@LaunchedEffect
            exo.setMediaItem(
                MediaItem.Builder().setUri(url).setMediaMetadata(
                    MediaMetadata.Builder().setTitle(detail.name).setSubtitle(ep.name).setArtworkUri(detail.toItem().thumbImage?.let(android.net.Uri::parse)).build(),
                ).build(),
            )
            val record = Library.record(detail.slug)
            // Synced Flutter positions are keyed by episode name.
            val resume = record?.positions?.get(ep.slug.orEmpty()) ?: record?.positions?.get(ep.name.orEmpty()) ?: 0.0
            val total = record?.durations?.get(ep.slug.orEmpty()) ?: 0.0
            if (resume > 5 && (total == 0.0 || resume < total - 20)) exo.seekTo((resume * 1000).toLong())
            exo.prepare()
            exo.play()
            save()
            interact()
        }

        // Network loss: show a banner, then resume at the same spot once the connection is back
        // (as many times as it takes). Other stream errors retry up to 3 times.
        val online by rememberOnline()
        var recoveries by remember(server, index) { mutableIntStateOf(0) }
        LaunchedEffect(playback.error, online) {
            val e = playback.error ?: return@LaunchedEffect
            val network = e.errorCode in 2000..2999
            if (network && !online) return@LaunchedEffect  // wait; this effect reruns when online flips
            if (!network && e.errorCode != androidx.media3.common.PlaybackException.ERROR_CODE_BEHIND_LIVE_WINDOW) return@LaunchedEffect
            if (online && !network && recoveries >= 3) return@LaunchedEffect
            recoveries++
            val at = exo.currentPosition
            delay(if (network) 500L else 1_000L * recoveries)
            exo.seekTo(at)
            playback.retry()
        }

        // Keep the screen awake while a film plays (the view's keepScreenOn alone wasn't reliable);
        // let it sleep again when paused or finished.
        LaunchedEffect(playback.isPlaying) {
            if (playback.isPlaying) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }

        // Save every 10 s while playing.
        LaunchedEffect(Unit) {
            while (true) {
                delay(10_000)
                if (exo.isPlaying) save()
            }
        }

        // Controls fade out 3 s after the last touch while playing.
        LaunchedEffect(lastInteraction, playback.isPlaying, panel) {
            if (!playback.isPlaying || panel != Panel.None) return@LaunchedEffect
            delay(3_000)
            controlsVisible = false
        }

        // Sleep timer.
        LaunchedEffect(sleepAt) {
            if (sleepAt <= 0) return@LaunchedEffect
            delay((sleepAt - System.currentTimeMillis()).coerceAtLeast(0))
            exo.pause()
            sleepMinutes = 0
            sleepAt = 0
            controlsVisible = true
        }
        // "End of this episode": pause instead of auto-advancing.
        LaunchedEffect(playback.ended, sleepMinutes) {
            if (playback.ended && sleepMinutes == -1) { sleepMinutes = 0; controlsVisible = true }
        }

        BackHandler(enabled = panel != Panel.None || locked) {
            if (panel != Panel.None) panel = Panel.None else { locked = false; interact() }
        }

        Box(Modifier.fillMaxSize().background(Color.Black)) {
            AndroidView(
                factory = { ctx ->
                    PlayerView(ctx).apply {
                        useController = false
                        keepScreenOn = true
                        player = exo
                    }
                },
                update = {
                    it.resizeMode = when {
                        aspect == AspectMode.Fill -> AspectRatioFrameLayout.RESIZE_MODE_FILL
                        aspect == AspectMode.Zoom || gestures.zoomed -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                        else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
                    }
                },
                modifier = Modifier.fillMaxSize().then(
                    if (inPip) Modifier else gestures.modifier(enabled = !locked && panel == Panel.None) {
                        if (panel != Panel.None) panel = Panel.None
                        else if (controlsVisible) controlsVisible = false else interact()
                    },
                ),
            )

            if (!inPip) {
                PlayerControls(
                    playback = playback,
                    gestures = gestures,
                    title = detail.name,
                    episodeName = episode?.name.orEmpty(),
                    nextEpisodeName = nextIndex?.let { episodes[it].name ?: "Tập ${it + 1}" },
                    nextThumb = detail.toItem().thumbImage,
                    visible = controlsVisible,
                    locked = locked,
                    hasEpisodes = episodes.size > 1 || servers.size > 1,
                    offline = !online,
                    sleepLabel = when (sleepMinutes) { 0 -> null; -1 -> "Hẹn giờ: hết tập"; else -> "Hẹn giờ: $sleepMinutes phút" },
                    onBack = { finish() },
                    onInteract = ::interact,
                    onToggleLock = { locked = !locked; interact() },
                    onPip = { enterPip() },
                    onSettings = { panel = Panel.Settings; interact() },
                    onEpisodes = { panel = Panel.Episodes; interact() },
                    onNext = { if (sleepMinutes != -1) nextIndex?.let { switchTo(server, it) } },
                )

                AnimatedVisibility(
                    panel != Panel.None,
                    enter = slideInHorizontally { it } + fadeIn(),
                    exit = slideOutHorizontally { it } + fadeOut(),
                    modifier = Modifier.align(Alignment.CenterEnd),
                ) {
                    when (panel) {
                        Panel.Settings -> SettingsPanel(
                            playback = playback,
                            aspect = aspect,
                            onAspect = { aspect = it; gestures.zoomed = it == AspectMode.Zoom },
                            sleepMinutes = sleepMinutes,
                            onSleep = { m ->
                                sleepMinutes = m
                                sleepAt = if (m > 0) System.currentTimeMillis() + m * 60_000L else 0
                            },
                            onClose = { panel = Panel.None },
                        )
                        else -> EpisodePanel(serverNames, servers, server, index, onPick = ::switchTo, onClose = { panel = Panel.None })
                    }
                }
            }
        }
    }

    private fun pipParams(): PictureInPictureParams {
        val b = PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) b.setAutoEnterEnabled(true).setSeamlessResizeEnabled(true)
        return b.build()
    }

    private fun enterPip() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) enterPictureInPictureMode(pipParams())
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Android 12+ auto-enters via setAutoEnterEnabled; earlier versions do it here.
        if (exo.isPlaying && Build.VERSION.SDK_INT in Build.VERSION_CODES.O until Build.VERSION_CODES.S) enterPip()
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        inPip = isInPictureInPictureMode
    }

    override fun onStop() {
        super.onStop()
        saveNow()
        if (!isInPictureInPictureMode) exo.pause()
    }

    override fun onDestroy() {
        saveNow()
        session?.release()
        exo.release()
        super.onDestroy()
    }

    companion object {
        const val EXTRA_DETAIL = "detail"
        const val EXTRA_SERVER = "server"
        const val EXTRA_INDEX = "index"
    }
}
