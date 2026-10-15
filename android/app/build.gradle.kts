import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

// Firebase (Google sign-in, per-account settings, sync) needs app/google-services.json, which
// is gitignored and restored by CI from a secret. Without it the app builds and simply hides login.
if (file("google-services.json").exists()) apply(plugin = "com.google.gms.google-services")

// Release signing from android/key.properties (written by CI from secrets). It must be the same
// key as the Flutter app so this APK installs as an update over it. Falls back to the debug key.
val keystoreProps = Properties().apply {
    rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) }
}

android {
    namespace = "com.thientech.tmovie"
    compileSdk = 35

    defaultConfig {
        // Same id as the Flutter mobile app, so this replaces it in place (OTA + Play-less updates).
        applicationId = "com.thientech.mobile"
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
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
    // Compress native libraries inside the APK (extracted at install): ONNX Runtime alone is 18 MB raw,
    // and every OTA update downloads the whole APK.
    packaging.jniLibs.useLegacyPackaging = true
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

// Release APKs carry native code for phones only: ONNX Runtime for every ABI would make the 5 MB app
// ~80 MB. "Thuyết minh AI" runs on arm64 (sea-g2p is built for it); armeabi-v7a stays, minus ONNX Runtime,
// so 32-bit phones still install, without the voice-over. Debug keeps x86_64 for the emulator.
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.addAll(listOf("lib/x86/**", "lib/x86_64/**", "lib/armeabi-v7a/libonnxruntime*"))
    }
}

dependencies {
    implementation(project(":core:ui"))
    implementation(project(":feature:home"))
    implementation(project(":feature:detail"))
    implementation(project(":feature:browse"))
    implementation(project(":feature:profile"))
    implementation(project(":feature:onboarding"))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.core.ktx)
    debugImplementation(libs.compose.ui.tooling)
}
