package com.skillsetpro.repositories;

import com.skillsetpro.model.entities.Skill;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface SkillRepository
    extends JpaRepository<Skill, String>, JpaSpecificationExecutor<Skill> {
  Optional<Skill> findByIdAndTenantIdAndDeletedOnIsNull(String id, String tenantId);
}
