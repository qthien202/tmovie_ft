plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android { namespace = "com.thientech.tmovie.feature.home" }

dependencies {
    implementation(project(":core:ui"))
    implementation(libs.media3.exoplayer)
    implementation(libs.media3.hls)
    implementation(libs.media3.ui)
}
