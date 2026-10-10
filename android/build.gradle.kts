import com.android.build.gradle.LibraryExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.google.services) apply false
}

// Shared config instead of convention plugins: every module targets Java 17, and every
// Android library gets the same SDK levels and Compose.
subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
            optIn.addAll(
                "androidx.compose.animation.ExperimentalSharedTransitionApi",
                "androidx.compose.foundation.ExperimentalFoundationApi",
                "androidx.compose.material3.ExperimentalMaterial3Api",
            )
        }
    }
    plugins.withId("org.jetbrains.kotlin.jvm") {
        extensions.configure<JavaPluginExtension> {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            compileSdk = 35
            defaultConfig.minSdk = 24
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            buildFeatures.compose = true
        }
    }
}
