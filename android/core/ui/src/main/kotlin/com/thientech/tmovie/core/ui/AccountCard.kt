package com.thientech.tmovie.core.ui

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.Account
import com.thientech.tmovie.core.designsystem.RemoteImage
import com.thientech.tmovie.core.designsystem.TMovieColors
import com.thientech.tmovie.core.designsystem.glass
import kotlinx.coroutines.launch

/** Google sign-in / signed-in account, for the Profile tab. Hidden when Firebase isn't configured. */
@Composable
fun AccountCard() {
    if (!Account.available) return
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val user by Account.user.collectAsStateWithLifecycle()
    var busy by remember { mutableStateOf(false) }
    val shape = RoundedCornerShape(14.dp)

    val u = user
    if (u == null) {
        Row(
            Modifier.fillMaxWidth().height(52.dp).clip(shape).background(Color.White).clickable(enabled = !busy) {
                scope.launch {
                    busy = true
                    Account.signIn(context).onFailure {
                        Toast.makeText(context, "Đăng nhập chưa hoàn tất, thử lại nhé.", Toast.LENGTH_SHORT).show()
                    }
                    busy = false
                }
            },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
        ) {
            if (busy) CircularProgressIndicator(Modifier.size(20.dp), color = Color.Black, strokeWidth = 2.dp)
            else Text("G", color = Color(0xFF4285F4), fontWeight = FontWeight.Black, fontSize = 20.sp)
            Text("  Đăng nhập với Google để đồng bộ", color = Color.Black, fontWeight = FontWeight.SemiBold)
        }
    } else {
        Row(Modifier.fillMaxWidth().clip(shape).glass(shape).padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(40.dp).clip(CircleShape)) {
                if (u.photoUrl != null) RemoteImage(u.photoUrl, Modifier.size(40.dp))
                else Icon(Icons.Filled.AccountCircle, null, tint = Color.White, modifier = Modifier.size(40.dp))
            }
            Column(Modifier.weight(1f).padding(horizontal = 12.dp)) {
                Text(u.name ?: "Tài khoản Google", color = Color.White, fontWeight = FontWeight.SemiBold, maxLines = 1)
                Text("Đã đồng bộ · ${u.email.orEmpty()}", color = TMovieColors.Secondary, fontSize = 12.sp, maxLines = 1)
            }
            Icon(
                Icons.AutoMirrored.Filled.Logout, "Đăng xuất", tint = Color.White,
                modifier = Modifier.clip(CircleShape).clickable { Account.signOut(context) }.padding(8.dp),
            )
        }
    }
}
