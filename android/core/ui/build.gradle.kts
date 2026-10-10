plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

android { namespace = "com.thientech.tmovie.core.ui" }

dependencies {
    api(project(":core:data"))
    api(project(":core:designsystem"))
    api(project(":core:player"))
    api(libs.androidx.lifecycle.runtime.compose)
    api(libs.androidx.lifecycle.viewmodel.compose)
    api(libs.androidx.navigation.compose)
}
