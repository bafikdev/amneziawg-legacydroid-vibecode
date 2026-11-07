@file:Suppress("UnstableApiUsage")

import org.gradle.api.tasks.testing.logging.TestLogEvent

val pkg: String = providers.gradleProperty("amneziawgPackageName").get()
val cmakeAndroidPackageName: String = providers.environmentVariable("ANDROID_PACKAGE_NAME").getOrElse(pkg)

plugins {
    alias(libs.plugins.android.library)
}

android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // The config layer uses java.util.Optional and java.time; API 19 needs the
        // desugared backports.
        isCoreLibraryDesugaringEnabled = true
    }
    namespace = "${pkg}.tunnel"
    androidResources {
        // The project-wide default disables library resources; GoBackend needs R for
        // the foreground notification strings and icon.
        enable = true
    }
    defaultConfig {
        // Порт предназначен для старых ARM-устройств (Sony Xperia ZR и подобных).
        // Остальные ABI не собираем: это ускоряет сборку и уменьшает APK.
        ndk {
            abiFilters.add("armeabi-v7a")
        }
        // Required by AGP when core-library desugaring is active on API < 21.
        multiDexEnabled = true
    }
    externalNativeBuild {
        cmake {
            path("tools/CMakeLists.txt")
        }
    }
    testOptions.unitTests.all {
        it.testLogging { events(TestLogEvent.PASSED, TestLogEvent.SKIPPED, TestLogEvent.FAILED) }
    }
    buildTypes {
        all {
            externalNativeBuild {
                cmake {
                    // libwg.so / libwg-quick.so belonged to the removed root/kernel backend.
                    targets("libwg-go.so")
                }
            }
        }
        release {
            externalNativeBuild {
                cmake {
                    arguments("-DANDROID_PACKAGE_NAME=${cmakeAndroidPackageName}")
                }
            }
        }
        debug {
            externalNativeBuild {
                cmake {
                    // The debug app has applicationIdSuffix ".debug"; the Go UAPI socket
                    // directory is derived from the package name, so it must match.
                    arguments("-DANDROID_PACKAGE_NAME=${cmakeAndroidPackageName}.debug")
                }
            }
        }
    }
    lint {
        disable += "LongLogTag"
    }
}

dependencies {
    implementation(libs.androidx.annotation)
    implementation(libs.androidx.collection)
    compileOnly(libs.jsr305)
    testImplementation(libs.junit)
    coreLibraryDesugaring(libs.desugarJdkLibs)
}
