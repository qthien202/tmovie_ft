package com.thientech.tmovie.feature.browse

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.HotList
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.ui.ListRoute
import com.thientech.tmovie.core.ui.PlayFilmButton
import com.thientech.tmovie.core.ui.PosterCard
import com.thientech.tmovie.core.ui.Shelf
import com.thientech.tmovie.core.ui.rememberNavigator
import com.thientech.tmovie.core.ui.route
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private class Mood(val emoji: String, val title: String, val route: ListRoute, val colors: List<Color>)

private val moods = listOf(
    Mood("😱", "Hồi hộp", ListRoute.genre("Hồi hộp", "kinh-di"), listOf(Color(0xFF3A1C71), Color(0xFFD76D77))),
    Mood("💕", "Lãng mạn", ListRoute.genre("Lãng mạn", "tinh-cam"), listOf(Color(0xFFFF8FB1), Color(0xFF9D5CFF))),
    Mood("😂", "Cười xả láng", ListRoute.genre("Cười xả láng", "hai-huoc"), listOf(Color(0xFFF7971E), Color(0xFFFFD200))),
    Mood("🍿", "Cày một đêm", ListRoute.type("Cày một đêm", "phim-le"), listOf(Color(0xFF1D976C), Color(0xFF93F9B9))),
    Mood("📺", "Cày dài kỳ", ListRoute.type("Cày dài kỳ", "phim-bo"), listOf(Color(0xFF2B5876), Color(0xFF4E4376))),
    Mood("👨‍👩‍👧", "Cả nhà cùng xem", ListRoute.type("Cả nhà cùng xem", "hoat-hinh"), listOf(Color(0xFF3D8BFF), Color(0xFF5BE0FF))),
    Mood("🤯", "Mind-blowing", ListRoute.genre("Mind-blowing", "vien-tuong"), listOf(Color(0xFF0F2027), Color(0xFF2C7A8C))),
    Mood("⚔️", "Cổ trang", ListRoute.genre("Cổ trang", "co-trang"), listOf(Color(0xFFC79A3A), Color(0xFF8A3A1F))),
)

private class Collection(val title: String, val subtitle: String, val route: ListRoute, val colors: List<Color>)

private val collections = listOf(
    Collection("Hàn Quốc đang gây sốt", "Những bộ ai cũng bàn tuần này", ListRoute.country("Hàn Quốc đang gây sốt", "han-quoc"), listOf(Color(0xFFFF5F6D), Color(0xFF7B2FF7))),
    Collection("Cày một lèo", "Phim bộ đã trọn, khỏi chờ tập", ListRoute.type("Cày một lèo", "phim-bo"), listOf(Color(0xFF1D976C), Color(0xFF2B5876))),
    Collection("Kinh dị nửa đêm", "Tắt đèn rồi hãy bấm", ListRoute.genre("Kinh dị nửa đêm", "kinh-di"), listOf(Color(0xFF200122), Color(0xFF6F0000))),
    Collection("Hoạt hình cả nhà", "Cuối tuần cho bé và bố mẹ", ListRoute.type("Hoạt hình cả nhà", "hoat-hinh"), listOf(Color(0xFF3D8BFF), Color(0xFF5B8CFF))),
)

private fun ListRoute.source(): Source = when (kind) {
    "genre" -> Source.Genre(slug)
    "country" -> Source.Country(slug)
    else -> Source.Type(slug)
}

/** "Việc Ma, Lương Quái: Phần 2" → "Việc Ma, Lương Quái". */
private fun shortName(name: String) = name.split(':', '/', '(').first().trim()

/**
 * "Khám phá": finding something to watch rather than browsing lists. Hot titles as stories,
 * moods, a shuffle that picks a film, the Mới & Hot feed, and themed collections.
 */
