package com.skillsetpro.controllers;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.skillsetpro.config.ApiProperties;
import com.skillsetpro.config.security.SecurityConfig;
import com.skillsetpro.exceptions.ResourceNotFoundException;
import com.skillsetpro.model.records.*;
import com.skillsetpro.services.SkillService;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

@WebMvcTest(SkillController.class)
@Import(SecurityConfig.class)
@EnableConfigurationProperties({ApiProperties.class, com.skillsetpro.config.CorsProperties.class})
@ActiveProfiles("test")
class SkillControllerTest {
  @Autowired MockMvc mvc;
  @MockitoBean SkillService service;
  @MockitoBean JwtDecoder decoder;

  private RequestPostProcessor reader() {
    return jwt().authorities(new SimpleGrantedAuthority("SCOPE_skills.read"));
  }

  @Test
  void listReturnsEnvelopeAndFrontendFieldNames() throws Exception {
    var dto =
        new SkillDto(
            "skill-text",
            "tenant-a",
            "Java",
            "",
            "category-a",
            "Engineering",
            List.of("backend"),
            "active",
            Instant.EPOCH,
            Instant.EPOCH);
    when(service.list(new SkillFilter(null, null, null), 0, 20))
        .thenReturn(new PageDto<>(List.of(dto), 0, 20, 1, 1));
    mvc.perform(get("/api/v1/skills").with(reader()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items[0].skill_name").value("Java"))
        .andExpect(jsonPath("$.data.items[0].category_id").value("category-a"))
        .andExpect(jsonPath("$.data.items[0].tags[0]").value("backend"))
        .andExpect(jsonPath("$.data.totalElements").value(1))
        .andExpect(jsonPath("$.error").isEmpty());
  }

  @Test
  void forwardsValidatedFiltersAndPagination() throws Exception {
    mvc.perform(
            get("/api/v1/skills")
                .with(reader())
                .param("page", "2")
                .param("size", "5")
                .param("search", "Java")
                .param("categoryId", "category-a")
                .param("status", "disabled"))
        .andExpect(status().isOk());
    verify(service).list(new SkillFilter("Java", "category-a", "disabled"), 2, 5);
  }

  @Test
  void countRouteDoesNotResolveAsId() throws Exception {
    when(service.count(new SkillFilter(null, null, null))).thenReturn(4L);
    mvc.perform(get("/api/v1/skills/count").with(reader()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data").value(4));
    verify(service, never()).findById(anyString());
  }

  @Test
  void missingDetailIsSafeNotFound() throws Exception {
    when(service.findById("text-id")).thenThrow(new ResourceNotFoundException("Skill not found"));
    mvc.perform(get("/api/v1/skills/text-id").with(reader()))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error").value("Skill not found"));
  }

  @Test
  void invalidRequestsAre400WithoutCallingService() throws Exception {
    for (String query :
        List.of("page=-1", "page=abc", "size=0", "size=101", "status=invalid", "categoryId=")) {
      mvc.perform(get("/api/v1/skills?" + query).with(reader())).andExpect(status().isBadRequest());
    }
    mvc.perform(get("/api/v1/skills/count").param("search", "x".repeat(201)).with(reader()))
        .andExpect(status().isBadRequest());
    verifyNoInteractions(service);
  }

  @Test
  void missingTokenIs401AndMissingScopeIs403() throws Exception {
    for (String path :
        List.of("/api/v1/skills", "/api/v1/skills/count", "/api/v1/skills/text-id")) {
      mvc.perform(get(path)).andExpect(status().isUnauthorized());
      mvc.perform(get(path).with(jwt())).andExpect(status().isForbidden());
    }
    verifyNoInteractions(service);
  }
}
