plugins {
    // Let Flutter/Gradle manage the Android versions automatically
    id("com.android.application") apply false
    id("com.android.library") apply false
    
    // UPDATED: Set to 2.2.20 to match your system's classpath
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    
    // Essential for your Firebase cloud synchronization
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Sets the build directory for the entire project
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Organizes subproject build outputs
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    // Ensures the app module is evaluated first
    project.evaluationDependsOn(":app")
}

// Task to clean the build artifacts
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}