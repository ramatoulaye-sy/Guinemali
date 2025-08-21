allprojects {
    repositories {
        google()
        mavenCentral()
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
    
    // Configuration pour éviter complètement les problèmes NDK
    if (project.name == "app") {
        // Désactiver toutes les tâches liées au NDK
        tasks.configureEach {
            if (name.contains("externalNativeBuild") || 
                name.contains("generateJsonModel") ||
                name.contains("Ndk") ||
                name.contains("CMake") ||
                name.contains("native") ||
                name.contains("ndk") ||
                name.contains("cmake")) {
                enabled = false
            }
        }
        
        // Désactiver explicitement les tâches NDK
        tasks.matching { it.name.contains("Ndk") || it.name.contains("ndk") }.configureEach {
            enabled = false
        }
    }
}

// Désactiver globalement toutes les tâches NDK
allprojects {
    tasks.matching { 
        it.name.contains("Ndk") || 
        it.name.contains("ndk") || 
        it.name.contains("externalNativeBuild") ||
        it.name.contains("cmake")
    }.configureEach {
        enabled = false
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
