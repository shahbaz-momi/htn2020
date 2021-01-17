package com.asdev.git3D

import org.springframework.stereotype.Service

@Service
class FileSystem {

    companion object {
        const val basePath = "C:\\Users\\shahb\\Documents\\frame\\storage\\"
    }

    fun getProjectDir(project: Project): String {
        return "$basePath/${project.id}"
    }

    fun getCommitDir(project: Project, commit: Commit): String {
        return "${getProjectDir(project)}/${commit.id}"
    }


}