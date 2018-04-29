package com.mycompany.simpleservice.config;

import org.apache.http.HttpHeaders;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import springfox.documentation.builders.RequestHandlerSelectors;
import springfox.documentation.service.*;
import springfox.documentation.spi.DocumentationType;
import springfox.documentation.spi.service.contexts.SecurityContext;
import springfox.documentation.spring.web.plugins.Docket;
import springfox.documentation.swagger.web.SecurityConfiguration;
import springfox.documentation.swagger.web.SecurityConfigurationBuilder;
import springfox.documentation.swagger2.annotations.EnableSwagger2;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static springfox.documentation.builders.PathSelectors.regex;

@Configuration
@EnableSwagger2
public class SwaggerConfig {

    private static final String NAME = "MyCompany Team";
    private static final String URL = "http://mycompany.com";
    private static final String EMAIL = "staff@mycompany.com";

    private static final String TITLE = "simple-service";
    private static final String DESCRIPTION = "";
    private static final String VERSION = "1.0";

    private static final String API_KEY_NAME = "JWT_TOKEN";

    @Bean
    public Docket api() {
        Contact contact = new Contact(NAME, URL, EMAIL);
        ApiInfo apiInfo = new ApiInfo(TITLE, DESCRIPTION, VERSION, "", contact, "", "", new ArrayList<>());

        return new Docket(DocumentationType.SWAGGER_2)
                .select()
                .apis(RequestHandlerSelectors.any())
                .paths(regex("/api/.*"))
                .build()
                .apiInfo(apiInfo)
                .securityContexts(Collections.singletonList(securityContext()))
                .securitySchemes(Collections.singletonList(apiKey()));
    }

    private ApiKey apiKey() {
        return new ApiKey(API_KEY_NAME, HttpHeaders.AUTHORIZATION, "header");
    }

    @Bean
    public SecurityConfiguration security() {
        return SecurityConfigurationBuilder.builder().useBasicAuthenticationWithAccessCodeGrant(false).build();
    }

    private SecurityContext securityContext() {
        return SecurityContext.builder().securityReferences(defaultAuth()).forPaths(regex("/api/private")).build();
    }

    List<SecurityReference> defaultAuth() {
        AuthorizationScope authorizationScope = new AuthorizationScope("global", "accessEverything");
        AuthorizationScope[] authorizationScopes = new AuthorizationScope[1];
        authorizationScopes[0] = authorizationScope;
        return Arrays.asList(new SecurityReference(API_KEY_NAME, authorizationScopes));
    }

}
