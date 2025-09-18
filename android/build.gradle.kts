// Load Mapbox downloads token from local.properties or environment (do not commit the token)
val localProps = java.util.Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.reader().use { load(it) }
}
val mapboxDownloadsToken: String = (localProps.getProperty("MAPBOX_DOWNLOADS_TOKEN")
    ?: System.getenv("MAPBOX_DOWNLOADS_TOKEN")) ?: ""

allprojects {
    repositories {
        google()
        mavenCentral()
        // Mapbox private Maven (required by mapbox_gl)
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication {
                create<org.gradle.authentication.http.BasicAuthentication>("basic")
            }
            credentials {
                username = "mapbox"
                password = mapboxDownloadsToken
            }
        }
    }
}

// Temporary compatibility for legacy Android plugins (e.g., older geolocator_android)
// They expect a Groovy 'ext.flutter' map with compileSdk/minSdk values.
// Remove this once all plugins are updated to AGP 8/Flutter new plugin APIs.
extra.set("flutter", mapOf(
    "compileSdkVersion" to 35,
    "minSdkVersion" to 21
))

subprojects {
    afterEvaluate {
        plugins.withId("com.android.application") {
            configure<com.android.build.gradle.BaseExtension> {
                ndkVersion = "29.0.13846066"
            }
        }
        plugins.withId("com.android.library") {
            configure<com.android.build.gradle.BaseExtension> {
                ndkVersion = "29.0.13846066"
            }
        }
    }
    
    val newSubprojectBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get().dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    project.evaluationDependsOn(":app")
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}