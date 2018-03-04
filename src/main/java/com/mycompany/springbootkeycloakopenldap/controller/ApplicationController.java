package com.mycompany.springbootkeycloakopenldap.controller;

import java.security.Principal;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ApplicationController {

    @GetMapping("/public")
    public ResponseEntity<String> getPublicString() {
        return ResponseEntity.ok("It is public.\n");
    }

    @GetMapping("/private")
    public ResponseEntity<String> getPrivateString(Principal principal) {
        String response = String.format("%s, it is private.\n", principal.getName());
        return ResponseEntity.ok(response);
    }

}