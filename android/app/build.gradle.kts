plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // Links your google-services.json for Cloud/Hybrid sync
    id("com.google.gms.google-services") 
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
        applicationId = "com.example.attendance_app"
        
        // Required for tflite_flutter and Face Recognition
        minSdk = 26 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Ensures your face recognition model files aren't compressed
    @Suppress("UnstableApiUsage")
    androidResources {
        noCompress.add("tflite")
        noCompress.add("lite")
    }

    buildTypes {
        getByName("release") {
            // Allows testing release builds on your Tecno CD7 using debug keys
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))

    // Hybrid Cloud Integration
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore")

    // UPDATED: Set to 2.2.20 to match the root file and system classpath
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.2.20")
}

flutter {
    source = "../.."
}