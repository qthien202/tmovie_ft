package com.thientech.tmovie.feature.browse

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.model.genreLine
import com.thientech.tmovie.core.model.metaLine
import com.thientech.tmovie.core.network.Source
import com.thientech.tmovie.core.ui.Pager
import com.thientech.tmovie.core.ui.SaveButton
import com.thientech.tmovie.core.ui.rememberNavigator
import com.thientech.tmovie.core.ui.route
import com.thientech.tmovie.core.ui.sharedFilm
import kotlinx.coroutines.launch

private enum class Feed(val title: String) {
    Upcoming("🍿 Sắp chiếu"), Airing("🔥 Đang chiếu"), Completed("✅ Trọn bộ");

    /** PhimAPI has no airing / completed lists, so both slice `phim-bo` by its episode label. */
    fun pager() = when (this) {
        Upcoming -> Pager(Source.Type("phim-sap-chieu"))
        Airing -> Pager(Source.Type("phim-bo")) { it.episodeCurrent.orEmpty().startsWith("Tập") }
        Completed -> Pager(Source.Type("phim-bo")) { it.episodeCurrent.orEmpty().contains("hoàn tất", ignoreCase = true) }
    }
}

/** "Mới & Hot": upcoming, airing and completed series as a feed of large cards. */
@Composable
fun NewHotScreen() {
    val scope = rememberCoroutineScope()
    var feed by remember { mutableStateOf(Feed.Upcoming) }
    val pagers = remember { Feed.entries.associateWith { it.pager() } }
    val pager = pagers.getValue(feed)
    LaunchedEffect(feed) { if (pager.items.isEmpty()) pager.loadMore() }

    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = 120.dp), verticalArrangement = Arrangement.spacedBy(28.dp)) {
        stickyHeader {
            Column(Modifier.background(TMovieColors.Canvas).statusBarsPadding().padding(vertical = 8.dp)) {
                Text("Mới & Hot", style = TMovieType.Title, color = Color.White, modifier = Modifier.padding(horizontal = 16.dp))
                Row(
                    Modifier.padding(top = 12.dp).horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp)
                        .clip(CircleShape).glass(CircleShape).padding(4.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Feed.entries.forEach { f ->
                        Text(
                            f.title,
                            color = if (f == feed) Color.Black else Color.White,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.clip(CircleShape).background(if (f == feed) Color.White else Color.Transparent)
                                .clickable { feed = f }.padding(horizontal = 14.dp, vertical = 8.dp),
                        )
                    }
                }
            }
        }
        items(pager.items, key = { "${feed.name}/${it.slug}" }) { film ->
            FeedCard(film)
            if (film.slug == pager.items.lastOrNull()?.slug) LaunchedEffect(pager.items.size) { pager.loadMore() }
        }
        if (pager.loading) item { Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = TMovieColors.Brand) } }
    }
}

/** Big landscape card for the feed. */
@Composable
private fun FeedCard(film: FilmItem) {
    val nav = rememberNavigator()
    val sourceId = "feed/${film.slug}"
    Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        RemoteImage(
            film.thumbImage,
            Modifier.fillMaxWidth().aspectRatio(16f / 9f).sharedFilm(sourceId).clip(RoundedCornerShape(10.dp))
                .clickable { nav.openFilm(film.route(sourceId)) },
            film.name,
        )
        Row(verticalAlignment = Alignment.Top) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(film.name, color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold, maxLines = 2)
                Text(film.metaLine(), color = TMovieColors.Secondary, fontSize = 12.sp)
                Text(film.genreLine(), color = TMovieColors.Secondary, fontSize = 12.sp, fontWeight = FontWeight.Medium)
            }
            SaveButton(film)
        }
    }
}
