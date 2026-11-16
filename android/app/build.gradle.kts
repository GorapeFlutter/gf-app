plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gorapeflutter.gf_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.gorapeflutter.gf_app"
        // Android Key Attestation (KeyGenParameterSpec.setAttestationChallenge)
        // requires API 24. Gorape's Android verifier is the only hardware-backed
        // registration path currently supported by the backend.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Used by flutter_appauth for the custom-scheme OIDC redirect.
        manifestPlaceholders["appAuthRedirectScheme"] =
            providers.gradleProperty("gorapeRedirectScheme")
                .orElse(providers.environmentVariable("GORAPE_REDIRECT_SCHEME"))
                .getOrElse("com.gorapeflutter.gfapp")
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
    // Credential Provider API is already used by the passkeys plugin; keep an
    // explicit dependency because gf-app also exposes its own provider service.
    implementation("androidx.credentials:credentials:1.6.0")
}

flutter {
    source = "../.."
}
