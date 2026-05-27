import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.theblacksheep.havenly"
    compileSdk = 34
    ndkVersion = "28.2.13676358"

    signingConfigs {
        // Debug config stays as-is — do not touch
        getByName("debug") {
            // default debug keystore — unchanged
        }
        // Release config reads from local.properties — never committed to git
        create("release") {
            val props = Properties().apply {
                val propFile = rootProject.file("local.properties")
                if (propFile.exists()) {
                    load(propFile.inputStream())
                }
            }
            storeFile     = file(props.getProperty("RELEASE_STORE_FILE", ""))
            storePassword = props.getProperty("RELEASE_STORE_PASSWORD", "")
            keyAlias      = props.getProperty("RELEASE_KEY_ALIAS", "")
            keyPassword   = props.getProperty("RELEASE_KEY_PASSWORD", "")
        }
    }

    buildTypes {
        getByName("debug") {
            isDebuggable  = true
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            isDebuggable         = false
            isMinifyEnabled      = true
            isShrinkResources    = true
            signingConfig        = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    defaultConfig {
        applicationId    = "com.theblacksheep.havenly"
        minSdk = flutter.minSdkVersion
        targetSdk        = 34
        versionCode      = 1
        versionName      = "1.0.0"
        multiDexEnabled  = true

        val localProperties = Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localProperties.load(localPropertiesFile.inputStream())
        }
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            localProperties.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility            = JavaVersion.VERSION_17
        targetCompatibility            = JavaVersion.VERSION_17
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
