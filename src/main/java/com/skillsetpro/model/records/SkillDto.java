package com.skillsetpro.model.records;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.List;

public record SkillDto(
    String id,
    @JsonProperty("tenant_id") String tenantId,
    @JsonProperty("skill_name") String skillName,
    @JsonProperty("skill_description") String skillDescription,
    @JsonProperty("category_id") String categoryId,
    @JsonProperty("skill_category") String skillCategory,
    List<String> tags,
    String status,
    @JsonProperty("created_at") Instant createdAt,
    @JsonProperty("updated_at") Instant updatedAt) {
  public SkillDto {
    tags = List.copyOf(tags);
  }
}
