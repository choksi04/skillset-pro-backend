package com.skillsetpro.model.records;

import com.skillsetpro.exceptions.BadRequestException;

public record SkillFilter(String search, String categoryId, String status) {
  public SkillFilter {
    if ((search != null && search.length() > 200)
        || (categoryId != null && (categoryId.isBlank() || categoryId.length() > 200))
        || (status != null && !status.equals("active") && !status.equals("disabled"))) {
      throw new BadRequestException("Invalid skill filters");
    }
  }
}
