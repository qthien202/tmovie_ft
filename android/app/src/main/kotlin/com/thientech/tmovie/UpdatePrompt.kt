package com.thientech.tmovie

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.thientech.tmovie.core.data.AppUpdate
import com.thientech.tmovie.core.data.AppUpdater
import com.thientech.tmovie.core.designsystem.TMovieColors
import kotlinx.coroutines.launch

/** Release builds check GitHub Releases on launch and offer a newer APK (same flow as the Flutter app). */
@Composable
fun UpdatePrompt() {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var update by remember { mutableStateOf<AppUpdate?>(null) }
    var progress by remember { mutableStateOf<Float?>(null) }
    var failed by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        if (BuildConfig.DEBUG) return@LaunchedEffect
        update = AppUpdater.check(BuildConfig.VERSION_NAME)
    }
    val u = update ?: return
    AlertDialog(
        onDismissRequest = { if (progress == null) update = null },
        title = { Text("Có bản cập nhật ${u.version}") },
        text = {
            Column(Modifier.heightIn(max = 320.dp).verticalScroll(rememberScrollState())) {
                Text(u.notes.ifBlank { "Bản mới đã sẵn sàng." })
                progress?.let { LinearProgressIndicator({ it }, Modifier.heightIn(min = 4.dp), color = TMovieColors.Brand) }
                if (failed) Text("Tải thất bại, thử lại nhé.")
            }
        },
        confirmButton = {
            TextButton(enabled = progress == null, onClick = {
                scope.launch {
                    failed = false
                    progress = 0f
                    runCatching { AppUpdater.download(context, u.apkUrl) { progress = it } }
                        .onSuccess { AppUpdater.install(context, it); progress = null }
                        .onFailure { failed = true; progress = null }
                }
            }) { Text("Cập nhật ngay") }
        },
        dismissButton = { if (progress == null) TextButton({ update = null }) { Text("Để sau") } },
    )
}
