package com.thientech.tmovie.core.ui

import android.widget.Toast
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.Library
import com.thientech.tmovie.core.designsystem.PlayCapsule
import com.thientech.tmovie.core.designsystem.PlayWide
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.glass
import com.thientech.tmovie.core.model.FilmItem
import com.thientech.tmovie.core.network.PhimApi
import com.thientech.tmovie.core.player.Player
import kotlinx.coroutines.launch

enum class SaveStyle { Column, Wide, Circle }

/** "+ Danh sách" ↔ "✓ Danh sách", backed by the shared [Library] so every copy updates together. */
@Composable
fun SaveButton(film: FilmItem, style: SaveStyle = SaveStyle.Column, modifier: Modifier = Modifier) {
    val saved by Library.saved.collectAsStateWithLifecycle()
    val isSaved = saved.any { it.film.slug == film.slug }
    val haptics = LocalHapticFeedback.current
    val toggle = {
        Library.toggleSaved(film)
        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
    }
    val icon = if (isSaved) Icons.Filled.Check else Icons.Filled.Add
    val label = if (isSaved) "Bỏ khỏi danh sách" else "Thêm vào danh sách"
    when (style) {
        SaveStyle.Column -> Column(
            modifier.clickable(onClick = toggle).defaultMinSize(minWidth = 64.dp, minHeight = 48.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Icon(icon, label, tint = Color.White)
            Text("Danh sách", color = TMovieColors.Secondary, fontSize = 11.sp)
        }
        SaveStyle.Wide -> Row(
            modifier.fillMaxWidth().height(46.dp).clip(RoundedCornerShape(8.dp)).glass(RoundedCornerShape(8.dp)).clickable(onClick = toggle),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
        ) {
            Icon(icon, label, tint = Color.White)
            Text(" Danh sách", color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
        }
        SaveStyle.Circle -> Box(
            modifier.size(50.dp).clip(CircleShape).glass(CircleShape).clickable(onClick = toggle),
            contentAlignment = Alignment.Center,
        ) { Icon(icon, label, tint = Color.White) }
    }
}

/** "Xem ngay" / "Phát" from anywhere a film shows: fetches the detail, then starts or resumes playback. */
@Composable
fun PlayFilmButton(film: FilmItem, capsule: Boolean, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val history by Library.history.collectAsStateWithLifecycle()
    var loading by remember { mutableStateOf(false) }
    val resumed = history.any { it.film.slug == film.slug }
    val onClick: () -> Unit = {
        scope.launch {
            loading = true
            val detail = runCatching { PhimApi.shared.detail(film.slug) }.getOrNull()
            loading = false
            if (detail == null || !Player.start(context, detail)) {
                Toast.makeText(context, "Phim này chưa có link phát", Toast.LENGTH_SHORT).show()
            }
        }
    }
    if (capsule) PlayCapsule(if (resumed) "Xem tiếp" else "Xem ngay", loading, onClick, modifier)
    else PlayWide(if (resumed) "Tiếp tục" else "Phát", loading, onClick, modifier)
}
