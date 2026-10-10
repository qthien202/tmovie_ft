package com.thientech.tmovie.feature.onboarding

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.PictureInPicture
import androidx.compose.material3.Icon
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.network.Source
import kotlinx.coroutines.launch

private val pages = listOf(
    Triple("Cả thế giới điện ảnh\ntrong túi bạn", "Phim bộ, phim lẻ, TV Shows cập nhật mỗi ngày.", Icons.Filled.AutoAwesome),
    Triple("Sắc nét đến\ntừng khung hình", "Phát Full HD, Hình trong hình và chọn tập ngay trong player.", Icons.Filled.PictureInPicture),
    Triple("Tiếp tục xem\nđúng chỗ bạn dừng", "Lịch sử và danh sách của bạn luôn sẵn sàng.", Icons.Filled.History),
)

/** First-launch intro over a slowly drifting wall of real posters. */
@Composable
fun OnboardingScreen(reduceMotion: Boolean, done: () -> Unit) {
    val scope = rememberCoroutineScope()
    val pager = rememberPagerState { pages.size }
    var posters by remember { mutableStateOf<List<FilmItem>>(emptyList()) }
    LaunchedEffect(Unit) { posters = runCatching { PhimApi.shared.list(Source.Type("phim-moi-cap-nhat")).items }.getOrDefault(emptyList()) }

    Box(Modifier.fillMaxSize().background(TMovieColors.Canvas)) {
        PosterWall(posters, animate = !reduceMotion)
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0f to TMovieColors.Canvas.copy(alpha = 0.2f), 0.55f to TMovieColors.Canvas.copy(alpha = 0.85f), 1f to TMovieColors.Canvas)))
        Column(Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            HorizontalPager(pager, Modifier.fillMaxWidth().height(300.dp)) { i ->
                val (title, body, icon) = pages[i]
                Column(Modifier.padding(horizontal = 32.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Icon(icon, null, tint = TMovieColors.Brand, modifier = Modifier.size(44.dp))
                    Text(title, style = TMovieType.Title.copy(fontSize = 32.sp, lineHeight = 36.sp), color = Color.White, textAlign = TextAlign.Center)
                    Text(body, color = TMovieColors.Secondary, textAlign = TextAlign.Center, fontSize = 16.sp)
                }
            }
            Row(Modifier.padding(vertical = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                repeat(pages.size) { i ->
                    Box(Modifier.size(8.dp).clip(CircleShape).background(if (i == pager.currentPage) Color.White else Color.White.copy(alpha = 0.3f)))
                }
            }
            val last = pager.currentPage == pages.lastIndex
            Box(
                Modifier.padding(horizontal = 24.dp).fillMaxWidth().height(52.dp).clip(RoundedCornerShape(12.dp)).background(TMovieColors.Brand)
                    .clickable { if (last) done() else scope.launch { pager.animateScrollToPage(pager.currentPage + 1) } },
                contentAlignment = Alignment.Center,
            ) { Text(if (last) "Bắt đầu xem" else "Tiếp tục", color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 17.sp) }
            Text("Bỏ qua", color = TMovieColors.Secondary, modifier = Modifier.padding(top = 14.dp).clickable(onClick = done))
        }
    }
}

/** Tilted grid of posters drifting slowly. */
@Composable
private fun PosterWall(films: List<FilmItem>, animate: Boolean) {
    if (films.isEmpty()) return
    val drift by rememberInfiniteTransition(label = "wall").animateFloat(
        0f, if (animate) 1f else 0f, infiniteRepeatable(tween(40_000, easing = LinearEasing), RepeatMode.Reverse), label = "drift",
    )
    Row(
        Modifier.fillMaxSize().graphicsLayer { rotationZ = -12f; translationX = -60.dp.toPx(); translationY = -40.dp.toPx() - drift * 260.dp.toPx() },
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        repeat(4) { col ->
            Column(
                Modifier.width(110.dp).graphicsLayer { translationY = if (col % 2 == 0) -40.dp.toPx() else -120.dp.toPx() },
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                (films + films).filterIndexed { i, _ -> i % 4 == col }.forEach {
                    RemoteImage(it.posterImage, Modifier.fillMaxWidth().aspectRatio(2f / 3f).clip(RoundedCornerShape(8.dp)))
                }
            }
        }
    }
}
