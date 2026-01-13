allprojects {
    repositories {
        google()
        mavenCentral()
    }

    subprojects {
        afterEvaluate {
            if (project.extensions.findByName("android") != null) {
                val androidExtension = project.extensions.findByName("android")
                if (androidExtension is com.android.build.gradle.BaseExtension) {
                    val currentNamespace = androidExtension.namespace
                    if (currentNamespace == null) {
                        androidExtension.namespace = project.group.toString()
                    }
                }
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
