package com.thientech.tmovie

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.thientech.tmovie.core.data.AppUpdate
import com.thientech.tmovie.core.data.AppUpdater
import com.thientech.tmovie.core.designsystem.TMovieColors
import java.io.File
import java.util.Locale
import kotlinx.coroutines.launch

private sealed interface Phase {
    data object Idle : Phase
    data class Downloading(val done: Long, val total: Long) : Phase
    data class Ready(val apk: File) : Phase
    data object Failed : Phase
}

/**
 * Release builds check GitHub Releases on launch and offer a newer APK: a glass card with the
 * app icon, version jump, formatted release notes, and an in-place download → install flow.
 */
@Composable
fun UpdatePrompt() {
    var update by remember { mutableStateOf<AppUpdate?>(null) }
    LaunchedEffect(Unit) {
        if (BuildConfig.DEBUG) return@LaunchedEffect
        update = AppUpdater.check(BuildConfig.VERSION_NAME)
    }
    update?.let { UpdateDialog(it) { update = null } }
}

@Composable
private fun UpdateDialog(update: AppUpdate, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var phase by remember { mutableStateOf<Phase>(Phase.Idle) }
    val busy = phase is Phase.Downloading
    val entrance = remember { Animatable(0f) }
    LaunchedEffect(Unit) { entrance.animateTo(1f, spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMediumLow)) }

    fun start() = scope.launch {
        phase = Phase.Downloading(0, -1)
        phase = runCatching {
            AppUpdater.download(context, update.apkUrl) { done, total -> phase = Phase.Downloading(done, total) }
        }.fold({ Phase.Ready(it) }, { Phase.Failed })
        (phase as? Phase.Ready)?.let { AppUpdater.install(context, it.apk) }
    }

    Dialog(onDismissRequest = { if (!busy) onDismiss() }, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(
            Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.55f * entrance.value))
                .clickable(remember { MutableInteractionSource() }, indication = null) { if (!busy) onDismiss() },
            contentAlignment = Alignment.Center,
        ) {
            val shape = RoundedCornerShape(28.dp)
            Column(
                Modifier
                    .padding(24.dp)
                    .widthIn(max = 420.dp)
                    .fillMaxWidth()
                    .graphicsLayer {
                        alpha = entrance.value
                        val s = 0.9f + 0.1f * entrance.value
                        scaleX = s; scaleY = s
                        translationY = (1 - entrance.value) * 40.dp.toPx()
                    }
                    .clip(shape)
                    .background(TMovieColors.Surface)
                    .background(Brush.radialGradient(listOf(TMovieColors.Brand.copy(alpha = 0.45f), Color.Transparent), radius = 700f, center = androidx.compose.ui.geometry.Offset(0f, 0f)))
                    .border(1.dp, Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.25f), Color.White.copy(alpha = 0.05f))), shape)
                    .clickable(remember { MutableInteractionSource() }, indication = null) {}
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Box(Modifier.size(76.dp).clip(RoundedCornerShape(20.dp)).background(colorResource(R.color.icon_background)), contentAlignment = Alignment.Center) {
                    Image(painterResource(R.mipmap.ic_launcher_foreground), null, Modifier.size(108.dp))
                }
                Spacer(Modifier.height(16.dp))
                Text("Đã có bản mới", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(10.dp))
                VersionJump(BuildConfig.VERSION_NAME, update.version)
                Spacer(Modifier.height(18.dp))

                Column(
                    Modifier
                        .fillMaxWidth()
                        .heightIn(max = 260.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .background(Color.White.copy(alpha = 0.05f))
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) { ReleaseNotes(update.notes) }

                Spacer(Modifier.height(20.dp))
                AnimatedContent(phase is Phase.Downloading, transitionSpec = { fadeIn() togetherWith fadeOut() }, label = "progress") { downloading ->
                    if (downloading) DownloadProgress(phase as? Phase.Downloading ?: Phase.Downloading(0, -1))
                    else Spacer(Modifier.height(0.dp))
                }
                if (phase is Phase.Failed) {
                    Text("Tải thất bại, kiểm tra mạng rồi thử lại nhé.", color = Color(0xFFFF8A80), fontSize = 13.sp, textAlign = TextAlign.Center,
                        modifier = Modifier.padding(bottom = 12.dp))
                }

                PrimaryButton(
                    text = when (phase) {
                        is Phase.Downloading -> "Đang tải…"
                        is Phase.Ready -> "Cài đặt"
                        is Phase.Failed -> "Thử lại"
                        Phase.Idle -> "Cập nhật ngay"
                    },
                    enabled = !busy,
                ) {
                    when (val p = phase) {
                        is Phase.Ready -> AppUpdater.install(context, p.apk)
                        else -> start()
                    }
                }
                if (!busy) {
                    Text(
                        "Để sau",
                        color = TMovieColors.Secondary,
                        fontSize = 15.sp,
                        modifier = Modifier.padding(top = 6.dp).clip(CircleShape).clickable(onClick = onDismiss).padding(horizontal = 16.dp, vertical = 10.dp),
                    )
                }
            }
        }
    }
}

