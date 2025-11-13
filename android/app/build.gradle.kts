plugins {
    id("com.android.application")
    // ✅ FlutterFire (Google services) configuration plugin
    id("com.google.gms.google-services")
    id("kotlin-android")
    // ✅ Must be applied last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.trade_journal"
    compileSdk = 36

    defaultConfig {
        // ✅ Use your unique app ID (this must match Firebase package name)
        applicationId = "com.example.trade_journal"

        // ✅ Minimum SDK for Firebase Auth + Google Sign-In
        minSdk = flutter.minSdkVersion

        targetSdk = 33
        versionCode = 1
        versionName = "1.0.0"

        // ✅ Enable MultiDex support (needed for Firebase)
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Optional: shrinkResources false // disable if you see resource shrink errors
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Add MultiDex support for Firebase dependencies
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
