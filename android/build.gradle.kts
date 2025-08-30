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