package com.skillsetpro.model.mappers;

import com.skillsetpro.model.entities.Skill;
import com.skillsetpro.model.records.SkillDto;
import java.util.Arrays;

public final class SkillMapper {
  private SkillMapper() {}

  public static SkillDto toDto(Skill skill) {
    return new SkillDto(
        skill.getId(),
        skill.getTenantId(),
        skill.getSkillName(),
        emptyIfNull(skill.getSkillDescription()),
        emptyIfNull(skill.getCategoryId()),
        emptyIfNull(skill.getSkillCategory()),
        Arrays.asList(skill.getTags()),
        skill.getStatus(),
        skill.getCreatedAt(),
        skill.getUpdatedAt());
  }

  private static String emptyIfNull(String value) {
    return value == null ? "" : value;
  }
}
