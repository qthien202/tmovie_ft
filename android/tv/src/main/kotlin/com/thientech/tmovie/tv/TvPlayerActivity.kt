package com.thientech.tmovie.tv

import android.net.Uri
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.annotation.OptIn
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieTheme
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.player.PlaybackState
import com.thientech.tmovie.core.player.PlayerActivity
import com.thientech.tmovie.core.player.StreamPlayer
import com.thientech.tmovie.core.player.TrackOption
import com.thientech.tmovie.core.player.formatTime
import com.thientech.tmovie.core.player.rememberOnline
import com.thientech.tmovie.core.player.rememberPlaybackState
import kotlinx.coroutines.delay

/**
 * The remote's player (same extras as the phone's PlayerActivity, same ad-free stream and resume
 * points). OK plays / pauses, ◀ ▶ seek (longer the longer they're held), ▼ opens episodes and
 * quality / audio / subtitles / speed, Back closes the panel or the player.
 */
@OptIn(UnstableApi::class)
class TvPlayerActivity : ComponentActivity() {
    private lateinit var exo: ExoPlayer
    private var saveNow: () -> Unit = {}
    private var slug: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val liveUrl = intent.getStringExtra(PlayerActivity.EXTRA_LIVE_URL)
        val detail = intent.getStringExtra(PlayerActivity.EXTRA_DETAIL)?.let { PhimApi.json.decodeFromString(FilmDetail.serializer(), it) }
        if (detail == null && liveUrl == null) return finish()
        slug = detail?.slug
        exo = if (liveUrl != null) {
            StreamPlayer.create(this, live = true, userAgent = intent.getStringExtra(PlayerActivity.EXTRA_LIVE_USER_AGENT), referrer = intent.getStringExtra(PlayerActivity.EXTRA_LIVE_REFERRER))
        } else {
            StreamPlayer.create(this)
        }
        setContent {
            TMovieTheme {
                if (detail != null) FilmPlayer(detail, intent.getIntExtra(PlayerActivity.EXTRA_SERVER, 0), intent.getIntExtra(PlayerActivity.EXTRA_INDEX, 0))
                else LivePlayer(intent.getStringExtra(PlayerActivity.EXTRA_LIVE_NAME).orEmpty(), liveUrl!!)
            }
        }
    }

    override fun onStop() {
        super.onStop()
        saveNow()
        if (::exo.isInitialized) exo.pause()
        slug?.let(Library::record)?.let { WatchNext.publish(this, it) }
    }

    override fun onDestroy() {
        if (::exo.isInitialized) { saveNow(); exo.release() }
        super.onDestroy()
    }

    @Composable
    private fun FilmPlayer(detail: FilmDetail, startServer: Int, startIndex: Int) {
        val servers = detail.episodes.orEmpty().map { it.serverData.orEmpty() }
        var server by remember { mutableIntStateOf(startServer) }
        var index by remember { mutableIntStateOf(startIndex) }
        val episodes = servers.getOrNull(server).orEmpty()
        val episode = episodes.getOrNull(index)
        val nextIndex = (index + 1 until episodes.size).firstOrNull { episodes[it].streamUrl != null }
        val playback = rememberPlaybackState(exo)

        fun save() {
            val ep = episode ?: return
            Library.save(
                film = detail.toItem(), server = server, episode = index, episodeName = ep.name.orEmpty(), episodeSlug = ep.slug.orEmpty(),
                position = exo.currentPosition / 1000.0, duration = exo.duration.takeIf { it > 0 }?.div(1000.0) ?: 0.0,
            )
        }
        saveNow = ::save
        fun switchTo(s: Int, i: Int) { save(); server = s; index = i }

        // Load the episode, resuming unless it was basically finished.
        LaunchedEffect(server, index) {
            val ep = episode ?: return@LaunchedEffect
            val url = ep.streamUrl ?: return@LaunchedEffect
            exo.setMediaItem(MediaItem.Builder().setUri(url).setMediaMetadata(MediaMetadata.Builder().setTitle(detail.name).setSubtitle(ep.name).build()).build())
            val record = Library.record(detail.slug)
            val resume = record?.positions?.get(ep.slug.orEmpty()) ?: record?.positions?.get(ep.name.orEmpty()) ?: 0.0
            val total = record?.durations?.get(ep.slug.orEmpty()) ?: 0.0
            if (resume > 5 && (total == 0.0 || resume < total - 20)) exo.seekTo((resume * 1000).toLong())
            exo.prepare()
            exo.play()
            save()
        }
        LaunchedEffect(Unit) { while (true) { delay(10_000); if (exo.isPlaying) save() } }
        LaunchedEffect(playback.ended) { if (playback.ended) nextIndex?.let { switchTo(server, it) } }

        // Network loss: wait, then resume at the same spot; other stream errors retry up to 3 times.
        val online by rememberOnline()
        var recoveries by remember(server, index) { mutableIntStateOf(0) }
        LaunchedEffect(playback.error, online) {
            val e = playback.error ?: return@LaunchedEffect
            val network = e.errorCode in 2000..2999
            if (network && !online) return@LaunchedEffect
            if (!network || recoveries >= 3) return@LaunchedEffect
            recoveries++
            val at = exo.currentPosition
            delay(500L * recoveries)
            exo.seekTo(at)
            playback.retry()
        }

        PlayerScreen(
            playback = playback,
            title = detail.name,
            subtitle = episode?.name?.let { if (servers.size > 1) "$it · ${detail.episodes?.getOrNull(server)?.serverName.orEmpty()}" else it }.orEmpty(),
            live = false,
            offline = !online,
            onNext = nextIndex?.let { { switchTo(server, it) } },
        ) { focus ->
            if (episodes.size > 1) {
                val state = rememberLazyListState(initialFirstVisibleItemIndex = (index - 2).coerceAtLeast(0))
                PanelRow("Tập phim · ${episodes.size}") {
                    Pivot(Tv.Start) {
                        LazyRow(Modifier.focusRestorer(), state, PaddingValues(start = Tv.Start, end = Tv.End, top = 8.dp, bottom = 8.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            itemsIndexed(episodes, { i, _ -> i }) { i, ep ->
                                val label = ep.name ?: "Tập ${i + 1}"
                                if (i == index) Chip(label, {}, selected = true, focusRequester = focus)
                                else Chip(label, { switchTo(server, i) })
                            }
                        }
                    }
                }
            }
            if (servers.size > 1) {
                Options("Nguồn", detail.episodes.orEmpty().mapIndexed { i, e -> TrackOption(e.serverName ?: "Server ${i + 1}", i == server) { switchTo(i, index.coerceAtMost(servers[i].size - 1)) } },
                    if (episodes.size > 1) null else focus)
            }
            TrackRows(playback, if (episodes.size > 1 || servers.size > 1) null else focus)
        }
    }

    @Composable
    private fun LivePlayer(name: String, url: String) {
        val playback = rememberPlaybackState(exo)
        val online by rememberOnline()
        LaunchedEffect(Unit) {
            val uri = Uri.parse(url)
            // Playlist URLs often hide the .m3u8 (`/live/kgtv`, `chunklist`): anything not obviously a file is HLS.
            val ext = uri.path.orEmpty().substringAfterLast('/').substringAfterLast('.', "").lowercase()
            val hls = ext !in setOf("mp4", "mkv", "ts", "webm", "mp3", "aac")
            exo.setMediaItem(MediaItem.Builder().setUri(uri).apply { if (hls) setMimeType(MimeTypes.APPLICATION_M3U8) }.setMediaMetadata(MediaMetadata.Builder().setTitle(name).build()).build())
            exo.prepare()
            exo.play()
        }
        // Fell behind the live window (a stall), or the network is back: rejoin the live edge.
        LaunchedEffect(playback.error, online) {
            val e = playback.error ?: return@LaunchedEffect
            if (e.errorCode == PlaybackException.ERROR_CODE_BEHIND_LIVE_WINDOW || (online && e.errorCode in 2000..2999)) {
                delay(500)
                exo.seekToDefaultPosition()
                playback.retry()
            }
        }
        PlayerScreen(playback, name, "", live = true, offline = !online, onNext = null) { focus -> TrackRows(playback, focus) }
    }

    @Composable
    private fun TrackRows(playback: PlaybackState, focus: FocusRequester?) {
        Options("Chất lượng", playback.qualityOptions(), focus)
        playback.subtitleOptions().takeIf { it.size > 1 }?.let { Options("Phụ đề", it) }
        playback.audioOptions().takeIf { it.size > 1 }?.let { Options("Âm thanh", it) }
        val speeds = listOf(0.75f, 1f, 1.25f, 1.5f, 2f)
        Options("Tốc độ", speeds.map { s -> TrackOption(if (s == 1f) "Bình thường" else "${s.toString().removeSuffix(".0")}×", s == playback.speed) { playback.changeSpeed(s) } })
    }

    /**
     * Video, chrome and the remote's keys. [panel] fills the ▼ sheet; its FocusRequester goes on
     * the chip that should take focus when the sheet opens.
     */
    @kotlin.OptIn(ExperimentalComposeUiApi::class)
    @Composable
    private fun PlayerScreen(
        playback: PlaybackState,
        title: String,
        subtitle: String,
        live: Boolean,
        offline: Boolean,
        onNext: (() -> Unit)?,
        panel: @Composable (FocusRequester) -> Unit,
    ) {
        var visible by remember { mutableStateOf(true) }
        var lastKey by remember { mutableLongStateOf(System.currentTimeMillis()) }
        var sheet by remember { mutableStateOf(false) }
        val root = remember { FocusRequester() }
        val sheetFocus = remember { FocusRequester() }
        fun show() { visible = true; lastKey = System.currentTimeMillis() }

        LaunchedEffect(Unit) { root.requestFocus() }
        LaunchedEffect(sheet) {
            withFrameNanos {}
            runCatching { if (sheet) sheetFocus.requestFocus() else root.requestFocus() }
        }
        LaunchedEffect(lastKey, playback.isPlaying, sheet) {
            if (!playback.isPlaying || sheet) return@LaunchedEffect
            delay(4_000)
            visible = false
        }
        // The TV may dim / start its screensaver while paused, never while a film plays.
        LaunchedEffect(playback.isPlaying) {
            if (playback.isPlaying) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
        BackHandler(sheet) { sheet = false; show() }

        fun onKey(e: KeyEvent): Boolean {
            // Back here, not via the dispatcher: Compose spends a focused Back on clearing focus.
            if (e.key == Key.Back) {
                if (e.type == KeyEventType.KeyUp) { if (sheet) { sheet = false; show() } else finish() }
                return true
            }
            if (sheet || e.type != KeyEventType.KeyDown) return false
            val wasVisible = visible
            show()
            // Held ◀ ▶ speed up: 10 s, then 30 s, then a minute per repeat.
            val step = when (e.nativeKeyEvent.repeatCount) { in 0..3 -> 10_000L; in 4..12 -> 30_000L; else -> 60_000L }
            when (e.key) {
                Key.DirectionCenter, Key.Enter, Key.NumPadEnter, Key.MediaPlayPause, Key.Spacebar ->
                    if (playback.error != null) playback.retry() else playback.toggle()
                Key.MediaPlay -> exo.play()
                Key.MediaPause -> exo.pause()
                Key.DirectionLeft, Key.MediaRewind -> if (!live) playback.seekBy(-step)
                Key.DirectionRight, Key.MediaFastForward -> if (!live) playback.seekBy(step)
                Key.DirectionDown, Key.Menu -> if (wasVisible) sheet = true
                Key.DirectionUp -> {}
                Key.MediaNext, Key.ChannelUp -> onNext?.invoke() ?: return false
                else -> return false
            }
            return true
        }

        Box(
            Modifier
                .fillMaxSize()
                .background(Color.Black)
                .onPreviewKeyEvent(::onKey)
                .focusRequester(root)
                .focusable(),
        ) {
            AndroidView({ PlayerView(it).apply { useController = false; player = exo } }, Modifier.fillMaxSize())
            Chrome(playback, title, subtitle, live, offline, (visible || !playback.isPlaying) && !sheet)
            AnimatedVisibility(sheet, Modifier.align(Alignment.BottomCenter), enter = slideInVertically { it / 3 } + fadeIn(), exit = slideOutVertically { it / 3 } + fadeOut()) {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.85f), Color.Black.copy(alpha = 0.95f))))
                        .padding(top = 64.dp, bottom = 28.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) { panel(sheetFocus) }
            }
        }
    }
}

