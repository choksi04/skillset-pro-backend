package com.skillsetpro.exceptions;

import org.springframework.http.HttpStatus;

public class ResourceNotFoundException extends DomainException {
  public ResourceNotFoundException(String message) {
    super(message, HttpStatus.NOT_FOUND);
  }
}
