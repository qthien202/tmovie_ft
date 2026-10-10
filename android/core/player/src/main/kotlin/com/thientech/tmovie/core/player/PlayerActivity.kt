package com.thientech.tmovie.core.player

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.Rational
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.VideoLibrary
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player as Media3Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieTheme
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.model.ServerData
import com.thientech.tmovie.core.network.PhimApi
import kotlinx.coroutines.delay

/**
 * Full-screen landscape HLS player: Media3 controls, resume, progress saved every 10s,
 * "Tập tiếp theo" in the last 18s with auto-advance, an episode panel, and Picture-in-Picture.
 */
@OptIn(UnstableApi::class)
class PlayerActivity : ComponentActivity() {
    private lateinit var exo: ExoPlayer
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
        exo = ExoPlayer.Builder(this).build()

        setContent {
            TMovieTheme {
                PlayerScreen(detail, startServer, startIndex)
            }
        }
    }

    @Composable
    private fun PlayerScreen(detail: FilmDetail, startServer: Int, startIndex: Int) {
        val servers = detail.episodes.orEmpty().map { it.serverData.orEmpty() }
        var server by remember { mutableIntStateOf(startServer) }
        var index by remember { mutableIntStateOf(startIndex) }
        var controlsVisible by remember { mutableStateOf(true) }
        var nearEnd by remember { mutableStateOf(false) }
        var panelOpen by remember { mutableStateOf(false) }
        val episodes = servers.getOrNull(server).orEmpty()
        val episode = episodes.getOrNull(index)
        val nextIndex = (index + 1 until episodes.size).firstOrNull { episodes[it].streamUrl != null }

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
            panelOpen = false
        }

        // Load the episode, resuming unless it was basically finished.
        LaunchedEffect(server, index) {
            val ep = episode ?: return@LaunchedEffect
            val url = ep.streamUrl ?: return@LaunchedEffect
            nearEnd = false
            exo.setMediaItem(
                MediaItem.Builder().setUri(url).setMediaMetadata(
                    MediaMetadata.Builder().setTitle(detail.name).setSubtitle(ep.name).build(),
                ).build(),
            )
            val record = Library.record(detail.slug)
            val resume = record?.positions?.get(ep.slug.orEmpty()) ?: 0.0
            val total = record?.durations?.get(ep.slug.orEmpty()) ?: 0.0
            if (resume > 5 && (total == 0.0 || resume < total - 20)) exo.seekTo((resume * 1000).toLong())
            exo.prepare()
            exo.play()
            save()
        }

        // Save every 10s and watch for the last 18s.
        LaunchedEffect(Unit) {
            while (true) {
                delay(1000)
                val d = exo.duration
                nearEnd = d > 0 && d - exo.currentPosition <= 18_000
                if ((exo.currentPosition / 1000) % 10 == 0L && exo.isPlaying) save()
            }
        }

        DisposableEffect(nextIndex) {
            val listener = object : Media3Player.Listener {
                override fun onPlaybackStateChanged(state: Int) {
                    if (state == Media3Player.STATE_ENDED) nextIndex?.let { switchTo(server, it) }
                }
            }
            exo.addListener(listener)
            onDispose { exo.removeListener(listener) }
        }

        Box(Modifier.fillMaxSize().background(Color.Black)) {
            AndroidView(
                factory = { ctx ->
                    PlayerView(ctx).apply {
                        player = exo
                        keepScreenOn = true
                        setShowNextButton(false)
                        setShowPreviousButton(false)
                        setControllerVisibilityListener(PlayerView.ControllerVisibilityListener { controlsVisible = it == android.view.View.VISIBLE })
                    }
                },
                update = { it.useController = !inPip },
                modifier = Modifier.fillMaxSize(),
            )

            if (!inPip) {
                // Top bar: back, title, episodes — follows the Media3 controller's visibility.
                AnimatedVisibility(controlsVisible, enter = fadeIn(), exit = fadeOut(), modifier = Modifier.align(Alignment.TopCenter)) {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .background(Brush.verticalGradient(listOf(Color.Black.copy(alpha = 0.7f), Color.Transparent)))
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        IconButton(onClick = { finish() }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Quay lại", tint = Color.White) }
                        Column(Modifier.weight(1f).padding(horizontal = 8.dp)) {
                            Text(detail.name, color = Color.White, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            Text(episode?.name.orEmpty(), color = TMovieColors.Secondary, fontSize = 13.sp, maxLines = 1)
                        }
                        if (episodes.size > 1 || servers.size > 1) {
                            Row(
                                Modifier.clip(CircleShape).glass(CircleShape).clickable { panelOpen = true }.padding(horizontal = 16.dp, vertical = 10.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Icon(Icons.Filled.VideoLibrary, null, tint = Color.White, modifier = Modifier.size(18.dp))
                                Text("Tập phim", color = Color.White, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(start = 6.dp))
                            }
                        }
                    }
                }

                AnimatedVisibility(
                    nearEnd && nextIndex != null,
                    enter = fadeIn() + slideInVertically { it / 2 },
                    exit = fadeOut() + slideOutVertically { it / 2 },
                    modifier = Modifier.align(Alignment.BottomEnd).padding(end = 24.dp, bottom = 96.dp),
                ) {
                    Row(
                        Modifier.clip(CircleShape).background(Color.White).clickable { nextIndex?.let { switchTo(server, it) } }
                            .padding(horizontal = 20.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.SkipNext, null, tint = Color.Black)
                        Text("Tập tiếp theo", color = Color.Black, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(start = 6.dp))
                    }
                }

                AnimatedVisibility(
                    panelOpen,
                    enter = slideInHorizontally { it } + fadeIn(),
                    exit = slideOutHorizontally { it } + fadeOut(),
                    modifier = Modifier.align(Alignment.CenterEnd),
                ) {
                    EpisodePanel(
                        servers = detail.episodes.orEmpty().mapIndexed { i, e -> e.serverName ?: "Server ${i + 1}" },
                        lists = servers,
                        currentServer = server,
                        currentIndex = index,
                        onPick = ::switchTo,
                        onClose = { panelOpen = false },
                    )
                }
            }
        }
    }

    @Composable
    private fun EpisodePanel(
        servers: List<String>,
        lists: List<List<ServerData>>,
        currentServer: Int,
        currentIndex: Int,
        onPick: (Int, Int) -> Unit,
        onClose: () -> Unit,
    ) {
        var shown by remember { mutableIntStateOf(currentServer) }
        Column(
            Modifier.fillMaxHeight().width(380.dp).background(Color(0xF00B0F12)).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Danh sách tập", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                IconButton(onClick = onClose) { Icon(Icons.Filled.Close, "Đóng", tint = Color.White) }
            }
            if (servers.size > 1) {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    itemsIndexed(servers) { i, name ->
                        Text(
                            name,
                            color = if (i == shown) Color.Black else Color.White,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.clip(CircleShape)
                                .background(if (i == shown) Color.White else Color.White.copy(alpha = 0.12f))
                                .clickable { shown = i }
                                .padding(horizontal = 14.dp, vertical = 8.dp),
                        )
                    }
                }
            }
            LazyVerticalGrid(
                GridCells.Fixed(3),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(bottom = 16.dp),
            ) {
                itemsIndexed(lists.getOrNull(shown).orEmpty()) { i, ep ->
                    val current = shown == currentServer && i == currentIndex
                    Box(
                        Modifier
                            .height(44.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (current) TMovieColors.Brand else Color.White.copy(alpha = 0.10f))
                            .clickable(enabled = ep.streamUrl != null) { onPick(shown, i) },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            ep.name ?: "${i + 1}",
                            color = if (ep.streamUrl == null) Color.White.copy(alpha = 0.3f) else Color.White,
                            fontWeight = FontWeight.SemiBold,
                            maxLines = 1,
                        )
                    }
                }
            }
            Spacer(Modifier.height(8.dp))
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (exo.isPlaying && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            enterPictureInPictureMode(PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9)).build())
        }
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
        exo.release()
        super.onDestroy()
    }

    companion object {
        const val EXTRA_DETAIL = "detail"
        const val EXTRA_SERVER = "server"
        const val EXTRA_INDEX = "index"
    }
}
