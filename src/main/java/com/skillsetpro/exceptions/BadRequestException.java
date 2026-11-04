package com.skillsetpro.exceptions;

import org.springframework.http.HttpStatus;

public class BadRequestException extends DomainException {
  public BadRequestException(String message) {
    super(message, HttpStatus.BAD_REQUEST);
  }
}
