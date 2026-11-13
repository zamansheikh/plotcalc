import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// The Google Maps key for the satellite map. It lives outside git (the repo
// is public): MAPS_API_KEY=... in android/local.properties, or the
// MAPS_API_KEY environment variable. Restrict it in Google Cloud Console to
// this package and signing certificates, and to "Maps SDK for Android".
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val mapsApiKey: String =
    localProperties.getProperty("MAPS_API_KEY")
        ?: System.getenv("MAPS_API_KEY")
        ?: ""

// A release without the key would ship a satellite map that stays blank.
gradle.taskGraph.whenReady {
    val releasing = allTasks.any {
        it.project == project && it.name.contains("Release")
    }
    if (releasing && mapsApiKey.isBlank()) {
        throw GradleException(
            "MAPS_API_KEY is not set. Add MAPS_API_KEY=<key> to " +
                "android/local.properties (see android/app/build.gradle.kts).",
        )
    }
}

android {
    namespace = "com.programmernexus.plotcalc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.programmernexus.plotcalc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
    }
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
