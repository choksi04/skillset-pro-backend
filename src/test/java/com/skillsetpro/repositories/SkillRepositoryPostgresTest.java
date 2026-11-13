package com.skillsetpro.repositories;

import static org.assertj.core.api.Assertions.*;

import com.skillsetpro.model.mappers.SkillMapper;
import com.skillsetpro.model.records.SkillFilter;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.data.domain.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@DataJpaTest(
    properties = {
      "spring.liquibase.change-log=classpath:db/changelog/db.changelog-development.yaml",
      "spring.jpa.hibernate.ddl-auto=validate"
    })
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers(disabledWithoutDocker = true)
class SkillRepositoryPostgresTest {
  @Container
  static final PostgreSQLContainer<?> DATABASE =
      new PostgreSQLContainer<>("postgres:18").withDatabaseName("skills_api_test");

  @DynamicPropertySource
  static void properties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", DATABASE::getJdbcUrl);
    registry.add("spring.datasource.username", DATABASE::getUsername);
    registry.add("spring.datasource.password", DATABASE::getPassword);
  }

  @Autowired SkillRepository repository;
  @Autowired JdbcTemplate jdbc;

  @BeforeEach
  void fixtures() {
    jdbc.update(
        """
        INSERT INTO public.skills
        (id,tenant_id,skill_name,category_id,skill_category,status,tags,deleted_on,created_at)
        VALUES
        ('a','tenant-a','Java','category-a','Legacy display','active',ARRAY['backend','java'],NULL,'2026-01-01T00:00:00Z'),
        ('b','tenant-a','JAVA advanced','category-b','Legacy display','disabled',ARRAY[]::text[],NULL,'2026-01-01T00:00:00Z'),
        ('c','tenant-a','literal%_\\','category-a','Other display','active',ARRAY[]::text[],NULL,'2026-01-01T00:00:00Z'),
        ('foreign','tenant-b','Java','category-a','Legacy display','active',ARRAY[]::text[],NULL,'2026-01-01T00:00:00Z'),
        ('deleted','tenant-a','Java','category-a','Legacy display','active',ARRAY[]::text[],now(),'2026-01-01T00:00:00Z')
        """);
  }

  private SkillFilter filter(String search, String category, String status) {
    return new SkillFilter(search, category, status);
  }

  @Test
  void tenantAndSoftDeletionApplyToListCountAndDetail() {
    var visible = SkillSpecifications.visible("tenant-a", filter(null, null, null));
    var page =
        repository.findAll(visible, PageRequest.of(0, 2, Sort.by("createdAt").and(Sort.by("id"))));
    assertThat(page.getContent()).extracting("id").containsExactly("a", "b");
    assertThat(page.getTotalElements()).isEqualTo(3);
    assertThat(repository.count(visible)).isEqualTo(3);
    assertThat(repository.findByIdAndTenantIdAndDeletedOnIsNull("foreign", "tenant-a")).isEmpty();
    assertThat(repository.findByIdAndTenantIdAndDeletedOnIsNull("deleted", "tenant-a")).isEmpty();
    var dto =
        SkillMapper.toDto(
            repository.findByIdAndTenantIdAndDeletedOnIsNull("a", "tenant-a").orElseThrow());
    assertThat(dto.tags()).containsExactly("backend", "java");
    assertThat(dto.categoryId()).isEqualTo("category-a");
    assertThat(repository.findAll(visible, PageRequest.of(10, 2))).isEmpty();
  }

  @Test
  void filtersUseCaseInsensitiveLiteralSearchAndCategoryId() {
    assertThat(
            repository.count(SkillSpecifications.visible("tenant-a", filter("java", null, null))))
        .isEqualTo(2);
    assertThat(
            repository.count(SkillSpecifications.visible("tenant-a", filter("%_\\", null, null))))
        .isEqualTo(1);
    assertThat(
            repository.count(
                SkillSpecifications.visible("tenant-a", filter(null, "category-a", "active"))))
        .isEqualTo(2);
    assertThat(
            repository.count(
                SkillSpecifications.visible("tenant-a", filter(" ", null, "disabled"))))
        .isEqualTo(1);
    assertThat(
            repository.count(
                SkillSpecifications.visible("tenant-a", filter(null, "Legacy display", null))))
        .isZero();
  }
}
