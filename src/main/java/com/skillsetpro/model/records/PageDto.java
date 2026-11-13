package com.skillsetpro.model.records;

import java.util.List;

public record PageDto<T>(List<T> items, int page, int size, long totalElements, int totalPages) {
  public PageDto {
    items = List.copyOf(items);
  }
}
