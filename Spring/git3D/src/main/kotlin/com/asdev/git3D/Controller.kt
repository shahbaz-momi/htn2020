package com.asdev.git3D

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile
import java.io.File
import java.net.URL
import java.net.URLEncoder

@RestController
@CrossOrigin(origins = ["http://192.168.137.1:8080", "http://localhost:3000"])
class Controller {

    @Autowired
    private lateinit var fileSystem: FileSystem

    @Autowired
    private lateinit var projectRepo: ProjectsRepo

    @Autowired
    private lateinit var convertor: ColladaConvertor

    @RequestMapping("/project/init")
    fun initProject(@RequestParam("name", required = true) name: String, @RequestParam("desc", required = false) desc: String?): Project {
        val project = Project(null, System.currentTimeMillis(), name, desc, false, mutableListOf())
        projectRepo.save(project)
        return project
    }

    @RequestMapping("/project/get")
    fun getProject(@RequestParam("id", required = true) id: String): Project? {
        return projectRepo.findById(id).orElseGet { null }
    }

    @RequestMapping("/project/get_all")
    fun getProjects(): List<Project> {
        return projectRepo.findAllByOrderByLastEditTimeDesc()?: listOf()
    }

    @RequestMapping("/project/{project_id}/commit")
    fun createCommit(@RequestParam("message") message: String, @PathVariable("project_id") projectId: String, @RequestParam("parent") parentId: String, @RequestParam("branching", required = false) branching: String?, @RequestParam("author", required = false) author: String?): Commit? {
        val p = projectRepo.findById(projectId)

        if(!p.isPresent) return null

        val project = p.get()

        val commit: Commit

        if(parentId == "INIT" && project.commits.isEmpty()) {
            // the base commit
            commit = Commit(
                    message = message,
                    tags = mutableListOf(),
                    parentId = null,
                    files = mutableListOf(),
                    author = author?: "Default <na>",
                    comments = mutableListOf(),
                    branchingName = "master"
            )
        } else {
            commit = Commit(
                    message = message,
                    tags = mutableListOf(),
                    parentId = parentId,
                    files = mutableListOf(),
                    author = author?: "Default <na>",
                    comments = mutableListOf(),
                    branchingName = branching
            )
        }

        project.lastEditTime = System.currentTimeMillis()
        project.commits.add(commit)

        projectRepo.save(project)

        return commit
    }

    @RequestMapping("/project/{project_id}/comment/{commit_id}")
    fun addComment(@PathVariable("project_id") projectId: String, @PathVariable("commit_id") commitId: String, @RequestParam("comment") comment: String): Commit? {
        val p = projectRepo.findById(projectId)

        if(!p.isPresent) return null

        val project = p.get()

        val commit = project.commits.find { it.id == commitId }?: return null

        project.lastEditTime = System.currentTimeMillis()
        commit.comments.add(comment)

        sendSlackMessage("git3D", "New comment on *${commit.message}* by *${commit.author}* in *${project.name}*: *$comment*")

        projectRepo.save(project)

        return commit
    }

    @RequestMapping("/project/{project_id}/tags/add/{commit_id}")
    fun addTag(@PathVariable("project_id") projectId: String, @PathVariable("commit_id") commitId: String, @RequestParam("name") name: String): Commit? {
        val p = projectRepo.findById(projectId)

        if(!p.isPresent) return null

        val project = p.get()

        val commit = project.commits.find { it.id == commitId }?: return null

        project.lastEditTime = System.currentTimeMillis()
        commit.tags.add(Tag(name))

        projectRepo.save(project)

        return commit
    }

    private val messageUrl = "https://adichha.api.stdlib.com/http-project@dev/"

    private fun sendSlackMessage(channel: String, message: String) {
        val json = "{ \"project\": \"$channel\", \"text\": \"$message\" }"
        val encoded = URLEncoder.encode(json, "UTF8")
        val request = "$messageUrl?obj=$encoded"
        URL(request).openConnection().getInputStream().close()
    }

    private fun process(project: Project, commit: Commit): String {
        val folder = fileSystem.getCommitDir(project, commit)
        val file = File(folder, ".processed")
        val hasProcessed = file.exists()

        if(hasProcessed) {
            return "{ \"success\": true, \"existing\": true }"
        }

        if(!file.parentFile.exists())
            return "{ \"success\": false }"

        project.lastEditTime = System.currentTimeMillis()
        projectRepo.save(project)

        file.createNewFile()

        var branch = "master"

        var current = commit
        try {
            while (current.branchingName == null) {
                current = project.commits.find { it.id == current.parentId }!!
            }
            branch = current.branchingName?: "master"
        } catch (e: Exception) {
        }

        sendSlackMessage("git3D", "New commit *'${commit.message}'* to branch *$branch* by *${commit.author}*, click git3D://${project.id}/${commit.id}/any.scn to check it out.")

        val tree = File(folder).walkTopDown().maxDepth(4)
        for(f in tree) {
            if(f.isDirectory)
                continue
            if(f.extension.equals("dae", ignoreCase = true)) {
                convertor.convert(f)
            }
        }

        return "{ \"success\": true }"
    }

    @RequestMapping("/project/{project_id}/process/{commit_id}")
    fun postProcess(@PathVariable("project_id") projectId: String, @PathVariable("commit_id") commitId: String): String {
        val p = projectRepo.findById(projectId)

        if(!p.isPresent) return "{ \"success\": false }"
        val project = p.get()
        val commit = project.commits.find { it.id == commitId }?: return "{ \"success\": false }"

        return process(project, commit)
    }

    /**
     * REQUIRES EXISTING COMMIT TO WORK
     */
    @PostMapping("/project/{project_id}/upload/{commit_id}")
    fun uploadFile(@RequestParam("file") file: MultipartFile, @RequestParam("relative_path") path: String,
                   @PathVariable("project_id") projectId: String, @PathVariable("commit_id") commitId: String): String {

        val p = projectRepo.findById(projectId)

        if(!p.isPresent) return "{ \"success\": false }"
        val project = p.get()
        val commit = project.commits.find { it.id == commitId }?: return "{ \"success\": false }"

        project.lastEditTime = System.currentTimeMillis()
        commit.files.add(path)
        projectRepo.save(project)

        val f = File(fileSystem.getCommitDir(project, commit), path)
        f.mkdirs()
        file.transferTo(f)

        return process(project, commit)
    }
}