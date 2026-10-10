plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android { namespace = "com.thientech.tmovie.feature.detail" }

dependencies {
    implementation(project(":core:ui"))
}
