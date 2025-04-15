pluginManagement {
    val flutterSdkPath: String = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        require(localPropertiesFile.exists()) { "local.properties file not found." }
        localPropertiesFile.inputStream().use { properties.load(it) }
        properties.getProperty("flutter.sdk")
            ?: error("flutter.sdk not set in local.properties")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.1.0" apply false // vérifie la version selon ton projet
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

include(":app")
