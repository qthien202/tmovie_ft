package com.thientech.tmovie.core.designsystem

import android.content.Context
import android.graphics.Bitmap
import androidx.compose.ui.graphics.Color
import coil3.SingletonImageLoader
import coil3.request.ImageRequest
import coil3.request.SuccessResult
import coil3.request.allowHardware
import coil3.toBitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Average colour of an image, brightened and saturated for use as a tint (as on iOS). */
object ColorSampler {
    suspend fun tint(context: Context, url: String?): Color? {
        if (url == null) return null
        val request = ImageRequest.Builder(context).data(url).size(48).allowHardware(false).build()
        val result = SingletonImageLoader.get(context).execute(request) as? SuccessResult ?: return null
        return withContext(Dispatchers.Default) { average(result.image.toBitmap()) }
    }

    private fun average(bitmap: Bitmap): Color {
        var r = 0L; var g = 0L; var b = 0L
        val px = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(px, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        for (p in px) { r += (p shr 16) and 0xFF; g += (p shr 8) and 0xFF; b += p and 0xFF }
        val n = px.size.coerceAtLeast(1)
        val hsv = FloatArray(3)
        android.graphics.Color.RGBToHSV((r / n).toInt(), (g / n).toInt(), (b / n).toInt(), hsv)
        hsv[1] = (hsv[1] * 1.6f + 0.15f).coerceAtMost(1f)
        hsv[2] = (hsv[2] * 1.5f).coerceIn(0.55f, 0.9f)
        return Color(android.graphics.Color.HSVToColor(hsv))
    }
}
