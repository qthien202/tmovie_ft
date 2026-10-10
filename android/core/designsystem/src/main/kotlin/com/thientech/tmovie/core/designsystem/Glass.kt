package com.thientech.tmovie.core.designsystem

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp

/**
 * Frosted "glass" surface: a translucent fill with a light rim, tinted when [tint] is given.
 * (Compose has no backdrop blur; translucency over our dark, art-heavy screens reads the same.)
 */
fun Modifier.glass(shape: Shape = CircleShape, tint: Color? = null): Modifier = this
    .background(
        Brush.verticalGradient(
            listOf(
                (tint ?: Color.White).copy(alpha = if (tint == null) 0.16f else 0.30f),
                (tint ?: Color.White).copy(alpha = if (tint == null) 0.08f else 0.18f),
            ),
        ),
        shape,
    )
    .border(1.dp, Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.35f), Color.White.copy(alpha = 0.08f))), shape)

val CardShape = RoundedCornerShape(8.dp)
val HeroShape = RoundedCornerShape(14.dp)

/** Scale-down on press, for cards and custom buttons. Pass the same [interaction] to `clickable`. */
fun Modifier.pressScale(interaction: MutableInteractionSource): Modifier = composed {
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.96f else 1f, label = "press")
    graphicsLayer { scaleX = scale; scaleY = scale }
}

@androidx.compose.runtime.Composable
fun rememberInteraction() = remember { MutableInteractionSource() }
