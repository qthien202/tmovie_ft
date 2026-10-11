package com.thientech.tmovie.core.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.thientech.tmovie.core.designsystem.Pill
import com.thientech.tmovie.core.designsystem.cinematic
import com.thientech.tmovie.core.model.FilmCategory
import com.thientech.tmovie.core.network.PhimApi
import kotlinx.coroutines.delay

/**
 * "Thể loại ⌄" / "Quốc gia ⌄" pill that opens a Netflix-style full-screen list. Picking opens that
 * genre/country page, or, with [filter], hands the pick back (null = "Tất cả") and shows [title].
 */
@Composable
fun GenrePickerPill(
    selected: String? = null,
    kind: PhimApi.Taxonomy = PhimApi.Taxonomy.Genres,
    title: String? = null,
    filter: ((FilmCategory?) -> Unit)? = null,
) {
    var open by remember { mutableStateOf(false) }
    val nav = rememberNavigator()
    val genres = kind == PhimApi.Taxonomy.Genres
    Pill(title ?: if (genres) "Thể loại" else "Quốc gia", onClick = { open = true }, selected = title != null) {
        Icon(Icons.Filled.KeyboardArrowDown, null, tint = if (title != null) Color.Black else Color.White, modifier = Modifier.size(18.dp))
    }
    if (open) {
        GenrePicker(selected, kind, showsAll = filter != null, onDismiss = { open = false }) { g ->
            open = false
            if (filter != null) { if (g?.slug != selected) filter(g); return@GenrePicker }
            if (g == null || g.slug == selected) return@GenrePicker
            val name = g.name.orEmpty(); val slug = g.slug.orEmpty()
            nav.openList(if (genres) ListRoute.genre(name, slug) else ListRoute.country(name, slug))
        }
    }
}

@Composable
private fun GenrePicker(selected: String?, kind: PhimApi.Taxonomy, showsAll: Boolean, onDismiss: () -> Unit, onPick: (FilmCategory?) -> Unit) {
    var genres by remember { mutableStateOf<List<FilmCategory>>(emptyList()) }
    LaunchedEffect(Unit) { genres = runCatching { PhimApi.shared.taxonomy(kind) }.getOrDefault(emptyList()) }
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.88f))) {
            LazyColumn(
                Modifier.fillMaxSize(),
                contentPadding = PaddingValues(top = 96.dp, bottom = 160.dp),
                verticalArrangement = Arrangement.spacedBy(22.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                if (showsAll) item("all") {
                    Text(
                        "Tất cả",
                        color = if (selected == null) Color.White else Color.White.copy(alpha = 0.6f),
                        fontSize = if (selected == null) 24.sp else 20.sp,
                        fontWeight = if (selected == null) FontWeight.Bold else FontWeight.Medium,
                        modifier = Modifier.fillMaxWidth().clickable { onPick(null) },
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    )
                }
                itemsIndexed(genres, key = { _, g -> g.slug.orEmpty() }) { i, g ->
                    // Staggered rise-in.
                    var shown by remember { mutableStateOf(false) }
                    LaunchedEffect(Unit) { delay(minOf(i, 14) * 25L); shown = true }
                    val p by animateFloatAsState(if (shown) 1f else 0f, cinematic(), label = "genre")
                    val isSelected = g.slug == selected
                    Text(
                        g.name.orEmpty(),
                        color = if (isSelected) Color.White else Color.White.copy(alpha = 0.6f),
                        fontSize = if (isSelected) 24.sp else 20.sp,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                        modifier = Modifier
                            .fillMaxWidth()
                            .graphicsLayer { alpha = p; translationY = (1 - p) * 16.dp.toPx() }
                            .clickable { onPick(g) },
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    )
                }
            }
            Box(
                Modifier
                    .align(Alignment.BottomCenter)
                    .navigationBarsPadding()
                    .padding(bottom = 32.dp)
                    .size(60.dp)
                    .clip(CircleShape)
                    .background(Color.White)
                    .clickable(onClick = onDismiss),
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Filled.Close, "Đóng", tint = Color.Black) }
        }
    }
}
