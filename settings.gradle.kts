import com.android.build.api.dsl.SettingsExtension

pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

@Suppress("UnstableApiUsage")
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.settings") version "8.13.0"
}

rootProject.name = "amneziawg-android"

include(":tunnel")
include(":ui")

configure<SettingsExtension> {
    buildToolsVersion = "36.0.0"
    compileSdk = 36
    // Порт под Android 4.4.4+ (KitKat, API 19) — Sony Xperia ZR / armeabi-v7a.
    // NDK r26+ removed the API-19 sysroot; r25c is the last NDK that can target KitKat.
    minSdk = 19
    ndkVersion = "25.2.9519653"
}
