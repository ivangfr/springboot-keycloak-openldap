package com.mycompany.simpleservice.controller;

import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiResponse;
import io.swagger.annotations.ApiResponses;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;

@RestController
@RequestMapping("/api")
public class PublicPrivateController {

    @ApiOperation(value = "Get string from public endpoint")
    @ApiResponses(value = {
            @ApiResponse(code = 200, message = "OK")
    })
    @ResponseStatus(HttpStatus.OK)
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
    @ResponseStatus(HttpStatus.OK)
    @GetMapping("/private")
    public String getPrivateString(Principal principal) {
        return String.format("%s, it is private.\n", principal.getName());
    }

}