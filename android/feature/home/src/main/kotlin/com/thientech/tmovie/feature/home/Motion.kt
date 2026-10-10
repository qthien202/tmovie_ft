package com.thientech.tmovie.feature.home

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.PowerManager
import android.provider.Settings as SystemSettings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.LocalContext

/** "Remove animations" in system settings: Android's Reduce Motion. */
@Composable
fun rememberReduceMotion(): Boolean {
    val context = LocalContext.current
    return remember {
        SystemSettings.Global.getFloat(context.contentResolver, SystemSettings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    }
}

@Composable
fun rememberPowerSave(): Boolean {
    val context = LocalContext.current
    return remember { (context.getSystemService(Context.POWER_SERVICE) as PowerManager).isPowerSaveMode }
}

/**
 * Smoothed device tilt (x = roll, y = pitch, about −1..1) relative to how the phone was held
 * when the hero appeared, from the gravity sensor. Zero when [enabled] is false.
 */
@Composable
fun rememberTilt(enabled: Boolean): State<Offset> {
    val context = LocalContext.current
    val tilt = remember { mutableStateOf(Offset.Zero) }
    DisposableEffect(enabled) {
        val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = sm.getDefaultSensor(Sensor.TYPE_GRAVITY)
        if (!enabled || sensor == null) {
            tilt.value = Offset.Zero
            return@DisposableEffect onDispose {}
        }
        var ref: Offset? = null
        val listener = object : SensorEventListener {
            override fun onSensorChanged(e: SensorEvent) {
                val now = Offset(e.values[0] / SensorManager.GRAVITY_EARTH, e.values[1] / SensorManager.GRAVITY_EARTH)
                val base = ref ?: now.also { ref = it }
                val target = Offset((base.x - now.x).coerceIn(-0.4f, 0.4f), (now.y - base.y).coerceIn(-0.4f, 0.4f))
                // Low-pass so the layers glide instead of jitter.
                tilt.value = tilt.value + (target - tilt.value) * 0.12f
            }
            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        sm.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_UI)  // ~60ms is plenty with the low-pass
        onDispose { sm.unregisterListener(listener) }
    }
    return tilt
}
