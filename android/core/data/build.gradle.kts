plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "com.thientech.tmovie.core.data"
    buildFeatures.compose = false  // plain Kotlin; the root default turns Compose on
}

dependencies {
    api(project(":core:network"))
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.androidx.core.ktx)
}
