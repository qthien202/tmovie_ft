package com.thientech.tmovie.tv

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
import androidx.compose.foundation.lazy.itemsIndexed
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.player.Player

/**
 * A film: key art and details on top, then Play / My List, the server and episode rows (with
 * watched progress) and similar films.
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

    val play = remember { FocusRequester() }
    LaunchedEffect(Unit) { runCatching { play.requestFocus() } }

    BoxWithConstraints(Modifier.fillMaxSize().background(TMovieColors.Canvas)) {
        Backdrop(backdrop ?: item.thumbImage)
        // Plain scrolling here (no pivot): the details stay up while Play has focus.
        LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = 48.dp)) {
            item("info") {
                Column(Modifier.padding(start = Tv.Start, top = 48.dp, end = Tv.End).width(maxWidth * 0.55f)) {
                    Text(item.name, style = TMovieType.Display.copy(fontSize = 44.sp, lineHeight = 50.sp), color = Color.White, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    item.originName?.takeIf { it.isNotBlank() && it != item.name }?.let {
                        Text(it, color = TMovieColors.Secondary, fontSize = 18.sp, maxLines = 1, modifier = Modifier.padding(top = 6.dp))
                    }
                    Text(item.metaLine(), color = Color.White.copy(alpha = 0.85f), fontSize = 16.sp, fontWeight = FontWeight.Medium,
                        maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 14.dp))
                    d?.content?.let { html ->
                        Text(html.replace(Regex("<[^>]*>"), "").replace("&nbsp;", " ").trim(), color = Color.White.copy(alpha = 0.8f), fontSize = 16.sp,
                            lineHeight = 24.sp, maxLines = 4, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 14.dp))
                    }
                    d?.actor?.filter { it.isNotBlank() }?.takeIf { it.isNotEmpty() }?.let {
                        Text("Diễn viên: ${it.take(5).joinToString(", ")}", color = TMovieColors.Secondary, fontSize = 15.sp, maxLines = 1,
                            overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 10.dp))
                    }
                }
            }
            item("actions") {
                Row(
                    Modifier.padding(start = Tv.Start, top = 24.dp, bottom = 20.dp).focusRestorer(play),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
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
                        else Icon(Icons.Rounded.PlayArrow, null, tint = fg, modifier = Modifier.size(26.dp))
                    }
                    Chip(if (isSaved) "Đã lưu" else "Danh sách", { Library.toggleSaved(item) }) { fg ->
                        Icon(if (isSaved) Icons.Rounded.Check else Icons.Rounded.Add, null, tint = fg, modifier = Modifier.size(24.dp))
                    }
                }
            }
            if (servers.size > 1) item("servers") {
                Row(Modifier.padding(start = Tv.Start, bottom = 12.dp).focusRestorer(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    servers.forEachIndexed { i, s -> Chip(s.serverName ?: "Server ${i + 1}", { server = i }, selected = i == server) }
                }
            }
            if (d != null && (episodes.size > 1 || servers.size > 1)) item("episodes") {
                val current = record?.takeIf { it.serverIndex == server }?.episodeIndex ?: 0
                Shelf("Tập phim · ${episodes.size}", episodes.withIndex().toList(), { it.index }) { (i, ep) ->
                    val progress = record?.progress(ep.slug.orEmpty()) ?: 0f
                    FocusCard(
                        { if (top && ep.streamUrl != null) Player.play(context, d, server, i, fromDetail = true) },
                        Modifier.width(150.dp).height(64.dp),
                        RoundedCornerShape(10.dp),
                    ) { focused ->
                        Box(Modifier.fillMaxSize().background(if (focused) Color.White else if (i == current && record != null) TMovieColors.Brand.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.08f)))
                        Text(ep.name ?: "Tập ${i + 1}", color = if (focused) Color.Black else Color.White, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                            maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.align(Alignment.Center).padding(horizontal = 10.dp))
                        if (progress > 0f) {
                            Box(Modifier.align(Alignment.BottomStart).fillMaxWidth(progress).height(4.dp).background(TMovieColors.BrandLight))
                        }
                    }
                }
            }
            if (similar.isNotEmpty()) item("similar") {
                Shelf("Có thể bạn thích", similar, { it.slug }) { f -> PosterCard(f, { onOpen(f) }) }
            }
        }
    }
}