@Composable
private fun BoxScope.Chrome(playback: PlaybackState, title: String, subtitle: String, live: Boolean, offline: Boolean, visible: Boolean) {
    AnimatedVisibility(visible, Modifier.matchParentSize(), enter = fadeIn(), exit = fadeOut()) {
        Box(Modifier.fillMaxSize()) {
            Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().height(300.dp).background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.9f)))))
            // Apple TV: title and episode sit just above the scrubber.
            Column(Modifier.align(Alignment.BottomStart).fillMaxWidth().padding(horizontal = 56.dp, vertical = 32.dp)) {
                if (subtitle.isNotBlank()) Text(subtitle, color = TMovieColors.Secondary, fontSize = 18.sp, fontWeight = FontWeight.Medium, maxLines = 1)
                Text(title, color = Color.White, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(bottom = 18.dp))
                if (live) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(10.dp).clip(CircleShape).background(Color(0xFFFF3B30)))
                        Text("TRỰC TIẾP", color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = 8.dp))
                    }
                } else {
                    val d = playback.duration.coerceAtLeast(1)
                    Box(Modifier.fillMaxWidth().height(6.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.2f))) {
                        Box(Modifier.fillMaxHeight().fillMaxWidth((playback.buffered.toFloat() / d).coerceIn(0f, 1f)).background(Color.White.copy(alpha = 0.35f)))
                        Box(Modifier.fillMaxHeight().fillMaxWidth((playback.position.toFloat() / d).coerceIn(0f, 1f)).background(TMovieColors.BrandLight))
                    }
                    Row(Modifier.fillMaxWidth().padding(top = 10.dp)) {
                        Text(formatTime(playback.position), color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Medium)
                        Spacer(Modifier.weight(1f))
                        Text("-" + formatTime((playback.duration - playback.position).coerceAtLeast(0)), color = TMovieColors.Secondary, fontSize = 16.sp)
                    }
                }
                Text(
                    if (live) "OK  Tạm dừng      ▼  Chất lượng & phụ đề" else "OK  Tạm dừng      ◀ ▶  Tua (giữ để tua nhanh)      ▼  Tập & cài đặt",
                    color = Color.White.copy(alpha = 0.6f), fontSize = 16.sp, modifier = Modifier.padding(top = 14.dp),
                )
            }
        }
    }
    val error = playback.error
    when {
        error != null -> Column(Modifier.align(Alignment.Center).clip(RoundedCornerShape(16.dp)).background(Color.Black.copy(alpha = 0.75f)).padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally) {
            Text(if (offline) "Mất kết nối mạng" else if (live) "Kênh này hiện không phát được" else "Không phát được tập này", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Text(if (offline) "Sẽ tự phát tiếp khi có mạng lại." else "Nhấn OK để thử lại.", color = TMovieColors.Secondary, fontSize = 16.sp, modifier = Modifier.padding(top = 8.dp))
        }
        playback.buffering -> CircularProgressIndicator(Modifier.align(Alignment.Center).size(56.dp), color = TMovieColors.BrandLight, strokeWidth = 4.dp)
        !playback.isPlaying -> Box(Modifier.align(Alignment.Center).size(96.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.5f)), contentAlignment = Alignment.Center) {
            Icon(Icons.Rounded.PlayArrow, "Phát", tint = Color.White, modifier = Modifier.size(60.dp))
        }
    }
}

@Composable
private fun PanelRow(title: String, content: @Composable () -> Unit) {
    Column {
        Text(title, color = Color.White.copy(alpha = 0.9f), fontSize = 18.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(start = Tv.Start))
        content()
    }
}

/** A titled row of choices; [focus] (when given) goes on the selected one. */
@kotlin.OptIn(ExperimentalComposeUiApi::class)
@Composable
private fun Options(title: String, options: List<TrackOption>, focus: FocusRequester? = null) {
    if (options.isEmpty()) return
    PanelRow(title) {
        Pivot(Tv.Start) {
            LazyRow(Modifier.focusRestorer(), contentPadding = PaddingValues(start = Tv.Start, end = Tv.End, top = 8.dp, bottom = 8.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                itemsIndexed(options, { i, _ -> i }) { _, o ->
                    if (focus != null && o.selected) Chip(o.label, o.apply, selected = true, focusRequester = focus)
                    else Chip(o.label, o.apply, selected = o.selected)
                }
            }
        }
    }
}
