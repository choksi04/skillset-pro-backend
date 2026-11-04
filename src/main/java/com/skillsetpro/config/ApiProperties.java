package com.skillsetpro.config;

import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "app.api")
public record ApiProperties(
    @NotBlank(message = "An internal error message is required") String internalErrorMessage) {}
