
import java.util.Base64

plugins {
    id("com.android.application")
    // El plugin de Flutter debe ir después de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

val dartDefines = mutableMapOf<String, String>()

if (project.hasProperty("dart-defines")) {
    (project.property("dart-defines") as String)
        .split(",")
        .forEach { entrada ->
            val texto = String(
                Base64.getDecoder().decode(entrada),
                Charsets.UTF_8
            )
            val partes = texto.split("=", limit = 2)
            dartDefines[partes[0]] = partes.getOrElse(1) { "" }
        }
}

android {
    namespace = "com.huellitas.huellitas_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.huellitas.huellitas_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["mapsApiKey"] =
            dartDefines["MAPS_API_KEY"] ?: ""
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
