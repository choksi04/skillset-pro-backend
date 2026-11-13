package com.skillsetpro.model.entities;

import jakarta.persistence.*;
import java.time.Instant;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

/**
 * Existing audit columns. Write-side auditing will be enabled with application identity mapping.
 */
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class Auditable {
  @CreatedDate
  @Column(name = "created_at", nullable = false)
  protected Instant createdAt;

  @CreatedBy
  @Column(name = "created_by")
  protected String createdBy;

  @LastModifiedDate
  @Column(name = "modified_at")
  protected Instant modifiedAt;

  @LastModifiedBy
  @Column(name = "modified_by")
  protected String modifiedBy;

  @Column(name = "deleted_on")
  protected Instant deletedOn;

  @Column(name = "deleted_by")
  protected String deletedBy;

  public Instant getCreatedAt() {
    return createdAt;
  }
}
