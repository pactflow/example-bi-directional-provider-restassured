package com.example.springboot;

import java.io.File;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport.Level;
import com.atlassian.oai.validator.restassured.OpenApiValidationFilter;
import com.atlassian.oai.validator.whitelist.ValidationErrorsWhitelist;
import com.atlassian.oai.validator.whitelist.rule.WhitelistRules;

import static io.restassured.RestAssured.given;

@ExtendWith(SpringExtension.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.DEFINED_PORT)
class ProductsAPITest {
  @LocalServerPort
  int port;

  @Autowired
  ProductRepository repository;

  File spec = new File("oas/swagger.yml");

  // Use this for "happy path" testing
  private final OpenApiValidationFilter validationFilter = new OpenApiValidationFilter(spec.getAbsolutePath());
  private final OpenApiInteractionValidator responseOnlyValidator = OpenApiInteractionValidator
      .createForSpecificationUrl(spec.getAbsolutePath())
      .withLevelResolver(LevelResolver.create().withLevel("validation.request", Level.WARN).build())
      .withWhitelist(ValidationErrorsWhitelist.create().withRule("Ignore request entities", WhitelistRules.isRequest()))
      .build();

  // Use this for "negative scenario" testing
  // ref: https://bitbucket.org/atlassian/swagger-request-validator/issues/332/restassured-skip-request-validation-with
  private OpenApiValidationFilter responseOnlyValidation = new OpenApiValidationFilter(responseOnlyValidator);

  @Test
  public void testCreateProduct200() {
    Product product = new Product(99L, "new product", "product category", "v1", 1.99);

    given().port(port).filter(validationFilter).body(product).contentType("application/json").when().post("/products")
        .then().assertThat().statusCode(200);
  }

  @Test
  public void testCreateProduct400() {
    given().port(port).filter(responseOnlyValidation).body("{}").contentType("application/json").when().post("/products")
        .then().assertThat().statusCode(400);
  }

  @Test
  public void testListProducts() {
    given().port(port).filter(validationFilter).when().get("/products").then().assertThat().statusCode(200);
  }

  @Test
  public void testGetProduct200() {
    given().port(port).filter(validationFilter).when().get("/product/1").then().assertThat().statusCode(200);
  }

  @Test
  public void testGetProduct404() {
    given().port(port).filter(responseOnlyValidation).when().get("/product/999").then().assertThat().statusCode(404);
  }

  @Test
  public void testGetProduct400() {
    given().port(port).filter(responseOnlyValidation).when().get("/product/notanumber").then().assertThat().statusCode(400);
  }
}