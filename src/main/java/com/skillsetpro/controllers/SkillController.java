package com.skillsetpro.controllers;

import com.skillsetpro.model.records.*;
import com.skillsetpro.model.responses.GenericResponse;
import com.skillsetpro.services.SkillService;
import com.skillsetpro.utils.AuthorityConstant;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@Tag(name = "Skills")
@SecurityRequirement(name = "bearerAuth")
@RequestMapping("/api/v1/skills")
@PreAuthorize(AuthorityConstant.READ_SKILLS)
public class SkillController {
  private final SkillService service;

  public SkillController(SkillService service) {
    this.service = service;
  }

  @GetMapping
  @Operation(summary = "List non-deleted skills in the authenticated application tenant")
  public GenericResponse<PageDto<SkillDto>> list(
      @RequestParam(defaultValue = "0") @Min(0) int page,
      @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size,
      @RequestParam(required = false) String search,
      @RequestParam(required = false) String categoryId,
      @RequestParam(required = false) String status) {
    return GenericResponse.success(
        service.list(new SkillFilter(search, categoryId, status), page, size));
  }

  @GetMapping("/count")
  @Operation(summary = "Count skills using the same visibility and filters as the list")
  public GenericResponse<Long> count(
      @RequestParam(required = false) String search,
      @RequestParam(required = false) String categoryId,
      @RequestParam(required = false) String status) {
    return GenericResponse.success(service.count(new SkillFilter(search, categoryId, status)));
  }

  @GetMapping("/{id}")
  @Operation(summary = "Get a non-deleted skill in the authenticated application tenant")
  public GenericResponse<SkillDto> findById(@PathVariable @NotBlank String id) {
    return GenericResponse.success(service.findById(id));
  }
}
