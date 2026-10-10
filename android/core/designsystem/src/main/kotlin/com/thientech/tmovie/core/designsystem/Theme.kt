package com.thientech.tmovie.core.designsystem

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// Brand: Transformative Teal, dark-first (same tokens as iOS DesignSystem).
object TMovieColors {
    val Brand = Color(0xFF0F9190)
    val BrandLight = Color(0xFF66E6CC)
    val Canvas = Color(0xFF05080A)
    val Surface = Color(0xFF12161A)
    val Secondary = Color(0xB3FFFFFF)
}

/** Cinematic page / hero motion (≈ SwiftUI spring(response: 0.45, damping: 0.85)). */
fun <T> cinematic() = spring<T>(dampingRatio = 0.85f, stiffness = Spring.StiffnessMediumLow)

object TMovieType {
    /** Serif display titles, like the iOS hero. */
    val Display = TextStyle(fontFamily = FontFamily.Serif, fontWeight = FontWeight.Black, fontSize = 36.sp, lineHeight = 40.sp)
    val Title = TextStyle(fontFamily = FontFamily.Serif, fontWeight = FontWeight.Bold, fontSize = 28.sp, lineHeight = 32.sp)
}

@Composable
fun TMovieTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = TMovieColors.Brand,
            onPrimary = Color.White,
            secondary = TMovieColors.BrandLight,
            background = TMovieColors.Canvas,
            surface = TMovieColors.Surface,
            onBackground = Color.White,
            onSurface = Color.White,
            surfaceVariant = Color(0xFF1C2126),
        ),
        typography = Typography(),
        content = content,
    )
}
