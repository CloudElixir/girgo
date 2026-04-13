allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Simplified default build directories to avoid resource shrinking misconfiguration
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
