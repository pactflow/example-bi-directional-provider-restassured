package com.example.springboot;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(value = HttpStatus.NOT_FOUND)
class ProductNotFoundException extends RuntimeException {
  private static final long serialVersionUID = 8087803211710068858L;

  ProductNotFoundException(Long id) {
    super("Could not find product " + id);
  }
}