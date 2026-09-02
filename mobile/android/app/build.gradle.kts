import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val repositoryRoot = rootProject.projectDir.parentFile.parentFile.canonicalFile
val signingPropertiesPath = System.getenv("CSE_KEY_PROPERTIES_FILE")
val requireReleaseSigning = System.getenv("CSE_REQUIRE_SIGNING") == "true"
val acceptanceHarnessBuild = System.getenv("CSE_ACCEPTANCE_HARNESS") == "true"
val signingPropertiesFile = signingPropertiesPath?.let(::File)?.canonicalFile
val signingProperties = Properties()

if (signingPropertiesFile != null) {
    require(signingPropertiesFile.isFile) {
        "CSE release signing properties file was not found."
    }
    require(!signingPropertiesFile.toPath().startsWith(repositoryRoot.toPath())) {
        "CSE release signing properties must stay outside the repository."
    }
    signingPropertiesFile.inputStream().use(signingProperties::load)
}

val signingKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasCompleteReleaseSigning = signingPropertiesFile != null &&
    signingKeys.all { !signingProperties.getProperty(it).isNullOrBlank() }

if (signingPropertiesFile != null && !hasCompleteReleaseSigning) {
    throw GradleException("CSE release signing properties are incomplete.")
}
if (requireReleaseSigning && !hasCompleteReleaseSigning) {
    throw GradleException(
        "Signed CSE release requested without external signing properties."
    )
}

android {
    namespace = "com.faliardic.chiefsiteengineer"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.faliardic.sefim"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appIcon"] = "@mipmap/ic_launcher"
        manifestPlaceholders["appRoundIcon"] = "@mipmap/ic_launcher_round"
    }

    signingConfigs {
        if (hasCompleteReleaseSigning) {
            create("cseRelease") {
                val configuredStore = File(
                    signingPropertiesFile!!.parentFile,
                    signingProperties.getProperty("storeFile"),
                ).canonicalFile
                require(
                    !configuredStore.toPath().startsWith(repositoryRoot.toPath())
                ) {
                    "CSE release keystore must stay outside the repository."
                }
                storeFile = configuredStore
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = if (acceptanceHarnessBuild) ".acceptance" else ".debug"
            versionNameSuffix = if (acceptanceHarnessBuild) "-acceptance" else "-debug"
            val launcherIcon = if (acceptanceHarnessBuild) {
                "ic_launcher_acceptance"
            } else {
                "ic_launcher_debug"
            }
            manifestPlaceholders["appIcon"] = "@mipmap/$launcherIcon"
            manifestPlaceholders["appRoundIcon"] = "@mipmap/${launcherIcon}_round"
            manifestPlaceholders["appLabel"] = if (acceptanceHarnessBuild) {
                "Şefim (Acceptance)"
            } else {
                "Şefim (Debug)"
            }
        }
        release {
            manifestPlaceholders["appLabel"] = "Şefim"
            signingConfig = if (hasCompleteReleaseSigning) {
                signingConfigs.getByName("cseRelease")
            } else {
                null
            }
        }
    }

    packaging {
        jniLibs.useLegacyPackaging = false
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
