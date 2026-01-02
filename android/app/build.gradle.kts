plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.billsplit.receipt_split"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.billsplit.receipt_split"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // --- FIXED: MOVED ndk BLOCK HERE ---
        ndk {
            // "abiFilters" belongs to defaultConfig
            abiFilters += listOf("x86_64", "armeabi-v7a", "arm64-v8a")
        }
    }

    // --- REMOVED INCORRECT ndk BLOCK FROM HERE ---


    buildTypes {
        release {
            // Tells Gradle to use your new rules file
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // signingConfig = ... (keep your existing signing config here)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}