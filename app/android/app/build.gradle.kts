import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "in.annadatamitra.annadata_mitra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Release signing from android/key.properties (local file, never
    // committed). Falls back to debug keys when the file is absent.
    val keystoreProps = Properties()
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) {
        keystoreProps.load(FileInputStream(keystoreFile))
    }

    signingConfigs {
        create("upload") {
            if (keystoreFile.exists()) {
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
                // Resolve against the android/ root (key.properties lives
                // there, not in the app/ module directory).
                storeFile = rootProject.file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "in.annadatamitra.annadata_mitra"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Upload-key signing when android/key.properties exists,
            // otherwise debug keys (local development only).
            signingConfig = if (keystoreFile.exists()) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
            // NDK 28's symbol stripper fails on this Windows toolchain;
            // skip native symbol extraction (Play symbolication optional).
            ndk {
                debugSymbolLevel = "NONE"
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
