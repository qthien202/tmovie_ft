plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android { namespace = "com.thientech.tmovie.core.designsystem" }

dependencies {
    api(platform(libs.compose.bom))
    api(libs.compose.ui)
    api(libs.compose.foundation)
    api(libs.compose.animation)
    api(libs.compose.material3)
    api(libs.compose.material.icons)
    api(libs.compose.ui.tooling.preview)
    api(libs.coil.compose)
    api(libs.coil.okhttp)
    debugImplementation(libs.compose.ui.tooling)
}
