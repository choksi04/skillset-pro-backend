package com.skillsetpro;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.skillsetpro.repositories.SkillRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SkillAccessTest {
  @Autowired MockMvc mvc;
  @MockitoBean JwtDecoder decoder;
  @MockitoBean SkillRepository repository;

  @Test
  void missingApplicationTenantCannotReachDatabaseEvenWithScope() throws Exception {
    mvc.perform(
            get("/api/v1/skills/count")
                .with(
                    jwt()
                        .jwt(token -> token.claim("tid", "tenant-a"))
                        .authorities(new SimpleGrantedAuthority("SCOPE_skills.read"))))
        .andExpect(status().isForbidden());
    verifyNoInteractions(repository);
  }

  @Test
  void scopeIsRequiredEvenWhenApplicationTenantExists() throws Exception {
    mvc.perform(
            get("/api/v1/skills/count")
                .with(jwt().jwt(token -> token.claim("app_tenant_id", "tenant-a"))))
        .andExpect(status().isForbidden());
    verifyNoInteractions(repository);
  }

  @Test
  void trustedTenantReachesRepositoryForCount() throws Exception {
    when(repository.count(any(Specification.class))).thenReturn(2L);
    mvc.perform(
            get("/api/v1/skills/count")
                .with(
                    jwt()
                        .jwt(token -> token.claim("app_tenant_id", "tenant-a"))
                        .authorities(new SimpleGrantedAuthority("SCOPE_skills.read"))))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data").value(2));
  }

  @Test
  void clientTenantCannotOverrideTrustedTenantAndHiddenRecordIs404() throws Exception {
    when(repository.findByIdAndTenantIdAndDeletedOnIsNull("foreign", "tenant-a"))
        .thenReturn(Optional.empty());
    mvc.perform(
            get("/api/v1/skills/foreign")
                .param("tenantId", "tenant-b")
                .header("X-Tenant-Id", "tenant-b")
                .with(
                    jwt()
                        .jwt(token -> token.claim("app_tenant_id", "tenant-a"))
                        .authorities(new SimpleGrantedAuthority("SCOPE_skills.read"))))
        .andExpect(status().isNotFound());
    verify(repository).findByIdAndTenantIdAndDeletedOnIsNull("foreign", "tenant-a");
  }
}
