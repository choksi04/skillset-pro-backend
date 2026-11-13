package com.skillsetpro.services;

import com.skillsetpro.model.records.*;

public interface SkillService {
  PageDto<SkillDto> list(SkillFilter filter, int page, int size);

  long count(SkillFilter filter);

  SkillDto findById(String id);
}
