package com.asdev.git3D

import org.springframework.boot.autoconfigure.AutoConfigureAfter
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.autoconfigure.web.servlet.DispatcherServletAutoConfiguration
import org.springframework.boot.runApplication
import org.springframework.context.annotation.Configuration
import org.springframework.scheduling.annotation.AsyncConfigurer
import org.springframework.scheduling.annotation.EnableAsync
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer
import java.util.concurrent.Executor
import java.util.concurrent.Executors

@Configuration
@EnableAsync
class AsyncConfig: AsyncConfigurer {

	override fun getAsyncExecutor(): Executor? {
		return Executors.newFixedThreadPool(32)
	}
}

@Configuration
@AutoConfigureAfter(DispatcherServletAutoConfiguration::class)
class StaticResourceConfig: WebMvcConfigurer {

    override fun addResourceHandlers(registry: ResourceHandlerRegistry) {
        registry.addResourceHandler("/**").addResourceLocations("file:/" + FileSystem.basePath)
    }
}

@EnableAsync
@SpringBootApplication
class git3DApplication

fun main(args: Array<String>) {
	runApplication<git3DApplication>(*args)
}
