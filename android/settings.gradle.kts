pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localFile = file("local.properties")
        if (localFile.exists()) {
            localFile.inputStream().use { properties.load(it) }
        }
        properties.getProperty("flutter.sdk")
            ?: System.getenv("FLUTTER_ROOT")
            ?: error("flutter.sdk is not set in local.properties and FLUTTER_ROOT is not defined")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
