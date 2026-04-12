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