plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 发布包只打 arm64（去掉 x86_64 / armeabi-v7a 的插件 so，这些 so 来自 AAR 的
// jniLibs，光靠 --target-platform 与 ndk.abiFilters 过滤不掉）：
//   ONLY_ARM64=true fvm flutter build apk --release \
//     --target-platform android-arm64 --no-tree-shake-icons
// 不设该变量时保持原样，x86_64 模拟器调试不受影响。
val onlyArm64: Boolean = System.getenv("ONLY_ARM64") == "true" ||
    (project.findProperty("onlyArm64") as String?)?.toBoolean() == true

android {
    namespace = "com.example.flutter_hot"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_hot"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 发布包只打 arm64（去掉 x86_64 / armeabi-v7a 的插件 so）：
        //   ORG_GRADLE_PROJECT_onlyArm64=true fvm flutter build apk --release \
        //     --target-platform android-arm64 --no-tree-shake-icons
        // 不传该属性时保持原样，x86_64 模拟器调试不受影响。
        println("[flutter_hot] onlyArm64 = $onlyArm64")
        if (onlyArm64) {
            ndk {
                abiFilters.clear()
                abiFilters.add("arm64-v8a")
            }
        }
    }

    if (onlyArm64) {
        packaging {
            jniLibs.excludes += listOf("lib/x86_64/**", "lib/armeabi-v7a/**")
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

flutter {
    source = "../.."
}
