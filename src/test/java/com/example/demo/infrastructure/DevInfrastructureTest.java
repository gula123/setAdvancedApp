package com.example.demo.infrastructure;

import org.springframework.test.context.ActiveProfiles;

/**
 * Infrastructure test for DEV environment
 * Validates that all AWS services are properly deployed and running
 */
@ActiveProfiles("dev")
public class DevInfrastructureTest extends BaseInfrastructureTest {

    public DevInfrastructureTest() {
        super(new InfrastructureConfig(
            "dev",
            "eu-north-1",
            "setadvanced-gula-dev",
            "image-recognition-results-dev",
            "app-lb-dev",
            "s3-events-dev",
            "image-processing-queue-dev"
        ));
    }
}