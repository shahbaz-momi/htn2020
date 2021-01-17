package com.asdev.git3D

import org.springframework.data.annotation.Id
import org.springframework.data.mongodb.core.mapping.Document
import java.util.*

data class Tag(
        var name: String
)

data class Commit(
        var id: String = UUID.randomUUID().toString(),
        var message: String,
        var tags: MutableList<Tag>,
        var author: String,
        var files: MutableList<String>,
        var comments: MutableList<String>,
        var parentId: String? = null,
        var branchingName: String? = null
)

@Document(collection = "projects")
data class Project(
        @Id
        var id: String? = null,
        var lastEditTime: Long = -1,
        var name: String,
        var description: String?,
        var autoCommit: Boolean,
        var commits: MutableList<Commit>
)