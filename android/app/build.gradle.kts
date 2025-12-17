import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // Kotlin plugin
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
}

dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}

// Load keystore properties safely
val keystoreProperties = Properties().apply {
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) {
        load(FileInputStream(keystoreFile))
    }
}

android {
    namespace = "com.regularomar.cdlExam.cdl_flutter"
    compileSdk = 36
    ndkVersion = "29.0.14033849"
    buildToolsVersion = "36.1.0"

    defaultConfig {
        applicationId = "com.regularomar.cdlExam.cdl_flutter"
        minSdk = 26
        targetSdk = 36
        versionCode = 4
        versionName = "0.4-beta"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it.toString()) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Use release signing if key.properties exists, otherwise fallback to debug
            signingConfig = if (keystoreProperties.isEmpty) signingConfigs.getByName("debug")
            else signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}