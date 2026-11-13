package com.skillsetpro.services.impl;

import com.skillsetpro.exceptions.*;
import com.skillsetpro.model.mappers.SkillMapper;
import com.skillsetpro.model.records.*;
import com.skillsetpro.repositories.*;
import com.skillsetpro.security.TenantContext;
import com.skillsetpro.services.SkillService;
import com.skillsetpro.utils.AuthorityConstant;
import org.springframework.data.domain.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
@PreAuthorize(AuthorityConstant.READ_SKILLS)
public class SkillServiceImpl implements SkillService {
  private final SkillRepository repository;
  private final TenantContext tenantContext;

  public SkillServiceImpl(SkillRepository repository, TenantContext tenantContext) {
    this.repository = repository;
    this.tenantContext = tenantContext;
  }

  @Override
  public PageDto<SkillDto> list(SkillFilter filter, int page, int size) {
    if (page < 0 || size < 1 || size > 100) throw new BadRequestException("Invalid pagination");
    var rows =
        repository.findAll(
            SkillSpecifications.visible(tenantContext.requiredTenantId(), filter),
            PageRequest.of(page, size, Sort.by("createdAt").ascending().and(Sort.by("id"))));
    return new PageDto<>(
        rows.map(SkillMapper::toDto).getContent(),
        page,
        size,
        rows.getTotalElements(),
        rows.getTotalPages());
  }

  @Override
  public long count(SkillFilter filter) {
    return repository.count(SkillSpecifications.visible(tenantContext.requiredTenantId(), filter));
  }

  @Override
  public SkillDto findById(String id) {
    return repository
        .findByIdAndTenantIdAndDeletedOnIsNull(id, tenantContext.requiredTenantId())
        .map(SkillMapper::toDto)
        .orElseThrow(() -> new ResourceNotFoundException("Skill not found"));
  }
}
