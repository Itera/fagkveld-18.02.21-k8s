package com.fagkveldtest.api.controllers

import org.springframework.web.bind.annotation.*

@RestController
class HelloController {
    @GetMapping("hello")
    fun get(): String {
        val secret = System.getenv("SECRET")
        return "world, $secret \n"
    }
}