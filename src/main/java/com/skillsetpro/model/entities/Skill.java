package com.skillsetpro.model.entities;

import jakarta.persistence.*;
import java.time.Instant;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "skills", schema = "public")
@Immutable
public class Skill extends Auditable {
  @Id private String id;

  @Column(name = "tenant_id", nullable = false)
  private String tenantId;

  @Column(name = "skill_name", nullable = false)
  private String skillName;

  @Column(name = "skill_description")
  private String skillDescription;

  @Column(name = "skill_category")
  private String skillCategory;

  @Column(name = "category_id")
  private String categoryId;

  @Column(nullable = false)
  private String status;

  @JdbcTypeCode(SqlTypes.ARRAY)
  @Column(nullable = false, columnDefinition = "text[]")
  private String[] tags;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected Skill() {}

  public String getId() {
    return id;
  }

  public String getTenantId() {
    return tenantId;
  }

  public String getSkillName() {
    return skillName;
  }

  public String getSkillDescription() {
    return skillDescription;
  }

  public String getSkillCategory() {
    return skillCategory;
  }

  public String getCategoryId() {
    return categoryId;
  }

  public String getStatus() {
    return status;
  }

  public String[] getTags() {
    return tags.clone();
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
