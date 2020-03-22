package com.mycompany.simpleservice.config;

import org.keycloak.adapters.springboot.KeycloakSpringBootConfigResolver;
import org.keycloak.adapters.springsecurity.config.KeycloakWebSecurityConfigurerAdapter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * This class was created because, according to {@code KEYCLOAK-11282}, declaring the {@link
 * KeycloakSpringBootConfigResolver} directly in your {@link SecurityConfig} class (that extends from
 * {@link KeycloakWebSecurityConfigurerAdapter}) will cause the Spring Boot application context not to load.
 */
@Configuration
public class KeycloakConfig {

    @Bean
    public KeycloakSpringBootConfigResolver keycloakConfigResolver() {
        return new KeycloakSpringBootConfigResolver();
    }
}
