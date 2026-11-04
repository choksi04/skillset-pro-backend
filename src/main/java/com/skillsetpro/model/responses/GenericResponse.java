package com.skillsetpro.model.responses;

public record GenericResponse<T>(T data, String error) {
  public static <T> GenericResponse<T> success(T data) {
    return new GenericResponse<>(data, null);
  }

  public static GenericResponse<Void> failure(String error) {
    return new GenericResponse<>(null, error);
  }
}
