package com.thientech.tmovie.core.designsystem

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import coil3.compose.AsyncImage
import coil3.request.ImageRequest
import coil3.request.crossfade

/** Network image, cropped to fill, over a faint placeholder; Coil caches memory + disk. */
@Composable
fun RemoteImage(url: String?, modifier: Modifier = Modifier, contentDescription: String? = null) {
    val context = LocalContext.current
    AsyncImage(
        // Crossfade so images settle in instead of popping.
        model = remember(url) { ImageRequest.Builder(context).data(url).crossfade(250).build() },
        contentDescription = contentDescription,
        contentScale = ContentScale.Crop,
        modifier = modifier.background(Color.White.copy(alpha = 0.06f)),
    )
}

/** White "Xem ngay" capsule (Apple TV hero). */
@Composable
fun PlayCapsule(title: String, loading: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val interaction = rememberInteraction()
    Row(
        modifier
            .pressScale(interaction)
            .clip(CircleShape)
            .background(Color.White)
            .clickable(interaction, indication = null, onClick = onClick)
            .heightIn(min = 50.dp)
            .padding(horizontal = 28.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        if (loading) CircularProgressIndicator(Modifier.size(20.dp), color = Color.Black, strokeWidth = 2.dp)
        else Icon(Icons.Filled.PlayArrow, null, tint = Color.Black)
        Text(title, color = Color.Black, fontWeight = FontWeight.SemiBold, fontSize = 17.sp, maxLines = 1)
    }
}

/** Full-width white "Phát" bar (detail, featured cards). */
@Composable
fun PlayWide(title: String, loading: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true) {
    val interaction = rememberInteraction()
    Row(
        modifier
            .fillMaxWidth()
            .pressScale(interaction)
            .clip(RoundedCornerShape(8.dp))
            .background(if (enabled) Color.White else Color.White.copy(alpha = 0.5f))
            .clickable(interaction, indication = null, enabled = enabled, onClick = onClick)
            .height(46.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        if (loading) CircularProgressIndicator(Modifier.size(20.dp), color = Color.Black, strokeWidth = 2.dp)
        else Icon(Icons.Filled.PlayArrow, null, tint = Color.Black)
        Text(title, color = Color.Black, fontWeight = FontWeight.SemiBold, fontSize = 17.sp, maxLines = 1, modifier = Modifier.padding(start = 6.dp))
    }
}

/** Outlined glass capsule for category pills. */
@Composable
fun Pill(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, trailing: (@Composable () -> Unit)? = null) {
    val interaction = rememberInteraction()
    Row(
        modifier
            .pressScale(interaction)
            .clip(CircleShape)
            .glass(CircleShape)
            .clickable(interaction, indication = null, onClick = onClick)
            .height(34.dp)
            .padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(text, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Medium)
        trailing?.invoke()
    }
}

/** Thin progress bar along the bottom of a thumbnail. */
@Composable
fun ProgressStrip(value: Float, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().height(3.dp).background(Color.White.copy(alpha = 0.25f))) {
        Box(Modifier.fillMaxHeight().fillMaxWidth(value.coerceIn(0f, 1f)).background(TMovieColors.Brand))
    }
}

@Composable
fun Wordmark(modifier: Modifier = Modifier, size: Int = 26) {
    Text(
        "TMOVIE",
        modifier = modifier,
        style = TextStyle(
            brush = Brush.horizontalGradient(listOf(TMovieColors.Brand, TMovieColors.BrandLight)),
            fontSize = size.sp,
            fontWeight = FontWeight.Black,
            letterSpacing = (size * 0.06).sp,
        ),
    )
}

/** Section title used above shelves and grids. */
@Composable
fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(text, modifier = modifier, color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
}