/** "1.4.0  →  1.4.1" as two chips. */
@Composable
private fun VersionJump(from: String, to: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(from, color = TMovieColors.Secondary, fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
            modifier = Modifier.clip(CircleShape).background(Color.White.copy(alpha = 0.08f)).padding(horizontal = 10.dp, vertical = 4.dp))
        Icon(Icons.AutoMirrored.Filled.ArrowForward, null, tint = TMovieColors.Secondary, modifier = Modifier.size(16.dp))
        Text(to, color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold,
            modifier = Modifier.clip(CircleShape).background(TMovieColors.Brand).padding(horizontal = 10.dp, vertical = 4.dp))
    }
}

/**
 * The release body is the plain-text `app:vi` block from CHANGELOG.md: emoji-led headings
 * followed by "•" bullets. Headings render bold, bullets as a list.
 */
@Composable
private fun ReleaseNotes(notes: String) {
    val lines = notes.lines().map { it.trim() }.filter { it.isNotEmpty() }.ifEmpty { listOf("Bản mới đã sẵn sàng.") }
    lines.forEachIndexed { i, line ->
        if (line.startsWith("•")) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Box(Modifier.padding(top = 8.dp).size(5.dp).clip(CircleShape).background(TMovieColors.BrandLight))
                Text(line.removePrefix("•").trim(), color = Color.White.copy(alpha = 0.85f), fontSize = 14.sp, lineHeight = 20.sp)
            }
        } else {
            Text(line, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = if (i == 0) 0.dp else 8.dp))
        }
    }
}

@Composable
private fun DownloadProgress(p: Phase.Downloading) {
    val fraction = if (p.total > 0) (p.done.toFloat() / p.total).coerceIn(0f, 1f) else 0f
    val animated by animateFloatAsState(fraction, label = "download")
    Column(Modifier.fillMaxWidth().padding(bottom = 16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(Modifier.fillMaxWidth().height(8.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.1f))) {
            Box(Modifier.fillMaxWidth(animated).height(8.dp).clip(CircleShape)
                .background(Brush.horizontalGradient(listOf(TMovieColors.Brand, TMovieColors.BrandLight))))
        }
        val mb = { b: Long -> String.format(Locale.forLanguageTag("vi"), "%.1f", b / 1_048_576.0) }
        Text(
            if (p.total > 0) "Đang tải ${(fraction * 100).toInt()}% · ${mb(p.done)} / ${mb(p.total)} MB" else "Đang tải…",
            color = TMovieColors.Secondary, fontSize = 13.sp, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun PrimaryButton(text: String, enabled: Boolean, onClick: () -> Unit) {
    Box(
        Modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(
                if (enabled) Brush.horizontalGradient(listOf(TMovieColors.Brand, Color(0xFF14B8A6)))
                else Brush.horizontalGradient(listOf(Color.White.copy(alpha = 0.12f), Color.White.copy(alpha = 0.12f))),
            )
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) { Text(text, color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.SemiBold) }
}
