package com.skillsetpro;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.skillsetpro.config.CorsProperties;
import com.skillsetpro.exceptions.BadRequestException;
import com.skillsetpro.exceptions.ResourceNotFoundException;
import com.skillsetpro.model.responses.GenericResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.BadJwtException;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class FoundationTest {
  @Autowired private MockMvc mvc;
  @MockitoBean private JwtDecoder jwtDecoder;
  @MockitoBean private com.skillsetpro.repositories.SkillRepository skillRepository;

  @Test
  void healthIsPublic() throws Exception {
    mvc.perform(get("/actuator/health"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("UP"))
        .andExpect(jsonPath("$.components").doesNotExist());
  }

  @Test
  void missingTokenIsUnauthorized() throws Exception {
    mvc.perform(get("/test/probe"))
        .andExpect(status().isUnauthorized())
        .andExpect(header().string("WWW-Authenticate", "Bearer"))
        .andExpect(jsonPath("$.error").value("Authentication required"));
  }

  @Test
  void invalidTokenIsUnauthorized() throws Exception {
    when(jwtDecoder.decode("invalid")).thenThrow(new BadJwtException("sensitive detail"));
    mvc.perform(get("/test/probe").header("Authorization", "Bearer invalid"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error").value("Authentication required"));
  }

  @Test
  void responseEnvelopeWorksForStrings() throws Exception {
    mvc.perform(get("/test/probe").with(jwt()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data").value("ok"));
  }

  @Test
  void insufficientAuthorityIsForbidden() throws Exception {
    mvc.perform(get("/test/restricted").with(jwt()))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error").value("Access denied"));
  }

  @Test
  void allowedCorsPreflightSucceeds() throws Exception {
    mvc.perform(
            options("/test/probe")
                .header("Origin", "http://localhost:8080")
                .header("Access-Control-Request-Method", "GET"))
        .andExpect(status().isOk())
        .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:8080"));
  }

  @Test
  void unapprovedCorsOriginIsRejected() throws Exception {
    mvc.perform(
            options("/test/probe")
                .header("Origin", "https://unapproved.example")
                .header("Access-Control-Request-Method", "GET"))
        .andExpect(status().isForbidden());
  }

  @Test
  void invalidAndMalformedBodiesReturn400() throws Exception {
    mvc.perform(
            post("/test/probe").with(jwt()).contentType(MediaType.APPLICATION_JSON).content("{}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").value("Invalid request"));
    mvc.perform(
            post("/test/probe").with(jwt()).contentType(MediaType.APPLICATION_JSON).content("{"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void domainErrorsPreserveStatus() throws Exception {
    mvc.perform(get("/test/missing").with(jwt()))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error").value("Missing record"));
    mvc.perform(get("/test/bad").with(jwt())).andExpect(status().isBadRequest());
  }

  @Test
  void unexpectedErrorsDoNotLeakDetails() throws Exception {
    mvc.perform(get("/test/failure").with(jwt()))
        .andExpect(status().isInternalServerError())
        .andExpect(jsonPath("$.error").value("An unexpected error occurred"));
  }

  @Test
  void unknownRoutesReturn404() throws Exception {
    mvc.perform(get("/unknown").with(jwt()))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error").value("Resource not found"));
  }

  @Test
  void documentationDeclaresBearerSecurity() throws Exception {
    mvc.perform(get("/v3/api-docs").with(jwt()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.components.securitySchemes.bearerAuth.scheme").value("bearer"));
  }

  @Test
  void corsDefaultsToNoOrigins() {
    assertThat(new CorsProperties(null).allowedOrigins()).isEmpty();
  }

  @TestConfiguration
  static class ProbeConfig {
    @Bean
    ProbeController probeController() {
      return new ProbeController();
    }
  }

  // Test-only fixtures; no placeholder business endpoints are shipped.
  @RestController
  static class ProbeController {
    @GetMapping("/test/probe")
    GenericResponse<String> probe() {
      return GenericResponse.success("ok");
    }

    @PostMapping("/test/probe")
    GenericResponse<String> create(@Valid @RequestBody ProbeRequest request) {
      return GenericResponse.success(request.name());
    }

    @GetMapping("/test/restricted")
    @PreAuthorize("hasAuthority('test:restricted')")
    GenericResponse<String> restricted() {
      return GenericResponse.success("restricted");
    }

    @GetMapping("/test/missing")
    void missing() {
      throw new ResourceNotFoundException("Missing record");
    }

    @GetMapping("/test/bad")
    void bad() {
      throw new BadRequestException("Bad request");
    }

    @GetMapping("/test/failure")
    void failure() {
      throw new IllegalStateException("sensitive internal detail");
    }
  }

  record ProbeRequest(@NotBlank(message = "Name is required") String name) {}
}
