package com.thientech.tmovie.tv

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.player.Player

private const val EpisodeBlock = 50

/**
 * A film, Apple TV style: full-screen key art with the details and Play / My List low on the
 * left; below the fold the server, episode (with watched progress) and similar rows, the art
 * dimming away once they scroll up.
 */
@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun DetailPage(film: FilmItem, top: Boolean, onOpen: (FilmItem) -> Unit) {
    val context = LocalContext.current
    val detail by produceState<FilmDetail?>(null, film.slug) { value = runCatching { PhimApi.shared.detail(film.slug) }.getOrNull() }
    val backdrop by produceState<String?>(null, film.slug) {
        value = runCatching { PhimApi.shared.images(film.slug) }.getOrDefault(emptyList())
            .let { imgs -> imgs.firstOrNull { it.type == "backdrop" && it.iso6391 == null } ?: imgs.firstOrNull { it.type == "backdrop" } }?.url("w1280")
    }
    val similar by produceState(emptyList<FilmItem>(), film.slug) {
        val genre = film.category?.firstOrNull()?.slug ?: return@produceState
        value = runCatching { PhimApi.shared.list(Source.Genre(genre)).items }.getOrDefault(emptyList()).filter { it.slug != film.slug }
    }
    val history by Library.history.collectAsStateWithLifecycle()
    val saved by Library.saved.collectAsStateWithLifecycle()
    val record = history.firstOrNull { it.film.slug == film.slug }
    val isSaved = saved.any { it.film.slug == film.slug }
    val d = detail
    val item = d?.toItem() ?: film
    val servers = d?.episodes.orEmpty()
    var server by remember(d) { mutableIntStateOf(record?.serverIndex?.coerceIn(0, (servers.size - 1).coerceAtLeast(0)) ?: 0) }
    val episodes = servers.getOrNull(server)?.serverData.orEmpty()
    val current = record?.takeIf { it.serverIndex == server }?.episodeIndex ?: 0
    var block by remember(d, server) { mutableIntStateOf(current / EpisodeBlock) }

    val play = remember { FocusRequester() }
    LaunchedEffect(Unit) { runCatching { play.requestFocus() } }
    val list = rememberLazyListState()
    val scrolled by remember { derivedStateOf { list.firstVisibleItemIndex > 0 || list.firstVisibleItemScrollOffset > 200 } }
    val dim by animateFloatAsState(if (scrolled) 0.88f else 0f, label = "dim")

    BoxWithConstraints(Modifier.fillMaxSize().background(TMovieColors.Canvas)) {
        val w = maxWidth
        val h = maxHeight
        Backdrop(backdrop ?: item.thumbImage)
        Box(Modifier.fillMaxSize().graphicsLayer { alpha = dim }.background(TMovieColors.Canvas))
        LazyColumn(Modifier.fillMaxSize(), list, contentPadding = PaddingValues(bottom = 64.dp)) {
            item("info") {
                Box(Modifier.fillMaxWidth().height(h * 0.92f)) {
                    Column(Modifier.align(Alignment.BottomStart).padding(start = Tv.Start, bottom = 32.dp).width(w * 0.56f)) {
                        Text(item.name, style = Tv.Title, color = Color.White, maxLines = 2, overflow = TextOverflow.Ellipsis)
                        item.originName?.takeIf { it.isNotBlank() && it != item.name }?.let {
                            Text(it, color = TMovieColors.Secondary, fontSize = 18.sp, maxLines = 1, modifier = Modifier.padding(top = 4.dp))
                        }
                        Row(Modifier.padding(top = 14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            item.rating?.let { Text("★ ${"%.1f".format(it)}", color = Color(0xFFFFD166), fontSize = 17.sp, fontWeight = FontWeight.Bold) }
                            Text(item.metaLine(), color = Color.White.copy(alpha = 0.9f), fontSize = 17.sp, fontWeight = FontWeight.Medium, maxLines = 1)
                            item.quality?.takeIf { it.isNotBlank() }?.let { Badge(it) }
                        }
                        Text(item.genreLine(), color = TMovieColors.Secondary, fontSize = 16.sp, maxLines = 1, modifier = Modifier.padding(top = 6.dp))
                        d?.content?.let { html ->
                            Text(html.replace(Regex("<[^>]*>"), "").replace("&nbsp;", " ").trim(), color = Color.White.copy(alpha = 0.85f), fontSize = 17.sp,
                                lineHeight = 25.sp, maxLines = 3, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 14.dp))
                        }
                        d?.actor?.filter { it.isNotBlank() }?.takeIf { it.isNotEmpty() }?.let {
                            Text("Diễn viên: ${it.take(4).joinToString(", ")}", color = TMovieColors.Secondary, fontSize = 16.sp, maxLines = 1,
                                overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 8.dp))
                        }
                        Row(
                            Modifier.padding(top = 24.dp).focusRestorer(play),
                            horizontalArrangement = Arrangement.spacedBy(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            val label = when {
                                d == null -> "Đang tải…"
                                !d.isPlayable -> "Chưa có tập để xem"
                                record != null -> "Tiếp tục · ${record.episodeName.ifBlank { "Tập ${record.episodeIndex + 1}" }}"
                                else -> "Phát"
                            }
                            Chip(label, { if (d != null && top) Player.start(context, d, fromDetail = true) }, focusRequester = play) { fg ->
                                if (d == null) CircularProgressIndicator(Modifier.size(20.dp), color = fg, strokeWidth = 2.dp)
                                else Icon(Icons.Rounded.PlayArrow, null, tint = fg, modifier = Modifier.size(28.dp))
                            }
                            RoundButton({ Library.toggleSaved(item) }) { fg ->
                                Icon(if (isSaved) Icons.Rounded.Check else Icons.Rounded.Add, if (isSaved) "Bỏ khỏi danh sách" else "Thêm vào danh sách", tint = fg, modifier = Modifier.size(26.dp))
                            }
                        }
                    }
                }
            }
            if (servers.size > 1) item("servers") {
                Row(Modifier.padding(start = Tv.Start, top = 8.dp).focusRestorer(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    servers.forEachIndexed { i, s -> Chip(s.serverName ?: "Server ${i + 1}", { server = i }, selected = i == server) }
                }
            }
            // Long series: pick a block of 50 first, so reaching episode 300 isn't 300 presses.
            if (d != null && episodes.size > EpisodeBlock) item("blocks") {
                Pivot(Tv.Start) {
                    LazyRow(
                        Modifier.focusRestorer(),
                        contentPadding = PaddingValues(start = Tv.Start, end = Tv.End, top = 12.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items((episodes.indices step EpisodeBlock).toList(), { it }) { from ->
                            Chip("${from + 1}–${minOf(from + EpisodeBlock, episodes.size)}", { block = from / EpisodeBlock }, selected = block == from / EpisodeBlock)
                        }
                    }
                }
            }
            if (d != null && (episodes.size > 1 || servers.size > 1)) item("episodes") {
                val shown = episodes.withIndex().toList().let { all -> if (all.size > EpisodeBlock) all.drop(block * EpisodeBlock).take(EpisodeBlock) else all }
                Shelf("Tập phim · ${episodes.size}", shown, { it.index }) { (i, ep) ->
                    val progress = record?.progress(ep.slug.orEmpty()) ?: 0f
                    FocusCard(
                        { if (top && ep.streamUrl != null) Player.play(context, d, server, i, fromDetail = true) },
                        Modifier.width(156.dp).height(68.dp),
                        RoundedCornerShape(10.dp),
                    ) { focused ->
                        Box(Modifier.fillMaxSize().background(if (focused) Color.White else if (i == current && record != null) TMovieColors.Brand.copy(alpha = 0.35f) else Color.White.copy(alpha = 0.1f)))
                        Text(ep.name ?: "Tập ${i + 1}", color = if (focused) Color.Black else Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold,
                            maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.align(Alignment.Center).padding(horizontal = 10.dp))
                        if (progress > 0f) Box(Modifier.align(Alignment.BottomStart).fillMaxWidth(progress).height(4.dp).background(TMovieColors.BrandLight))
                    }
                }
            }
            if (similar.isNotEmpty()) item("similar") {
                Shelf("Có thể bạn thích", similar, { it.slug }) { f -> WideCard(f, { onOpen(f) }) }
            }
        }
    }
}
