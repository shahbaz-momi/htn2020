package com.asdev.git3D

import org.springframework.data.mongodb.repository.MongoRepository

interface ProjectsRepo: MongoRepository<Project, String> {

    fun findAllByOrderByLastEditTimeDesc(): List<Project>?
}