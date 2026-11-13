package com.skillsetpro.security;

import static org.assertj.core.api.Assertions.*;

import java.util.List;
import org.junit.jupiter.api.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

class TenantContextTest {
  private final TenantContext context = new TenantContext();

  @AfterEach
  void clear() {
    SecurityContextHolder.clearContext();
  }

  private void token(Object tenant) {
    var jwt =
        Jwt.withTokenValue("test")
            .header("alg", "RS256")
            .subject("subject")
            .claim("tid", "entra-directory-id")
            .claim("app_tenant_id", tenant)
            .build();
    SecurityContextHolder.getContext()
        .setAuthentication(new JwtAuthenticationToken(jwt, List.of()));
  }

  @Test
  void applicationTenantIsRequired() {
    token("tenant-a");
    assertThat(context.requiredTenantId()).isEqualTo("tenant-a");
  }

  @Test
  void rejectsAbsentAuthentication() {
    assertThatThrownBy(context::requiredTenantId).isInstanceOf(AccessDeniedException.class);
  }

  @Test
  void rejectsNonJwtPrincipal() {
    SecurityContextHolder.getContext()
        .setAuthentication(
            UsernamePasswordAuthenticationToken.authenticated("user", "password", List.of()));
    assertThatThrownBy(context::requiredTenantId).isInstanceOf(AccessDeniedException.class);
    SecurityContextHolder.getContext()
        .setAuthentication(UsernamePasswordAuthenticationToken.unauthenticated("user", "password"));
    assertThatThrownBy(context::requiredTenantId).isInstanceOf(AccessDeniedException.class);
  }

  @Test
  void rejectsMissingBlankOrWrongTypeTenantWithoutUsingDirectoryId() {
    for (Object tenant : List.of("", " ", 123)) {
      token(tenant);
      assertThatThrownBy(context::requiredTenantId).isInstanceOf(AccessDeniedException.class);
    }
    var jwt =
        Jwt.withTokenValue("test")
            .header("alg", "RS256")
            .subject("subject")
            .claim("tid", "tenant-a")
            .build();
    SecurityContextHolder.getContext()
        .setAuthentication(new JwtAuthenticationToken(jwt, List.of()));
    assertThatThrownBy(context::requiredTenantId).isInstanceOf(AccessDeniedException.class);
  }
}
