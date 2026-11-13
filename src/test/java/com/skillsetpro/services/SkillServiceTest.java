package com.skillsetpro.services;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.skillsetpro.exceptions.*;
import com.skillsetpro.model.entities.Skill;
import com.skillsetpro.model.records.*;
import com.skillsetpro.repositories.SkillRepository;
import com.skillsetpro.security.TenantContext;
import com.skillsetpro.services.impl.SkillServiceImpl;
import java.time.Instant;
import java.util.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class SkillServiceTest {
  @Mock SkillRepository repository;
  @Mock TenantContext tenantContext;
  @InjectMocks SkillServiceImpl service;
  private final SkillFilter filter = new SkillFilter(null, null, null);

  private Skill skill() {
    Skill skill = org.springframework.beans.BeanUtils.instantiateClass(Skill.class);
    Map<String, Object> fields =
        Map.of(
            "id",
            "skill-text-id",
            "tenantId",
            "tenant-a",
            "skillName",
            "Java",
            "status",
            "active",
            "tags",
            new String[] {"backend"},
            "createdAt",
            Instant.parse("2026-01-01T00:00:00Z"),
            "updatedAt",
            Instant.parse("2026-02-01T00:00:00Z"));
    fields.forEach((key, value) -> ReflectionTestUtils.setField(skill, key, value));
    return skill;
  }

  @Test
  void listMapsExistingFieldsAndUsesStablePagination() {
    when(tenantContext.requiredTenantId()).thenReturn("tenant-a");
    when(repository.findAll(any(Specification.class), any(Pageable.class)))
        .thenReturn(new PageImpl<>(List.of(skill()), PageRequest.of(0, 20), 1));
    var page = service.list(filter, 0, 20);
    assertThat(page.totalElements()).isEqualTo(1);
    assertThat(page.totalPages()).isEqualTo(1);
    assertThat(page.page()).isZero();
    assertThat(page.size()).isEqualTo(20);
    var dto = page.items().get(0);
    assertThat(dto.id()).isEqualTo("skill-text-id");
    assertThat(dto.tenantId()).isEqualTo("tenant-a");
    assertThat(dto.skillName()).isEqualTo("Java");
    assertThat(dto.skillDescription()).isEmpty();
    assertThat(dto.skillCategory()).isEmpty();
    assertThat(dto.categoryId()).isEmpty();
    assertThat(dto.status()).isEqualTo("active");
    assertThat(dto.tags()).containsExactly("backend");
    assertThat(dto.createdAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
    assertThat(dto.updatedAt()).isEqualTo(Instant.parse("2026-02-01T00:00:00Z"));
    var pageable = ArgumentCaptor.forClass(Pageable.class);
    verify(repository).findAll(any(Specification.class), pageable.capture());
    assertThat(pageable.getValue().getSort()).isEqualTo(Sort.by("createdAt").and(Sort.by("id")));
  }

  @Test
  void detailUsesTenantAndPreservesNonNullValues() {
    var skill = skill();
    ReflectionTestUtils.setField(skill, "skillDescription", "Description");
    ReflectionTestUtils.setField(skill, "skillCategory", "Display name");
    ReflectionTestUtils.setField(skill, "categoryId", "category-text");
    when(tenantContext.requiredTenantId()).thenReturn("tenant-a");
    when(repository.findByIdAndTenantIdAndDeletedOnIsNull("skill-text-id", "tenant-a"))
        .thenReturn(Optional.of(skill));
    var dto = service.findById("skill-text-id");
    assertThat(dto.skillDescription()).isEqualTo("Description");
    assertThat(dto.skillCategory()).isEqualTo("Display name");
    assertThat(dto.categoryId()).isEqualTo("category-text");
    String[] tags = skill.getTags();
    tags[0] = "changed";
    assertThat(skill.getTags()).containsExactly("backend");
    assertThatThrownBy(() -> dto.tags().add("changed"))
        .isInstanceOf(UnsupportedOperationException.class);
  }

  @Test
  void absentOrInvisibleDetailIsNotFound() {
    when(tenantContext.requiredTenantId()).thenReturn("tenant-a");
    when(repository.findByIdAndTenantIdAndDeletedOnIsNull("hidden", "tenant-a"))
        .thenReturn(Optional.empty());
    assertThatThrownBy(() -> service.findById("hidden"))
        .isInstanceOf(ResourceNotFoundException.class);
  }

  @Test
  void countUsesRepositoryAndTenantContext() {
    when(tenantContext.requiredTenantId()).thenReturn("tenant-a");
    when(repository.count(any(Specification.class))).thenReturn(3L);
    assertThat(service.count(filter)).isEqualTo(3);
  }

  @Test
  void missingTenantNeverQueriesRepository() {
    when(tenantContext.requiredTenantId()).thenThrow(new AccessDeniedException("denied"));
    assertThatThrownBy(() -> service.list(filter, 0, 20)).isInstanceOf(AccessDeniedException.class);
    assertThatThrownBy(() -> service.count(filter)).isInstanceOf(AccessDeniedException.class);
    assertThatThrownBy(() -> service.findById("id")).isInstanceOf(AccessDeniedException.class);
    verifyNoInteractions(repository);
  }

  @Test
  void invalidPaginationFailsBeforeQuery() {
    for (int[] values : new int[][] {{-1, 20}, {0, 0}, {0, 101}}) {
      assertThatThrownBy(() -> service.list(filter, values[0], values[1]))
          .isInstanceOf(BadRequestException.class);
    }
    verifyNoInteractions(repository, tenantContext);
  }

  @Test
  void invalidFiltersAreRejected() {
    assertThatThrownBy(() -> new SkillFilter("x".repeat(201), null, null))
        .isInstanceOf(BadRequestException.class);
    assertThatThrownBy(() -> new SkillFilter(null, " ", null))
        .isInstanceOf(BadRequestException.class);
    assertThatThrownBy(() -> new SkillFilter(null, "x".repeat(201), null))
        .isInstanceOf(BadRequestException.class);
    assertThatThrownBy(() -> new SkillFilter(null, null, "unknown"))
        .isInstanceOf(BadRequestException.class);
    assertThat(new SkillFilter("Java", "category-text", "disabled").status()).isEqualTo("disabled");
  }
}
