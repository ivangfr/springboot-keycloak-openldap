package com.ivanfranchin.simpleservice.controller;

import com.ivanfranchin.simpleservice.config.SwaggerConfig;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import java.security.Principal;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class SimpleServiceController {

  @Operation(summary = "Get string from public endpoint")
  @GetMapping("/public")
  public ResponseEntity<String> getPublicString() {
    return ResponseEntity.ok("It is public.");
  }

  @Operation(
      summary = "Get string from private/secured endpoint",
      security = {@SecurityRequirement(name = SwaggerConfig.BEARER_KEY_SECURITY_SCHEME)})
  @GetMapping("/private")
  public ResponseEntity<String> getPrivateString(Principal principal) {
    return ResponseEntity.ok("%s, it is private.".formatted(principal.getName()));
  }
}
