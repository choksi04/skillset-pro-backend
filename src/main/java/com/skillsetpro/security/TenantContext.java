package com.skillsetpro.security;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

@Component
public class TenantContext {
  /**
   * Provisional trusted-token contract; never substitute Entra tid or a request tenant parameter.
   */
  public String requiredTenantId() {
    var authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication != null
        && authentication.isAuthenticated()
        && authentication.getPrincipal() instanceof Jwt jwt
        && jwt.getClaims().get("app_tenant_id") instanceof String tenant
        && !tenant.isBlank()) {
      return tenant;
    }
    throw new AccessDeniedException("Application tenant mapping required");
  }
}
