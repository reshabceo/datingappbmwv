allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    afterEvaluate {
        tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
            options.compilerArgs.addAll(listOf(
                "-Xlint:-options",      // Suppress Java 8 obsolete warnings
                "-Xlint:-deprecation",  // Suppress deprecation warnings
                "-Xlint:-removal",      // Suppress removal warnings
                "-Xlint:-unchecked"     // Suppress unchecked operation warnings
            ))
            sourceCompatibility = JavaVersion.VERSION_11.toString()
            targetCompatibility = JavaVersion.VERSION_11.toString()
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
