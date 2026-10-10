package com.thientech.tmovie.feature.onboarding

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thientech.tmovie.core.designsystem.TMovieColors
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Wordmark intro: letters spring in one after another, unblurring as they land. */
@Composable
fun SplashScreen(reduceMotion: Boolean, done: () -> Unit) {
    val letters = "TMOVIE"
    val progress = remember { letters.map { Animatable(if (reduceMotion) 1f else 0f) } }
    LaunchedEffect(Unit) {
        progress.forEachIndexed { i, a ->
            launch {
                delay(i * 70L)
                a.animateTo(1f, if (reduceMotion) tween(0) else spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = 300f))
            }
        }
        delay(if (reduceMotion) 600 else 1400)
        done()
    }
    Box(Modifier.fillMaxSize().background(TMovieColors.Canvas), contentAlignment = Alignment.Center) {
        Row {
            letters.forEachIndexed { i, ch ->
                val p = progress[i].value
                Text(
                    "$ch",
                    style = TextStyle(
                        brush = Brush.verticalGradient(listOf(TMovieColors.Brand, TMovieColors.BrandLight)),
                        fontSize = 54.sp,
                        fontWeight = FontWeight.Black,
                    ),
                    modifier = Modifier
                        .graphicsLayer {
                            alpha = p.coerceIn(0f, 1f)
                            translationY = (1 - p) * 30.dp.toPx()
                            scaleX = 0.6f + 0.4f * p; scaleY = scaleX
                        }
                        .blur(((1 - p).coerceIn(0f, 1f) * 8).dp),
                )
            }
        }
    }
}
