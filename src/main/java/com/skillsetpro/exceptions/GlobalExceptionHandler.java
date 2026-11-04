package com.skillsetpro.exceptions;

import com.skillsetpro.config.ApiProperties;
import com.skillsetpro.model.responses.GenericResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

@RestControllerAdvice
public class GlobalExceptionHandler {
  private static final Logger LOG = LoggerFactory.getLogger(GlobalExceptionHandler.class);
  private final ApiProperties properties;

  public GlobalExceptionHandler(ApiProperties properties) {
    this.properties = properties;
  }

  @ExceptionHandler(DomainException.class)
  ResponseEntity<GenericResponse<Void>> domain(DomainException exception) {
    return ResponseEntity.status(exception.getStatus())
        .body(GenericResponse.failure(exception.getMessage()));
  }

  @ExceptionHandler({MethodArgumentNotValidException.class, HttpMessageNotReadableException.class})
  ResponseEntity<GenericResponse<Void>> invalidRequest(Exception exception) {
    return ResponseEntity.badRequest().body(GenericResponse.failure("Invalid request"));
  }

  @ExceptionHandler(AccessDeniedException.class)
  ResponseEntity<GenericResponse<Void>> forbidden(AccessDeniedException exception) {
    return ResponseEntity.status(HttpStatus.FORBIDDEN)
        .body(GenericResponse.failure("Access denied"));
  }

  @ExceptionHandler({NoResourceFoundException.class, NoHandlerFoundException.class})
  ResponseEntity<GenericResponse<Void>> notFound(Exception exception) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(GenericResponse.failure("Resource not found"));
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<GenericResponse<Void>> unexpected(Exception exception) {
    LOG.error("Unhandled API exception: {}", exception.getClass().getName());
    return ResponseEntity.internalServerError()
        .body(GenericResponse.failure(properties.internalErrorMessage()));
  }
}
