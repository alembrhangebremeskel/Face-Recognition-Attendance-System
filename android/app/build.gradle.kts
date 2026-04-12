plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.attendance_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // Unique ID for your MIT 4th-year project
        applicationId = "com.example.attendance_app"
        
        // FIXED: Set to 26 as required by tflite_flutter
        minSdk = 26 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // CRITICAL: Prevents TFLite model compression so the app can read it
    androidResources {
        noCompress.add("tflite")
        noCompress.add("lite")
    }

    buildTypes {
        getByName("release") {
            // Signing with debug keys so 'flutter run' works on your TECNO CD7
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}