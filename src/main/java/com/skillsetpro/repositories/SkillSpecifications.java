package com.skillsetpro.repositories;

import com.skillsetpro.model.entities.Skill;
import com.skillsetpro.model.records.SkillFilter;
import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.Locale;
import org.springframework.data.jpa.domain.Specification;

public final class SkillSpecifications {
  private SkillSpecifications() {}

  public static Specification<Skill> visible(String tenantId, SkillFilter filter) {
    return (root, query, builder) -> {
      var predicates = new ArrayList<Predicate>();
      predicates.add(builder.equal(root.get("tenantId"), tenantId));
      predicates.add(builder.isNull(root.get("deletedOn")));
      if (filter.search() != null && !filter.search().isBlank()) {
        String literal =
            filter
                .search()
                .toLowerCase(Locale.ROOT)
                .replace("\\", "\\\\")
                .replace("%", "\\%")
                .replace("_", "\\_");
        predicates.add(
            builder.like(builder.lower(root.get("skillName")), "%" + literal + "%", '\\'));
      }
      if (filter.categoryId() != null) {
        predicates.add(builder.equal(root.get("categoryId"), filter.categoryId()));
      }
      if (filter.status() != null) {
        predicates.add(builder.equal(root.get("status"), filter.status()));
      }
      return builder.and(predicates.toArray(Predicate[]::new));
    };
  }
}
