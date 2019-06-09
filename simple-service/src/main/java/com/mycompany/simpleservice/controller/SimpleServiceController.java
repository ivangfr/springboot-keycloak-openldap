package com.mycompany.simpleservice.controller;

import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiResponse;
import io.swagger.annotations.ApiResponses;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;

@RestController
@RequestMapping("/api")
public class SimpleServiceController {

    @ApiOperation(value = "Get string from public endpoint")
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "OK")
    })
    @GetMapping("/public")
    public String getPublicString() {
        return "It is public.\n";
    }

    @ApiOperation(value = "Get string from private/secured endpoint")
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "OK"),
            @ApiResponse(code = 401, message = "Unauthorized"),
            @ApiResponse(code = 403, message = "Forbidden")
    })
    @GetMapping("/private")
    public String getPrivateString(Principal principal) {
        return String.format("%s, it is private.\n", principal.getName());
    }

}