package com.thientech.tmovie.core.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.AccessGate
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.Wordmark
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Shows [content] once this device has been let in; until then, the access request / code screen. */
@Composable
fun AccessGate(platform: String, content: @Composable () -> Unit) {
    val unlocked by AccessGate.unlocked.collectAsStateWithLifecycle()
    if (unlocked) content() else AccessGateScreen(platform)
}

@Composable
private fun AccessGateScreen(platform: String) {
    val scope = rememberCoroutineScope()
    var pending by remember { mutableStateOf(AccessGate.pendingEmail()) }
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val field = remember { FocusRequester() }
    val button = remember { FocusRequester() }
    LaunchedEffect(pending) { runCatching { if (pending == null) field.requestFocus() else button.requestFocus() } }

    // While a request waits, ask every 10 s whether the owner approved it; the screen leaves on its own.
    LaunchedEffect(pending) {
        while (pending != null) {
            AccessGate.check().onSuccess { if (it == AccessGate.Status.Expired) { pending = null; error = "Yêu cầu đã hết hạn, gửi lại nhé." } }
            delay(10_000)
        }
    }

    val validEmail = Regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$").matches(email.trim())
    fun send() {
        if (name.isBlank() || !validEmail || busy) return
        busy = true; error = null
        scope.launch {
            AccessGate.request(name.trim(), email.trim(), platform)
                .onSuccess { pending = email.trim() }
                .onFailure { error = "Không gửi được, kiểm tra mạng rồi thử lại nhé." }
            busy = false
        }
    }

    Box(
        Modifier
            .fillMaxSize()
            .background(TMovieColors.Canvas)
            .background(Brush.radialGradient(listOf(TMovieColors.Brand.copy(alpha = 0.35f), Color.Transparent), radius = 1100f, center = Offset(0f, 0f)))
            .imePadding(),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            Modifier.widthIn(max = 440.dp).fillMaxWidth().verticalScroll(rememberScrollState()).padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Wordmark(size = 34)
            Text(if (pending == null) "App riêng tư" else "Đang chờ duyệt…", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(top = 8.dp))
            Text(
                if (pending == null) "TMovie chỉ dành cho bạn bè của chủ app. Gửi yêu cầu, chủ app duyệt là bạn vào được."
                else "Đã gửi yêu cầu. Chủ app duyệt xong là app tự mở, và bạn nhận mail báo ở $pending.",
                color = TMovieColors.Secondary, fontSize = 15.sp, lineHeight = 21.sp, textAlign = TextAlign.Center,
            )
            if (pending == null) {
                val colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = TMovieColors.BrandLight, unfocusedBorderColor = Color.White.copy(alpha = 0.25f),
                    focusedLabelColor = TMovieColors.BrandLight, cursorColor = TMovieColors.BrandLight,
                )
                OutlinedTextField(
                    name, { name = it.take(40); error = null }, Modifier.fillMaxWidth().focusRequester(field),
                    label = { Text("Tên của bạn") }, singleLine = true, colors = colors,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words, imeAction = ImeAction.Next),
                )
                OutlinedTextField(
                    email, { email = it.take(100); error = null }, Modifier.fillMaxWidth(),
                    label = { Text("Email") }, singleLine = true, colors = colors,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, autoCorrectEnabled = false, imeAction = ImeAction.Send),
                    keyboardActions = KeyboardActions(onSend = { send() }),
                )
            }
            error?.let { Text(it, color = Color(0xFFFF8A80), fontSize = 14.sp, textAlign = TextAlign.Center) }
            if (pending == null) {
                PrimaryButton(button, if (busy) "Đang gửi…" else "Gửi yêu cầu", enabled = name.isNotBlank() && validEmail && !busy, onClick = ::send)
            } else {
                var focused by remember { mutableStateOf(false) }
                Text(
                    "Gửi lại yêu cầu",
                    color = if (focused) Color.White else TMovieColors.Secondary,
                    fontSize = 15.sp,
                    modifier = Modifier
                        .focusRequester(button)
                        .onFocusChanged { focused = it.isFocused }
                        .clip(CircleShape)
                        .border(2.dp, if (focused) Color.White else Color.Transparent, CircleShape)
                        .clickable { AccessGate.forgetRequest(); pending = null; error = null }
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                )
            }
        }
    }
}