@Composable
fun ExploreScreen() {
    var hot by remember { mutableStateOf<List<FilmItem>>(emptyList()) }
    var mood by remember { mutableIntStateOf(0) }
    val moodFilms = remember { mutableStateMapOf<Int, List<FilmItem>>() }
    val collectionFilms = remember { mutableStateMapOf<String, List<FilmItem>>() }
    var feed by remember { mutableStateOf(Feed.Upcoming) }
    val pagers = remember { Feed.entries.associateWith { it.pager() } }
    val pager = pagers.getValue(feed)

    LaunchedEffect(Unit) {
        HotList.fetch()?.let { list -> hot = (list.films + list.series).distinctBy { it.slug } }
    }
    LaunchedEffect(Unit) {
        coroutineScope {
            moods.mapIndexed { i, m -> async { i to runCatching { PhimApi.shared.list(m.route.source()).items }.getOrDefault(emptyList()) } }
                .awaitAll().forEach { (i, films) -> moodFilms[i] = films }
        }
    }
    LaunchedEffect(Unit) {
        coroutineScope {
            collections.map { c -> async { c.title to runCatching { PhimApi.shared.list(c.route.source()).items.drop(1).take(3) }.getOrDefault(emptyList()) } }
                .awaitAll().forEach { (t, films) -> collectionFilms[t] = films }
        }
    }
    LaunchedEffect(feed) { if (pager.items.isEmpty()) pager.loadMore() }

    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = 120.dp), verticalArrangement = Arrangement.spacedBy(28.dp)) {
        item {
            Column(Modifier.statusBarsPadding().padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text("Khám phá", style = TMovieType.Title, color = Color.White, modifier = Modifier.padding(horizontal = 16.dp))
                Stories(hot)
            }
        }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                SectionTitle("Hôm nay bạn muốn xem gì?")
                LazyRow(contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    itemsIndexed(moods) { i, m -> MoodCard(m, moodFilms[i].orEmpty(), selected = mood == i) { mood = i } }
                }
                val m = moods[mood]
                Shelf("${m.emoji} ${m.title}", more = m.route) {
                    items(moodFilms[mood].orEmpty(), key = { "mood/${it.slug}" }) { PosterCard(it, "mood/${it.slug}") }
                }
            }
        }
        item { ShuffleCard(hot) }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                SectionTitle("Mới & Hot")
                Row(Modifier.padding(horizontal = 16.dp).fillMaxWidth().clip(CircleShape).glass(CircleShape).padding(4.dp)) {
                    Feed.entries.forEach { f ->
                        Text(
                            f.title,
                            color = if (f == feed) Color.Black else Color.White,
                            fontWeight = FontWeight.SemiBold, fontSize = 14.sp, maxLines = 1,
                            modifier = Modifier.weight(1f).clip(CircleShape).background(if (f == feed) Color.White else Color.Transparent)
                                .clickable { feed = f }.padding(vertical = 9.dp),
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        )
                    }
                }
            }
        }
        items(pager.items.take(5), key = { "feed/${feed.name}/${it.slug}" }) { FeedCard(it) }
        if (pager.items.isEmpty()) item { Box(Modifier.fillMaxWidth().height(120.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = TMovieColors.Brand) } }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                SectionTitle("Bộ sưu tập")
                collections.chunked(2).forEach { row ->
                    Row(Modifier.padding(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        row.forEach { c -> CollectionCard(c, collectionFilms[c.title].orEmpty(), Modifier.weight(1f)) }
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String) =
    Text(text, color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 16.dp))

@Composable
private fun Stories(films: List<FilmItem>) {
    val nav = rememberNavigator()
    val ring = Brush.sweepGradient(listOf(TMovieColors.Brand, Color(0xFF9D8CFF), Color(0xFFFF8FB1), Color(0xFFFFD36E), TMovieColors.Brand))
    LazyRow(contentPadding = PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        itemsIndexed(films.take(12), key = { _, f -> "story/${f.slug}" }) { i, film ->
            Column(
                Modifier.width(74.dp).clickable { nav.openFilm(film.route("story/${film.slug}")) },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Box(Modifier.size(72.dp).clip(CircleShape).background(ring).padding(3.dp).clip(CircleShape).background(TMovieColors.Canvas).padding(3.dp).clip(CircleShape)) {
                    RemoteImage(film.posterImage, Modifier.fillMaxSize(), film.name)
                }
                Text((if (i < 3) "🔥 " else "") + shortName(film.name), color = TMovieColors.Secondary, fontSize = 11.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

/** Three posters fanned like cards. */
@Composable
private fun Fan(posters: List<FilmItem>, width: Dp, modifier: Modifier = Modifier) {
    Box(modifier, contentAlignment = Alignment.TopCenter) {
        posters.take(3).forEachIndexed { i, f ->
            RemoteImage(
                f.posterImage,
                Modifier
                    .zIndex(if (i == 1) 1f else 0f)
                    .offset(x = width * listOf(-0.55f, 0f, 0.55f)[i], y = if (i == 1) (-2).dp else 10.dp)
                    .rotate(listOf(-14f, 0f, 14f)[i])
                    .size(width, width * 1.48f)
                    .clip(RoundedCornerShape(10.dp)),
            )
        }
    }
}

@Composable
private fun MoodCard(mood: Mood, posters: List<FilmItem>, selected: Boolean, onClick: () -> Unit) {
    val shape = RoundedCornerShape(26.dp)
    Box(
        Modifier
            .offset(y = if (selected) (-3).dp else 0.dp)
            .size(150.dp, 178.dp)
            .clip(shape)
            .background(Brush.linearGradient(mood.colors))
            .border(if (selected) 2.5.dp else 1.dp, Color.White.copy(alpha = if (selected) 1f else 0.18f), shape)
            .clickable(onClick = onClick),
    ) {
        Fan(posters, 62.dp, Modifier.fillMaxWidth().padding(top = 14.dp))
        Row(
            Modifier.align(Alignment.BottomCenter).padding(8.dp).fillMaxWidth().clip(RoundedCornerShape(18.dp)).glass(RoundedCornerShape(18.dp))
                .padding(horizontal = 10.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(mood.emoji, fontSize = 20.sp)
            Text(mood.title, color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.Bold, maxLines = 2, lineHeight = 16.sp)
        }
    }
}

@Composable
private fun CollectionCard(c: Collection, posters: List<FilmItem>, modifier: Modifier) {
    val nav = rememberNavigator()
    val shape = RoundedCornerShape(26.dp)
    Box(
        modifier.height(236.dp).clip(shape).background(Brush.linearGradient(c.colors)).border(1.dp, Color.White.copy(alpha = 0.16f), shape)
            .clickable { nav.openList(c.route) },
    ) {
        Fan(posters, 60.dp, Modifier.fillMaxWidth().padding(top = 12.dp))
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.5f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.55f))))
        Column(Modifier.align(Alignment.BottomStart).padding(12.dp)) {
            Text(c.title, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 18.sp, maxLines = 2)
            Text(c.subtitle, color = Color.White.copy(alpha = 0.8f), fontSize = 11.sp, lineHeight = 14.sp, maxLines = 2)
        }
    }
}

/** "Để TMovie chọn giúp": posters spin past like a slot machine and stop on one hot title. */
@Composable
private fun ShuffleCard(pool: List<FilmItem>) {
    val scope = rememberCoroutineScope()
    var shown by remember { mutableStateOf<FilmItem?>(null) }
    var picked by remember { mutableStateOf<FilmItem?>(null) }
    var spinning by remember { mutableStateOf(false) }
    fun spin() {
        if (pool.isEmpty() || spinning) return
        spinning = true
        picked = null
        val target = pool.random()
        scope.launch {
            repeat(16) { step -> shown = pool.random(); delay(60L + step * step * 2L) }
            shown = target
            picked = target
            spinning = false
        }
    }
    val shape = RoundedCornerShape(30.dp)
    Row(
        Modifier.padding(horizontal = 16.dp).fillMaxWidth().clip(shape)
            .background(Brush.linearGradient(listOf(TMovieColors.Brand.copy(alpha = 0.28f), Color(0xFF9D8CFF).copy(alpha = 0.22f), Color(0xFFFF8FB1).copy(alpha = 0.2f))))
            .glass(shape).padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        AnimatedContent(shown ?: pool.firstOrNull(), transitionSpec = { slideInVertically { it } togetherWith slideOutVertically { -it } }, label = "reel") { f ->
            RemoteImage(f?.posterImage, Modifier.size(124.dp, 186.dp).clip(RoundedCornerShape(18.dp)).blur(if (spinning) 1.5.dp else 0.dp))
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(if (picked == null) "KHÔNG BIẾT XEM GÌ?" else "TMOVIE CHỌN CHO BẠN", color = TMovieColors.BrandLight, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            Text(picked?.name ?: "Để TMovie chọn giúp", color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 23.sp, maxLines = 3)
            Text(
                picked?.let { listOfNotNull(it.year?.toString(), it.country?.firstOrNull()?.name, it.episodeCurrent).joinToString(" · ") } ?: "Lắc một cái, ra một phim đang hot.",
                color = TMovieColors.Secondary, fontSize = 13.sp, maxLines = 2,
            )
            Spacer(Modifier.height(4.dp))
            picked?.let { PlayFilmButton(it, capsule = true) }
            Text(
                if (picked == null) "🎲 Chọn giúp tôi" else "🎲 Chọn lại",
                color = if (picked == null) Color.Black else Color.White,
                fontWeight = FontWeight.Bold, fontSize = 14.sp,
                modifier = Modifier.heightIn(min = 44.dp).clip(CircleShape)
                    .background(if (picked == null) Color.White else Color.White.copy(alpha = 0.14f))
                    .clickable(enabled = !spinning && pool.isNotEmpty()) { spin() }
                    .padding(horizontal = 16.dp, vertical = 12.dp),
            )
        }
    }
}
