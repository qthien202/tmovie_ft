package com.thientech.tmovie.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Slideshow
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.data.Settings
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.TMovieType
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.ui.ContinueCard
import com.thientech.tmovie.core.ui.PosterCard
import com.thientech.tmovie.core.ui.RailHeader
import com.thientech.tmovie.core.ui.Shelf
import com.thientech.tmovie.core.ui.bleed
import com.thientech.tmovie.core.ui.fullSpan

/** "Của tôi": profile, recently watched, My List and data settings (Netflix's My Netflix tab). */
@Composable
fun ProfileScreen(account: @Composable () -> Unit = {}) {
    val context = LocalContext.current
    val history by Library.history.collectAsStateWithLifecycle()
    val saved by Library.saved.collectAsStateWithLifecycle()
    val name by Settings.profileName.collectAsStateWithLifecycle()
    val autoplay by Settings.heroAutoplay.collectAsStateWithLifecycle()
    var confirm by remember { mutableStateOf<String?>(null) }
    val version = remember { runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }.getOrNull() ?: "1.0" }

    LazyVerticalGrid(
        GridCells.Fixed(3),
        Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 120.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        fullSpan("head") {
            Column(Modifier.statusBarsPadding().padding(top = 8.dp, bottom = 12.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Text("Của tôi", style = TMovieType.Title, color = Color.White)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.size(64.dp).clip(RoundedCornerShape(12.dp))
                            .background(Brush.linearGradient(listOf(TMovieColors.Brand, Color(0xFF5B5BD6)))),
                        contentAlignment = Alignment.Center,
                    ) { Text(name.take(1).uppercase(), color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.Bold) }
                    Column(Modifier.padding(start = 14.dp)) {
                        BasicTextField(
                            name, { Settings.setProfileName(it) },
                            textStyle = TextStyle(color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold),
                            cursorBrush = SolidColor(TMovieColors.Brand), singleLine = true,
                        )
                        Text("${saved.size} phim đã lưu · ${history.size} phim đã xem", color = TMovieColors.Secondary, fontSize = 14.sp)
                    }
                }
                account()
            }
        }
        if (history.isNotEmpty()) fullSpan("recent") {
            Box(Modifier.bleed(16.dp)) { Shelf("Xem gần đây") { items(history.take(20), key = { it.film.slug }) { ContinueCard(it) } } }
        }
        fullSpan("listTitle") { Box(Modifier.bleed(16.dp)) { RailHeader("Danh sách của tôi") } }
        if (saved.isEmpty()) fullSpan("listEmpty") {
            Text("Nhấn + Danh sách ở một bộ phim để lưu lại.", color = TMovieColors.Secondary, fontSize = 14.sp)
        } else items(saved, key = { "mylist/${it.film.slug}" }) { PosterCard(it.film, "profile-list/${it.film.slug}", width = null) }
        fullSpan("settings") {
            Column(Modifier.padding(top = 16.dp).clip(RoundedCornerShape(16.dp)).glass(RoundedCornerShape(16.dp))) {
                Row(Modifier.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Slideshow, null, tint = Color.White)
                    Text("Tự phát xem trước", color = Color.White, modifier = Modifier.weight(1f).padding(start = 12.dp))
                    Switch(autoplay, Settings::setHeroAutoplay, colors = SwitchDefaults.colors(checkedTrackColor = TMovieColors.Brand))
                }
                HorizontalDivider(Modifier.padding(start = 52.dp), color = Color.White.copy(alpha = 0.1f))
                SettingRow("Xoá lịch sử xem", Icons.Filled.History) { confirm = "history" }
                HorizontalDivider(Modifier.padding(start = 52.dp), color = Color.White.copy(alpha = 0.1f))
                SettingRow("Xoá danh sách của tôi", Icons.Filled.DeleteOutline) { confirm = "saved" }
                HorizontalDivider(Modifier.padding(start = 52.dp), color = Color.White.copy(alpha = 0.1f))
                Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Info, null, tint = Color.White)
                    Text("Phiên bản", color = Color.White, modifier = Modifier.weight(1f).padding(start = 12.dp))
                    Text(version, color = TMovieColors.Secondary)
                }
            }
        }
    }

    confirm?.let { what ->
        AlertDialog(
            onDismissRequest = { confirm = null },
            title = { Text(if (what == "history") "Xoá lịch sử xem?" else "Xoá danh sách của tôi?") },
            confirmButton = {
                TextButton({ if (what == "history") Library.clearHistory() else Library.clearSaved(); confirm = null }) {
                    Text("Xoá", color = Color(0xFFFF6B6B))
                }
            },
            dismissButton = { TextButton({ confirm = null }) { Text("Huỷ") } },
        )
    }
}

@Composable
private fun SettingRow(title: String, icon: ImageVector, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = Color.White)
        Text(title, color = Color.White, modifier = Modifier.weight(1f).padding(start = 12.dp))
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Color.White.copy(alpha = 0.4f))
    }
    Spacer(Modifier.size(0.dp))
}
