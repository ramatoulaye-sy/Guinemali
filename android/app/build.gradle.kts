plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin Google Services pour Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.guinemali.mobile"
    compileSdk = 36  // Requis par certains plugins (camera_android, media3, etc.)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Activer le core library desugaring pour flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
    
    // Forcer la version Kotlin compatible
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    
    // Désactiver explicitement les fonctionnalités natives
    buildFeatures {
        aidl = false
        buildConfig = false
        renderScript = false
        shaders = false
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.guinemali.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23  // Mettre à jour vers 23 pour record_android
        targetSdk = 34  // Peut rester à 34; compileSdk gère les ABI/compat
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Forcer l'utilisation d'AndroidX
        vectorDrawables.useSupportLibrary = true
    }
    
    // Configuration pour éviter les conflits de bibliothèques
    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            pickFirsts += "META-INF/io.netty.versions.properties"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Core library desugaring pour flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Firebase BOM (Bill of Materials) pour gérer les versions Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging-ktx")
    
    // Firebase Analytics (optionnel mais recommandé)
    implementation("com.google.firebase:firebase-analytics-ktx")
    
    // Dépendances essentielles pour l'application
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}

flutter {
    source = "../.."
}
