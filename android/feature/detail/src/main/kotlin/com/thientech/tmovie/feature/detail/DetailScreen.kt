package com.thientech.tmovie.feature.detail

import android.content.Intent
import android.widget.Toast
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.net.toUri
import androidx.core.text.HtmlCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.PlayWide
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmDetail
import com.thientech.tmovie.core.model.FilmImage
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.model.FilmPerson
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.player.Player
import com.thientech.tmovie.core.ui.FilmRoute
import com.thientech.tmovie.core.ui.PosterCard
import com.thientech.tmovie.core.ui.SaveButton
import com.thientech.tmovie.core.ui.fullSpan
import com.thientech.tmovie.core.ui.rememberNavigator
import com.thientech.tmovie.core.ui.sharedFilm
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope

private enum class Tab(val title: String) { Episodes("Tập phim"), Similar("Tương tự"), Images("Hình ảnh") }

/** Netflix-style detail: 16:10 art, Play/Resume, synopsis, actions, cast, then Episodes / Similar / Images. */
@Composable
fun DetailScreen(route: FilmRoute) {
    val context = LocalContext.current
    val nav = rememberNavigator()
    var detail by remember { mutableStateOf<FilmDetail?>(null) }
    var people by remember { mutableStateOf<List<FilmPerson>>(emptyList()) }
    var backdrops by remember { mutableStateOf<List<FilmImage>>(emptyList()) }
    var similar by remember { mutableStateOf<List<FilmItem>>(emptyList()) }
    var failed by remember { mutableStateOf(false) }
    var attempt by remember { mutableIntStateOf(0) }
    var expanded by remember { mutableStateOf(false) }
    var tab by remember { mutableStateOf(Tab.Episodes) }
    val history by Library.history.collectAsStateWithLifecycle()
    val record = history.firstOrNull { it.film.slug == route.slug }

    LaunchedEffect(route.slug, attempt) {
        failed = false
        coroutineScope {
            val p = async { runCatching { PhimApi.shared.peoples(route.slug) }.getOrDefault(emptyList()) }
            val i = async { runCatching { PhimApi.shared.images(route.slug) }.getOrDefault(emptyList()) }
            detail = runCatching { PhimApi.shared.detail(route.slug) }.onFailure { failed = true }.getOrNull()
            detail?.category?.firstOrNull()?.slug?.let { g ->
                similar = runCatching { PhimApi.shared.list(Source.Genre(g)).items }.getOrDefault(emptyList()).filter { it.slug != route.slug }
            }
            people = p.await()
            backdrops = i.await().filter { it.type == "backdrop" }
        }
    }

    val d = detail
    val film = d?.toItem()
    val servers = d?.episodes.orEmpty()
    val isSeries = servers.any { (it.serverData?.size ?: 0) > 1 }
    val tabs = buildList { if (isSeries) add(Tab.Episodes); add(Tab.Similar); if (backdrops.isNotEmpty()) add(Tab.Images) }
    val current = if (tab in tabs) tab else tabs.first()
    val grid = rememberLazyGridState()

    Box(Modifier.fillMaxSize().background(TMovieColors.Canvas)) {
        LazyVerticalGrid(
            GridCells.Fixed(3),
            state = grid,
            contentPadding = PaddingValues(bottom = 120.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            fullSpan("header") {
                Box(
                    Modifier
                        .fillMaxWidth()
                        .aspectRatio(16f / 10f)
                        .graphicsLayer {
                            // Lags behind on scroll for a little depth.
                            if (grid.firstVisibleItemIndex == 0) translationY = grid.firstVisibleItemScrollOffset * 0.3f
                        }
                        .sharedFilm(route.sourceId),
                ) {
                    RemoteImage(film?.thumbImage ?: route.thumb, Modifier.fillMaxSize(), route.name)
                    Box(
                        Modifier.fillMaxSize().background(
                            Brush.verticalGradient(0f to Color.Black.copy(alpha = 0.6f), 0.3f to Color.Transparent, 0.6f to Color.Transparent, 1f to TMovieColors.Canvas),
                        ),
                    )
                }
            }
            fullSpan("title") {
                Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(d?.name ?: route.name, style = TMovieType.Title, color = Color.White)
                    d?.originName?.takeIf { it.isNotBlank() }?.let { Text(it, color = TMovieColors.Secondary, fontSize = 15.sp) }
                    MetaRow(d)
                    PlayWide(
                        title = record?.let { "Tiếp tục ${it.episodeName}" } ?: "Phát",
                        loading = false,
                        enabled = d != null,
                        onClick = {
                            if (d != null && !Player.start(context, d, fromDetail = true)) Toast.makeText(context, "Phim này chưa có link phát", Toast.LENGTH_SHORT).show()
                        },
                    )
                    if (failed) Text("Không tải được phim · Thử lại", color = TMovieColors.BrandLight, modifier = Modifier.clickable { attempt++ })
                    val synopsis = remember(d?.content) { d?.content?.let { HtmlCompat.fromHtml(it, HtmlCompat.FROM_HTML_MODE_COMPACT).toString().trim() }.orEmpty() }
                    if (synopsis.isNotEmpty()) {
                        Text(
                            synopsis,
                            color = Color.White,
                            fontSize = 15.sp,
                            maxLines = if (expanded) Int.MAX_VALUE else 3,
                            modifier = Modifier.animateContentSize().clickable { expanded = !expanded },
                        )
                    }
                    Credits(d, people)
                }
            }
            fullSpan("actions") {
                Row(Modifier.padding(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(28.dp)) {
                    if (film != null) SaveButton(film)
                    Action("Chia sẻ", Icons.AutoMirrored.Filled.Send) {
                        val text = "${d?.name ?: route.name}${d?.originName?.let { " ($it)" } ?: ""} — đang xem trên TMovie"
                        context.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text), null))
                    }
                    d?.trailerUrl?.takeIf { it.isNotBlank() }?.let { url ->
                        Action("Trailer", Icons.Filled.Movie) { context.startActivity(Intent(Intent.ACTION_VIEW, url.toUri())) }
                    }
                }
            }
            val actors = people.filter { it.knownForDepartment == "Acting" }
            if (actors.isNotEmpty()) fullSpan("cast") {
                LazyRow(contentPadding = PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    items(actors) { p ->
                        Column(Modifier.width(72.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            RemoteImage(p.profileUrl(), Modifier.size(64.dp).clip(CircleShape))
                            Text(p.name.orEmpty(), color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
                            Text(p.character.orEmpty(), color = TMovieColors.Secondary, fontSize = 11.sp, maxLines = 1)
                        }
                    }
                }
            }
            fullSpan("tabs") {
                Row(Modifier.padding(horizontal = 16.dp).padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(24.dp)) {
                    tabs.forEach { t ->
                        Column(Modifier.clickable { tab = t }) {
                            Box(Modifier.width(40.dp).height(4.dp).background(if (t == current) TMovieColors.Brand else Color.Transparent))
                            Text(
                                t.title,
                                color = if (t == current) Color.White else TMovieColors.Secondary,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(top = 10.dp),
                            )
                        }
                    }
                }
            }
            when (current) {
                Tab.Episodes -> if (d != null) fullSpan("episodes") {
                    EpisodeList(d, record, backdrops) { s, i -> Player.play(context, d, s, i, fromDetail = true) }
                }
                Tab.Similar -> similar.chunked(3).forEachIndexed { r, row ->
                    fullSpan("similar/$r") {
                        Row(Modifier.padding(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            row.forEach { f -> PosterCard(f, "similar/${route.sourceId}/${f.slug}", Modifier.weight(1f), width = null) }
                            repeat(3 - row.size) { androidx.compose.foundation.layout.Spacer(Modifier.weight(1f)) }
                        }
                    }
                }
                Tab.Images -> backdrops.forEachIndexed { i, img ->
                    fullSpan("img$i") {
                        RemoteImage(img.url(), Modifier.padding(horizontal = 16.dp).fillMaxWidth().aspectRatio(16f / 9f).clip(RoundedCornerShape(8.dp)))
                    }
                }
            }
        }
        Box(
            Modifier.statusBarsPadding().padding(12.dp).size(44.dp).clip(CircleShape).glass(CircleShape).clickable { nav.back() },
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Quay lại", tint = Color.White) }
    }
}

@Composable
private fun MetaRow(d: FilmDetail?) {
    val film = d?.toItem() ?: return
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
        film.rating?.let { Text("★ " + String.format(java.util.Locale.US, "%.1f", it), color = Color(0xFFFFD60A), fontSize = 13.sp) }
        film.year?.let { Text("$it", color = TMovieColors.Secondary, fontSize = 13.sp) }
        film.quality?.takeIf { it.isNotBlank() }?.let {
            Text(it, color = TMovieColors.Secondary, fontSize = 11.sp, fontWeight = FontWeight.Bold,
                modifier = Modifier.border(1.dp, TMovieColors.Secondary, RoundedCornerShape(3.dp)).padding(horizontal = 5.dp, vertical = 1.dp))
        }
        film.episodeCurrent?.let { Text(it, color = TMovieColors.Secondary, fontSize = 13.sp, maxLines = 1) }
        d.time?.takeIf { it.isNotBlank() }?.let { Text(it, color = TMovieColors.Secondary, fontSize = 13.sp, maxLines = 1) }
    }
}

@Composable
private fun Credits(d: FilmDetail?, people: List<FilmPerson>) {
    // PhimAPI fills unknown credits with "Đang cập nhật".
    val known = { s: String -> s.isNotBlank() && s != "Đang cập nhật" }
    val actors = d?.actor.orEmpty().filter(known).take(4)
    val directors = people.filter { it.knownForDepartment == "Directing" }.mapNotNull { it.name }
        .ifEmpty { d?.director.orEmpty().filter(known) }
    listOf("Diễn viên" to actors, "Đạo diễn" to directors).forEach { (label, names) ->
        if (names.isNotEmpty()) {
            Text(
                buildAnnotatedString {
                    withStyle(SpanStyle(color = TMovieColors.Secondary)) { append("$label: ") }
                    withStyle(SpanStyle(color = Color.White.copy(alpha = 0.55f))) { append(names.joinToString(", ")) }
                },
                fontSize = 12.sp,
                maxLines = 1,
            )
        }
    }
}

@Composable
private fun Action(title: String, icon: androidx.compose.ui.graphics.vector.ImageVector, onClick: () -> Unit) {
    Column(Modifier.clickable(onClick = onClick).padding(4.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Icon(icon, title, tint = Color.White)
        Text(title, color = TMovieColors.Secondary, fontSize = 11.sp)
    }
}
