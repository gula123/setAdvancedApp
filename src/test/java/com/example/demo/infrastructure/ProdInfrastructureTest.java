package com.example.demo.infrastructure;

import org.springframework.test.context.ActiveProfiles;

/**
 * Infrastructure test for PROD environment
 * Validates that all AWS services are properly deployed and running
 */
@ActiveProfiles("prod")
public class ProdInfrastructureTest extends BaseInfrastructureTest {

    public ProdInfrastructureTest() {
        super(new InfrastructureConfig(
            "prod",
            "eu-north-1",
            "setadvanced-gula-prod",
            "image-recognition-results-prod",
            "app-lb-prod",
            "s3-events-prod",
            "image-processing-queue-prod"
        ));
    }
}