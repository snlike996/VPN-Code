plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
import java.io.FileInputStream
import java.util.Properties

android {
    namespace = "com.app.pixivpngold"
    compileSdk = 34
    ndkVersion = "28.1.13356709"

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.app.pixivpngold"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        vectorDrawables {
            useSupportLibrary = true
        }

    }

    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    val envStorePath = System.getenv("ANDROID_KEYSTORE_PATH")
    val envStorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
    val envKeyAlias = System.getenv("ANDROID_KEY_ALIAS")
    val envKeyPassword = System.getenv("ANDROID_KEY_PASSWORD")

    val storeFilePath = envStorePath ?: keystoreProperties.getProperty("storeFile")
    val keystoreFile = if (storeFilePath != null) rootProject.file(storeFilePath) else null
    val keyAliasValue = envKeyAlias ?: keystoreProperties.getProperty("keyAlias")
    val keyPasswordValue = envKeyPassword ?: keystoreProperties.getProperty("keyPassword")
    val storePasswordValue = envStorePassword ?: keystoreProperties.getProperty("storePassword")

    val hasKeystore = keystoreFile != null &&
        keystoreFile.exists() &&
        !keyAliasValue.isNullOrBlank() &&
        !keyPasswordValue.isNullOrBlank() &&
        !storePasswordValue.isNullOrBlank()

    signingConfigs {
        create("release") {
            if (hasKeystore) {
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
                storeFile = keystoreFile
                storePassword = storePasswordValue
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
    // add others as needed
}
