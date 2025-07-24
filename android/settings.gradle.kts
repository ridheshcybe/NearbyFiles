pluginManagement { // This block is typically in settings.gradle.kts
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
    // It's not standard to have a 'plugins' block directly inside 'pluginManagement'
    // in the module-level build.gradle.kts.
    // Plugin versions are usually managed via the plugin {} block itself
    // or through version catalogs.
    // However, if your setup requires it, it should look like this if specifying versions for resolution strategy.
    // resolutions.eachPlugin {
    // if (requested.id.id == "com.android.application") {
    // useVersion("8.3.0")
    // }
    // if (requested.id.id == "org.jetbrains.kotlin.android") {
    // useVersion("1.9.22")
    // }
    // }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "nearbyfiles"
include(":app")
