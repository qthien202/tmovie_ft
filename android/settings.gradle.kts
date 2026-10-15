pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "TMovie"

// Same layering as the iOS TMovieKit package: pure-Kotlin core, Android core, one module per
// feature. Features never depend on each other; :app wires navigation between them.
include(
    ":core:model",
    ":core:network",
    ":core:data",
    ":core:designsystem",
    ":core:player",
    ":core:voiceover",
    ":core:ui",
    ":feature:home",
    ":feature:detail",
    ":feature:browse",
    ":feature:profile",
    ":feature:onboarding",
    ":app",
)
