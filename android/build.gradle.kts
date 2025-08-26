allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        plugins.withId("com.android.application") {
            configure<com.android.build.gradle.BaseExtension> {
                ndkVersion = "29.0.13846066"  // Updated to match the downloading version
            }
        }
        plugins.withId("com.android.library") {
            configure<com.android.build.gradle.BaseExtension> {
                ndkVersion = "29.0.13846066"  // Updated to match the downloading version
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
