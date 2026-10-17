plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android { namespace = "com.thientech.tmovie.feature.browse" }

dependencies {
    implementation(project(":core:ui"))
    testImplementation(libs.junit)
}
