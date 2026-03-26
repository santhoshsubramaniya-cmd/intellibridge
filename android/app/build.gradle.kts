plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // ✅ Firebase plugin
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.santh.intellibridge"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.santh.intellibridge"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM (recommended)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    // Add Firebase services you use (example)
    implementation("com.google.firebase:firebase-analytics")

    // (Optional)
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
}