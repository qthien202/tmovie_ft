import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

// Android TV app: same core (PhimAPI, ad filter, library, OTA) as :app, with a remote-driven UI.
// Same package id and key as the old Flutter TV app, so it installs as an update over it.
val keystoreProps = Properties().apply {
    rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

android {
    namespace = "com.thientech.tmovie.tv"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.thientech.tv"
        minSdk = 24
        targetSdk = 35
        versionCode = (findProperty("versionCode") as String?)?.toInt() ?: 1
        versionName = (findProperty("versionName") as String?) ?: "1.4.0"
    }

    signingConfigs {
        create("release") {
            if (keystoreProps.isNotEmpty()) {
                storeFile = file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "../app/proguard-rules.pro")
            signingConfig = signingConfigs.getByName(if (keystoreProps.isNotEmpty()) "release" else "debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

dependencies {
    implementation(project(":core:ui"))
    implementation(project(":feature:home"))  // HomeViewModel: hero, hot list, rails
    implementation(project(":feature:browse"))  // M3U channels
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.tvprovider)  // Watch Next on the TV home screen
    implementation(libs.media3.exoplayer)
    implementation(libs.media3.ui)
    debugImplementation(libs.compose.ui.tooling)
}
