package com.thientech.tmovie

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.Crossfade
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.thientech.tmovie.core.data.Settings
import com.thientech.tmovie.core.designsystem.TMovieTheme
import com.thientech.tmovie.core.ui.UpdatePrompt
import com.thientech.tmovie.feature.home.rememberReduceMotion
import com.thientech.tmovie.feature.onboarding.OnboardingScreen
import com.thientech.tmovie.feature.onboarding.SplashScreen

class MainActivity : ComponentActivity() {
    /** The latest `tmovie://` link, consumed by the nav host. */
    private var link by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        link = intent?.dataString
        setContent {
            TMovieTheme {
                val onboarded by Settings.onboarded.collectAsStateWithLifecycle()
                var splashDone by remember { mutableStateOf(savedInstanceState != null) }
                val reduceMotion = rememberReduceMotion()
                Crossfade(
                    when {
                        !splashDone -> "splash"
                        !onboarded -> "onboarding"
                        else -> "main"
                    },
                    label = "root",
                ) { stage ->
                    when (stage) {
                        "splash" -> SplashScreen(reduceMotion) { splashDone = true }
                        "onboarding" -> OnboardingScreen(reduceMotion) { Settings.setOnboarded() }
                        else -> AppNavHost(link = link, onLinkHandled = { link = null })
                    }
                }
                UpdatePrompt(BuildConfig.VERSION_NAME, BuildConfig.DEBUG, R.mipmap.ic_launcher_foreground)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        link = intent.dataString
    }
}
