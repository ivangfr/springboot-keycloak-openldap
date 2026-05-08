package com.ivanfranchin.simpleservice.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.ivanfranchin.simpleservice.security.JwtAuthenticationTokenConverter;
import com.ivanfranchin.simpleservice.security.SecurityConfig;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;

@WebMvcTest(SimpleServiceController.class)
@Import(SecurityConfig.class)
class SimpleServiceControllerTests {

    @MockitoBean
    private JwtDecoder jwtDecoder;

    @MockitoBean
    private JwtAuthenticationTokenConverter jwtAuthenticationTokenConverter;

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldReturnPublicString() throws Exception {
        mockMvc.perform(get("/api/public"))
                .andExpect(status().isOk())
                .andExpect(content().string("It is public."));
    }

    @Test
    void shouldReturnPrivateStringWithJwt() throws Exception {
        mockMvc.perform(get("/api/private").with(jwt()))
                .andExpect(status().isForbidden());
    }

    @Test
    void publicEndpointShouldBeAccessibleWithoutAuthentication() throws Exception {
        mockMvc.perform(get("/api/public"))
                .andExpect(status().isOk());
    }

    @Test
    void privateEndpointShouldRequireAuthentication() throws Exception {
        mockMvc.perform(get("/api/private"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void privateEndpointShouldBeAccessibleWithJwt() throws Exception {
        mockMvc.perform(get("/api/private").with(jwt()))
                .andExpect(status().isForbidden());
    }
}
